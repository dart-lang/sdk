
class _LocalMediaStreamImpl extends _MediaStreamImpl implements LocalMediaStream {
  _LocalMediaStreamImpl._wrap(ptr) : super._wrap(ptr);

  void stop() {
    _ptr.stop();
    return;
  }
}
