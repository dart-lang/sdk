
class _EventSourceImpl extends _EventTargetImpl implements EventSource native "*EventSource" {

  _EventSourceEventsImpl get on() =>
    new _EventSourceEventsImpl(this);

  static final int CLOSED = 2;

  static final int CONNECTING = 0;

  static final int OPEN = 1;

  final String URL;

  final int readyState;

  final String url;

  void _addEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.addEventListener(type, listener, useCapture);";

  void close() native;

  bool _dispatchEvent(_EventImpl evt) native "return this.dispatchEvent(evt);";

  void _removeEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.removeEventListener(type, listener, useCapture);";
}

class _EventSourceEventsImpl extends _EventsImpl implements EventSourceEvents {
  _EventSourceEventsImpl(_ptr) : super(_ptr);

  EventListenerList get error() => _get('error');

  EventListenerList get message() => _get('message');

  EventListenerList get open() => _get('open');
}
