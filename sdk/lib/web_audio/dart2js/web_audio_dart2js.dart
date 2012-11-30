library web_audio;

import 'dart:html';
// DO NOT EDIT
// Auto-generated dart:audio library.




// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName AnalyserNode; @docsEditable true
class AnalyserNode extends AudioNode native "*AnalyserNode" {

  /// @domName AnalyserNode.fftSize; @docsEditable true
  int fftSize;

  /// @domName AnalyserNode.frequencyBinCount; @docsEditable true
  final int frequencyBinCount;

  /// @domName AnalyserNode.maxDecibels; @docsEditable true
  num maxDecibels;

  /// @domName AnalyserNode.minDecibels; @docsEditable true
  num minDecibels;

  /// @domName AnalyserNode.smoothingTimeConstant; @docsEditable true
  num smoothingTimeConstant;

  /// @domName AnalyserNode.getByteFrequencyData; @docsEditable true
  void getByteFrequencyData(Uint8Array array) native;

  /// @domName AnalyserNode.getByteTimeDomainData; @docsEditable true
  void getByteTimeDomainData(Uint8Array array) native;

  /// @domName AnalyserNode.getFloatFrequencyData; @docsEditable true
  void getFloatFrequencyData(Float32Array array) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName AudioBuffer; @docsEditable true
class AudioBuffer native "*AudioBuffer" {

  /// @domName AudioBuffer.duration; @docsEditable true
  final num duration;

  /// @domName AudioBuffer.gain; @docsEditable true
  num gain;

  /// @domName AudioBuffer.length; @docsEditable true
  final int length;

  /// @domName AudioBuffer.numberOfChannels; @docsEditable true
  final int numberOfChannels;

  /// @domName AudioBuffer.sampleRate; @docsEditable true
  final num sampleRate;

  /// @domName AudioBuffer.getChannelData; @docsEditable true
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


/// @domName AudioBufferSourceNode
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

  /// @domName AudioBufferSourceNode.buffer; @docsEditable true
  AudioBuffer buffer;

  /// @domName AudioBufferSourceNode.gain; @docsEditable true
  final AudioGain gain;

  /// @domName AudioBufferSourceNode.loop; @docsEditable true
  bool loop;

  /// @domName AudioBufferSourceNode.loopEnd; @docsEditable true
  num loopEnd;

  /// @domName AudioBufferSourceNode.loopStart; @docsEditable true
  num loopStart;

  /// @domName AudioBufferSourceNode.playbackRate; @docsEditable true
  final AudioParam playbackRate;

  /// @domName AudioBufferSourceNode.playbackState; @docsEditable true
  final int playbackState;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName AudioContext
class AudioContext extends EventTarget native "*AudioContext" {
  factory AudioContext() => JS('AudioContext',
      'new (window.AudioContext || window.webkitAudioContext)()');


  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  AudioContextEvents get on =>
    new AudioContextEvents(this);

  /// @domName AudioContext.activeSourceCount; @docsEditable true
  final int activeSourceCount;

  /// @domName AudioContext.currentTime; @docsEditable true
  final num currentTime;

  /// @domName AudioContext.destination; @docsEditable true
  final AudioDestinationNode destination;

  /// @domName AudioContext.listener; @docsEditable true
  final AudioListener listener;

  /// @domName AudioContext.sampleRate; @docsEditable true
  final num sampleRate;

  /// @domName AudioContext.createAnalyser; @docsEditable true
  AnalyserNode createAnalyser() native;

  /// @domName AudioContext.createBiquadFilter; @docsEditable true
  BiquadFilterNode createBiquadFilter() native;

  /// @domName AudioContext.createBuffer; @docsEditable true
  AudioBuffer createBuffer(buffer_OR_numberOfChannels, mixToMono_OR_numberOfFrames, [num sampleRate]) native;

  /// @domName AudioContext.createBufferSource; @docsEditable true
  AudioBufferSourceNode createBufferSource() native;

  /// @domName AudioContext.createChannelMerger; @docsEditable true
  ChannelMergerNode createChannelMerger([int numberOfInputs]) native;

