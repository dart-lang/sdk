
class _NotificationImpl extends _EventTargetImpl implements Notification native "*Notification" {

  String dir;

  String replaceId;

  _NotificationEventsImpl get on() =>
    new _NotificationEventsImpl(this);

  void cancel() native;

  void show() native;
}

class _NotificationEventsImpl extends _EventsImpl implements NotificationEvents {
  _NotificationEventsImpl(_ptr) : super(_ptr);

  EventListenerList get click() => _get('click');

  EventListenerList get close() => _get('close');

  EventListenerList get display() => _get('display');

  EventListenerList get error() => _get('error');

  EventListenerList get show() => _get('show');
}
