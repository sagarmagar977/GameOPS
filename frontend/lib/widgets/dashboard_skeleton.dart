import 'package:flutter/material.dart';

import 'list_row_skeleton.dart';
import 'skeleton_box.dart';

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _section([const SkeletonBox(height: 30, width: 80), const SizedBox(height: 16), const ListRowSkeleton(), const SizedBox(height: 10), const ListRowSkeleton()])),
            const SizedBox(width: 16),
            Expanded(child: _section([const SkeletonBox(height: 16, width: 180), const SizedBox(height: 16), const SkeletonBox(height: 22, width: 120), const SizedBox(height: 12), const SkeletonBox(height: 22, width: 120)])),
          ],
        ),
        const SizedBox(height: 20),
        _section([const ListRowSkeleton(), const SizedBox(height: 10), const ListRowSkeleton(), const SizedBox(height: 10), const ListRowSkeleton()]),
      ],
    );
  }

  Widget _section(List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}
