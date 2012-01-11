
class AudioNode native "*AudioNode" {

  AudioContext context;

  int numberOfInputs;

  int numberOfOutputs;

  void connect(AudioNode destination, int output, int input) native;

  void disconnect(int output) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
