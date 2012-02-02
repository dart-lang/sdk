
class _AudioNodeJs extends _DOMTypeJs implements AudioNode native "*AudioNode" {

  _AudioContextJs get context() native "return this.context;";

  int get numberOfInputs() native "return this.numberOfInputs;";

  int get numberOfOutputs() native "return this.numberOfOutputs;";

  void connect(_AudioNodeJs destination, int output, int input) native;

  void disconnect(int output) native;
}
