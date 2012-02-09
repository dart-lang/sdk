
class _TextTrackListJs extends _DOMTypeJs implements TextTrackList native "*TextTrackList" {

  final int length;

  EventListener onaddtrack;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventJs evt) native;

  _TextTrackJs item(int index) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}
