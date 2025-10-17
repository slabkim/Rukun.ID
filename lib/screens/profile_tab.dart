import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../widgets/poin_badge.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _svc = FirestoreService.instance;
  final _nameCtrl = TextEditingController();
  final _rtCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '-';
    return StreamBuilder<UserProfile>(
      stream: FirebaseAuth.instance.currentUser == null
          ? const Stream<UserProfile>.empty()
          : _svc.streamProfile(),
      builder: (context, snap) {
        if (FirebaseAuth.instance.currentUser == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final profile = snap.data!;
        _nameCtrl.text = profile.name;
        _rtCtrl.text = profile.rt;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(Icons.person_outline),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.name.isEmpty ? 'Warga' : profile.name,
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(user?.email ?? 'ID: $uid',
                            style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Keluar'),
                  )
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _rtCtrl,
                decoration: const InputDecoration(labelText: 'RT/RW'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  PoinBadge(points: profile.points),
                  const SizedBox(width: 12),
                  Text(
                      'Lencana: ${profile.badges.isEmpty ? "-" : profile.badges.join(", ")}'),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final updated = profile.copyWith(
                    name: _nameCtrl.text.trim(),
                    rt: _rtCtrl.text.trim(),
                  );
                  await _svc.upsertProfile(updated);
                  if (!mounted) return;
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profil disimpan')),
                      );
                    }
                  });
                },
                child: const Text('Simpan Profil'),
              ),
              const Spacer(),
              Text(
                'Tips: Ikut aksi (+10 poin) dan berpartisipasi musyawarah (+5 poin).',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        );
      },
    );
  }
}
