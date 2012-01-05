
class MediaController native "*MediaController" {

  TimeRanges buffered;

  num currentTime;

  num defaultPlaybackRate;

  num duration;

  bool muted;

  bool paused;

  num playbackRate;

  TimeRanges played;

  TimeRanges seekable;

  num volume;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(Event evt) native;

  void pause() native;

  void play() native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
