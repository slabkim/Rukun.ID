import 'package:flutter/material.dart';
import 'actions_tab.dart';
import 'polls_tab.dart';
import 'profile_tab.dart';
import 'package:animations/animations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final _pages = const [
    ActionsTab(),
    PollsTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final title = () {
      switch (_index) {
        case 1:
          return const _TitleWithIcon(label: 'Musyawarah', icon: Icons.how_to_vote_outlined);
        case 2:
          return const Text('Profil');
        default:
          return const Text('Aksi');
      }
    }();

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: title,
        centerTitle: true,
      ),
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 300),
        reverse: false,
        transitionBuilder: (child, primaryAnimation, secondaryAnimation) =>
            FadeThroughTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        ),
        child: _pages[_index],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                ),
              ],
            ),
            child: NavigationBar(
              height: 64,
              backgroundColor: Colors.white,
              indicatorColor: const Color(0x1A2563EB),
              selectedIndex: _index,
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.handshake_outlined), label: 'Aksi'),
                NavigationDestination(
                    icon: Icon(Icons.how_to_vote_outlined), label: 'Musyawarah'),
                NavigationDestination(
                    icon: Icon(Icons.person_outline), label: 'Profil'),
              ],
              onDestinationSelected: (i) => setState(() => _index = i),
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleWithIcon extends StatelessWidget {
  final String label;
  final IconData icon;
  const _TitleWithIcon({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF2563EB)),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}
