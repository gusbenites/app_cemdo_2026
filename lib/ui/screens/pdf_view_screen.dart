import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
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
        final file = File('${dir.path}/${widget.nroFactura}.pdf');
        await file.writeAsBytes(response.bodyBytes);
        setState(() {
          _pdfPath = file.path;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load PDF: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _sharePdf() async {
    if (_pdfPath != null) {
      await Share.shareXFiles([
        XFile(_pdfPath!),
      ], text: 'Factura ${widget.nroFactura}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay PDF para compartir.')),
      );
    }
  }

  Future<void> _downloadPdf() async {
    if (_pdfPath == null) return;

    try {
      // Get the external storage directory (e.g., Downloads on Android)
      // For iOS, getApplicationDocumentsDirectory() is usually used, but for saving to user accessible
      // locations, other methods might be needed. For simplicity, we'll use getExternalStorageDirectory
      // which works well for Android.
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo acceder al directorio de descarga.'),
          ),
        );
        return;
      }

      final newPath = '${directory.path}/${widget.nroFactura}.pdf';
      final originalFile = File(_pdfPath!);
      await originalFile.copy(newPath);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF descargado en: $newPath')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al descargar el PDF: \$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Factura ${widget.nroFactura}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _pdfPath != null ? _sharePdf : null,
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
