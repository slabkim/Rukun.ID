import 'package:flutter/material.dart';
import '../models/poll.dart';
import '../services/firestore_service.dart';
import '../widgets/poll_card.dart';

class PollsTab extends StatelessWidget {
  const PollsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = FirestoreService.instance;
    return Scaffold(
      body: StreamBuilder<List<Poll>>(
        stream: svc.streamPolls(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Gagal memuat musyawarah\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final polls = snapshot.data ?? [];
          if (polls.isEmpty) {
            return const Center(child: Text('Belum ada musyawarah. Tambahkan dengan tombol +'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: polls.length,
            itemBuilder: (context, i) => PollCard(poll: polls[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePollDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreatePollDialog(BuildContext context) {
    final svc = FirestoreService.instance;
    final tCtrl = TextEditingController();
    final o1 = TextEditingController(text: 'Minggu 07.00');
    final o2 = TextEditingController(text: 'Minggu 16.00');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Musyawarah (Poll)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: tCtrl, decoration: const InputDecoration(labelText: 'Judul')),
              TextField(controller: o1, decoration: const InputDecoration(labelText: 'Opsi 1')),
              TextField(controller: o2, decoration: const InputDecoration(labelText: 'Opsi 2')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              final poll = Poll(
                id: 'new',
                title: tCtrl.text.trim().isEmpty ? 'Jadwal Kerja Bakti' : tCtrl.text.trim(),
                options: [o1.text.trim(), o2.text.trim()],
                votes: const {},
                closesAt: null,
              );
              await svc.createPoll(poll);
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
