
class _XMLHttpRequestUploadImpl extends _EventTargetImpl implements XMLHttpRequestUpload native "*XMLHttpRequestUpload" {

  _XMLHttpRequestUploadEventsImpl get on() =>
    new _XMLHttpRequestUploadEventsImpl(this);

  void _addEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.addEventListener(type, listener, useCapture);";

  bool _dispatchEvent(_EventImpl evt) native "return this.dispatchEvent(evt);";

  void _removeEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.removeEventListener(type, listener, useCapture);";
}

class _XMLHttpRequestUploadEventsImpl extends _EventsImpl implements XMLHttpRequestUploadEvents {
  _XMLHttpRequestUploadEventsImpl(_ptr) : super(_ptr);

  EventListenerList get abort() => _get('abort');

  EventListenerList get error() => _get('error');

  EventListenerList get load() => _get('load');

  EventListenerList get loadEnd() => _get('loadend');

  EventListenerList get loadStart() => _get('loadstart');

  EventListenerList get progress() => _get('progress');
}
