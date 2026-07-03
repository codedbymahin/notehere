import 'package:flutter/material.dart';

/// Lays out [child] inside a horizontally-padded column that has a
/// maximum width. On phones the child fills the available space; on
/// tablets and desktop browsers the content is centred and never
/// exceeds [maxWidth], keeping line lengths readable.
class CenteredMaxWidth extends StatelessWidget {
  const CenteredMaxWidth({
    super.key,
    required this.child,
    this.maxWidth = 880,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
