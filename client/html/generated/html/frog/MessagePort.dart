
class _MessagePortImpl extends _EventTargetImpl implements MessagePort native "*MessagePort" {

  _MessagePortEventsImpl get on() =>
    new _MessagePortEventsImpl(this);

  void _addEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.addEventListener(type, listener, useCapture);";

  void close() native;

  bool _dispatchEvent(_EventImpl evt) native "return this.dispatchEvent(evt);";

  void postMessage(String message, [List messagePorts = null]) native;

  void _removeEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.removeEventListener(type, listener, useCapture);";

  void start() native;

  void webkitPostMessage(String message, [List transfer = null]) native;
}

class _MessagePortEventsImpl extends _EventsImpl implements MessagePortEvents {
  _MessagePortEventsImpl(_ptr) : super(_ptr);

  EventListenerList get message() => _get('message');
}
