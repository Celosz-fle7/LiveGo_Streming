import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import '../api_service.dart';
import 'tv_player.dart';

class TVHomePage extends StatefulWidget {
  const TVHomePage({super.key});

  @override
  State<TVHomePage> createState() => _TVHomePageState();
}

class _TVHomePageState extends State<TVHomePage> {

  List platforms = [
    {'id': 'freereels', 'name': 'FreeReels'},
    {'id': 'shortmax', 'name': 'ShortMax'},
    {'id': 'dramawave', 'name': 'DramaWave'},
    {'id': 'netshort', 'name': 'NetShort'},
  ];

  List activeDramas = [];

  String selectedPlatform = 'freereels';
  bool isLoading = true;

  int focusIndex = 0;

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);

    final res = await ApiService.get(
      "/api/v2/detail?category_p=$selectedPlatform&id=all&lang=id",
    );

    if (res != null && res['data'] != null) {
      setState(() {
        activeDramas =
            res['data']['chapters'] ??
            res['data']['films'] ??
            [];
      });
    }

    setState(() => isLoading = false);
  }

  void _onKey(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    setState(() {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
          focusIndex < activeDramas.length - 1) {
        focusIndex++;
      }

      if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
          focusIndex > 0) {
        focusIndex--;
      }

      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.select) {
        final item = activeDramas[focusIndex];

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TVPlayerPage(
              videoUrl: item['video_url'] ?? '',
              title: item['title'] ?? 'Drama',
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),

      body: RawKeyboardListener(
        focusNode: _focusNode,
        onKey: _onKey,
        child: Row(
          children: [

            // SIDEBAR
            Container(
              width: 80,
              color: const Color(0xFF161B22),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home, color: Colors.white),
                  SizedBox(height: 20),
                  Icon(Icons.movie, color: Colors.white),
                  SizedBox(height: 20),
                  Icon(Icons.favorite, color: Colors.white),
                ],
              ),
            ),

            // CONTENT
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.cyan,
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: activeDramas.length,
                      itemBuilder: (context, i) {
                        final item = activeDramas[i];
                        final focused = i == focusIndex;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: focused
                                  ? Colors.cyan
                                  : Colors.transparent,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: item['cover'] ?? '',
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
