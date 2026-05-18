import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class TVPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String title;

  const TVPlayerPage({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  State<TVPlayerPage> createState() => _TVPlayerPageState();
}

class _TVPlayerPageState extends State<TVPlayerPage> {
  late VideoPlayerController controller;
  final FocusNode focusNode = FocusNode();

  bool showControls = true;
  Timer? hideTimer;
  DateTime lastKeyPress = DateTime.now();

  @override
  void initState() {
    super.initState();

    controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );

    controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      controller.play();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });

    _startHideTimer();
  }

  @override
  void dispose() {
    hideTimer?.cancel();
    focusNode.dispose();
    controller.dispose();
    super.dispose();
  }

  void _startHideTimer() {
    hideTimer?.cancel();
    hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => showControls = false);
      }
    });
  }

  void _showControls() {
    if (!showControls) {
      setState(() => showControls = true);
    }
    _startHideTimer();
  }

  KeyEventResult onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final now = DateTime.now();
    if (now.difference(lastKeyPress) <
        const Duration(milliseconds: 120)) {
      return KeyEventResult.handled;
    }
    lastKeyPress = now;

    _showControls();

    final key = event.logicalKey;

    /// PLAY / PAUSE
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
      final pos = controller.value.position +
          const Duration(seconds: 10);

      final max = controller.value.duration;

      controller.seekTo(
        pos > max ? max : pos,
      );

      return KeyEventResult.handled;
    }

    /// SEEK BACKWARD
    if (key == LogicalKeyboardKey.arrowLeft) {
      final pos = controller.value.position -
          const Duration(seconds: 10);

      controller.seekTo(
        pos < Duration.zero
            ? Duration.zero
            : pos,
      );

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
              child: controller.value.isInitialized
                  ? AspectRatio(
                      aspectRatio:
                          controller.value.aspectRatio,
                      child: VideoPlayer(controller),
                    )
                  : const CircularProgressIndicator(
                      color: Colors.cyan,
                    ),
            ),

            /// CONTROLS
            AnimatedOpacity(
              opacity: showControls ? 1 : 0,
              duration:
                  const Duration(milliseconds: 200),

              child: IgnorePointer(
                ignoring: !showControls,

                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                      colors: [
                        Colors.black.withOpacity(0.9),
                        Colors.transparent,
                      ],
                    ),
                  ),

                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(25),

                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.end,
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// PROGRESS
                          ValueListenableBuilder(
                            valueListenable: controller,
                            builder: (context, value, _) {
                              final pos = value
                                  .position
                                  .inSeconds
                                  .toDouble();

                              final dur = value
                                  .duration
                                  .inSeconds
                                  .toDouble();

                              final progress =
                                  (dur <= 0)
                                      ? 0.0
                                      : pos / dur;

                              return Column(
                                children: [

                                  LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 6,
                                    color: Colors.cyan,
                                    backgroundColor:
                                        Colors.white24,
                                  ),

                                  const SizedBox(height: 10),

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,

                                    children: [
                                      Text(
                                        _fmt(
                                            value.position),
                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.white,
                                        ),
                                      ),

                                      Text(
                                        _fmt(
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

  String _fmt(Duration d) {
    String two(int n) =>
        n.toString().padLeft(2, '0');

    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);

    if (h > 0) {
      return "${two(h)}:${two(m)}:${two(s)}";
    }
    return "${two(m)}:${two(s)}";
  }
}
