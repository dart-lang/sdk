
class _AudioListenerImpl extends _DOMTypeBase implements AudioListener {
  _AudioListenerImpl._wrap(ptr) : super._wrap(ptr);

  num get dopplerFactor() => _wrap(_ptr.dopplerFactor);

  void set dopplerFactor(num value) { _ptr.dopplerFactor = _unwrap(value); }

  num get speedOfSound() => _wrap(_ptr.speedOfSound);

  void set speedOfSound(num value) { _ptr.speedOfSound = _unwrap(value); }

  void setOrientation(num x, num y, num z, num xUp, num yUp, num zUp) {
    _ptr.setOrientation(_unwrap(x), _unwrap(y), _unwrap(z), _unwrap(xUp), _unwrap(yUp), _unwrap(zUp));
    return;
  }

  void setPosition(num x, num y, num z) {
    _ptr.setPosition(_unwrap(x), _unwrap(y), _unwrap(z));
    return;
  }

  void setVelocity(num x, num y, num z) {
    _ptr.setVelocity(_unwrap(x), _unwrap(y), _unwrap(z));
    return;
  }
}