  /// @domName AudioContext.createChannelSplitter; @docsEditable true
  ChannelSplitterNode createChannelSplitter([int numberOfOutputs]) native;

  /// @domName AudioContext.createConvolver; @docsEditable true
  ConvolverNode createConvolver() native;

  /// @domName AudioContext.createDelay; @docsEditable true
  DelayNode createDelay([num maxDelayTime]) native;

  /// @domName AudioContext.createDynamicsCompressor; @docsEditable true
  DynamicsCompressorNode createDynamicsCompressor() native;

  /// @domName AudioContext.createMediaElementSource; @docsEditable true
  MediaElementAudioSourceNode createMediaElementSource(MediaElement mediaElement) native;

  /// @domName AudioContext.createMediaStreamSource; @docsEditable true
  MediaStreamAudioSourceNode createMediaStreamSource(MediaStream mediaStream) native;

  /// @domName AudioContext.createOscillator; @docsEditable true
  OscillatorNode createOscillator() native;

  /// @domName AudioContext.createPanner; @docsEditable true
  PannerNode createPanner() native;

  /// @domName AudioContext.createWaveShaper; @docsEditable true
  WaveShaperNode createWaveShaper() native;

  /// @domName AudioContext.createWaveTable; @docsEditable true
  WaveTable createWaveTable(Float32Array real, Float32Array imag) native;

  /// @domName AudioContext.decodeAudioData; @docsEditable true
  void decodeAudioData(ArrayBuffer audioData, AudioBufferCallback successCallback, [AudioBufferCallback errorCallback]) native;

