
class _DOMApplicationCacheImpl extends _EventTargetImpl implements DOMApplicationCache native "*DOMApplicationCache" {

  static final int CHECKING = 2;

  static final int DOWNLOADING = 3;

  static final int IDLE = 1;

  static final int OBSOLETE = 5;

  static final int UNCACHED = 0;

  static final int UPDATEREADY = 4;

  final int status;

  _DOMApplicationCacheEventsImpl get on() =>
    new _DOMApplicationCacheEventsImpl(this);

  void abort() native;

  void _addEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.addEventListener(type, listener, useCapture);";

  bool _dispatchEvent(_EventImpl evt) native "return this.dispatchEvent(evt);";

  void _removeEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.removeEventListener(type, listener, useCapture);";

  void swapCache() native;

  void update() native;
}

class _DOMApplicationCacheEventsImpl extends _EventsImpl implements DOMApplicationCacheEvents {
  _DOMApplicationCacheEventsImpl(_ptr) : super(_ptr);

  EventListenerList get cached() => _get('cached');

  EventListenerList get checking() => _get('checking');

  EventListenerList get downloading() => _get('downloading');

  EventListenerList get error() => _get('error');

  EventListenerList get noUpdate() => _get('noupdate');

  EventListenerList get obsolete() => _get('obsolete');

  EventListenerList get progress() => _get('progress');

  EventListenerList get updateReady() => _get('updateready');
}
