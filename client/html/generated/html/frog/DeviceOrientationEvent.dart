
class _DeviceOrientationEventImpl extends _EventImpl implements DeviceOrientationEvent native "*DeviceOrientationEvent" {

  final bool absolute;

  final num alpha;

  final num beta;

  final num gamma;

  void initDeviceOrientationEvent(String type, bool bubbles, bool cancelable, num alpha, num beta, num gamma, bool absolute) native;
}
