
class HTMLMediaElement extends HTMLElement native "HTMLMediaElement" {

  static final int EOS_DECODE_ERR = 2;

  static final int EOS_NETWORK_ERR = 1;

  static final int EOS_NO_ERROR = 0;

  static final int HAVE_CURRENT_DATA = 2;

  static final int HAVE_ENOUGH_DATA = 4;

  static final int HAVE_FUTURE_DATA = 3;

  static final int HAVE_METADATA = 1;

  static final int HAVE_NOTHING = 0;

  static final int NETWORK_EMPTY = 0;

  static final int NETWORK_IDLE = 1;

  static final int NETWORK_LOADING = 2;

  static final int NETWORK_NO_SOURCE = 3;

  static final int SOURCE_CLOSED = 0;

  static final int SOURCE_ENDED = 2;

  static final int SOURCE_OPEN = 1;

  bool autoplay;

  TimeRanges buffered;

  MediaController controller;

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

  String mediaGroup;

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

  TextTrackList textTracks;

  num volume;

  int webkitAudioDecodedByteCount;

  bool webkitClosedCaptionsVisible;

  bool webkitHasClosedCaptions;

  String webkitMediaSourceURL;

  bool webkitPreservesPitch;

  int webkitSourceState;

  int webkitVideoDecodedByteCount;

  TextTrack addTrack(String kind, [String label = null, String language = null]) native;

  String canPlayType(String type) native;

  void load() native;

  void pause() native;

  void play() native;

  void webkitSourceAppend(Uint8Array data) native;

  void webkitSourceEndOfStream(int status) native;
}
