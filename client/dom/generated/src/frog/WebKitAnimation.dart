
class WebKitAnimation native "*WebKitAnimation" {

  static final int DIRECTION_ALTERNATE = 1;

  static final int DIRECTION_NORMAL = 0;

  static final int FILL_BACKWARDS = 1;

  static final int FILL_BOTH = 3;

  static final int FILL_FORWARDS = 2;

  static final int FILL_NONE = 0;

  num delay;

  int direction;

  num duration;

  num elapsedTime;

  bool ended;

  int fillMode;

  int iterationCount;

  String name;

  bool paused;

  void pause() native;

  void play() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
