
class _XMLHttpRequestProgressEventImpl extends _ProgressEventImpl implements XMLHttpRequestProgressEvent {
  _XMLHttpRequestProgressEventImpl._wrap(ptr) : super._wrap(ptr);

  int get position() => _wrap(_ptr.position);

  int get totalSize() => _wrap(_ptr.totalSize);
}
