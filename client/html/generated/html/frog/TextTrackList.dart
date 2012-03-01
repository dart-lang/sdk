
class _TextTrackListImpl implements TextTrackList native "*TextTrackList" {

  final int length;

  EventListener onaddtrack;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventImpl evt) native;

  _TextTrackImpl item(int index) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}
