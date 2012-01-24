
class DelayNodeJS extends AudioNodeJS implements DelayNode native "*DelayNode" {

  AudioParamJS get delayTime() native "return this.delayTime;";
}
