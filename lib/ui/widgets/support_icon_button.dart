import 'package:flutter/material.dart';
import 'package:app_cemdo/ui/utils/support_utils.dart';

class SupportIconButton extends StatelessWidget {
  final Color? color;

  const SupportIconButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.headset_mic, color: color),
      tooltip: 'Contactar Soporte',
      onPressed: () => SupportUtils.showContactDialog(context),
    );
  }
}
