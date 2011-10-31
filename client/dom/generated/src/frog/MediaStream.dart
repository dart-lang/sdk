
class MediaStream native "MediaStream" {

  String label;

  EventListener onended;

  int readyState;

  MediaStreamTrackList tracks;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(Event event) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
