
class _TrackEventImpl extends _EventImpl implements TrackEvent {
  _TrackEventImpl._wrap(ptr) : super._wrap(ptr);

  Object get track() => _wrap(_ptr.track);
}
