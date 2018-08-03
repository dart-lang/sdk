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

  int fftSize;

  final int frequencyBinCount;

  num maxDecibels;

  num minDecibels;

  num smoothingTimeConstant;

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

  final num duration;

  final int length;

  final int numberOfChannels;

  final num sampleRate;

  void copyFromChannel(Float32List destination, int channelNumber,
      [int startInChannel]) native;

  void copyToChannel(Float32List source, int channelNumber,
      [int startInChannel]) native;

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

  AudioBuffer buffer;

  final AudioParam detune;

  bool loop;

  num loopEnd;

  num loopStart;

  final AudioParam playbackRate;

  void start([num when, num grainOffset, num grainDuration]) native;
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

  final num baseLatency;

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
  Future _decodeAudioData(ByteBuffer audioData,
      [DecodeSuccessCallback successCallback,
      DecodeErrorCallback errorCallback]) native;

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

@Native("AudioDestinationNode")
class AudioDestinationNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory AudioDestinationNode._() {
    throw new UnsupportedError("Not supported");
  }

  final int maxChannelCount;
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

  final AudioParam forwardX;

  final AudioParam forwardY;

  final AudioParam forwardZ;

  final AudioParam positionX;

  final AudioParam positionY;

  final AudioParam positionZ;

  final AudioParam upX;

  final AudioParam upY;

  final AudioParam upZ;

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

  int channelCount;

  String channelCountMode;

  String channelInterpretation;

  final BaseAudioContext context;

  final int numberOfInputs;

  final int numberOfOutputs;

  @JSName('connect')
  AudioNode _connect(destination, [int output, int input]) native;

  void disconnect([destination_OR_output, int output, int input]) native;

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

  final num defaultValue;

  final num maxValue;

  final num minValue;

  num value;

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

  final AudioBuffer inputBuffer;

  final AudioBuffer outputBuffer;

  final num playbackTime;
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
  void start2([num when]) native;

  void stop([num when]) native;

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

  bool enabled;

  final String id;

  final String kind;

  final String label;

  final String language;

  final SourceBuffer sourceBuffer;
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

  final int length;

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

  final num currentTime;

  final num sampleRate;

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

  final AudioParamMap parameters;
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

  final num currentTime;

  final AudioDestinationNode destination;

  final AudioListener listener;

  final num sampleRate;

  final String state;

  AnalyserNode createAnalyser() native;

  BiquadFilterNode createBiquadFilter() native;

  AudioBuffer createBuffer(
      int numberOfChannels, int numberOfFrames, num sampleRate) native;

  AudioBufferSourceNode createBufferSource() native;

  ChannelMergerNode createChannelMerger([int numberOfInputs]) native;

  ChannelSplitterNode createChannelSplitter([int numberOfOutputs]) native;

  ConstantSourceNode createConstantSource() native;

  ConvolverNode createConvolver() native;

  DelayNode createDelay([num maxDelayTime]) native;

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
      [Map options]) {
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
      [int bufferSize,
      int numberOfInputChannels,
      int numberOfOutputChannels]) native;

  StereoPannerNode createStereoPanner() native;

  WaveShaperNode createWaveShaper() native;

  Future<AudioBuffer> decodeAudioData(ByteBuffer audioData,
          [DecodeSuccessCallback successCallback,
          DecodeErrorCallback errorCallback]) =>
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

  final AudioParam Q;

  final AudioParam detune;

  final AudioParam frequency;

  final AudioParam gain;

  String type;

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

@Native("ChannelSplitterNode,AudioChannelSplitter")
class ChannelSplitterNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory ChannelSplitterNode._() {
    throw new UnsupportedError("Not supported");
  }

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

@Native("ConstantSourceNode")
class ConstantSourceNode extends AudioScheduledSourceNode {
  // To suppress missing implicit constructor warnings.
  factory ConstantSourceNode._() {
    throw new UnsupportedError("Not supported");
  }

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

  final AudioParam offset;
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

  AudioBuffer buffer;

  bool normalize;
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

  final AudioParam delayTime;
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

  final AudioParam attack;

  final AudioParam knee;

  final AudioParam ratio;

  final num reduction;

  final AudioParam release;

  final AudioParam threshold;
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

  final AudioParam gain;
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

  final MediaElement mediaElement;
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

  final MediaStream stream;
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

  final MediaStream mediaStream;
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

  final AudioBuffer renderedBuffer;
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

  final int length;

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

  final AudioParam detune;

  final AudioParam frequency;

  String type;

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

  num coneInnerAngle;

  num coneOuterAngle;

  num coneOuterGain;

  String distanceModel;

  num maxDistance;

  final AudioParam orientationX;

  final AudioParam orientationY;

  final AudioParam orientationZ;

  String panningModel;

  final AudioParam positionX;

  final AudioParam positionY;

  final AudioParam positionZ;

  num refDistance;

  num rolloffFactor;

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

  final int bufferSize;

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

  final AudioParam pan;
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

  Float32List curve;

  String oversample;
}
