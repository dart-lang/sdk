
class _FrameSetElementImpl extends _ElementImpl implements FrameSetElement {
  _FrameSetElementImpl._wrap(ptr) : super._wrap(ptr);

  _FrameSetElementEventsImpl get on() {
    if (_on == null) _on = new _FrameSetElementEventsImpl(this);
    return _on;
  }

  String get cols() => _wrap(_ptr.cols);

  void set cols(String value) { _ptr.cols = _unwrap(value); }

  String get rows() => _wrap(_ptr.rows);

  void set rows(String value) { _ptr.rows = _unwrap(value); }
}

class _FrameSetElementEventsImpl extends _ElementEventsImpl implements FrameSetElementEvents {
  _FrameSetElementEventsImpl(_ptr) : super(_ptr);

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
