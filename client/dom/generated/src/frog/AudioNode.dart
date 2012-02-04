
class _AudioNodeJs extends _DOMTypeJs implements AudioNode native "*AudioNode" {

  final _AudioContextJs context;

  final int numberOfInputs;

  final int numberOfOutputs;

  void connect(_AudioNodeJs destination, int output, int input) native;

  void disconnect(int output) native;
}
