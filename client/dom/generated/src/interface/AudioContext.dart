// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioContext factory _AudioContextFactoryProvider {

  AudioContext();

  num get currentTime();

  AudioDestinationNode get destination();

  AudioListener get listener();

  num get sampleRate();

  RealtimeAnalyserNode createAnalyser();

  BiquadFilterNode createBiquadFilter();

  AudioBuffer createBuffer();

  AudioBufferSourceNode createBufferSource();

  AudioChannelMerger createChannelMerger();

  AudioChannelSplitter createChannelSplitter();

  ConvolverNode createConvolver();

  DelayNode createDelayNode();

  DynamicsCompressorNode createDynamicsCompressor();

  AudioGainNode createGainNode();

  HighPass2FilterNode createHighPass2Filter();

  JavaScriptAudioNode createJavaScriptNode(int bufferSize);

  LowPass2FilterNode createLowPass2Filter();

  AudioPannerNode createPanner();

  WaveShaperNode createWaveShaper();

  void decodeAudioData(ArrayBuffer audioData, AudioBufferCallback successCallback, [AudioBufferCallback errorCallback]);

  void startRendering();
}
