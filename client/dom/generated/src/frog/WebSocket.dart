
class _WebSocketJs extends _EventTargetJs implements WebSocket native "*WebSocket" {

  static final int CLOSED = 3;

  static final int CLOSING = 2;

  static final int CONNECTING = 0;

  static final int OPEN = 1;

  final String URL;

  String binaryType;

  final int bufferedAmount;

  final String extensions;

  final String protocol;

  final int readyState;

  final String url;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void close([int code = null, String reason = null]) native;

  bool dispatchEvent(_EventJs evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool send(String data) native;
}
