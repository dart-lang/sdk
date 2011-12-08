
class AudioContext native "*AudioContext" {
  AudioContext() native;


  num currentTime;

  AudioDestinationNode destination;

  AudioListener listener;

  num sampleRate;

  RealtimeAnalyserNode createAnalyser() native;

  BiquadFilterNode createBiquadFilter() native;

  AudioBuffer createBuffer() native;

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

  AudioPannerNode createPanner() native;

  WaveShaperNode createWaveShaper() native;

  void decodeAudioData(ArrayBuffer audioData, AudioBufferCallback successCallback, [AudioBufferCallback errorCallback = null]) native;

  void startRendering() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
