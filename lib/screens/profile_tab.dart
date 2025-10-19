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

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF0F5FF), Colors.transparent],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    StreamBuilder<bool>(
                      stream: _svc.streamIsAdmin(),
                      builder: (context, snap) {
                        final isAdmin = snap.data == true;
                        if (!isAdmin) return const SizedBox.shrink();
                        return OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/admin');
                          },
                          icon: const Icon(Icons.admin_panel_settings_outlined),
                          label: const Text('Panel Admin'),
                        );
                      },
                    ),
                    const Spacer(),
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
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF93C5FD), Color(0xFF2563EB)],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Text(
                        (profile.name.isNotEmpty ? profile.name[0] : 'W'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 28,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Column(
                    children: [
                      Text(
                        profile.name.isEmpty ? 'Warga' : profile.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(user?.email ?? 'ID: $uid',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PoinBadge(points: profile.points),
                    const SizedBox(width: 12),
                    _badgeForPoints(profile.points),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Informasi Profil',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _nameCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Nama Lengkap'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _rtCtrl,
                          decoration: const InputDecoration(labelText: 'RT/RW'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ElevatedButton(
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
                          const SnackBar(content: Text('Profil berhasil disimpan')),
                        );
                      }
                    });
                  },
                  child: const Text('Simpan Profil'),
              ),
                const Spacer(),
                Text(
                  'Tips: Ikut aksi (+10 poin) dan berpartisipasi musyawarah (+5 poin).',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget _badgeForPoints(int points) {
  String label;
  Color color;
  if (points > 200) {
    label = 'Gold';
    color = const Color(0xFFFFC107);
  } else if (points < 100) {
    label = 'Bronze';
    color = const Color(0xFFCD7F32);
  } else {
    label = 'Silver';
    color = const Color(0xFFC0C0C0);
  }
  return Chip(
    avatar: const Icon(Icons.military_tech_outlined, size: 16),
    label: Text(label),
    backgroundColor: color.withOpacity(0.2),
    side: BorderSide(color: color.withOpacity(0.6)),
  );
}
