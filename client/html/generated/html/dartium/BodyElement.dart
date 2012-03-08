
class _BodyElementImpl extends _ElementImpl implements BodyElement {
  _BodyElementImpl._wrap(ptr) : super._wrap(ptr);

  _BodyElementEventsImpl get on() {
    if (_on == null) _on = new _BodyElementEventsImpl(this);
    return _on;
  }

  String get aLink() => _wrap(_ptr.aLink);

  void set aLink(String value) { _ptr.aLink = _unwrap(value); }

  String get background() => _wrap(_ptr.background);

  void set background(String value) { _ptr.background = _unwrap(value); }

  String get bgColor() => _wrap(_ptr.bgColor);

  void set bgColor(String value) { _ptr.bgColor = _unwrap(value); }

  String get link() => _wrap(_ptr.link);

  void set link(String value) { _ptr.link = _unwrap(value); }

  String get vLink() => _wrap(_ptr.vLink);

  void set vLink(String value) { _ptr.vLink = _unwrap(value); }
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
