
class AudioBufferSourceNodeJS extends AudioSourceNodeJS implements AudioBufferSourceNode native "*AudioBufferSourceNode" {

  AudioBufferJS get buffer() native "return this.buffer;";

  void set buffer(AudioBufferJS value) native "this.buffer = value;";

  AudioGainJS get gain() native "return this.gain;";

  bool get loop() native "return this.loop;";

  void set loop(bool value) native "this.loop = value;";

  bool get looping() native "return this.looping;";

  void set looping(bool value) native "this.looping = value;";

  AudioParamJS get playbackRate() native "return this.playbackRate;";

  void noteGrainOn(num when, num grainOffset, num grainDuration) native;

  void noteOff(num when) native;

  void noteOn(num when) native;
}
