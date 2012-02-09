
class _AudioBufferJs extends _DOMTypeJs implements AudioBuffer native "*AudioBuffer" {

  final num duration;

  num gain;

  final int length;

  final int numberOfChannels;

  final num sampleRate;

  _Float32ArrayJs getChannelData(int channelIndex) native;
}
