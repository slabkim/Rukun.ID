import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _svc = FirestoreService.instance;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Admin'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                labelText: 'Cari nama/RT',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<UserProfile>>(
              stream: _svc.streamUsers(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final q = _searchCtrl.text.trim().toLowerCase();
                final users = (snap.data ?? [])
                    .where((u) => q.isEmpty ||
                        u.name.toLowerCase().contains(q) ||
                        u.rt.toLowerCase().contains(q))
                    .toList();
                if (users.isEmpty) {
                  return const Center(child: Text('Tidak ada data'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final u = users[i];
                    final isAdmin = u.badges.contains('Admin');
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0x1A2563EB),
                        foregroundColor: const Color(0xFF2563EB),
                        child: Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : 'W'),
                      ),
                      title: Text(u.name),
                      subtitle: Text('RT/RW: ${u.rt}  •  Poin: ${u.points}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Admin'),
                          const SizedBox(width: 8),
                          Switch(
                            value: isAdmin,
                            onChanged: (val) async {
                              await _svc.setUserAdmin(u.id, val);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

