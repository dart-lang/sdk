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

  ///@docsEditable true
  factory AudioContext() => AudioContext._create();
  static AudioContext _create() => JS('AudioContext',
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

  /// @domName AudioContext.createMediaStreamDestination; @docsEditable true
  MediaStreamAudioDestinationNode createMediaStreamDestination() native;

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


/// @domName AudioDestinationNode; @docsEditable true
class AudioDestinationNode extends AudioNode native "*AudioDestinationNode" {

  /// @domName AudioDestinationNode.numberOfChannels; @docsEditable true
  final int numberOfChannels;
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

  /// @domName BiquadFilterNode.detune; @docsEditable true
  final AudioParam detune;

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


/// @domName MediaStreamAudioDestinationNode; @docsEditable true
class MediaStreamAudioDestinationNode extends AudioSourceNode native "*MediaStreamAudioDestinationNode" {

  /// @domName MediaStreamAudioDestinationNode.stream; @docsEditable true
  final MediaStream stream;
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


/// @domName OfflineAudioContext; @docsEditable true
class OfflineAudioContext extends AudioContext implements EventTarget native "*OfflineAudioContext" {

  ///@docsEditable true
  factory OfflineAudioContext(int numberOfChannels, int numberOfFrames, num sampleRate) => OfflineAudioContext._create(numberOfChannels, numberOfFrames, sampleRate);
  static OfflineAudioContext _create(int numberOfChannels, int numberOfFrames, num sampleRate) => JS('OfflineAudioContext', 'new OfflineAudioContext(#,#,#)', numberOfChannels, numberOfFrames, sampleRate);
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

  /// @domName PannerNode.coneInnerAngle; @docsEditable true
  num coneInnerAngle;

  /// @domName PannerNode.coneOuterAngle; @docsEditable true
  num coneOuterAngle;

  /// @domName PannerNode.coneOuterGain; @docsEditable true
  num coneOuterGain;

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

  /// @domName ScriptProcessorNode.bufferSize; @docsEditable true
  final int bufferSize;
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


/// @domName WaveTable; @docsEditable true
class WaveTable native "*WaveTable" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Window
class Window extends EventTarget implements WindowBase native "@*DOMWindow" {

  Document get document => JS('Document', '#.document', this);

  WindowBase _open2(url, name) => JS('Window', '#.open(#,#)', this, url, name);

  WindowBase _open3(url, name, options) =>
      JS('Window', '#.open(#,#,#)', this, url, name, options);

  WindowBase open(String url, String name, [String options]) {
    if (options == null) {
      return _DOMWindowCrossFrame._createSafe(_open2(url, name));
    } else {
      return _DOMWindowCrossFrame._createSafe(_open3(url, name, options));
    }
  }

  // API level getter and setter for Location.
  // TODO: The cross domain safe wrapper can be inserted here or folded into
  // _LocationWrapper.
  Location get location {
    // Firefox work-around for Location.  The Firefox location object cannot be
    // made to behave like a Dart object so must be wrapped.
    var result = _location;
    if (_isDartLocation(result)) return result;  // e.g. on Chrome.
    if (null == _location_wrapper) {
      _location_wrapper = new _LocationWrapper(result);
    }
    return _location_wrapper;
  }

  // TODO: consider forcing users to do: window.location.assign('string').
  /**
   * Sets the window's location, which causes the browser to navigate to the new
   * location. [value] may be a Location object or a string.
   */
  void set location(value) {
    if (value is _LocationWrapper) {
      _location = value._ptr;
    } else {
      _location = value;
    }
  }

  _LocationWrapper _location_wrapper;  // Cached wrapped Location object.

  // Native getter and setter to access raw Location object.
  dynamic get _location => JS('Location|=Object', '#.location', this);
  void set _location(value) {
    JS('void', '#.location = #', this, value);
  }
  // Prevent compiled from thinking 'location' property is available for a Dart
  // member.
  @JSName('location')
  _protect_location() native;

  static _isDartLocation(thing) {
    // On Firefox the code that implements 'is Location' fails to find the patch
    // stub on Object.prototype and throws an exception.
    try {
      return thing is Location;
    } catch (e) {
      return false;
    }
  }

  /**
   * Executes a [callback] after the next batch of browser layout measurements
   * has completed or would have completed if any browser layout measurements
   * had been scheduled.
   */
  void requestLayoutFrame(TimeoutHandler callback) {
    _addMeasurementFrameCallback(callback);
  }

  /** @domName DOMWindow.requestAnimationFrame */
  int requestAnimationFrame(RequestAnimationFrameCallback callback) {
    _ensureRequestAnimationFrame();
    return _requestAnimationFrame(callback);
  }

  void cancelAnimationFrame(id) {
    _ensureRequestAnimationFrame();
    _cancelAnimationFrame(id);
  }

  @JSName('requestAnimationFrame')
  int _requestAnimationFrame(RequestAnimationFrameCallback callback) native;

  @JSName('cancelAnimationFrame')
  void _cancelAnimationFrame(int id) native;

  _ensureRequestAnimationFrame() {
    if (JS('bool',
           '!!(#.requestAnimationFrame && #.cancelAnimationFrame)', this, this))
      return;

    JS('void',
       r"""
  (function($this) {
   var vendors = ['ms', 'moz', 'webkit', 'o'];
   for (var i = 0; i < vendors.length && !$this.requestAnimationFrame; ++i) {
     $this.requestAnimationFrame = $this[vendors[i] + 'RequestAnimationFrame'];
     $this.cancelAnimationFrame =
         $this[vendors[i]+'CancelAnimationFrame'] ||
         $this[vendors[i]+'CancelRequestAnimationFrame'];
   }
   if ($this.requestAnimationFrame && $this.cancelAnimationFrame) return;
   $this.requestAnimationFrame = function(callback) {
      return window.setTimeout(function() {
        callback(Date.now());
      }, 16 /* 16ms ~= 60fps */);
   };
   $this.cancelAnimationFrame = function(id) { clearTimeout(id); }
  })(#)""",
       this);
  }

  /**
   * Gets an instance of the Indexed DB factory to being using Indexed DB.
   *
   * Use [IdbFactory.supported] to check if Indexed DB is supported on the
   * current platform.
   */
  @SupportedBrowser(SupportedBrowser.CHROME, '23.0')
  @SupportedBrowser(SupportedBrowser.FIREFOX, '15.0')
  @SupportedBrowser(SupportedBrowser.IE, '10.0')
  @Experimental()
  IdbFactory get indexedDB =>
      JS('IdbFactory',
         '#.indexedDB || #.webkitIndexedDB || #.mozIndexedDB',
         this, this, this);

  /**
   * Lookup a port by its [name].  Return null if no port is
   * registered under [name].
   */
  SendPortSync lookupPort(String name) {
    var port = json.parse(document.documentElement.attributes['dart-port:$name']);
    return _deserialize(port);
  }

  /**
   * Register a [port] on this window under the given [name].  This
   * port may be retrieved by any isolate (or JavaScript script)
   * running in this window.
   */
  void registerPort(String name, var port) {
    var serialized = _serialize(port);
    document.documentElement.attributes['dart-port:$name'] = json.stringify(serialized);
  }

  /// @domName Window.console; @docsEditable true
  Console get console => Console.safeConsole;


  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  WindowEvents get on =>
    new WindowEvents(this);

  static const int PERSISTENT = 1;

  static const int TEMPORARY = 0;

  /// @domName Window.applicationCache; @docsEditable true
  final ApplicationCache applicationCache;

  /// @domName Window.closed; @docsEditable true
  final bool closed;

  /// @domName Window.crypto; @docsEditable true
  final Crypto crypto;

  /// @domName Window.defaultStatus; @docsEditable true
  String defaultStatus;

  /// @domName Window.defaultstatus; @docsEditable true
  String defaultstatus;

  /// @domName Window.devicePixelRatio; @docsEditable true
  final num devicePixelRatio;

  /// @domName Window.event; @docsEditable true
  final Event event;

  /// @domName Window.history; @docsEditable true
  final History history;

  /// @domName Window.innerHeight; @docsEditable true
  final int innerHeight;

  /// @domName Window.innerWidth; @docsEditable true
  final int innerWidth;

  /// @domName Window.localStorage; @docsEditable true
  final Storage localStorage;

  /// @domName Window.locationbar; @docsEditable true
  final BarInfo locationbar;

  /// @domName Window.menubar; @docsEditable true
  final BarInfo menubar;

  /// @domName Window.name; @docsEditable true
  String name;

  /// @domName Window.navigator; @docsEditable true
  final Navigator navigator;

  /// @domName Window.offscreenBuffering; @docsEditable true
  final bool offscreenBuffering;

  /// @domName Window.opener; @docsEditable true
  WindowBase get opener => _convertNativeToDart_Window(this._opener);
  @JSName('opener')
  @Creates('Window|=Object') @Returns('Window|=Object')
  final dynamic _opener;

  /// @domName Window.outerHeight; @docsEditable true
  final int outerHeight;

  /// @domName Window.outerWidth; @docsEditable true
  final int outerWidth;

  /// @domName DOMWindow.pagePopupController; @docsEditable true
  final PagePopupController pagePopupController;

  /// @domName Window.pageXOffset; @docsEditable true
  final int pageXOffset;

  /// @domName Window.pageYOffset; @docsEditable true
  final int pageYOffset;

  /// @domName Window.parent; @docsEditable true
  WindowBase get parent => _convertNativeToDart_Window(this._parent);
  @JSName('parent')
  @Creates('Window|=Object') @Returns('Window|=Object')
  final dynamic _parent;

  /// @domName Window.performance; @docsEditable true
  final Performance performance;

  /// @domName Window.personalbar; @docsEditable true
  final BarInfo personalbar;

  /// @domName Window.screen; @docsEditable true
  final Screen screen;

  /// @domName Window.screenLeft; @docsEditable true
  final int screenLeft;

  /// @domName Window.screenTop; @docsEditable true
  final int screenTop;

  /// @domName Window.screenX; @docsEditable true
  final int screenX;

  /// @domName Window.screenY; @docsEditable true
  final int screenY;

  /// @domName Window.scrollX; @docsEditable true
  final int scrollX;

  /// @domName Window.scrollY; @docsEditable true
  final int scrollY;

  /// @domName Window.scrollbars; @docsEditable true
  final BarInfo scrollbars;

  /// @domName Window.self; @docsEditable true
  WindowBase get self => _convertNativeToDart_Window(this._self);
  @JSName('self')
  @Creates('Window|=Object') @Returns('Window|=Object')
  final dynamic _self;

  /// @domName Window.sessionStorage; @docsEditable true
  final Storage sessionStorage;

  /// @domName Window.status; @docsEditable true
  String status;

  /// @domName Window.statusbar; @docsEditable true
  final BarInfo statusbar;

  /// @domName Window.styleMedia; @docsEditable true
  final StyleMedia styleMedia;

  /// @domName Window.toolbar; @docsEditable true
  final BarInfo toolbar;

  /// @domName Window.top; @docsEditable true
  WindowBase get top => _convertNativeToDart_Window(this._top);
  @JSName('top')
  @Creates('Window|=Object') @Returns('Window|=Object')
  final dynamic _top;

  /// @domName DOMWindow.webkitNotifications; @docsEditable true
  final NotificationCenter webkitNotifications;

  /// @domName DOMWindow.webkitStorageInfo; @docsEditable true
  final StorageInfo webkitStorageInfo;

  /// @domName Window.window; @docsEditable true
  WindowBase get window => _convertNativeToDart_Window(this._window);
  @JSName('window')
  @Creates('Window|=Object') @Returns('Window|=Object')
  final dynamic _window;

  /// @domName Window.addEventListener; @docsEditable true
  @JSName('addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  /// @domName Window.alert; @docsEditable true
  void alert(String message) native;

  /// @domName Window.atob; @docsEditable true
  String atob(String string) native;

  /// @domName Window.btoa; @docsEditable true
  String btoa(String string) native;

  /// @domName Window.captureEvents; @docsEditable true
  void captureEvents() native;

  /// @domName Window.clearInterval; @docsEditable true
  void clearInterval(int handle) native;

  /// @domName Window.clearTimeout; @docsEditable true
  void clearTimeout(int handle) native;

  /// @domName Window.close; @docsEditable true
  void close() native;

  /// @domName Window.confirm; @docsEditable true
  bool confirm(String message) native;

  /// @domName Window.dispatchEvent; @docsEditable true
  @JSName('dispatchEvent')
  bool $dom_dispatchEvent(Event evt) native;

  /// @domName Window.find; @docsEditable true
  bool find(String string, bool caseSensitive, bool backwards, bool wrap, bool wholeWord, bool searchInFrames, bool showDialog) native;

  /// @domName Window.getComputedStyle; @docsEditable true
  @JSName('getComputedStyle')
  CssStyleDeclaration $dom_getComputedStyle(Element element, String pseudoElement) native;

  /// @domName Window.getMatchedCSSRules; @docsEditable true
  @JSName('getMatchedCSSRules')
  @Returns('_CssRuleList') @Creates('_CssRuleList')
  List<CssRule> getMatchedCssRules(Element element, String pseudoElement) native;

  /// @domName Window.getSelection; @docsEditable true
  DomSelection getSelection() native;

  /// @domName Window.matchMedia; @docsEditable true
  MediaQueryList matchMedia(String query) native;

  /// @domName Window.moveBy; @docsEditable true
  void moveBy(num x, num y) native;

  /// @domName Window.moveTo; @docsEditable true
  void moveTo(num x, num y) native;

  /// @domName DOMWindow.openDatabase; @docsEditable true
  @Creates('Database') @Creates('DatabaseSync')
  Database openDatabase(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback]) native;

  /// @domName Window.postMessage; @docsEditable true
  void postMessage(/*SerializedScriptValue*/ message, String targetOrigin, [List messagePorts]) {
    if (?message &&
        !?messagePorts) {
      var message_1 = convertDartToNative_SerializedScriptValue(message);
      _postMessage_1(message_1, targetOrigin);
      return;
    }
    if (?message) {
      var message_2 = convertDartToNative_SerializedScriptValue(message);
      _postMessage_2(message_2, targetOrigin, messagePorts);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }
  @JSName('postMessage')
  void _postMessage_1(message, targetOrigin) native;
  @JSName('postMessage')
  void _postMessage_2(message, targetOrigin, List messagePorts) native;

  /// @domName Window.print; @docsEditable true
  void print() native;

  /// @domName Window.releaseEvents; @docsEditable true
  void releaseEvents() native;

  /// @domName Window.removeEventListener; @docsEditable true
  @JSName('removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  /// @domName Window.resizeBy; @docsEditable true
  void resizeBy(num x, num y) native;

  /// @domName Window.resizeTo; @docsEditable true
  void resizeTo(num width, num height) native;

  /// @domName Window.scroll; @docsEditable true
  void scroll(int x, int y) native;

  /// @domName Window.scrollBy; @docsEditable true
  void scrollBy(int x, int y) native;

  /// @domName Window.scrollTo; @docsEditable true
  void scrollTo(int x, int y) native;

  /// @domName Window.setInterval; @docsEditable true
  int setInterval(TimeoutHandler handler, int timeout) native;

  /// @domName Window.setTimeout; @docsEditable true
  int setTimeout(TimeoutHandler handler, int timeout) native;

  /// @domName Window.showModalDialog; @docsEditable true
  Object showModalDialog(String url, [Object dialogArgs, String featureArgs]) native;

  /// @domName Window.stop; @docsEditable true
  void stop() native;

  /// @domName Window.webkitConvertPointFromNodeToPage; @docsEditable true
  Point webkitConvertPointFromNodeToPage(Node node, Point p) native;

  /// @domName Window.webkitConvertPointFromPageToNode; @docsEditable true
  Point webkitConvertPointFromPageToNode(Node node, Point p) native;

  /// @domName DOMWindow.webkitRequestFileSystem; @docsEditable true
  void webkitRequestFileSystem(int type, int size, FileSystemCallback successCallback, [ErrorCallback errorCallback]) native;

  /// @domName DOMWindow.webkitResolveLocalFileSystemURL; @docsEditable true
  @JSName('webkitResolveLocalFileSystemURL')
  void webkitResolveLocalFileSystemUrl(String url, EntryCallback successCallback, [ErrorCallback errorCallback]) native;

}

/// @docsEditable true
class WindowEvents extends Events {
  /// @docsEditable true
  WindowEvents(EventTarget _ptr) : super(_ptr);

  /// @docsEditable true
  EventListenerList get contentLoaded => this['DOMContentLoaded'];

  /// @docsEditable true
  EventListenerList get abort => this['abort'];

  /// @docsEditable true
  EventListenerList get beforeUnload => this['beforeunload'];

  /// @docsEditable true
  EventListenerList get blur => this['blur'];

  /// @docsEditable true
  EventListenerList get canPlay => this['canplay'];

  /// @docsEditable true
  EventListenerList get canPlayThrough => this['canplaythrough'];

  /// @docsEditable true
  EventListenerList get change => this['change'];

  /// @docsEditable true
  EventListenerList get click => this['click'];

  /// @docsEditable true
  EventListenerList get contextMenu => this['contextmenu'];

  /// @docsEditable true
  EventListenerList get doubleClick => this['dblclick'];

  /// @docsEditable true
  EventListenerList get deviceMotion => this['devicemotion'];

  /// @docsEditable true
  EventListenerList get deviceOrientation => this['deviceorientation'];

  /// @docsEditable true
  EventListenerList get drag => this['drag'];

  /// @docsEditable true
  EventListenerList get dragEnd => this['dragend'];

  /// @docsEditable true
  EventListenerList get dragEnter => this['dragenter'];

  /// @docsEditable true
  EventListenerList get dragLeave => this['dragleave'];

  /// @docsEditable true
  EventListenerList get dragOver => this['dragover'];

  /// @docsEditable true
  EventListenerList get dragStart => this['dragstart'];

  /// @docsEditable true
  EventListenerList get drop => this['drop'];

  /// @docsEditable true
  EventListenerList get durationChange => this['durationchange'];

  /// @docsEditable true
  EventListenerList get emptied => this['emptied'];

  /// @docsEditable true
  EventListenerList get ended => this['ended'];

  /// @docsEditable true
  EventListenerList get error => this['error'];

  /// @docsEditable true
  EventListenerList get focus => this['focus'];

  /// @docsEditable true
  EventListenerList get hashChange => this['hashchange'];

  /// @docsEditable true
  EventListenerList get input => this['input'];

  /// @docsEditable true
  EventListenerList get invalid => this['invalid'];

  /// @docsEditable true
  EventListenerList get keyDown => this['keydown'];

  /// @docsEditable true
  EventListenerList get keyPress => this['keypress'];

  /// @docsEditable true
  EventListenerList get keyUp => this['keyup'];

  /// @docsEditable true
  EventListenerList get load => this['load'];

  /// @docsEditable true
  EventListenerList get loadedData => this['loadeddata'];

  /// @docsEditable true
  EventListenerList get loadedMetadata => this['loadedmetadata'];

  /// @docsEditable true
  EventListenerList get loadStart => this['loadstart'];

  /// @docsEditable true
  EventListenerList get message => this['message'];

  /// @docsEditable true
  EventListenerList get mouseDown => this['mousedown'];

  /// @docsEditable true
  EventListenerList get mouseMove => this['mousemove'];

  /// @docsEditable true
  EventListenerList get mouseOut => this['mouseout'];

  /// @docsEditable true
  EventListenerList get mouseOver => this['mouseover'];

  /// @docsEditable true
  EventListenerList get mouseUp => this['mouseup'];

  /// @docsEditable true
  EventListenerList get mouseWheel => this['mousewheel'];

  /// @docsEditable true
  EventListenerList get offline => this['offline'];

  /// @docsEditable true
  EventListenerList get online => this['online'];

  /// @docsEditable true
  EventListenerList get pageHide => this['pagehide'];

  /// @docsEditable true
  EventListenerList get pageShow => this['pageshow'];

  /// @docsEditable true
  EventListenerList get pause => this['pause'];

  /// @docsEditable true
  EventListenerList get play => this['play'];

  /// @docsEditable true
  EventListenerList get playing => this['playing'];

  /// @docsEditable true
  EventListenerList get popState => this['popstate'];

  /// @docsEditable true
  EventListenerList get progress => this['progress'];

  /// @docsEditable true
  EventListenerList get rateChange => this['ratechange'];

  /// @docsEditable true
  EventListenerList get reset => this['reset'];

  /// @docsEditable true
  EventListenerList get resize => this['resize'];

  /// @docsEditable true
  EventListenerList get scroll => this['scroll'];

  /// @docsEditable true
  EventListenerList get search => this['search'];

  /// @docsEditable true
  EventListenerList get seeked => this['seeked'];

  /// @docsEditable true
  EventListenerList get seeking => this['seeking'];

  /// @docsEditable true
  EventListenerList get select => this['select'];

  /// @docsEditable true
  EventListenerList get stalled => this['stalled'];

  /// @docsEditable true
  EventListenerList get storage => this['storage'];

  /// @docsEditable true
  EventListenerList get submit => this['submit'];

  /// @docsEditable true
  EventListenerList get suspend => this['suspend'];

  /// @docsEditable true
  EventListenerList get timeUpdate => this['timeupdate'];

  /// @docsEditable true
  EventListenerList get touchCancel => this['touchcancel'];

  /// @docsEditable true
  EventListenerList get touchEnd => this['touchend'];

  /// @docsEditable true
  EventListenerList get touchMove => this['touchmove'];

  /// @docsEditable true
  EventListenerList get touchStart => this['touchstart'];

  /// @docsEditable true
  EventListenerList get unload => this['unload'];

  /// @docsEditable true
  EventListenerList get volumeChange => this['volumechange'];

  /// @docsEditable true
  EventListenerList get waiting => this['waiting'];

  /// @docsEditable true
  EventListenerList get animationEnd => this['webkitAnimationEnd'];

  /// @docsEditable true
  EventListenerList get animationIteration => this['webkitAnimationIteration'];

  /// @docsEditable true
  EventListenerList get animationStart => this['webkitAnimationStart'];

  /// @docsEditable true
  EventListenerList get transitionEnd => this['webkitTransitionEnd'];
}
