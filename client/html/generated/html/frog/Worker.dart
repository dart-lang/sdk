
class _WorkerImpl extends _AbstractWorkerImpl implements Worker native "*Worker" {

  _WorkerEventsImpl get on() =>
    new _WorkerEventsImpl(this);

  void postMessage(Dynamic message, [List messagePorts = null]) native;

  void terminate() native;

  void webkitPostMessage(Dynamic message, [List messagePorts = null]) native;
}

class _WorkerEventsImpl extends _AbstractWorkerEventsImpl implements WorkerEvents {
  _WorkerEventsImpl(_ptr) : super(_ptr);

  EventListenerList get message() => _get('message');
}
