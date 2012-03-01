
class _MediaControllerImpl implements MediaController native "*MediaController" {

  final _TimeRangesImpl buffered;

  num currentTime;

  num defaultPlaybackRate;

  final num duration;

  bool muted;

  final bool paused;

  num playbackRate;

  final _TimeRangesImpl played;

  final _TimeRangesImpl seekable;

  num volume;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventImpl evt) native;

  void pause() native;

  void play() native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}
