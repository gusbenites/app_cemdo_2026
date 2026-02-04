import 'package:app_cemdo/data/models/account_model.dart';
import 'package:flutter/material.dart';

class AccountListItem extends StatelessWidget {
  final Account account;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback onDelete;

  const AccountListItem({
    super.key,
    required this.account,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(account.razonSocial),
      subtitle: Text('Usuario: ${account.idcliente}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(Icons.check_circle, color: Colors.green),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: onDelete,
            tooltip: 'Desvincular cuenta',
          ),
        ],
      ),
      onTap: onTap,
      selected: isActive,
      selectedTileColor: Colors.green.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
    );
  }
}
