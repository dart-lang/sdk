
class DeviceMotionEventJs extends EventJs implements DeviceMotionEvent native "*DeviceMotionEvent" {

  num get interval() native "return this.interval;";
}
