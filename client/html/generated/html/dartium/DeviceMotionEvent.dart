
class _DeviceMotionEventImpl extends _EventImpl implements DeviceMotionEvent {
  _DeviceMotionEventImpl._wrap(ptr) : super._wrap(ptr);

  num get interval() => _wrap(_ptr.interval);
}
