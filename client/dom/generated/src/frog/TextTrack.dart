
class TextTrack native "*TextTrack" {

  static final int DISABLED = 0;

  static final int HIDDEN = 1;

  static final int SHOWING = 2;

  TextTrackCueList activeCues;

  TextTrackCueList cues;

  String kind;

  String label;

  String language;

  int mode;

  EventListener oncuechange;

  void addCue(TextTrackCue cue) native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(Event evt) native;

  void removeCue(TextTrackCue cue) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
