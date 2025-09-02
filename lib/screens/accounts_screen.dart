import 'package:app_cemdo/models/account_model.dart';
import 'package:app_cemdo/providers/account_provider.dart';
import 'package:app_cemdo/widgets/account_list_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  Future<void> _showUnlinkConfirmationDialog(
      BuildContext context, Account account, AccountProvider provider) async {
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
                const Text('¿Estás seguro de que quieres desvincular la cuenta?'),
                const SizedBox(height: 8),
                Text(account.razonSocial, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Esta acción no se puede deshacer.', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
              onPressed: () {
                provider.unlinkAccount(account);
                Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Added Scaffold
      backgroundColor: Colors.white, // Set background color
      body: Consumer<AccountProvider>(
        builder: (context, accountProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cuentas Vinculadas',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: accountProvider.accounts.isEmpty
                      ? Center(
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
                              const SizedBox(height: 8),
                              Text(
                                'Vincula una cuenta para empezar.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: accountProvider.accounts.length,
                          itemBuilder: (context, index) {
                            final account = accountProvider.accounts[index];
                            return AccountListItem(
                              account: account,
                              isActive: account.idcliente == accountProvider.activeAccount?.idcliente,
                              onTap: () => accountProvider.setActiveAccount(account),
                              onDelete: () => _showUnlinkConfirmationDialog(context, account, accountProvider),
                            );
                          },
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                        ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Placeholder for the "Vincular cuenta" action
                    showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                              title: const Text('Vincular Cuenta'),
                              content: const Text('Aquí iría el formulario para vincular una nueva cuenta.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cerrar'),
                                )
                              ],
                            ));
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Vincular nueva cuenta'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50), // full width
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
