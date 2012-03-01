
class _AnimationEventImpl extends _EventImpl implements AnimationEvent {
  _AnimationEventImpl._wrap(ptr) : super._wrap(ptr);

  String get animationName() => _wrap(_ptr.animationName);

  num get elapsedTime() => _wrap(_ptr.elapsedTime);
}
