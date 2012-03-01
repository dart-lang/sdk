
class _DedicatedWorkerContextImpl extends _WorkerContextImpl implements DedicatedWorkerContext {
  _DedicatedWorkerContextImpl._wrap(ptr) : super._wrap(ptr);

  EventListener get onmessage() => _wrap(_ptr.onmessage);

  void set onmessage(EventListener value) { _ptr.onmessage = _unwrap(value); }

  void postMessage(Object message, [List messagePorts = null]) {
    if (messagePorts === null) {
      _ptr.postMessage(_unwrap(message));
      return;
    } else {
      _ptr.postMessage(_unwrap(message), _unwrap(messagePorts));
      return;
    }
  }

  void webkitPostMessage(Object message, [List transferList = null]) {
    if (transferList === null) {
      _ptr.webkitPostMessage(_unwrap(message));
      return;
    } else {
      _ptr.webkitPostMessage(_unwrap(message), _unwrap(transferList));
      return;
    }
  }
}
