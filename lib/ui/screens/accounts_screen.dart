import 'package:app_cemdo/data/models/account_model.dart';
import 'package:app_cemdo/logic/providers/account_provider.dart';
import 'package:app_cemdo/ui/widgets/account_list_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_cemdo/data/services/secure_storage_service.dart'; // Added
import 'package:app_cemdo/ui/widgets/link_account_dialog.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final SecureStorageService _secureStorageService = SecureStorageService();
  bool _isChangingAccount = false; // Added

  Future<void> _showUnlinkConfirmationDialog(
    BuildContext context,
    Account account,
    AccountProvider provider,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          elevation: 5,
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 10),
              Text('Confirmar Acción'),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text(
                  '¿Estás seguro de que quieres desvincular la cuenta?',
                ),
                const SizedBox(height: 8),
                Text(
                  account.razonSocial,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Esta acción no se puede deshacer.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever, size: 18),
              label: const Text('Desvincular'),
              onPressed: _isChangingAccount
                  ? null
                  : () {
                      _handleUnlinkAccount(account, provider);
                    },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }

  // New method to handle account tap
  void _handleAccountTap(
    Account account,
    AccountProvider accountProvider,
  ) async {
    setState(() {
      _isChangingAccount = true;
    }); // Set loading state
    try {
      final token = await _secureStorageService.getToken();
      if (!mounted) return;
      if (token != null) {
        final success = await accountProvider.changeActiveAccount(
          token,
          account.idcliente,
        );
        if (!mounted) return;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cuenta activa cambiada con éxito.')),
          );
          if (mounted) {
            // Reset loading state before navigation
            setState(() {
              _isChangingAccount = false;
            });
          }
          if (!mounted) return; // Check mounted again before navigation
          Navigator.of(
            context,
          ).pushReplacementNamed('/main'); // Navigate to main screen
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al cambiar la cuenta activa.')),
          );
          if (mounted) {
            // Only reset if still mounted and no navigation
            setState(() {
              _isChangingAccount = false;
            });
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontró el token de autenticación.'),
          ),
        );
        if (mounted) {
          // Only reset if still mounted and no navigation
          setState(() {
            _isChangingAccount = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error in _handleAccountTap: $e');
      if (mounted) {
        // Reset on error
        setState(() {
          _isChangingAccount = false;
        });
      }
    }
  }

  // New method to handle unlink account
  void _handleUnlinkAccount(Account account, AccountProvider provider) async {
    setState(() {
      _isChangingAccount = true;
    }); // Set loading state
    try {
      final token = await _secureStorageService.getToken();
      if (!mounted) return;
      if (token != null) {
        final success = await provider.unlinkAccountApi(
          token,
          account.idcliente,
        );
        if (!mounted) return;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cuenta desvinculada con éxito.')),
          );
          if (mounted) {
            // Reset loading state before navigation
            setState(() {
              _isChangingAccount = false;
            });
          }
          if (!mounted) return; // Check mounted again before navigation
          Navigator.of(context).pop(); // Close dialog
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al desvincular la cuenta.')),
          );
          if (mounted) {
            // Only reset if still mounted and no navigation
            setState(() {
              _isChangingAccount = false;
            });
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontró el token de autenticación.'),
          ),
        );
        if (mounted) {
          // Only reset if still mounted and no navigation
          setState(() {
            _isChangingAccount = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error in _handleUnlinkAccount: $e');
      if (mounted) {
        // Reset on error
        setState(() {
          _isChangingAccount = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountProvider>(
      builder: (context, accountProvider, child) {
        return CustomScrollView(
          slivers: [
            // Blue Header
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue[900],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20.0),
                    bottomRight: Radius.circular(20.0),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cuentas Vinculadas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Gestione sus cuentas para acceder a los servicios.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Accounts List or Empty State
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverToBoxAdapter(
                child: accountProvider.accounts.isEmpty
                    ? Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No tienes cuentas vinculadas.',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          itemCount: accountProvider.accounts.length,
                          itemBuilder: (context, index) {
                            final account = accountProvider.accounts[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: AccountListItem(
                                account: account,
                                isActive:
                                    account.idcliente ==
                                    accountProvider.activeAccount?.idcliente,
                                onTap: _isChangingAccount
                                    ? null
                                    : () => _handleAccountTap(
                                        account,
                                        accountProvider,
                                      ),
                                onDelete: () => _showUnlinkConfirmationDialog(
                                  context,
                                  account,
                                  accountProvider,
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (context, index) =>
                              const Divider(indent: 16, endIndent: 16),
                        ),
                      ),
              ),
            ),

            // Link New Account Button
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 32.0),
              sliver: SliverToBoxAdapter(
                child: FilledButton.icon(
                  onPressed: _isChangingAccount
                      ? null
                      : () async {
                          final success = await showDialog<bool>(
                            context: context,
                            builder: (context) => const LinkAccountDialog(),
                          );
                          if (success == true && mounted) {
                            Navigator.of(context).pushReplacementNamed('/main');
                          }
                        },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Vincular Nueva Cuenta'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ),
            ),

            // Loading Indicator Overlay
            if (_isChangingAccount)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        );
      },
    );
  }
}
