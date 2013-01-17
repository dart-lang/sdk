library web_audio;

import 'dart:async';
import 'dart:html';
import 'dart:html_common';
// DO NOT EDIT
// Auto-generated dart:audio library.




// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('AnalyserNode')
class AnalyserNode extends AudioNode native "*AnalyserNode" {

  @DocsEditable
  @DomName('AnalyserNode.fftSize')
  int fftSize;

  @DocsEditable
  @DomName('AnalyserNode.frequencyBinCount')
  final int frequencyBinCount;

  @DocsEditable
  @DomName('AnalyserNode.maxDecibels')
  num maxDecibels;

  @DocsEditable
  @DomName('AnalyserNode.minDecibels')
  num minDecibels;

  @DocsEditable
  @DomName('AnalyserNode.smoothingTimeConstant')
  num smoothingTimeConstant;

  @DocsEditable
  @DomName('AnalyserNode.getByteFrequencyData')
  void getByteFrequencyData(Uint8Array array) native;

  @DocsEditable
  @DomName('AnalyserNode.getByteTimeDomainData')
  void getByteTimeDomainData(Uint8Array array) native;

  @DocsEditable
  @DomName('AnalyserNode.getFloatFrequencyData')
  void getFloatFrequencyData(Float32Array array) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('AudioBuffer')
class AudioBuffer native "*AudioBuffer" {

  @DocsEditable
  @DomName('AudioBuffer.duration')
  final num duration;

  @DocsEditable
  @DomName('AudioBuffer.gain')
  num gain;

  @DocsEditable
  @DomName('AudioBuffer.length')
  final int length;

  @DocsEditable
  @DomName('AudioBuffer.numberOfChannels')
  final int numberOfChannels;

  @DocsEditable
  @DomName('AudioBuffer.sampleRate')
  final num sampleRate;

  @DocsEditable
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


@DocsEditable
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

  @DocsEditable
  @DomName('AudioBufferSourceNode.buffer')
  AudioBuffer buffer;

  @DocsEditable
  @DomName('AudioBufferSourceNode.gain')
  final AudioGain gain;

  @DocsEditable
  @DomName('AudioBufferSourceNode.loop')
  bool loop;

  @DocsEditable
  @DomName('AudioBufferSourceNode.loopEnd')
  num loopEnd;

  @DocsEditable
  @DomName('AudioBufferSourceNode.loopStart')
  num loopStart;

  @DocsEditable
  @DomName('AudioBufferSourceNode.playbackRate')
  final AudioParam playbackRate;

  @DocsEditable
  @DomName('AudioBufferSourceNode.playbackState')
  final int playbackState;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('AudioContext')
class AudioContext extends EventTarget native "*AudioContext" {

  static const EventStreamProvider<Event> completeEvent = const EventStreamProvider<Event>('complete');

  @DocsEditable
  factory AudioContext() => AudioContext._create();

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  AudioContextEvents get on =>
    new AudioContextEvents(this);

  @DocsEditable
  @DomName('AudioContext.activeSourceCount')
  final int activeSourceCount;

  @DocsEditable
  @DomName('AudioContext.currentTime')
  final num currentTime;

  @DocsEditable
  @DomName('AudioContext.destination')
  final AudioDestinationNode destination;

  @DocsEditable
  @DomName('AudioContext.listener')
  final AudioListener listener;

  @DocsEditable
  @DomName('AudioContext.sampleRate')
  final num sampleRate;

  @DocsEditable
  @DomName('AudioContext.createAnalyser')
  AnalyserNode createAnalyser() native;

  @DocsEditable
  @DomName('AudioContext.createBiquadFilter')
  BiquadFilterNode createBiquadFilter() native;

  @DocsEditable
  @DomName('AudioContext.createBuffer')
  AudioBuffer createBuffer(buffer_OR_numberOfChannels, mixToMono_OR_numberOfFrames, [num sampleRate]) native;

  @DocsEditable
  @DomName('AudioContext.createBufferSource')
  AudioBufferSourceNode createBufferSource() native;

