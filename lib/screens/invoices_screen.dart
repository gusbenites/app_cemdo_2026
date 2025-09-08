import 'package:app_cemdo/providers/account_provider.dart';
import 'package:app_cemdo/models/invoice_model.dart';
import 'package:app_cemdo/widgets/account_card.dart';
import 'package:app_cemdo/widgets/invoice_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_cemdo/providers/invoice_provider.dart'; // Added
import 'package:app_cemdo/services/secure_storage_service.dart'; // Added
import 'package:app_cemdo/screens/pdf_view_screen.dart';

class InvoicesScreen extends StatefulWidget {
  final bool showAll;

  const InvoicesScreen({super.key, this.showAll = false});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final SecureStorageService _secureStorageService = SecureStorageService();
  bool _isLoading = true; // To show loading indicator
  int? _lastFetchedAccountId; // Added

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This is a better place to react to provider changes
    final accountProvider = Provider.of<AccountProvider>(
      context,
    ); // Listen to changes
    if (accountProvider.activeAccount?.idcliente != _lastFetchedAccountId) {
      _fetchInvoices();
    }
  }

  Future<void> _fetchInvoices() async {
    // Set loading to true at the start of fetch
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final token = await _secureStorageService.getToken();
      if (!mounted) return;

      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );
      final invoiceProvider = Provider.of<InvoiceProvider>(
        context,
        listen: false,
      );

      if (token != null && accountProvider.activeAccount != null) {
        _lastFetchedAccountId = accountProvider
            .activeAccount!
            .idcliente; // Update last fetched ID here
        await invoiceProvider.fetchInvoices(
          token,
          accountProvider.activeAccount!.idcliente,
          showAll: widget.showAll,
        );
      } else {
        // If no active account or token, clear invoices
        invoiceProvider.allInvoices.clear(); // Clear all invoices
        invoiceProvider.unpaidInvoices.clear(); // Clear unpaid invoices
        debugPrint('Token or active account is null. Cannot fetch invoices.');
      }
    } catch (e) {
      debugPrint('Error fetching invoices in InvoicesScreen: $e');
      // Clear invoices on error
      final invoiceProvider = Provider.of<InvoiceProvider>(
        context,
        listen: false,
      );
      invoiceProvider.allInvoices.clear();
      invoiceProvider.unpaidInvoices.clear();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Removed sampleInvoices
    return Consumer2<AccountProvider, InvoiceProvider>(
      // Use Consumer2 for multiple providers
      builder: (context, accountProvider, invoiceProvider, child) {
        if (accountProvider.activeAccount == null) {
          return const Center(
            child: Text('No hay una cuenta activa seleccionada.'),
          );
        }

        if (_isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          ); // Show loading indicator
        }

        // Determine which list of invoices to show based on showAll
        final List<Invoice> invoicesToShow = widget.showAll
            ? invoiceProvider
                  .allInvoices // Show all invoices
            : invoiceProvider.unpaidInvoices; // Show only unpaid invoices

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: Colors.blue[900],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20.0),
                  bottomRight: Radius.circular(20.0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 16.0),
                child: AccountCard(account: accountProvider.activeAccount!),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Historial de Facturas',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: invoicesToShow.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No hay facturas para mostrar.',
                                  ), // Generic message
                                )
                              : ListView.separated(
                                  itemCount: invoicesToShow.length,
                                  itemBuilder: (context, index) {
                                    final invoice = invoicesToShow[index];
                                    return InvoiceCard(
                                      invoice: invoice,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => PdfViewScreen(
                                              idcbte: invoice.idcbte.toString(),
                                              nroFactura: invoice.nroFactura,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  separatorBuilder: (context, index) =>
                                      const Divider(),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
