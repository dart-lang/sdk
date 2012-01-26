
class AudioContextJs extends DOMTypeJs implements AudioContext native "*AudioContext" {
  AudioContext() native;


  num get currentTime() native "return this.currentTime;";

  AudioDestinationNodeJs get destination() native "return this.destination;";

  AudioListenerJs get listener() native "return this.listener;";

  EventListener get oncomplete() native "return this.oncomplete;";

  void set oncomplete(EventListener value) native "this.oncomplete = value;";

  num get sampleRate() native "return this.sampleRate;";

  RealtimeAnalyserNodeJs createAnalyser() native;

  BiquadFilterNodeJs createBiquadFilter() native;

  AudioBufferJs createBuffer(var buffer_OR_numberOfChannels, var mixToMono_OR_numberOfFrames, [num sampleRate = null]) native;

  AudioBufferSourceNodeJs createBufferSource() native;

  AudioChannelMergerJs createChannelMerger() native;

  AudioChannelSplitterJs createChannelSplitter() native;

  ConvolverNodeJs createConvolver() native;

  DelayNodeJs createDelayNode() native;

  DynamicsCompressorNodeJs createDynamicsCompressor() native;

  AudioGainNodeJs createGainNode() native;

  HighPass2FilterNodeJs createHighPass2Filter() native;

  JavaScriptAudioNodeJs createJavaScriptNode(int bufferSize) native;

  LowPass2FilterNodeJs createLowPass2Filter() native;

  MediaElementAudioSourceNodeJs createMediaElementSource(HTMLMediaElementJs mediaElement) native;

  AudioPannerNodeJs createPanner() native;

  WaveShaperNodeJs createWaveShaper() native;

  void decodeAudioData(ArrayBufferJs audioData, AudioBufferCallback successCallback, [AudioBufferCallback errorCallback = null]) native;

  void startRendering() native;
}
