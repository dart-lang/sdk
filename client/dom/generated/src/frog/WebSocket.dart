
class WebSocket native "*WebSocket" {
  WebSocket(String url) native;


  static final int CLOSED = 3;

  static final int CLOSING = 2;

  static final int CONNECTING = 0;

  static final int OPEN = 1;

  String get URL() native "return this.URL;";

  String get binaryType() native "return this.binaryType;";

  void set binaryType(String value) native "this.binaryType = value;";

  int get bufferedAmount() native "return this.bufferedAmount;";

  String get extensions() native "return this.extensions;";

  String get protocol() native "return this.protocol;";

  int get readyState() native "return this.readyState;";

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void close([int code = null, String reason = null]) native;

  bool dispatchEvent(Event evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool send(String data) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
