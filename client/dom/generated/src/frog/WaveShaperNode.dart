
class WaveShaperNodeJS extends AudioNodeJS implements WaveShaperNode native "*WaveShaperNode" {

  Float32ArrayJS get curve() native "return this.curve;";

  void set curve(Float32ArrayJS value) native "this.curve = value;";
}
