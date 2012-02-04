
class _AudioBufferSourceNodeJs extends _AudioSourceNodeJs implements AudioBufferSourceNode native "*AudioBufferSourceNode" {

  _AudioBufferJs buffer;

  final _AudioGainJs gain;

  bool loop;

  bool looping;

  final _AudioParamJs playbackRate;

  void noteGrainOn(num when, num grainOffset, num grainDuration) native;

  void noteOff(num when) native;

  void noteOn(num when) native;
}
