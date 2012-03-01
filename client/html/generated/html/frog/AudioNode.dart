
class _AudioNodeImpl implements AudioNode native "*AudioNode" {

  final _AudioContextImpl context;

  final int numberOfInputs;

  final int numberOfOutputs;

  void connect(_AudioNodeImpl destination, int output, int input) native;

  void disconnect(int output) native;
}
