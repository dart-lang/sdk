
class _WaveShaperNodeJs extends _AudioNodeJs implements WaveShaperNode native "*WaveShaperNode" {

  _Float32ArrayJs get curve() native "return this.curve;";

  void set curve(_Float32ArrayJs value) native "this.curve = value;";
}
