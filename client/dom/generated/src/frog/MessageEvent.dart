
class MessageEvent extends Event native "MessageEvent" {

  String data;

  String lastEventId;

  MessagePort messagePort;

  String origin;

  DOMWindow source;

  void initMessageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String dataArg, String originArg, String lastEventIdArg, DOMWindow sourceArg, MessagePort messagePort) native;
}
