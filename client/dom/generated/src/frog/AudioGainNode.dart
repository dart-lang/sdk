
class AudioGainNode extends AudioNode native "*AudioGainNode" {

  AudioGain get gain() native "return this.gain;";
}
