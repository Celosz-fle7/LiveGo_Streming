import 'package:flutter/material.dart';
import 'ui/home.dart';
import 'ui/account.dart';
import 'ui/downloads.dart';
import 'ui/search_screen.dart';
import 'ui/history_screen.dart';
import 'ui/tv/tv_home.dart';
import 'ui/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LiveGO',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        primaryColor: const Color(0xFF4F46E5),
      ),
      home: const DeviceWrapper(),
      routes: {
        '/history': (context) => const HistoryScreen(),
        '/search': (context) => const SearchScreen(),
        '/download': (context) => const DownloadPage(),
        '/profile': (context) => const AccountPage(),
      },
    );
  }
}

class DeviceWrapper extends StatelessWidget {
  const DeviceWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        
        // 🔥 TV MODE DETECTION (STABLE)
        final isTV = constraints.maxWidth > 900;

        return isTV
            ? const TVHomePage()
            : const MainPage();
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _idx = 0;

  final List<Widget> _pages = const [
    HomePage(),
    HistoryScreen(),
    SearchScreen(),
    DownloadPage(),
    AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _idx,
        children: _pages,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'HOME',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'HISTORY',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.download),
            label: 'DOWNLOAD',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'AKUN',
          ),
        ],
      ),
    );
  }
}
