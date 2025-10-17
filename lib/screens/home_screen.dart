import 'package:flutter/material.dart';
import 'actions_tab.dart';
import 'polls_tab.dart';
import 'profile_tab.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rukun.ID'),
        centerTitle: true,
      ),
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.handshake_outlined), label: 'Aksi'),
          NavigationDestination(icon: Icon(Icons.how_to_vote_outlined), label: 'Musyawarah'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
        onDestinationSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}
