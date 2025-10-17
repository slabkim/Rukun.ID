import 'package:flutter/material.dart';
import '../models/action_item.dart';
import '../services/firestore_service.dart';
import '../widgets/action_card.dart';

class ActionsTab extends StatelessWidget {
  const ActionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = FirestoreService.instance;
    return Scaffold(
      body: StreamBuilder<List<ActionItem>>(
        stream: svc.streamActions(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Gagal memuat aksi\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Belum ada aksi. Tambahkan dengan tombol +'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, i) => ActionCard(item: items[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final svc = FirestoreService.instance;
    final tCtrl = TextEditingController();
    final cCtrl = TextEditingController(text: 'Kerja Bakti');
    final lCtrl = TextEditingController(text: 'Balai RT');
    final nCtrl = TextEditingController(text: 'Sapu, Kantong Sampah');
    DateTime? date;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Aksi'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: tCtrl, decoration: const InputDecoration(labelText: 'Judul')),
              TextField(controller: cCtrl, decoration: const InputDecoration(labelText: 'Kategori')),
              TextField(controller: lCtrl, decoration: const InputDecoration(labelText: 'Lokasi')),
              TextField(controller: nCtrl, decoration: const InputDecoration(labelText: 'Kebutuhan')),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Tanggal: '),
                  TextButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: now.subtract(const Duration(days: 1)),
                        lastDate: now.add(const Duration(days: 365)),
                        initialDate: now,
                      );
                      if (picked != null) {
                        date = picked;
                      }
                    },
                    child: const Text('Pilih'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              final item = ActionItem(
                id: 'new',
                title: tCtrl.text.trim().isEmpty ? 'Kerja Bakti' : tCtrl.text.trim(),
                category: cCtrl.text.trim(),
                date: date,
                location: lCtrl.text.trim(),
                needs: nCtrl.text.trim(),
                createdBy: svc.uid,
                participants: const [],
              );
              await svc.createAction(item);
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
