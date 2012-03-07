// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioContext {

  final num currentTime;

  final AudioDestinationNode destination;

  final AudioListener listener;

  EventListener oncomplete;

  final num sampleRate;

  RealtimeAnalyserNode createAnalyser();

  BiquadFilterNode createBiquadFilter();

  AudioBuffer createBuffer(var buffer_OR_numberOfChannels, var mixToMono_OR_numberOfFrames, [num sampleRate]);

  AudioBufferSourceNode createBufferSource();

  AudioChannelMerger createChannelMerger();

  AudioChannelSplitter createChannelSplitter();

  ConvolverNode createConvolver();

  DelayNode createDelayNode([num maxDelayTime]);

  DynamicsCompressorNode createDynamicsCompressor();

  AudioGainNode createGainNode();

  HighPass2FilterNode createHighPass2Filter();

  JavaScriptAudioNode createJavaScriptNode(int bufferSize);

  LowPass2FilterNode createLowPass2Filter();

  MediaElementAudioSourceNode createMediaElementSource(MediaElement mediaElement);

  AudioPannerNode createPanner();

  WaveShaperNode createWaveShaper();

  void decodeAudioData(ArrayBuffer audioData, AudioBufferCallback successCallback, [AudioBufferCallback errorCallback]);

  void startRendering();
}
