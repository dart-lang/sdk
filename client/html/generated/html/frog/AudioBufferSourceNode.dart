
class _AudioBufferSourceNodeImpl extends _AudioSourceNodeImpl implements AudioBufferSourceNode native "*AudioBufferSourceNode" {

  _AudioBufferImpl buffer;

  final _AudioGainImpl gain;

  bool loop;

  bool looping;

  final _AudioParamImpl playbackRate;

  void noteGrainOn(num when, num grainOffset, num grainDuration) native;

  void noteOff(num when) native;

  void noteOn(num when) native;
}
