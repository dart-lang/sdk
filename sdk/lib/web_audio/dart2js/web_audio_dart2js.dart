library web_audio;

import 'dart:async';
import 'dart:html';
import 'dart:html_common';
// DO NOT EDIT
// Auto-generated dart:audio library.




// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('AnalyserNode')
class AnalyserNode extends AudioNode native "*AnalyserNode" {

  /// @docsEditable true
  @DomName('AnalyserNode.fftSize')
  int fftSize;

  /// @docsEditable true
  @DomName('AnalyserNode.frequencyBinCount')
  final int frequencyBinCount;

  /// @docsEditable true
  @DomName('AnalyserNode.maxDecibels')
  num maxDecibels;

  /// @docsEditable true
  @DomName('AnalyserNode.minDecibels')
  num minDecibels;

  /// @docsEditable true
  @DomName('AnalyserNode.smoothingTimeConstant')
  num smoothingTimeConstant;

  /// @docsEditable true
  @DomName('AnalyserNode.getByteFrequencyData')
  void getByteFrequencyData(Uint8Array array) native;

  /// @docsEditable true
  @DomName('AnalyserNode.getByteTimeDomainData')
  void getByteTimeDomainData(Uint8Array array) native;

  /// @docsEditable true
  @DomName('AnalyserNode.getFloatFrequencyData')
  void getFloatFrequencyData(Float32Array array) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('AudioBuffer')
class AudioBuffer native "*AudioBuffer" {

  /// @docsEditable true
  @DomName('AudioBuffer.duration')
  final num duration;

  /// @docsEditable true
  @DomName('AudioBuffer.gain')
  num gain;

  /// @docsEditable true
  @DomName('AudioBuffer.length')
  final int length;

  /// @docsEditable true
  @DomName('AudioBuffer.numberOfChannels')
  final int numberOfChannels;

  /// @docsEditable true
  @DomName('AudioBuffer.sampleRate')
  final num sampleRate;

  /// @docsEditable true
  @DomName('AudioBuffer.getChannelData')
  Float32Array getChannelData(int channelIndex) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void AudioBufferCallback(AudioBuffer audioBuffer);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('AudioBufferSourceNode')
class AudioBufferSourceNode extends AudioSourceNode native "*AudioBufferSourceNode" {

  // TODO(efortuna): Remove these methods when Chrome stable also uses start
  // instead of noteOn.
  void start(num when, [num grainOffset, num grainDuration]) {
    if (JS('bool', '!!#.start', this)) {
      if (?grainDuration) {
        JS('void', '#.start(#, #, #)', this, when, grainOffset, grainDuration);
      } else if (?grainOffset) {
        JS('void', '#.start(#, #)', this, when, grainOffset);
      } else {
        JS('void', '#.start(#)', this, when);
      }
    } else {
      if (?grainDuration) {
        JS('void', '#.noteOn(#, #, #)', this, when, grainOffset, grainDuration);
      } else if (?grainOffset) {
        JS('void', '#.noteOn(#, #)', this, when, grainOffset);
      } else {
        JS('void', '#.noteOn(#)', this, when);
      }
    }
  }

  void stop(num when) {
    if (JS('bool', '!!#.stop', this)) {
      JS('void', '#.stop(#)', this, when);
    } else {
      JS('void', '#.noteOff(#)', this, when);
    }
  }

  static const int FINISHED_STATE = 3;

  static const int PLAYING_STATE = 2;

  static const int SCHEDULED_STATE = 1;

  static const int UNSCHEDULED_STATE = 0;

  /// @docsEditable true
  @DomName('AudioBufferSourceNode.buffer')
  AudioBuffer buffer;

  /// @docsEditable true
  @DomName('AudioBufferSourceNode.gain')
  final AudioGain gain;

  /// @docsEditable true
  @DomName('AudioBufferSourceNode.loop')
  bool loop;

  /// @docsEditable true
  @DomName('AudioBufferSourceNode.loopEnd')
  num loopEnd;

  /// @docsEditable true
  @DomName('AudioBufferSourceNode.loopStart')
  num loopStart;

  /// @docsEditable true
  @DomName('AudioBufferSourceNode.playbackRate')
  final AudioParam playbackRate;

