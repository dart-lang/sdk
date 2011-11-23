
class WebKitAnimation native "*WebKitAnimation" {

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
