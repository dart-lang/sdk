
class _HTMLMediaElementJs extends _HTMLElementJs implements HTMLMediaElement native "*HTMLMediaElement" {

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

  final _TimeRangesJs buffered;

  _MediaControllerJs controller;

  bool controls;

  final String currentSrc;

  num currentTime;

  bool defaultMuted;

  num defaultPlaybackRate;

  final num duration;

  final bool ended;

  final _MediaErrorJs error;

  final num initialTime;

  bool loop;

  String mediaGroup;

  bool muted;

  final int networkState;

  final bool paused;

  num playbackRate;

  final _TimeRangesJs played;

  String preload;

  final int readyState;

  final _TimeRangesJs seekable;

  final bool seeking;

  String src;

  final num startTime;

  final _TextTrackListJs textTracks;

  num volume;

  final int webkitAudioDecodedByteCount;

  bool webkitClosedCaptionsVisible;

  final bool webkitHasClosedCaptions;

  final String webkitMediaSourceURL;

  bool webkitPreservesPitch;

  final int webkitSourceState;

  final int webkitVideoDecodedByteCount;

  _TextTrackJs addTextTrack(String kind, [String label = null, String language = null]) native;

  String canPlayType(String type) native;

  void load() native;

  void pause() native;

  void play() native;

  void webkitSourceAppend(_Uint8ArrayJs data) native;

  void webkitSourceEndOfStream(int status) native;
}
