
class _MediaStreamImpl implements MediaStream native "*MediaStream" {

  static final int ENDED = 2;

  static final int LIVE = 1;

  final _MediaStreamTrackListImpl audioTracks;

  final String label;

  EventListener onended;

  final int readyState;

  final _MediaStreamTrackListImpl videoTracks;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventImpl event) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}
