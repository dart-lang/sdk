
class _BodyElementImpl extends _ElementImpl implements BodyElement native "*HTMLBodyElement" {

  String aLink;

  String background;

  String bgColor;

  String link;

  String vLink;

  _BodyElementEventsImpl get on() =>
    new _BodyElementEventsImpl(this);
}

class _BodyElementEventsImpl extends _ElementEventsImpl implements BodyElementEvents {
  _BodyElementEventsImpl(_ptr) : super(_ptr);

  EventListenerList get beforeUnload() => _get('beforeunload');

  EventListenerList get blur() => _get('blur');

  EventListenerList get error() => _get('error');

  EventListenerList get focus() => _get('focus');

  EventListenerList get hashChange() => _get('hashchange');

  EventListenerList get load() => _get('load');

  EventListenerList get message() => _get('message');

  EventListenerList get offline() => _get('offline');

  EventListenerList get online() => _get('online');

  EventListenerList get popState() => _get('popstate');

  EventListenerList get resize() => _get('resize');

  EventListenerList get storage() => _get('storage');

  EventListenerList get unload() => _get('unload');
}
