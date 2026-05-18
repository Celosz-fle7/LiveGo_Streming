import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const TVApp());
}

class TVApp extends StatelessWidget {
  const TVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const TVHomePage(),
    );
  }
}

class TVHomePage extends StatefulWidget {
  const TVHomePage({super.key});

  @override
  State<TVHomePage> createState() => _TVHomePageState();
}

class _TVHomePageState extends State<TVHomePage> {
  final List<String> categories = [
    "Trending",
    "Action",
    "Drama",
    "Comedy",
  ];

  final List<List<String>> posters = List.generate(
    4,
    (_) => List.generate(
      12,
      (index) =>
          "https://picsum.photos/300/450?random=${index + 1}",
    ),
  );

  int sidebarIndex = 0;
  int rowIndex = 0;
  int colIndex = 0;

  bool sidebarFocused = false;

  late FocusNode _focusNode;

  final List<String> menus = [
    "Home",
    "Movies",
    "Series",
    "Favorites",
    "Settings"
  ];

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void handleKey(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    final key = event.logicalKey;

    setState(() {
      if (sidebarFocused) {
        /// SIDEBAR
        if (key == LogicalKeyboardKey.arrowDown &&
            sidebarIndex < menus.length - 1) {
          sidebarIndex++;
        }

        else if (key == LogicalKeyboardKey.arrowUp &&
            sidebarIndex > 0) {
          sidebarIndex--;
        }

        else if (key == LogicalKeyboardKey.arrowRight) {
          sidebarFocused = false;
        }

        return;
      }

      /// CONTENT
      if (key == LogicalKeyboardKey.arrowRight &&
          colIndex < posters[rowIndex].length - 1) {
        colIndex++;
      }

      else if (key == LogicalKeyboardKey.arrowLeft) {
        if (colIndex == 0) {
          sidebarFocused = true;
        } else {
          colIndex--;
        }
      }

      else if (key == LogicalKeyboardKey.arrowDown &&
          rowIndex < categories.length - 1) {
        rowIndex++;

        if (colIndex >= posters[rowIndex].length) {
          colIndex = posters[rowIndex].length - 1;
        }
      }

      else if (key == LogicalKeyboardKey.arrowUp &&
          rowIndex > 0) {
        rowIndex--;
      }

      else if (key == LogicalKeyboardKey.select ||
          key == LogicalKeyboardKey.enter) {

        final movie =
            "Row: $rowIndex  Col: $colIndex";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(movie)),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),

      body: RawKeyboardListener(
        focusNode: _focusNode,
        onKey: handleKey,

        child: Row(
          children: [

            /// SIDEBAR
            Container(
              width: 90,
              color: const Color(0xFF11161D),

              child: Column(
                children: [

                  const SizedBox(height: 40),

                  const Icon(
                    Icons.live_tv,
                    color: Colors.cyan,
                    size: 36,
                  ),

                  const SizedBox(height: 40),

                  ...List.generate(
                    menus.length,
                    (index) {

                      final focused =
                          sidebarFocused &&
                          sidebarIndex == index;

                      return AnimatedContainer(
                        duration:
                            const Duration(milliseconds: 150),

                        margin: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 10,
                        ),

                        height: 60,

                        decoration: BoxDecoration(
                          color: focused
                              ? Colors.cyan
                              : Colors.transparent,

                          borderRadius:
                              BorderRadius.circular(14),

                          boxShadow: focused
                              ? [
                                  BoxShadow(
                                    color: Colors.cyan
                                        .withOpacity(0.7),
                                    blurRadius: 18,
                                    spreadRadius: 1,
                                  )
                                ]
                              : [],
                        ),

                        child: Icon(
                          [
                            Icons.home,
                            Icons.movie,
                            Icons.tv,
                            Icons.favorite,
                            Icons.settings,
                          ][index],
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            /// CONTENT
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(30),
                itemCount: categories.length,

                itemBuilder: (context, rIndex) {

                  return Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Text(
                        categories[rIndex],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        height: 250,

                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,

                          itemCount:
                              posters[rIndex].length,

                          itemBuilder: (context, cIndex) {

                            final focused =
                                !sidebarFocused &&
                                rowIndex == rIndex &&
                                colIndex == cIndex;

                            return RepaintBoundary(
                              child: AnimatedScale(
                                scale:
                                    focused ? 1.08 : 1.0,

                                duration:
                                    const Duration(
                                        milliseconds: 140),

                                child: AnimatedContainer(
                                  duration:
                                      const Duration(
                                          milliseconds:
                                              140),

                                  width: 160,

                                  margin:
                                      const EdgeInsets.only(
                                          right: 18),

                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(
                                            14),

                                    boxShadow: focused
                                        ? [
                                            BoxShadow(
                                              color: Colors
                                                  .cyan
                                                  .withOpacity(
                                                      0.9),
                                              blurRadius: 25,
                                              spreadRadius: 3,
                                            )
                                          ]
                                        : [],
                                  ),

                                  clipBehavior:
                                      Clip.antiAlias,

                                  child: Stack(
                                    fit: StackFit.expand,

                                    children: [

                                      Image.network(
                                        posters[rIndex]
                                            [cIndex],

                                        fit: BoxFit.cover,

                                        filterQuality:
                                            FilterQuality
                                                .medium,
                                      ),

                                      Container(
                                        decoration:
                                            BoxDecoration(
                                          gradient:
                                              LinearGradient(
                                            begin:
                                                Alignment
                                                    .bottomCenter,
                                            end: Alignment
                                                .center,

                                            colors: [
                                              Colors.black
                                                  .withOpacity(
                                                      0.9),
                                              Colors
                                                  .transparent,
                                            ],
                                          ),
                                        ),
                                      ),

                                      Positioned(
                                        left: 12,
                                        right: 12,
                                        bottom: 12,

                                        child: Text(
                                          "Movie ${cIndex + 1}",

                                          maxLines: 1,

                                          overflow:
                                              TextOverflow
                                                  .ellipsis,

                                          style:
                                              const TextStyle(
                                            color:
                                                Colors.white,
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
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
