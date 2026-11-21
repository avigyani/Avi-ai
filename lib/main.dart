// Avi AI v1 — Flutter app for Abhi.
// Unified manual-mode inbox: WhatsApp / Instagram / Facebook / GBP.
// AI drafts from Abhi's training, Abhi approves, Abhi sends himself.
// Nothing auto-sends. No storage / file access.
import 'package:flutter/material.dart';

import 'screens.dart';
import 'store.dart';

void main() {
  runApp(const AviAiApp());
}

class AviAiApp extends StatelessWidget {
  const AviAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Avi AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7B1E26),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF9EF),
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final AviStore store = AviStore();
  int index = 0;

  @override
  void initState() {
    super.initState();
    store.load();
    store.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!store.loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final pages = <Widget>[
      InboxScreen(store: store),
      ComposeScreen(store: store, onAdded: () => setState(() => index = 0)),
      TrainScreen(store: store),
      ProfilesScreen(store: store),
      SettingsScreen(store: store),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avi AI',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: Center(
              child: Text('ಅವಿ AI',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(
          key: ValueKey(index),
          child: pages[index],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.inbox_outlined),
              selectedIcon: Icon(Icons.inbox),
              label: 'Inbox'),
          NavigationDestination(
              icon: Icon(Icons.paste_outlined),
              selectedIcon: Icon(Icons.paste),
              label: 'Paste'),
          NavigationDestination(
              icon: Icon(Icons.school_outlined),
              selectedIcon: Icon(Icons.school),
              label: 'Train'),
          NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Profiles'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
      ),
    );
  }
}
