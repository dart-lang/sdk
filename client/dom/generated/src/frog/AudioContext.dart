
class AudioContextJS implements AudioContext native "*AudioContext" {
  AudioContext() native;


  num get currentTime() native "return this.currentTime;";

  AudioDestinationNodeJS get destination() native "return this.destination;";

  AudioListenerJS get listener() native "return this.listener;";

  EventListener get oncomplete() native "return this.oncomplete;";

  void set oncomplete(EventListener value) native "this.oncomplete = value;";

  num get sampleRate() native "return this.sampleRate;";

  RealtimeAnalyserNodeJS createAnalyser() native;

  BiquadFilterNodeJS createBiquadFilter() native;

  AudioBufferJS createBuffer(var buffer_OR_numberOfChannels, var mixToMono_OR_numberOfFrames, [num sampleRate = null]) native;

  AudioBufferSourceNodeJS createBufferSource() native;

  AudioChannelMergerJS createChannelMerger() native;

  AudioChannelSplitterJS createChannelSplitter() native;

  ConvolverNodeJS createConvolver() native;

  DelayNodeJS createDelayNode() native;

  DynamicsCompressorNodeJS createDynamicsCompressor() native;

  AudioGainNodeJS createGainNode() native;

  HighPass2FilterNodeJS createHighPass2Filter() native;

  JavaScriptAudioNodeJS createJavaScriptNode(int bufferSize) native;

  LowPass2FilterNodeJS createLowPass2Filter() native;

  MediaElementAudioSourceNodeJS createMediaElementSource(HTMLMediaElementJS mediaElement) native;

  AudioPannerNodeJS createPanner() native;

  WaveShaperNodeJS createWaveShaper() native;

  void decodeAudioData(ArrayBufferJS audioData, AudioBufferCallback successCallback, [AudioBufferCallback errorCallback = null]) native;

  void startRendering() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
