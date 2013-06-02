library dart.dom.web_audio;

import 'dart:async';
import 'dart:collection';
import 'dart:_collection-dev';
import 'dart:html';
import 'dart:html_common';
import 'dart:typed_data';
import 'dart:_js_helper' show Creates, JSName, Returns, convertDartClosureToJS;
import 'dart:_foreign_helper' show JS;
import 'dart:_interceptors' show Interceptor;
// DO NOT EDIT - unless you are editing documentation as per:
// https://code.google.com/p/dart/wiki/ContributingHTMLDocumentation
// Auto-generated dart:audio library.




// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('AnalyserNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AnalyserNode
@Experimental
class AnalyserNode extends AudioNode native "AnalyserNode" {

  @DomName('AnalyserNode.fftSize')
  @DocsEditable
  int fftSize;

  @DomName('AnalyserNode.frequencyBinCount')
  @DocsEditable
  final int frequencyBinCount;

  @DomName('AnalyserNode.maxDecibels')
  @DocsEditable
  num maxDecibels;

  @DomName('AnalyserNode.minDecibels')
  @DocsEditable
  num minDecibels;

  @DomName('AnalyserNode.smoothingTimeConstant')
  @DocsEditable
  num smoothingTimeConstant;

  @DomName('AnalyserNode.getByteFrequencyData')
  @DocsEditable
  void getByteFrequencyData(Uint8List array) native;

  @DomName('AnalyserNode.getByteTimeDomainData')
  @DocsEditable
  void getByteTimeDomainData(Uint8List array) native;

  @DomName('AnalyserNode.getFloatFrequencyData')
  @DocsEditable
  void getFloatFrequencyData(Float32List array) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('AudioBuffer')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioBuffer-section
@Experimental
class AudioBuffer native "AudioBuffer" {

  @DomName('AudioBuffer.duration')
  @DocsEditable
  final num duration;

  @DomName('AudioBuffer.gain')
  @DocsEditable
  num gain;

  @DomName('AudioBuffer.length')
  @DocsEditable
  final int length;

  @DomName('AudioBuffer.numberOfChannels')
  @DocsEditable
  final int numberOfChannels;

  @DomName('AudioBuffer.sampleRate')
  @DocsEditable
  final num sampleRate;

