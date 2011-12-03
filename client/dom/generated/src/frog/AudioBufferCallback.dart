
class AudioBufferCallback native "*AudioBufferCallback" {

  bool handleEvent(AudioBuffer audioBuffer) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
