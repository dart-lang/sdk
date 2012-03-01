
class _TextTrackImpl implements TextTrack native "*TextTrack" {

  static final int DISABLED = 0;

  static final int HIDDEN = 1;

  static final int SHOWING = 2;

  final _TextTrackCueListImpl activeCues;

  final _TextTrackCueListImpl cues;

  final String kind;

  final String label;

  final String language;

  int mode;

  EventListener oncuechange;

  void addCue(_TextTrackCueImpl cue) native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventImpl evt) native;

  void removeCue(_TextTrackCueImpl cue) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}
