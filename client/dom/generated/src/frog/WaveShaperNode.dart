
class WaveShaperNode extends AudioNode native "*WaveShaperNode" {

  Float32Array get curve() native "return this.curve;";

  void set curve(Float32Array value) native "this.curve = value;";
}
