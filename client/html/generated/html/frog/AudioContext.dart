
class _AudioContextImpl implements AudioContext native "*AudioContext" {

  final num currentTime;

  final _AudioDestinationNodeImpl destination;

  final _AudioListenerImpl listener;

  EventListener oncomplete;

  final num sampleRate;

  _RealtimeAnalyserNodeImpl createAnalyser() native;

  _BiquadFilterNodeImpl createBiquadFilter() native;

  _AudioBufferImpl createBuffer(var buffer_OR_numberOfChannels, var mixToMono_OR_numberOfFrames, [num sampleRate = null]) native;

  _AudioBufferSourceNodeImpl createBufferSource() native;

  _AudioChannelMergerImpl createChannelMerger() native;

  _AudioChannelSplitterImpl createChannelSplitter() native;

  _ConvolverNodeImpl createConvolver() native;

  _DelayNodeImpl createDelayNode([num maxDelayTime = null]) native;

  _DynamicsCompressorNodeImpl createDynamicsCompressor() native;

  _AudioGainNodeImpl createGainNode() native;

  _HighPass2FilterNodeImpl createHighPass2Filter() native;

  _JavaScriptAudioNodeImpl createJavaScriptNode(int bufferSize) native;

  _LowPass2FilterNodeImpl createLowPass2Filter() native;

  _MediaElementAudioSourceNodeImpl createMediaElementSource(_MediaElementImpl mediaElement) native;

  _AudioPannerNodeImpl createPanner() native;

  _WaveShaperNodeImpl createWaveShaper() native;

  void decodeAudioData(_ArrayBufferImpl audioData, AudioBufferCallback successCallback, [AudioBufferCallback errorCallback = null]) native;

  void startRendering() native;
}
