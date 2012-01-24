
class HTMLMediaElementJS extends HTMLElementJS implements HTMLMediaElement native "*HTMLMediaElement" {

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

  bool get autoplay() native "return this.autoplay;";

  void set autoplay(bool value) native "this.autoplay = value;";

  TimeRangesJS get buffered() native "return this.buffered;";

  MediaControllerJS get controller() native "return this.controller;";

  void set controller(MediaControllerJS value) native "this.controller = value;";

  bool get controls() native "return this.controls;";

  void set controls(bool value) native "this.controls = value;";

  String get currentSrc() native "return this.currentSrc;";

  num get currentTime() native "return this.currentTime;";

  void set currentTime(num value) native "this.currentTime = value;";

  bool get defaultMuted() native "return this.defaultMuted;";

  void set defaultMuted(bool value) native "this.defaultMuted = value;";

  num get defaultPlaybackRate() native "return this.defaultPlaybackRate;";

  void set defaultPlaybackRate(num value) native "this.defaultPlaybackRate = value;";

  num get duration() native "return this.duration;";

  bool get ended() native "return this.ended;";

  MediaErrorJS get error() native "return this.error;";

  num get initialTime() native "return this.initialTime;";

  bool get loop() native "return this.loop;";

  void set loop(bool value) native "this.loop = value;";

  String get mediaGroup() native "return this.mediaGroup;";

  void set mediaGroup(String value) native "this.mediaGroup = value;";

  bool get muted() native "return this.muted;";

  void set muted(bool value) native "this.muted = value;";

  int get networkState() native "return this.networkState;";

  bool get paused() native "return this.paused;";

  num get playbackRate() native "return this.playbackRate;";

  void set playbackRate(num value) native "this.playbackRate = value;";

  TimeRangesJS get played() native "return this.played;";

  String get preload() native "return this.preload;";

  void set preload(String value) native "this.preload = value;";

  int get readyState() native "return this.readyState;";

  TimeRangesJS get seekable() native "return this.seekable;";

  bool get seeking() native "return this.seeking;";

  String get src() native "return this.src;";

  void set src(String value) native "this.src = value;";

  num get startTime() native "return this.startTime;";

  TextTrackListJS get textTracks() native "return this.textTracks;";

  num get volume() native "return this.volume;";

  void set volume(num value) native "this.volume = value;";

  int get webkitAudioDecodedByteCount() native "return this.webkitAudioDecodedByteCount;";

  bool get webkitClosedCaptionsVisible() native "return this.webkitClosedCaptionsVisible;";

  void set webkitClosedCaptionsVisible(bool value) native "this.webkitClosedCaptionsVisible = value;";

  bool get webkitHasClosedCaptions() native "return this.webkitHasClosedCaptions;";

  String get webkitMediaSourceURL() native "return this.webkitMediaSourceURL;";

  bool get webkitPreservesPitch() native "return this.webkitPreservesPitch;";

  void set webkitPreservesPitch(bool value) native "this.webkitPreservesPitch = value;";

  int get webkitSourceState() native "return this.webkitSourceState;";

  int get webkitVideoDecodedByteCount() native "return this.webkitVideoDecodedByteCount;";

  TextTrackJS addTrack(String kind, [String label = null, String language = null]) native;

  String canPlayType(String type) native;

  void load() native;

  void pause() native;

  void play() native;

  void webkitSourceAppend(Uint8ArrayJS data) native;

  void webkitSourceEndOfStream(int status) native;
}
