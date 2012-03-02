
class _TransitionEventImpl extends _EventImpl implements TransitionEvent {
  _TransitionEventImpl._wrap(ptr) : super._wrap(ptr);

  num get elapsedTime() => _wrap(_ptr.elapsedTime);

  String get propertyName() => _wrap(_ptr.propertyName);
}
