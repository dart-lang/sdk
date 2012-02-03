
class _ConvolverNodeJs extends _AudioNodeJs implements ConvolverNode native "*ConvolverNode" {

  _AudioBufferJs get buffer() native "return this.buffer;";

  void set buffer(_AudioBufferJs value) native "this.buffer = value;";

  bool get normalize() native "return this.normalize;";

  void set normalize(bool value) native "this.normalize = value;";
}
