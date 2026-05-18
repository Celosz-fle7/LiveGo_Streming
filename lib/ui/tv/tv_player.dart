import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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

  @override
  void initState() {
    super.initState();

    WakelockPlus.enable();

    controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );

    controller.initialize().then((_) {
      setState(() {});
      controller.play();
    });

    focusNode.requestFocus();

    _startHideTimer();
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
    setState(() => showControls = true);
    _startHideTimer();
  }

  void _onKey(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    _showControls();

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter) {
      controller.value.isPlaying
          ? controller.pause()
          : controller.play();
    }

    if (key == LogicalKeyboardKey.arrowRight) {
      controller.seekTo(
        controller.value.position + const Duration(seconds: 10),
      );
    }

    if (key == LogicalKeyboardKey.arrowLeft) {
      controller.seekTo(
        controller.value.position - const Duration(seconds: 10),
      );
    }

    setState(() {});
  }

  @override
  void dispose() {
    hideTimer?.cancel();
    focusNode.dispose();
    controller.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: Focus(
        focusNode: focusNode,
        onKeyEvent: (node, event) {
          _onKey(event);
          return KeyEventResult.handled;
        },

        child: Stack(
          children: [

            // VIDEO
            Center(
              child: controller.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: VideoPlayer(controller),
                    )
                  : const CircularProgressIndicator(),
            ),

            // CONTROLS
            AnimatedOpacity(
              opacity: showControls ? 1 : 0,
              duration: const Duration(milliseconds: 200),

              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),

                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        ValueListenableBuilder(
                          valueListenable: controller,
                          builder: (context, VideoPlayerValue value, _) {

                            final pos = value.position.inSeconds.toDouble();
                            final dur = value.duration.inSeconds.toDouble();

                            return Column(
                              children: [

                                LinearProgressIndicator(
                                  value: dur == 0 ? 0 : pos / dur,
                                  color: Colors.cyan,
                                  backgroundColor: Colors.white24,
                                ),

                                const SizedBox(height: 8),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _format(value.position),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    Text(
                                      _format(value.duration),
                                      style: const TextStyle(color: Colors.white),
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
          ],
        ),
      ),
    );
  }

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inMinutes)}:${two(d.inSeconds.remainder(60))}";
  }
}
