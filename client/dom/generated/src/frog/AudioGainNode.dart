
class _AudioGainNodeJs extends _AudioNodeJs implements AudioGainNode native "*AudioGainNode" {

  _AudioGainJs get gain() native "return this.gain;";
}
