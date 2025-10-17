import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/action_item.dart';
import '../services/firestore_service.dart';

class ActionCard extends StatelessWidget {
  final ActionItem item;
  const ActionCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final dateStr = item.date != null ? DateFormat('EEE, d MMM yyyy').format(item.date!) : 'Waktu fleksibel';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Wrap(spacing: 8, runSpacing: 4, children: [
              Chip(label: Text(item.category)),
              Chip(label: Text(dateStr)),
              Chip(label: Text(item.location)),
            ]),
            const SizedBox(height: 8),
            Text('Kebutuhan: ${item.needs}'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Peserta: ${item.participantCount}'),
                FilledButton.icon(
                  onPressed: () async {
                    try {
                      await FirestoreService.instance.joinAction(item.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Berhasil mendaftar aksi')), 
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal bergabung: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.volunteer_activism_outlined),
                  label: const Text('Saya Ikut'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
