class TVPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String title;

  const TVPlayerPage({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  State<TVPlayerPage> createState() =>
      _TVPlayerPageState();
}

class _TVPlayerPageState
    extends State<TVPlayerPage> {

  late VideoPlayerController controller;

  final FocusNode focusNode = FocusNode();

  bool showControls = true;

  Timer? hideTimer;

  DateTime? lastKeyPress;

  @override
  void initState() {
    super.initState();

    controller =
        VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );

    controller.initialize().then((_) {
      setState(() {});
      controller.play();
    });

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      focusNode.requestFocus();
    });

    startHideTimer();
  }

  @override
  void dispose() {
    hideTimer?.cancel();
    focusNode.dispose();
    controller.dispose();
    super.dispose();
  }

  void startHideTimer() {
    hideTimer?.cancel();

    hideTimer = Timer(
      const Duration(seconds: 5),
      () {
        if (mounted) {
          setState(() {
            showControls = false;
          });
        }
      },
    );
  }

  void showOverlay() {
    if (!showControls) {
      setState(() {
        showControls = true;
      });
    }

    startHideTimer();
  }

  KeyEventResult onKey(
    FocusNode node,
    KeyEvent event,
  ) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    /// DEBOUNCE
    final now = DateTime.now();

    if (lastKeyPress != null &&
        now.difference(lastKeyPress!) <
            const Duration(milliseconds: 120)) {
      return KeyEventResult.handled;
    }

    lastKeyPress = now;

    showOverlay();

    final key = event.logicalKey;

    /// PLAY PAUSE
    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter) {

      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }

      setState(() {});

      return KeyEventResult.handled;
    }

    /// SEEK FORWARD
    if (key == LogicalKeyboardKey.arrowRight) {

      final pos =
          controller.value.position +
              const Duration(seconds: 10);

      controller.seekTo(pos);

      return KeyEventResult.handled;
    }

    /// SEEK BACK
    if (key == LogicalKeyboardKey.arrowLeft) {

      final pos =
          controller.value.position -
              const Duration(seconds: 10);

      controller.seekTo(pos);

      return KeyEventResult.handled;
    }

    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,

      body: Focus(
        focusNode: focusNode,
        onKeyEvent: onKey,

        child: Stack(
          children: [

            /// VIDEO
            Center(
              child:
                  controller.value.isInitialized
                      ? AspectRatio(
                          aspectRatio:
                              controller
                                  .value
                                  .aspectRatio,

                          child: VideoPlayer(
                            controller,
                          ),
                        )
                      : const CircularProgressIndicator(),
            ),

            /// CONTROLS
            AnimatedOpacity(
              opacity:
                  showControls ? 1 : 0,

              duration:
                  const Duration(
                      milliseconds: 200),

              child: IgnorePointer(
                ignoring: !showControls,

                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin:
                          Alignment.bottomCenter,
                      end: Alignment.center,

                      colors: [
                        Colors.black
                            .withOpacity(0.9),
                        Colors.transparent,
                      ],
                    ),
                  ),

                  child: SafeArea(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(30),

                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.end,

                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          Text(
                            widget.title,

                            style:
                                const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// PROGRESS
                          ValueListenableBuilder(
                            valueListenable:
                                controller,

                            builder:
                                (context, value, _) {

                              final pos =
                                  value.position
                                      .inSeconds
                                      .toDouble();

                              final dur =
                                  value.duration
                                      .inSeconds
                                      .toDouble();

                              return Column(
                                children: [

                                  LinearProgressIndicator(
                                    value: dur <= 0
                                        ? 0
                                        : pos / dur,

                                    minHeight: 6,

                                    color:
                                        Colors.cyan,

                                    backgroundColor:
                                        Colors.white24,
                                  ),

                                  const SizedBox(
                                      height: 12),

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,

                                    children: [

                                      Text(
                                        formatTime(
                                            value.position),

                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.white,
                                        ),
                                      ),

                                      Text(
                                        formatTime(
                                            value.duration),

                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatTime(Duration d) {

    String two(int n) =>
        n.toString().padLeft(2, '0');

    final h = two(d.inHours);

    final m = two(d.inMinutes.remainder(60));

    final s = two(d.inSeconds.remainder(60));

    if (h == '00') {
      return "$m:$s";
    }

    return "$h:$m:$s";
  }
}
