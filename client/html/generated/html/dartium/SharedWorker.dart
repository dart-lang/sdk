
class _SharedWorkerImpl extends _AbstractWorkerImpl implements SharedWorker {
  _SharedWorkerImpl._wrap(ptr) : super._wrap(ptr);

  MessagePort get port() => _wrap(_ptr.port);
}
