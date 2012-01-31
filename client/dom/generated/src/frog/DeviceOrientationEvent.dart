
class DeviceOrientationEventJs extends EventJs implements DeviceOrientationEvent native "*DeviceOrientationEvent" {

  bool get absolute() native "return this.absolute;";

  num get alpha() native "return this.alpha;";

  num get beta() native "return this.beta;";

  num get gamma() native "return this.gamma;";

  void initDeviceOrientationEvent(String type, bool bubbles, bool cancelable, num alpha, num beta, num gamma, bool absolute) native;
}
