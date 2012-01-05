
class TextTrackCue native "*TextTrackCue" {

  String alignment;

  String direction;

  num endTime;

  String id;

  int linePosition;

  EventListener onenter;

  EventListener onexit;

  bool pauseOnExit;

  int size;

  bool snapToLines;

  num startTime;

  int textPosition;

  TextTrack track;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(Event evt) native;

  DocumentFragment getCueAsHTML() native;

  String getCueAsSource() native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