  @DocsEditable
  @DomName('AudioContext.createChannelMerger')
  ChannelMergerNode createChannelMerger([int numberOfInputs]) native;

  @DocsEditable
  @DomName('AudioContext.createChannelSplitter')
  ChannelSplitterNode createChannelSplitter([int numberOfOutputs]) native;

  @DocsEditable
  @DomName('AudioContext.createConvolver')
  ConvolverNode createConvolver() native;

  @DocsEditable
  @DomName('AudioContext.createDelay')
  DelayNode createDelay([num maxDelayTime]) native;

  @DocsEditable
  @DomName('AudioContext.createDynamicsCompressor')
  DynamicsCompressorNode createDynamicsCompressor() native;

  @DocsEditable
  @DomName('AudioContext.createMediaElementSource')
  MediaElementAudioSourceNode createMediaElementSource(MediaElement mediaElement) native;

  @DocsEditable
  @DomName('AudioContext.createMediaStreamDestination')
  MediaStreamAudioDestinationNode createMediaStreamDestination() native;

  @DocsEditable
  @DomName('AudioContext.createMediaStreamSource')
  MediaStreamAudioSourceNode createMediaStreamSource(MediaStream mediaStream) native;

  @DocsEditable
  @DomName('AudioContext.createOscillator')
  OscillatorNode createOscillator() native;

  @DocsEditable
  @DomName('AudioContext.createPanner')
  PannerNode createPanner() native;

  @DocsEditable
  @DomName('AudioContext.createWaveShaper')
  WaveShaperNode createWaveShaper() native;

  @DocsEditable
  @DomName('AudioContext.createWaveTable')
  WaveTable createWaveTable(Float32Array real, Float32Array imag) native;

  @DocsEditable
  @DomName('AudioContext.decodeAudioData')
  void decodeAudioData(ArrayBuffer audioData, AudioBufferCallback successCallback, [AudioBufferCallback errorCallback]) native;

