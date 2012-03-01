
class _ProgressEventImpl extends _EventImpl implements ProgressEvent {
  _ProgressEventImpl._wrap(ptr) : super._wrap(ptr);

  bool get lengthComputable() => _wrap(_ptr.lengthComputable);

  int get loaded() => _wrap(_ptr.loaded);

  int get total() => _wrap(_ptr.total);
}
