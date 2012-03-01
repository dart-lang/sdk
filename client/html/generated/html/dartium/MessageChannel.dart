
class _MessageChannelImpl extends _DOMTypeBase implements MessageChannel {
  _MessageChannelImpl._wrap(ptr) : super._wrap(ptr);

  MessagePort get port1() => _wrap(_ptr.port1);

  MessagePort get port2() => _wrap(_ptr.port2);
}
