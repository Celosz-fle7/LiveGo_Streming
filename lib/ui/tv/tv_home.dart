class _TVHomePageState extends State<TVHomePage> {
  final FocusNode _focusNode = FocusNode();

  // HANYA 1 PLATFORM
  final Map<String, dynamic> platform = {
    'id': 'freereels',
    'name': 'FreeReels'
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
          setState(() {
            dramaFocusIndex = -1;
          });
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