  /// @docsEditable true
  @DomName('AudioBufferSourceNode.playbackState')
  final int playbackState;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('AudioContext')
class AudioContext extends EventTarget native "*AudioContext" {

  static const EventStreamProvider<Event> completeEvent = const EventStreamProvider<Event>('complete');

  /// @docsEditable true
  factory AudioContext() => AudioContext._create();

  /// @docsEditable true
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  AudioContextEvents get on =>
    new AudioContextEvents(this);

  /// @docsEditable true
  @DomName('AudioContext.activeSourceCount')
  final int activeSourceCount;

  /// @docsEditable true
  @DomName('AudioContext.currentTime')
  final num currentTime;

  /// @docsEditable true
  @DomName('AudioContext.destination')
  final AudioDestinationNode destination;

  /// @docsEditable true
  @DomName('AudioContext.listener')
  final AudioListener listener;

  /// @docsEditable true
  @DomName('AudioContext.sampleRate')
  final num sampleRate;

  /// @docsEditable true
  @DomName('AudioContext.createAnalyser')
  AnalyserNode createAnalyser() native;

  /// @docsEditable true
  @DomName('AudioContext.createBiquadFilter')
  BiquadFilterNode createBiquadFilter() native;

  /// @docsEditable true
  @DomName('AudioContext.createBuffer')
  AudioBuffer createBuffer(buffer_OR_numberOfChannels, mixToMono_OR_numberOfFrames, [num sampleRate]) native;

  /// @docsEditable true
  @DomName('AudioContext.createBufferSource')
  AudioBufferSourceNode createBufferSource() native;

  /// @docsEditable true
  @DomName('AudioContext.createChannelMerger')
  ChannelMergerNode createChannelMerger([int numberOfInputs]) native;

  /// @docsEditable true
  @DomName('AudioContext.createChannelSplitter')
  ChannelSplitterNode createChannelSplitter([int numberOfOutputs]) native;

  /// @docsEditable true
  @DomName('AudioContext.createConvolver')
  ConvolverNode createConvolver() native;

  /// @docsEditable true
  @DomName('AudioContext.createDelay')
  DelayNode createDelay([num maxDelayTime]) native;

  /// @docsEditable true
  @DomName('AudioContext.createDynamicsCompressor')
  DynamicsCompressorNode createDynamicsCompressor() native;

  /// @docsEditable true
  @DomName('AudioContext.createMediaElementSource')
  MediaElementAudioSourceNode createMediaElementSource(MediaElement mediaElement) native;

  /// @docsEditable true
  @DomName('AudioContext.createMediaStreamDestination')
  MediaStreamAudioDestinationNode createMediaStreamDestination() native;

  /// @docsEditable true
  @DomName('AudioContext.createMediaStreamSource')
  MediaStreamAudioSourceNode createMediaStreamSource(MediaStream mediaStream) native;

  /// @docsEditable true
  @DomName('AudioContext.createOscillator')
  OscillatorNode createOscillator() native;

  /// @docsEditable true
  @DomName('AudioContext.createPanner')
  PannerNode createPanner() native;

  /// @docsEditable true
  @DomName('AudioContext.createWaveShaper')
  WaveShaperNode createWaveShaper() native;

  /// @docsEditable true
  @DomName('AudioContext.createWaveTable')
  WaveTable createWaveTable(Float32Array real, Float32Array imag) native;

  /// @docsEditable true
  @DomName('AudioContext.decodeAudioData')
  void decodeAudioData(ArrayBuffer audioData, AudioBufferCallback successCallback, [AudioBufferCallback errorCallback]) native;

  /// @docsEditable true
  @DomName('AudioContext.startRendering')
  void startRendering() native;

  Stream<Event> get onComplete => completeEvent.forTarget(this);

  static AudioContext _create() => JS('AudioContext',
      'new (window.AudioContext || window.webkitAudioContext)()');

  GainNode createGain() {
    if (JS('bool', '#.createGain !== undefined', this)) {
      return JS('GainNode', '#.createGain()', this);
    } else {
      return JS('GainNode', '#.createGainNode()', this);
    }
  }

