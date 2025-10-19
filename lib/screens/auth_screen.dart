import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user_profile.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isRegister = false;
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (isRegister) {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
        // Optional: set display name
        if (_nameCtrl.text.trim().isNotEmpty) {
          await cred.user?.updateDisplayName(_nameCtrl.text.trim());
        }
        // Create minimal profile in Firestore
        final profile = UserProfile(
          id: cred.user!.uid,
          name: _nameCtrl.text.trim().isEmpty ? 'Warga' : _nameCtrl.text.trim(),
          rt: '-',
          points: 0,
          badges: const [],
        );
        await FirestoreService.instance.upsertProfile(profile);
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      final msg = _translateError(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _translateError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Email tidak valid';
      case 'user-disabled':
        return 'Akun dinonaktifkan';
      case 'user-not-found':
        return 'Pengguna tidak ditemukan';
      case 'wrong-password':
        return 'Kata sandi salah';
      case 'email-already-in-use':
        return 'Email sudah terdaftar';
      case 'weak-password':
        return 'Kata sandi terlalu lemah (min. 6 karakter)';
      case 'operation-not-allowed':
        return 'Metode login ditutup. Cek konsol Firebase';
      default:
        return e.message ?? 'Gagal autentikasi';
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi email untuk reset sandi')),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email reset sandi terkirim')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_translateError(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth >= 720;
            return Row(
              children: [
                if (wide)
                  Expanded(
                    child: _LeftPanel(colors: cs),
                  ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!wide) _BrandHeader(colors: cs),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      isRegister ? 'Daftar Akun' : 'Masuk',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: cs.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    if (isRegister) ...[
                                      TextFormField(
                                        controller: _nameCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'Nama (opsional)',
                                          prefixIcon:
                                              Icon(Icons.person_outline),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    TextFormField(
                                      controller: _emailCtrl,
                                      keyboardType: TextInputType.emailAddress,
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      validator: (v) => (v == null ||
                                              v.trim().isEmpty ||
                                              !v.contains('@'))
                                          ? 'Masukkan email yang valid'
                                          : null,
                                      decoration: const InputDecoration(
                                        labelText: 'Email',
                                        prefixIcon: Icon(Icons.email_outlined),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _passwordCtrl,
                                      obscureText: _obscure,
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      validator: (v) =>
                                          (v == null || v.length < 6)
                                              ? 'Minimal 6 karakter'
                                              : null,
                                      decoration: InputDecoration(
                                        labelText: 'Kata Sandi',
                                        prefixIcon:
                                            const Icon(Icons.lock_outline),
                                        suffixIcon: IconButton(
                                          onPressed: () => setState(
                                              () => _obscure = !_obscure),
                                          icon: Icon(_obscure
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined),
                                        ),
                                      ),
                                    ),
                                    if (isRegister) ...[
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _confirmCtrl,
                                        obscureText: true,
                                        autovalidateMode:
                                            AutovalidateMode.onUserInteraction,
                                        validator: (v) =>
                                            v != _passwordCtrl.text
                                                ? 'Konfirmasi tidak cocok'
                                                : null,
                                        decoration: const InputDecoration(
                                          labelText: 'Konfirmasi Kata Sandi',
                                          prefixIcon:
                                              Icon(Icons.lock_reset_outlined),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    if (!isRegister)
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed:
                                              _loading ? null : _resetPassword,
                                          child: const Text('Lupa kata sandi?'),
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    FilledButton(
                                      onPressed: _loading ? null : _submit,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            if (_loading) ...[
                                              const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white),
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                            Text(isRegister
                                                ? 'Daftar'
                                                : 'Masuk'),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(isRegister
                                            ? 'Sudah punya akun?'
                                            : 'Belum punya akun?'),
                                        TextButton(
                                          onPressed: _loading
                                              ? null
                                              : () => setState(() =>
                                                  isRegister = !isRegister),
                                          child: Text(
                                            isRegister ? 'Masuk' : 'Daftar',
                                            style:
                                                TextStyle(color: cs.secondary),
                                          ),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _FunTips(colors: cs),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LeftPanel extends StatelessWidget {
  final ColorScheme colors;
  const _LeftPanel({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -40,
            right: -20,
            child: _Blob(color: Colors.white.withOpacity(0.15), size: 180),
          ),
          Positioned(
            bottom: -30,
            left: -20,
            child: _Blob(color: Colors.white.withOpacity(0.12), size: 220),
          ),
          Center(child: _BrandHeader(colors: colors, dark: true)),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final ColorScheme colors;
  final bool dark;
  const _BrandHeader({required this.colors, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final titleColor = dark ? Colors.white : colors.primary;
    final subColor = dark ? Colors.white70 : Colors.black54;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: colors.secondary,
              child: const Icon(Icons.handshake, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              'Rukun.ID',
              style: TextStyle(
                color: titleColor,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Gotong royong jadi makin seru!',
          style: TextStyle(color: subColor),
        ),
      ],
    );
  }
}

class _FunTips extends StatelessWidget {
  final ColorScheme colors;
  const _FunTips({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
                child: _Pill(
                    color: colors.tertiary,
                    icon: Icons.military_tech_outlined,
                    text: '+ Poin')),
            const SizedBox(width: 10),
            Expanded(
                child: _Pill(
                    color: colors.primary,
                    icon: Icons.handshake_outlined,
                    text: 'Aksi')),
          ],
        ),
        const SizedBox(height: 10),
        _Pill(
            color: colors.secondary,
            icon: Icons.how_to_vote_outlined,
            text: 'Musyawarah'),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  const _Pill({required this.color, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size),
      ),
    );
  }
}
