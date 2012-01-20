
class ConvolverNode extends AudioNode native "*ConvolverNode" {

  AudioBuffer get buffer() native "return this.buffer;";

  void set buffer(AudioBuffer value) native "this.buffer = value;";

  bool get normalize() native "return this.normalize;";

  void set normalize(bool value) native "this.normalize = value;";
}
