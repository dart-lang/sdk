
class HTMLMediaElement extends HTMLElement native "*HTMLMediaElement" {

  static final int HAVE_CURRENT_DATA = 2;

  static final int HAVE_ENOUGH_DATA = 4;

  static final int HAVE_FUTURE_DATA = 3;

  static final int HAVE_METADATA = 1;

  static final int HAVE_NOTHING = 0;

  static final int NETWORK_EMPTY = 0;

  static final int NETWORK_IDLE = 1;

  static final int NETWORK_LOADING = 2;

  static final int NETWORK_NO_SOURCE = 3;

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
