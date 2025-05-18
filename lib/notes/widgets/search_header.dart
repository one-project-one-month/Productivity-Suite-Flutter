import 'package:flutter/material.dart';

class SearchHeader extends SliverPersistentHeaderDelegate {
  final Widget child;
  @override
  final double maxExtent;
  @override
  final double minExtent;

  SearchHeader({
    required this.child,
    required this.maxExtent,
    required this.minExtent,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: shrinkOffset < maxExtent ? 1.0 : 0.0,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}