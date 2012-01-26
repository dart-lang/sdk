
class DelayNodeJs extends AudioNodeJs implements DelayNode native "*DelayNode" {

  AudioParamJs get delayTime() native "return this.delayTime;";
}
