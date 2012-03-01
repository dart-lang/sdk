
class _DeviceOrientationEventImpl extends _EventImpl implements DeviceOrientationEvent {
  _DeviceOrientationEventImpl._wrap(ptr) : super._wrap(ptr);

  bool get absolute() => _wrap(_ptr.absolute);

  num get alpha() => _wrap(_ptr.alpha);

  num get beta() => _wrap(_ptr.beta);

  num get gamma() => _wrap(_ptr.gamma);

  void initDeviceOrientationEvent(String type, bool bubbles, bool cancelable, num alpha, num beta, num gamma, bool absolute) {
    _ptr.initDeviceOrientationEvent(_unwrap(type), _unwrap(bubbles), _unwrap(cancelable), _unwrap(alpha), _unwrap(beta), _unwrap(gamma), _unwrap(absolute));
    return;
  }
}
