
class AudioContext native "*AudioContext" {
  AudioContext() native;


  num get currentTime() native "return this.currentTime;";

  AudioDestinationNode get destination() native "return this.destination;";

  AudioListener get listener() native "return this.listener;";

  EventListener get oncomplete() native "return this.oncomplete;";

  void set oncomplete(EventListener value) native "this.oncomplete = value;";

  num get sampleRate() native "return this.sampleRate;";

  RealtimeAnalyserNode createAnalyser() native;

  BiquadFilterNode createBiquadFilter() native;

  AudioBuffer createBuffer(var buffer_OR_numberOfChannels, var mixToMono_OR_numberOfFrames, [num sampleRate = null]) native;

  AudioBufferSourceNode createBufferSource() native;

  AudioChannelMerger createChannelMerger() native;

  AudioChannelSplitter createChannelSplitter() native;

  ConvolverNode createConvolver() native;

  DelayNode createDelayNode() native;

  DynamicsCompressorNode createDynamicsCompressor() native;

  AudioGainNode createGainNode() native;

  HighPass2FilterNode createHighPass2Filter() native;

  JavaScriptAudioNode createJavaScriptNode(int bufferSize) native;

  LowPass2FilterNode createLowPass2Filter() native;

  MediaElementAudioSourceNode createMediaElementSource(HTMLMediaElement mediaElement) native;

  AudioPannerNode createPanner() native;

  WaveShaperNode createWaveShaper() native;

  void decodeAudioData(ArrayBuffer audioData, AudioBufferCallback successCallback, [AudioBufferCallback errorCallback = null]) native;

  void startRendering() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
