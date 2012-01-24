
class DeviceMotionEventJS extends EventJS implements DeviceMotionEvent native "*DeviceMotionEvent" {

  num get interval() native "return this.interval;";
}
