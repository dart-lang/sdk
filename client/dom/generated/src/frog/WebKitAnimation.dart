
class _WebKitAnimationJs extends _DOMTypeJs implements WebKitAnimation native "*WebKitAnimation" {

  static final int DIRECTION_ALTERNATE = 1;

  static final int DIRECTION_NORMAL = 0;

  static final int FILL_BACKWARDS = 1;

  static final int FILL_BOTH = 3;

  static final int FILL_FORWARDS = 2;

  static final int FILL_NONE = 0;

  final num delay;

  final int direction;

  final num duration;

  num elapsedTime;

  final bool ended;

  final int fillMode;

  final int iterationCount;

  final String name;

  final bool paused;

  void pause() native;

  void play() native;
}
