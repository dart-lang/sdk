
class HTMLMediaElement extends HTMLElement native "HTMLMediaElement" {

  bool autoplay;

  TimeRanges buffered;

  bool controls;

  String currentSrc;

  num currentTime;

  bool defaultMuted;

  num defaultPlaybackRate;

  num duration;

  bool ended;

  MediaError error;

  num initialTime;

  bool loop;

  bool muted;

  int networkState;

  bool paused;

  num playbackRate;

  TimeRanges played;

  String preload;

  int readyState;

  TimeRanges seekable;

  bool seeking;

  String src;

  num startTime;

  num volume;

  int webkitAudioDecodedByteCount;

  bool webkitClosedCaptionsVisible;

  bool webkitHasClosedCaptions;

  bool webkitPreservesPitch;

  int webkitVideoDecodedByteCount;

  String canPlayType(String type) native;

  void load() native;

  void pause() native;

  void play() native;
}
