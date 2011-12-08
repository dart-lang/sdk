
class AudioBufferSourceNode extends AudioSourceNode native "*AudioBufferSourceNode" {

  AudioBuffer buffer;

  AudioGain gain;

  bool loop;

  bool looping;

  AudioParam playbackRate;

  void noteGrainOn(num when, num grainOffset, num grainDuration) native;

  void noteOff(num when) native;

  void noteOn(num when) native;
}
