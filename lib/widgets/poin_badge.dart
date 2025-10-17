import 'package:flutter/material.dart';

class PoinBadge extends StatelessWidget {
  final int points;
  const PoinBadge({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.primary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.military_tech_outlined, size: 18),
          const SizedBox(width: 6),
          Text('$points poin'),
        ],
      ),
    );
  }
}