  @DomName('AudioBuffer.getChannelData')
  @DocsEditable
  Float32List getChannelData(int channelIndex) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DomName('AudioBufferCallback')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioBuffer-section
@Experimental
typedef void AudioBufferCallback(AudioBuffer audioBuffer);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('AudioBufferSourceNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioBufferSourceNode-section
@Experimental
class AudioBufferSourceNode extends AudioSourceNode native "AudioBufferSourceNode" {

  // TODO(efortuna): Remove these methods when Chrome stable also uses start
  // instead of noteOn.
  void start(num when, [num grainOffset, num grainDuration]) {
    if (JS('bool', '!!#.start', this)) {
      if (grainDuration != null) {
        JS('void', '#.start(#, #, #)', this, when, grainOffset, grainDuration);
      } else if (grainOffset != null) {
        JS('void', '#.start(#, #)', this, when, grainOffset);
      } else {
        JS('void', '#.start(#)', this, when);
      }
    } else {
      if (grainDuration != null) {
        JS('void', '#.noteOn(#, #, #)', this, when, grainOffset, grainDuration);
      } else if (grainOffset != null) {
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

  @DomName('AudioBufferSourceNode.FINISHED_STATE')
  @DocsEditable
  static const int FINISHED_STATE = 3;

  @DomName('AudioBufferSourceNode.PLAYING_STATE')
  @DocsEditable
  static const int PLAYING_STATE = 2;

  @DomName('AudioBufferSourceNode.SCHEDULED_STATE')
  @DocsEditable
  static const int SCHEDULED_STATE = 1;

  @DomName('AudioBufferSourceNode.UNSCHEDULED_STATE')
  @DocsEditable
  static const int UNSCHEDULED_STATE = 0;

  @DomName('AudioBufferSourceNode.buffer')
  @DocsEditable
  AudioBuffer buffer;

  @DomName('AudioBufferSourceNode.gain')
  @DocsEditable
  final AudioParam gain;

  @DomName('AudioBufferSourceNode.loop')
  @DocsEditable
  bool loop;

  @DomName('AudioBufferSourceNode.loopEnd')
  @DocsEditable
  num loopEnd;

  @DomName('AudioBufferSourceNode.loopStart')
  @DocsEditable
  num loopStart;

  @DomName('AudioBufferSourceNode.playbackRate')
  @DocsEditable
  final AudioParam playbackRate;

  @DomName('AudioBufferSourceNode.playbackState')
  @DocsEditable
  final int playbackState;

  @DomName('AudioBufferSourceNode.noteGrainOn')
  @DocsEditable
  @Experimental // untriaged
  void noteGrainOn(num when, num grainOffset, num grainDuration) native;

  @DomName('AudioBufferSourceNode.noteOff')
  @DocsEditable
  @Experimental // untriaged
  void noteOff(num when) native;

  @DomName('AudioBufferSourceNode.noteOn')
  @DocsEditable
  @Experimental // untriaged
  void noteOn(num when) native;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('AudioContext')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioContext-section
@Experimental
class AudioContext extends EventTarget native "AudioContext" {

  @DomName('AudioContext.completeEvent')
  @DocsEditable
  static const EventStreamProvider<Event> completeEvent = const EventStreamProvider<Event>('complete');

  /// Checks if this type is supported on the current platform.
  static bool get supported => JS('bool', '!!(window.AudioContext || window.webkitAudioContext)');

  @DomName('AudioContext.activeSourceCount')
  @DocsEditable
  final int activeSourceCount;

  @DomName('AudioContext.currentTime')
  @DocsEditable
  final num currentTime;

  @DomName('AudioContext.destination')
  @DocsEditable
  final AudioDestinationNode destination;

  @DomName('AudioContext.listener')
  @DocsEditable
  final AudioListener listener;

  @DomName('AudioContext.sampleRate')
  @DocsEditable
  final num sampleRate;

  @DomName('AudioContext.createAnalyser')
  @DocsEditable
  AnalyserNode createAnalyser() native;

  @DomName('AudioContext.createBiquadFilter')
  @DocsEditable
  BiquadFilterNode createBiquadFilter() native;

  @DomName('AudioContext.createBuffer')
  @DocsEditable
  AudioBuffer createBuffer(buffer_OR_numberOfChannels, mixToMono_OR_numberOfFrames, [num sampleRate]) native;

  @DomName('AudioContext.createBufferSource')
  @DocsEditable
  AudioBufferSourceNode createBufferSource() native;

  @DomName('AudioContext.createChannelMerger')
  @DocsEditable
  ChannelMergerNode createChannelMerger([int numberOfInputs]) native;

  @DomName('AudioContext.createChannelSplitter')
  @DocsEditable
  ChannelSplitterNode createChannelSplitter([int numberOfOutputs]) native;

  @DomName('AudioContext.createConvolver')
  @DocsEditable
  ConvolverNode createConvolver() native;

  @DomName('AudioContext.createDelay')
  @DocsEditable
  DelayNode createDelay([num maxDelayTime]) native;

  @DomName('AudioContext.createDelayNode')
  @DocsEditable
  @Experimental // untriaged
  DelayNode createDelayNode([num maxDelayTime]) native;

  @DomName('AudioContext.createDynamicsCompressor')
  @DocsEditable
  DynamicsCompressorNode createDynamicsCompressor() native;

  @DomName('AudioContext.createGainNode')
  @DocsEditable
  @Experimental // untriaged
  GainNode createGainNode() native;

  @DomName('AudioContext.createJavaScriptNode')
  @DocsEditable
  @Experimental // untriaged
  ScriptProcessorNode createJavaScriptNode(int bufferSize, [int numberOfInputChannels, int numberOfOutputChannels]) native;

  @DomName('AudioContext.createMediaElementSource')
  @DocsEditable
  MediaElementAudioSourceNode createMediaElementSource(MediaElement mediaElement) native;

  @DomName('AudioContext.createMediaStreamDestination')
  @DocsEditable
  MediaStreamAudioDestinationNode createMediaStreamDestination() native;

  @DomName('AudioContext.createMediaStreamSource')
  @DocsEditable
  MediaStreamAudioSourceNode createMediaStreamSource(MediaStream mediaStream) native;

  @DomName('AudioContext.createOscillator')
  @DocsEditable
  OscillatorNode createOscillator() native;

  @DomName('AudioContext.createPanner')
  @DocsEditable
  PannerNode createPanner() native;

  @DomName('AudioContext.createWaveShaper')
  @DocsEditable
  WaveShaperNode createWaveShaper() native;

  @DomName('AudioContext.createWaveTable')
  @DocsEditable
  WaveTable createWaveTable(Float32List real, Float32List imag) native;

  @DomName('AudioContext.decodeAudioData')
  @DocsEditable
  void decodeAudioData(ByteBuffer audioData, AudioBufferCallback successCallback, [AudioBufferCallback errorCallback]) native;

  @DomName('AudioContext.startRendering')
  @DocsEditable
  void startRendering() native;

  @DomName('AudioContext.oncomplete')
  @DocsEditable
  Stream<Event> get onComplete => completeEvent.forTarget(this);

  factory AudioContext() => JS('AudioContext',
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
    if (numberOfOutputChannels != null) {
      return JS('ScriptProcessorNode', '#.call(#, #, #, #)', function, this,
          bufferSize, numberOfInputChannels, numberOfOutputChannels);
    } else if (numberOfInputChannels != null) {
      return JS('ScriptProcessorNode', '#.call(#, #, #)', function, this,
          bufferSize, numberOfInputChannels);
    } else {
      return JS('ScriptProcessorNode', '#.call(#, #)', function, this,
          bufferSize);
    }
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('AudioDestinationNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioDestinationNode-section
@Experimental
class AudioDestinationNode extends AudioNode native "AudioDestinationNode" {

  @DomName('AudioDestinationNode.maxChannelCount')
  @DocsEditable
  final int maxChannelCount;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('AudioListener')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioListener-section
@Experimental
class AudioListener native "AudioListener" {

  @DomName('AudioListener.dopplerFactor')
  @DocsEditable
  num dopplerFactor;

  @DomName('AudioListener.speedOfSound')
  @DocsEditable
  num speedOfSound;

  @DomName('AudioListener.setOrientation')
  @DocsEditable
  void setOrientation(num x, num y, num z, num xUp, num yUp, num zUp) native;

  @DomName('AudioListener.setPosition')
  @DocsEditable
  void setPosition(num x, num y, num z) native;

  @DomName('AudioListener.setVelocity')
  @DocsEditable
  void setVelocity(num x, num y, num z) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('AudioNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioNode-section
@Experimental
class AudioNode extends EventTarget native "AudioNode" {

  @DomName('AudioNode.channelCount')
  @DocsEditable
  int channelCount;

  @DomName('AudioNode.channelCountMode')
  @DocsEditable
  String channelCountMode;

  @DomName('AudioNode.channelInterpretation')
  @DocsEditable
  String channelInterpretation;

  @DomName('AudioNode.context')
  @DocsEditable
  final AudioContext context;

  @DomName('AudioNode.numberOfInputs')
  @DocsEditable
  final int numberOfInputs;

  @DomName('AudioNode.numberOfOutputs')
  @DocsEditable
  final int numberOfOutputs;

  @JSName('addEventListener')
  @DomName('AudioNode.addEventListener')
  @DocsEditable
  @Experimental // untriaged
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DomName('AudioNode.connect')
  @DocsEditable
  void connect(destination, int output, [int input]) native;

  @DomName('AudioNode.disconnect')
  @DocsEditable
  void disconnect(int output) native;

  @DomName('AudioNode.dispatchEvent')
  @DocsEditable
  @Experimental // untriaged
  bool dispatchEvent(Event event) native;

  @JSName('removeEventListener')
  @DomName('AudioNode.removeEventListener')
  @DocsEditable
  @Experimental // untriaged
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('AudioParam')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioParam
@Experimental
class AudioParam native "AudioParam" {

  @DomName('AudioParam.defaultValue')
  @DocsEditable
  final num defaultValue;

  @DomName('AudioParam.maxValue')
  @DocsEditable
  final num maxValue;

  @DomName('AudioParam.minValue')
  @DocsEditable
  final num minValue;

  @DomName('AudioParam.name')
  @DocsEditable
  final String name;

  @DomName('AudioParam.units')
  @DocsEditable
  final int units;

  @DomName('AudioParam.value')
  @DocsEditable
  num value;

  @DomName('AudioParam.cancelScheduledValues')
  @DocsEditable
  void cancelScheduledValues(num startTime) native;

  @DomName('AudioParam.exponentialRampToValueAtTime')
  @DocsEditable
  void exponentialRampToValueAtTime(num value, num time) native;

  @DomName('AudioParam.linearRampToValueAtTime')
  @DocsEditable
  void linearRampToValueAtTime(num value, num time) native;

  @DomName('AudioParam.setTargetAtTime')
  @DocsEditable
  void setTargetAtTime(num target, num time, num timeConstant) native;

  @DomName('AudioParam.setTargetValueAtTime')
  @DocsEditable
  @Experimental // untriaged
  void setTargetValueAtTime(num targetValue, num time, num timeConstant) native;

  @DomName('AudioParam.setValueAtTime')
  @DocsEditable
  void setValueAtTime(num value, num time) native;

  @DomName('AudioParam.setValueCurveAtTime')
  @DocsEditable
  void setValueCurveAtTime(Float32List values, num time, num duration) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('AudioProcessingEvent')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioProcessingEvent-section
@Experimental
class AudioProcessingEvent extends Event native "AudioProcessingEvent" {

  @DomName('AudioProcessingEvent.inputBuffer')
  @DocsEditable
  final AudioBuffer inputBuffer;

  @DomName('AudioProcessingEvent.outputBuffer')
  @DocsEditable
  final AudioBuffer outputBuffer;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('AudioSourceNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html
@Experimental
class AudioSourceNode extends AudioNode native "AudioSourceNode" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('BiquadFilterNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#BiquadFilterNode-section
@Experimental
class BiquadFilterNode extends AudioNode native "BiquadFilterNode" {

  @DomName('BiquadFilterNode.ALLPASS')
  @DocsEditable
  static const int ALLPASS = 7;

  @DomName('BiquadFilterNode.BANDPASS')
  @DocsEditable
  static const int BANDPASS = 2;

  @DomName('BiquadFilterNode.HIGHPASS')
  @DocsEditable
  static const int HIGHPASS = 1;

  @DomName('BiquadFilterNode.HIGHSHELF')
  @DocsEditable
  static const int HIGHSHELF = 4;

  @DomName('BiquadFilterNode.LOWPASS')
  @DocsEditable
  static const int LOWPASS = 0;

  @DomName('BiquadFilterNode.LOWSHELF')
  @DocsEditable
  static const int LOWSHELF = 3;

  @DomName('BiquadFilterNode.NOTCH')
  @DocsEditable
  static const int NOTCH = 6;

  @DomName('BiquadFilterNode.PEAKING')
  @DocsEditable
  static const int PEAKING = 5;

  @DomName('BiquadFilterNode.Q')
  @DocsEditable
  final AudioParam Q;

  @DomName('BiquadFilterNode.detune')
  @DocsEditable
  final AudioParam detune;

  @DomName('BiquadFilterNode.frequency')
  @DocsEditable
  final AudioParam frequency;

  @DomName('BiquadFilterNode.gain')
  @DocsEditable
  final AudioParam gain;

  @DomName('BiquadFilterNode.type')
  @DocsEditable
  String type;

  @DomName('BiquadFilterNode.getFrequencyResponse')
  @DocsEditable
  void getFrequencyResponse(Float32List frequencyHz, Float32List magResponse, Float32List phaseResponse) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('ChannelMergerNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#ChannelMergerNode-section
@Experimental
class ChannelMergerNode extends AudioNode native "ChannelMergerNode" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('ChannelSplitterNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#ChannelSplitterNode-section
@Experimental
class ChannelSplitterNode extends AudioNode native "ChannelSplitterNode" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('ConvolverNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#ConvolverNode
@Experimental
class ConvolverNode extends AudioNode native "ConvolverNode" {

  @DomName('ConvolverNode.buffer')
  @DocsEditable
  AudioBuffer buffer;

  @DomName('ConvolverNode.normalize')
  @DocsEditable
  bool normalize;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('DelayNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#DelayNode
@Experimental
class DelayNode extends AudioNode native "DelayNode" {

  @DomName('DelayNode.delayTime')
  @DocsEditable
  final AudioParam delayTime;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('DynamicsCompressorNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#DynamicsCompressorNode
@Experimental
class DynamicsCompressorNode extends AudioNode native "DynamicsCompressorNode" {

  @DomName('DynamicsCompressorNode.attack')
  @DocsEditable
  final AudioParam attack;

  @DomName('DynamicsCompressorNode.knee')
  @DocsEditable
  final AudioParam knee;

  @DomName('DynamicsCompressorNode.ratio')
  @DocsEditable
  final AudioParam ratio;

  @DomName('DynamicsCompressorNode.reduction')
  @DocsEditable
  final AudioParam reduction;

  @DomName('DynamicsCompressorNode.release')
  @DocsEditable
  final AudioParam release;

  @DomName('DynamicsCompressorNode.threshold')
  @DocsEditable
  final AudioParam threshold;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('GainNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#GainNode
@Experimental
class GainNode extends AudioNode native "GainNode" {

  @DomName('GainNode.gain')
  @DocsEditable
  final AudioParam gain;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('MediaElementAudioSourceNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#MediaElementAudioSourceNode
@Experimental
class MediaElementAudioSourceNode extends AudioSourceNode native "MediaElementAudioSourceNode" {

  @DomName('MediaElementAudioSourceNode.mediaElement')
  @DocsEditable
  @Experimental // non-standard
  final MediaElement mediaElement;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('MediaStreamAudioDestinationNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#MediaStreamAudioDestinationNode
@Experimental
class MediaStreamAudioDestinationNode extends AudioSourceNode native "MediaStreamAudioDestinationNode" {

  @DomName('MediaStreamAudioDestinationNode.stream')
  @DocsEditable
  final MediaStream stream;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('MediaStreamAudioSourceNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#MediaStreamAudioSourceNode
@Experimental
class MediaStreamAudioSourceNode extends AudioSourceNode native "MediaStreamAudioSourceNode" {

  @DomName('MediaStreamAudioSourceNode.mediaStream')
  @DocsEditable
  final MediaStream mediaStream;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('OfflineAudioCompletionEvent')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#OfflineAudioCompletionEvent-section
@Experimental
class OfflineAudioCompletionEvent extends Event native "OfflineAudioCompletionEvent" {

  @DomName('OfflineAudioCompletionEvent.renderedBuffer')
  @DocsEditable
  final AudioBuffer renderedBuffer;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('OfflineAudioContext')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#OfflineAudioContext-section
@Experimental
class OfflineAudioContext extends AudioContext implements EventTarget native "OfflineAudioContext" {

  @DomName('OfflineAudioContext.OfflineAudioContext')
  @DocsEditable
  factory OfflineAudioContext(int numberOfChannels, int numberOfFrames, num sampleRate) {
    return OfflineAudioContext._create_1(numberOfChannels, numberOfFrames, sampleRate);
  }
  static OfflineAudioContext _create_1(numberOfChannels, numberOfFrames, sampleRate) => JS('OfflineAudioContext', 'new OfflineAudioContext(#,#,#)', numberOfChannels, numberOfFrames, sampleRate);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('OscillatorNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#dfn-OscillatorNode
@Experimental
class OscillatorNode extends AudioSourceNode native "OscillatorNode" {

  @DomName('OscillatorNode.CUSTOM')
  @DocsEditable
  // https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AlternateNames
  @deprecated // deprecated
  static const int CUSTOM = 4;

  @DomName('OscillatorNode.FINISHED_STATE')
  @DocsEditable
  static const int FINISHED_STATE = 3;

  @DomName('OscillatorNode.PLAYING_STATE')
  @DocsEditable
  static const int PLAYING_STATE = 2;

  @DomName('OscillatorNode.SAWTOOTH')
  @DocsEditable
  // https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AlternateNames
  @deprecated // deprecated
  static const int SAWTOOTH = 2;

  @DomName('OscillatorNode.SCHEDULED_STATE')
  @DocsEditable
  static const int SCHEDULED_STATE = 1;

  @DomName('OscillatorNode.SINE')
  @DocsEditable
  // https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AlternateNames
  @deprecated // deprecated
  static const int SINE = 0;

  @DomName('OscillatorNode.SQUARE')
  @DocsEditable
  // https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AlternateNames
  @deprecated // deprecated
  static const int SQUARE = 1;

  @DomName('OscillatorNode.TRIANGLE')
  @DocsEditable
  // https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AlternateNames
  @deprecated // deprecated
  static const int TRIANGLE = 3;

  @DomName('OscillatorNode.UNSCHEDULED_STATE')
  @DocsEditable
  static const int UNSCHEDULED_STATE = 0;

  @DomName('OscillatorNode.detune')
  @DocsEditable
  final AudioParam detune;

  @DomName('OscillatorNode.frequency')
  @DocsEditable
  final AudioParam frequency;

  @DomName('OscillatorNode.playbackState')
  @DocsEditable
  final int playbackState;

  @DomName('OscillatorNode.type')
  @DocsEditable
  String type;

  @DomName('OscillatorNode.noteOff')
  @DocsEditable
  @Experimental // untriaged
  void noteOff(num when) native;

  @DomName('OscillatorNode.noteOn')
  @DocsEditable
  @Experimental // untriaged
  void noteOn(num when) native;

  @DomName('OscillatorNode.setWaveTable')
  @DocsEditable
  void setWaveTable(WaveTable waveTable) native;

  @DomName('OscillatorNode.start')
  @DocsEditable
  void start(num when) native;

  @DomName('OscillatorNode.stop')
  @DocsEditable
  void stop(num when) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('PannerNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#PannerNode
@Experimental
class PannerNode extends AudioNode native "PannerNode" {

  @DomName('PannerNode.EQUALPOWER')
  @DocsEditable
  // https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AlternateNames
  @deprecated // deprecated
  static const int EQUALPOWER = 0;

  @DomName('PannerNode.EXPONENTIAL_DISTANCE')
  @DocsEditable
  // https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AlternateNames
  @deprecated // deprecated
  static const int EXPONENTIAL_DISTANCE = 2;

  @DomName('PannerNode.HRTF')
  @DocsEditable
  // https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AlternateNames
  @deprecated // deprecated
  static const int HRTF = 1;

  @DomName('PannerNode.INVERSE_DISTANCE')
  @DocsEditable
  // https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AlternateNames
  @deprecated // deprecated
  static const int INVERSE_DISTANCE = 1;

  @DomName('PannerNode.LINEAR_DISTANCE')
  @DocsEditable
  // https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AlternateNames
  @deprecated // deprecated
  static const int LINEAR_DISTANCE = 0;

  @DomName('PannerNode.SOUNDFIELD')
  @DocsEditable
  // https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AlternateNames
  @deprecated // deprecated
  static const int SOUNDFIELD = 2;

  @DomName('PannerNode.coneInnerAngle')
  @DocsEditable
  num coneInnerAngle;

  @DomName('PannerNode.coneOuterAngle')
  @DocsEditable
  num coneOuterAngle;

  @DomName('PannerNode.coneOuterGain')
  @DocsEditable
  num coneOuterGain;

  @DomName('PannerNode.distanceModel')
  @DocsEditable
  String distanceModel;

  @DomName('PannerNode.maxDistance')
  @DocsEditable
  num maxDistance;

  @DomName('PannerNode.panningModel')
  @DocsEditable
  String panningModel;

  @DomName('PannerNode.refDistance')
  @DocsEditable
  num refDistance;

  @DomName('PannerNode.rolloffFactor')
  @DocsEditable
  num rolloffFactor;

  @DomName('PannerNode.setOrientation')
  @DocsEditable
  void setOrientation(num x, num y, num z) native;

  @DomName('PannerNode.setPosition')
  @DocsEditable
  void setPosition(num x, num y, num z) native;

  @DomName('PannerNode.setVelocity')
  @DocsEditable
  void setVelocity(num x, num y, num z) native;
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('ScriptProcessorNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#ScriptProcessorNode
@Experimental
class ScriptProcessorNode extends AudioNode native "ScriptProcessorNode" {
  Stream<AudioProcessingEvent> _eventStream;

  /**
   * Get a Stream that fires events when AudioProcessingEvents occur.
   * This particular stream is special in that it only allows one listener to a
   * given stream. Converting the returned Stream [asBroadcast] will likely ruin
   * the soft-real-time properties which which these events are fired and can
   * be processed.
   */
  Stream<AudioProcessingEvent> get onAudioProcess {
    if (_eventStream == null) {
      var controller = new StreamController(sync: true);
      var callback = (audioData) {
          if (controller.hasListener) {
            // This stream is a strange combination of broadcast and single
            // subscriber streams. We only allow one listener, but if there is
            // no listener, we don't queue up events, we just drop them on the
            // floor.
            controller.add(audioData);
          }
        };
      _setEventListener(callback);
      _eventStream = controller.stream;
    }
    return _eventStream;
  }

    _setEventListener(callback) {
      JS('void', '#.onaudioprocess = #', this,
          convertDartClosureToJS(callback, 1));
    }


  @DomName('ScriptProcessorNode.bufferSize')
  @DocsEditable
  final int bufferSize;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WaveShaperNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#dfn-WaveShaperNode
@Experimental
class WaveShaperNode extends AudioNode native "WaveShaperNode" {

  @DomName('WaveShaperNode.curve')
  @DocsEditable
  Float32List curve;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('WaveTable')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#WaveTable-section
@Experimental
class WaveTable native "WaveTable" {
}
