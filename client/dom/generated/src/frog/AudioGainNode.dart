
class AudioGainNodeJs extends AudioNodeJs implements AudioGainNode native "*AudioGainNode" {

  AudioGainJs get gain() native "return this.gain;";
}
