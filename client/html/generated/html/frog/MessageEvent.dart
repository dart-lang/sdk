
class _MessageEventImpl extends _EventImpl implements MessageEvent native "*MessageEvent" {

  final Object data;

  final String lastEventId;

  final String origin;

  final List ports;

  final _WindowImpl source;

  void initMessageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object dataArg, String originArg, String lastEventIdArg, _WindowImpl sourceArg, List messagePorts) native;

  void webkitInitMessageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object dataArg, String originArg, String lastEventIdArg, _WindowImpl sourceArg, List transferables) native;
}
