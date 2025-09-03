import 'package:app_cemdo/models/invoice_model.dart';
import 'package:app_cemdo/providers/account_provider.dart';
import 'package:app_cemdo/widgets/account_card.dart';
import 'package:app_cemdo/widgets/invoice_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_cemdo/providers/invoice_provider.dart'; // Added
import 'package:app_cemdo/services/secure_storage_service.dart'; // Added

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    final accountProvider = Provider.of<AccountProvider>(context);
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

      final accountProvider = Provider.of<AccountProvider>(context, listen: false);
      final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);

      if (token != null && accountProvider.activeAccount != null) {
        _lastFetchedAccountId = accountProvider.activeAccount!.idcliente; // Update last fetched ID here
        await invoiceProvider.fetchInvoices(token, accountProvider.activeAccount!.idcliente, showAll: false);
      } else {
        // If no active account or token, clear invoices
        invoiceProvider.allInvoices.clear(); // Clear all invoices
        invoiceProvider.unpaidInvoices.clear(); // Clear unpaid invoices
        debugPrint('Token or active account is null. Cannot fetch invoices for Home Screen.');
      }
    } catch (e) {
      debugPrint('Error fetching invoices in HomeScreen: $e');
      // Clear invoices on error
      final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
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
    return Consumer2<AccountProvider, InvoiceProvider>(
      builder: (context, accountProvider, invoiceProvider, child) {
        if (accountProvider.activeAccount == null) {
          return const Center(child: Text('No hay una cuenta activa seleccionada.'));
        }

        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<Invoice> pendingAndOverdueInvoices = invoiceProvider.unpaidInvoices;
        final int overdueCount = pendingAndOverdueInvoices.where((inv) => inv.isVencida).length;

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
                child: AccountCard(
                  key: ValueKey(accountProvider.activeAccount!.idcliente),
                  account: accountProvider.activeAccount!,
                ),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Facturas Pendientes',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (overdueCount > 0)
                              Chip(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 4.0),
                                label: Text(
                                  '$overdueCount VENCIDA(S)',
                                  style: const TextStyle(
                                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: pendingAndOverdueInvoices.isEmpty
                              ? const Center(
                                  child: Text('No hay facturas pendientes.'),
                                )
                              : ListView.separated(
                                  itemCount: pendingAndOverdueInvoices.length,
                                  itemBuilder: (context, index) {
                                    return InvoiceCard(invoice: pendingAndOverdueInvoices[index]);
                                  },
                                  separatorBuilder: (context, index) => const Divider(),
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