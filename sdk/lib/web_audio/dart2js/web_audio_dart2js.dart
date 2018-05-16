/**
 * High-fidelity audio programming in the browser.
 *
 * {@category Web}
 */
library dart.dom.web_audio;

import 'dart:async';
import 'dart:collection' hide LinkedList, LinkedListEntry;
import 'dart:_internal' show FixedLengthListMixin;
import 'dart:html';
import 'dart:html_common';
import 'dart:_native_typed_data';
import 'dart:typed_data';
import 'dart:_foreign_helper' show JS;
import 'dart:_interceptors' show Interceptor;
// DO NOT EDIT - unless you are editing documentation as per:
// https://code.google.com/p/dart/wiki/ContributingHTMLDocumentation
// Auto-generated dart:audio library.

import 'dart:_js_helper'
    show
        Creates,
        JavaScriptIndexingBehavior,
        JSName,
        Native,
        Returns,
        convertDartClosureToJS;

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('AnalyserNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AnalyserNode
@Experimental()
@Native("AnalyserNode,RealtimeAnalyserNode")
class AnalyserNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory AnalyserNode._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('AnalyserNode.AnalyserNode')
  @DocsEditable()
  factory AnalyserNode(BaseAudioContext context, [Map options]) {
    if (options != null) {
      var options_1 = convertDartToNative_Dictionary(options);
      return AnalyserNode._create_1(context, options_1);
    }
    return AnalyserNode._create_2(context);
  }
  static AnalyserNode _create_1(context, options) =>
      JS('AnalyserNode', 'new AnalyserNode(#,#)', context, options);
  static AnalyserNode _create_2(context) =>
      JS('AnalyserNode', 'new AnalyserNode(#)', context);

  @DomName('AnalyserNode.fftSize')
  @DocsEditable()
  int fftSize;

  @DomName('AnalyserNode.frequencyBinCount')
  @DocsEditable()
  final int frequencyBinCount;

  @DomName('AnalyserNode.maxDecibels')
  @DocsEditable()
  num maxDecibels;

  @DomName('AnalyserNode.minDecibels')
  @DocsEditable()
  num minDecibels;

  @DomName('AnalyserNode.smoothingTimeConstant')
  @DocsEditable()
  num smoothingTimeConstant;

  @DomName('AnalyserNode.getByteFrequencyData')
  @DocsEditable()
  void getByteFrequencyData(Uint8List array) native;

  @DomName('AnalyserNode.getByteTimeDomainData')
  @DocsEditable()
  void getByteTimeDomainData(Uint8List array) native;

  @DomName('AnalyserNode.getFloatFrequencyData')
  @DocsEditable()
  void getFloatFrequencyData(Float32List array) native;

  @DomName('AnalyserNode.getFloatTimeDomainData')
  @DocsEditable()
  @Experimental() // untriaged
  void getFloatTimeDomainData(Float32List array) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('AudioBuffer')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioBuffer-section
@Experimental()
@Native("AudioBuffer")
class AudioBuffer extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory AudioBuffer._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('AudioBuffer.AudioBuffer')
  @DocsEditable()
  factory AudioBuffer(Map options) {
    var options_1 = convertDartToNative_Dictionary(options);
    return AudioBuffer._create_1(options_1);
  }
  static AudioBuffer _create_1(options) =>
      JS('AudioBuffer', 'new AudioBuffer(#)', options);

  @DomName('AudioBuffer.duration')
  @DocsEditable()
  final num duration;

  @DomName('AudioBuffer.length')
  @DocsEditable()
  final int length;

  @DomName('AudioBuffer.numberOfChannels')
  @DocsEditable()
  final int numberOfChannels;

  @DomName('AudioBuffer.sampleRate')
  @DocsEditable()
  final num sampleRate;

  @DomName('AudioBuffer.copyFromChannel')
  @DocsEditable()
  @Experimental() // untriaged
  void copyFromChannel(Float32List destination, int channelNumber,
      [int startInChannel]) native;

  @DomName('AudioBuffer.copyToChannel')
  @DocsEditable()
  @Experimental() // untriaged
  void copyToChannel(Float32List source, int channelNumber,
      [int startInChannel]) native;

  @DomName('AudioBuffer.getChannelData')
  @DocsEditable()
  Float32List getChannelData(int channelIndex) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('AudioBufferSourceNode')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@Experimental()
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioBufferSourceNode-section
@Native("AudioBufferSourceNode")
class AudioBufferSourceNode extends AudioScheduledSourceNode {
  // To suppress missing implicit constructor warnings.
  factory AudioBufferSourceNode._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('AudioBufferSourceNode.AudioBufferSourceNode')
  @DocsEditable()
  factory AudioBufferSourceNode(BaseAudioContext context, [Map options]) {
    if (options != null) {
      var options_1 = convertDartToNative_Dictionary(options);
      return AudioBufferSourceNode._create_1(context, options_1);
    }
    return AudioBufferSourceNode._create_2(context);
  }
  static AudioBufferSourceNode _create_1(context, options) => JS(
      'AudioBufferSourceNode',
      'new AudioBufferSourceNode(#,#)',
      context,
      options);
  static AudioBufferSourceNode _create_2(context) =>
      JS('AudioBufferSourceNode', 'new AudioBufferSourceNode(#)', context);

  @DomName('AudioBufferSourceNode.buffer')
  @DocsEditable()
  AudioBuffer buffer;

  @DomName('AudioBufferSourceNode.detune')
  @DocsEditable()
  @Experimental() // untriaged
  final AudioParam detune;

  @DomName('AudioBufferSourceNode.loop')
  @DocsEditable()
  bool loop;

  @DomName('AudioBufferSourceNode.loopEnd')
  @DocsEditable()
  num loopEnd;

  @DomName('AudioBufferSourceNode.loopStart')
  @DocsEditable()
  num loopStart;

  @DomName('AudioBufferSourceNode.playbackRate')
  @DocsEditable()
  final AudioParam playbackRate;

  @DomName('AudioBufferSourceNode.start')
  @DocsEditable()
  void start([num when, num grainOffset, num grainDuration]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DomName('AudioContext')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@Experimental()
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioContext-section
@Native("AudioContext,webkitAudioContext")
class AudioContext extends BaseAudioContext {
  // To suppress missing implicit constructor warnings.
  factory AudioContext._() {
    throw new UnsupportedError("Not supported");
  }

  /// Checks if this type is supported on the current platform.
  static bool get supported =>
      JS('bool', '!!(window.AudioContext || window.webkitAudioContext)');

  @DomName('AudioContext.baseLatency')
  @DocsEditable()
  @Experimental() // untriaged
  final num baseLatency;

  @DomName('AudioContext.close')
  @DocsEditable()
  @Experimental() // untriaged
  Future close() native;

  @DomName('AudioContext.getOutputTimestamp')
  @DocsEditable()
  @Experimental() // untriaged
  Map getOutputTimestamp() {
    return convertNativeToDart_Dictionary(_getOutputTimestamp_1());
  }

  @JSName('getOutputTimestamp')
  @DomName('AudioContext.getOutputTimestamp')
  @DocsEditable()
  @Experimental() // untriaged
  _getOutputTimestamp_1() native;

  @DomName('AudioContext.suspend')
  @DocsEditable()
  @Experimental() // untriaged
  Future suspend() native;

  factory AudioContext() => JS('AudioContext',
      'new (window.AudioContext || window.webkitAudioContext)()');

  GainNode createGain() {
    if (JS('bool', '#.createGain !== undefined', this)) {
      return JS('GainNode', '#.createGain()', this);
    } else {
      return JS('GainNode', '#.createGainNode()', this);
    }
  }

  ScriptProcessorNode createScriptProcessor(
      [int bufferSize, int numberOfInputChannels, int numberOfOutputChannels]) {
    var function = JS(
        '=Object',
        '#.createScriptProcessor || '
        '#.createJavaScriptNode',
        this,
        this);
    if (numberOfOutputChannels != null) {
      return JS('ScriptProcessorNode', '#.call(#, #, #, #)', function, this,
          bufferSize, numberOfInputChannels, numberOfOutputChannels);
    } else if (numberOfInputChannels != null) {
      return JS('ScriptProcessorNode', '#.call(#, #, #)', function, this,
          bufferSize, numberOfInputChannels);
    } else if (bufferSize != null) {
      return JS(
          'ScriptProcessorNode', '#.call(#, #)', function, this, bufferSize);
    } else {
      return JS('ScriptProcessorNode', '#.call(#)', function, this);
    }
  }

  @JSName('decodeAudioData')
  @DomName('AudioContext.decodeAudioData')
  @DocsEditable()
  Future _decodeAudioData(ByteBuffer audioData,
      [DecodeSuccessCallback successCallback,
      DecodeErrorCallback errorCallback]) native;

  @DomName('AudioContext.decodeAudioData')
  Future<AudioBuffer> decodeAudioData(ByteBuffer audioData,
      [DecodeSuccessCallback successCallback,
      DecodeErrorCallback errorCallback]) {
    if (successCallback != null && errorCallback != null) {
      return _decodeAudioData(audioData, successCallback, errorCallback);
    }

    var completer = new Completer<AudioBuffer>();
    _decodeAudioData(audioData, (value) {
      completer.complete(value);
    }, (error) {
      if (error == null) {
        completer.completeError('');
      } else {
        completer.completeError(error);
      }
    });
    return completer.future;
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('AudioDestinationNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioDestinationNode-section
@Experimental()
@Native("AudioDestinationNode")
class AudioDestinationNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory AudioDestinationNode._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('AudioDestinationNode.maxChannelCount')
  @DocsEditable()
  final int maxChannelCount;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('AudioListener')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioListener-section
@Experimental()
@Native("AudioListener")
class AudioListener extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory AudioListener._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('AudioListener.forwardX')
  @DocsEditable()
  @Experimental() // untriaged
  final AudioParam forwardX;

  @DomName('AudioListener.forwardY')
  @DocsEditable()
  @Experimental() // untriaged
  final AudioParam forwardY;

  @DomName('AudioListener.forwardZ')
  @DocsEditable()
  @Experimental() // untriaged
  final AudioParam forwardZ;

  @DomName('AudioListener.positionX')
  @DocsEditable()
  @Experimental() // untriaged
  final AudioParam positionX;

  @DomName('AudioListener.positionY')
  @DocsEditable()
  @Experimental() // untriaged
  final AudioParam positionY;

  @DomName('AudioListener.positionZ')
  @DocsEditable()
  @Experimental() // untriaged
  final AudioParam positionZ;

  @DomName('AudioListener.upX')
  @DocsEditable()
  @Experimental() // untriaged
  final AudioParam upX;

  @DomName('AudioListener.upY')
  @DocsEditable()
  @Experimental() // untriaged
  final AudioParam upY;

  @DomName('AudioListener.upZ')
  @DocsEditable()
  @Experimental() // untriaged
  final AudioParam upZ;

  @DomName('AudioListener.setOrientation')
  @DocsEditable()
  void setOrientation(num x, num y, num z, num xUp, num yUp, num zUp) native;

  @DomName('AudioListener.setPosition')
  @DocsEditable()
  void setPosition(num x, num y, num z) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DomName('AudioNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioNode-section
@Experimental()
@Native("AudioNode")
class AudioNode extends EventTarget {
  // To suppress missing implicit constructor warnings.
  factory AudioNode._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('AudioNode.channelCount')
  @DocsEditable()
  int channelCount;

  @DomName('AudioNode.channelCountMode')
  @DocsEditable()
  String channelCountMode;

  @DomName('AudioNode.channelInterpretation')
  @DocsEditable()
  String channelInterpretation;

  @DomName('AudioNode.context')
  @DocsEditable()
  final BaseAudioContext context;

  @DomName('AudioNode.numberOfInputs')
  @DocsEditable()
  final int numberOfInputs;

  @DomName('AudioNode.numberOfOutputs')
  @DocsEditable()
  final int numberOfOutputs;

  @JSName('connect')
  @DomName('AudioNode.connect')
  @DocsEditable()
  AudioNode _connect(destination, [int output, int input]) native;

  @DomName('AudioNode.disconnect')
  @DocsEditable()
  void disconnect([destination_OR_output, int output, int input]) native;

  @DomName('AudioNode.connect')
  void connectNode(AudioNode destination, [int output = 0, int input = 0]) {
    _connect(destination, output, input);
  }

  @DomName('AudioNode.connect')
  void connectParam(AudioParam destination, [int output = 0]) {
    _connect(destination, output);
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('AudioParam')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioParam
@Experimental()
@Native("AudioParam")
class AudioParam extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory AudioParam._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('AudioParam.defaultValue')
  @DocsEditable()
  final num defaultValue;

  @DomName('AudioParam.maxValue')
  @DocsEditable()
  final num maxValue;

  @DomName('AudioParam.minValue')
  @DocsEditable()
  final num minValue;

  @DomName('AudioParam.value')
  @DocsEditable()
  num value;

  @DomName('AudioParam.cancelAndHoldAtTime')
  @DocsEditable()
  @Experimental() // untriaged
  AudioParam cancelAndHoldAtTime(num startTime) native;

  @DomName('AudioParam.cancelScheduledValues')
  @DocsEditable()
  AudioParam cancelScheduledValues(num startTime) native;

  @DomName('AudioParam.exponentialRampToValueAtTime')
  @DocsEditable()
  AudioParam exponentialRampToValueAtTime(num value, num time) native;

  @DomName('AudioParam.linearRampToValueAtTime')
  @DocsEditable()
  AudioParam linearRampToValueAtTime(num value, num time) native;

  @DomName('AudioParam.setTargetAtTime')
  @DocsEditable()
  AudioParam setTargetAtTime(num target, num time, num timeConstant) native;

  @DomName('AudioParam.setValueAtTime')
  @DocsEditable()
  AudioParam setValueAtTime(num value, num time) native;

  @DomName('AudioParam.setValueCurveAtTime')
  @DocsEditable()
  AudioParam setValueCurveAtTime(List<num> values, num time, num duration)
      native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('AudioParamMap')
@Experimental() // untriaged
@Native("AudioParamMap")
class AudioParamMap extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory AudioParamMap._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('AudioProcessingEvent')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioProcessingEvent-section
@Experimental()
@Native("AudioProcessingEvent")
class AudioProcessingEvent extends Event {
  // To suppress missing implicit constructor warnings.
  factory AudioProcessingEvent._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('AudioProcessingEvent.AudioProcessingEvent')
  @DocsEditable()
  factory AudioProcessingEvent(String type, Map eventInitDict) {
    var eventInitDict_1 = convertDartToNative_Dictionary(eventInitDict);
    return AudioProcessingEvent._create_1(type, eventInitDict_1);
  }
  static AudioProcessingEvent _create_1(type, eventInitDict) => JS(
      'AudioProcessingEvent',
      'new AudioProcessingEvent(#,#)',
      type,
      eventInitDict);

  @DomName('AudioProcessingEvent.inputBuffer')
  @DocsEditable()
  final AudioBuffer inputBuffer;

  @DomName('AudioProcessingEvent.outputBuffer')
  @DocsEditable()
  final AudioBuffer outputBuffer;

  @DomName('AudioProcessingEvent.playbackTime')
  @DocsEditable()
  @Experimental() // untriaged
  final num playbackTime;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('AudioScheduledSourceNode')
@Experimental() // untriaged
@Native("AudioScheduledSourceNode")
class AudioScheduledSourceNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory AudioScheduledSourceNode._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('AudioScheduledSourceNode.endedEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> endedEvent =
      const EventStreamProvider<Event>('ended');

  @JSName('start')
  @DomName('AudioScheduledSourceNode.start')
  @DocsEditable()
  @Experimental() // untriaged
  void start2([num when]) native;

  @DomName('AudioScheduledSourceNode.stop')
  @DocsEditable()
  @Experimental() // untriaged
  void stop([num when]) native;

  @DomName('AudioScheduledSourceNode.onended')
  @DocsEditable()
  @Experimental() // untriaged
  Stream<Event> get onEnded => endedEvent.forTarget(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('AudioTrack')
@Experimental() // untriaged
@Native("AudioTrack")
class AudioTrack extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory AudioTrack._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('AudioTrack.enabled')
  @DocsEditable()
  @Experimental() // untriaged
  bool enabled;

  @DomName('AudioTrack.id')
  @DocsEditable()
  @Experimental() // untriaged
  final String id;

  @DomName('AudioTrack.kind')
  @DocsEditable()
  @Experimental() // untriaged
  final String kind;

  @DomName('AudioTrack.label')
  @DocsEditable()
  @Experimental() // untriaged
  final String label;

  @DomName('AudioTrack.language')
  @DocsEditable()
  @Experimental() // untriaged
  final String language;

  @DomName('AudioTrack.sourceBuffer')
  @DocsEditable()
  @Experimental() // untriaged
  final SourceBuffer sourceBuffer;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('AudioTrackList')
@Experimental() // untriaged
@Native("AudioTrackList")
class AudioTrackList extends EventTarget {
  // To suppress missing implicit constructor warnings.
  factory AudioTrackList._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('AudioTrackList.changeEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> changeEvent =
      const EventStreamProvider<Event>('change');

  @DomName('AudioTrackList.length')
  @DocsEditable()
  @Experimental() // untriaged
  final int length;

  @DomName('AudioTrackList.__getter__')
  @DocsEditable()
  @Experimental() // untriaged
  AudioTrack __getter__(int index) native;

  @DomName('AudioTrackList.getTrackById')
  @DocsEditable()
  @Experimental() // untriaged
  AudioTrack getTrackById(String id) native;

  @DomName('AudioTrackList.onchange')
  @DocsEditable()
  @Experimental() // untriaged
  Stream<Event> get onChange => changeEvent.forTarget(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('AudioWorkletGlobalScope')
@Experimental() // untriaged
@Native("AudioWorkletGlobalScope")
class AudioWorkletGlobalScope extends WorkletGlobalScope {
  // To suppress missing implicit constructor warnings.
  factory AudioWorkletGlobalScope._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('AudioWorkletGlobalScope.currentTime')
  @DocsEditable()
  @Experimental() // untriaged
  final num currentTime;

  @DomName('AudioWorkletGlobalScope.sampleRate')
  @DocsEditable()
  @Experimental() // untriaged
  final num sampleRate;

  @DomName('AudioWorkletGlobalScope.registerProcessor')
  @DocsEditable()
  @Experimental() // untriaged
  void registerProcessor(String name, Object processorConstructor) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('AudioWorkletNode')
@Experimental() // untriaged
@Native("AudioWorkletNode")
class AudioWorkletNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory AudioWorkletNode._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('AudioWorkletNode.AudioWorkletNode')
  @DocsEditable()
  factory AudioWorkletNode(BaseAudioContext context, String name,
      [Map options]) {
    if (options != null) {
      var options_1 = convertDartToNative_Dictionary(options);
      return AudioWorkletNode._create_1(context, name, options_1);
    }
    return AudioWorkletNode._create_2(context, name);
  }
  static AudioWorkletNode _create_1(context, name, options) => JS(
      'AudioWorkletNode',
      'new AudioWorkletNode(#,#,#)',
      context,
      name,
      options);
  static AudioWorkletNode _create_2(context, name) =>
      JS('AudioWorkletNode', 'new AudioWorkletNode(#,#)', context, name);

  @DomName('AudioWorkletNode.parameters')
  @DocsEditable()
  @Experimental() // untriaged
  final AudioParamMap parameters;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('AudioWorkletProcessor')
@Experimental() // untriaged
@Native("AudioWorkletProcessor")
class AudioWorkletProcessor extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory AudioWorkletProcessor._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('BaseAudioContext')
@Experimental() // untriaged
@Native("BaseAudioContext")
class BaseAudioContext extends EventTarget {
  // To suppress missing implicit constructor warnings.
  factory BaseAudioContext._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('BaseAudioContext.currentTime')
  @DocsEditable()
  @Experimental() // untriaged
  final num currentTime;

  @DomName('BaseAudioContext.destination')
  @DocsEditable()
  @Experimental() // untriaged
  final AudioDestinationNode destination;

  @DomName('BaseAudioContext.listener')
  @DocsEditable()
  @Experimental() // untriaged
  final AudioListener listener;

  @DomName('BaseAudioContext.sampleRate')
  @DocsEditable()
  @Experimental() // untriaged
  final num sampleRate;

  @DomName('BaseAudioContext.state')
  @DocsEditable()
  @Experimental() // untriaged
  final String state;

  @DomName('BaseAudioContext.createAnalyser')
  @DocsEditable()
  @Experimental() // untriaged
  AnalyserNode createAnalyser() native;

  @DomName('BaseAudioContext.createBiquadFilter')
  @DocsEditable()
  @Experimental() // untriaged
  BiquadFilterNode createBiquadFilter() native;

  @DomName('BaseAudioContext.createBuffer')
  @DocsEditable()
  @Experimental() // untriaged
  AudioBuffer createBuffer(
      int numberOfChannels, int numberOfFrames, num sampleRate) native;

  @DomName('BaseAudioContext.createBufferSource')
  @DocsEditable()
  @Experimental() // untriaged
  AudioBufferSourceNode createBufferSource() native;

  @DomName('BaseAudioContext.createChannelMerger')
  @DocsEditable()
  @Experimental() // untriaged
  ChannelMergerNode createChannelMerger([int numberOfInputs]) native;

  @DomName('BaseAudioContext.createChannelSplitter')
  @DocsEditable()
  @Experimental() // untriaged
  ChannelSplitterNode createChannelSplitter([int numberOfOutputs]) native;

  @DomName('BaseAudioContext.createConstantSource')
  @DocsEditable()
  @Experimental() // untriaged
  ConstantSourceNode createConstantSource() native;

  @DomName('BaseAudioContext.createConvolver')
  @DocsEditable()
  @Experimental() // untriaged
  ConvolverNode createConvolver() native;

  @DomName('BaseAudioContext.createDelay')
  @DocsEditable()
  @Experimental() // untriaged
  DelayNode createDelay([num maxDelayTime]) native;

  @DomName('BaseAudioContext.createDynamicsCompressor')
  @DocsEditable()
  @Experimental() // untriaged
  DynamicsCompressorNode createDynamicsCompressor() native;

  @DomName('BaseAudioContext.createGain')
  @DocsEditable()
  @Experimental() // untriaged
  GainNode createGain() native;

  @JSName('createIIRFilter')
  @DomName('BaseAudioContext.createIIRFilter')
  @DocsEditable()
  @Experimental() // untriaged
  IirFilterNode createIirFilter(List<num> feedForward, List<num> feedBack)
      native;

  @DomName('BaseAudioContext.createMediaElementSource')
  @DocsEditable()
  @Experimental() // untriaged
  MediaElementAudioSourceNode createMediaElementSource(
      MediaElement mediaElement) native;

  @DomName('BaseAudioContext.createMediaStreamDestination')
  @DocsEditable()
  @Experimental() // untriaged
  MediaStreamAudioDestinationNode createMediaStreamDestination() native;

  @DomName('BaseAudioContext.createMediaStreamSource')
  @DocsEditable()
  @Experimental() // untriaged
  MediaStreamAudioSourceNode createMediaStreamSource(MediaStream mediaStream)
      native;

  @DomName('BaseAudioContext.createOscillator')
  @DocsEditable()
  @Experimental() // untriaged
  OscillatorNode createOscillator() native;

  @DomName('BaseAudioContext.createPanner')
  @DocsEditable()
  @Experimental() // untriaged
  PannerNode createPanner() native;

  @DomName('BaseAudioContext.createPeriodicWave')
  @DocsEditable()
  @Experimental() // untriaged
  PeriodicWave createPeriodicWave(List<num> real, List<num> imag,
      [Map options]) {
    if (options != null) {
      var options_1 = convertDartToNative_Dictionary(options);
      return _createPeriodicWave_1(real, imag, options_1);
    }
    return _createPeriodicWave_2(real, imag);
  }

  @JSName('createPeriodicWave')
  @DomName('BaseAudioContext.createPeriodicWave')
  @DocsEditable()
  @Experimental() // untriaged
  PeriodicWave _createPeriodicWave_1(List<num> real, List<num> imag, options)
      native;
  @JSName('createPeriodicWave')
  @DomName('BaseAudioContext.createPeriodicWave')
  @DocsEditable()
  @Experimental() // untriaged
  PeriodicWave _createPeriodicWave_2(List<num> real, List<num> imag) native;

  @DomName('BaseAudioContext.createScriptProcessor')
  @DocsEditable()
  @Experimental() // untriaged
  ScriptProcessorNode createScriptProcessor(
      [int bufferSize,
      int numberOfInputChannels,
      int numberOfOutputChannels]) native;

  @DomName('BaseAudioContext.createStereoPanner')
  @DocsEditable()
  @Experimental() // untriaged
  StereoPannerNode createStereoPanner() native;

  @DomName('BaseAudioContext.createWaveShaper')
  @DocsEditable()
  @Experimental() // untriaged
  WaveShaperNode createWaveShaper() native;

  @DomName('BaseAudioContext.decodeAudioData')
  @DocsEditable()
  @Experimental() // untriaged
  Future decodeAudioData(ByteBuffer audioData,
      [DecodeSuccessCallback successCallback,
      DecodeErrorCallback errorCallback]) native;

  @DomName('BaseAudioContext.resume')
  @DocsEditable()
  @Experimental() // untriaged
  Future resume() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('BiquadFilterNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#BiquadFilterNode-section
@Experimental()
@Native("BiquadFilterNode")
class BiquadFilterNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory BiquadFilterNode._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('BiquadFilterNode.BiquadFilterNode')
  @DocsEditable()
  factory BiquadFilterNode(BaseAudioContext context, [Map options]) {
    if (options != null) {
      var options_1 = convertDartToNative_Dictionary(options);
      return BiquadFilterNode._create_1(context, options_1);
    }
    return BiquadFilterNode._create_2(context);
  }
  static BiquadFilterNode _create_1(context, options) =>
      JS('BiquadFilterNode', 'new BiquadFilterNode(#,#)', context, options);
  static BiquadFilterNode _create_2(context) =>
      JS('BiquadFilterNode', 'new BiquadFilterNode(#)', context);

  @DomName('BiquadFilterNode.Q')
  @DocsEditable()
  final AudioParam Q;

  @DomName('BiquadFilterNode.detune')
  @DocsEditable()
  final AudioParam detune;

  @DomName('BiquadFilterNode.frequency')
  @DocsEditable()
  final AudioParam frequency;

  @DomName('BiquadFilterNode.gain')
  @DocsEditable()
  final AudioParam gain;

  @DomName('BiquadFilterNode.type')
  @DocsEditable()
  String type;

  @DomName('BiquadFilterNode.getFrequencyResponse')
  @DocsEditable()
  void getFrequencyResponse(Float32List frequencyHz, Float32List magResponse,
      Float32List phaseResponse) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('ChannelMergerNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#ChannelMergerNode-section
@Experimental()
@Native("ChannelMergerNode,AudioChannelMerger")
class ChannelMergerNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory ChannelMergerNode._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('ChannelMergerNode.ChannelMergerNode')
  @DocsEditable()
  factory ChannelMergerNode(BaseAudioContext context, [Map options]) {
    if (options != null) {
      var options_1 = convertDartToNative_Dictionary(options);
      return ChannelMergerNode._create_1(context, options_1);
    }
    return ChannelMergerNode._create_2(context);
  }
  static ChannelMergerNode _create_1(context, options) =>
      JS('ChannelMergerNode', 'new ChannelMergerNode(#,#)', context, options);
  static ChannelMergerNode _create_2(context) =>
      JS('ChannelMergerNode', 'new ChannelMergerNode(#)', context);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('ChannelSplitterNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#ChannelSplitterNode-section
@Experimental()
@Native("ChannelSplitterNode,AudioChannelSplitter")
class ChannelSplitterNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory ChannelSplitterNode._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('ChannelSplitterNode.ChannelSplitterNode')
  @DocsEditable()
  factory ChannelSplitterNode(BaseAudioContext context, [Map options]) {
    if (options != null) {
      var options_1 = convertDartToNative_Dictionary(options);
      return ChannelSplitterNode._create_1(context, options_1);
    }
    return ChannelSplitterNode._create_2(context);
  }
  static ChannelSplitterNode _create_1(context, options) => JS(
      'ChannelSplitterNode', 'new ChannelSplitterNode(#,#)', context, options);
  static ChannelSplitterNode _create_2(context) =>
      JS('ChannelSplitterNode', 'new ChannelSplitterNode(#)', context);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('ConstantSourceNode')
@Experimental() // untriaged
@Native("ConstantSourceNode")
class ConstantSourceNode extends AudioScheduledSourceNode {
  // To suppress missing implicit constructor warnings.
  factory ConstantSourceNode._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('ConstantSourceNode.ConstantSourceNode')
  @DocsEditable()
  factory ConstantSourceNode(BaseAudioContext context, [Map options]) {
    if (options != null) {
      var options_1 = convertDartToNative_Dictionary(options);
      return ConstantSourceNode._create_1(context, options_1);
    }
    return ConstantSourceNode._create_2(context);
  }
  static ConstantSourceNode _create_1(context, options) =>
      JS('ConstantSourceNode', 'new ConstantSourceNode(#,#)', context, options);
  static ConstantSourceNode _create_2(context) =>
      JS('ConstantSourceNode', 'new ConstantSourceNode(#)', context);

  @DomName('ConstantSourceNode.offset')
  @DocsEditable()
  @Experimental() // untriaged
  final AudioParam offset;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('ConvolverNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#ConvolverNode
@Experimental()
@Native("ConvolverNode")
class ConvolverNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory ConvolverNode._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('ConvolverNode.ConvolverNode')
  @DocsEditable()
  factory ConvolverNode(BaseAudioContext context, [Map options]) {
    if (options != null) {
      var options_1 = convertDartToNative_Dictionary(options);
      return ConvolverNode._create_1(context, options_1);
    }
    return ConvolverNode._create_2(context);
  }
  static ConvolverNode _create_1(context, options) =>
      JS('ConvolverNode', 'new ConvolverNode(#,#)', context, options);
  static ConvolverNode _create_2(context) =>
      JS('ConvolverNode', 'new ConvolverNode(#)', context);

  @DomName('ConvolverNode.buffer')
  @DocsEditable()
  AudioBuffer buffer;

  @DomName('ConvolverNode.normalize')
  @DocsEditable()
  bool normalize;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('DelayNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#DelayNode
@Experimental()
@Native("DelayNode")
class DelayNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory DelayNode._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('DelayNode.DelayNode')
  @DocsEditable()
  factory DelayNode(BaseAudioContext context, [Map options]) {
    if (options != null) {
      var options_1 = convertDartToNative_Dictionary(options);
      return DelayNode._create_1(context, options_1);
    }
    return DelayNode._create_2(context);
  }
  static DelayNode _create_1(context, options) =>
      JS('DelayNode', 'new DelayNode(#,#)', context, options);
  static DelayNode _create_2(context) =>
      JS('DelayNode', 'new DelayNode(#)', context);

  @DomName('DelayNode.delayTime')
  @DocsEditable()
  final AudioParam delayTime;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('DynamicsCompressorNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#DynamicsCompressorNode
@Experimental()
@Native("DynamicsCompressorNode")
class DynamicsCompressorNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory DynamicsCompressorNode._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('DynamicsCompressorNode.DynamicsCompressorNode')
  @DocsEditable()
  factory DynamicsCompressorNode(BaseAudioContext context, [Map options]) {
    if (options != null) {
      var options_1 = convertDartToNative_Dictionary(options);
      return DynamicsCompressorNode._create_1(context, options_1);
    }
    return DynamicsCompressorNode._create_2(context);
  }
  static DynamicsCompressorNode _create_1(context, options) => JS(
      'DynamicsCompressorNode',
      'new DynamicsCompressorNode(#,#)',
      context,
      options);
  static DynamicsCompressorNode _create_2(context) =>
      JS('DynamicsCompressorNode', 'new DynamicsCompressorNode(#)', context);

  @DomName('DynamicsCompressorNode.attack')
  @DocsEditable()
  final AudioParam attack;

  @DomName('DynamicsCompressorNode.knee')
  @DocsEditable()
  final AudioParam knee;

  @DomName('DynamicsCompressorNode.ratio')
  @DocsEditable()
  final AudioParam ratio;

  @DomName('DynamicsCompressorNode.reduction')
  @DocsEditable()
  final num reduction;

  @DomName('DynamicsCompressorNode.release')
  @DocsEditable()
  final AudioParam release;

  @DomName('DynamicsCompressorNode.threshold')
  @DocsEditable()
  final AudioParam threshold;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('GainNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#GainNode
@Experimental()
@Native("GainNode,AudioGainNode")
class GainNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory GainNode._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('GainNode.GainNode')
  @DocsEditable()
  factory GainNode(BaseAudioContext context, [Map options]) {
    if (options != null) {
      var options_1 = convertDartToNative_Dictionary(options);
      return GainNode._create_1(context, options_1);
    }
    return GainNode._create_2(context);
  }
  static GainNode _create_1(context, options) =>
      JS('GainNode', 'new GainNode(#,#)', context, options);
  static GainNode _create_2(context) =>
      JS('GainNode', 'new GainNode(#)', context);

  @DomName('GainNode.gain')
  @DocsEditable()
  final AudioParam gain;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('IIRFilterNode')
@Experimental() // untriaged
@Native("IIRFilterNode")
class IirFilterNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory IirFilterNode._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('IIRFilterNode.IIRFilterNode')
  @DocsEditable()
  factory IirFilterNode(BaseAudioContext context, Map options) {
    var options_1 = convertDartToNative_Dictionary(options);
    return IirFilterNode._create_1(context, options_1);
  }
  static IirFilterNode _create_1(context, options) =>
      JS('IirFilterNode', 'new IIRFilterNode(#,#)', context, options);

  @DomName('IIRFilterNode.getFrequencyResponse')
  @DocsEditable()
  @Experimental() // untriaged
  void getFrequencyResponse(Float32List frequencyHz, Float32List magResponse,
      Float32List phaseResponse) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('MediaElementAudioSourceNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#MediaElementAudioSourceNode
@Experimental()
@Native("MediaElementAudioSourceNode")
class MediaElementAudioSourceNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory MediaElementAudioSourceNode._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('MediaElementAudioSourceNode.MediaElementAudioSourceNode')
  @DocsEditable()
  factory MediaElementAudioSourceNode(BaseAudioContext context, Map options) {
    var options_1 = convertDartToNative_Dictionary(options);
    return MediaElementAudioSourceNode._create_1(context, options_1);
  }
  static MediaElementAudioSourceNode _create_1(context, options) => JS(
      'MediaElementAudioSourceNode',
      'new MediaElementAudioSourceNode(#,#)',
      context,
      options);

  @DomName('MediaElementAudioSourceNode.mediaElement')
  @DocsEditable()
  @Experimental() // non-standard
  final MediaElement mediaElement;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('MediaStreamAudioDestinationNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#MediaStreamAudioDestinationNode
@Experimental()
@Native("MediaStreamAudioDestinationNode")
class MediaStreamAudioDestinationNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory MediaStreamAudioDestinationNode._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('MediaStreamAudioDestinationNode.MediaStreamAudioDestinationNode')
  @DocsEditable()
  factory MediaStreamAudioDestinationNode(BaseAudioContext context,
      [Map options]) {
    if (options != null) {
      var options_1 = convertDartToNative_Dictionary(options);
      return MediaStreamAudioDestinationNode._create_1(context, options_1);
    }
    return MediaStreamAudioDestinationNode._create_2(context);
  }
  static MediaStreamAudioDestinationNode _create_1(context, options) => JS(
      'MediaStreamAudioDestinationNode',
      'new MediaStreamAudioDestinationNode(#,#)',
      context,
      options);
  static MediaStreamAudioDestinationNode _create_2(context) => JS(
      'MediaStreamAudioDestinationNode',
      'new MediaStreamAudioDestinationNode(#)',
      context);

  @DomName('MediaStreamAudioDestinationNode.stream')
  @DocsEditable()
  final MediaStream stream;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('MediaStreamAudioSourceNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#MediaStreamAudioSourceNode
@Experimental()
@Native("MediaStreamAudioSourceNode")
class MediaStreamAudioSourceNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory MediaStreamAudioSourceNode._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('MediaStreamAudioSourceNode.MediaStreamAudioSourceNode')
  @DocsEditable()
  factory MediaStreamAudioSourceNode(BaseAudioContext context, Map options) {
    var options_1 = convertDartToNative_Dictionary(options);
    return MediaStreamAudioSourceNode._create_1(context, options_1);
  }
  static MediaStreamAudioSourceNode _create_1(context, options) => JS(
      'MediaStreamAudioSourceNode',
      'new MediaStreamAudioSourceNode(#,#)',
      context,
      options);

  @DomName('MediaStreamAudioSourceNode.mediaStream')
  @DocsEditable()
  final MediaStream mediaStream;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('OfflineAudioCompletionEvent')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#OfflineAudioCompletionEvent-section
@Experimental()
@Native("OfflineAudioCompletionEvent")
class OfflineAudioCompletionEvent extends Event {
  // To suppress missing implicit constructor warnings.
  factory OfflineAudioCompletionEvent._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('OfflineAudioCompletionEvent.OfflineAudioCompletionEvent')
  @DocsEditable()
  factory OfflineAudioCompletionEvent(String type, Map eventInitDict) {
    var eventInitDict_1 = convertDartToNative_Dictionary(eventInitDict);
    return OfflineAudioCompletionEvent._create_1(type, eventInitDict_1);
  }
  static OfflineAudioCompletionEvent _create_1(type, eventInitDict) => JS(
      'OfflineAudioCompletionEvent',
      'new OfflineAudioCompletionEvent(#,#)',
      type,
      eventInitDict);

  @DomName('OfflineAudioCompletionEvent.renderedBuffer')
  @DocsEditable()
  final AudioBuffer renderedBuffer;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('OfflineAudioContext')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#OfflineAudioContext-section
@Experimental()
@Native("OfflineAudioContext")
class OfflineAudioContext extends BaseAudioContext {
  // To suppress missing implicit constructor warnings.
  factory OfflineAudioContext._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('OfflineAudioContext.OfflineAudioContext')
  @DocsEditable()
  factory OfflineAudioContext(numberOfChannels_OR_options,
      [int numberOfFrames, num sampleRate]) {
    if ((sampleRate is num) &&
        (numberOfFrames is int) &&
        (numberOfChannels_OR_options is int)) {
      return OfflineAudioContext._create_1(
          numberOfChannels_OR_options, numberOfFrames, sampleRate);
    }
    if ((numberOfChannels_OR_options is Map) &&
        numberOfFrames == null &&
        sampleRate == null) {
      var options_1 =
          convertDartToNative_Dictionary(numberOfChannels_OR_options);
      return OfflineAudioContext._create_2(options_1);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }
  static OfflineAudioContext _create_1(
          numberOfChannels_OR_options, numberOfFrames, sampleRate) =>
      JS('OfflineAudioContext', 'new OfflineAudioContext(#,#,#)',
          numberOfChannels_OR_options, numberOfFrames, sampleRate);
  static OfflineAudioContext _create_2(numberOfChannels_OR_options) => JS(
      'OfflineAudioContext',
      'new OfflineAudioContext(#)',
      numberOfChannels_OR_options);

  @DomName('OfflineAudioContext.length')
  @DocsEditable()
  @Experimental() // untriaged
  final int length;

  @DomName('OfflineAudioContext.startRendering')
  @DocsEditable()
  @Experimental() // untriaged
  Future startRendering() native;

  @JSName('suspend')
  @DomName('OfflineAudioContext.suspend')
  @DocsEditable()
  @Experimental() // untriaged
  Future suspendFor(num suspendTime) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('OscillatorNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#dfn-OscillatorNode
@Experimental()
@Native("OscillatorNode,Oscillator")
class OscillatorNode extends AudioScheduledSourceNode {
  // To suppress missing implicit constructor warnings.
  factory OscillatorNode._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('OscillatorNode.OscillatorNode')
  @DocsEditable()
  factory OscillatorNode(BaseAudioContext context, [Map options]) {
    if (options != null) {
      var options_1 = convertDartToNative_Dictionary(options);
      return OscillatorNode._create_1(context, options_1);
    }
    return OscillatorNode._create_2(context);
  }
  static OscillatorNode _create_1(context, options) =>
      JS('OscillatorNode', 'new OscillatorNode(#,#)', context, options);
  static OscillatorNode _create_2(context) =>
      JS('OscillatorNode', 'new OscillatorNode(#)', context);

  @DomName('OscillatorNode.detune')
  @DocsEditable()
  final AudioParam detune;

  @DomName('OscillatorNode.frequency')
  @DocsEditable()
  final AudioParam frequency;

  @DomName('OscillatorNode.type')
  @DocsEditable()
  String type;

  @DomName('OscillatorNode.setPeriodicWave')
  @DocsEditable()
  @Experimental() // untriaged
  void setPeriodicWave(PeriodicWave periodicWave) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('PannerNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#PannerNode
@Experimental()
@Native("PannerNode,AudioPannerNode,webkitAudioPannerNode")
class PannerNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory PannerNode._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('PannerNode.PannerNode')
  @DocsEditable()
  factory PannerNode(BaseAudioContext context, [Map options]) {
    if (options != null) {
      var options_1 = convertDartToNative_Dictionary(options);
      return PannerNode._create_1(context, options_1);
    }
    return PannerNode._create_2(context);
  }
  static PannerNode _create_1(context, options) =>
      JS('PannerNode', 'new PannerNode(#,#)', context, options);
  static PannerNode _create_2(context) =>
      JS('PannerNode', 'new PannerNode(#)', context);

  @DomName('PannerNode.coneInnerAngle')
  @DocsEditable()
  num coneInnerAngle;

  @DomName('PannerNode.coneOuterAngle')
  @DocsEditable()
  num coneOuterAngle;

  @DomName('PannerNode.coneOuterGain')
  @DocsEditable()
  num coneOuterGain;

  @DomName('PannerNode.distanceModel')
  @DocsEditable()
  String distanceModel;

  @DomName('PannerNode.maxDistance')
  @DocsEditable()
  num maxDistance;

  @DomName('PannerNode.orientationX')
  @DocsEditable()
  @Experimental() // untriaged
  final AudioParam orientationX;

  @DomName('PannerNode.orientationY')
  @DocsEditable()
  @Experimental() // untriaged
  final AudioParam orientationY;

  @DomName('PannerNode.orientationZ')
  @DocsEditable()
  @Experimental() // untriaged
  final AudioParam orientationZ;

  @DomName('PannerNode.panningModel')
  @DocsEditable()
  String panningModel;

  @DomName('PannerNode.positionX')
  @DocsEditable()
  @Experimental() // untriaged
  final AudioParam positionX;

  @DomName('PannerNode.positionY')
  @DocsEditable()
  @Experimental() // untriaged
  final AudioParam positionY;

  @DomName('PannerNode.positionZ')
  @DocsEditable()
  @Experimental() // untriaged
  final AudioParam positionZ;

  @DomName('PannerNode.refDistance')
  @DocsEditable()
  num refDistance;

  @DomName('PannerNode.rolloffFactor')
  @DocsEditable()
  num rolloffFactor;

  @DomName('PannerNode.setOrientation')
  @DocsEditable()
  void setOrientation(num x, num y, num z) native;

  @DomName('PannerNode.setPosition')
  @DocsEditable()
  void setPosition(num x, num y, num z) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('PeriodicWave')
@Experimental() // untriaged
@Native("PeriodicWave")
class PeriodicWave extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory PeriodicWave._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('PeriodicWave.PeriodicWave')
  @DocsEditable()
  factory PeriodicWave(BaseAudioContext context, [Map options]) {
    if (options != null) {
      var options_1 = convertDartToNative_Dictionary(options);
      return PeriodicWave._create_1(context, options_1);
    }
    return PeriodicWave._create_2(context);
  }
  static PeriodicWave _create_1(context, options) =>
      JS('PeriodicWave', 'new PeriodicWave(#,#)', context, options);
  static PeriodicWave _create_2(context) =>
      JS('PeriodicWave', 'new PeriodicWave(#)', context);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('ScriptProcessorNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#ScriptProcessorNode
@Experimental()
@Native("ScriptProcessorNode,JavaScriptAudioNode")
class ScriptProcessorNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory ScriptProcessorNode._() {
    throw new UnsupportedError("Not supported");
  }

  /**
   * Static factory designed to expose `audioprocess` events to event
   * handlers that are not necessarily instances of [ScriptProcessorNode].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('ScriptProcessorNode.audioprocessEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<AudioProcessingEvent> audioProcessEvent =
      const EventStreamProvider<AudioProcessingEvent>('audioprocess');

  @DomName('ScriptProcessorNode.bufferSize')
  @DocsEditable()
  final int bufferSize;

  @DomName('ScriptProcessorNode.setEventListener')
  @DocsEditable()
  @Experimental() // untriaged
  void setEventListener(EventListener eventListener) native;

  /// Stream of `audioprocess` events handled by this [ScriptProcessorNode].
/**
   * Get a Stream that fires events when AudioProcessingEvents occur.
   * This particular stream is special in that it only allows one listener to a
   * given stream. Converting the returned Stream [asBroadcast] will likely ruin
   * the soft-real-time properties which which these events are fired and can
   * be processed.
   */
  @DomName('ScriptProcessorNode.onaudioprocess')
  @DocsEditable()
  @Experimental() // untriaged
  Stream<AudioProcessingEvent> get onAudioProcess =>
      audioProcessEvent.forTarget(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('StereoPannerNode')
@Experimental() // untriaged
@Native("StereoPannerNode")
class StereoPannerNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory StereoPannerNode._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('StereoPannerNode.StereoPannerNode')
  @DocsEditable()
  factory StereoPannerNode(BaseAudioContext context, [Map options]) {
    if (options != null) {
      var options_1 = convertDartToNative_Dictionary(options);
      return StereoPannerNode._create_1(context, options_1);
    }
    return StereoPannerNode._create_2(context);
  }
  static StereoPannerNode _create_1(context, options) =>
      JS('StereoPannerNode', 'new StereoPannerNode(#,#)', context, options);
  static StereoPannerNode _create_2(context) =>
      JS('StereoPannerNode', 'new StereoPannerNode(#)', context);

  @DomName('StereoPannerNode.pan')
  @DocsEditable()
  @Experimental() // untriaged
  final AudioParam pan;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('WaveShaperNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#dfn-WaveShaperNode
@Experimental()
@Native("WaveShaperNode")
class WaveShaperNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory WaveShaperNode._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('WaveShaperNode.WaveShaperNode')
  @DocsEditable()
  factory WaveShaperNode(BaseAudioContext context, [Map options]) {
    if (options != null) {
      var options_1 = convertDartToNative_Dictionary(options);
      return WaveShaperNode._create_1(context, options_1);
    }
    return WaveShaperNode._create_2(context);
  }
  static WaveShaperNode _create_1(context, options) =>
      JS('WaveShaperNode', 'new WaveShaperNode(#,#)', context, options);
  static WaveShaperNode _create_2(context) =>
      JS('WaveShaperNode', 'new WaveShaperNode(#)', context);

  @DomName('WaveShaperNode.curve')
  @DocsEditable()
  Float32List curve;

  @DomName('WaveShaperNode.oversample')
  @DocsEditable()
  String oversample;
}
