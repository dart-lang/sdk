
class MediaControllerJs extends DOMTypeJs implements MediaController native "*MediaController" {

  TimeRangesJs get buffered() native "return this.buffered;";

  num get currentTime() native "return this.currentTime;";

  void set currentTime(num value) native "this.currentTime = value;";

  num get defaultPlaybackRate() native "return this.defaultPlaybackRate;";

  void set defaultPlaybackRate(num value) native "this.defaultPlaybackRate = value;";

  num get duration() native "return this.duration;";

  bool get muted() native "return this.muted;";

  void set muted(bool value) native "this.muted = value;";

  bool get paused() native "return this.paused;";

  num get playbackRate() native "return this.playbackRate;";

  void set playbackRate(num value) native "this.playbackRate = value;";

  TimeRangesJs get played() native "return this.played;";

  TimeRangesJs get seekable() native "return this.seekable;";

  num get volume() native "return this.volume;";

  void set volume(num value) native "this.volume = value;";

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(EventJs evt) native;

  void pause() native;

  void play() native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}
