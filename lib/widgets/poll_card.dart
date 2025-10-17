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

  @override
  Widget build(BuildContext context) {
    final totalVotes = widget.poll.votes.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.poll.title,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...List.generate(widget.poll.options.length, (i) {
              final option = widget.poll.options[i];
              final votesForOption =
                  widget.poll.votes.values.where((v) => v == i).length;
              final percent = totalVotes == 0
                  ? 0
                  : ((votesForOption / totalVotes) * 100).round();
              return ListTile(
                title: Text(option),
                subtitle: Text('$votesForOption suara • $percent%'),
                leading: Radio<int>(
                  value: i,
                  groupValue: selected,
                  onChanged: (val) => setState(() => selected = val),
                ),
              );
            }),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: selected == null
                    ? null
                    : () async {
                        try {
                          await FirestoreService.instance
                              .vote(widget.poll.id, selected!);
                          if (!mounted) return;
                          SchedulerBinding.instance
                              .addPostFrameCallback((_) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Terima kasih sudah berpartisipasi!'),
                                ),
                              );
                            }
                          });
                        } catch (e) {
                          if (!mounted) return;
                          SchedulerBinding.instance
                              .addPostFrameCallback((_) {
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
          ],
        ),
      ),
    );
  }
}
