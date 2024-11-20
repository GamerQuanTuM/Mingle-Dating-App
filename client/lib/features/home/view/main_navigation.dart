import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_heart/features/home/view/chat_page.dart';
import 'package:social_heart/features/home/view/match_page.dart';
import 'package:social_heart/features/home/view/settings_page.dart';
import 'package:social_heart/features/home/view/home_page.dart';
import 'package:social_heart/core/theme/app_pallete.dart';
import 'package:social_heart/features/home/viewmodel/asset_viewmodel.dart';
import 'package:social_heart/core/utils/socket_io_client.dart';
import 'package:social_heart/core/providers/current_user_notifier.dart';

class MainNavigationPage extends ConsumerStatefulWidget {
  const MainNavigationPage({super.key});

  @override
  ConsumerState<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends ConsumerState<MainNavigationPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const MatchPage(),
    const ChatPage(),
    const SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(currentUserNotifierProvider);

      if (currentUser != null) {
        SocketSingleton.instance.initSocket(currentUser.id);
      }
      ref.read(assetViewmodelProvider.notifier).getUserAsset();
    });
  }

  @override
  void dispose() {
    SocketSingleton.instance.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Pallete.primaryPurple,
        unselectedItemColor: Pallete.secondaryBorder,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 10.0),
              child: Icon(Icons.home),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 10.0),
              child: Icon(Icons.favorite),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 10.0),
              child: Icon(Icons.chat_bubble),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 10.0),
              child: Icon(Icons.person),
            ),
            label: '',
          ),
        ],
      ),
    );
  }
}
