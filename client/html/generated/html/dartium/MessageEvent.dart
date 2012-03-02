
class _MessageEventImpl extends _EventImpl implements MessageEvent {
  _MessageEventImpl._wrap(ptr) : super._wrap(ptr);

  Object get data() => _wrap(_ptr.data);

  String get lastEventId() => _wrap(_ptr.lastEventId);

  String get origin() => _wrap(_ptr.origin);

  List get ports() => _wrap(_ptr.ports);

  Window get source() => _wrap(_ptr.source);

  void initMessageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object dataArg, String originArg, String lastEventIdArg, Window sourceArg, List messagePorts) {
    _ptr.initMessageEvent(_unwrap(typeArg), _unwrap(canBubbleArg), _unwrap(cancelableArg), _unwrap(dataArg), _unwrap(originArg), _unwrap(lastEventIdArg), _unwrap(sourceArg), _unwrap(messagePorts));
    return;
  }

  void webkitInitMessageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object dataArg, String originArg, String lastEventIdArg, Window sourceArg, List transferables) {
    _ptr.webkitInitMessageEvent(_unwrap(typeArg), _unwrap(canBubbleArg), _unwrap(cancelableArg), _unwrap(dataArg), _unwrap(originArg), _unwrap(lastEventIdArg), _unwrap(sourceArg), _unwrap(transferables));
    return;
  }
}
