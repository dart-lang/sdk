
class _MarqueeElementImpl extends _ElementImpl implements MarqueeElement {
  _MarqueeElementImpl._wrap(ptr) : super._wrap(ptr);

  String get behavior() => _wrap(_ptr.behavior);

  void set behavior(String value) { _ptr.behavior = _unwrap(value); }

  String get bgColor() => _wrap(_ptr.bgColor);

  void set bgColor(String value) { _ptr.bgColor = _unwrap(value); }

  String get direction() => _wrap(_ptr.direction);

  void set direction(String value) { _ptr.direction = _unwrap(value); }

  String get height() => _wrap(_ptr.height);

  void set height(String value) { _ptr.height = _unwrap(value); }

  int get hspace() => _wrap(_ptr.hspace);

  void set hspace(int value) { _ptr.hspace = _unwrap(value); }

  int get loop() => _wrap(_ptr.loop);

  void set loop(int value) { _ptr.loop = _unwrap(value); }

  int get scrollAmount() => _wrap(_ptr.scrollAmount);

  void set scrollAmount(int value) { _ptr.scrollAmount = _unwrap(value); }

  int get scrollDelay() => _wrap(_ptr.scrollDelay);

  void set scrollDelay(int value) { _ptr.scrollDelay = _unwrap(value); }

  bool get trueSpeed() => _wrap(_ptr.trueSpeed);

  void set trueSpeed(bool value) { _ptr.trueSpeed = _unwrap(value); }

  int get vspace() => _wrap(_ptr.vspace);

  void set vspace(int value) { _ptr.vspace = _unwrap(value); }

  String get width() => _wrap(_ptr.width);

  void set width(String value) { _ptr.width = _unwrap(value); }

  void start() {
    _ptr.start();
    return;
  }

  void stop() {
    _ptr.stop();
    return;
  }
}
