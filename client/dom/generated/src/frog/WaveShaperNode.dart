
class WaveShaperNodeJs extends AudioNodeJs implements WaveShaperNode native "*WaveShaperNode" {

  Float32ArrayJs get curve() native "return this.curve;";

  void set curve(Float32ArrayJs value) native "this.curve = value;";
}
