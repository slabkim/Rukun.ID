import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _Slide(
        icon: Icons.handshake_outlined,
        title: 'Gotong Royong Lebih Mudah',
        desc: 'Gabung aksi warga dan saling bantu antar tetangga.',
      ),
      _Slide(
        icon: Icons.how_to_vote_outlined,
        title: 'Musyawarah Transparan',
        desc: 'Suara Anda penting. Ikut voting dan lihat hasilnya.',
      ),
      _Slide(
        icon: Icons.person_outline,
        title: 'Profil & Poin',
        desc: 'Kumpulkan poin dari partisipasi dan raih lencana.',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _index = i),
                  children: pages,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _index == i ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _index == i
                          ? const Color(0xFF2563EB)
                          : const Color(0x332563EB),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: widget.onDone,
                    child: const Text('Lewati'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      if (_index == pages.length - 1) {
                        widget.onDone();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    child:
                        Text(_index == pages.length - 1 ? 'Mulai' : 'Lanjut'),
                  )
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _Slide({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0x1A2563EB),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(icon, size: 72, color: const Color(0xFF2563EB)),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          desc,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
              ),
        ),
      ],
    );
  }
}

