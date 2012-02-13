
class _EventSourceJs extends _EventTargetJs implements EventSource native "*EventSource" {

  static final int CLOSED = 2;

  static final int CONNECTING = 0;

  static final int OPEN = 1;

  final String URL;

  final int readyState;

  final String url;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void close() native;

  bool dispatchEvent(_EventJs evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}
