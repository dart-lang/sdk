
class DeviceOrientationEvent extends Event native "DeviceOrientationEvent" {

  num alpha;

  num beta;

  num gamma;

  void initDeviceOrientationEvent(String type, bool bubbles, bool cancelable, num alpha, num beta, num gamma) native;
}
