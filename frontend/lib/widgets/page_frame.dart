import 'package:flutter/material.dart';

class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(compact ? 22 : 28),
            border: Border.all(color: const Color(0xFFDCE7EA)),
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
                SizedBox(height: compact ? 16 : 24),
                Expanded(child: child),
              ],
            ),
          ),
        );
      },
    );
  }
}