  /// @domName AudioContext.startRendering; @docsEditable true
  void startRendering() native;

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

class AudioContextEvents extends Events {
  AudioContextEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get complete => this['complete'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName AudioDestinationNode; @docsEditable true
class AudioDestinationNode extends AudioNode native "*AudioDestinationNode" {

  /// @domName AudioDestinationNode.numberOfChannels; @docsEditable true
  final int numberOfChannels;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLAudioElement; @docsEditable true
class AudioElement extends MediaElement native "*HTMLAudioElement" {

  factory AudioElement([String src]) {
    if (!?src) {
      return _AudioElementFactoryProvider.createAudioElement();
    }
    return _AudioElementFactoryProvider.createAudioElement(src);
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName AudioGain; @docsEditable true
class AudioGain extends AudioParam native "*AudioGain" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName AudioListener; @docsEditable true
class AudioListener native "*AudioListener" {

  /// @domName AudioListener.dopplerFactor; @docsEditable true
  num dopplerFactor;

  /// @domName AudioListener.speedOfSound; @docsEditable true
  num speedOfSound;

  /// @domName AudioListener.setOrientation; @docsEditable true
  void setOrientation(num x, num y, num z, num xUp, num yUp, num zUp) native;

  /// @domName AudioListener.setPosition; @docsEditable true
  void setPosition(num x, num y, num z) native;

  /// @domName AudioListener.setVelocity; @docsEditable true
  void setVelocity(num x, num y, num z) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName AudioNode; @docsEditable true
class AudioNode native "*AudioNode" {

  /// @domName AudioNode.context; @docsEditable true
  final AudioContext context;

  /// @domName AudioNode.numberOfInputs; @docsEditable true
  final int numberOfInputs;

  /// @domName AudioNode.numberOfOutputs; @docsEditable true
  final int numberOfOutputs;

  /// @domName AudioNode.connect; @docsEditable true
  void connect(destination, int output, [int input]) native;

  /// @domName AudioNode.disconnect; @docsEditable true
  void disconnect(int output) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName AudioParam; @docsEditable true
class AudioParam native "*AudioParam" {

  /// @domName AudioParam.defaultValue; @docsEditable true
  final num defaultValue;

  /// @domName AudioParam.maxValue; @docsEditable true
  final num maxValue;

  /// @domName AudioParam.minValue; @docsEditable true
  final num minValue;

  /// @domName AudioParam.name; @docsEditable true
  final String name;

  /// @domName AudioParam.units; @docsEditable true
  final int units;

  /// @domName AudioParam.value; @docsEditable true
  num value;

  /// @domName AudioParam.cancelScheduledValues; @docsEditable true
  void cancelScheduledValues(num startTime) native;

  /// @domName AudioParam.exponentialRampToValueAtTime; @docsEditable true
  void exponentialRampToValueAtTime(num value, num time) native;

  /// @domName AudioParam.linearRampToValueAtTime; @docsEditable true
  void linearRampToValueAtTime(num value, num time) native;

  /// @domName AudioParam.setTargetAtTime; @docsEditable true
  void setTargetAtTime(num target, num time, num timeConstant) native;

  /// @domName AudioParam.setValueAtTime; @docsEditable true
  void setValueAtTime(num value, num time) native;

  /// @domName AudioParam.setValueCurveAtTime; @docsEditable true
  void setValueCurveAtTime(Float32Array values, num time, num duration) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName AudioProcessingEvent; @docsEditable true
class AudioProcessingEvent extends Event native "*AudioProcessingEvent" {

  /// @domName AudioProcessingEvent.inputBuffer; @docsEditable true
  final AudioBuffer inputBuffer;

  /// @domName AudioProcessingEvent.outputBuffer; @docsEditable true
  final AudioBuffer outputBuffer;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName AudioSourceNode; @docsEditable true
class AudioSourceNode extends AudioNode native "*AudioSourceNode" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName BiquadFilterNode; @docsEditable true
class BiquadFilterNode extends AudioNode native "*BiquadFilterNode" {

  static const int ALLPASS = 7;

  static const int BANDPASS = 2;

  static const int HIGHPASS = 1;

  static const int HIGHSHELF = 4;

  static const int LOWPASS = 0;

  static const int LOWSHELF = 3;

  static const int NOTCH = 6;

  static const int PEAKING = 5;

  /// @domName BiquadFilterNode.Q; @docsEditable true
  final AudioParam Q;

  /// @domName BiquadFilterNode.frequency; @docsEditable true
  final AudioParam frequency;

  /// @domName BiquadFilterNode.gain; @docsEditable true
  final AudioParam gain;

  /// @domName BiquadFilterNode.type; @docsEditable true
  int type;

  /// @domName BiquadFilterNode.getFrequencyResponse; @docsEditable true
  void getFrequencyResponse(Float32Array frequencyHz, Float32Array magResponse, Float32Array phaseResponse) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName ChannelMergerNode; @docsEditable true
class ChannelMergerNode extends AudioNode native "*ChannelMergerNode" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName ChannelSplitterNode; @docsEditable true
class ChannelSplitterNode extends AudioNode native "*ChannelSplitterNode" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName ConvolverNode; @docsEditable true
class ConvolverNode extends AudioNode native "*ConvolverNode" {

  /// @domName ConvolverNode.buffer; @docsEditable true
  AudioBuffer buffer;

  /// @domName ConvolverNode.normalize; @docsEditable true
  bool normalize;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName DelayNode; @docsEditable true
class DelayNode extends AudioNode native "*DelayNode" {

  /// @domName DelayNode.delayTime; @docsEditable true
  final AudioParam delayTime;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName DynamicsCompressorNode; @docsEditable true
class DynamicsCompressorNode extends AudioNode native "*DynamicsCompressorNode" {

  /// @domName DynamicsCompressorNode.attack; @docsEditable true
  final AudioParam attack;

  /// @domName DynamicsCompressorNode.knee; @docsEditable true
  final AudioParam knee;

  /// @domName DynamicsCompressorNode.ratio; @docsEditable true
  final AudioParam ratio;

  /// @domName DynamicsCompressorNode.reduction; @docsEditable true
  final AudioParam reduction;

  /// @domName DynamicsCompressorNode.release; @docsEditable true
  final AudioParam release;

  /// @domName DynamicsCompressorNode.threshold; @docsEditable true
  final AudioParam threshold;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName GainNode; @docsEditable true
class GainNode extends AudioNode native "*GainNode" {

  /// @domName GainNode.gain; @docsEditable true
  final AudioGain gain;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName MediaElementAudioSourceNode; @docsEditable true
class MediaElementAudioSourceNode extends AudioSourceNode native "*MediaElementAudioSourceNode" {

  /// @domName MediaElementAudioSourceNode.mediaElement; @docsEditable true
  final MediaElement mediaElement;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName MediaStreamAudioSourceNode; @docsEditable true
class MediaStreamAudioSourceNode extends AudioSourceNode native "*MediaStreamAudioSourceNode" {

  /// @domName MediaStreamAudioSourceNode.mediaStream; @docsEditable true
  final MediaStream mediaStream;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName OfflineAudioCompletionEvent; @docsEditable true
class OfflineAudioCompletionEvent extends Event native "*OfflineAudioCompletionEvent" {

  /// @domName OfflineAudioCompletionEvent.renderedBuffer; @docsEditable true
  final AudioBuffer renderedBuffer;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName OscillatorNode; @docsEditable true
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

  /// @domName OscillatorNode.detune; @docsEditable true
  final AudioParam detune;

  /// @domName OscillatorNode.frequency; @docsEditable true
  final AudioParam frequency;

  /// @domName OscillatorNode.playbackState; @docsEditable true
  final int playbackState;

  /// @domName OscillatorNode.type; @docsEditable true
  int type;

  /// @domName OscillatorNode.setWaveTable; @docsEditable true
  void setWaveTable(WaveTable waveTable) native;

  /// @domName OscillatorNode.start; @docsEditable true
  void start(num when) native;

  /// @domName OscillatorNode.stop; @docsEditable true
  void stop(num when) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName PannerNode; @docsEditable true
class PannerNode extends AudioNode native "*PannerNode" {

  static const int EQUALPOWER = 0;

  static const int EXPONENTIAL_DISTANCE = 2;

  static const int HRTF = 1;

  static const int INVERSE_DISTANCE = 1;

  static const int LINEAR_DISTANCE = 0;

  static const int SOUNDFIELD = 2;

  /// @domName PannerNode.coneGain; @docsEditable true
  final AudioGain coneGain;

  /// @domName PannerNode.coneInnerAngle; @docsEditable true
  num coneInnerAngle;

  /// @domName PannerNode.coneOuterAngle; @docsEditable true
  num coneOuterAngle;

  /// @domName PannerNode.coneOuterGain; @docsEditable true
  num coneOuterGain;

  /// @domName PannerNode.distanceGain; @docsEditable true
  final AudioGain distanceGain;

  /// @domName PannerNode.distanceModel; @docsEditable true
  int distanceModel;

  /// @domName PannerNode.maxDistance; @docsEditable true
  num maxDistance;

  /// @domName PannerNode.panningModel; @docsEditable true
  int panningModel;

  /// @domName PannerNode.refDistance; @docsEditable true
  num refDistance;

  /// @domName PannerNode.rolloffFactor; @docsEditable true
  num rolloffFactor;

  /// @domName PannerNode.setOrientation; @docsEditable true
  void setOrientation(num x, num y, num z) native;

  /// @domName PannerNode.setPosition; @docsEditable true
  void setPosition(num x, num y, num z) native;

  /// @domName PannerNode.setVelocity; @docsEditable true
  void setVelocity(num x, num y, num z) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName ScriptProcessorNode; @docsEditable true
class ScriptProcessorNode extends AudioNode implements EventTarget native "*ScriptProcessorNode" {

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  ScriptProcessorNodeEvents get on =>
    new ScriptProcessorNodeEvents(this);

  /// @domName ScriptProcessorNode.bufferSize; @docsEditable true
  final int bufferSize;
}

class ScriptProcessorNodeEvents extends Events {
  ScriptProcessorNodeEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get audioProcess => this['audioprocess'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WaveShaperNode; @docsEditable true
class WaveShaperNode extends AudioNode native "*WaveShaperNode" {

  /// @domName WaveShaperNode.curve; @docsEditable true
  Float32Array curve;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _AudioElementFactoryProvider {
  static AudioElement createAudioElement([String src = null]) {
    if (src == null) return JS('AudioElement', 'new Audio()');
    return JS('AudioElement', 'new Audio(#)', src);
  }
}
