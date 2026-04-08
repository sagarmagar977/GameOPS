import 'package:flutter/material.dart';

import 'skeleton_box.dart';

class ListRowSkeleton extends StatelessWidget {
  const ListRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE4E8)),
      ),
      child: Row(
        children: const [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 16, width: 140, radius: 8),
                SizedBox(height: 8),
                SkeletonBox(height: 12, width: 200, radius: 8),
              ],
            ),
          ),
          SizedBox(width: 12),
          SkeletonBox(height: 24, width: 48, radius: 12),
        ],
      ),
    );
  }
}
