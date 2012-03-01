
class _PageTransitionEventImpl extends _EventImpl implements PageTransitionEvent {
  _PageTransitionEventImpl._wrap(ptr) : super._wrap(ptr);

  bool get persisted() => _wrap(_ptr.persisted);
}
