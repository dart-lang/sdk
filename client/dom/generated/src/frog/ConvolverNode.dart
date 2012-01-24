
class ConvolverNodeJs extends AudioNodeJs implements ConvolverNode native "*ConvolverNode" {

  AudioBufferJs get buffer() native "return this.buffer;";

  void set buffer(AudioBufferJs value) native "this.buffer = value;";

  bool get normalize() native "return this.normalize;";

  void set normalize(bool value) native "this.normalize = value;";
}