  @DocsEditable
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

@DocsEditable
class AudioContextEvents extends Events {
  @DocsEditable
  AudioContextEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get complete => this['complete'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('AudioDestinationNode')
class AudioDestinationNode extends AudioNode native "*AudioDestinationNode" {

  @DocsEditable
  @DomName('AudioDestinationNode.numberOfChannels')
  final int numberOfChannels;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('AudioGain')
class AudioGain extends AudioParam native "*AudioGain" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('AudioListener')
class AudioListener native "*AudioListener" {

  @DocsEditable
  @DomName('AudioListener.dopplerFactor')
  num dopplerFactor;

  @DocsEditable
  @DomName('AudioListener.speedOfSound')
  num speedOfSound;

  @DocsEditable
  @DomName('AudioListener.setOrientation')
  void setOrientation(num x, num y, num z, num xUp, num yUp, num zUp) native;

  @DocsEditable
  @DomName('AudioListener.setPosition')
  void setPosition(num x, num y, num z) native;

  @DocsEditable
  @DomName('AudioListener.setVelocity')
  void setVelocity(num x, num y, num z) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('AudioNode')
class AudioNode native "*AudioNode" {

  @DocsEditable
  @DomName('AudioNode.context')
  final AudioContext context;

  @DocsEditable
  @DomName('AudioNode.numberOfInputs')
  final int numberOfInputs;

  @DocsEditable
  @DomName('AudioNode.numberOfOutputs')
  final int numberOfOutputs;

  @DocsEditable
  @DomName('AudioNode.connect')
  void connect(destination, int output, [int input]) native;

  @DocsEditable
  @DomName('AudioNode.disconnect')
  void disconnect(int output) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('AudioParam')
class AudioParam native "*AudioParam" {

  @DocsEditable
  @DomName('AudioParam.defaultValue')
  final num defaultValue;

  @DocsEditable
  @DomName('AudioParam.maxValue')
  final num maxValue;

  @DocsEditable
  @DomName('AudioParam.minValue')
  final num minValue;

  @DocsEditable
  @DomName('AudioParam.name')
  final String name;

  @DocsEditable
  @DomName('AudioParam.units')
  final int units;

  @DocsEditable
  @DomName('AudioParam.value')
  num value;

  @DocsEditable
  @DomName('AudioParam.cancelScheduledValues')
  void cancelScheduledValues(num startTime) native;

  @DocsEditable
  @DomName('AudioParam.exponentialRampToValueAtTime')
  void exponentialRampToValueAtTime(num value, num time) native;

  @DocsEditable
  @DomName('AudioParam.linearRampToValueAtTime')
  void linearRampToValueAtTime(num value, num time) native;

  @DocsEditable
  @DomName('AudioParam.setTargetAtTime')
  void setTargetAtTime(num target, num time, num timeConstant) native;

  @DocsEditable
  @DomName('AudioParam.setValueAtTime')
  void setValueAtTime(num value, num time) native;

  @DocsEditable
  @DomName('AudioParam.setValueCurveAtTime')
  void setValueCurveAtTime(Float32Array values, num time, num duration) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('AudioProcessingEvent')
class AudioProcessingEvent extends Event native "*AudioProcessingEvent" {

  @DocsEditable
  @DomName('AudioProcessingEvent.inputBuffer')
  final AudioBuffer inputBuffer;

  @DocsEditable
  @DomName('AudioProcessingEvent.outputBuffer')
  final AudioBuffer outputBuffer;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('AudioSourceNode')
class AudioSourceNode extends AudioNode native "*AudioSourceNode" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
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

  @DocsEditable
  @DomName('BiquadFilterNode.Q')
  final AudioParam Q;

  @DocsEditable
  @DomName('BiquadFilterNode.detune')
  final AudioParam detune;

  @DocsEditable
  @DomName('BiquadFilterNode.frequency')
  final AudioParam frequency;

  @DocsEditable
  @DomName('BiquadFilterNode.gain')
  final AudioParam gain;

  @DocsEditable
  @DomName('BiquadFilterNode.type')
  String type;

  @DocsEditable
  @DomName('BiquadFilterNode.getFrequencyResponse')
  void getFrequencyResponse(Float32Array frequencyHz, Float32Array magResponse, Float32Array phaseResponse) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('ChannelMergerNode')
class ChannelMergerNode extends AudioNode native "*ChannelMergerNode" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('ChannelSplitterNode')
class ChannelSplitterNode extends AudioNode native "*ChannelSplitterNode" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('ConvolverNode')
class ConvolverNode extends AudioNode native "*ConvolverNode" {

  @DocsEditable
  @DomName('ConvolverNode.buffer')
  AudioBuffer buffer;

  @DocsEditable
  @DomName('ConvolverNode.normalize')
  bool normalize;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('DelayNode')
class DelayNode extends AudioNode native "*DelayNode" {

  @DocsEditable
  @DomName('DelayNode.delayTime')
  final AudioParam delayTime;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('DynamicsCompressorNode')
class DynamicsCompressorNode extends AudioNode native "*DynamicsCompressorNode" {

  @DocsEditable
  @DomName('DynamicsCompressorNode.attack')
  final AudioParam attack;

  @DocsEditable
  @DomName('DynamicsCompressorNode.knee')
  final AudioParam knee;

  @DocsEditable
  @DomName('DynamicsCompressorNode.ratio')
  final AudioParam ratio;

  @DocsEditable
  @DomName('DynamicsCompressorNode.reduction')
  final AudioParam reduction;

  @DocsEditable
  @DomName('DynamicsCompressorNode.release')
  final AudioParam release;

  @DocsEditable
  @DomName('DynamicsCompressorNode.threshold')
  final AudioParam threshold;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('GainNode')
class GainNode extends AudioNode native "*GainNode" {

  @DocsEditable
  @DomName('GainNode.gain')
  final AudioGain gain;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('MediaElementAudioSourceNode')
class MediaElementAudioSourceNode extends AudioSourceNode native "*MediaElementAudioSourceNode" {

  @DocsEditable
  @DomName('MediaElementAudioSourceNode.mediaElement')
  final MediaElement mediaElement;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('MediaStreamAudioDestinationNode')
class MediaStreamAudioDestinationNode extends AudioSourceNode native "*MediaStreamAudioDestinationNode" {

  @DocsEditable
  @DomName('MediaStreamAudioDestinationNode.stream')
  final MediaStream stream;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('MediaStreamAudioSourceNode')
class MediaStreamAudioSourceNode extends AudioSourceNode native "*MediaStreamAudioSourceNode" {

  @DocsEditable
  @DomName('MediaStreamAudioSourceNode.mediaStream')
  final MediaStream mediaStream;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('OfflineAudioCompletionEvent')
class OfflineAudioCompletionEvent extends Event native "*OfflineAudioCompletionEvent" {

  @DocsEditable
  @DomName('OfflineAudioCompletionEvent.renderedBuffer')
  final AudioBuffer renderedBuffer;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('OfflineAudioContext')
class OfflineAudioContext extends AudioContext implements EventTarget native "*OfflineAudioContext" {

  @DocsEditable
  factory OfflineAudioContext(int numberOfChannels, int numberOfFrames, num sampleRate) => OfflineAudioContext._create(numberOfChannels, numberOfFrames, sampleRate);
  static OfflineAudioContext _create(int numberOfChannels, int numberOfFrames, num sampleRate) => JS('OfflineAudioContext', 'new OfflineAudioContext(#,#,#)', numberOfChannels, numberOfFrames, sampleRate);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
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

  @DocsEditable
  @DomName('OscillatorNode.detune')
  final AudioParam detune;

  @DocsEditable
  @DomName('OscillatorNode.frequency')
  final AudioParam frequency;

  @DocsEditable
  @DomName('OscillatorNode.playbackState')
  final int playbackState;

  @DocsEditable
  @DomName('OscillatorNode.type')
  String type;

  @DocsEditable
  @DomName('OscillatorNode.setWaveTable')
  void setWaveTable(WaveTable waveTable) native;

  @DocsEditable
  @DomName('OscillatorNode.start')
  void start(num when) native;

  @DocsEditable
  @DomName('OscillatorNode.stop')
  void stop(num when) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('PannerNode')
class PannerNode extends AudioNode native "*PannerNode" {

  static const int EQUALPOWER = 0;

  static const int EXPONENTIAL_DISTANCE = 2;

  static const int HRTF = 1;

  static const int INVERSE_DISTANCE = 1;

  static const int LINEAR_DISTANCE = 0;

  static const int SOUNDFIELD = 2;

  @DocsEditable
  @DomName('PannerNode.coneInnerAngle')
  num coneInnerAngle;

  @DocsEditable
  @DomName('PannerNode.coneOuterAngle')
  num coneOuterAngle;

  @DocsEditable
  @DomName('PannerNode.coneOuterGain')
  num coneOuterGain;

  @DocsEditable
  @DomName('PannerNode.distanceModel')
  String distanceModel;

  @DocsEditable
  @DomName('PannerNode.maxDistance')
  num maxDistance;

  @DocsEditable
  @DomName('PannerNode.panningModel')
  String panningModel;

  @DocsEditable
  @DomName('PannerNode.refDistance')
  num refDistance;

  @DocsEditable
  @DomName('PannerNode.rolloffFactor')
  num rolloffFactor;

  @DocsEditable
  @DomName('PannerNode.setOrientation')
  void setOrientation(num x, num y, num z) native;

  @DocsEditable
  @DomName('PannerNode.setPosition')
  void setPosition(num x, num y, num z) native;

  @DocsEditable
  @DomName('PannerNode.setVelocity')
  void setVelocity(num x, num y, num z) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('ScriptProcessorNode')
class ScriptProcessorNode extends AudioNode implements EventTarget native "*ScriptProcessorNode" {

  @DocsEditable
  @DomName('ScriptProcessorNode.bufferSize')
  final int bufferSize;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('WaveShaperNode')
class WaveShaperNode extends AudioNode native "*WaveShaperNode" {

  @DocsEditable
  @DomName('WaveShaperNode.curve')
  Float32Array curve;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('WaveTable')
class WaveTable native "*WaveTable" {
}
