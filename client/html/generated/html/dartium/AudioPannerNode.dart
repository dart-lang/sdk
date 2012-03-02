
class _AudioPannerNodeImpl extends _AudioNodeImpl implements AudioPannerNode {
  _AudioPannerNodeImpl._wrap(ptr) : super._wrap(ptr);

  AudioGain get coneGain() => _wrap(_ptr.coneGain);

  num get coneInnerAngle() => _wrap(_ptr.coneInnerAngle);

  void set coneInnerAngle(num value) { _ptr.coneInnerAngle = _unwrap(value); }

  num get coneOuterAngle() => _wrap(_ptr.coneOuterAngle);

  void set coneOuterAngle(num value) { _ptr.coneOuterAngle = _unwrap(value); }

  num get coneOuterGain() => _wrap(_ptr.coneOuterGain);

  void set coneOuterGain(num value) { _ptr.coneOuterGain = _unwrap(value); }

  AudioGain get distanceGain() => _wrap(_ptr.distanceGain);

  int get distanceModel() => _wrap(_ptr.distanceModel);

  void set distanceModel(int value) { _ptr.distanceModel = _unwrap(value); }

  num get maxDistance() => _wrap(_ptr.maxDistance);

  void set maxDistance(num value) { _ptr.maxDistance = _unwrap(value); }

  int get panningModel() => _wrap(_ptr.panningModel);

  void set panningModel(int value) { _ptr.panningModel = _unwrap(value); }

  num get refDistance() => _wrap(_ptr.refDistance);

  void set refDistance(num value) { _ptr.refDistance = _unwrap(value); }

  num get rolloffFactor() => _wrap(_ptr.rolloffFactor);

  void set rolloffFactor(num value) { _ptr.rolloffFactor = _unwrap(value); }

  void setOrientation(num x, num y, num z) {
    _ptr.setOrientation(_unwrap(x), _unwrap(y), _unwrap(z));
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
