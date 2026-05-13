import 'package:flutter/material.dart';
import 'ui/home.dart';
import 'ui/account.dart';
import 'ui/downloads.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: const Color(0xFF0D1117), primaryColor: Colors.red),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _idx = 0;
  final List<Widget> _pages = [const HomePage(), const DownloadPage(), const AccountPage()];

  @override Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        backgroundColor: const Color(0xFF161B22),
        selectedItemColor: Colors.red,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.download), label: 'UNDUHAN'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'AKUN'),
        ],
      ),
    );
  }
}
