import 'package:flutter/material.dart';

class ComBtn extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ComBtn({
    required this.icon,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: icon,
      ),
    );
  }
}
