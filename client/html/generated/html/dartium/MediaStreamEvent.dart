
class _MediaStreamEventImpl extends _EventImpl implements MediaStreamEvent {
  _MediaStreamEventImpl._wrap(ptr) : super._wrap(ptr);

  MediaStream get stream() => _wrap(_ptr.stream);
}
