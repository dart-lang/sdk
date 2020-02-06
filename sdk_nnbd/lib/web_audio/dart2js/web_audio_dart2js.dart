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

@Native("AnalyserNode,RealtimeAnalyserNode")
class AnalyserNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory AnalyserNode._() {
    throw new UnsupportedError("Not supported");
  }

  factory AnalyserNode(BaseAudioContext context, [Map? options]) {
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

  int get fftSize => JS("int", "#.fftSize", this);

  set fftSize(int value) {
    JS("void", "#.fftSize = #", this, value);
  }

  int get frequencyBinCount => JS("int", "#.frequencyBinCount", this);

  num get maxDecibels => JS("num", "#.maxDecibels", this);

  set maxDecibels(num value) {
    JS("void", "#.maxDecibels = #", this, value);
  }

  num get minDecibels => JS("num", "#.minDecibels", this);

  set minDecibels(num value) {
    JS("void", "#.minDecibels = #", this, value);
  }

  num get smoothingTimeConstant => JS("num", "#.smoothingTimeConstant", this);

  set smoothingTimeConstant(num value) {
    JS("void", "#.smoothingTimeConstant = #", this, value);
  }

  void getByteFrequencyData(Uint8List array) native;

  void getByteTimeDomainData(Uint8List array) native;

  void getFloatFrequencyData(Float32List array) native;

  void getFloatTimeDomainData(Float32List array) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("AudioBuffer")
class AudioBuffer extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory AudioBuffer._() {
    throw new UnsupportedError("Not supported");
  }

  factory AudioBuffer(Map options) {
    var options_1 = convertDartToNative_Dictionary(options);
    return AudioBuffer._create_1(options_1);
  }
  static AudioBuffer _create_1(options) =>
      JS('AudioBuffer', 'new AudioBuffer(#)', options);

  num get duration => JS("num", "#.duration", this);

  int get length => JS("int", "#.length", this);

  int get numberOfChannels => JS("int", "#.numberOfChannels", this);

  num get sampleRate => JS("num", "#.sampleRate", this);

  void copyFromChannel(Float32List destination, int channelNumber,
      [int? startInChannel]) native;

  void copyToChannel(Float32List source, int channelNumber,
      [int? startInChannel]) native;

  Float32List getChannelData(int channelIndex) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@Native("AudioBufferSourceNode")
class AudioBufferSourceNode extends AudioScheduledSourceNode {
  // To suppress missing implicit constructor warnings.
  factory AudioBufferSourceNode._() {
    throw new UnsupportedError("Not supported");
  }

  factory AudioBufferSourceNode(BaseAudioContext context, [Map? options]) {
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

  AudioBuffer? buffer;

  AudioParam get detune => JS("AudioParam", "#.detune", this);

  bool get loop => JS("bool", "#.loop", this);

  set loop(bool value) {
    JS("void", "#.loop = #", this, value);
  }

  num get loopEnd => JS("num", "#.loopEnd", this);

  set loopEnd(num value) {
    JS("void", "#.loopEnd = #", this, value);
  }

  num get loopStart => JS("num", "#.loopStart", this);

  set loopStart(num value) {
    JS("void", "#.loopStart = #", this, value);
  }

  AudioParam get playbackRate => JS("AudioParam", "#.playbackRate", this);

  void start([num? when, num? grainOffset, num? grainDuration]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@Native("AudioContext,webkitAudioContext")
class AudioContext extends BaseAudioContext {
  // To suppress missing implicit constructor warnings.
  factory AudioContext._() {
    throw new UnsupportedError("Not supported");
  }

  /// Checks if this type is supported on the current platform.
  static bool get supported =>
      JS('bool', '!!(window.AudioContext || window.webkitAudioContext)');

  num get baseLatency => JS("num", "#.baseLatency", this);

  Future close() => promiseToFuture(JS("", "#.close()", this));

  Map getOutputTimestamp() {
    return convertNativeToDart_Dictionary(_getOutputTimestamp_1());
  }

  @JSName('getOutputTimestamp')
  _getOutputTimestamp_1() native;

  Future suspend() => promiseToFuture(JS("", "#.suspend()", this));

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
      [int? bufferSize,
      int? numberOfInputChannels,
      int? numberOfOutputChannels]) {
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
  Future<AudioBuffer> _decodeAudioData(ByteBuffer audioData,
      [DecodeSuccessCallback? successCallback,
      DecodeErrorCallback? errorCallback]) native;

  Future<AudioBuffer> decodeAudioData(ByteBuffer audioData,
      [DecodeSuccessCallback? successCallback,
      DecodeErrorCallback? errorCallback]) {
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

@Native("AudioDestinationNode")
class AudioDestinationNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory AudioDestinationNode._() {
    throw new UnsupportedError("Not supported");
  }

  int get maxChannelCount => JS("int", "#.maxChannelCount", this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("AudioListener")
class AudioListener extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory AudioListener._() {
    throw new UnsupportedError("Not supported");
  }

  AudioParam get forwardX => JS("AudioParam", "#.forwardX", this);

  AudioParam get forwardY => JS("AudioParam", "#.forwardY", this);

  AudioParam get forwardZ => JS("AudioParam", "#.forwardZ", this);

  AudioParam get positionX => JS("AudioParam", "#.positionX", this);

  AudioParam get positionY => JS("AudioParam", "#.positionY", this);

  AudioParam get positionZ => JS("AudioParam", "#.positionZ", this);

  AudioParam get upX => JS("AudioParam", "#.upX", this);

  AudioParam get upY => JS("AudioParam", "#.upY", this);

  AudioParam get upZ => JS("AudioParam", "#.upZ", this);

  void setOrientation(num x, num y, num z, num xUp, num yUp, num zUp) native;

  void setPosition(num x, num y, num z) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("AudioNode")
class AudioNode extends EventTarget {
  // To suppress missing implicit constructor warnings.
  factory AudioNode._() {
    throw new UnsupportedError("Not supported");
  }

  int get channelCount => JS("int", "#.channelCount", this);

  set channelCount(int value) {
    JS("void", "#.channelCount = #", this, value);
  }

  String get channelCountMode => JS("String", "#.channelCountMode", this);

  set channelCountMode(String value) {
    JS("void", "#.channelCountMode = #", this, value);
  }

  String get channelInterpretation =>
      JS("String", "#.channelInterpretation", this);

  set channelInterpretation(String value) {
    JS("void", "#.channelInterpretation = #", this, value);
  }

  BaseAudioContext get context => JS("BaseAudioContext", "#.context", this);

  int get numberOfInputs => JS("int", "#.numberOfInputs", this);

  int get numberOfOutputs => JS("int", "#.numberOfOutputs", this);

  @JSName('connect')
  AudioNode _connect(destination, [int? output, int? input]) native;

  void disconnect([destination_OR_output, int? output, int? input]) native;

  void connectNode(AudioNode destination, [int output = 0, int input = 0]) {
    _connect(destination, output, input);
  }

  void connectParam(AudioParam destination, [int output = 0]) {
    _connect(destination, output);
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("AudioParam")
class AudioParam extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory AudioParam._() {
    throw new UnsupportedError("Not supported");
  }

  num get defaultValue => JS("num", "#.defaultValue", this);

  num get maxValue => JS("num", "#.maxValue", this);

  num get minValue => JS("num", "#.minValue", this);

  num get value => JS("num", "#.value", this);

  set value(num value) {
    JS("void", "#.value = #", this, value);
  }

  AudioParam cancelAndHoldAtTime(num startTime) native;

  AudioParam cancelScheduledValues(num startTime) native;

  AudioParam exponentialRampToValueAtTime(num value, num time) native;

  AudioParam linearRampToValueAtTime(num value, num time) native;

  AudioParam setTargetAtTime(num target, num time, num timeConstant) native;

  AudioParam setValueAtTime(num value, num time) native;

  AudioParam setValueCurveAtTime(List<num> values, num time, num duration)
      native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("AudioParamMap")
class AudioParamMap extends Interceptor with MapMixin<String, dynamic> {
  // To suppress missing implicit constructor warnings.
  factory AudioParamMap._() {
    throw new UnsupportedError("Not supported");
  }

  Map _getItem(String key) =>
      convertNativeToDart_Dictionary(JS('', '#.get(#)', this, key));

  void addAll(Map<String, dynamic> other) {
    throw new UnsupportedError("Not supported");
  }

  bool containsValue(dynamic value) => values.any((e) => e == value);

  bool containsKey(dynamic key) => _getItem(key) != null;

  Map operator [](dynamic key) => _getItem(key);

  void forEach(void f(String key, dynamic value)) {
    var entries = JS('', '#.entries()', this);
    while (true) {
      var entry = JS('', '#.next()', entries);
      if (JS('bool', '#.done', entry)) return;
      f(JS('String', '#.value[0]', entry),
          convertNativeToDart_Dictionary(JS('', '#.value[1]', entry)));
    }
  }

  Iterable<String> get keys {
    final keys = <String>[];
    forEach((k, v) => keys.add(k));
    return keys;
  }

  Iterable<Map> get values {
    final values = <Map>[];
    forEach((k, v) => values.add(v));
    return values;
  }

  int get length => JS('int', '#.size', this);

  bool get isEmpty => length == 0;

  bool get isNotEmpty => !isEmpty;

  void operator []=(String key, dynamic value) {
    throw new UnsupportedError("Not supported");
  }

  dynamic putIfAbsent(String key, dynamic ifAbsent()) {
    throw new UnsupportedError("Not supported");
  }

  String remove(dynamic key) {
    throw new UnsupportedError("Not supported");
  }

  void clear() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("AudioProcessingEvent")
class AudioProcessingEvent extends Event {
  // To suppress missing implicit constructor warnings.
  factory AudioProcessingEvent._() {
    throw new UnsupportedError("Not supported");
  }

  factory AudioProcessingEvent(String type, Map eventInitDict) {
    var eventInitDict_1 = convertDartToNative_Dictionary(eventInitDict);
    return AudioProcessingEvent._create_1(type, eventInitDict_1);
  }
  static AudioProcessingEvent _create_1(type, eventInitDict) => JS(
      'AudioProcessingEvent',
      'new AudioProcessingEvent(#,#)',
      type,
      eventInitDict);

  AudioBuffer get inputBuffer => JS("AudioBuffer", "#.inputBuffer", this);

  AudioBuffer get outputBuffer => JS("AudioBuffer", "#.outputBuffer", this);

  num get playbackTime => JS("num", "#.playbackTime", this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("AudioScheduledSourceNode")
class AudioScheduledSourceNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory AudioScheduledSourceNode._() {
    throw new UnsupportedError("Not supported");
  }

  static const EventStreamProvider<Event> endedEvent =
      const EventStreamProvider<Event>('ended');

  @JSName('start')
  void start2([num? when]) native;

  void stop([num? when]) native;

  Stream<Event> get onEnded => endedEvent.forTarget(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("AudioTrack")
class AudioTrack extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory AudioTrack._() {
    throw new UnsupportedError("Not supported");
  }

  bool get enabled => JS("bool", "#.enabled", this);

  set enabled(bool value) {
    JS("void", "#.enabled = #", this, value);
  }

  String get id => JS("String", "#.id", this);

  String get kind => JS("String", "#.kind", this);

  String get label => JS("String", "#.label", this);

  String get language => JS("String", "#.language", this);

  final SourceBuffer? sourceBuffer;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("AudioTrackList")
class AudioTrackList extends EventTarget {
  // To suppress missing implicit constructor warnings.
  factory AudioTrackList._() {
    throw new UnsupportedError("Not supported");
  }

  static const EventStreamProvider<Event> changeEvent =
      const EventStreamProvider<Event>('change');

  int get length => JS("int", "#.length", this);

  AudioTrack __getter__(int index) native;

  AudioTrack getTrackById(String id) native;

  Stream<Event> get onChange => changeEvent.forTarget(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("AudioWorkletGlobalScope")
class AudioWorkletGlobalScope extends WorkletGlobalScope {
  // To suppress missing implicit constructor warnings.
  factory AudioWorkletGlobalScope._() {
    throw new UnsupportedError("Not supported");
  }

  num get currentTime => JS("num", "#.currentTime", this);

  num get sampleRate => JS("num", "#.sampleRate", this);

  void registerProcessor(String name, Object processorConstructor) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("AudioWorkletNode")
class AudioWorkletNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory AudioWorkletNode._() {
    throw new UnsupportedError("Not supported");
  }

  factory AudioWorkletNode(BaseAudioContext context, String name,
      [Map? options]) {
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

  AudioParamMap get parameters => JS("AudioParamMap", "#.parameters", this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

@Native("BaseAudioContext")
class BaseAudioContext extends EventTarget {
  // To suppress missing implicit constructor warnings.
  factory BaseAudioContext._() {
    throw new UnsupportedError("Not supported");
  }

  num get currentTime => JS("num", "#.currentTime", this);

  AudioDestinationNode get destination =>
      JS("AudioDestinationNode", "#.destination", this);

  AudioListener get listener => JS("AudioListener", "#.listener", this);

  num get sampleRate => JS("num", "#.sampleRate", this);

  String get state => JS("String", "#.state", this);

  AnalyserNode createAnalyser() native;

  BiquadFilterNode createBiquadFilter() native;

  AudioBuffer createBuffer(
      int numberOfChannels, int numberOfFrames, num sampleRate) native;

  AudioBufferSourceNode createBufferSource() native;

  ChannelMergerNode createChannelMerger([int? numberOfInputs]) native;

  ChannelSplitterNode createChannelSplitter([int? numberOfOutputs]) native;

  ConstantSourceNode createConstantSource() native;

  ConvolverNode createConvolver() native;

  DelayNode createDelay([num? maxDelayTime]) native;

  DynamicsCompressorNode createDynamicsCompressor() native;

  GainNode createGain() native;

  @JSName('createIIRFilter')
  IirFilterNode createIirFilter(List<num> feedForward, List<num> feedBack)
      native;

  MediaElementAudioSourceNode createMediaElementSource(
      MediaElement mediaElement) native;

  MediaStreamAudioDestinationNode createMediaStreamDestination() native;

  MediaStreamAudioSourceNode createMediaStreamSource(MediaStream mediaStream)
      native;

  OscillatorNode createOscillator() native;

  PannerNode createPanner() native;

  PeriodicWave createPeriodicWave(List<num> real, List<num> imag,
      [Map? options]) {
    if (options != null) {
      var options_1 = convertDartToNative_Dictionary(options);
      return _createPeriodicWave_1(real, imag, options_1);
    }
    return _createPeriodicWave_2(real, imag);
  }

  @JSName('createPeriodicWave')
  PeriodicWave _createPeriodicWave_1(List<num> real, List<num> imag, options)
      native;
  @JSName('createPeriodicWave')
  PeriodicWave _createPeriodicWave_2(List<num> real, List<num> imag) native;

  ScriptProcessorNode createScriptProcessor(
      [int? bufferSize,
      int? numberOfInputChannels,
      int? numberOfOutputChannels]) native;

  StereoPannerNode createStereoPanner() native;

  WaveShaperNode createWaveShaper() native;

  Future<AudioBuffer> decodeAudioData(ByteBuffer audioData,
          [DecodeSuccessCallback? successCallback,
          DecodeErrorCallback? errorCallback]) =>
      promiseToFuture<AudioBuffer>(JS("", "#.decodeAudioData(#, #, #)", this,
          audioData, successCallback, errorCallback));

  Future resume() => promiseToFuture(JS("", "#.resume()", this));
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("BiquadFilterNode")
class BiquadFilterNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory BiquadFilterNode._() {
    throw new UnsupportedError("Not supported");
  }

  factory BiquadFilterNode(BaseAudioContext context, [Map? options]) {
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

  AudioParam get Q => JS("AudioParam", "#.Q", this);

  AudioParam get detune => JS("AudioParam", "#.detune", this);

  AudioParam get frequency => JS("AudioParam", "#.frequency", this);

  AudioParam get gain => JS("AudioParam", "#.gain", this);

  String get type => JS("String", "#.type", this);

  set type(String value) {
    JS("void", "#.type = #", this, value);
  }

  void getFrequencyResponse(Float32List frequencyHz, Float32List magResponse,
      Float32List phaseResponse) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("ChannelMergerNode,AudioChannelMerger")
class ChannelMergerNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory ChannelMergerNode._() {
    throw new UnsupportedError("Not supported");
  }

  factory ChannelMergerNode(BaseAudioContext context, [Map? options]) {
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

@Native("ChannelSplitterNode,AudioChannelSplitter")
class ChannelSplitterNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory ChannelSplitterNode._() {
    throw new UnsupportedError("Not supported");
  }

  factory ChannelSplitterNode(BaseAudioContext context, [Map? options]) {
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

@Native("ConstantSourceNode")
class ConstantSourceNode extends AudioScheduledSourceNode {
  // To suppress missing implicit constructor warnings.
  factory ConstantSourceNode._() {
    throw new UnsupportedError("Not supported");
  }

  factory ConstantSourceNode(BaseAudioContext context, [Map? options]) {
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

  AudioParam get offset => JS("AudioParam", "#.offset", this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("ConvolverNode")
class ConvolverNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory ConvolverNode._() {
    throw new UnsupportedError("Not supported");
  }

  factory ConvolverNode(BaseAudioContext context, [Map? options]) {
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

  AudioBuffer? buffer;

  bool get normalize => JS("bool", "#.normalize", this);

  set normalize(bool value) {
    JS("void", "#.normalize = #", this, value);
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("DelayNode")
class DelayNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory DelayNode._() {
    throw new UnsupportedError("Not supported");
  }

  factory DelayNode(BaseAudioContext context, [Map? options]) {
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

  AudioParam get delayTime => JS("AudioParam", "#.delayTime", this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("DynamicsCompressorNode")
class DynamicsCompressorNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory DynamicsCompressorNode._() {
    throw new UnsupportedError("Not supported");
  }

  factory DynamicsCompressorNode(BaseAudioContext context, [Map? options]) {
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

  AudioParam get attack => JS("AudioParam", "#.attack", this);

  AudioParam get knee => JS("AudioParam", "#.knee", this);

  AudioParam get ratio => JS("AudioParam", "#.ratio", this);

  num get reduction => JS("num", "#.reduction", this);

  AudioParam get release => JS("AudioParam", "#.release", this);

  AudioParam get threshold => JS("AudioParam", "#.threshold", this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("GainNode,AudioGainNode")
class GainNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory GainNode._() {
    throw new UnsupportedError("Not supported");
  }

  factory GainNode(BaseAudioContext context, [Map? options]) {
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

  AudioParam get gain => JS("AudioParam", "#.gain", this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("IIRFilterNode")
class IirFilterNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory IirFilterNode._() {
    throw new UnsupportedError("Not supported");
  }

  factory IirFilterNode(BaseAudioContext context, Map options) {
    var options_1 = convertDartToNative_Dictionary(options);
    return IirFilterNode._create_1(context, options_1);
  }
  static IirFilterNode _create_1(context, options) =>
      JS('IirFilterNode', 'new IIRFilterNode(#,#)', context, options);

  void getFrequencyResponse(Float32List frequencyHz, Float32List magResponse,
      Float32List phaseResponse) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("MediaElementAudioSourceNode")
class MediaElementAudioSourceNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory MediaElementAudioSourceNode._() {
    throw new UnsupportedError("Not supported");
  }

  factory MediaElementAudioSourceNode(BaseAudioContext context, Map options) {
    var options_1 = convertDartToNative_Dictionary(options);
    return MediaElementAudioSourceNode._create_1(context, options_1);
  }
  static MediaElementAudioSourceNode _create_1(context, options) => JS(
      'MediaElementAudioSourceNode',
      'new MediaElementAudioSourceNode(#,#)',
      context,
      options);

  MediaElement get mediaElement => JS("MediaElement", "#.mediaElement", this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("MediaStreamAudioDestinationNode")
class MediaStreamAudioDestinationNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory MediaStreamAudioDestinationNode._() {
    throw new UnsupportedError("Not supported");
  }

  factory MediaStreamAudioDestinationNode(BaseAudioContext context,
      [Map? options]) {
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

  MediaStream get stream => JS("MediaStream", "#.stream", this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("MediaStreamAudioSourceNode")
class MediaStreamAudioSourceNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory MediaStreamAudioSourceNode._() {
    throw new UnsupportedError("Not supported");
  }

  factory MediaStreamAudioSourceNode(BaseAudioContext context, Map options) {
    var options_1 = convertDartToNative_Dictionary(options);
    return MediaStreamAudioSourceNode._create_1(context, options_1);
  }
  static MediaStreamAudioSourceNode _create_1(context, options) => JS(
      'MediaStreamAudioSourceNode',
      'new MediaStreamAudioSourceNode(#,#)',
      context,
      options);

  MediaStream get mediaStream => JS("MediaStream", "#.mediaStream", this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("OfflineAudioCompletionEvent")
class OfflineAudioCompletionEvent extends Event {
  // To suppress missing implicit constructor warnings.
  factory OfflineAudioCompletionEvent._() {
    throw new UnsupportedError("Not supported");
  }

  factory OfflineAudioCompletionEvent(String type, Map eventInitDict) {
    var eventInitDict_1 = convertDartToNative_Dictionary(eventInitDict);
    return OfflineAudioCompletionEvent._create_1(type, eventInitDict_1);
  }
  static OfflineAudioCompletionEvent _create_1(type, eventInitDict) => JS(
      'OfflineAudioCompletionEvent',
      'new OfflineAudioCompletionEvent(#,#)',
      type,
      eventInitDict);

  AudioBuffer get renderedBuffer => JS("AudioBuffer", "#.renderedBuffer", this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("OfflineAudioContext")
class OfflineAudioContext extends BaseAudioContext {
  // To suppress missing implicit constructor warnings.
  factory OfflineAudioContext._() {
    throw new UnsupportedError("Not supported");
  }

  factory OfflineAudioContext(numberOfChannels_OR_options,
      [int? numberOfFrames, num? sampleRate]) {
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

  int get length => JS("int", "#.length", this);

  Future<AudioBuffer> startRendering() =>
      promiseToFuture<AudioBuffer>(JS("", "#.startRendering()", this));

  @JSName('suspend')
  Future suspendFor(num suspendTime) =>
      promiseToFuture(JS("", "#.suspendFor(#)", this, suspendTime));
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("OscillatorNode,Oscillator")
class OscillatorNode extends AudioScheduledSourceNode {
  // To suppress missing implicit constructor warnings.
  factory OscillatorNode._() {
    throw new UnsupportedError("Not supported");
  }

  factory OscillatorNode(BaseAudioContext context, [Map? options]) {
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

  AudioParam get detune => JS("AudioParam", "#.detune", this);

  AudioParam get frequency => JS("AudioParam", "#.frequency", this);

  String get type => JS("String", "#.type", this);

  set type(String value) {
    JS("void", "#.type = #", this, value);
  }

  void setPeriodicWave(PeriodicWave periodicWave) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("PannerNode,AudioPannerNode,webkitAudioPannerNode")
class PannerNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory PannerNode._() {
    throw new UnsupportedError("Not supported");
  }

  factory PannerNode(BaseAudioContext context, [Map? options]) {
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

  num get coneInnerAngle => JS("num", "#.coneInnerAngle", this);

  set coneInnerAngle(num value) {
    JS("void", "#.coneInnerAngle = #", this, value);
  }

  num get coneOuterAngle => JS("num", "#.coneOuterAngle", this);

  set coneOuterAngle(num value) {
    JS("void", "#.coneOuterAngle = #", this, value);
  }

  num get coneOuterGain => JS("num", "#.coneOuterGain", this);

  set coneOuterGain(num value) {
    JS("void", "#.coneOuterGain = #", this, value);
  }

  String get distanceModel => JS("String", "#.distanceModel", this);

  set distanceModel(String value) {
    JS("void", "#.distanceModel = #", this, value);
  }

  num get maxDistance => JS("num", "#.maxDistance", this);

  set maxDistance(num value) {
    JS("void", "#.maxDistance = #", this, value);
  }

  AudioParam get orientationX => JS("AudioParam", "#.orientationX", this);

  AudioParam get orientationY => JS("AudioParam", "#.orientationY", this);

  AudioParam get orientationZ => JS("AudioParam", "#.orientationZ", this);

  String get panningModel => JS("String", "#.panningModel", this);

  set panningModel(String value) {
    JS("void", "#.panningModel = #", this, value);
  }

  AudioParam get positionX => JS("AudioParam", "#.positionX", this);

  AudioParam get positionY => JS("AudioParam", "#.positionY", this);

  AudioParam get positionZ => JS("AudioParam", "#.positionZ", this);

  num get refDistance => JS("num", "#.refDistance", this);

  set refDistance(num value) {
    JS("void", "#.refDistance = #", this, value);
  }

  num get rolloffFactor => JS("num", "#.rolloffFactor", this);

  set rolloffFactor(num value) {
    JS("void", "#.rolloffFactor = #", this, value);
  }

  void setOrientation(num x, num y, num z) native;

  void setPosition(num x, num y, num z) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("PeriodicWave")
class PeriodicWave extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory PeriodicWave._() {
    throw new UnsupportedError("Not supported");
  }

  factory PeriodicWave(BaseAudioContext context, [Map? options]) {
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
  static const EventStreamProvider<AudioProcessingEvent> audioProcessEvent =
      const EventStreamProvider<AudioProcessingEvent>('audioprocess');

  int get bufferSize => JS("int", "#.bufferSize", this);

  void setEventListener(EventListener eventListener) native;

  /// Stream of `audioprocess` events handled by this [ScriptProcessorNode].
/**
   * Get a Stream that fires events when AudioProcessingEvents occur.
   * This particular stream is special in that it only allows one listener to a
   * given stream. Converting the returned Stream [asBroadcast] will likely ruin
   * the soft-real-time properties which which these events are fired and can
   * be processed.
   */
  Stream<AudioProcessingEvent> get onAudioProcess =>
      audioProcessEvent.forTarget(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("StereoPannerNode")
class StereoPannerNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory StereoPannerNode._() {
    throw new UnsupportedError("Not supported");
  }

  factory StereoPannerNode(BaseAudioContext context, [Map? options]) {
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

  AudioParam get pan => JS("AudioParam", "#.pan", this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("WaveShaperNode")
class WaveShaperNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory WaveShaperNode._() {
    throw new UnsupportedError("Not supported");
  }

  factory WaveShaperNode(BaseAudioContext context, [Map? options]) {
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

  Float32List? curve;

  String get oversample => JS("String", "#.oversample", this);

  set oversample(String value) {
    JS("void", "#.oversample = #", this, value);
  }
}
