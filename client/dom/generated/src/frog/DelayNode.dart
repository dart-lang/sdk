
class _DelayNodeJs extends _AudioNodeJs implements DelayNode native "*DelayNode" {

  _AudioParamJs get delayTime() native "return this.delayTime;";
}
