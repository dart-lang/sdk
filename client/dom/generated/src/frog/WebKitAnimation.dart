
class WebKitAnimationJS implements WebKitAnimation native "*WebKitAnimation" {

  static final int DIRECTION_ALTERNATE = 1;

  static final int DIRECTION_NORMAL = 0;

  static final int FILL_BACKWARDS = 1;

  static final int FILL_BOTH = 3;

  static final int FILL_FORWARDS = 2;

  static final int FILL_NONE = 0;

  num get delay() native "return this.delay;";

  int get direction() native "return this.direction;";

  num get duration() native "return this.duration;";

  num get elapsedTime() native "return this.elapsedTime;";

  void set elapsedTime(num value) native "this.elapsedTime = value;";

  bool get ended() native "return this.ended;";

  int get fillMode() native "return this.fillMode;";

  int get iterationCount() native "return this.iterationCount;";

  String get name() native "return this.name;";

  bool get paused() native "return this.paused;";

  void pause() native;

  void play() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
