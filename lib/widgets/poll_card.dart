import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/poll.dart';
import '../services/firestore_service.dart';

class PollCard extends StatefulWidget {
  final Poll poll;
  const PollCard({super.key, required this.poll});

  @override
  State<PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<PollCard> {
  int? selected;
  bool _showing = false;

  @override
  Widget build(BuildContext context) {
    final totalVotes = widget.poll.votes.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.poll.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                StreamBuilder<bool>(
                  stream: FirestoreService.instance.streamIsAdmin(),
                  builder: (context, snap) {
                    final isAdmin = snap.data == true;
                    if (!isAdmin) return const SizedBox.shrink();
                    return IconButton(
                      tooltip: 'Hapus Poll',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Hapus Poll?'),
                            content: Text('Anda akan menghapus "${widget.poll.title}"'),
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
                          await FirestoreService.instance.deletePoll(widget.poll.id);
                        }
                      },
                    );
                  },
                )
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(widget.poll.options.length, (i) {
              final option = widget.poll.options[i];
              final votesForOption =
                  widget.poll.votes.values.where((v) => v == i).length;
              final ratio = totalVotes == 0 ? 0.0 : votesForOption / totalVotes;
              final isSelected = selected == i;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => setState(() => selected = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0x1A2563EB)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : Colors.black12,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(option,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w400)),
                            ),
                            Text('${(ratio * 100).round()}%',
                                style: const TextStyle(color: Colors.black54)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LayoutBuilder(
                          builder: (context, c) {
                            final w = c.maxWidth;
                            return Stack(
                              children: [
                                Container(
                                  height: 8,
                                  width: w,
                                  decoration: BoxDecoration(
                                    color: const Color(0x112563EB),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOut,
                                  height: 8,
                                  width: w * ratio,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: selected == null
                    ? null
                    : () async {
                        try {
                          await FirestoreService.instance
                              .vote(widget.poll.id, selected!);
                          if (!mounted) return;
                          SchedulerBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Terima kasih sudah berpartisipasi!'),
                                ),
                              );
                            }
                          });
                        } catch (e) {
                          if (!mounted) return;
                          SchedulerBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Gagal mengirim suara: $e'),
                                ),
                              );
                            }
                          });
                        }
                      },
                child: const Text('Kirim Suara'),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _showing
                    ? null
                    : () async {
                        setState(() => _showing = true);
                        await _showParticipantsBottomSheet(context);
                        if (mounted) setState(() => _showing = false);
                      },
                icon: const Icon(Icons.people_outline),
                label: const Text('Lihat Partisipan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showParticipantsBottomSheet(BuildContext context) async {
    final votes = widget.poll.votes;
    final allUids = votes.keys.toList();
    final profiles = await FirestoreService.instance.getProfilesByIds(allUids);
    final nameByUid = {for (final p in profiles) p.id: p.name};
    final grouped = <int, List<String>>{};
    votes.forEach((uid, idx) {
      final i = idx;
      grouped.putIfAbsent(i, () => []);
      grouped[i]!.add(nameByUid[uid] ?? uid.substring(0, 6));
    });

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: ListView(
            children: [
              Text('Partisipan',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              for (var i = 0; i < widget.poll.options.length; i++) ...[
                Text(widget.poll.options[i],
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 6),
                if ((grouped[i] ?? const []).isEmpty)
                  const Text('Belum ada', style: TextStyle(color: Colors.black54))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final name in grouped[i]!)
                        Chip(
                          avatar: const Icon(Icons.person_outline, size: 16),
                          label: Text(name),
                        )
                    ],
                  ),
                const SizedBox(height: 12),
              ]
            ],
          ),
        );
      },
    );
  }
}
