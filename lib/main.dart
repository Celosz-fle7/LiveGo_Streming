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
    final isTV = MediaQuery.of(context).size.width > 900;
    
    if (isTV) {
      return const TVHomePage();
    } else {
      return const HomePage();
    }
  }
}
