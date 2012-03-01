
class _TextTrackCueImpl implements TextTrackCue native "*TextTrackCue" {

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

  String text;

  int textPosition;

  final _TextTrackImpl track;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventImpl evt) native;

  _DocumentFragmentImpl getCueAsHTML() native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}
