
class _MessageEventJs extends _EventJs implements MessageEvent native "*MessageEvent" {

  Object get data() native "return this.data;";

  String get lastEventId() native "return this.lastEventId;";

  String get origin() native "return this.origin;";

  List get ports() native "return this.ports;";

  _DOMWindowJs get source() native "return this.source;";

  void initMessageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object dataArg, String originArg, String lastEventIdArg, _DOMWindowJs sourceArg, List messagePorts) native;

  void webkitInitMessageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object dataArg, String originArg, String lastEventIdArg, _DOMWindowJs sourceArg, List transferables) native;
}
