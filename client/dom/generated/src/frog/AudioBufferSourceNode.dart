
class AudioBufferSourceNode extends AudioSourceNode native "*AudioBufferSourceNode" {

  AudioBuffer get buffer() native "return this.buffer;";

  void set buffer(AudioBuffer value) native "this.buffer = value;";

  AudioGain get gain() native "return this.gain;";

  bool get loop() native "return this.loop;";

  void set loop(bool value) native "this.loop = value;";

  bool get looping() native "return this.looping;";

  void set looping(bool value) native "this.looping = value;";

  AudioParam get playbackRate() native "return this.playbackRate;";

  void noteGrainOn(num when, num grainOffset, num grainDuration) native;

  void noteOff(num when) native;

  void noteOn(num when) native;
}
