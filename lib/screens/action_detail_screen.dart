import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/action_item.dart';
import '../services/firestore_service.dart';

class ActionDetailScreen extends StatelessWidget {
  final ActionItem item;
  const ActionDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final dateStr = item.date != null
        ? DateFormat('EEE, d MMM yyyy').format(item.date!)
        : 'Waktu fleksibel';
    return Scaffold(
      appBar: AppBar(
        actions: [
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
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await FirestoreService.instance.deleteAction(item.id);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'action_title_${item.id}',
              child: Material(
                color: Colors.transparent,
                child: Text(
                  item.title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(avatar: const Icon(Icons.category_outlined, size: 16), label: Text(item.category)),
                Chip(avatar: const Icon(Icons.event_outlined, size: 16), label: Text(dateStr)),
                Chip(avatar: const Icon(Icons.place_outlined, size: 16), label: Text(item.location)),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kebutuhan', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(item.needs),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _ParticipantsProgress(count: item.participants.length, target: item.capacity),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daftar Peserta', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _ParticipantsList(uids: item.participants),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Builder(builder: (context) {
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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

class _ParticipantsList extends StatelessWidget {
  final List<String> uids;
  const _ParticipantsList({required this.uids});

  @override
  Widget build(BuildContext context) {
    if (uids.isEmpty) {
      return const Text('Belum ada peserta.', style: TextStyle(color: Colors.black54));
    }
    return FutureBuilder(
      future: FirestoreService.instance.getProfilesByIds(uids),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: LinearProgressIndicator(minHeight: 2),
          );
        }
        final profiles = (snap.data ?? []) as List<dynamic>;
        return Column(
          children: [
            for (final p in profiles)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: const Color(0x1A2563EB),
                  foregroundColor: const Color(0xFF2563EB),
                  child: Text((p.name as String).isNotEmpty ? (p.name as String).substring(0, 1).toUpperCase() : 'W'),
                ),
                title: Text(p.name),
                subtitle: Text('RT/RW: ${p.rt}'),
              ),
          ],
        );
      },
    );
  }
}
