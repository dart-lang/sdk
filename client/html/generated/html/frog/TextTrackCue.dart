
class _TextTrackCueImpl implements TextTrackCue native "*TextTrackCue" {

  String align;

  num endTime;

  String id;

  int line;

  EventListener onenter;

  EventListener onexit;

  bool pauseOnExit;

  int position;

  int size;

  bool snapToLines;

  num startTime;

  String text;

  final _TextTrackImpl track;

  String vertical;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventImpl evt) native;

  _DocumentFragmentImpl getCueAsHTML() native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}
