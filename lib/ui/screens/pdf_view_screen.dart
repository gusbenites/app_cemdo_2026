import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:app_cemdo/data/services/error_service.dart';
import 'package:app_cemdo/data/services/secure_storage_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:share_plus/share_plus.dart'; // Added for sharing

class PdfViewScreen extends StatefulWidget {
  final String idcbte;
  final String nroFactura;

  const PdfViewScreen({
    super.key,
    required this.idcbte,
    required this.nroFactura,
  });

  @override
  State<PdfViewScreen> createState() => _PdfViewScreenState();
}

class _PdfViewScreenState extends State<PdfViewScreen> {
  String? _pdfPath;
  bool _isLoading = true;
  String? _errorMessage;

  /// Nombre base de archivo válido para cualquier sistema de archivo
  /// (sin `/`, `:`, etc. que romperían la escritura o el compartir).
  String get _fileName {
    final cleaned = widget.nroFactura.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return cleaned.trim().isEmpty ? 'factura_${widget.idcbte}' : cleaned;
  }

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final secureStorage = SecureStorageService();
      final token = await secureStorage.getToken();
      final backendUrl = dotenv.env['BACKEND_URL'];

      if (token == null || backendUrl == null) {
        throw Exception('Token or Backend URL not found.');
      }

      final url = Uri.parse('$backendUrl/pdf/${widget.idcbte}');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$_fileName.pdf');
        await file.writeAsBytes(response.bodyBytes);
        if (!mounted) return;
        setState(() {
          _pdfPath = file.path;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load PDF: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _sharePdf(BuildContext shareContext) async {
    final String? path = _pdfPath;
    if (path == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay PDF para compartir.')),
      );
      return;
    }

    try {
      // Se resuelve el origen del popover ANTES del primer await, para no
      // usar el BuildContext a través de una brecha asíncrona.
      final box = shareContext.findRenderObject();
      Rect? sharePositionOrigin;
      if (box is RenderBox &&
          box.hasSize &&
          box.size.width > 0 &&
          box.size.height > 0) {
        sharePositionOrigin = box.localToGlobal(Offset.zero) & box.size;
      } else {
        final size = MediaQuery.maybeOf(shareContext)?.size;
        if (size != null && size.width > 0 && size.height > 0) {
          sharePositionOrigin = Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: 10,
            height: 10,
          );
        }
      }

      if (!await File(path).exists()) {
        throw Exception('El archivo PDF ya no está disponible.');
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: 'application/pdf')],
          text: 'Factura ${widget.nroFactura}',
          subject: 'Factura ${widget.nroFactura}',
          fileNameOverrides: ['$_fileName.pdf'],
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } catch (e, stack) {
      // Visible para el usuario (SnackBar) y reportado a Sentry.
      ErrorService().reportError(
        e,
        stack,
        'Al compartir el PDF ${widget.nroFactura}',
      );
    }
  }

  /// Copia el PDF a una ubicación accesible para el usuario.
  ///
  /// * **Android:** directorio externo de la app
  ///   (`getExternalStorageDirectory()`), que sólo existe en Android.
  /// * **iOS:** no existe una carpeta "Descargas" accesible para la app y
  ///   `getExternalStorageDirectory()` lanza `UnsupportedError`, así que se
  ///   guarda en `Documentos/Downloads`, visible en la app **Archivos**
  ///   (On My iPhone › Portal CEMDO › Downloads) gracias a las claves
  ///   `UIFileSharingEnabled` y `LSSupportsOpeningDocumentsInPlace` del
  ///   Info.plist.
  Future<void> _downloadPdf() async {
    final String? path = _pdfPath;
    if (path == null) return;

    try {
      final File source = File(path);
      if (!await source.exists()) {
        throw Exception('El archivo PDF ya no está disponible.');
      }

      final Directory targetDir;
      if (Platform.isIOS) {
        final Directory docs = await getApplicationDocumentsDirectory();
        targetDir = Directory('${docs.path}/Downloads');
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
      } else {
        final Directory? external = await getExternalStorageDirectory();
        if (external == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo acceder al directorio de descarga.'),
            ),
          );
          return;
        }
        targetDir = external;
      }

      final newPath = '${targetDir.path}/$_fileName.pdf';
      await source.copy(newPath);

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            Platform.isIOS
                ? 'PDF guardado en Archivos › Portal CEMDO › Downloads'
                : 'PDF descargado en: $newPath',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e, stack) {
      // Visible para el usuario (SnackBar) y reportado a Sentry.
      if (!mounted) return;
      ErrorService().reportError(
        e,
        stack,
        'Al descargar el PDF ${widget.nroFactura}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Factura ${widget.nroFactura}'),
        actions: [
          Builder(
            builder: (buttonContext) => IconButton(
              icon: const Icon(Icons.share),
              onPressed: _pdfPath != null
                  ? () => _sharePdf(buttonContext)
                  : null,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download), // Changed to download icon
            onPressed: _pdfPath != null ? _downloadPdf : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text('Error: $_errorMessage'))
          : _pdfPath != null
          ? PDFView(filePath: _pdfPath)
          : const Center(child: Text('No se pudo cargar el PDF.')),
    );
  }
}
