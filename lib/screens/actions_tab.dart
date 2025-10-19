import 'package:flutter/material.dart';
import '../models/action_item.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
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
            return const Center(
                child: Text('Belum ada aksi. Tambahkan dengan tombol +'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => ActionCard(item: items[i]),
          );
        },
      ),
      floatingActionButton: _ScaleFab(
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
    final capCtrl = TextEditingController(text: '10');
    DateTime? date;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Aksi'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: tCtrl,
                  decoration: const InputDecoration(labelText: 'Judul')),
              const SizedBox(height: 16),
              TextField(
                  controller: cCtrl,
                  decoration: const InputDecoration(labelText: 'Kategori')),
              const SizedBox(height: 16),
              TextField(
                  controller: lCtrl,
                  decoration: const InputDecoration(labelText: 'Lokasi')),
              const SizedBox(height: 16),
              TextField(
                  controller: nCtrl,
                  decoration: const InputDecoration(labelText: 'Kebutuhan')),
              const SizedBox(height: 16),
              TextField(
                controller: capCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Kapasitas Peserta'),
              ),
              const SizedBox(height: 16),
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
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              final item = ActionItem(
                id: 'new',
                title: tCtrl.text.trim().isEmpty
                    ? 'Kerja Bakti'
                    : tCtrl.text.trim(),
                category: cCtrl.text.trim(),
                date: date,
                location: lCtrl.text.trim(),
                needs: nCtrl.text.trim(),
                createdBy: svc.uid,
                participants: const [],
                capacity: int.tryParse(capCtrl.text.trim()) ?? 10,
              );
              await svc.createAction(item);
              // Notifikasi lokal untuk aksi baru
              await NotificationService.instance
                  .showNewAction(title: item.title, category: item.category);
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

class _ScaleFab extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  const _ScaleFab({required this.onPressed, required this.child});

  @override
  State<_ScaleFab> createState() => _ScaleFabState();
}

class _ScaleFabState extends State<_ScaleFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
    lowerBound: 0.0,
    upperBound: 0.06,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 88),
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) => _ctrl.reverse(),
        onTapCancel: () => _ctrl.reverse(),
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            final scale = 1 - _ctrl.value;
            return Transform.scale(
              scale: scale,
              child: FloatingActionButton(
                onPressed: widget.onPressed,
                child: widget.child,
              ),
            );
          },
        ),
      ),
    );
  }
}
