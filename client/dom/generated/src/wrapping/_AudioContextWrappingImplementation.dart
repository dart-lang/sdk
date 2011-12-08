// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _AudioContextWrappingImplementation extends DOMWrapperBase implements AudioContext {
  _AudioContextWrappingImplementation() : super() {}

  static create__AudioContextWrappingImplementation() native {
    return new _AudioContextWrappingImplementation();
  }

  num get currentTime() { return _get_currentTime(this); }
  static num _get_currentTime(var _this) native;

  AudioDestinationNode get destination() { return _get_destination(this); }
  static AudioDestinationNode _get_destination(var _this) native;

  AudioListener get listener() { return _get_listener(this); }
  static AudioListener _get_listener(var _this) native;

  num get sampleRate() { return _get_sampleRate(this); }
  static num _get_sampleRate(var _this) native;

  RealtimeAnalyserNode createAnalyser() {
    return _createAnalyser(this);
  }
  static RealtimeAnalyserNode _createAnalyser(receiver) native;

  BiquadFilterNode createBiquadFilter() {
    return _createBiquadFilter(this);
  }
  static BiquadFilterNode _createBiquadFilter(receiver) native;

  AudioBuffer createBuffer() {
    return _createBuffer(this);
  }
  static AudioBuffer _createBuffer(receiver) native;

  AudioBufferSourceNode createBufferSource() {
    return _createBufferSource(this);
  }
  static AudioBufferSourceNode _createBufferSource(receiver) native;

  AudioChannelMerger createChannelMerger() {
    return _createChannelMerger(this);
  }
  static AudioChannelMerger _createChannelMerger(receiver) native;

  AudioChannelSplitter createChannelSplitter() {
    return _createChannelSplitter(this);
  }
  static AudioChannelSplitter _createChannelSplitter(receiver) native;

  ConvolverNode createConvolver() {
    return _createConvolver(this);
  }
  static ConvolverNode _createConvolver(receiver) native;

  DelayNode createDelayNode() {
    return _createDelayNode(this);
  }
  static DelayNode _createDelayNode(receiver) native;

  DynamicsCompressorNode createDynamicsCompressor() {
    return _createDynamicsCompressor(this);
  }
  static DynamicsCompressorNode _createDynamicsCompressor(receiver) native;

  AudioGainNode createGainNode() {
    return _createGainNode(this);
  }
  static AudioGainNode _createGainNode(receiver) native;

  HighPass2FilterNode createHighPass2Filter() {
    return _createHighPass2Filter(this);
  }
  static HighPass2FilterNode _createHighPass2Filter(receiver) native;

  JavaScriptAudioNode createJavaScriptNode(int bufferSize) {
    return _createJavaScriptNode(this, bufferSize);
  }
  static JavaScriptAudioNode _createJavaScriptNode(receiver, bufferSize) native;

  LowPass2FilterNode createLowPass2Filter() {
    return _createLowPass2Filter(this);
  }
  static LowPass2FilterNode _createLowPass2Filter(receiver) native;

  AudioPannerNode createPanner() {
    return _createPanner(this);
  }
  static AudioPannerNode _createPanner(receiver) native;

  WaveShaperNode createWaveShaper() {
    return _createWaveShaper(this);
  }
  static WaveShaperNode _createWaveShaper(receiver) native;

  void decodeAudioData(ArrayBuffer audioData, AudioBufferCallback successCallback, [AudioBufferCallback errorCallback = null]) {
    if (errorCallback === null) {
      _decodeAudioData(this, audioData, successCallback);
      return;
    } else {
      _decodeAudioData_2(this, audioData, successCallback, errorCallback);
      return;
    }
  }
  static void _decodeAudioData(receiver, audioData, successCallback) native;
  static void _decodeAudioData_2(receiver, audioData, successCallback, errorCallback) native;

  void startRendering() {
    _startRendering(this);
    return;
  }
  static void _startRendering(receiver) native;

  String get typeName() { return "AudioContext"; }
}
