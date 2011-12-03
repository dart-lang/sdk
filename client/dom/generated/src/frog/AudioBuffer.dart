
class AudioBuffer native "*AudioBuffer" {

  num duration;

  num gain;

  int length;

  int numberOfChannels;

  num sampleRate;

  Float32Array getChannelData(int channelIndex) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
