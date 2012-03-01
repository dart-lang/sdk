
class _PopStateEventImpl extends _EventImpl implements PopStateEvent {
  _PopStateEventImpl._wrap(ptr) : super._wrap(ptr);

  Object get state() => _wrap(_ptr.state);
}
