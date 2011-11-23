
class MessageEvent extends Event native "*MessageEvent" {

  Object data;

  String lastEventId;

  String origin;

  List ports;

  DOMWindow source;

  void initMessageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object dataArg, String originArg, String lastEventIdArg, DOMWindow sourceArg, List messagePorts) native;

  void webkitInitMessageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object dataArg, String originArg, String lastEventIdArg, DOMWindow sourceArg, List transferables) native;
}
