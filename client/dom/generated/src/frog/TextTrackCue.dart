
class TextTrackCue native "TextTrackCue" {

  String alignment;

  String direction;

  num endTime;

  String id;

  int linePosition;

  bool pauseOnExit;

  int size;

  bool snapToLines;

  num startTime;

  int textPosition;

  TextTrack track;

  DocumentFragment getCueAsHTML() native;

  String getCueAsSource() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
