
class AudioGainNodeJS extends AudioNodeJS implements AudioGainNode native "*AudioGainNode" {

  AudioGainJS get gain() native "return this.gain;";
}
