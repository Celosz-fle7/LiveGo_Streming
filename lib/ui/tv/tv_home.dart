import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../api_service.dart';
import 'tv_player.dart';

class TVHomePage extends StatefulWidget {
  const TVHomePage({super.key});

  @override
  State<TVHomePage> createState() => _TVHomePageState();
}

class _TVHomePageState extends State<TVHomePage> {
  final FocusNode _focusNode = FocusNode();

  final Map<String, dynamic> platform = {
    'id': 'freereels',
    'name': 'FreeReels',
  };

  List<Map<String, dynamic>> sidebarMenus = [
    {'id': 'beranda', 'name': 'Beranda', 'icon': Icons.home},
    {'id': 'unduhan', 'name': 'Unduhan', 'icon': Icons.download},
    {'id': 'riwayat', 'name': 'Riwayat', 'icon': Icons.history},
    {'id': 'favorit', 'name': 'Favorit', 'icon': Icons.favorite},
    {'id': 'akun', 'name': 'Akun', 'icon': Icons.person},
  ];

  List<dynamic> activeDramas = [];

  String selectedMenu = 'beranda';
  String selectedPlatform = 'freereels';

  bool isSidebarExpanded = false;
  bool isLoading = true;

  int sidebarFocusIndex = 0;
  int dramaFocusIndex = -1;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });

    _fetchTVData();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchTVData() async {
    setState(() => isLoading = true);

    final res = await ApiService.get(
      "/api/v2/detail?category_p=$selectedPlatform&id=all&lang=id",
    );

    if (!mounted) return;

    if (res != null && res['success'] == true && res['data'] != null) {
      setState(() {
        activeDramas =
            res['data']['chapters'] ??
            res['data']['films'] ??
            [];
        isLoading = false;
      });
    } else {
      setState(() {
        activeDramas = [];
        isLoading = false;
      });
    }
  }

  void _restoreFocus() {
    Future.delayed(const Duration(milliseconds: 30), () {
      if (mounted && !_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    final key = event.logicalKey;

    if (isSidebarExpanded) {
      if (key == LogicalKeyboardKey.arrowDown &&
          sidebarFocusIndex < sidebarMenus.length - 1) {
        setState(() => sidebarFocusIndex++);
      } else if (key == LogicalKeyboardKey.arrowUp &&
          sidebarFocusIndex > 0) {
        setState(() => sidebarFocusIndex--);
      } else if (key == LogicalKeyboardKey.arrowRight ||
          key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.select) {
        setState(() {
          selectedMenu = sidebarMenus[sidebarFocusIndex]['id'];
          isSidebarExpanded = false;
        });
      }

      _restoreFocus();
      return;
    }

    if (dramaFocusIndex != -1) {
      if (key == LogicalKeyboardKey.arrowRight &&
          dramaFocusIndex < activeDramas.length - 1) {
        setState(() => dramaFocusIndex++);
      } else if (key == LogicalKeyboardKey.arrowLeft) {
        if (dramaFocusIndex % 6 == 0) {
          setState(() {
            isSidebarExpanded = true;
            dramaFocusIndex = -1;
          });
        } else {
          setState(() => dramaFocusIndex--);
        }
      } else if (key == LogicalKeyboardKey.arrowUp) {
        if (dramaFocusIndex < 6) {
          setState(() => dramaFocusIndex = -1);
        } else {
          setState(() => dramaFocusIndex -= 6);
        }
      } else if (key == LogicalKeyboardKey.arrowDown &&
          dramaFocusIndex + 6 < activeDramas.length) {
        setState(() => dramaFocusIndex += 6);
      } else if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.select) {
        final drama = activeDramas[dramaFocusIndex];

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TVPlayerPage(
              id: drama['id'].toString(),
              source: selectedPlatform,
              title: drama['title'] ?? 'Drama TV',
            ),
          ),
        ).then((_) => _restoreFocus());
      }

      _restoreFocus();
    }
  }

  Widget _buildPoster(dynamic drama, bool isFocused) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFocused ? const Color(0xFF06B6D4) : Colors.transparent,
          width: 2,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFF06B6D4).withOpacity(0.4),
                  blurRadius: 10,
                )
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedNetworkImage(
          imageUrl: drama['cover'] ?? '',
          fit: BoxFit.cover,
          placeholder: (c, u) => Container(color: Colors.white12),
          errorWidget: (c, u, e) => Container(
            color: Colors.white24,
            child: const Icon(Icons.movie, color: Colors.white30),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: RawKeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKey: _handleKeyEvent,
          child: Row(
            children: [
              // SIDEBAR
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSidebarExpanded ? 220 : 70,
                color: const Color(0xFF161B22),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'CineFlow',
                      style: TextStyle(
                        color: Color(0xFF06B6D4),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),

                    Expanded(
                      child: ListView.builder(
                        itemCount: sidebarMenus.length,
                        itemBuilder: (context, i) {
                          final item = sidebarMenus[i];
                          final focused = sidebarFocusIndex == i && isSidebarExpanded;
                          final selected = selectedMenu == item['id'];

                          return Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: focused
                                  ? const Color(0xFF06B6D4)
                                  : selected
                                      ? Colors.white10
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: Icon(
                                item['icon'],
                                color: Colors.white,
                              ),
                              title: isSidebarExpanded
                                  ? Text(item['name'],
                                      style:
                                          const TextStyle(color: Colors.white))
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // MAIN
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Expanded(
                        child: selectedMenu != 'beranda'
                            ? const Center(
                                child: Text(
                                  'Menu kosong',
                                  style: TextStyle(color: Colors.white38),
                                ),
                              )
                            : isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                        color: Color(0xFF06B6D4)),
                                  )
                                : GridView.builder(
                                    itemCount: activeDramas.length,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 6,
                                      childAspectRatio: 0.7,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                    itemBuilder: (context, i) {
                                      final drama = activeDramas[i];
                                      return _buildPoster(
                                        drama,
                                        dramaFocusIndex == i,
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
