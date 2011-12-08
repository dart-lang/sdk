// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AudioContextWrappingImplementation extends DOMWrapperBase implements AudioContext {
  AudioContextWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get currentTime() { return _ptr.currentTime; }

  AudioDestinationNode get destination() { return LevelDom.wrapAudioDestinationNode(_ptr.destination); }

  AudioListener get listener() { return LevelDom.wrapAudioListener(_ptr.listener); }

  num get sampleRate() { return _ptr.sampleRate; }

  RealtimeAnalyserNode createAnalyser() {
    return LevelDom.wrapRealtimeAnalyserNode(_ptr.createAnalyser());
  }

  BiquadFilterNode createBiquadFilter() {
    return LevelDom.wrapBiquadFilterNode(_ptr.createBiquadFilter());
  }

  AudioBuffer createBuffer() {
    return LevelDom.wrapAudioBuffer(_ptr.createBuffer());
  }

  AudioBufferSourceNode createBufferSource() {
    return LevelDom.wrapAudioBufferSourceNode(_ptr.createBufferSource());
  }

  AudioChannelMerger createChannelMerger() {
    return LevelDom.wrapAudioChannelMerger(_ptr.createChannelMerger());
  }

  AudioChannelSplitter createChannelSplitter() {
    return LevelDom.wrapAudioChannelSplitter(_ptr.createChannelSplitter());
  }

  ConvolverNode createConvolver() {
    return LevelDom.wrapConvolverNode(_ptr.createConvolver());
  }

  DelayNode createDelayNode() {
    return LevelDom.wrapDelayNode(_ptr.createDelayNode());
  }

  DynamicsCompressorNode createDynamicsCompressor() {
    return LevelDom.wrapDynamicsCompressorNode(_ptr.createDynamicsCompressor());
  }

  AudioGainNode createGainNode() {
    return LevelDom.wrapAudioGainNode(_ptr.createGainNode());
  }

  HighPass2FilterNode createHighPass2Filter() {
    return LevelDom.wrapHighPass2FilterNode(_ptr.createHighPass2Filter());
  }

  JavaScriptAudioNode createJavaScriptNode(int bufferSize) {
    return LevelDom.wrapJavaScriptAudioNode(_ptr.createJavaScriptNode(bufferSize));
  }

  LowPass2FilterNode createLowPass2Filter() {
    return LevelDom.wrapLowPass2FilterNode(_ptr.createLowPass2Filter());
  }

  AudioPannerNode createPanner() {
    return LevelDom.wrapAudioPannerNode(_ptr.createPanner());
  }

  WaveShaperNode createWaveShaper() {
    return LevelDom.wrapWaveShaperNode(_ptr.createWaveShaper());
  }

  void decodeAudioData(ArrayBuffer audioData, AudioBufferCallback successCallback, [AudioBufferCallback errorCallback]) {
    if (errorCallback === null) {
      _ptr.decodeAudioData(LevelDom.unwrap(audioData), successCallback);
      return;
    } else {
      _ptr.decodeAudioData(LevelDom.unwrap(audioData), successCallback, errorCallback);
      return;
    }
  }

  void startRendering() {
    _ptr.startRendering();
    return;
  }
}
