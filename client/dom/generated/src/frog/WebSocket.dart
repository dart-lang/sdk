
class WebSocket native "*WebSocket" {

  String URL;

  String binaryType;

  int bufferedAmount;

  String extensions;

  String protocol;

  int readyState;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void close([int code = null, String reason = null]) native;

  bool dispatchEvent(Event evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool send(String data) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
