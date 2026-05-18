class TVHomePage extends StatefulWidget {
  const TVHomePage({super.key});

  @override
  State<TVHomePage> createState() => _TVHomePageState();
}

class _TVHomePageState extends State<TVHomePage> {
  final FocusNode _focusNode = FocusNode();

  List platforms = [
    {'id': 'freereels', 'name': 'FreeReels'},
    {'id': 'shortmax', 'name': 'ShortMax'},
    {'id': 'dramawave', 'name': 'DramaWave'},
    {'id': 'netshort', 'name': 'NetShort'}
  ];

  List activeDramas = [];

  List sidebarMenus = [
    {'id': 'beranda', 'name': 'Beranda', 'icon': Icons.home},
    {'id': 'unduhan', 'name': 'Unduhan', 'icon': Icons.download},
    {'id': 'riwayat', 'name': 'Riwayat', 'icon': Icons.history},
    {'id': 'favorit', 'name': 'Favorit', 'icon': Icons.favorite},
    {'id': 'akun', 'name': 'Akun', 'icon': Icons.person},
  ];

  String selectedMenu = 'beranda';
  String selectedPlatform = 'freereels';

  bool isSidebarExpanded = false;
  bool isLoading = true;

  int sidebarFocusIndex = 0;
  int platformFocusIndex = 0;
  int dramaFocusIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    final res = await ApiService.get(
      "/api/v2/detail?category_p=$selectedPlatform&id=all&lang=id",
    );

    if (res != null && res['success'] == true) {
      setState(() {
        activeDramas =
            res['data']['chapters'] ?? res['data']['films'] ?? [];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  void _onKey(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    final key = event.logicalKey;

    setState(() {
      // LEFT → sidebar
      if (key == LogicalKeyboardKey.arrowLeft) {
        isSidebarExpanded = true;
      }

      // RIGHT → content
      if (key == LogicalKeyboardKey.arrowRight) {
        isSidebarExpanded = false;
      }

      // SIDEBAR NAV
      if (isSidebarExpanded) {
        if (key == LogicalKeyboardKey.arrowDown &&
            sidebarFocusIndex < sidebarMenus.length - 1) {
          sidebarFocusIndex++;
        }

        if (key == LogicalKeyboardKey.arrowUp &&
            sidebarFocusIndex > 0) {
          sidebarFocusIndex--;
        }

        if (key == LogicalKeyboardKey.select ||
            key == LogicalKeyboardKey.enter) {
          selectedMenu =
              sidebarMenus[sidebarFocusIndex]['id'];
          isSidebarExpanded = false;
        }
      }

      // PLATFORM NAV
      if (!isSidebarExpanded) {
        if (key == LogicalKeyboardKey.arrowRight &&
            platformFocusIndex < platforms.length - 1) {
          platformFocusIndex++;
        }

        if (key == LogicalKeyboardKey.arrowLeft &&
            platformFocusIndex > 0) {
          platformFocusIndex--;
        }

        if (key == LogicalKeyboardKey.select ||
            key == LogicalKeyboardKey.enter) {
          selectedPlatform =
              platforms[platformFocusIndex]['id'];
          _loadData();
        }

        if (key == LogicalKeyboardKey.arrowDown) {
          dramaFocusIndex = 0;
        }
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSidebarExpanded ? 220 : 70,
              color: const Color(0xFF161B22),

              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "LiveGO TV",
                    style: TextStyle(
                      color: Color(0xFF06B6D4),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Expanded(
                    child: ListView.builder(
                      itemCount: sidebarMenus.length,
                      itemBuilder: (c, i) {
                        final focused =
                            isSidebarExpanded &&
                            sidebarFocusIndex == i;

                        return Container(
                          margin: const EdgeInsets.all(6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: focused
                                ? const Color(0xFF06B6D4)
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          child: Icon(
                            sidebarMenus[i]['icon'],
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // CONTENT
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF06B6D4),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: activeDramas.length,
                      itemBuilder: (c, i) {
                        final item = activeDramas[i];

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(10),
                            border: Border.all(
                              color: i == dramaFocusIndex
                                  ? const Color(0xFF06B6D4)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(10),
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
