library html;

import 'dart:isolate';
import 'dart:json';
import 'dart:nativewrappers';
import 'dart:svg' as svg;
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// DO NOT EDIT
// Auto-generated dart:html library.







LocalWindow _window;

LocalWindow get window {
  if (_window != null) {
    return _window;
  }
  _window = _Utils.window();
  return _window;
}

HtmlDocument _document;

HtmlDocument get document {
  if (_document != null) {
    return _document;
  }
  _document = window.document;
  return _document;
}


Element query(String selector) => document.query(selector);
List<Element> queryAll(String selector) => document.queryAll(selector);

int _getNewIsolateId() => _Utils._getNewIsolateId();

bool _callPortInitialized = false;
var _callPortLastResult = null;

_callPortSync(num id, var message) {
  if (!_callPortInitialized) {
    window.on['js-result'].add((event) {
      _callPortLastResult = JSON.parse(_getPortSyncEventData(event));
    }, false);
    _callPortInitialized = true;
  }
  assert(_callPortLastResult == null);
  _dispatchEvent('js-sync-message', {'id': id, 'message': message});
  var result = _callPortLastResult;
  _callPortLastResult = null;
  return result;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName AbstractWorker
class AbstractWorker extends EventTarget {
  AbstractWorker.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  AbstractWorkerEvents get on =>
    new AbstractWorkerEvents(this);


  /** @domName AbstractWorker.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "AbstractWorker_addEventListener_Callback";


  /** @domName AbstractWorker.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "AbstractWorker_dispatchEvent_Callback";


  /** @domName AbstractWorker.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "AbstractWorker_removeEventListener_Callback";

}

class AbstractWorkerEvents extends Events {
  AbstractWorkerEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get error => this['error'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName AnalyserNode
class AnalyserNode extends AudioNode {
  AnalyserNode.internal(): super.internal();


  /** @domName AnalyserNode.fftSize */
  int get fftSize native "AnalyserNode_fftSize_Getter";


  /** @domName AnalyserNode.fftSize */
  void set fftSize(int value) native "AnalyserNode_fftSize_Setter";


  /** @domName AnalyserNode.frequencyBinCount */
  int get frequencyBinCount native "AnalyserNode_frequencyBinCount_Getter";


  /** @domName AnalyserNode.maxDecibels */
  num get maxDecibels native "AnalyserNode_maxDecibels_Getter";


  /** @domName AnalyserNode.maxDecibels */
  void set maxDecibels(num value) native "AnalyserNode_maxDecibels_Setter";


  /** @domName AnalyserNode.minDecibels */
  num get minDecibels native "AnalyserNode_minDecibels_Getter";


  /** @domName AnalyserNode.minDecibels */
  void set minDecibels(num value) native "AnalyserNode_minDecibels_Setter";


  /** @domName AnalyserNode.smoothingTimeConstant */
  num get smoothingTimeConstant native "AnalyserNode_smoothingTimeConstant_Getter";


  /** @domName AnalyserNode.smoothingTimeConstant */
  void set smoothingTimeConstant(num value) native "AnalyserNode_smoothingTimeConstant_Setter";


  /** @domName AnalyserNode.getByteFrequencyData */
  void getByteFrequencyData(Uint8Array array) native "AnalyserNode_getByteFrequencyData_Callback";


  /** @domName AnalyserNode.getByteTimeDomainData */
  void getByteTimeDomainData(Uint8Array array) native "AnalyserNode_getByteTimeDomainData_Callback";


  /** @domName AnalyserNode.getFloatFrequencyData */
  void getFloatFrequencyData(Float32Array array) native "AnalyserNode_getFloatFrequencyData_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLAnchorElement
class AnchorElement extends _Element_Merged {

  factory AnchorElement({String href}) {
    var e = document.$dom_createElement("a");
    if (href != null) e.href = href;
    return e;
  }
  AnchorElement.internal(): super.internal();


  /** @domName HTMLAnchorElement.charset */
  String get charset native "HTMLAnchorElement_charset_Getter";


  /** @domName HTMLAnchorElement.charset */
  void set charset(String value) native "HTMLAnchorElement_charset_Setter";


  /** @domName HTMLAnchorElement.coords */
  String get coords native "HTMLAnchorElement_coords_Getter";


  /** @domName HTMLAnchorElement.coords */
  void set coords(String value) native "HTMLAnchorElement_coords_Setter";


  /** @domName HTMLAnchorElement.download */
  String get download native "HTMLAnchorElement_download_Getter";


  /** @domName HTMLAnchorElement.download */
  void set download(String value) native "HTMLAnchorElement_download_Setter";


  /** @domName HTMLAnchorElement.hash */
  String get hash native "HTMLAnchorElement_hash_Getter";


  /** @domName HTMLAnchorElement.hash */
  void set hash(String value) native "HTMLAnchorElement_hash_Setter";


  /** @domName HTMLAnchorElement.host */
  String get host native "HTMLAnchorElement_host_Getter";


  /** @domName HTMLAnchorElement.host */
  void set host(String value) native "HTMLAnchorElement_host_Setter";


  /** @domName HTMLAnchorElement.hostname */
  String get hostname native "HTMLAnchorElement_hostname_Getter";


  /** @domName HTMLAnchorElement.hostname */
  void set hostname(String value) native "HTMLAnchorElement_hostname_Setter";


  /** @domName HTMLAnchorElement.href */
  String get href native "HTMLAnchorElement_href_Getter";


  /** @domName HTMLAnchorElement.href */
  void set href(String value) native "HTMLAnchorElement_href_Setter";


  /** @domName HTMLAnchorElement.hreflang */
  String get hreflang native "HTMLAnchorElement_hreflang_Getter";


  /** @domName HTMLAnchorElement.hreflang */
  void set hreflang(String value) native "HTMLAnchorElement_hreflang_Setter";


  /** @domName HTMLAnchorElement.name */
  String get name native "HTMLAnchorElement_name_Getter";


  /** @domName HTMLAnchorElement.name */
  void set name(String value) native "HTMLAnchorElement_name_Setter";


  /** @domName HTMLAnchorElement.origin */
  String get origin native "HTMLAnchorElement_origin_Getter";


  /** @domName HTMLAnchorElement.pathname */
  String get pathname native "HTMLAnchorElement_pathname_Getter";


  /** @domName HTMLAnchorElement.pathname */
  void set pathname(String value) native "HTMLAnchorElement_pathname_Setter";


  /** @domName HTMLAnchorElement.ping */
  String get ping native "HTMLAnchorElement_ping_Getter";


  /** @domName HTMLAnchorElement.ping */
  void set ping(String value) native "HTMLAnchorElement_ping_Setter";


  /** @domName HTMLAnchorElement.port */
  String get port native "HTMLAnchorElement_port_Getter";


  /** @domName HTMLAnchorElement.port */
  void set port(String value) native "HTMLAnchorElement_port_Setter";


  /** @domName HTMLAnchorElement.protocol */
  String get protocol native "HTMLAnchorElement_protocol_Getter";


  /** @domName HTMLAnchorElement.protocol */
  void set protocol(String value) native "HTMLAnchorElement_protocol_Setter";


  /** @domName HTMLAnchorElement.rel */
  String get rel native "HTMLAnchorElement_rel_Getter";


  /** @domName HTMLAnchorElement.rel */
  void set rel(String value) native "HTMLAnchorElement_rel_Setter";


  /** @domName HTMLAnchorElement.rev */
  String get rev native "HTMLAnchorElement_rev_Getter";


  /** @domName HTMLAnchorElement.rev */
  void set rev(String value) native "HTMLAnchorElement_rev_Setter";


  /** @domName HTMLAnchorElement.search */
  String get search native "HTMLAnchorElement_search_Getter";


  /** @domName HTMLAnchorElement.search */
  void set search(String value) native "HTMLAnchorElement_search_Setter";


  /** @domName HTMLAnchorElement.shape */
  String get shape native "HTMLAnchorElement_shape_Getter";


  /** @domName HTMLAnchorElement.shape */
  void set shape(String value) native "HTMLAnchorElement_shape_Setter";


  /** @domName HTMLAnchorElement.target */
  String get target native "HTMLAnchorElement_target_Getter";


  /** @domName HTMLAnchorElement.target */
  void set target(String value) native "HTMLAnchorElement_target_Setter";


  /** @domName HTMLAnchorElement.type */
  String get type native "HTMLAnchorElement_type_Getter";


  /** @domName HTMLAnchorElement.type */
  void set type(String value) native "HTMLAnchorElement_type_Setter";


  /** @domName HTMLAnchorElement.toString */
  String toString() native "HTMLAnchorElement_toString_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WebKitAnimation
class Animation extends NativeFieldWrapperClass1 {
  Animation.internal();

  static const int DIRECTION_ALTERNATE = 1;

  static const int DIRECTION_NORMAL = 0;

  static const int FILL_BACKWARDS = 1;

  static const int FILL_BOTH = 3;

  static const int FILL_FORWARDS = 2;

  static const int FILL_NONE = 0;


  /** @domName WebKitAnimation.delay */
  num get delay native "WebKitAnimation_delay_Getter";


  /** @domName WebKitAnimation.direction */
  int get direction native "WebKitAnimation_direction_Getter";


  /** @domName WebKitAnimation.duration */
  num get duration native "WebKitAnimation_duration_Getter";


  /** @domName WebKitAnimation.elapsedTime */
  num get elapsedTime native "WebKitAnimation_elapsedTime_Getter";


  /** @domName WebKitAnimation.elapsedTime */
  void set elapsedTime(num value) native "WebKitAnimation_elapsedTime_Setter";


  /** @domName WebKitAnimation.ended */
  bool get ended native "WebKitAnimation_ended_Getter";


  /** @domName WebKitAnimation.fillMode */
  int get fillMode native "WebKitAnimation_fillMode_Getter";


  /** @domName WebKitAnimation.iterationCount */
  int get iterationCount native "WebKitAnimation_iterationCount_Getter";


  /** @domName WebKitAnimation.name */
  String get name native "WebKitAnimation_name_Getter";


  /** @domName WebKitAnimation.paused */
  bool get paused native "WebKitAnimation_paused_Getter";


  /** @domName WebKitAnimation.pause */
  void pause() native "WebKitAnimation_pause_Callback";


  /** @domName WebKitAnimation.play */
  void play() native "WebKitAnimation_play_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WebKitAnimationEvent
class AnimationEvent extends Event {
  AnimationEvent.internal(): super.internal();


  /** @domName WebKitAnimationEvent.animationName */
  String get animationName native "WebKitAnimationEvent_animationName_Getter";


  /** @domName WebKitAnimationEvent.elapsedTime */
  num get elapsedTime native "WebKitAnimationEvent_elapsedTime_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLAppletElement
class AppletElement extends _Element_Merged {
  AppletElement.internal(): super.internal();


  /** @domName HTMLAppletElement.align */
  String get align native "HTMLAppletElement_align_Getter";


  /** @domName HTMLAppletElement.align */
  void set align(String value) native "HTMLAppletElement_align_Setter";


  /** @domName HTMLAppletElement.alt */
  String get alt native "HTMLAppletElement_alt_Getter";


  /** @domName HTMLAppletElement.alt */
  void set alt(String value) native "HTMLAppletElement_alt_Setter";


  /** @domName HTMLAppletElement.archive */
  String get archive native "HTMLAppletElement_archive_Getter";


  /** @domName HTMLAppletElement.archive */
  void set archive(String value) native "HTMLAppletElement_archive_Setter";


  /** @domName HTMLAppletElement.code */
  String get code native "HTMLAppletElement_code_Getter";


  /** @domName HTMLAppletElement.code */
  void set code(String value) native "HTMLAppletElement_code_Setter";


  /** @domName HTMLAppletElement.codeBase */
  String get codeBase native "HTMLAppletElement_codeBase_Getter";


  /** @domName HTMLAppletElement.codeBase */
  void set codeBase(String value) native "HTMLAppletElement_codeBase_Setter";


  /** @domName HTMLAppletElement.height */
  String get height native "HTMLAppletElement_height_Getter";


  /** @domName HTMLAppletElement.height */
  void set height(String value) native "HTMLAppletElement_height_Setter";


  /** @domName HTMLAppletElement.hspace */
  String get hspace native "HTMLAppletElement_hspace_Getter";


  /** @domName HTMLAppletElement.hspace */
  void set hspace(String value) native "HTMLAppletElement_hspace_Setter";


  /** @domName HTMLAppletElement.name */
  String get name native "HTMLAppletElement_name_Getter";


  /** @domName HTMLAppletElement.name */
  void set name(String value) native "HTMLAppletElement_name_Setter";


  /** @domName HTMLAppletElement.object */
  String get object native "HTMLAppletElement_object_Getter";


  /** @domName HTMLAppletElement.object */
  void set object(String value) native "HTMLAppletElement_object_Setter";


  /** @domName HTMLAppletElement.vspace */
  String get vspace native "HTMLAppletElement_vspace_Getter";


  /** @domName HTMLAppletElement.vspace */
  void set vspace(String value) native "HTMLAppletElement_vspace_Setter";


  /** @domName HTMLAppletElement.width */
  String get width native "HTMLAppletElement_width_Getter";


  /** @domName HTMLAppletElement.width */
  void set width(String value) native "HTMLAppletElement_width_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLAreaElement
class AreaElement extends _Element_Merged {

  factory AreaElement() => document.$dom_createElement("area");
  AreaElement.internal(): super.internal();


  /** @domName HTMLAreaElement.alt */
  String get alt native "HTMLAreaElement_alt_Getter";


  /** @domName HTMLAreaElement.alt */
  void set alt(String value) native "HTMLAreaElement_alt_Setter";


  /** @domName HTMLAreaElement.coords */
  String get coords native "HTMLAreaElement_coords_Getter";


  /** @domName HTMLAreaElement.coords */
  void set coords(String value) native "HTMLAreaElement_coords_Setter";


  /** @domName HTMLAreaElement.hash */
  String get hash native "HTMLAreaElement_hash_Getter";


  /** @domName HTMLAreaElement.host */
  String get host native "HTMLAreaElement_host_Getter";


  /** @domName HTMLAreaElement.hostname */
  String get hostname native "HTMLAreaElement_hostname_Getter";


  /** @domName HTMLAreaElement.href */
  String get href native "HTMLAreaElement_href_Getter";


  /** @domName HTMLAreaElement.href */
  void set href(String value) native "HTMLAreaElement_href_Setter";


  /** @domName HTMLAreaElement.noHref */
  bool get noHref native "HTMLAreaElement_noHref_Getter";


  /** @domName HTMLAreaElement.noHref */
  void set noHref(bool value) native "HTMLAreaElement_noHref_Setter";


  /** @domName HTMLAreaElement.pathname */
  String get pathname native "HTMLAreaElement_pathname_Getter";


  /** @domName HTMLAreaElement.ping */
  String get ping native "HTMLAreaElement_ping_Getter";


  /** @domName HTMLAreaElement.ping */
  void set ping(String value) native "HTMLAreaElement_ping_Setter";


  /** @domName HTMLAreaElement.port */
  String get port native "HTMLAreaElement_port_Getter";


  /** @domName HTMLAreaElement.protocol */
  String get protocol native "HTMLAreaElement_protocol_Getter";


  /** @domName HTMLAreaElement.search */
  String get search native "HTMLAreaElement_search_Getter";


  /** @domName HTMLAreaElement.shape */
  String get shape native "HTMLAreaElement_shape_Getter";


  /** @domName HTMLAreaElement.shape */
  void set shape(String value) native "HTMLAreaElement_shape_Setter";


  /** @domName HTMLAreaElement.target */
  String get target native "HTMLAreaElement_target_Getter";


  /** @domName HTMLAreaElement.target */
  void set target(String value) native "HTMLAreaElement_target_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName ArrayBuffer
class ArrayBuffer extends NativeFieldWrapperClass1 {

  factory ArrayBuffer(int length) => _ArrayBufferFactoryProvider.createArrayBuffer(length);
  ArrayBuffer.internal();


  /** @domName ArrayBuffer.byteLength */
  int get byteLength native "ArrayBuffer_byteLength_Getter";

  ArrayBuffer slice(/*long*/ begin, [/*long*/ end]) {
    if (?end) {
      return _slice_1(begin, end);
    }
    return _slice_2(begin);
  }


  /** @domName ArrayBuffer.slice_1 */
  ArrayBuffer _slice_1(begin, end) native "ArrayBuffer_slice_1_Callback";


  /** @domName ArrayBuffer.slice_2 */
  ArrayBuffer _slice_2(begin) native "ArrayBuffer_slice_2_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName ArrayBufferView
class ArrayBufferView extends NativeFieldWrapperClass1 {
  ArrayBufferView.internal();


  /** @domName ArrayBufferView.buffer */
  ArrayBuffer get buffer native "ArrayBufferView_buffer_Getter";


  /** @domName ArrayBufferView.byteLength */
  int get byteLength native "ArrayBufferView_byteLength_Getter";


  /** @domName ArrayBufferView.byteOffset */
  int get byteOffset native "ArrayBufferView_byteOffset_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Attr
class Attr extends Node {
  Attr.internal(): super.internal();


  /** @domName Attr.isId */
  bool get isId native "Attr_isId_Getter";


  /** @domName Attr.name */
  String get name native "Attr_name_Getter";


  /** @domName Attr.ownerElement */
  Element get ownerElement native "Attr_ownerElement_Getter";


  /** @domName Attr.specified */
  bool get specified native "Attr_specified_Getter";


  /** @domName Attr.value */
  String get value native "Attr_value_Getter";


  /** @domName Attr.value */
  void set value(String value) native "Attr_value_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName AudioBuffer
class AudioBuffer extends NativeFieldWrapperClass1 {
  AudioBuffer.internal();


  /** @domName AudioBuffer.duration */
  num get duration native "AudioBuffer_duration_Getter";


  /** @domName AudioBuffer.gain */
  num get gain native "AudioBuffer_gain_Getter";


  /** @domName AudioBuffer.gain */
  void set gain(num value) native "AudioBuffer_gain_Setter";


  /** @domName AudioBuffer.length */
  int get length native "AudioBuffer_length_Getter";


  /** @domName AudioBuffer.numberOfChannels */
  int get numberOfChannels native "AudioBuffer_numberOfChannels_Getter";


  /** @domName AudioBuffer.sampleRate */
  num get sampleRate native "AudioBuffer_sampleRate_Getter";


  /** @domName AudioBuffer.getChannelData */
  Float32Array getChannelData(int channelIndex) native "AudioBuffer_getChannelData_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void AudioBufferCallback(AudioBuffer audioBuffer);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName AudioBufferSourceNode
class AudioBufferSourceNode extends AudioSourceNode {
  AudioBufferSourceNode.internal(): super.internal();

  static const int FINISHED_STATE = 3;

  static const int PLAYING_STATE = 2;

  static const int SCHEDULED_STATE = 1;

  static const int UNSCHEDULED_STATE = 0;


  /** @domName AudioBufferSourceNode.buffer */
  AudioBuffer get buffer native "AudioBufferSourceNode_buffer_Getter";


  /** @domName AudioBufferSourceNode.buffer */
  void set buffer(AudioBuffer value) native "AudioBufferSourceNode_buffer_Setter";


  /** @domName AudioBufferSourceNode.gain */
  AudioGain get gain native "AudioBufferSourceNode_gain_Getter";


  /** @domName AudioBufferSourceNode.loop */
  bool get loop native "AudioBufferSourceNode_loop_Getter";


  /** @domName AudioBufferSourceNode.loop */
  void set loop(bool value) native "AudioBufferSourceNode_loop_Setter";


  /** @domName AudioBufferSourceNode.loopEnd */
  num get loopEnd native "AudioBufferSourceNode_loopEnd_Getter";


  /** @domName AudioBufferSourceNode.loopEnd */
  void set loopEnd(num value) native "AudioBufferSourceNode_loopEnd_Setter";


  /** @domName AudioBufferSourceNode.loopStart */
  num get loopStart native "AudioBufferSourceNode_loopStart_Getter";


  /** @domName AudioBufferSourceNode.loopStart */
  void set loopStart(num value) native "AudioBufferSourceNode_loopStart_Setter";


  /** @domName AudioBufferSourceNode.playbackRate */
  AudioParam get playbackRate native "AudioBufferSourceNode_playbackRate_Getter";


  /** @domName AudioBufferSourceNode.playbackState */
  int get playbackState native "AudioBufferSourceNode_playbackState_Getter";

  void start(/*double*/ when, [/*double*/ grainOffset, /*double*/ grainDuration]) {
    if ((when is num || when == null) && !?grainOffset && !?grainDuration) {
      _start_1(when);
      return;
    }
    if ((when is num || when == null) && (grainOffset is num || grainOffset == null) && (grainDuration is num || grainDuration == null)) {
      _start_2(when, grainOffset, grainDuration);
      return;
    }
    throw "Incorrect number or type of arguments";
  }


  /** @domName AudioBufferSourceNode.start_1 */
  void _start_1(when) native "AudioBufferSourceNode_start_1_Callback";


  /** @domName AudioBufferSourceNode.start_2 */
  void _start_2(when, grainOffset, grainDuration) native "AudioBufferSourceNode_start_2_Callback";


  /** @domName AudioBufferSourceNode.stop */
  void stop(num when) native "AudioBufferSourceNode_stop_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class AudioContext extends EventTarget {
  factory AudioContext() => _AudioContextFactoryProvider.createAudioContext();
  AudioContext.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  AudioContextEvents get on =>
    new AudioContextEvents(this);


  /** @domName AudioContext.activeSourceCount */
  int get activeSourceCount native "AudioContext_activeSourceCount_Getter";


  /** @domName AudioContext.currentTime */
  num get currentTime native "AudioContext_currentTime_Getter";


  /** @domName AudioContext.destination */
  AudioDestinationNode get destination native "AudioContext_destination_Getter";


  /** @domName AudioContext.listener */
  AudioListener get listener native "AudioContext_listener_Getter";


  /** @domName AudioContext.sampleRate */
  num get sampleRate native "AudioContext_sampleRate_Getter";


  /** @domName AudioContext.createAnalyser */
  AnalyserNode createAnalyser() native "AudioContext_createAnalyser_Callback";


  /** @domName AudioContext.createBiquadFilter */
  BiquadFilterNode createBiquadFilter() native "AudioContext_createBiquadFilter_Callback";

  AudioBuffer createBuffer(buffer_OR_numberOfChannels, mixToMono_OR_numberOfFrames, [/*float*/ sampleRate]) {
    if ((buffer_OR_numberOfChannels is int || buffer_OR_numberOfChannels == null) && (mixToMono_OR_numberOfFrames is int || mixToMono_OR_numberOfFrames == null) && (sampleRate is num || sampleRate == null)) {
      return _createBuffer_1(buffer_OR_numberOfChannels, mixToMono_OR_numberOfFrames, sampleRate);
    }
    if ((buffer_OR_numberOfChannels is ArrayBuffer || buffer_OR_numberOfChannels == null) && (mixToMono_OR_numberOfFrames is bool || mixToMono_OR_numberOfFrames == null) && !?sampleRate) {
      return _createBuffer_2(buffer_OR_numberOfChannels, mixToMono_OR_numberOfFrames);
    }
    throw "Incorrect number or type of arguments";
  }


  /** @domName AudioContext.createBuffer_1 */
  AudioBuffer _createBuffer_1(buffer_OR_numberOfChannels, mixToMono_OR_numberOfFrames, sampleRate) native "AudioContext_createBuffer_1_Callback";


  /** @domName AudioContext.createBuffer_2 */
  AudioBuffer _createBuffer_2(buffer_OR_numberOfChannels, mixToMono_OR_numberOfFrames) native "AudioContext_createBuffer_2_Callback";


  /** @domName AudioContext.createBufferSource */
  AudioBufferSourceNode createBufferSource() native "AudioContext_createBufferSource_Callback";

  ChannelMergerNode createChannelMerger([/*unsigned long*/ numberOfInputs]) {
    if (?numberOfInputs) {
      return _createChannelMerger_1(numberOfInputs);
    }
    return _createChannelMerger_2();
  }


  /** @domName AudioContext.createChannelMerger_1 */
  ChannelMergerNode _createChannelMerger_1(numberOfInputs) native "AudioContext_createChannelMerger_1_Callback";


  /** @domName AudioContext.createChannelMerger_2 */
  ChannelMergerNode _createChannelMerger_2() native "AudioContext_createChannelMerger_2_Callback";

  ChannelSplitterNode createChannelSplitter([/*unsigned long*/ numberOfOutputs]) {
    if (?numberOfOutputs) {
      return _createChannelSplitter_1(numberOfOutputs);
    }
    return _createChannelSplitter_2();
  }


  /** @domName AudioContext.createChannelSplitter_1 */
  ChannelSplitterNode _createChannelSplitter_1(numberOfOutputs) native "AudioContext_createChannelSplitter_1_Callback";


  /** @domName AudioContext.createChannelSplitter_2 */
  ChannelSplitterNode _createChannelSplitter_2() native "AudioContext_createChannelSplitter_2_Callback";


  /** @domName AudioContext.createConvolver */
  ConvolverNode createConvolver() native "AudioContext_createConvolver_Callback";

  DelayNode createDelay([/*double*/ maxDelayTime]) {
    if (?maxDelayTime) {
      return _createDelay_1(maxDelayTime);
    }
    return _createDelay_2();
  }


  /** @domName AudioContext.createDelay_1 */
  DelayNode _createDelay_1(maxDelayTime) native "AudioContext_createDelay_1_Callback";


  /** @domName AudioContext.createDelay_2 */
  DelayNode _createDelay_2() native "AudioContext_createDelay_2_Callback";


  /** @domName AudioContext.createDynamicsCompressor */
  DynamicsCompressorNode createDynamicsCompressor() native "AudioContext_createDynamicsCompressor_Callback";


  /** @domName AudioContext.createGain */
  GainNode createGain() native "AudioContext_createGain_Callback";


  /** @domName AudioContext.createMediaElementSource */
  MediaElementAudioSourceNode createMediaElementSource(MediaElement mediaElement) native "AudioContext_createMediaElementSource_Callback";


  /** @domName AudioContext.createMediaStreamSource */
  MediaStreamAudioSourceNode createMediaStreamSource(MediaStream mediaStream) native "AudioContext_createMediaStreamSource_Callback";


  /** @domName AudioContext.createOscillator */
  OscillatorNode createOscillator() native "AudioContext_createOscillator_Callback";


  /** @domName AudioContext.createPanner */
  PannerNode createPanner() native "AudioContext_createPanner_Callback";

  ScriptProcessorNode createScriptProcessor(/*unsigned long*/ bufferSize, [/*unsigned long*/ numberOfInputChannels, /*unsigned long*/ numberOfOutputChannels]) {
    if (?numberOfOutputChannels) {
      return _createScriptProcessor_1(bufferSize, numberOfInputChannels, numberOfOutputChannels);
    }
    if (?numberOfInputChannels) {
      return _createScriptProcessor_2(bufferSize, numberOfInputChannels);
    }
    return _createScriptProcessor_3(bufferSize);
  }


  /** @domName AudioContext.createScriptProcessor_1 */
  ScriptProcessorNode _createScriptProcessor_1(bufferSize, numberOfInputChannels, numberOfOutputChannels) native "AudioContext_createScriptProcessor_1_Callback";


  /** @domName AudioContext.createScriptProcessor_2 */
  ScriptProcessorNode _createScriptProcessor_2(bufferSize, numberOfInputChannels) native "AudioContext_createScriptProcessor_2_Callback";


  /** @domName AudioContext.createScriptProcessor_3 */
  ScriptProcessorNode _createScriptProcessor_3(bufferSize) native "AudioContext_createScriptProcessor_3_Callback";


  /** @domName AudioContext.createWaveShaper */
  WaveShaperNode createWaveShaper() native "AudioContext_createWaveShaper_Callback";


  /** @domName AudioContext.createWaveTable */
  WaveTable createWaveTable(Float32Array real, Float32Array imag) native "AudioContext_createWaveTable_Callback";


  /** @domName AudioContext.decodeAudioData */
  void decodeAudioData(ArrayBuffer audioData, AudioBufferCallback successCallback, [AudioBufferCallback errorCallback]) native "AudioContext_decodeAudioData_Callback";


  /** @domName AudioContext.startRendering */
  void startRendering() native "AudioContext_startRendering_Callback";

}

class AudioContextEvents extends Events {
  AudioContextEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get complete => this['complete'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName AudioDestinationNode
class AudioDestinationNode extends AudioNode {
  AudioDestinationNode.internal(): super.internal();


  /** @domName AudioDestinationNode.numberOfChannels */
  int get numberOfChannels native "AudioDestinationNode_numberOfChannels_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLAudioElement
class AudioElement extends MediaElement {

  factory AudioElement([String src]) {
    if (!?src) {
      return _AudioElementFactoryProvider.createAudioElement();
    }
    return _AudioElementFactoryProvider.createAudioElement(src);
  }
  AudioElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName AudioGain
class AudioGain extends AudioParam {
  AudioGain.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName AudioListener
class AudioListener extends NativeFieldWrapperClass1 {
  AudioListener.internal();


  /** @domName AudioListener.dopplerFactor */
  num get dopplerFactor native "AudioListener_dopplerFactor_Getter";


  /** @domName AudioListener.dopplerFactor */
  void set dopplerFactor(num value) native "AudioListener_dopplerFactor_Setter";


  /** @domName AudioListener.speedOfSound */
  num get speedOfSound native "AudioListener_speedOfSound_Getter";


  /** @domName AudioListener.speedOfSound */
  void set speedOfSound(num value) native "AudioListener_speedOfSound_Setter";


  /** @domName AudioListener.setOrientation */
  void setOrientation(num x, num y, num z, num xUp, num yUp, num zUp) native "AudioListener_setOrientation_Callback";


  /** @domName AudioListener.setPosition */
  void setPosition(num x, num y, num z) native "AudioListener_setPosition_Callback";


  /** @domName AudioListener.setVelocity */
  void setVelocity(num x, num y, num z) native "AudioListener_setVelocity_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName AudioNode
class AudioNode extends NativeFieldWrapperClass1 {
  AudioNode.internal();


  /** @domName AudioNode.context */
  AudioContext get context native "AudioNode_context_Getter";


  /** @domName AudioNode.numberOfInputs */
  int get numberOfInputs native "AudioNode_numberOfInputs_Getter";


  /** @domName AudioNode.numberOfOutputs */
  int get numberOfOutputs native "AudioNode_numberOfOutputs_Getter";

  void connect(destination, /*unsigned long*/ output, [/*unsigned long*/ input]) {
    if ((destination is AudioNode || destination == null) && (output is int || output == null) && (input is int || input == null)) {
      _connect_1(destination, output, input);
      return;
    }
    if ((destination is AudioParam || destination == null) && (output is int || output == null) && !?input) {
      _connect_2(destination, output);
      return;
    }
    throw "Incorrect number or type of arguments";
  }


  /** @domName AudioNode.connect_1 */
  void _connect_1(destination, output, input) native "AudioNode_connect_1_Callback";


  /** @domName AudioNode.connect_2 */
  void _connect_2(destination, output) native "AudioNode_connect_2_Callback";


  /** @domName AudioNode.disconnect */
  void disconnect(int output) native "AudioNode_disconnect_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName AudioParam
class AudioParam extends NativeFieldWrapperClass1 {
  AudioParam.internal();


  /** @domName AudioParam.defaultValue */
  num get defaultValue native "AudioParam_defaultValue_Getter";


  /** @domName AudioParam.maxValue */
  num get maxValue native "AudioParam_maxValue_Getter";


  /** @domName AudioParam.minValue */
  num get minValue native "AudioParam_minValue_Getter";


  /** @domName AudioParam.name */
  String get name native "AudioParam_name_Getter";


  /** @domName AudioParam.units */
  int get units native "AudioParam_units_Getter";


  /** @domName AudioParam.value */
  num get value native "AudioParam_value_Getter";


  /** @domName AudioParam.value */
  void set value(num value) native "AudioParam_value_Setter";


  /** @domName AudioParam.cancelScheduledValues */
  void cancelScheduledValues(num startTime) native "AudioParam_cancelScheduledValues_Callback";


  /** @domName AudioParam.exponentialRampToValueAtTime */
  void exponentialRampToValueAtTime(num value, num time) native "AudioParam_exponentialRampToValueAtTime_Callback";


  /** @domName AudioParam.linearRampToValueAtTime */
  void linearRampToValueAtTime(num value, num time) native "AudioParam_linearRampToValueAtTime_Callback";


  /** @domName AudioParam.setTargetAtTime */
  void setTargetAtTime(num target, num time, num timeConstant) native "AudioParam_setTargetAtTime_Callback";


  /** @domName AudioParam.setValueAtTime */
  void setValueAtTime(num value, num time) native "AudioParam_setValueAtTime_Callback";


  /** @domName AudioParam.setValueCurveAtTime */
  void setValueCurveAtTime(Float32Array values, num time, num duration) native "AudioParam_setValueCurveAtTime_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName AudioProcessingEvent
class AudioProcessingEvent extends Event {
  AudioProcessingEvent.internal(): super.internal();


  /** @domName AudioProcessingEvent.inputBuffer */
  AudioBuffer get inputBuffer native "AudioProcessingEvent_inputBuffer_Getter";


  /** @domName AudioProcessingEvent.outputBuffer */
  AudioBuffer get outputBuffer native "AudioProcessingEvent_outputBuffer_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName AudioSourceNode
class AudioSourceNode extends AudioNode {
  AudioSourceNode.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLBRElement
class BRElement extends _Element_Merged {

  factory BRElement() => document.$dom_createElement("br");
  BRElement.internal(): super.internal();


  /** @domName HTMLBRElement.clear */
  String get clear native "HTMLBRElement_clear_Getter";


  /** @domName HTMLBRElement.clear */
  void set clear(String value) native "HTMLBRElement_clear_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName BarInfo
class BarInfo extends NativeFieldWrapperClass1 {
  BarInfo.internal();


  /** @domName BarInfo.visible */
  bool get visible native "BarInfo_visible_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLBaseElement
class BaseElement extends _Element_Merged {

  factory BaseElement() => document.$dom_createElement("base");
  BaseElement.internal(): super.internal();


  /** @domName HTMLBaseElement.href */
  String get href native "HTMLBaseElement_href_Getter";


  /** @domName HTMLBaseElement.href */
  void set href(String value) native "HTMLBaseElement_href_Setter";


  /** @domName HTMLBaseElement.target */
  String get target native "HTMLBaseElement_target_Getter";


  /** @domName HTMLBaseElement.target */
  void set target(String value) native "HTMLBaseElement_target_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLBaseFontElement
class BaseFontElement extends _Element_Merged {
  BaseFontElement.internal(): super.internal();


  /** @domName HTMLBaseFontElement.color */
  String get color native "HTMLBaseFontElement_color_Getter";


  /** @domName HTMLBaseFontElement.color */
  void set color(String value) native "HTMLBaseFontElement_color_Setter";


  /** @domName HTMLBaseFontElement.face */
  String get face native "HTMLBaseFontElement_face_Getter";


  /** @domName HTMLBaseFontElement.face */
  void set face(String value) native "HTMLBaseFontElement_face_Setter";


  /** @domName HTMLBaseFontElement.size */
  int get size native "HTMLBaseFontElement_size_Getter";


  /** @domName HTMLBaseFontElement.size */
  void set size(int value) native "HTMLBaseFontElement_size_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName BatteryManager
class BatteryManager extends EventTarget {
  BatteryManager.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  BatteryManagerEvents get on =>
    new BatteryManagerEvents(this);


  /** @domName BatteryManager.charging */
  bool get charging native "BatteryManager_charging_Getter";


  /** @domName BatteryManager.chargingTime */
  num get chargingTime native "BatteryManager_chargingTime_Getter";


  /** @domName BatteryManager.dischargingTime */
  num get dischargingTime native "BatteryManager_dischargingTime_Getter";


  /** @domName BatteryManager.level */
  num get level native "BatteryManager_level_Getter";


  /** @domName BatteryManager.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "BatteryManager_addEventListener_Callback";


  /** @domName BatteryManager.dispatchEvent */
  bool $dom_dispatchEvent(Event event) native "BatteryManager_dispatchEvent_Callback";


  /** @domName BatteryManager.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "BatteryManager_removeEventListener_Callback";

}

class BatteryManagerEvents extends Events {
  BatteryManagerEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get chargingChange => this['chargingchange'];

  EventListenerList get chargingTimeChange => this['chargingtimechange'];

  EventListenerList get dischargingTimeChange => this['dischargingtimechange'];

  EventListenerList get levelChange => this['levelchange'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName BeforeLoadEvent
class BeforeLoadEvent extends Event {
  BeforeLoadEvent.internal(): super.internal();


  /** @domName BeforeLoadEvent.url */
  String get url native "BeforeLoadEvent_url_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName BiquadFilterNode
class BiquadFilterNode extends AudioNode {
  BiquadFilterNode.internal(): super.internal();

  static const int ALLPASS = 7;

  static const int BANDPASS = 2;

  static const int HIGHPASS = 1;

  static const int HIGHSHELF = 4;

  static const int LOWPASS = 0;

  static const int LOWSHELF = 3;

  static const int NOTCH = 6;

  static const int PEAKING = 5;


  /** @domName BiquadFilterNode.Q */
  AudioParam get Q native "BiquadFilterNode_Q_Getter";


  /** @domName BiquadFilterNode.frequency */
  AudioParam get frequency native "BiquadFilterNode_frequency_Getter";


  /** @domName BiquadFilterNode.gain */
  AudioParam get gain native "BiquadFilterNode_gain_Getter";


  /** @domName BiquadFilterNode.type */
  int get type native "BiquadFilterNode_type_Getter";


  /** @domName BiquadFilterNode.type */
  void set type(int value) native "BiquadFilterNode_type_Setter";


  /** @domName BiquadFilterNode.getFrequencyResponse */
  void getFrequencyResponse(Float32Array frequencyHz, Float32Array magResponse, Float32Array phaseResponse) native "BiquadFilterNode_getFrequencyResponse_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Blob
class Blob extends NativeFieldWrapperClass1 {

  factory Blob(List blobParts, [String type, String endings]) {
    if (!?type) {
      return _BlobFactoryProvider.createBlob(blobParts);
    }
    if (!?endings) {
      return _BlobFactoryProvider.createBlob(blobParts, type);
    }
    return _BlobFactoryProvider.createBlob(blobParts, type, endings);
  }
  Blob.internal();


  /** @domName Blob.size */
  int get size native "Blob_size_Getter";


  /** @domName Blob.type */
  String get type native "Blob_type_Getter";

  Blob slice([/*long long*/ start, /*long long*/ end, /*DOMString*/ contentType]) {
    if (?contentType) {
      return _slice_1(start, end, contentType);
    }
    if (?end) {
      return _slice_2(start, end);
    }
    if (?start) {
      return _slice_3(start);
    }
    return _slice_4();
  }


  /** @domName Blob.slice_1 */
  Blob _slice_1(start, end, contentType) native "Blob_slice_1_Callback";


  /** @domName Blob.slice_2 */
  Blob _slice_2(start, end) native "Blob_slice_2_Callback";


  /** @domName Blob.slice_3 */
  Blob _slice_3(start) native "Blob_slice_3_Callback";


  /** @domName Blob.slice_4 */
  Blob _slice_4() native "Blob_slice_4_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLBodyElement
class BodyElement extends _Element_Merged {

  factory BodyElement() => document.$dom_createElement("body");
  BodyElement.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  BodyElementEvents get on =>
    new BodyElementEvents(this);


  /** @domName HTMLBodyElement.aLink */
  String get aLink native "HTMLBodyElement_aLink_Getter";


  /** @domName HTMLBodyElement.aLink */
  void set aLink(String value) native "HTMLBodyElement_aLink_Setter";


  /** @domName HTMLBodyElement.background */
  String get background native "HTMLBodyElement_background_Getter";


  /** @domName HTMLBodyElement.background */
  void set background(String value) native "HTMLBodyElement_background_Setter";


  /** @domName HTMLBodyElement.bgColor */
  String get bgColor native "HTMLBodyElement_bgColor_Getter";


  /** @domName HTMLBodyElement.bgColor */
  void set bgColor(String value) native "HTMLBodyElement_bgColor_Setter";


  /** @domName HTMLBodyElement.link */
  String get link native "HTMLBodyElement_link_Getter";


  /** @domName HTMLBodyElement.link */
  void set link(String value) native "HTMLBodyElement_link_Setter";


  /** @domName HTMLBodyElement.vLink */
  String get vLink native "HTMLBodyElement_vLink_Getter";


  /** @domName HTMLBodyElement.vLink */
  void set vLink(String value) native "HTMLBodyElement_vLink_Setter";

}

class BodyElementEvents extends ElementEvents {
  BodyElementEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get beforeUnload => this['beforeunload'];

  EventListenerList get blur => this['blur'];

  EventListenerList get error => this['error'];

  EventListenerList get focus => this['focus'];

  EventListenerList get hashChange => this['hashchange'];

  EventListenerList get load => this['load'];

  EventListenerList get message => this['message'];

  EventListenerList get offline => this['offline'];

  EventListenerList get online => this['online'];

  EventListenerList get popState => this['popstate'];

  EventListenerList get resize => this['resize'];

  EventListenerList get storage => this['storage'];

  EventListenerList get unload => this['unload'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLButtonElement
class ButtonElement extends _Element_Merged {

  factory ButtonElement() => document.$dom_createElement("button");
  ButtonElement.internal(): super.internal();


  /** @domName HTMLButtonElement.autofocus */
  bool get autofocus native "HTMLButtonElement_autofocus_Getter";


  /** @domName HTMLButtonElement.autofocus */
  void set autofocus(bool value) native "HTMLButtonElement_autofocus_Setter";


  /** @domName HTMLButtonElement.disabled */
  bool get disabled native "HTMLButtonElement_disabled_Getter";


  /** @domName HTMLButtonElement.disabled */
  void set disabled(bool value) native "HTMLButtonElement_disabled_Setter";


  /** @domName HTMLButtonElement.form */
  FormElement get form native "HTMLButtonElement_form_Getter";


  /** @domName HTMLButtonElement.formAction */
  String get formAction native "HTMLButtonElement_formAction_Getter";


  /** @domName HTMLButtonElement.formAction */
  void set formAction(String value) native "HTMLButtonElement_formAction_Setter";


  /** @domName HTMLButtonElement.formEnctype */
  String get formEnctype native "HTMLButtonElement_formEnctype_Getter";


  /** @domName HTMLButtonElement.formEnctype */
  void set formEnctype(String value) native "HTMLButtonElement_formEnctype_Setter";


  /** @domName HTMLButtonElement.formMethod */
  String get formMethod native "HTMLButtonElement_formMethod_Getter";


  /** @domName HTMLButtonElement.formMethod */
  void set formMethod(String value) native "HTMLButtonElement_formMethod_Setter";


  /** @domName HTMLButtonElement.formNoValidate */
  bool get formNoValidate native "HTMLButtonElement_formNoValidate_Getter";


  /** @domName HTMLButtonElement.formNoValidate */
  void set formNoValidate(bool value) native "HTMLButtonElement_formNoValidate_Setter";


  /** @domName HTMLButtonElement.formTarget */
  String get formTarget native "HTMLButtonElement_formTarget_Getter";


  /** @domName HTMLButtonElement.formTarget */
  void set formTarget(String value) native "HTMLButtonElement_formTarget_Setter";


  /** @domName HTMLButtonElement.labels */
  List<Node> get labels native "HTMLButtonElement_labels_Getter";


  /** @domName HTMLButtonElement.name */
  String get name native "HTMLButtonElement_name_Getter";


  /** @domName HTMLButtonElement.name */
  void set name(String value) native "HTMLButtonElement_name_Setter";


  /** @domName HTMLButtonElement.type */
  String get type native "HTMLButtonElement_type_Getter";


  /** @domName HTMLButtonElement.type */
  void set type(String value) native "HTMLButtonElement_type_Setter";


  /** @domName HTMLButtonElement.validationMessage */
  String get validationMessage native "HTMLButtonElement_validationMessage_Getter";


  /** @domName HTMLButtonElement.validity */
  ValidityState get validity native "HTMLButtonElement_validity_Getter";


  /** @domName HTMLButtonElement.value */
  String get value native "HTMLButtonElement_value_Getter";


  /** @domName HTMLButtonElement.value */
  void set value(String value) native "HTMLButtonElement_value_Setter";


  /** @domName HTMLButtonElement.willValidate */
  bool get willValidate native "HTMLButtonElement_willValidate_Getter";


  /** @domName HTMLButtonElement.checkValidity */
  bool checkValidity() native "HTMLButtonElement_checkValidity_Callback";


  /** @domName HTMLButtonElement.setCustomValidity */
  void setCustomValidity(String error) native "HTMLButtonElement_setCustomValidity_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName CDATASection
class CDATASection extends Text {
  CDATASection.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName CSSCharsetRule
class CSSCharsetRule extends CSSRule {
  CSSCharsetRule.internal(): super.internal();


  /** @domName CSSCharsetRule.encoding */
  String get encoding native "CSSCharsetRule_encoding_Getter";


  /** @domName CSSCharsetRule.encoding */
  void set encoding(String value) native "CSSCharsetRule_encoding_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName CSSFontFaceRule
class CSSFontFaceRule extends CSSRule {
  CSSFontFaceRule.internal(): super.internal();


  /** @domName CSSFontFaceRule.style */
  CSSStyleDeclaration get style native "CSSFontFaceRule_style_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName CSSImportRule
class CSSImportRule extends CSSRule {
  CSSImportRule.internal(): super.internal();


  /** @domName CSSImportRule.href */
  String get href native "CSSImportRule_href_Getter";


  /** @domName CSSImportRule.media */
  MediaList get media native "CSSImportRule_media_Getter";


  /** @domName CSSImportRule.styleSheet */
  CSSStyleSheet get styleSheet native "CSSImportRule_styleSheet_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WebKitCSSKeyframeRule
class CSSKeyframeRule extends CSSRule {
  CSSKeyframeRule.internal(): super.internal();


  /** @domName WebKitCSSKeyframeRule.keyText */
  String get keyText native "WebKitCSSKeyframeRule_keyText_Getter";


  /** @domName WebKitCSSKeyframeRule.keyText */
  void set keyText(String value) native "WebKitCSSKeyframeRule_keyText_Setter";


  /** @domName WebKitCSSKeyframeRule.style */
  CSSStyleDeclaration get style native "WebKitCSSKeyframeRule_style_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WebKitCSSKeyframesRule
class CSSKeyframesRule extends CSSRule {
  CSSKeyframesRule.internal(): super.internal();


  /** @domName WebKitCSSKeyframesRule.cssRules */
  List<CSSRule> get cssRules native "WebKitCSSKeyframesRule_cssRules_Getter";


  /** @domName WebKitCSSKeyframesRule.name */
  String get name native "WebKitCSSKeyframesRule_name_Getter";


  /** @domName WebKitCSSKeyframesRule.name */
  void set name(String value) native "WebKitCSSKeyframesRule_name_Setter";


  /** @domName WebKitCSSKeyframesRule.deleteRule */
  void deleteRule(String key) native "WebKitCSSKeyframesRule_deleteRule_Callback";


  /** @domName WebKitCSSKeyframesRule.findRule */
  CSSKeyframeRule findRule(String key) native "WebKitCSSKeyframesRule_findRule_Callback";


  /** @domName WebKitCSSKeyframesRule.insertRule */
  void insertRule(String rule) native "WebKitCSSKeyframesRule_insertRule_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WebKitCSSMatrix
class CSSMatrix extends NativeFieldWrapperClass1 {

  factory CSSMatrix([String cssValue]) {
    if (!?cssValue) {
      return _CSSMatrixFactoryProvider.createCSSMatrix();
    }
    return _CSSMatrixFactoryProvider.createCSSMatrix(cssValue);
  }
  CSSMatrix.internal();


  /** @domName WebKitCSSMatrix.a */
  num get a native "WebKitCSSMatrix_a_Getter";


  /** @domName WebKitCSSMatrix.a */
  void set a(num value) native "WebKitCSSMatrix_a_Setter";


  /** @domName WebKitCSSMatrix.b */
  num get b native "WebKitCSSMatrix_b_Getter";


  /** @domName WebKitCSSMatrix.b */
  void set b(num value) native "WebKitCSSMatrix_b_Setter";


  /** @domName WebKitCSSMatrix.c */
  num get c native "WebKitCSSMatrix_c_Getter";


  /** @domName WebKitCSSMatrix.c */
  void set c(num value) native "WebKitCSSMatrix_c_Setter";


  /** @domName WebKitCSSMatrix.d */
  num get d native "WebKitCSSMatrix_d_Getter";


  /** @domName WebKitCSSMatrix.d */
  void set d(num value) native "WebKitCSSMatrix_d_Setter";


  /** @domName WebKitCSSMatrix.e */
  num get e native "WebKitCSSMatrix_e_Getter";


  /** @domName WebKitCSSMatrix.e */
  void set e(num value) native "WebKitCSSMatrix_e_Setter";


  /** @domName WebKitCSSMatrix.f */
  num get f native "WebKitCSSMatrix_f_Getter";


  /** @domName WebKitCSSMatrix.f */
  void set f(num value) native "WebKitCSSMatrix_f_Setter";


  /** @domName WebKitCSSMatrix.m11 */
  num get m11 native "WebKitCSSMatrix_m11_Getter";


  /** @domName WebKitCSSMatrix.m11 */
  void set m11(num value) native "WebKitCSSMatrix_m11_Setter";


  /** @domName WebKitCSSMatrix.m12 */
  num get m12 native "WebKitCSSMatrix_m12_Getter";


  /** @domName WebKitCSSMatrix.m12 */
  void set m12(num value) native "WebKitCSSMatrix_m12_Setter";


  /** @domName WebKitCSSMatrix.m13 */
  num get m13 native "WebKitCSSMatrix_m13_Getter";


  /** @domName WebKitCSSMatrix.m13 */
  void set m13(num value) native "WebKitCSSMatrix_m13_Setter";


  /** @domName WebKitCSSMatrix.m14 */
  num get m14 native "WebKitCSSMatrix_m14_Getter";


  /** @domName WebKitCSSMatrix.m14 */
  void set m14(num value) native "WebKitCSSMatrix_m14_Setter";


  /** @domName WebKitCSSMatrix.m21 */
  num get m21 native "WebKitCSSMatrix_m21_Getter";


  /** @domName WebKitCSSMatrix.m21 */
  void set m21(num value) native "WebKitCSSMatrix_m21_Setter";


  /** @domName WebKitCSSMatrix.m22 */
  num get m22 native "WebKitCSSMatrix_m22_Getter";


  /** @domName WebKitCSSMatrix.m22 */
  void set m22(num value) native "WebKitCSSMatrix_m22_Setter";


  /** @domName WebKitCSSMatrix.m23 */
  num get m23 native "WebKitCSSMatrix_m23_Getter";


  /** @domName WebKitCSSMatrix.m23 */
  void set m23(num value) native "WebKitCSSMatrix_m23_Setter";


  /** @domName WebKitCSSMatrix.m24 */
  num get m24 native "WebKitCSSMatrix_m24_Getter";


  /** @domName WebKitCSSMatrix.m24 */
  void set m24(num value) native "WebKitCSSMatrix_m24_Setter";


  /** @domName WebKitCSSMatrix.m31 */
  num get m31 native "WebKitCSSMatrix_m31_Getter";


  /** @domName WebKitCSSMatrix.m31 */
  void set m31(num value) native "WebKitCSSMatrix_m31_Setter";


  /** @domName WebKitCSSMatrix.m32 */
  num get m32 native "WebKitCSSMatrix_m32_Getter";


  /** @domName WebKitCSSMatrix.m32 */
  void set m32(num value) native "WebKitCSSMatrix_m32_Setter";


  /** @domName WebKitCSSMatrix.m33 */
  num get m33 native "WebKitCSSMatrix_m33_Getter";


  /** @domName WebKitCSSMatrix.m33 */
  void set m33(num value) native "WebKitCSSMatrix_m33_Setter";


  /** @domName WebKitCSSMatrix.m34 */
  num get m34 native "WebKitCSSMatrix_m34_Getter";


  /** @domName WebKitCSSMatrix.m34 */
  void set m34(num value) native "WebKitCSSMatrix_m34_Setter";


  /** @domName WebKitCSSMatrix.m41 */
  num get m41 native "WebKitCSSMatrix_m41_Getter";


  /** @domName WebKitCSSMatrix.m41 */
  void set m41(num value) native "WebKitCSSMatrix_m41_Setter";


  /** @domName WebKitCSSMatrix.m42 */
  num get m42 native "WebKitCSSMatrix_m42_Getter";


  /** @domName WebKitCSSMatrix.m42 */
  void set m42(num value) native "WebKitCSSMatrix_m42_Setter";


  /** @domName WebKitCSSMatrix.m43 */
  num get m43 native "WebKitCSSMatrix_m43_Getter";


  /** @domName WebKitCSSMatrix.m43 */
  void set m43(num value) native "WebKitCSSMatrix_m43_Setter";


  /** @domName WebKitCSSMatrix.m44 */
  num get m44 native "WebKitCSSMatrix_m44_Getter";


  /** @domName WebKitCSSMatrix.m44 */
  void set m44(num value) native "WebKitCSSMatrix_m44_Setter";


  /** @domName WebKitCSSMatrix.inverse */
  CSSMatrix inverse() native "WebKitCSSMatrix_inverse_Callback";


  /** @domName WebKitCSSMatrix.multiply */
  CSSMatrix multiply(CSSMatrix secondMatrix) native "WebKitCSSMatrix_multiply_Callback";


  /** @domName WebKitCSSMatrix.rotate */
  CSSMatrix rotate(num rotX, num rotY, num rotZ) native "WebKitCSSMatrix_rotate_Callback";


  /** @domName WebKitCSSMatrix.rotateAxisAngle */
  CSSMatrix rotateAxisAngle(num x, num y, num z, num angle) native "WebKitCSSMatrix_rotateAxisAngle_Callback";


  /** @domName WebKitCSSMatrix.scale */
  CSSMatrix scale(num scaleX, num scaleY, num scaleZ) native "WebKitCSSMatrix_scale_Callback";


  /** @domName WebKitCSSMatrix.setMatrixValue */
  void setMatrixValue(String string) native "WebKitCSSMatrix_setMatrixValue_Callback";


  /** @domName WebKitCSSMatrix.skewX */
  CSSMatrix skewX(num angle) native "WebKitCSSMatrix_skewX_Callback";


  /** @domName WebKitCSSMatrix.skewY */
  CSSMatrix skewY(num angle) native "WebKitCSSMatrix_skewY_Callback";


  /** @domName WebKitCSSMatrix.toString */
  String toString() native "WebKitCSSMatrix_toString_Callback";


  /** @domName WebKitCSSMatrix.translate */
  CSSMatrix translate(num x, num y, num z) native "WebKitCSSMatrix_translate_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName CSSMediaRule
class CSSMediaRule extends CSSRule {
  CSSMediaRule.internal(): super.internal();


  /** @domName CSSMediaRule.cssRules */
  List<CSSRule> get cssRules native "CSSMediaRule_cssRules_Getter";


  /** @domName CSSMediaRule.media */
  MediaList get media native "CSSMediaRule_media_Getter";


  /** @domName CSSMediaRule.deleteRule */
  void deleteRule(int index) native "CSSMediaRule_deleteRule_Callback";


  /** @domName CSSMediaRule.insertRule */
  int insertRule(String rule, int index) native "CSSMediaRule_insertRule_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName CSSPageRule
class CSSPageRule extends CSSRule {
  CSSPageRule.internal(): super.internal();


  /** @domName CSSPageRule.selectorText */
  String get selectorText native "CSSPageRule_selectorText_Getter";


  /** @domName CSSPageRule.selectorText */
  void set selectorText(String value) native "CSSPageRule_selectorText_Setter";


  /** @domName CSSPageRule.style */
  CSSStyleDeclaration get style native "CSSPageRule_style_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName CSSPrimitiveValue
class CSSPrimitiveValue extends CSSValue {
  CSSPrimitiveValue.internal(): super.internal();

  static const int CSS_ATTR = 22;

  static const int CSS_CM = 6;

  static const int CSS_COUNTER = 23;

  static const int CSS_DEG = 11;

  static const int CSS_DIMENSION = 18;

  static const int CSS_EMS = 3;

  static const int CSS_EXS = 4;

  static const int CSS_GRAD = 13;

  static const int CSS_HZ = 16;

  static const int CSS_IDENT = 21;

  static const int CSS_IN = 8;

  static const int CSS_KHZ = 17;

  static const int CSS_MM = 7;

  static const int CSS_MS = 14;

  static const int CSS_NUMBER = 1;

  static const int CSS_PC = 10;

  static const int CSS_PERCENTAGE = 2;

  static const int CSS_PT = 9;

  static const int CSS_PX = 5;

  static const int CSS_RAD = 12;

  static const int CSS_RECT = 24;

  static const int CSS_RGBCOLOR = 25;

  static const int CSS_S = 15;

  static const int CSS_STRING = 19;

  static const int CSS_UNKNOWN = 0;

  static const int CSS_URI = 20;

  static const int CSS_VH = 27;

  static const int CSS_VMIN = 28;

  static const int CSS_VW = 26;


  /** @domName CSSPrimitiveValue.primitiveType */
  int get primitiveType native "CSSPrimitiveValue_primitiveType_Getter";


  /** @domName CSSPrimitiveValue.getCounterValue */
  Counter getCounterValue() native "CSSPrimitiveValue_getCounterValue_Callback";


  /** @domName CSSPrimitiveValue.getFloatValue */
  num getFloatValue(int unitType) native "CSSPrimitiveValue_getFloatValue_Callback";


  /** @domName CSSPrimitiveValue.getRGBColorValue */
  RGBColor getRGBColorValue() native "CSSPrimitiveValue_getRGBColorValue_Callback";


  /** @domName CSSPrimitiveValue.getRectValue */
  Rect getRectValue() native "CSSPrimitiveValue_getRectValue_Callback";


  /** @domName CSSPrimitiveValue.getStringValue */
  String getStringValue() native "CSSPrimitiveValue_getStringValue_Callback";


  /** @domName CSSPrimitiveValue.setFloatValue */
  void setFloatValue(int unitType, num floatValue) native "CSSPrimitiveValue_setFloatValue_Callback";


  /** @domName CSSPrimitiveValue.setStringValue */
  void setStringValue(int stringType, String stringValue) native "CSSPrimitiveValue_setStringValue_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName CSSRule
class CSSRule extends NativeFieldWrapperClass1 {
  CSSRule.internal();

  static const int CHARSET_RULE = 2;

  static const int FONT_FACE_RULE = 5;

  static const int IMPORT_RULE = 3;

  static const int MEDIA_RULE = 4;

  static const int PAGE_RULE = 6;

  static const int STYLE_RULE = 1;

  static const int UNKNOWN_RULE = 0;

  static const int WEBKIT_KEYFRAMES_RULE = 7;

  static const int WEBKIT_KEYFRAME_RULE = 8;


  /** @domName CSSRule.cssText */
  String get cssText native "CSSRule_cssText_Getter";


  /** @domName CSSRule.cssText */
  void set cssText(String value) native "CSSRule_cssText_Setter";


  /** @domName CSSRule.parentRule */
  CSSRule get parentRule native "CSSRule_parentRule_Getter";


  /** @domName CSSRule.parentStyleSheet */
  CSSStyleSheet get parentStyleSheet native "CSSRule_parentStyleSheet_Getter";


  /** @domName CSSRule.type */
  int get type native "CSSRule_type_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


String _cachedBrowserPrefix;

String get _browserPrefix {
  if (_cachedBrowserPrefix == null) {
    if (_Device.isFirefox) {
      _cachedBrowserPrefix = '-moz-';
    } else if (_Device.isIE) {
      _cachedBrowserPrefix = '-ms-';
    } else if (_Device.isOpera) {
      _cachedBrowserPrefix = '-o-';
    } else {
      _cachedBrowserPrefix = '-webkit-';
    }
  }
  return _cachedBrowserPrefix;
}

class CSSStyleDeclaration extends NativeFieldWrapperClass1 {
  factory CSSStyleDeclaration() => _CSSStyleDeclarationFactoryProvider.createCSSStyleDeclaration();
  factory CSSStyleDeclaration.css(String css) =>
      _CSSStyleDeclarationFactoryProvider.createCSSStyleDeclaration_css(css);

  CSSStyleDeclaration.internal();


  /** @domName CSSStyleDeclaration.cssText */
  String get cssText native "CSSStyleDeclaration_cssText_Getter";


  /** @domName CSSStyleDeclaration.cssText */
  void set cssText(String value) native "CSSStyleDeclaration_cssText_Setter";


  /** @domName CSSStyleDeclaration.length */
  int get length native "CSSStyleDeclaration_length_Getter";


  /** @domName CSSStyleDeclaration.parentRule */
  CSSRule get parentRule native "CSSStyleDeclaration_parentRule_Getter";


  /** @domName CSSStyleDeclaration.getPropertyCSSValue */
  CSSValue getPropertyCSSValue(String propertyName) native "CSSStyleDeclaration_getPropertyCSSValue_Callback";


  /** @domName CSSStyleDeclaration.getPropertyPriority */
  String getPropertyPriority(String propertyName) native "CSSStyleDeclaration_getPropertyPriority_Callback";


  /** @domName CSSStyleDeclaration.getPropertyShorthand */
  String getPropertyShorthand(String propertyName) native "CSSStyleDeclaration_getPropertyShorthand_Callback";


  /** @domName CSSStyleDeclaration._getPropertyValue */
  String _getPropertyValue(String propertyName) native "CSSStyleDeclaration__getPropertyValue_Callback";


  /** @domName CSSStyleDeclaration.isPropertyImplicit */
  bool isPropertyImplicit(String propertyName) native "CSSStyleDeclaration_isPropertyImplicit_Callback";


  /** @domName CSSStyleDeclaration.item */
  String item(int index) native "CSSStyleDeclaration_item_Callback";


  /** @domName CSSStyleDeclaration.removeProperty */
  String removeProperty(String propertyName) native "CSSStyleDeclaration_removeProperty_Callback";


  /** @domName CSSStyleDeclaration.setProperty */
  void setProperty(String propertyName, String value, [String priority]) native "CSSStyleDeclaration_setProperty_Callback";


  String getPropertyValue(String propertyName) {
    var propValue = _getPropertyValue(propertyName);
    return propValue != null ? propValue : '';
  }


  // TODO(jacobr): generate this list of properties using the existing script.
  /** Gets the value of "align-content" */
  String get alignContent =>
    getPropertyValue('${_browserPrefix}align-content');

  /** Sets the value of "align-content" */
  void set alignContent(String value) {
    setProperty('${_browserPrefix}align-content', value, '');
  }

  /** Gets the value of "align-items" */
  String get alignItems =>
    getPropertyValue('${_browserPrefix}align-items');

  /** Sets the value of "align-items" */
  void set alignItems(String value) {
    setProperty('${_browserPrefix}align-items', value, '');
  }

  /** Gets the value of "align-self" */
  String get alignSelf =>
    getPropertyValue('${_browserPrefix}align-self');

  /** Sets the value of "align-self" */
  void set alignSelf(String value) {
    setProperty('${_browserPrefix}align-self', value, '');
  }

  /** Gets the value of "animation" */
  String get animation =>
    getPropertyValue('${_browserPrefix}animation');

  /** Sets the value of "animation" */
  void set animation(String value) {
    setProperty('${_browserPrefix}animation', value, '');
  }

  /** Gets the value of "animation-delay" */
  String get animationDelay =>
    getPropertyValue('${_browserPrefix}animation-delay');

  /** Sets the value of "animation-delay" */
  void set animationDelay(String value) {
    setProperty('${_browserPrefix}animation-delay', value, '');
  }

  /** Gets the value of "animation-direction" */
  String get animationDirection =>
    getPropertyValue('${_browserPrefix}animation-direction');

  /** Sets the value of "animation-direction" */
  void set animationDirection(String value) {
    setProperty('${_browserPrefix}animation-direction', value, '');
  }

  /** Gets the value of "animation-duration" */
  String get animationDuration =>
    getPropertyValue('${_browserPrefix}animation-duration');

  /** Sets the value of "animation-duration" */
  void set animationDuration(String value) {
    setProperty('${_browserPrefix}animation-duration', value, '');
  }

  /** Gets the value of "animation-fill-mode" */
  String get animationFillMode =>
    getPropertyValue('${_browserPrefix}animation-fill-mode');

  /** Sets the value of "animation-fill-mode" */
  void set animationFillMode(String value) {
    setProperty('${_browserPrefix}animation-fill-mode', value, '');
  }

  /** Gets the value of "animation-iteration-count" */
  String get animationIterationCount =>
    getPropertyValue('${_browserPrefix}animation-iteration-count');

  /** Sets the value of "animation-iteration-count" */
  void set animationIterationCount(String value) {
    setProperty('${_browserPrefix}animation-iteration-count', value, '');
  }

  /** Gets the value of "animation-name" */
  String get animationName =>
    getPropertyValue('${_browserPrefix}animation-name');

  /** Sets the value of "animation-name" */
  void set animationName(String value) {
    setProperty('${_browserPrefix}animation-name', value, '');
  }

  /** Gets the value of "animation-play-state" */
  String get animationPlayState =>
    getPropertyValue('${_browserPrefix}animation-play-state');

  /** Sets the value of "animation-play-state" */
  void set animationPlayState(String value) {
    setProperty('${_browserPrefix}animation-play-state', value, '');
  }

  /** Gets the value of "animation-timing-function" */
  String get animationTimingFunction =>
    getPropertyValue('${_browserPrefix}animation-timing-function');

  /** Sets the value of "animation-timing-function" */
  void set animationTimingFunction(String value) {
    setProperty('${_browserPrefix}animation-timing-function', value, '');
  }

  /** Gets the value of "app-region" */
  String get appRegion =>
    getPropertyValue('${_browserPrefix}app-region');

  /** Sets the value of "app-region" */
  void set appRegion(String value) {
    setProperty('${_browserPrefix}app-region', value, '');
  }

  /** Gets the value of "appearance" */
  String get appearance =>
    getPropertyValue('${_browserPrefix}appearance');

  /** Sets the value of "appearance" */
  void set appearance(String value) {
    setProperty('${_browserPrefix}appearance', value, '');
  }

  /** Gets the value of "aspect-ratio" */
  String get aspectRatio =>
    getPropertyValue('${_browserPrefix}aspect-ratio');

  /** Sets the value of "aspect-ratio" */
  void set aspectRatio(String value) {
    setProperty('${_browserPrefix}aspect-ratio', value, '');
  }

  /** Gets the value of "backface-visibility" */
  String get backfaceVisibility =>
    getPropertyValue('${_browserPrefix}backface-visibility');

  /** Sets the value of "backface-visibility" */
  void set backfaceVisibility(String value) {
    setProperty('${_browserPrefix}backface-visibility', value, '');
  }

  /** Gets the value of "background" */
  String get background =>
    getPropertyValue('background');

  /** Sets the value of "background" */
  void set background(String value) {
    setProperty('background', value, '');
  }

  /** Gets the value of "background-attachment" */
  String get backgroundAttachment =>
    getPropertyValue('background-attachment');

  /** Sets the value of "background-attachment" */
  void set backgroundAttachment(String value) {
    setProperty('background-attachment', value, '');
  }

  /** Gets the value of "background-clip" */
  String get backgroundClip =>
    getPropertyValue('background-clip');

  /** Sets the value of "background-clip" */
  void set backgroundClip(String value) {
    setProperty('background-clip', value, '');
  }

  /** Gets the value of "background-color" */
  String get backgroundColor =>
    getPropertyValue('background-color');

  /** Sets the value of "background-color" */
  void set backgroundColor(String value) {
    setProperty('background-color', value, '');
  }

  /** Gets the value of "background-composite" */
  String get backgroundComposite =>
    getPropertyValue('${_browserPrefix}background-composite');

  /** Sets the value of "background-composite" */
  void set backgroundComposite(String value) {
    setProperty('${_browserPrefix}background-composite', value, '');
  }

  /** Gets the value of "background-image" */
  String get backgroundImage =>
    getPropertyValue('background-image');

  /** Sets the value of "background-image" */
  void set backgroundImage(String value) {
    setProperty('background-image', value, '');
  }

  /** Gets the value of "background-origin" */
  String get backgroundOrigin =>
    getPropertyValue('background-origin');

  /** Sets the value of "background-origin" */
  void set backgroundOrigin(String value) {
    setProperty('background-origin', value, '');
  }

  /** Gets the value of "background-position" */
  String get backgroundPosition =>
    getPropertyValue('background-position');

  /** Sets the value of "background-position" */
  void set backgroundPosition(String value) {
    setProperty('background-position', value, '');
  }

  /** Gets the value of "background-position-x" */
  String get backgroundPositionX =>
    getPropertyValue('background-position-x');

  /** Sets the value of "background-position-x" */
  void set backgroundPositionX(String value) {
    setProperty('background-position-x', value, '');
  }

  /** Gets the value of "background-position-y" */
  String get backgroundPositionY =>
    getPropertyValue('background-position-y');

  /** Sets the value of "background-position-y" */
  void set backgroundPositionY(String value) {
    setProperty('background-position-y', value, '');
  }

  /** Gets the value of "background-repeat" */
  String get backgroundRepeat =>
    getPropertyValue('background-repeat');

  /** Sets the value of "background-repeat" */
  void set backgroundRepeat(String value) {
    setProperty('background-repeat', value, '');
  }

  /** Gets the value of "background-repeat-x" */
  String get backgroundRepeatX =>
    getPropertyValue('background-repeat-x');

  /** Sets the value of "background-repeat-x" */
  void set backgroundRepeatX(String value) {
    setProperty('background-repeat-x', value, '');
  }

  /** Gets the value of "background-repeat-y" */
  String get backgroundRepeatY =>
    getPropertyValue('background-repeat-y');

  /** Sets the value of "background-repeat-y" */
  void set backgroundRepeatY(String value) {
    setProperty('background-repeat-y', value, '');
  }

  /** Gets the value of "background-size" */
  String get backgroundSize =>
    getPropertyValue('background-size');

  /** Sets the value of "background-size" */
  void set backgroundSize(String value) {
    setProperty('background-size', value, '');
  }

  /** Gets the value of "blend-mode" */
  String get blendMode =>
    getPropertyValue('${_browserPrefix}blend-mode');

  /** Sets the value of "blend-mode" */
  void set blendMode(String value) {
    setProperty('${_browserPrefix}blend-mode', value, '');
  }

  /** Gets the value of "border" */
  String get border =>
    getPropertyValue('border');

  /** Sets the value of "border" */
  void set border(String value) {
    setProperty('border', value, '');
  }

  /** Gets the value of "border-after" */
  String get borderAfter =>
    getPropertyValue('${_browserPrefix}border-after');

  /** Sets the value of "border-after" */
  void set borderAfter(String value) {
    setProperty('${_browserPrefix}border-after', value, '');
  }

  /** Gets the value of "border-after-color" */
  String get borderAfterColor =>
    getPropertyValue('${_browserPrefix}border-after-color');

  /** Sets the value of "border-after-color" */
  void set borderAfterColor(String value) {
    setProperty('${_browserPrefix}border-after-color', value, '');
  }

  /** Gets the value of "border-after-style" */
  String get borderAfterStyle =>
    getPropertyValue('${_browserPrefix}border-after-style');

  /** Sets the value of "border-after-style" */
  void set borderAfterStyle(String value) {
    setProperty('${_browserPrefix}border-after-style', value, '');
  }

  /** Gets the value of "border-after-width" */
  String get borderAfterWidth =>
    getPropertyValue('${_browserPrefix}border-after-width');

  /** Sets the value of "border-after-width" */
  void set borderAfterWidth(String value) {
    setProperty('${_browserPrefix}border-after-width', value, '');
  }

  /** Gets the value of "border-before" */
  String get borderBefore =>
    getPropertyValue('${_browserPrefix}border-before');

  /** Sets the value of "border-before" */
  void set borderBefore(String value) {
    setProperty('${_browserPrefix}border-before', value, '');
  }

  /** Gets the value of "border-before-color" */
  String get borderBeforeColor =>
    getPropertyValue('${_browserPrefix}border-before-color');

  /** Sets the value of "border-before-color" */
  void set borderBeforeColor(String value) {
    setProperty('${_browserPrefix}border-before-color', value, '');
  }

  /** Gets the value of "border-before-style" */
  String get borderBeforeStyle =>
    getPropertyValue('${_browserPrefix}border-before-style');

  /** Sets the value of "border-before-style" */
  void set borderBeforeStyle(String value) {
    setProperty('${_browserPrefix}border-before-style', value, '');
  }

  /** Gets the value of "border-before-width" */
  String get borderBeforeWidth =>
    getPropertyValue('${_browserPrefix}border-before-width');

  /** Sets the value of "border-before-width" */
  void set borderBeforeWidth(String value) {
    setProperty('${_browserPrefix}border-before-width', value, '');
  }

  /** Gets the value of "border-bottom" */
  String get borderBottom =>
    getPropertyValue('border-bottom');

  /** Sets the value of "border-bottom" */
  void set borderBottom(String value) {
    setProperty('border-bottom', value, '');
  }

  /** Gets the value of "border-bottom-color" */
  String get borderBottomColor =>
    getPropertyValue('border-bottom-color');

  /** Sets the value of "border-bottom-color" */
  void set borderBottomColor(String value) {
    setProperty('border-bottom-color', value, '');
  }

  /** Gets the value of "border-bottom-left-radius" */
  String get borderBottomLeftRadius =>
    getPropertyValue('border-bottom-left-radius');

  /** Sets the value of "border-bottom-left-radius" */
  void set borderBottomLeftRadius(String value) {
    setProperty('border-bottom-left-radius', value, '');
  }

  /** Gets the value of "border-bottom-right-radius" */
  String get borderBottomRightRadius =>
    getPropertyValue('border-bottom-right-radius');

  /** Sets the value of "border-bottom-right-radius" */
  void set borderBottomRightRadius(String value) {
    setProperty('border-bottom-right-radius', value, '');
  }

  /** Gets the value of "border-bottom-style" */
  String get borderBottomStyle =>
    getPropertyValue('border-bottom-style');

  /** Sets the value of "border-bottom-style" */
  void set borderBottomStyle(String value) {
    setProperty('border-bottom-style', value, '');
  }

  /** Gets the value of "border-bottom-width" */
  String get borderBottomWidth =>
    getPropertyValue('border-bottom-width');

  /** Sets the value of "border-bottom-width" */
  void set borderBottomWidth(String value) {
    setProperty('border-bottom-width', value, '');
  }

  /** Gets the value of "border-collapse" */
  String get borderCollapse =>
    getPropertyValue('border-collapse');

  /** Sets the value of "border-collapse" */
  void set borderCollapse(String value) {
    setProperty('border-collapse', value, '');
  }

  /** Gets the value of "border-color" */
  String get borderColor =>
    getPropertyValue('border-color');

  /** Sets the value of "border-color" */
  void set borderColor(String value) {
    setProperty('border-color', value, '');
  }

  /** Gets the value of "border-end" */
  String get borderEnd =>
    getPropertyValue('${_browserPrefix}border-end');

  /** Sets the value of "border-end" */
  void set borderEnd(String value) {
    setProperty('${_browserPrefix}border-end', value, '');
  }

  /** Gets the value of "border-end-color" */
  String get borderEndColor =>
    getPropertyValue('${_browserPrefix}border-end-color');

  /** Sets the value of "border-end-color" */
  void set borderEndColor(String value) {
    setProperty('${_browserPrefix}border-end-color', value, '');
  }

  /** Gets the value of "border-end-style" */
  String get borderEndStyle =>
    getPropertyValue('${_browserPrefix}border-end-style');

  /** Sets the value of "border-end-style" */
  void set borderEndStyle(String value) {
    setProperty('${_browserPrefix}border-end-style', value, '');
  }

  /** Gets the value of "border-end-width" */
  String get borderEndWidth =>
    getPropertyValue('${_browserPrefix}border-end-width');

  /** Sets the value of "border-end-width" */
  void set borderEndWidth(String value) {
    setProperty('${_browserPrefix}border-end-width', value, '');
  }

  /** Gets the value of "border-fit" */
  String get borderFit =>
    getPropertyValue('${_browserPrefix}border-fit');

  /** Sets the value of "border-fit" */
  void set borderFit(String value) {
    setProperty('${_browserPrefix}border-fit', value, '');
  }

  /** Gets the value of "border-horizontal-spacing" */
  String get borderHorizontalSpacing =>
    getPropertyValue('${_browserPrefix}border-horizontal-spacing');

  /** Sets the value of "border-horizontal-spacing" */
  void set borderHorizontalSpacing(String value) {
    setProperty('${_browserPrefix}border-horizontal-spacing', value, '');
  }

  /** Gets the value of "border-image" */
  String get borderImage =>
    getPropertyValue('border-image');

  /** Sets the value of "border-image" */
  void set borderImage(String value) {
    setProperty('border-image', value, '');
  }

  /** Gets the value of "border-image-outset" */
  String get borderImageOutset =>
    getPropertyValue('border-image-outset');

  /** Sets the value of "border-image-outset" */
  void set borderImageOutset(String value) {
    setProperty('border-image-outset', value, '');
  }

  /** Gets the value of "border-image-repeat" */
  String get borderImageRepeat =>
    getPropertyValue('border-image-repeat');

  /** Sets the value of "border-image-repeat" */
  void set borderImageRepeat(String value) {
    setProperty('border-image-repeat', value, '');
  }

  /** Gets the value of "border-image-slice" */
  String get borderImageSlice =>
    getPropertyValue('border-image-slice');

  /** Sets the value of "border-image-slice" */
  void set borderImageSlice(String value) {
    setProperty('border-image-slice', value, '');
  }

  /** Gets the value of "border-image-source" */
  String get borderImageSource =>
    getPropertyValue('border-image-source');

  /** Sets the value of "border-image-source" */
  void set borderImageSource(String value) {
    setProperty('border-image-source', value, '');
  }

  /** Gets the value of "border-image-width" */
  String get borderImageWidth =>
    getPropertyValue('border-image-width');

  /** Sets the value of "border-image-width" */
  void set borderImageWidth(String value) {
    setProperty('border-image-width', value, '');
  }

  /** Gets the value of "border-left" */
  String get borderLeft =>
    getPropertyValue('border-left');

  /** Sets the value of "border-left" */
  void set borderLeft(String value) {
    setProperty('border-left', value, '');
  }

  /** Gets the value of "border-left-color" */
  String get borderLeftColor =>
    getPropertyValue('border-left-color');

  /** Sets the value of "border-left-color" */
  void set borderLeftColor(String value) {
    setProperty('border-left-color', value, '');
  }

  /** Gets the value of "border-left-style" */
  String get borderLeftStyle =>
    getPropertyValue('border-left-style');

  /** Sets the value of "border-left-style" */
  void set borderLeftStyle(String value) {
    setProperty('border-left-style', value, '');
  }

  /** Gets the value of "border-left-width" */
  String get borderLeftWidth =>
    getPropertyValue('border-left-width');

  /** Sets the value of "border-left-width" */
  void set borderLeftWidth(String value) {
    setProperty('border-left-width', value, '');
  }

  /** Gets the value of "border-radius" */
  String get borderRadius =>
    getPropertyValue('border-radius');

  /** Sets the value of "border-radius" */
  void set borderRadius(String value) {
    setProperty('border-radius', value, '');
  }

  /** Gets the value of "border-right" */
  String get borderRight =>
    getPropertyValue('border-right');

  /** Sets the value of "border-right" */
  void set borderRight(String value) {
    setProperty('border-right', value, '');
  }

  /** Gets the value of "border-right-color" */
  String get borderRightColor =>
    getPropertyValue('border-right-color');

  /** Sets the value of "border-right-color" */
  void set borderRightColor(String value) {
    setProperty('border-right-color', value, '');
  }

  /** Gets the value of "border-right-style" */
  String get borderRightStyle =>
    getPropertyValue('border-right-style');

  /** Sets the value of "border-right-style" */
  void set borderRightStyle(String value) {
    setProperty('border-right-style', value, '');
  }

  /** Gets the value of "border-right-width" */
  String get borderRightWidth =>
    getPropertyValue('border-right-width');

  /** Sets the value of "border-right-width" */
  void set borderRightWidth(String value) {
    setProperty('border-right-width', value, '');
  }

  /** Gets the value of "border-spacing" */
  String get borderSpacing =>
    getPropertyValue('border-spacing');

  /** Sets the value of "border-spacing" */
  void set borderSpacing(String value) {
    setProperty('border-spacing', value, '');
  }

  /** Gets the value of "border-start" */
  String get borderStart =>
    getPropertyValue('${_browserPrefix}border-start');

  /** Sets the value of "border-start" */
  void set borderStart(String value) {
    setProperty('${_browserPrefix}border-start', value, '');
  }

  /** Gets the value of "border-start-color" */
  String get borderStartColor =>
    getPropertyValue('${_browserPrefix}border-start-color');

  /** Sets the value of "border-start-color" */
  void set borderStartColor(String value) {
    setProperty('${_browserPrefix}border-start-color', value, '');
  }

  /** Gets the value of "border-start-style" */
  String get borderStartStyle =>
    getPropertyValue('${_browserPrefix}border-start-style');

  /** Sets the value of "border-start-style" */
  void set borderStartStyle(String value) {
    setProperty('${_browserPrefix}border-start-style', value, '');
  }

  /** Gets the value of "border-start-width" */
  String get borderStartWidth =>
    getPropertyValue('${_browserPrefix}border-start-width');

  /** Sets the value of "border-start-width" */
  void set borderStartWidth(String value) {
    setProperty('${_browserPrefix}border-start-width', value, '');
  }

  /** Gets the value of "border-style" */
  String get borderStyle =>
    getPropertyValue('border-style');

  /** Sets the value of "border-style" */
  void set borderStyle(String value) {
    setProperty('border-style', value, '');
  }

  /** Gets the value of "border-top" */
  String get borderTop =>
    getPropertyValue('border-top');

  /** Sets the value of "border-top" */
  void set borderTop(String value) {
    setProperty('border-top', value, '');
  }

  /** Gets the value of "border-top-color" */
  String get borderTopColor =>
    getPropertyValue('border-top-color');

  /** Sets the value of "border-top-color" */
  void set borderTopColor(String value) {
    setProperty('border-top-color', value, '');
  }

  /** Gets the value of "border-top-left-radius" */
  String get borderTopLeftRadius =>
    getPropertyValue('border-top-left-radius');

  /** Sets the value of "border-top-left-radius" */
  void set borderTopLeftRadius(String value) {
    setProperty('border-top-left-radius', value, '');
  }

  /** Gets the value of "border-top-right-radius" */
  String get borderTopRightRadius =>
    getPropertyValue('border-top-right-radius');

  /** Sets the value of "border-top-right-radius" */
  void set borderTopRightRadius(String value) {
    setProperty('border-top-right-radius', value, '');
  }

  /** Gets the value of "border-top-style" */
  String get borderTopStyle =>
    getPropertyValue('border-top-style');

  /** Sets the value of "border-top-style" */
  void set borderTopStyle(String value) {
    setProperty('border-top-style', value, '');
  }

  /** Gets the value of "border-top-width" */
  String get borderTopWidth =>
    getPropertyValue('border-top-width');

  /** Sets the value of "border-top-width" */
  void set borderTopWidth(String value) {
    setProperty('border-top-width', value, '');
  }

  /** Gets the value of "border-vertical-spacing" */
  String get borderVerticalSpacing =>
    getPropertyValue('${_browserPrefix}border-vertical-spacing');

  /** Sets the value of "border-vertical-spacing" */
  void set borderVerticalSpacing(String value) {
    setProperty('${_browserPrefix}border-vertical-spacing', value, '');
  }

  /** Gets the value of "border-width" */
  String get borderWidth =>
    getPropertyValue('border-width');

  /** Sets the value of "border-width" */
  void set borderWidth(String value) {
    setProperty('border-width', value, '');
  }

  /** Gets the value of "bottom" */
  String get bottom =>
    getPropertyValue('bottom');

  /** Sets the value of "bottom" */
  void set bottom(String value) {
    setProperty('bottom', value, '');
  }

  /** Gets the value of "box-align" */
  String get boxAlign =>
    getPropertyValue('${_browserPrefix}box-align');

  /** Sets the value of "box-align" */
  void set boxAlign(String value) {
    setProperty('${_browserPrefix}box-align', value, '');
  }

  /** Gets the value of "box-decoration-break" */
  String get boxDecorationBreak =>
    getPropertyValue('${_browserPrefix}box-decoration-break');

  /** Sets the value of "box-decoration-break" */
  void set boxDecorationBreak(String value) {
    setProperty('${_browserPrefix}box-decoration-break', value, '');
  }

  /** Gets the value of "box-direction" */
  String get boxDirection =>
    getPropertyValue('${_browserPrefix}box-direction');

  /** Sets the value of "box-direction" */
  void set boxDirection(String value) {
    setProperty('${_browserPrefix}box-direction', value, '');
  }

  /** Gets the value of "box-flex" */
  String get boxFlex =>
    getPropertyValue('${_browserPrefix}box-flex');

  /** Sets the value of "box-flex" */
  void set boxFlex(String value) {
    setProperty('${_browserPrefix}box-flex', value, '');
  }

  /** Gets the value of "box-flex-group" */
  String get boxFlexGroup =>
    getPropertyValue('${_browserPrefix}box-flex-group');

  /** Sets the value of "box-flex-group" */
  void set boxFlexGroup(String value) {
    setProperty('${_browserPrefix}box-flex-group', value, '');
  }

  /** Gets the value of "box-lines" */
  String get boxLines =>
    getPropertyValue('${_browserPrefix}box-lines');

  /** Sets the value of "box-lines" */
  void set boxLines(String value) {
    setProperty('${_browserPrefix}box-lines', value, '');
  }

  /** Gets the value of "box-ordinal-group" */
  String get boxOrdinalGroup =>
    getPropertyValue('${_browserPrefix}box-ordinal-group');

  /** Sets the value of "box-ordinal-group" */
  void set boxOrdinalGroup(String value) {
    setProperty('${_browserPrefix}box-ordinal-group', value, '');
  }

  /** Gets the value of "box-orient" */
  String get boxOrient =>
    getPropertyValue('${_browserPrefix}box-orient');

  /** Sets the value of "box-orient" */
  void set boxOrient(String value) {
    setProperty('${_browserPrefix}box-orient', value, '');
  }

  /** Gets the value of "box-pack" */
  String get boxPack =>
    getPropertyValue('${_browserPrefix}box-pack');

  /** Sets the value of "box-pack" */
  void set boxPack(String value) {
    setProperty('${_browserPrefix}box-pack', value, '');
  }

  /** Gets the value of "box-reflect" */
  String get boxReflect =>
    getPropertyValue('${_browserPrefix}box-reflect');

  /** Sets the value of "box-reflect" */
  void set boxReflect(String value) {
    setProperty('${_browserPrefix}box-reflect', value, '');
  }

  /** Gets the value of "box-shadow" */
  String get boxShadow =>
    getPropertyValue('box-shadow');

  /** Sets the value of "box-shadow" */
  void set boxShadow(String value) {
    setProperty('box-shadow', value, '');
  }

  /** Gets the value of "box-sizing" */
  String get boxSizing =>
    getPropertyValue('box-sizing');

  /** Sets the value of "box-sizing" */
  void set boxSizing(String value) {
    setProperty('box-sizing', value, '');
  }

  /** Gets the value of "caption-side" */
  String get captionSide =>
    getPropertyValue('caption-side');

  /** Sets the value of "caption-side" */
  void set captionSide(String value) {
    setProperty('caption-side', value, '');
  }

  /** Gets the value of "clear" */
  String get clear =>
    getPropertyValue('clear');

  /** Sets the value of "clear" */
  void set clear(String value) {
    setProperty('clear', value, '');
  }

  /** Gets the value of "clip" */
  String get clip =>
    getPropertyValue('clip');

  /** Sets the value of "clip" */
  void set clip(String value) {
    setProperty('clip', value, '');
  }

  /** Gets the value of "clip-path" */
  String get clipPath =>
    getPropertyValue('${_browserPrefix}clip-path');

  /** Sets the value of "clip-path" */
  void set clipPath(String value) {
    setProperty('${_browserPrefix}clip-path', value, '');
  }

  /** Gets the value of "color" */
  String get color =>
    getPropertyValue('color');

  /** Sets the value of "color" */
  void set color(String value) {
    setProperty('color', value, '');
  }

  /** Gets the value of "color-correction" */
  String get colorCorrection =>
    getPropertyValue('${_browserPrefix}color-correction');

  /** Sets the value of "color-correction" */
  void set colorCorrection(String value) {
    setProperty('${_browserPrefix}color-correction', value, '');
  }

  /** Gets the value of "column-axis" */
  String get columnAxis =>
    getPropertyValue('${_browserPrefix}column-axis');

  /** Sets the value of "column-axis" */
  void set columnAxis(String value) {
    setProperty('${_browserPrefix}column-axis', value, '');
  }

  /** Gets the value of "column-break-after" */
  String get columnBreakAfter =>
    getPropertyValue('${_browserPrefix}column-break-after');

  /** Sets the value of "column-break-after" */
  void set columnBreakAfter(String value) {
    setProperty('${_browserPrefix}column-break-after', value, '');
  }

  /** Gets the value of "column-break-before" */
  String get columnBreakBefore =>
    getPropertyValue('${_browserPrefix}column-break-before');

  /** Sets the value of "column-break-before" */
  void set columnBreakBefore(String value) {
    setProperty('${_browserPrefix}column-break-before', value, '');
  }

  /** Gets the value of "column-break-inside" */
  String get columnBreakInside =>
    getPropertyValue('${_browserPrefix}column-break-inside');

  /** Sets the value of "column-break-inside" */
  void set columnBreakInside(String value) {
    setProperty('${_browserPrefix}column-break-inside', value, '');
  }

  /** Gets the value of "column-count" */
  String get columnCount =>
    getPropertyValue('${_browserPrefix}column-count');

  /** Sets the value of "column-count" */
  void set columnCount(String value) {
    setProperty('${_browserPrefix}column-count', value, '');
  }

  /** Gets the value of "column-gap" */
  String get columnGap =>
    getPropertyValue('${_browserPrefix}column-gap');

  /** Sets the value of "column-gap" */
  void set columnGap(String value) {
    setProperty('${_browserPrefix}column-gap', value, '');
  }

  /** Gets the value of "column-progression" */
  String get columnProgression =>
    getPropertyValue('${_browserPrefix}column-progression');

  /** Sets the value of "column-progression" */
  void set columnProgression(String value) {
    setProperty('${_browserPrefix}column-progression', value, '');
  }

  /** Gets the value of "column-rule" */
  String get columnRule =>
    getPropertyValue('${_browserPrefix}column-rule');

  /** Sets the value of "column-rule" */
  void set columnRule(String value) {
    setProperty('${_browserPrefix}column-rule', value, '');
  }

  /** Gets the value of "column-rule-color" */
  String get columnRuleColor =>
    getPropertyValue('${_browserPrefix}column-rule-color');

  /** Sets the value of "column-rule-color" */
  void set columnRuleColor(String value) {
    setProperty('${_browserPrefix}column-rule-color', value, '');
  }

  /** Gets the value of "column-rule-style" */
  String get columnRuleStyle =>
    getPropertyValue('${_browserPrefix}column-rule-style');

  /** Sets the value of "column-rule-style" */
  void set columnRuleStyle(String value) {
    setProperty('${_browserPrefix}column-rule-style', value, '');
  }

  /** Gets the value of "column-rule-width" */
  String get columnRuleWidth =>
    getPropertyValue('${_browserPrefix}column-rule-width');

  /** Sets the value of "column-rule-width" */
  void set columnRuleWidth(String value) {
    setProperty('${_browserPrefix}column-rule-width', value, '');
  }

  /** Gets the value of "column-span" */
  String get columnSpan =>
    getPropertyValue('${_browserPrefix}column-span');

  /** Sets the value of "column-span" */
  void set columnSpan(String value) {
    setProperty('${_browserPrefix}column-span', value, '');
  }

  /** Gets the value of "column-width" */
  String get columnWidth =>
    getPropertyValue('${_browserPrefix}column-width');

  /** Sets the value of "column-width" */
  void set columnWidth(String value) {
    setProperty('${_browserPrefix}column-width', value, '');
  }

  /** Gets the value of "columns" */
  String get columns =>
    getPropertyValue('${_browserPrefix}columns');

  /** Sets the value of "columns" */
  void set columns(String value) {
    setProperty('${_browserPrefix}columns', value, '');
  }

  /** Gets the value of "content" */
  String get content =>
    getPropertyValue('content');

  /** Sets the value of "content" */
  void set content(String value) {
    setProperty('content', value, '');
  }

  /** Gets the value of "counter-increment" */
  String get counterIncrement =>
    getPropertyValue('counter-increment');

  /** Sets the value of "counter-increment" */
  void set counterIncrement(String value) {
    setProperty('counter-increment', value, '');
  }

  /** Gets the value of "counter-reset" */
  String get counterReset =>
    getPropertyValue('counter-reset');

  /** Sets the value of "counter-reset" */
  void set counterReset(String value) {
    setProperty('counter-reset', value, '');
  }

  /** Gets the value of "cursor" */
  String get cursor =>
    getPropertyValue('cursor');

  /** Sets the value of "cursor" */
  void set cursor(String value) {
    setProperty('cursor', value, '');
  }

  /** Gets the value of "dashboard-region" */
  String get dashboardRegion =>
    getPropertyValue('${_browserPrefix}dashboard-region');

  /** Sets the value of "dashboard-region" */
  void set dashboardRegion(String value) {
    setProperty('${_browserPrefix}dashboard-region', value, '');
  }

  /** Gets the value of "direction" */
  String get direction =>
    getPropertyValue('direction');

  /** Sets the value of "direction" */
  void set direction(String value) {
    setProperty('direction', value, '');
  }

  /** Gets the value of "display" */
  String get display =>
    getPropertyValue('display');

  /** Sets the value of "display" */
  void set display(String value) {
    setProperty('display', value, '');
  }

  /** Gets the value of "empty-cells" */
  String get emptyCells =>
    getPropertyValue('empty-cells');

  /** Sets the value of "empty-cells" */
  void set emptyCells(String value) {
    setProperty('empty-cells', value, '');
  }

  /** Gets the value of "filter" */
  String get filter =>
    getPropertyValue('${_browserPrefix}filter');

  /** Sets the value of "filter" */
  void set filter(String value) {
    setProperty('${_browserPrefix}filter', value, '');
  }

  /** Gets the value of "flex" */
  String get flex =>
    getPropertyValue('${_browserPrefix}flex');

  /** Sets the value of "flex" */
  void set flex(String value) {
    setProperty('${_browserPrefix}flex', value, '');
  }

  /** Gets the value of "flex-basis" */
  String get flexBasis =>
    getPropertyValue('${_browserPrefix}flex-basis');

  /** Sets the value of "flex-basis" */
  void set flexBasis(String value) {
    setProperty('${_browserPrefix}flex-basis', value, '');
  }

  /** Gets the value of "flex-direction" */
  String get flexDirection =>
    getPropertyValue('${_browserPrefix}flex-direction');

  /** Sets the value of "flex-direction" */
  void set flexDirection(String value) {
    setProperty('${_browserPrefix}flex-direction', value, '');
  }

  /** Gets the value of "flex-flow" */
  String get flexFlow =>
    getPropertyValue('${_browserPrefix}flex-flow');

  /** Sets the value of "flex-flow" */
  void set flexFlow(String value) {
    setProperty('${_browserPrefix}flex-flow', value, '');
  }

  /** Gets the value of "flex-grow" */
  String get flexGrow =>
    getPropertyValue('${_browserPrefix}flex-grow');

  /** Sets the value of "flex-grow" */
  void set flexGrow(String value) {
    setProperty('${_browserPrefix}flex-grow', value, '');
  }

  /** Gets the value of "flex-shrink" */
  String get flexShrink =>
    getPropertyValue('${_browserPrefix}flex-shrink');

  /** Sets the value of "flex-shrink" */
  void set flexShrink(String value) {
    setProperty('${_browserPrefix}flex-shrink', value, '');
  }

  /** Gets the value of "flex-wrap" */
  String get flexWrap =>
    getPropertyValue('${_browserPrefix}flex-wrap');

  /** Sets the value of "flex-wrap" */
  void set flexWrap(String value) {
    setProperty('${_browserPrefix}flex-wrap', value, '');
  }

  /** Gets the value of "float" */
  String get float =>
    getPropertyValue('float');

  /** Sets the value of "float" */
  void set float(String value) {
    setProperty('float', value, '');
  }

  /** Gets the value of "flow-from" */
  String get flowFrom =>
    getPropertyValue('${_browserPrefix}flow-from');

  /** Sets the value of "flow-from" */
  void set flowFrom(String value) {
    setProperty('${_browserPrefix}flow-from', value, '');
  }

  /** Gets the value of "flow-into" */
  String get flowInto =>
    getPropertyValue('${_browserPrefix}flow-into');

  /** Sets the value of "flow-into" */
  void set flowInto(String value) {
    setProperty('${_browserPrefix}flow-into', value, '');
  }

  /** Gets the value of "font" */
  String get font =>
    getPropertyValue('font');

  /** Sets the value of "font" */
  void set font(String value) {
    setProperty('font', value, '');
  }

  /** Gets the value of "font-family" */
  String get fontFamily =>
    getPropertyValue('font-family');

  /** Sets the value of "font-family" */
  void set fontFamily(String value) {
    setProperty('font-family', value, '');
  }

  /** Gets the value of "font-feature-settings" */
  String get fontFeatureSettings =>
    getPropertyValue('${_browserPrefix}font-feature-settings');

  /** Sets the value of "font-feature-settings" */
  void set fontFeatureSettings(String value) {
    setProperty('${_browserPrefix}font-feature-settings', value, '');
  }

  /** Gets the value of "font-kerning" */
  String get fontKerning =>
    getPropertyValue('${_browserPrefix}font-kerning');

  /** Sets the value of "font-kerning" */
  void set fontKerning(String value) {
    setProperty('${_browserPrefix}font-kerning', value, '');
  }

  /** Gets the value of "font-size" */
  String get fontSize =>
    getPropertyValue('font-size');

  /** Sets the value of "font-size" */
  void set fontSize(String value) {
    setProperty('font-size', value, '');
  }

  /** Gets the value of "font-size-delta" */
  String get fontSizeDelta =>
    getPropertyValue('${_browserPrefix}font-size-delta');

  /** Sets the value of "font-size-delta" */
  void set fontSizeDelta(String value) {
    setProperty('${_browserPrefix}font-size-delta', value, '');
  }

  /** Gets the value of "font-smoothing" */
  String get fontSmoothing =>
    getPropertyValue('${_browserPrefix}font-smoothing');

  /** Sets the value of "font-smoothing" */
  void set fontSmoothing(String value) {
    setProperty('${_browserPrefix}font-smoothing', value, '');
  }

  /** Gets the value of "font-stretch" */
  String get fontStretch =>
    getPropertyValue('font-stretch');

  /** Sets the value of "font-stretch" */
  void set fontStretch(String value) {
    setProperty('font-stretch', value, '');
  }

  /** Gets the value of "font-style" */
  String get fontStyle =>
    getPropertyValue('font-style');

  /** Sets the value of "font-style" */
  void set fontStyle(String value) {
    setProperty('font-style', value, '');
  }

  /** Gets the value of "font-variant" */
  String get fontVariant =>
    getPropertyValue('font-variant');

  /** Sets the value of "font-variant" */
  void set fontVariant(String value) {
    setProperty('font-variant', value, '');
  }

  /** Gets the value of "font-variant-ligatures" */
  String get fontVariantLigatures =>
    getPropertyValue('${_browserPrefix}font-variant-ligatures');

  /** Sets the value of "font-variant-ligatures" */
  void set fontVariantLigatures(String value) {
    setProperty('${_browserPrefix}font-variant-ligatures', value, '');
  }

  /** Gets the value of "font-weight" */
  String get fontWeight =>
    getPropertyValue('font-weight');

  /** Sets the value of "font-weight" */
  void set fontWeight(String value) {
    setProperty('font-weight', value, '');
  }

  /** Gets the value of "grid-column" */
  String get gridColumn =>
    getPropertyValue('${_browserPrefix}grid-column');

  /** Sets the value of "grid-column" */
  void set gridColumn(String value) {
    setProperty('${_browserPrefix}grid-column', value, '');
  }

  /** Gets the value of "grid-columns" */
  String get gridColumns =>
    getPropertyValue('${_browserPrefix}grid-columns');

  /** Sets the value of "grid-columns" */
  void set gridColumns(String value) {
    setProperty('${_browserPrefix}grid-columns', value, '');
  }

  /** Gets the value of "grid-row" */
  String get gridRow =>
    getPropertyValue('${_browserPrefix}grid-row');

  /** Sets the value of "grid-row" */
  void set gridRow(String value) {
    setProperty('${_browserPrefix}grid-row', value, '');
  }

  /** Gets the value of "grid-rows" */
  String get gridRows =>
    getPropertyValue('${_browserPrefix}grid-rows');

  /** Sets the value of "grid-rows" */
  void set gridRows(String value) {
    setProperty('${_browserPrefix}grid-rows', value, '');
  }

  /** Gets the value of "height" */
  String get height =>
    getPropertyValue('height');

  /** Sets the value of "height" */
  void set height(String value) {
    setProperty('height', value, '');
  }

  /** Gets the value of "highlight" */
  String get highlight =>
    getPropertyValue('${_browserPrefix}highlight');

  /** Sets the value of "highlight" */
  void set highlight(String value) {
    setProperty('${_browserPrefix}highlight', value, '');
  }

  /** Gets the value of "hyphenate-character" */
  String get hyphenateCharacter =>
    getPropertyValue('${_browserPrefix}hyphenate-character');

  /** Sets the value of "hyphenate-character" */
  void set hyphenateCharacter(String value) {
    setProperty('${_browserPrefix}hyphenate-character', value, '');
  }

  /** Gets the value of "hyphenate-limit-after" */
  String get hyphenateLimitAfter =>
    getPropertyValue('${_browserPrefix}hyphenate-limit-after');

  /** Sets the value of "hyphenate-limit-after" */
  void set hyphenateLimitAfter(String value) {
    setProperty('${_browserPrefix}hyphenate-limit-after', value, '');
  }

  /** Gets the value of "hyphenate-limit-before" */
  String get hyphenateLimitBefore =>
    getPropertyValue('${_browserPrefix}hyphenate-limit-before');

  /** Sets the value of "hyphenate-limit-before" */
  void set hyphenateLimitBefore(String value) {
    setProperty('${_browserPrefix}hyphenate-limit-before', value, '');
  }

  /** Gets the value of "hyphenate-limit-lines" */
  String get hyphenateLimitLines =>
    getPropertyValue('${_browserPrefix}hyphenate-limit-lines');

  /** Sets the value of "hyphenate-limit-lines" */
  void set hyphenateLimitLines(String value) {
    setProperty('${_browserPrefix}hyphenate-limit-lines', value, '');
  }

  /** Gets the value of "hyphens" */
  String get hyphens =>
    getPropertyValue('${_browserPrefix}hyphens');

  /** Sets the value of "hyphens" */
  void set hyphens(String value) {
    setProperty('${_browserPrefix}hyphens', value, '');
  }

  /** Gets the value of "image-orientation" */
  String get imageOrientation =>
    getPropertyValue('image-orientation');

  /** Sets the value of "image-orientation" */
  void set imageOrientation(String value) {
    setProperty('image-orientation', value, '');
  }

  /** Gets the value of "image-rendering" */
  String get imageRendering =>
    getPropertyValue('image-rendering');

  /** Sets the value of "image-rendering" */
  void set imageRendering(String value) {
    setProperty('image-rendering', value, '');
  }

  /** Gets the value of "image-resolution" */
  String get imageResolution =>
    getPropertyValue('image-resolution');

  /** Sets the value of "image-resolution" */
  void set imageResolution(String value) {
    setProperty('image-resolution', value, '');
  }

  /** Gets the value of "justify-content" */
  String get justifyContent =>
    getPropertyValue('${_browserPrefix}justify-content');

  /** Sets the value of "justify-content" */
  void set justifyContent(String value) {
    setProperty('${_browserPrefix}justify-content', value, '');
  }

  /** Gets the value of "left" */
  String get left =>
    getPropertyValue('left');

  /** Sets the value of "left" */
  void set left(String value) {
    setProperty('left', value, '');
  }

  /** Gets the value of "letter-spacing" */
  String get letterSpacing =>
    getPropertyValue('letter-spacing');

  /** Sets the value of "letter-spacing" */
  void set letterSpacing(String value) {
    setProperty('letter-spacing', value, '');
  }

  /** Gets the value of "line-align" */
  String get lineAlign =>
    getPropertyValue('${_browserPrefix}line-align');

  /** Sets the value of "line-align" */
  void set lineAlign(String value) {
    setProperty('${_browserPrefix}line-align', value, '');
  }

  /** Gets the value of "line-box-contain" */
  String get lineBoxContain =>
    getPropertyValue('${_browserPrefix}line-box-contain');

  /** Sets the value of "line-box-contain" */
  void set lineBoxContain(String value) {
    setProperty('${_browserPrefix}line-box-contain', value, '');
  }

  /** Gets the value of "line-break" */
  String get lineBreak =>
    getPropertyValue('${_browserPrefix}line-break');

  /** Sets the value of "line-break" */
  void set lineBreak(String value) {
    setProperty('${_browserPrefix}line-break', value, '');
  }

  /** Gets the value of "line-clamp" */
  String get lineClamp =>
    getPropertyValue('${_browserPrefix}line-clamp');

  /** Sets the value of "line-clamp" */
  void set lineClamp(String value) {
    setProperty('${_browserPrefix}line-clamp', value, '');
  }

  /** Gets the value of "line-grid" */
  String get lineGrid =>
    getPropertyValue('${_browserPrefix}line-grid');

  /** Sets the value of "line-grid" */
  void set lineGrid(String value) {
    setProperty('${_browserPrefix}line-grid', value, '');
  }

  /** Gets the value of "line-height" */
  String get lineHeight =>
    getPropertyValue('line-height');

  /** Sets the value of "line-height" */
  void set lineHeight(String value) {
    setProperty('line-height', value, '');
  }

  /** Gets the value of "line-snap" */
  String get lineSnap =>
    getPropertyValue('${_browserPrefix}line-snap');

  /** Sets the value of "line-snap" */
  void set lineSnap(String value) {
    setProperty('${_browserPrefix}line-snap', value, '');
  }

  /** Gets the value of "list-style" */
  String get listStyle =>
    getPropertyValue('list-style');

  /** Sets the value of "list-style" */
  void set listStyle(String value) {
    setProperty('list-style', value, '');
  }

  /** Gets the value of "list-style-image" */
  String get listStyleImage =>
    getPropertyValue('list-style-image');

  /** Sets the value of "list-style-image" */
  void set listStyleImage(String value) {
    setProperty('list-style-image', value, '');
  }

  /** Gets the value of "list-style-position" */
  String get listStylePosition =>
    getPropertyValue('list-style-position');

  /** Sets the value of "list-style-position" */
  void set listStylePosition(String value) {
    setProperty('list-style-position', value, '');
  }

  /** Gets the value of "list-style-type" */
  String get listStyleType =>
    getPropertyValue('list-style-type');

  /** Sets the value of "list-style-type" */
  void set listStyleType(String value) {
    setProperty('list-style-type', value, '');
  }

  /** Gets the value of "locale" */
  String get locale =>
    getPropertyValue('${_browserPrefix}locale');

  /** Sets the value of "locale" */
  void set locale(String value) {
    setProperty('${_browserPrefix}locale', value, '');
  }

  /** Gets the value of "logical-height" */
  String get logicalHeight =>
    getPropertyValue('${_browserPrefix}logical-height');

  /** Sets the value of "logical-height" */
  void set logicalHeight(String value) {
    setProperty('${_browserPrefix}logical-height', value, '');
  }

  /** Gets the value of "logical-width" */
  String get logicalWidth =>
    getPropertyValue('${_browserPrefix}logical-width');

  /** Sets the value of "logical-width" */
  void set logicalWidth(String value) {
    setProperty('${_browserPrefix}logical-width', value, '');
  }

  /** Gets the value of "margin" */
  String get margin =>
    getPropertyValue('margin');

  /** Sets the value of "margin" */
  void set margin(String value) {
    setProperty('margin', value, '');
  }

  /** Gets the value of "margin-after" */
  String get marginAfter =>
    getPropertyValue('${_browserPrefix}margin-after');

  /** Sets the value of "margin-after" */
  void set marginAfter(String value) {
    setProperty('${_browserPrefix}margin-after', value, '');
  }

  /** Gets the value of "margin-after-collapse" */
  String get marginAfterCollapse =>
    getPropertyValue('${_browserPrefix}margin-after-collapse');

  /** Sets the value of "margin-after-collapse" */
  void set marginAfterCollapse(String value) {
    setProperty('${_browserPrefix}margin-after-collapse', value, '');
  }

  /** Gets the value of "margin-before" */
  String get marginBefore =>
    getPropertyValue('${_browserPrefix}margin-before');

  /** Sets the value of "margin-before" */
  void set marginBefore(String value) {
    setProperty('${_browserPrefix}margin-before', value, '');
  }

  /** Gets the value of "margin-before-collapse" */
  String get marginBeforeCollapse =>
    getPropertyValue('${_browserPrefix}margin-before-collapse');

  /** Sets the value of "margin-before-collapse" */
  void set marginBeforeCollapse(String value) {
    setProperty('${_browserPrefix}margin-before-collapse', value, '');
  }

  /** Gets the value of "margin-bottom" */
  String get marginBottom =>
    getPropertyValue('margin-bottom');

  /** Sets the value of "margin-bottom" */
  void set marginBottom(String value) {
    setProperty('margin-bottom', value, '');
  }

  /** Gets the value of "margin-bottom-collapse" */
  String get marginBottomCollapse =>
    getPropertyValue('${_browserPrefix}margin-bottom-collapse');

  /** Sets the value of "margin-bottom-collapse" */
  void set marginBottomCollapse(String value) {
    setProperty('${_browserPrefix}margin-bottom-collapse', value, '');
  }

  /** Gets the value of "margin-collapse" */
  String get marginCollapse =>
    getPropertyValue('${_browserPrefix}margin-collapse');

  /** Sets the value of "margin-collapse" */
  void set marginCollapse(String value) {
    setProperty('${_browserPrefix}margin-collapse', value, '');
  }

  /** Gets the value of "margin-end" */
  String get marginEnd =>
    getPropertyValue('${_browserPrefix}margin-end');

  /** Sets the value of "margin-end" */
  void set marginEnd(String value) {
    setProperty('${_browserPrefix}margin-end', value, '');
  }

  /** Gets the value of "margin-left" */
  String get marginLeft =>
    getPropertyValue('margin-left');

  /** Sets the value of "margin-left" */
  void set marginLeft(String value) {
    setProperty('margin-left', value, '');
  }

  /** Gets the value of "margin-right" */
  String get marginRight =>
    getPropertyValue('margin-right');

  /** Sets the value of "margin-right" */
  void set marginRight(String value) {
    setProperty('margin-right', value, '');
  }

  /** Gets the value of "margin-start" */
  String get marginStart =>
    getPropertyValue('${_browserPrefix}margin-start');

  /** Sets the value of "margin-start" */
  void set marginStart(String value) {
    setProperty('${_browserPrefix}margin-start', value, '');
  }

  /** Gets the value of "margin-top" */
  String get marginTop =>
    getPropertyValue('margin-top');

  /** Sets the value of "margin-top" */
  void set marginTop(String value) {
    setProperty('margin-top', value, '');
  }

  /** Gets the value of "margin-top-collapse" */
  String get marginTopCollapse =>
    getPropertyValue('${_browserPrefix}margin-top-collapse');

  /** Sets the value of "margin-top-collapse" */
  void set marginTopCollapse(String value) {
    setProperty('${_browserPrefix}margin-top-collapse', value, '');
  }

  /** Gets the value of "marquee" */
  String get marquee =>
    getPropertyValue('${_browserPrefix}marquee');

  /** Sets the value of "marquee" */
  void set marquee(String value) {
    setProperty('${_browserPrefix}marquee', value, '');
  }

  /** Gets the value of "marquee-direction" */
  String get marqueeDirection =>
    getPropertyValue('${_browserPrefix}marquee-direction');

  /** Sets the value of "marquee-direction" */
  void set marqueeDirection(String value) {
    setProperty('${_browserPrefix}marquee-direction', value, '');
  }

  /** Gets the value of "marquee-increment" */
  String get marqueeIncrement =>
    getPropertyValue('${_browserPrefix}marquee-increment');

  /** Sets the value of "marquee-increment" */
  void set marqueeIncrement(String value) {
    setProperty('${_browserPrefix}marquee-increment', value, '');
  }

  /** Gets the value of "marquee-repetition" */
  String get marqueeRepetition =>
    getPropertyValue('${_browserPrefix}marquee-repetition');

  /** Sets the value of "marquee-repetition" */
  void set marqueeRepetition(String value) {
    setProperty('${_browserPrefix}marquee-repetition', value, '');
  }

  /** Gets the value of "marquee-speed" */
  String get marqueeSpeed =>
    getPropertyValue('${_browserPrefix}marquee-speed');

  /** Sets the value of "marquee-speed" */
  void set marqueeSpeed(String value) {
    setProperty('${_browserPrefix}marquee-speed', value, '');
  }

  /** Gets the value of "marquee-style" */
  String get marqueeStyle =>
    getPropertyValue('${_browserPrefix}marquee-style');

  /** Sets the value of "marquee-style" */
  void set marqueeStyle(String value) {
    setProperty('${_browserPrefix}marquee-style', value, '');
  }

  /** Gets the value of "mask" */
  String get mask =>
    getPropertyValue('${_browserPrefix}mask');

  /** Sets the value of "mask" */
  void set mask(String value) {
    setProperty('${_browserPrefix}mask', value, '');
  }

  /** Gets the value of "mask-attachment" */
  String get maskAttachment =>
    getPropertyValue('${_browserPrefix}mask-attachment');

  /** Sets the value of "mask-attachment" */
  void set maskAttachment(String value) {
    setProperty('${_browserPrefix}mask-attachment', value, '');
  }

  /** Gets the value of "mask-box-image" */
  String get maskBoxImage =>
    getPropertyValue('${_browserPrefix}mask-box-image');

  /** Sets the value of "mask-box-image" */
  void set maskBoxImage(String value) {
    setProperty('${_browserPrefix}mask-box-image', value, '');
  }

  /** Gets the value of "mask-box-image-outset" */
  String get maskBoxImageOutset =>
    getPropertyValue('${_browserPrefix}mask-box-image-outset');

  /** Sets the value of "mask-box-image-outset" */
  void set maskBoxImageOutset(String value) {
    setProperty('${_browserPrefix}mask-box-image-outset', value, '');
  }

  /** Gets the value of "mask-box-image-repeat" */
  String get maskBoxImageRepeat =>
    getPropertyValue('${_browserPrefix}mask-box-image-repeat');

  /** Sets the value of "mask-box-image-repeat" */
  void set maskBoxImageRepeat(String value) {
    setProperty('${_browserPrefix}mask-box-image-repeat', value, '');
  }

  /** Gets the value of "mask-box-image-slice" */
  String get maskBoxImageSlice =>
    getPropertyValue('${_browserPrefix}mask-box-image-slice');

  /** Sets the value of "mask-box-image-slice" */
  void set maskBoxImageSlice(String value) {
    setProperty('${_browserPrefix}mask-box-image-slice', value, '');
  }

  /** Gets the value of "mask-box-image-source" */
  String get maskBoxImageSource =>
    getPropertyValue('${_browserPrefix}mask-box-image-source');

  /** Sets the value of "mask-box-image-source" */
  void set maskBoxImageSource(String value) {
    setProperty('${_browserPrefix}mask-box-image-source', value, '');
  }

  /** Gets the value of "mask-box-image-width" */
  String get maskBoxImageWidth =>
    getPropertyValue('${_browserPrefix}mask-box-image-width');

  /** Sets the value of "mask-box-image-width" */
  void set maskBoxImageWidth(String value) {
    setProperty('${_browserPrefix}mask-box-image-width', value, '');
  }

  /** Gets the value of "mask-clip" */
  String get maskClip =>
    getPropertyValue('${_browserPrefix}mask-clip');

  /** Sets the value of "mask-clip" */
  void set maskClip(String value) {
    setProperty('${_browserPrefix}mask-clip', value, '');
  }

  /** Gets the value of "mask-composite" */
  String get maskComposite =>
    getPropertyValue('${_browserPrefix}mask-composite');

  /** Sets the value of "mask-composite" */
  void set maskComposite(String value) {
    setProperty('${_browserPrefix}mask-composite', value, '');
  }

  /** Gets the value of "mask-image" */
  String get maskImage =>
    getPropertyValue('${_browserPrefix}mask-image');

  /** Sets the value of "mask-image" */
  void set maskImage(String value) {
    setProperty('${_browserPrefix}mask-image', value, '');
  }

  /** Gets the value of "mask-origin" */
  String get maskOrigin =>
    getPropertyValue('${_browserPrefix}mask-origin');

  /** Sets the value of "mask-origin" */
  void set maskOrigin(String value) {
    setProperty('${_browserPrefix}mask-origin', value, '');
  }

  /** Gets the value of "mask-position" */
  String get maskPosition =>
    getPropertyValue('${_browserPrefix}mask-position');

  /** Sets the value of "mask-position" */
  void set maskPosition(String value) {
    setProperty('${_browserPrefix}mask-position', value, '');
  }

  /** Gets the value of "mask-position-x" */
  String get maskPositionX =>
    getPropertyValue('${_browserPrefix}mask-position-x');

  /** Sets the value of "mask-position-x" */
  void set maskPositionX(String value) {
    setProperty('${_browserPrefix}mask-position-x', value, '');
  }

  /** Gets the value of "mask-position-y" */
  String get maskPositionY =>
    getPropertyValue('${_browserPrefix}mask-position-y');

  /** Sets the value of "mask-position-y" */
  void set maskPositionY(String value) {
    setProperty('${_browserPrefix}mask-position-y', value, '');
  }

  /** Gets the value of "mask-repeat" */
  String get maskRepeat =>
    getPropertyValue('${_browserPrefix}mask-repeat');

  /** Sets the value of "mask-repeat" */
  void set maskRepeat(String value) {
    setProperty('${_browserPrefix}mask-repeat', value, '');
  }

  /** Gets the value of "mask-repeat-x" */
  String get maskRepeatX =>
    getPropertyValue('${_browserPrefix}mask-repeat-x');

  /** Sets the value of "mask-repeat-x" */
  void set maskRepeatX(String value) {
    setProperty('${_browserPrefix}mask-repeat-x', value, '');
  }

  /** Gets the value of "mask-repeat-y" */
  String get maskRepeatY =>
    getPropertyValue('${_browserPrefix}mask-repeat-y');

  /** Sets the value of "mask-repeat-y" */
  void set maskRepeatY(String value) {
    setProperty('${_browserPrefix}mask-repeat-y', value, '');
  }

  /** Gets the value of "mask-size" */
  String get maskSize =>
    getPropertyValue('${_browserPrefix}mask-size');

  /** Sets the value of "mask-size" */
  void set maskSize(String value) {
    setProperty('${_browserPrefix}mask-size', value, '');
  }

  /** Gets the value of "max-height" */
  String get maxHeight =>
    getPropertyValue('max-height');

  /** Sets the value of "max-height" */
  void set maxHeight(String value) {
    setProperty('max-height', value, '');
  }

  /** Gets the value of "max-logical-height" */
  String get maxLogicalHeight =>
    getPropertyValue('${_browserPrefix}max-logical-height');

  /** Sets the value of "max-logical-height" */
  void set maxLogicalHeight(String value) {
    setProperty('${_browserPrefix}max-logical-height', value, '');
  }

  /** Gets the value of "max-logical-width" */
  String get maxLogicalWidth =>
    getPropertyValue('${_browserPrefix}max-logical-width');

  /** Sets the value of "max-logical-width" */
  void set maxLogicalWidth(String value) {
    setProperty('${_browserPrefix}max-logical-width', value, '');
  }

  /** Gets the value of "max-width" */
  String get maxWidth =>
    getPropertyValue('max-width');

  /** Sets the value of "max-width" */
  void set maxWidth(String value) {
    setProperty('max-width', value, '');
  }

  /** Gets the value of "max-zoom" */
  String get maxZoom =>
    getPropertyValue('max-zoom');

  /** Sets the value of "max-zoom" */
  void set maxZoom(String value) {
    setProperty('max-zoom', value, '');
  }

  /** Gets the value of "min-height" */
  String get minHeight =>
    getPropertyValue('min-height');

  /** Sets the value of "min-height" */
  void set minHeight(String value) {
    setProperty('min-height', value, '');
  }

  /** Gets the value of "min-logical-height" */
  String get minLogicalHeight =>
    getPropertyValue('${_browserPrefix}min-logical-height');

  /** Sets the value of "min-logical-height" */
  void set minLogicalHeight(String value) {
    setProperty('${_browserPrefix}min-logical-height', value, '');
  }

  /** Gets the value of "min-logical-width" */
  String get minLogicalWidth =>
    getPropertyValue('${_browserPrefix}min-logical-width');

  /** Sets the value of "min-logical-width" */
  void set minLogicalWidth(String value) {
    setProperty('${_browserPrefix}min-logical-width', value, '');
  }

  /** Gets the value of "min-width" */
  String get minWidth =>
    getPropertyValue('min-width');

  /** Sets the value of "min-width" */
  void set minWidth(String value) {
    setProperty('min-width', value, '');
  }

  /** Gets the value of "min-zoom" */
  String get minZoom =>
    getPropertyValue('min-zoom');

  /** Sets the value of "min-zoom" */
  void set minZoom(String value) {
    setProperty('min-zoom', value, '');
  }

  /** Gets the value of "nbsp-mode" */
  String get nbspMode =>
    getPropertyValue('${_browserPrefix}nbsp-mode');

  /** Sets the value of "nbsp-mode" */
  void set nbspMode(String value) {
    setProperty('${_browserPrefix}nbsp-mode', value, '');
  }

  /** Gets the value of "opacity" */
  String get opacity =>
    getPropertyValue('opacity');

  /** Sets the value of "opacity" */
  void set opacity(String value) {
    setProperty('opacity', value, '');
  }

  /** Gets the value of "order" */
  String get order =>
    getPropertyValue('${_browserPrefix}order');

  /** Sets the value of "order" */
  void set order(String value) {
    setProperty('${_browserPrefix}order', value, '');
  }

  /** Gets the value of "orientation" */
  String get orientation =>
    getPropertyValue('orientation');

  /** Sets the value of "orientation" */
  void set orientation(String value) {
    setProperty('orientation', value, '');
  }

  /** Gets the value of "orphans" */
  String get orphans =>
    getPropertyValue('orphans');

  /** Sets the value of "orphans" */
  void set orphans(String value) {
    setProperty('orphans', value, '');
  }

  /** Gets the value of "outline" */
  String get outline =>
    getPropertyValue('outline');

  /** Sets the value of "outline" */
  void set outline(String value) {
    setProperty('outline', value, '');
  }

  /** Gets the value of "outline-color" */
  String get outlineColor =>
    getPropertyValue('outline-color');

  /** Sets the value of "outline-color" */
  void set outlineColor(String value) {
    setProperty('outline-color', value, '');
  }

  /** Gets the value of "outline-offset" */
  String get outlineOffset =>
    getPropertyValue('outline-offset');

  /** Sets the value of "outline-offset" */
  void set outlineOffset(String value) {
    setProperty('outline-offset', value, '');
  }

  /** Gets the value of "outline-style" */
  String get outlineStyle =>
    getPropertyValue('outline-style');

  /** Sets the value of "outline-style" */
  void set outlineStyle(String value) {
    setProperty('outline-style', value, '');
  }

  /** Gets the value of "outline-width" */
  String get outlineWidth =>
    getPropertyValue('outline-width');

  /** Sets the value of "outline-width" */
  void set outlineWidth(String value) {
    setProperty('outline-width', value, '');
  }

  /** Gets the value of "overflow" */
  String get overflow =>
    getPropertyValue('overflow');

  /** Sets the value of "overflow" */
  void set overflow(String value) {
    setProperty('overflow', value, '');
  }

  /** Gets the value of "overflow-scrolling" */
  String get overflowScrolling =>
    getPropertyValue('${_browserPrefix}overflow-scrolling');

  /** Sets the value of "overflow-scrolling" */
  void set overflowScrolling(String value) {
    setProperty('${_browserPrefix}overflow-scrolling', value, '');
  }

  /** Gets the value of "overflow-wrap" */
  String get overflowWrap =>
    getPropertyValue('overflow-wrap');

  /** Sets the value of "overflow-wrap" */
  void set overflowWrap(String value) {
    setProperty('overflow-wrap', value, '');
  }

  /** Gets the value of "overflow-x" */
  String get overflowX =>
    getPropertyValue('overflow-x');

  /** Sets the value of "overflow-x" */
  void set overflowX(String value) {
    setProperty('overflow-x', value, '');
  }

  /** Gets the value of "overflow-y" */
  String get overflowY =>
    getPropertyValue('overflow-y');

  /** Sets the value of "overflow-y" */
  void set overflowY(String value) {
    setProperty('overflow-y', value, '');
  }

  /** Gets the value of "padding" */
  String get padding =>
    getPropertyValue('padding');

  /** Sets the value of "padding" */
  void set padding(String value) {
    setProperty('padding', value, '');
  }

  /** Gets the value of "padding-after" */
  String get paddingAfter =>
    getPropertyValue('${_browserPrefix}padding-after');

  /** Sets the value of "padding-after" */
  void set paddingAfter(String value) {
    setProperty('${_browserPrefix}padding-after', value, '');
  }

  /** Gets the value of "padding-before" */
  String get paddingBefore =>
    getPropertyValue('${_browserPrefix}padding-before');

  /** Sets the value of "padding-before" */
  void set paddingBefore(String value) {
    setProperty('${_browserPrefix}padding-before', value, '');
  }

  /** Gets the value of "padding-bottom" */
  String get paddingBottom =>
    getPropertyValue('padding-bottom');

  /** Sets the value of "padding-bottom" */
  void set paddingBottom(String value) {
    setProperty('padding-bottom', value, '');
  }

  /** Gets the value of "padding-end" */
  String get paddingEnd =>
    getPropertyValue('${_browserPrefix}padding-end');

  /** Sets the value of "padding-end" */
  void set paddingEnd(String value) {
    setProperty('${_browserPrefix}padding-end', value, '');
  }

  /** Gets the value of "padding-left" */
  String get paddingLeft =>
    getPropertyValue('padding-left');

  /** Sets the value of "padding-left" */
  void set paddingLeft(String value) {
    setProperty('padding-left', value, '');
  }

  /** Gets the value of "padding-right" */
  String get paddingRight =>
    getPropertyValue('padding-right');

  /** Sets the value of "padding-right" */
  void set paddingRight(String value) {
    setProperty('padding-right', value, '');
  }

  /** Gets the value of "padding-start" */
  String get paddingStart =>
    getPropertyValue('${_browserPrefix}padding-start');

  /** Sets the value of "padding-start" */
  void set paddingStart(String value) {
    setProperty('${_browserPrefix}padding-start', value, '');
  }

  /** Gets the value of "padding-top" */
  String get paddingTop =>
    getPropertyValue('padding-top');

  /** Sets the value of "padding-top" */
  void set paddingTop(String value) {
    setProperty('padding-top', value, '');
  }

  /** Gets the value of "page" */
  String get page =>
    getPropertyValue('page');

  /** Sets the value of "page" */
  void set page(String value) {
    setProperty('page', value, '');
  }

  /** Gets the value of "page-break-after" */
  String get pageBreakAfter =>
    getPropertyValue('page-break-after');

  /** Sets the value of "page-break-after" */
  void set pageBreakAfter(String value) {
    setProperty('page-break-after', value, '');
  }

  /** Gets the value of "page-break-before" */
  String get pageBreakBefore =>
    getPropertyValue('page-break-before');

  /** Sets the value of "page-break-before" */
  void set pageBreakBefore(String value) {
    setProperty('page-break-before', value, '');
  }

  /** Gets the value of "page-break-inside" */
  String get pageBreakInside =>
    getPropertyValue('page-break-inside');

  /** Sets the value of "page-break-inside" */
  void set pageBreakInside(String value) {
    setProperty('page-break-inside', value, '');
  }

  /** Gets the value of "perspective" */
  String get perspective =>
    getPropertyValue('${_browserPrefix}perspective');

  /** Sets the value of "perspective" */
  void set perspective(String value) {
    setProperty('${_browserPrefix}perspective', value, '');
  }

  /** Gets the value of "perspective-origin" */
  String get perspectiveOrigin =>
    getPropertyValue('${_browserPrefix}perspective-origin');

  /** Sets the value of "perspective-origin" */
  void set perspectiveOrigin(String value) {
    setProperty('${_browserPrefix}perspective-origin', value, '');
  }

  /** Gets the value of "perspective-origin-x" */
  String get perspectiveOriginX =>
    getPropertyValue('${_browserPrefix}perspective-origin-x');

  /** Sets the value of "perspective-origin-x" */
  void set perspectiveOriginX(String value) {
    setProperty('${_browserPrefix}perspective-origin-x', value, '');
  }

  /** Gets the value of "perspective-origin-y" */
  String get perspectiveOriginY =>
    getPropertyValue('${_browserPrefix}perspective-origin-y');

  /** Sets the value of "perspective-origin-y" */
  void set perspectiveOriginY(String value) {
    setProperty('${_browserPrefix}perspective-origin-y', value, '');
  }

  /** Gets the value of "pointer-events" */
  String get pointerEvents =>
    getPropertyValue('pointer-events');

  /** Sets the value of "pointer-events" */
  void set pointerEvents(String value) {
    setProperty('pointer-events', value, '');
  }

  /** Gets the value of "position" */
  String get position =>
    getPropertyValue('position');

  /** Sets the value of "position" */
  void set position(String value) {
    setProperty('position', value, '');
  }

  /** Gets the value of "print-color-adjust" */
  String get printColorAdjust =>
    getPropertyValue('${_browserPrefix}print-color-adjust');

  /** Sets the value of "print-color-adjust" */
  void set printColorAdjust(String value) {
    setProperty('${_browserPrefix}print-color-adjust', value, '');
  }

  /** Gets the value of "quotes" */
  String get quotes =>
    getPropertyValue('quotes');

  /** Sets the value of "quotes" */
  void set quotes(String value) {
    setProperty('quotes', value, '');
  }

  /** Gets the value of "region-break-after" */
  String get regionBreakAfter =>
    getPropertyValue('${_browserPrefix}region-break-after');

  /** Sets the value of "region-break-after" */
  void set regionBreakAfter(String value) {
    setProperty('${_browserPrefix}region-break-after', value, '');
  }

  /** Gets the value of "region-break-before" */
  String get regionBreakBefore =>
    getPropertyValue('${_browserPrefix}region-break-before');

  /** Sets the value of "region-break-before" */
  void set regionBreakBefore(String value) {
    setProperty('${_browserPrefix}region-break-before', value, '');
  }

  /** Gets the value of "region-break-inside" */
  String get regionBreakInside =>
    getPropertyValue('${_browserPrefix}region-break-inside');

  /** Sets the value of "region-break-inside" */
  void set regionBreakInside(String value) {
    setProperty('${_browserPrefix}region-break-inside', value, '');
  }

  /** Gets the value of "region-overflow" */
  String get regionOverflow =>
    getPropertyValue('${_browserPrefix}region-overflow');

  /** Sets the value of "region-overflow" */
  void set regionOverflow(String value) {
    setProperty('${_browserPrefix}region-overflow', value, '');
  }

  /** Gets the value of "resize" */
  String get resize =>
    getPropertyValue('resize');

  /** Sets the value of "resize" */
  void set resize(String value) {
    setProperty('resize', value, '');
  }

  /** Gets the value of "right" */
  String get right =>
    getPropertyValue('right');

  /** Sets the value of "right" */
  void set right(String value) {
    setProperty('right', value, '');
  }

  /** Gets the value of "rtl-ordering" */
  String get rtlOrdering =>
    getPropertyValue('${_browserPrefix}rtl-ordering');

  /** Sets the value of "rtl-ordering" */
  void set rtlOrdering(String value) {
    setProperty('${_browserPrefix}rtl-ordering', value, '');
  }

  /** Gets the value of "shape-inside" */
  String get shapeInside =>
    getPropertyValue('${_browserPrefix}shape-inside');

  /** Sets the value of "shape-inside" */
  void set shapeInside(String value) {
    setProperty('${_browserPrefix}shape-inside', value, '');
  }

  /** Gets the value of "shape-margin" */
  String get shapeMargin =>
    getPropertyValue('${_browserPrefix}shape-margin');

  /** Sets the value of "shape-margin" */
  void set shapeMargin(String value) {
    setProperty('${_browserPrefix}shape-margin', value, '');
  }

  /** Gets the value of "shape-outside" */
  String get shapeOutside =>
    getPropertyValue('${_browserPrefix}shape-outside');

  /** Sets the value of "shape-outside" */
  void set shapeOutside(String value) {
    setProperty('${_browserPrefix}shape-outside', value, '');
  }

  /** Gets the value of "shape-padding" */
  String get shapePadding =>
    getPropertyValue('${_browserPrefix}shape-padding');

  /** Sets the value of "shape-padding" */
  void set shapePadding(String value) {
    setProperty('${_browserPrefix}shape-padding', value, '');
  }

  /** Gets the value of "size" */
  String get size =>
    getPropertyValue('size');

  /** Sets the value of "size" */
  void set size(String value) {
    setProperty('size', value, '');
  }

  /** Gets the value of "speak" */
  String get speak =>
    getPropertyValue('speak');

  /** Sets the value of "speak" */
  void set speak(String value) {
    setProperty('speak', value, '');
  }

  /** Gets the value of "src" */
  String get src =>
    getPropertyValue('src');

  /** Sets the value of "src" */
  void set src(String value) {
    setProperty('src', value, '');
  }

  /** Gets the value of "tab-size" */
  String get tabSize =>
    getPropertyValue('tab-size');

  /** Sets the value of "tab-size" */
  void set tabSize(String value) {
    setProperty('tab-size', value, '');
  }

  /** Gets the value of "table-layout" */
  String get tableLayout =>
    getPropertyValue('table-layout');

  /** Sets the value of "table-layout" */
  void set tableLayout(String value) {
    setProperty('table-layout', value, '');
  }

  /** Gets the value of "tap-highlight-color" */
  String get tapHighlightColor =>
    getPropertyValue('${_browserPrefix}tap-highlight-color');

  /** Sets the value of "tap-highlight-color" */
  void set tapHighlightColor(String value) {
    setProperty('${_browserPrefix}tap-highlight-color', value, '');
  }

  /** Gets the value of "text-align" */
  String get textAlign =>
    getPropertyValue('text-align');

  /** Sets the value of "text-align" */
  void set textAlign(String value) {
    setProperty('text-align', value, '');
  }

  /** Gets the value of "text-align-last" */
  String get textAlignLast =>
    getPropertyValue('${_browserPrefix}text-align-last');

  /** Sets the value of "text-align-last" */
  void set textAlignLast(String value) {
    setProperty('${_browserPrefix}text-align-last', value, '');
  }

  /** Gets the value of "text-combine" */
  String get textCombine =>
    getPropertyValue('${_browserPrefix}text-combine');

  /** Sets the value of "text-combine" */
  void set textCombine(String value) {
    setProperty('${_browserPrefix}text-combine', value, '');
  }

  /** Gets the value of "text-decoration" */
  String get textDecoration =>
    getPropertyValue('text-decoration');

  /** Sets the value of "text-decoration" */
  void set textDecoration(String value) {
    setProperty('text-decoration', value, '');
  }

  /** Gets the value of "text-decoration-line" */
  String get textDecorationLine =>
    getPropertyValue('${_browserPrefix}text-decoration-line');

  /** Sets the value of "text-decoration-line" */
  void set textDecorationLine(String value) {
    setProperty('${_browserPrefix}text-decoration-line', value, '');
  }

  /** Gets the value of "text-decoration-style" */
  String get textDecorationStyle =>
    getPropertyValue('${_browserPrefix}text-decoration-style');

  /** Sets the value of "text-decoration-style" */
  void set textDecorationStyle(String value) {
    setProperty('${_browserPrefix}text-decoration-style', value, '');
  }

  /** Gets the value of "text-decorations-in-effect" */
  String get textDecorationsInEffect =>
    getPropertyValue('${_browserPrefix}text-decorations-in-effect');

  /** Sets the value of "text-decorations-in-effect" */
  void set textDecorationsInEffect(String value) {
    setProperty('${_browserPrefix}text-decorations-in-effect', value, '');
  }

  /** Gets the value of "text-emphasis" */
  String get textEmphasis =>
    getPropertyValue('${_browserPrefix}text-emphasis');

  /** Sets the value of "text-emphasis" */
  void set textEmphasis(String value) {
    setProperty('${_browserPrefix}text-emphasis', value, '');
  }

  /** Gets the value of "text-emphasis-color" */
  String get textEmphasisColor =>
    getPropertyValue('${_browserPrefix}text-emphasis-color');

  /** Sets the value of "text-emphasis-color" */
  void set textEmphasisColor(String value) {
    setProperty('${_browserPrefix}text-emphasis-color', value, '');
  }

  /** Gets the value of "text-emphasis-position" */
  String get textEmphasisPosition =>
    getPropertyValue('${_browserPrefix}text-emphasis-position');

  /** Sets the value of "text-emphasis-position" */
  void set textEmphasisPosition(String value) {
    setProperty('${_browserPrefix}text-emphasis-position', value, '');
  }

  /** Gets the value of "text-emphasis-style" */
  String get textEmphasisStyle =>
    getPropertyValue('${_browserPrefix}text-emphasis-style');

  /** Sets the value of "text-emphasis-style" */
  void set textEmphasisStyle(String value) {
    setProperty('${_browserPrefix}text-emphasis-style', value, '');
  }

  /** Gets the value of "text-fill-color" */
  String get textFillColor =>
    getPropertyValue('${_browserPrefix}text-fill-color');

  /** Sets the value of "text-fill-color" */
  void set textFillColor(String value) {
    setProperty('${_browserPrefix}text-fill-color', value, '');
  }

  /** Gets the value of "text-indent" */
  String get textIndent =>
    getPropertyValue('text-indent');

  /** Sets the value of "text-indent" */
  void set textIndent(String value) {
    setProperty('text-indent', value, '');
  }

  /** Gets the value of "text-line-through" */
  String get textLineThrough =>
    getPropertyValue('text-line-through');

  /** Sets the value of "text-line-through" */
  void set textLineThrough(String value) {
    setProperty('text-line-through', value, '');
  }

  /** Gets the value of "text-line-through-color" */
  String get textLineThroughColor =>
    getPropertyValue('text-line-through-color');

  /** Sets the value of "text-line-through-color" */
  void set textLineThroughColor(String value) {
    setProperty('text-line-through-color', value, '');
  }

  /** Gets the value of "text-line-through-mode" */
  String get textLineThroughMode =>
    getPropertyValue('text-line-through-mode');

  /** Sets the value of "text-line-through-mode" */
  void set textLineThroughMode(String value) {
    setProperty('text-line-through-mode', value, '');
  }

  /** Gets the value of "text-line-through-style" */
  String get textLineThroughStyle =>
    getPropertyValue('text-line-through-style');

  /** Sets the value of "text-line-through-style" */
  void set textLineThroughStyle(String value) {
    setProperty('text-line-through-style', value, '');
  }

  /** Gets the value of "text-line-through-width" */
  String get textLineThroughWidth =>
    getPropertyValue('text-line-through-width');

  /** Sets the value of "text-line-through-width" */
  void set textLineThroughWidth(String value) {
    setProperty('text-line-through-width', value, '');
  }

  /** Gets the value of "text-orientation" */
  String get textOrientation =>
    getPropertyValue('${_browserPrefix}text-orientation');

  /** Sets the value of "text-orientation" */
  void set textOrientation(String value) {
    setProperty('${_browserPrefix}text-orientation', value, '');
  }

  /** Gets the value of "text-overflow" */
  String get textOverflow =>
    getPropertyValue('text-overflow');

  /** Sets the value of "text-overflow" */
  void set textOverflow(String value) {
    setProperty('text-overflow', value, '');
  }

  /** Gets the value of "text-overline" */
  String get textOverline =>
    getPropertyValue('text-overline');

  /** Sets the value of "text-overline" */
  void set textOverline(String value) {
    setProperty('text-overline', value, '');
  }

  /** Gets the value of "text-overline-color" */
  String get textOverlineColor =>
    getPropertyValue('text-overline-color');

  /** Sets the value of "text-overline-color" */
  void set textOverlineColor(String value) {
    setProperty('text-overline-color', value, '');
  }

  /** Gets the value of "text-overline-mode" */
  String get textOverlineMode =>
    getPropertyValue('text-overline-mode');

  /** Sets the value of "text-overline-mode" */
  void set textOverlineMode(String value) {
    setProperty('text-overline-mode', value, '');
  }

  /** Gets the value of "text-overline-style" */
  String get textOverlineStyle =>
    getPropertyValue('text-overline-style');

  /** Sets the value of "text-overline-style" */
  void set textOverlineStyle(String value) {
    setProperty('text-overline-style', value, '');
  }

  /** Gets the value of "text-overline-width" */
  String get textOverlineWidth =>
    getPropertyValue('text-overline-width');

  /** Sets the value of "text-overline-width" */
  void set textOverlineWidth(String value) {
    setProperty('text-overline-width', value, '');
  }

  /** Gets the value of "text-rendering" */
  String get textRendering =>
    getPropertyValue('text-rendering');

  /** Sets the value of "text-rendering" */
  void set textRendering(String value) {
    setProperty('text-rendering', value, '');
  }

  /** Gets the value of "text-security" */
  String get textSecurity =>
    getPropertyValue('${_browserPrefix}text-security');

  /** Sets the value of "text-security" */
  void set textSecurity(String value) {
    setProperty('${_browserPrefix}text-security', value, '');
  }

  /** Gets the value of "text-shadow" */
  String get textShadow =>
    getPropertyValue('text-shadow');

  /** Sets the value of "text-shadow" */
  void set textShadow(String value) {
    setProperty('text-shadow', value, '');
  }

  /** Gets the value of "text-size-adjust" */
  String get textSizeAdjust =>
    getPropertyValue('${_browserPrefix}text-size-adjust');

  /** Sets the value of "text-size-adjust" */
  void set textSizeAdjust(String value) {
    setProperty('${_browserPrefix}text-size-adjust', value, '');
  }

  /** Gets the value of "text-stroke" */
  String get textStroke =>
    getPropertyValue('${_browserPrefix}text-stroke');

  /** Sets the value of "text-stroke" */
  void set textStroke(String value) {
    setProperty('${_browserPrefix}text-stroke', value, '');
  }

  /** Gets the value of "text-stroke-color" */
  String get textStrokeColor =>
    getPropertyValue('${_browserPrefix}text-stroke-color');

  /** Sets the value of "text-stroke-color" */
  void set textStrokeColor(String value) {
    setProperty('${_browserPrefix}text-stroke-color', value, '');
  }

  /** Gets the value of "text-stroke-width" */
  String get textStrokeWidth =>
    getPropertyValue('${_browserPrefix}text-stroke-width');

  /** Sets the value of "text-stroke-width" */
  void set textStrokeWidth(String value) {
    setProperty('${_browserPrefix}text-stroke-width', value, '');
  }

  /** Gets the value of "text-transform" */
  String get textTransform =>
    getPropertyValue('text-transform');

  /** Sets the value of "text-transform" */
  void set textTransform(String value) {
    setProperty('text-transform', value, '');
  }

  /** Gets the value of "text-underline" */
  String get textUnderline =>
    getPropertyValue('text-underline');

  /** Sets the value of "text-underline" */
  void set textUnderline(String value) {
    setProperty('text-underline', value, '');
  }

  /** Gets the value of "text-underline-color" */
  String get textUnderlineColor =>
    getPropertyValue('text-underline-color');

  /** Sets the value of "text-underline-color" */
  void set textUnderlineColor(String value) {
    setProperty('text-underline-color', value, '');
  }

  /** Gets the value of "text-underline-mode" */
  String get textUnderlineMode =>
    getPropertyValue('text-underline-mode');

  /** Sets the value of "text-underline-mode" */
  void set textUnderlineMode(String value) {
    setProperty('text-underline-mode', value, '');
  }

  /** Gets the value of "text-underline-style" */
  String get textUnderlineStyle =>
    getPropertyValue('text-underline-style');

  /** Sets the value of "text-underline-style" */
  void set textUnderlineStyle(String value) {
    setProperty('text-underline-style', value, '');
  }

  /** Gets the value of "text-underline-width" */
  String get textUnderlineWidth =>
    getPropertyValue('text-underline-width');

  /** Sets the value of "text-underline-width" */
  void set textUnderlineWidth(String value) {
    setProperty('text-underline-width', value, '');
  }

  /** Gets the value of "top" */
  String get top =>
    getPropertyValue('top');

  /** Sets the value of "top" */
  void set top(String value) {
    setProperty('top', value, '');
  }

  /** Gets the value of "transform" */
  String get transform =>
    getPropertyValue('${_browserPrefix}transform');

  /** Sets the value of "transform" */
  void set transform(String value) {
    setProperty('${_browserPrefix}transform', value, '');
  }

  /** Gets the value of "transform-origin" */
  String get transformOrigin =>
    getPropertyValue('${_browserPrefix}transform-origin');

  /** Sets the value of "transform-origin" */
  void set transformOrigin(String value) {
    setProperty('${_browserPrefix}transform-origin', value, '');
  }

  /** Gets the value of "transform-origin-x" */
  String get transformOriginX =>
    getPropertyValue('${_browserPrefix}transform-origin-x');

  /** Sets the value of "transform-origin-x" */
  void set transformOriginX(String value) {
    setProperty('${_browserPrefix}transform-origin-x', value, '');
  }

  /** Gets the value of "transform-origin-y" */
  String get transformOriginY =>
    getPropertyValue('${_browserPrefix}transform-origin-y');

  /** Sets the value of "transform-origin-y" */
  void set transformOriginY(String value) {
    setProperty('${_browserPrefix}transform-origin-y', value, '');
  }

  /** Gets the value of "transform-origin-z" */
  String get transformOriginZ =>
    getPropertyValue('${_browserPrefix}transform-origin-z');

  /** Sets the value of "transform-origin-z" */
  void set transformOriginZ(String value) {
    setProperty('${_browserPrefix}transform-origin-z', value, '');
  }

  /** Gets the value of "transform-style" */
  String get transformStyle =>
    getPropertyValue('${_browserPrefix}transform-style');

  /** Sets the value of "transform-style" */
  void set transformStyle(String value) {
    setProperty('${_browserPrefix}transform-style', value, '');
  }

  /** Gets the value of "transition" */
  String get transition =>
    getPropertyValue('${_browserPrefix}transition');

  /** Sets the value of "transition" */
  void set transition(String value) {
    setProperty('${_browserPrefix}transition', value, '');
  }

  /** Gets the value of "transition-delay" */
  String get transitionDelay =>
    getPropertyValue('${_browserPrefix}transition-delay');

  /** Sets the value of "transition-delay" */
  void set transitionDelay(String value) {
    setProperty('${_browserPrefix}transition-delay', value, '');
  }

  /** Gets the value of "transition-duration" */
  String get transitionDuration =>
    getPropertyValue('${_browserPrefix}transition-duration');

  /** Sets the value of "transition-duration" */
  void set transitionDuration(String value) {
    setProperty('${_browserPrefix}transition-duration', value, '');
  }

  /** Gets the value of "transition-property" */
  String get transitionProperty =>
    getPropertyValue('${_browserPrefix}transition-property');

  /** Sets the value of "transition-property" */
  void set transitionProperty(String value) {
    setProperty('${_browserPrefix}transition-property', value, '');
  }

  /** Gets the value of "transition-timing-function" */
  String get transitionTimingFunction =>
    getPropertyValue('${_browserPrefix}transition-timing-function');

  /** Sets the value of "transition-timing-function" */
  void set transitionTimingFunction(String value) {
    setProperty('${_browserPrefix}transition-timing-function', value, '');
  }

  /** Gets the value of "unicode-bidi" */
  String get unicodeBidi =>
    getPropertyValue('unicode-bidi');

  /** Sets the value of "unicode-bidi" */
  void set unicodeBidi(String value) {
    setProperty('unicode-bidi', value, '');
  }

  /** Gets the value of "unicode-range" */
  String get unicodeRange =>
    getPropertyValue('unicode-range');

  /** Sets the value of "unicode-range" */
  void set unicodeRange(String value) {
    setProperty('unicode-range', value, '');
  }

  /** Gets the value of "user-drag" */
  String get userDrag =>
    getPropertyValue('${_browserPrefix}user-drag');

  /** Sets the value of "user-drag" */
  void set userDrag(String value) {
    setProperty('${_browserPrefix}user-drag', value, '');
  }

  /** Gets the value of "user-modify" */
  String get userModify =>
    getPropertyValue('${_browserPrefix}user-modify');

  /** Sets the value of "user-modify" */
  void set userModify(String value) {
    setProperty('${_browserPrefix}user-modify', value, '');
  }

  /** Gets the value of "user-select" */
  String get userSelect =>
    getPropertyValue('${_browserPrefix}user-select');

  /** Sets the value of "user-select" */
  void set userSelect(String value) {
    setProperty('${_browserPrefix}user-select', value, '');
  }

  /** Gets the value of "user-zoom" */
  String get userZoom =>
    getPropertyValue('user-zoom');

  /** Sets the value of "user-zoom" */
  void set userZoom(String value) {
    setProperty('user-zoom', value, '');
  }

  /** Gets the value of "vertical-align" */
  String get verticalAlign =>
    getPropertyValue('vertical-align');

  /** Sets the value of "vertical-align" */
  void set verticalAlign(String value) {
    setProperty('vertical-align', value, '');
  }

  /** Gets the value of "visibility" */
  String get visibility =>
    getPropertyValue('visibility');

  /** Sets the value of "visibility" */
  void set visibility(String value) {
    setProperty('visibility', value, '');
  }

  /** Gets the value of "white-space" */
  String get whiteSpace =>
    getPropertyValue('white-space');

  /** Sets the value of "white-space" */
  void set whiteSpace(String value) {
    setProperty('white-space', value, '');
  }

  /** Gets the value of "widows" */
  String get widows =>
    getPropertyValue('widows');

  /** Sets the value of "widows" */
  void set widows(String value) {
    setProperty('widows', value, '');
  }

  /** Gets the value of "width" */
  String get width =>
    getPropertyValue('width');

  /** Sets the value of "width" */
  void set width(String value) {
    setProperty('width', value, '');
  }

  /** Gets the value of "word-break" */
  String get wordBreak =>
    getPropertyValue('word-break');

  /** Sets the value of "word-break" */
  void set wordBreak(String value) {
    setProperty('word-break', value, '');
  }

  /** Gets the value of "word-spacing" */
  String get wordSpacing =>
    getPropertyValue('word-spacing');

  /** Sets the value of "word-spacing" */
  void set wordSpacing(String value) {
    setProperty('word-spacing', value, '');
  }

  /** Gets the value of "word-wrap" */
  String get wordWrap =>
    getPropertyValue('word-wrap');

  /** Sets the value of "word-wrap" */
  void set wordWrap(String value) {
    setProperty('word-wrap', value, '');
  }

  /** Gets the value of "wrap" */
  String get wrap =>
    getPropertyValue('${_browserPrefix}wrap');

  /** Sets the value of "wrap" */
  void set wrap(String value) {
    setProperty('${_browserPrefix}wrap', value, '');
  }

  /** Gets the value of "wrap-flow" */
  String get wrapFlow =>
    getPropertyValue('${_browserPrefix}wrap-flow');

  /** Sets the value of "wrap-flow" */
  void set wrapFlow(String value) {
    setProperty('${_browserPrefix}wrap-flow', value, '');
  }

  /** Gets the value of "wrap-through" */
  String get wrapThrough =>
    getPropertyValue('${_browserPrefix}wrap-through');

  /** Sets the value of "wrap-through" */
  void set wrapThrough(String value) {
    setProperty('${_browserPrefix}wrap-through', value, '');
  }

  /** Gets the value of "writing-mode" */
  String get writingMode =>
    getPropertyValue('${_browserPrefix}writing-mode');

  /** Sets the value of "writing-mode" */
  void set writingMode(String value) {
    setProperty('${_browserPrefix}writing-mode', value, '');
  }

  /** Gets the value of "z-index" */
  String get zIndex =>
    getPropertyValue('z-index');

  /** Sets the value of "z-index" */
  void set zIndex(String value) {
    setProperty('z-index', value, '');
  }

  /** Gets the value of "zoom" */
  String get zoom =>
    getPropertyValue('zoom');

  /** Sets the value of "zoom" */
  void set zoom(String value) {
    setProperty('zoom', value, '');
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName CSSStyleRule
class CSSStyleRule extends CSSRule {
  CSSStyleRule.internal(): super.internal();


  /** @domName CSSStyleRule.selectorText */
  String get selectorText native "CSSStyleRule_selectorText_Getter";


  /** @domName CSSStyleRule.selectorText */
  void set selectorText(String value) native "CSSStyleRule_selectorText_Setter";


  /** @domName CSSStyleRule.style */
  CSSStyleDeclaration get style native "CSSStyleRule_style_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName CSSStyleSheet
class CSSStyleSheet extends StyleSheet {
  CSSStyleSheet.internal(): super.internal();


  /** @domName CSSStyleSheet.cssRules */
  List<CSSRule> get cssRules native "CSSStyleSheet_cssRules_Getter";


  /** @domName CSSStyleSheet.ownerRule */
  CSSRule get ownerRule native "CSSStyleSheet_ownerRule_Getter";


  /** @domName CSSStyleSheet.rules */
  List<CSSRule> get rules native "CSSStyleSheet_rules_Getter";

  int addRule(/*DOMString*/ selector, /*DOMString*/ style, [/*unsigned long*/ index]) {
    if (?index) {
      return _addRule_1(selector, style, index);
    }
    return _addRule_2(selector, style);
  }


  /** @domName CSSStyleSheet.addRule_1 */
  int _addRule_1(selector, style, index) native "CSSStyleSheet_addRule_1_Callback";


  /** @domName CSSStyleSheet.addRule_2 */
  int _addRule_2(selector, style) native "CSSStyleSheet_addRule_2_Callback";


  /** @domName CSSStyleSheet.deleteRule */
  void deleteRule(int index) native "CSSStyleSheet_deleteRule_Callback";


  /** @domName CSSStyleSheet.insertRule */
  int insertRule(String rule, int index) native "CSSStyleSheet_insertRule_Callback";


  /** @domName CSSStyleSheet.removeRule */
  void removeRule(int index) native "CSSStyleSheet_removeRule_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WebKitCSSTransformValue
class CSSTransformValue extends _CSSValueList {
  CSSTransformValue.internal(): super.internal();

  static const int CSS_MATRIX = 11;

  static const int CSS_MATRIX3D = 21;

  static const int CSS_PERSPECTIVE = 20;

  static const int CSS_ROTATE = 4;

  static const int CSS_ROTATE3D = 17;

  static const int CSS_ROTATEX = 14;

  static const int CSS_ROTATEY = 15;

  static const int CSS_ROTATEZ = 16;

  static const int CSS_SCALE = 5;

  static const int CSS_SCALE3D = 19;

  static const int CSS_SCALEX = 6;

  static const int CSS_SCALEY = 7;

  static const int CSS_SCALEZ = 18;

  static const int CSS_SKEW = 8;

  static const int CSS_SKEWX = 9;

  static const int CSS_SKEWY = 10;

  static const int CSS_TRANSLATE = 1;

  static const int CSS_TRANSLATE3D = 13;

  static const int CSS_TRANSLATEX = 2;

  static const int CSS_TRANSLATEY = 3;

  static const int CSS_TRANSLATEZ = 12;


  /** @domName WebKitCSSTransformValue.operationType */
  int get operationType native "WebKitCSSTransformValue_operationType_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName CSSUnknownRule
class CSSUnknownRule extends CSSRule {
  CSSUnknownRule.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName CSSValue
class CSSValue extends NativeFieldWrapperClass1 {
  CSSValue.internal();

  static const int CSS_CUSTOM = 3;

  static const int CSS_INHERIT = 0;

  static const int CSS_PRIMITIVE_VALUE = 1;

  static const int CSS_VALUE_LIST = 2;


  /** @domName CSSValue.cssText */
  String get cssText native "CSSValue_cssText_Getter";


  /** @domName CSSValue.cssText */
  void set cssText(String value) native "CSSValue_cssText_Setter";


  /** @domName CSSValue.cssValueType */
  int get cssValueType native "CSSValue_cssValueType_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class CanvasElement extends _Element_Merged {

  factory CanvasElement({int width, int height}) {
    var e = document.$dom_createElement("canvas");
    if (width != null) e.width = width;
    if (height != null) e.height = height;
    return e;
  }
  CanvasElement.internal(): super.internal();


  /** @domName HTMLCanvasElement.height */
  int get height native "HTMLCanvasElement_height_Getter";


  /** @domName HTMLCanvasElement.height */
  void set height(int value) native "HTMLCanvasElement_height_Setter";


  /** @domName HTMLCanvasElement.width */
  int get width native "HTMLCanvasElement_width_Getter";


  /** @domName HTMLCanvasElement.width */
  void set width(int value) native "HTMLCanvasElement_width_Setter";


  /** @domName HTMLCanvasElement.getContext */
  Object getContext(String contextId) native "HTMLCanvasElement_getContext_Callback";


  /** @domName HTMLCanvasElement.toDataURL */
  String toDataURL(String type, [num quality]) native "HTMLCanvasElement_toDataURL_Callback";


  CanvasRenderingContext2D get context2d => getContext('2d');
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName CanvasGradient
class CanvasGradient extends NativeFieldWrapperClass1 {
  CanvasGradient.internal();


  /** @domName CanvasGradient.addColorStop */
  void addColorStop(num offset, String color) native "CanvasGradient_addColorStop_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName CanvasPattern
class CanvasPattern extends NativeFieldWrapperClass1 {
  CanvasPattern.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName CanvasRenderingContext
class CanvasRenderingContext extends NativeFieldWrapperClass1 {
  CanvasRenderingContext.internal();


  /** @domName CanvasRenderingContext.canvas */
  CanvasElement get canvas native "CanvasRenderingContext_canvas_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class CanvasRenderingContext2D extends CanvasRenderingContext {
  CanvasRenderingContext2D.internal(): super.internal();


  /** @domName CanvasRenderingContext2D.fillStyle */
  dynamic get fillStyle native "CanvasRenderingContext2D_fillStyle_Getter";


  /** @domName CanvasRenderingContext2D.fillStyle */
  void set fillStyle(dynamic value) native "CanvasRenderingContext2D_fillStyle_Setter";


  /** @domName CanvasRenderingContext2D.font */
  String get font native "CanvasRenderingContext2D_font_Getter";


  /** @domName CanvasRenderingContext2D.font */
  void set font(String value) native "CanvasRenderingContext2D_font_Setter";


  /** @domName CanvasRenderingContext2D.globalAlpha */
  num get globalAlpha native "CanvasRenderingContext2D_globalAlpha_Getter";


  /** @domName CanvasRenderingContext2D.globalAlpha */
  void set globalAlpha(num value) native "CanvasRenderingContext2D_globalAlpha_Setter";


  /** @domName CanvasRenderingContext2D.globalCompositeOperation */
  String get globalCompositeOperation native "CanvasRenderingContext2D_globalCompositeOperation_Getter";


  /** @domName CanvasRenderingContext2D.globalCompositeOperation */
  void set globalCompositeOperation(String value) native "CanvasRenderingContext2D_globalCompositeOperation_Setter";


  /** @domName CanvasRenderingContext2D.lineCap */
  String get lineCap native "CanvasRenderingContext2D_lineCap_Getter";


  /** @domName CanvasRenderingContext2D.lineCap */
  void set lineCap(String value) native "CanvasRenderingContext2D_lineCap_Setter";


  /** @domName CanvasRenderingContext2D.lineDashOffset */
  num get lineDashOffset native "CanvasRenderingContext2D_lineDashOffset_Getter";


  /** @domName CanvasRenderingContext2D.lineDashOffset */
  void set lineDashOffset(num value) native "CanvasRenderingContext2D_lineDashOffset_Setter";


  /** @domName CanvasRenderingContext2D.lineJoin */
  String get lineJoin native "CanvasRenderingContext2D_lineJoin_Getter";


  /** @domName CanvasRenderingContext2D.lineJoin */
  void set lineJoin(String value) native "CanvasRenderingContext2D_lineJoin_Setter";


  /** @domName CanvasRenderingContext2D.lineWidth */
  num get lineWidth native "CanvasRenderingContext2D_lineWidth_Getter";


  /** @domName CanvasRenderingContext2D.lineWidth */
  void set lineWidth(num value) native "CanvasRenderingContext2D_lineWidth_Setter";


  /** @domName CanvasRenderingContext2D.miterLimit */
  num get miterLimit native "CanvasRenderingContext2D_miterLimit_Getter";


  /** @domName CanvasRenderingContext2D.miterLimit */
  void set miterLimit(num value) native "CanvasRenderingContext2D_miterLimit_Setter";


  /** @domName CanvasRenderingContext2D.shadowBlur */
  num get shadowBlur native "CanvasRenderingContext2D_shadowBlur_Getter";


  /** @domName CanvasRenderingContext2D.shadowBlur */
  void set shadowBlur(num value) native "CanvasRenderingContext2D_shadowBlur_Setter";


  /** @domName CanvasRenderingContext2D.shadowColor */
  String get shadowColor native "CanvasRenderingContext2D_shadowColor_Getter";


  /** @domName CanvasRenderingContext2D.shadowColor */
  void set shadowColor(String value) native "CanvasRenderingContext2D_shadowColor_Setter";


  /** @domName CanvasRenderingContext2D.shadowOffsetX */
  num get shadowOffsetX native "CanvasRenderingContext2D_shadowOffsetX_Getter";


  /** @domName CanvasRenderingContext2D.shadowOffsetX */
  void set shadowOffsetX(num value) native "CanvasRenderingContext2D_shadowOffsetX_Setter";


  /** @domName CanvasRenderingContext2D.shadowOffsetY */
  num get shadowOffsetY native "CanvasRenderingContext2D_shadowOffsetY_Getter";


  /** @domName CanvasRenderingContext2D.shadowOffsetY */
  void set shadowOffsetY(num value) native "CanvasRenderingContext2D_shadowOffsetY_Setter";


  /** @domName CanvasRenderingContext2D.strokeStyle */
  dynamic get strokeStyle native "CanvasRenderingContext2D_strokeStyle_Getter";


  /** @domName CanvasRenderingContext2D.strokeStyle */
  void set strokeStyle(dynamic value) native "CanvasRenderingContext2D_strokeStyle_Setter";


  /** @domName CanvasRenderingContext2D.textAlign */
  String get textAlign native "CanvasRenderingContext2D_textAlign_Getter";


  /** @domName CanvasRenderingContext2D.textAlign */
  void set textAlign(String value) native "CanvasRenderingContext2D_textAlign_Setter";


  /** @domName CanvasRenderingContext2D.textBaseline */
  String get textBaseline native "CanvasRenderingContext2D_textBaseline_Getter";


  /** @domName CanvasRenderingContext2D.textBaseline */
  void set textBaseline(String value) native "CanvasRenderingContext2D_textBaseline_Setter";


  /** @domName CanvasRenderingContext2D.webkitBackingStorePixelRatio */
  num get webkitBackingStorePixelRatio native "CanvasRenderingContext2D_webkitBackingStorePixelRatio_Getter";


  /** @domName CanvasRenderingContext2D.webkitImageSmoothingEnabled */
  bool get webkitImageSmoothingEnabled native "CanvasRenderingContext2D_webkitImageSmoothingEnabled_Getter";


  /** @domName CanvasRenderingContext2D.webkitImageSmoothingEnabled */
  void set webkitImageSmoothingEnabled(bool value) native "CanvasRenderingContext2D_webkitImageSmoothingEnabled_Setter";


  /** @domName CanvasRenderingContext2D.webkitLineDash */
  List get webkitLineDash native "CanvasRenderingContext2D_webkitLineDash_Getter";


  /** @domName CanvasRenderingContext2D.webkitLineDash */
  void set webkitLineDash(List value) native "CanvasRenderingContext2D_webkitLineDash_Setter";


  /** @domName CanvasRenderingContext2D.webkitLineDashOffset */
  num get webkitLineDashOffset native "CanvasRenderingContext2D_webkitLineDashOffset_Getter";


  /** @domName CanvasRenderingContext2D.webkitLineDashOffset */
  void set webkitLineDashOffset(num value) native "CanvasRenderingContext2D_webkitLineDashOffset_Setter";


  /** @domName CanvasRenderingContext2D.arc */
  void arc(num x, num y, num radius, num startAngle, num endAngle, bool anticlockwise) native "CanvasRenderingContext2D_arc_Callback";


  /** @domName CanvasRenderingContext2D.arcTo */
  void arcTo(num x1, num y1, num x2, num y2, num radius) native "CanvasRenderingContext2D_arcTo_Callback";


  /** @domName CanvasRenderingContext2D.beginPath */
  void beginPath() native "CanvasRenderingContext2D_beginPath_Callback";


  /** @domName CanvasRenderingContext2D.bezierCurveTo */
  void bezierCurveTo(num cp1x, num cp1y, num cp2x, num cp2y, num x, num y) native "CanvasRenderingContext2D_bezierCurveTo_Callback";


  /** @domName CanvasRenderingContext2D.clearRect */
  void clearRect(num x, num y, num width, num height) native "CanvasRenderingContext2D_clearRect_Callback";


  /** @domName CanvasRenderingContext2D.clearShadow */
  void clearShadow() native "CanvasRenderingContext2D_clearShadow_Callback";


  /** @domName CanvasRenderingContext2D.clip */
  void clip() native "CanvasRenderingContext2D_clip_Callback";


  /** @domName CanvasRenderingContext2D.closePath */
  void closePath() native "CanvasRenderingContext2D_closePath_Callback";

  ImageData createImageData(imagedata_OR_sw, [/*float*/ sh]) {
    if ((imagedata_OR_sw is ImageData || imagedata_OR_sw == null) && !?sh) {
      return _createImageData_1(imagedata_OR_sw);
    }
    if ((imagedata_OR_sw is num || imagedata_OR_sw == null) && (sh is num || sh == null)) {
      return _createImageData_2(imagedata_OR_sw, sh);
    }
    throw "Incorrect number or type of arguments";
  }


  /** @domName CanvasRenderingContext2D.createImageData_1 */
  ImageData _createImageData_1(imagedata_OR_sw) native "CanvasRenderingContext2D_createImageData_1_Callback";


  /** @domName CanvasRenderingContext2D.createImageData_2 */
  ImageData _createImageData_2(imagedata_OR_sw, sh) native "CanvasRenderingContext2D_createImageData_2_Callback";


  /** @domName CanvasRenderingContext2D.createLinearGradient */
  CanvasGradient createLinearGradient(num x0, num y0, num x1, num y1) native "CanvasRenderingContext2D_createLinearGradient_Callback";

  CanvasPattern createPattern(canvas_OR_image, /*DOMString*/ repetitionType) {
    if ((canvas_OR_image is CanvasElement || canvas_OR_image == null) && (repetitionType is String || repetitionType == null)) {
      return _createPattern_1(canvas_OR_image, repetitionType);
    }
    if ((canvas_OR_image is ImageElement || canvas_OR_image == null) && (repetitionType is String || repetitionType == null)) {
      return _createPattern_2(canvas_OR_image, repetitionType);
    }
    throw "Incorrect number or type of arguments";
  }


  /** @domName CanvasRenderingContext2D.createPattern_1 */
  CanvasPattern _createPattern_1(canvas_OR_image, repetitionType) native "CanvasRenderingContext2D_createPattern_1_Callback";


  /** @domName CanvasRenderingContext2D.createPattern_2 */
  CanvasPattern _createPattern_2(canvas_OR_image, repetitionType) native "CanvasRenderingContext2D_createPattern_2_Callback";


  /** @domName CanvasRenderingContext2D.createRadialGradient */
  CanvasGradient createRadialGradient(num x0, num y0, num r0, num x1, num y1, num r1) native "CanvasRenderingContext2D_createRadialGradient_Callback";

  void drawImage(canvas_OR_image_OR_video, /*float*/ sx_OR_x, /*float*/ sy_OR_y, [/*float*/ sw_OR_width, /*float*/ height_OR_sh, /*float*/ dx, /*float*/ dy, /*float*/ dw, /*float*/ dh]) {
    if ((canvas_OR_image_OR_video is ImageElement || canvas_OR_image_OR_video == null) && (sx_OR_x is num || sx_OR_x == null) && (sy_OR_y is num || sy_OR_y == null) && !?sw_OR_width && !?height_OR_sh && !?dx && !?dy && !?dw && !?dh) {
      _drawImage_1(canvas_OR_image_OR_video, sx_OR_x, sy_OR_y);
      return;
    }
    if ((canvas_OR_image_OR_video is ImageElement || canvas_OR_image_OR_video == null) && (sx_OR_x is num || sx_OR_x == null) && (sy_OR_y is num || sy_OR_y == null) && (sw_OR_width is num || sw_OR_width == null) && (height_OR_sh is num || height_OR_sh == null) && !?dx && !?dy && !?dw && !?dh) {
      _drawImage_2(canvas_OR_image_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh);
      return;
    }
    if ((canvas_OR_image_OR_video is ImageElement || canvas_OR_image_OR_video == null) && (sx_OR_x is num || sx_OR_x == null) && (sy_OR_y is num || sy_OR_y == null) && (sw_OR_width is num || sw_OR_width == null) && (height_OR_sh is num || height_OR_sh == null) && (dx is num || dx == null) && (dy is num || dy == null) && (dw is num || dw == null) && (dh is num || dh == null)) {
      _drawImage_3(canvas_OR_image_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh);
      return;
    }
    if ((canvas_OR_image_OR_video is CanvasElement || canvas_OR_image_OR_video == null) && (sx_OR_x is num || sx_OR_x == null) && (sy_OR_y is num || sy_OR_y == null) && !?sw_OR_width && !?height_OR_sh && !?dx && !?dy && !?dw && !?dh) {
      _drawImage_4(canvas_OR_image_OR_video, sx_OR_x, sy_OR_y);
      return;
    }
    if ((canvas_OR_image_OR_video is CanvasElement || canvas_OR_image_OR_video == null) && (sx_OR_x is num || sx_OR_x == null) && (sy_OR_y is num || sy_OR_y == null) && (sw_OR_width is num || sw_OR_width == null) && (height_OR_sh is num || height_OR_sh == null) && !?dx && !?dy && !?dw && !?dh) {
      _drawImage_5(canvas_OR_image_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh);
      return;
    }
    if ((canvas_OR_image_OR_video is CanvasElement || canvas_OR_image_OR_video == null) && (sx_OR_x is num || sx_OR_x == null) && (sy_OR_y is num || sy_OR_y == null) && (sw_OR_width is num || sw_OR_width == null) && (height_OR_sh is num || height_OR_sh == null) && (dx is num || dx == null) && (dy is num || dy == null) && (dw is num || dw == null) && (dh is num || dh == null)) {
      _drawImage_6(canvas_OR_image_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh);
      return;
    }
    if ((canvas_OR_image_OR_video is VideoElement || canvas_OR_image_OR_video == null) && (sx_OR_x is num || sx_OR_x == null) && (sy_OR_y is num || sy_OR_y == null) && !?sw_OR_width && !?height_OR_sh && !?dx && !?dy && !?dw && !?dh) {
      _drawImage_7(canvas_OR_image_OR_video, sx_OR_x, sy_OR_y);
      return;
    }
    if ((canvas_OR_image_OR_video is VideoElement || canvas_OR_image_OR_video == null) && (sx_OR_x is num || sx_OR_x == null) && (sy_OR_y is num || sy_OR_y == null) && (sw_OR_width is num || sw_OR_width == null) && (height_OR_sh is num || height_OR_sh == null) && !?dx && !?dy && !?dw && !?dh) {
      _drawImage_8(canvas_OR_image_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh);
      return;
    }
    if ((canvas_OR_image_OR_video is VideoElement || canvas_OR_image_OR_video == null) && (sx_OR_x is num || sx_OR_x == null) && (sy_OR_y is num || sy_OR_y == null) && (sw_OR_width is num || sw_OR_width == null) && (height_OR_sh is num || height_OR_sh == null) && (dx is num || dx == null) && (dy is num || dy == null) && (dw is num || dw == null) && (dh is num || dh == null)) {
      _drawImage_9(canvas_OR_image_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh);
      return;
    }
    throw "Incorrect number or type of arguments";
  }


  /** @domName CanvasRenderingContext2D.drawImage_1 */
  void _drawImage_1(canvas_OR_image_OR_video, sx_OR_x, sy_OR_y) native "CanvasRenderingContext2D_drawImage_1_Callback";


  /** @domName CanvasRenderingContext2D.drawImage_2 */
  void _drawImage_2(canvas_OR_image_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh) native "CanvasRenderingContext2D_drawImage_2_Callback";


  /** @domName CanvasRenderingContext2D.drawImage_3 */
  void _drawImage_3(canvas_OR_image_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh) native "CanvasRenderingContext2D_drawImage_3_Callback";


  /** @domName CanvasRenderingContext2D.drawImage_4 */
  void _drawImage_4(canvas_OR_image_OR_video, sx_OR_x, sy_OR_y) native "CanvasRenderingContext2D_drawImage_4_Callback";


  /** @domName CanvasRenderingContext2D.drawImage_5 */
  void _drawImage_5(canvas_OR_image_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh) native "CanvasRenderingContext2D_drawImage_5_Callback";


  /** @domName CanvasRenderingContext2D.drawImage_6 */
  void _drawImage_6(canvas_OR_image_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh) native "CanvasRenderingContext2D_drawImage_6_Callback";


  /** @domName CanvasRenderingContext2D.drawImage_7 */
  void _drawImage_7(canvas_OR_image_OR_video, sx_OR_x, sy_OR_y) native "CanvasRenderingContext2D_drawImage_7_Callback";


  /** @domName CanvasRenderingContext2D.drawImage_8 */
  void _drawImage_8(canvas_OR_image_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh) native "CanvasRenderingContext2D_drawImage_8_Callback";


  /** @domName CanvasRenderingContext2D.drawImage_9 */
  void _drawImage_9(canvas_OR_image_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh) native "CanvasRenderingContext2D_drawImage_9_Callback";

  void drawImageFromRect(/*HTMLImageElement*/ image, [/*float*/ sx, /*float*/ sy, /*float*/ sw, /*float*/ sh, /*float*/ dx, /*float*/ dy, /*float*/ dw, /*float*/ dh, /*DOMString*/ compositeOperation]) {
    if (?compositeOperation) {
      _drawImageFromRect_1(image, sx, sy, sw, sh, dx, dy, dw, dh, compositeOperation);
      return;
    }
    if (?dh) {
      _drawImageFromRect_2(image, sx, sy, sw, sh, dx, dy, dw, dh);
      return;
    }
    if (?dw) {
      _drawImageFromRect_3(image, sx, sy, sw, sh, dx, dy, dw);
      return;
    }
    if (?dy) {
      _drawImageFromRect_4(image, sx, sy, sw, sh, dx, dy);
      return;
    }
    if (?dx) {
      _drawImageFromRect_5(image, sx, sy, sw, sh, dx);
      return;
    }
    if (?sh) {
      _drawImageFromRect_6(image, sx, sy, sw, sh);
      return;
    }
    if (?sw) {
      _drawImageFromRect_7(image, sx, sy, sw);
      return;
    }
    if (?sy) {
      _drawImageFromRect_8(image, sx, sy);
      return;
    }
    if (?sx) {
      _drawImageFromRect_9(image, sx);
      return;
    }
    _drawImageFromRect_10(image);
  }


  /** @domName CanvasRenderingContext2D.drawImageFromRect_1 */
  void _drawImageFromRect_1(image, sx, sy, sw, sh, dx, dy, dw, dh, compositeOperation) native "CanvasRenderingContext2D_drawImageFromRect_1_Callback";


  /** @domName CanvasRenderingContext2D.drawImageFromRect_2 */
  void _drawImageFromRect_2(image, sx, sy, sw, sh, dx, dy, dw, dh) native "CanvasRenderingContext2D_drawImageFromRect_2_Callback";


  /** @domName CanvasRenderingContext2D.drawImageFromRect_3 */
  void _drawImageFromRect_3(image, sx, sy, sw, sh, dx, dy, dw) native "CanvasRenderingContext2D_drawImageFromRect_3_Callback";


  /** @domName CanvasRenderingContext2D.drawImageFromRect_4 */
  void _drawImageFromRect_4(image, sx, sy, sw, sh, dx, dy) native "CanvasRenderingContext2D_drawImageFromRect_4_Callback";


  /** @domName CanvasRenderingContext2D.drawImageFromRect_5 */
  void _drawImageFromRect_5(image, sx, sy, sw, sh, dx) native "CanvasRenderingContext2D_drawImageFromRect_5_Callback";


  /** @domName CanvasRenderingContext2D.drawImageFromRect_6 */
  void _drawImageFromRect_6(image, sx, sy, sw, sh) native "CanvasRenderingContext2D_drawImageFromRect_6_Callback";


  /** @domName CanvasRenderingContext2D.drawImageFromRect_7 */
  void _drawImageFromRect_7(image, sx, sy, sw) native "CanvasRenderingContext2D_drawImageFromRect_7_Callback";


  /** @domName CanvasRenderingContext2D.drawImageFromRect_8 */
  void _drawImageFromRect_8(image, sx, sy) native "CanvasRenderingContext2D_drawImageFromRect_8_Callback";


  /** @domName CanvasRenderingContext2D.drawImageFromRect_9 */
  void _drawImageFromRect_9(image, sx) native "CanvasRenderingContext2D_drawImageFromRect_9_Callback";


  /** @domName CanvasRenderingContext2D.drawImageFromRect_10 */
  void _drawImageFromRect_10(image) native "CanvasRenderingContext2D_drawImageFromRect_10_Callback";


  /** @domName CanvasRenderingContext2D.fill */
  void fill() native "CanvasRenderingContext2D_fill_Callback";


  /** @domName CanvasRenderingContext2D.fillRect */
  void fillRect(num x, num y, num width, num height) native "CanvasRenderingContext2D_fillRect_Callback";

  void fillText(/*DOMString*/ text, /*float*/ x, /*float*/ y, [/*float*/ maxWidth]) {
    if (?maxWidth) {
      _fillText_1(text, x, y, maxWidth);
      return;
    }
    _fillText_2(text, x, y);
  }


  /** @domName CanvasRenderingContext2D.fillText_1 */
  void _fillText_1(text, x, y, maxWidth) native "CanvasRenderingContext2D_fillText_1_Callback";


  /** @domName CanvasRenderingContext2D.fillText_2 */
  void _fillText_2(text, x, y) native "CanvasRenderingContext2D_fillText_2_Callback";


  /** @domName CanvasRenderingContext2D.getImageData */
  ImageData getImageData(num sx, num sy, num sw, num sh) native "CanvasRenderingContext2D_getImageData_Callback";


  /** @domName CanvasRenderingContext2D.getLineDash */
  List<num> getLineDash() native "CanvasRenderingContext2D_getLineDash_Callback";


  /** @domName CanvasRenderingContext2D.isPointInPath */
  bool isPointInPath(num x, num y) native "CanvasRenderingContext2D_isPointInPath_Callback";


  /** @domName CanvasRenderingContext2D.lineTo */
  void lineTo(num x, num y) native "CanvasRenderingContext2D_lineTo_Callback";


  /** @domName CanvasRenderingContext2D.measureText */
  TextMetrics measureText(String text) native "CanvasRenderingContext2D_measureText_Callback";


  /** @domName CanvasRenderingContext2D.moveTo */
  void moveTo(num x, num y) native "CanvasRenderingContext2D_moveTo_Callback";

  void putImageData(/*ImageData*/ imagedata, /*float*/ dx, /*float*/ dy, [/*float*/ dirtyX, /*float*/ dirtyY, /*float*/ dirtyWidth, /*float*/ dirtyHeight]) {
    if ((imagedata is ImageData || imagedata == null) && (dx is num || dx == null) && (dy is num || dy == null) && !?dirtyX && !?dirtyY && !?dirtyWidth && !?dirtyHeight) {
      _putImageData_1(imagedata, dx, dy);
      return;
    }
    if ((imagedata is ImageData || imagedata == null) && (dx is num || dx == null) && (dy is num || dy == null) && (dirtyX is num || dirtyX == null) && (dirtyY is num || dirtyY == null) && (dirtyWidth is num || dirtyWidth == null) && (dirtyHeight is num || dirtyHeight == null)) {
      _putImageData_2(imagedata, dx, dy, dirtyX, dirtyY, dirtyWidth, dirtyHeight);
      return;
    }
    throw "Incorrect number or type of arguments";
  }


  /** @domName CanvasRenderingContext2D.putImageData_1 */
  void _putImageData_1(imagedata, dx, dy) native "CanvasRenderingContext2D_putImageData_1_Callback";


  /** @domName CanvasRenderingContext2D.putImageData_2 */
  void _putImageData_2(imagedata, dx, dy, dirtyX, dirtyY, dirtyWidth, dirtyHeight) native "CanvasRenderingContext2D_putImageData_2_Callback";


  /** @domName CanvasRenderingContext2D.quadraticCurveTo */
  void quadraticCurveTo(num cpx, num cpy, num x, num y) native "CanvasRenderingContext2D_quadraticCurveTo_Callback";


  /** @domName CanvasRenderingContext2D.rect */
  void rect(num x, num y, num width, num height) native "CanvasRenderingContext2D_rect_Callback";


  /** @domName CanvasRenderingContext2D.restore */
  void restore() native "CanvasRenderingContext2D_restore_Callback";


  /** @domName CanvasRenderingContext2D.rotate */
  void rotate(num angle) native "CanvasRenderingContext2D_rotate_Callback";


  /** @domName CanvasRenderingContext2D.save */
  void save() native "CanvasRenderingContext2D_save_Callback";


  /** @domName CanvasRenderingContext2D.scale */
  void scale(num sx, num sy) native "CanvasRenderingContext2D_scale_Callback";


  /** @domName CanvasRenderingContext2D.setAlpha */
  void setAlpha(num alpha) native "CanvasRenderingContext2D_setAlpha_Callback";


  /** @domName CanvasRenderingContext2D.setCompositeOperation */
  void setCompositeOperation(String compositeOperation) native "CanvasRenderingContext2D_setCompositeOperation_Callback";


  /** @domName CanvasRenderingContext2D.setLineCap */
  void setLineCap(String cap) native "CanvasRenderingContext2D_setLineCap_Callback";


  /** @domName CanvasRenderingContext2D.setLineDash */
  void setLineDash(List<num> dash) native "CanvasRenderingContext2D_setLineDash_Callback";


  /** @domName CanvasRenderingContext2D.setLineJoin */
  void setLineJoin(String join) native "CanvasRenderingContext2D_setLineJoin_Callback";


  /** @domName CanvasRenderingContext2D.setLineWidth */
  void setLineWidth(num width) native "CanvasRenderingContext2D_setLineWidth_Callback";


  /** @domName CanvasRenderingContext2D.setMiterLimit */
  void setMiterLimit(num limit) native "CanvasRenderingContext2D_setMiterLimit_Callback";

  void setShadow(/*float*/ width, /*float*/ height, /*float*/ blur, [c_OR_color_OR_grayLevel_OR_r, /*float*/ alpha_OR_g_OR_m, /*float*/ b_OR_y, /*float*/ a_OR_k, /*float*/ a]) {
    if ((width is num || width == null) && (height is num || height == null) && (blur is num || blur == null) && !?c_OR_color_OR_grayLevel_OR_r && !?alpha_OR_g_OR_m && !?b_OR_y && !?a_OR_k && !?a) {
      _setShadow_1(width, height, blur);
      return;
    }
    if ((width is num || width == null) && (height is num || height == null) && (blur is num || blur == null) && (c_OR_color_OR_grayLevel_OR_r is String || c_OR_color_OR_grayLevel_OR_r == null) && !?alpha_OR_g_OR_m && !?b_OR_y && !?a_OR_k && !?a) {
      _setShadow_2(width, height, blur, c_OR_color_OR_grayLevel_OR_r);
      return;
    }
    if ((width is num || width == null) && (height is num || height == null) && (blur is num || blur == null) && (c_OR_color_OR_grayLevel_OR_r is String || c_OR_color_OR_grayLevel_OR_r == null) && (alpha_OR_g_OR_m is num || alpha_OR_g_OR_m == null) && !?b_OR_y && !?a_OR_k && !?a) {
      _setShadow_3(width, height, blur, c_OR_color_OR_grayLevel_OR_r, alpha_OR_g_OR_m);
      return;
    }
    if ((width is num || width == null) && (height is num || height == null) && (blur is num || blur == null) && (c_OR_color_OR_grayLevel_OR_r is num || c_OR_color_OR_grayLevel_OR_r == null) && !?alpha_OR_g_OR_m && !?b_OR_y && !?a_OR_k && !?a) {
      _setShadow_4(width, height, blur, c_OR_color_OR_grayLevel_OR_r);
      return;
    }
    if ((width is num || width == null) && (height is num || height == null) && (blur is num || blur == null) && (c_OR_color_OR_grayLevel_OR_r is num || c_OR_color_OR_grayLevel_OR_r == null) && (alpha_OR_g_OR_m is num || alpha_OR_g_OR_m == null) && !?b_OR_y && !?a_OR_k && !?a) {
      _setShadow_5(width, height, blur, c_OR_color_OR_grayLevel_OR_r, alpha_OR_g_OR_m);
      return;
    }
    if ((width is num || width == null) && (height is num || height == null) && (blur is num || blur == null) && (c_OR_color_OR_grayLevel_OR_r is num || c_OR_color_OR_grayLevel_OR_r == null) && (alpha_OR_g_OR_m is num || alpha_OR_g_OR_m == null) && (b_OR_y is num || b_OR_y == null) && (a_OR_k is num || a_OR_k == null) && !?a) {
      _setShadow_6(width, height, blur, c_OR_color_OR_grayLevel_OR_r, alpha_OR_g_OR_m, b_OR_y, a_OR_k);
      return;
    }
    if ((width is num || width == null) && (height is num || height == null) && (blur is num || blur == null) && (c_OR_color_OR_grayLevel_OR_r is num || c_OR_color_OR_grayLevel_OR_r == null) && (alpha_OR_g_OR_m is num || alpha_OR_g_OR_m == null) && (b_OR_y is num || b_OR_y == null) && (a_OR_k is num || a_OR_k == null) && (a is num || a == null)) {
      _setShadow_7(width, height, blur, c_OR_color_OR_grayLevel_OR_r, alpha_OR_g_OR_m, b_OR_y, a_OR_k, a);
      return;
    }
    throw "Incorrect number or type of arguments";
  }


  /** @domName CanvasRenderingContext2D.setShadow_1 */
  void _setShadow_1(width, height, blur) native "CanvasRenderingContext2D_setShadow_1_Callback";


  /** @domName CanvasRenderingContext2D.setShadow_2 */
  void _setShadow_2(width, height, blur, c_OR_color_OR_grayLevel_OR_r) native "CanvasRenderingContext2D_setShadow_2_Callback";


  /** @domName CanvasRenderingContext2D.setShadow_3 */
  void _setShadow_3(width, height, blur, c_OR_color_OR_grayLevel_OR_r, alpha_OR_g_OR_m) native "CanvasRenderingContext2D_setShadow_3_Callback";


  /** @domName CanvasRenderingContext2D.setShadow_4 */
  void _setShadow_4(width, height, blur, c_OR_color_OR_grayLevel_OR_r) native "CanvasRenderingContext2D_setShadow_4_Callback";


  /** @domName CanvasRenderingContext2D.setShadow_5 */
  void _setShadow_5(width, height, blur, c_OR_color_OR_grayLevel_OR_r, alpha_OR_g_OR_m) native "CanvasRenderingContext2D_setShadow_5_Callback";


  /** @domName CanvasRenderingContext2D.setShadow_6 */
  void _setShadow_6(width, height, blur, c_OR_color_OR_grayLevel_OR_r, alpha_OR_g_OR_m, b_OR_y, a_OR_k) native "CanvasRenderingContext2D_setShadow_6_Callback";


  /** @domName CanvasRenderingContext2D.setShadow_7 */
  void _setShadow_7(width, height, blur, c_OR_color_OR_grayLevel_OR_r, alpha_OR_g_OR_m, b_OR_y, a_OR_k, a) native "CanvasRenderingContext2D_setShadow_7_Callback";


  /** @domName CanvasRenderingContext2D.setTransform */
  void setTransform(num m11, num m12, num m21, num m22, num dx, num dy) native "CanvasRenderingContext2D_setTransform_Callback";


  /** @domName CanvasRenderingContext2D.stroke */
  void stroke() native "CanvasRenderingContext2D_stroke_Callback";

  void strokeRect(/*float*/ x, /*float*/ y, /*float*/ width, /*float*/ height, [/*float*/ lineWidth]) {
    if (?lineWidth) {
      _strokeRect_1(x, y, width, height, lineWidth);
      return;
    }
    _strokeRect_2(x, y, width, height);
  }


  /** @domName CanvasRenderingContext2D.strokeRect_1 */
  void _strokeRect_1(x, y, width, height, lineWidth) native "CanvasRenderingContext2D_strokeRect_1_Callback";


  /** @domName CanvasRenderingContext2D.strokeRect_2 */
  void _strokeRect_2(x, y, width, height) native "CanvasRenderingContext2D_strokeRect_2_Callback";

  void strokeText(/*DOMString*/ text, /*float*/ x, /*float*/ y, [/*float*/ maxWidth]) {
    if (?maxWidth) {
      _strokeText_1(text, x, y, maxWidth);
      return;
    }
    _strokeText_2(text, x, y);
  }


  /** @domName CanvasRenderingContext2D.strokeText_1 */
  void _strokeText_1(text, x, y, maxWidth) native "CanvasRenderingContext2D_strokeText_1_Callback";


  /** @domName CanvasRenderingContext2D.strokeText_2 */
  void _strokeText_2(text, x, y) native "CanvasRenderingContext2D_strokeText_2_Callback";


  /** @domName CanvasRenderingContext2D.transform */
  void transform(num m11, num m12, num m21, num m22, num dx, num dy) native "CanvasRenderingContext2D_transform_Callback";


  /** @domName CanvasRenderingContext2D.translate */
  void translate(num tx, num ty) native "CanvasRenderingContext2D_translate_Callback";


  /** @domName CanvasRenderingContext2D.webkitGetImageDataHD */
  ImageData webkitGetImageDataHD(num sx, num sy, num sw, num sh) native "CanvasRenderingContext2D_webkitGetImageDataHD_Callback";

  void webkitPutImageDataHD(/*ImageData*/ imagedata, /*float*/ dx, /*float*/ dy, [/*float*/ dirtyX, /*float*/ dirtyY, /*float*/ dirtyWidth, /*float*/ dirtyHeight]) {
    if ((imagedata is ImageData || imagedata == null) && (dx is num || dx == null) && (dy is num || dy == null) && !?dirtyX && !?dirtyY && !?dirtyWidth && !?dirtyHeight) {
      _webkitPutImageDataHD_1(imagedata, dx, dy);
      return;
    }
    if ((imagedata is ImageData || imagedata == null) && (dx is num || dx == null) && (dy is num || dy == null) && (dirtyX is num || dirtyX == null) && (dirtyY is num || dirtyY == null) && (dirtyWidth is num || dirtyWidth == null) && (dirtyHeight is num || dirtyHeight == null)) {
      _webkitPutImageDataHD_2(imagedata, dx, dy, dirtyX, dirtyY, dirtyWidth, dirtyHeight);
      return;
    }
    throw "Incorrect number or type of arguments";
  }


  /** @domName CanvasRenderingContext2D.webkitPutImageDataHD_1 */
  void _webkitPutImageDataHD_1(imagedata, dx, dy) native "CanvasRenderingContext2D_webkitPutImageDataHD_1_Callback";


  /** @domName CanvasRenderingContext2D.webkitPutImageDataHD_2 */
  void _webkitPutImageDataHD_2(imagedata, dx, dy, dirtyX, dirtyY, dirtyWidth, dirtyHeight) native "CanvasRenderingContext2D_webkitPutImageDataHD_2_Callback";


  /**
   * Sets the color used inside shapes.
   * [r], [g], [b] are 0-255, [a] is 0-1.
   */
  void setFillColorRgb(int r, int g, int b, [num a = 1]) {
    this.fillStyle = 'rgba($r, $g, $b, $a)';
  }

  /**
   * Sets the color used inside shapes.
   * [h] is in degrees, 0-360.
   * [s], [l] are in percent, 0-100.
   * [a] is 0-1.
   */
  void setFillColorHsl(int h, num s, num l, [num a = 1]) {
    this.fillStyle = 'hsla($h, $s%, $l%, $a)';
  }

  /**
   * Sets the color used for stroking shapes.
   * [r], [g], [b] are 0-255, [a] is 0-1.
   */
  void setStrokeColorRgb(int r, int g, int b, [num a = 1]) {
    this.strokeStyle = 'rgba($r, $g, $b, $a)';
  }

  /**
   * Sets the color used for stroking shapes.
   * [h] is in degrees, 0-360.
   * [s], [l] are in percent, 0-100.
   * [a] is 0-1.
   */
  void setStrokeColorHsl(int h, num s, num l, [num a = 1]) {
    this.strokeStyle = 'hsla($h, $s%, $l%, $a)';
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName ChannelMergerNode
class ChannelMergerNode extends AudioNode {
  ChannelMergerNode.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName ChannelSplitterNode
class ChannelSplitterNode extends AudioNode {
  ChannelSplitterNode.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName CharacterData
class CharacterData extends Node {
  CharacterData.internal(): super.internal();


  /** @domName CharacterData.data */
  String get data native "CharacterData_data_Getter";


  /** @domName CharacterData.data */
  void set data(String value) native "CharacterData_data_Setter";


  /** @domName CharacterData.length */
  int get length native "CharacterData_length_Getter";


  /** @domName CharacterData.appendData */
  void appendData(String data) native "CharacterData_appendData_Callback";


  /** @domName CharacterData.deleteData */
  void deleteData(int offset, int length) native "CharacterData_deleteData_Callback";


  /** @domName CharacterData.insertData */
  void insertData(int offset, String data) native "CharacterData_insertData_Callback";


  /** @domName CharacterData.remove */
  void remove() native "CharacterData_remove_Callback";


  /** @domName CharacterData.replaceData */
  void replaceData(int offset, int length, String data) native "CharacterData_replaceData_Callback";


  /** @domName CharacterData.substringData */
  String substringData(int offset, int length) native "CharacterData_substringData_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName ClientRect
class ClientRect extends NativeFieldWrapperClass1 {
  ClientRect.internal();


  /** @domName ClientRect.bottom */
  num get bottom native "ClientRect_bottom_Getter";


  /** @domName ClientRect.height */
  num get height native "ClientRect_height_Getter";


  /** @domName ClientRect.left */
  num get left native "ClientRect_left_Getter";


  /** @domName ClientRect.right */
  num get right native "ClientRect_right_Getter";


  /** @domName ClientRect.top */
  num get top native "ClientRect_top_Getter";


  /** @domName ClientRect.width */
  num get width native "ClientRect_width_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Clipboard
class Clipboard extends NativeFieldWrapperClass1 {
  Clipboard.internal();


  /** @domName Clipboard.dropEffect */
  String get dropEffect native "Clipboard_dropEffect_Getter";


  /** @domName Clipboard.dropEffect */
  void set dropEffect(String value) native "Clipboard_dropEffect_Setter";


  /** @domName Clipboard.effectAllowed */
  String get effectAllowed native "Clipboard_effectAllowed_Getter";


  /** @domName Clipboard.effectAllowed */
  void set effectAllowed(String value) native "Clipboard_effectAllowed_Setter";


  /** @domName Clipboard.files */
  List<File> get files native "Clipboard_files_Getter";


  /** @domName Clipboard.items */
  DataTransferItemList get items native "Clipboard_items_Getter";


  /** @domName Clipboard.types */
  List get types native "Clipboard_types_Getter";


  /** @domName Clipboard.clearData */
  void clearData([String type]) native "Clipboard_clearData_Callback";


  /** @domName Clipboard.getData */
  String getData(String type) native "Clipboard_getData_Callback";


  /** @domName Clipboard.setData */
  bool setData(String type, String data) native "Clipboard_setData_Callback";


  /** @domName Clipboard.setDragImage */
  void setDragImage(ImageElement image, int x, int y) native "Clipboard_setDragImage_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName CloseEvent
class CloseEvent extends Event {
  CloseEvent.internal(): super.internal();


  /** @domName CloseEvent.code */
  int get code native "CloseEvent_code_Getter";


  /** @domName CloseEvent.reason */
  String get reason native "CloseEvent_reason_Getter";


  /** @domName CloseEvent.wasClean */
  bool get wasClean native "CloseEvent_wasClean_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Comment
class Comment extends CharacterData {
  Comment.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName CompositionEvent
class CompositionEvent extends UIEvent {
  CompositionEvent.internal(): super.internal();


  /** @domName CompositionEvent.data */
  String get data native "CompositionEvent_data_Getter";


  /** @domName CompositionEvent.initCompositionEvent */
  void initCompositionEvent(String typeArg, bool canBubbleArg, bool cancelableArg, LocalWindow viewArg, String dataArg) native "CompositionEvent_initCompositionEvent_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Console
class Console extends NativeFieldWrapperClass1 {
  Console.internal();


  /** @domName Console.memory */
  MemoryInfo get memory native "Console_memory_Getter";


  /** @domName Console.profiles */
  List<ScriptProfile> get profiles native "Console_profiles_Getter";


  /** @domName Console.assertCondition */
  void assertCondition(bool condition, Object arg) native "Console_assertCondition_Callback";


  /** @domName Console.count */
  void count(Object arg) native "Console_count_Callback";


  /** @domName Console.debug */
  void debug(Object arg) native "Console_debug_Callback";


  /** @domName Console.dir */
  void dir(Object arg) native "Console_dir_Callback";


  /** @domName Console.dirxml */
  void dirxml(Object arg) native "Console_dirxml_Callback";


  /** @domName Console.error */
  void error(Object arg) native "Console_error_Callback";


  /** @domName Console.group */
  void group(Object arg) native "Console_group_Callback";


  /** @domName Console.groupCollapsed */
  void groupCollapsed(Object arg) native "Console_groupCollapsed_Callback";


  /** @domName Console.groupEnd */
  void groupEnd() native "Console_groupEnd_Callback";


  /** @domName Console.info */
  void info(Object arg) native "Console_info_Callback";


  /** @domName Console.log */
  void log(Object arg) native "Console_log_Callback";


  /** @domName Console.markTimeline */
  void markTimeline(Object arg) native "Console_markTimeline_Callback";


  /** @domName Console.profile */
  void profile(String title) native "Console_profile_Callback";


  /** @domName Console.profileEnd */
  void profileEnd(String title) native "Console_profileEnd_Callback";


  /** @domName Console.time */
  void time(String title) native "Console_time_Callback";


  /** @domName Console.timeEnd */
  void timeEnd(String title, Object arg) native "Console_timeEnd_Callback";


  /** @domName Console.timeStamp */
  void timeStamp(Object arg) native "Console_timeStamp_Callback";


  /** @domName Console.trace */
  void trace(Object arg) native "Console_trace_Callback";


  /** @domName Console.warn */
  void warn(Object arg) native "Console_warn_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLContentElement
class ContentElement extends _Element_Merged {

  factory ContentElement() => document.$dom_createElement("content");
  ContentElement.internal(): super.internal();


  /** @domName HTMLContentElement.resetStyleInheritance */
  bool get resetStyleInheritance native "HTMLContentElement_resetStyleInheritance_Getter";


  /** @domName HTMLContentElement.resetStyleInheritance */
  void set resetStyleInheritance(bool value) native "HTMLContentElement_resetStyleInheritance_Setter";


  /** @domName HTMLContentElement.select */
  String get select native "HTMLContentElement_select_Getter";


  /** @domName HTMLContentElement.select */
  void set select(String value) native "HTMLContentElement_select_Setter";


  /** @domName HTMLContentElement.getDistributedNodes */
  List<Node> getDistributedNodes() native "HTMLContentElement_getDistributedNodes_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName ConvolverNode
class ConvolverNode extends AudioNode {
  ConvolverNode.internal(): super.internal();


  /** @domName ConvolverNode.buffer */
  AudioBuffer get buffer native "ConvolverNode_buffer_Getter";


  /** @domName ConvolverNode.buffer */
  void set buffer(AudioBuffer value) native "ConvolverNode_buffer_Setter";


  /** @domName ConvolverNode.normalize */
  bool get normalize native "ConvolverNode_normalize_Getter";


  /** @domName ConvolverNode.normalize */
  void set normalize(bool value) native "ConvolverNode_normalize_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Coordinates
class Coordinates extends NativeFieldWrapperClass1 {
  Coordinates.internal();


  /** @domName Coordinates.accuracy */
  num get accuracy native "Coordinates_accuracy_Getter";


  /** @domName Coordinates.altitude */
  num get altitude native "Coordinates_altitude_Getter";


  /** @domName Coordinates.altitudeAccuracy */
  num get altitudeAccuracy native "Coordinates_altitudeAccuracy_Getter";


  /** @domName Coordinates.heading */
  num get heading native "Coordinates_heading_Getter";


  /** @domName Coordinates.latitude */
  num get latitude native "Coordinates_latitude_Getter";


  /** @domName Coordinates.longitude */
  num get longitude native "Coordinates_longitude_Getter";


  /** @domName Coordinates.speed */
  num get speed native "Coordinates_speed_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Counter
class Counter extends NativeFieldWrapperClass1 {
  Counter.internal();


  /** @domName Counter.identifier */
  String get identifier native "Counter_identifier_Getter";


  /** @domName Counter.listStyle */
  String get listStyle native "Counter_listStyle_Getter";


  /** @domName Counter.separator */
  String get separator native "Counter_separator_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Crypto
class Crypto extends NativeFieldWrapperClass1 {
  Crypto.internal();


  /** @domName Crypto.getRandomValues */
  void getRandomValues(ArrayBufferView array) native "Crypto_getRandomValues_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


class CustomEvent extends Event {
  factory CustomEvent(String type, [bool canBubble = true, bool cancelable = true,
      Object detail]) => _CustomEventFactoryProvider.createCustomEvent(
      type, canBubble, cancelable, detail);
  CustomEvent.internal(): super.internal();


  /** @domName CustomEvent.detail */
  Object get detail native "CustomEvent_detail_Getter";


  /** @domName CustomEvent.initCustomEvent */
  void $dom_initCustomEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object detailArg) native "CustomEvent_initCustomEvent_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLDListElement
class DListElement extends _Element_Merged {

  factory DListElement() => document.$dom_createElement("dl");
  DListElement.internal(): super.internal();


  /** @domName HTMLDListElement.compact */
  bool get compact native "HTMLDListElement_compact_Getter";


  /** @domName HTMLDListElement.compact */
  void set compact(bool value) native "HTMLDListElement_compact_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName DOMApplicationCache
class DOMApplicationCache extends EventTarget {
  DOMApplicationCache.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  DOMApplicationCacheEvents get on =>
    new DOMApplicationCacheEvents(this);

  static const int CHECKING = 2;

  static const int DOWNLOADING = 3;

  static const int IDLE = 1;

  static const int OBSOLETE = 5;

  static const int UNCACHED = 0;

  static const int UPDATEREADY = 4;


  /** @domName DOMApplicationCache.status */
  int get status native "DOMApplicationCache_status_Getter";


  /** @domName DOMApplicationCache.abort */
  void abort() native "DOMApplicationCache_abort_Callback";


  /** @domName DOMApplicationCache.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "DOMApplicationCache_addEventListener_Callback";


  /** @domName DOMApplicationCache.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "DOMApplicationCache_dispatchEvent_Callback";


  /** @domName DOMApplicationCache.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "DOMApplicationCache_removeEventListener_Callback";


  /** @domName DOMApplicationCache.swapCache */
  void swapCache() native "DOMApplicationCache_swapCache_Callback";


  /** @domName DOMApplicationCache.update */
  void update() native "DOMApplicationCache_update_Callback";

}

class DOMApplicationCacheEvents extends Events {
  DOMApplicationCacheEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get cached => this['cached'];

  EventListenerList get checking => this['checking'];

  EventListenerList get downloading => this['downloading'];

  EventListenerList get error => this['error'];

  EventListenerList get noUpdate => this['noupdate'];

  EventListenerList get obsolete => this['obsolete'];

  EventListenerList get progress => this['progress'];

  EventListenerList get updateReady => this['updateready'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName DOMError
class DOMError extends NativeFieldWrapperClass1 {
  DOMError.internal();


  /** @domName DOMError.name */
  String get name native "DOMError_name_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName DOMException
class DOMException extends NativeFieldWrapperClass1 {
  DOMException.internal();

  static const int ABORT_ERR = 20;

  static const int DATA_CLONE_ERR = 25;

  static const int DOMSTRING_SIZE_ERR = 2;

  static const int HIERARCHY_REQUEST_ERR = 3;

  static const int INDEX_SIZE_ERR = 1;

  static const int INUSE_ATTRIBUTE_ERR = 10;

  static const int INVALID_ACCESS_ERR = 15;

  static const int INVALID_CHARACTER_ERR = 5;

  static const int INVALID_MODIFICATION_ERR = 13;

  static const int INVALID_NODE_TYPE_ERR = 24;

  static const int INVALID_STATE_ERR = 11;

  static const int NAMESPACE_ERR = 14;

  static const int NETWORK_ERR = 19;

  static const int NOT_FOUND_ERR = 8;

  static const int NOT_SUPPORTED_ERR = 9;

  static const int NO_DATA_ALLOWED_ERR = 6;

  static const int NO_MODIFICATION_ALLOWED_ERR = 7;

  static const int QUOTA_EXCEEDED_ERR = 22;

  static const int SECURITY_ERR = 18;

  static const int SYNTAX_ERR = 12;

  static const int TIMEOUT_ERR = 23;

  static const int TYPE_MISMATCH_ERR = 17;

  static const int URL_MISMATCH_ERR = 21;

  static const int VALIDATION_ERR = 16;

  static const int WRONG_DOCUMENT_ERR = 4;


  /** @domName DOMCoreException.code */
  int get code native "DOMCoreException_code_Getter";


  /** @domName DOMCoreException.message */
  String get message native "DOMCoreException_message_Getter";


  /** @domName DOMCoreException.name */
  String get name native "DOMCoreException_name_Getter";


  /** @domName DOMCoreException.toString */
  String toString() native "DOMCoreException_toString_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName DOMFileSystem
class DOMFileSystem extends NativeFieldWrapperClass1 {
  DOMFileSystem.internal();


  /** @domName DOMFileSystem.name */
  String get name native "DOMFileSystem_name_Getter";


  /** @domName DOMFileSystem.root */
  DirectoryEntry get root native "DOMFileSystem_root_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName DOMFileSystemSync
class DOMFileSystemSync extends NativeFieldWrapperClass1 {
  DOMFileSystemSync.internal();


  /** @domName DOMFileSystemSync.name */
  String get name native "DOMFileSystemSync_name_Getter";


  /** @domName DOMFileSystemSync.root */
  DirectoryEntrySync get root native "DOMFileSystemSync_root_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName DOMImplementation
class DOMImplementation extends NativeFieldWrapperClass1 {
  DOMImplementation.internal();


  /** @domName DOMImplementation.createCSSStyleSheet */
  CSSStyleSheet createCSSStyleSheet(String title, String media) native "DOMImplementation_createCSSStyleSheet_Callback";


  /** @domName DOMImplementation.createDocument */
  Document createDocument(String namespaceURI, String qualifiedName, DocumentType doctype) native "DOMImplementation_createDocument_Callback";


  /** @domName DOMImplementation.createDocumentType */
  DocumentType createDocumentType(String qualifiedName, String publicId, String systemId) native "DOMImplementation_createDocumentType_Callback";


  /** @domName DOMImplementation.createHTMLDocument */
  HtmlDocument createHTMLDocument(String title) native "DOMImplementation_createHTMLDocument_Callback";


  /** @domName DOMImplementation.hasFeature */
  bool hasFeature(String feature, String version) native "DOMImplementation_hasFeature_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName MimeType
class DOMMimeType extends NativeFieldWrapperClass1 {
  DOMMimeType.internal();


  /** @domName DOMMimeType.description */
  String get description native "DOMMimeType_description_Getter";


  /** @domName DOMMimeType.enabledPlugin */
  DOMPlugin get enabledPlugin native "DOMMimeType_enabledPlugin_Getter";


  /** @domName DOMMimeType.suffixes */
  String get suffixes native "DOMMimeType_suffixes_Getter";


  /** @domName DOMMimeType.type */
  String get type native "DOMMimeType_type_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName MimeTypeArray
class DOMMimeTypeArray extends NativeFieldWrapperClass1 implements List<DOMMimeType> {
  DOMMimeTypeArray.internal();


  /** @domName DOMMimeTypeArray.length */
  int get length native "DOMMimeTypeArray_length_Getter";

  DOMMimeType operator[](int index) native "DOMMimeTypeArray_item_Callback";

  void operator[]=(int index, DOMMimeType value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<DOMMimeType> mixins.
  // DOMMimeType is the element type.

  // From Iterable<DOMMimeType>:

  Iterator<DOMMimeType> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<DOMMimeType>(this);
  }

  // From Collection<DOMMimeType>:

  void add(DOMMimeType value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(DOMMimeType value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<DOMMimeType> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(DOMMimeType element) => _Collections.contains(this, element);

  void forEach(void f(DOMMimeType element)) => _Collections.forEach(this, f);

  Collection map(f(DOMMimeType element)) => _Collections.map(this, [], f);

  Collection<DOMMimeType> filter(bool f(DOMMimeType element)) =>
     _Collections.filter(this, <DOMMimeType>[], f);

  bool every(bool f(DOMMimeType element)) => _Collections.every(this, f);

  bool some(bool f(DOMMimeType element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<DOMMimeType>:

  void sort([Comparator<DOMMimeType> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(DOMMimeType element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(DOMMimeType element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  DOMMimeType get first => this[0];

  DOMMimeType get last => this[length - 1];

  DOMMimeType removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<DOMMimeType> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [DOMMimeType initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<DOMMimeType> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <DOMMimeType>[]);

  // -- end List<DOMMimeType> mixins.


  /** @domName DOMMimeTypeArray.item */
  DOMMimeType item(int index) native "DOMMimeTypeArray_item_Callback";


  /** @domName DOMMimeTypeArray.namedItem */
  DOMMimeType namedItem(String name) native "DOMMimeTypeArray_namedItem_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName DOMParser
class DOMParser extends NativeFieldWrapperClass1 {

  factory DOMParser() => _DOMParserFactoryProvider.createDOMParser();
  DOMParser.internal();


  /** @domName DOMParser.parseFromString */
  Document parseFromString(String str, String contentType) native "DOMParser_parseFromString_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Plugin
class DOMPlugin extends NativeFieldWrapperClass1 {
  DOMPlugin.internal();


  /** @domName DOMPlugin.description */
  String get description native "DOMPlugin_description_Getter";


  /** @domName DOMPlugin.filename */
  String get filename native "DOMPlugin_filename_Getter";


  /** @domName DOMPlugin.length */
  int get length native "DOMPlugin_length_Getter";


  /** @domName DOMPlugin.name */
  String get name native "DOMPlugin_name_Getter";


  /** @domName DOMPlugin.item */
  DOMMimeType item(int index) native "DOMPlugin_item_Callback";


  /** @domName DOMPlugin.namedItem */
  DOMMimeType namedItem(String name) native "DOMPlugin_namedItem_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName PluginArray
class DOMPluginArray extends NativeFieldWrapperClass1 implements List<DOMPlugin> {
  DOMPluginArray.internal();


  /** @domName DOMPluginArray.length */
  int get length native "DOMPluginArray_length_Getter";

  DOMPlugin operator[](int index) native "DOMPluginArray_item_Callback";

  void operator[]=(int index, DOMPlugin value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<DOMPlugin> mixins.
  // DOMPlugin is the element type.

  // From Iterable<DOMPlugin>:

  Iterator<DOMPlugin> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<DOMPlugin>(this);
  }

  // From Collection<DOMPlugin>:

  void add(DOMPlugin value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(DOMPlugin value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<DOMPlugin> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(DOMPlugin element) => _Collections.contains(this, element);

  void forEach(void f(DOMPlugin element)) => _Collections.forEach(this, f);

  Collection map(f(DOMPlugin element)) => _Collections.map(this, [], f);

  Collection<DOMPlugin> filter(bool f(DOMPlugin element)) =>
     _Collections.filter(this, <DOMPlugin>[], f);

  bool every(bool f(DOMPlugin element)) => _Collections.every(this, f);

  bool some(bool f(DOMPlugin element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<DOMPlugin>:

  void sort([Comparator<DOMPlugin> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(DOMPlugin element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(DOMPlugin element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  DOMPlugin get first => this[0];

  DOMPlugin get last => this[length - 1];

  DOMPlugin removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<DOMPlugin> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [DOMPlugin initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<DOMPlugin> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <DOMPlugin>[]);

  // -- end List<DOMPlugin> mixins.


  /** @domName DOMPluginArray.item */
  DOMPlugin item(int index) native "DOMPluginArray_item_Callback";


  /** @domName DOMPluginArray.namedItem */
  DOMPlugin namedItem(String name) native "DOMPluginArray_namedItem_Callback";


  /** @domName DOMPluginArray.refresh */
  void refresh(bool reload) native "DOMPluginArray_refresh_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Selection
class DOMSelection extends NativeFieldWrapperClass1 {
  DOMSelection.internal();


  /** @domName DOMSelection.anchorNode */
  Node get anchorNode native "DOMSelection_anchorNode_Getter";


  /** @domName DOMSelection.anchorOffset */
  int get anchorOffset native "DOMSelection_anchorOffset_Getter";


  /** @domName DOMSelection.baseNode */
  Node get baseNode native "DOMSelection_baseNode_Getter";


  /** @domName DOMSelection.baseOffset */
  int get baseOffset native "DOMSelection_baseOffset_Getter";


  /** @domName DOMSelection.extentNode */
  Node get extentNode native "DOMSelection_extentNode_Getter";


  /** @domName DOMSelection.extentOffset */
  int get extentOffset native "DOMSelection_extentOffset_Getter";


  /** @domName DOMSelection.focusNode */
  Node get focusNode native "DOMSelection_focusNode_Getter";


  /** @domName DOMSelection.focusOffset */
  int get focusOffset native "DOMSelection_focusOffset_Getter";


  /** @domName DOMSelection.isCollapsed */
  bool get isCollapsed native "DOMSelection_isCollapsed_Getter";


  /** @domName DOMSelection.rangeCount */
  int get rangeCount native "DOMSelection_rangeCount_Getter";


  /** @domName DOMSelection.type */
  String get type native "DOMSelection_type_Getter";


  /** @domName DOMSelection.addRange */
  void addRange(Range range) native "DOMSelection_addRange_Callback";


  /** @domName DOMSelection.collapse */
  void collapse(Node node, int index) native "DOMSelection_collapse_Callback";


  /** @domName DOMSelection.collapseToEnd */
  void collapseToEnd() native "DOMSelection_collapseToEnd_Callback";


  /** @domName DOMSelection.collapseToStart */
  void collapseToStart() native "DOMSelection_collapseToStart_Callback";


  /** @domName DOMSelection.containsNode */
  bool containsNode(Node node, bool allowPartial) native "DOMSelection_containsNode_Callback";


  /** @domName DOMSelection.deleteFromDocument */
  void deleteFromDocument() native "DOMSelection_deleteFromDocument_Callback";


  /** @domName DOMSelection.empty */
  void empty() native "DOMSelection_empty_Callback";


  /** @domName DOMSelection.extend */
  void extend(Node node, int offset) native "DOMSelection_extend_Callback";


  /** @domName DOMSelection.getRangeAt */
  Range getRangeAt(int index) native "DOMSelection_getRangeAt_Callback";


  /** @domName DOMSelection.modify */
  void modify(String alter, String direction, String granularity) native "DOMSelection_modify_Callback";


  /** @domName DOMSelection.removeAllRanges */
  void removeAllRanges() native "DOMSelection_removeAllRanges_Callback";


  /** @domName DOMSelection.selectAllChildren */
  void selectAllChildren(Node node) native "DOMSelection_selectAllChildren_Callback";


  /** @domName DOMSelection.setBaseAndExtent */
  void setBaseAndExtent(Node baseNode, int baseOffset, Node extentNode, int extentOffset) native "DOMSelection_setBaseAndExtent_Callback";


  /** @domName DOMSelection.setPosition */
  void setPosition(Node node, int offset) native "DOMSelection_setPosition_Callback";


  /** @domName DOMSelection.toString */
  String toString() native "DOMSelection_toString_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName DOMSettableTokenList
class DOMSettableTokenList extends DOMTokenList {
  DOMSettableTokenList.internal(): super.internal();


  /** @domName DOMSettableTokenList.value */
  String get value native "DOMSettableTokenList_value_Getter";


  /** @domName DOMSettableTokenList.value */
  void set value(String value) native "DOMSettableTokenList_value_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName DOMStringMap
class DOMStringMap extends NativeFieldWrapperClass1 {
  DOMStringMap.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName DOMTokenList
class DOMTokenList extends NativeFieldWrapperClass1 {
  DOMTokenList.internal();


  /** @domName DOMTokenList.length */
  int get length native "DOMTokenList_length_Getter";


  /** @domName DOMTokenList.contains */
  bool contains(String token) native "DOMTokenList_contains_Callback";


  /** @domName DOMTokenList.item */
  String item(int index) native "DOMTokenList_item_Callback";


  /** @domName DOMTokenList.toString */
  String toString() native "DOMTokenList_toString_Callback";

  bool toggle(/*DOMString*/ token, [/*boolean*/ force]) {
    if (?force) {
      return _toggle_1(token, force);
    }
    return _toggle_2(token);
  }


  /** @domName DOMTokenList.toggle_1 */
  bool _toggle_1(token, force) native "DOMTokenList_toggle_1_Callback";


  /** @domName DOMTokenList.toggle_2 */
  bool _toggle_2(token) native "DOMTokenList_toggle_2_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLDataListElement
class DataListElement extends _Element_Merged {

  factory DataListElement() => document.$dom_createElement("datalist");
  DataListElement.internal(): super.internal();


  /** @domName HTMLDataListElement.options */
  HTMLCollection get options native "HTMLDataListElement_options_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName DataTransferItem
class DataTransferItem extends NativeFieldWrapperClass1 {
  DataTransferItem.internal();


  /** @domName DataTransferItem.kind */
  String get kind native "DataTransferItem_kind_Getter";


  /** @domName DataTransferItem.type */
  String get type native "DataTransferItem_type_Getter";


  /** @domName DataTransferItem.getAsFile */
  Blob getAsFile() native "DataTransferItem_getAsFile_Callback";


  /** @domName DataTransferItem.getAsString */
  void getAsString([StringCallback callback]) native "DataTransferItem_getAsString_Callback";


  /** @domName DataTransferItem.webkitGetAsEntry */
  Entry webkitGetAsEntry() native "DataTransferItem_webkitGetAsEntry_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName DataTransferItemList
class DataTransferItemList extends NativeFieldWrapperClass1 {
  DataTransferItemList.internal();


  /** @domName DataTransferItemList.length */
  int get length native "DataTransferItemList_length_Getter";

  void add(data_OR_file, [/*DOMString*/ type]) {
    if ((data_OR_file is File || data_OR_file == null) && !?type) {
      _add_1(data_OR_file);
      return;
    }
    if ((data_OR_file is String || data_OR_file == null) && (type is String || type == null)) {
      _add_2(data_OR_file, type);
      return;
    }
    throw "Incorrect number or type of arguments";
  }


  /** @domName DataTransferItemList.add_1 */
  void _add_1(data_OR_file) native "DataTransferItemList_add_1_Callback";


  /** @domName DataTransferItemList.add_2 */
  void _add_2(data_OR_file, type) native "DataTransferItemList_add_2_Callback";


  /** @domName DataTransferItemList.clear */
  void clear() native "DataTransferItemList_clear_Callback";


  /** @domName DataTransferItemList.item */
  DataTransferItem item(int index) native "DataTransferItemList_item_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName DataView
class DataView extends ArrayBufferView {

  factory DataView(ArrayBuffer buffer, [int byteOffset, int byteLength]) {
    if (!?byteOffset) {
      return _DataViewFactoryProvider.createDataView(buffer);
    }
    if (!?byteLength) {
      return _DataViewFactoryProvider.createDataView(buffer, byteOffset);
    }
    return _DataViewFactoryProvider.createDataView(buffer, byteOffset, byteLength);
  }
  DataView.internal(): super.internal();

  num getFloat32(/*unsigned long*/ byteOffset, {/*boolean*/ littleEndian}) {
    if (?littleEndian) {
      return _getFloat32_1(byteOffset, littleEndian);
    }
    return _getFloat32_2(byteOffset);
  }


  /** @domName DataView.getFloat32_1 */
  num _getFloat32_1(byteOffset, littleEndian) native "DataView_getFloat32_1_Callback";


  /** @domName DataView.getFloat32_2 */
  num _getFloat32_2(byteOffset) native "DataView_getFloat32_2_Callback";

  num getFloat64(/*unsigned long*/ byteOffset, {/*boolean*/ littleEndian}) {
    if (?littleEndian) {
      return _getFloat64_1(byteOffset, littleEndian);
    }
    return _getFloat64_2(byteOffset);
  }


  /** @domName DataView.getFloat64_1 */
  num _getFloat64_1(byteOffset, littleEndian) native "DataView_getFloat64_1_Callback";


  /** @domName DataView.getFloat64_2 */
  num _getFloat64_2(byteOffset) native "DataView_getFloat64_2_Callback";

  int getInt16(/*unsigned long*/ byteOffset, {/*boolean*/ littleEndian}) {
    if (?littleEndian) {
      return _getInt16_1(byteOffset, littleEndian);
    }
    return _getInt16_2(byteOffset);
  }


  /** @domName DataView.getInt16_1 */
  int _getInt16_1(byteOffset, littleEndian) native "DataView_getInt16_1_Callback";


  /** @domName DataView.getInt16_2 */
  int _getInt16_2(byteOffset) native "DataView_getInt16_2_Callback";

  int getInt32(/*unsigned long*/ byteOffset, {/*boolean*/ littleEndian}) {
    if (?littleEndian) {
      return _getInt32_1(byteOffset, littleEndian);
    }
    return _getInt32_2(byteOffset);
  }


  /** @domName DataView.getInt32_1 */
  int _getInt32_1(byteOffset, littleEndian) native "DataView_getInt32_1_Callback";


  /** @domName DataView.getInt32_2 */
  int _getInt32_2(byteOffset) native "DataView_getInt32_2_Callback";


  /** @domName DataView.getInt8 */
  int getInt8(int byteOffset) native "DataView_getInt8_Callback";

  int getUint16(/*unsigned long*/ byteOffset, {/*boolean*/ littleEndian}) {
    if (?littleEndian) {
      return _getUint16_1(byteOffset, littleEndian);
    }
    return _getUint16_2(byteOffset);
  }


  /** @domName DataView.getUint16_1 */
  int _getUint16_1(byteOffset, littleEndian) native "DataView_getUint16_1_Callback";


  /** @domName DataView.getUint16_2 */
  int _getUint16_2(byteOffset) native "DataView_getUint16_2_Callback";

  int getUint32(/*unsigned long*/ byteOffset, {/*boolean*/ littleEndian}) {
    if (?littleEndian) {
      return _getUint32_1(byteOffset, littleEndian);
    }
    return _getUint32_2(byteOffset);
  }


  /** @domName DataView.getUint32_1 */
  int _getUint32_1(byteOffset, littleEndian) native "DataView_getUint32_1_Callback";


  /** @domName DataView.getUint32_2 */
  int _getUint32_2(byteOffset) native "DataView_getUint32_2_Callback";


  /** @domName DataView.getUint8 */
  int getUint8(int byteOffset) native "DataView_getUint8_Callback";

  void setFloat32(/*unsigned long*/ byteOffset, /*float*/ value, {/*boolean*/ littleEndian}) {
    if (?littleEndian) {
      _setFloat32_1(byteOffset, value, littleEndian);
      return;
    }
    _setFloat32_2(byteOffset, value);
  }


  /** @domName DataView.setFloat32_1 */
  void _setFloat32_1(byteOffset, value, littleEndian) native "DataView_setFloat32_1_Callback";


  /** @domName DataView.setFloat32_2 */
  void _setFloat32_2(byteOffset, value) native "DataView_setFloat32_2_Callback";

  void setFloat64(/*unsigned long*/ byteOffset, /*double*/ value, {/*boolean*/ littleEndian}) {
    if (?littleEndian) {
      _setFloat64_1(byteOffset, value, littleEndian);
      return;
    }
    _setFloat64_2(byteOffset, value);
  }


  /** @domName DataView.setFloat64_1 */
  void _setFloat64_1(byteOffset, value, littleEndian) native "DataView_setFloat64_1_Callback";


  /** @domName DataView.setFloat64_2 */
  void _setFloat64_2(byteOffset, value) native "DataView_setFloat64_2_Callback";

  void setInt16(/*unsigned long*/ byteOffset, /*short*/ value, {/*boolean*/ littleEndian}) {
    if (?littleEndian) {
      _setInt16_1(byteOffset, value, littleEndian);
      return;
    }
    _setInt16_2(byteOffset, value);
  }


  /** @domName DataView.setInt16_1 */
  void _setInt16_1(byteOffset, value, littleEndian) native "DataView_setInt16_1_Callback";


  /** @domName DataView.setInt16_2 */
  void _setInt16_2(byteOffset, value) native "DataView_setInt16_2_Callback";

  void setInt32(/*unsigned long*/ byteOffset, /*long*/ value, {/*boolean*/ littleEndian}) {
    if (?littleEndian) {
      _setInt32_1(byteOffset, value, littleEndian);
      return;
    }
    _setInt32_2(byteOffset, value);
  }


  /** @domName DataView.setInt32_1 */
  void _setInt32_1(byteOffset, value, littleEndian) native "DataView_setInt32_1_Callback";


  /** @domName DataView.setInt32_2 */
  void _setInt32_2(byteOffset, value) native "DataView_setInt32_2_Callback";


  /** @domName DataView.setInt8 */
  void setInt8(int byteOffset, int value) native "DataView_setInt8_Callback";

  void setUint16(/*unsigned long*/ byteOffset, /*unsigned short*/ value, {/*boolean*/ littleEndian}) {
    if (?littleEndian) {
      _setUint16_1(byteOffset, value, littleEndian);
      return;
    }
    _setUint16_2(byteOffset, value);
  }


  /** @domName DataView.setUint16_1 */
  void _setUint16_1(byteOffset, value, littleEndian) native "DataView_setUint16_1_Callback";


  /** @domName DataView.setUint16_2 */
  void _setUint16_2(byteOffset, value) native "DataView_setUint16_2_Callback";

  void setUint32(/*unsigned long*/ byteOffset, /*unsigned long*/ value, {/*boolean*/ littleEndian}) {
    if (?littleEndian) {
      _setUint32_1(byteOffset, value, littleEndian);
      return;
    }
    _setUint32_2(byteOffset, value);
  }


  /** @domName DataView.setUint32_1 */
  void _setUint32_1(byteOffset, value, littleEndian) native "DataView_setUint32_1_Callback";


  /** @domName DataView.setUint32_2 */
  void _setUint32_2(byteOffset, value) native "DataView_setUint32_2_Callback";


  /** @domName DataView.setUint8 */
  void setUint8(int byteOffset, int value) native "DataView_setUint8_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Database
class Database extends NativeFieldWrapperClass1 {
  Database.internal();


  /** @domName Database.version */
  String get version native "Database_version_Getter";


  /** @domName Database.changeVersion */
  void changeVersion(String oldVersion, String newVersion, [SQLTransactionCallback callback, SQLTransactionErrorCallback errorCallback, VoidCallback successCallback]) native "Database_changeVersion_Callback";


  /** @domName Database.readTransaction */
  void readTransaction(SQLTransactionCallback callback, [SQLTransactionErrorCallback errorCallback, VoidCallback successCallback]) native "Database_readTransaction_Callback";


  /** @domName Database.transaction */
  void transaction(SQLTransactionCallback callback, [SQLTransactionErrorCallback errorCallback, VoidCallback successCallback]) native "Database_transaction_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void DatabaseCallback(database);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName DatabaseSync
class DatabaseSync extends NativeFieldWrapperClass1 {
  DatabaseSync.internal();


  /** @domName DatabaseSync.lastErrorMessage */
  String get lastErrorMessage native "DatabaseSync_lastErrorMessage_Getter";


  /** @domName DatabaseSync.version */
  String get version native "DatabaseSync_version_Getter";


  /** @domName DatabaseSync.changeVersion */
  void changeVersion(String oldVersion, String newVersion, [SQLTransactionSyncCallback callback]) native "DatabaseSync_changeVersion_Callback";


  /** @domName DatabaseSync.readTransaction */
  void readTransaction(SQLTransactionSyncCallback callback) native "DatabaseSync_readTransaction_Callback";


  /** @domName DatabaseSync.transaction */
  void transaction(SQLTransactionSyncCallback callback) native "DatabaseSync_transaction_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName DedicatedWorkerContext
class DedicatedWorkerContext extends WorkerContext {
  DedicatedWorkerContext.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  DedicatedWorkerContextEvents get on =>
    new DedicatedWorkerContextEvents(this);


  /** @domName DedicatedWorkerContext.postMessage */
  void postMessage(Object message, [List messagePorts]) native "DedicatedWorkerContext_postMessage_Callback";

}

class DedicatedWorkerContextEvents extends WorkerContextEvents {
  DedicatedWorkerContextEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get message => this['message'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName DelayNode
class DelayNode extends AudioNode {
  DelayNode.internal(): super.internal();


  /** @domName DelayNode.delayTime */
  AudioParam get delayTime native "DelayNode_delayTime_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLDetailsElement
class DetailsElement extends _Element_Merged {

  factory DetailsElement() => document.$dom_createElement("details");
  DetailsElement.internal(): super.internal();


  /** @domName HTMLDetailsElement.open */
  bool get open native "HTMLDetailsElement_open_Getter";


  /** @domName HTMLDetailsElement.open */
  void set open(bool value) native "HTMLDetailsElement_open_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName DeviceMotionEvent
class DeviceMotionEvent extends Event {
  DeviceMotionEvent.internal(): super.internal();


  /** @domName DeviceMotionEvent.interval */
  num get interval native "DeviceMotionEvent_interval_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName DeviceOrientationEvent
class DeviceOrientationEvent extends Event {
  DeviceOrientationEvent.internal(): super.internal();


  /** @domName DeviceOrientationEvent.absolute */
  bool get absolute native "DeviceOrientationEvent_absolute_Getter";


  /** @domName DeviceOrientationEvent.alpha */
  num get alpha native "DeviceOrientationEvent_alpha_Getter";


  /** @domName DeviceOrientationEvent.beta */
  num get beta native "DeviceOrientationEvent_beta_Getter";


  /** @domName DeviceOrientationEvent.gamma */
  num get gamma native "DeviceOrientationEvent_gamma_Getter";


  /** @domName DeviceOrientationEvent.initDeviceOrientationEvent */
  void initDeviceOrientationEvent(String type, bool bubbles, bool cancelable, num alpha, num beta, num gamma, bool absolute) native "DeviceOrientationEvent_initDeviceOrientationEvent_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLDirectoryElement
class DirectoryElement extends _Element_Merged {
  DirectoryElement.internal(): super.internal();


  /** @domName HTMLDirectoryElement.compact */
  bool get compact native "HTMLDirectoryElement_compact_Getter";


  /** @domName HTMLDirectoryElement.compact */
  void set compact(bool value) native "HTMLDirectoryElement_compact_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName DirectoryEntry
class DirectoryEntry extends Entry {
  DirectoryEntry.internal(): super.internal();


  /** @domName DirectoryEntry.createReader */
  DirectoryReader createReader() native "DirectoryEntry_createReader_Callback";


  /** @domName DirectoryEntry.getDirectory */
  void getDirectory(String path, {Map options, EntryCallback successCallback, ErrorCallback errorCallback}) native "DirectoryEntry_getDirectory_Callback";


  /** @domName DirectoryEntry.getFile */
  void getFile(String path, {Map options, EntryCallback successCallback, ErrorCallback errorCallback}) native "DirectoryEntry_getFile_Callback";


  /** @domName DirectoryEntry.removeRecursively */
  void removeRecursively(VoidCallback successCallback, [ErrorCallback errorCallback]) native "DirectoryEntry_removeRecursively_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName DirectoryEntrySync
class DirectoryEntrySync extends EntrySync {
  DirectoryEntrySync.internal(): super.internal();


  /** @domName DirectoryEntrySync.createReader */
  DirectoryReaderSync createReader() native "DirectoryEntrySync_createReader_Callback";


  /** @domName DirectoryEntrySync.getDirectory */
  DirectoryEntrySync getDirectory(String path, Map flags) native "DirectoryEntrySync_getDirectory_Callback";


  /** @domName DirectoryEntrySync.getFile */
  FileEntrySync getFile(String path, Map flags) native "DirectoryEntrySync_getFile_Callback";


  /** @domName DirectoryEntrySync.removeRecursively */
  void removeRecursively() native "DirectoryEntrySync_removeRecursively_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName DirectoryReader
class DirectoryReader extends NativeFieldWrapperClass1 {
  DirectoryReader.internal();


  /** @domName DirectoryReader.readEntries */
  void readEntries(EntriesCallback successCallback, [ErrorCallback errorCallback]) native "DirectoryReader_readEntries_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName DirectoryReaderSync
class DirectoryReaderSync extends NativeFieldWrapperClass1 {
  DirectoryReaderSync.internal();


  /** @domName DirectoryReaderSync.readEntries */
  List<EntrySync> readEntries() native "DirectoryReaderSync_readEntries_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLDivElement
class DivElement extends _Element_Merged {

  factory DivElement() => document.$dom_createElement("div");
  DivElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class Document extends Node 
{

  Document.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  DocumentEvents get on =>
    new DocumentEvents(this);


  /** @domName Document.body */
  Element get $dom_body native "Document_body_Getter";


  /** @domName Document.body */
  void set $dom_body(Element value) native "Document_body_Setter";


  /** @domName Document.charset */
  String get charset native "Document_charset_Getter";


  /** @domName Document.charset */
  void set charset(String value) native "Document_charset_Setter";


  /** @domName Document.cookie */
  String get cookie native "Document_cookie_Getter";


  /** @domName Document.cookie */
  void set cookie(String value) native "Document_cookie_Setter";


  /** @domName Document.defaultView */
  Window get window native "Document_defaultView_Getter";


  /** @domName Document.documentElement */
  Element get documentElement native "Document_documentElement_Getter";


  /** @domName Document.domain */
  String get domain native "Document_domain_Getter";


  /** @domName Document.head */
  HeadElement get $dom_head native "Document_head_Getter";


  /** @domName Document.implementation */
  DOMImplementation get implementation native "Document_implementation_Getter";


  /** @domName Document.lastModified */
  String get $dom_lastModified native "Document_lastModified_Getter";


  /** @domName Document.preferredStylesheetSet */
  String get preferredStylesheetSet native "Document_preferredStylesheetSet_Getter";


  /** @domName Document.readyState */
  String get readyState native "Document_readyState_Getter";


  /** @domName Document.referrer */
  String get $dom_referrer native "Document_referrer_Getter";


  /** @domName Document.selectedStylesheetSet */
  String get selectedStylesheetSet native "Document_selectedStylesheetSet_Getter";


  /** @domName Document.selectedStylesheetSet */
  void set selectedStylesheetSet(String value) native "Document_selectedStylesheetSet_Setter";


  /** @domName Document.styleSheets */
  List<StyleSheet> get $dom_styleSheets native "Document_styleSheets_Getter";


  /** @domName Document.title */
  String get $dom_title native "Document_title_Getter";


  /** @domName Document.title */
  void set $dom_title(String value) native "Document_title_Setter";


  /** @domName Document.webkitFullscreenElement */
  Element get $dom_webkitFullscreenElement native "Document_webkitFullscreenElement_Getter";


  /** @domName Document.webkitFullscreenEnabled */
  bool get $dom_webkitFullscreenEnabled native "Document_webkitFullscreenEnabled_Getter";


  /** @domName Document.webkitHidden */
  bool get $dom_webkitHidden native "Document_webkitHidden_Getter";


  /** @domName Document.webkitIsFullScreen */
  bool get $dom_webkitIsFullScreen native "Document_webkitIsFullScreen_Getter";


  /** @domName Document.webkitPointerLockElement */
  Element get $dom_webkitPointerLockElement native "Document_webkitPointerLockElement_Getter";


  /** @domName Document.webkitVisibilityState */
  String get $dom_webkitVisibilityState native "Document_webkitVisibilityState_Getter";


  /** @domName Document.caretRangeFromPoint */
  Range $dom_caretRangeFromPoint(int x, int y) native "Document_caretRangeFromPoint_Callback";


  /** @domName Document.createCDATASection */
  CDATASection createCDATASection(String data) native "Document_createCDATASection_Callback";


  /** @domName Document.createDocumentFragment */
  DocumentFragment createDocumentFragment() native "Document_createDocumentFragment_Callback";


  /** @domName Document.createElement */
  Element $dom_createElement(String tagName) native "Document_createElement_Callback";


  /** @domName Document.createElementNS */
  Element $dom_createElementNS(String namespaceURI, String qualifiedName) native "Document_createElementNS_Callback";


  /** @domName Document.createEvent */
  Event $dom_createEvent(String eventType) native "Document_createEvent_Callback";


  /** @domName Document.createRange */
  Range createRange() native "Document_createRange_Callback";


  /** @domName Document.createTextNode */
  Text $dom_createTextNode(String data) native "Document_createTextNode_Callback";


  /** @domName Document.createTouch */
  Touch createTouch(LocalWindow window, EventTarget target, int identifier, int pageX, int pageY, int screenX, int screenY, int webkitRadiusX, int webkitRadiusY, num webkitRotationAngle, num webkitForce) native "Document_createTouch_Callback";


  /** @domName Document.createTouchList */
  TouchList $dom_createTouchList() native "Document_createTouchList_Callback";


  /** @domName Document.elementFromPoint */
  Element $dom_elementFromPoint(int x, int y) native "Document_elementFromPoint_Callback";


  /** @domName Document.execCommand */
  bool execCommand(String command, bool userInterface, String value) native "Document_execCommand_Callback";


  /** @domName Document.getCSSCanvasContext */
  CanvasRenderingContext getCSSCanvasContext(String contextId, String name, int width, int height) native "Document_getCSSCanvasContext_Callback";


  /** @domName Document.getElementById */
  Element $dom_getElementById(String elementId) native "Document_getElementById_Callback";


  /** @domName Document.getElementsByClassName */
  List<Node> $dom_getElementsByClassName(String tagname) native "Document_getElementsByClassName_Callback";


  /** @domName Document.getElementsByName */
  List<Node> $dom_getElementsByName(String elementName) native "Document_getElementsByName_Callback";


  /** @domName Document.getElementsByTagName */
  List<Node> $dom_getElementsByTagName(String tagname) native "Document_getElementsByTagName_Callback";


  /** @domName Document.queryCommandEnabled */
  bool queryCommandEnabled(String command) native "Document_queryCommandEnabled_Callback";


  /** @domName Document.queryCommandIndeterm */
  bool queryCommandIndeterm(String command) native "Document_queryCommandIndeterm_Callback";


  /** @domName Document.queryCommandState */
  bool queryCommandState(String command) native "Document_queryCommandState_Callback";


  /** @domName Document.queryCommandSupported */
  bool queryCommandSupported(String command) native "Document_queryCommandSupported_Callback";


  /** @domName Document.queryCommandValue */
  String queryCommandValue(String command) native "Document_queryCommandValue_Callback";


  /** @domName Document.querySelector */
  Element $dom_querySelector(String selectors) native "Document_querySelector_Callback";


  /** @domName Document.querySelectorAll */
  List<Node> $dom_querySelectorAll(String selectors) native "Document_querySelectorAll_Callback";


  /** @domName Document.webkitCancelFullScreen */
  void $dom_webkitCancelFullScreen() native "Document_webkitCancelFullScreen_Callback";


  /** @domName Document.webkitExitFullscreen */
  void $dom_webkitExitFullscreen() native "Document_webkitExitFullscreen_Callback";


  /** @domName Document.webkitExitPointerLock */
  void $dom_webkitExitPointerLock() native "Document_webkitExitPointerLock_Callback";

  // TODO(jacobr): implement all Element methods not on Document.

  Element query(String selectors) {
    // It is fine for our RegExp to detect element id query selectors to have
    // false negatives but not false positives.
    if (new RegExp("^#[_a-zA-Z]\\w*\$").hasMatch(selectors)) {
      return $dom_getElementById(selectors.substring(1));
    }
    return $dom_querySelector(selectors);
  }

  List<Element> queryAll(String selectors) {
    if (new RegExp("""^\\[name=["'][^'"]+['"]\\]\$""").hasMatch(selectors)) {
      final mutableMatches = $dom_getElementsByName(
          selectors.substring(7,selectors.length - 2));
      int len = mutableMatches.length;
      final copyOfMatches = new List<Element>(len);
      for (int i = 0; i < len; ++i) {
        copyOfMatches[i] = mutableMatches[i];
      }
      return new _FrozenElementList._wrap(copyOfMatches);
    } else if (new RegExp("^[*a-zA-Z0-9]+\$").hasMatch(selectors)) {
      final mutableMatches = $dom_getElementsByTagName(selectors);
      int len = mutableMatches.length;
      final copyOfMatches = new List<Element>(len);
      for (int i = 0; i < len; ++i) {
        copyOfMatches[i] = mutableMatches[i];
      }
      return new _FrozenElementList._wrap(copyOfMatches);
    } else {
      return new _FrozenElementList._wrap($dom_querySelectorAll(selectors));
    }
  }
}

class DocumentEvents extends ElementEvents {
  DocumentEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get abort => this['abort'];

  EventListenerList get beforeCopy => this['beforecopy'];

  EventListenerList get beforeCut => this['beforecut'];

  EventListenerList get beforePaste => this['beforepaste'];

  EventListenerList get blur => this['blur'];

  EventListenerList get change => this['change'];

  EventListenerList get click => this['click'];

  EventListenerList get contextMenu => this['contextmenu'];

  EventListenerList get copy => this['copy'];

  EventListenerList get cut => this['cut'];

  EventListenerList get doubleClick => this['dblclick'];

  EventListenerList get drag => this['drag'];

  EventListenerList get dragEnd => this['dragend'];

  EventListenerList get dragEnter => this['dragenter'];

  EventListenerList get dragLeave => this['dragleave'];

  EventListenerList get dragOver => this['dragover'];

  EventListenerList get dragStart => this['dragstart'];

  EventListenerList get drop => this['drop'];

  EventListenerList get error => this['error'];

  EventListenerList get focus => this['focus'];

  EventListenerList get input => this['input'];

  EventListenerList get invalid => this['invalid'];

  EventListenerList get keyDown => this['keydown'];

  EventListenerList get keyPress => this['keypress'];

  EventListenerList get keyUp => this['keyup'];

  EventListenerList get load => this['load'];

  EventListenerList get mouseDown => this['mousedown'];

  EventListenerList get mouseMove => this['mousemove'];

  EventListenerList get mouseOut => this['mouseout'];

  EventListenerList get mouseOver => this['mouseover'];

  EventListenerList get mouseUp => this['mouseup'];

  EventListenerList get mouseWheel => this['mousewheel'];

  EventListenerList get paste => this['paste'];

  EventListenerList get readyStateChange => this['readystatechange'];

  EventListenerList get reset => this['reset'];

  EventListenerList get scroll => this['scroll'];

  EventListenerList get search => this['search'];

  EventListenerList get select => this['select'];

  EventListenerList get selectionChange => this['selectionchange'];

  EventListenerList get selectStart => this['selectstart'];

  EventListenerList get submit => this['submit'];

  EventListenerList get touchCancel => this['touchcancel'];

  EventListenerList get touchEnd => this['touchend'];

  EventListenerList get touchMove => this['touchmove'];

  EventListenerList get touchStart => this['touchstart'];

  EventListenerList get fullscreenChange => this['webkitfullscreenchange'];

  EventListenerList get fullscreenError => this['webkitfullscreenerror'];

  EventListenerList get pointerLockChange => this['webkitpointerlockchange'];

  EventListenerList get pointerLockError => this['webkitpointerlockerror'];
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


Future<CSSStyleDeclaration> _emptyStyleFuture() {
  return _createMeasurementFuture(() => new Element.tag('div').style,
                                  new Completer<CSSStyleDeclaration>());
}

class _FrozenCssClassSet extends CssClassSet {
  void writeClasses(Set s) {
    throw new UnsupportedError(
        'frozen class set cannot be modified');
  }
  Set<String> readClasses() => new Set<String>();

  bool get frozen => true;
}

class DocumentFragment extends Node {
  factory DocumentFragment() => _DocumentFragmentFactoryProvider.createDocumentFragment();

  factory DocumentFragment.html(String html) =>
      _DocumentFragmentFactoryProvider.createDocumentFragment_html(html);

  factory DocumentFragment.svg(String svgContent) =>
      _DocumentFragmentFactoryProvider.createDocumentFragment_svg(svgContent);

  List<Element> get elements => this.children;

  // TODO: The type of value should be Collection<Element>. See http://b/5392897
  void set elements(value) {
    this.children = value;
  }

  List<Element> _children;

  List<Element> get children {
    if (_children == null) {
      _children = new FilteredElementList(this);
    }
    return _children;
  }

  void set children(Collection<Element> value) {
    // Copy list first since we don't want liveness during iteration.
    List copy = new List.from(value);
    var children = this.children;
    children.clear();
    children.addAll(copy);
  }

  Element query(String selectors) => $dom_querySelector(selectors);

  List<Element> queryAll(String selectors) =>
    new _FrozenElementList._wrap($dom_querySelectorAll(selectors));

  String get innerHTML {
    final e = new Element.tag("div");
    e.nodes.add(this.clone(true));
    return e.innerHTML;
  }

  String get outerHTML => innerHTML;

  // TODO(nweiz): Do we want to support some variant of innerHTML for XML and/or
  // SVG strings?
  void set innerHTML(String value) {
    this.nodes.clear();

    final e = new Element.tag("div");
    e.innerHTML = value;

    // Copy list first since we don't want liveness during iteration.
    List nodes = new List.from(e.nodes);
    this.nodes.addAll(nodes);
  }

  Node _insertAdjacentNode(String where, Node node) {
    switch (where.toLowerCase()) {
      case "beforebegin": return null;
      case "afterend": return null;
      case "afterbegin":
        var first = this.nodes.length > 0 ? this.nodes[0] : null;
        this.insertBefore(node, first);
        return node;
      case "beforeend":
        this.nodes.add(node);
        return node;
      default:
        throw new ArgumentError("Invalid position ${where}");
    }
  }

  Element insertAdjacentElement(String where, Element element)
    => this._insertAdjacentNode(where, element);

  void insertAdjacentText(String where, String text) {
    this._insertAdjacentNode(where, new Text(text));
  }

  void insertAdjacentHTML(String where, String text) {
    this._insertAdjacentNode(where, new DocumentFragment.html(text));
  }

  void addText(String text) {
    this.insertAdjacentText('beforeend', text);
  }

  void addHtml(String text) {
    this.insertAdjacentHTML('beforeend', text);
  }

  // If we can come up with a semi-reasonable default value for an Element
  // getter, we'll use it. In general, these return the same values as an
  // element that has no parent.
  String get contentEditable => "false";
  bool get isContentEditable => false;
  bool get draggable => false;
  bool get hidden => false;
  bool get spellcheck => false;
  bool get translate => false;
  int get tabIndex => -1;
  String get id => "";
  String get title => "";
  String get tagName => "";
  String get webkitdropzone => "";
  String get webkitRegionOverflow => "";
  Element get $m_firstElementChild {
    if (elements.length > 0) {
      return elements[0];
    }
    return null;
  }
  Element get $m_lastElementChild() => elements.last;
  Element get nextElementSibling => null;
  Element get previousElementSibling => null;
  Element get offsetParent => null;
  Element get parent => null;
  Map<String, String> get attributes => const {};
  CssClassSet get classes => new _FrozenCssClassSet();
  Map<String, String> get dataAttributes => const {};
  CSSStyleDeclaration get style => new Element.tag('div').style;
  Future<CSSStyleDeclaration> get computedStyle =>
      _emptyStyleFuture();
  Future<CSSStyleDeclaration> getComputedStyle(String pseudoElement) =>
      _emptyStyleFuture();
  bool matchesSelector(String selectors) => false;

  // Imperative Element methods are made into no-ops, as they are on parentless
  // elements.
  void blur() {}
  void focus() {}
  void click() {}
  void scrollByLines(int lines) {}
  void scrollByPages(int pages) {}
  void scrollIntoView([bool centerIfNeeded]) {}
  void webkitRequestFullScreen(int flags) {}
  void webkitRequestFullscreen() {}

  // Setters throw errors rather than being no-ops because we aren't going to
  // retain the values that were set, and erroring out seems clearer.
  void set attributes(Map<String, String> value) {
    throw new UnsupportedError(
      "Attributes can't be set for document fragments.");
  }

  void set classes(Collection<String> value) {
    throw new UnsupportedError(
      "Classes can't be set for document fragments.");
  }

  void set dataAttributes(Map<String, String> value) {
    throw new UnsupportedError(
      "Data attributes can't be set for document fragments.");
  }

  void set contentEditable(String value) {
    throw new UnsupportedError(
      "Content editable can't be set for document fragments.");
  }

  String get dir {
    throw new UnsupportedError(
      "Document fragments don't support text direction.");
  }

  void set dir(String value) {
    throw new UnsupportedError(
      "Document fragments don't support text direction.");
  }

  void set draggable(bool value) {
    throw new UnsupportedError(
      "Draggable can't be set for document fragments.");
  }

  void set hidden(bool value) {
    throw new UnsupportedError(
      "Hidden can't be set for document fragments.");
  }

  void set id(String value) {
    throw new UnsupportedError(
      "ID can't be set for document fragments.");
  }

  String get lang {
    throw new UnsupportedError(
      "Document fragments don't support language.");
  }

  void set lang(String value) {
    throw new UnsupportedError(
      "Document fragments don't support language.");
  }

  void set scrollLeft(int value) {
    throw new UnsupportedError(
      "Document fragments don't support scrolling.");
  }

  void set scrollTop(int value) {
    throw new UnsupportedError(
      "Document fragments don't support scrolling.");
  }

  void set spellcheck(bool value) {
     throw new UnsupportedError(
      "Spellcheck can't be set for document fragments.");
  }

  void set translate(bool value) {
     throw new UnsupportedError(
      "Spellcheck can't be set for document fragments.");
  }

  void set tabIndex(int value) {
    throw new UnsupportedError(
      "Tab index can't be set for document fragments.");
  }

  void set title(String value) {
    throw new UnsupportedError(
      "Title can't be set for document fragments.");
  }

  void set webkitdropzone(String value) {
    throw new UnsupportedError(
      "WebKit drop zone can't be set for document fragments.");
  }

  void set webkitRegionOverflow(String value) {
    throw new UnsupportedError(
      "WebKit region overflow can't be set for document fragments.");
  }

  DocumentFragment.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  ElementEvents get on =>
    new ElementEvents(this);


  /** @domName DocumentFragment.querySelector */
  Element $dom_querySelector(String selectors) native "DocumentFragment_querySelector_Callback";


  /** @domName DocumentFragment.querySelectorAll */
  List<Node> $dom_querySelectorAll(String selectors) native "DocumentFragment_querySelectorAll_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName DocumentType
class DocumentType extends Node {
  DocumentType.internal(): super.internal();


  /** @domName DocumentType.entities */
  NamedNodeMap get entities native "DocumentType_entities_Getter";


  /** @domName DocumentType.internalSubset */
  String get internalSubset native "DocumentType_internalSubset_Getter";


  /** @domName DocumentType.name */
  String get name native "DocumentType_name_Getter";


  /** @domName DocumentType.notations */
  NamedNodeMap get notations native "DocumentType_notations_Getter";


  /** @domName DocumentType.publicId */
  String get publicId native "DocumentType_publicId_Getter";


  /** @domName DocumentType.systemId */
  String get systemId native "DocumentType_systemId_Getter";


  /** @domName DocumentType.remove */
  void remove() native "DocumentType_remove_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName DynamicsCompressorNode
class DynamicsCompressorNode extends AudioNode {
  DynamicsCompressorNode.internal(): super.internal();


  /** @domName DynamicsCompressorNode.attack */
  AudioParam get attack native "DynamicsCompressorNode_attack_Getter";


  /** @domName DynamicsCompressorNode.knee */
  AudioParam get knee native "DynamicsCompressorNode_knee_Getter";


  /** @domName DynamicsCompressorNode.ratio */
  AudioParam get ratio native "DynamicsCompressorNode_ratio_Getter";


  /** @domName DynamicsCompressorNode.reduction */
  AudioParam get reduction native "DynamicsCompressorNode_reduction_Getter";


  /** @domName DynamicsCompressorNode.release */
  AudioParam get release native "DynamicsCompressorNode_release_Getter";


  /** @domName DynamicsCompressorNode.threshold */
  AudioParam get threshold native "DynamicsCompressorNode_threshold_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName EXTTextureFilterAnisotropic
class EXTTextureFilterAnisotropic extends NativeFieldWrapperClass1 {
  EXTTextureFilterAnisotropic.internal();

  static const int MAX_TEXTURE_MAX_ANISOTROPY_EXT = 0x84FF;

  static const int TEXTURE_MAX_ANISOTROPY_EXT = 0x84FE;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// TODO(jacobr): use _Lists.dart to remove some of the duplicated
// functionality.
class _ChildrenElementList implements List {
  // Raw Element.
  final Element _element;
  final HTMLCollection _childElements;

  _ChildrenElementList._wrap(Element element)
    : _childElements = element.$dom_children,
      _element = element;

  List<Element> _toList() {
    final output = new List(_childElements.length);
    for (int i = 0, len = _childElements.length; i < len; i++) {
      output[i] = _childElements[i];
    }
    return output;
  }

  bool contains(Element element) => _childElements.contains(element);

  void forEach(void f(Element element)) {
    for (Element element in _childElements) {
      f(element);
    }
  }

  List<Element> filter(bool f(Element element)) {
    final output = [];
    forEach((Element element) {
      if (f(element)) {
        output.add(element);
      }
    });
    return new _FrozenElementList._wrap(output);
  }

  bool every(bool f(Element element)) {
    for (Element element in this) {
      if (!f(element)) {
        return false;
      }
    };
    return true;
  }

  bool some(bool f(Element element)) {
    for (Element element in this) {
      if (f(element)) {
        return true;
      }
    };
    return false;
  }

  Collection map(f(Element element)) {
    final out = [];
    for (Element el in this) {
      out.add(f(el));
    }
    return out;
  }

  bool get isEmpty {
    return _element.$dom_firstElementChild == null;
  }

  int get length {
    return _childElements.length;
  }

  Element operator [](int index) {
    return _childElements[index];
  }

  void operator []=(int index, Element value) {
    _element.$dom_replaceChild(value, _childElements[index]);
  }

   void set length(int newLength) {
     // TODO(jacobr): remove children when length is reduced.
     throw new UnsupportedError('');
   }

  Element add(Element value) {
    _element.$dom_appendChild(value);
    return value;
  }

  Element addLast(Element value) => add(value);

  Iterator<Element> iterator() => _toList().iterator();

  void addAll(Collection<Element> collection) {
    for (Element element in collection) {
      _element.$dom_appendChild(element);
    }
  }

  void sort([Comparator<Element> compare = Comparable.compare]) {
    throw new UnsupportedError('TODO(jacobr): should we impl?');
  }

  void setRange(int start, int rangeLength, List from, [int startFrom = 0]) {
    throw new UnimplementedError();
  }

  void removeRange(int start, int rangeLength) {
    throw new UnimplementedError();
  }

  void insertRange(int start, int rangeLength, [initialValue = null]) {
    throw new UnimplementedError();
  }

  List getRange(int start, int rangeLength) =>
    new _FrozenElementList._wrap(_Lists.getRange(this, start, rangeLength,
        []));

  int indexOf(Element element, [int start = 0]) {
    return _Lists.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(Element element, [int start = null]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  void clear() {
    // It is unclear if we want to keep non element nodes?
    _element.text = '';
  }

  Element removeLast() {
    final result = this.last;
    if (result != null) {
      _element.$dom_removeChild(result);
    }
    return result;
  }

  Element get first {
    return _element.$dom_firstElementChild;
  }


  Element get last {
    return _element.$dom_lastElementChild;
  }
}

// TODO(jacobr): this is an inefficient implementation but it is hard to see
// a better option given that we cannot quite force NodeList to be an
// ElementList as there are valid cases where a NodeList JavaScript object
// contains Node objects that are not Elements.
class _FrozenElementList implements List {
  final List<Node> _nodeList;

  _FrozenElementList._wrap(this._nodeList);

  bool contains(Element element) {
    for (Element el in this) {
      if (el == element) return true;
    }
    return false;
  }

  void forEach(void f(Element element)) {
    for (Element el in this) {
      f(el);
    }
  }

  Collection map(f(Element element)) {
    final out = [];
    for (Element el in this) {
      out.add(f(el));
    }
    return out;
  }

  List<Element> filter(bool f(Element element)) {
    final out = [];
    for (Element el in this) {
      if (f(el)) out.add(el);
    }
    return out;
  }

  bool every(bool f(Element element)) {
    for(Element element in this) {
      if (!f(element)) {
        return false;
      }
    };
    return true;
  }

  bool some(bool f(Element element)) {
    for(Element element in this) {
      if (f(element)) {
        return true;
      }
    };
    return false;
  }

  bool get isEmpty => _nodeList.isEmpty;

  int get length => _nodeList.length;

  Element operator [](int index) => _nodeList[index];

  void operator []=(int index, Element value) {
    throw new UnsupportedError('');
  }

  void set length(int newLength) {
    _nodeList.length = newLength;
  }

  void add(Element value) {
    throw new UnsupportedError('');
  }

  void addLast(Element value) {
    throw new UnsupportedError('');
  }

  Iterator<Element> iterator() => new _FrozenElementListIterator(this);

  void addAll(Collection<Element> collection) {
    throw new UnsupportedError('');
  }

  void sort([Comparator<Element> compare = Comparable.compare]) {
    throw new UnsupportedError('');
  }

  void setRange(int start, int rangeLength, List from, [int startFrom = 0]) {
    throw new UnsupportedError('');
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError('');
  }

  void insertRange(int start, int rangeLength, [initialValue = null]) {
    throw new UnsupportedError('');
  }

  List<Element> getRange(int start, int rangeLength) =>
    new _FrozenElementList._wrap(_nodeList.getRange(start, rangeLength));

  int indexOf(Element element, [int start = 0]) =>
    _nodeList.indexOf(element, start);

  int lastIndexOf(Element element, [int start = null]) =>
    _nodeList.lastIndexOf(element, start);

  void clear() {
    throw new UnsupportedError('');
  }

  Element removeLast() {
    throw new UnsupportedError('');
  }

  Element get first => _nodeList.first;

  Element get last => _nodeList.last;
}

class _FrozenElementListIterator implements Iterator<Element> {
  final _FrozenElementList _list;
  int _index = 0;

  _FrozenElementListIterator(this._list);

  /**
   * Gets the next element in the iteration. Throws a
   * [StateError("No more elements")] if no element is left.
   */
  Element next() {
    if (!hasNext) {
      throw new StateError("No more elements");
    }

    return _list[_index++];
  }

  /**
   * Returns whether the [Iterator] has elements left.
   */
  bool get hasNext => _index < _list.length;
}

class _ElementCssClassSet extends CssClassSet {

  final Element _element;

  _ElementCssClassSet(this._element);

  Set<String> readClasses() {
    var s = new Set<String>();
    var classname = _element.$dom_className;

    for (String name in classname.split(' ')) {
      String trimmed = name.trim();
      if (!trimmed.isEmpty) {
        s.add(trimmed);
      }
    }
    return s;
  }

  void writeClasses(Set<String> s) {
    List list = new List.from(s);
    _element.$dom_className = Strings.join(list, ' ');
  }
}

class _SimpleClientRect implements ClientRect {
  final num left;
  final num top;
  final num width;
  final num height;
  num get right => left + width;
  num get bottom => top + height;

  const _SimpleClientRect(this.left, this.top, this.width, this.height);

  bool operator ==(ClientRect other) {
    return other != null && left == other.left && top == other.top
        && width == other.width && height == other.height;
  }

  String toString() => "($left, $top, $width, $height)";
}

abstract class Element extends Node implements ElementTraversal {

  factory Element.html(String html) =>
      _ElementFactoryProvider.createElement_html(html);
  factory Element.tag(String tag) =>
      _ElementFactoryProvider.createElement_tag(tag);

  /**
   * @domName Element.hasAttribute, Element.getAttribute, Element.setAttribute,
   *   Element.removeAttribute
   */
  Map<String, String> get attributes => new _ElementAttributeMap(this);

  void set attributes(Map<String, String> value) {
    Map<String, String> attributes = this.attributes;
    attributes.clear();
    for (String key in value.keys) {
      attributes[key] = value[key];
    }
  }

  void set elements(Collection<Element> value) {
    this.children = value;
  }

  /**
   * Deprecated, use [children] instead.
   */
  List<Element> get elements => this.children;

  /**
   * @domName childElementCount, firstElementChild, lastElementChild,
   *   children, Node.nodes.add
   */
  List<Element> get children => new _ChildrenElementList._wrap(this);

  void set children(Collection<Element> value) {
    // Copy list first since we don't want liveness during iteration.
    List copy = new List.from(value);
    var children = this.children;
    children.clear();
    children.addAll(copy);
  }

  Element query(String selectors) => $dom_querySelector(selectors);

  List<Element> queryAll(String selectors) =>
    new _FrozenElementList._wrap($dom_querySelectorAll(selectors));

  /** @domName className, classList */
  CssClassSet get classes => new _ElementCssClassSet(this);

  void set classes(Collection<String> value) {
    CssClassSet classSet = classes;
    classSet.clear();
    classSet.addAll(value);
  }

  Map<String, String> get dataAttributes =>
    new _DataAttributeMap(attributes);

  void set dataAttributes(Map<String, String> value) {
    final dataAttributes = this.dataAttributes;
    dataAttributes.clear();
    for (String key in value.keys) {
      dataAttributes[key] = value[key];
    }
  }

  /**
   * Gets a map for manipulating the attributes of a particular namespace.
   * This is primarily useful for SVG attributes such as xref:link.
   */
  Map<String, String> getNamespacedAttributes(String namespace) {
    return new _NamespacedAttributeMap(this, namespace);
  }

  /** @domName Window.getComputedStyle */
  Future<CSSStyleDeclaration> get computedStyle {
     // TODO(jacobr): last param should be null, see b/5045788
     return getComputedStyle('');
  }

  /** @domName Window.getComputedStyle */
  Future<CSSStyleDeclaration> getComputedStyle(String pseudoElement) {
    return _createMeasurementFuture(
        () => window.$dom_getComputedStyle(this, pseudoElement),
        new Completer<CSSStyleDeclaration>());
  }

  /**
   * Adds the specified text as a text node after the last child of this.
   */
  void addText(String text) {
    this.insertAdjacentText('beforeend', text);
  }

  /**
   * Parses the specified text as HTML and adds the resulting node after the
   * last child of this.
   */
  void addHtml(String text) {
    this.insertAdjacentHTML('beforeend', text);
  }

  // Hooks to support custom WebComponents.
  /**
   * Experimental support for [web components][wc]. This field stores a
   * reference to the component implementation. It was inspired by Mozilla's
   * [x-tags][] project. Please note: in the future it may be possible to
   * `extend Element` from your class, in which case this field will be
   * deprecated and will simply return this [Element] object.
   *
   * [wc]: http://dvcs.w3.org/hg/webcomponents/raw-file/tip/explainer/index.html
   * [x-tags]: http://x-tags.org/
   */
  var xtag;

  noSuchMethod(InvocationMirror invocation) {
    if (dynamicUnknownElementDispatcher == null) {
      throw new NoSuchMethodError(this, invocation.memberName,
                                        invocation.positionalArguments,
                                        invocation.namedArguments);
    } else {
      String hackedName = invocation.memberName;
      if (invocation.isGetter) hackedName = "get:$hackedName";
      if (invocation.isSetter) hackedName = "set:$hackedName";
      return dynamicUnknownElementDispatcher(this,
                                             hackedName,
                                             invocation.positionalArguments);
    }
  }


  Element.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  ElementEvents get on =>
    new ElementEvents(this);

  /// @domName HTMLElement.children; @docsEditable true
  HTMLCollection get $dom_children;

  /// @domName HTMLElement.contentEditable; @docsEditable true
  String contentEditable;

  /// @domName HTMLElement.dir; @docsEditable true
  String dir;

  /// @domName HTMLElement.draggable; @docsEditable true
  bool draggable;

  /// @domName HTMLElement.hidden; @docsEditable true
  bool hidden;

  /// @domName HTMLElement.id; @docsEditable true
  String id;

  /// @domName HTMLElement.innerHTML; @docsEditable true
  String innerHTML;

  /// @domName HTMLElement.isContentEditable; @docsEditable true
  bool get isContentEditable;

  /// @domName HTMLElement.lang; @docsEditable true
  String lang;

  /// @domName HTMLElement.outerHTML; @docsEditable true
  String get outerHTML;

  /// @domName HTMLElement.spellcheck; @docsEditable true
  bool spellcheck;

  /// @domName HTMLElement.tabIndex; @docsEditable true
  int tabIndex;

  /// @domName HTMLElement.title; @docsEditable true
  String title;

  /// @domName HTMLElement.translate; @docsEditable true
  bool translate;

  /// @domName HTMLElement.webkitdropzone; @docsEditable true
  String webkitdropzone;

  /// @domName HTMLElement.click; @docsEditable true
  void click();

  /// @domName HTMLElement.insertAdjacentElement; @docsEditable true
  Element insertAdjacentElement(String where, Element element);

  /// @domName HTMLElement.insertAdjacentHTML; @docsEditable true
  void insertAdjacentHTML(String where, String html);

  /// @domName HTMLElement.insertAdjacentText; @docsEditable true
  void insertAdjacentText(String where, String text);

  static const int ALLOW_KEYBOARD_INPUT = 1;


  /** @domName Element.childElementCount */
  int get $dom_childElementCount native "Element_childElementCount_Getter";


  /** @domName Element.className */
  String get $dom_className native "Element_className_Getter";


  /** @domName Element.className */
  void set $dom_className(String value) native "Element_className_Setter";


  /** @domName Element.clientHeight */
  int get clientHeight native "Element_clientHeight_Getter";


  /** @domName Element.clientLeft */
  int get clientLeft native "Element_clientLeft_Getter";


  /** @domName Element.clientTop */
  int get clientTop native "Element_clientTop_Getter";


  /** @domName Element.clientWidth */
  int get clientWidth native "Element_clientWidth_Getter";


  /** @domName Element.dataset */
  Map<String, String> get dataset native "Element_dataset_Getter";


  /** @domName Element.firstElementChild */
  Element get $dom_firstElementChild native "Element_firstElementChild_Getter";


  /** @domName Element.lastElementChild */
  Element get $dom_lastElementChild native "Element_lastElementChild_Getter";


  /** @domName Element.nextElementSibling */
  Element get nextElementSibling native "Element_nextElementSibling_Getter";


  /** @domName Element.offsetHeight */
  int get offsetHeight native "Element_offsetHeight_Getter";


  /** @domName Element.offsetLeft */
  int get offsetLeft native "Element_offsetLeft_Getter";


  /** @domName Element.offsetParent */
  Element get offsetParent native "Element_offsetParent_Getter";


  /** @domName Element.offsetTop */
  int get offsetTop native "Element_offsetTop_Getter";


  /** @domName Element.offsetWidth */
  int get offsetWidth native "Element_offsetWidth_Getter";


  /** @domName Element.previousElementSibling */
  Element get previousElementSibling native "Element_previousElementSibling_Getter";


  /** @domName Element.scrollHeight */
  int get scrollHeight native "Element_scrollHeight_Getter";


  /** @domName Element.scrollLeft */
  int get scrollLeft native "Element_scrollLeft_Getter";


  /** @domName Element.scrollLeft */
  void set scrollLeft(int value) native "Element_scrollLeft_Setter";


  /** @domName Element.scrollTop */
  int get scrollTop native "Element_scrollTop_Getter";


  /** @domName Element.scrollTop */
  void set scrollTop(int value) native "Element_scrollTop_Setter";


  /** @domName Element.scrollWidth */
  int get scrollWidth native "Element_scrollWidth_Getter";


  /** @domName Element.style */
  CSSStyleDeclaration get style native "Element_style_Getter";


  /** @domName Element.tagName */
  String get tagName native "Element_tagName_Getter";


  /** @domName Element.blur */
  void blur() native "Element_blur_Callback";


  /** @domName Element.focus */
  void focus() native "Element_focus_Callback";


  /** @domName Element.getAttribute */
  String $dom_getAttribute(String name) native "Element_getAttribute_Callback";


  /** @domName Element.getAttributeNS */
  String $dom_getAttributeNS(String namespaceURI, String localName) native "Element_getAttributeNS_Callback";


  /** @domName Element.getBoundingClientRect */
  ClientRect getBoundingClientRect() native "Element_getBoundingClientRect_Callback";


  /** @domName Element.getClientRects */
  List<ClientRect> getClientRects() native "Element_getClientRects_Callback";


  /** @domName Element.getElementsByClassName */
  List<Node> $dom_getElementsByClassName(String name) native "Element_getElementsByClassName_Callback";


  /** @domName Element.getElementsByTagName */
  List<Node> $dom_getElementsByTagName(String name) native "Element_getElementsByTagName_Callback";


  /** @domName Element.hasAttribute */
  bool $dom_hasAttribute(String name) native "Element_hasAttribute_Callback";


  /** @domName Element.hasAttributeNS */
  bool $dom_hasAttributeNS(String namespaceURI, String localName) native "Element_hasAttributeNS_Callback";


  /** @domName Element.querySelector */
  Element $dom_querySelector(String selectors) native "Element_querySelector_Callback";


  /** @domName Element.querySelectorAll */
  List<Node> $dom_querySelectorAll(String selectors) native "Element_querySelectorAll_Callback";


  /** @domName Element.remove */
  void remove() native "Element_remove_Callback";


  /** @domName Element.removeAttribute */
  void $dom_removeAttribute(String name) native "Element_removeAttribute_Callback";


  /** @domName Element.removeAttributeNS */
  void $dom_removeAttributeNS(String namespaceURI, String localName) native "Element_removeAttributeNS_Callback";


  /** @domName Element.scrollByLines */
  void scrollByLines(int lines) native "Element_scrollByLines_Callback";


  /** @domName Element.scrollByPages */
  void scrollByPages(int pages) native "Element_scrollByPages_Callback";

  void scrollIntoView([/*boolean*/ centerIfNeeded]) {
    if (?centerIfNeeded) {
      _scrollIntoViewIfNeeded_1(centerIfNeeded);
      return;
    }
    _scrollIntoViewIfNeeded_2();
  }


  /** @domName Element.scrollIntoViewIfNeeded_1 */
  void _scrollIntoViewIfNeeded_1(centerIfNeeded) native "Element_scrollIntoViewIfNeeded_1_Callback";


  /** @domName Element.scrollIntoViewIfNeeded_2 */
  void _scrollIntoViewIfNeeded_2() native "Element_scrollIntoViewIfNeeded_2_Callback";


  /** @domName Element.setAttribute */
  void $dom_setAttribute(String name, String value) native "Element_setAttribute_Callback";


  /** @domName Element.setAttributeNS */
  void $dom_setAttributeNS(String namespaceURI, String qualifiedName, String value) native "Element_setAttributeNS_Callback";


  /** @domName Element.webkitMatchesSelector */
  bool matchesSelector(String selectors) native "Element_webkitMatchesSelector_Callback";


  /** @domName Element.webkitRequestFullScreen */
  void webkitRequestFullScreen(int flags) native "Element_webkitRequestFullScreen_Callback";


  /** @domName Element.webkitRequestFullscreen */
  void webkitRequestFullscreen() native "Element_webkitRequestFullscreen_Callback";


  /** @domName Element.webkitRequestPointerLock */
  void webkitRequestPointerLock() native "Element_webkitRequestPointerLock_Callback";

}

// Temporary dispatch hook to support WebComponents.
Function dynamicUnknownElementDispatcher;

final _START_TAG_REGEXP = new RegExp('<(\\w+)');
class _ElementFactoryProvider {
  static final _CUSTOM_PARENT_TAG_MAP = const {
    'body' : 'html',
    'head' : 'html',
    'caption' : 'table',
    'td': 'tr',
    'colgroup': 'table',
    'col' : 'colgroup',
    'tr' : 'tbody',
    'tbody' : 'table',
    'tfoot' : 'table',
    'thead' : 'table',
    'track' : 'audio',
  };

  /** @domName Document.createElement */
  static Element createElement_html(String html) {
    // TODO(jacobr): this method can be made more robust and performant.
    // 1) Cache the dummy parent elements required to use innerHTML rather than
    //    creating them every call.
    // 2) Verify that the html does not contain leading or trailing text nodes.
    // 3) Verify that the html does not contain both <head> and <body> tags.
    // 4) Detatch the created element from its dummy parent.
    String parentTag = 'div';
    String tag;
    final match = _START_TAG_REGEXP.firstMatch(html);
    if (match != null) {
      tag = match.group(1).toLowerCase();
      if (_CUSTOM_PARENT_TAG_MAP.containsKey(tag)) {
        parentTag = _CUSTOM_PARENT_TAG_MAP[tag];
      }
    }
    final Element temp = new Element.tag(parentTag);
    temp.innerHTML = html;

    Element element;
    if (temp.children.length == 1) {
      element = temp.children[0];
    } else if (parentTag == 'html' && temp.children.length == 2) {
      // Work around for edge case in WebKit and possibly other browsers where
      // both body and head elements are created even though the inner html
      // only contains a head or body element.
      element = temp.children[tag == 'head' ? 0 : 1];
    } else {
      throw new ArgumentError('HTML had ${temp.children.length} '
          'top level elements but 1 expected');
    }
    element.remove();
    return element;
  }

  /** @domName Document.createElement */
  static Element createElement_tag(String tag) =>
      document.$dom_createElement(tag);
}

class ElementEvents extends Events {
  ElementEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get abort => this['abort'];

  EventListenerList get beforeCopy => this['beforecopy'];

  EventListenerList get beforeCut => this['beforecut'];

  EventListenerList get beforePaste => this['beforepaste'];

  EventListenerList get blur => this['blur'];

  EventListenerList get change => this['change'];

  EventListenerList get click => this['click'];

  EventListenerList get contextMenu => this['contextmenu'];

  EventListenerList get copy => this['copy'];

  EventListenerList get cut => this['cut'];

  EventListenerList get doubleClick => this['dblclick'];

  EventListenerList get drag => this['drag'];

  EventListenerList get dragEnd => this['dragend'];

  EventListenerList get dragEnter => this['dragenter'];

  EventListenerList get dragLeave => this['dragleave'];

  EventListenerList get dragOver => this['dragover'];

  EventListenerList get dragStart => this['dragstart'];

  EventListenerList get drop => this['drop'];

  EventListenerList get error => this['error'];

  EventListenerList get focus => this['focus'];

  EventListenerList get input => this['input'];

  EventListenerList get invalid => this['invalid'];

  EventListenerList get keyDown => this['keydown'];

  EventListenerList get keyPress => this['keypress'];

  EventListenerList get keyUp => this['keyup'];

  EventListenerList get load => this['load'];

  EventListenerList get mouseDown => this['mousedown'];

  EventListenerList get mouseMove => this['mousemove'];

  EventListenerList get mouseOut => this['mouseout'];

  EventListenerList get mouseOver => this['mouseover'];

  EventListenerList get mouseUp => this['mouseup'];

  EventListenerList get mouseWheel => this['mousewheel'];

  EventListenerList get paste => this['paste'];

  EventListenerList get reset => this['reset'];

  EventListenerList get scroll => this['scroll'];

  EventListenerList get search => this['search'];

  EventListenerList get select => this['select'];

  EventListenerList get selectStart => this['selectstart'];

  EventListenerList get submit => this['submit'];

  EventListenerList get touchCancel => this['touchcancel'];

  EventListenerList get touchEnd => this['touchend'];

  EventListenerList get touchEnter => this['touchenter'];

  EventListenerList get touchLeave => this['touchleave'];

  EventListenerList get touchMove => this['touchmove'];

  EventListenerList get touchStart => this['touchstart'];

  EventListenerList get transitionEnd => this['webkitTransitionEnd'];

  EventListenerList get fullscreenChange => this['webkitfullscreenchange'];

  EventListenerList get fullscreenError => this['webkitfullscreenerror'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName ElementTimeControl
class ElementTimeControl extends NativeFieldWrapperClass1 {
  ElementTimeControl.internal();


  /** @domName ElementTimeControl.beginElement */
  void beginElement() native "ElementTimeControl_beginElement_Callback";


  /** @domName ElementTimeControl.beginElementAt */
  void beginElementAt(num offset) native "ElementTimeControl_beginElementAt_Callback";


  /** @domName ElementTimeControl.endElement */
  void endElement() native "ElementTimeControl_endElement_Callback";


  /** @domName ElementTimeControl.endElementAt */
  void endElementAt(num offset) native "ElementTimeControl_endElementAt_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName ElementTraversal
class ElementTraversal extends NativeFieldWrapperClass1 {
  ElementTraversal.internal();


  /** @domName ElementTraversal.childElementCount */
  int get childElementCount native "ElementTraversal_childElementCount_Getter";


  /** @domName ElementTraversal.firstElementChild */
  Element get firstElementChild native "ElementTraversal_firstElementChild_Getter";


  /** @domName ElementTraversal.lastElementChild */
  Element get lastElementChild native "ElementTraversal_lastElementChild_Getter";


  /** @domName ElementTraversal.nextElementSibling */
  Element get nextElementSibling native "ElementTraversal_nextElementSibling_Getter";


  /** @domName ElementTraversal.previousElementSibling */
  Element get previousElementSibling native "ElementTraversal_previousElementSibling_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLEmbedElement
class EmbedElement extends _Element_Merged {

  factory EmbedElement() => document.$dom_createElement("embed");
  EmbedElement.internal(): super.internal();


  /** @domName HTMLEmbedElement.align */
  String get align native "HTMLEmbedElement_align_Getter";


  /** @domName HTMLEmbedElement.align */
  void set align(String value) native "HTMLEmbedElement_align_Setter";


  /** @domName HTMLEmbedElement.height */
  String get height native "HTMLEmbedElement_height_Getter";


  /** @domName HTMLEmbedElement.height */
  void set height(String value) native "HTMLEmbedElement_height_Setter";


  /** @domName HTMLEmbedElement.name */
  String get name native "HTMLEmbedElement_name_Getter";


  /** @domName HTMLEmbedElement.name */
  void set name(String value) native "HTMLEmbedElement_name_Setter";


  /** @domName HTMLEmbedElement.src */
  String get src native "HTMLEmbedElement_src_Getter";


  /** @domName HTMLEmbedElement.src */
  void set src(String value) native "HTMLEmbedElement_src_Setter";


  /** @domName HTMLEmbedElement.type */
  String get type native "HTMLEmbedElement_type_Getter";


  /** @domName HTMLEmbedElement.type */
  void set type(String value) native "HTMLEmbedElement_type_Setter";


  /** @domName HTMLEmbedElement.width */
  String get width native "HTMLEmbedElement_width_Getter";


  /** @domName HTMLEmbedElement.width */
  void set width(String value) native "HTMLEmbedElement_width_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName EntityReference
class EntityReference extends Node {
  EntityReference.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void EntriesCallback(List<Entry> entries);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Entry
class Entry extends NativeFieldWrapperClass1 {
  Entry.internal();


  /** @domName Entry.filesystem */
  DOMFileSystem get filesystem native "Entry_filesystem_Getter";


  /** @domName Entry.fullPath */
  String get fullPath native "Entry_fullPath_Getter";


  /** @domName Entry.isDirectory */
  bool get isDirectory native "Entry_isDirectory_Getter";


  /** @domName Entry.isFile */
  bool get isFile native "Entry_isFile_Getter";


  /** @domName Entry.name */
  String get name native "Entry_name_Getter";

  void copyTo(/*DirectoryEntry*/ parent, [/*DOMString*/ name, /*EntryCallback*/ successCallback, /*ErrorCallback*/ errorCallback]) {
    if (?name) {
      _copyTo_1(parent, name, successCallback, errorCallback);
      return;
    }
    _copyTo_2(parent);
  }


  /** @domName Entry.copyTo_1 */
  void _copyTo_1(parent, name, successCallback, errorCallback) native "Entry_copyTo_1_Callback";


  /** @domName Entry.copyTo_2 */
  void _copyTo_2(parent) native "Entry_copyTo_2_Callback";


  /** @domName Entry.getMetadata */
  void getMetadata(MetadataCallback successCallback, [ErrorCallback errorCallback]) native "Entry_getMetadata_Callback";


  /** @domName Entry.getParent */
  void getParent([EntryCallback successCallback, ErrorCallback errorCallback]) native "Entry_getParent_Callback";

  void moveTo(/*DirectoryEntry*/ parent, [/*DOMString*/ name, /*EntryCallback*/ successCallback, /*ErrorCallback*/ errorCallback]) {
    if (?name) {
      _moveTo_1(parent, name, successCallback, errorCallback);
      return;
    }
    _moveTo_2(parent);
  }


  /** @domName Entry.moveTo_1 */
  void _moveTo_1(parent, name, successCallback, errorCallback) native "Entry_moveTo_1_Callback";


  /** @domName Entry.moveTo_2 */
  void _moveTo_2(parent) native "Entry_moveTo_2_Callback";


  /** @domName Entry.remove */
  void remove(VoidCallback successCallback, [ErrorCallback errorCallback]) native "Entry_remove_Callback";


  /** @domName Entry.toURL */
  String toURL() native "Entry_toURL_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void EntryCallback(Entry entry);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName EntrySync
class EntrySync extends NativeFieldWrapperClass1 {
  EntrySync.internal();


  /** @domName EntrySync.filesystem */
  DOMFileSystemSync get filesystem native "EntrySync_filesystem_Getter";


  /** @domName EntrySync.fullPath */
  String get fullPath native "EntrySync_fullPath_Getter";


  /** @domName EntrySync.isDirectory */
  bool get isDirectory native "EntrySync_isDirectory_Getter";


  /** @domName EntrySync.isFile */
  bool get isFile native "EntrySync_isFile_Getter";


  /** @domName EntrySync.name */
  String get name native "EntrySync_name_Getter";


  /** @domName EntrySync.copyTo */
  EntrySync copyTo(DirectoryEntrySync parent, String name) native "EntrySync_copyTo_Callback";


  /** @domName EntrySync.getMetadata */
  Metadata getMetadata() native "EntrySync_getMetadata_Callback";


  /** @domName EntrySync.getParent */
  EntrySync getParent() native "EntrySync_getParent_Callback";


  /** @domName EntrySync.moveTo */
  EntrySync moveTo(DirectoryEntrySync parent, String name) native "EntrySync_moveTo_Callback";


  /** @domName EntrySync.remove */
  void remove() native "EntrySync_remove_Callback";


  /** @domName EntrySync.toURL */
  String toURL() native "EntrySync_toURL_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void ErrorCallback(FileError error);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName ErrorEvent
class ErrorEvent extends Event {
  ErrorEvent.internal(): super.internal();


  /** @domName ErrorEvent.filename */
  String get filename native "ErrorEvent_filename_Getter";


  /** @domName ErrorEvent.lineno */
  int get lineno native "ErrorEvent_lineno_Getter";


  /** @domName ErrorEvent.message */
  String get message native "ErrorEvent_message_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


class Event extends NativeFieldWrapperClass1 {
  // In JS, canBubble and cancelable are technically required parameters to
  // init*Event. In practice, though, if they aren't provided they simply
  // default to false (since that's Boolean(undefined)).
  //
  // Contrary to JS, we default canBubble and cancelable to true, since that's
  // what people want most of the time anyway.
  factory Event(String type, [bool canBubble = true, bool cancelable = true]) =>
      _EventFactoryProvider.createEvent(type, canBubble, cancelable);
  Event.internal();

  static const int AT_TARGET = 2;

  static const int BLUR = 8192;

  static const int BUBBLING_PHASE = 3;

  static const int CAPTURING_PHASE = 1;

  static const int CHANGE = 32768;

  static const int CLICK = 64;

  static const int DBLCLICK = 128;

  static const int DRAGDROP = 2048;

  static const int FOCUS = 4096;

  static const int KEYDOWN = 256;

  static const int KEYPRESS = 1024;

  static const int KEYUP = 512;

  static const int MOUSEDOWN = 1;

  static const int MOUSEDRAG = 32;

  static const int MOUSEMOVE = 16;

  static const int MOUSEOUT = 8;

  static const int MOUSEOVER = 4;

  static const int MOUSEUP = 2;

  static const int NONE = 0;

  static const int SELECT = 16384;


  /** @domName Event.bubbles */
  bool get bubbles native "Event_bubbles_Getter";


  /** @domName Event.cancelBubble */
  bool get cancelBubble native "Event_cancelBubble_Getter";


  /** @domName Event.cancelBubble */
  void set cancelBubble(bool value) native "Event_cancelBubble_Setter";


  /** @domName Event.cancelable */
  bool get cancelable native "Event_cancelable_Getter";


  /** @domName Event.clipboardData */
  Clipboard get clipboardData native "Event_clipboardData_Getter";


  /** @domName Event.currentTarget */
  EventTarget get currentTarget native "Event_currentTarget_Getter";


  /** @domName Event.defaultPrevented */
  bool get defaultPrevented native "Event_defaultPrevented_Getter";


  /** @domName Event.eventPhase */
  int get eventPhase native "Event_eventPhase_Getter";


  /** @domName Event.returnValue */
  bool get returnValue native "Event_returnValue_Getter";


  /** @domName Event.returnValue */
  void set returnValue(bool value) native "Event_returnValue_Setter";


  /** @domName Event.target */
  EventTarget get target native "Event_target_Getter";


  /** @domName Event.timeStamp */
  int get timeStamp native "Event_timeStamp_Getter";


  /** @domName Event.type */
  String get type native "Event_type_Getter";


  /** @domName Event.initEvent */
  void $dom_initEvent(String eventTypeArg, bool canBubbleArg, bool cancelableArg) native "Event_initEvent_Callback";


  /** @domName Event.preventDefault */
  void preventDefault() native "Event_preventDefault_Callback";


  /** @domName Event.stopImmediatePropagation */
  void stopImmediatePropagation() native "Event_stopImmediatePropagation_Callback";


  /** @domName Event.stopPropagation */
  void stopPropagation() native "Event_stopPropagation_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName EventException
class EventException extends NativeFieldWrapperClass1 {
  EventException.internal();

  static const int DISPATCH_REQUEST_ERR = 1;

  static const int UNSPECIFIED_EVENT_TYPE_ERR = 0;


  /** @domName EventException.code */
  int get code native "EventException_code_Getter";


  /** @domName EventException.message */
  String get message native "EventException_message_Getter";


  /** @domName EventException.name */
  String get name native "EventException_name_Getter";


  /** @domName EventException.toString */
  String toString() native "EventException_toString_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName EventSource
class EventSource extends EventTarget {

  factory EventSource(String scriptUrl) => _EventSourceFactoryProvider.createEventSource(scriptUrl);
  EventSource.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  EventSourceEvents get on =>
    new EventSourceEvents(this);

  static const int CLOSED = 2;

  static const int CONNECTING = 0;

  static const int OPEN = 1;


  /** @domName EventSource.URL */
  String get URL native "EventSource_URL_Getter";


  /** @domName EventSource.readyState */
  int get readyState native "EventSource_readyState_Getter";


  /** @domName EventSource.url */
  String get url native "EventSource_url_Getter";


  /** @domName EventSource.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "EventSource_addEventListener_Callback";


  /** @domName EventSource.close */
  void close() native "EventSource_close_Callback";


  /** @domName EventSource.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "EventSource_dispatchEvent_Callback";


  /** @domName EventSource.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "EventSource_removeEventListener_Callback";

}

class EventSourceEvents extends Events {
  EventSourceEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get error => this['error'];

  EventListenerList get message => this['message'];

  EventListenerList get open => this['open'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class Events {
  /* Raw event target. */
  final EventTarget _ptr;

  Events(this._ptr);

  EventListenerList operator [](String type) {
    return new EventListenerList(_ptr, type);
  }
}

class EventListenerList {

  final EventTarget _ptr;
  final String _type;

  EventListenerList(this._ptr, this._type);

  // TODO(jacobr): implement equals.

  EventListenerList add(EventListener listener,
      [bool useCapture = false]) {
    _add(listener, useCapture);
    return this;
  }

  EventListenerList remove(EventListener listener,
      [bool useCapture = false]) {
    _remove(listener, useCapture);
    return this;
  }

  bool dispatch(Event evt) {
    return _ptr.$dom_dispatchEvent(evt);
  }

  void _add(EventListener listener, bool useCapture) {
    _ptr.$dom_addEventListener(_type, listener, useCapture);
  }

  void _remove(EventListener listener, bool useCapture) {
    _ptr.$dom_removeEventListener(_type, listener, useCapture);
  }
}


class EventTarget extends NativeFieldWrapperClass1 {

  /** @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent */
  Events get on => new Events(this);
  EventTarget.internal();


  /** @domName EventTarget.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "EventTarget_addEventListener_Callback";


  /** @domName EventTarget.dispatchEvent */
  bool $dom_dispatchEvent(Event event) native "EventTarget_dispatchEvent_Callback";


  /** @domName EventTarget.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "EventTarget_removeEventListener_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLFieldSetElement
class FieldSetElement extends _Element_Merged {

  factory FieldSetElement() => document.$dom_createElement("fieldset");
  FieldSetElement.internal(): super.internal();


  /** @domName HTMLFieldSetElement.disabled */
  bool get disabled native "HTMLFieldSetElement_disabled_Getter";


  /** @domName HTMLFieldSetElement.disabled */
  void set disabled(bool value) native "HTMLFieldSetElement_disabled_Setter";


  /** @domName HTMLFieldSetElement.elements */
  HTMLCollection get elements native "HTMLFieldSetElement_elements_Getter";


  /** @domName HTMLFieldSetElement.form */
  FormElement get form native "HTMLFieldSetElement_form_Getter";


  /** @domName HTMLFieldSetElement.name */
  String get name native "HTMLFieldSetElement_name_Getter";


  /** @domName HTMLFieldSetElement.name */
  void set name(String value) native "HTMLFieldSetElement_name_Setter";


  /** @domName HTMLFieldSetElement.type */
  String get type native "HTMLFieldSetElement_type_Getter";


  /** @domName HTMLFieldSetElement.validationMessage */
  String get validationMessage native "HTMLFieldSetElement_validationMessage_Getter";


  /** @domName HTMLFieldSetElement.validity */
  ValidityState get validity native "HTMLFieldSetElement_validity_Getter";


  /** @domName HTMLFieldSetElement.willValidate */
  bool get willValidate native "HTMLFieldSetElement_willValidate_Getter";


  /** @domName HTMLFieldSetElement.checkValidity */
  bool checkValidity() native "HTMLFieldSetElement_checkValidity_Callback";


  /** @domName HTMLFieldSetElement.setCustomValidity */
  void setCustomValidity(String error) native "HTMLFieldSetElement_setCustomValidity_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName File
class File extends Blob {
  File.internal(): super.internal();


  /** @domName File.lastModifiedDate */
  Date get lastModifiedDate native "File_lastModifiedDate_Getter";


  /** @domName File.name */
  String get name native "File_name_Getter";


  /** @domName File.webkitRelativePath */
  String get webkitRelativePath native "File_webkitRelativePath_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void FileCallback(File file);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName FileEntry
class FileEntry extends Entry {
  FileEntry.internal(): super.internal();


  /** @domName FileEntry.createWriter */
  void createWriter(FileWriterCallback successCallback, [ErrorCallback errorCallback]) native "FileEntry_createWriter_Callback";


  /** @domName FileEntry.file */
  void file(FileCallback successCallback, [ErrorCallback errorCallback]) native "FileEntry_file_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName FileEntrySync
class FileEntrySync extends EntrySync {
  FileEntrySync.internal(): super.internal();


  /** @domName FileEntrySync.createWriter */
  FileWriterSync createWriter() native "FileEntrySync_createWriter_Callback";


  /** @domName FileEntrySync.file */
  File file() native "FileEntrySync_file_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName FileError
class FileError extends NativeFieldWrapperClass1 {
  FileError.internal();

  static const int ABORT_ERR = 3;

  static const int ENCODING_ERR = 5;

  static const int INVALID_MODIFICATION_ERR = 9;

  static const int INVALID_STATE_ERR = 7;

  static const int NOT_FOUND_ERR = 1;

  static const int NOT_READABLE_ERR = 4;

  static const int NO_MODIFICATION_ALLOWED_ERR = 6;

  static const int PATH_EXISTS_ERR = 12;

  static const int QUOTA_EXCEEDED_ERR = 10;

  static const int SECURITY_ERR = 2;

  static const int SYNTAX_ERR = 8;

  static const int TYPE_MISMATCH_ERR = 11;


  /** @domName FileError.code */
  int get code native "FileError_code_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName FileException
class FileException extends NativeFieldWrapperClass1 {
  FileException.internal();

  static const int ABORT_ERR = 3;

  static const int ENCODING_ERR = 5;

  static const int INVALID_MODIFICATION_ERR = 9;

  static const int INVALID_STATE_ERR = 7;

  static const int NOT_FOUND_ERR = 1;

  static const int NOT_READABLE_ERR = 4;

  static const int NO_MODIFICATION_ALLOWED_ERR = 6;

  static const int PATH_EXISTS_ERR = 12;

  static const int QUOTA_EXCEEDED_ERR = 10;

  static const int SECURITY_ERR = 2;

  static const int SYNTAX_ERR = 8;

  static const int TYPE_MISMATCH_ERR = 11;


  /** @domName FileException.code */
  int get code native "FileException_code_Getter";


  /** @domName FileException.message */
  String get message native "FileException_message_Getter";


  /** @domName FileException.name */
  String get name native "FileException_name_Getter";


  /** @domName FileException.toString */
  String toString() native "FileException_toString_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName FileReader
class FileReader extends EventTarget {

  factory FileReader() => _FileReaderFactoryProvider.createFileReader();
  FileReader.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  FileReaderEvents get on =>
    new FileReaderEvents(this);

  static const int DONE = 2;

  static const int EMPTY = 0;

  static const int LOADING = 1;


  /** @domName FileReader.error */
  FileError get error native "FileReader_error_Getter";


  /** @domName FileReader.readyState */
  int get readyState native "FileReader_readyState_Getter";


  /** @domName FileReader.result */
  Object get result native "FileReader_result_Getter";


  /** @domName FileReader.abort */
  void abort() native "FileReader_abort_Callback";


  /** @domName FileReader.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "FileReader_addEventListener_Callback";


  /** @domName FileReader.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "FileReader_dispatchEvent_Callback";


  /** @domName FileReader.readAsArrayBuffer */
  void readAsArrayBuffer(Blob blob) native "FileReader_readAsArrayBuffer_Callback";


  /** @domName FileReader.readAsBinaryString */
  void readAsBinaryString(Blob blob) native "FileReader_readAsBinaryString_Callback";


  /** @domName FileReader.readAsDataURL */
  void readAsDataURL(Blob blob) native "FileReader_readAsDataURL_Callback";

  void readAsText(/*Blob*/ blob, [/*DOMString*/ encoding]) {
    if (?encoding) {
      _readAsText_1(blob, encoding);
      return;
    }
    _readAsText_2(blob);
  }


  /** @domName FileReader.readAsText_1 */
  void _readAsText_1(blob, encoding) native "FileReader_readAsText_1_Callback";


  /** @domName FileReader.readAsText_2 */
  void _readAsText_2(blob) native "FileReader_readAsText_2_Callback";


  /** @domName FileReader.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "FileReader_removeEventListener_Callback";

}

class FileReaderEvents extends Events {
  FileReaderEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get abort => this['abort'];

  EventListenerList get error => this['error'];

  EventListenerList get load => this['load'];

  EventListenerList get loadEnd => this['loadend'];

  EventListenerList get loadStart => this['loadstart'];

  EventListenerList get progress => this['progress'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName FileReaderSync
class FileReaderSync extends NativeFieldWrapperClass1 {

  factory FileReaderSync() => _FileReaderSyncFactoryProvider.createFileReaderSync();
  FileReaderSync.internal();


  /** @domName FileReaderSync.readAsArrayBuffer */
  ArrayBuffer readAsArrayBuffer(Blob blob) native "FileReaderSync_readAsArrayBuffer_Callback";


  /** @domName FileReaderSync.readAsBinaryString */
  String readAsBinaryString(Blob blob) native "FileReaderSync_readAsBinaryString_Callback";


  /** @domName FileReaderSync.readAsDataURL */
  String readAsDataURL(Blob blob) native "FileReaderSync_readAsDataURL_Callback";

  String readAsText(/*Blob*/ blob, [/*DOMString*/ encoding]) {
    if (?encoding) {
      return _readAsText_1(blob, encoding);
    }
    return _readAsText_2(blob);
  }


  /** @domName FileReaderSync.readAsText_1 */
  String _readAsText_1(blob, encoding) native "FileReaderSync_readAsText_1_Callback";


  /** @domName FileReaderSync.readAsText_2 */
  String _readAsText_2(blob) native "FileReaderSync_readAsText_2_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void FileSystemCallback(DOMFileSystem fileSystem);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName FileWriter
class FileWriter extends EventTarget {
  FileWriter.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  FileWriterEvents get on =>
    new FileWriterEvents(this);

  static const int DONE = 2;

  static const int INIT = 0;

  static const int WRITING = 1;


  /** @domName FileWriter.error */
  FileError get error native "FileWriter_error_Getter";


  /** @domName FileWriter.length */
  int get length native "FileWriter_length_Getter";


  /** @domName FileWriter.position */
  int get position native "FileWriter_position_Getter";


  /** @domName FileWriter.readyState */
  int get readyState native "FileWriter_readyState_Getter";


  /** @domName FileWriter.abort */
  void abort() native "FileWriter_abort_Callback";


  /** @domName FileWriter.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "FileWriter_addEventListener_Callback";


  /** @domName FileWriter.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "FileWriter_dispatchEvent_Callback";


  /** @domName FileWriter.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "FileWriter_removeEventListener_Callback";


  /** @domName FileWriter.seek */
  void seek(int position) native "FileWriter_seek_Callback";


  /** @domName FileWriter.truncate */
  void truncate(int size) native "FileWriter_truncate_Callback";


  /** @domName FileWriter.write */
  void write(Blob data) native "FileWriter_write_Callback";

}

class FileWriterEvents extends Events {
  FileWriterEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get abort => this['abort'];

  EventListenerList get error => this['error'];

  EventListenerList get progress => this['progress'];

  EventListenerList get write => this['write'];

  EventListenerList get writeEnd => this['writeend'];

  EventListenerList get writeStart => this['writestart'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void FileWriterCallback(FileWriter fileWriter);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName FileWriterSync
class FileWriterSync extends NativeFieldWrapperClass1 {
  FileWriterSync.internal();


  /** @domName FileWriterSync.length */
  int get length native "FileWriterSync_length_Getter";


  /** @domName FileWriterSync.position */
  int get position native "FileWriterSync_position_Getter";


  /** @domName FileWriterSync.seek */
  void seek(int position) native "FileWriterSync_seek_Callback";


  /** @domName FileWriterSync.truncate */
  void truncate(int size) native "FileWriterSync_truncate_Callback";


  /** @domName FileWriterSync.write */
  void write(Blob data) native "FileWriterSync_write_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Float32Array
class Float32Array extends ArrayBufferView implements List<num> {

  factory Float32Array(int length) =>
    _TypedArrayFactoryProvider.createFloat32Array(length);

  factory Float32Array.fromList(List<num> list) =>
    _TypedArrayFactoryProvider.createFloat32Array_fromList(list);

  factory Float32Array.fromBuffer(ArrayBuffer buffer, [int byteOffset, int length]) => 
    _TypedArrayFactoryProvider.createFloat32Array_fromBuffer(buffer, byteOffset, length);
  Float32Array.internal(): super.internal();

  static const int BYTES_PER_ELEMENT = 4;


  /** @domName Float32Array.length */
  int get length native "Float32Array_length_Getter";


  /** @domName Float32Array.numericIndexGetter */
  num operator[](int index) native "Float32Array_numericIndexGetter_Callback";


  /** @domName Float32Array.numericIndexSetter */
  void operator[]=(int index, num value) native "Float32Array_numericIndexSetter_Callback";
  // -- start List<num> mixins.
  // num is the element type.

  // From Iterable<num>:

  Iterator<num> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<num>(this);
  }

  // From Collection<num>:

  void add(num value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(num value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<num> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(num element) => _Collections.contains(this, element);

  void forEach(void f(num element)) => _Collections.forEach(this, f);

  Collection map(f(num element)) => _Collections.map(this, [], f);

  Collection<num> filter(bool f(num element)) =>
     _Collections.filter(this, <num>[], f);

  bool every(bool f(num element)) => _Collections.every(this, f);

  bool some(bool f(num element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<num>:

  void sort([Comparator<num> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(num element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(num element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  num get first => this[0];

  num get last => this[length - 1];

  num removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<num> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [num initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<num> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <num>[]);

  // -- end List<num> mixins.


  /** @domName Float32Array.setElements */
  void setElements(Object array, [int offset]) native "Float32Array_setElements_Callback";

  Float32Array subarray(/*long*/ start, [/*long*/ end]) {
    if (?end) {
      return _subarray_1(start, end);
    }
    return _subarray_2(start);
  }


  /** @domName Float32Array.subarray_1 */
  Float32Array _subarray_1(start, end) native "Float32Array_subarray_1_Callback";


  /** @domName Float32Array.subarray_2 */
  Float32Array _subarray_2(start) native "Float32Array_subarray_2_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Float64Array
class Float64Array extends ArrayBufferView implements List<num> {

  factory Float64Array(int length) =>
    _TypedArrayFactoryProvider.createFloat64Array(length);

  factory Float64Array.fromList(List<num> list) =>
    _TypedArrayFactoryProvider.createFloat64Array_fromList(list);

  factory Float64Array.fromBuffer(ArrayBuffer buffer, [int byteOffset, int length]) => 
    _TypedArrayFactoryProvider.createFloat64Array_fromBuffer(buffer, byteOffset, length);
  Float64Array.internal(): super.internal();

  static const int BYTES_PER_ELEMENT = 8;


  /** @domName Float64Array.length */
  int get length native "Float64Array_length_Getter";


  /** @domName Float64Array.numericIndexGetter */
  num operator[](int index) native "Float64Array_numericIndexGetter_Callback";


  /** @domName Float64Array.numericIndexSetter */
  void operator[]=(int index, num value) native "Float64Array_numericIndexSetter_Callback";
  // -- start List<num> mixins.
  // num is the element type.

  // From Iterable<num>:

  Iterator<num> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<num>(this);
  }

  // From Collection<num>:

  void add(num value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(num value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<num> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(num element) => _Collections.contains(this, element);

  void forEach(void f(num element)) => _Collections.forEach(this, f);

  Collection map(f(num element)) => _Collections.map(this, [], f);

  Collection<num> filter(bool f(num element)) =>
     _Collections.filter(this, <num>[], f);

  bool every(bool f(num element)) => _Collections.every(this, f);

  bool some(bool f(num element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<num>:

  void sort([Comparator<num> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(num element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(num element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  num get first => this[0];

  num get last => this[length - 1];

  num removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<num> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [num initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<num> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <num>[]);

  // -- end List<num> mixins.


  /** @domName Float64Array.setElements */
  void setElements(Object array, [int offset]) native "Float64Array_setElements_Callback";

  Float64Array subarray(/*long*/ start, [/*long*/ end]) {
    if (?end) {
      return _subarray_1(start, end);
    }
    return _subarray_2(start);
  }


  /** @domName Float64Array.subarray_1 */
  Float64Array _subarray_1(start, end) native "Float64Array_subarray_1_Callback";


  /** @domName Float64Array.subarray_2 */
  Float64Array _subarray_2(start) native "Float64Array_subarray_2_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLFontElement
class FontElement extends _Element_Merged {
  FontElement.internal(): super.internal();


  /** @domName HTMLFontElement.color */
  String get color native "HTMLFontElement_color_Getter";


  /** @domName HTMLFontElement.color */
  void set color(String value) native "HTMLFontElement_color_Setter";


  /** @domName HTMLFontElement.face */
  String get face native "HTMLFontElement_face_Getter";


  /** @domName HTMLFontElement.face */
  void set face(String value) native "HTMLFontElement_face_Setter";


  /** @domName HTMLFontElement.size */
  String get size native "HTMLFontElement_size_Getter";


  /** @domName HTMLFontElement.size */
  void set size(String value) native "HTMLFontElement_size_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName FormData
class FormData extends NativeFieldWrapperClass1 {

  factory FormData([FormElement form]) {
    if (!?form) {
      return _FormDataFactoryProvider.createFormData();
    }
    return _FormDataFactoryProvider.createFormData(form);
  }
  FormData.internal();


  /** @domName DOMFormData.append */
  void append(String name, String value, String filename) native "DOMFormData_append_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLFormElement
class FormElement extends _Element_Merged {

  factory FormElement() => document.$dom_createElement("form");
  FormElement.internal(): super.internal();


  /** @domName HTMLFormElement.acceptCharset */
  String get acceptCharset native "HTMLFormElement_acceptCharset_Getter";


  /** @domName HTMLFormElement.acceptCharset */
  void set acceptCharset(String value) native "HTMLFormElement_acceptCharset_Setter";


  /** @domName HTMLFormElement.action */
  String get action native "HTMLFormElement_action_Getter";


  /** @domName HTMLFormElement.action */
  void set action(String value) native "HTMLFormElement_action_Setter";


  /** @domName HTMLFormElement.autocomplete */
  String get autocomplete native "HTMLFormElement_autocomplete_Getter";


  /** @domName HTMLFormElement.autocomplete */
  void set autocomplete(String value) native "HTMLFormElement_autocomplete_Setter";


  /** @domName HTMLFormElement.encoding */
  String get encoding native "HTMLFormElement_encoding_Getter";


  /** @domName HTMLFormElement.encoding */
  void set encoding(String value) native "HTMLFormElement_encoding_Setter";


  /** @domName HTMLFormElement.enctype */
  String get enctype native "HTMLFormElement_enctype_Getter";


  /** @domName HTMLFormElement.enctype */
  void set enctype(String value) native "HTMLFormElement_enctype_Setter";


  /** @domName HTMLFormElement.length */
  int get length native "HTMLFormElement_length_Getter";


  /** @domName HTMLFormElement.method */
  String get method native "HTMLFormElement_method_Getter";


  /** @domName HTMLFormElement.method */
  void set method(String value) native "HTMLFormElement_method_Setter";


  /** @domName HTMLFormElement.name */
  String get name native "HTMLFormElement_name_Getter";


  /** @domName HTMLFormElement.name */
  void set name(String value) native "HTMLFormElement_name_Setter";


  /** @domName HTMLFormElement.noValidate */
  bool get noValidate native "HTMLFormElement_noValidate_Getter";


  /** @domName HTMLFormElement.noValidate */
  void set noValidate(bool value) native "HTMLFormElement_noValidate_Setter";


  /** @domName HTMLFormElement.target */
  String get target native "HTMLFormElement_target_Getter";


  /** @domName HTMLFormElement.target */
  void set target(String value) native "HTMLFormElement_target_Setter";


  /** @domName HTMLFormElement.checkValidity */
  bool checkValidity() native "HTMLFormElement_checkValidity_Callback";


  /** @domName HTMLFormElement.reset */
  void reset() native "HTMLFormElement_reset_Callback";


  /** @domName HTMLFormElement.submit */
  void submit() native "HTMLFormElement_submit_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLFrameElement
class FrameElement extends _Element_Merged {
  FrameElement.internal(): super.internal();


  /** @domName HTMLFrameElement.contentWindow */
  Window get contentWindow native "HTMLFrameElement_contentWindow_Getter";


  /** @domName HTMLFrameElement.frameBorder */
  String get frameBorder native "HTMLFrameElement_frameBorder_Getter";


  /** @domName HTMLFrameElement.frameBorder */
  void set frameBorder(String value) native "HTMLFrameElement_frameBorder_Setter";


  /** @domName HTMLFrameElement.height */
  int get height native "HTMLFrameElement_height_Getter";


  /** @domName HTMLFrameElement.location */
  String get location native "HTMLFrameElement_location_Getter";


  /** @domName HTMLFrameElement.location */
  void set location(String value) native "HTMLFrameElement_location_Setter";


  /** @domName HTMLFrameElement.longDesc */
  String get longDesc native "HTMLFrameElement_longDesc_Getter";


  /** @domName HTMLFrameElement.longDesc */
  void set longDesc(String value) native "HTMLFrameElement_longDesc_Setter";


  /** @domName HTMLFrameElement.marginHeight */
  String get marginHeight native "HTMLFrameElement_marginHeight_Getter";


  /** @domName HTMLFrameElement.marginHeight */
  void set marginHeight(String value) native "HTMLFrameElement_marginHeight_Setter";


  /** @domName HTMLFrameElement.marginWidth */
  String get marginWidth native "HTMLFrameElement_marginWidth_Getter";


  /** @domName HTMLFrameElement.marginWidth */
  void set marginWidth(String value) native "HTMLFrameElement_marginWidth_Setter";


  /** @domName HTMLFrameElement.name */
  String get name native "HTMLFrameElement_name_Getter";


  /** @domName HTMLFrameElement.name */
  void set name(String value) native "HTMLFrameElement_name_Setter";


  /** @domName HTMLFrameElement.noResize */
  bool get noResize native "HTMLFrameElement_noResize_Getter";


  /** @domName HTMLFrameElement.noResize */
  void set noResize(bool value) native "HTMLFrameElement_noResize_Setter";


  /** @domName HTMLFrameElement.scrolling */
  String get scrolling native "HTMLFrameElement_scrolling_Getter";


  /** @domName HTMLFrameElement.scrolling */
  void set scrolling(String value) native "HTMLFrameElement_scrolling_Setter";


  /** @domName HTMLFrameElement.src */
  String get src native "HTMLFrameElement_src_Getter";


  /** @domName HTMLFrameElement.src */
  void set src(String value) native "HTMLFrameElement_src_Setter";


  /** @domName HTMLFrameElement.width */
  int get width native "HTMLFrameElement_width_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLFrameSetElement
class FrameSetElement extends _Element_Merged {
  FrameSetElement.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  FrameSetElementEvents get on =>
    new FrameSetElementEvents(this);


  /** @domName HTMLFrameSetElement.cols */
  String get cols native "HTMLFrameSetElement_cols_Getter";


  /** @domName HTMLFrameSetElement.cols */
  void set cols(String value) native "HTMLFrameSetElement_cols_Setter";


  /** @domName HTMLFrameSetElement.rows */
  String get rows native "HTMLFrameSetElement_rows_Getter";


  /** @domName HTMLFrameSetElement.rows */
  void set rows(String value) native "HTMLFrameSetElement_rows_Setter";

}

class FrameSetElementEvents extends ElementEvents {
  FrameSetElementEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get beforeUnload => this['beforeunload'];

  EventListenerList get blur => this['blur'];

  EventListenerList get error => this['error'];

  EventListenerList get focus => this['focus'];

  EventListenerList get hashChange => this['hashchange'];

  EventListenerList get load => this['load'];

  EventListenerList get message => this['message'];

  EventListenerList get offline => this['offline'];

  EventListenerList get online => this['online'];

  EventListenerList get popState => this['popstate'];

  EventListenerList get resize => this['resize'];

  EventListenerList get storage => this['storage'];

  EventListenerList get unload => this['unload'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName GainNode
class GainNode extends AudioNode {
  GainNode.internal(): super.internal();


  /** @domName GainNode.gain */
  AudioGain get gain native "GainNode_gain_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Gamepad
class Gamepad extends NativeFieldWrapperClass1 {
  Gamepad.internal();


  /** @domName Gamepad.axes */
  List<num> get axes native "Gamepad_axes_Getter";


  /** @domName Gamepad.buttons */
  List<num> get buttons native "Gamepad_buttons_Getter";


  /** @domName Gamepad.id */
  String get id native "Gamepad_id_Getter";


  /** @domName Gamepad.index */
  int get index native "Gamepad_index_Getter";


  /** @domName Gamepad.timestamp */
  int get timestamp native "Gamepad_timestamp_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Geolocation
class Geolocation extends NativeFieldWrapperClass1 {
  Geolocation.internal();


  /** @domName Geolocation.clearWatch */
  void clearWatch(int watchId) native "Geolocation_clearWatch_Callback";


  /** @domName Geolocation.getCurrentPosition */
  void getCurrentPosition(PositionCallback successCallback, [PositionErrorCallback errorCallback, Object options]) native "Geolocation_getCurrentPosition_Callback";


  /** @domName Geolocation.watchPosition */
  int watchPosition(PositionCallback successCallback, [PositionErrorCallback errorCallback, Object options]) native "Geolocation_watchPosition_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Geoposition
class Geoposition extends NativeFieldWrapperClass1 {
  Geoposition.internal();


  /** @domName Geoposition.coords */
  Coordinates get coords native "Geoposition_coords_Getter";


  /** @domName Geoposition.timestamp */
  int get timestamp native "Geoposition_timestamp_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLHRElement
class HRElement extends _Element_Merged {

  factory HRElement() => document.$dom_createElement("hr");
  HRElement.internal(): super.internal();


  /** @domName HTMLHRElement.align */
  String get align native "HTMLHRElement_align_Getter";


  /** @domName HTMLHRElement.align */
  void set align(String value) native "HTMLHRElement_align_Setter";


  /** @domName HTMLHRElement.noShade */
  bool get noShade native "HTMLHRElement_noShade_Getter";


  /** @domName HTMLHRElement.noShade */
  void set noShade(bool value) native "HTMLHRElement_noShade_Setter";


  /** @domName HTMLHRElement.size */
  String get size native "HTMLHRElement_size_Getter";


  /** @domName HTMLHRElement.size */
  void set size(String value) native "HTMLHRElement_size_Setter";


  /** @domName HTMLHRElement.width */
  String get width native "HTMLHRElement_width_Getter";


  /** @domName HTMLHRElement.width */
  void set width(String value) native "HTMLHRElement_width_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLAllCollection
class HTMLAllCollection extends NativeFieldWrapperClass1 implements List<Node> {
  HTMLAllCollection.internal();


  /** @domName HTMLAllCollection.length */
  int get length native "HTMLAllCollection_length_Getter";

  Node operator[](int index) native "HTMLAllCollection_item_Callback";

  void operator[]=(int index, Node value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Node> mixins.
  // Node is the element type.

  // From Iterable<Node>:

  Iterator<Node> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Node>(this);
  }

  // From Collection<Node>:

  void add(Node value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(Node value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<Node> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(Node element) => _Collections.contains(this, element);

  void forEach(void f(Node element)) => _Collections.forEach(this, f);

  Collection map(f(Node element)) => _Collections.map(this, [], f);

  Collection<Node> filter(bool f(Node element)) =>
     _Collections.filter(this, <Node>[], f);

  bool every(bool f(Node element)) => _Collections.every(this, f);

  bool some(bool f(Node element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<Node>:

  void sort([Comparator<Node> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Node element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Node element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  Node get first => this[0];

  Node get last => this[length - 1];

  Node removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<Node> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [Node initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<Node> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <Node>[]);

  // -- end List<Node> mixins.


  /** @domName HTMLAllCollection.item */
  Node item(int index) native "HTMLAllCollection_item_Callback";


  /** @domName HTMLAllCollection.namedItem */
  Node namedItem(String name) native "HTMLAllCollection_namedItem_Callback";


  /** @domName HTMLAllCollection.tags */
  List<Node> tags(String name) native "HTMLAllCollection_tags_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLCollection
class HTMLCollection extends NativeFieldWrapperClass1 implements List<Node> {
  HTMLCollection.internal();


  /** @domName HTMLCollection.length */
  int get length native "HTMLCollection_length_Getter";

  Node operator[](int index) native "HTMLCollection_item_Callback";

  void operator[]=(int index, Node value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Node> mixins.
  // Node is the element type.

  // From Iterable<Node>:

  Iterator<Node> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Node>(this);
  }

  // From Collection<Node>:

  void add(Node value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(Node value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<Node> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(Node element) => _Collections.contains(this, element);

  void forEach(void f(Node element)) => _Collections.forEach(this, f);

  Collection map(f(Node element)) => _Collections.map(this, [], f);

  Collection<Node> filter(bool f(Node element)) =>
     _Collections.filter(this, <Node>[], f);

  bool every(bool f(Node element)) => _Collections.every(this, f);

  bool some(bool f(Node element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<Node>:

  void sort([Comparator<Node> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Node element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Node element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  Node get first => this[0];

  Node get last => this[length - 1];

  Node removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<Node> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [Node initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<Node> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <Node>[]);

  // -- end List<Node> mixins.


  /** @domName HTMLCollection.item */
  Node item(int index) native "HTMLCollection_item_Callback";


  /** @domName HTMLCollection.namedItem */
  Node namedItem(String name) native "HTMLCollection_namedItem_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLOptionsCollection
class HTMLOptionsCollection extends HTMLCollection {
  HTMLOptionsCollection.internal(): super.internal();


  /** @domName HTMLOptionsCollection.length */
  int get length native "HTMLOptionsCollection_length_Getter";


  /** @domName HTMLOptionsCollection.length */
  void set length(int value) native "HTMLOptionsCollection_length_Setter";


  /** @domName HTMLOptionsCollection.selectedIndex */
  int get selectedIndex native "HTMLOptionsCollection_selectedIndex_Getter";


  /** @domName HTMLOptionsCollection.selectedIndex */
  void set selectedIndex(int value) native "HTMLOptionsCollection_selectedIndex_Setter";


  /** @domName HTMLOptionsCollection.numericIndexSetter */
  void operator[]=(int index, Node value) native "HTMLOptionsCollection_numericIndexSetter_Callback";


  /** @domName HTMLOptionsCollection.remove */
  void remove(int index) native "HTMLOptionsCollection_remove_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HashChangeEvent
class HashChangeEvent extends Event {
  HashChangeEvent.internal(): super.internal();


  /** @domName HashChangeEvent.newURL */
  String get newURL native "HashChangeEvent_newURL_Getter";


  /** @domName HashChangeEvent.oldURL */
  String get oldURL native "HashChangeEvent_oldURL_Getter";


  /** @domName HashChangeEvent.initHashChangeEvent */
  void initHashChangeEvent(String type, bool canBubble, bool cancelable, String oldURL, String newURL) native "HashChangeEvent_initHashChangeEvent_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLHeadElement
class HeadElement extends _Element_Merged {

  factory HeadElement() => document.$dom_createElement("head");
  HeadElement.internal(): super.internal();


  /** @domName HTMLHeadElement.profile */
  String get profile native "HTMLHeadElement_profile_Getter";


  /** @domName HTMLHeadElement.profile */
  void set profile(String value) native "HTMLHeadElement_profile_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLHeadingElement
class HeadingElement extends _Element_Merged {

  factory HeadingElement.h1() => document.$dom_createElement("h1");

  factory HeadingElement.h2() => document.$dom_createElement("h2");

  factory HeadingElement.h3() => document.$dom_createElement("h3");

  factory HeadingElement.h4() => document.$dom_createElement("h4");

  factory HeadingElement.h5() => document.$dom_createElement("h5");

  factory HeadingElement.h6() => document.$dom_createElement("h6");
  HeadingElement.internal(): super.internal();


  /** @domName HTMLHeadingElement.align */
  String get align native "HTMLHeadingElement_align_Getter";


  /** @domName HTMLHeadingElement.align */
  void set align(String value) native "HTMLHeadingElement_align_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


class HtmlDocument extends Document {
  HtmlDocument.internal(): super.internal();


  /** @domName HTMLDocument.activeElement */
  Element get activeElement native "HTMLDocument_activeElement_Getter";

  /** @domName Document.body */
  BodyElement get body => document.$dom_body;

  /** @domName Document.body */
  void set body(BodyElement value) {
    document.$dom_body = value;
  }

  /** @domName Document.caretRangeFromPoint */
  Range caretRangeFromPoint(int x, int y) {
    return document.$dom_caretRangeFromPoint(x, y);
  }

  /** @domName Document.elementFromPoint */
  Element elementFromPoint(int x, int y) {
    return document.$dom_elementFromPoint(x, y);
  }

  /** @domName Document.head */
  HeadElement get head => document.$dom_head;

  /** @domName Document.lastModified */
  String get lastModified => document.$dom_lastModified;

  /** @domName Document.referrer */
  String get referrer => document.$dom_referrer;

  /** @domName Document.styleSheets */
  List<StyleSheet> get styleSheets => document.$dom_styleSheets;

  /** @domName Document.title */
  String get title => document.$dom_title;

  /** @domName Document.title */
  void set title(String value) {
    document.$dom_title = value;
  }

  /** @domName Document.webkitCancelFullScreen */
  void webkitCancelFullScreen() {
    document.$dom_webkitCancelFullScreen();
  }

  /** @domName Document.webkitExitFullscreen */
  void webkitExitFullscreen() {
    document.$dom_webkitExitFullscreen();
  }

  /** @domName Document.webkitExitPointerLock */
  void webkitExitPointerLock() {
    document.$dom_webkitExitPointerLock();
  }

  /** @domName Document.webkitFullscreenElement */
  Element get webkitFullscreenElement => document.$dom_webkitFullscreenElement;

  /** @domName Document.webkitFullscreenEnabled */
  bool get webkitFullscreenEnabled => document.$dom_webkitFullscreenEnabled;

  /** @domName Document.webkitHidden */
  bool get webkitHidden => document.$dom_webkitHidden;

  /** @domName Document.webkitIsFullScreen */
  bool get webkitIsFullScreen => document.$dom_webkitIsFullScreen;

  /** @domName Document.webkitPointerLockElement */
  Element get webkitPointerLockElement =>
      document.$dom_webkitPointerLockElement;

  /** @domName Document.webkitVisibilityState */
  String get webkitVisibilityState => document.$dom_webkitVisibilityState;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLHtmlElement
class HtmlElement extends _Element_Merged {

  factory HtmlElement() => document.$dom_createElement("html");
  HtmlElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class HttpRequest extends EventTarget {
  factory HttpRequest.get(String url, onComplete(HttpRequest request)) =>
      _HttpRequestFactoryProvider.createHttpRequest_get(url, onComplete);

  factory HttpRequest.getWithCredentials(String url,
      onComplete(HttpRequest request)) =>
      _HttpRequestFactoryProvider.createHttpRequest_getWithCredentials(url,
      onComplete);


  factory HttpRequest() => _HttpRequestFactoryProvider.createHttpRequest();
  HttpRequest.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  HttpRequestEvents get on =>
    new HttpRequestEvents(this);

  static const int DONE = 4;

  static const int HEADERS_RECEIVED = 2;

  static const int LOADING = 3;

  static const int OPENED = 1;

  static const int UNSENT = 0;


  /** @domName XMLHttpRequest.readyState */
  int get readyState native "XMLHttpRequest_readyState_Getter";


  /** @domName XMLHttpRequest.response */
  Object get response native "XMLHttpRequest_response_Getter";


  /** @domName XMLHttpRequest.responseText */
  String get responseText native "XMLHttpRequest_responseText_Getter";


  /** @domName XMLHttpRequest.responseType */
  String get responseType native "XMLHttpRequest_responseType_Getter";


  /** @domName XMLHttpRequest.responseType */
  void set responseType(String value) native "XMLHttpRequest_responseType_Setter";


  /** @domName XMLHttpRequest.responseXML */
  Document get responseXML native "XMLHttpRequest_responseXML_Getter";


  /** @domName XMLHttpRequest.status */
  int get status native "XMLHttpRequest_status_Getter";


  /** @domName XMLHttpRequest.statusText */
  String get statusText native "XMLHttpRequest_statusText_Getter";


  /** @domName XMLHttpRequest.upload */
  HttpRequestUpload get upload native "XMLHttpRequest_upload_Getter";


  /** @domName XMLHttpRequest.withCredentials */
  bool get withCredentials native "XMLHttpRequest_withCredentials_Getter";


  /** @domName XMLHttpRequest.withCredentials */
  void set withCredentials(bool value) native "XMLHttpRequest_withCredentials_Setter";


  /** @domName XMLHttpRequest.abort */
  void abort() native "XMLHttpRequest_abort_Callback";


  /** @domName XMLHttpRequest.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "XMLHttpRequest_addEventListener_Callback";


  /** @domName XMLHttpRequest.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "XMLHttpRequest_dispatchEvent_Callback";


  /** @domName XMLHttpRequest.getAllResponseHeaders */
  String getAllResponseHeaders() native "XMLHttpRequest_getAllResponseHeaders_Callback";


  /** @domName XMLHttpRequest.getResponseHeader */
  String getResponseHeader(String header) native "XMLHttpRequest_getResponseHeader_Callback";


  /** @domName XMLHttpRequest.open */
  void open(String method, String url, [bool async, String user, String password]) native "XMLHttpRequest_open_Callback";


  /** @domName XMLHttpRequest.overrideMimeType */
  void overrideMimeType(String override) native "XMLHttpRequest_overrideMimeType_Callback";


  /** @domName XMLHttpRequest.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "XMLHttpRequest_removeEventListener_Callback";


  /** @domName XMLHttpRequest.send */
  void send([data]) native "XMLHttpRequest_send_Callback";


  /** @domName XMLHttpRequest.setRequestHeader */
  void setRequestHeader(String header, String value) native "XMLHttpRequest_setRequestHeader_Callback";

}

class HttpRequestEvents extends Events {
  HttpRequestEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get abort => this['abort'];

  EventListenerList get error => this['error'];

  EventListenerList get load => this['load'];

  EventListenerList get loadEnd => this['loadend'];

  EventListenerList get loadStart => this['loadstart'];

  EventListenerList get progress => this['progress'];

  EventListenerList get readyStateChange => this['readystatechange'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName XMLHttpRequestException
class HttpRequestException extends NativeFieldWrapperClass1 {
  HttpRequestException.internal();

  static const int ABORT_ERR = 102;

  static const int NETWORK_ERR = 101;


  /** @domName XMLHttpRequestException.code */
  int get code native "XMLHttpRequestException_code_Getter";


  /** @domName XMLHttpRequestException.message */
  String get message native "XMLHttpRequestException_message_Getter";


  /** @domName XMLHttpRequestException.name */
  String get name native "XMLHttpRequestException_name_Getter";


  /** @domName XMLHttpRequestException.toString */
  String toString() native "XMLHttpRequestException_toString_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName XMLHttpRequestProgressEvent
class HttpRequestProgressEvent extends ProgressEvent {
  HttpRequestProgressEvent.internal(): super.internal();


  /** @domName XMLHttpRequestProgressEvent.position */
  int get position native "XMLHttpRequestProgressEvent_position_Getter";


  /** @domName XMLHttpRequestProgressEvent.totalSize */
  int get totalSize native "XMLHttpRequestProgressEvent_totalSize_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName XMLHttpRequestUpload
class HttpRequestUpload extends EventTarget {
  HttpRequestUpload.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  HttpRequestUploadEvents get on =>
    new HttpRequestUploadEvents(this);


  /** @domName XMLHttpRequestUpload.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "XMLHttpRequestUpload_addEventListener_Callback";


  /** @domName XMLHttpRequestUpload.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "XMLHttpRequestUpload_dispatchEvent_Callback";


  /** @domName XMLHttpRequestUpload.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "XMLHttpRequestUpload_removeEventListener_Callback";

}

class HttpRequestUploadEvents extends Events {
  HttpRequestUploadEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get abort => this['abort'];

  EventListenerList get error => this['error'];

  EventListenerList get load => this['load'];

  EventListenerList get loadEnd => this['loadend'];

  EventListenerList get loadStart => this['loadstart'];

  EventListenerList get progress => this['progress'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName IDBAny
class IDBAny extends NativeFieldWrapperClass1 {
  IDBAny.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName IDBCursor
class IDBCursor extends NativeFieldWrapperClass1 {
  IDBCursor.internal();

  static const int NEXT = 0;

  static const int NEXT_NO_DUPLICATE = 1;

  static const int PREV = 2;

  static const int PREV_NO_DUPLICATE = 3;


  /** @domName IDBCursor.direction */
  String get direction native "IDBCursor_direction_Getter";


  /** @domName IDBCursor.key */
  Object get key native "IDBCursor_key_Getter";


  /** @domName IDBCursor.primaryKey */
  Object get primaryKey native "IDBCursor_primaryKey_Getter";


  /** @domName IDBCursor.source */
  dynamic get source native "IDBCursor_source_Getter";


  /** @domName IDBCursor.advance */
  void advance(int count) native "IDBCursor_advance_Callback";

  void continueFunction([/*IDBKey*/ key]) {
    if (?key) {
      _continue_1(key);
      return;
    }
    _continue_2();
  }


  /** @domName IDBCursor.continue_1 */
  void _continue_1(key) native "IDBCursor_continue_1_Callback";


  /** @domName IDBCursor.continue_2 */
  void _continue_2() native "IDBCursor_continue_2_Callback";


  /** @domName IDBCursor.delete */
  IDBRequest delete() native "IDBCursor_delete_Callback";


  /** @domName IDBCursor.update */
  IDBRequest update(Object value) native "IDBCursor_update_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName IDBCursorWithValue
class IDBCursorWithValue extends IDBCursor {
  IDBCursorWithValue.internal(): super.internal();


  /** @domName IDBCursorWithValue.value */
  Object get value native "IDBCursorWithValue_value_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName IDBDatabase
class IDBDatabase extends EventTarget {
  IDBDatabase.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  IDBDatabaseEvents get on =>
    new IDBDatabaseEvents(this);


  /** @domName IDBDatabase.name */
  String get name native "IDBDatabase_name_Getter";


  /** @domName IDBDatabase.objectStoreNames */
  List<String> get objectStoreNames native "IDBDatabase_objectStoreNames_Getter";


  /** @domName IDBDatabase.version */
  dynamic get version native "IDBDatabase_version_Getter";


  /** @domName IDBDatabase.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "IDBDatabase_addEventListener_Callback";


  /** @domName IDBDatabase.close */
  void close() native "IDBDatabase_close_Callback";


  /** @domName IDBDatabase.createObjectStore */
  IDBObjectStore createObjectStore(String name, [Map options]) native "IDBDatabase_createObjectStore_Callback";


  /** @domName IDBDatabase.deleteObjectStore */
  void deleteObjectStore(String name) native "IDBDatabase_deleteObjectStore_Callback";


  /** @domName IDBDatabase.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "IDBDatabase_dispatchEvent_Callback";


  /** @domName IDBDatabase.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "IDBDatabase_removeEventListener_Callback";


  /** @domName IDBDatabase.setVersion */
  IDBVersionChangeRequest setVersion(String version) native "IDBDatabase_setVersion_Callback";

  IDBTransaction transaction(storeName_OR_storeNames, /*DOMString*/ mode) {
    if ((storeName_OR_storeNames is List<String> || storeName_OR_storeNames == null) && (mode is String || mode == null)) {
      return _transaction_1(storeName_OR_storeNames, mode);
    }
    if ((storeName_OR_storeNames is List<String> || storeName_OR_storeNames == null) && (mode is String || mode == null)) {
      return _transaction_2(storeName_OR_storeNames, mode);
    }
    if ((storeName_OR_storeNames is String || storeName_OR_storeNames == null) && (mode is String || mode == null)) {
      return _transaction_3(storeName_OR_storeNames, mode);
    }
    throw "Incorrect number or type of arguments";
  }


  /** @domName IDBDatabase.transaction_1 */
  IDBTransaction _transaction_1(storeName_OR_storeNames, mode) native "IDBDatabase_transaction_1_Callback";


  /** @domName IDBDatabase.transaction_2 */
  IDBTransaction _transaction_2(storeName_OR_storeNames, mode) native "IDBDatabase_transaction_2_Callback";


  /** @domName IDBDatabase.transaction_3 */
  IDBTransaction _transaction_3(storeName_OR_storeNames, mode) native "IDBDatabase_transaction_3_Callback";

}

class IDBDatabaseEvents extends Events {
  IDBDatabaseEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get abort => this['abort'];

  EventListenerList get error => this['error'];

  EventListenerList get versionChange => this['versionchange'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName IDBDatabaseException
class IDBDatabaseException extends NativeFieldWrapperClass1 {
  IDBDatabaseException.internal();

  static const int ABORT_ERR = 20;

  static const int CONSTRAINT_ERR = 4;

  static const int DATA_ERR = 5;

  static const int NON_TRANSIENT_ERR = 2;

  static const int NOT_ALLOWED_ERR = 6;

  static const int NOT_FOUND_ERR = 8;

  static const int NO_ERR = 0;

  static const int QUOTA_ERR = 22;

  static const int READ_ONLY_ERR = 9;

  static const int TIMEOUT_ERR = 23;

  static const int TRANSACTION_INACTIVE_ERR = 7;

  static const int UNKNOWN_ERR = 1;

  static const int VER_ERR = 12;


  /** @domName IDBDatabaseException.code */
  int get code native "IDBDatabaseException_code_Getter";


  /** @domName IDBDatabaseException.message */
  String get message native "IDBDatabaseException_message_Getter";


  /** @domName IDBDatabaseException.name */
  String get name native "IDBDatabaseException_name_Getter";


  /** @domName IDBDatabaseException.toString */
  String toString() native "IDBDatabaseException_toString_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName IDBFactory
class IDBFactory extends NativeFieldWrapperClass1 {
  IDBFactory.internal();


  /** @domName IDBFactory.cmp */
  int cmp(/*IDBKey*/ first, /*IDBKey*/ second) native "IDBFactory_cmp_Callback";


  /** @domName IDBFactory.deleteDatabase */
  IDBVersionChangeRequest deleteDatabase(String name) native "IDBFactory_deleteDatabase_Callback";

  IDBOpenDBRequest open(/*DOMString*/ name, [/*long long*/ version]) {
    if (?version) {
      return _open_1(name, version);
    }
    return _open_2(name);
  }


  /** @domName IDBFactory.open_1 */
  IDBOpenDBRequest _open_1(name, version) native "IDBFactory_open_1_Callback";


  /** @domName IDBFactory.open_2 */
  IDBOpenDBRequest _open_2(name) native "IDBFactory_open_2_Callback";


  /** @domName IDBFactory.webkitGetDatabaseNames */
  IDBRequest webkitGetDatabaseNames() native "IDBFactory_webkitGetDatabaseNames_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName IDBIndex
class IDBIndex extends NativeFieldWrapperClass1 {
  IDBIndex.internal();


  /** @domName IDBIndex.keyPath */
  dynamic get keyPath native "IDBIndex_keyPath_Getter";


  /** @domName IDBIndex.multiEntry */
  bool get multiEntry native "IDBIndex_multiEntry_Getter";


  /** @domName IDBIndex.name */
  String get name native "IDBIndex_name_Getter";


  /** @domName IDBIndex.objectStore */
  IDBObjectStore get objectStore native "IDBIndex_objectStore_Getter";


  /** @domName IDBIndex.unique */
  bool get unique native "IDBIndex_unique_Getter";

  IDBRequest count([key_OR_range]) {
    if (!?key_OR_range) {
      return _count_1();
    }
    if ((key_OR_range is IDBKeyRange || key_OR_range == null)) {
      return _count_2(key_OR_range);
    }
    return _count_3(key_OR_range);
    throw "Incorrect number or type of arguments";
  }


  /** @domName IDBIndex.count_1 */
  IDBRequest _count_1() native "IDBIndex_count_1_Callback";


  /** @domName IDBIndex.count_2 */
  IDBRequest _count_2(key_OR_range) native "IDBIndex_count_2_Callback";


  /** @domName IDBIndex.count_3 */
  IDBRequest _count_3(key_OR_range) native "IDBIndex_count_3_Callback";

  IDBRequest get(key) {
    if ((key is IDBKeyRange || key == null)) {
      return _get_1(key);
    }
    return _get_2(key);
    throw "Incorrect number or type of arguments";
  }


  /** @domName IDBIndex.get_1 */
  IDBRequest _get_1(key) native "IDBIndex_get_1_Callback";


  /** @domName IDBIndex.get_2 */
  IDBRequest _get_2(key) native "IDBIndex_get_2_Callback";

  IDBRequest getKey(key) {
    if ((key is IDBKeyRange || key == null)) {
      return _getKey_1(key);
    }
    return _getKey_2(key);
    throw "Incorrect number or type of arguments";
  }


  /** @domName IDBIndex.getKey_1 */
  IDBRequest _getKey_1(key) native "IDBIndex_getKey_1_Callback";


  /** @domName IDBIndex.getKey_2 */
  IDBRequest _getKey_2(key) native "IDBIndex_getKey_2_Callback";

  IDBRequest openCursor([key_OR_range, /*DOMString*/ direction]) {
    if (!?key_OR_range && !?direction) {
      return _openCursor_1();
    }
    if ((key_OR_range is IDBKeyRange || key_OR_range == null) && !?direction) {
      return _openCursor_2(key_OR_range);
    }
    if ((key_OR_range is IDBKeyRange || key_OR_range == null) && (direction is String || direction == null)) {
      return _openCursor_3(key_OR_range, direction);
    }
    if (!?direction) {
      return _openCursor_4(key_OR_range);
    }
    if ((direction is String || direction == null)) {
      return _openCursor_5(key_OR_range, direction);
    }
    throw "Incorrect number or type of arguments";
  }


  /** @domName IDBIndex.openCursor_1 */
  IDBRequest _openCursor_1() native "IDBIndex_openCursor_1_Callback";


  /** @domName IDBIndex.openCursor_2 */
  IDBRequest _openCursor_2(key_OR_range) native "IDBIndex_openCursor_2_Callback";


  /** @domName IDBIndex.openCursor_3 */
  IDBRequest _openCursor_3(key_OR_range, direction) native "IDBIndex_openCursor_3_Callback";


  /** @domName IDBIndex.openCursor_4 */
  IDBRequest _openCursor_4(key_OR_range) native "IDBIndex_openCursor_4_Callback";


  /** @domName IDBIndex.openCursor_5 */
  IDBRequest _openCursor_5(key_OR_range, direction) native "IDBIndex_openCursor_5_Callback";

  IDBRequest openKeyCursor([key_OR_range, /*DOMString*/ direction]) {
    if (!?key_OR_range && !?direction) {
      return _openKeyCursor_1();
    }
    if ((key_OR_range is IDBKeyRange || key_OR_range == null) && !?direction) {
      return _openKeyCursor_2(key_OR_range);
    }
    if ((key_OR_range is IDBKeyRange || key_OR_range == null) && (direction is String || direction == null)) {
      return _openKeyCursor_3(key_OR_range, direction);
    }
    if (!?direction) {
      return _openKeyCursor_4(key_OR_range);
    }
    if ((direction is String || direction == null)) {
      return _openKeyCursor_5(key_OR_range, direction);
    }
    throw "Incorrect number or type of arguments";
  }


  /** @domName IDBIndex.openKeyCursor_1 */
  IDBRequest _openKeyCursor_1() native "IDBIndex_openKeyCursor_1_Callback";


  /** @domName IDBIndex.openKeyCursor_2 */
  IDBRequest _openKeyCursor_2(key_OR_range) native "IDBIndex_openKeyCursor_2_Callback";


  /** @domName IDBIndex.openKeyCursor_3 */
  IDBRequest _openKeyCursor_3(key_OR_range, direction) native "IDBIndex_openKeyCursor_3_Callback";


  /** @domName IDBIndex.openKeyCursor_4 */
  IDBRequest _openKeyCursor_4(key_OR_range) native "IDBIndex_openKeyCursor_4_Callback";


  /** @domName IDBIndex.openKeyCursor_5 */
  IDBRequest _openKeyCursor_5(key_OR_range, direction) native "IDBIndex_openKeyCursor_5_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName IDBKey
class IDBKey extends NativeFieldWrapperClass1 {
  IDBKey.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class IDBKeyRange extends NativeFieldWrapperClass1 {
  /**
   * @domName IDBKeyRange.only
   */
  factory IDBKeyRange.only(/*IDBKey*/ value) =>
      _IDBKeyRangeFactoryProvider.createIDBKeyRange_only(value);

  /**
   * @domName IDBKeyRange.lowerBound
   */
  factory IDBKeyRange.lowerBound(/*IDBKey*/ bound, [bool open = false]) =>
      _IDBKeyRangeFactoryProvider.createIDBKeyRange_lowerBound(bound, open);

  /**
   * @domName IDBKeyRange.upperBound
   */
  factory IDBKeyRange.upperBound(/*IDBKey*/ bound, [bool open = false]) =>
      _IDBKeyRangeFactoryProvider.createIDBKeyRange_upperBound(bound, open);

  /**
   * @domName IDBKeyRange.bound
   */
  factory IDBKeyRange.bound(/*IDBKey*/ lower, /*IDBKey*/ upper,
                            [bool lowerOpen = false, bool upperOpen = false]) =>
      _IDBKeyRangeFactoryProvider.createIDBKeyRange_bound(
          lower, upper, lowerOpen, upperOpen);

  IDBKeyRange.internal();


  /** @domName IDBKeyRange.lower */
  dynamic get lower native "IDBKeyRange_lower_Getter";


  /** @domName IDBKeyRange.lowerOpen */
  bool get lowerOpen native "IDBKeyRange_lowerOpen_Getter";


  /** @domName IDBKeyRange.upper */
  dynamic get upper native "IDBKeyRange_upper_Getter";


  /** @domName IDBKeyRange.upperOpen */
  bool get upperOpen native "IDBKeyRange_upperOpen_Getter";

  static IDBKeyRange bound_(/*IDBKey*/ lower, /*IDBKey*/ upper, [/*boolean*/ lowerOpen, /*boolean*/ upperOpen]) {
    if (?upperOpen) {
      return _bound_1(lower, upper, lowerOpen, upperOpen);
    }
    if (?lowerOpen) {
      return _bound_2(lower, upper, lowerOpen);
    }
    return _bound_3(lower, upper);
  }


  /** @domName IDBKeyRange.bound_1 */
  static IDBKeyRange _bound_1(lower, upper, lowerOpen, upperOpen) native "IDBKeyRange_bound_1_Callback";


  /** @domName IDBKeyRange.bound_2 */
  static IDBKeyRange _bound_2(lower, upper, lowerOpen) native "IDBKeyRange_bound_2_Callback";


  /** @domName IDBKeyRange.bound_3 */
  static IDBKeyRange _bound_3(lower, upper) native "IDBKeyRange_bound_3_Callback";

  static IDBKeyRange lowerBound_(/*IDBKey*/ bound, [/*boolean*/ open]) {
    if (?open) {
      return _lowerBound_1(bound, open);
    }
    return _lowerBound_2(bound);
  }


  /** @domName IDBKeyRange.lowerBound_1 */
  static IDBKeyRange _lowerBound_1(bound, open) native "IDBKeyRange_lowerBound_1_Callback";


  /** @domName IDBKeyRange.lowerBound_2 */
  static IDBKeyRange _lowerBound_2(bound) native "IDBKeyRange_lowerBound_2_Callback";


  /** @domName IDBKeyRange.only_ */
  static IDBKeyRange only_(/*IDBKey*/ value) native "IDBKeyRange_only__Callback";

  static IDBKeyRange upperBound_(/*IDBKey*/ bound, [/*boolean*/ open]) {
    if (?open) {
      return _upperBound_1(bound, open);
    }
    return _upperBound_2(bound);
  }


  /** @domName IDBKeyRange.upperBound_1 */
  static IDBKeyRange _upperBound_1(bound, open) native "IDBKeyRange_upperBound_1_Callback";


  /** @domName IDBKeyRange.upperBound_2 */
  static IDBKeyRange _upperBound_2(bound) native "IDBKeyRange_upperBound_2_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName IDBObjectStore
class IDBObjectStore extends NativeFieldWrapperClass1 {
  IDBObjectStore.internal();


  /** @domName IDBObjectStore.autoIncrement */
  bool get autoIncrement native "IDBObjectStore_autoIncrement_Getter";


  /** @domName IDBObjectStore.indexNames */
  List<String> get indexNames native "IDBObjectStore_indexNames_Getter";


  /** @domName IDBObjectStore.keyPath */
  dynamic get keyPath native "IDBObjectStore_keyPath_Getter";


  /** @domName IDBObjectStore.name */
  String get name native "IDBObjectStore_name_Getter";


  /** @domName IDBObjectStore.transaction */
  IDBTransaction get transaction native "IDBObjectStore_transaction_Getter";

  IDBRequest add(/*any*/ value, [/*IDBKey*/ key]) {
    if (?key) {
      return _add_1(value, key);
    }
    return _add_2(value);
  }


  /** @domName IDBObjectStore.add_1 */
  IDBRequest _add_1(value, key) native "IDBObjectStore_add_1_Callback";


  /** @domName IDBObjectStore.add_2 */
  IDBRequest _add_2(value) native "IDBObjectStore_add_2_Callback";


  /** @domName IDBObjectStore.clear */
  IDBRequest clear() native "IDBObjectStore_clear_Callback";

  IDBRequest count([key_OR_range]) {
    if (!?key_OR_range) {
      return _count_1();
    }
    if ((key_OR_range is IDBKeyRange || key_OR_range == null)) {
      return _count_2(key_OR_range);
    }
    return _count_3(key_OR_range);
    throw "Incorrect number or type of arguments";
  }


  /** @domName IDBObjectStore.count_1 */
  IDBRequest _count_1() native "IDBObjectStore_count_1_Callback";


  /** @domName IDBObjectStore.count_2 */
  IDBRequest _count_2(key_OR_range) native "IDBObjectStore_count_2_Callback";


  /** @domName IDBObjectStore.count_3 */
  IDBRequest _count_3(key_OR_range) native "IDBObjectStore_count_3_Callback";

  IDBIndex createIndex(/*DOMString*/ name, keyPath, [/*Dictionary*/ options]) {
    if ((name is String || name == null) && (keyPath is List<String> || keyPath == null) && (options is Map || options == null)) {
      return _createIndex_1(name, keyPath, options);
    }
    if ((name is String || name == null) && (keyPath is String || keyPath == null) && (options is Map || options == null)) {
      return _createIndex_2(name, keyPath, options);
    }
    throw "Incorrect number or type of arguments";
  }


  /** @domName IDBObjectStore.createIndex_1 */
  IDBIndex _createIndex_1(name, keyPath, options) native "IDBObjectStore_createIndex_1_Callback";


  /** @domName IDBObjectStore.createIndex_2 */
  IDBIndex _createIndex_2(name, keyPath, options) native "IDBObjectStore_createIndex_2_Callback";

  IDBRequest delete(key_OR_keyRange) {
    if ((key_OR_keyRange is IDBKeyRange || key_OR_keyRange == null)) {
      return _delete_1(key_OR_keyRange);
    }
    return _delete_2(key_OR_keyRange);
    throw "Incorrect number or type of arguments";
  }


  /** @domName IDBObjectStore.delete_1 */
  IDBRequest _delete_1(key_OR_keyRange) native "IDBObjectStore_delete_1_Callback";


  /** @domName IDBObjectStore.delete_2 */
  IDBRequest _delete_2(key_OR_keyRange) native "IDBObjectStore_delete_2_Callback";


  /** @domName IDBObjectStore.deleteIndex */
  void deleteIndex(String name) native "IDBObjectStore_deleteIndex_Callback";

  IDBRequest getObject(key) {
    if ((key is IDBKeyRange || key == null)) {
      return _get_1(key);
    }
    return _get_2(key);
    throw "Incorrect number or type of arguments";
  }


  /** @domName IDBObjectStore.get_1 */
  IDBRequest _get_1(key) native "IDBObjectStore_get_1_Callback";


  /** @domName IDBObjectStore.get_2 */
  IDBRequest _get_2(key) native "IDBObjectStore_get_2_Callback";


  /** @domName IDBObjectStore.index */
  IDBIndex index(String name) native "IDBObjectStore_index_Callback";

  IDBRequest openCursor([key_OR_range, /*DOMString*/ direction]) {
    if (!?key_OR_range && !?direction) {
      return _openCursor_1();
    }
    if ((key_OR_range is IDBKeyRange || key_OR_range == null) && !?direction) {
      return _openCursor_2(key_OR_range);
    }
    if ((key_OR_range is IDBKeyRange || key_OR_range == null) && (direction is String || direction == null)) {
      return _openCursor_3(key_OR_range, direction);
    }
    if (!?direction) {
      return _openCursor_4(key_OR_range);
    }
    if ((direction is String || direction == null)) {
      return _openCursor_5(key_OR_range, direction);
    }
    throw "Incorrect number or type of arguments";
  }


  /** @domName IDBObjectStore.openCursor_1 */
  IDBRequest _openCursor_1() native "IDBObjectStore_openCursor_1_Callback";


  /** @domName IDBObjectStore.openCursor_2 */
  IDBRequest _openCursor_2(key_OR_range) native "IDBObjectStore_openCursor_2_Callback";


  /** @domName IDBObjectStore.openCursor_3 */
  IDBRequest _openCursor_3(key_OR_range, direction) native "IDBObjectStore_openCursor_3_Callback";


  /** @domName IDBObjectStore.openCursor_4 */
  IDBRequest _openCursor_4(key_OR_range) native "IDBObjectStore_openCursor_4_Callback";


  /** @domName IDBObjectStore.openCursor_5 */
  IDBRequest _openCursor_5(key_OR_range, direction) native "IDBObjectStore_openCursor_5_Callback";

  IDBRequest put(/*any*/ value, [/*IDBKey*/ key]) {
    if (?key) {
      return _put_1(value, key);
    }
    return _put_2(value);
  }


  /** @domName IDBObjectStore.put_1 */
  IDBRequest _put_1(value, key) native "IDBObjectStore_put_1_Callback";


  /** @domName IDBObjectStore.put_2 */
  IDBRequest _put_2(value) native "IDBObjectStore_put_2_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName IDBOpenDBRequest
class IDBOpenDBRequest extends IDBRequest implements EventTarget {
  IDBOpenDBRequest.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  IDBOpenDBRequestEvents get on =>
    new IDBOpenDBRequestEvents(this);

}

class IDBOpenDBRequestEvents extends IDBRequestEvents {
  IDBOpenDBRequestEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get blocked => this['blocked'];

  EventListenerList get upgradeNeeded => this['upgradeneeded'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName IDBRequest
class IDBRequest extends EventTarget {
  IDBRequest.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  IDBRequestEvents get on =>
    new IDBRequestEvents(this);


  /** @domName IDBRequest.error */
  DOMError get error native "IDBRequest_error_Getter";


  /** @domName IDBRequest.errorCode */
  int get errorCode native "IDBRequest_errorCode_Getter";


  /** @domName IDBRequest.readyState */
  String get readyState native "IDBRequest_readyState_Getter";


  /** @domName IDBRequest.result */
  dynamic get result native "IDBRequest_result_Getter";


  /** @domName IDBRequest.source */
  dynamic get source native "IDBRequest_source_Getter";


  /** @domName IDBRequest.transaction */
  IDBTransaction get transaction native "IDBRequest_transaction_Getter";


  /** @domName IDBRequest.webkitErrorMessage */
  String get webkitErrorMessage native "IDBRequest_webkitErrorMessage_Getter";


  /** @domName IDBRequest.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "IDBRequest_addEventListener_Callback";


  /** @domName IDBRequest.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "IDBRequest_dispatchEvent_Callback";


  /** @domName IDBRequest.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "IDBRequest_removeEventListener_Callback";

}

class IDBRequestEvents extends Events {
  IDBRequestEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get error => this['error'];

  EventListenerList get success => this['success'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName IDBTransaction
class IDBTransaction extends EventTarget {
  IDBTransaction.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  IDBTransactionEvents get on =>
    new IDBTransactionEvents(this);

  static const int READ_ONLY = 0;

  static const int READ_WRITE = 1;

  static const int VERSION_CHANGE = 2;


  /** @domName IDBTransaction.db */
  IDBDatabase get db native "IDBTransaction_db_Getter";


  /** @domName IDBTransaction.error */
  DOMError get error native "IDBTransaction_error_Getter";


  /** @domName IDBTransaction.mode */
  String get mode native "IDBTransaction_mode_Getter";


  /** @domName IDBTransaction.abort */
  void abort() native "IDBTransaction_abort_Callback";


  /** @domName IDBTransaction.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "IDBTransaction_addEventListener_Callback";


  /** @domName IDBTransaction.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "IDBTransaction_dispatchEvent_Callback";


  /** @domName IDBTransaction.objectStore */
  IDBObjectStore objectStore(String name) native "IDBTransaction_objectStore_Callback";


  /** @domName IDBTransaction.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "IDBTransaction_removeEventListener_Callback";

}

class IDBTransactionEvents extends Events {
  IDBTransactionEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get abort => this['abort'];

  EventListenerList get complete => this['complete'];

  EventListenerList get error => this['error'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName IDBVersionChangeEvent
class IDBUpgradeNeededEvent extends Event {
  IDBUpgradeNeededEvent.internal(): super.internal();


  /** @domName IDBUpgradeNeededEvent.newVersion */
  int get newVersion native "IDBUpgradeNeededEvent_newVersion_Getter";


  /** @domName IDBUpgradeNeededEvent.oldVersion */
  int get oldVersion native "IDBUpgradeNeededEvent_oldVersion_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName IDBVersionChangeEvent
class IDBVersionChangeEvent extends Event {
  IDBVersionChangeEvent.internal(): super.internal();


  /** @domName IDBVersionChangeEvent.version */
  String get version native "IDBVersionChangeEvent_version_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName IDBVersionChangeRequest
class IDBVersionChangeRequest extends IDBRequest implements EventTarget {
  IDBVersionChangeRequest.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  IDBVersionChangeRequestEvents get on =>
    new IDBVersionChangeRequestEvents(this);

}

class IDBVersionChangeRequestEvents extends IDBRequestEvents {
  IDBVersionChangeRequestEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get blocked => this['blocked'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLIFrameElement
class IFrameElement extends _Element_Merged {

  factory IFrameElement() => document.$dom_createElement("iframe");
  IFrameElement.internal(): super.internal();


  /** @domName HTMLIFrameElement.align */
  String get align native "HTMLIFrameElement_align_Getter";


  /** @domName HTMLIFrameElement.align */
  void set align(String value) native "HTMLIFrameElement_align_Setter";


  /** @domName HTMLIFrameElement.contentWindow */
  Window get contentWindow native "HTMLIFrameElement_contentWindow_Getter";


  /** @domName HTMLIFrameElement.frameBorder */
  String get frameBorder native "HTMLIFrameElement_frameBorder_Getter";


  /** @domName HTMLIFrameElement.frameBorder */
  void set frameBorder(String value) native "HTMLIFrameElement_frameBorder_Setter";


  /** @domName HTMLIFrameElement.height */
  String get height native "HTMLIFrameElement_height_Getter";


  /** @domName HTMLIFrameElement.height */
  void set height(String value) native "HTMLIFrameElement_height_Setter";


  /** @domName HTMLIFrameElement.longDesc */
  String get longDesc native "HTMLIFrameElement_longDesc_Getter";


  /** @domName HTMLIFrameElement.longDesc */
  void set longDesc(String value) native "HTMLIFrameElement_longDesc_Setter";


  /** @domName HTMLIFrameElement.marginHeight */
  String get marginHeight native "HTMLIFrameElement_marginHeight_Getter";


  /** @domName HTMLIFrameElement.marginHeight */
  void set marginHeight(String value) native "HTMLIFrameElement_marginHeight_Setter";


  /** @domName HTMLIFrameElement.marginWidth */
  String get marginWidth native "HTMLIFrameElement_marginWidth_Getter";


  /** @domName HTMLIFrameElement.marginWidth */
  void set marginWidth(String value) native "HTMLIFrameElement_marginWidth_Setter";


  /** @domName HTMLIFrameElement.name */
  String get name native "HTMLIFrameElement_name_Getter";


  /** @domName HTMLIFrameElement.name */
  void set name(String value) native "HTMLIFrameElement_name_Setter";


  /** @domName HTMLIFrameElement.sandbox */
  String get sandbox native "HTMLIFrameElement_sandbox_Getter";


  /** @domName HTMLIFrameElement.sandbox */
  void set sandbox(String value) native "HTMLIFrameElement_sandbox_Setter";


  /** @domName HTMLIFrameElement.scrolling */
  String get scrolling native "HTMLIFrameElement_scrolling_Getter";


  /** @domName HTMLIFrameElement.scrolling */
  void set scrolling(String value) native "HTMLIFrameElement_scrolling_Setter";


  /** @domName HTMLIFrameElement.src */
  String get src native "HTMLIFrameElement_src_Getter";


  /** @domName HTMLIFrameElement.src */
  void set src(String value) native "HTMLIFrameElement_src_Setter";


  /** @domName HTMLIFrameElement.srcdoc */
  String get srcdoc native "HTMLIFrameElement_srcdoc_Getter";


  /** @domName HTMLIFrameElement.srcdoc */
  void set srcdoc(String value) native "HTMLIFrameElement_srcdoc_Setter";


  /** @domName HTMLIFrameElement.width */
  String get width native "HTMLIFrameElement_width_Getter";


  /** @domName HTMLIFrameElement.width */
  void set width(String value) native "HTMLIFrameElement_width_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void IceCallback(IceCandidate candidate, bool moreToFollow, PeerConnection00 source);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName IceCandidate
class IceCandidate extends NativeFieldWrapperClass1 {

  factory IceCandidate(String label, String candidateLine) => _IceCandidateFactoryProvider.createIceCandidate(label, candidateLine);
  IceCandidate.internal();


  /** @domName IceCandidate.label */
  String get label native "IceCandidate_label_Getter";


  /** @domName IceCandidate.toSdp */
  String toSdp() native "IceCandidate_toSdp_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName ImageData
class ImageData extends NativeFieldWrapperClass1 {
  ImageData.internal();


  /** @domName ImageData.data */
  Uint8ClampedArray get data native "ImageData_data_Getter";


  /** @domName ImageData.height */
  int get height native "ImageData_height_Getter";


  /** @domName ImageData.width */
  int get width native "ImageData_width_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLImageElement
class ImageElement extends _Element_Merged {

  factory ImageElement({String src, int width, int height}) {
    var e = document.$dom_createElement("img");
    if (src != null) e.src = src;
    if (width != null) e.width = width;
    if (height != null) e.height = height;
    return e;
  }
  ImageElement.internal(): super.internal();


  /** @domName HTMLImageElement.align */
  String get align native "HTMLImageElement_align_Getter";


  /** @domName HTMLImageElement.align */
  void set align(String value) native "HTMLImageElement_align_Setter";


  /** @domName HTMLImageElement.alt */
  String get alt native "HTMLImageElement_alt_Getter";


  /** @domName HTMLImageElement.alt */
  void set alt(String value) native "HTMLImageElement_alt_Setter";


  /** @domName HTMLImageElement.border */
  String get border native "HTMLImageElement_border_Getter";


  /** @domName HTMLImageElement.border */
  void set border(String value) native "HTMLImageElement_border_Setter";


  /** @domName HTMLImageElement.complete */
  bool get complete native "HTMLImageElement_complete_Getter";


  /** @domName HTMLImageElement.crossOrigin */
  String get crossOrigin native "HTMLImageElement_crossOrigin_Getter";


  /** @domName HTMLImageElement.crossOrigin */
  void set crossOrigin(String value) native "HTMLImageElement_crossOrigin_Setter";


  /** @domName HTMLImageElement.height */
  int get height native "HTMLImageElement_height_Getter";


  /** @domName HTMLImageElement.height */
  void set height(int value) native "HTMLImageElement_height_Setter";


  /** @domName HTMLImageElement.hspace */
  int get hspace native "HTMLImageElement_hspace_Getter";


  /** @domName HTMLImageElement.hspace */
  void set hspace(int value) native "HTMLImageElement_hspace_Setter";


  /** @domName HTMLImageElement.isMap */
  bool get isMap native "HTMLImageElement_isMap_Getter";


  /** @domName HTMLImageElement.isMap */
  void set isMap(bool value) native "HTMLImageElement_isMap_Setter";


  /** @domName HTMLImageElement.longDesc */
  String get longDesc native "HTMLImageElement_longDesc_Getter";


  /** @domName HTMLImageElement.longDesc */
  void set longDesc(String value) native "HTMLImageElement_longDesc_Setter";


  /** @domName HTMLImageElement.lowsrc */
  String get lowsrc native "HTMLImageElement_lowsrc_Getter";


  /** @domName HTMLImageElement.lowsrc */
  void set lowsrc(String value) native "HTMLImageElement_lowsrc_Setter";


  /** @domName HTMLImageElement.name */
  String get name native "HTMLImageElement_name_Getter";


  /** @domName HTMLImageElement.name */
  void set name(String value) native "HTMLImageElement_name_Setter";


  /** @domName HTMLImageElement.naturalHeight */
  int get naturalHeight native "HTMLImageElement_naturalHeight_Getter";


  /** @domName HTMLImageElement.naturalWidth */
  int get naturalWidth native "HTMLImageElement_naturalWidth_Getter";


  /** @domName HTMLImageElement.src */
  String get src native "HTMLImageElement_src_Getter";


  /** @domName HTMLImageElement.src */
  void set src(String value) native "HTMLImageElement_src_Setter";


  /** @domName HTMLImageElement.useMap */
  String get useMap native "HTMLImageElement_useMap_Getter";


  /** @domName HTMLImageElement.useMap */
  void set useMap(String value) native "HTMLImageElement_useMap_Setter";


  /** @domName HTMLImageElement.vspace */
  int get vspace native "HTMLImageElement_vspace_Getter";


  /** @domName HTMLImageElement.vspace */
  void set vspace(int value) native "HTMLImageElement_vspace_Setter";


  /** @domName HTMLImageElement.width */
  int get width native "HTMLImageElement_width_Getter";


  /** @domName HTMLImageElement.width */
  void set width(int value) native "HTMLImageElement_width_Setter";


  /** @domName HTMLImageElement.x */
  int get x native "HTMLImageElement_x_Getter";


  /** @domName HTMLImageElement.y */
  int get y native "HTMLImageElement_y_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLInputElement
class InputElement extends _Element_Merged {

  factory InputElement({String type}) {
    var e = document.$dom_createElement("input");
    if (type != null) e.type = type;
    return e;
  }
  InputElement.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  InputElementEvents get on =>
    new InputElementEvents(this);


  /** @domName HTMLInputElement.accept */
  String get accept native "HTMLInputElement_accept_Getter";


  /** @domName HTMLInputElement.accept */
  void set accept(String value) native "HTMLInputElement_accept_Setter";


  /** @domName HTMLInputElement.align */
  String get align native "HTMLInputElement_align_Getter";


  /** @domName HTMLInputElement.align */
  void set align(String value) native "HTMLInputElement_align_Setter";


  /** @domName HTMLInputElement.alt */
  String get alt native "HTMLInputElement_alt_Getter";


  /** @domName HTMLInputElement.alt */
  void set alt(String value) native "HTMLInputElement_alt_Setter";


  /** @domName HTMLInputElement.autocomplete */
  String get autocomplete native "HTMLInputElement_autocomplete_Getter";


  /** @domName HTMLInputElement.autocomplete */
  void set autocomplete(String value) native "HTMLInputElement_autocomplete_Setter";


  /** @domName HTMLInputElement.autofocus */
  bool get autofocus native "HTMLInputElement_autofocus_Getter";


  /** @domName HTMLInputElement.autofocus */
  void set autofocus(bool value) native "HTMLInputElement_autofocus_Setter";


  /** @domName HTMLInputElement.checked */
  bool get checked native "HTMLInputElement_checked_Getter";


  /** @domName HTMLInputElement.checked */
  void set checked(bool value) native "HTMLInputElement_checked_Setter";


  /** @domName HTMLInputElement.defaultChecked */
  bool get defaultChecked native "HTMLInputElement_defaultChecked_Getter";


  /** @domName HTMLInputElement.defaultChecked */
  void set defaultChecked(bool value) native "HTMLInputElement_defaultChecked_Setter";


  /** @domName HTMLInputElement.defaultValue */
  String get defaultValue native "HTMLInputElement_defaultValue_Getter";


  /** @domName HTMLInputElement.defaultValue */
  void set defaultValue(String value) native "HTMLInputElement_defaultValue_Setter";


  /** @domName HTMLInputElement.dirName */
  String get dirName native "HTMLInputElement_dirName_Getter";


  /** @domName HTMLInputElement.dirName */
  void set dirName(String value) native "HTMLInputElement_dirName_Setter";


  /** @domName HTMLInputElement.disabled */
  bool get disabled native "HTMLInputElement_disabled_Getter";


  /** @domName HTMLInputElement.disabled */
  void set disabled(bool value) native "HTMLInputElement_disabled_Setter";


  /** @domName HTMLInputElement.files */
  List<File> get files native "HTMLInputElement_files_Getter";


  /** @domName HTMLInputElement.files */
  void set files(List<File> value) native "HTMLInputElement_files_Setter";


  /** @domName HTMLInputElement.form */
  FormElement get form native "HTMLInputElement_form_Getter";


  /** @domName HTMLInputElement.formAction */
  String get formAction native "HTMLInputElement_formAction_Getter";


  /** @domName HTMLInputElement.formAction */
  void set formAction(String value) native "HTMLInputElement_formAction_Setter";


  /** @domName HTMLInputElement.formEnctype */
  String get formEnctype native "HTMLInputElement_formEnctype_Getter";


  /** @domName HTMLInputElement.formEnctype */
  void set formEnctype(String value) native "HTMLInputElement_formEnctype_Setter";


  /** @domName HTMLInputElement.formMethod */
  String get formMethod native "HTMLInputElement_formMethod_Getter";


  /** @domName HTMLInputElement.formMethod */
  void set formMethod(String value) native "HTMLInputElement_formMethod_Setter";


  /** @domName HTMLInputElement.formNoValidate */
  bool get formNoValidate native "HTMLInputElement_formNoValidate_Getter";


  /** @domName HTMLInputElement.formNoValidate */
  void set formNoValidate(bool value) native "HTMLInputElement_formNoValidate_Setter";


  /** @domName HTMLInputElement.formTarget */
  String get formTarget native "HTMLInputElement_formTarget_Getter";


  /** @domName HTMLInputElement.formTarget */
  void set formTarget(String value) native "HTMLInputElement_formTarget_Setter";


  /** @domName HTMLInputElement.height */
  int get height native "HTMLInputElement_height_Getter";


  /** @domName HTMLInputElement.height */
  void set height(int value) native "HTMLInputElement_height_Setter";


  /** @domName HTMLInputElement.incremental */
  bool get incremental native "HTMLInputElement_incremental_Getter";


  /** @domName HTMLInputElement.incremental */
  void set incremental(bool value) native "HTMLInputElement_incremental_Setter";


  /** @domName HTMLInputElement.indeterminate */
  bool get indeterminate native "HTMLInputElement_indeterminate_Getter";


  /** @domName HTMLInputElement.indeterminate */
  void set indeterminate(bool value) native "HTMLInputElement_indeterminate_Setter";


  /** @domName HTMLInputElement.labels */
  List<Node> get labels native "HTMLInputElement_labels_Getter";


  /** @domName HTMLInputElement.list */
  Element get list native "HTMLInputElement_list_Getter";


  /** @domName HTMLInputElement.max */
  String get max native "HTMLInputElement_max_Getter";


  /** @domName HTMLInputElement.max */
  void set max(String value) native "HTMLInputElement_max_Setter";


  /** @domName HTMLInputElement.maxLength */
  int get maxLength native "HTMLInputElement_maxLength_Getter";


  /** @domName HTMLInputElement.maxLength */
  void set maxLength(int value) native "HTMLInputElement_maxLength_Setter";


  /** @domName HTMLInputElement.min */
  String get min native "HTMLInputElement_min_Getter";


  /** @domName HTMLInputElement.min */
  void set min(String value) native "HTMLInputElement_min_Setter";


  /** @domName HTMLInputElement.multiple */
  bool get multiple native "HTMLInputElement_multiple_Getter";


  /** @domName HTMLInputElement.multiple */
  void set multiple(bool value) native "HTMLInputElement_multiple_Setter";


  /** @domName HTMLInputElement.name */
  String get name native "HTMLInputElement_name_Getter";


  /** @domName HTMLInputElement.name */
  void set name(String value) native "HTMLInputElement_name_Setter";


  /** @domName HTMLInputElement.pattern */
  String get pattern native "HTMLInputElement_pattern_Getter";


  /** @domName HTMLInputElement.pattern */
  void set pattern(String value) native "HTMLInputElement_pattern_Setter";


  /** @domName HTMLInputElement.placeholder */
  String get placeholder native "HTMLInputElement_placeholder_Getter";


  /** @domName HTMLInputElement.placeholder */
  void set placeholder(String value) native "HTMLInputElement_placeholder_Setter";


  /** @domName HTMLInputElement.readOnly */
  bool get readOnly native "HTMLInputElement_readOnly_Getter";


  /** @domName HTMLInputElement.readOnly */
  void set readOnly(bool value) native "HTMLInputElement_readOnly_Setter";


  /** @domName HTMLInputElement.required */
  bool get required native "HTMLInputElement_required_Getter";


  /** @domName HTMLInputElement.required */
  void set required(bool value) native "HTMLInputElement_required_Setter";


  /** @domName HTMLInputElement.selectionDirection */
  String get selectionDirection native "HTMLInputElement_selectionDirection_Getter";


  /** @domName HTMLInputElement.selectionDirection */
  void set selectionDirection(String value) native "HTMLInputElement_selectionDirection_Setter";


  /** @domName HTMLInputElement.selectionEnd */
  int get selectionEnd native "HTMLInputElement_selectionEnd_Getter";


  /** @domName HTMLInputElement.selectionEnd */
  void set selectionEnd(int value) native "HTMLInputElement_selectionEnd_Setter";


  /** @domName HTMLInputElement.selectionStart */
  int get selectionStart native "HTMLInputElement_selectionStart_Getter";


  /** @domName HTMLInputElement.selectionStart */
  void set selectionStart(int value) native "HTMLInputElement_selectionStart_Setter";


  /** @domName HTMLInputElement.size */
  int get size native "HTMLInputElement_size_Getter";


  /** @domName HTMLInputElement.size */
  void set size(int value) native "HTMLInputElement_size_Setter";


  /** @domName HTMLInputElement.src */
  String get src native "HTMLInputElement_src_Getter";


  /** @domName HTMLInputElement.src */
  void set src(String value) native "HTMLInputElement_src_Setter";


  /** @domName HTMLInputElement.step */
  String get step native "HTMLInputElement_step_Getter";


  /** @domName HTMLInputElement.step */
  void set step(String value) native "HTMLInputElement_step_Setter";


  /** @domName HTMLInputElement.type */
  String get type native "HTMLInputElement_type_Getter";


  /** @domName HTMLInputElement.type */
  void set type(String value) native "HTMLInputElement_type_Setter";


  /** @domName HTMLInputElement.useMap */
  String get useMap native "HTMLInputElement_useMap_Getter";


  /** @domName HTMLInputElement.useMap */
  void set useMap(String value) native "HTMLInputElement_useMap_Setter";


  /** @domName HTMLInputElement.validationMessage */
  String get validationMessage native "HTMLInputElement_validationMessage_Getter";


  /** @domName HTMLInputElement.validity */
  ValidityState get validity native "HTMLInputElement_validity_Getter";


  /** @domName HTMLInputElement.value */
  String get value native "HTMLInputElement_value_Getter";


  /** @domName HTMLInputElement.value */
  void set value(String value) native "HTMLInputElement_value_Setter";


  /** @domName HTMLInputElement.valueAsDate */
  Date get valueAsDate native "HTMLInputElement_valueAsDate_Getter";


  /** @domName HTMLInputElement.valueAsDate */
  void set valueAsDate(Date value) native "HTMLInputElement_valueAsDate_Setter";


  /** @domName HTMLInputElement.valueAsNumber */
  num get valueAsNumber native "HTMLInputElement_valueAsNumber_Getter";


  /** @domName HTMLInputElement.valueAsNumber */
  void set valueAsNumber(num value) native "HTMLInputElement_valueAsNumber_Setter";


  /** @domName HTMLInputElement.webkitEntries */
  List<Entry> get webkitEntries native "HTMLInputElement_webkitEntries_Getter";


  /** @domName HTMLInputElement.webkitGrammar */
  bool get webkitGrammar native "HTMLInputElement_webkitGrammar_Getter";


  /** @domName HTMLInputElement.webkitGrammar */
  void set webkitGrammar(bool value) native "HTMLInputElement_webkitGrammar_Setter";


  /** @domName HTMLInputElement.webkitSpeech */
  bool get webkitSpeech native "HTMLInputElement_webkitSpeech_Getter";


  /** @domName HTMLInputElement.webkitSpeech */
  void set webkitSpeech(bool value) native "HTMLInputElement_webkitSpeech_Setter";


  /** @domName HTMLInputElement.webkitdirectory */
  bool get webkitdirectory native "HTMLInputElement_webkitdirectory_Getter";


  /** @domName HTMLInputElement.webkitdirectory */
  void set webkitdirectory(bool value) native "HTMLInputElement_webkitdirectory_Setter";


  /** @domName HTMLInputElement.width */
  int get width native "HTMLInputElement_width_Getter";


  /** @domName HTMLInputElement.width */
  void set width(int value) native "HTMLInputElement_width_Setter";


  /** @domName HTMLInputElement.willValidate */
  bool get willValidate native "HTMLInputElement_willValidate_Getter";


  /** @domName HTMLInputElement.checkValidity */
  bool checkValidity() native "HTMLInputElement_checkValidity_Callback";


  /** @domName HTMLInputElement.select */
  void select() native "HTMLInputElement_select_Callback";


  /** @domName HTMLInputElement.setCustomValidity */
  void setCustomValidity(String error) native "HTMLInputElement_setCustomValidity_Callback";

  void setRangeText(/*DOMString*/ replacement, [/*unsigned long*/ start, /*unsigned long*/ end, /*DOMString*/ selectionMode]) {
    if ((replacement is String || replacement == null) && !?start && !?end && !?selectionMode) {
      _setRangeText_1(replacement);
      return;
    }
    if ((replacement is String || replacement == null) && (start is int || start == null) && (end is int || end == null) && (selectionMode is String || selectionMode == null)) {
      _setRangeText_2(replacement, start, end, selectionMode);
      return;
    }
    throw "Incorrect number or type of arguments";
  }


  /** @domName HTMLInputElement.setRangeText_1 */
  void _setRangeText_1(replacement) native "HTMLInputElement_setRangeText_1_Callback";


  /** @domName HTMLInputElement.setRangeText_2 */
  void _setRangeText_2(replacement, start, end, selectionMode) native "HTMLInputElement_setRangeText_2_Callback";


  /** @domName HTMLInputElement.setSelectionRange */
  void setSelectionRange(int start, int end, [String direction]) native "HTMLInputElement_setSelectionRange_Callback";

  void stepDown([/*long*/ n]) {
    if (?n) {
      _stepDown_1(n);
      return;
    }
    _stepDown_2();
  }


  /** @domName HTMLInputElement.stepDown_1 */
  void _stepDown_1(n) native "HTMLInputElement_stepDown_1_Callback";


  /** @domName HTMLInputElement.stepDown_2 */
  void _stepDown_2() native "HTMLInputElement_stepDown_2_Callback";

  void stepUp([/*long*/ n]) {
    if (?n) {
      _stepUp_1(n);
      return;
    }
    _stepUp_2();
  }


  /** @domName HTMLInputElement.stepUp_1 */
  void _stepUp_1(n) native "HTMLInputElement_stepUp_1_Callback";


  /** @domName HTMLInputElement.stepUp_2 */
  void _stepUp_2() native "HTMLInputElement_stepUp_2_Callback";

}

class InputElementEvents extends ElementEvents {
  InputElementEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get speechChange => this['webkitSpeechChange'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Int16Array
class Int16Array extends ArrayBufferView implements List<int> {

  factory Int16Array(int length) =>
    _TypedArrayFactoryProvider.createInt16Array(length);

  factory Int16Array.fromList(List<int> list) =>
    _TypedArrayFactoryProvider.createInt16Array_fromList(list);

  factory Int16Array.fromBuffer(ArrayBuffer buffer, [int byteOffset, int length]) => 
    _TypedArrayFactoryProvider.createInt16Array_fromBuffer(buffer, byteOffset, length);
  Int16Array.internal(): super.internal();

  static const int BYTES_PER_ELEMENT = 2;


  /** @domName Int16Array.length */
  int get length native "Int16Array_length_Getter";


  /** @domName Int16Array.numericIndexGetter */
  int operator[](int index) native "Int16Array_numericIndexGetter_Callback";


  /** @domName Int16Array.numericIndexSetter */
  void operator[]=(int index, int value) native "Int16Array_numericIndexSetter_Callback";
  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<int>(this);
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<int> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(int element) => _Collections.contains(this, element);

  void forEach(void f(int element)) => _Collections.forEach(this, f);

  Collection map(f(int element)) => _Collections.map(this, [], f);

  Collection<int> filter(bool f(int element)) =>
     _Collections.filter(this, <int>[], f);

  bool every(bool f(int element)) => _Collections.every(this, f);

  bool some(bool f(int element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<int>:

  void sort([Comparator<int> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int get first => this[0];

  int get last => this[length - 1];

  int removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<int> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [int initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<int> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <int>[]);

  // -- end List<int> mixins.


  /** @domName Int16Array.setElements */
  void setElements(Object array, [int offset]) native "Int16Array_setElements_Callback";

  Int16Array subarray(/*long*/ start, [/*long*/ end]) {
    if (?end) {
      return _subarray_1(start, end);
    }
    return _subarray_2(start);
  }


  /** @domName Int16Array.subarray_1 */
  Int16Array _subarray_1(start, end) native "Int16Array_subarray_1_Callback";


  /** @domName Int16Array.subarray_2 */
  Int16Array _subarray_2(start) native "Int16Array_subarray_2_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Int32Array
class Int32Array extends ArrayBufferView implements List<int> {

  factory Int32Array(int length) =>
    _TypedArrayFactoryProvider.createInt32Array(length);

  factory Int32Array.fromList(List<int> list) =>
    _TypedArrayFactoryProvider.createInt32Array_fromList(list);

  factory Int32Array.fromBuffer(ArrayBuffer buffer, [int byteOffset, int length]) => 
    _TypedArrayFactoryProvider.createInt32Array_fromBuffer(buffer, byteOffset, length);
  Int32Array.internal(): super.internal();

  static const int BYTES_PER_ELEMENT = 4;


  /** @domName Int32Array.length */
  int get length native "Int32Array_length_Getter";


  /** @domName Int32Array.numericIndexGetter */
  int operator[](int index) native "Int32Array_numericIndexGetter_Callback";


  /** @domName Int32Array.numericIndexSetter */
  void operator[]=(int index, int value) native "Int32Array_numericIndexSetter_Callback";
  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<int>(this);
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<int> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(int element) => _Collections.contains(this, element);

  void forEach(void f(int element)) => _Collections.forEach(this, f);

  Collection map(f(int element)) => _Collections.map(this, [], f);

  Collection<int> filter(bool f(int element)) =>
     _Collections.filter(this, <int>[], f);

  bool every(bool f(int element)) => _Collections.every(this, f);

  bool some(bool f(int element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<int>:

  void sort([Comparator<int> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int get first => this[0];

  int get last => this[length - 1];

  int removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<int> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [int initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<int> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <int>[]);

  // -- end List<int> mixins.


  /** @domName Int32Array.setElements */
  void setElements(Object array, [int offset]) native "Int32Array_setElements_Callback";

  Int32Array subarray(/*long*/ start, [/*long*/ end]) {
    if (?end) {
      return _subarray_1(start, end);
    }
    return _subarray_2(start);
  }


  /** @domName Int32Array.subarray_1 */
  Int32Array _subarray_1(start, end) native "Int32Array_subarray_1_Callback";


  /** @domName Int32Array.subarray_2 */
  Int32Array _subarray_2(start) native "Int32Array_subarray_2_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Int8Array
class Int8Array extends ArrayBufferView implements List<int> {

  factory Int8Array(int length) =>
    _TypedArrayFactoryProvider.createInt8Array(length);

  factory Int8Array.fromList(List<int> list) =>
    _TypedArrayFactoryProvider.createInt8Array_fromList(list);

  factory Int8Array.fromBuffer(ArrayBuffer buffer, [int byteOffset, int length]) => 
    _TypedArrayFactoryProvider.createInt8Array_fromBuffer(buffer, byteOffset, length);
  Int8Array.internal(): super.internal();

  static const int BYTES_PER_ELEMENT = 1;


  /** @domName Int8Array.length */
  int get length native "Int8Array_length_Getter";


  /** @domName Int8Array.numericIndexGetter */
  int operator[](int index) native "Int8Array_numericIndexGetter_Callback";


  /** @domName Int8Array.numericIndexSetter */
  void operator[]=(int index, int value) native "Int8Array_numericIndexSetter_Callback";
  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<int>(this);
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<int> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(int element) => _Collections.contains(this, element);

  void forEach(void f(int element)) => _Collections.forEach(this, f);

  Collection map(f(int element)) => _Collections.map(this, [], f);

  Collection<int> filter(bool f(int element)) =>
     _Collections.filter(this, <int>[], f);

  bool every(bool f(int element)) => _Collections.every(this, f);

  bool some(bool f(int element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<int>:

  void sort([Comparator<int> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int get first => this[0];

  int get last => this[length - 1];

  int removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<int> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [int initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<int> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <int>[]);

  // -- end List<int> mixins.


  /** @domName Int8Array.setElements */
  void setElements(Object array, [int offset]) native "Int8Array_setElements_Callback";

  Int8Array subarray(/*long*/ start, [/*long*/ end]) {
    if (?end) {
      return _subarray_1(start, end);
    }
    return _subarray_2(start);
  }


  /** @domName Int8Array.subarray_1 */
  Int8Array _subarray_1(start, end) native "Int8Array_subarray_1_Callback";


  /** @domName Int8Array.subarray_2 */
  Int8Array _subarray_2(start) native "Int8Array_subarray_2_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName JavaScriptCallFrame
class JavaScriptCallFrame extends NativeFieldWrapperClass1 {
  JavaScriptCallFrame.internal();

  static const int CATCH_SCOPE = 4;

  static const int CLOSURE_SCOPE = 3;

  static const int GLOBAL_SCOPE = 0;

  static const int LOCAL_SCOPE = 1;

  static const int WITH_SCOPE = 2;


  /** @domName JavaScriptCallFrame.caller */
  JavaScriptCallFrame get caller native "JavaScriptCallFrame_caller_Getter";


  /** @domName JavaScriptCallFrame.column */
  int get column native "JavaScriptCallFrame_column_Getter";


  /** @domName JavaScriptCallFrame.functionName */
  String get functionName native "JavaScriptCallFrame_functionName_Getter";


  /** @domName JavaScriptCallFrame.line */
  int get line native "JavaScriptCallFrame_line_Getter";


  /** @domName JavaScriptCallFrame.scopeChain */
  List get scopeChain native "JavaScriptCallFrame_scopeChain_Getter";


  /** @domName JavaScriptCallFrame.sourceID */
  int get sourceID native "JavaScriptCallFrame_sourceID_Getter";


  /** @domName JavaScriptCallFrame.thisObject */
  Object get thisObject native "JavaScriptCallFrame_thisObject_Getter";


  /** @domName JavaScriptCallFrame.type */
  String get type native "JavaScriptCallFrame_type_Getter";


  /** @domName JavaScriptCallFrame.evaluate */
  void evaluate(String script) native "JavaScriptCallFrame_evaluate_Callback";


  /** @domName JavaScriptCallFrame.restart */
  Object restart() native "JavaScriptCallFrame_restart_Callback";


  /** @domName JavaScriptCallFrame.scopeType */
  int scopeType(int scopeIndex) native "JavaScriptCallFrame_scopeType_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName KeyboardEvent
class KeyboardEvent extends UIEvent {
  KeyboardEvent.internal(): super.internal();


  /** @domName KeyboardEvent.altGraphKey */
  bool get altGraphKey native "KeyboardEvent_altGraphKey_Getter";


  /** @domName KeyboardEvent.altKey */
  bool get altKey native "KeyboardEvent_altKey_Getter";


  /** @domName KeyboardEvent.ctrlKey */
  bool get ctrlKey native "KeyboardEvent_ctrlKey_Getter";


  /** @domName KeyboardEvent.keyIdentifier */
  String get keyIdentifier native "KeyboardEvent_keyIdentifier_Getter";


  /** @domName KeyboardEvent.keyLocation */
  int get keyLocation native "KeyboardEvent_keyLocation_Getter";


  /** @domName KeyboardEvent.metaKey */
  bool get metaKey native "KeyboardEvent_metaKey_Getter";


  /** @domName KeyboardEvent.shiftKey */
  bool get shiftKey native "KeyboardEvent_shiftKey_Getter";


  /** @domName KeyboardEvent.initKeyboardEvent */
  void initKeyboardEvent(String type, bool canBubble, bool cancelable, LocalWindow view, String keyIdentifier, int keyLocation, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, bool altGraphKey) native "KeyboardEvent_initKeyboardEvent_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLKeygenElement
class KeygenElement extends _Element_Merged {

  factory KeygenElement() => document.$dom_createElement("keygen");
  KeygenElement.internal(): super.internal();


  /** @domName HTMLKeygenElement.autofocus */
  bool get autofocus native "HTMLKeygenElement_autofocus_Getter";


  /** @domName HTMLKeygenElement.autofocus */
  void set autofocus(bool value) native "HTMLKeygenElement_autofocus_Setter";


  /** @domName HTMLKeygenElement.challenge */
  String get challenge native "HTMLKeygenElement_challenge_Getter";


  /** @domName HTMLKeygenElement.challenge */
  void set challenge(String value) native "HTMLKeygenElement_challenge_Setter";


  /** @domName HTMLKeygenElement.disabled */
  bool get disabled native "HTMLKeygenElement_disabled_Getter";


  /** @domName HTMLKeygenElement.disabled */
  void set disabled(bool value) native "HTMLKeygenElement_disabled_Setter";


  /** @domName HTMLKeygenElement.form */
  FormElement get form native "HTMLKeygenElement_form_Getter";


  /** @domName HTMLKeygenElement.keytype */
  String get keytype native "HTMLKeygenElement_keytype_Getter";


  /** @domName HTMLKeygenElement.keytype */
  void set keytype(String value) native "HTMLKeygenElement_keytype_Setter";


  /** @domName HTMLKeygenElement.labels */
  List<Node> get labels native "HTMLKeygenElement_labels_Getter";


  /** @domName HTMLKeygenElement.name */
  String get name native "HTMLKeygenElement_name_Getter";


  /** @domName HTMLKeygenElement.name */
  void set name(String value) native "HTMLKeygenElement_name_Setter";


  /** @domName HTMLKeygenElement.type */
  String get type native "HTMLKeygenElement_type_Getter";


  /** @domName HTMLKeygenElement.validationMessage */
  String get validationMessage native "HTMLKeygenElement_validationMessage_Getter";


  /** @domName HTMLKeygenElement.validity */
  ValidityState get validity native "HTMLKeygenElement_validity_Getter";


  /** @domName HTMLKeygenElement.willValidate */
  bool get willValidate native "HTMLKeygenElement_willValidate_Getter";


  /** @domName HTMLKeygenElement.checkValidity */
  bool checkValidity() native "HTMLKeygenElement_checkValidity_Callback";


  /** @domName HTMLKeygenElement.setCustomValidity */
  void setCustomValidity(String error) native "HTMLKeygenElement_setCustomValidity_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLLIElement
class LIElement extends _Element_Merged {

  factory LIElement() => document.$dom_createElement("li");
  LIElement.internal(): super.internal();


  /** @domName HTMLLIElement.type */
  String get type native "HTMLLIElement_type_Getter";


  /** @domName HTMLLIElement.type */
  void set type(String value) native "HTMLLIElement_type_Setter";


  /** @domName HTMLLIElement.value */
  int get value native "HTMLLIElement_value_Getter";


  /** @domName HTMLLIElement.value */
  void set value(int value) native "HTMLLIElement_value_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLLabelElement
class LabelElement extends _Element_Merged {

  factory LabelElement() => document.$dom_createElement("label");
  LabelElement.internal(): super.internal();


  /** @domName HTMLLabelElement.control */
  Element get control native "HTMLLabelElement_control_Getter";


  /** @domName HTMLLabelElement.form */
  FormElement get form native "HTMLLabelElement_form_Getter";


  /** @domName HTMLLabelElement.htmlFor */
  String get htmlFor native "HTMLLabelElement_htmlFor_Getter";


  /** @domName HTMLLabelElement.htmlFor */
  void set htmlFor(String value) native "HTMLLabelElement_htmlFor_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLLegendElement
class LegendElement extends _Element_Merged {

  factory LegendElement() => document.$dom_createElement("legend");
  LegendElement.internal(): super.internal();


  /** @domName HTMLLegendElement.align */
  String get align native "HTMLLegendElement_align_Getter";


  /** @domName HTMLLegendElement.align */
  void set align(String value) native "HTMLLegendElement_align_Setter";


  /** @domName HTMLLegendElement.form */
  FormElement get form native "HTMLLegendElement_form_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLLinkElement
class LinkElement extends _Element_Merged {

  factory LinkElement() => document.$dom_createElement("link");
  LinkElement.internal(): super.internal();


  /** @domName HTMLLinkElement.charset */
  String get charset native "HTMLLinkElement_charset_Getter";


  /** @domName HTMLLinkElement.charset */
  void set charset(String value) native "HTMLLinkElement_charset_Setter";


  /** @domName HTMLLinkElement.disabled */
  bool get disabled native "HTMLLinkElement_disabled_Getter";


  /** @domName HTMLLinkElement.disabled */
  void set disabled(bool value) native "HTMLLinkElement_disabled_Setter";


  /** @domName HTMLLinkElement.href */
  String get href native "HTMLLinkElement_href_Getter";


  /** @domName HTMLLinkElement.href */
  void set href(String value) native "HTMLLinkElement_href_Setter";


  /** @domName HTMLLinkElement.hreflang */
  String get hreflang native "HTMLLinkElement_hreflang_Getter";


  /** @domName HTMLLinkElement.hreflang */
  void set hreflang(String value) native "HTMLLinkElement_hreflang_Setter";


  /** @domName HTMLLinkElement.media */
  String get media native "HTMLLinkElement_media_Getter";


  /** @domName HTMLLinkElement.media */
  void set media(String value) native "HTMLLinkElement_media_Setter";


  /** @domName HTMLLinkElement.rel */
  String get rel native "HTMLLinkElement_rel_Getter";


  /** @domName HTMLLinkElement.rel */
  void set rel(String value) native "HTMLLinkElement_rel_Setter";


  /** @domName HTMLLinkElement.rev */
  String get rev native "HTMLLinkElement_rev_Getter";


  /** @domName HTMLLinkElement.rev */
  void set rev(String value) native "HTMLLinkElement_rev_Setter";


  /** @domName HTMLLinkElement.sheet */
  StyleSheet get sheet native "HTMLLinkElement_sheet_Getter";


  /** @domName HTMLLinkElement.sizes */
  DOMSettableTokenList get sizes native "HTMLLinkElement_sizes_Getter";


  /** @domName HTMLLinkElement.sizes */
  void set sizes(DOMSettableTokenList value) native "HTMLLinkElement_sizes_Setter";


  /** @domName HTMLLinkElement.target */
  String get target native "HTMLLinkElement_target_Getter";


  /** @domName HTMLLinkElement.target */
  void set target(String value) native "HTMLLinkElement_target_Setter";


  /** @domName HTMLLinkElement.type */
  String get type native "HTMLLinkElement_type_Getter";


  /** @domName HTMLLinkElement.type */
  void set type(String value) native "HTMLLinkElement_type_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName History
class LocalHistory extends NativeFieldWrapperClass1 implements History {
  LocalHistory.internal();


  /** @domName History.length */
  int get length native "History_length_Getter";


  /** @domName History.state */
  dynamic get state native "History_state_Getter";


  /** @domName History.back */
  void back() native "History_back_Callback";


  /** @domName History.forward */
  void forward() native "History_forward_Callback";


  /** @domName History.go */
  void go(int distance) native "History_go_Callback";


  /** @domName History.pushState */
  void pushState(Object data, String title, [String url]) native "History_pushState_Callback";


  /** @domName History.replaceState */
  void replaceState(Object data, String title, [String url]) native "History_replaceState_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Location
class LocalLocation extends NativeFieldWrapperClass1 implements Location {
  LocalLocation.internal();


  /** @domName Location.ancestorOrigins */
  List<String> get ancestorOrigins native "Location_ancestorOrigins_Getter";


  /** @domName Location.hash */
  String get hash native "Location_hash_Getter";


  /** @domName Location.hash */
  void set hash(String value) native "Location_hash_Setter";


  /** @domName Location.host */
  String get host native "Location_host_Getter";


  /** @domName Location.host */
  void set host(String value) native "Location_host_Setter";


  /** @domName Location.hostname */
  String get hostname native "Location_hostname_Getter";


  /** @domName Location.hostname */
  void set hostname(String value) native "Location_hostname_Setter";


  /** @domName Location.href */
  String get href native "Location_href_Getter";


  /** @domName Location.href */
  void set href(String value) native "Location_href_Setter";


  /** @domName Location.origin */
  String get origin native "Location_origin_Getter";


  /** @domName Location.pathname */
  String get pathname native "Location_pathname_Getter";


  /** @domName Location.pathname */
  void set pathname(String value) native "Location_pathname_Setter";


  /** @domName Location.port */
  String get port native "Location_port_Getter";


  /** @domName Location.port */
  void set port(String value) native "Location_port_Setter";


  /** @domName Location.protocol */
  String get protocol native "Location_protocol_Getter";


  /** @domName Location.protocol */
  void set protocol(String value) native "Location_protocol_Setter";


  /** @domName Location.search */
  String get search native "Location_search_Getter";


  /** @domName Location.search */
  void set search(String value) native "Location_search_Setter";


  /** @domName Location.assign */
  void assign(String url) native "Location_assign_Callback";


  /** @domName Location.reload */
  void reload() native "Location_reload_Callback";


  /** @domName Location.replace */
  void replace(String url) native "Location_replace_Callback";


  /** @domName Location.toString */
  String toString() native "Location_toString_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName LocalMediaStream
class LocalMediaStream extends MediaStream implements EventTarget {
  LocalMediaStream.internal(): super.internal();


  /** @domName LocalMediaStream.stop */
  void stop() native "LocalMediaStream_stop_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class LocalWindow extends EventTarget implements Window {

  /**
   * Executes a [callback] after the next batch of browser layout measurements
   * has completed or would have completed if any browser layout measurements
   * had been scheduled.
   */
  void requestLayoutFrame(TimeoutHandler callback) {
    _addMeasurementFrameCallback(callback);
  }

  /**
   * Lookup a port by its [name].  Return null if no port is
   * registered under [name].
   */
  lookupPort(String name) {
    var port = JSON.parse(document.documentElement.attributes['dart-port:$name']);
    return _deserialize(port);
  }

  /**
   * Register a [port] on this window under the given [name].  This
   * port may be retrieved by any isolate (or JavaScript script)
   * running in this window.
   */
  registerPort(String name, var port) {
    var serialized = _serialize(port);
    document.documentElement.attributes['dart-port:$name'] = JSON.stringify(serialized);
  }

  LocalWindow.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  LocalWindowEvents get on =>
    new LocalWindowEvents(this);

  static const int PERSISTENT = 1;

  static const int TEMPORARY = 0;


  /** @domName DOMWindow.applicationCache */
  DOMApplicationCache get applicationCache native "DOMWindow_applicationCache_Getter";


  /** @domName DOMWindow.closed */
  bool get closed native "DOMWindow_closed_Getter";


  /** @domName DOMWindow.console */
  Console get console native "DOMWindow_console_Getter";


  /** @domName DOMWindow.crypto */
  Crypto get crypto native "DOMWindow_crypto_Getter";


  /** @domName DOMWindow.defaultStatus */
  String get defaultStatus native "DOMWindow_defaultStatus_Getter";


  /** @domName DOMWindow.defaultStatus */
  void set defaultStatus(String value) native "DOMWindow_defaultStatus_Setter";


  /** @domName DOMWindow.defaultstatus */
  String get defaultstatus native "DOMWindow_defaultstatus_Getter";


  /** @domName DOMWindow.defaultstatus */
  void set defaultstatus(String value) native "DOMWindow_defaultstatus_Setter";


  /** @domName DOMWindow.devicePixelRatio */
  num get devicePixelRatio native "DOMWindow_devicePixelRatio_Getter";


  /** @domName DOMWindow.document */
  Document get document native "DOMWindow_document_Getter";


  /** @domName DOMWindow.event */
  Event get event native "DOMWindow_event_Getter";


  /** @domName DOMWindow.history */
  LocalHistory get history native "DOMWindow_history_Getter";


  /** @domName DOMWindow.indexedDB */
  IDBFactory get indexedDB native "DOMWindow_indexedDB_Getter";


  /** @domName DOMWindow.innerHeight */
  int get innerHeight native "DOMWindow_innerHeight_Getter";


  /** @domName DOMWindow.innerWidth */
  int get innerWidth native "DOMWindow_innerWidth_Getter";


  /** @domName DOMWindow.localStorage */
  Storage get localStorage native "DOMWindow_localStorage_Getter";


  /** @domName DOMWindow.location */
  LocalLocation get location native "DOMWindow_location_Getter";


  /** @domName DOMWindow.location */
  void set location(LocalLocation value) native "DOMWindow_location_Setter";


  /** @domName DOMWindow.locationbar */
  BarInfo get locationbar native "DOMWindow_locationbar_Getter";


  /** @domName DOMWindow.menubar */
  BarInfo get menubar native "DOMWindow_menubar_Getter";


  /** @domName DOMWindow.name */
  String get name native "DOMWindow_name_Getter";


  /** @domName DOMWindow.name */
  void set name(String value) native "DOMWindow_name_Setter";


  /** @domName DOMWindow.navigator */
  Navigator get navigator native "DOMWindow_navigator_Getter";


  /** @domName DOMWindow.offscreenBuffering */
  bool get offscreenBuffering native "DOMWindow_offscreenBuffering_Getter";


  /** @domName DOMWindow.opener */
  Window get opener native "DOMWindow_opener_Getter";


  /** @domName DOMWindow.outerHeight */
  int get outerHeight native "DOMWindow_outerHeight_Getter";


  /** @domName DOMWindow.outerWidth */
  int get outerWidth native "DOMWindow_outerWidth_Getter";


  /** @domName DOMWindow.pagePopupController */
  PagePopupController get pagePopupController native "DOMWindow_pagePopupController_Getter";


  /** @domName DOMWindow.pageXOffset */
  int get pageXOffset native "DOMWindow_pageXOffset_Getter";


  /** @domName DOMWindow.pageYOffset */
  int get pageYOffset native "DOMWindow_pageYOffset_Getter";


  /** @domName DOMWindow.parent */
  Window get parent native "DOMWindow_parent_Getter";


  /** @domName DOMWindow.performance */
  Performance get performance native "DOMWindow_performance_Getter";


  /** @domName DOMWindow.personalbar */
  BarInfo get personalbar native "DOMWindow_personalbar_Getter";


  /** @domName DOMWindow.screen */
  Screen get screen native "DOMWindow_screen_Getter";


  /** @domName DOMWindow.screenLeft */
  int get screenLeft native "DOMWindow_screenLeft_Getter";


  /** @domName DOMWindow.screenTop */
  int get screenTop native "DOMWindow_screenTop_Getter";


  /** @domName DOMWindow.screenX */
  int get screenX native "DOMWindow_screenX_Getter";


  /** @domName DOMWindow.screenY */
  int get screenY native "DOMWindow_screenY_Getter";


  /** @domName DOMWindow.scrollX */
  int get scrollX native "DOMWindow_scrollX_Getter";


  /** @domName DOMWindow.scrollY */
  int get scrollY native "DOMWindow_scrollY_Getter";


  /** @domName DOMWindow.scrollbars */
  BarInfo get scrollbars native "DOMWindow_scrollbars_Getter";


  /** @domName DOMWindow.self */
  Window get self native "DOMWindow_self_Getter";


  /** @domName DOMWindow.sessionStorage */
  Storage get sessionStorage native "DOMWindow_sessionStorage_Getter";


  /** @domName DOMWindow.status */
  String get status native "DOMWindow_status_Getter";


  /** @domName DOMWindow.status */
  void set status(String value) native "DOMWindow_status_Setter";


  /** @domName DOMWindow.statusbar */
  BarInfo get statusbar native "DOMWindow_statusbar_Getter";


  /** @domName DOMWindow.styleMedia */
  StyleMedia get styleMedia native "DOMWindow_styleMedia_Getter";


  /** @domName DOMWindow.toolbar */
  BarInfo get toolbar native "DOMWindow_toolbar_Getter";


  /** @domName DOMWindow.top */
  Window get top native "DOMWindow_top_Getter";


  /** @domName DOMWindow.webkitIndexedDB */
  IDBFactory get webkitIndexedDB native "DOMWindow_webkitIndexedDB_Getter";


  /** @domName DOMWindow.webkitNotifications */
  NotificationCenter get webkitNotifications native "DOMWindow_webkitNotifications_Getter";


  /** @domName DOMWindow.webkitStorageInfo */
  StorageInfo get webkitStorageInfo native "DOMWindow_webkitStorageInfo_Getter";


  /** @domName DOMWindow.window */
  Window get window native "DOMWindow_window_Getter";


  /** @domName DOMWindow.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "DOMWindow_addEventListener_Callback";


  /** @domName DOMWindow.alert */
  void alert(String message) native "DOMWindow_alert_Callback";


  /** @domName DOMWindow.atob */
  String atob(String string) native "DOMWindow_atob_Callback";


  /** @domName DOMWindow.btoa */
  String btoa(String string) native "DOMWindow_btoa_Callback";


  /** @domName DOMWindow.cancelAnimationFrame */
  void cancelAnimationFrame(int id) native "DOMWindow_cancelAnimationFrame_Callback";


  /** @domName DOMWindow.captureEvents */
  void captureEvents() native "DOMWindow_captureEvents_Callback";


  /** @domName DOMWindow.clearInterval */
  void clearInterval(int handle) native "DOMWindow_clearInterval_Callback";


  /** @domName DOMWindow.clearTimeout */
  void clearTimeout(int handle) native "DOMWindow_clearTimeout_Callback";


  /** @domName DOMWindow.close */
  void close() native "DOMWindow_close_Callback";


  /** @domName DOMWindow.confirm */
  bool confirm(String message) native "DOMWindow_confirm_Callback";


  /** @domName DOMWindow.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "DOMWindow_dispatchEvent_Callback";


  /** @domName DOMWindow.find */
  bool find(String string, bool caseSensitive, bool backwards, bool wrap, bool wholeWord, bool searchInFrames, bool showDialog) native "DOMWindow_find_Callback";


  /** @domName DOMWindow.getComputedStyle */
  CSSStyleDeclaration $dom_getComputedStyle(Element element, String pseudoElement) native "DOMWindow_getComputedStyle_Callback";


  /** @domName DOMWindow.getMatchedCSSRules */
  List<CSSRule> getMatchedCSSRules(Element element, String pseudoElement) native "DOMWindow_getMatchedCSSRules_Callback";


  /** @domName DOMWindow.getSelection */
  DOMSelection getSelection() native "DOMWindow_getSelection_Callback";


  /** @domName DOMWindow.matchMedia */
  MediaQueryList matchMedia(String query) native "DOMWindow_matchMedia_Callback";


  /** @domName DOMWindow.moveBy */
  void moveBy(num x, num y) native "DOMWindow_moveBy_Callback";


  /** @domName DOMWindow.moveTo */
  void moveTo(num x, num y) native "DOMWindow_moveTo_Callback";


  /** @domName DOMWindow.open */
  Window open(String url, String name, [String options]) native "DOMWindow_open_Callback";


  /** @domName DOMWindow.openDatabase */
  Database openDatabase(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback]) native "DOMWindow_openDatabase_Callback";


  /** @domName DOMWindow.postMessage */
  void postMessage(/*SerializedScriptValue*/ message, String targetOrigin, [List messagePorts]) native "DOMWindow_postMessage_Callback";


  /** @domName DOMWindow.print */
  void print() native "DOMWindow_print_Callback";


  /** @domName DOMWindow.releaseEvents */
  void releaseEvents() native "DOMWindow_releaseEvents_Callback";


  /** @domName DOMWindow.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "DOMWindow_removeEventListener_Callback";


  /** @domName DOMWindow.requestAnimationFrame */
  int requestAnimationFrame(RequestAnimationFrameCallback callback) native "DOMWindow_requestAnimationFrame_Callback";


  /** @domName DOMWindow.resizeBy */
  void resizeBy(num x, num y) native "DOMWindow_resizeBy_Callback";


  /** @domName DOMWindow.resizeTo */
  void resizeTo(num width, num height) native "DOMWindow_resizeTo_Callback";


  /** @domName DOMWindow.scroll */
  void scroll(int x, int y) native "DOMWindow_scroll_Callback";


  /** @domName DOMWindow.scrollBy */
  void scrollBy(int x, int y) native "DOMWindow_scrollBy_Callback";


  /** @domName DOMWindow.scrollTo */
  void scrollTo(int x, int y) native "DOMWindow_scrollTo_Callback";


  /** @domName DOMWindow.setInterval */
  int setInterval(TimeoutHandler handler, int timeout) native "DOMWindow_setInterval_Callback";


  /** @domName DOMWindow.setTimeout */
  int setTimeout(TimeoutHandler handler, int timeout) native "DOMWindow_setTimeout_Callback";


  /** @domName DOMWindow.showModalDialog */
  Object showModalDialog(String url, [Object dialogArgs, String featureArgs]) native "DOMWindow_showModalDialog_Callback";


  /** @domName DOMWindow.stop */
  void stop() native "DOMWindow_stop_Callback";


  /** @domName DOMWindow.webkitCancelAnimationFrame */
  void webkitCancelAnimationFrame(int id) native "DOMWindow_webkitCancelAnimationFrame_Callback";


  /** @domName DOMWindow.webkitConvertPointFromNodeToPage */
  Point webkitConvertPointFromNodeToPage(Node node, Point p) native "DOMWindow_webkitConvertPointFromNodeToPage_Callback";


  /** @domName DOMWindow.webkitConvertPointFromPageToNode */
  Point webkitConvertPointFromPageToNode(Node node, Point p) native "DOMWindow_webkitConvertPointFromPageToNode_Callback";


  /** @domName DOMWindow.webkitRequestAnimationFrame */
  int webkitRequestAnimationFrame(RequestAnimationFrameCallback callback) native "DOMWindow_webkitRequestAnimationFrame_Callback";


  /** @domName DOMWindow.webkitRequestFileSystem */
  void webkitRequestFileSystem(int type, int size, FileSystemCallback successCallback, [ErrorCallback errorCallback]) native "DOMWindow_webkitRequestFileSystem_Callback";


  /** @domName DOMWindow.webkitResolveLocalFileSystemURL */
  void webkitResolveLocalFileSystemURL(String url, EntryCallback successCallback, [ErrorCallback errorCallback]) native "DOMWindow_webkitResolveLocalFileSystemURL_Callback";

}

class LocalWindowEvents extends Events {
  LocalWindowEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get abort => this['abort'];

  EventListenerList get beforeUnload => this['beforeunload'];

  EventListenerList get blur => this['blur'];

  EventListenerList get canPlay => this['canplay'];

  EventListenerList get canPlayThrough => this['canplaythrough'];

  EventListenerList get change => this['change'];

  EventListenerList get click => this['click'];

  EventListenerList get contextMenu => this['contextmenu'];

  EventListenerList get doubleClick => this['dblclick'];

  EventListenerList get deviceMotion => this['devicemotion'];

  EventListenerList get deviceOrientation => this['deviceorientation'];

  EventListenerList get drag => this['drag'];

  EventListenerList get dragEnd => this['dragend'];

  EventListenerList get dragEnter => this['dragenter'];

  EventListenerList get dragLeave => this['dragleave'];

  EventListenerList get dragOver => this['dragover'];

  EventListenerList get dragStart => this['dragstart'];

  EventListenerList get drop => this['drop'];

  EventListenerList get durationChange => this['durationchange'];

  EventListenerList get emptied => this['emptied'];

  EventListenerList get ended => this['ended'];

  EventListenerList get error => this['error'];

  EventListenerList get focus => this['focus'];

  EventListenerList get hashChange => this['hashchange'];

  EventListenerList get input => this['input'];

  EventListenerList get invalid => this['invalid'];

  EventListenerList get keyDown => this['keydown'];

  EventListenerList get keyPress => this['keypress'];

  EventListenerList get keyUp => this['keyup'];

  EventListenerList get load => this['load'];

  EventListenerList get loadedData => this['loadeddata'];

  EventListenerList get loadedMetadata => this['loadedmetadata'];

  EventListenerList get loadStart => this['loadstart'];

  EventListenerList get message => this['message'];

  EventListenerList get mouseDown => this['mousedown'];

  EventListenerList get mouseMove => this['mousemove'];

  EventListenerList get mouseOut => this['mouseout'];

  EventListenerList get mouseOver => this['mouseover'];

  EventListenerList get mouseUp => this['mouseup'];

  EventListenerList get mouseWheel => this['mousewheel'];

  EventListenerList get offline => this['offline'];

  EventListenerList get online => this['online'];

  EventListenerList get pageHide => this['pagehide'];

  EventListenerList get pageShow => this['pageshow'];

  EventListenerList get pause => this['pause'];

  EventListenerList get play => this['play'];

  EventListenerList get playing => this['playing'];

  EventListenerList get popState => this['popstate'];

  EventListenerList get progress => this['progress'];

  EventListenerList get rateChange => this['ratechange'];

  EventListenerList get reset => this['reset'];

  EventListenerList get resize => this['resize'];

  EventListenerList get scroll => this['scroll'];

  EventListenerList get search => this['search'];

  EventListenerList get seeked => this['seeked'];

  EventListenerList get seeking => this['seeking'];

  EventListenerList get select => this['select'];

  EventListenerList get stalled => this['stalled'];

  EventListenerList get storage => this['storage'];

  EventListenerList get submit => this['submit'];

  EventListenerList get suspend => this['suspend'];

  EventListenerList get timeUpdate => this['timeupdate'];

  EventListenerList get touchCancel => this['touchcancel'];

  EventListenerList get touchEnd => this['touchend'];

  EventListenerList get touchMove => this['touchmove'];

  EventListenerList get touchStart => this['touchstart'];

  EventListenerList get unload => this['unload'];

  EventListenerList get volumeChange => this['volumechange'];

  EventListenerList get waiting => this['waiting'];

  EventListenerList get animationEnd => this['webkitAnimationEnd'];

  EventListenerList get animationIteration => this['webkitAnimationIteration'];

  EventListenerList get animationStart => this['webkitAnimationStart'];

  EventListenerList get transitionEnd => this['webkitTransitionEnd'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLMapElement
class MapElement extends _Element_Merged {

  factory MapElement() => document.$dom_createElement("map");
  MapElement.internal(): super.internal();


  /** @domName HTMLMapElement.areas */
  HTMLCollection get areas native "HTMLMapElement_areas_Getter";


  /** @domName HTMLMapElement.name */
  String get name native "HTMLMapElement_name_Getter";


  /** @domName HTMLMapElement.name */
  void set name(String value) native "HTMLMapElement_name_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLMarqueeElement
class MarqueeElement extends _Element_Merged {
  MarqueeElement.internal(): super.internal();


  /** @domName HTMLMarqueeElement.behavior */
  String get behavior native "HTMLMarqueeElement_behavior_Getter";


  /** @domName HTMLMarqueeElement.behavior */
  void set behavior(String value) native "HTMLMarqueeElement_behavior_Setter";


  /** @domName HTMLMarqueeElement.bgColor */
  String get bgColor native "HTMLMarqueeElement_bgColor_Getter";


  /** @domName HTMLMarqueeElement.bgColor */
  void set bgColor(String value) native "HTMLMarqueeElement_bgColor_Setter";


  /** @domName HTMLMarqueeElement.direction */
  String get direction native "HTMLMarqueeElement_direction_Getter";


  /** @domName HTMLMarqueeElement.direction */
  void set direction(String value) native "HTMLMarqueeElement_direction_Setter";


  /** @domName HTMLMarqueeElement.height */
  String get height native "HTMLMarqueeElement_height_Getter";


  /** @domName HTMLMarqueeElement.height */
  void set height(String value) native "HTMLMarqueeElement_height_Setter";


  /** @domName HTMLMarqueeElement.hspace */
  int get hspace native "HTMLMarqueeElement_hspace_Getter";


  /** @domName HTMLMarqueeElement.hspace */
  void set hspace(int value) native "HTMLMarqueeElement_hspace_Setter";


  /** @domName HTMLMarqueeElement.loop */
  int get loop native "HTMLMarqueeElement_loop_Getter";


  /** @domName HTMLMarqueeElement.loop */
  void set loop(int value) native "HTMLMarqueeElement_loop_Setter";


  /** @domName HTMLMarqueeElement.scrollAmount */
  int get scrollAmount native "HTMLMarqueeElement_scrollAmount_Getter";


  /** @domName HTMLMarqueeElement.scrollAmount */
  void set scrollAmount(int value) native "HTMLMarqueeElement_scrollAmount_Setter";


  /** @domName HTMLMarqueeElement.scrollDelay */
  int get scrollDelay native "HTMLMarqueeElement_scrollDelay_Getter";


  /** @domName HTMLMarqueeElement.scrollDelay */
  void set scrollDelay(int value) native "HTMLMarqueeElement_scrollDelay_Setter";


  /** @domName HTMLMarqueeElement.trueSpeed */
  bool get trueSpeed native "HTMLMarqueeElement_trueSpeed_Getter";


  /** @domName HTMLMarqueeElement.trueSpeed */
  void set trueSpeed(bool value) native "HTMLMarqueeElement_trueSpeed_Setter";


  /** @domName HTMLMarqueeElement.vspace */
  int get vspace native "HTMLMarqueeElement_vspace_Getter";


  /** @domName HTMLMarqueeElement.vspace */
  void set vspace(int value) native "HTMLMarqueeElement_vspace_Setter";


  /** @domName HTMLMarqueeElement.width */
  String get width native "HTMLMarqueeElement_width_Getter";


  /** @domName HTMLMarqueeElement.width */
  void set width(String value) native "HTMLMarqueeElement_width_Setter";


  /** @domName HTMLMarqueeElement.start */
  void start() native "HTMLMarqueeElement_start_Callback";


  /** @domName HTMLMarqueeElement.stop */
  void stop() native "HTMLMarqueeElement_stop_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName MediaController
class MediaController extends EventTarget {

  factory MediaController() => _MediaControllerFactoryProvider.createMediaController();
  MediaController.internal(): super.internal();


  /** @domName MediaController.buffered */
  TimeRanges get buffered native "MediaController_buffered_Getter";


  /** @domName MediaController.currentTime */
  num get currentTime native "MediaController_currentTime_Getter";


  /** @domName MediaController.currentTime */
  void set currentTime(num value) native "MediaController_currentTime_Setter";


  /** @domName MediaController.defaultPlaybackRate */
  num get defaultPlaybackRate native "MediaController_defaultPlaybackRate_Getter";


  /** @domName MediaController.defaultPlaybackRate */
  void set defaultPlaybackRate(num value) native "MediaController_defaultPlaybackRate_Setter";


  /** @domName MediaController.duration */
  num get duration native "MediaController_duration_Getter";


  /** @domName MediaController.muted */
  bool get muted native "MediaController_muted_Getter";


  /** @domName MediaController.muted */
  void set muted(bool value) native "MediaController_muted_Setter";


  /** @domName MediaController.paused */
  bool get paused native "MediaController_paused_Getter";


  /** @domName MediaController.playbackRate */
  num get playbackRate native "MediaController_playbackRate_Getter";


  /** @domName MediaController.playbackRate */
  void set playbackRate(num value) native "MediaController_playbackRate_Setter";


  /** @domName MediaController.played */
  TimeRanges get played native "MediaController_played_Getter";


  /** @domName MediaController.seekable */
  TimeRanges get seekable native "MediaController_seekable_Getter";


  /** @domName MediaController.volume */
  num get volume native "MediaController_volume_Getter";


  /** @domName MediaController.volume */
  void set volume(num value) native "MediaController_volume_Setter";


  /** @domName MediaController.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "MediaController_addEventListener_Callback";


  /** @domName MediaController.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "MediaController_dispatchEvent_Callback";


  /** @domName MediaController.pause */
  void pause() native "MediaController_pause_Callback";


  /** @domName MediaController.play */
  void play() native "MediaController_play_Callback";


  /** @domName MediaController.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "MediaController_removeEventListener_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLMediaElement
class MediaElement extends _Element_Merged {
  MediaElement.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  MediaElementEvents get on =>
    new MediaElementEvents(this);

  static const int HAVE_CURRENT_DATA = 2;

  static const int HAVE_ENOUGH_DATA = 4;

  static const int HAVE_FUTURE_DATA = 3;

  static const int HAVE_METADATA = 1;

  static const int HAVE_NOTHING = 0;

  static const int NETWORK_EMPTY = 0;

  static const int NETWORK_IDLE = 1;

  static const int NETWORK_LOADING = 2;

  static const int NETWORK_NO_SOURCE = 3;


  /** @domName HTMLMediaElement.autoplay */
  bool get autoplay native "HTMLMediaElement_autoplay_Getter";


  /** @domName HTMLMediaElement.autoplay */
  void set autoplay(bool value) native "HTMLMediaElement_autoplay_Setter";


  /** @domName HTMLMediaElement.buffered */
  TimeRanges get buffered native "HTMLMediaElement_buffered_Getter";


  /** @domName HTMLMediaElement.controller */
  MediaController get controller native "HTMLMediaElement_controller_Getter";


  /** @domName HTMLMediaElement.controller */
  void set controller(MediaController value) native "HTMLMediaElement_controller_Setter";


  /** @domName HTMLMediaElement.controls */
  bool get controls native "HTMLMediaElement_controls_Getter";


  /** @domName HTMLMediaElement.controls */
  void set controls(bool value) native "HTMLMediaElement_controls_Setter";


  /** @domName HTMLMediaElement.currentSrc */
  String get currentSrc native "HTMLMediaElement_currentSrc_Getter";


  /** @domName HTMLMediaElement.currentTime */
  num get currentTime native "HTMLMediaElement_currentTime_Getter";


  /** @domName HTMLMediaElement.currentTime */
  void set currentTime(num value) native "HTMLMediaElement_currentTime_Setter";


  /** @domName HTMLMediaElement.defaultMuted */
  bool get defaultMuted native "HTMLMediaElement_defaultMuted_Getter";


  /** @domName HTMLMediaElement.defaultMuted */
  void set defaultMuted(bool value) native "HTMLMediaElement_defaultMuted_Setter";


  /** @domName HTMLMediaElement.defaultPlaybackRate */
  num get defaultPlaybackRate native "HTMLMediaElement_defaultPlaybackRate_Getter";


  /** @domName HTMLMediaElement.defaultPlaybackRate */
  void set defaultPlaybackRate(num value) native "HTMLMediaElement_defaultPlaybackRate_Setter";


  /** @domName HTMLMediaElement.duration */
  num get duration native "HTMLMediaElement_duration_Getter";


  /** @domName HTMLMediaElement.ended */
  bool get ended native "HTMLMediaElement_ended_Getter";


  /** @domName HTMLMediaElement.error */
  MediaError get error native "HTMLMediaElement_error_Getter";


  /** @domName HTMLMediaElement.initialTime */
  num get initialTime native "HTMLMediaElement_initialTime_Getter";


  /** @domName HTMLMediaElement.loop */
  bool get loop native "HTMLMediaElement_loop_Getter";


  /** @domName HTMLMediaElement.loop */
  void set loop(bool value) native "HTMLMediaElement_loop_Setter";


  /** @domName HTMLMediaElement.mediaGroup */
  String get mediaGroup native "HTMLMediaElement_mediaGroup_Getter";


  /** @domName HTMLMediaElement.mediaGroup */
  void set mediaGroup(String value) native "HTMLMediaElement_mediaGroup_Setter";


  /** @domName HTMLMediaElement.muted */
  bool get muted native "HTMLMediaElement_muted_Getter";


  /** @domName HTMLMediaElement.muted */
  void set muted(bool value) native "HTMLMediaElement_muted_Setter";


  /** @domName HTMLMediaElement.networkState */
  int get networkState native "HTMLMediaElement_networkState_Getter";


  /** @domName HTMLMediaElement.paused */
  bool get paused native "HTMLMediaElement_paused_Getter";


  /** @domName HTMLMediaElement.playbackRate */
  num get playbackRate native "HTMLMediaElement_playbackRate_Getter";


  /** @domName HTMLMediaElement.playbackRate */
  void set playbackRate(num value) native "HTMLMediaElement_playbackRate_Setter";


  /** @domName HTMLMediaElement.played */
  TimeRanges get played native "HTMLMediaElement_played_Getter";


  /** @domName HTMLMediaElement.preload */
  String get preload native "HTMLMediaElement_preload_Getter";


  /** @domName HTMLMediaElement.preload */
  void set preload(String value) native "HTMLMediaElement_preload_Setter";


  /** @domName HTMLMediaElement.readyState */
  int get readyState native "HTMLMediaElement_readyState_Getter";


  /** @domName HTMLMediaElement.seekable */
  TimeRanges get seekable native "HTMLMediaElement_seekable_Getter";


  /** @domName HTMLMediaElement.seeking */
  bool get seeking native "HTMLMediaElement_seeking_Getter";


  /** @domName HTMLMediaElement.src */
  String get src native "HTMLMediaElement_src_Getter";


  /** @domName HTMLMediaElement.src */
  void set src(String value) native "HTMLMediaElement_src_Setter";


  /** @domName HTMLMediaElement.startTime */
  num get startTime native "HTMLMediaElement_startTime_Getter";


  /** @domName HTMLMediaElement.textTracks */
  TextTrackList get textTracks native "HTMLMediaElement_textTracks_Getter";


  /** @domName HTMLMediaElement.volume */
  num get volume native "HTMLMediaElement_volume_Getter";


  /** @domName HTMLMediaElement.volume */
  void set volume(num value) native "HTMLMediaElement_volume_Setter";


  /** @domName HTMLMediaElement.webkitAudioDecodedByteCount */
  int get webkitAudioDecodedByteCount native "HTMLMediaElement_webkitAudioDecodedByteCount_Getter";


  /** @domName HTMLMediaElement.webkitClosedCaptionsVisible */
  bool get webkitClosedCaptionsVisible native "HTMLMediaElement_webkitClosedCaptionsVisible_Getter";


  /** @domName HTMLMediaElement.webkitClosedCaptionsVisible */
  void set webkitClosedCaptionsVisible(bool value) native "HTMLMediaElement_webkitClosedCaptionsVisible_Setter";


  /** @domName HTMLMediaElement.webkitHasClosedCaptions */
  bool get webkitHasClosedCaptions native "HTMLMediaElement_webkitHasClosedCaptions_Getter";


  /** @domName HTMLMediaElement.webkitPreservesPitch */
  bool get webkitPreservesPitch native "HTMLMediaElement_webkitPreservesPitch_Getter";


  /** @domName HTMLMediaElement.webkitPreservesPitch */
  void set webkitPreservesPitch(bool value) native "HTMLMediaElement_webkitPreservesPitch_Setter";


  /** @domName HTMLMediaElement.webkitVideoDecodedByteCount */
  int get webkitVideoDecodedByteCount native "HTMLMediaElement_webkitVideoDecodedByteCount_Getter";

  TextTrack addTextTrack(/*DOMString*/ kind, [/*DOMString*/ label, /*DOMString*/ language]) {
    if (?language) {
      return _addTextTrack_1(kind, label, language);
    }
    if (?label) {
      return _addTextTrack_2(kind, label);
    }
    return _addTextTrack_3(kind);
  }


  /** @domName HTMLMediaElement.addTextTrack_1 */
  TextTrack _addTextTrack_1(kind, label, language) native "HTMLMediaElement_addTextTrack_1_Callback";


  /** @domName HTMLMediaElement.addTextTrack_2 */
  TextTrack _addTextTrack_2(kind, label) native "HTMLMediaElement_addTextTrack_2_Callback";


  /** @domName HTMLMediaElement.addTextTrack_3 */
  TextTrack _addTextTrack_3(kind) native "HTMLMediaElement_addTextTrack_3_Callback";


  /** @domName HTMLMediaElement.canPlayType */
  String canPlayType(String type, String keySystem) native "HTMLMediaElement_canPlayType_Callback";


  /** @domName HTMLMediaElement.load */
  void load() native "HTMLMediaElement_load_Callback";


  /** @domName HTMLMediaElement.pause */
  void pause() native "HTMLMediaElement_pause_Callback";


  /** @domName HTMLMediaElement.play */
  void play() native "HTMLMediaElement_play_Callback";

  void webkitAddKey(/*DOMString*/ keySystem, /*Uint8Array*/ key, [/*Uint8Array*/ initData, /*DOMString*/ sessionId]) {
    if (?initData) {
      _webkitAddKey_1(keySystem, key, initData, sessionId);
      return;
    }
    _webkitAddKey_2(keySystem, key);
  }


  /** @domName HTMLMediaElement.webkitAddKey_1 */
  void _webkitAddKey_1(keySystem, key, initData, sessionId) native "HTMLMediaElement_webkitAddKey_1_Callback";


  /** @domName HTMLMediaElement.webkitAddKey_2 */
  void _webkitAddKey_2(keySystem, key) native "HTMLMediaElement_webkitAddKey_2_Callback";


  /** @domName HTMLMediaElement.webkitCancelKeyRequest */
  void webkitCancelKeyRequest(String keySystem, String sessionId) native "HTMLMediaElement_webkitCancelKeyRequest_Callback";

  void webkitGenerateKeyRequest(/*DOMString*/ keySystem, [/*Uint8Array*/ initData]) {
    if (?initData) {
      _webkitGenerateKeyRequest_1(keySystem, initData);
      return;
    }
    _webkitGenerateKeyRequest_2(keySystem);
  }


  /** @domName HTMLMediaElement.webkitGenerateKeyRequest_1 */
  void _webkitGenerateKeyRequest_1(keySystem, initData) native "HTMLMediaElement_webkitGenerateKeyRequest_1_Callback";


  /** @domName HTMLMediaElement.webkitGenerateKeyRequest_2 */
  void _webkitGenerateKeyRequest_2(keySystem) native "HTMLMediaElement_webkitGenerateKeyRequest_2_Callback";

}

class MediaElementEvents extends ElementEvents {
  MediaElementEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get canPlay => this['canplay'];

  EventListenerList get canPlayThrough => this['canplaythrough'];

  EventListenerList get durationChange => this['durationchange'];

  EventListenerList get emptied => this['emptied'];

  EventListenerList get ended => this['ended'];

  EventListenerList get loadedData => this['loadeddata'];

  EventListenerList get loadedMetadata => this['loadedmetadata'];

  EventListenerList get loadStart => this['loadstart'];

  EventListenerList get pause => this['pause'];

  EventListenerList get play => this['play'];

  EventListenerList get playing => this['playing'];

  EventListenerList get progress => this['progress'];

  EventListenerList get rateChange => this['ratechange'];

  EventListenerList get seeked => this['seeked'];

  EventListenerList get seeking => this['seeking'];

  EventListenerList get show => this['show'];

  EventListenerList get stalled => this['stalled'];

  EventListenerList get suspend => this['suspend'];

  EventListenerList get timeUpdate => this['timeupdate'];

  EventListenerList get volumeChange => this['volumechange'];

  EventListenerList get waiting => this['waiting'];

  EventListenerList get keyAdded => this['webkitkeyadded'];

  EventListenerList get keyError => this['webkitkeyerror'];

  EventListenerList get keyMessage => this['webkitkeymessage'];

  EventListenerList get needKey => this['webkitneedkey'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName MediaElementAudioSourceNode
class MediaElementAudioSourceNode extends AudioSourceNode {
  MediaElementAudioSourceNode.internal(): super.internal();


  /** @domName MediaElementAudioSourceNode.mediaElement */
  MediaElement get mediaElement native "MediaElementAudioSourceNode_mediaElement_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName MediaError
class MediaError extends NativeFieldWrapperClass1 {
  MediaError.internal();

  static const int MEDIA_ERR_ABORTED = 1;

  static const int MEDIA_ERR_DECODE = 3;

  static const int MEDIA_ERR_ENCRYPTED = 5;

  static const int MEDIA_ERR_NETWORK = 2;

  static const int MEDIA_ERR_SRC_NOT_SUPPORTED = 4;


  /** @domName MediaError.code */
  int get code native "MediaError_code_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName MediaKeyError
class MediaKeyError extends NativeFieldWrapperClass1 {
  MediaKeyError.internal();

  static const int MEDIA_KEYERR_CLIENT = 2;

  static const int MEDIA_KEYERR_DOMAIN = 6;

  static const int MEDIA_KEYERR_HARDWARECHANGE = 5;

  static const int MEDIA_KEYERR_OUTPUT = 4;

  static const int MEDIA_KEYERR_SERVICE = 3;

  static const int MEDIA_KEYERR_UNKNOWN = 1;


  /** @domName MediaKeyError.code */
  int get code native "MediaKeyError_code_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName MediaKeyEvent
class MediaKeyEvent extends Event {
  MediaKeyEvent.internal(): super.internal();


  /** @domName MediaKeyEvent.defaultURL */
  String get defaultURL native "MediaKeyEvent_defaultURL_Getter";


  /** @domName MediaKeyEvent.errorCode */
  MediaKeyError get errorCode native "MediaKeyEvent_errorCode_Getter";


  /** @domName MediaKeyEvent.initData */
  Uint8Array get initData native "MediaKeyEvent_initData_Getter";


  /** @domName MediaKeyEvent.keySystem */
  String get keySystem native "MediaKeyEvent_keySystem_Getter";


  /** @domName MediaKeyEvent.message */
  Uint8Array get message native "MediaKeyEvent_message_Getter";


  /** @domName MediaKeyEvent.sessionId */
  String get sessionId native "MediaKeyEvent_sessionId_Getter";


  /** @domName MediaKeyEvent.systemCode */
  int get systemCode native "MediaKeyEvent_systemCode_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName MediaList
class MediaList extends NativeFieldWrapperClass1 {
  MediaList.internal();


  /** @domName MediaList.length */
  int get length native "MediaList_length_Getter";


  /** @domName MediaList.mediaText */
  String get mediaText native "MediaList_mediaText_Getter";


  /** @domName MediaList.mediaText */
  void set mediaText(String value) native "MediaList_mediaText_Setter";


  /** @domName MediaList.appendMedium */
  void appendMedium(String newMedium) native "MediaList_appendMedium_Callback";


  /** @domName MediaList.deleteMedium */
  void deleteMedium(String oldMedium) native "MediaList_deleteMedium_Callback";


  /** @domName MediaList.item */
  String item(int index) native "MediaList_item_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName MediaQueryList
class MediaQueryList extends NativeFieldWrapperClass1 {
  MediaQueryList.internal();


  /** @domName MediaQueryList.matches */
  bool get matches native "MediaQueryList_matches_Getter";


  /** @domName MediaQueryList.media */
  String get media native "MediaQueryList_media_Getter";


  /** @domName MediaQueryList.addListener */
  void addListener(MediaQueryListListener listener) native "MediaQueryList_addListener_Callback";


  /** @domName MediaQueryList.removeListener */
  void removeListener(MediaQueryListListener listener) native "MediaQueryList_removeListener_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName MediaQueryListListener
class MediaQueryListListener extends NativeFieldWrapperClass1 {
  MediaQueryListListener.internal();


  /** @domName MediaQueryListListener.queryChanged */
  void queryChanged(MediaQueryList list) native "MediaQueryListListener_queryChanged_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName MediaSource
class MediaSource extends EventTarget {

  factory MediaSource() => _MediaSourceFactoryProvider.createMediaSource();
  MediaSource.internal(): super.internal();


  /** @domName MediaSource.activeSourceBuffers */
  SourceBufferList get activeSourceBuffers native "MediaSource_activeSourceBuffers_Getter";


  /** @domName MediaSource.duration */
  num get duration native "MediaSource_duration_Getter";


  /** @domName MediaSource.duration */
  void set duration(num value) native "MediaSource_duration_Setter";


  /** @domName MediaSource.readyState */
  String get readyState native "MediaSource_readyState_Getter";


  /** @domName MediaSource.sourceBuffers */
  SourceBufferList get sourceBuffers native "MediaSource_sourceBuffers_Getter";


  /** @domName MediaSource.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "MediaSource_addEventListener_Callback";


  /** @domName MediaSource.addSourceBuffer */
  SourceBuffer addSourceBuffer(String type) native "MediaSource_addSourceBuffer_Callback";


  /** @domName MediaSource.dispatchEvent */
  bool $dom_dispatchEvent(Event event) native "MediaSource_dispatchEvent_Callback";


  /** @domName MediaSource.endOfStream */
  void endOfStream(String error) native "MediaSource_endOfStream_Callback";


  /** @domName MediaSource.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "MediaSource_removeEventListener_Callback";


  /** @domName MediaSource.removeSourceBuffer */
  void removeSourceBuffer(SourceBuffer buffer) native "MediaSource_removeSourceBuffer_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName MediaStream
class MediaStream extends EventTarget {

  factory MediaStream(MediaStreamTrackList audioTracks, MediaStreamTrackList videoTracks) => _MediaStreamFactoryProvider.createMediaStream(audioTracks, videoTracks);
  MediaStream.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  MediaStreamEvents get on =>
    new MediaStreamEvents(this);

  static const int ENDED = 2;

  static const int LIVE = 1;


  /** @domName MediaStream.audioTracks */
  MediaStreamTrackList get audioTracks native "MediaStream_audioTracks_Getter";


  /** @domName MediaStream.label */
  String get label native "MediaStream_label_Getter";


  /** @domName MediaStream.readyState */
  int get readyState native "MediaStream_readyState_Getter";


  /** @domName MediaStream.videoTracks */
  MediaStreamTrackList get videoTracks native "MediaStream_videoTracks_Getter";


  /** @domName MediaStream.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "MediaStream_addEventListener_Callback";


  /** @domName MediaStream.dispatchEvent */
  bool $dom_dispatchEvent(Event event) native "MediaStream_dispatchEvent_Callback";


  /** @domName MediaStream.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "MediaStream_removeEventListener_Callback";

}

class MediaStreamEvents extends Events {
  MediaStreamEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get ended => this['ended'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName MediaStreamAudioSourceNode
class MediaStreamAudioSourceNode extends AudioSourceNode {
  MediaStreamAudioSourceNode.internal(): super.internal();


  /** @domName MediaStreamAudioSourceNode.mediaStream */
  MediaStream get mediaStream native "MediaStreamAudioSourceNode_mediaStream_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName MediaStreamEvent
class MediaStreamEvent extends Event {
  MediaStreamEvent.internal(): super.internal();


  /** @domName MediaStreamEvent.stream */
  MediaStream get stream native "MediaStreamEvent_stream_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName MediaStreamTrack
class MediaStreamTrack extends EventTarget {
  MediaStreamTrack.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  MediaStreamTrackEvents get on =>
    new MediaStreamTrackEvents(this);

  static const int ENDED = 2;

  static const int LIVE = 0;

  static const int MUTED = 1;


  /** @domName MediaStreamTrack.enabled */
  bool get enabled native "MediaStreamTrack_enabled_Getter";


  /** @domName MediaStreamTrack.enabled */
  void set enabled(bool value) native "MediaStreamTrack_enabled_Setter";


  /** @domName MediaStreamTrack.kind */
  String get kind native "MediaStreamTrack_kind_Getter";


  /** @domName MediaStreamTrack.label */
  String get label native "MediaStreamTrack_label_Getter";


  /** @domName MediaStreamTrack.readyState */
  int get readyState native "MediaStreamTrack_readyState_Getter";


  /** @domName MediaStreamTrack.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "MediaStreamTrack_addEventListener_Callback";


  /** @domName MediaStreamTrack.dispatchEvent */
  bool $dom_dispatchEvent(Event event) native "MediaStreamTrack_dispatchEvent_Callback";


  /** @domName MediaStreamTrack.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "MediaStreamTrack_removeEventListener_Callback";

}

class MediaStreamTrackEvents extends Events {
  MediaStreamTrackEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get ended => this['ended'];

  EventListenerList get mute => this['mute'];

  EventListenerList get unmute => this['unmute'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName MediaStreamTrackEvent
class MediaStreamTrackEvent extends Event {
  MediaStreamTrackEvent.internal(): super.internal();


  /** @domName MediaStreamTrackEvent.track */
  MediaStreamTrack get track native "MediaStreamTrackEvent_track_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName MediaStreamTrackList
class MediaStreamTrackList extends EventTarget {
  MediaStreamTrackList.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  MediaStreamTrackListEvents get on =>
    new MediaStreamTrackListEvents(this);


  /** @domName MediaStreamTrackList.length */
  int get length native "MediaStreamTrackList_length_Getter";


  /** @domName MediaStreamTrackList.add */
  void add(MediaStreamTrack track) native "MediaStreamTrackList_add_Callback";


  /** @domName MediaStreamTrackList.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "MediaStreamTrackList_addEventListener_Callback";


  /** @domName MediaStreamTrackList.dispatchEvent */
  bool $dom_dispatchEvent(Event event) native "MediaStreamTrackList_dispatchEvent_Callback";


  /** @domName MediaStreamTrackList.item */
  MediaStreamTrack item(int index) native "MediaStreamTrackList_item_Callback";


  /** @domName MediaStreamTrackList.remove */
  void remove(MediaStreamTrack track) native "MediaStreamTrackList_remove_Callback";


  /** @domName MediaStreamTrackList.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "MediaStreamTrackList_removeEventListener_Callback";

}

class MediaStreamTrackListEvents extends Events {
  MediaStreamTrackListEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get addTrack => this['addtrack'];

  EventListenerList get removeTrack => this['removetrack'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName MemoryInfo
class MemoryInfo extends NativeFieldWrapperClass1 {
  MemoryInfo.internal();


  /** @domName MemoryInfo.jsHeapSizeLimit */
  int get jsHeapSizeLimit native "MemoryInfo_jsHeapSizeLimit_Getter";


  /** @domName MemoryInfo.totalJSHeapSize */
  int get totalJSHeapSize native "MemoryInfo_totalJSHeapSize_Getter";


  /** @domName MemoryInfo.usedJSHeapSize */
  int get usedJSHeapSize native "MemoryInfo_usedJSHeapSize_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLMenuElement
class MenuElement extends _Element_Merged {

  factory MenuElement() => document.$dom_createElement("menu");
  MenuElement.internal(): super.internal();


  /** @domName HTMLMenuElement.compact */
  bool get compact native "HTMLMenuElement_compact_Getter";


  /** @domName HTMLMenuElement.compact */
  void set compact(bool value) native "HTMLMenuElement_compact_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName MessageChannel
class MessageChannel extends NativeFieldWrapperClass1 {

  factory MessageChannel() => _MessageChannelFactoryProvider.createMessageChannel();
  MessageChannel.internal();


  /** @domName MessageChannel.port1 */
  MessagePort get port1 native "MessageChannel_port1_Getter";


  /** @domName MessageChannel.port2 */
  MessagePort get port2 native "MessageChannel_port2_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName MessageEvent
class MessageEvent extends Event {
  MessageEvent.internal(): super.internal();


  /** @domName MessageEvent.data */
  Object get data native "MessageEvent_data_Getter";


  /** @domName MessageEvent.lastEventId */
  String get lastEventId native "MessageEvent_lastEventId_Getter";


  /** @domName MessageEvent.origin */
  String get origin native "MessageEvent_origin_Getter";


  /** @domName MessageEvent.ports */
  List get ports native "MessageEvent_ports_Getter";


  /** @domName MessageEvent.source */
  Window get source native "MessageEvent_source_Getter";


  /** @domName MessageEvent.initMessageEvent */
  void initMessageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object dataArg, String originArg, String lastEventIdArg, LocalWindow sourceArg, List messagePorts) native "MessageEvent_initMessageEvent_Callback";


  /** @domName MessageEvent.webkitInitMessageEvent */
  void webkitInitMessageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object dataArg, String originArg, String lastEventIdArg, LocalWindow sourceArg, List transferables) native "MessageEvent_webkitInitMessageEvent_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName MessagePort
class MessagePort extends EventTarget {
  MessagePort.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  MessagePortEvents get on =>
    new MessagePortEvents(this);


  /** @domName MessagePort.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "MessagePort_addEventListener_Callback";


  /** @domName MessagePort.close */
  void close() native "MessagePort_close_Callback";


  /** @domName MessagePort.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "MessagePort_dispatchEvent_Callback";


  /** @domName MessagePort.postMessage */
  void postMessage(Object message, [List messagePorts]) native "MessagePort_postMessage_Callback";


  /** @domName MessagePort.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "MessagePort_removeEventListener_Callback";


  /** @domName MessagePort.start */
  void start() native "MessagePort_start_Callback";

}

class MessagePortEvents extends Events {
  MessagePortEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get message => this['message'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLMetaElement
class MetaElement extends _Element_Merged {
  MetaElement.internal(): super.internal();


  /** @domName HTMLMetaElement.content */
  String get content native "HTMLMetaElement_content_Getter";


  /** @domName HTMLMetaElement.content */
  void set content(String value) native "HTMLMetaElement_content_Setter";


  /** @domName HTMLMetaElement.httpEquiv */
  String get httpEquiv native "HTMLMetaElement_httpEquiv_Getter";


  /** @domName HTMLMetaElement.httpEquiv */
  void set httpEquiv(String value) native "HTMLMetaElement_httpEquiv_Setter";


  /** @domName HTMLMetaElement.name */
  String get name native "HTMLMetaElement_name_Getter";


  /** @domName HTMLMetaElement.name */
  void set name(String value) native "HTMLMetaElement_name_Setter";


  /** @domName HTMLMetaElement.scheme */
  String get scheme native "HTMLMetaElement_scheme_Getter";


  /** @domName HTMLMetaElement.scheme */
  void set scheme(String value) native "HTMLMetaElement_scheme_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Metadata
class Metadata extends NativeFieldWrapperClass1 {
  Metadata.internal();


  /** @domName Metadata.modificationTime */
  Date get modificationTime native "Metadata_modificationTime_Getter";


  /** @domName Metadata.size */
  int get size native "Metadata_size_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void MetadataCallback(Metadata metadata);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLMeterElement
class MeterElement extends _Element_Merged {

  factory MeterElement() => document.$dom_createElement("meter");
  MeterElement.internal(): super.internal();


  /** @domName HTMLMeterElement.high */
  num get high native "HTMLMeterElement_high_Getter";


  /** @domName HTMLMeterElement.high */
  void set high(num value) native "HTMLMeterElement_high_Setter";


  /** @domName HTMLMeterElement.labels */
  List<Node> get labels native "HTMLMeterElement_labels_Getter";


  /** @domName HTMLMeterElement.low */
  num get low native "HTMLMeterElement_low_Getter";


  /** @domName HTMLMeterElement.low */
  void set low(num value) native "HTMLMeterElement_low_Setter";


  /** @domName HTMLMeterElement.max */
  num get max native "HTMLMeterElement_max_Getter";


  /** @domName HTMLMeterElement.max */
  void set max(num value) native "HTMLMeterElement_max_Setter";


  /** @domName HTMLMeterElement.min */
  num get min native "HTMLMeterElement_min_Getter";


  /** @domName HTMLMeterElement.min */
  void set min(num value) native "HTMLMeterElement_min_Setter";


  /** @domName HTMLMeterElement.optimum */
  num get optimum native "HTMLMeterElement_optimum_Getter";


  /** @domName HTMLMeterElement.optimum */
  void set optimum(num value) native "HTMLMeterElement_optimum_Setter";


  /** @domName HTMLMeterElement.value */
  num get value native "HTMLMeterElement_value_Getter";


  /** @domName HTMLMeterElement.value */
  void set value(num value) native "HTMLMeterElement_value_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLModElement
class ModElement extends _Element_Merged {
  ModElement.internal(): super.internal();


  /** @domName HTMLModElement.cite */
  String get cite native "HTMLModElement_cite_Getter";


  /** @domName HTMLModElement.cite */
  void set cite(String value) native "HTMLModElement_cite_Setter";


  /** @domName HTMLModElement.dateTime */
  String get dateTime native "HTMLModElement_dateTime_Getter";


  /** @domName HTMLModElement.dateTime */
  void set dateTime(String value) native "HTMLModElement_dateTime_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


class MouseEvent extends UIEvent {
  factory MouseEvent(String type, Window view, int detail, int screenX,
      int screenY, int clientX, int clientY, int button, [bool canBubble = true,
      bool cancelable = true, bool ctrlKey = false, bool altKey = false,
      bool shiftKey = false, bool metaKey = false,
      EventTarget relatedTarget = null]) =>
      _MouseEventFactoryProvider.createMouseEvent(
          type, view, detail, screenX, screenY,
          clientX, clientY, button, canBubble, cancelable,
          ctrlKey, altKey, shiftKey, metaKey,
          relatedTarget);
  MouseEvent.internal(): super.internal();


  /** @domName MouseEvent.altKey */
  bool get altKey native "MouseEvent_altKey_Getter";


  /** @domName MouseEvent.button */
  int get button native "MouseEvent_button_Getter";


  /** @domName MouseEvent.clientX */
  int get clientX native "MouseEvent_clientX_Getter";


  /** @domName MouseEvent.clientY */
  int get clientY native "MouseEvent_clientY_Getter";


  /** @domName MouseEvent.ctrlKey */
  bool get ctrlKey native "MouseEvent_ctrlKey_Getter";


  /** @domName MouseEvent.dataTransfer */
  Clipboard get dataTransfer native "MouseEvent_dataTransfer_Getter";


  /** @domName MouseEvent.fromElement */
  Node get fromElement native "MouseEvent_fromElement_Getter";


  /** @domName MouseEvent.metaKey */
  bool get metaKey native "MouseEvent_metaKey_Getter";


  /** @domName MouseEvent.offsetX */
  int get offsetX native "MouseEvent_offsetX_Getter";


  /** @domName MouseEvent.offsetY */
  int get offsetY native "MouseEvent_offsetY_Getter";


  /** @domName MouseEvent.relatedTarget */
  EventTarget get relatedTarget native "MouseEvent_relatedTarget_Getter";


  /** @domName MouseEvent.screenX */
  int get screenX native "MouseEvent_screenX_Getter";


  /** @domName MouseEvent.screenY */
  int get screenY native "MouseEvent_screenY_Getter";


  /** @domName MouseEvent.shiftKey */
  bool get shiftKey native "MouseEvent_shiftKey_Getter";


  /** @domName MouseEvent.toElement */
  Node get toElement native "MouseEvent_toElement_Getter";


  /** @domName MouseEvent.webkitMovementX */
  int get webkitMovementX native "MouseEvent_webkitMovementX_Getter";


  /** @domName MouseEvent.webkitMovementY */
  int get webkitMovementY native "MouseEvent_webkitMovementY_Getter";


  /** @domName MouseEvent.x */
  int get x native "MouseEvent_x_Getter";


  /** @domName MouseEvent.y */
  int get y native "MouseEvent_y_Getter";


  /** @domName MouseEvent.initMouseEvent */
  void $dom_initMouseEvent(String type, bool canBubble, bool cancelable, LocalWindow view, int detail, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, int button, EventTarget relatedTarget) native "MouseEvent_initMouseEvent_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void MutationCallback(List<MutationRecord> mutations, MutationObserver observer);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName MutationEvent
class MutationEvent extends Event {
  MutationEvent.internal(): super.internal();

  static const int ADDITION = 2;

  static const int MODIFICATION = 1;

  static const int REMOVAL = 3;


  /** @domName MutationEvent.attrChange */
  int get attrChange native "MutationEvent_attrChange_Getter";


  /** @domName MutationEvent.attrName */
  String get attrName native "MutationEvent_attrName_Getter";


  /** @domName MutationEvent.newValue */
  String get newValue native "MutationEvent_newValue_Getter";


  /** @domName MutationEvent.prevValue */
  String get prevValue native "MutationEvent_prevValue_Getter";


  /** @domName MutationEvent.relatedNode */
  Node get relatedNode native "MutationEvent_relatedNode_Getter";


  /** @domName MutationEvent.initMutationEvent */
  void initMutationEvent(String type, bool canBubble, bool cancelable, Node relatedNode, String prevValue, String newValue, String attrName, int attrChange) native "MutationEvent_initMutationEvent_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class MutationObserver extends NativeFieldWrapperClass1 {

  factory MutationObserver(MutationCallback callback) => _MutationObserverFactoryProvider.createMutationObserver(callback);
  MutationObserver.internal();


  /** @domName MutationObserver.disconnect */
  void disconnect() native "MutationObserver_disconnect_Callback";


  /** @domName MutationObserver._observe */
  void _observe(Node target, Map options) native "MutationObserver__observe_Callback";


  /** @domName MutationObserver.takeRecords */
  List<MutationRecord> takeRecords() native "MutationObserver_takeRecords_Callback";

  void observe(Node target,
               {Map options,
                bool childList,
                bool attributes,
                bool characterData,
                bool subtree,
                bool attributeOldValue,
                bool characterDataOldValue,
                List<String> attributeFilter}) {

    // Parse options into map of known type.
    var parsedOptions = _createDict();

    if (options != null) {
      options.forEach((k, v) {
          if (_boolKeys.containsKey(k)) {
            _add(parsedOptions, k, true == v);
          } else if (k == 'attributeFilter') {
            _add(parsedOptions, k, _fixupList(v));
          } else {
            throw new ArgumentError(
                "Illegal MutationObserver.observe option '$k'");
          }
        });
    }

    // Override options passed in the map with named optional arguments.
    override(key, value) {
      if (value != null) _add(parsedOptions, key, value);
    }

    override('childList', childList);
    override('attributes', attributes);
    override('characterData', characterData);
    override('subtree', subtree);
    override('attributeOldValue', attributeOldValue);
    override('characterDataOldValue', characterDataOldValue);
    if (attributeFilter != null) {
      override('attributeFilter', _fixupList(attributeFilter));
    }

    _call(target, parsedOptions);
  }

   // TODO: Change to a set when const Sets are available.
  static final _boolKeys =
    const {'childList': true,
           'attributes': true,
           'characterData': true,
           'subtree': true,
           'attributeOldValue': true,
           'characterDataOldValue': true };

  static _createDict() => {};
  static _add(m, String key, value) { m[key] = value; }
  static _fixupList(list) => list;

  void _call(Node target, options) {
    _observe(target, options);
  }

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName MutationRecord
class MutationRecord extends NativeFieldWrapperClass1 {
  MutationRecord.internal();


  /** @domName MutationRecord.addedNodes */
  List<Node> get addedNodes native "MutationRecord_addedNodes_Getter";


  /** @domName MutationRecord.attributeName */
  String get attributeName native "MutationRecord_attributeName_Getter";


  /** @domName MutationRecord.attributeNamespace */
  String get attributeNamespace native "MutationRecord_attributeNamespace_Getter";


  /** @domName MutationRecord.nextSibling */
  Node get nextSibling native "MutationRecord_nextSibling_Getter";


  /** @domName MutationRecord.oldValue */
  String get oldValue native "MutationRecord_oldValue_Getter";


  /** @domName MutationRecord.previousSibling */
  Node get previousSibling native "MutationRecord_previousSibling_Getter";


  /** @domName MutationRecord.removedNodes */
  List<Node> get removedNodes native "MutationRecord_removedNodes_Getter";


  /** @domName MutationRecord.target */
  Node get target native "MutationRecord_target_Getter";


  /** @domName MutationRecord.type */
  String get type native "MutationRecord_type_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName NamedNodeMap
class NamedNodeMap extends NativeFieldWrapperClass1 implements List<Node> {
  NamedNodeMap.internal();


  /** @domName NamedNodeMap.length */
  int get length native "NamedNodeMap_length_Getter";

  Node operator[](int index) native "NamedNodeMap_item_Callback";

  void operator[]=(int index, Node value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Node> mixins.
  // Node is the element type.

  // From Iterable<Node>:

  Iterator<Node> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Node>(this);
  }

  // From Collection<Node>:

  void add(Node value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(Node value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<Node> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(Node element) => _Collections.contains(this, element);

  void forEach(void f(Node element)) => _Collections.forEach(this, f);

  Collection map(f(Node element)) => _Collections.map(this, [], f);

  Collection<Node> filter(bool f(Node element)) =>
     _Collections.filter(this, <Node>[], f);

  bool every(bool f(Node element)) => _Collections.every(this, f);

  bool some(bool f(Node element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<Node>:

  void sort([Comparator<Node> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Node element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Node element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  Node get first => this[0];

  Node get last => this[length - 1];

  Node removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<Node> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [Node initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<Node> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <Node>[]);

  // -- end List<Node> mixins.


  /** @domName NamedNodeMap.getNamedItem */
  Node getNamedItem(String name) native "NamedNodeMap_getNamedItem_Callback";


  /** @domName NamedNodeMap.getNamedItemNS */
  Node getNamedItemNS(String namespaceURI, String localName) native "NamedNodeMap_getNamedItemNS_Callback";


  /** @domName NamedNodeMap.item */
  Node item(int index) native "NamedNodeMap_item_Callback";


  /** @domName NamedNodeMap.removeNamedItem */
  Node removeNamedItem(String name) native "NamedNodeMap_removeNamedItem_Callback";


  /** @domName NamedNodeMap.removeNamedItemNS */
  Node removeNamedItemNS(String namespaceURI, String localName) native "NamedNodeMap_removeNamedItemNS_Callback";


  /** @domName NamedNodeMap.setNamedItem */
  Node setNamedItem(Node node) native "NamedNodeMap_setNamedItem_Callback";


  /** @domName NamedNodeMap.setNamedItemNS */
  Node setNamedItemNS(Node node) native "NamedNodeMap_setNamedItemNS_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Navigator
class Navigator extends NativeFieldWrapperClass1 {
  Navigator.internal();


  /** @domName Navigator.appCodeName */
  String get appCodeName native "Navigator_appCodeName_Getter";


  /** @domName Navigator.appName */
  String get appName native "Navigator_appName_Getter";


  /** @domName Navigator.appVersion */
  String get appVersion native "Navigator_appVersion_Getter";


  /** @domName Navigator.cookieEnabled */
  bool get cookieEnabled native "Navigator_cookieEnabled_Getter";


  /** @domName Navigator.geolocation */
  Geolocation get geolocation native "Navigator_geolocation_Getter";


  /** @domName Navigator.language */
  String get language native "Navigator_language_Getter";


  /** @domName Navigator.mimeTypes */
  DOMMimeTypeArray get mimeTypes native "Navigator_mimeTypes_Getter";


  /** @domName Navigator.onLine */
  bool get onLine native "Navigator_onLine_Getter";


  /** @domName Navigator.platform */
  String get platform native "Navigator_platform_Getter";


  /** @domName Navigator.plugins */
  DOMPluginArray get plugins native "Navigator_plugins_Getter";


  /** @domName Navigator.product */
  String get product native "Navigator_product_Getter";


  /** @domName Navigator.productSub */
  String get productSub native "Navigator_productSub_Getter";


  /** @domName Navigator.userAgent */
  String get userAgent native "Navigator_userAgent_Getter";


  /** @domName Navigator.vendor */
  String get vendor native "Navigator_vendor_Getter";


  /** @domName Navigator.vendorSub */
  String get vendorSub native "Navigator_vendorSub_Getter";


  /** @domName Navigator.webkitBattery */
  BatteryManager get webkitBattery native "Navigator_webkitBattery_Getter";


  /** @domName Navigator.getStorageUpdates */
  void getStorageUpdates() native "Navigator_getStorageUpdates_Callback";


  /** @domName Navigator.javaEnabled */
  bool javaEnabled() native "Navigator_javaEnabled_Callback";


  /** @domName Navigator.webkitGetGamepads */
  List<Gamepad> webkitGetGamepads() native "Navigator_webkitGetGamepads_Callback";


  /** @domName Navigator.webkitGetUserMedia */
  void webkitGetUserMedia(Map options, NavigatorUserMediaSuccessCallback successCallback, [NavigatorUserMediaErrorCallback errorCallback]) native "Navigator_webkitGetUserMedia_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName NavigatorUserMediaError
class NavigatorUserMediaError extends NativeFieldWrapperClass1 {
  NavigatorUserMediaError.internal();

  static const int PERMISSION_DENIED = 1;


  /** @domName NavigatorUserMediaError.code */
  int get code native "NavigatorUserMediaError_code_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void NavigatorUserMediaErrorCallback(NavigatorUserMediaError error);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void NavigatorUserMediaSuccessCallback(LocalMediaStream stream);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * Lazy implementation of the child nodes of an element that does not request
 * the actual child nodes of an element until strictly necessary greatly
 * improving performance for the typical cases where it is not required.
 */
class _ChildNodeListLazy implements List {
  final Node _this;

  _ChildNodeListLazy(this._this);


  Node get first => _this.$dom_firstChild;
  Node get last => _this.$dom_lastChild;

  void add(Node value) {
    _this.$dom_appendChild(value);
  }

  void addLast(Node value) {
    _this.$dom_appendChild(value);
  }


  void addAll(Collection<Node> collection) {
    for (Node node in collection) {
      _this.$dom_appendChild(node);
    }
  }

  Node removeLast() {
    final result = last;
    if (result != null) {
      _this.$dom_removeChild(result);
    }
    return result;
  }

  void clear() {
    _this.text = '';
  }

  void operator []=(int index, Node value) {
    _this.$dom_replaceChild(value, this[index]);
  }

  Iterator<Node> iterator() => _this.$dom_childNodes.iterator();

  // TODO(jacobr): We can implement these methods much more efficiently by
  // looking up the nodeList only once instead of once per iteration.
  bool contains(Node element) => _Collections.contains(this, element);

  void forEach(void f(Node element)) => _Collections.forEach(this, f);

  Collection map(f(Node element)) => _Collections.map(this, [], f);

  Collection<Node> filter(bool f(Node element)) =>
     _Collections.filter(this, <Node>[], f);

  bool every(bool f(Node element)) => _Collections.every(this, f);

  bool some(bool f(Node element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<Node>:

  // TODO(jacobr): this could be implemented for child node lists.
  // The exception we throw here is misleading.
  void sort([Comparator<Node> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Node element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Node element, [int start = 0]) =>
      _Lists.lastIndexOf(this, element, start);

  // FIXME: implement these.
  void setRange(int start, int rangeLength, List<Node> from, [int startFrom]) {
    throw new UnsupportedError(
        "Cannot setRange on immutable List.");
  }
  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError(
        "Cannot removeRange on immutable List.");
  }
  void insertRange(int start, int rangeLength, [Node initialValue]) {
    throw new UnsupportedError(
        "Cannot insertRange on immutable List.");
  }
  List<Node> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <Node>[]);

  // -- end List<Node> mixins.

  // TODO(jacobr): benchmark whether this is more efficient or whether caching
  // a local copy of $dom_childNodes is more efficient.
  int get length => _this.$dom_childNodes.length;

  Node operator[](int index) => _this.$dom_childNodes[index];
}

class Node extends EventTarget {
  _ChildNodeListLazy get nodes {
    return new _ChildNodeListLazy(this);
  }

  void set nodes(Collection<Node> value) {
    // Copy list first since we don't want liveness during iteration.
    // TODO(jacobr): there is a better way to do this.
    List copy = new List.from(value);
    text = '';
    for (Node node in copy) {
      $dom_appendChild(node);
    }
  }

  /**
   * Removes this node from the DOM.
   * @domName Node.removeChild
   */
  void remove() {
    // TODO(jacobr): should we throw an exception if parent is already null?
    // TODO(vsm): Use the native remove when available.
    if (this.parent != null) {
      final Node parent = this.parent;
      parent.$dom_removeChild(this);
    }
  }

  /**
   * Replaces this node with another node.
   * @domName Node.replaceChild
   */
  Node replaceWith(Node otherNode) {
    try {
      final Node parent = this.parent;
      parent.$dom_replaceChild(otherNode, this);
    } catch (e) {

    };
    return this;
  }

  Node.internal(): super.internal();

  static const int ATTRIBUTE_NODE = 2;

  static const int CDATA_SECTION_NODE = 4;

  static const int COMMENT_NODE = 8;

  static const int DOCUMENT_FRAGMENT_NODE = 11;

  static const int DOCUMENT_NODE = 9;

  static const int DOCUMENT_POSITION_CONTAINED_BY = 0x10;

  static const int DOCUMENT_POSITION_CONTAINS = 0x08;

  static const int DOCUMENT_POSITION_DISCONNECTED = 0x01;

  static const int DOCUMENT_POSITION_FOLLOWING = 0x04;

  static const int DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC = 0x20;

  static const int DOCUMENT_POSITION_PRECEDING = 0x02;

  static const int DOCUMENT_TYPE_NODE = 10;

  static const int ELEMENT_NODE = 1;

  static const int ENTITY_NODE = 6;

  static const int ENTITY_REFERENCE_NODE = 5;

  static const int NOTATION_NODE = 12;

  static const int PROCESSING_INSTRUCTION_NODE = 7;

  static const int TEXT_NODE = 3;


  /** @domName Node.attributes */
  NamedNodeMap get $dom_attributes native "Node_attributes_Getter";


  /** @domName Node.childNodes */
  List<Node> get $dom_childNodes native "Node_childNodes_Getter";


  /** @domName Node.firstChild */
  Node get $dom_firstChild native "Node_firstChild_Getter";


  /** @domName Node.lastChild */
  Node get $dom_lastChild native "Node_lastChild_Getter";


  /** @domName Node.localName */
  String get $dom_localName native "Node_localName_Getter";


  /** @domName Node.namespaceURI */
  String get $dom_namespaceURI native "Node_namespaceURI_Getter";


  /** @domName Node.nextSibling */
  Node get nextNode native "Node_nextSibling_Getter";


  /** @domName Node.nodeType */
  int get nodeType native "Node_nodeType_Getter";


  /** @domName Node.ownerDocument */
  Document get document native "Node_ownerDocument_Getter";


  /** @domName Node.parentNode */
  Node get parent native "Node_parentNode_Getter";


  /** @domName Node.previousSibling */
  Node get previousNode native "Node_previousSibling_Getter";


  /** @domName Node.textContent */
  String get text native "Node_textContent_Getter";


  /** @domName Node.textContent */
  void set text(String value) native "Node_textContent_Setter";


  /** @domName Node.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "Node_addEventListener_Callback";


  /** @domName Node.appendChild */
  Node $dom_appendChild(Node newChild) native "Node_appendChild_Callback";


  /** @domName Node.cloneNode */
  Node clone(bool deep) native "Node_cloneNode_Callback";


  /** @domName Node.contains */
  bool contains(Node other) native "Node_contains_Callback";


  /** @domName Node.dispatchEvent */
  bool $dom_dispatchEvent(Event event) native "Node_dispatchEvent_Callback";


  /** @domName Node.hasChildNodes */
  bool hasChildNodes() native "Node_hasChildNodes_Callback";


  /** @domName Node.insertBefore */
  Node insertBefore(Node newChild, Node refChild) native "Node_insertBefore_Callback";


  /** @domName Node.removeChild */
  Node $dom_removeChild(Node oldChild) native "Node_removeChild_Callback";


  /** @domName Node.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "Node_removeEventListener_Callback";


  /** @domName Node.replaceChild */
  Node $dom_replaceChild(Node newChild, Node oldChild) native "Node_replaceChild_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName NodeFilter
class NodeFilter extends NativeFieldWrapperClass1 {
  NodeFilter.internal();

  static const int FILTER_ACCEPT = 1;

  static const int FILTER_REJECT = 2;

  static const int FILTER_SKIP = 3;

  static const int SHOW_ALL = 0xFFFFFFFF;

  static const int SHOW_ATTRIBUTE = 0x00000002;

  static const int SHOW_CDATA_SECTION = 0x00000008;

  static const int SHOW_COMMENT = 0x00000080;

  static const int SHOW_DOCUMENT = 0x00000100;

  static const int SHOW_DOCUMENT_FRAGMENT = 0x00000400;

  static const int SHOW_DOCUMENT_TYPE = 0x00000200;

  static const int SHOW_ELEMENT = 0x00000001;

  static const int SHOW_ENTITY = 0x00000020;

  static const int SHOW_ENTITY_REFERENCE = 0x00000010;

  static const int SHOW_NOTATION = 0x00000800;

  static const int SHOW_PROCESSING_INSTRUCTION = 0x00000040;

  static const int SHOW_TEXT = 0x00000004;


  /** @domName NodeFilter.acceptNode */
  int acceptNode(Node n) native "NodeFilter_acceptNode_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName NodeIterator
class NodeIterator extends NativeFieldWrapperClass1 {
  NodeIterator.internal();


  /** @domName NodeIterator.expandEntityReferences */
  bool get expandEntityReferences native "NodeIterator_expandEntityReferences_Getter";


  /** @domName NodeIterator.filter */
  NodeFilter get filter native "NodeIterator_filter_Getter";


  /** @domName NodeIterator.pointerBeforeReferenceNode */
  bool get pointerBeforeReferenceNode native "NodeIterator_pointerBeforeReferenceNode_Getter";


  /** @domName NodeIterator.referenceNode */
  Node get referenceNode native "NodeIterator_referenceNode_Getter";


  /** @domName NodeIterator.root */
  Node get root native "NodeIterator_root_Getter";


  /** @domName NodeIterator.whatToShow */
  int get whatToShow native "NodeIterator_whatToShow_Getter";


  /** @domName NodeIterator.detach */
  void detach() native "NodeIterator_detach_Callback";


  /** @domName NodeIterator.nextNode */
  Node nextNode() native "NodeIterator_nextNode_Callback";


  /** @domName NodeIterator.previousNode */
  Node previousNode() native "NodeIterator_previousNode_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Notation
class Notation extends Node {
  Notation.internal(): super.internal();


  /** @domName Notation.publicId */
  String get publicId native "Notation_publicId_Getter";


  /** @domName Notation.systemId */
  String get systemId native "Notation_systemId_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Notification
class Notification extends EventTarget {

  factory Notification(String title, [Map options]) {
    if (!?options) {
      return _NotificationFactoryProvider.createNotification(title);
    }
    return _NotificationFactoryProvider.createNotification(title, options);
  }
  Notification.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  NotificationEvents get on =>
    new NotificationEvents(this);


  /** @domName Notification.dir */
  String get dir native "Notification_dir_Getter";


  /** @domName Notification.dir */
  void set dir(String value) native "Notification_dir_Setter";


  /** @domName Notification.permission */
  String get permission native "Notification_permission_Getter";


  /** @domName Notification.replaceId */
  String get replaceId native "Notification_replaceId_Getter";


  /** @domName Notification.replaceId */
  void set replaceId(String value) native "Notification_replaceId_Setter";


  /** @domName Notification.tag */
  String get tag native "Notification_tag_Getter";


  /** @domName Notification.tag */
  void set tag(String value) native "Notification_tag_Setter";


  /** @domName Notification.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "Notification_addEventListener_Callback";


  /** @domName Notification.cancel */
  void cancel() native "Notification_cancel_Callback";


  /** @domName Notification.close */
  void close() native "Notification_close_Callback";


  /** @domName Notification.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "Notification_dispatchEvent_Callback";


  /** @domName Notification.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "Notification_removeEventListener_Callback";


  /** @domName Notification.requestPermission */
  static void requestPermission(NotificationPermissionCallback callback) native "Notification_requestPermission_Callback";


  /** @domName Notification.show */
  void show() native "Notification_show_Callback";

}

class NotificationEvents extends Events {
  NotificationEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get click => this['click'];

  EventListenerList get close => this['close'];

  EventListenerList get display => this['display'];

  EventListenerList get error => this['error'];

  EventListenerList get show => this['show'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName NotificationCenter
class NotificationCenter extends NativeFieldWrapperClass1 {
  NotificationCenter.internal();


  /** @domName NotificationCenter.checkPermission */
  int checkPermission() native "NotificationCenter_checkPermission_Callback";


  /** @domName NotificationCenter.createHTMLNotification */
  Notification createHTMLNotification(String url) native "NotificationCenter_createHTMLNotification_Callback";


  /** @domName NotificationCenter.createNotification */
  Notification createNotification(String iconUrl, String title, String body) native "NotificationCenter_createNotification_Callback";


  /** @domName NotificationCenter.requestPermission */
  void requestPermission(VoidCallback callback) native "NotificationCenter_requestPermission_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void NotificationPermissionCallback(String permission);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName OESElementIndexUint
class OESElementIndexUint extends NativeFieldWrapperClass1 {
  OESElementIndexUint.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName OESStandardDerivatives
class OESStandardDerivatives extends NativeFieldWrapperClass1 {
  OESStandardDerivatives.internal();

  static const int FRAGMENT_SHADER_DERIVATIVE_HINT_OES = 0x8B8B;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName OESTextureFloat
class OESTextureFloat extends NativeFieldWrapperClass1 {
  OESTextureFloat.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName OESVertexArrayObject
class OESVertexArrayObject extends NativeFieldWrapperClass1 {
  OESVertexArrayObject.internal();

  static const int VERTEX_ARRAY_BINDING_OES = 0x85B5;


  /** @domName OESVertexArrayObject.bindVertexArrayOES */
  void bindVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) native "OESVertexArrayObject_bindVertexArrayOES_Callback";


  /** @domName OESVertexArrayObject.createVertexArrayOES */
  WebGLVertexArrayObjectOES createVertexArrayOES() native "OESVertexArrayObject_createVertexArrayOES_Callback";


  /** @domName OESVertexArrayObject.deleteVertexArrayOES */
  void deleteVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) native "OESVertexArrayObject_deleteVertexArrayOES_Callback";


  /** @domName OESVertexArrayObject.isVertexArrayOES */
  bool isVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) native "OESVertexArrayObject_isVertexArrayOES_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLOListElement
class OListElement extends _Element_Merged {

  factory OListElement() => document.$dom_createElement("ol");
  OListElement.internal(): super.internal();


  /** @domName HTMLOListElement.compact */
  bool get compact native "HTMLOListElement_compact_Getter";


  /** @domName HTMLOListElement.compact */
  void set compact(bool value) native "HTMLOListElement_compact_Setter";


  /** @domName HTMLOListElement.reversed */
  bool get reversed native "HTMLOListElement_reversed_Getter";


  /** @domName HTMLOListElement.reversed */
  void set reversed(bool value) native "HTMLOListElement_reversed_Setter";


  /** @domName HTMLOListElement.start */
  int get start native "HTMLOListElement_start_Getter";


  /** @domName HTMLOListElement.start */
  void set start(int value) native "HTMLOListElement_start_Setter";


  /** @domName HTMLOListElement.type */
  String get type native "HTMLOListElement_type_Getter";


  /** @domName HTMLOListElement.type */
  void set type(String value) native "HTMLOListElement_type_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLObjectElement
class ObjectElement extends _Element_Merged {

  factory ObjectElement() => document.$dom_createElement("object");
  ObjectElement.internal(): super.internal();


  /** @domName HTMLObjectElement.align */
  String get align native "HTMLObjectElement_align_Getter";


  /** @domName HTMLObjectElement.align */
  void set align(String value) native "HTMLObjectElement_align_Setter";


  /** @domName HTMLObjectElement.archive */
  String get archive native "HTMLObjectElement_archive_Getter";


  /** @domName HTMLObjectElement.archive */
  void set archive(String value) native "HTMLObjectElement_archive_Setter";


  /** @domName HTMLObjectElement.border */
  String get border native "HTMLObjectElement_border_Getter";


  /** @domName HTMLObjectElement.border */
  void set border(String value) native "HTMLObjectElement_border_Setter";


  /** @domName HTMLObjectElement.code */
  String get code native "HTMLObjectElement_code_Getter";


  /** @domName HTMLObjectElement.code */
  void set code(String value) native "HTMLObjectElement_code_Setter";


  /** @domName HTMLObjectElement.codeBase */
  String get codeBase native "HTMLObjectElement_codeBase_Getter";


  /** @domName HTMLObjectElement.codeBase */
  void set codeBase(String value) native "HTMLObjectElement_codeBase_Setter";


  /** @domName HTMLObjectElement.codeType */
  String get codeType native "HTMLObjectElement_codeType_Getter";


  /** @domName HTMLObjectElement.codeType */
  void set codeType(String value) native "HTMLObjectElement_codeType_Setter";


  /** @domName HTMLObjectElement.data */
  String get data native "HTMLObjectElement_data_Getter";


  /** @domName HTMLObjectElement.data */
  void set data(String value) native "HTMLObjectElement_data_Setter";


  /** @domName HTMLObjectElement.declare */
  bool get declare native "HTMLObjectElement_declare_Getter";


  /** @domName HTMLObjectElement.declare */
  void set declare(bool value) native "HTMLObjectElement_declare_Setter";


  /** @domName HTMLObjectElement.form */
  FormElement get form native "HTMLObjectElement_form_Getter";


  /** @domName HTMLObjectElement.height */
  String get height native "HTMLObjectElement_height_Getter";


  /** @domName HTMLObjectElement.height */
  void set height(String value) native "HTMLObjectElement_height_Setter";


  /** @domName HTMLObjectElement.hspace */
  int get hspace native "HTMLObjectElement_hspace_Getter";


  /** @domName HTMLObjectElement.hspace */
  void set hspace(int value) native "HTMLObjectElement_hspace_Setter";


  /** @domName HTMLObjectElement.name */
  String get name native "HTMLObjectElement_name_Getter";


  /** @domName HTMLObjectElement.name */
  void set name(String value) native "HTMLObjectElement_name_Setter";


  /** @domName HTMLObjectElement.standby */
  String get standby native "HTMLObjectElement_standby_Getter";


  /** @domName HTMLObjectElement.standby */
  void set standby(String value) native "HTMLObjectElement_standby_Setter";


  /** @domName HTMLObjectElement.type */
  String get type native "HTMLObjectElement_type_Getter";


  /** @domName HTMLObjectElement.type */
  void set type(String value) native "HTMLObjectElement_type_Setter";


  /** @domName HTMLObjectElement.useMap */
  String get useMap native "HTMLObjectElement_useMap_Getter";


  /** @domName HTMLObjectElement.useMap */
  void set useMap(String value) native "HTMLObjectElement_useMap_Setter";


  /** @domName HTMLObjectElement.validationMessage */
  String get validationMessage native "HTMLObjectElement_validationMessage_Getter";


  /** @domName HTMLObjectElement.validity */
  ValidityState get validity native "HTMLObjectElement_validity_Getter";


  /** @domName HTMLObjectElement.vspace */
  int get vspace native "HTMLObjectElement_vspace_Getter";


  /** @domName HTMLObjectElement.vspace */
  void set vspace(int value) native "HTMLObjectElement_vspace_Setter";


  /** @domName HTMLObjectElement.width */
  String get width native "HTMLObjectElement_width_Getter";


  /** @domName HTMLObjectElement.width */
  void set width(String value) native "HTMLObjectElement_width_Setter";


  /** @domName HTMLObjectElement.willValidate */
  bool get willValidate native "HTMLObjectElement_willValidate_Getter";


  /** @domName HTMLObjectElement.checkValidity */
  bool checkValidity() native "HTMLObjectElement_checkValidity_Callback";


  /** @domName HTMLObjectElement.setCustomValidity */
  void setCustomValidity(String error) native "HTMLObjectElement_setCustomValidity_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName OfflineAudioCompletionEvent
class OfflineAudioCompletionEvent extends Event {
  OfflineAudioCompletionEvent.internal(): super.internal();


  /** @domName OfflineAudioCompletionEvent.renderedBuffer */
  AudioBuffer get renderedBuffer native "OfflineAudioCompletionEvent_renderedBuffer_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLOptGroupElement
class OptGroupElement extends _Element_Merged {

  factory OptGroupElement() => document.$dom_createElement("optgroup");
  OptGroupElement.internal(): super.internal();


  /** @domName HTMLOptGroupElement.disabled */
  bool get disabled native "HTMLOptGroupElement_disabled_Getter";


  /** @domName HTMLOptGroupElement.disabled */
  void set disabled(bool value) native "HTMLOptGroupElement_disabled_Setter";


  /** @domName HTMLOptGroupElement.label */
  String get label native "HTMLOptGroupElement_label_Getter";


  /** @domName HTMLOptGroupElement.label */
  void set label(String value) native "HTMLOptGroupElement_label_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLOptionElement
class OptionElement extends _Element_Merged {

  factory OptionElement([String data, String value, bool defaultSelected, bool selected]) {
    if (!?data) {
      return _OptionElementFactoryProvider.createOptionElement();
    }
    if (!?value) {
      return _OptionElementFactoryProvider.createOptionElement(data);
    }
    if (!?defaultSelected) {
      return _OptionElementFactoryProvider.createOptionElement(data, value);
    }
    if (!?selected) {
      return _OptionElementFactoryProvider.createOptionElement(data, value, defaultSelected);
    }
    return _OptionElementFactoryProvider.createOptionElement(data, value, defaultSelected, selected);
  }
  OptionElement.internal(): super.internal();


  /** @domName HTMLOptionElement.defaultSelected */
  bool get defaultSelected native "HTMLOptionElement_defaultSelected_Getter";


  /** @domName HTMLOptionElement.defaultSelected */
  void set defaultSelected(bool value) native "HTMLOptionElement_defaultSelected_Setter";


  /** @domName HTMLOptionElement.disabled */
  bool get disabled native "HTMLOptionElement_disabled_Getter";


  /** @domName HTMLOptionElement.disabled */
  void set disabled(bool value) native "HTMLOptionElement_disabled_Setter";


  /** @domName HTMLOptionElement.form */
  FormElement get form native "HTMLOptionElement_form_Getter";


  /** @domName HTMLOptionElement.index */
  int get index native "HTMLOptionElement_index_Getter";


  /** @domName HTMLOptionElement.label */
  String get label native "HTMLOptionElement_label_Getter";


  /** @domName HTMLOptionElement.label */
  void set label(String value) native "HTMLOptionElement_label_Setter";


  /** @domName HTMLOptionElement.selected */
  bool get selected native "HTMLOptionElement_selected_Getter";


  /** @domName HTMLOptionElement.selected */
  void set selected(bool value) native "HTMLOptionElement_selected_Setter";


  /** @domName HTMLOptionElement.value */
  String get value native "HTMLOptionElement_value_Getter";


  /** @domName HTMLOptionElement.value */
  void set value(String value) native "HTMLOptionElement_value_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName OscillatorNode
class OscillatorNode extends AudioSourceNode {
  OscillatorNode.internal(): super.internal();

  static const int CUSTOM = 4;

  static const int FINISHED_STATE = 3;

  static const int PLAYING_STATE = 2;

  static const int SAWTOOTH = 2;

  static const int SCHEDULED_STATE = 1;

  static const int SINE = 0;

  static const int SQUARE = 1;

  static const int TRIANGLE = 3;

  static const int UNSCHEDULED_STATE = 0;


  /** @domName OscillatorNode.detune */
  AudioParam get detune native "OscillatorNode_detune_Getter";


  /** @domName OscillatorNode.frequency */
  AudioParam get frequency native "OscillatorNode_frequency_Getter";


  /** @domName OscillatorNode.playbackState */
  int get playbackState native "OscillatorNode_playbackState_Getter";


  /** @domName OscillatorNode.type */
  int get type native "OscillatorNode_type_Getter";


  /** @domName OscillatorNode.type */
  void set type(int value) native "OscillatorNode_type_Setter";


  /** @domName OscillatorNode.setWaveTable */
  void setWaveTable(WaveTable waveTable) native "OscillatorNode_setWaveTable_Callback";


  /** @domName OscillatorNode.start */
  void start(num when) native "OscillatorNode_start_Callback";


  /** @domName OscillatorNode.stop */
  void stop(num when) native "OscillatorNode_stop_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLOutputElement
class OutputElement extends _Element_Merged {

  factory OutputElement() => document.$dom_createElement("output");
  OutputElement.internal(): super.internal();


  /** @domName HTMLOutputElement.defaultValue */
  String get defaultValue native "HTMLOutputElement_defaultValue_Getter";


  /** @domName HTMLOutputElement.defaultValue */
  void set defaultValue(String value) native "HTMLOutputElement_defaultValue_Setter";


  /** @domName HTMLOutputElement.form */
  FormElement get form native "HTMLOutputElement_form_Getter";


  /** @domName HTMLOutputElement.htmlFor */
  DOMSettableTokenList get htmlFor native "HTMLOutputElement_htmlFor_Getter";


  /** @domName HTMLOutputElement.htmlFor */
  void set htmlFor(DOMSettableTokenList value) native "HTMLOutputElement_htmlFor_Setter";


  /** @domName HTMLOutputElement.labels */
  List<Node> get labels native "HTMLOutputElement_labels_Getter";


  /** @domName HTMLOutputElement.name */
  String get name native "HTMLOutputElement_name_Getter";


  /** @domName HTMLOutputElement.name */
  void set name(String value) native "HTMLOutputElement_name_Setter";


  /** @domName HTMLOutputElement.type */
  String get type native "HTMLOutputElement_type_Getter";


  /** @domName HTMLOutputElement.validationMessage */
  String get validationMessage native "HTMLOutputElement_validationMessage_Getter";


  /** @domName HTMLOutputElement.validity */
  ValidityState get validity native "HTMLOutputElement_validity_Getter";


  /** @domName HTMLOutputElement.value */
  String get value native "HTMLOutputElement_value_Getter";


  /** @domName HTMLOutputElement.value */
  void set value(String value) native "HTMLOutputElement_value_Setter";


  /** @domName HTMLOutputElement.willValidate */
  bool get willValidate native "HTMLOutputElement_willValidate_Getter";


  /** @domName HTMLOutputElement.checkValidity */
  bool checkValidity() native "HTMLOutputElement_checkValidity_Callback";


  /** @domName HTMLOutputElement.setCustomValidity */
  void setCustomValidity(String error) native "HTMLOutputElement_setCustomValidity_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName OverflowEvent
class OverflowEvent extends Event {
  OverflowEvent.internal(): super.internal();

  static const int BOTH = 2;

  static const int HORIZONTAL = 0;

  static const int VERTICAL = 1;


  /** @domName OverflowEvent.horizontalOverflow */
  bool get horizontalOverflow native "OverflowEvent_horizontalOverflow_Getter";


  /** @domName OverflowEvent.orient */
  int get orient native "OverflowEvent_orient_Getter";


  /** @domName OverflowEvent.verticalOverflow */
  bool get verticalOverflow native "OverflowEvent_verticalOverflow_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName PagePopupController
class PagePopupController extends NativeFieldWrapperClass1 {
  PagePopupController.internal();


  /** @domName PagePopupController.localizeNumberString */
  String localizeNumberString(String numberString) native "PagePopupController_localizeNumberString_Callback";


  /** @domName PagePopupController.setValueAndClosePopup */
  void setValueAndClosePopup(int numberValue, String stringValue) native "PagePopupController_setValueAndClosePopup_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName PageTransitionEvent
class PageTransitionEvent extends Event {
  PageTransitionEvent.internal(): super.internal();


  /** @domName PageTransitionEvent.persisted */
  bool get persisted native "PageTransitionEvent_persisted_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName PannerNode
class PannerNode extends AudioNode {
  PannerNode.internal(): super.internal();

  static const int EQUALPOWER = 0;

  static const int EXPONENTIAL_DISTANCE = 2;

  static const int HRTF = 1;

  static const int INVERSE_DISTANCE = 1;

  static const int LINEAR_DISTANCE = 0;

  static const int SOUNDFIELD = 2;


  /** @domName PannerNode.coneGain */
  AudioGain get coneGain native "PannerNode_coneGain_Getter";


  /** @domName PannerNode.coneInnerAngle */
  num get coneInnerAngle native "PannerNode_coneInnerAngle_Getter";


  /** @domName PannerNode.coneInnerAngle */
  void set coneInnerAngle(num value) native "PannerNode_coneInnerAngle_Setter";


  /** @domName PannerNode.coneOuterAngle */
  num get coneOuterAngle native "PannerNode_coneOuterAngle_Getter";


  /** @domName PannerNode.coneOuterAngle */
  void set coneOuterAngle(num value) native "PannerNode_coneOuterAngle_Setter";


  /** @domName PannerNode.coneOuterGain */
  num get coneOuterGain native "PannerNode_coneOuterGain_Getter";


  /** @domName PannerNode.coneOuterGain */
  void set coneOuterGain(num value) native "PannerNode_coneOuterGain_Setter";


  /** @domName PannerNode.distanceGain */
  AudioGain get distanceGain native "PannerNode_distanceGain_Getter";


  /** @domName PannerNode.distanceModel */
  int get distanceModel native "PannerNode_distanceModel_Getter";


  /** @domName PannerNode.distanceModel */
  void set distanceModel(int value) native "PannerNode_distanceModel_Setter";


  /** @domName PannerNode.maxDistance */
  num get maxDistance native "PannerNode_maxDistance_Getter";


  /** @domName PannerNode.maxDistance */
  void set maxDistance(num value) native "PannerNode_maxDistance_Setter";


  /** @domName PannerNode.panningModel */
  int get panningModel native "PannerNode_panningModel_Getter";


  /** @domName PannerNode.panningModel */
  void set panningModel(int value) native "PannerNode_panningModel_Setter";


  /** @domName PannerNode.refDistance */
  num get refDistance native "PannerNode_refDistance_Getter";


  /** @domName PannerNode.refDistance */
  void set refDistance(num value) native "PannerNode_refDistance_Setter";


  /** @domName PannerNode.rolloffFactor */
  num get rolloffFactor native "PannerNode_rolloffFactor_Getter";


  /** @domName PannerNode.rolloffFactor */
  void set rolloffFactor(num value) native "PannerNode_rolloffFactor_Setter";


  /** @domName PannerNode.setOrientation */
  void setOrientation(num x, num y, num z) native "PannerNode_setOrientation_Callback";


  /** @domName PannerNode.setPosition */
  void setPosition(num x, num y, num z) native "PannerNode_setPosition_Callback";


  /** @domName PannerNode.setVelocity */
  void setVelocity(num x, num y, num z) native "PannerNode_setVelocity_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLParagraphElement
class ParagraphElement extends _Element_Merged {

  factory ParagraphElement() => document.$dom_createElement("p");
  ParagraphElement.internal(): super.internal();


  /** @domName HTMLParagraphElement.align */
  String get align native "HTMLParagraphElement_align_Getter";


  /** @domName HTMLParagraphElement.align */
  void set align(String value) native "HTMLParagraphElement_align_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLParamElement
class ParamElement extends _Element_Merged {

  factory ParamElement() => document.$dom_createElement("param");
  ParamElement.internal(): super.internal();


  /** @domName HTMLParamElement.name */
  String get name native "HTMLParamElement_name_Getter";


  /** @domName HTMLParamElement.name */
  void set name(String value) native "HTMLParamElement_name_Setter";


  /** @domName HTMLParamElement.type */
  String get type native "HTMLParamElement_type_Getter";


  /** @domName HTMLParamElement.type */
  void set type(String value) native "HTMLParamElement_type_Setter";


  /** @domName HTMLParamElement.value */
  String get value native "HTMLParamElement_value_Getter";


  /** @domName HTMLParamElement.value */
  void set value(String value) native "HTMLParamElement_value_Setter";


  /** @domName HTMLParamElement.valueType */
  String get valueType native "HTMLParamElement_valueType_Getter";


  /** @domName HTMLParamElement.valueType */
  void set valueType(String value) native "HTMLParamElement_valueType_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName PeerConnection00
class PeerConnection00 extends EventTarget {

  factory PeerConnection00(String serverConfiguration, IceCallback iceCallback) => _PeerConnection00FactoryProvider.createPeerConnection00(serverConfiguration, iceCallback);
  PeerConnection00.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  PeerConnection00Events get on =>
    new PeerConnection00Events(this);

  static const int ACTIVE = 2;

  static const int CLOSED = 3;

  static const int ICE_CHECKING = 0x300;

  static const int ICE_CLOSED = 0x700;

  static const int ICE_COMPLETED = 0x500;

  static const int ICE_CONNECTED = 0x400;

  static const int ICE_FAILED = 0x600;

  static const int ICE_GATHERING = 0x100;

  static const int ICE_WAITING = 0x200;

  static const int NEW = 0;

  static const int OPENING = 1;

  static const int SDP_ANSWER = 0x300;

  static const int SDP_OFFER = 0x100;

  static const int SDP_PRANSWER = 0x200;


  /** @domName PeerConnection00.iceState */
  int get iceState native "PeerConnection00_iceState_Getter";


  /** @domName PeerConnection00.localDescription */
  SessionDescription get localDescription native "PeerConnection00_localDescription_Getter";


  /** @domName PeerConnection00.localStreams */
  List<MediaStream> get localStreams native "PeerConnection00_localStreams_Getter";


  /** @domName PeerConnection00.readyState */
  int get readyState native "PeerConnection00_readyState_Getter";


  /** @domName PeerConnection00.remoteDescription */
  SessionDescription get remoteDescription native "PeerConnection00_remoteDescription_Getter";


  /** @domName PeerConnection00.remoteStreams */
  List<MediaStream> get remoteStreams native "PeerConnection00_remoteStreams_Getter";


  /** @domName PeerConnection00.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "PeerConnection00_addEventListener_Callback";


  /** @domName PeerConnection00.addStream */
  void addStream(MediaStream stream, [Map mediaStreamHints]) native "PeerConnection00_addStream_Callback";


  /** @domName PeerConnection00.close */
  void close() native "PeerConnection00_close_Callback";


  /** @domName PeerConnection00.createAnswer */
  SessionDescription createAnswer(String offer, [Map mediaHints]) native "PeerConnection00_createAnswer_Callback";


  /** @domName PeerConnection00.createOffer */
  SessionDescription createOffer([Map mediaHints]) native "PeerConnection00_createOffer_Callback";


  /** @domName PeerConnection00.dispatchEvent */
  bool $dom_dispatchEvent(Event event) native "PeerConnection00_dispatchEvent_Callback";


  /** @domName PeerConnection00.processIceMessage */
  void processIceMessage(IceCandidate candidate) native "PeerConnection00_processIceMessage_Callback";


  /** @domName PeerConnection00.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "PeerConnection00_removeEventListener_Callback";


  /** @domName PeerConnection00.removeStream */
  void removeStream(MediaStream stream) native "PeerConnection00_removeStream_Callback";


  /** @domName PeerConnection00.setLocalDescription */
  void setLocalDescription(int action, SessionDescription desc) native "PeerConnection00_setLocalDescription_Callback";


  /** @domName PeerConnection00.setRemoteDescription */
  void setRemoteDescription(int action, SessionDescription desc) native "PeerConnection00_setRemoteDescription_Callback";


  /** @domName PeerConnection00.startIce */
  void startIce([Map iceOptions]) native "PeerConnection00_startIce_Callback";

}

class PeerConnection00Events extends Events {
  PeerConnection00Events(EventTarget _ptr) : super(_ptr);

  EventListenerList get addStream => this['addstream'];

  EventListenerList get connecting => this['connecting'];

  EventListenerList get open => this['open'];

  EventListenerList get removeStream => this['removestream'];

  EventListenerList get stateChange => this['statechange'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Performance
class Performance extends EventTarget {
  Performance.internal(): super.internal();


  /** @domName Performance.memory */
  MemoryInfo get memory native "Performance_memory_Getter";


  /** @domName Performance.navigation */
  PerformanceNavigation get navigation native "Performance_navigation_Getter";


  /** @domName Performance.timing */
  PerformanceTiming get timing native "Performance_timing_Getter";


  /** @domName Performance.now */
  num now() native "Performance_now_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName PerformanceNavigation
class PerformanceNavigation extends NativeFieldWrapperClass1 {
  PerformanceNavigation.internal();

  static const int TYPE_BACK_FORWARD = 2;

  static const int TYPE_NAVIGATE = 0;

  static const int TYPE_RELOAD = 1;

  static const int TYPE_RESERVED = 255;


  /** @domName PerformanceNavigation.redirectCount */
  int get redirectCount native "PerformanceNavigation_redirectCount_Getter";


  /** @domName PerformanceNavigation.type */
  int get type native "PerformanceNavigation_type_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName PerformanceTiming
class PerformanceTiming extends NativeFieldWrapperClass1 {
  PerformanceTiming.internal();


  /** @domName PerformanceTiming.connectEnd */
  int get connectEnd native "PerformanceTiming_connectEnd_Getter";


  /** @domName PerformanceTiming.connectStart */
  int get connectStart native "PerformanceTiming_connectStart_Getter";


  /** @domName PerformanceTiming.domComplete */
  int get domComplete native "PerformanceTiming_domComplete_Getter";


  /** @domName PerformanceTiming.domContentLoadedEventEnd */
  int get domContentLoadedEventEnd native "PerformanceTiming_domContentLoadedEventEnd_Getter";


  /** @domName PerformanceTiming.domContentLoadedEventStart */
  int get domContentLoadedEventStart native "PerformanceTiming_domContentLoadedEventStart_Getter";


  /** @domName PerformanceTiming.domInteractive */
  int get domInteractive native "PerformanceTiming_domInteractive_Getter";


  /** @domName PerformanceTiming.domLoading */
  int get domLoading native "PerformanceTiming_domLoading_Getter";


  /** @domName PerformanceTiming.domainLookupEnd */
  int get domainLookupEnd native "PerformanceTiming_domainLookupEnd_Getter";


  /** @domName PerformanceTiming.domainLookupStart */
  int get domainLookupStart native "PerformanceTiming_domainLookupStart_Getter";


  /** @domName PerformanceTiming.fetchStart */
  int get fetchStart native "PerformanceTiming_fetchStart_Getter";


  /** @domName PerformanceTiming.loadEventEnd */
  int get loadEventEnd native "PerformanceTiming_loadEventEnd_Getter";


  /** @domName PerformanceTiming.loadEventStart */
  int get loadEventStart native "PerformanceTiming_loadEventStart_Getter";


  /** @domName PerformanceTiming.navigationStart */
  int get navigationStart native "PerformanceTiming_navigationStart_Getter";


  /** @domName PerformanceTiming.redirectEnd */
  int get redirectEnd native "PerformanceTiming_redirectEnd_Getter";


  /** @domName PerformanceTiming.redirectStart */
  int get redirectStart native "PerformanceTiming_redirectStart_Getter";


  /** @domName PerformanceTiming.requestStart */
  int get requestStart native "PerformanceTiming_requestStart_Getter";


  /** @domName PerformanceTiming.responseEnd */
  int get responseEnd native "PerformanceTiming_responseEnd_Getter";


  /** @domName PerformanceTiming.responseStart */
  int get responseStart native "PerformanceTiming_responseStart_Getter";


  /** @domName PerformanceTiming.secureConnectionStart */
  int get secureConnectionStart native "PerformanceTiming_secureConnectionStart_Getter";


  /** @domName PerformanceTiming.unloadEventEnd */
  int get unloadEventEnd native "PerformanceTiming_unloadEventEnd_Getter";


  /** @domName PerformanceTiming.unloadEventStart */
  int get unloadEventStart native "PerformanceTiming_unloadEventStart_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


class Point extends NativeFieldWrapperClass1 {
  factory Point(num x, num y) => _PointFactoryProvider.createPoint(x, y);
  Point.internal();


  /** @domName WebKitPoint.x */
  num get x native "WebKitPoint_x_Getter";


  /** @domName WebKitPoint.x */
  void set x(num value) native "WebKitPoint_x_Setter";


  /** @domName WebKitPoint.y */
  num get y native "WebKitPoint_y_Getter";


  /** @domName WebKitPoint.y */
  void set y(num value) native "WebKitPoint_y_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName PopStateEvent
class PopStateEvent extends Event {
  PopStateEvent.internal(): super.internal();


  /** @domName PopStateEvent.state */
  Object get state native "PopStateEvent_state_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void PositionCallback(Geoposition position);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName PositionError
class PositionError extends NativeFieldWrapperClass1 {
  PositionError.internal();

  static const int PERMISSION_DENIED = 1;

  static const int POSITION_UNAVAILABLE = 2;

  static const int TIMEOUT = 3;


  /** @domName PositionError.code */
  int get code native "PositionError_code_Getter";


  /** @domName PositionError.message */
  String get message native "PositionError_message_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void PositionErrorCallback(PositionError error);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLPreElement
class PreElement extends _Element_Merged {

  factory PreElement() => document.$dom_createElement("pre");
  PreElement.internal(): super.internal();


  /** @domName HTMLPreElement.width */
  int get width native "HTMLPreElement_width_Getter";


  /** @domName HTMLPreElement.width */
  void set width(int value) native "HTMLPreElement_width_Setter";


  /** @domName HTMLPreElement.wrap */
  bool get wrap native "HTMLPreElement_wrap_Getter";


  /** @domName HTMLPreElement.wrap */
  void set wrap(bool value) native "HTMLPreElement_wrap_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName ProcessingInstruction
class ProcessingInstruction extends Node {
  ProcessingInstruction.internal(): super.internal();


  /** @domName ProcessingInstruction.data */
  String get data native "ProcessingInstruction_data_Getter";


  /** @domName ProcessingInstruction.data */
  void set data(String value) native "ProcessingInstruction_data_Setter";


  /** @domName ProcessingInstruction.sheet */
  StyleSheet get sheet native "ProcessingInstruction_sheet_Getter";


  /** @domName ProcessingInstruction.target */
  String get target native "ProcessingInstruction_target_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLProgressElement
class ProgressElement extends _Element_Merged {

  factory ProgressElement() => document.$dom_createElement("progress");
  ProgressElement.internal(): super.internal();


  /** @domName HTMLProgressElement.labels */
  List<Node> get labels native "HTMLProgressElement_labels_Getter";


  /** @domName HTMLProgressElement.max */
  num get max native "HTMLProgressElement_max_Getter";


  /** @domName HTMLProgressElement.max */
  void set max(num value) native "HTMLProgressElement_max_Setter";


  /** @domName HTMLProgressElement.position */
  num get position native "HTMLProgressElement_position_Getter";


  /** @domName HTMLProgressElement.value */
  num get value native "HTMLProgressElement_value_Getter";


  /** @domName HTMLProgressElement.value */
  void set value(num value) native "HTMLProgressElement_value_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName ProgressEvent
class ProgressEvent extends Event {
  ProgressEvent.internal(): super.internal();


  /** @domName ProgressEvent.lengthComputable */
  bool get lengthComputable native "ProgressEvent_lengthComputable_Getter";


  /** @domName ProgressEvent.loaded */
  int get loaded native "ProgressEvent_loaded_Getter";


  /** @domName ProgressEvent.total */
  int get total native "ProgressEvent_total_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLQuoteElement
class QuoteElement extends _Element_Merged {
  QuoteElement.internal(): super.internal();


  /** @domName HTMLQuoteElement.cite */
  String get cite native "HTMLQuoteElement_cite_Getter";


  /** @domName HTMLQuoteElement.cite */
  void set cite(String value) native "HTMLQuoteElement_cite_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName RGBColor
class RGBColor extends NativeFieldWrapperClass1 {
  RGBColor.internal();


  /** @domName RGBColor.blue */
  CSSPrimitiveValue get blue native "RGBColor_blue_Getter";


  /** @domName RGBColor.green */
  CSSPrimitiveValue get green native "RGBColor_green_Getter";


  /** @domName RGBColor.red */
  CSSPrimitiveValue get red native "RGBColor_red_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName RTCDataChannel
class RTCDataChannel extends EventTarget {
  RTCDataChannel.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  RTCDataChannelEvents get on =>
    new RTCDataChannelEvents(this);


  /** @domName RTCDataChannel.binaryType */
  String get binaryType native "RTCDataChannel_binaryType_Getter";


  /** @domName RTCDataChannel.binaryType */
  void set binaryType(String value) native "RTCDataChannel_binaryType_Setter";


  /** @domName RTCDataChannel.bufferedAmount */
  int get bufferedAmount native "RTCDataChannel_bufferedAmount_Getter";


  /** @domName RTCDataChannel.label */
  String get label native "RTCDataChannel_label_Getter";


  /** @domName RTCDataChannel.readyState */
  String get readyState native "RTCDataChannel_readyState_Getter";


  /** @domName RTCDataChannel.reliable */
  bool get reliable native "RTCDataChannel_reliable_Getter";


  /** @domName RTCDataChannel.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "RTCDataChannel_addEventListener_Callback";


  /** @domName RTCDataChannel.close */
  void close() native "RTCDataChannel_close_Callback";


  /** @domName RTCDataChannel.dispatchEvent */
  bool $dom_dispatchEvent(Event event) native "RTCDataChannel_dispatchEvent_Callback";


  /** @domName RTCDataChannel.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "RTCDataChannel_removeEventListener_Callback";

  void send(data) {
    if ((data is ArrayBuffer || data == null)) {
      _send_1(data);
      return;
    }
    if ((data is ArrayBufferView || data == null)) {
      _send_2(data);
      return;
    }
    if ((data is Blob || data == null)) {
      _send_3(data);
      return;
    }
    if ((data is String || data == null)) {
      _send_4(data);
      return;
    }
    throw "Incorrect number or type of arguments";
  }


  /** @domName RTCDataChannel.send_1 */
  void _send_1(data) native "RTCDataChannel_send_1_Callback";


  /** @domName RTCDataChannel.send_2 */
  void _send_2(data) native "RTCDataChannel_send_2_Callback";


  /** @domName RTCDataChannel.send_3 */
  void _send_3(data) native "RTCDataChannel_send_3_Callback";


  /** @domName RTCDataChannel.send_4 */
  void _send_4(data) native "RTCDataChannel_send_4_Callback";

}

class RTCDataChannelEvents extends Events {
  RTCDataChannelEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get close => this['close'];

  EventListenerList get error => this['error'];

  EventListenerList get message => this['message'];

  EventListenerList get open => this['open'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName RTCDataChannelEvent
class RTCDataChannelEvent extends Event {
  RTCDataChannelEvent.internal(): super.internal();


  /** @domName RTCDataChannelEvent.channel */
  RTCDataChannel get channel native "RTCDataChannelEvent_channel_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void RTCErrorCallback(String errorInformation);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName RTCIceCandidate
class RTCIceCandidate extends NativeFieldWrapperClass1 {

  factory RTCIceCandidate(Map dictionary) => _RTCIceCandidateFactoryProvider.createRTCIceCandidate(dictionary);
  RTCIceCandidate.internal();


  /** @domName RTCIceCandidate.candidate */
  String get candidate native "RTCIceCandidate_candidate_Getter";


  /** @domName RTCIceCandidate.sdpMLineIndex */
  int get sdpMLineIndex native "RTCIceCandidate_sdpMLineIndex_Getter";


  /** @domName RTCIceCandidate.sdpMid */
  String get sdpMid native "RTCIceCandidate_sdpMid_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName RTCIceCandidateEvent
class RTCIceCandidateEvent extends Event {
  RTCIceCandidateEvent.internal(): super.internal();


  /** @domName RTCIceCandidateEvent.candidate */
  RTCIceCandidate get candidate native "RTCIceCandidateEvent_candidate_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName RTCPeerConnection
class RTCPeerConnection extends EventTarget {

  factory RTCPeerConnection(Map rtcIceServers, [Map mediaConstraints]) {
    if (!?mediaConstraints) {
      return _RTCPeerConnectionFactoryProvider.createRTCPeerConnection(rtcIceServers);
    }
    return _RTCPeerConnectionFactoryProvider.createRTCPeerConnection(rtcIceServers, mediaConstraints);
  }
  RTCPeerConnection.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  RTCPeerConnectionEvents get on =>
    new RTCPeerConnectionEvents(this);


  /** @domName RTCPeerConnection.iceState */
  String get iceState native "RTCPeerConnection_iceState_Getter";


  /** @domName RTCPeerConnection.localDescription */
  RTCSessionDescription get localDescription native "RTCPeerConnection_localDescription_Getter";


  /** @domName RTCPeerConnection.localStreams */
  List<MediaStream> get localStreams native "RTCPeerConnection_localStreams_Getter";


  /** @domName RTCPeerConnection.readyState */
  String get readyState native "RTCPeerConnection_readyState_Getter";


  /** @domName RTCPeerConnection.remoteDescription */
  RTCSessionDescription get remoteDescription native "RTCPeerConnection_remoteDescription_Getter";


  /** @domName RTCPeerConnection.remoteStreams */
  List<MediaStream> get remoteStreams native "RTCPeerConnection_remoteStreams_Getter";


  /** @domName RTCPeerConnection.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "RTCPeerConnection_addEventListener_Callback";


  /** @domName RTCPeerConnection.addIceCandidate */
  void addIceCandidate(RTCIceCandidate candidate) native "RTCPeerConnection_addIceCandidate_Callback";


  /** @domName RTCPeerConnection.addStream */
  void addStream(MediaStream stream, [Map mediaConstraints]) native "RTCPeerConnection_addStream_Callback";


  /** @domName RTCPeerConnection.close */
  void close() native "RTCPeerConnection_close_Callback";


  /** @domName RTCPeerConnection.createAnswer */
  void createAnswer(RTCSessionDescriptionCallback successCallback, [RTCErrorCallback failureCallback, Map mediaConstraints]) native "RTCPeerConnection_createAnswer_Callback";


  /** @domName RTCPeerConnection.createDataChannel */
  RTCDataChannel createDataChannel(String label, [Map options]) native "RTCPeerConnection_createDataChannel_Callback";


  /** @domName RTCPeerConnection.createOffer */
  void createOffer(RTCSessionDescriptionCallback successCallback, [RTCErrorCallback failureCallback, Map mediaConstraints]) native "RTCPeerConnection_createOffer_Callback";


  /** @domName RTCPeerConnection.dispatchEvent */
  bool $dom_dispatchEvent(Event event) native "RTCPeerConnection_dispatchEvent_Callback";


  /** @domName RTCPeerConnection.getStats */
  void getStats(RTCStatsCallback successCallback, MediaStreamTrack selector) native "RTCPeerConnection_getStats_Callback";


  /** @domName RTCPeerConnection.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "RTCPeerConnection_removeEventListener_Callback";


  /** @domName RTCPeerConnection.removeStream */
  void removeStream(MediaStream stream) native "RTCPeerConnection_removeStream_Callback";


  /** @domName RTCPeerConnection.setLocalDescription */
  void setLocalDescription(RTCSessionDescription description, [VoidCallback successCallback, RTCErrorCallback failureCallback]) native "RTCPeerConnection_setLocalDescription_Callback";


  /** @domName RTCPeerConnection.setRemoteDescription */
  void setRemoteDescription(RTCSessionDescription description, [VoidCallback successCallback, RTCErrorCallback failureCallback]) native "RTCPeerConnection_setRemoteDescription_Callback";


  /** @domName RTCPeerConnection.updateIce */
  void updateIce([Map configuration, Map mediaConstraints]) native "RTCPeerConnection_updateIce_Callback";

}

class RTCPeerConnectionEvents extends Events {
  RTCPeerConnectionEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get addStream => this['addstream'];

  EventListenerList get iceCandidate => this['icecandidate'];

  EventListenerList get iceChange => this['icechange'];

  EventListenerList get negotiationNeeded => this['negotiationneeded'];

  EventListenerList get open => this['open'];

  EventListenerList get removeStream => this['removestream'];

  EventListenerList get stateChange => this['statechange'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName RTCSessionDescription
class RTCSessionDescription extends NativeFieldWrapperClass1 {

  factory RTCSessionDescription(Map dictionary) => _RTCSessionDescriptionFactoryProvider.createRTCSessionDescription(dictionary);
  RTCSessionDescription.internal();


  /** @domName RTCSessionDescription.sdp */
  String get sdp native "RTCSessionDescription_sdp_Getter";


  /** @domName RTCSessionDescription.sdp */
  void set sdp(String value) native "RTCSessionDescription_sdp_Setter";


  /** @domName RTCSessionDescription.type */
  String get type native "RTCSessionDescription_type_Getter";


  /** @domName RTCSessionDescription.type */
  void set type(String value) native "RTCSessionDescription_type_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void RTCSessionDescriptionCallback(RTCSessionDescription sdp);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void RTCStatsCallback(RTCStatsResponse response);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName RTCStatsElement
class RTCStatsElement extends NativeFieldWrapperClass1 {
  RTCStatsElement.internal();


  /** @domName RTCStatsElement.timestamp */
  Date get timestamp native "RTCStatsElement_timestamp_Getter";


  /** @domName RTCStatsElement.stat */
  String stat(String name) native "RTCStatsElement_stat_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName RTCStatsReport
class RTCStatsReport extends NativeFieldWrapperClass1 {
  RTCStatsReport.internal();


  /** @domName RTCStatsReport.local */
  RTCStatsElement get local native "RTCStatsReport_local_Getter";


  /** @domName RTCStatsReport.remote */
  RTCStatsElement get remote native "RTCStatsReport_remote_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName RTCStatsResponse
class RTCStatsResponse extends NativeFieldWrapperClass1 {
  RTCStatsResponse.internal();


  /** @domName RTCStatsResponse.result */
  List<RTCStatsReport> result() native "RTCStatsResponse_result_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName RadioNodeList
class RadioNodeList extends _NodeList {
  RadioNodeList.internal(): super.internal();


  /** @domName RadioNodeList.value */
  String get value native "RadioNodeList_value_Getter";


  /** @domName RadioNodeList.value */
  void set value(String value) native "RadioNodeList_value_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Range
class Range extends NativeFieldWrapperClass1 {
  Range.internal();

  static const int END_TO_END = 2;

  static const int END_TO_START = 3;

  static const int NODE_AFTER = 1;

  static const int NODE_BEFORE = 0;

  static const int NODE_BEFORE_AND_AFTER = 2;

  static const int NODE_INSIDE = 3;

  static const int START_TO_END = 1;

  static const int START_TO_START = 0;


  /** @domName Range.collapsed */
  bool get collapsed native "Range_collapsed_Getter";


  /** @domName Range.commonAncestorContainer */
  Node get commonAncestorContainer native "Range_commonAncestorContainer_Getter";


  /** @domName Range.endContainer */
  Node get endContainer native "Range_endContainer_Getter";


  /** @domName Range.endOffset */
  int get endOffset native "Range_endOffset_Getter";


  /** @domName Range.startContainer */
  Node get startContainer native "Range_startContainer_Getter";


  /** @domName Range.startOffset */
  int get startOffset native "Range_startOffset_Getter";


  /** @domName Range.cloneContents */
  DocumentFragment cloneContents() native "Range_cloneContents_Callback";


  /** @domName Range.cloneRange */
  Range cloneRange() native "Range_cloneRange_Callback";


  /** @domName Range.collapse */
  void collapse(bool toStart) native "Range_collapse_Callback";


  /** @domName Range.compareNode */
  int compareNode(Node refNode) native "Range_compareNode_Callback";


  /** @domName Range.comparePoint */
  int comparePoint(Node refNode, int offset) native "Range_comparePoint_Callback";


  /** @domName Range.createContextualFragment */
  DocumentFragment createContextualFragment(String html) native "Range_createContextualFragment_Callback";


  /** @domName Range.deleteContents */
  void deleteContents() native "Range_deleteContents_Callback";


  /** @domName Range.detach */
  void detach() native "Range_detach_Callback";


  /** @domName Range.expand */
  void expand(String unit) native "Range_expand_Callback";


  /** @domName Range.extractContents */
  DocumentFragment extractContents() native "Range_extractContents_Callback";


  /** @domName Range.getBoundingClientRect */
  ClientRect getBoundingClientRect() native "Range_getBoundingClientRect_Callback";


  /** @domName Range.getClientRects */
  List<ClientRect> getClientRects() native "Range_getClientRects_Callback";


  /** @domName Range.insertNode */
  void insertNode(Node newNode) native "Range_insertNode_Callback";


  /** @domName Range.intersectsNode */
  bool intersectsNode(Node refNode) native "Range_intersectsNode_Callback";


  /** @domName Range.isPointInRange */
  bool isPointInRange(Node refNode, int offset) native "Range_isPointInRange_Callback";


  /** @domName Range.selectNode */
  void selectNode(Node refNode) native "Range_selectNode_Callback";


  /** @domName Range.selectNodeContents */
  void selectNodeContents(Node refNode) native "Range_selectNodeContents_Callback";


  /** @domName Range.setEnd */
  void setEnd(Node refNode, int offset) native "Range_setEnd_Callback";


  /** @domName Range.setEndAfter */
  void setEndAfter(Node refNode) native "Range_setEndAfter_Callback";


  /** @domName Range.setEndBefore */
  void setEndBefore(Node refNode) native "Range_setEndBefore_Callback";


  /** @domName Range.setStart */
  void setStart(Node refNode, int offset) native "Range_setStart_Callback";


  /** @domName Range.setStartAfter */
  void setStartAfter(Node refNode) native "Range_setStartAfter_Callback";


  /** @domName Range.setStartBefore */
  void setStartBefore(Node refNode) native "Range_setStartBefore_Callback";


  /** @domName Range.surroundContents */
  void surroundContents(Node newParent) native "Range_surroundContents_Callback";


  /** @domName Range.toString */
  String toString() native "Range_toString_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName RangeException
class RangeException extends NativeFieldWrapperClass1 {
  RangeException.internal();

  static const int BAD_BOUNDARYPOINTS_ERR = 1;

  static const int INVALID_NODE_TYPE_ERR = 2;


  /** @domName RangeException.code */
  int get code native "RangeException_code_Getter";


  /** @domName RangeException.message */
  String get message native "RangeException_message_Getter";


  /** @domName RangeException.name */
  String get name native "RangeException_name_Getter";


  /** @domName RangeException.toString */
  String toString() native "RangeException_toString_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Rect
class Rect extends NativeFieldWrapperClass1 {
  Rect.internal();


  /** @domName Rect.bottom */
  CSSPrimitiveValue get bottom native "Rect_bottom_Getter";


  /** @domName Rect.left */
  CSSPrimitiveValue get left native "Rect_left_Getter";


  /** @domName Rect.right */
  CSSPrimitiveValue get right native "Rect_right_Getter";


  /** @domName Rect.top */
  CSSPrimitiveValue get top native "Rect_top_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void RequestAnimationFrameCallback(num highResTime);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SQLError
class SQLError extends NativeFieldWrapperClass1 {
  SQLError.internal();

  static const int CONSTRAINT_ERR = 6;

  static const int DATABASE_ERR = 1;

  static const int QUOTA_ERR = 4;

  static const int SYNTAX_ERR = 5;

  static const int TIMEOUT_ERR = 7;

  static const int TOO_LARGE_ERR = 3;

  static const int UNKNOWN_ERR = 0;

  static const int VERSION_ERR = 2;


  /** @domName SQLError.code */
  int get code native "SQLError_code_Getter";


  /** @domName SQLError.message */
  String get message native "SQLError_message_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SQLException
class SQLException extends NativeFieldWrapperClass1 {
  SQLException.internal();

  static const int CONSTRAINT_ERR = 6;

  static const int DATABASE_ERR = 1;

  static const int QUOTA_ERR = 4;

  static const int SYNTAX_ERR = 5;

  static const int TIMEOUT_ERR = 7;

  static const int TOO_LARGE_ERR = 3;

  static const int UNKNOWN_ERR = 0;

  static const int VERSION_ERR = 2;


  /** @domName SQLException.code */
  int get code native "SQLException_code_Getter";


  /** @domName SQLException.message */
  String get message native "SQLException_message_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SQLResultSet
class SQLResultSet extends NativeFieldWrapperClass1 {
  SQLResultSet.internal();


  /** @domName SQLResultSet.insertId */
  int get insertId native "SQLResultSet_insertId_Getter";


  /** @domName SQLResultSet.rows */
  SQLResultSetRowList get rows native "SQLResultSet_rows_Getter";


  /** @domName SQLResultSet.rowsAffected */
  int get rowsAffected native "SQLResultSet_rowsAffected_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SQLResultSetRowList
class SQLResultSetRowList extends NativeFieldWrapperClass1 implements List<Map> {
  SQLResultSetRowList.internal();


  /** @domName SQLResultSetRowList.length */
  int get length native "SQLResultSetRowList_length_Getter";

  Map operator[](int index) native "SQLResultSetRowList_item_Callback";

  void operator[]=(int index, Map value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Map> mixins.
  // Map is the element type.

  // From Iterable<Map>:

  Iterator<Map> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Map>(this);
  }

  // From Collection<Map>:

  void add(Map value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(Map value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<Map> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(Map element) => _Collections.contains(this, element);

  void forEach(void f(Map element)) => _Collections.forEach(this, f);

  Collection map(f(Map element)) => _Collections.map(this, [], f);

  Collection<Map> filter(bool f(Map element)) =>
     _Collections.filter(this, <Map>[], f);

  bool every(bool f(Map element)) => _Collections.every(this, f);

  bool some(bool f(Map element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<Map>:

  void sort([Comparator<Map> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Map element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Map element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  Map get first => this[0];

  Map get last => this[length - 1];

  Map removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<Map> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [Map initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<Map> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <Map>[]);

  // -- end List<Map> mixins.


  /** @domName SQLResultSetRowList.item */
  Map item(int index) native "SQLResultSetRowList_item_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void SQLStatementCallback(SQLTransaction transaction, SQLResultSet resultSet);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void SQLStatementErrorCallback(SQLTransaction transaction, SQLError error);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SQLTransaction
class SQLTransaction extends NativeFieldWrapperClass1 {
  SQLTransaction.internal();


  /** @domName SQLTransaction.executeSql */
  void executeSql(String sqlStatement, List arguments, [SQLStatementCallback callback, SQLStatementErrorCallback errorCallback]) native "SQLTransaction_executeSql_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void SQLTransactionCallback(SQLTransaction transaction);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void SQLTransactionErrorCallback(SQLError error);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SQLTransactionSync
class SQLTransactionSync extends NativeFieldWrapperClass1 {
  SQLTransactionSync.internal();


  /** @domName SQLTransactionSync.executeSql */
  SQLResultSet executeSql(String sqlStatement, List arguments) native "SQLTransactionSync_executeSql_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void SQLTransactionSyncCallback(SQLTransactionSync transaction);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Screen
class Screen extends NativeFieldWrapperClass1 {
  Screen.internal();


  /** @domName Screen.availHeight */
  int get availHeight native "Screen_availHeight_Getter";


  /** @domName Screen.availLeft */
  int get availLeft native "Screen_availLeft_Getter";


  /** @domName Screen.availTop */
  int get availTop native "Screen_availTop_Getter";


  /** @domName Screen.availWidth */
  int get availWidth native "Screen_availWidth_Getter";


  /** @domName Screen.colorDepth */
  int get colorDepth native "Screen_colorDepth_Getter";


  /** @domName Screen.height */
  int get height native "Screen_height_Getter";


  /** @domName Screen.pixelDepth */
  int get pixelDepth native "Screen_pixelDepth_Getter";


  /** @domName Screen.width */
  int get width native "Screen_width_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLScriptElement
class ScriptElement extends _Element_Merged {

  factory ScriptElement() => document.$dom_createElement("script");
  ScriptElement.internal(): super.internal();


  /** @domName HTMLScriptElement.async */
  bool get async native "HTMLScriptElement_async_Getter";


  /** @domName HTMLScriptElement.async */
  void set async(bool value) native "HTMLScriptElement_async_Setter";


  /** @domName HTMLScriptElement.charset */
  String get charset native "HTMLScriptElement_charset_Getter";


  /** @domName HTMLScriptElement.charset */
  void set charset(String value) native "HTMLScriptElement_charset_Setter";


  /** @domName HTMLScriptElement.crossOrigin */
  String get crossOrigin native "HTMLScriptElement_crossOrigin_Getter";


  /** @domName HTMLScriptElement.crossOrigin */
  void set crossOrigin(String value) native "HTMLScriptElement_crossOrigin_Setter";


  /** @domName HTMLScriptElement.defer */
  bool get defer native "HTMLScriptElement_defer_Getter";


  /** @domName HTMLScriptElement.defer */
  void set defer(bool value) native "HTMLScriptElement_defer_Setter";


  /** @domName HTMLScriptElement.event */
  String get event native "HTMLScriptElement_event_Getter";


  /** @domName HTMLScriptElement.event */
  void set event(String value) native "HTMLScriptElement_event_Setter";


  /** @domName HTMLScriptElement.htmlFor */
  String get htmlFor native "HTMLScriptElement_htmlFor_Getter";


  /** @domName HTMLScriptElement.htmlFor */
  void set htmlFor(String value) native "HTMLScriptElement_htmlFor_Setter";


  /** @domName HTMLScriptElement.src */
  String get src native "HTMLScriptElement_src_Getter";


  /** @domName HTMLScriptElement.src */
  void set src(String value) native "HTMLScriptElement_src_Setter";


  /** @domName HTMLScriptElement.type */
  String get type native "HTMLScriptElement_type_Getter";


  /** @domName HTMLScriptElement.type */
  void set type(String value) native "HTMLScriptElement_type_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName ScriptProcessorNode
class ScriptProcessorNode extends AudioNode implements EventTarget {
  ScriptProcessorNode.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  ScriptProcessorNodeEvents get on =>
    new ScriptProcessorNodeEvents(this);


  /** @domName ScriptProcessorNode.bufferSize */
  int get bufferSize native "ScriptProcessorNode_bufferSize_Getter";

}

class ScriptProcessorNodeEvents extends Events {
  ScriptProcessorNodeEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get audioProcess => this['audioprocess'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName ScriptProfile
class ScriptProfile extends NativeFieldWrapperClass1 {
  ScriptProfile.internal();


  /** @domName ScriptProfile.head */
  ScriptProfileNode get head native "ScriptProfile_head_Getter";


  /** @domName ScriptProfile.title */
  String get title native "ScriptProfile_title_Getter";


  /** @domName ScriptProfile.uid */
  int get uid native "ScriptProfile_uid_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName ScriptProfileNode
class ScriptProfileNode extends NativeFieldWrapperClass1 {
  ScriptProfileNode.internal();


  /** @domName ScriptProfileNode.callUID */
  int get callUID native "ScriptProfileNode_callUID_Getter";


  /** @domName ScriptProfileNode.functionName */
  String get functionName native "ScriptProfileNode_functionName_Getter";


  /** @domName ScriptProfileNode.lineNumber */
  int get lineNumber native "ScriptProfileNode_lineNumber_Getter";


  /** @domName ScriptProfileNode.numberOfCalls */
  int get numberOfCalls native "ScriptProfileNode_numberOfCalls_Getter";


  /** @domName ScriptProfileNode.selfTime */
  num get selfTime native "ScriptProfileNode_selfTime_Getter";


  /** @domName ScriptProfileNode.totalTime */
  num get totalTime native "ScriptProfileNode_totalTime_Getter";


  /** @domName ScriptProfileNode.url */
  String get url native "ScriptProfileNode_url_Getter";


  /** @domName ScriptProfileNode.visible */
  bool get visible native "ScriptProfileNode_visible_Getter";


  /** @domName ScriptProfileNode.children */
  List<ScriptProfileNode> children() native "ScriptProfileNode_children_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLSelectElement
class SelectElement extends _Element_Merged {

  factory SelectElement() => document.$dom_createElement("select");
  SelectElement.internal(): super.internal();


  /** @domName HTMLSelectElement.autofocus */
  bool get autofocus native "HTMLSelectElement_autofocus_Getter";


  /** @domName HTMLSelectElement.autofocus */
  void set autofocus(bool value) native "HTMLSelectElement_autofocus_Setter";


  /** @domName HTMLSelectElement.disabled */
  bool get disabled native "HTMLSelectElement_disabled_Getter";


  /** @domName HTMLSelectElement.disabled */
  void set disabled(bool value) native "HTMLSelectElement_disabled_Setter";


  /** @domName HTMLSelectElement.form */
  FormElement get form native "HTMLSelectElement_form_Getter";


  /** @domName HTMLSelectElement.labels */
  List<Node> get labels native "HTMLSelectElement_labels_Getter";


  /** @domName HTMLSelectElement.length */
  int get length native "HTMLSelectElement_length_Getter";


  /** @domName HTMLSelectElement.length */
  void set length(int value) native "HTMLSelectElement_length_Setter";


  /** @domName HTMLSelectElement.multiple */
  bool get multiple native "HTMLSelectElement_multiple_Getter";


  /** @domName HTMLSelectElement.multiple */
  void set multiple(bool value) native "HTMLSelectElement_multiple_Setter";


  /** @domName HTMLSelectElement.name */
  String get name native "HTMLSelectElement_name_Getter";


  /** @domName HTMLSelectElement.name */
  void set name(String value) native "HTMLSelectElement_name_Setter";


  /** @domName HTMLSelectElement.options */
  HTMLOptionsCollection get options native "HTMLSelectElement_options_Getter";


  /** @domName HTMLSelectElement.required */
  bool get required native "HTMLSelectElement_required_Getter";


  /** @domName HTMLSelectElement.required */
  void set required(bool value) native "HTMLSelectElement_required_Setter";


  /** @domName HTMLSelectElement.selectedIndex */
  int get selectedIndex native "HTMLSelectElement_selectedIndex_Getter";


  /** @domName HTMLSelectElement.selectedIndex */
  void set selectedIndex(int value) native "HTMLSelectElement_selectedIndex_Setter";


  /** @domName HTMLSelectElement.selectedOptions */
  HTMLCollection get selectedOptions native "HTMLSelectElement_selectedOptions_Getter";


  /** @domName HTMLSelectElement.size */
  int get size native "HTMLSelectElement_size_Getter";


  /** @domName HTMLSelectElement.size */
  void set size(int value) native "HTMLSelectElement_size_Setter";


  /** @domName HTMLSelectElement.type */
  String get type native "HTMLSelectElement_type_Getter";


  /** @domName HTMLSelectElement.validationMessage */
  String get validationMessage native "HTMLSelectElement_validationMessage_Getter";


  /** @domName HTMLSelectElement.validity */
  ValidityState get validity native "HTMLSelectElement_validity_Getter";


  /** @domName HTMLSelectElement.value */
  String get value native "HTMLSelectElement_value_Getter";


  /** @domName HTMLSelectElement.value */
  void set value(String value) native "HTMLSelectElement_value_Setter";


  /** @domName HTMLSelectElement.willValidate */
  bool get willValidate native "HTMLSelectElement_willValidate_Getter";


  /** @domName HTMLSelectElement.checkValidity */
  bool checkValidity() native "HTMLSelectElement_checkValidity_Callback";


  /** @domName HTMLSelectElement.item */
  Node item(int index) native "HTMLSelectElement_item_Callback";


  /** @domName HTMLSelectElement.namedItem */
  Node namedItem(String name) native "HTMLSelectElement_namedItem_Callback";


  /** @domName HTMLSelectElement.setCustomValidity */
  void setCustomValidity(String error) native "HTMLSelectElement_setCustomValidity_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SessionDescription
class SessionDescription extends NativeFieldWrapperClass1 {

  factory SessionDescription(String sdp) => _SessionDescriptionFactoryProvider.createSessionDescription(sdp);
  SessionDescription.internal();


  /** @domName SessionDescription.addCandidate */
  void addCandidate(IceCandidate candidate) native "SessionDescription_addCandidate_Callback";


  /** @domName SessionDescription.toSdp */
  String toSdp() native "SessionDescription_toSdp_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLShadowElement
class ShadowElement extends _Element_Merged {
  ShadowElement.internal(): super.internal();


  /** @domName HTMLShadowElement.resetStyleInheritance */
  bool get resetStyleInheritance native "HTMLShadowElement_resetStyleInheritance_Getter";


  /** @domName HTMLShadowElement.resetStyleInheritance */
  void set resetStyleInheritance(bool value) native "HTMLShadowElement_resetStyleInheritance_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


class ShadowRoot extends DocumentFragment {

  factory ShadowRoot(Element host) => _ShadowRootFactoryProvider.createShadowRoot(host);
  ShadowRoot.internal(): super.internal();


  /** @domName ShadowRoot.activeElement */
  Element get activeElement native "ShadowRoot_activeElement_Getter";


  /** @domName ShadowRoot.applyAuthorStyles */
  bool get applyAuthorStyles native "ShadowRoot_applyAuthorStyles_Getter";


  /** @domName ShadowRoot.applyAuthorStyles */
  void set applyAuthorStyles(bool value) native "ShadowRoot_applyAuthorStyles_Setter";


  /** @domName ShadowRoot.innerHTML */
  String get innerHTML native "ShadowRoot_innerHTML_Getter";


  /** @domName ShadowRoot.innerHTML */
  void set innerHTML(String value) native "ShadowRoot_innerHTML_Setter";


  /** @domName ShadowRoot.resetStyleInheritance */
  bool get resetStyleInheritance native "ShadowRoot_resetStyleInheritance_Getter";


  /** @domName ShadowRoot.resetStyleInheritance */
  void set resetStyleInheritance(bool value) native "ShadowRoot_resetStyleInheritance_Setter";


  /** @domName ShadowRoot.cloneNode */
  Node clone(bool deep) native "ShadowRoot_cloneNode_Callback";


  /** @domName ShadowRoot.getElementById */
  Element $dom_getElementById(String elementId) native "ShadowRoot_getElementById_Callback";


  /** @domName ShadowRoot.getElementsByClassName */
  List<Node> $dom_getElementsByClassName(String className) native "ShadowRoot_getElementsByClassName_Callback";


  /** @domName ShadowRoot.getElementsByTagName */
  List<Node> $dom_getElementsByTagName(String tagName) native "ShadowRoot_getElementsByTagName_Callback";


  /** @domName ShadowRoot.getSelection */
  DOMSelection getSelection() native "ShadowRoot_getSelection_Callback";

  static bool get supported => _Utils.shadowRootSupported(window.document);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SharedWorker
class SharedWorker extends AbstractWorker {

  factory SharedWorker(String scriptURL, [String name]) {
    if (!?name) {
      return _SharedWorkerFactoryProvider.createSharedWorker(scriptURL);
    }
    return _SharedWorkerFactoryProvider.createSharedWorker(scriptURL, name);
  }
  SharedWorker.internal(): super.internal();


  /** @domName SharedWorker.port */
  MessagePort get port native "SharedWorker_port_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SharedWorkerContext
class SharedWorkerContext extends WorkerContext {
  SharedWorkerContext.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  SharedWorkerContextEvents get on =>
    new SharedWorkerContextEvents(this);


  /** @domName SharedWorkerContext.name */
  String get name native "SharedWorkerContext_name_Getter";

}

class SharedWorkerContextEvents extends WorkerContextEvents {
  SharedWorkerContextEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get connect => this['connect'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SourceBuffer
class SourceBuffer extends NativeFieldWrapperClass1 {
  SourceBuffer.internal();


  /** @domName SourceBuffer.buffered */
  TimeRanges get buffered native "SourceBuffer_buffered_Getter";


  /** @domName SourceBuffer.timestampOffset */
  num get timestampOffset native "SourceBuffer_timestampOffset_Getter";


  /** @domName SourceBuffer.timestampOffset */
  void set timestampOffset(num value) native "SourceBuffer_timestampOffset_Setter";


  /** @domName SourceBuffer.abort */
  void abort() native "SourceBuffer_abort_Callback";


  /** @domName SourceBuffer.append */
  void append(Uint8Array data) native "SourceBuffer_append_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SourceBufferList
class SourceBufferList extends EventTarget implements List<SourceBuffer> {
  SourceBufferList.internal(): super.internal();


  /** @domName SourceBufferList.length */
  int get length native "SourceBufferList_length_Getter";

  SourceBuffer operator[](int index) native "SourceBufferList_item_Callback";

  void operator[]=(int index, SourceBuffer value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<SourceBuffer> mixins.
  // SourceBuffer is the element type.

  // From Iterable<SourceBuffer>:

  Iterator<SourceBuffer> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<SourceBuffer>(this);
  }

  // From Collection<SourceBuffer>:

  void add(SourceBuffer value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(SourceBuffer value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<SourceBuffer> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(SourceBuffer element) => _Collections.contains(this, element);

  void forEach(void f(SourceBuffer element)) => _Collections.forEach(this, f);

  Collection map(f(SourceBuffer element)) => _Collections.map(this, [], f);

  Collection<SourceBuffer> filter(bool f(SourceBuffer element)) =>
     _Collections.filter(this, <SourceBuffer>[], f);

  bool every(bool f(SourceBuffer element)) => _Collections.every(this, f);

  bool some(bool f(SourceBuffer element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<SourceBuffer>:

  void sort([Comparator<SourceBuffer> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(SourceBuffer element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(SourceBuffer element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  SourceBuffer get first => this[0];

  SourceBuffer get last => this[length - 1];

  SourceBuffer removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<SourceBuffer> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [SourceBuffer initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<SourceBuffer> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <SourceBuffer>[]);

  // -- end List<SourceBuffer> mixins.


  /** @domName SourceBufferList.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "SourceBufferList_addEventListener_Callback";


  /** @domName SourceBufferList.dispatchEvent */
  bool $dom_dispatchEvent(Event event) native "SourceBufferList_dispatchEvent_Callback";


  /** @domName SourceBufferList.item */
  SourceBuffer item(int index) native "SourceBufferList_item_Callback";


  /** @domName SourceBufferList.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "SourceBufferList_removeEventListener_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLSourceElement
class SourceElement extends _Element_Merged {

  factory SourceElement() => document.$dom_createElement("source");
  SourceElement.internal(): super.internal();


  /** @domName HTMLSourceElement.media */
  String get media native "HTMLSourceElement_media_Getter";


  /** @domName HTMLSourceElement.media */
  void set media(String value) native "HTMLSourceElement_media_Setter";


  /** @domName HTMLSourceElement.src */
  String get src native "HTMLSourceElement_src_Getter";


  /** @domName HTMLSourceElement.src */
  void set src(String value) native "HTMLSourceElement_src_Setter";


  /** @domName HTMLSourceElement.type */
  String get type native "HTMLSourceElement_type_Getter";


  /** @domName HTMLSourceElement.type */
  void set type(String value) native "HTMLSourceElement_type_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLSpanElement
class SpanElement extends _Element_Merged {

  factory SpanElement() => document.$dom_createElement("span");
  SpanElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SpeechGrammar
class SpeechGrammar extends NativeFieldWrapperClass1 {

  factory SpeechGrammar() => _SpeechGrammarFactoryProvider.createSpeechGrammar();
  SpeechGrammar.internal();


  /** @domName SpeechGrammar.src */
  String get src native "SpeechGrammar_src_Getter";


  /** @domName SpeechGrammar.src */
  void set src(String value) native "SpeechGrammar_src_Setter";


  /** @domName SpeechGrammar.weight */
  num get weight native "SpeechGrammar_weight_Getter";


  /** @domName SpeechGrammar.weight */
  void set weight(num value) native "SpeechGrammar_weight_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SpeechGrammarList
class SpeechGrammarList extends NativeFieldWrapperClass1 implements List<SpeechGrammar> {

  factory SpeechGrammarList() => _SpeechGrammarListFactoryProvider.createSpeechGrammarList();
  SpeechGrammarList.internal();


  /** @domName SpeechGrammarList.length */
  int get length native "SpeechGrammarList_length_Getter";

  SpeechGrammar operator[](int index) native "SpeechGrammarList_item_Callback";

  void operator[]=(int index, SpeechGrammar value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<SpeechGrammar> mixins.
  // SpeechGrammar is the element type.

  // From Iterable<SpeechGrammar>:

  Iterator<SpeechGrammar> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<SpeechGrammar>(this);
  }

  // From Collection<SpeechGrammar>:

  void add(SpeechGrammar value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(SpeechGrammar value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<SpeechGrammar> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(SpeechGrammar element) => _Collections.contains(this, element);

  void forEach(void f(SpeechGrammar element)) => _Collections.forEach(this, f);

  Collection map(f(SpeechGrammar element)) => _Collections.map(this, [], f);

  Collection<SpeechGrammar> filter(bool f(SpeechGrammar element)) =>
     _Collections.filter(this, <SpeechGrammar>[], f);

  bool every(bool f(SpeechGrammar element)) => _Collections.every(this, f);

  bool some(bool f(SpeechGrammar element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<SpeechGrammar>:

  void sort([Comparator<SpeechGrammar> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(SpeechGrammar element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(SpeechGrammar element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  SpeechGrammar get first => this[0];

  SpeechGrammar get last => this[length - 1];

  SpeechGrammar removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<SpeechGrammar> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [SpeechGrammar initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<SpeechGrammar> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <SpeechGrammar>[]);

  // -- end List<SpeechGrammar> mixins.

  void addFromString(/*DOMString*/ string, [/*float*/ weight]) {
    if (?weight) {
      _addFromString_1(string, weight);
      return;
    }
    _addFromString_2(string);
  }


  /** @domName SpeechGrammarList.addFromString_1 */
  void _addFromString_1(string, weight) native "SpeechGrammarList_addFromString_1_Callback";


  /** @domName SpeechGrammarList.addFromString_2 */
  void _addFromString_2(string) native "SpeechGrammarList_addFromString_2_Callback";

  void addFromUri(/*DOMString*/ src, [/*float*/ weight]) {
    if (?weight) {
      _addFromUri_1(src, weight);
      return;
    }
    _addFromUri_2(src);
  }


  /** @domName SpeechGrammarList.addFromUri_1 */
  void _addFromUri_1(src, weight) native "SpeechGrammarList_addFromUri_1_Callback";


  /** @domName SpeechGrammarList.addFromUri_2 */
  void _addFromUri_2(src) native "SpeechGrammarList_addFromUri_2_Callback";


  /** @domName SpeechGrammarList.item */
  SpeechGrammar item(int index) native "SpeechGrammarList_item_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SpeechInputEvent
class SpeechInputEvent extends Event {
  SpeechInputEvent.internal(): super.internal();


  /** @domName SpeechInputEvent.results */
  List<SpeechInputResult> get results native "SpeechInputEvent_results_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SpeechInputResult
class SpeechInputResult extends NativeFieldWrapperClass1 {
  SpeechInputResult.internal();


  /** @domName SpeechInputResult.confidence */
  num get confidence native "SpeechInputResult_confidence_Getter";


  /** @domName SpeechInputResult.utterance */
  String get utterance native "SpeechInputResult_utterance_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SpeechRecognition
class SpeechRecognition extends EventTarget {

  factory SpeechRecognition() => _SpeechRecognitionFactoryProvider.createSpeechRecognition();
  SpeechRecognition.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  SpeechRecognitionEvents get on =>
    new SpeechRecognitionEvents(this);


  /** @domName SpeechRecognition.continuous */
  bool get continuous native "SpeechRecognition_continuous_Getter";


  /** @domName SpeechRecognition.continuous */
  void set continuous(bool value) native "SpeechRecognition_continuous_Setter";


  /** @domName SpeechRecognition.grammars */
  SpeechGrammarList get grammars native "SpeechRecognition_grammars_Getter";


  /** @domName SpeechRecognition.grammars */
  void set grammars(SpeechGrammarList value) native "SpeechRecognition_grammars_Setter";


  /** @domName SpeechRecognition.interimResults */
  bool get interimResults native "SpeechRecognition_interimResults_Getter";


  /** @domName SpeechRecognition.interimResults */
  void set interimResults(bool value) native "SpeechRecognition_interimResults_Setter";


  /** @domName SpeechRecognition.lang */
  String get lang native "SpeechRecognition_lang_Getter";


  /** @domName SpeechRecognition.lang */
  void set lang(String value) native "SpeechRecognition_lang_Setter";


  /** @domName SpeechRecognition.maxAlternatives */
  int get maxAlternatives native "SpeechRecognition_maxAlternatives_Getter";


  /** @domName SpeechRecognition.maxAlternatives */
  void set maxAlternatives(int value) native "SpeechRecognition_maxAlternatives_Setter";


  /** @domName SpeechRecognition.abort */
  void abort() native "SpeechRecognition_abort_Callback";


  /** @domName SpeechRecognition.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "SpeechRecognition_addEventListener_Callback";


  /** @domName SpeechRecognition.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "SpeechRecognition_dispatchEvent_Callback";


  /** @domName SpeechRecognition.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "SpeechRecognition_removeEventListener_Callback";


  /** @domName SpeechRecognition.start */
  void start() native "SpeechRecognition_start_Callback";


  /** @domName SpeechRecognition.stop */
  void stop() native "SpeechRecognition_stop_Callback";

}

class SpeechRecognitionEvents extends Events {
  SpeechRecognitionEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get audioEnd => this['audioend'];

  EventListenerList get audioStart => this['audiostart'];

  EventListenerList get end => this['end'];

  EventListenerList get error => this['error'];

  EventListenerList get noMatch => this['nomatch'];

  EventListenerList get result => this['result'];

  EventListenerList get soundEnd => this['soundend'];

  EventListenerList get soundStart => this['soundstart'];

  EventListenerList get speechEnd => this['speechend'];

  EventListenerList get speechStart => this['speechstart'];

  EventListenerList get start => this['start'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SpeechRecognitionAlternative
class SpeechRecognitionAlternative extends NativeFieldWrapperClass1 {
  SpeechRecognitionAlternative.internal();


  /** @domName SpeechRecognitionAlternative.confidence */
  num get confidence native "SpeechRecognitionAlternative_confidence_Getter";


  /** @domName SpeechRecognitionAlternative.transcript */
  String get transcript native "SpeechRecognitionAlternative_transcript_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SpeechRecognitionError
class SpeechRecognitionError extends Event {
  SpeechRecognitionError.internal(): super.internal();

  static const int ABORTED = 2;

  static const int AUDIO_CAPTURE = 3;

  static const int BAD_GRAMMAR = 7;

  static const int LANGUAGE_NOT_SUPPORTED = 8;

  static const int NETWORK = 4;

  static const int NOT_ALLOWED = 5;

  static const int NO_SPEECH = 1;

  static const int OTHER = 0;

  static const int SERVICE_NOT_ALLOWED = 6;


  /** @domName SpeechRecognitionError.code */
  int get code native "SpeechRecognitionError_code_Getter";


  /** @domName SpeechRecognitionError.message */
  String get message native "SpeechRecognitionError_message_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SpeechRecognitionEvent
class SpeechRecognitionEvent extends Event {
  SpeechRecognitionEvent.internal(): super.internal();


  /** @domName SpeechRecognitionEvent.result */
  SpeechRecognitionResult get result native "SpeechRecognitionEvent_result_Getter";


  /** @domName SpeechRecognitionEvent.resultHistory */
  List<SpeechRecognitionResult> get resultHistory native "SpeechRecognitionEvent_resultHistory_Getter";


  /** @domName SpeechRecognitionEvent.resultIndex */
  int get resultIndex native "SpeechRecognitionEvent_resultIndex_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SpeechRecognitionResult
class SpeechRecognitionResult extends NativeFieldWrapperClass1 {
  SpeechRecognitionResult.internal();


  /** @domName SpeechRecognitionResult.emma */
  Document get emma native "SpeechRecognitionResult_emma_Getter";


  /** @domName SpeechRecognitionResult.final */
  bool get finalValue native "SpeechRecognitionResult_final_Getter";


  /** @domName SpeechRecognitionResult.length */
  int get length native "SpeechRecognitionResult_length_Getter";


  /** @domName SpeechRecognitionResult.item */
  SpeechRecognitionAlternative item(int index) native "SpeechRecognitionResult_item_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class Storage extends NativeFieldWrapperClass1 implements Map<String, String>  {

  // TODO(nweiz): update this when maps support lazy iteration
  bool containsValue(String value) => values.some((e) => e == value);

  bool containsKey(String key) => $dom_getItem(key) != null;

  String operator [](String key) => $dom_getItem(key);

  void operator []=(String key, String value) { $dom_setItem(key, value); }

  String putIfAbsent(String key, String ifAbsent()) {
    if (!containsKey(key)) this[key] = ifAbsent();
    return this[key];
  }

  String remove(String key) {
    final value = this[key];
    $dom_removeItem(key);
    return value;
  }

  void clear() => $dom_clear();

  void forEach(void f(String key, String value)) {
    for (var i = 0; true; i++) {
      final key = $dom_key(i);
      if (key == null) return;

      f(key, this[key]);
    }
  }

  Collection<String> get keys {
    final keys = [];
    forEach((k, v) => keys.add(k));
    return keys;
  }

  Collection<String> get values {
    final values = [];
    forEach((k, v) => values.add(v));
    return values;
  }

  int get length => $dom_length;

  bool get isEmpty => $dom_key(0) == null;
  Storage.internal();


  /** @domName Storage.length */
  int get $dom_length native "Storage_length_Getter";


  /** @domName Storage.clear */
  void $dom_clear() native "Storage_clear_Callback";


  /** @domName Storage.getItem */
  String $dom_getItem(String key) native "Storage_getItem_Callback";


  /** @domName Storage.key */
  String $dom_key(int index) native "Storage_key_Callback";


  /** @domName Storage.removeItem */
  void $dom_removeItem(String key) native "Storage_removeItem_Callback";


  /** @domName Storage.setItem */
  void $dom_setItem(String key, String data) native "Storage_setItem_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName StorageEvent
class StorageEvent extends Event {
  StorageEvent.internal(): super.internal();


  /** @domName StorageEvent.key */
  String get key native "StorageEvent_key_Getter";


  /** @domName StorageEvent.newValue */
  String get newValue native "StorageEvent_newValue_Getter";


  /** @domName StorageEvent.oldValue */
  String get oldValue native "StorageEvent_oldValue_Getter";


  /** @domName StorageEvent.storageArea */
  Storage get storageArea native "StorageEvent_storageArea_Getter";


  /** @domName StorageEvent.url */
  String get url native "StorageEvent_url_Getter";


  /** @domName StorageEvent.initStorageEvent */
  void initStorageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String keyArg, String oldValueArg, String newValueArg, String urlArg, Storage storageAreaArg) native "StorageEvent_initStorageEvent_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName StorageInfo
class StorageInfo extends NativeFieldWrapperClass1 {
  StorageInfo.internal();

  static const int PERSISTENT = 1;

  static const int TEMPORARY = 0;


  /** @domName StorageInfo.queryUsageAndQuota */
  void queryUsageAndQuota(int storageType, [StorageInfoUsageCallback usageCallback, StorageInfoErrorCallback errorCallback]) native "StorageInfo_queryUsageAndQuota_Callback";


  /** @domName StorageInfo.requestQuota */
  void requestQuota(int storageType, int newQuotaInBytes, [StorageInfoQuotaCallback quotaCallback, StorageInfoErrorCallback errorCallback]) native "StorageInfo_requestQuota_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void StorageInfoErrorCallback(DOMException error);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void StorageInfoQuotaCallback(int grantedQuotaInBytes);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void StorageInfoUsageCallback(int currentUsageInBytes, int currentQuotaInBytes);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void StringCallback(String data);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLStyleElement
class StyleElement extends _Element_Merged {

  factory StyleElement() => document.$dom_createElement("style");
  StyleElement.internal(): super.internal();


  /** @domName HTMLStyleElement.disabled */
  bool get disabled native "HTMLStyleElement_disabled_Getter";


  /** @domName HTMLStyleElement.disabled */
  void set disabled(bool value) native "HTMLStyleElement_disabled_Setter";


  /** @domName HTMLStyleElement.media */
  String get media native "HTMLStyleElement_media_Getter";


  /** @domName HTMLStyleElement.media */
  void set media(String value) native "HTMLStyleElement_media_Setter";


  /** @domName HTMLStyleElement.scoped */
  bool get scoped native "HTMLStyleElement_scoped_Getter";


  /** @domName HTMLStyleElement.scoped */
  void set scoped(bool value) native "HTMLStyleElement_scoped_Setter";


  /** @domName HTMLStyleElement.sheet */
  StyleSheet get sheet native "HTMLStyleElement_sheet_Getter";


  /** @domName HTMLStyleElement.type */
  String get type native "HTMLStyleElement_type_Getter";


  /** @domName HTMLStyleElement.type */
  void set type(String value) native "HTMLStyleElement_type_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName StyleMedia
class StyleMedia extends NativeFieldWrapperClass1 {
  StyleMedia.internal();


  /** @domName StyleMedia.type */
  String get type native "StyleMedia_type_Getter";


  /** @domName StyleMedia.matchMedium */
  bool matchMedium(String mediaquery) native "StyleMedia_matchMedium_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName StyleSheet
class StyleSheet extends NativeFieldWrapperClass1 {
  StyleSheet.internal();


  /** @domName StyleSheet.disabled */
  bool get disabled native "StyleSheet_disabled_Getter";


  /** @domName StyleSheet.disabled */
  void set disabled(bool value) native "StyleSheet_disabled_Setter";


  /** @domName StyleSheet.href */
  String get href native "StyleSheet_href_Getter";


  /** @domName StyleSheet.media */
  MediaList get media native "StyleSheet_media_Getter";


  /** @domName StyleSheet.ownerNode */
  Node get ownerNode native "StyleSheet_ownerNode_Getter";


  /** @domName StyleSheet.parentStyleSheet */
  StyleSheet get parentStyleSheet native "StyleSheet_parentStyleSheet_Getter";


  /** @domName StyleSheet.title */
  String get title native "StyleSheet_title_Getter";


  /** @domName StyleSheet.type */
  String get type native "StyleSheet_type_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLTableCaptionElement
class TableCaptionElement extends _Element_Merged {

  factory TableCaptionElement() => document.$dom_createElement("caption");
  TableCaptionElement.internal(): super.internal();


  /** @domName HTMLTableCaptionElement.align */
  String get align native "HTMLTableCaptionElement_align_Getter";


  /** @domName HTMLTableCaptionElement.align */
  void set align(String value) native "HTMLTableCaptionElement_align_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLTableCellElement
class TableCellElement extends _Element_Merged {

  factory TableCellElement() => document.$dom_createElement("td");
  TableCellElement.internal(): super.internal();


  /** @domName HTMLTableCellElement.abbr */
  String get abbr native "HTMLTableCellElement_abbr_Getter";


  /** @domName HTMLTableCellElement.abbr */
  void set abbr(String value) native "HTMLTableCellElement_abbr_Setter";


  /** @domName HTMLTableCellElement.align */
  String get align native "HTMLTableCellElement_align_Getter";


  /** @domName HTMLTableCellElement.align */
  void set align(String value) native "HTMLTableCellElement_align_Setter";


  /** @domName HTMLTableCellElement.axis */
  String get axis native "HTMLTableCellElement_axis_Getter";


  /** @domName HTMLTableCellElement.axis */
  void set axis(String value) native "HTMLTableCellElement_axis_Setter";


  /** @domName HTMLTableCellElement.bgColor */
  String get bgColor native "HTMLTableCellElement_bgColor_Getter";


  /** @domName HTMLTableCellElement.bgColor */
  void set bgColor(String value) native "HTMLTableCellElement_bgColor_Setter";


  /** @domName HTMLTableCellElement.cellIndex */
  int get cellIndex native "HTMLTableCellElement_cellIndex_Getter";


  /** @domName HTMLTableCellElement.ch */
  String get ch native "HTMLTableCellElement_ch_Getter";


  /** @domName HTMLTableCellElement.ch */
  void set ch(String value) native "HTMLTableCellElement_ch_Setter";


  /** @domName HTMLTableCellElement.chOff */
  String get chOff native "HTMLTableCellElement_chOff_Getter";


  /** @domName HTMLTableCellElement.chOff */
  void set chOff(String value) native "HTMLTableCellElement_chOff_Setter";


  /** @domName HTMLTableCellElement.colSpan */
  int get colSpan native "HTMLTableCellElement_colSpan_Getter";


  /** @domName HTMLTableCellElement.colSpan */
  void set colSpan(int value) native "HTMLTableCellElement_colSpan_Setter";


  /** @domName HTMLTableCellElement.headers */
  String get headers native "HTMLTableCellElement_headers_Getter";


  /** @domName HTMLTableCellElement.headers */
  void set headers(String value) native "HTMLTableCellElement_headers_Setter";


  /** @domName HTMLTableCellElement.height */
  String get height native "HTMLTableCellElement_height_Getter";


  /** @domName HTMLTableCellElement.height */
  void set height(String value) native "HTMLTableCellElement_height_Setter";


  /** @domName HTMLTableCellElement.noWrap */
  bool get noWrap native "HTMLTableCellElement_noWrap_Getter";


  /** @domName HTMLTableCellElement.noWrap */
  void set noWrap(bool value) native "HTMLTableCellElement_noWrap_Setter";


  /** @domName HTMLTableCellElement.rowSpan */
  int get rowSpan native "HTMLTableCellElement_rowSpan_Getter";


  /** @domName HTMLTableCellElement.rowSpan */
  void set rowSpan(int value) native "HTMLTableCellElement_rowSpan_Setter";


  /** @domName HTMLTableCellElement.scope */
  String get scope native "HTMLTableCellElement_scope_Getter";


  /** @domName HTMLTableCellElement.scope */
  void set scope(String value) native "HTMLTableCellElement_scope_Setter";


  /** @domName HTMLTableCellElement.vAlign */
  String get vAlign native "HTMLTableCellElement_vAlign_Getter";


  /** @domName HTMLTableCellElement.vAlign */
  void set vAlign(String value) native "HTMLTableCellElement_vAlign_Setter";


  /** @domName HTMLTableCellElement.width */
  String get width native "HTMLTableCellElement_width_Getter";


  /** @domName HTMLTableCellElement.width */
  void set width(String value) native "HTMLTableCellElement_width_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLTableColElement
class TableColElement extends _Element_Merged {

  factory TableColElement() => document.$dom_createElement("col");
  TableColElement.internal(): super.internal();


  /** @domName HTMLTableColElement.align */
  String get align native "HTMLTableColElement_align_Getter";


  /** @domName HTMLTableColElement.align */
  void set align(String value) native "HTMLTableColElement_align_Setter";


  /** @domName HTMLTableColElement.ch */
  String get ch native "HTMLTableColElement_ch_Getter";


  /** @domName HTMLTableColElement.ch */
  void set ch(String value) native "HTMLTableColElement_ch_Setter";


  /** @domName HTMLTableColElement.chOff */
  String get chOff native "HTMLTableColElement_chOff_Getter";


  /** @domName HTMLTableColElement.chOff */
  void set chOff(String value) native "HTMLTableColElement_chOff_Setter";


  /** @domName HTMLTableColElement.span */
  int get span native "HTMLTableColElement_span_Getter";


  /** @domName HTMLTableColElement.span */
  void set span(int value) native "HTMLTableColElement_span_Setter";


  /** @domName HTMLTableColElement.vAlign */
  String get vAlign native "HTMLTableColElement_vAlign_Getter";


  /** @domName HTMLTableColElement.vAlign */
  void set vAlign(String value) native "HTMLTableColElement_vAlign_Setter";


  /** @domName HTMLTableColElement.width */
  String get width native "HTMLTableColElement_width_Getter";


  /** @domName HTMLTableColElement.width */
  void set width(String value) native "HTMLTableColElement_width_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLTableElement
class TableElement extends _Element_Merged {

  factory TableElement() => document.$dom_createElement("table");
  TableElement.internal(): super.internal();


  /** @domName HTMLTableElement.align */
  String get align native "HTMLTableElement_align_Getter";


  /** @domName HTMLTableElement.align */
  void set align(String value) native "HTMLTableElement_align_Setter";


  /** @domName HTMLTableElement.bgColor */
  String get bgColor native "HTMLTableElement_bgColor_Getter";


  /** @domName HTMLTableElement.bgColor */
  void set bgColor(String value) native "HTMLTableElement_bgColor_Setter";


  /** @domName HTMLTableElement.border */
  String get border native "HTMLTableElement_border_Getter";


  /** @domName HTMLTableElement.border */
  void set border(String value) native "HTMLTableElement_border_Setter";


  /** @domName HTMLTableElement.caption */
  TableCaptionElement get caption native "HTMLTableElement_caption_Getter";


  /** @domName HTMLTableElement.caption */
  void set caption(TableCaptionElement value) native "HTMLTableElement_caption_Setter";


  /** @domName HTMLTableElement.cellPadding */
  String get cellPadding native "HTMLTableElement_cellPadding_Getter";


  /** @domName HTMLTableElement.cellPadding */
  void set cellPadding(String value) native "HTMLTableElement_cellPadding_Setter";


  /** @domName HTMLTableElement.cellSpacing */
  String get cellSpacing native "HTMLTableElement_cellSpacing_Getter";


  /** @domName HTMLTableElement.cellSpacing */
  void set cellSpacing(String value) native "HTMLTableElement_cellSpacing_Setter";


  /** @domName HTMLTableElement.frame */
  String get frame native "HTMLTableElement_frame_Getter";


  /** @domName HTMLTableElement.frame */
  void set frame(String value) native "HTMLTableElement_frame_Setter";


  /** @domName HTMLTableElement.rows */
  HTMLCollection get rows native "HTMLTableElement_rows_Getter";


  /** @domName HTMLTableElement.rules */
  String get rules native "HTMLTableElement_rules_Getter";


  /** @domName HTMLTableElement.rules */
  void set rules(String value) native "HTMLTableElement_rules_Setter";


  /** @domName HTMLTableElement.summary */
  String get summary native "HTMLTableElement_summary_Getter";


  /** @domName HTMLTableElement.summary */
  void set summary(String value) native "HTMLTableElement_summary_Setter";


  /** @domName HTMLTableElement.tBodies */
  HTMLCollection get tBodies native "HTMLTableElement_tBodies_Getter";


  /** @domName HTMLTableElement.tFoot */
  TableSectionElement get tFoot native "HTMLTableElement_tFoot_Getter";


  /** @domName HTMLTableElement.tFoot */
  void set tFoot(TableSectionElement value) native "HTMLTableElement_tFoot_Setter";


  /** @domName HTMLTableElement.tHead */
  TableSectionElement get tHead native "HTMLTableElement_tHead_Getter";


  /** @domName HTMLTableElement.tHead */
  void set tHead(TableSectionElement value) native "HTMLTableElement_tHead_Setter";


  /** @domName HTMLTableElement.width */
  String get width native "HTMLTableElement_width_Getter";


  /** @domName HTMLTableElement.width */
  void set width(String value) native "HTMLTableElement_width_Setter";


  /** @domName HTMLTableElement.createCaption */
  Element createCaption() native "HTMLTableElement_createCaption_Callback";


  /** @domName HTMLTableElement.createTBody */
  Element createTBody() native "HTMLTableElement_createTBody_Callback";


  /** @domName HTMLTableElement.createTFoot */
  Element createTFoot() native "HTMLTableElement_createTFoot_Callback";


  /** @domName HTMLTableElement.createTHead */
  Element createTHead() native "HTMLTableElement_createTHead_Callback";


  /** @domName HTMLTableElement.deleteCaption */
  void deleteCaption() native "HTMLTableElement_deleteCaption_Callback";


  /** @domName HTMLTableElement.deleteRow */
  void deleteRow(int index) native "HTMLTableElement_deleteRow_Callback";


  /** @domName HTMLTableElement.deleteTFoot */
  void deleteTFoot() native "HTMLTableElement_deleteTFoot_Callback";


  /** @domName HTMLTableElement.deleteTHead */
  void deleteTHead() native "HTMLTableElement_deleteTHead_Callback";


  /** @domName HTMLTableElement.insertRow */
  Element insertRow(int index) native "HTMLTableElement_insertRow_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLTableRowElement
class TableRowElement extends _Element_Merged {

  factory TableRowElement() => document.$dom_createElement("tr");
  TableRowElement.internal(): super.internal();


  /** @domName HTMLTableRowElement.align */
  String get align native "HTMLTableRowElement_align_Getter";


  /** @domName HTMLTableRowElement.align */
  void set align(String value) native "HTMLTableRowElement_align_Setter";


  /** @domName HTMLTableRowElement.bgColor */
  String get bgColor native "HTMLTableRowElement_bgColor_Getter";


  /** @domName HTMLTableRowElement.bgColor */
  void set bgColor(String value) native "HTMLTableRowElement_bgColor_Setter";


  /** @domName HTMLTableRowElement.cells */
  HTMLCollection get cells native "HTMLTableRowElement_cells_Getter";


  /** @domName HTMLTableRowElement.ch */
  String get ch native "HTMLTableRowElement_ch_Getter";


  /** @domName HTMLTableRowElement.ch */
  void set ch(String value) native "HTMLTableRowElement_ch_Setter";


  /** @domName HTMLTableRowElement.chOff */
  String get chOff native "HTMLTableRowElement_chOff_Getter";


  /** @domName HTMLTableRowElement.chOff */
  void set chOff(String value) native "HTMLTableRowElement_chOff_Setter";


  /** @domName HTMLTableRowElement.rowIndex */
  int get rowIndex native "HTMLTableRowElement_rowIndex_Getter";


  /** @domName HTMLTableRowElement.sectionRowIndex */
  int get sectionRowIndex native "HTMLTableRowElement_sectionRowIndex_Getter";


  /** @domName HTMLTableRowElement.vAlign */
  String get vAlign native "HTMLTableRowElement_vAlign_Getter";


  /** @domName HTMLTableRowElement.vAlign */
  void set vAlign(String value) native "HTMLTableRowElement_vAlign_Setter";


  /** @domName HTMLTableRowElement.deleteCell */
  void deleteCell(int index) native "HTMLTableRowElement_deleteCell_Callback";


  /** @domName HTMLTableRowElement.insertCell */
  Element insertCell(int index) native "HTMLTableRowElement_insertCell_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLTableSectionElement
class TableSectionElement extends _Element_Merged {
  TableSectionElement.internal(): super.internal();


  /** @domName HTMLTableSectionElement.align */
  String get align native "HTMLTableSectionElement_align_Getter";


  /** @domName HTMLTableSectionElement.align */
  void set align(String value) native "HTMLTableSectionElement_align_Setter";


  /** @domName HTMLTableSectionElement.ch */
  String get ch native "HTMLTableSectionElement_ch_Getter";


  /** @domName HTMLTableSectionElement.ch */
  void set ch(String value) native "HTMLTableSectionElement_ch_Setter";


  /** @domName HTMLTableSectionElement.chOff */
  String get chOff native "HTMLTableSectionElement_chOff_Getter";


  /** @domName HTMLTableSectionElement.chOff */
  void set chOff(String value) native "HTMLTableSectionElement_chOff_Setter";


  /** @domName HTMLTableSectionElement.rows */
  HTMLCollection get rows native "HTMLTableSectionElement_rows_Getter";


  /** @domName HTMLTableSectionElement.vAlign */
  String get vAlign native "HTMLTableSectionElement_vAlign_Getter";


  /** @domName HTMLTableSectionElement.vAlign */
  void set vAlign(String value) native "HTMLTableSectionElement_vAlign_Setter";


  /** @domName HTMLTableSectionElement.deleteRow */
  void deleteRow(int index) native "HTMLTableSectionElement_deleteRow_Callback";


  /** @domName HTMLTableSectionElement.insertRow */
  Element insertRow(int index) native "HTMLTableSectionElement_insertRow_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


class Text extends CharacterData {
  factory Text(String data) => _TextFactoryProvider.createText(data);
  Text.internal(): super.internal();


  /** @domName Text.wholeText */
  String get wholeText native "Text_wholeText_Getter";


  /** @domName Text.replaceWholeText */
  Text replaceWholeText(String content) native "Text_replaceWholeText_Callback";


  /** @domName Text.splitText */
  Text splitText(int offset) native "Text_splitText_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLTextAreaElement
class TextAreaElement extends _Element_Merged {

  factory TextAreaElement() => document.$dom_createElement("textarea");
  TextAreaElement.internal(): super.internal();


  /** @domName HTMLTextAreaElement.autofocus */
  bool get autofocus native "HTMLTextAreaElement_autofocus_Getter";


  /** @domName HTMLTextAreaElement.autofocus */
  void set autofocus(bool value) native "HTMLTextAreaElement_autofocus_Setter";


  /** @domName HTMLTextAreaElement.cols */
  int get cols native "HTMLTextAreaElement_cols_Getter";


  /** @domName HTMLTextAreaElement.cols */
  void set cols(int value) native "HTMLTextAreaElement_cols_Setter";


  /** @domName HTMLTextAreaElement.defaultValue */
  String get defaultValue native "HTMLTextAreaElement_defaultValue_Getter";


  /** @domName HTMLTextAreaElement.defaultValue */
  void set defaultValue(String value) native "HTMLTextAreaElement_defaultValue_Setter";


  /** @domName HTMLTextAreaElement.dirName */
  String get dirName native "HTMLTextAreaElement_dirName_Getter";


  /** @domName HTMLTextAreaElement.dirName */
  void set dirName(String value) native "HTMLTextAreaElement_dirName_Setter";


  /** @domName HTMLTextAreaElement.disabled */
  bool get disabled native "HTMLTextAreaElement_disabled_Getter";


  /** @domName HTMLTextAreaElement.disabled */
  void set disabled(bool value) native "HTMLTextAreaElement_disabled_Setter";


  /** @domName HTMLTextAreaElement.form */
  FormElement get form native "HTMLTextAreaElement_form_Getter";


  /** @domName HTMLTextAreaElement.labels */
  List<Node> get labels native "HTMLTextAreaElement_labels_Getter";


  /** @domName HTMLTextAreaElement.maxLength */
  int get maxLength native "HTMLTextAreaElement_maxLength_Getter";


  /** @domName HTMLTextAreaElement.maxLength */
  void set maxLength(int value) native "HTMLTextAreaElement_maxLength_Setter";


  /** @domName HTMLTextAreaElement.name */
  String get name native "HTMLTextAreaElement_name_Getter";


  /** @domName HTMLTextAreaElement.name */
  void set name(String value) native "HTMLTextAreaElement_name_Setter";


  /** @domName HTMLTextAreaElement.placeholder */
  String get placeholder native "HTMLTextAreaElement_placeholder_Getter";


  /** @domName HTMLTextAreaElement.placeholder */
  void set placeholder(String value) native "HTMLTextAreaElement_placeholder_Setter";


  /** @domName HTMLTextAreaElement.readOnly */
  bool get readOnly native "HTMLTextAreaElement_readOnly_Getter";


  /** @domName HTMLTextAreaElement.readOnly */
  void set readOnly(bool value) native "HTMLTextAreaElement_readOnly_Setter";


  /** @domName HTMLTextAreaElement.required */
  bool get required native "HTMLTextAreaElement_required_Getter";


  /** @domName HTMLTextAreaElement.required */
  void set required(bool value) native "HTMLTextAreaElement_required_Setter";


  /** @domName HTMLTextAreaElement.rows */
  int get rows native "HTMLTextAreaElement_rows_Getter";


  /** @domName HTMLTextAreaElement.rows */
  void set rows(int value) native "HTMLTextAreaElement_rows_Setter";


  /** @domName HTMLTextAreaElement.selectionDirection */
  String get selectionDirection native "HTMLTextAreaElement_selectionDirection_Getter";


  /** @domName HTMLTextAreaElement.selectionDirection */
  void set selectionDirection(String value) native "HTMLTextAreaElement_selectionDirection_Setter";


  /** @domName HTMLTextAreaElement.selectionEnd */
  int get selectionEnd native "HTMLTextAreaElement_selectionEnd_Getter";


  /** @domName HTMLTextAreaElement.selectionEnd */
  void set selectionEnd(int value) native "HTMLTextAreaElement_selectionEnd_Setter";


  /** @domName HTMLTextAreaElement.selectionStart */
  int get selectionStart native "HTMLTextAreaElement_selectionStart_Getter";


  /** @domName HTMLTextAreaElement.selectionStart */
  void set selectionStart(int value) native "HTMLTextAreaElement_selectionStart_Setter";


  /** @domName HTMLTextAreaElement.textLength */
  int get textLength native "HTMLTextAreaElement_textLength_Getter";


  /** @domName HTMLTextAreaElement.type */
  String get type native "HTMLTextAreaElement_type_Getter";


  /** @domName HTMLTextAreaElement.validationMessage */
  String get validationMessage native "HTMLTextAreaElement_validationMessage_Getter";


  /** @domName HTMLTextAreaElement.validity */
  ValidityState get validity native "HTMLTextAreaElement_validity_Getter";


  /** @domName HTMLTextAreaElement.value */
  String get value native "HTMLTextAreaElement_value_Getter";


  /** @domName HTMLTextAreaElement.value */
  void set value(String value) native "HTMLTextAreaElement_value_Setter";


  /** @domName HTMLTextAreaElement.willValidate */
  bool get willValidate native "HTMLTextAreaElement_willValidate_Getter";


  /** @domName HTMLTextAreaElement.wrap */
  String get wrap native "HTMLTextAreaElement_wrap_Getter";


  /** @domName HTMLTextAreaElement.wrap */
  void set wrap(String value) native "HTMLTextAreaElement_wrap_Setter";


  /** @domName HTMLTextAreaElement.checkValidity */
  bool checkValidity() native "HTMLTextAreaElement_checkValidity_Callback";


  /** @domName HTMLTextAreaElement.select */
  void select() native "HTMLTextAreaElement_select_Callback";


  /** @domName HTMLTextAreaElement.setCustomValidity */
  void setCustomValidity(String error) native "HTMLTextAreaElement_setCustomValidity_Callback";

  void setRangeText(/*DOMString*/ replacement, [/*unsigned long*/ start, /*unsigned long*/ end, /*DOMString*/ selectionMode]) {
    if ((replacement is String || replacement == null) && !?start && !?end && !?selectionMode) {
      _setRangeText_1(replacement);
      return;
    }
    if ((replacement is String || replacement == null) && (start is int || start == null) && (end is int || end == null) && (selectionMode is String || selectionMode == null)) {
      _setRangeText_2(replacement, start, end, selectionMode);
      return;
    }
    throw "Incorrect number or type of arguments";
  }


  /** @domName HTMLTextAreaElement.setRangeText_1 */
  void _setRangeText_1(replacement) native "HTMLTextAreaElement_setRangeText_1_Callback";


  /** @domName HTMLTextAreaElement.setRangeText_2 */
  void _setRangeText_2(replacement, start, end, selectionMode) native "HTMLTextAreaElement_setRangeText_2_Callback";

  void setSelectionRange(/*long*/ start, /*long*/ end, [/*DOMString*/ direction]) {
    if (?direction) {
      _setSelectionRange_1(start, end, direction);
      return;
    }
    _setSelectionRange_2(start, end);
  }


  /** @domName HTMLTextAreaElement.setSelectionRange_1 */
  void _setSelectionRange_1(start, end, direction) native "HTMLTextAreaElement_setSelectionRange_1_Callback";


  /** @domName HTMLTextAreaElement.setSelectionRange_2 */
  void _setSelectionRange_2(start, end) native "HTMLTextAreaElement_setSelectionRange_2_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName TextEvent
class TextEvent extends UIEvent {
  TextEvent.internal(): super.internal();


  /** @domName TextEvent.data */
  String get data native "TextEvent_data_Getter";


  /** @domName TextEvent.initTextEvent */
  void initTextEvent(String typeArg, bool canBubbleArg, bool cancelableArg, LocalWindow viewArg, String dataArg) native "TextEvent_initTextEvent_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName TextMetrics
class TextMetrics extends NativeFieldWrapperClass1 {
  TextMetrics.internal();


  /** @domName TextMetrics.width */
  num get width native "TextMetrics_width_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName TextTrack
class TextTrack extends EventTarget {
  TextTrack.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  TextTrackEvents get on =>
    new TextTrackEvents(this);


  /** @domName TextTrack.activeCues */
  TextTrackCueList get activeCues native "TextTrack_activeCues_Getter";


  /** @domName TextTrack.cues */
  TextTrackCueList get cues native "TextTrack_cues_Getter";


  /** @domName TextTrack.kind */
  String get kind native "TextTrack_kind_Getter";


  /** @domName TextTrack.label */
  String get label native "TextTrack_label_Getter";


  /** @domName TextTrack.language */
  String get language native "TextTrack_language_Getter";


  /** @domName TextTrack.mode */
  String get mode native "TextTrack_mode_Getter";


  /** @domName TextTrack.mode */
  void set mode(String value) native "TextTrack_mode_Setter";


  /** @domName TextTrack.addCue */
  void addCue(TextTrackCue cue) native "TextTrack_addCue_Callback";


  /** @domName TextTrack.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "TextTrack_addEventListener_Callback";


  /** @domName TextTrack.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "TextTrack_dispatchEvent_Callback";


  /** @domName TextTrack.removeCue */
  void removeCue(TextTrackCue cue) native "TextTrack_removeCue_Callback";


  /** @domName TextTrack.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "TextTrack_removeEventListener_Callback";

}

class TextTrackEvents extends Events {
  TextTrackEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get cueChange => this['cuechange'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName TextTrackCue
class TextTrackCue extends EventTarget {

  factory TextTrackCue(num startTime, num endTime, String text) => _TextTrackCueFactoryProvider.createTextTrackCue(startTime, endTime, text);
  TextTrackCue.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  TextTrackCueEvents get on =>
    new TextTrackCueEvents(this);


  /** @domName TextTrackCue.align */
  String get align native "TextTrackCue_align_Getter";


  /** @domName TextTrackCue.align */
  void set align(String value) native "TextTrackCue_align_Setter";


  /** @domName TextTrackCue.endTime */
  num get endTime native "TextTrackCue_endTime_Getter";


  /** @domName TextTrackCue.endTime */
  void set endTime(num value) native "TextTrackCue_endTime_Setter";


  /** @domName TextTrackCue.id */
  String get id native "TextTrackCue_id_Getter";


  /** @domName TextTrackCue.id */
  void set id(String value) native "TextTrackCue_id_Setter";


  /** @domName TextTrackCue.line */
  int get line native "TextTrackCue_line_Getter";


  /** @domName TextTrackCue.line */
  void set line(int value) native "TextTrackCue_line_Setter";


  /** @domName TextTrackCue.pauseOnExit */
  bool get pauseOnExit native "TextTrackCue_pauseOnExit_Getter";


  /** @domName TextTrackCue.pauseOnExit */
  void set pauseOnExit(bool value) native "TextTrackCue_pauseOnExit_Setter";


  /** @domName TextTrackCue.position */
  int get position native "TextTrackCue_position_Getter";


  /** @domName TextTrackCue.position */
  void set position(int value) native "TextTrackCue_position_Setter";


  /** @domName TextTrackCue.size */
  int get size native "TextTrackCue_size_Getter";


  /** @domName TextTrackCue.size */
  void set size(int value) native "TextTrackCue_size_Setter";


  /** @domName TextTrackCue.snapToLines */
  bool get snapToLines native "TextTrackCue_snapToLines_Getter";


  /** @domName TextTrackCue.snapToLines */
  void set snapToLines(bool value) native "TextTrackCue_snapToLines_Setter";


  /** @domName TextTrackCue.startTime */
  num get startTime native "TextTrackCue_startTime_Getter";


  /** @domName TextTrackCue.startTime */
  void set startTime(num value) native "TextTrackCue_startTime_Setter";


  /** @domName TextTrackCue.text */
  String get text native "TextTrackCue_text_Getter";


  /** @domName TextTrackCue.text */
  void set text(String value) native "TextTrackCue_text_Setter";


  /** @domName TextTrackCue.track */
  TextTrack get track native "TextTrackCue_track_Getter";


  /** @domName TextTrackCue.vertical */
  String get vertical native "TextTrackCue_vertical_Getter";


  /** @domName TextTrackCue.vertical */
  void set vertical(String value) native "TextTrackCue_vertical_Setter";


  /** @domName TextTrackCue.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "TextTrackCue_addEventListener_Callback";


  /** @domName TextTrackCue.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "TextTrackCue_dispatchEvent_Callback";


  /** @domName TextTrackCue.getCueAsHTML */
  DocumentFragment getCueAsHTML() native "TextTrackCue_getCueAsHTML_Callback";


  /** @domName TextTrackCue.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "TextTrackCue_removeEventListener_Callback";

}

class TextTrackCueEvents extends Events {
  TextTrackCueEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get enter => this['enter'];

  EventListenerList get exit => this['exit'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName TextTrackCueList
class TextTrackCueList extends NativeFieldWrapperClass1 implements List<TextTrackCue> {
  TextTrackCueList.internal();


  /** @domName TextTrackCueList.length */
  int get length native "TextTrackCueList_length_Getter";

  TextTrackCue operator[](int index) native "TextTrackCueList_item_Callback";

  void operator[]=(int index, TextTrackCue value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<TextTrackCue> mixins.
  // TextTrackCue is the element type.

  // From Iterable<TextTrackCue>:

  Iterator<TextTrackCue> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<TextTrackCue>(this);
  }

  // From Collection<TextTrackCue>:

  void add(TextTrackCue value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(TextTrackCue value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<TextTrackCue> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(TextTrackCue element) => _Collections.contains(this, element);

  void forEach(void f(TextTrackCue element)) => _Collections.forEach(this, f);

  Collection map(f(TextTrackCue element)) => _Collections.map(this, [], f);

  Collection<TextTrackCue> filter(bool f(TextTrackCue element)) =>
     _Collections.filter(this, <TextTrackCue>[], f);

  bool every(bool f(TextTrackCue element)) => _Collections.every(this, f);

  bool some(bool f(TextTrackCue element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<TextTrackCue>:

  void sort([Comparator<TextTrackCue> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(TextTrackCue element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(TextTrackCue element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  TextTrackCue get first => this[0];

  TextTrackCue get last => this[length - 1];

  TextTrackCue removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<TextTrackCue> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [TextTrackCue initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<TextTrackCue> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <TextTrackCue>[]);

  // -- end List<TextTrackCue> mixins.


  /** @domName TextTrackCueList.getCueById */
  TextTrackCue getCueById(String id) native "TextTrackCueList_getCueById_Callback";


  /** @domName TextTrackCueList.item */
  TextTrackCue item(int index) native "TextTrackCueList_item_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName TextTrackList
class TextTrackList extends EventTarget implements List<TextTrack> {
  TextTrackList.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  TextTrackListEvents get on =>
    new TextTrackListEvents(this);


  /** @domName TextTrackList.length */
  int get length native "TextTrackList_length_Getter";

  TextTrack operator[](int index) native "TextTrackList_item_Callback";

  void operator[]=(int index, TextTrack value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<TextTrack> mixins.
  // TextTrack is the element type.

  // From Iterable<TextTrack>:

  Iterator<TextTrack> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<TextTrack>(this);
  }

  // From Collection<TextTrack>:

  void add(TextTrack value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(TextTrack value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<TextTrack> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(TextTrack element) => _Collections.contains(this, element);

  void forEach(void f(TextTrack element)) => _Collections.forEach(this, f);

  Collection map(f(TextTrack element)) => _Collections.map(this, [], f);

  Collection<TextTrack> filter(bool f(TextTrack element)) =>
     _Collections.filter(this, <TextTrack>[], f);

  bool every(bool f(TextTrack element)) => _Collections.every(this, f);

  bool some(bool f(TextTrack element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<TextTrack>:

  void sort([Comparator<TextTrack> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(TextTrack element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(TextTrack element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  TextTrack get first => this[0];

  TextTrack get last => this[length - 1];

  TextTrack removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<TextTrack> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [TextTrack initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<TextTrack> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <TextTrack>[]);

  // -- end List<TextTrack> mixins.


  /** @domName TextTrackList.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "TextTrackList_addEventListener_Callback";


  /** @domName TextTrackList.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "TextTrackList_dispatchEvent_Callback";


  /** @domName TextTrackList.item */
  TextTrack item(int index) native "TextTrackList_item_Callback";


  /** @domName TextTrackList.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "TextTrackList_removeEventListener_Callback";

}

class TextTrackListEvents extends Events {
  TextTrackListEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get addTrack => this['addtrack'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName TimeRanges
class TimeRanges extends NativeFieldWrapperClass1 {
  TimeRanges.internal();


  /** @domName TimeRanges.length */
  int get length native "TimeRanges_length_Getter";


  /** @domName TimeRanges.end */
  num end(int index) native "TimeRanges_end_Callback";


  /** @domName TimeRanges.start */
  num start(int index) native "TimeRanges_start_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void TimeoutHandler();
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLTitleElement
class TitleElement extends _Element_Merged {

  factory TitleElement() => document.$dom_createElement("title");
  TitleElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Touch
class Touch extends NativeFieldWrapperClass1 {
  Touch.internal();


  /** @domName Touch.clientX */
  int get clientX native "Touch_clientX_Getter";


  /** @domName Touch.clientY */
  int get clientY native "Touch_clientY_Getter";


  /** @domName Touch.identifier */
  int get identifier native "Touch_identifier_Getter";


  /** @domName Touch.pageX */
  int get pageX native "Touch_pageX_Getter";


  /** @domName Touch.pageY */
  int get pageY native "Touch_pageY_Getter";


  /** @domName Touch.screenX */
  int get screenX native "Touch_screenX_Getter";


  /** @domName Touch.screenY */
  int get screenY native "Touch_screenY_Getter";


  /** @domName Touch.target */
  EventTarget get target native "Touch_target_Getter";


  /** @domName Touch.webkitForce */
  num get webkitForce native "Touch_webkitForce_Getter";


  /** @domName Touch.webkitRadiusX */
  int get webkitRadiusX native "Touch_webkitRadiusX_Getter";


  /** @domName Touch.webkitRadiusY */
  int get webkitRadiusY native "Touch_webkitRadiusY_Getter";


  /** @domName Touch.webkitRotationAngle */
  num get webkitRotationAngle native "Touch_webkitRotationAngle_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName TouchEvent
class TouchEvent extends UIEvent {
  TouchEvent.internal(): super.internal();


  /** @domName TouchEvent.altKey */
  bool get altKey native "TouchEvent_altKey_Getter";


  /** @domName TouchEvent.changedTouches */
  TouchList get changedTouches native "TouchEvent_changedTouches_Getter";


  /** @domName TouchEvent.ctrlKey */
  bool get ctrlKey native "TouchEvent_ctrlKey_Getter";


  /** @domName TouchEvent.metaKey */
  bool get metaKey native "TouchEvent_metaKey_Getter";


  /** @domName TouchEvent.shiftKey */
  bool get shiftKey native "TouchEvent_shiftKey_Getter";


  /** @domName TouchEvent.targetTouches */
  TouchList get targetTouches native "TouchEvent_targetTouches_Getter";


  /** @domName TouchEvent.touches */
  TouchList get touches native "TouchEvent_touches_Getter";


  /** @domName TouchEvent.initTouchEvent */
  void initTouchEvent(TouchList touches, TouchList targetTouches, TouchList changedTouches, String type, LocalWindow view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) native "TouchEvent_initTouchEvent_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName TouchList
class TouchList extends NativeFieldWrapperClass1 implements List<Touch> {
  TouchList.internal();


  /** @domName TouchList.length */
  int get length native "TouchList_length_Getter";

  Touch operator[](int index) native "TouchList_item_Callback";

  void operator[]=(int index, Touch value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Touch> mixins.
  // Touch is the element type.

  // From Iterable<Touch>:

  Iterator<Touch> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Touch>(this);
  }

  // From Collection<Touch>:

  void add(Touch value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(Touch value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<Touch> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(Touch element) => _Collections.contains(this, element);

  void forEach(void f(Touch element)) => _Collections.forEach(this, f);

  Collection map(f(Touch element)) => _Collections.map(this, [], f);

  Collection<Touch> filter(bool f(Touch element)) =>
     _Collections.filter(this, <Touch>[], f);

  bool every(bool f(Touch element)) => _Collections.every(this, f);

  bool some(bool f(Touch element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<Touch>:

  void sort([Comparator<Touch> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Touch element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Touch element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  Touch get first => this[0];

  Touch get last => this[length - 1];

  Touch removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<Touch> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [Touch initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<Touch> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <Touch>[]);

  // -- end List<Touch> mixins.


  /** @domName TouchList.item */
  Touch item(int index) native "TouchList_item_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLTrackElement
class TrackElement extends _Element_Merged {

  factory TrackElement() => document.$dom_createElement("track");
  TrackElement.internal(): super.internal();

  static const int ERROR = 3;

  static const int LOADED = 2;

  static const int LOADING = 1;

  static const int NONE = 0;


  /** @domName HTMLTrackElement.default */
  bool get defaultValue native "HTMLTrackElement_default_Getter";


  /** @domName HTMLTrackElement.default */
  void set defaultValue(bool value) native "HTMLTrackElement_default_Setter";


  /** @domName HTMLTrackElement.kind */
  String get kind native "HTMLTrackElement_kind_Getter";


  /** @domName HTMLTrackElement.kind */
  void set kind(String value) native "HTMLTrackElement_kind_Setter";


  /** @domName HTMLTrackElement.label */
  String get label native "HTMLTrackElement_label_Getter";


  /** @domName HTMLTrackElement.label */
  void set label(String value) native "HTMLTrackElement_label_Setter";


  /** @domName HTMLTrackElement.readyState */
  int get readyState native "HTMLTrackElement_readyState_Getter";


  /** @domName HTMLTrackElement.src */
  String get src native "HTMLTrackElement_src_Getter";


  /** @domName HTMLTrackElement.src */
  void set src(String value) native "HTMLTrackElement_src_Setter";


  /** @domName HTMLTrackElement.srclang */
  String get srclang native "HTMLTrackElement_srclang_Getter";


  /** @domName HTMLTrackElement.srclang */
  void set srclang(String value) native "HTMLTrackElement_srclang_Setter";


  /** @domName HTMLTrackElement.track */
  TextTrack get track native "HTMLTrackElement_track_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName TrackEvent
class TrackEvent extends Event {
  TrackEvent.internal(): super.internal();


  /** @domName TrackEvent.track */
  Object get track native "TrackEvent_track_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WebKitTransitionEvent
class TransitionEvent extends Event {
  TransitionEvent.internal(): super.internal();


  /** @domName WebKitTransitionEvent.elapsedTime */
  num get elapsedTime native "WebKitTransitionEvent_elapsedTime_Getter";


  /** @domName WebKitTransitionEvent.propertyName */
  String get propertyName native "WebKitTransitionEvent_propertyName_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName TreeWalker
class TreeWalker extends NativeFieldWrapperClass1 {
  TreeWalker.internal();


  /** @domName TreeWalker.currentNode */
  Node get currentNode native "TreeWalker_currentNode_Getter";


  /** @domName TreeWalker.currentNode */
  void set currentNode(Node value) native "TreeWalker_currentNode_Setter";


  /** @domName TreeWalker.expandEntityReferences */
  bool get expandEntityReferences native "TreeWalker_expandEntityReferences_Getter";


  /** @domName TreeWalker.filter */
  NodeFilter get filter native "TreeWalker_filter_Getter";


  /** @domName TreeWalker.root */
  Node get root native "TreeWalker_root_Getter";


  /** @domName TreeWalker.whatToShow */
  int get whatToShow native "TreeWalker_whatToShow_Getter";


  /** @domName TreeWalker.firstChild */
  Node firstChild() native "TreeWalker_firstChild_Callback";


  /** @domName TreeWalker.lastChild */
  Node lastChild() native "TreeWalker_lastChild_Callback";


  /** @domName TreeWalker.nextNode */
  Node nextNode() native "TreeWalker_nextNode_Callback";


  /** @domName TreeWalker.nextSibling */
  Node nextSibling() native "TreeWalker_nextSibling_Callback";


  /** @domName TreeWalker.parentNode */
  Node parentNode() native "TreeWalker_parentNode_Callback";


  /** @domName TreeWalker.previousNode */
  Node previousNode() native "TreeWalker_previousNode_Callback";


  /** @domName TreeWalker.previousSibling */
  Node previousSibling() native "TreeWalker_previousSibling_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName UIEvent
class UIEvent extends Event {
  UIEvent.internal(): super.internal();


  /** @domName UIEvent.charCode */
  int get charCode native "UIEvent_charCode_Getter";


  /** @domName UIEvent.detail */
  int get detail native "UIEvent_detail_Getter";


  /** @domName UIEvent.keyCode */
  int get keyCode native "UIEvent_keyCode_Getter";


  /** @domName UIEvent.layerX */
  int get layerX native "UIEvent_layerX_Getter";


  /** @domName UIEvent.layerY */
  int get layerY native "UIEvent_layerY_Getter";


  /** @domName UIEvent.pageX */
  int get pageX native "UIEvent_pageX_Getter";


  /** @domName UIEvent.pageY */
  int get pageY native "UIEvent_pageY_Getter";


  /** @domName UIEvent.view */
  Window get view native "UIEvent_view_Getter";


  /** @domName UIEvent.which */
  int get which native "UIEvent_which_Getter";


  /** @domName UIEvent.initUIEvent */
  void initUIEvent(String type, bool canBubble, bool cancelable, LocalWindow view, int detail) native "UIEvent_initUIEvent_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLUListElement
class UListElement extends _Element_Merged {

  factory UListElement() => document.$dom_createElement("ul");
  UListElement.internal(): super.internal();


  /** @domName HTMLUListElement.compact */
  bool get compact native "HTMLUListElement_compact_Getter";


  /** @domName HTMLUListElement.compact */
  void set compact(bool value) native "HTMLUListElement_compact_Setter";


  /** @domName HTMLUListElement.type */
  String get type native "HTMLUListElement_type_Getter";


  /** @domName HTMLUListElement.type */
  void set type(String value) native "HTMLUListElement_type_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Uint16Array
class Uint16Array extends ArrayBufferView implements List<int> {

  factory Uint16Array(int length) =>
    _TypedArrayFactoryProvider.createUint16Array(length);

  factory Uint16Array.fromList(List<int> list) =>
    _TypedArrayFactoryProvider.createUint16Array_fromList(list);

  factory Uint16Array.fromBuffer(ArrayBuffer buffer, [int byteOffset, int length]) => 
    _TypedArrayFactoryProvider.createUint16Array_fromBuffer(buffer, byteOffset, length);
  Uint16Array.internal(): super.internal();

  static const int BYTES_PER_ELEMENT = 2;


  /** @domName Uint16Array.length */
  int get length native "Uint16Array_length_Getter";


  /** @domName Uint16Array.numericIndexGetter */
  int operator[](int index) native "Uint16Array_numericIndexGetter_Callback";


  /** @domName Uint16Array.numericIndexSetter */
  void operator[]=(int index, int value) native "Uint16Array_numericIndexSetter_Callback";
  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<int>(this);
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<int> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(int element) => _Collections.contains(this, element);

  void forEach(void f(int element)) => _Collections.forEach(this, f);

  Collection map(f(int element)) => _Collections.map(this, [], f);

  Collection<int> filter(bool f(int element)) =>
     _Collections.filter(this, <int>[], f);

  bool every(bool f(int element)) => _Collections.every(this, f);

  bool some(bool f(int element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<int>:

  void sort([Comparator<int> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int get first => this[0];

  int get last => this[length - 1];

  int removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<int> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [int initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<int> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <int>[]);

  // -- end List<int> mixins.


  /** @domName Uint16Array.setElements */
  void setElements(Object array, [int offset]) native "Uint16Array_setElements_Callback";

  Uint16Array subarray(/*long*/ start, [/*long*/ end]) {
    if (?end) {
      return _subarray_1(start, end);
    }
    return _subarray_2(start);
  }


  /** @domName Uint16Array.subarray_1 */
  Uint16Array _subarray_1(start, end) native "Uint16Array_subarray_1_Callback";


  /** @domName Uint16Array.subarray_2 */
  Uint16Array _subarray_2(start) native "Uint16Array_subarray_2_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Uint32Array
class Uint32Array extends ArrayBufferView implements List<int> {

  factory Uint32Array(int length) =>
    _TypedArrayFactoryProvider.createUint32Array(length);

  factory Uint32Array.fromList(List<int> list) =>
    _TypedArrayFactoryProvider.createUint32Array_fromList(list);

  factory Uint32Array.fromBuffer(ArrayBuffer buffer, [int byteOffset, int length]) => 
    _TypedArrayFactoryProvider.createUint32Array_fromBuffer(buffer, byteOffset, length);
  Uint32Array.internal(): super.internal();

  static const int BYTES_PER_ELEMENT = 4;


  /** @domName Uint32Array.length */
  int get length native "Uint32Array_length_Getter";


  /** @domName Uint32Array.numericIndexGetter */
  int operator[](int index) native "Uint32Array_numericIndexGetter_Callback";


  /** @domName Uint32Array.numericIndexSetter */
  void operator[]=(int index, int value) native "Uint32Array_numericIndexSetter_Callback";
  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<int>(this);
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<int> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(int element) => _Collections.contains(this, element);

  void forEach(void f(int element)) => _Collections.forEach(this, f);

  Collection map(f(int element)) => _Collections.map(this, [], f);

  Collection<int> filter(bool f(int element)) =>
     _Collections.filter(this, <int>[], f);

  bool every(bool f(int element)) => _Collections.every(this, f);

  bool some(bool f(int element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<int>:

  void sort([Comparator<int> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int get first => this[0];

  int get last => this[length - 1];

  int removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<int> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [int initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<int> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <int>[]);

  // -- end List<int> mixins.


  /** @domName Uint32Array.setElements */
  void setElements(Object array, [int offset]) native "Uint32Array_setElements_Callback";

  Uint32Array subarray(/*long*/ start, [/*long*/ end]) {
    if (?end) {
      return _subarray_1(start, end);
    }
    return _subarray_2(start);
  }


  /** @domName Uint32Array.subarray_1 */
  Uint32Array _subarray_1(start, end) native "Uint32Array_subarray_1_Callback";


  /** @domName Uint32Array.subarray_2 */
  Uint32Array _subarray_2(start) native "Uint32Array_subarray_2_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Uint8Array
class Uint8Array extends ArrayBufferView implements List<int> {

  factory Uint8Array(int length) =>
    _TypedArrayFactoryProvider.createUint8Array(length);

  factory Uint8Array.fromList(List<int> list) =>
    _TypedArrayFactoryProvider.createUint8Array_fromList(list);

  factory Uint8Array.fromBuffer(ArrayBuffer buffer, [int byteOffset, int length]) => 
    _TypedArrayFactoryProvider.createUint8Array_fromBuffer(buffer, byteOffset, length);
  Uint8Array.internal(): super.internal();

  static const int BYTES_PER_ELEMENT = 1;


  /** @domName Uint8Array.length */
  int get length native "Uint8Array_length_Getter";


  /** @domName Uint8Array.numericIndexGetter */
  int operator[](int index) native "Uint8Array_numericIndexGetter_Callback";


  /** @domName Uint8Array.numericIndexSetter */
  void operator[]=(int index, int value) native "Uint8Array_numericIndexSetter_Callback";
  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<int>(this);
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<int> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(int element) => _Collections.contains(this, element);

  void forEach(void f(int element)) => _Collections.forEach(this, f);

  Collection map(f(int element)) => _Collections.map(this, [], f);

  Collection<int> filter(bool f(int element)) =>
     _Collections.filter(this, <int>[], f);

  bool every(bool f(int element)) => _Collections.every(this, f);

  bool some(bool f(int element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<int>:

  void sort([Comparator<int> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int get first => this[0];

  int get last => this[length - 1];

  int removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<int> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [int initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<int> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <int>[]);

  // -- end List<int> mixins.


  /** @domName Uint8Array.setElements */
  void setElements(Object array, [int offset]) native "Uint8Array_setElements_Callback";

  Uint8Array subarray(/*long*/ start, [/*long*/ end]) {
    if (?end) {
      return _subarray_1(start, end);
    }
    return _subarray_2(start);
  }


  /** @domName Uint8Array.subarray_1 */
  Uint8Array _subarray_1(start, end) native "Uint8Array_subarray_1_Callback";


  /** @domName Uint8Array.subarray_2 */
  Uint8Array _subarray_2(start) native "Uint8Array_subarray_2_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Uint8ClampedArray
class Uint8ClampedArray extends Uint8Array {

  factory Uint8ClampedArray(int length) =>
    _TypedArrayFactoryProvider.createUint8ClampedArray(length);

  factory Uint8ClampedArray.fromList(List<int> list) =>
    _TypedArrayFactoryProvider.createUint8ClampedArray_fromList(list);

  factory Uint8ClampedArray.fromBuffer(ArrayBuffer buffer, [int byteOffset, int length]) => 
    _TypedArrayFactoryProvider.createUint8ClampedArray_fromBuffer(buffer, byteOffset, length);
  Uint8ClampedArray.internal(): super.internal();


  /** @domName Uint8ClampedArray.length */
  int get length native "Uint8ClampedArray_length_Getter";


  /** @domName Uint8ClampedArray.numericIndexGetter */
  int operator[](int index) native "Uint8ClampedArray_numericIndexGetter_Callback";


  /** @domName Uint8ClampedArray.numericIndexSetter */
  void operator[]=(int index, int value) native "Uint8ClampedArray_numericIndexSetter_Callback";


  /** @domName Uint8ClampedArray.setElements */
  void setElements(Object array, [int offset]) native "Uint8ClampedArray_setElements_Callback";

  Uint8ClampedArray subarray(/*long*/ start, [/*long*/ end]) {
    if (?end) {
      return _subarray_1(start, end);
    }
    return _subarray_2(start);
  }


  /** @domName Uint8ClampedArray.subarray_1 */
  Uint8ClampedArray _subarray_1(start, end) native "Uint8ClampedArray_subarray_1_Callback";


  /** @domName Uint8ClampedArray.subarray_2 */
  Uint8ClampedArray _subarray_2(start) native "Uint8ClampedArray_subarray_2_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLUnknownElement
class UnknownElement extends _Element_Merged {
  UnknownElement.internal(): super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName URL
class Url extends NativeFieldWrapperClass1 {
  Url.internal();

  static String createObjectUrl(blob_OR_source_OR_stream) {
    if ((blob_OR_source_OR_stream is MediaSource || blob_OR_source_OR_stream == null)) {
      return _createObjectURL_1(blob_OR_source_OR_stream);
    }
    if ((blob_OR_source_OR_stream is MediaStream || blob_OR_source_OR_stream == null)) {
      return _createObjectURL_2(blob_OR_source_OR_stream);
    }
    if ((blob_OR_source_OR_stream is Blob || blob_OR_source_OR_stream == null)) {
      return _createObjectURL_3(blob_OR_source_OR_stream);
    }
    throw "Incorrect number or type of arguments";
  }


  /** @domName DOMURL.createObjectURL_1 */
  static String _createObjectURL_1(blob_OR_source_OR_stream) native "DOMURL_createObjectURL_1_Callback";


  /** @domName DOMURL.createObjectURL_2 */
  static String _createObjectURL_2(blob_OR_source_OR_stream) native "DOMURL_createObjectURL_2_Callback";


  /** @domName DOMURL.createObjectURL_3 */
  static String _createObjectURL_3(blob_OR_source_OR_stream) native "DOMURL_createObjectURL_3_Callback";


  /** @domName DOMURL.revokeObjectURL */
  static void revokeObjectUrl(String url) native "DOMURL_revokeObjectURL_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName ValidityState
class ValidityState extends NativeFieldWrapperClass1 {
  ValidityState.internal();


  /** @domName ValidityState.customError */
  bool get customError native "ValidityState_customError_Getter";


  /** @domName ValidityState.patternMismatch */
  bool get patternMismatch native "ValidityState_patternMismatch_Getter";


  /** @domName ValidityState.rangeOverflow */
  bool get rangeOverflow native "ValidityState_rangeOverflow_Getter";


  /** @domName ValidityState.rangeUnderflow */
  bool get rangeUnderflow native "ValidityState_rangeUnderflow_Getter";


  /** @domName ValidityState.stepMismatch */
  bool get stepMismatch native "ValidityState_stepMismatch_Getter";


  /** @domName ValidityState.tooLong */
  bool get tooLong native "ValidityState_tooLong_Getter";


  /** @domName ValidityState.typeMismatch */
  bool get typeMismatch native "ValidityState_typeMismatch_Getter";


  /** @domName ValidityState.valid */
  bool get valid native "ValidityState_valid_Getter";


  /** @domName ValidityState.valueMissing */
  bool get valueMissing native "ValidityState_valueMissing_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLVideoElement
class VideoElement extends MediaElement {

  factory VideoElement() => document.$dom_createElement("video");
  VideoElement.internal(): super.internal();


  /** @domName HTMLVideoElement.height */
  int get height native "HTMLVideoElement_height_Getter";


  /** @domName HTMLVideoElement.height */
  void set height(int value) native "HTMLVideoElement_height_Setter";


  /** @domName HTMLVideoElement.poster */
  String get poster native "HTMLVideoElement_poster_Getter";


  /** @domName HTMLVideoElement.poster */
  void set poster(String value) native "HTMLVideoElement_poster_Setter";


  /** @domName HTMLVideoElement.videoHeight */
  int get videoHeight native "HTMLVideoElement_videoHeight_Getter";


  /** @domName HTMLVideoElement.videoWidth */
  int get videoWidth native "HTMLVideoElement_videoWidth_Getter";


  /** @domName HTMLVideoElement.webkitDecodedFrameCount */
  int get webkitDecodedFrameCount native "HTMLVideoElement_webkitDecodedFrameCount_Getter";


  /** @domName HTMLVideoElement.webkitDisplayingFullscreen */
  bool get webkitDisplayingFullscreen native "HTMLVideoElement_webkitDisplayingFullscreen_Getter";


  /** @domName HTMLVideoElement.webkitDroppedFrameCount */
  int get webkitDroppedFrameCount native "HTMLVideoElement_webkitDroppedFrameCount_Getter";


  /** @domName HTMLVideoElement.webkitSupportsFullscreen */
  bool get webkitSupportsFullscreen native "HTMLVideoElement_webkitSupportsFullscreen_Getter";


  /** @domName HTMLVideoElement.width */
  int get width native "HTMLVideoElement_width_Getter";


  /** @domName HTMLVideoElement.width */
  void set width(int value) native "HTMLVideoElement_width_Setter";


  /** @domName HTMLVideoElement.webkitEnterFullScreen */
  void webkitEnterFullScreen() native "HTMLVideoElement_webkitEnterFullScreen_Callback";


  /** @domName HTMLVideoElement.webkitEnterFullscreen */
  void webkitEnterFullscreen() native "HTMLVideoElement_webkitEnterFullscreen_Callback";


  /** @domName HTMLVideoElement.webkitExitFullScreen */
  void webkitExitFullScreen() native "HTMLVideoElement_webkitExitFullScreen_Callback";


  /** @domName HTMLVideoElement.webkitExitFullscreen */
  void webkitExitFullscreen() native "HTMLVideoElement_webkitExitFullscreen_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void VoidCallback();
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WaveShaperNode
class WaveShaperNode extends AudioNode {
  WaveShaperNode.internal(): super.internal();


  /** @domName WaveShaperNode.curve */
  Float32Array get curve native "WaveShaperNode_curve_Getter";


  /** @domName WaveShaperNode.curve */
  void set curve(Float32Array value) native "WaveShaperNode_curve_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WaveTable
class WaveTable extends NativeFieldWrapperClass1 {
  WaveTable.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WebGLActiveInfo
class WebGLActiveInfo extends NativeFieldWrapperClass1 {
  WebGLActiveInfo.internal();


  /** @domName WebGLActiveInfo.name */
  String get name native "WebGLActiveInfo_name_Getter";


  /** @domName WebGLActiveInfo.size */
  int get size native "WebGLActiveInfo_size_Getter";


  /** @domName WebGLActiveInfo.type */
  int get type native "WebGLActiveInfo_type_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WebGLBuffer
class WebGLBuffer extends NativeFieldWrapperClass1 {
  WebGLBuffer.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WebGLCompressedTextureS3TC
class WebGLCompressedTextureS3TC extends NativeFieldWrapperClass1 {
  WebGLCompressedTextureS3TC.internal();

  static const int COMPRESSED_RGBA_S3TC_DXT1_EXT = 0x83F1;

  static const int COMPRESSED_RGBA_S3TC_DXT3_EXT = 0x83F2;

  static const int COMPRESSED_RGBA_S3TC_DXT5_EXT = 0x83F3;

  static const int COMPRESSED_RGB_S3TC_DXT1_EXT = 0x83F0;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WebGLContextAttributes
class WebGLContextAttributes extends NativeFieldWrapperClass1 {
  WebGLContextAttributes.internal();


  /** @domName WebGLContextAttributes.alpha */
  bool get alpha native "WebGLContextAttributes_alpha_Getter";


  /** @domName WebGLContextAttributes.alpha */
  void set alpha(bool value) native "WebGLContextAttributes_alpha_Setter";


  /** @domName WebGLContextAttributes.antialias */
  bool get antialias native "WebGLContextAttributes_antialias_Getter";


  /** @domName WebGLContextAttributes.antialias */
  void set antialias(bool value) native "WebGLContextAttributes_antialias_Setter";


  /** @domName WebGLContextAttributes.depth */
  bool get depth native "WebGLContextAttributes_depth_Getter";


  /** @domName WebGLContextAttributes.depth */
  void set depth(bool value) native "WebGLContextAttributes_depth_Setter";


  /** @domName WebGLContextAttributes.premultipliedAlpha */
  bool get premultipliedAlpha native "WebGLContextAttributes_premultipliedAlpha_Getter";


  /** @domName WebGLContextAttributes.premultipliedAlpha */
  void set premultipliedAlpha(bool value) native "WebGLContextAttributes_premultipliedAlpha_Setter";


  /** @domName WebGLContextAttributes.preserveDrawingBuffer */
  bool get preserveDrawingBuffer native "WebGLContextAttributes_preserveDrawingBuffer_Getter";


  /** @domName WebGLContextAttributes.preserveDrawingBuffer */
  void set preserveDrawingBuffer(bool value) native "WebGLContextAttributes_preserveDrawingBuffer_Setter";


  /** @domName WebGLContextAttributes.stencil */
  bool get stencil native "WebGLContextAttributes_stencil_Getter";


  /** @domName WebGLContextAttributes.stencil */
  void set stencil(bool value) native "WebGLContextAttributes_stencil_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WebGLContextEvent
class WebGLContextEvent extends Event {
  WebGLContextEvent.internal(): super.internal();


  /** @domName WebGLContextEvent.statusMessage */
  String get statusMessage native "WebGLContextEvent_statusMessage_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WebGLDebugRendererInfo
class WebGLDebugRendererInfo extends NativeFieldWrapperClass1 {
  WebGLDebugRendererInfo.internal();

  static const int UNMASKED_RENDERER_WEBGL = 0x9246;

  static const int UNMASKED_VENDOR_WEBGL = 0x9245;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WebGLDebugShaders
class WebGLDebugShaders extends NativeFieldWrapperClass1 {
  WebGLDebugShaders.internal();


  /** @domName WebGLDebugShaders.getTranslatedShaderSource */
  String getTranslatedShaderSource(WebGLShader shader) native "WebGLDebugShaders_getTranslatedShaderSource_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WebGLDepthTexture
class WebGLDepthTexture extends NativeFieldWrapperClass1 {
  WebGLDepthTexture.internal();

  static const int UNSIGNED_INT_24_8_WEBGL = 0x84FA;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WebGLFramebuffer
class WebGLFramebuffer extends NativeFieldWrapperClass1 {
  WebGLFramebuffer.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WebGLLoseContext
class WebGLLoseContext extends NativeFieldWrapperClass1 {
  WebGLLoseContext.internal();


  /** @domName WebGLLoseContext.loseContext */
  void loseContext() native "WebGLLoseContext_loseContext_Callback";


  /** @domName WebGLLoseContext.restoreContext */
  void restoreContext() native "WebGLLoseContext_restoreContext_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WebGLProgram
class WebGLProgram extends NativeFieldWrapperClass1 {
  WebGLProgram.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WebGLRenderbuffer
class WebGLRenderbuffer extends NativeFieldWrapperClass1 {
  WebGLRenderbuffer.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WebGLRenderingContext
class WebGLRenderingContext extends CanvasRenderingContext {
  WebGLRenderingContext.internal(): super.internal();

  static const int ACTIVE_ATTRIBUTES = 0x8B89;

  static const int ACTIVE_TEXTURE = 0x84E0;

  static const int ACTIVE_UNIFORMS = 0x8B86;

  static const int ALIASED_LINE_WIDTH_RANGE = 0x846E;

  static const int ALIASED_POINT_SIZE_RANGE = 0x846D;

  static const int ALPHA = 0x1906;

  static const int ALPHA_BITS = 0x0D55;

  static const int ALWAYS = 0x0207;

  static const int ARRAY_BUFFER = 0x8892;

  static const int ARRAY_BUFFER_BINDING = 0x8894;

  static const int ATTACHED_SHADERS = 0x8B85;

  static const int BACK = 0x0405;

  static const int BLEND = 0x0BE2;

  static const int BLEND_COLOR = 0x8005;

  static const int BLEND_DST_ALPHA = 0x80CA;

  static const int BLEND_DST_RGB = 0x80C8;

  static const int BLEND_EQUATION = 0x8009;

  static const int BLEND_EQUATION_ALPHA = 0x883D;

  static const int BLEND_EQUATION_RGB = 0x8009;

  static const int BLEND_SRC_ALPHA = 0x80CB;

  static const int BLEND_SRC_RGB = 0x80C9;

  static const int BLUE_BITS = 0x0D54;

  static const int BOOL = 0x8B56;

  static const int BOOL_VEC2 = 0x8B57;

  static const int BOOL_VEC3 = 0x8B58;

  static const int BOOL_VEC4 = 0x8B59;

  static const int BROWSER_DEFAULT_WEBGL = 0x9244;

  static const int BUFFER_SIZE = 0x8764;

  static const int BUFFER_USAGE = 0x8765;

  static const int BYTE = 0x1400;

  static const int CCW = 0x0901;

  static const int CLAMP_TO_EDGE = 0x812F;

  static const int COLOR_ATTACHMENT0 = 0x8CE0;

  static const int COLOR_BUFFER_BIT = 0x00004000;

  static const int COLOR_CLEAR_VALUE = 0x0C22;

  static const int COLOR_WRITEMASK = 0x0C23;

  static const int COMPILE_STATUS = 0x8B81;

  static const int COMPRESSED_TEXTURE_FORMATS = 0x86A3;

  static const int CONSTANT_ALPHA = 0x8003;

  static const int CONSTANT_COLOR = 0x8001;

  static const int CONTEXT_LOST_WEBGL = 0x9242;

  static const int CULL_FACE = 0x0B44;

  static const int CULL_FACE_MODE = 0x0B45;

  static const int CURRENT_PROGRAM = 0x8B8D;

  static const int CURRENT_VERTEX_ATTRIB = 0x8626;

  static const int CW = 0x0900;

  static const int DECR = 0x1E03;

  static const int DECR_WRAP = 0x8508;

  static const int DELETE_STATUS = 0x8B80;

  static const int DEPTH_ATTACHMENT = 0x8D00;

  static const int DEPTH_BITS = 0x0D56;

  static const int DEPTH_BUFFER_BIT = 0x00000100;

  static const int DEPTH_CLEAR_VALUE = 0x0B73;

  static const int DEPTH_COMPONENT = 0x1902;

  static const int DEPTH_COMPONENT16 = 0x81A5;

  static const int DEPTH_FUNC = 0x0B74;

  static const int DEPTH_RANGE = 0x0B70;

  static const int DEPTH_STENCIL = 0x84F9;

  static const int DEPTH_STENCIL_ATTACHMENT = 0x821A;

  static const int DEPTH_TEST = 0x0B71;

  static const int DEPTH_WRITEMASK = 0x0B72;

  static const int DITHER = 0x0BD0;

  static const int DONT_CARE = 0x1100;

  static const int DST_ALPHA = 0x0304;

  static const int DST_COLOR = 0x0306;

  static const int DYNAMIC_DRAW = 0x88E8;

  static const int ELEMENT_ARRAY_BUFFER = 0x8893;

  static const int ELEMENT_ARRAY_BUFFER_BINDING = 0x8895;

  static const int EQUAL = 0x0202;

  static const int FASTEST = 0x1101;

  static const int FLOAT = 0x1406;

  static const int FLOAT_MAT2 = 0x8B5A;

  static const int FLOAT_MAT3 = 0x8B5B;

  static const int FLOAT_MAT4 = 0x8B5C;

  static const int FLOAT_VEC2 = 0x8B50;

  static const int FLOAT_VEC3 = 0x8B51;

  static const int FLOAT_VEC4 = 0x8B52;

  static const int FRAGMENT_SHADER = 0x8B30;

  static const int FRAMEBUFFER = 0x8D40;

  static const int FRAMEBUFFER_ATTACHMENT_OBJECT_NAME = 0x8CD1;

  static const int FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE = 0x8CD0;

  static const int FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE = 0x8CD3;

  static const int FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL = 0x8CD2;

  static const int FRAMEBUFFER_BINDING = 0x8CA6;

  static const int FRAMEBUFFER_COMPLETE = 0x8CD5;

  static const int FRAMEBUFFER_INCOMPLETE_ATTACHMENT = 0x8CD6;

  static const int FRAMEBUFFER_INCOMPLETE_DIMENSIONS = 0x8CD9;

  static const int FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT = 0x8CD7;

  static const int FRAMEBUFFER_UNSUPPORTED = 0x8CDD;

  static const int FRONT = 0x0404;

  static const int FRONT_AND_BACK = 0x0408;

  static const int FRONT_FACE = 0x0B46;

  static const int FUNC_ADD = 0x8006;

  static const int FUNC_REVERSE_SUBTRACT = 0x800B;

  static const int FUNC_SUBTRACT = 0x800A;

  static const int GENERATE_MIPMAP_HINT = 0x8192;

  static const int GEQUAL = 0x0206;

  static const int GREATER = 0x0204;

  static const int GREEN_BITS = 0x0D53;

  static const int HIGH_FLOAT = 0x8DF2;

  static const int HIGH_INT = 0x8DF5;

  static const int INCR = 0x1E02;

  static const int INCR_WRAP = 0x8507;

  static const int INT = 0x1404;

  static const int INT_VEC2 = 0x8B53;

  static const int INT_VEC3 = 0x8B54;

  static const int INT_VEC4 = 0x8B55;

  static const int INVALID_ENUM = 0x0500;

  static const int INVALID_FRAMEBUFFER_OPERATION = 0x0506;

  static const int INVALID_OPERATION = 0x0502;

  static const int INVALID_VALUE = 0x0501;

  static const int INVERT = 0x150A;

  static const int KEEP = 0x1E00;

  static const int LEQUAL = 0x0203;

  static const int LESS = 0x0201;

  static const int LINEAR = 0x2601;

  static const int LINEAR_MIPMAP_LINEAR = 0x2703;

  static const int LINEAR_MIPMAP_NEAREST = 0x2701;

  static const int LINES = 0x0001;

  static const int LINE_LOOP = 0x0002;

  static const int LINE_STRIP = 0x0003;

  static const int LINE_WIDTH = 0x0B21;

  static const int LINK_STATUS = 0x8B82;

  static const int LOW_FLOAT = 0x8DF0;

  static const int LOW_INT = 0x8DF3;

  static const int LUMINANCE = 0x1909;

  static const int LUMINANCE_ALPHA = 0x190A;

  static const int MAX_COMBINED_TEXTURE_IMAGE_UNITS = 0x8B4D;

  static const int MAX_CUBE_MAP_TEXTURE_SIZE = 0x851C;

  static const int MAX_FRAGMENT_UNIFORM_VECTORS = 0x8DFD;

  static const int MAX_RENDERBUFFER_SIZE = 0x84E8;

  static const int MAX_TEXTURE_IMAGE_UNITS = 0x8872;

  static const int MAX_TEXTURE_SIZE = 0x0D33;

  static const int MAX_VARYING_VECTORS = 0x8DFC;

  static const int MAX_VERTEX_ATTRIBS = 0x8869;

  static const int MAX_VERTEX_TEXTURE_IMAGE_UNITS = 0x8B4C;

  static const int MAX_VERTEX_UNIFORM_VECTORS = 0x8DFB;

  static const int MAX_VIEWPORT_DIMS = 0x0D3A;

  static const int MEDIUM_FLOAT = 0x8DF1;

  static const int MEDIUM_INT = 0x8DF4;

  static const int MIRRORED_REPEAT = 0x8370;

  static const int NEAREST = 0x2600;

  static const int NEAREST_MIPMAP_LINEAR = 0x2702;

  static const int NEAREST_MIPMAP_NEAREST = 0x2700;

  static const int NEVER = 0x0200;

  static const int NICEST = 0x1102;

  static const int NONE = 0;

  static const int NOTEQUAL = 0x0205;

  static const int NO_ERROR = 0;

  static const int ONE = 1;

  static const int ONE_MINUS_CONSTANT_ALPHA = 0x8004;

  static const int ONE_MINUS_CONSTANT_COLOR = 0x8002;

  static const int ONE_MINUS_DST_ALPHA = 0x0305;

  static const int ONE_MINUS_DST_COLOR = 0x0307;

  static const int ONE_MINUS_SRC_ALPHA = 0x0303;

  static const int ONE_MINUS_SRC_COLOR = 0x0301;

  static const int OUT_OF_MEMORY = 0x0505;

  static const int PACK_ALIGNMENT = 0x0D05;

  static const int POINTS = 0x0000;

  static const int POLYGON_OFFSET_FACTOR = 0x8038;

  static const int POLYGON_OFFSET_FILL = 0x8037;

  static const int POLYGON_OFFSET_UNITS = 0x2A00;

  static const int RED_BITS = 0x0D52;

  static const int RENDERBUFFER = 0x8D41;

  static const int RENDERBUFFER_ALPHA_SIZE = 0x8D53;

  static const int RENDERBUFFER_BINDING = 0x8CA7;

  static const int RENDERBUFFER_BLUE_SIZE = 0x8D52;

  static const int RENDERBUFFER_DEPTH_SIZE = 0x8D54;

  static const int RENDERBUFFER_GREEN_SIZE = 0x8D51;

  static const int RENDERBUFFER_HEIGHT = 0x8D43;

  static const int RENDERBUFFER_INTERNAL_FORMAT = 0x8D44;

  static const int RENDERBUFFER_RED_SIZE = 0x8D50;

  static const int RENDERBUFFER_STENCIL_SIZE = 0x8D55;

  static const int RENDERBUFFER_WIDTH = 0x8D42;

  static const int RENDERER = 0x1F01;

  static const int REPEAT = 0x2901;

  static const int REPLACE = 0x1E01;

  static const int RGB = 0x1907;

  static const int RGB565 = 0x8D62;

  static const int RGB5_A1 = 0x8057;

  static const int RGBA = 0x1908;

  static const int RGBA4 = 0x8056;

  static const int SAMPLER_2D = 0x8B5E;

  static const int SAMPLER_CUBE = 0x8B60;

  static const int SAMPLES = 0x80A9;

  static const int SAMPLE_ALPHA_TO_COVERAGE = 0x809E;

  static const int SAMPLE_BUFFERS = 0x80A8;

  static const int SAMPLE_COVERAGE = 0x80A0;

  static const int SAMPLE_COVERAGE_INVERT = 0x80AB;

  static const int SAMPLE_COVERAGE_VALUE = 0x80AA;

  static const int SCISSOR_BOX = 0x0C10;

  static const int SCISSOR_TEST = 0x0C11;

  static const int SHADER_TYPE = 0x8B4F;

  static const int SHADING_LANGUAGE_VERSION = 0x8B8C;

  static const int SHORT = 0x1402;

  static const int SRC_ALPHA = 0x0302;

  static const int SRC_ALPHA_SATURATE = 0x0308;

  static const int SRC_COLOR = 0x0300;

  static const int STATIC_DRAW = 0x88E4;

  static const int STENCIL_ATTACHMENT = 0x8D20;

  static const int STENCIL_BACK_FAIL = 0x8801;

  static const int STENCIL_BACK_FUNC = 0x8800;

  static const int STENCIL_BACK_PASS_DEPTH_FAIL = 0x8802;

  static const int STENCIL_BACK_PASS_DEPTH_PASS = 0x8803;

  static const int STENCIL_BACK_REF = 0x8CA3;

  static const int STENCIL_BACK_VALUE_MASK = 0x8CA4;

  static const int STENCIL_BACK_WRITEMASK = 0x8CA5;

  static const int STENCIL_BITS = 0x0D57;

  static const int STENCIL_BUFFER_BIT = 0x00000400;

  static const int STENCIL_CLEAR_VALUE = 0x0B91;

  static const int STENCIL_FAIL = 0x0B94;

  static const int STENCIL_FUNC = 0x0B92;

  static const int STENCIL_INDEX = 0x1901;

  static const int STENCIL_INDEX8 = 0x8D48;

  static const int STENCIL_PASS_DEPTH_FAIL = 0x0B95;

  static const int STENCIL_PASS_DEPTH_PASS = 0x0B96;

  static const int STENCIL_REF = 0x0B97;

  static const int STENCIL_TEST = 0x0B90;

  static const int STENCIL_VALUE_MASK = 0x0B93;

  static const int STENCIL_WRITEMASK = 0x0B98;

  static const int STREAM_DRAW = 0x88E0;

  static const int SUBPIXEL_BITS = 0x0D50;

  static const int TEXTURE = 0x1702;

  static const int TEXTURE0 = 0x84C0;

  static const int TEXTURE1 = 0x84C1;

  static const int TEXTURE10 = 0x84CA;

  static const int TEXTURE11 = 0x84CB;

  static const int TEXTURE12 = 0x84CC;

  static const int TEXTURE13 = 0x84CD;

  static const int TEXTURE14 = 0x84CE;

  static const int TEXTURE15 = 0x84CF;

  static const int TEXTURE16 = 0x84D0;

  static const int TEXTURE17 = 0x84D1;

  static const int TEXTURE18 = 0x84D2;

  static const int TEXTURE19 = 0x84D3;

  static const int TEXTURE2 = 0x84C2;

  static const int TEXTURE20 = 0x84D4;

  static const int TEXTURE21 = 0x84D5;

  static const int TEXTURE22 = 0x84D6;

  static const int TEXTURE23 = 0x84D7;

  static const int TEXTURE24 = 0x84D8;

  static const int TEXTURE25 = 0x84D9;

  static const int TEXTURE26 = 0x84DA;

  static const int TEXTURE27 = 0x84DB;

  static const int TEXTURE28 = 0x84DC;

  static const int TEXTURE29 = 0x84DD;

  static const int TEXTURE3 = 0x84C3;

  static const int TEXTURE30 = 0x84DE;

  static const int TEXTURE31 = 0x84DF;

  static const int TEXTURE4 = 0x84C4;

  static const int TEXTURE5 = 0x84C5;

  static const int TEXTURE6 = 0x84C6;

  static const int TEXTURE7 = 0x84C7;

  static const int TEXTURE8 = 0x84C8;

  static const int TEXTURE9 = 0x84C9;

  static const int TEXTURE_2D = 0x0DE1;

  static const int TEXTURE_BINDING_2D = 0x8069;

  static const int TEXTURE_BINDING_CUBE_MAP = 0x8514;

  static const int TEXTURE_CUBE_MAP = 0x8513;

  static const int TEXTURE_CUBE_MAP_NEGATIVE_X = 0x8516;

  static const int TEXTURE_CUBE_MAP_NEGATIVE_Y = 0x8518;

  static const int TEXTURE_CUBE_MAP_NEGATIVE_Z = 0x851A;

  static const int TEXTURE_CUBE_MAP_POSITIVE_X = 0x8515;

  static const int TEXTURE_CUBE_MAP_POSITIVE_Y = 0x8517;

  static const int TEXTURE_CUBE_MAP_POSITIVE_Z = 0x8519;

  static const int TEXTURE_MAG_FILTER = 0x2800;

  static const int TEXTURE_MIN_FILTER = 0x2801;

  static const int TEXTURE_WRAP_S = 0x2802;

  static const int TEXTURE_WRAP_T = 0x2803;

  static const int TRIANGLES = 0x0004;

  static const int TRIANGLE_FAN = 0x0006;

  static const int TRIANGLE_STRIP = 0x0005;

  static const int UNPACK_ALIGNMENT = 0x0CF5;

  static const int UNPACK_COLORSPACE_CONVERSION_WEBGL = 0x9243;

  static const int UNPACK_FLIP_Y_WEBGL = 0x9240;

  static const int UNPACK_PREMULTIPLY_ALPHA_WEBGL = 0x9241;

  static const int UNSIGNED_BYTE = 0x1401;

  static const int UNSIGNED_INT = 0x1405;

  static const int UNSIGNED_SHORT = 0x1403;

  static const int UNSIGNED_SHORT_4_4_4_4 = 0x8033;

  static const int UNSIGNED_SHORT_5_5_5_1 = 0x8034;

  static const int UNSIGNED_SHORT_5_6_5 = 0x8363;

  static const int VALIDATE_STATUS = 0x8B83;

  static const int VENDOR = 0x1F00;

  static const int VERSION = 0x1F02;

  static const int VERTEX_ATTRIB_ARRAY_BUFFER_BINDING = 0x889F;

  static const int VERTEX_ATTRIB_ARRAY_ENABLED = 0x8622;

  static const int VERTEX_ATTRIB_ARRAY_NORMALIZED = 0x886A;

  static const int VERTEX_ATTRIB_ARRAY_POINTER = 0x8645;

  static const int VERTEX_ATTRIB_ARRAY_SIZE = 0x8623;

  static const int VERTEX_ATTRIB_ARRAY_STRIDE = 0x8624;

  static const int VERTEX_ATTRIB_ARRAY_TYPE = 0x8625;

  static const int VERTEX_SHADER = 0x8B31;

  static const int VIEWPORT = 0x0BA2;

  static const int ZERO = 0;


  /** @domName WebGLRenderingContext.drawingBufferHeight */
  int get drawingBufferHeight native "WebGLRenderingContext_drawingBufferHeight_Getter";


  /** @domName WebGLRenderingContext.drawingBufferWidth */
  int get drawingBufferWidth native "WebGLRenderingContext_drawingBufferWidth_Getter";


  /** @domName WebGLRenderingContext.activeTexture */
  void activeTexture(int texture) native "WebGLRenderingContext_activeTexture_Callback";


  /** @domName WebGLRenderingContext.attachShader */
  void attachShader(WebGLProgram program, WebGLShader shader) native "WebGLRenderingContext_attachShader_Callback";


  /** @domName WebGLRenderingContext.bindAttribLocation */
  void bindAttribLocation(WebGLProgram program, int index, String name) native "WebGLRenderingContext_bindAttribLocation_Callback";


  /** @domName WebGLRenderingContext.bindBuffer */
  void bindBuffer(int target, WebGLBuffer buffer) native "WebGLRenderingContext_bindBuffer_Callback";


  /** @domName WebGLRenderingContext.bindFramebuffer */
  void bindFramebuffer(int target, WebGLFramebuffer framebuffer) native "WebGLRenderingContext_bindFramebuffer_Callback";


  /** @domName WebGLRenderingContext.bindRenderbuffer */
  void bindRenderbuffer(int target, WebGLRenderbuffer renderbuffer) native "WebGLRenderingContext_bindRenderbuffer_Callback";


  /** @domName WebGLRenderingContext.bindTexture */
  void bindTexture(int target, WebGLTexture texture) native "WebGLRenderingContext_bindTexture_Callback";


  /** @domName WebGLRenderingContext.blendColor */
  void blendColor(num red, num green, num blue, num alpha) native "WebGLRenderingContext_blendColor_Callback";


  /** @domName WebGLRenderingContext.blendEquation */
  void blendEquation(int mode) native "WebGLRenderingContext_blendEquation_Callback";


  /** @domName WebGLRenderingContext.blendEquationSeparate */
  void blendEquationSeparate(int modeRGB, int modeAlpha) native "WebGLRenderingContext_blendEquationSeparate_Callback";


  /** @domName WebGLRenderingContext.blendFunc */
  void blendFunc(int sfactor, int dfactor) native "WebGLRenderingContext_blendFunc_Callback";


  /** @domName WebGLRenderingContext.blendFuncSeparate */
  void blendFuncSeparate(int srcRGB, int dstRGB, int srcAlpha, int dstAlpha) native "WebGLRenderingContext_blendFuncSeparate_Callback";

  void bufferData(/*unsigned long*/ target, data_OR_size, /*unsigned long*/ usage) {
    if ((target is int || target == null) && (data_OR_size is ArrayBuffer || data_OR_size == null) && (usage is int || usage == null)) {
      _bufferData_1(target, data_OR_size, usage);
      return;
    }
    if ((target is int || target == null) && (data_OR_size is ArrayBufferView || data_OR_size == null) && (usage is int || usage == null)) {
      _bufferData_2(target, data_OR_size, usage);
      return;
    }
    if ((target is int || target == null) && (data_OR_size is int || data_OR_size == null) && (usage is int || usage == null)) {
      _bufferData_3(target, data_OR_size, usage);
      return;
    }
    throw "Incorrect number or type of arguments";
  }


  /** @domName WebGLRenderingContext.bufferData_1 */
  void _bufferData_1(target, data_OR_size, usage) native "WebGLRenderingContext_bufferData_1_Callback";


  /** @domName WebGLRenderingContext.bufferData_2 */
  void _bufferData_2(target, data_OR_size, usage) native "WebGLRenderingContext_bufferData_2_Callback";


  /** @domName WebGLRenderingContext.bufferData_3 */
  void _bufferData_3(target, data_OR_size, usage) native "WebGLRenderingContext_bufferData_3_Callback";

  void bufferSubData(/*unsigned long*/ target, /*long long*/ offset, data) {
    if ((target is int || target == null) && (offset is int || offset == null) && (data is ArrayBuffer || data == null)) {
      _bufferSubData_1(target, offset, data);
      return;
    }
    if ((target is int || target == null) && (offset is int || offset == null) && (data is ArrayBufferView || data == null)) {
      _bufferSubData_2(target, offset, data);
      return;
    }
    throw "Incorrect number or type of arguments";
  }


  /** @domName WebGLRenderingContext.bufferSubData_1 */
  void _bufferSubData_1(target, offset, data) native "WebGLRenderingContext_bufferSubData_1_Callback";


  /** @domName WebGLRenderingContext.bufferSubData_2 */
  void _bufferSubData_2(target, offset, data) native "WebGLRenderingContext_bufferSubData_2_Callback";


  /** @domName WebGLRenderingContext.checkFramebufferStatus */
  int checkFramebufferStatus(int target) native "WebGLRenderingContext_checkFramebufferStatus_Callback";


  /** @domName WebGLRenderingContext.clear */
  void clear(int mask) native "WebGLRenderingContext_clear_Callback";


  /** @domName WebGLRenderingContext.clearColor */
  void clearColor(num red, num green, num blue, num alpha) native "WebGLRenderingContext_clearColor_Callback";


  /** @domName WebGLRenderingContext.clearDepth */
  void clearDepth(num depth) native "WebGLRenderingContext_clearDepth_Callback";


  /** @domName WebGLRenderingContext.clearStencil */
  void clearStencil(int s) native "WebGLRenderingContext_clearStencil_Callback";


  /** @domName WebGLRenderingContext.colorMask */
  void colorMask(bool red, bool green, bool blue, bool alpha) native "WebGLRenderingContext_colorMask_Callback";


  /** @domName WebGLRenderingContext.compileShader */
  void compileShader(WebGLShader shader) native "WebGLRenderingContext_compileShader_Callback";


  /** @domName WebGLRenderingContext.compressedTexImage2D */
  void compressedTexImage2D(int target, int level, int internalformat, int width, int height, int border, ArrayBufferView data) native "WebGLRenderingContext_compressedTexImage2D_Callback";


  /** @domName WebGLRenderingContext.compressedTexSubImage2D */
  void compressedTexSubImage2D(int target, int level, int xoffset, int yoffset, int width, int height, int format, ArrayBufferView data) native "WebGLRenderingContext_compressedTexSubImage2D_Callback";


  /** @domName WebGLRenderingContext.copyTexImage2D */
  void copyTexImage2D(int target, int level, int internalformat, int x, int y, int width, int height, int border) native "WebGLRenderingContext_copyTexImage2D_Callback";


  /** @domName WebGLRenderingContext.copyTexSubImage2D */
  void copyTexSubImage2D(int target, int level, int xoffset, int yoffset, int x, int y, int width, int height) native "WebGLRenderingContext_copyTexSubImage2D_Callback";


  /** @domName WebGLRenderingContext.createBuffer */
  WebGLBuffer createBuffer() native "WebGLRenderingContext_createBuffer_Callback";


  /** @domName WebGLRenderingContext.createFramebuffer */
  WebGLFramebuffer createFramebuffer() native "WebGLRenderingContext_createFramebuffer_Callback";


  /** @domName WebGLRenderingContext.createProgram */
  WebGLProgram createProgram() native "WebGLRenderingContext_createProgram_Callback";


  /** @domName WebGLRenderingContext.createRenderbuffer */
  WebGLRenderbuffer createRenderbuffer() native "WebGLRenderingContext_createRenderbuffer_Callback";


  /** @domName WebGLRenderingContext.createShader */
  WebGLShader createShader(int type) native "WebGLRenderingContext_createShader_Callback";


  /** @domName WebGLRenderingContext.createTexture */
  WebGLTexture createTexture() native "WebGLRenderingContext_createTexture_Callback";


  /** @domName WebGLRenderingContext.cullFace */
  void cullFace(int mode) native "WebGLRenderingContext_cullFace_Callback";


  /** @domName WebGLRenderingContext.deleteBuffer */
  void deleteBuffer(WebGLBuffer buffer) native "WebGLRenderingContext_deleteBuffer_Callback";


  /** @domName WebGLRenderingContext.deleteFramebuffer */
  void deleteFramebuffer(WebGLFramebuffer framebuffer) native "WebGLRenderingContext_deleteFramebuffer_Callback";


  /** @domName WebGLRenderingContext.deleteProgram */
  void deleteProgram(WebGLProgram program) native "WebGLRenderingContext_deleteProgram_Callback";


  /** @domName WebGLRenderingContext.deleteRenderbuffer */
  void deleteRenderbuffer(WebGLRenderbuffer renderbuffer) native "WebGLRenderingContext_deleteRenderbuffer_Callback";


  /** @domName WebGLRenderingContext.deleteShader */
  void deleteShader(WebGLShader shader) native "WebGLRenderingContext_deleteShader_Callback";


  /** @domName WebGLRenderingContext.deleteTexture */
  void deleteTexture(WebGLTexture texture) native "WebGLRenderingContext_deleteTexture_Callback";


  /** @domName WebGLRenderingContext.depthFunc */
  void depthFunc(int func) native "WebGLRenderingContext_depthFunc_Callback";


  /** @domName WebGLRenderingContext.depthMask */
  void depthMask(bool flag) native "WebGLRenderingContext_depthMask_Callback";


  /** @domName WebGLRenderingContext.depthRange */
  void depthRange(num zNear, num zFar) native "WebGLRenderingContext_depthRange_Callback";


  /** @domName WebGLRenderingContext.detachShader */
  void detachShader(WebGLProgram program, WebGLShader shader) native "WebGLRenderingContext_detachShader_Callback";


  /** @domName WebGLRenderingContext.disable */
  void disable(int cap) native "WebGLRenderingContext_disable_Callback";


  /** @domName WebGLRenderingContext.disableVertexAttribArray */
  void disableVertexAttribArray(int index) native "WebGLRenderingContext_disableVertexAttribArray_Callback";


  /** @domName WebGLRenderingContext.drawArrays */
  void drawArrays(int mode, int first, int count) native "WebGLRenderingContext_drawArrays_Callback";


  /** @domName WebGLRenderingContext.drawElements */
  void drawElements(int mode, int count, int type, int offset) native "WebGLRenderingContext_drawElements_Callback";


  /** @domName WebGLRenderingContext.enable */
  void enable(int cap) native "WebGLRenderingContext_enable_Callback";


  /** @domName WebGLRenderingContext.enableVertexAttribArray */
  void enableVertexAttribArray(int index) native "WebGLRenderingContext_enableVertexAttribArray_Callback";


  /** @domName WebGLRenderingContext.finish */
  void finish() native "WebGLRenderingContext_finish_Callback";


  /** @domName WebGLRenderingContext.flush */
  void flush() native "WebGLRenderingContext_flush_Callback";


  /** @domName WebGLRenderingContext.framebufferRenderbuffer */
  void framebufferRenderbuffer(int target, int attachment, int renderbuffertarget, WebGLRenderbuffer renderbuffer) native "WebGLRenderingContext_framebufferRenderbuffer_Callback";


  /** @domName WebGLRenderingContext.framebufferTexture2D */
  void framebufferTexture2D(int target, int attachment, int textarget, WebGLTexture texture, int level) native "WebGLRenderingContext_framebufferTexture2D_Callback";


  /** @domName WebGLRenderingContext.frontFace */
  void frontFace(int mode) native "WebGLRenderingContext_frontFace_Callback";


  /** @domName WebGLRenderingContext.generateMipmap */
  void generateMipmap(int target) native "WebGLRenderingContext_generateMipmap_Callback";


  /** @domName WebGLRenderingContext.getActiveAttrib */
  WebGLActiveInfo getActiveAttrib(WebGLProgram program, int index) native "WebGLRenderingContext_getActiveAttrib_Callback";


  /** @domName WebGLRenderingContext.getActiveUniform */
  WebGLActiveInfo getActiveUniform(WebGLProgram program, int index) native "WebGLRenderingContext_getActiveUniform_Callback";


  /** @domName WebGLRenderingContext.getAttachedShaders */
  void getAttachedShaders(WebGLProgram program) native "WebGLRenderingContext_getAttachedShaders_Callback";


  /** @domName WebGLRenderingContext.getAttribLocation */
  int getAttribLocation(WebGLProgram program, String name) native "WebGLRenderingContext_getAttribLocation_Callback";


  /** @domName WebGLRenderingContext.getBufferParameter */
  Object getBufferParameter(int target, int pname) native "WebGLRenderingContext_getBufferParameter_Callback";


  /** @domName WebGLRenderingContext.getContextAttributes */
  WebGLContextAttributes getContextAttributes() native "WebGLRenderingContext_getContextAttributes_Callback";


  /** @domName WebGLRenderingContext.getError */
  int getError() native "WebGLRenderingContext_getError_Callback";


  /** @domName WebGLRenderingContext.getExtension */
  Object getExtension(String name) native "WebGLRenderingContext_getExtension_Callback";


  /** @domName WebGLRenderingContext.getFramebufferAttachmentParameter */
  Object getFramebufferAttachmentParameter(int target, int attachment, int pname) native "WebGLRenderingContext_getFramebufferAttachmentParameter_Callback";


  /** @domName WebGLRenderingContext.getParameter */
  Object getParameter(int pname) native "WebGLRenderingContext_getParameter_Callback";


  /** @domName WebGLRenderingContext.getProgramInfoLog */
  String getProgramInfoLog(WebGLProgram program) native "WebGLRenderingContext_getProgramInfoLog_Callback";


  /** @domName WebGLRenderingContext.getProgramParameter */
  Object getProgramParameter(WebGLProgram program, int pname) native "WebGLRenderingContext_getProgramParameter_Callback";


  /** @domName WebGLRenderingContext.getRenderbufferParameter */
  Object getRenderbufferParameter(int target, int pname) native "WebGLRenderingContext_getRenderbufferParameter_Callback";


  /** @domName WebGLRenderingContext.getShaderInfoLog */
  String getShaderInfoLog(WebGLShader shader) native "WebGLRenderingContext_getShaderInfoLog_Callback";


  /** @domName WebGLRenderingContext.getShaderParameter */
  Object getShaderParameter(WebGLShader shader, int pname) native "WebGLRenderingContext_getShaderParameter_Callback";


  /** @domName WebGLRenderingContext.getShaderPrecisionFormat */
  WebGLShaderPrecisionFormat getShaderPrecisionFormat(int shadertype, int precisiontype) native "WebGLRenderingContext_getShaderPrecisionFormat_Callback";


  /** @domName WebGLRenderingContext.getShaderSource */
  String getShaderSource(WebGLShader shader) native "WebGLRenderingContext_getShaderSource_Callback";


  /** @domName WebGLRenderingContext.getSupportedExtensions */
  List<String> getSupportedExtensions() native "WebGLRenderingContext_getSupportedExtensions_Callback";


  /** @domName WebGLRenderingContext.getTexParameter */
  Object getTexParameter(int target, int pname) native "WebGLRenderingContext_getTexParameter_Callback";


  /** @domName WebGLRenderingContext.getUniform */
  Object getUniform(WebGLProgram program, WebGLUniformLocation location) native "WebGLRenderingContext_getUniform_Callback";


  /** @domName WebGLRenderingContext.getUniformLocation */
  WebGLUniformLocation getUniformLocation(WebGLProgram program, String name) native "WebGLRenderingContext_getUniformLocation_Callback";


  /** @domName WebGLRenderingContext.getVertexAttrib */
  Object getVertexAttrib(int index, int pname) native "WebGLRenderingContext_getVertexAttrib_Callback";


  /** @domName WebGLRenderingContext.getVertexAttribOffset */
  int getVertexAttribOffset(int index, int pname) native "WebGLRenderingContext_getVertexAttribOffset_Callback";


  /** @domName WebGLRenderingContext.hint */
  void hint(int target, int mode) native "WebGLRenderingContext_hint_Callback";


  /** @domName WebGLRenderingContext.isBuffer */
  bool isBuffer(WebGLBuffer buffer) native "WebGLRenderingContext_isBuffer_Callback";


  /** @domName WebGLRenderingContext.isContextLost */
  bool isContextLost() native "WebGLRenderingContext_isContextLost_Callback";


  /** @domName WebGLRenderingContext.isEnabled */
  bool isEnabled(int cap) native "WebGLRenderingContext_isEnabled_Callback";


  /** @domName WebGLRenderingContext.isFramebuffer */
  bool isFramebuffer(WebGLFramebuffer framebuffer) native "WebGLRenderingContext_isFramebuffer_Callback";


  /** @domName WebGLRenderingContext.isProgram */
  bool isProgram(WebGLProgram program) native "WebGLRenderingContext_isProgram_Callback";


  /** @domName WebGLRenderingContext.isRenderbuffer */
  bool isRenderbuffer(WebGLRenderbuffer renderbuffer) native "WebGLRenderingContext_isRenderbuffer_Callback";


  /** @domName WebGLRenderingContext.isShader */
  bool isShader(WebGLShader shader) native "WebGLRenderingContext_isShader_Callback";


  /** @domName WebGLRenderingContext.isTexture */
  bool isTexture(WebGLTexture texture) native "WebGLRenderingContext_isTexture_Callback";


  /** @domName WebGLRenderingContext.lineWidth */
  void lineWidth(num width) native "WebGLRenderingContext_lineWidth_Callback";


  /** @domName WebGLRenderingContext.linkProgram */
  void linkProgram(WebGLProgram program) native "WebGLRenderingContext_linkProgram_Callback";


  /** @domName WebGLRenderingContext.pixelStorei */
  void pixelStorei(int pname, int param) native "WebGLRenderingContext_pixelStorei_Callback";


  /** @domName WebGLRenderingContext.polygonOffset */
  void polygonOffset(num factor, num units) native "WebGLRenderingContext_polygonOffset_Callback";


  /** @domName WebGLRenderingContext.readPixels */
  void readPixels(int x, int y, int width, int height, int format, int type, ArrayBufferView pixels) native "WebGLRenderingContext_readPixels_Callback";


  /** @domName WebGLRenderingContext.releaseShaderCompiler */
  void releaseShaderCompiler() native "WebGLRenderingContext_releaseShaderCompiler_Callback";


  /** @domName WebGLRenderingContext.renderbufferStorage */
  void renderbufferStorage(int target, int internalformat, int width, int height) native "WebGLRenderingContext_renderbufferStorage_Callback";


  /** @domName WebGLRenderingContext.sampleCoverage */
  void sampleCoverage(num value, bool invert) native "WebGLRenderingContext_sampleCoverage_Callback";


  /** @domName WebGLRenderingContext.scissor */
  void scissor(int x, int y, int width, int height) native "WebGLRenderingContext_scissor_Callback";


  /** @domName WebGLRenderingContext.shaderSource */
  void shaderSource(WebGLShader shader, String string) native "WebGLRenderingContext_shaderSource_Callback";


  /** @domName WebGLRenderingContext.stencilFunc */
  void stencilFunc(int func, int ref, int mask) native "WebGLRenderingContext_stencilFunc_Callback";


  /** @domName WebGLRenderingContext.stencilFuncSeparate */
  void stencilFuncSeparate(int face, int func, int ref, int mask) native "WebGLRenderingContext_stencilFuncSeparate_Callback";


  /** @domName WebGLRenderingContext.stencilMask */
  void stencilMask(int mask) native "WebGLRenderingContext_stencilMask_Callback";


  /** @domName WebGLRenderingContext.stencilMaskSeparate */
  void stencilMaskSeparate(int face, int mask) native "WebGLRenderingContext_stencilMaskSeparate_Callback";


  /** @domName WebGLRenderingContext.stencilOp */
  void stencilOp(int fail, int zfail, int zpass) native "WebGLRenderingContext_stencilOp_Callback";


  /** @domName WebGLRenderingContext.stencilOpSeparate */
  void stencilOpSeparate(int face, int fail, int zfail, int zpass) native "WebGLRenderingContext_stencilOpSeparate_Callback";

  void texImage2D(/*unsigned long*/ target, /*long*/ level, /*unsigned long*/ internalformat, /*long*/ format_OR_width, /*long*/ height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video, [/*unsigned long*/ format, /*unsigned long*/ type, /*ArrayBufferView*/ pixels]) {
    if ((target is int || target == null) && (level is int || level == null) && (internalformat is int || internalformat == null) && (format_OR_width is int || format_OR_width == null) && (height_OR_type is int || height_OR_type == null) && (border_OR_canvas_OR_image_OR_pixels_OR_video is int || border_OR_canvas_OR_image_OR_pixels_OR_video == null) && (format is int || format == null) && (type is int || type == null) && (pixels is ArrayBufferView || pixels == null)) {
      _texImage2D_1(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video, format, type, pixels);
      return;
    }
    if ((target is int || target == null) && (level is int || level == null) && (internalformat is int || internalformat == null) && (format_OR_width is int || format_OR_width == null) && (height_OR_type is int || height_OR_type == null) && (border_OR_canvas_OR_image_OR_pixels_OR_video is ImageData || border_OR_canvas_OR_image_OR_pixels_OR_video == null) && !?format && !?type && !?pixels) {
      _texImage2D_2(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((target is int || target == null) && (level is int || level == null) && (internalformat is int || internalformat == null) && (format_OR_width is int || format_OR_width == null) && (height_OR_type is int || height_OR_type == null) && (border_OR_canvas_OR_image_OR_pixels_OR_video is ImageElement || border_OR_canvas_OR_image_OR_pixels_OR_video == null) && !?format && !?type && !?pixels) {
      _texImage2D_3(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((target is int || target == null) && (level is int || level == null) && (internalformat is int || internalformat == null) && (format_OR_width is int || format_OR_width == null) && (height_OR_type is int || height_OR_type == null) && (border_OR_canvas_OR_image_OR_pixels_OR_video is CanvasElement || border_OR_canvas_OR_image_OR_pixels_OR_video == null) && !?format && !?type && !?pixels) {
      _texImage2D_4(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((target is int || target == null) && (level is int || level == null) && (internalformat is int || internalformat == null) && (format_OR_width is int || format_OR_width == null) && (height_OR_type is int || height_OR_type == null) && (border_OR_canvas_OR_image_OR_pixels_OR_video is VideoElement || border_OR_canvas_OR_image_OR_pixels_OR_video == null) && !?format && !?type && !?pixels) {
      _texImage2D_5(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    throw "Incorrect number or type of arguments";
  }


  /** @domName WebGLRenderingContext.texImage2D_1 */
  void _texImage2D_1(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video, format, type, pixels) native "WebGLRenderingContext_texImage2D_1_Callback";


  /** @domName WebGLRenderingContext.texImage2D_2 */
  void _texImage2D_2(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext_texImage2D_2_Callback";


  /** @domName WebGLRenderingContext.texImage2D_3 */
  void _texImage2D_3(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext_texImage2D_3_Callback";


  /** @domName WebGLRenderingContext.texImage2D_4 */
  void _texImage2D_4(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext_texImage2D_4_Callback";


  /** @domName WebGLRenderingContext.texImage2D_5 */
  void _texImage2D_5(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext_texImage2D_5_Callback";


  /** @domName WebGLRenderingContext.texParameterf */
  void texParameterf(int target, int pname, num param) native "WebGLRenderingContext_texParameterf_Callback";


  /** @domName WebGLRenderingContext.texParameteri */
  void texParameteri(int target, int pname, int param) native "WebGLRenderingContext_texParameteri_Callback";

  void texSubImage2D(/*unsigned long*/ target, /*long*/ level, /*long*/ xoffset, /*long*/ yoffset, /*long*/ format_OR_width, /*long*/ height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video, [/*unsigned long*/ type, /*ArrayBufferView*/ pixels]) {
    if ((target is int || target == null) && (level is int || level == null) && (xoffset is int || xoffset == null) && (yoffset is int || yoffset == null) && (format_OR_width is int || format_OR_width == null) && (height_OR_type is int || height_OR_type == null) && (canvas_OR_format_OR_image_OR_pixels_OR_video is int || canvas_OR_format_OR_image_OR_pixels_OR_video == null) && (type is int || type == null) && (pixels is ArrayBufferView || pixels == null)) {
      _texSubImage2D_1(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video, type, pixels);
      return;
    }
    if ((target is int || target == null) && (level is int || level == null) && (xoffset is int || xoffset == null) && (yoffset is int || yoffset == null) && (format_OR_width is int || format_OR_width == null) && (height_OR_type is int || height_OR_type == null) && (canvas_OR_format_OR_image_OR_pixels_OR_video is ImageData || canvas_OR_format_OR_image_OR_pixels_OR_video == null) && !?type && !?pixels) {
      _texSubImage2D_2(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((target is int || target == null) && (level is int || level == null) && (xoffset is int || xoffset == null) && (yoffset is int || yoffset == null) && (format_OR_width is int || format_OR_width == null) && (height_OR_type is int || height_OR_type == null) && (canvas_OR_format_OR_image_OR_pixels_OR_video is ImageElement || canvas_OR_format_OR_image_OR_pixels_OR_video == null) && !?type && !?pixels) {
      _texSubImage2D_3(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((target is int || target == null) && (level is int || level == null) && (xoffset is int || xoffset == null) && (yoffset is int || yoffset == null) && (format_OR_width is int || format_OR_width == null) && (height_OR_type is int || height_OR_type == null) && (canvas_OR_format_OR_image_OR_pixels_OR_video is CanvasElement || canvas_OR_format_OR_image_OR_pixels_OR_video == null) && !?type && !?pixels) {
      _texSubImage2D_4(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((target is int || target == null) && (level is int || level == null) && (xoffset is int || xoffset == null) && (yoffset is int || yoffset == null) && (format_OR_width is int || format_OR_width == null) && (height_OR_type is int || height_OR_type == null) && (canvas_OR_format_OR_image_OR_pixels_OR_video is VideoElement || canvas_OR_format_OR_image_OR_pixels_OR_video == null) && !?type && !?pixels) {
      _texSubImage2D_5(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    throw "Incorrect number or type of arguments";
  }


  /** @domName WebGLRenderingContext.texSubImage2D_1 */
  void _texSubImage2D_1(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video, type, pixels) native "WebGLRenderingContext_texSubImage2D_1_Callback";


  /** @domName WebGLRenderingContext.texSubImage2D_2 */
  void _texSubImage2D_2(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext_texSubImage2D_2_Callback";


  /** @domName WebGLRenderingContext.texSubImage2D_3 */
  void _texSubImage2D_3(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext_texSubImage2D_3_Callback";


  /** @domName WebGLRenderingContext.texSubImage2D_4 */
  void _texSubImage2D_4(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext_texSubImage2D_4_Callback";


  /** @domName WebGLRenderingContext.texSubImage2D_5 */
  void _texSubImage2D_5(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext_texSubImage2D_5_Callback";


  /** @domName WebGLRenderingContext.uniform1f */
  void uniform1f(WebGLUniformLocation location, num x) native "WebGLRenderingContext_uniform1f_Callback";


  /** @domName WebGLRenderingContext.uniform1fv */
  void uniform1fv(WebGLUniformLocation location, Float32Array v) native "WebGLRenderingContext_uniform1fv_Callback";


  /** @domName WebGLRenderingContext.uniform1i */
  void uniform1i(WebGLUniformLocation location, int x) native "WebGLRenderingContext_uniform1i_Callback";


  /** @domName WebGLRenderingContext.uniform1iv */
  void uniform1iv(WebGLUniformLocation location, Int32Array v) native "WebGLRenderingContext_uniform1iv_Callback";


  /** @domName WebGLRenderingContext.uniform2f */
  void uniform2f(WebGLUniformLocation location, num x, num y) native "WebGLRenderingContext_uniform2f_Callback";


  /** @domName WebGLRenderingContext.uniform2fv */
  void uniform2fv(WebGLUniformLocation location, Float32Array v) native "WebGLRenderingContext_uniform2fv_Callback";


  /** @domName WebGLRenderingContext.uniform2i */
  void uniform2i(WebGLUniformLocation location, int x, int y) native "WebGLRenderingContext_uniform2i_Callback";


  /** @domName WebGLRenderingContext.uniform2iv */
  void uniform2iv(WebGLUniformLocation location, Int32Array v) native "WebGLRenderingContext_uniform2iv_Callback";


  /** @domName WebGLRenderingContext.uniform3f */
  void uniform3f(WebGLUniformLocation location, num x, num y, num z) native "WebGLRenderingContext_uniform3f_Callback";


  /** @domName WebGLRenderingContext.uniform3fv */
  void uniform3fv(WebGLUniformLocation location, Float32Array v) native "WebGLRenderingContext_uniform3fv_Callback";


  /** @domName WebGLRenderingContext.uniform3i */
  void uniform3i(WebGLUniformLocation location, int x, int y, int z) native "WebGLRenderingContext_uniform3i_Callback";


  /** @domName WebGLRenderingContext.uniform3iv */
  void uniform3iv(WebGLUniformLocation location, Int32Array v) native "WebGLRenderingContext_uniform3iv_Callback";


  /** @domName WebGLRenderingContext.uniform4f */
  void uniform4f(WebGLUniformLocation location, num x, num y, num z, num w) native "WebGLRenderingContext_uniform4f_Callback";


  /** @domName WebGLRenderingContext.uniform4fv */
  void uniform4fv(WebGLUniformLocation location, Float32Array v) native "WebGLRenderingContext_uniform4fv_Callback";


  /** @domName WebGLRenderingContext.uniform4i */
  void uniform4i(WebGLUniformLocation location, int x, int y, int z, int w) native "WebGLRenderingContext_uniform4i_Callback";


  /** @domName WebGLRenderingContext.uniform4iv */
  void uniform4iv(WebGLUniformLocation location, Int32Array v) native "WebGLRenderingContext_uniform4iv_Callback";


  /** @domName WebGLRenderingContext.uniformMatrix2fv */
  void uniformMatrix2fv(WebGLUniformLocation location, bool transpose, Float32Array array) native "WebGLRenderingContext_uniformMatrix2fv_Callback";


  /** @domName WebGLRenderingContext.uniformMatrix3fv */
  void uniformMatrix3fv(WebGLUniformLocation location, bool transpose, Float32Array array) native "WebGLRenderingContext_uniformMatrix3fv_Callback";


  /** @domName WebGLRenderingContext.uniformMatrix4fv */
  void uniformMatrix4fv(WebGLUniformLocation location, bool transpose, Float32Array array) native "WebGLRenderingContext_uniformMatrix4fv_Callback";


  /** @domName WebGLRenderingContext.useProgram */
  void useProgram(WebGLProgram program) native "WebGLRenderingContext_useProgram_Callback";


  /** @domName WebGLRenderingContext.validateProgram */
  void validateProgram(WebGLProgram program) native "WebGLRenderingContext_validateProgram_Callback";


  /** @domName WebGLRenderingContext.vertexAttrib1f */
  void vertexAttrib1f(int indx, num x) native "WebGLRenderingContext_vertexAttrib1f_Callback";


  /** @domName WebGLRenderingContext.vertexAttrib1fv */
  void vertexAttrib1fv(int indx, Float32Array values) native "WebGLRenderingContext_vertexAttrib1fv_Callback";


  /** @domName WebGLRenderingContext.vertexAttrib2f */
  void vertexAttrib2f(int indx, num x, num y) native "WebGLRenderingContext_vertexAttrib2f_Callback";


  /** @domName WebGLRenderingContext.vertexAttrib2fv */
  void vertexAttrib2fv(int indx, Float32Array values) native "WebGLRenderingContext_vertexAttrib2fv_Callback";


  /** @domName WebGLRenderingContext.vertexAttrib3f */
  void vertexAttrib3f(int indx, num x, num y, num z) native "WebGLRenderingContext_vertexAttrib3f_Callback";


  /** @domName WebGLRenderingContext.vertexAttrib3fv */
  void vertexAttrib3fv(int indx, Float32Array values) native "WebGLRenderingContext_vertexAttrib3fv_Callback";


  /** @domName WebGLRenderingContext.vertexAttrib4f */
  void vertexAttrib4f(int indx, num x, num y, num z, num w) native "WebGLRenderingContext_vertexAttrib4f_Callback";


  /** @domName WebGLRenderingContext.vertexAttrib4fv */
  void vertexAttrib4fv(int indx, Float32Array values) native "WebGLRenderingContext_vertexAttrib4fv_Callback";


  /** @domName WebGLRenderingContext.vertexAttribPointer */
  void vertexAttribPointer(int indx, int size, int type, bool normalized, int stride, int offset) native "WebGLRenderingContext_vertexAttribPointer_Callback";


  /** @domName WebGLRenderingContext.viewport */
  void viewport(int x, int y, int width, int height) native "WebGLRenderingContext_viewport_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WebGLShader
class WebGLShader extends NativeFieldWrapperClass1 {
  WebGLShader.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WebGLShaderPrecisionFormat
class WebGLShaderPrecisionFormat extends NativeFieldWrapperClass1 {
  WebGLShaderPrecisionFormat.internal();


  /** @domName WebGLShaderPrecisionFormat.precision */
  int get precision native "WebGLShaderPrecisionFormat_precision_Getter";


  /** @domName WebGLShaderPrecisionFormat.rangeMax */
  int get rangeMax native "WebGLShaderPrecisionFormat_rangeMax_Getter";


  /** @domName WebGLShaderPrecisionFormat.rangeMin */
  int get rangeMin native "WebGLShaderPrecisionFormat_rangeMin_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WebGLTexture
class WebGLTexture extends NativeFieldWrapperClass1 {
  WebGLTexture.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WebGLUniformLocation
class WebGLUniformLocation extends NativeFieldWrapperClass1 {
  WebGLUniformLocation.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WebGLVertexArrayObjectOES
class WebGLVertexArrayObjectOES extends NativeFieldWrapperClass1 {
  WebGLVertexArrayObjectOES.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WebKitCSSFilterValue
class WebKitCSSFilterValue extends _CSSValueList {
  WebKitCSSFilterValue.internal(): super.internal();

  static const int CSS_FILTER_BLUR = 10;

  static const int CSS_FILTER_BRIGHTNESS = 8;

  static const int CSS_FILTER_CONTRAST = 9;

  static const int CSS_FILTER_CUSTOM = 12;

  static const int CSS_FILTER_DROP_SHADOW = 11;

  static const int CSS_FILTER_GRAYSCALE = 2;

  static const int CSS_FILTER_HUE_ROTATE = 5;

  static const int CSS_FILTER_INVERT = 6;

  static const int CSS_FILTER_OPACITY = 7;

  static const int CSS_FILTER_REFERENCE = 1;

  static const int CSS_FILTER_SATURATE = 4;

  static const int CSS_FILTER_SEPIA = 3;


  /** @domName WebKitCSSFilterValue.operationType */
  int get operationType native "WebKitCSSFilterValue_operationType_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WebKitNamedFlow
class WebKitNamedFlow extends EventTarget {
  WebKitNamedFlow.internal(): super.internal();


  /** @domName WebKitNamedFlow.firstEmptyRegionIndex */
  int get firstEmptyRegionIndex native "WebKitNamedFlow_firstEmptyRegionIndex_Getter";


  /** @domName WebKitNamedFlow.name */
  String get name native "WebKitNamedFlow_name_Getter";


  /** @domName WebKitNamedFlow.overset */
  bool get overset native "WebKitNamedFlow_overset_Getter";


  /** @domName WebKitNamedFlow.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "WebKitNamedFlow_addEventListener_Callback";


  /** @domName WebKitNamedFlow.dispatchEvent */
  bool $dom_dispatchEvent(Event event) native "WebKitNamedFlow_dispatchEvent_Callback";


  /** @domName WebKitNamedFlow.getContent */
  List<Node> getContent() native "WebKitNamedFlow_getContent_Callback";


  /** @domName WebKitNamedFlow.getRegions */
  List<Node> getRegions() native "WebKitNamedFlow_getRegions_Callback";


  /** @domName WebKitNamedFlow.getRegionsByContent */
  List<Node> getRegionsByContent(Node contentNode) native "WebKitNamedFlow_getRegionsByContent_Callback";


  /** @domName WebKitNamedFlow.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "WebKitNamedFlow_removeEventListener_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


class WebSocket extends EventTarget {
  factory WebSocket(String url) => _WebSocketFactoryProvider.createWebSocket(url);
  WebSocket.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  WebSocketEvents get on =>
    new WebSocketEvents(this);

  static const int CLOSED = 3;

  static const int CLOSING = 2;

  static const int CONNECTING = 0;

  static const int OPEN = 1;


  /** @domName WebSocket.URL */
  String get URL native "WebSocket_URL_Getter";


  /** @domName WebSocket.binaryType */
  String get binaryType native "WebSocket_binaryType_Getter";


  /** @domName WebSocket.binaryType */
  void set binaryType(String value) native "WebSocket_binaryType_Setter";


  /** @domName WebSocket.bufferedAmount */
  int get bufferedAmount native "WebSocket_bufferedAmount_Getter";


  /** @domName WebSocket.extensions */
  String get extensions native "WebSocket_extensions_Getter";


  /** @domName WebSocket.protocol */
  String get protocol native "WebSocket_protocol_Getter";


  /** @domName WebSocket.readyState */
  int get readyState native "WebSocket_readyState_Getter";


  /** @domName WebSocket.url */
  String get url native "WebSocket_url_Getter";


  /** @domName WebSocket.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "WebSocket_addEventListener_Callback";

  void close([/*unsigned short*/ code, /*DOMString*/ reason]) {
    if (?reason) {
      _close_1(code, reason);
      return;
    }
    if (?code) {
      _close_2(code);
      return;
    }
    _close_3();
  }


  /** @domName WebSocket.close_1 */
  void _close_1(code, reason) native "WebSocket_close_1_Callback";


  /** @domName WebSocket.close_2 */
  void _close_2(code) native "WebSocket_close_2_Callback";


  /** @domName WebSocket.close_3 */
  void _close_3() native "WebSocket_close_3_Callback";


  /** @domName WebSocket.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "WebSocket_dispatchEvent_Callback";


  /** @domName WebSocket.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "WebSocket_removeEventListener_Callback";


  /** @domName WebSocket.send */
  void send(data) native "WebSocket_send_Callback";

}

class WebSocketEvents extends Events {
  WebSocketEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get close => this['close'];

  EventListenerList get error => this['error'];

  EventListenerList get message => this['message'];

  EventListenerList get open => this['open'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class WheelEvent extends MouseEvent {
  WheelEvent.internal(): super.internal();


  /** @domName WheelEvent.webkitDirectionInvertedFromDevice */
  bool get webkitDirectionInvertedFromDevice native "WheelEvent_webkitDirectionInvertedFromDevice_Getter";


  /** @domName WheelEvent.wheelDeltaX */
  int get $dom_wheelDeltaX native "WheelEvent_wheelDeltaX_Getter";


  /** @domName WheelEvent.wheelDeltaY */
  int get $dom_wheelDeltaY native "WheelEvent_wheelDeltaY_Getter";


  /** @domName WheelEvent.initWebKitWheelEvent */
  void initWebKitWheelEvent(int wheelDeltaX, int wheelDeltaY, LocalWindow view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) native "WheelEvent_initWebKitWheelEvent_Callback";


  /** @domName WheelEvent.deltaX */
  num get deltaX => $dom_wheelDeltaX;
  /** @domName WheelEvent.deltaY */
  num get deltaY => $dom_wheelDeltaY;
  /** @domName WheelEvent.deltaMode */
  int get deltaMode => 0;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName Worker
class Worker extends AbstractWorker {

  factory Worker(String scriptUrl) => _WorkerFactoryProvider.createWorker(scriptUrl);
  Worker.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  WorkerEvents get on =>
    new WorkerEvents(this);


  /** @domName Worker.postMessage */
  void postMessage(/*SerializedScriptValue*/ message, [List messagePorts]) native "Worker_postMessage_Callback";


  /** @domName Worker.terminate */
  void terminate() native "Worker_terminate_Callback";

}

class WorkerEvents extends AbstractWorkerEvents {
  WorkerEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get message => this['message'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WorkerContext
class WorkerContext extends EventTarget {
  WorkerContext.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  WorkerContextEvents get on =>
    new WorkerContextEvents(this);

  static const int PERSISTENT = 1;

  static const int TEMPORARY = 0;


  /** @domName WorkerContext.indexedDB */
  IDBFactory get indexedDB native "WorkerContext_indexedDB_Getter";


  /** @domName WorkerContext.location */
  WorkerLocation get location native "WorkerContext_location_Getter";


  /** @domName WorkerContext.navigator */
  WorkerNavigator get navigator native "WorkerContext_navigator_Getter";


  /** @domName WorkerContext.self */
  WorkerContext get self native "WorkerContext_self_Getter";


  /** @domName WorkerContext.webkitIndexedDB */
  IDBFactory get webkitIndexedDB native "WorkerContext_webkitIndexedDB_Getter";


  /** @domName WorkerContext.webkitNotifications */
  NotificationCenter get webkitNotifications native "WorkerContext_webkitNotifications_Getter";


  /** @domName WorkerContext.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "WorkerContext_addEventListener_Callback";


  /** @domName WorkerContext.clearInterval */
  void clearInterval(int handle) native "WorkerContext_clearInterval_Callback";


  /** @domName WorkerContext.clearTimeout */
  void clearTimeout(int handle) native "WorkerContext_clearTimeout_Callback";


  /** @domName WorkerContext.close */
  void close() native "WorkerContext_close_Callback";


  /** @domName WorkerContext.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "WorkerContext_dispatchEvent_Callback";


  /** @domName WorkerContext.importScripts */
  void importScripts() native "WorkerContext_importScripts_Callback";


  /** @domName WorkerContext.openDatabase */
  Database openDatabase(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback]) native "WorkerContext_openDatabase_Callback";


  /** @domName WorkerContext.openDatabaseSync */
  DatabaseSync openDatabaseSync(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback]) native "WorkerContext_openDatabaseSync_Callback";


  /** @domName WorkerContext.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "WorkerContext_removeEventListener_Callback";


  /** @domName WorkerContext.setInterval */
  int setInterval(TimeoutHandler handler, int timeout) native "WorkerContext_setInterval_Callback";


  /** @domName WorkerContext.setTimeout */
  int setTimeout(TimeoutHandler handler, int timeout) native "WorkerContext_setTimeout_Callback";


  /** @domName WorkerContext.webkitRequestFileSystem */
  void webkitRequestFileSystem(int type, int size, [FileSystemCallback successCallback, ErrorCallback errorCallback]) native "WorkerContext_webkitRequestFileSystem_Callback";


  /** @domName WorkerContext.webkitRequestFileSystemSync */
  DOMFileSystemSync webkitRequestFileSystemSync(int type, int size) native "WorkerContext_webkitRequestFileSystemSync_Callback";


  /** @domName WorkerContext.webkitResolveLocalFileSystemSyncURL */
  EntrySync webkitResolveLocalFileSystemSyncURL(String url) native "WorkerContext_webkitResolveLocalFileSystemSyncURL_Callback";


  /** @domName WorkerContext.webkitResolveLocalFileSystemURL */
  void webkitResolveLocalFileSystemURL(String url, EntryCallback successCallback, [ErrorCallback errorCallback]) native "WorkerContext_webkitResolveLocalFileSystemURL_Callback";

}

class WorkerContextEvents extends Events {
  WorkerContextEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get error => this['error'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WorkerLocation
class WorkerLocation extends NativeFieldWrapperClass1 {
  WorkerLocation.internal();


  /** @domName WorkerLocation.hash */
  String get hash native "WorkerLocation_hash_Getter";


  /** @domName WorkerLocation.host */
  String get host native "WorkerLocation_host_Getter";


  /** @domName WorkerLocation.hostname */
  String get hostname native "WorkerLocation_hostname_Getter";


  /** @domName WorkerLocation.href */
  String get href native "WorkerLocation_href_Getter";


  /** @domName WorkerLocation.pathname */
  String get pathname native "WorkerLocation_pathname_Getter";


  /** @domName WorkerLocation.port */
  String get port native "WorkerLocation_port_Getter";


  /** @domName WorkerLocation.protocol */
  String get protocol native "WorkerLocation_protocol_Getter";


  /** @domName WorkerLocation.search */
  String get search native "WorkerLocation_search_Getter";


  /** @domName WorkerLocation.toString */
  String toString() native "WorkerLocation_toString_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WorkerNavigator
class WorkerNavigator extends NativeFieldWrapperClass1 {
  WorkerNavigator.internal();


  /** @domName WorkerNavigator.appName */
  String get appName native "WorkerNavigator_appName_Getter";


  /** @domName WorkerNavigator.appVersion */
  String get appVersion native "WorkerNavigator_appVersion_Getter";


  /** @domName WorkerNavigator.onLine */
  bool get onLine native "WorkerNavigator_onLine_Getter";


  /** @domName WorkerNavigator.platform */
  String get platform native "WorkerNavigator_platform_Getter";


  /** @domName WorkerNavigator.userAgent */
  String get userAgent native "WorkerNavigator_userAgent_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName XMLSerializer
class XMLSerializer extends NativeFieldWrapperClass1 {

  factory XMLSerializer() => _XMLSerializerFactoryProvider.createXMLSerializer();
  XMLSerializer.internal();


  /** @domName XMLSerializer.serializeToString */
  String serializeToString(Node node) native "XMLSerializer_serializeToString_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName XPathEvaluator
class XPathEvaluator extends NativeFieldWrapperClass1 {

  factory XPathEvaluator() => _XPathEvaluatorFactoryProvider.createXPathEvaluator();
  XPathEvaluator.internal();


  /** @domName XPathEvaluator.createExpression */
  XPathExpression createExpression(String expression, XPathNSResolver resolver) native "XPathEvaluator_createExpression_Callback";


  /** @domName XPathEvaluator.createNSResolver */
  XPathNSResolver createNSResolver(Node nodeResolver) native "XPathEvaluator_createNSResolver_Callback";


  /** @domName XPathEvaluator.evaluate */
  XPathResult evaluate(String expression, Node contextNode, XPathNSResolver resolver, int type, XPathResult inResult) native "XPathEvaluator_evaluate_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName XPathException
class XPathException extends NativeFieldWrapperClass1 {
  XPathException.internal();

  static const int INVALID_EXPRESSION_ERR = 51;

  static const int TYPE_ERR = 52;


  /** @domName XPathException.code */
  int get code native "XPathException_code_Getter";


  /** @domName XPathException.message */
  String get message native "XPathException_message_Getter";


  /** @domName XPathException.name */
  String get name native "XPathException_name_Getter";


  /** @domName XPathException.toString */
  String toString() native "XPathException_toString_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName XPathExpression
class XPathExpression extends NativeFieldWrapperClass1 {
  XPathExpression.internal();


  /** @domName XPathExpression.evaluate */
  XPathResult evaluate(Node contextNode, int type, XPathResult inResult) native "XPathExpression_evaluate_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName XPathNSResolver
class XPathNSResolver extends NativeFieldWrapperClass1 {
  XPathNSResolver.internal();


  /** @domName XPathNSResolver.lookupNamespaceURI */
  String lookupNamespaceURI(String prefix) native "XPathNSResolver_lookupNamespaceURI_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName XPathResult
class XPathResult extends NativeFieldWrapperClass1 {
  XPathResult.internal();

  static const int ANY_TYPE = 0;

  static const int ANY_UNORDERED_NODE_TYPE = 8;

  static const int BOOLEAN_TYPE = 3;

  static const int FIRST_ORDERED_NODE_TYPE = 9;

  static const int NUMBER_TYPE = 1;

  static const int ORDERED_NODE_ITERATOR_TYPE = 5;

  static const int ORDERED_NODE_SNAPSHOT_TYPE = 7;

  static const int STRING_TYPE = 2;

  static const int UNORDERED_NODE_ITERATOR_TYPE = 4;

  static const int UNORDERED_NODE_SNAPSHOT_TYPE = 6;


  /** @domName XPathResult.booleanValue */
  bool get booleanValue native "XPathResult_booleanValue_Getter";


  /** @domName XPathResult.invalidIteratorState */
  bool get invalidIteratorState native "XPathResult_invalidIteratorState_Getter";


  /** @domName XPathResult.numberValue */
  num get numberValue native "XPathResult_numberValue_Getter";


  /** @domName XPathResult.resultType */
  int get resultType native "XPathResult_resultType_Getter";


  /** @domName XPathResult.singleNodeValue */
  Node get singleNodeValue native "XPathResult_singleNodeValue_Getter";


  /** @domName XPathResult.snapshotLength */
  int get snapshotLength native "XPathResult_snapshotLength_Getter";


  /** @domName XPathResult.stringValue */
  String get stringValue native "XPathResult_stringValue_Getter";


  /** @domName XPathResult.iterateNext */
  Node iterateNext() native "XPathResult_iterateNext_Callback";


  /** @domName XPathResult.snapshotItem */
  Node snapshotItem(int index) native "XPathResult_snapshotItem_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName XSLTProcessor
class XSLTProcessor extends NativeFieldWrapperClass1 {

  factory XSLTProcessor() => _XSLTProcessorFactoryProvider.createXSLTProcessor();
  XSLTProcessor.internal();


  /** @domName XSLTProcessor.clearParameters */
  void clearParameters() native "XSLTProcessor_clearParameters_Callback";


  /** @domName XSLTProcessor.getParameter */
  String getParameter(String namespaceURI, String localName) native "XSLTProcessor_getParameter_Callback";


  /** @domName XSLTProcessor.importStylesheet */
  void importStylesheet(Node stylesheet) native "XSLTProcessor_importStylesheet_Callback";


  /** @domName XSLTProcessor.removeParameter */
  void removeParameter(String namespaceURI, String localName) native "XSLTProcessor_removeParameter_Callback";


  /** @domName XSLTProcessor.reset */
  void reset() native "XSLTProcessor_reset_Callback";


  /** @domName XSLTProcessor.setParameter */
  void setParameter(String namespaceURI, String localName, String value) native "XSLTProcessor_setParameter_Callback";


  /** @domName XSLTProcessor.transformToDocument */
  Document transformToDocument(Node source) native "XSLTProcessor_transformToDocument_Callback";


  /** @domName XSLTProcessor.transformToFragment */
  DocumentFragment transformToFragment(Node source, Document docVal) native "XSLTProcessor_transformToFragment_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _ArrayBufferFactoryProvider {
  static ArrayBuffer createArrayBuffer(int length) native "ArrayBuffer_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _AudioElementFactoryProvider {
  static AudioElement createAudioElement([String src]) native "HTMLAudioElement_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _BlobFactoryProvider {
  static Blob createBlob(List blobParts, [String type, String endings]) native "Blob_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _CSSMatrixFactoryProvider {
  static CSSMatrix createCSSMatrix([String cssValue]) native "WebKitCSSMatrix_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName CSSRuleList
class _CSSRuleList extends NativeFieldWrapperClass1 implements List<CSSRule> {
  _CSSRuleList.internal();


  /** @domName CSSRuleList.length */
  int get length native "CSSRuleList_length_Getter";

  CSSRule operator[](int index) native "CSSRuleList_item_Callback";

  void operator[]=(int index, CSSRule value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<CSSRule> mixins.
  // CSSRule is the element type.

  // From Iterable<CSSRule>:

  Iterator<CSSRule> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<CSSRule>(this);
  }

  // From Collection<CSSRule>:

  void add(CSSRule value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(CSSRule value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<CSSRule> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(CSSRule element) => _Collections.contains(this, element);

  void forEach(void f(CSSRule element)) => _Collections.forEach(this, f);

  Collection map(f(CSSRule element)) => _Collections.map(this, [], f);

  Collection<CSSRule> filter(bool f(CSSRule element)) =>
     _Collections.filter(this, <CSSRule>[], f);

  bool every(bool f(CSSRule element)) => _Collections.every(this, f);

  bool some(bool f(CSSRule element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<CSSRule>:

  void sort([Comparator<CSSRule> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(CSSRule element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(CSSRule element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  CSSRule get first => this[0];

  CSSRule get last => this[length - 1];

  CSSRule removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<CSSRule> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [CSSRule initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<CSSRule> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <CSSRule>[]);

  // -- end List<CSSRule> mixins.


  /** @domName CSSRuleList.item */
  CSSRule item(int index) native "CSSRuleList_item_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName CSSValueList
class _CSSValueList extends CSSValue implements List<CSSValue> {
  _CSSValueList.internal(): super.internal();


  /** @domName CSSValueList.length */
  int get length native "CSSValueList_length_Getter";

  CSSValue operator[](int index) native "CSSValueList_item_Callback";

  void operator[]=(int index, CSSValue value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<CSSValue> mixins.
  // CSSValue is the element type.

  // From Iterable<CSSValue>:

  Iterator<CSSValue> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<CSSValue>(this);
  }

  // From Collection<CSSValue>:

  void add(CSSValue value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(CSSValue value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<CSSValue> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(CSSValue element) => _Collections.contains(this, element);

  void forEach(void f(CSSValue element)) => _Collections.forEach(this, f);

  Collection map(f(CSSValue element)) => _Collections.map(this, [], f);

  Collection<CSSValue> filter(bool f(CSSValue element)) =>
     _Collections.filter(this, <CSSValue>[], f);

  bool every(bool f(CSSValue element)) => _Collections.every(this, f);

  bool some(bool f(CSSValue element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<CSSValue>:

  void sort([Comparator<CSSValue> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(CSSValue element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(CSSValue element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  CSSValue get first => this[0];

  CSSValue get last => this[length - 1];

  CSSValue removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<CSSValue> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [CSSValue initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<CSSValue> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <CSSValue>[]);

  // -- end List<CSSValue> mixins.


  /** @domName CSSValueList.item */
  CSSValue item(int index) native "CSSValueList_item_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName ClientRectList
class _ClientRectList extends NativeFieldWrapperClass1 implements List<ClientRect> {
  _ClientRectList.internal();


  /** @domName ClientRectList.length */
  int get length native "ClientRectList_length_Getter";

  ClientRect operator[](int index) native "ClientRectList_item_Callback";

  void operator[]=(int index, ClientRect value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<ClientRect> mixins.
  // ClientRect is the element type.

  // From Iterable<ClientRect>:

  Iterator<ClientRect> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<ClientRect>(this);
  }

  // From Collection<ClientRect>:

  void add(ClientRect value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(ClientRect value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<ClientRect> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(ClientRect element) => _Collections.contains(this, element);

  void forEach(void f(ClientRect element)) => _Collections.forEach(this, f);

  Collection map(f(ClientRect element)) => _Collections.map(this, [], f);

  Collection<ClientRect> filter(bool f(ClientRect element)) =>
     _Collections.filter(this, <ClientRect>[], f);

  bool every(bool f(ClientRect element)) => _Collections.every(this, f);

  bool some(bool f(ClientRect element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<ClientRect>:

  void sort([Comparator<ClientRect> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(ClientRect element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(ClientRect element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  ClientRect get first => this[0];

  ClientRect get last => this[length - 1];

  ClientRect removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<ClientRect> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [ClientRect initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<ClientRect> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <ClientRect>[]);

  // -- end List<ClientRect> mixins.


  /** @domName ClientRectList.item */
  ClientRect item(int index) native "ClientRectList_item_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _DOMParserFactoryProvider {
  static DOMParser createDOMParser() native "DOMParser_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName DOMStringList
class _DOMStringList extends NativeFieldWrapperClass1 implements List<String> {
  _DOMStringList.internal();


  /** @domName DOMStringList.length */
  int get length native "DOMStringList_length_Getter";

  String operator[](int index) native "DOMStringList_item_Callback";

  void operator[]=(int index, String value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<String> mixins.
  // String is the element type.

  // From Iterable<String>:

  Iterator<String> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<String>(this);
  }

  // From Collection<String>:

  void add(String value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(String value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<String> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // contains() defined by IDL.

  void forEach(void f(String element)) => _Collections.forEach(this, f);

  Collection map(f(String element)) => _Collections.map(this, [], f);

  Collection<String> filter(bool f(String element)) =>
     _Collections.filter(this, <String>[], f);

  bool every(bool f(String element)) => _Collections.every(this, f);

  bool some(bool f(String element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<String>:

  void sort([Comparator<String> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(String element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(String element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  String get first => this[0];

  String get last => this[length - 1];

  String removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<String> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [String initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<String> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <String>[]);

  // -- end List<String> mixins.


  /** @domName DOMStringList.contains */
  bool contains(String string) native "DOMStringList_contains_Callback";


  /** @domName DOMStringList.item */
  String item(int index) native "DOMStringList_item_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _DataViewFactoryProvider {
  static DataView createDataView(ArrayBuffer buffer, [int byteOffset, int byteLength]) native "DataView_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName HTMLElement
class _Element_Merged extends Element {
  _Element_Merged.internal(): super.internal();


  /** @domName HTMLElement.children */
  HTMLCollection get $dom_children native "HTMLElement_children_Getter";


  /** @domName HTMLElement.contentEditable */
  String get contentEditable native "HTMLElement_contentEditable_Getter";


  /** @domName HTMLElement.contentEditable */
  void set contentEditable(String value) native "HTMLElement_contentEditable_Setter";


  /** @domName HTMLElement.dir */
  String get dir native "HTMLElement_dir_Getter";


  /** @domName HTMLElement.dir */
  void set dir(String value) native "HTMLElement_dir_Setter";


  /** @domName HTMLElement.draggable */
  bool get draggable native "HTMLElement_draggable_Getter";


  /** @domName HTMLElement.draggable */
  void set draggable(bool value) native "HTMLElement_draggable_Setter";


  /** @domName HTMLElement.hidden */
  bool get hidden native "HTMLElement_hidden_Getter";


  /** @domName HTMLElement.hidden */
  void set hidden(bool value) native "HTMLElement_hidden_Setter";


  /** @domName HTMLElement.id */
  String get id native "HTMLElement_id_Getter";


  /** @domName HTMLElement.id */
  void set id(String value) native "HTMLElement_id_Setter";


  /** @domName HTMLElement.innerHTML */
  String get innerHTML native "HTMLElement_innerHTML_Getter";


  /** @domName HTMLElement.innerHTML */
  void set innerHTML(String value) native "HTMLElement_innerHTML_Setter";


  /** @domName HTMLElement.isContentEditable */
  bool get isContentEditable native "HTMLElement_isContentEditable_Getter";


  /** @domName HTMLElement.lang */
  String get lang native "HTMLElement_lang_Getter";


  /** @domName HTMLElement.lang */
  void set lang(String value) native "HTMLElement_lang_Setter";


  /** @domName HTMLElement.outerHTML */
  String get outerHTML native "HTMLElement_outerHTML_Getter";


  /** @domName HTMLElement.spellcheck */
  bool get spellcheck native "HTMLElement_spellcheck_Getter";


  /** @domName HTMLElement.spellcheck */
  void set spellcheck(bool value) native "HTMLElement_spellcheck_Setter";


  /** @domName HTMLElement.tabIndex */
  int get tabIndex native "HTMLElement_tabIndex_Getter";


  /** @domName HTMLElement.tabIndex */
  void set tabIndex(int value) native "HTMLElement_tabIndex_Setter";


  /** @domName HTMLElement.title */
  String get title native "HTMLElement_title_Getter";


  /** @domName HTMLElement.title */
  void set title(String value) native "HTMLElement_title_Setter";


  /** @domName HTMLElement.translate */
  bool get translate native "HTMLElement_translate_Getter";


  /** @domName HTMLElement.translate */
  void set translate(bool value) native "HTMLElement_translate_Setter";


  /** @domName HTMLElement.webkitdropzone */
  String get webkitdropzone native "HTMLElement_webkitdropzone_Getter";


  /** @domName HTMLElement.webkitdropzone */
  void set webkitdropzone(String value) native "HTMLElement_webkitdropzone_Setter";


  /** @domName HTMLElement.click */
  void click() native "HTMLElement_click_Callback";


  /** @domName HTMLElement.insertAdjacentElement */
  Element insertAdjacentElement(String where, Element element) native "HTMLElement_insertAdjacentElement_Callback";


  /** @domName HTMLElement.insertAdjacentHTML */
  void insertAdjacentHTML(String where, String html) native "HTMLElement_insertAdjacentHTML_Callback";


  /** @domName HTMLElement.insertAdjacentText */
  void insertAdjacentText(String where, String text) native "HTMLElement_insertAdjacentText_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName EntryArray
class _EntryArray extends NativeFieldWrapperClass1 implements List<Entry> {
  _EntryArray.internal();


  /** @domName EntryArray.length */
  int get length native "EntryArray_length_Getter";

  Entry operator[](int index) native "EntryArray_item_Callback";

  void operator[]=(int index, Entry value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Entry> mixins.
  // Entry is the element type.

  // From Iterable<Entry>:

  Iterator<Entry> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Entry>(this);
  }

  // From Collection<Entry>:

  void add(Entry value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(Entry value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<Entry> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(Entry element) => _Collections.contains(this, element);

  void forEach(void f(Entry element)) => _Collections.forEach(this, f);

  Collection map(f(Entry element)) => _Collections.map(this, [], f);

  Collection<Entry> filter(bool f(Entry element)) =>
     _Collections.filter(this, <Entry>[], f);

  bool every(bool f(Entry element)) => _Collections.every(this, f);

  bool some(bool f(Entry element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<Entry>:

  void sort([Comparator<Entry> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Entry element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Entry element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  Entry get first => this[0];

  Entry get last => this[length - 1];

  Entry removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<Entry> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [Entry initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<Entry> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <Entry>[]);

  // -- end List<Entry> mixins.


  /** @domName EntryArray.item */
  Entry item(int index) native "EntryArray_item_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName EntryArraySync
class _EntryArraySync extends NativeFieldWrapperClass1 implements List<EntrySync> {
  _EntryArraySync.internal();


  /** @domName EntryArraySync.length */
  int get length native "EntryArraySync_length_Getter";

  EntrySync operator[](int index) native "EntryArraySync_item_Callback";

  void operator[]=(int index, EntrySync value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<EntrySync> mixins.
  // EntrySync is the element type.

  // From Iterable<EntrySync>:

  Iterator<EntrySync> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<EntrySync>(this);
  }

  // From Collection<EntrySync>:

  void add(EntrySync value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(EntrySync value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<EntrySync> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(EntrySync element) => _Collections.contains(this, element);

  void forEach(void f(EntrySync element)) => _Collections.forEach(this, f);

  Collection map(f(EntrySync element)) => _Collections.map(this, [], f);

  Collection<EntrySync> filter(bool f(EntrySync element)) =>
     _Collections.filter(this, <EntrySync>[], f);

  bool every(bool f(EntrySync element)) => _Collections.every(this, f);

  bool some(bool f(EntrySync element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<EntrySync>:

  void sort([Comparator<EntrySync> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(EntrySync element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(EntrySync element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  EntrySync get first => this[0];

  EntrySync get last => this[length - 1];

  EntrySync removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<EntrySync> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [EntrySync initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<EntrySync> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <EntrySync>[]);

  // -- end List<EntrySync> mixins.


  /** @domName EntryArraySync.item */
  EntrySync item(int index) native "EntryArraySync_item_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _EventSourceFactoryProvider {
  static EventSource createEventSource(String scriptUrl) native "EventSource_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName FileList
class _FileList extends NativeFieldWrapperClass1 implements List<File> {
  _FileList.internal();


  /** @domName FileList.length */
  int get length native "FileList_length_Getter";

  File operator[](int index) native "FileList_item_Callback";

  void operator[]=(int index, File value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<File> mixins.
  // File is the element type.

  // From Iterable<File>:

  Iterator<File> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<File>(this);
  }

  // From Collection<File>:

  void add(File value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(File value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<File> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(File element) => _Collections.contains(this, element);

  void forEach(void f(File element)) => _Collections.forEach(this, f);

  Collection map(f(File element)) => _Collections.map(this, [], f);

  Collection<File> filter(bool f(File element)) =>
     _Collections.filter(this, <File>[], f);

  bool every(bool f(File element)) => _Collections.every(this, f);

  bool some(bool f(File element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<File>:

  void sort([Comparator<File> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(File element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(File element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  File get first => this[0];

  File get last => this[length - 1];

  File removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<File> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [File initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<File> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <File>[]);

  // -- end List<File> mixins.


  /** @domName FileList.item */
  File item(int index) native "FileList_item_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _FileReaderFactoryProvider {
  static FileReader createFileReader() native "FileReader_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _FileReaderSyncFactoryProvider {
  static FileReaderSync createFileReaderSync() native "FileReaderSync_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _FormDataFactoryProvider {
  static FormData createFormData([FormElement form]) native "DOMFormData_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName GamepadList
class _GamepadList extends NativeFieldWrapperClass1 implements List<Gamepad> {
  _GamepadList.internal();


  /** @domName GamepadList.length */
  int get length native "GamepadList_length_Getter";

  Gamepad operator[](int index) native "GamepadList_item_Callback";

  void operator[]=(int index, Gamepad value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Gamepad> mixins.
  // Gamepad is the element type.

  // From Iterable<Gamepad>:

  Iterator<Gamepad> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Gamepad>(this);
  }

  // From Collection<Gamepad>:

  void add(Gamepad value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(Gamepad value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<Gamepad> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(Gamepad element) => _Collections.contains(this, element);

  void forEach(void f(Gamepad element)) => _Collections.forEach(this, f);

  Collection map(f(Gamepad element)) => _Collections.map(this, [], f);

  Collection<Gamepad> filter(bool f(Gamepad element)) =>
     _Collections.filter(this, <Gamepad>[], f);

  bool every(bool f(Gamepad element)) => _Collections.every(this, f);

  bool some(bool f(Gamepad element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<Gamepad>:

  void sort([Comparator<Gamepad> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Gamepad element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Gamepad element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  Gamepad get first => this[0];

  Gamepad get last => this[length - 1];

  Gamepad removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<Gamepad> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [Gamepad initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<Gamepad> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <Gamepad>[]);

  // -- end List<Gamepad> mixins.


  /** @domName GamepadList.item */
  Gamepad item(int index) native "GamepadList_item_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _HttpRequestFactoryProvider {
  static HttpRequest createHttpRequest() => _createHttpRequest();
  static HttpRequest _createHttpRequest() native "XMLHttpRequest_constructor_Callback";

  static HttpRequest createHttpRequest_get(String url,
                                     onSuccess(HttpRequest request)) =>
      _HttpRequestUtils.get(url, onSuccess, false);

  static HttpRequest createHttpRequest_getWithCredentials(String url,
                                     onSuccess(HttpRequest request)) =>
      _HttpRequestUtils.get(url, onSuccess, true);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _IceCandidateFactoryProvider {
  static IceCandidate createIceCandidate(String label, String candidateLine) native "IceCandidate_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _MediaControllerFactoryProvider {
  static MediaController createMediaController() native "MediaController_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _MediaSourceFactoryProvider {
  static MediaSource createMediaSource() native "MediaSource_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _MediaStreamFactoryProvider {
  static MediaStream createMediaStream(MediaStreamTrackList audioTracks, MediaStreamTrackList videoTracks) native "MediaStream_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName MediaStreamList
class _MediaStreamList extends NativeFieldWrapperClass1 implements List<MediaStream> {
  _MediaStreamList.internal();


  /** @domName MediaStreamList.length */
  int get length native "MediaStreamList_length_Getter";

  MediaStream operator[](int index) native "MediaStreamList_item_Callback";

  void operator[]=(int index, MediaStream value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<MediaStream> mixins.
  // MediaStream is the element type.

  // From Iterable<MediaStream>:

  Iterator<MediaStream> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<MediaStream>(this);
  }

  // From Collection<MediaStream>:

  void add(MediaStream value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(MediaStream value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<MediaStream> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(MediaStream element) => _Collections.contains(this, element);

  void forEach(void f(MediaStream element)) => _Collections.forEach(this, f);

  Collection map(f(MediaStream element)) => _Collections.map(this, [], f);

  Collection<MediaStream> filter(bool f(MediaStream element)) =>
     _Collections.filter(this, <MediaStream>[], f);

  bool every(bool f(MediaStream element)) => _Collections.every(this, f);

  bool some(bool f(MediaStream element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<MediaStream>:

  void sort([Comparator<MediaStream> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(MediaStream element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(MediaStream element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  MediaStream get first => this[0];

  MediaStream get last => this[length - 1];

  MediaStream removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<MediaStream> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [MediaStream initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<MediaStream> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <MediaStream>[]);

  // -- end List<MediaStream> mixins.


  /** @domName MediaStreamList.item */
  MediaStream item(int index) native "MediaStreamList_item_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _MessageChannelFactoryProvider {
  static MessageChannel createMessageChannel() native "MessageChannel_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _MutationObserverFactoryProvider {
  static MutationObserver createMutationObserver(MutationCallback callback) native "MutationObserver_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName NodeList
class _NodeList extends NativeFieldWrapperClass1 implements List<Node> {
  _NodeList.internal();


  /** @domName NodeList.length */
  int get length native "NodeList_length_Getter";

  Node operator[](int index) native "NodeList_item_Callback";

  void operator[]=(int index, Node value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Node> mixins.
  // Node is the element type.

  // From Iterable<Node>:

  Iterator<Node> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Node>(this);
  }

  // From Collection<Node>:

  void add(Node value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(Node value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<Node> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(Node element) => _Collections.contains(this, element);

  void forEach(void f(Node element)) => _Collections.forEach(this, f);

  Collection map(f(Node element)) => _Collections.map(this, [], f);

  Collection<Node> filter(bool f(Node element)) =>
     _Collections.filter(this, <Node>[], f);

  bool every(bool f(Node element)) => _Collections.every(this, f);

  bool some(bool f(Node element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<Node>:

  void sort([Comparator<Node> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Node element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Node element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  Node get first => this[0];

  Node get last => this[length - 1];

  Node removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<Node> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [Node initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<Node> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <Node>[]);

  // -- end List<Node> mixins.


  /** @domName NodeList.item */
  Node _item(int index) native "NodeList_item_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _NotificationFactoryProvider {
  static Notification createNotification(String title, [Map options]) native "Notification_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _OptionElementFactoryProvider {
  static OptionElement createOptionElement([String data, String value, bool defaultSelected, bool selected]) native "HTMLOptionElement_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _PeerConnection00FactoryProvider {
  static PeerConnection00 createPeerConnection00(String serverConfiguration, IceCallback iceCallback) native "PeerConnection00_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _RTCIceCandidateFactoryProvider {
  static RTCIceCandidate createRTCIceCandidate(Map dictionary) native "RTCIceCandidate_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _RTCPeerConnectionFactoryProvider {
  static RTCPeerConnection createRTCPeerConnection(Map rtcIceServers, [Map mediaConstraints]) native "RTCPeerConnection_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _RTCSessionDescriptionFactoryProvider {
  static RTCSessionDescription createRTCSessionDescription(Map dictionary) native "RTCSessionDescription_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _SessionDescriptionFactoryProvider {
  static SessionDescription createSessionDescription(String sdp) native "SessionDescription_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _ShadowRootFactoryProvider {
  static ShadowRoot createShadowRoot(Element host) native "ShadowRoot_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _SharedWorkerFactoryProvider {
  static SharedWorker createSharedWorker(String scriptURL, [String name]) native "SharedWorker_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _SpeechGrammarFactoryProvider {
  static SpeechGrammar createSpeechGrammar() native "SpeechGrammar_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _SpeechGrammarListFactoryProvider {
  static SpeechGrammarList createSpeechGrammarList() native "SpeechGrammarList_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SpeechInputResultList
class _SpeechInputResultList extends NativeFieldWrapperClass1 implements List<SpeechInputResult> {
  _SpeechInputResultList.internal();


  /** @domName SpeechInputResultList.length */
  int get length native "SpeechInputResultList_length_Getter";

  SpeechInputResult operator[](int index) native "SpeechInputResultList_item_Callback";

  void operator[]=(int index, SpeechInputResult value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<SpeechInputResult> mixins.
  // SpeechInputResult is the element type.

  // From Iterable<SpeechInputResult>:

  Iterator<SpeechInputResult> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<SpeechInputResult>(this);
  }

  // From Collection<SpeechInputResult>:

  void add(SpeechInputResult value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(SpeechInputResult value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<SpeechInputResult> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(SpeechInputResult element) => _Collections.contains(this, element);

  void forEach(void f(SpeechInputResult element)) => _Collections.forEach(this, f);

  Collection map(f(SpeechInputResult element)) => _Collections.map(this, [], f);

  Collection<SpeechInputResult> filter(bool f(SpeechInputResult element)) =>
     _Collections.filter(this, <SpeechInputResult>[], f);

  bool every(bool f(SpeechInputResult element)) => _Collections.every(this, f);

  bool some(bool f(SpeechInputResult element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<SpeechInputResult>:

  void sort([Comparator<SpeechInputResult> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(SpeechInputResult element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(SpeechInputResult element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  SpeechInputResult get first => this[0];

  SpeechInputResult get last => this[length - 1];

  SpeechInputResult removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<SpeechInputResult> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [SpeechInputResult initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<SpeechInputResult> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <SpeechInputResult>[]);

  // -- end List<SpeechInputResult> mixins.


  /** @domName SpeechInputResultList.item */
  SpeechInputResult item(int index) native "SpeechInputResultList_item_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _SpeechRecognitionFactoryProvider {
  static SpeechRecognition createSpeechRecognition() native "SpeechRecognition_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName SpeechRecognitionResultList
class _SpeechRecognitionResultList extends NativeFieldWrapperClass1 implements List<SpeechRecognitionResult> {
  _SpeechRecognitionResultList.internal();


  /** @domName SpeechRecognitionResultList.length */
  int get length native "SpeechRecognitionResultList_length_Getter";

  SpeechRecognitionResult operator[](int index) native "SpeechRecognitionResultList_item_Callback";

  void operator[]=(int index, SpeechRecognitionResult value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<SpeechRecognitionResult> mixins.
  // SpeechRecognitionResult is the element type.

  // From Iterable<SpeechRecognitionResult>:

  Iterator<SpeechRecognitionResult> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<SpeechRecognitionResult>(this);
  }

  // From Collection<SpeechRecognitionResult>:

  void add(SpeechRecognitionResult value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(SpeechRecognitionResult value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<SpeechRecognitionResult> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(SpeechRecognitionResult element) => _Collections.contains(this, element);

  void forEach(void f(SpeechRecognitionResult element)) => _Collections.forEach(this, f);

  Collection map(f(SpeechRecognitionResult element)) => _Collections.map(this, [], f);

  Collection<SpeechRecognitionResult> filter(bool f(SpeechRecognitionResult element)) =>
     _Collections.filter(this, <SpeechRecognitionResult>[], f);

  bool every(bool f(SpeechRecognitionResult element)) => _Collections.every(this, f);

  bool some(bool f(SpeechRecognitionResult element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<SpeechRecognitionResult>:

  void sort([Comparator<SpeechRecognitionResult> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(SpeechRecognitionResult element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(SpeechRecognitionResult element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  SpeechRecognitionResult get first => this[0];

  SpeechRecognitionResult get last => this[length - 1];

  SpeechRecognitionResult removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<SpeechRecognitionResult> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [SpeechRecognitionResult initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<SpeechRecognitionResult> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <SpeechRecognitionResult>[]);

  // -- end List<SpeechRecognitionResult> mixins.


  /** @domName SpeechRecognitionResultList.item */
  SpeechRecognitionResult item(int index) native "SpeechRecognitionResultList_item_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName StyleSheetList
class _StyleSheetList extends NativeFieldWrapperClass1 implements List<StyleSheet> {
  _StyleSheetList.internal();


  /** @domName StyleSheetList.length */
  int get length native "StyleSheetList_length_Getter";

  StyleSheet operator[](int index) native "StyleSheetList_item_Callback";

  void operator[]=(int index, StyleSheet value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<StyleSheet> mixins.
  // StyleSheet is the element type.

  // From Iterable<StyleSheet>:

  Iterator<StyleSheet> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<StyleSheet>(this);
  }

  // From Collection<StyleSheet>:

  void add(StyleSheet value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(StyleSheet value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<StyleSheet> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(StyleSheet element) => _Collections.contains(this, element);

  void forEach(void f(StyleSheet element)) => _Collections.forEach(this, f);

  Collection map(f(StyleSheet element)) => _Collections.map(this, [], f);

  Collection<StyleSheet> filter(bool f(StyleSheet element)) =>
     _Collections.filter(this, <StyleSheet>[], f);

  bool every(bool f(StyleSheet element)) => _Collections.every(this, f);

  bool some(bool f(StyleSheet element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<StyleSheet>:

  void sort([Comparator<StyleSheet> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(StyleSheet element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(StyleSheet element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  StyleSheet get first => this[0];

  StyleSheet get last => this[length - 1];

  StyleSheet removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<StyleSheet> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [StyleSheet initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<StyleSheet> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <StyleSheet>[]);

  // -- end List<StyleSheet> mixins.


  /** @domName StyleSheetList.item */
  StyleSheet item(int index) native "StyleSheetList_item_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _TextTrackCueFactoryProvider {
  static TextTrackCue createTextTrackCue(num startTime, num endTime, String text) native "TextTrackCue_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName WebKitAnimationList
class _WebKitAnimationList extends NativeFieldWrapperClass1 implements List<Animation> {
  _WebKitAnimationList.internal();


  /** @domName WebKitAnimationList.length */
  int get length native "WebKitAnimationList_length_Getter";

  Animation operator[](int index) native "WebKitAnimationList_item_Callback";

  void operator[]=(int index, Animation value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Animation> mixins.
  // Animation is the element type.

  // From Iterable<Animation>:

  Iterator<Animation> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Animation>(this);
  }

  // From Collection<Animation>:

  void add(Animation value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(Animation value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<Animation> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(Animation element) => _Collections.contains(this, element);

  void forEach(void f(Animation element)) => _Collections.forEach(this, f);

  Collection map(f(Animation element)) => _Collections.map(this, [], f);

  Collection<Animation> filter(bool f(Animation element)) =>
     _Collections.filter(this, <Animation>[], f);

  bool every(bool f(Animation element)) => _Collections.every(this, f);

  bool some(bool f(Animation element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<Animation>:

  void sort([Comparator<Animation> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Animation element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Animation element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  Animation get first => this[0];

  Animation get last => this[length - 1];

  Animation removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<Animation> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [Animation initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<Animation> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <Animation>[]);

  // -- end List<Animation> mixins.


  /** @domName WebKitAnimationList.item */
  Animation item(int index) native "WebKitAnimationList_item_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _WorkerFactoryProvider {
  static Worker createWorker(String scriptUrl) native "Worker_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _XMLSerializerFactoryProvider {
  static XMLSerializer createXMLSerializer() native "XMLSerializer_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _XPathEvaluatorFactoryProvider {
  static XPathEvaluator createXPathEvaluator() native "XPathEvaluator_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _XSLTProcessorFactoryProvider {
  static XSLTProcessor createXSLTProcessor() native "XSLTProcessor_constructor_Callback";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


abstract class _AttributeMap implements Map<String, String> {

  bool containsValue(String value) {
    for (var v in this.values) {
      if (value == v) {
        return true;
      }
    }
    return false;
  }

  String putIfAbsent(String key, String ifAbsent()) {
    if (!containsKey(key)) {
      this[key] = ifAbsent();
    }
    return this[key];
  }

  void clear() {
    for (var key in keys) {
      remove(key);
    }
  }

  void forEach(void f(String key, String value)) {
    for (var key in keys) {
      var value = this[key];
      f(key, value);
    }
  }

  Collection<String> get keys {
    // TODO: generate a lazy collection instead.
    var attributes = _element.$dom_attributes;
    var keys = new List<String>();
    for (int i = 0, len = attributes.length; i < len; i++) {
      if (_matches(attributes[i])) {
        keys.add(attributes[i].$dom_localName);
      }
    }
    return keys;
  }

  Collection<String> get values {
    // TODO: generate a lazy collection instead.
    var attributes = _element.$dom_attributes;
    var values = new List<String>();
    for (int i = 0, len = attributes.length; i < len; i++) {
      if (_matches(attributes[i])) {
        values.add(attributes[i].value);
      }
    }
    return values;
  }

  /**
   * Returns true if there is no {key, value} pair in the map.
   */
  bool get isEmpty {
    return length == 0;
  }

  /**
   * Checks to see if the node should be included in this map.
   */
  bool _matches(Node node);
}

/**
 * Wrapper to expose Element.attributes as a typed map.
 */
class _ElementAttributeMap extends _AttributeMap {

  final Element _element;

  _ElementAttributeMap(this._element);

  bool containsKey(String key) {
    return _element.$dom_hasAttribute(key);
  }

  String operator [](String key) {
    return _element.$dom_getAttribute(key);
  }

  void operator []=(String key, value) {
    _element.$dom_setAttribute(key, '$value');
  }

  String remove(String key) {
    String value = _element.$dom_getAttribute(key);
    _element.$dom_removeAttribute(key);
    return value;
  }

  /**
   * The number of {key, value} pairs in the map.
   */
  int get length {
    return keys.length;
  }

  bool _matches(Node node) => node.$dom_namespaceURI == null;
}

/**
 * Wrapper to expose namespaced attributes as a typed map.
 */
class _NamespacedAttributeMap extends _AttributeMap {

  final Element _element;
  final String _namespace;

  _NamespacedAttributeMap(this._element, this._namespace);

  bool containsKey(String key) {
    return _element.$dom_hasAttributeNS(_namespace, key);
  }

  String operator [](String key) {
    return _element.$dom_getAttributeNS(_namespace, key);
  }

  void operator []=(String key, value) {
    _element.$dom_setAttributeNS(_namespace, key, '$value');
  }

  String remove(String key) {
    String value = this[key];
    _element.$dom_removeAttributeNS(_namespace, key);
    return value;
  }

  /**
   * The number of {key, value} pairs in the map.
   */
  int get length {
    return keys.length;
  }

  bool _matches(Node node) => node.$dom_namespaceURI == _namespace;
}


/**
 * Provides a Map abstraction on top of data-* attributes, similar to the
 * dataSet in the old DOM.
 */
class _DataAttributeMap implements Map<String, String> {

  final Map<String, String> $dom_attributes;

  _DataAttributeMap(this.$dom_attributes);

  // interface Map

  // TODO: Use lazy iterator when it is available on Map.
  bool containsValue(String value) => values.some((v) => v == value);

  bool containsKey(String key) => $dom_attributes.containsKey(_attr(key));

  String operator [](String key) => $dom_attributes[_attr(key)];

  void operator []=(String key, value) {
    $dom_attributes[_attr(key)] = '$value';
  }

  String putIfAbsent(String key, String ifAbsent()) =>
    $dom_attributes.putIfAbsent(_attr(key), ifAbsent);

  String remove(String key) => $dom_attributes.remove(_attr(key));

  void clear() {
    // Needs to operate on a snapshot since we are mutating the collection.
    for (String key in keys) {
      remove(key);
    }
  }

  void forEach(void f(String key, String value)) {
    $dom_attributes.forEach((String key, String value) {
      if (_matches(key)) {
        f(_strip(key), value);
      }
    });
  }

  Collection<String> get keys {
    final keys = new List<String>();
    $dom_attributes.forEach((String key, String value) {
      if (_matches(key)) {
        keys.add(_strip(key));
      }
    });
    return keys;
  }

  Collection<String> get values {
    final values = new List<String>();
    $dom_attributes.forEach((String key, String value) {
      if (_matches(key)) {
        values.add(value);
      }
    });
    return values;
  }

  int get length => keys.length;

  // TODO: Use lazy iterator when it is available on Map.
  bool get isEmpty => length == 0;

  // Helpers.
  String _attr(String key) => 'data-$key';
  bool _matches(String key) => key.startsWith('data-');
  String _strip(String key) => key.substring(5);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * An object representing the top-level context object for web scripting.
 *
 * In a web browser, a [Window] object represents the actual browser window.
 * In a multi-tabbed browser, each tab has its own [Window] object. A [Window]
 * is the container that displays a [Document]'s content. All web scripting
 * happens within the context of a [Window] object.
 *
 * **Note:** This class represents any window, whereas [LocalWindow] is
 * used to access the properties and content of the current window.
 *
 * See also:
 *
 * * [DOM Window](https://developer.mozilla.org/en-US/docs/DOM/window) from MDN.
 * * [Window](http://www.w3.org/TR/Window/) from the W3C.
 */
abstract class Window {
  // Fields.

  /**
   * The current location of this window.
   *
   *     Location currentLocation = window.location;
   *     print(currentLocation.href); // 'http://www.example.com:80/'
   */
  Location get location;
  History get history;

  /**
   * Indicates whether this window is closed.
   *
   *     print(window.closed); // 'false'
   *     window.close();
   *     print(window.closed); // 'true'
   */
  bool get closed;

  /**
   * A reference to the window that opened this one.
   *
   *     Window thisWindow = window;
   *     Window otherWindow = thisWindow.open('http://www.example.com/', 'foo');
   *     print(otherWindow.opener == thisWindow); // 'true'
   */
  Window get opener;

  /**
   * A reference to the parent of this window.
   *
   * If this [Window] has no parent, [parent] will return a reference to
   * the [Window] itself.
   *
   *     IFrameElement myIFrame = new IFrameElement();
   *     window.document.body.elements.add(myIFrame);
   *     print(myIframe.contentWindow.parent == window) // 'true'
   *
   *     print(window.parent == window) // 'true'
   */
  Window get parent;

  /**
   * A reference to the topmost window in the window hierarchy.
   *
   * If this [Window] is the topmost [Window], [top] will return a reference to
   * the [Window] itself.
   *
   *     // Add an IFrame to the current window.
   *     IFrameElement myIFrame = new IFrameElement();
   *     window.document.body.elements.add(myIFrame);
   *
   *     // Add an IFrame inside of the other IFrame.
   *     IFrameElement innerIFrame = new IFrameElement();
   *     myIFrame.elements.add(innerIFrame);
   *
   *     print(myIframe.contentWindow.top == window) // 'true'
   *     print(innerIFrame.contentWindow.top == window) // 'true'
   *
   *     print(window.top == window) // 'true'
   */
  Window get top;

  // Methods.
  void close();
  void postMessage(var message, String targetOrigin, [List messagePorts = null]);
}

abstract class Location {
  void set href(String val);
}

abstract class History {
  void back();
  void forward();
  void go(int distance);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


abstract class CssClassSet implements Set<String> {

  String toString() {
    return Strings.join(new List.from(readClasses()), ' ');
  }

  /**
   * Adds the class [token] to the element if it is not on it, removes it if it
   * is.
   */
  bool toggle(String value) {
    Set<String> s = readClasses();
    bool result = false;
    if (s.contains(value)) {
      s.remove(value);
    } else {
      s.add(value);
      result = true;
    }
    writeClasses(s);
    return result;
  }

  /**
   * Returns [:true:] if classes cannot be added or removed from this
   * [:CssClassSet:].
   */
  bool get frozen => false;

  // interface Iterable - BEGIN
  Iterator<String> iterator() => readClasses().iterator();
  // interface Iterable - END

  // interface Collection - BEGIN
  void forEach(void f(String element)) {
    readClasses().forEach(f);
  }

  Collection map(f(String element)) => readClasses().map(f);

  Collection<String> filter(bool f(String element)) => readClasses().filter(f);

  bool every(bool f(String element)) => readClasses().every(f);

  bool some(bool f(String element)) => readClasses().some(f);

  bool get isEmpty => readClasses().isEmpty;

  int get length =>readClasses().length;
  // interface Collection - END

  // interface Set - BEGIN
  bool contains(String value) => readClasses().contains(value);

  void add(String value) {
    // TODO - figure out if we need to do any validation here
    // or if the browser natively does enough
    _modify((s) => s.add(value));
  }

  bool remove(String value) {
    Set<String> s = readClasses();
    bool result = s.remove(value);
    writeClasses(s);
    return result;
  }

  void addAll(Collection<String> collection) {
    // TODO - see comment above about validation
    _modify((s) => s.addAll(collection));
  }

  void removeAll(Collection<String> collection) {
    _modify((s) => s.removeAll(collection));
  }

  bool isSubsetOf(Collection<String> collection) =>
    readClasses().isSubsetOf(collection);

  bool containsAll(Collection<String> collection) =>
    readClasses().containsAll(collection);

  Set<String> intersection(Collection<String> other) =>
    readClasses().intersection(other);

  void clear() {
    _modify((s) => s.clear());
  }
  // interface Set - END

  /**
   * Helper method used to modify the set of css classes on this element.
   *
   *   f - callback with:
   *      s - a Set of all the css class name currently on this element.
   *
   *   After f returns, the modified set is written to the
   *       className property of this element.
   */
  void _modify( f(Set<String> s)) {
    Set<String> s = readClasses();
    f(s);
    writeClasses(s);
  }

  /**
   * Read the class names from the Element class property,
   * and put them into a set (duplicates are discarded).
   * This is intended to be overridden by specific implementations.
   */
  Set<String> readClasses();

  /**
   * Join all the elements of a set into one string and write
   * back to the element.
   * This is intended to be overridden by specific implementations.
   */
  void writeClasses(Set<String> s);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


typedef void EventListener(Event event);
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class FilteredElementList implements List {
  final Node _node;
  final List<Node> _childNodes;

  FilteredElementList(Node node): _childNodes = node.nodes, _node = node;

  // We can't memoize this, since it's possible that children will be messed
  // with externally to this class.
  //
  // TODO(nweiz): Do we really need to copy the list to make the types work out?
  List<Element> get _filtered =>
    new List.from(_childNodes.filter((n) => n is Element));

  void forEach(void f(Element element)) {
    _filtered.forEach(f);
  }

  void operator []=(int index, Element value) {
    this[index].replaceWith(value);
  }

  void set length(int newLength) {
    final len = this.length;
    if (newLength >= len) {
      return;
    } else if (newLength < 0) {
      throw new ArgumentError("Invalid list length");
    }

    removeRange(newLength - 1, len - newLength);
  }

  void add(Element value) {
    _childNodes.add(value);
  }

  void addAll(Collection<Element> collection) {
    collection.forEach(add);
  }

  void addLast(Element value) {
    add(value);
  }

  bool contains(Element element) {
    return element is Element && _childNodes.contains(element);
  }

  void sort([Comparator<Element> compare = Comparable.compare]) {
    throw new UnsupportedError('TODO(jacobr): should we impl?');
  }

  void setRange(int start, int rangeLength, List from, [int startFrom = 0]) {
    throw new UnimplementedError();
  }

  void removeRange(int start, int rangeLength) {
    _filtered.getRange(start, rangeLength).forEach((el) => el.remove());
  }

  void insertRange(int start, int rangeLength, [initialValue = null]) {
    throw new UnimplementedError();
  }

  void clear() {
    // Currently, ElementList#clear clears even non-element nodes, so we follow
    // that behavior.
    _childNodes.clear();
  }

  Element removeLast() {
    final result = this.last;
    if (result != null) {
      result.remove();
    }
    return result;
  }

  Collection map(f(Element element)) => _filtered.map(f);
  Collection<Element> filter(bool f(Element element)) => _filtered.filter(f);
  bool every(bool f(Element element)) => _filtered.every(f);
  bool some(bool f(Element element)) => _filtered.some(f);
  bool get isEmpty => _filtered.isEmpty;
  int get length => _filtered.length;
  Element operator [](int index) => _filtered[index];
  Iterator<Element> iterator() => _filtered.iterator();
  List<Element> getRange(int start, int rangeLength) =>
    _filtered.getRange(start, rangeLength);
  int indexOf(Element element, [int start = 0]) =>
    _filtered.indexOf(element, start);

  int lastIndexOf(Element element, [int start = null]) {
    if (start == null) start = length - 1;
    return _filtered.lastIndexOf(element, start);
  }

  Element get first => _filtered.first;

  Element get last => _filtered.last;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * Defines the keycode values for keys that are returned by 
 * KeyboardEvent.keyCode.
 * 
 * Important note: There is substantial divergence in how different browsers
 * handle keycodes and their variants in different locales/keyboard layouts. We
 * provide these constants to help make code processing keys more readable.
 */
abstract class KeyCode {
  // These constant names were borrowed from Closure's Keycode enumeration
  // class.
  // http://closure-library.googlecode.com/svn/docs/closure_goog_events_keycodes.js.source.html  
  static const int WIN_KEY_FF_LINUX = 0;
  static const int MAC_ENTER = 3;
  static const int BACKSPACE = 8;
  static const int TAB = 9;
  /** NUM_CENTER is also NUMLOCK for FF and Safari on Mac. */
  static const int NUM_CENTER = 12;
  static const int ENTER = 13;
  static const int SHIFT = 16;
  static const int CTRL = 17;
  static const int ALT = 18;
  static const int PAUSE = 19;
  static const int CAPS_LOCK = 20;
  static const int ESC = 27;
  static const int SPACE = 32;
  static const int PAGE_UP = 33;
  static const int PAGE_DOWN = 34;
  static const int END = 35;
  static const int HOME = 36;
  static const int LEFT = 37;
  static const int UP = 38;
  static const int RIGHT = 39;
  static const int DOWN = 40;
  static const int NUM_NORTH_EAST = 33;
  static const int NUM_SOUTH_EAST = 34;
  static const int NUM_SOUTH_WEST = 35;
  static const int NUM_NORTH_WEST = 36;
  static const int NUM_WEST = 37;
  static const int NUM_NORTH = 38;
  static const int NUM_EAST = 39;
  static const int NUM_SOUTH = 40;
  static const int PRINT_SCREEN = 44;
  static const int INSERT = 45;
  static const int NUM_INSERT = 45;
  static const int DELETE = 46;
  static const int NUM_DELETE = 46;
  static const int ZERO = 48;
  static const int ONE = 49;
  static const int TWO = 50;
  static const int THREE = 51;
  static const int FOUR = 52;
  static const int FIVE = 53;
  static const int SIX = 54;
  static const int SEVEN = 55;
  static const int EIGHT = 56;
  static const int NINE = 57;
  static const int FF_SEMICOLON = 59;
  static const int FF_EQUALS = 61;
  /**
   * CAUTION: The question mark is for US-keyboard layouts. It varies
   * for other locales and keyboard layouts.
   */
  static const int QUESTION_MARK = 63;
  static const int A = 65;
  static const int B = 66;
  static const int C = 67;
  static const int D = 68;
  static const int E = 69;
  static const int F = 70;
  static const int G = 71;
  static const int H = 72;
  static const int I = 73;
  static const int J = 74;
  static const int K = 75;
  static const int L = 76;
  static const int M = 77;
  static const int N = 78;
  static const int O = 79;
  static const int P = 80;
  static const int Q = 81;
  static const int R = 82;
  static const int S = 83;
  static const int T = 84;
  static const int U = 85;
  static const int V = 86;
  static const int W = 87;
  static const int X = 88;
  static const int Y = 89;
  static const int Z = 90;
  static const int META = 91;
  static const int WIN_KEY_LEFT = 91;
  static const int WIN_KEY_RIGHT = 92;
  static const int CONTEXT_MENU = 93;
  static const int NUM_ZERO = 96;
  static const int NUM_ONE = 97;
  static const int NUM_TWO = 98;
  static const int NUM_THREE = 99;
  static const int NUM_FOUR = 100;
  static const int NUM_FIVE = 101;
  static const int NUM_SIX = 102;
  static const int NUM_SEVEN = 103;
  static const int NUM_EIGHT = 104;
  static const int NUM_NINE = 105;
  static const int NUM_MULTIPLY = 106;
  static const int NUM_PLUS = 107;
  static const int NUM_MINUS = 109;
  static const int NUM_PERIOD = 110;
  static const int NUM_DIVISION = 111;
  static const int F1 = 112;
  static const int F2 = 113;
  static const int F3 = 114;
  static const int F4 = 115;
  static const int F5 = 116;
  static const int F6 = 117;
  static const int F7 = 118;
  static const int F8 = 119;
  static const int F9 = 120;
  static const int F10 = 121;
  static const int F11 = 122;
  static const int F12 = 123;
  static const int NUMLOCK = 144;
  static const int SCROLL_LOCK = 145;

  // OS-specific media keys like volume controls and browser controls.
  static const int FIRST_MEDIA_KEY = 166;
  static const int LAST_MEDIA_KEY = 183;

  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int SEMICOLON = 186;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int DASH = 189;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int EQUALS = 187;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int COMMA = 188;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int PERIOD = 190;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int SLASH = 191;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int APOSTROPHE = 192;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int TILDE = 192;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int SINGLE_QUOTE = 222;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int OPEN_SQUARE_BRACKET = 219;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int BACKSLASH = 220;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int CLOSE_SQUARE_BRACKET = 221;
  static const int WIN_KEY = 224;
  static const int MAC_FF_META = 224;
  static const int WIN_IME = 229;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * Defines the standard key locations returned by
 * KeyboardEvent.getKeyLocation.
 */
abstract class KeyLocation {

  /**
   * The event key is not distinguished as the left or right version
   * of the key, and did not originate from the numeric keypad (or did not
   * originate with a virtual key corresponding to the numeric keypad).
   */
  static const int STANDARD = 0;

  /**
   * The event key is in the left key location.
   */
  static const int LEFT = 1;

  /**
   * The event key is in the right key location.
   */
  static const int RIGHT = 2;

  /**
   * The event key originated on the numeric keypad or with a virtual key
   * corresponding to the numeric keypad.
   */
  static const int NUMPAD = 3;

  /**
   * The event key originated on a mobile device, either on a physical
   * keypad or a virtual keyboard.
   */
  static const int MOBILE = 4;

  /**
   * The event key originated on a game controller or a joystick on a mobile
   * device.
   */
  static const int JOYSTICK = 5;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * Defines the standard keyboard identifier names for keys that are returned
 * by KeyEvent.getKeyboardIdentifier when the key does not have a direct
 * unicode mapping.
 */
abstract class KeyName {

  /** The Accept (Commit, OK) key */
  static const String ACCEPT = "Accept";

  /** The Add key */
  static const String ADD = "Add";

  /** The Again key */
  static const String AGAIN = "Again";

  /** The All Candidates key */
  static const String ALL_CANDIDATES = "AllCandidates";

  /** The Alphanumeric key */
  static const String ALPHANUMERIC = "Alphanumeric";

  /** The Alt (Menu) key */
  static const String ALT = "Alt";

  /** The Alt-Graph key */
  static const String ALT_GRAPH = "AltGraph";

  /** The Application key */
  static const String APPS = "Apps";

  /** The ATTN key */
  static const String ATTN = "Attn";

  /** The Browser Back key */
  static const String BROWSER_BACK = "BrowserBack";

  /** The Browser Favorites key */
  static const String BROWSER_FAVORTIES = "BrowserFavorites";

  /** The Browser Forward key */
  static const String BROWSER_FORWARD = "BrowserForward";

  /** The Browser Home key */
  static const String BROWSER_NAME = "BrowserHome";

  /** The Browser Refresh key */
  static const String BROWSER_REFRESH = "BrowserRefresh";

  /** The Browser Search key */
  static const String BROWSER_SEARCH = "BrowserSearch";

  /** The Browser Stop key */
  static const String BROWSER_STOP = "BrowserStop";

  /** The Camera key */
  static const String CAMERA = "Camera";

  /** The Caps Lock (Capital) key */
  static const String CAPS_LOCK = "CapsLock";

  /** The Clear key */
  static const String CLEAR = "Clear";

  /** The Code Input key */
  static const String CODE_INPUT = "CodeInput";

  /** The Compose key */
  static const String COMPOSE = "Compose";

  /** The Control (Ctrl) key */
  static const String CONTROL = "Control";

  /** The Crsel key */
  static const String CRSEL = "Crsel";

  /** The Convert key */
  static const String CONVERT = "Convert";

  /** The Copy key */
  static const String COPY = "Copy";

  /** The Cut key */
  static const String CUT = "Cut";

  /** The Decimal key */
  static const String DECIMAL = "Decimal";

  /** The Divide key */
  static const String DIVIDE = "Divide";

  /** The Down Arrow key */
  static const String DOWN = "Down";

  /** The diagonal Down-Left Arrow key */
  static const String DOWN_LEFT = "DownLeft";

  /** The diagonal Down-Right Arrow key */
  static const String DOWN_RIGHT = "DownRight";

  /** The Eject key */
  static const String EJECT = "Eject";

  /** The End key */
  static const String END = "End";

  /**
   * The Enter key. Note: This key value must also be used for the Return
   *  (Macintosh numpad) key
   */
  static const String ENTER = "Enter";

  /** The Erase EOF key */
  static const String ERASE_EOF= "EraseEof";

  /** The Execute key */
  static const String EXECUTE = "Execute";

  /** The Exsel key */
  static const String EXSEL = "Exsel";

  /** The Function switch key */
  static const String FN = "Fn";

  /** The F1 key */
  static const String F1 = "F1";

  /** The F2 key */
  static const String F2 = "F2";

  /** The F3 key */
  static const String F3 = "F3";

  /** The F4 key */
  static const String F4 = "F4";

  /** The F5 key */
  static const String F5 = "F5";

  /** The F6 key */
  static const String F6 = "F6";

  /** The F7 key */
  static const String F7 = "F7";

  /** The F8 key */
  static const String F8 = "F8";

  /** The F9 key */
  static const String F9 = "F9";

  /** The F10 key */
  static const String F10 = "F10";

  /** The F11 key */
  static const String F11 = "F11";

  /** The F12 key */
  static const String F12 = "F12";

  /** The F13 key */
  static const String F13 = "F13";

  /** The F14 key */
  static const String F14 = "F14";

  /** The F15 key */
  static const String F15 = "F15";

  /** The F16 key */
  static const String F16 = "F16";

  /** The F17 key */
  static const String F17 = "F17";

  /** The F18 key */
  static const String F18 = "F18";

  /** The F19 key */
  static const String F19 = "F19";

  /** The F20 key */
  static const String F20 = "F20";

  /** The F21 key */
  static const String F21 = "F21";

  /** The F22 key */
  static const String F22 = "F22";

  /** The F23 key */
  static const String F23 = "F23";

  /** The F24 key */
  static const String F24 = "F24";

  /** The Final Mode (Final) key used on some asian keyboards */
  static const String FINAL_MODE = "FinalMode";

  /** The Find key */
  static const String FIND = "Find";

  /** The Full-Width Characters key */
  static const String FULL_WIDTH = "FullWidth";

  /** The Half-Width Characters key */
  static const String HALF_WIDTH = "HalfWidth";

  /** The Hangul (Korean characters) Mode key */
  static const String HANGUL_MODE = "HangulMode";

  /** The Hanja (Korean characters) Mode key */
  static const String HANJA_MODE = "HanjaMode";

  /** The Help key */
  static const String HELP = "Help";

  /** The Hiragana (Japanese Kana characters) key */
  static const String HIRAGANA = "Hiragana";

  /** The Home key */
  static const String HOME = "Home";

  /** The Insert (Ins) key */
  static const String INSERT = "Insert";

  /** The Japanese-Hiragana key */
  static const String JAPANESE_HIRAGANA = "JapaneseHiragana";

  /** The Japanese-Katakana key */
  static const String JAPANESE_KATAKANA = "JapaneseKatakana";

  /** The Japanese-Romaji key */
  static const String JAPANESE_ROMAJI = "JapaneseRomaji";

  /** The Junja Mode key */
  static const String JUNJA_MODE = "JunjaMode";

  /** The Kana Mode (Kana Lock) key */
  static const String KANA_MODE = "KanaMode";

  /**
   * The Kanji (Japanese name for ideographic characters of Chinese origin)
   * Mode key
   */
  static const String KANJI_MODE = "KanjiMode";

  /** The Katakana (Japanese Kana characters) key */
  static const String KATAKANA = "Katakana";

  /** The Start Application One key */
  static const String LAUNCH_APPLICATION_1 = "LaunchApplication1";

  /** The Start Application Two key */
  static const String LAUNCH_APPLICATION_2 = "LaunchApplication2";

  /** The Start Mail key */
  static const String LAUNCH_MAIL = "LaunchMail";

  /** The Left Arrow key */
  static const String LEFT = "Left";

  /** The Menu key */
  static const String MENU = "Menu";

  /**
   * The Meta key. Note: This key value shall be also used for the Apple
   * Command key
   */
  static const String META = "Meta";

  /** The Media Next Track key */
  static const String MEDIA_NEXT_TRACK = "MediaNextTrack";

  /** The Media Play Pause key */
  static const String MEDIA_PAUSE_PLAY = "MediaPlayPause";

  /** The Media Previous Track key */
  static const String MEDIA_PREVIOUS_TRACK = "MediaPreviousTrack";

  /** The Media Stop key */
  static const String MEDIA_STOP = "MediaStop";

  /** The Mode Change key */
  static const String MODE_CHANGE = "ModeChange";

  /** The Next Candidate function key */
  static const String NEXT_CANDIDATE = "NextCandidate";

  /** The Nonconvert (Don't Convert) key */
  static const String NON_CONVERT = "Nonconvert";

  /** The Number Lock key */
  static const String NUM_LOCK = "NumLock";

  /** The Page Down (Next) key */
  static const String PAGE_DOWN = "PageDown";

  /** The Page Up key */
  static const String PAGE_UP = "PageUp";

  /** The Paste key */
  static const String PASTE = "Paste";

  /** The Pause key */
  static const String PAUSE = "Pause";

  /** The Play key */
  static const String PLAY = "Play";

  /**
   * The Power key. Note: Some devices may not expose this key to the
   * operating environment
   */
  static const String POWER = "Power";

  /** The Previous Candidate function key */
  static const String PREVIOUS_CANDIDATE = "PreviousCandidate";

  /** The Print Screen (PrintScrn, SnapShot) key */
  static const String PRINT_SCREEN = "PrintScreen";

  /** The Process key */
  static const String PROCESS = "Process";

  /** The Props key */
  static const String PROPS = "Props";

  /** The Right Arrow key */
  static const String RIGHT = "Right";

  /** The Roman Characters function key */
  static const String ROMAN_CHARACTERS = "RomanCharacters";

  /** The Scroll Lock key */
  static const String SCROLL = "Scroll";

  /** The Select key */
  static const String SELECT = "Select";

  /** The Select Media key */
  static const String SELECT_MEDIA = "SelectMedia";

  /** The Separator key */
  static const String SEPARATOR = "Separator";

  /** The Shift key */
  static const String SHIFT = "Shift";

  /** The Soft1 key */
  static const String SOFT_1 = "Soft1";

  /** The Soft2 key */
  static const String SOFT_2 = "Soft2";

  /** The Soft3 key */
  static const String SOFT_3 = "Soft3";

  /** The Soft4 key */
  static const String SOFT_4 = "Soft4";

  /** The Stop key */
  static const String STOP = "Stop";

  /** The Subtract key */
  static const String SUBTRACT = "Subtract";

  /** The Symbol Lock key */
  static const String SYMBOL_LOCK = "SymbolLock";

  /** The Up Arrow key */
  static const String UP = "Up";

  /** The diagonal Up-Left Arrow key */
  static const String UP_LEFT = "UpLeft";

  /** The diagonal Up-Right Arrow key */
  static const String UP_RIGHT = "UpRight";

  /** The Undo key */
  static const String UNDO = "Undo";

  /** The Volume Down key */
  static const String VOLUME_DOWN = "VolumeDown";

  /** The Volume Mute key */
  static const String VOLUMN_MUTE = "VolumeMute";

  /** The Volume Up key */
  static const String VOLUMN_UP = "VolumeUp";

  /** The Windows Logo key */
  static const String WIN = "Win";

  /** The Zoom key */
  static const String ZOOM = "Zoom";

  /**
   * The Backspace (Back) key. Note: This key value shall be also used for the
   * key labeled 'delete' MacOS keyboards when not modified by the 'Fn' key
   */
  static const String BACKSPACE = "Backspace";

  /** The Horizontal Tabulation (Tab) key */
  static const String TAB = "Tab";

  /** The Cancel key */
  static const String CANCEL = "Cancel";

  /** The Escape (Esc) key */
  static const String ESC = "Esc";

  /** The Space (Spacebar) key:   */
  static const String SPACEBAR = "Spacebar";

  /**
   * The Delete (Del) Key. Note: This key value shall be also used for the key
   * labeled 'delete' MacOS keyboards when modified by the 'Fn' key
   */
  static const String DEL = "Del";

  /** The Combining Grave Accent (Greek Varia, Dead Grave) key */
  static const String DEAD_GRAVE = "DeadGrave";

  /**
   * The Combining Acute Accent (Stress Mark, Greek Oxia, Tonos, Dead Eacute)
   * key
   */
  static const String DEAD_EACUTE = "DeadEacute";

  /** The Combining Circumflex Accent (Hat, Dead Circumflex) key */
  static const String DEAD_CIRCUMFLEX = "DeadCircumflex";

  /** The Combining Tilde (Dead Tilde) key */
  static const String DEAD_TILDE = "DeadTilde";

  /** The Combining Macron (Long, Dead Macron) key */
  static const String DEAD_MACRON = "DeadMacron";

  /** The Combining Breve (Short, Dead Breve) key */
  static const String DEAD_BREVE = "DeadBreve";

  /** The Combining Dot Above (Derivative, Dead Above Dot) key */
  static const String DEAD_ABOVE_DOT = "DeadAboveDot";

  /**
   * The Combining Diaeresis (Double Dot Abode, Umlaut, Greek Dialytika,
   * Double Derivative, Dead Diaeresis) key
   */
  static const String DEAD_UMLAUT = "DeadUmlaut";

  /** The Combining Ring Above (Dead Above Ring) key */
  static const String DEAD_ABOVE_RING = "DeadAboveRing";

  /** The Combining Double Acute Accent (Dead Doubleacute) key */
  static const String DEAD_DOUBLEACUTE = "DeadDoubleacute";

  /** The Combining Caron (Hacek, V Above, Dead Caron) key */
  static const String DEAD_CARON = "DeadCaron";

  /** The Combining Cedilla (Dead Cedilla) key */
  static const String DEAD_CEDILLA = "DeadCedilla";

  /** The Combining Ogonek (Nasal Hook, Dead Ogonek) key */
  static const String DEAD_OGONEK = "DeadOgonek";

  /**
   * The Combining Greek Ypogegrammeni (Greek Non-Spacing Iota Below, Iota
   * Subscript, Dead Iota) key
   */
  static const String DEAD_IOTA = "DeadIota";

  /**
   * The Combining Katakana-Hiragana Voiced Sound Mark (Dead Voiced Sound) key
   */
  static const String DEAD_VOICED_SOUND = "DeadVoicedSound";

  /**
   * The Combining Katakana-Hiragana Semi-Voiced Sound Mark (Dead Semivoiced
   * Sound) key
   */
  static const String DEC_SEMIVOICED_SOUND= "DeadSemivoicedSound";

  /**
   * Key value used when an implementation is unable to identify another key
   * value, due to either hardware, platform, or software constraints
   */
  static const String UNIDENTIFIED = "Unidentified";
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * Contains the set of standard values returned by HTMLDocument.getReadyState.
 */
abstract class ReadyState {
  /**
   * Indicates the document is still loading and parsing.
   */
  static const String LOADING = "loading";

  /**
   * Indicates the document is finished parsing but is still loading
   * subresources.
   */
  static const String INTERACTIVE = "interactive";

  /**
   * Indicates the document and all subresources have been loaded.
   */
  static const String COMPLETE = "complete";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// TODO(antonm): support not DOM isolates too.
class _Timer implements Timer {
  final canceller;

  _Timer(this.canceller);

  void cancel() { canceller(); }
}

get _timerFactoryClosure => (int milliSeconds, void callback(Timer timer), bool repeating) {
  var maker;
  var canceller;
  if (repeating) {
    maker = window.setInterval;
    canceller = window.clearInterval;
  } else {
    maker = window.setTimeout;
    canceller = window.clearTimeout;
  }
  Timer timer;
  final int id = maker(() { callback(timer); }, milliSeconds);
  timer = new _Timer(() { canceller(id); });
  return timer;
};
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * The [Collections] class implements static methods useful when
 * writing a class that implements [Collection] and the [iterator]
 * method.
 */
class _Collections {
  static bool contains(Iterable<Object> iterable, Object element) {
    for (final e in iterable) {
      if (e == element) return true;
    }
    return false;
  }

  static void forEach(Iterable<Object> iterable, void f(Object o)) {
    for (final e in iterable) {
      f(e);
    }
  }

  static List map(Iterable<Object> source,
                  List<Object> destination,
                  f(o)) {
    for (final e in source) {
      destination.add(f(e));
    }
    return destination;
  }

  static bool some(Iterable<Object> iterable, bool f(Object o)) {
    for (final e in iterable) {
      if (f(e)) return true;
    }
    return false;
  }

  static bool every(Iterable<Object> iterable, bool f(Object o)) {
    for (final e in iterable) {
      if (!f(e)) return false;
    }
    return true;
  }

  static List filter(Iterable<Object> source,
                     List<Object> destination,
                     bool f(o)) {
    for (final e in source) {
      if (f(e)) destination.add(e);
    }
    return destination;
  }

  static bool isEmpty(Iterable<Object> iterable) {
    return !iterable.iterator().hasNext;
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _HttpRequestUtils {

  // Helper for factory HttpRequest.get
  static HttpRequest get(String url,
                            onSuccess(HttpRequest request),
                            bool withCredentials) {
    final request = new HttpRequest();
    request.open('GET', url, true);

    request.withCredentials = withCredentials;

    // Status 0 is for local XHR request.
    request.on.readyStateChange.add((e) {
      if (request.readyState == HttpRequest.DONE &&
          (request.status == 200 || request.status == 0)) {
        onSuccess(request);
      }
    });

    request.send();

    return request;
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _CustomEventFactoryProvider {
  static CustomEvent createCustomEvent(String type, [bool canBubble = true,
      bool cancelable = true, Object detail = null]) {
    final CustomEvent e = document.$dom_createEvent("CustomEvent");
    e.$dom_initCustomEvent(type, canBubble, cancelable, detail);
    return e;
  }
}

class _EventFactoryProvider {
  static Event createEvent(String type, [bool canBubble = true,
      bool cancelable = true]) {
    final Event e = document.$dom_createEvent("Event");
    e.$dom_initEvent(type, canBubble, cancelable);
    return e;
  }
}

class _MouseEventFactoryProvider {
  static MouseEvent createMouseEvent(String type, Window view, int detail,
      int screenX, int screenY, int clientX, int clientY, int button,
      [bool canBubble = true, bool cancelable = true, bool ctrlKey = false,
      bool altKey = false, bool shiftKey = false, bool metaKey = false,
      EventTarget relatedTarget = null]) {
    final e = document.$dom_createEvent("MouseEvent");
    e.$dom_initMouseEvent(type, canBubble, cancelable, view, detail,
        screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey,
        button, relatedTarget);
    return e;
  }
}

class _CSSStyleDeclarationFactoryProvider {
  static CSSStyleDeclaration createCSSStyleDeclaration_css(String css) {
    final style = new Element.tag('div').style;
    style.cssText = css;
    return style;
  }

  static CSSStyleDeclaration createCSSStyleDeclaration() {
    return new CSSStyleDeclaration.css('');
  }
}

class _DocumentFragmentFactoryProvider {
  /** @domName Document.createDocumentFragment */
  static DocumentFragment createDocumentFragment() =>
      document.createDocumentFragment();

  static DocumentFragment createDocumentFragment_html(String html) {
    final fragment = new DocumentFragment();
    fragment.innerHTML = html;
    return fragment;
  }

  // TODO(nweiz): enable this when XML is ported.
  // factory DocumentFragment.xml(String xml) {
  //   final fragment = new DocumentFragment();
  //   final e = new XMLElement.tag("xml");
  //   e.innerHTML = xml;
  //
  //   // Copy list first since we don't want liveness during iteration.
  //   final List nodes = new List.from(e.nodes);
  //   fragment.nodes.addAll(nodes);
  //   return fragment;
  // }

  static DocumentFragment createDocumentFragment_svg(String svgContent) {
    final fragment = new DocumentFragment();
    final e = new svg.SVGSVGElement();
    e.innerHTML = svgContent;

    // Copy list first since we don't want liveness during iteration.
    final List nodes = new List.from(e.nodes);
    fragment.nodes.addAll(nodes);
    return fragment;
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _AudioContextFactoryProvider {
  static AudioContext createAudioContext() => _createAudioContext();
  static _createAudioContext([int numberOfChannels,
                              int numberOfFrames,
                              int sampleRate])
      native "AudioContext_constructor_Callback";
}

class _IDBKeyRangeFactoryProvider {

  static IDBKeyRange createIDBKeyRange_only(/*IDBKey*/ value) =>
      IDBKeyRange.only_(value);

  static IDBKeyRange createIDBKeyRange_lowerBound(
      /*IDBKey*/ bound, [bool open = false]) =>
      IDBKeyRange.lowerBound_(bound, open);

  static IDBKeyRange createIDBKeyRange_upperBound(
      /*IDBKey*/ bound, [bool open = false]) =>
      IDBKeyRange.upperBound_(bound, open);

  static IDBKeyRange createIDBKeyRange_bound(
      /*IDBKey*/ lower, /*IDBKey*/ upper,
      [bool lowerOpen = false, bool upperOpen = false]) =>
      IDBKeyRange.bound_(lower, upper, lowerOpen, upperOpen);
}

class _TypedArrayFactoryProvider {
  static Float32Array createFloat32Array(int length) => _F32(length);
  static Float32Array createFloat32Array_fromList(List<num> list) =>
      _F32(ensureNative(list));
  static Float32Array createFloat32Array_fromBuffer(ArrayBuffer buffer,
      [int byteOffset = 0, int length]) => _F32(buffer, byteOffset, length);
  static _F32(arg0, [arg1, arg2]) native "Float32Array_constructor_Callback";

  static Float64Array createFloat64Array(int length) => _F64(length);
  static Float64Array createFloat64Array_fromList(List<num> list) =>
      _F64(ensureNative(list));
  static Float64Array createFloat64Array_fromBuffer(ArrayBuffer buffer,
      [int byteOffset = 0, int length]) => _F64(buffer, byteOffset, length);
  static _F64(arg0, [arg1, arg2]) native "Float64Array_constructor_Callback";

  static Int8Array createInt8Array(int length) => _I8(length);
  static Int8Array createInt8Array_fromList(List<num> list) =>
      _I8(ensureNative(list));
  static Int8Array createInt8Array_fromBuffer(ArrayBuffer buffer,
      [int byteOffset = 0, int length]) => _I8(buffer, byteOffset, length);
  static _I8(arg0, [arg1, arg2]) native "Int8Array_constructor_Callback";

  static Int16Array createInt16Array(int length) => _I16(length);
  static Int16Array createInt16Array_fromList(List<num> list) =>
      _I16(ensureNative(list));
  static Int16Array createInt16Array_fromBuffer(ArrayBuffer buffer,
      [int byteOffset = 0, int length]) => _I16(buffer, byteOffset, length);
  static _I16(arg0, [arg1, arg2]) native "Int16Array_constructor_Callback";

  static Int32Array createInt32Array(int length) => _I32(length);
  static Int32Array createInt32Array_fromList(List<num> list) =>
      _I32(ensureNative(list));
  static Int32Array createInt32Array_fromBuffer(ArrayBuffer buffer,
      [int byteOffset = 0, int length]) => _I32(buffer, byteOffset, length);
  static _I32(arg0, [arg1, arg2]) native "Int32Array_constructor_Callback";

  static Uint8Array createUint8Array(int length) => _U8(length);
  static Uint8Array createUint8Array_fromList(List<num> list) =>
      _U8(ensureNative(list));
  static Uint8Array createUint8Array_fromBuffer(ArrayBuffer buffer,
      [int byteOffset = 0, int length]) => _U8(buffer, byteOffset, length);
  static _U8(arg0, [arg1, arg2]) native "Uint8Array_constructor_Callback";

  static Uint16Array createUint16Array(int length) => _U16(length);
  static Uint16Array createUint16Array_fromList(List<num> list) =>
      _U16(ensureNative(list));
  static Uint16Array createUint16Array_fromBuffer(ArrayBuffer buffer,
      [int byteOffset = 0, int length]) => _U16(buffer, byteOffset, length);
  static _U16(arg0, [arg1, arg2]) native "Uint16Array_constructor_Callback";

  static Uint32Array createUint32Array(int length) => _U32(length);
  static Uint32Array createUint32Array_fromList(List<num> list) =>
      _U32(ensureNative(list));
  static Uint32Array createUint32Array_fromBuffer(ArrayBuffer buffer,
      [int byteOffset = 0, int length]) => _U32(buffer, byteOffset, length);
  static _U32(arg0, [arg1, arg2]) native "Uint32Array_constructor_Callback";

  static Uint8ClampedArray createUint8ClampedArray(int length) => _U8C(length);
  static Uint8ClampedArray createUint8ClampedArray_fromList(
      List<num> list) => _U8C(ensureNative(list));
  static Uint8ClampedArray createUint8ClampedArray_fromBuffer(
      ArrayBuffer buffer, [int byteOffset = 0, int length]) =>
      _U8C(buffer, byteOffset, length);
  static _U8C(arg0, [arg1, arg2]) native "Uint8ClampedArray_constructor_Callback";

  static ensureNative(List list) => list;  // TODO: make sure.
}

class _PointFactoryProvider {
  static Point createPoint(num x, num y) => _createWebKitPoint(x, y);
  static _createWebKitPoint(num x, num y) native "WebKitPoint_constructor_Callback";
}

class _WebSocketFactoryProvider {
  static WebSocket createWebSocket(String url) => _createWebSocket(url);
  static _createWebSocket(String url) native "WebSocket_constructor_Callback";
}

class _TextFactoryProvider {
  static Text createText(String data) => document.$dom_createTextNode(data);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * Utils for device detection.
 */
class _Device {
  /**
   * Gets the browser's user agent. Using this function allows tests to inject
   * the user agent.
   * Returns the user agent.
   */
  static String get userAgent => window.navigator.userAgent;

  /**
   * Determines if the current device is running Opera.
   */
  static bool get isOpera => userAgent.contains("Opera", 0);

  /**
   * Determines if the current device is running Internet Explorer.
   */
  static bool get isIE => !isOpera && userAgent.contains("MSIE", 0);

  /**
   * Determines if the current device is running Firefox.
   */
  static bool get isFirefox => userAgent.contains("Firefox", 0);

  /**
   * Determines if the current device is running WebKit.
   */
  static bool get isWebKit => !isOpera && userAgent.contains("WebKit", 0);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


_serialize(var message) {
  return new _JsSerializer().traverse(message);
}

class _JsSerializer extends _Serializer {

  visitSendPortSync(SendPortSync x) {
    if (x is _JsSendPortSync) return visitJsSendPortSync(x);
    if (x is _LocalSendPortSync) return visitLocalSendPortSync(x);
    if (x is _RemoteSendPortSync) return visitRemoteSendPortSync(x);
    throw "Unknown port type $x";
  }

  visitJsSendPortSync(_JsSendPortSync x) {
    return [ 'sendport', 'nativejs', x._id ];
  }

  visitLocalSendPortSync(_LocalSendPortSync x) {
    return [ 'sendport', 'dart',
             ReceivePortSync._isolateId, x._receivePort._portId ];
  }

  visitRemoteSendPortSync(_RemoteSendPortSync x) {
    return [ 'sendport', 'dart',
             x._receivePort._isolateId, x._receivePort._portId ];
  }
}

_deserialize(var message) {
  return new _JsDeserializer().deserialize(message);
}


class _JsDeserializer extends _Deserializer {

  static const _UNSPECIFIED = const Object();

  deserializeSendPort(List x) {
    String tag = x[1];
    switch (tag) {
      case 'nativejs':
        num id = x[2];
        return new _JsSendPortSync(id);
      case 'dart':
        num isolateId = x[2];
        num portId = x[3];
        return ReceivePortSync._lookup(isolateId, portId);
      default:
        throw 'Illegal SendPortSync type: $tag';
    }
  }
}

// The receiver is JS.
class _JsSendPortSync implements SendPortSync {

  num _id;
  _JsSendPortSync(this._id);

  callSync(var message) {
    var serialized = _serialize(message);
    var result = _callPortSync(_id, serialized);
    return _deserialize(result);
  }

}

// TODO(vsm): Differentiate between Dart2Js and Dartium isolates.
// The receiver is a different Dart isolate, compiled to JS.
class _RemoteSendPortSync implements SendPortSync {

  int _isolateId;
  int _portId;
  _RemoteSendPortSync(this._isolateId, this._portId);

  callSync(var message) {
    var serialized = _serialize(message);
    var result = _call(_isolateId, _portId, serialized);
    return _deserialize(result);
  }

  static _call(int isolateId, int portId, var message) {
    var target = 'dart-port-$isolateId-$portId'; 
    // TODO(vsm): Make this re-entrant.
    // TODO(vsm): Set this up set once, on the first call.
    var source = '$target-result';
    var result = null;
    var listener = (Event e) {
      result = JSON.parse(_getPortSyncEventData(e));
    };
    window.on[source].add(listener);
    _dispatchEvent(target, [source, message]);
    window.on[source].remove(listener);
    return result;
  }
}

// The receiver is in the same Dart isolate, compiled to JS.
class _LocalSendPortSync implements SendPortSync {

  ReceivePortSync _receivePort;

  _LocalSendPortSync._internal(this._receivePort);

  callSync(var message) {
    // TODO(vsm): Do a more efficient deep copy.
    var copy = _deserialize(_serialize(message));
    var result = _receivePort._callback(copy);
    return _deserialize(_serialize(result));
  }
}

// TODO(vsm): Move this to dart:isolate.  This will take some
// refactoring as there are dependences here on the DOM.  Users
// interact with this class (or interface if we change it) directly -
// new ReceivePortSync.  I think most of the DOM logic could be
// delayed until the corresponding SendPort is registered on the
// window.

// A Dart ReceivePortSync (tagged 'dart' when serialized) is
// identifiable / resolvable by the combination of its isolateid and
// portid.  When a corresponding SendPort is used within the same
// isolate, the _portMap below can be used to obtain the
// ReceivePortSync directly.  Across isolates (or from JS), an
// EventListener can be used to communicate with the port indirectly.
class ReceivePortSync {

  static Map<int, ReceivePortSync> _portMap;
  static int _portIdCount;
  static int _cachedIsolateId;

  num _portId;
  Function _callback;
  EventListener _listener;

  ReceivePortSync() {
    if (_portIdCount == null) {
      _portIdCount = 0;
      _portMap = new Map<int, ReceivePortSync>();
    }
    _portId = _portIdCount++;
    _portMap[_portId] = this;
  }

  static int get _isolateId {
    // TODO(vsm): Make this coherent with existing isolate code.
    if (_cachedIsolateId == null) {
      _cachedIsolateId = _getNewIsolateId();      
    }
    return _cachedIsolateId;
  }

  static String _getListenerName(isolateId, portId) =>
      'dart-port-$isolateId-$portId'; 
  String get _listenerName => _getListenerName(_isolateId, _portId);

  void receive(callback(var message)) {
    _callback = callback;
    if (_listener == null) {
      _listener = (Event e) {
        var data = JSON.parse(_getPortSyncEventData(e));
        var replyTo = data[0];
        var message = _deserialize(data[1]);
        var result = _callback(message);
        _dispatchEvent(replyTo, _serialize(result));
      };
      window.on[_listenerName].add(_listener);
    }
  }

  void close() {
    _portMap.remove(_portId);
    if (_listener != null) window.on[_listenerName].remove(_listener);
  }

  SendPortSync toSendPort() {
    return new _LocalSendPortSync._internal(this);
  }

  static SendPortSync _lookup(int isolateId, int portId) {
    if (isolateId == _isolateId) {
      return _portMap[portId].toSendPort();
    } else {
      return new _RemoteSendPortSync(isolateId, portId);
    }
  }
}

get _isolateId => ReceivePortSync._isolateId;

void _dispatchEvent(String receiver, var message) {
  var event = new CustomEvent(receiver, false, false, JSON.stringify(message));
  window.$dom_dispatchEvent(event);
}

String _getPortSyncEventData(CustomEvent event) => event.detail;
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


typedef Object ComputeValue();

class _MeasurementRequest<T> {
  final ComputeValue computeValue;
  final Completer<T> completer;
  Object value;
  bool exception = false;
  _MeasurementRequest(this.computeValue, this.completer);
}

typedef void _MeasurementCallback();


/**
 * This class attempts to invoke a callback as soon as the current event stack
 * unwinds, but before the browser repaints.
 */
abstract class _MeasurementScheduler {
  bool _nextMeasurementFrameScheduled = false;
  _MeasurementCallback _callback;

  _MeasurementScheduler(this._callback);

  /**
   * Creates the best possible measurement scheduler for the current platform.
   */
  factory _MeasurementScheduler.best(_MeasurementCallback callback) {
    if (_isMutationObserverSupported()) {
      return new _MutationObserverScheduler(callback);
    }
    return new _PostMessageScheduler(callback);
  }

  /**
   * Schedules a measurement callback if one has not been scheduled already.
   */
  void maybeSchedule() {
    if (this._nextMeasurementFrameScheduled) {
      return;
    }
    this._nextMeasurementFrameScheduled = true;
    this._schedule();
  }

  /**
   * Does the actual scheduling of the callback.
   */
  void _schedule();

  /**
   * Handles the measurement callback and forwards it if necessary.
   */
  void _onCallback() {
    // Ignore spurious messages.
    if (!_nextMeasurementFrameScheduled) {
      return;
    }
    _nextMeasurementFrameScheduled = false;
    this._callback();
  }
}

/**
 * Scheduler which uses window.postMessage to schedule events.
 */
class _PostMessageScheduler extends _MeasurementScheduler {
  const _MEASUREMENT_MESSAGE = "DART-MEASURE";

  _PostMessageScheduler(_MeasurementCallback callback): super(callback) {
      // Messages from other windows do not cause a security risk as
      // all we care about is that _handleMessage is called
      // after the current event loop is unwound and calling the function is
      // a noop when zero requests are pending.
      window.on.message.add(this._handleMessage);
  }

  void _schedule() {
    window.postMessage(_MEASUREMENT_MESSAGE, "*");
  }

  _handleMessage(e) {
    this._onCallback();
  }
}

/**
 * Scheduler which uses a MutationObserver to schedule events.
 */
class _MutationObserverScheduler extends _MeasurementScheduler {
  MutationObserver _observer;
  Element _dummy;

  _MutationObserverScheduler(_MeasurementCallback callback): super(callback) {
    // Mutation events get fired as soon as the current event stack is unwound
    // so we just make a dummy event and listen for that.
    _observer = new MutationObserver(this._handleMutation);
    _dummy = new DivElement();
    _observer.observe(_dummy, attributes: true);
  }

  void _schedule() {
    // Toggle it to trigger the mutation event.
    _dummy.hidden = !_dummy.hidden;
  }

  _handleMutation(List<MutationRecord> mutations, MutationObserver observer) {
    this._onCallback();
  }
}


List<_MeasurementRequest> _pendingRequests;
List<TimeoutHandler> _pendingMeasurementFrameCallbacks;
_MeasurementScheduler _measurementScheduler = null;

void _maybeScheduleMeasurementFrame() {
  if (_measurementScheduler == null) {
    _measurementScheduler =
      new _MeasurementScheduler.best(_completeMeasurementFutures);
  }
  _measurementScheduler.maybeSchedule();
}

/**
 * Registers a [callback] which is called after the next batch of measurements
 * completes. Even if no measurements completed, the callback is triggered
 * when they would have completed to avoid confusing bugs if it happened that
 * no measurements were actually requested.
 */
void _addMeasurementFrameCallback(TimeoutHandler callback) {
  if (_pendingMeasurementFrameCallbacks == null) {
    _pendingMeasurementFrameCallbacks = <TimeoutHandler>[];
    _maybeScheduleMeasurementFrame();
  }
  _pendingMeasurementFrameCallbacks.add(callback);
}

/**
 * Returns a [Future] whose value will be the result of evaluating
 * [computeValue] during the next safe measurement interval.
 * The next safe measurement interval is after the current event loop has
 * unwound but before the browser has rendered the page.
 * It is important that the [computeValue] function only queries the html
 * layout and html in any way.
 */
Future _createMeasurementFuture(ComputeValue computeValue,
                                Completer completer) {
  if (_pendingRequests == null) {
    _pendingRequests = <_MeasurementRequest>[];
    _maybeScheduleMeasurementFrame();
  }
  _pendingRequests.add(new _MeasurementRequest(computeValue, completer));
  return completer.future;
}

/**
 * Complete all pending measurement futures evaluating them in a single batch
 * so that the the browser is guaranteed to avoid multiple layouts.
 */
void _completeMeasurementFutures() {
  // We must compute all new values before fulfilling the futures as
  // the onComplete callbacks for the futures could modify the DOM making
  // subsequent measurement calculations expensive to compute.
  if (_pendingRequests != null) {
    for (_MeasurementRequest request in _pendingRequests) {
      try {
        request.value = request.computeValue();
      } catch (e) {
        request.value = e;
        request.exception = true;
      }
    }
  }

  final completedRequests = _pendingRequests;
  final readyMeasurementFrameCallbacks = _pendingMeasurementFrameCallbacks;
  _pendingRequests = null;
  _pendingMeasurementFrameCallbacks = null;
  if (completedRequests != null) {
    for (_MeasurementRequest request in completedRequests) {
      if (request.exception) {
        request.completer.completeException(request.value);
      } else {
        request.completer.complete(request.value);
      }
    }
  }

  if (readyMeasurementFrameCallbacks != null) {
    for (TimeoutHandler handler in readyMeasurementFrameCallbacks) {
      // TODO(jacobr): wrap each call to a handler in a try-catch block.
      handler();
    }
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for the dart:isolate library.


/********************************************************
  Inserted from lib/isolate/serialization.dart
 ********************************************************/

class _MessageTraverserVisitedMap {

  operator[](var object) => null;
  void operator[]=(var object, var info) { }

  void reset() { }
  void cleanup() { }

}

/** Abstract visitor for dart objects that can be sent as isolate messages. */
class _MessageTraverser {

  _MessageTraverserVisitedMap _visited;
  _MessageTraverser() : _visited = new _MessageTraverserVisitedMap();

  /** Visitor's entry point. */
  traverse(var x) {
    if (isPrimitive(x)) return visitPrimitive(x);
    _visited.reset();
    var result;
    try {
      result = _dispatch(x);
    } finally {
      _visited.cleanup();
    }
    return result;
  }

  _dispatch(var x) {
    if (isPrimitive(x)) return visitPrimitive(x);
    if (x is List) return visitList(x);
    if (x is Map) return visitMap(x);
    if (x is SendPort) return visitSendPort(x);
    if (x is SendPortSync) return visitSendPortSync(x);

    // Overridable fallback.
    return visitObject(x);
  }

  visitPrimitive(x);
  visitList(List x);
  visitMap(Map x);
  visitSendPort(SendPort x);
  visitSendPortSync(SendPortSync x);

  visitObject(Object x) {
    // TODO(floitsch): make this a real exception. (which one)?
    throw "Message serialization: Illegal value $x passed";
  }

  static bool isPrimitive(x) {
    return (x == null) || (x is String) || (x is num) || (x is bool);
  }
}


/** A visitor that recursively copies a message. */
class _Copier extends _MessageTraverser {

  visitPrimitive(x) => x;

  List visitList(List list) {
    List copy = _visited[list];
    if (copy != null) return copy;

    int len = list.length;

    // TODO(floitsch): we loose the generic type of the List.
    copy = new List(len);
    _visited[list] = copy;
    for (int i = 0; i < len; i++) {
      copy[i] = _dispatch(list[i]);
    }
    return copy;
  }

  Map visitMap(Map map) {
    Map copy = _visited[map];
    if (copy != null) return copy;

    // TODO(floitsch): we loose the generic type of the map.
    copy = new Map();
    _visited[map] = copy;
    map.forEach((key, val) {
      copy[_dispatch(key)] = _dispatch(val);
    });
    return copy;
  }

}

/** Visitor that serializes a message as a JSON array. */
class _Serializer extends _MessageTraverser {
  int _nextFreeRefId = 0;

  visitPrimitive(x) => x;

  visitList(List list) {
    int copyId = _visited[list];
    if (copyId != null) return ['ref', copyId];

    int id = _nextFreeRefId++;
    _visited[list] = id;
    var jsArray = _serializeList(list);
    // TODO(floitsch): we are losing the generic type.
    return ['list', id, jsArray];
  }

  visitMap(Map map) {
    int copyId = _visited[map];
    if (copyId != null) return ['ref', copyId];

    int id = _nextFreeRefId++;
    _visited[map] = id;
    var keys = _serializeList(map.keys);
    var values = _serializeList(map.values);
    // TODO(floitsch): we are losing the generic type.
    return ['map', id, keys, values];
  }

  _serializeList(List list) {
    int len = list.length;
    var result = new List(len);
    for (int i = 0; i < len; i++) {
      result[i] = _dispatch(list[i]);
    }
    return result;
  }
}

/** Deserializes arrays created with [_Serializer]. */
class _Deserializer {
  Map<int, dynamic> _deserialized;

  _Deserializer();

  static bool isPrimitive(x) {
    return (x == null) || (x is String) || (x is num) || (x is bool);
  }

  deserialize(x) {
    if (isPrimitive(x)) return x;
    // TODO(floitsch): this should be new HashMap<int, dynamic>()
    _deserialized = new HashMap();
    return _deserializeHelper(x);
  }

  _deserializeHelper(x) {
    if (isPrimitive(x)) return x;
    assert(x is List);
    switch (x[0]) {
      case 'ref': return _deserializeRef(x);
      case 'list': return _deserializeList(x);
      case 'map': return _deserializeMap(x);
      case 'sendport': return deserializeSendPort(x);
      default: return deserializeObject(x);
    }
  }

  _deserializeRef(List x) {
    int id = x[1];
    var result = _deserialized[id];
    assert(result != null);
    return result;
  }

  List _deserializeList(List x) {
    int id = x[1];
    // We rely on the fact that Dart-lists are directly mapped to Js-arrays.
    List dartList = x[2];
    _deserialized[id] = dartList;
    int len = dartList.length;
    for (int i = 0; i < len; i++) {
      dartList[i] = _deserializeHelper(dartList[i]);
    }
    return dartList;
  }

  Map _deserializeMap(List x) {
    Map result = new Map();
    int id = x[1];
    _deserialized[id] = result;
    List keys = x[2];
    List values = x[3];
    int len = keys.length;
    assert(len == values.length);
    for (int i = 0; i < len; i++) {
      var key = _deserializeHelper(keys[i]);
      var value = _deserializeHelper(values[i]);
      result[key] = value;
    }
    return result;
  }

  deserializeSendPort(List x);

  deserializeObject(List x) {
    // TODO(floitsch): Use real exception (which one?).
    throw "Unexpected serialized object";
  }
}

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * Checks to see if the mutation observer API is supported on the current
 * platform.
 */
bool _isMutationObserverSupported() {
  return true;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// TODO(rnystrom): add a way to supress public classes from DartDoc output.
// TODO(jacobr): we can remove this class now that we are using the $dom_
// convention for deprecated methods rather than truly private methods.
/**
 * This class is intended for testing purposes only.
 */
class Testing {
  static void addEventListener(EventTarget target, String type, EventListener listener, bool useCapture) {
    target.$dom_addEventListener(type, listener, useCapture);
  }
  static void removeEventListener(EventTarget target, String type, EventListener listener, bool useCapture) {
    target.$dom_removeEventListener(type, listener, useCapture);
  }

}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Iterator for arrays with fixed size.
class FixedSizeListIterator<T> extends _VariableSizeListIterator<T> {
  FixedSizeListIterator(List<T> array)
      : super(array),
        _length = array.length;

  bool get hasNext => _length > _pos;

  final int _length;  // Cache array length for faster access.
}

// Iterator for arrays with variable size.
class _VariableSizeListIterator<T> implements Iterator<T> {
  _VariableSizeListIterator(List<T> array)
      : _array = array,
        _pos = 0;

  bool get hasNext => _array.length > _pos;

  T next() {
    if (!hasNext) {
      throw new StateError("No more elements");
    }
    return _array[_pos++];
  }

  final List<T> _array;
  int _pos;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _Lists {

  /**
   * Returns the index in the array [a] of the given [element], starting
   * the search at index [startIndex] to [endIndex] (exclusive).
   * Returns -1 if [element] is not found.
   */
  static int indexOf(List a,
                     Object element,
                     int startIndex,
                     int endIndex) {
    if (startIndex >= a.length) {
      return -1;
    }
    if (startIndex < 0) {
      startIndex = 0;
    }
    for (int i = startIndex; i < endIndex; i++) {
      if (a[i] == element) {
        return i;
      }
    }
    return -1;
  }

  /**
   * Returns the last index in the array [a] of the given [element], starting
   * the search at index [startIndex] to 0.
   * Returns -1 if [element] is not found.
   */
  static int lastIndexOf(List a, Object element, int startIndex) {
    if (startIndex < 0) {
      return -1;
    }
    if (startIndex >= a.length) {
      startIndex = a.length - 1;
    }
    for (int i = startIndex; i >= 0; i--) {
      if (a[i] == element) {
        return i;
      }
    }
    return -1;
  }

  /**
   * Returns a sub list copy of this list, from [start] to
   * [:start + length:].
   * Returns an empty list if [length] is 0.
   * Throws an [ArgumentError] if [length] is negative.
   * Throws a [RangeError] if [start] or [:start + length:] are out of range.
   */
  static List getRange(List a, int start, int length, List accumulator) {
    if (length < 0) throw new ArgumentError('length');
    if (start < 0) throw new RangeError.value(start);
    int end = start + length;
    if (end > a.length) throw new RangeError.value(end);
    for (int i = start; i < end; i++) {
      accumulator.add(a[i]);
    }
    return accumulator;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// This API is exploratory.
spawnDomFunction(Function topLevelFunction) => _Utils.spawnDomFunctionImpl(topLevelFunction);

// testRunner implementation.
// FIXME: provide a separate lib for testRunner.

var _testRunner;

TestRunner get testRunner {
  if (_testRunner == null)
    _testRunner = new TestRunner._(_NPObject.retrieve("testRunner"));
  return _testRunner;
}

class TestRunner {
  final _NPObject _npObject;

  TestRunner._(this._npObject);

  display() => _npObject.invoke('display');
  dumpAsText() => _npObject.invoke('dumpAsText');
  notifyDone() => _npObject.invoke('notifyDone');
  setCanOpenWindows() => _npObject.invoke('setCanOpenWindows');
  waitUntilDone() => _npObject.invoke('waitUntilDone');
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _Utils {
  static List convertToList(List list) {
    // FIXME: [possible optimization]: do not copy the array if Dart_IsArray is fine w/ it.
    final length = list.length;
    List result = new List(length);
    result.setRange(0, length, list);
    return result;
  }

  static List convertMapToList(Map map) {
    List result = [];
    map.forEach((k, v) => result.addAll([k, v]));
    return result;
  }

  static void populateMap(Map result, List list) {
    for (int i = 0; i < list.length; i += 2) {
      result[list[i]] = list[i + 1];
    }
  }

  static bool isMap(obj) => obj is Map;

  static Map createMap() => {};

  static makeUnimplementedError(String fileName, int lineNo) {
    return new UnsupportedError('[info: $fileName:$lineNo]');
  }

  static window() native "Utils_window";
  static print(String message) native "Utils_print";
  static SendPort spawnDomFunctionImpl(Function topLevelFunction) native "Utils_spawnDomFunction";
  static int _getNewIsolateId() native "Utils_getNewIsolateId";
  static bool shadowRootSupported(Document document) native "Utils_shadowRootSupported";
}

class _NPObject extends NativeFieldWrapperClass1 {
  _NPObject.internal();
  static _NPObject retrieve(String key) native "NPObject_retrieve";
  property(String propertyName) native "NPObject_property";
  invoke(String methodName, [List args = null]) native "NPObject_invoke";
}

class _DOMWindowCrossFrame extends NativeFieldWrapperClass1 implements Window {
  _DOMWindowCrossFrame.internal();

  // Fields.
  History get history() native "DOMWindow_history_cross_frame_Getter";
  Location get location() native "DOMWindow_location_cross_frame_Getter";
  bool get closed() native "DOMWindow_closed_Getter";
  int get length() native "DOMWindow_length_Getter";
  Window get opener() native "DOMWindow_opener_Getter";
  Window get parent() native "DOMWindow_parent_Getter";
  Window get top() native "DOMWindow_top_Getter";

  // Methods.
  void close() native "DOMWindow_close_Callback";
  void postMessage(/*SerializedScriptValue*/ message, String targetOrigin, [List messagePorts]) native "DOMWindow_postMessage_Callback";

  // Implementation support.
  String get typeName => "DOMWindow";
}

class _HistoryCrossFrame extends NativeFieldWrapperClass1 implements History {
  _HistoryCrossFrame.internal();

  // Methods.
  void back() native "History_back_Callback";
  void forward() native "History_forward_Callback";
  void go(int distance) native "History_go_Callback";

  // Implementation support.
  String get typeName => "History";
}

class _LocationCrossFrame extends NativeFieldWrapperClass1 implements Location {
  _LocationCrossFrame.internal();

  // Fields.
  void set href(String) native "Location_href_Setter";

  // Implementation support.
  String get typeName => "Location";
}

class _DOMStringMap extends NativeFieldWrapperClass1 implements Map<String, String> {
  _DOMStringMap.internal();

  bool containsValue(String value) => Maps.containsValue(this, value);
  bool containsKey(String key) native "DOMStringMap_containsKey_Callback";
  String operator [](String key) native "DOMStringMap_item_Callback";
  void operator []=(String key, String value) native "DOMStringMap_setItem_Callback";
  String putIfAbsent(String key, String ifAbsent()) => Maps.putIfAbsent(this, key, ifAbsent);
  String remove(String key) native "DOMStringMap_remove_Callback";
  void clear() => Maps.clear(this);
  void forEach(void f(String key, String value)) => Maps.forEach(this, f);
  Collection<String> get keys native "DOMStringMap_getKeys_Callback";
  Collection<String> get values => Maps.getValues(this);
  int get length => Maps.length(this);
  bool get isEmpty => Maps.isEmpty(this);
}

get _printClosure => (s) {
  try {
    window.console.log(s);
  } catch (_) {
    _Utils.print(s);
  }
};