  ScriptProcessorNode createScriptProcessor(int bufferSize,
      [int numberOfInputChannels, int numberOfOutputChannels]) {
    var function = JS('dynamic', '#.createScriptProcessor || '
        '#.createJavaScriptNode', this, this);
    if (?numberOfOutputChannels) {
      return JS('ScriptProcessorNode', '#.call(#, #, #, #)', function, this,
          bufferSize, numberOfInputChannels, numberOfOutputChannels);
    } else if (?numberOfInputChannels) {
      return JS('ScriptProcessorNode', '#.call(#, #, #)', function, this,
          bufferSize, numberOfInputChannels);
    } else {
      return JS('ScriptProcessorNode', '#.call(#, #)', function, this,
          bufferSize);
    }
  }
}

/// @docsEditable true
class AudioContextEvents extends Events {
  /// @docsEditable true
  AudioContextEvents(EventTarget _ptr) : super(_ptr);

  /// @docsEditable true
  EventListenerList get complete => this['complete'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('AudioDestinationNode')
class AudioDestinationNode extends AudioNode native "*AudioDestinationNode" {

  /// @docsEditable true
  @DomName('AudioDestinationNode.numberOfChannels')
  final int numberOfChannels;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('AudioGain')
class AudioGain extends AudioParam native "*AudioGain" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('AudioListener')
class AudioListener native "*AudioListener" {

  /// @docsEditable true
  @DomName('AudioListener.dopplerFactor')
  num dopplerFactor;

  /// @docsEditable true
  @DomName('AudioListener.speedOfSound')
  num speedOfSound;

  /// @docsEditable true
  @DomName('AudioListener.setOrientation')
  void setOrientation(num x, num y, num z, num xUp, num yUp, num zUp) native;

  /// @docsEditable true
  @DomName('AudioListener.setPosition')
  void setPosition(num x, num y, num z) native;

  /// @docsEditable true
  @DomName('AudioListener.setVelocity')
  void setVelocity(num x, num y, num z) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('AudioNode')
class AudioNode native "*AudioNode" {

  /// @docsEditable true
  @DomName('AudioNode.context')
  final AudioContext context;

  /// @docsEditable true
  @DomName('AudioNode.numberOfInputs')
  final int numberOfInputs;

  /// @docsEditable true
  @DomName('AudioNode.numberOfOutputs')
  final int numberOfOutputs;

  /// @docsEditable true
  @DomName('AudioNode.connect')
  void connect(destination, int output, [int input]) native;

  /// @docsEditable true
  @DomName('AudioNode.disconnect')
  void disconnect(int output) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('AudioParam')
class AudioParam native "*AudioParam" {

  /// @docsEditable true
  @DomName('AudioParam.defaultValue')
  final num defaultValue;

  /// @docsEditable true
  @DomName('AudioParam.maxValue')
  final num maxValue;

  /// @docsEditable true
  @DomName('AudioParam.minValue')
  final num minValue;

  /// @docsEditable true
  @DomName('AudioParam.name')
  final String name;

  /// @docsEditable true
  @DomName('AudioParam.units')
  final int units;

  /// @docsEditable true
  @DomName('AudioParam.value')
  num value;

  /// @docsEditable true
  @DomName('AudioParam.cancelScheduledValues')
  void cancelScheduledValues(num startTime) native;

  /// @docsEditable true
  @DomName('AudioParam.exponentialRampToValueAtTime')
  void exponentialRampToValueAtTime(num value, num time) native;

  /// @docsEditable true
  @DomName('AudioParam.linearRampToValueAtTime')
  void linearRampToValueAtTime(num value, num time) native;

  /// @docsEditable true
  @DomName('AudioParam.setTargetAtTime')
  void setTargetAtTime(num target, num time, num timeConstant) native;

  /// @docsEditable true
  @DomName('AudioParam.setValueAtTime')
  void setValueAtTime(num value, num time) native;

  /// @docsEditable true
  @DomName('AudioParam.setValueCurveAtTime')
  void setValueCurveAtTime(Float32Array values, num time, num duration) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('AudioProcessingEvent')
class AudioProcessingEvent extends Event native "*AudioProcessingEvent" {

  /// @docsEditable true
  @DomName('AudioProcessingEvent.inputBuffer')
  final AudioBuffer inputBuffer;

  /// @docsEditable true
  @DomName('AudioProcessingEvent.outputBuffer')
  final AudioBuffer outputBuffer;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('AudioSourceNode')
class AudioSourceNode extends AudioNode native "*AudioSourceNode" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('BiquadFilterNode')
class BiquadFilterNode extends AudioNode native "*BiquadFilterNode" {

  static const int ALLPASS = 7;

  static const int BANDPASS = 2;

  static const int HIGHPASS = 1;

  static const int HIGHSHELF = 4;

  static const int LOWPASS = 0;

  static const int LOWSHELF = 3;

  static const int NOTCH = 6;

  static const int PEAKING = 5;

  /// @docsEditable true
  @DomName('BiquadFilterNode.Q')
  final AudioParam Q;

  /// @docsEditable true
  @DomName('BiquadFilterNode.detune')
  final AudioParam detune;

  /// @docsEditable true
  @DomName('BiquadFilterNode.frequency')
  final AudioParam frequency;

  /// @docsEditable true
  @DomName('BiquadFilterNode.gain')
  final AudioParam gain;

  /// @docsEditable true
  @DomName('BiquadFilterNode.type')
  int type;

  /// @docsEditable true
  @DomName('BiquadFilterNode.getFrequencyResponse')
  void getFrequencyResponse(Float32Array frequencyHz, Float32Array magResponse, Float32Array phaseResponse) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('ChannelMergerNode')
class ChannelMergerNode extends AudioNode native "*ChannelMergerNode" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('ChannelSplitterNode')
class ChannelSplitterNode extends AudioNode native "*ChannelSplitterNode" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('ConvolverNode')
class ConvolverNode extends AudioNode native "*ConvolverNode" {

  /// @docsEditable true
  @DomName('ConvolverNode.buffer')
  AudioBuffer buffer;

  /// @docsEditable true
  @DomName('ConvolverNode.normalize')
  bool normalize;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('DelayNode')
class DelayNode extends AudioNode native "*DelayNode" {

  /// @docsEditable true
  @DomName('DelayNode.delayTime')
  final AudioParam delayTime;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('DynamicsCompressorNode')
class DynamicsCompressorNode extends AudioNode native "*DynamicsCompressorNode" {

  /// @docsEditable true
  @DomName('DynamicsCompressorNode.attack')
  final AudioParam attack;

  /// @docsEditable true
  @DomName('DynamicsCompressorNode.knee')
  final AudioParam knee;

  /// @docsEditable true
  @DomName('DynamicsCompressorNode.ratio')
  final AudioParam ratio;

  /// @docsEditable true
  @DomName('DynamicsCompressorNode.reduction')
  final AudioParam reduction;

  /// @docsEditable true
  @DomName('DynamicsCompressorNode.release')
  final AudioParam release;

  /// @docsEditable true
  @DomName('DynamicsCompressorNode.threshold')
  final AudioParam threshold;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('GainNode')
class GainNode extends AudioNode native "*GainNode" {

  /// @docsEditable true
  @DomName('GainNode.gain')
  final AudioGain gain;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('MediaElementAudioSourceNode')
class MediaElementAudioSourceNode extends AudioSourceNode native "*MediaElementAudioSourceNode" {

  /// @docsEditable true
  @DomName('MediaElementAudioSourceNode.mediaElement')
  final MediaElement mediaElement;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('MediaStreamAudioDestinationNode')
class MediaStreamAudioDestinationNode extends AudioSourceNode native "*MediaStreamAudioDestinationNode" {

  /// @docsEditable true
  @DomName('MediaStreamAudioDestinationNode.stream')
  final MediaStream stream;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('MediaStreamAudioSourceNode')
class MediaStreamAudioSourceNode extends AudioSourceNode native "*MediaStreamAudioSourceNode" {

  /// @docsEditable true
  @DomName('MediaStreamAudioSourceNode.mediaStream')
  final MediaStream mediaStream;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('OfflineAudioCompletionEvent')
class OfflineAudioCompletionEvent extends Event native "*OfflineAudioCompletionEvent" {

  /// @docsEditable true
  @DomName('OfflineAudioCompletionEvent.renderedBuffer')
  final AudioBuffer renderedBuffer;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('OfflineAudioContext')
class OfflineAudioContext extends AudioContext implements EventTarget native "*OfflineAudioContext" {

  /// @docsEditable true
  factory OfflineAudioContext(int numberOfChannels, int numberOfFrames, num sampleRate) => OfflineAudioContext._create(numberOfChannels, numberOfFrames, sampleRate);
  static OfflineAudioContext _create(int numberOfChannels, int numberOfFrames, num sampleRate) => JS('OfflineAudioContext', 'new OfflineAudioContext(#,#,#)', numberOfChannels, numberOfFrames, sampleRate);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('OscillatorNode')
class OscillatorNode extends AudioSourceNode native "*OscillatorNode" {

  static const int CUSTOM = 4;

  static const int FINISHED_STATE = 3;

  static const int PLAYING_STATE = 2;

  static const int SAWTOOTH = 2;

  static const int SCHEDULED_STATE = 1;

  static const int SINE = 0;

  static const int SQUARE = 1;

  static const int TRIANGLE = 3;

  static const int UNSCHEDULED_STATE = 0;

  /// @docsEditable true
  @DomName('OscillatorNode.detune')
  final AudioParam detune;

  /// @docsEditable true
  @DomName('OscillatorNode.frequency')
  final AudioParam frequency;

  /// @docsEditable true
  @DomName('OscillatorNode.playbackState')
  final int playbackState;

  /// @docsEditable true
  @DomName('OscillatorNode.type')
  int type;

  /// @docsEditable true
  @DomName('OscillatorNode.setWaveTable')
  void setWaveTable(WaveTable waveTable) native;

  /// @docsEditable true
  @DomName('OscillatorNode.start')
  void start(num when) native;

  /// @docsEditable true
  @DomName('OscillatorNode.stop')
  void stop(num when) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('PannerNode')
class PannerNode extends AudioNode native "*PannerNode" {

  static const int EQUALPOWER = 0;

  static const int EXPONENTIAL_DISTANCE = 2;

  static const int HRTF = 1;

  static const int INVERSE_DISTANCE = 1;

  static const int LINEAR_DISTANCE = 0;

  static const int SOUNDFIELD = 2;

  /// @docsEditable true
  @DomName('PannerNode.coneInnerAngle')
  num coneInnerAngle;

  /// @docsEditable true
  @DomName('PannerNode.coneOuterAngle')
  num coneOuterAngle;

  /// @docsEditable true
  @DomName('PannerNode.coneOuterGain')
  num coneOuterGain;

  /// @docsEditable true
  @DomName('PannerNode.distanceModel')
  int distanceModel;

  /// @docsEditable true
  @DomName('PannerNode.maxDistance')
  num maxDistance;

  /// @docsEditable true
  @DomName('PannerNode.panningModel')
  int panningModel;

  /// @docsEditable true
  @DomName('PannerNode.refDistance')
  num refDistance;

  /// @docsEditable true
  @DomName('PannerNode.rolloffFactor')
  num rolloffFactor;

  /// @docsEditable true
  @DomName('PannerNode.setOrientation')
  void setOrientation(num x, num y, num z) native;

  /// @docsEditable true
  @DomName('PannerNode.setPosition')
  void setPosition(num x, num y, num z) native;

  /// @docsEditable true
  @DomName('PannerNode.setVelocity')
  void setVelocity(num x, num y, num z) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('ScriptProcessorNode')
class ScriptProcessorNode extends AudioNode implements EventTarget native "*ScriptProcessorNode" {

  /// @docsEditable true
  @DomName('ScriptProcessorNode.bufferSize')
  final int bufferSize;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('WaveShaperNode')
class WaveShaperNode extends AudioNode native "*WaveShaperNode" {

  /// @docsEditable true
  @DomName('WaveShaperNode.curve')
  Float32Array curve;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @docsEditable true
@DomName('WaveTable')
class WaveTable native "*WaveTable" {
}
