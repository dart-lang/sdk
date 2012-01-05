
class TextTrack native "*TextTrack" {

  static final int Disabled = 0;

  static final int Error = 3;

  static final int Hidden = 1;

  static final int Loaded = 2;

  static final int Loading = 1;

  static final int None = 0;

  static final int Showing = 2;

  TextTrackCueList activeCues;

  TextTrackCueList cues;

  String kind;

  String label;

  String language;

  int mode;

  int readyState;

  void addCue(TextTrackCue cue) native;

  void removeCue(TextTrackCue cue) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
