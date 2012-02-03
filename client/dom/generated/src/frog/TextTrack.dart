
class _TextTrackJs extends _DOMTypeJs implements TextTrack native "*TextTrack" {

  static final int DISABLED = 0;

  static final int HIDDEN = 1;

  static final int SHOWING = 2;

  _TextTrackCueListJs get activeCues() native "return this.activeCues;";

  _TextTrackCueListJs get cues() native "return this.cues;";

  String get kind() native "return this.kind;";

  String get label() native "return this.label;";

  String get language() native "return this.language;";

  int get mode() native "return this.mode;";

  void set mode(int value) native "this.mode = value;";

  EventListener get oncuechange() native "return this.oncuechange;";

  void set oncuechange(EventListener value) native "this.oncuechange = value;";

  void addCue(_TextTrackCueJs cue) native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventJs evt) native;

  void removeCue(_TextTrackCueJs cue) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}
