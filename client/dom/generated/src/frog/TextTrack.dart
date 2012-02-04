
class _TextTrackJs extends _DOMTypeJs implements TextTrack native "*TextTrack" {

  static final int DISABLED = 0;

  static final int HIDDEN = 1;

  static final int SHOWING = 2;

  final _TextTrackCueListJs activeCues;

  final _TextTrackCueListJs cues;

  final String kind;

  final String label;

  final String language;

  int mode;

  EventListener oncuechange;

  void addCue(_TextTrackCueJs cue) native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventJs evt) native;

  void removeCue(_TextTrackCueJs cue) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}
