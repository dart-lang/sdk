
class _AudioContextJs extends _DOMTypeJs implements AudioContext native "*AudioContext" {

  final num currentTime;

  final _AudioDestinationNodeJs destination;

  final _AudioListenerJs listener;

  EventListener oncomplete;

  final num sampleRate;

  _RealtimeAnalyserNodeJs createAnalyser() native;

  _BiquadFilterNodeJs createBiquadFilter() native;

  _AudioBufferJs createBuffer(var buffer_OR_numberOfChannels, var mixToMono_OR_numberOfFrames, [num sampleRate = null]) native;

  _AudioBufferSourceNodeJs createBufferSource() native;

  _AudioChannelMergerJs createChannelMerger() native;

  _AudioChannelSplitterJs createChannelSplitter() native;

  _ConvolverNodeJs createConvolver() native;

  _DelayNodeJs createDelayNode() native;

  _DynamicsCompressorNodeJs createDynamicsCompressor() native;

  _AudioGainNodeJs createGainNode() native;

  _HighPass2FilterNodeJs createHighPass2Filter() native;

  _JavaScriptAudioNodeJs createJavaScriptNode(int bufferSize) native;

  _LowPass2FilterNodeJs createLowPass2Filter() native;

  _MediaElementAudioSourceNodeJs createMediaElementSource(_HTMLMediaElementJs mediaElement) native;

  _AudioPannerNodeJs createPanner() native;

  _WaveShaperNodeJs createWaveShaper() native;

  void decodeAudioData(_ArrayBufferJs audioData, AudioBufferCallback successCallback, [AudioBufferCallback errorCallback = null]) native;

  void startRendering() native;
}
