
class AudioNodeJs extends DOMTypeJs implements AudioNode native "*AudioNode" {

  AudioContextJs get context() native "return this.context;";

  int get numberOfInputs() native "return this.numberOfInputs;";

  int get numberOfOutputs() native "return this.numberOfOutputs;";

  void connect(AudioNodeJs destination, int output, int input) native;

  void disconnect(int output) native;
}
