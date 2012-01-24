
class ConvolverNodeJS extends AudioNodeJS implements ConvolverNode native "*ConvolverNode" {

  AudioBufferJS get buffer() native "return this.buffer;";

  void set buffer(AudioBufferJS value) native "this.buffer = value;";

  bool get normalize() native "return this.normalize;";

  void set normalize(bool value) native "this.normalize = value;";
}
