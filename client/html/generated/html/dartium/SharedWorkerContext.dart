
class _SharedWorkerContextImpl extends _WorkerContextImpl implements SharedWorkerContext {
  _SharedWorkerContextImpl._wrap(ptr) : super._wrap(ptr);

  String get name() => _wrap(_ptr.name);

  EventListener get onconnect() => _wrap(_ptr.onconnect);

  void set onconnect(EventListener value) { _ptr.onconnect = _unwrap(value); }
}
