
class _AudioBufferImpl implements AudioBuffer native "*AudioBuffer" {

  final num duration;

  num gain;

  final int length;

  final int numberOfChannels;

  final num sampleRate;

  _Float32ArrayImpl getChannelData(int channelIndex) native;
}
