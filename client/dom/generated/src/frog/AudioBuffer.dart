
class AudioBuffer native "*AudioBuffer" {

  num get duration() native "return this.duration;";

  num get gain() native "return this.gain;";

  void set gain(num value) native "this.gain = value;";

  int get length() native "return this.length;";

  int get numberOfChannels() native "return this.numberOfChannels;";

  num get sampleRate() native "return this.sampleRate;";

  Float32Array getChannelData(int channelIndex) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
