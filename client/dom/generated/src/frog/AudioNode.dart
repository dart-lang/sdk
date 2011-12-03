
class AudioNode native "*AudioNode" {

  AudioContext context;

  int numberOfInputs;

  int numberOfOutputs;

  void connect(AudioNode destination, [int output = null, int input = null]) native;

  void disconnect([int output = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
