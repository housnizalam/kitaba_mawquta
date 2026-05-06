import 'package:flutter/material.dart';

/// Wraps [child] in a centered, width-constrained column so the app stays
/// phone-proportioned on wide screens like Windows desktops.
///
/// Use this at the top of every page scaffold body.
class ConstrainedPageBody extends StatelessWidget {
  final Widget child;

  /// Maximum width of the content column.
  /// Defaults to 480 dp — comfortable on phones and narrow on large screens.
  final double maxWidth;

  const ConstrainedPageBody({
    super.key,
    required this.child,
    this.maxWidth = 480,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
