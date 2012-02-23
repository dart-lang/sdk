
class _MediaStreamJs extends _DOMTypeJs implements MediaStream native "*MediaStream" {

  static final int ENDED = 2;

  static final int LIVE = 1;

  final _MediaStreamTrackListJs audioTracks;

  final String label;

  EventListener onended;

  final int readyState;

  final _MediaStreamTrackListJs videoTracks;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventJs event) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}
