
class _AbstractWorkerImpl extends _EventTargetImpl implements AbstractWorker native "*AbstractWorker" {

  _AbstractWorkerEventsImpl get on() =>
    new _AbstractWorkerEventsImpl(this);

  void _addEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.addEventListener(type, listener, useCapture);";

  bool _dispatchEvent(_EventImpl evt) native "return this.dispatchEvent(evt);";

  void _removeEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.removeEventListener(type, listener, useCapture);";
}

class _AbstractWorkerEventsImpl extends _EventsImpl implements AbstractWorkerEvents {
  _AbstractWorkerEventsImpl(_ptr) : super(_ptr);

  EventListenerList get error() => _get('error');
}
