
class _NotificationImpl extends _EventTargetImpl implements Notification {
  _NotificationImpl._wrap(ptr) : super._wrap(ptr);

  _NotificationEventsImpl get on() {
    if (_on == null) _on = new _NotificationEventsImpl(this);
    return _on;
  }

  String get dir() => _wrap(_ptr.dir);

  void set dir(String value) { _ptr.dir = _unwrap(value); }

  String get replaceId() => _wrap(_ptr.replaceId);

  void set replaceId(String value) { _ptr.replaceId = _unwrap(value); }

  void cancel() {
    _ptr.cancel();
    return;
  }

  void show() {
    _ptr.show();
    return;
  }
}

class _NotificationEventsImpl extends _EventsImpl implements NotificationEvents {
  _NotificationEventsImpl(_ptr) : super(_ptr);

  EventListenerList get click() => _get('click');

  EventListenerList get close() => _get('close');

  EventListenerList get display() => _get('display');

  EventListenerList get error() => _get('error');

  EventListenerList get show() => _get('show');
}
