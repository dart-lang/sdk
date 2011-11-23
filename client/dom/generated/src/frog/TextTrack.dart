
class TextTrack native "*TextTrack" {

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
