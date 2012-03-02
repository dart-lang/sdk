
class _WebSocketImpl extends _EventTargetImpl implements WebSocket native "*WebSocket" {

  static final int CLOSED = 3;

  static final int CLOSING = 2;

  static final int CONNECTING = 0;

  static final int OPEN = 1;

  final String URL;

  String binaryType;

  final int bufferedAmount;

  final String extensions;

  final String protocol;

  final int readyState;

  final String url;

  _WebSocketEventsImpl get on() =>
    new _WebSocketEventsImpl(this);

  void _addEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.addEventListener(type, listener, useCapture);";

  void close([int code = null, String reason = null]) native;

  bool _dispatchEvent(_EventImpl evt) native "return this.dispatchEvent(evt);";

  void _removeEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.removeEventListener(type, listener, useCapture);";

  bool send(String data) native;
}

class _WebSocketEventsImpl extends _EventsImpl implements WebSocketEvents {
  _WebSocketEventsImpl(_ptr) : super(_ptr);

  EventListenerList get close() => _get('close');

  EventListenerList get error() => _get('error');

  EventListenerList get message() => _get('message');

  EventListenerList get open() => _get('open');
}
