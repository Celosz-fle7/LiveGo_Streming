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

  // Hanya 1 platform untuk testing
  final String selectedPlatform = 'freereels';

  List<dynamic> dramas = [];

  bool isLoading = true;
  int focusedIndex = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });

    _loadData();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    final res = await ApiService.get(
      '/api/v2/home?category_p=$selectedPlatform&lang=id',
    );

    if (!mounted) return;

    if (res != null && res['success'] == true && res['data'] != null) {
      final data = res['data'];

      List<dynamic> items = [];

      if (data is List) {
        items = data;
      } else if (data is Map) {
        items =
            data['films'] ??
            data['list'] ??
            data['items'] ??
            data['chapters'] ??
            [];
      }

      setState(() {
        dramas = items.take(30).toList();
        isLoading = false;
        focusedIndex = 0;
      });
    } else {
      setState(() {
        dramas = [];
        isLoading = false;
      });
    }
  }

  void _restoreFocus() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted && !_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  void _onKey(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    if (isLoading || dramas.isEmpty) return;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowRight) {
      if (focusedIndex < dramas.length - 1) {
        setState(() => focusedIndex++);
      }
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      if (focusedIndex > 0) {
        setState(() => focusedIndex--);
      }
    } else if (key == LogicalKeyboardKey.arrowDown) {
      if (focusedIndex + 5 < dramas.length) {
        setState(() => focusedIndex += 5);
      }
    } else if (key == LogicalKeyboardKey.arrowUp) {
      if (focusedIndex - 5 >= 0) {
        setState(() => focusedIndex -= 5);
      }
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select) {
      final drama = dramas[focusedIndex];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TVPlayerPage(
            id: drama['id'].toString(),
            source: selectedPlatform,
            title: drama['title'] ?? 'Drama',
          ),
        ),
      ).then((_) {
        _restoreFocus();
      });
    }

    _restoreFocus();
  }

  Widget _buildCard(dynamic drama, bool focused) {
    final imageUrl =
        drama['cover'] ??
        drama['thumbnail'] ??
        drama['image'] ??
        '';

    final title = drama['title'] ?? 'No Title';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: focused
              ? const Color(0xFF06B6D4)
              : Colors.transparent,
          width: 3,
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: const Color(0xFF06B6D4).withOpacity(0.4),
                  blurRadius: 12,
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              memCacheWidth: 300,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              placeholder: (_, __) => Container(
                color: Colors.grey.shade900,
              ),
              errorWidget: (_, __, ___) => Container(
                color: Colors.grey.shade900,
                child: const Icon(
                  Icons.movie,
                  color: Colors.white30,
                  size: 40,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                color: Colors.black54,
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
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
          onKey: _onKey,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CineFlow TV',
                  style: TextStyle(
                    color: Color(0xFF06B6D4),
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Platform: FreeReels',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF06B6D4),
                          ),
                        )
                      : dramas.isEmpty
                          ? const Center(
                              child: Text(
                                'Tidak ada data',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 20,
                                ),
                              ),
                            )
                          : GridView.builder(
                              cacheExtent: 1000,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 5,
                                childAspectRatio: 0.65,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: dramas.length,
                              itemBuilder: (context, index) {
                                return _buildCard(
                                  dramas[index],
                                  focusedIndex == index,
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
