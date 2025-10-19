import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/action_item.dart';
import '../services/firestore_service.dart';
import '../screens/action_detail_screen.dart';

class ActionCard extends StatelessWidget {
  final ActionItem item;
  const ActionCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final dateStr = item.date != null
        ? DateFormat('EEE, d MMM yyyy').format(item.date!)
        : 'Waktu fleksibel';
    final icon = _iconForCategory(item.category);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ActionDetailScreen(item: item),
          ),
        );
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0x1A2563EB),
                    foregroundColor: const Color(0xFF2563EB),
                    child: Icon(icon),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Hero(
                      tag: 'action_title_${item.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          item.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  StreamBuilder<bool>(
                    stream: FirestoreService.instance.streamIsAdmin(),
                    builder: (context, snap) {
                      final isAdmin = snap.data == true;
                      if (!isAdmin) return const SizedBox.shrink();
                      return IconButton(
                        tooltip: 'Hapus Aksi',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Hapus Aksi?'),
                              content: Text('Anda akan menghapus "${item.title}"'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Batal')),
                                FilledButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Hapus')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await FirestoreService.instance.deleteAction(item.id);
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 4, children: [
                Chip(label: Text(item.category)),
                Chip(label: Text(dateStr)),
                Chip(label: Text(item.location)),
              ]),
              const SizedBox(height: 8),
              Text('Kebutuhan: ${item.needs}'),
              const SizedBox(height: 12),
              _ParticipantsProgress(count: item.participants.length, target: item.capacity),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Spacer(),
                  Builder(builder: (context) {
                    final isFull = item.participants.length >= item.capacity;
                    return ElevatedButton.icon(
                      onPressed: isFull
                          ? null
                          : () async {
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
                      icon: Icon(isFull ? Icons.block : Icons.favorite_border),
                      label: Text(isFull ? 'Penuh' : 'Saya Ikut'),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _iconForCategory(String category) {
  final c = category.toLowerCase();
  if (c.contains('bakti') || c.contains('bersih')) return Icons.cleaning_services;
  if (c.contains('donor')) return Icons.bloodtype;
  if (c.contains('ronda') || c.contains('jaga')) return Icons.shield_moon_outlined;
  if (c.contains('bencana') || c.contains('darurat')) return Icons.volunteer_activism;
  if (c.contains('rapat') || c.contains('musyawarah')) return Icons.groups_2_outlined;
  return Icons.event_outlined;
}

class _ParticipantsProgress extends StatelessWidget {
  final int count;
  final int target;
  const _ParticipantsProgress({required this.count, required this.target});

  @override
  Widget build(BuildContext context) {
    final value = (count / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Peserta'),
            Text('$count / $target orang', style: const TextStyle(color: Colors.black54)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: const Color(0x112563EB),
            color: const Color(0xFF2563EB),
          ),
        ),
      ],
    );
  }
}
