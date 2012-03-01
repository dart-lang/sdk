
class _AnimationImpl extends _DOMTypeBase implements Animation {
  _AnimationImpl._wrap(ptr) : super._wrap(ptr);

  num get delay() => _wrap(_ptr.delay);

  int get direction() => _wrap(_ptr.direction);

  num get duration() => _wrap(_ptr.duration);

  num get elapsedTime() => _wrap(_ptr.elapsedTime);

  void set elapsedTime(num value) { _ptr.elapsedTime = _unwrap(value); }

  bool get ended() => _wrap(_ptr.ended);

  int get fillMode() => _wrap(_ptr.fillMode);

  int get iterationCount() => _wrap(_ptr.iterationCount);

  String get name() => _wrap(_ptr.name);

  bool get paused() => _wrap(_ptr.paused);

  void pause() {
    _ptr.pause();
    return;
  }

  void play() {
    _ptr.play();
    return;
  }
}
