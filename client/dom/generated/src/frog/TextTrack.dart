
class TextTrack native "*TextTrack" {

  static final int DISABLED = 0;

  static final int HIDDEN = 1;

  static final int SHOWING = 2;

  TextTrackCueList get activeCues() native "return this.activeCues;";

  TextTrackCueList get cues() native "return this.cues;";

  String get kind() native "return this.kind;";

  String get label() native "return this.label;";

  String get language() native "return this.language;";

  int get mode() native "return this.mode;";

  void set mode(int value) native "this.mode = value;";

  EventListener get oncuechange() native "return this.oncuechange;";

  void set oncuechange(EventListener value) native "this.oncuechange = value;";

  void addCue(TextTrackCue cue) native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(Event evt) native;

  void removeCue(TextTrackCue cue) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
