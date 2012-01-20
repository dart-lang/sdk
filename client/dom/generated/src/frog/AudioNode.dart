
class AudioNode native "*AudioNode" {

  AudioContext get context() native "return this.context;";

  int get numberOfInputs() native "return this.numberOfInputs;";

  int get numberOfOutputs() native "return this.numberOfOutputs;";

  void connect(AudioNode destination, int output, int input) native;

  void disconnect(int output) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
