/**
 * This library provides entry points to the native Blink code which backs
 * up the dart:html library.
 */
library dart.dom._blink;

import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:_internal' hide Symbol, deprecated;
import 'dart:html_common';
import 'dart:indexed_db';
import 'dart:isolate';
import "dart:convert";
import 'dart:math';
import 'dart:mirrors';
import 'dart:nativewrappers';
import 'dart:typed_data';
import 'dart:web_gl' as gl;
import 'dart:web_gl' show web_glBlinkMap;
import 'dart:web_sql';
import 'dart:svg' as svg;
import 'dart:svg' show Matrix;
import 'dart:svg' show SvgSvgElement;
import 'dart:svg' show svgBlinkMap;
import 'dart:web_audio' show AudioNode, AudioParam, web_audioBlinkMap;
// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// DO NOT EDIT
// Auto-generated dart:_blink library.

// TODO(leafp) These are mostly copied over from dart:html.  When
// we shift dart:blink generation over to dartium, this dependency 
// should go away, or at least be reconsidered.
// TODO(vsm): Remove this when we can do the proper checking in
// native code for custom elements.
// Not actually used, but imported since dart:html can generate these objects.



class BlinkANGLEInstancedArrays {
  static $drawArraysInstancedANGLE_Callback(mthis, mode, first, count, primcount) native "ANGLEInstancedArrays_drawArraysInstancedANGLE_Callback_RESOLVER_STRING_4_unsigned long_long_long_long";

  static $drawElementsInstancedANGLE_Callback(mthis, mode, count, type, offset, primcount) native "ANGLEInstancedArrays_drawElementsInstancedANGLE_Callback_RESOLVER_STRING_5_unsigned long_long_unsigned long_long long_long";

  static $vertexAttribDivisorANGLE_Callback(mthis, index, divisor) native "ANGLEInstancedArrays_vertexAttribDivisorANGLE_Callback_RESOLVER_STRING_2_unsigned long_long";
}

class BlinkAbstractWorker {}

class BlinkAlgorithm {
  static $name_Getter(mthis) native "KeyAlgorithm_name_Getter";
}

class BlinkEventTarget {
  static $addEventListener_Callback(mthis, type, listener, useCapture) native "EventTarget_addEventListener_Callback_RESOLVER_STRING_3_DOMString_EventListener_boolean";

  static $dispatchEvent_Callback(mthis, event) native "EventTarget_dispatchEvent_Callback_RESOLVER_STRING_1_Event";

  static $removeEventListener_Callback(mthis, type, listener, useCapture) native "EventTarget_removeEventListener_Callback_RESOLVER_STRING_3_DOMString_EventListener_boolean";
}

class BlinkAudioNode {
  static $channelCount_Getter(mthis) native "AudioNode_channelCount_Getter";

  static $channelCount_Setter(mthis, value) native "AudioNode_channelCount_Setter";

  static $channelCountMode_Getter(mthis) native "AudioNode_channelCountMode_Getter";

  static $channelCountMode_Setter(mthis, value) native "AudioNode_channelCountMode_Setter";

  static $channelInterpretation_Getter(mthis) native "AudioNode_channelInterpretation_Getter";

  static $channelInterpretation_Setter(mthis, value) native "AudioNode_channelInterpretation_Setter";

  static $context_Getter(mthis) native "AudioNode_context_Getter";

  static $numberOfInputs_Getter(mthis) native "AudioNode_numberOfInputs_Getter";

  static $numberOfOutputs_Getter(mthis) native "AudioNode_numberOfOutputs_Getter";

  // Generated overload resolver
  static $_connect(mthis, destination, output, input) {
    if ((input is int || input == null) && (output is int || output == null) && (destination is AudioNode || destination == null)) {
      $_connect_1_Callback(mthis, destination, output, input);
      return;
    }
    if ((output is int || output == null) && (destination is AudioParam || destination == null) && input == null) {
      $_connect_2_Callback(mthis, destination, output);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  static $_connect_1_Callback(mthis, destination, output, input) native "AudioNode_connect_Callback_RESOLVER_STRING_3_AudioNode_unsigned long_unsigned long";

  static $_connect_2_Callback(mthis, destination, output) native "AudioNode_connect_Callback_RESOLVER_STRING_2_AudioParam_unsigned long";

  static $disconnect_Callback(mthis, output) native "AudioNode_disconnect_Callback_RESOLVER_STRING_1_unsigned long";
}

class BlinkAnalyserNode {
  static $fftSize_Getter(mthis) native "AnalyserNode_fftSize_Getter";

  static $fftSize_Setter(mthis, value) native "AnalyserNode_fftSize_Setter";

  static $frequencyBinCount_Getter(mthis) native "AnalyserNode_frequencyBinCount_Getter";

  static $maxDecibels_Getter(mthis) native "AnalyserNode_maxDecibels_Getter";

  static $maxDecibels_Setter(mthis, value) native "AnalyserNode_maxDecibels_Setter";

  static $minDecibels_Getter(mthis) native "AnalyserNode_minDecibels_Getter";

  static $minDecibels_Setter(mthis, value) native "AnalyserNode_minDecibels_Setter";

  static $smoothingTimeConstant_Getter(mthis) native "AnalyserNode_smoothingTimeConstant_Getter";

  static $smoothingTimeConstant_Setter(mthis, value) native "AnalyserNode_smoothingTimeConstant_Setter";

  static $getByteFrequencyData_Callback(mthis, array) native "AnalyserNode_getByteFrequencyData_Callback_RESOLVER_STRING_1_Uint8Array";

  static $getByteTimeDomainData_Callback(mthis, array) native "AnalyserNode_getByteTimeDomainData_Callback_RESOLVER_STRING_1_Uint8Array";

  static $getFloatFrequencyData_Callback(mthis, array) native "AnalyserNode_getFloatFrequencyData_Callback_RESOLVER_STRING_1_Float32Array";
}

class BlinkTimedItem {
  static $activeDuration_Getter(mthis) native "TimedItem_activeDuration_Getter";

  static $currentIteration_Getter(mthis) native "TimedItem_currentIteration_Getter";

  static $duration_Getter(mthis) native "TimedItem_duration_Getter";

  static $endTime_Getter(mthis) native "TimedItem_endTime_Getter";

  static $localTime_Getter(mthis) native "TimedItem_localTime_Getter";

  static $player_Getter(mthis) native "TimedItem_player_Getter";

  static $startTime_Getter(mthis) native "TimedItem_startTime_Getter";
}

class BlinkAnimation {
  // Generated overload resolver
  static $mkAnimation(target, keyframes, timingInput) {
    if ((timingInput is Map || timingInput == null) && (keyframes is List<Map> || keyframes == null) && (target is Element || target == null)) {
      return $_create_1constructorCallback(target, keyframes, timingInput);
    }
    if ((timingInput is num || timingInput == null) && (keyframes is List<Map> || keyframes == null) && (target is Element || target == null)) {
      return $_create_2constructorCallback(target, keyframes, timingInput);
    }
    if ((keyframes is List<Map> || keyframes == null) && (target is Element || target == null) && timingInput == null) {
      return $_create_3constructorCallback(target, keyframes);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  static $_create_1constructorCallback(target, keyframes, timingInput) native "Animation_constructorCallback_RESOLVER_STRING_3_Element_sequence<Dictionary>_Dictionary";

  static $_create_2constructorCallback(target, keyframes, timingInput) native "Animation_constructorCallback_RESOLVER_STRING_3_Element_sequence<Dictionary>_double";

  static $_create_3constructorCallback(target, keyframes) native "Animation_constructorCallback_RESOLVER_STRING_2_Element_sequence<Dictionary>";
}

class BlinkApplicationCache {
  static $status_Getter(mthis) native "ApplicationCache_status_Getter";

  static $abort_Callback(mthis) native "ApplicationCache_abort_Callback_RESOLVER_STRING_0_";

  static $swapCache_Callback(mthis) native "ApplicationCache_swapCache_Callback_RESOLVER_STRING_0_";

  static $update_Callback(mthis) native "ApplicationCache_update_Callback_RESOLVER_STRING_0_";
}

class BlinkNode {
  static $baseURI_Getter(mthis) native "Node_baseURI_Getter";

  static $childNodes_Getter(mthis) native "Node_childNodes_Getter";

  static $firstChild_Getter(mthis) native "Node_firstChild_Getter";

  static $lastChild_Getter(mthis) native "Node_lastChild_Getter";

  static $localName_Getter(mthis) native "Node_localName_Getter";

  static $namespaceURI_Getter(mthis) native "Node_namespaceURI_Getter";

  static $nextSibling_Getter(mthis) native "Node_nextSibling_Getter";

  static $nodeName_Getter(mthis) native "Node_nodeName_Getter";

  static $nodeType_Getter(mthis) native "Node_nodeType_Getter";

  static $nodeValue_Getter(mthis) native "Node_nodeValue_Getter";

  static $ownerDocument_Getter(mthis) native "Node_ownerDocument_Getter";

  static $parentElement_Getter(mthis) native "Node_parentElement_Getter";

  static $parentNode_Getter(mthis) native "Node_parentNode_Getter";

  static $previousSibling_Getter(mthis) native "Node_previousSibling_Getter";

  static $textContent_Getter(mthis) native "Node_textContent_Getter";

  static $textContent_Setter(mthis, value) native "Node_textContent_Setter";

  static $appendChild_Callback(mthis, newChild) native "Node_appendChild_Callback";

  static $cloneNode_Callback(mthis, deep) native "Node_cloneNode_Callback";

  static $contains_Callback(mthis, other) native "Node_contains_Callback_RESOLVER_STRING_1_Node";

  static $hasChildNodes_Callback(mthis) native "Node_hasChildNodes_Callback_RESOLVER_STRING_0_";

  static $insertBefore_Callback(mthis, newChild, refChild) native "Node_insertBefore_Callback";

  static $removeChild_Callback(mthis, oldChild) native "Node_removeChild_Callback";

  static $replaceChild_Callback(mthis, newChild, oldChild) native "Node_replaceChild_Callback";
}

class BlinkAttr {
  static $localName_Getter(mthis) native "Attr_localName_Getter";

  static $name_Getter(mthis) native "Attr_name_Getter";

  static $namespaceURI_Getter(mthis) native "Attr_namespaceURI_Getter";

  static $value_Getter(mthis) native "Attr_value_Getter";

  static $value_Setter(mthis, value) native "Attr_value_Setter";
}

class BlinkAudioBuffer {
  static $duration_Getter(mthis) native "AudioBuffer_duration_Getter";

  static $length_Getter(mthis) native "AudioBuffer_length_Getter";

  static $numberOfChannels_Getter(mthis) native "AudioBuffer_numberOfChannels_Getter";

  static $sampleRate_Getter(mthis) native "AudioBuffer_sampleRate_Getter";

  static $getChannelData_Callback(mthis, channelIndex) native "AudioBuffer_getChannelData_Callback_RESOLVER_STRING_1_unsigned long";
}

class BlinkAudioSourceNode {}

class BlinkAudioBufferSourceNode {
  static $buffer_Getter(mthis) native "AudioBufferSourceNode_buffer_Getter";

  static $buffer_Setter(mthis, value) native "AudioBufferSourceNode_buffer_Setter";

  static $loop_Getter(mthis) native "AudioBufferSourceNode_loop_Getter";

  static $loop_Setter(mthis, value) native "AudioBufferSourceNode_loop_Setter";

  static $loopEnd_Getter(mthis) native "AudioBufferSourceNode_loopEnd_Getter";

  static $loopEnd_Setter(mthis, value) native "AudioBufferSourceNode_loopEnd_Setter";

  static $loopStart_Getter(mthis) native "AudioBufferSourceNode_loopStart_Getter";

  static $loopStart_Setter(mthis, value) native "AudioBufferSourceNode_loopStart_Setter";

  static $playbackRate_Getter(mthis) native "AudioBufferSourceNode_playbackRate_Getter";

  static $noteGrainOn_Callback(mthis, when, grainOffset, grainDuration) native "AudioBufferSourceNode_noteGrainOn_Callback_RESOLVER_STRING_3_double_double_double";

  static $noteOff_Callback(mthis, when) native "AudioBufferSourceNode_noteOff_Callback_RESOLVER_STRING_1_double";

  static $noteOn_Callback(mthis, when) native "AudioBufferSourceNode_noteOn_Callback_RESOLVER_STRING_1_double";

  // Generated overload resolver
  static $start(mthis, when, grainOffset, grainDuration) {
    if (grainDuration != null) {
      $_start_1_Callback(mthis, when, grainOffset, grainDuration);
      return;
    }
    if (grainOffset != null) {
      $_start_2_Callback(mthis, when, grainOffset);
      return;
    }
    if (when != null) {
      $_start_3_Callback(mthis, when);
      return;
    }
    $_start_4_Callback(mthis);
    return;
  }

  static $_start_1_Callback(mthis, when, grainOffset, grainDuration) native "AudioBufferSourceNode_start_Callback_RESOLVER_STRING_3_double_double_double";

  static $_start_2_Callback(mthis, when, grainOffset) native "AudioBufferSourceNode_start_Callback_RESOLVER_STRING_2_double_double";

  static $_start_3_Callback(mthis, when) native "AudioBufferSourceNode_start_Callback_RESOLVER_STRING_1_double";

  static $_start_4_Callback(mthis) native "AudioBufferSourceNode_start_Callback_RESOLVER_STRING_0_";

  // Generated overload resolver
  static $stop(mthis, when) {
    if (when != null) {
      $_stop_1_Callback(mthis, when);
      return;
    }
    $_stop_2_Callback(mthis);
    return;
  }

  static $_stop_1_Callback(mthis, when) native "AudioBufferSourceNode_stop_Callback_RESOLVER_STRING_1_double";

  static $_stop_2_Callback(mthis) native "AudioBufferSourceNode_stop_Callback_RESOLVER_STRING_0_";
}

class BlinkAudioContext {
  // Generated overload resolver
  static $mkAudioContext() {
    return $_create_1constructorCallback();
  }

  static $_create_1constructorCallback() native "AudioContext_constructorCallback_RESOLVER_STRING_0_";

  static $currentTime_Getter(mthis) native "AudioContext_currentTime_Getter";

  static $destination_Getter(mthis) native "AudioContext_destination_Getter";

  static $listener_Getter(mthis) native "AudioContext_listener_Getter";

  static $sampleRate_Getter(mthis) native "AudioContext_sampleRate_Getter";

  static $createAnalyser_Callback(mthis) native "AudioContext_createAnalyser_Callback_RESOLVER_STRING_0_";

  static $createBiquadFilter_Callback(mthis) native "AudioContext_createBiquadFilter_Callback_RESOLVER_STRING_0_";

  static $createBuffer_Callback(mthis, numberOfChannels, numberOfFrames, sampleRate) native "AudioContext_createBuffer_Callback_RESOLVER_STRING_3_unsigned long_unsigned long_float";

  static $createBufferSource_Callback(mthis) native "AudioContext_createBufferSource_Callback_RESOLVER_STRING_0_";

  // Generated overload resolver
  static $createChannelMerger(mthis, numberOfInputs) {
    if (numberOfInputs != null) {
      return $_createChannelMerger_1_Callback(mthis, numberOfInputs);
    }
    return $_createChannelMerger_2_Callback(mthis);
  }

  static $_createChannelMerger_1_Callback(mthis, numberOfInputs) native "AudioContext_createChannelMerger_Callback_RESOLVER_STRING_1_unsigned long";

  static $_createChannelMerger_2_Callback(mthis) native "AudioContext_createChannelMerger_Callback_RESOLVER_STRING_0_";

  // Generated overload resolver
  static $createChannelSplitter(mthis, numberOfOutputs) {
    if (numberOfOutputs != null) {
      return $_createChannelSplitter_1_Callback(mthis, numberOfOutputs);
    }
    return $_createChannelSplitter_2_Callback(mthis);
  }

  static $_createChannelSplitter_1_Callback(mthis, numberOfOutputs) native "AudioContext_createChannelSplitter_Callback_RESOLVER_STRING_1_unsigned long";

  static $_createChannelSplitter_2_Callback(mthis) native "AudioContext_createChannelSplitter_Callback_RESOLVER_STRING_0_";

  static $createConvolver_Callback(mthis) native "AudioContext_createConvolver_Callback_RESOLVER_STRING_0_";

  // Generated overload resolver
  static $createDelay(mthis, maxDelayTime) {
    if (maxDelayTime != null) {
      return $_createDelay_1_Callback(mthis, maxDelayTime);
    }
    return $_createDelay_2_Callback(mthis);
  }

  static $_createDelay_1_Callback(mthis, maxDelayTime) native "AudioContext_createDelay_Callback_RESOLVER_STRING_1_double";

  static $_createDelay_2_Callback(mthis) native "AudioContext_createDelay_Callback_RESOLVER_STRING_0_";

  static $createDynamicsCompressor_Callback(mthis) native "AudioContext_createDynamicsCompressor_Callback_RESOLVER_STRING_0_";

  static $createGain_Callback(mthis) native "AudioContext_createGain_Callback_RESOLVER_STRING_0_";

  static $createMediaElementSource_Callback(mthis, mediaElement) native "AudioContext_createMediaElementSource_Callback_RESOLVER_STRING_1_HTMLMediaElement";

  static $createMediaStreamDestination_Callback(mthis) native "AudioContext_createMediaStreamDestination_Callback_RESOLVER_STRING_0_";

  static $createMediaStreamSource_Callback(mthis, mediaStream) native "AudioContext_createMediaStreamSource_Callback_RESOLVER_STRING_1_MediaStream";

  static $createOscillator_Callback(mthis) native "AudioContext_createOscillator_Callback_RESOLVER_STRING_0_";

  static $createPanner_Callback(mthis) native "AudioContext_createPanner_Callback_RESOLVER_STRING_0_";

  static $createPeriodicWave_Callback(mthis, real, imag) native "AudioContext_createPeriodicWave_Callback_RESOLVER_STRING_2_Float32Array_Float32Array";

  // Generated overload resolver
  static $createScriptProcessor(mthis, bufferSize, numberOfInputChannels, numberOfOutputChannels) {
    if (numberOfOutputChannels != null) {
      return $_createScriptProcessor_1_Callback(mthis, bufferSize, numberOfInputChannels, numberOfOutputChannels);
    }
    if (numberOfInputChannels != null) {
      return $_createScriptProcessor_2_Callback(mthis, bufferSize, numberOfInputChannels);
    }
    if (bufferSize != null) {
      return $_createScriptProcessor_3_Callback(mthis, bufferSize);
    }
    return $_createScriptProcessor_4_Callback(mthis);
  }

  static $_createScriptProcessor_1_Callback(mthis, bufferSize, numberOfInputChannels, numberOfOutputChannels) native "AudioContext_createScriptProcessor_Callback_RESOLVER_STRING_3_unsigned long_unsigned long_unsigned long";

  static $_createScriptProcessor_2_Callback(mthis, bufferSize, numberOfInputChannels) native "AudioContext_createScriptProcessor_Callback_RESOLVER_STRING_2_unsigned long_unsigned long";

  static $_createScriptProcessor_3_Callback(mthis, bufferSize) native "AudioContext_createScriptProcessor_Callback_RESOLVER_STRING_1_unsigned long";

  static $_createScriptProcessor_4_Callback(mthis) native "AudioContext_createScriptProcessor_Callback_RESOLVER_STRING_0_";

  static $createWaveShaper_Callback(mthis) native "AudioContext_createWaveShaper_Callback_RESOLVER_STRING_0_";

  static $decodeAudioData_Callback(mthis, audioData, successCallback, errorCallback) native "AudioContext_decodeAudioData_Callback";

  static $startRendering_Callback(mthis) native "AudioContext_startRendering_Callback_RESOLVER_STRING_0_";
}

class BlinkAudioDestinationNode {
  static $maxChannelCount_Getter(mthis) native "AudioDestinationNode_maxChannelCount_Getter";
}

class BlinkAudioListener {
  static $dopplerFactor_Getter(mthis) native "AudioListener_dopplerFactor_Getter";

  static $dopplerFactor_Setter(mthis, value) native "AudioListener_dopplerFactor_Setter";

  static $speedOfSound_Getter(mthis) native "AudioListener_speedOfSound_Getter";

  static $speedOfSound_Setter(mthis, value) native "AudioListener_speedOfSound_Setter";

  static $setOrientation_Callback(mthis, x, y, z, xUp, yUp, zUp) native "AudioListener_setOrientation_Callback_RESOLVER_STRING_6_float_float_float_float_float_float";

  static $setPosition_Callback(mthis, x, y, z) native "AudioListener_setPosition_Callback_RESOLVER_STRING_3_float_float_float";

  static $setVelocity_Callback(mthis, x, y, z) native "AudioListener_setVelocity_Callback_RESOLVER_STRING_3_float_float_float";
}

class BlinkAudioParam {
  static $defaultValue_Getter(mthis) native "AudioParam_defaultValue_Getter";

  static $maxValue_Getter(mthis) native "AudioParam_maxValue_Getter";

  static $minValue_Getter(mthis) native "AudioParam_minValue_Getter";

  static $name_Getter(mthis) native "AudioParam_name_Getter";

  static $units_Getter(mthis) native "AudioParam_units_Getter";

  static $value_Getter(mthis) native "AudioParam_value_Getter";

  static $value_Setter(mthis, value) native "AudioParam_value_Setter";

  static $cancelScheduledValues_Callback(mthis, startTime) native "AudioParam_cancelScheduledValues_Callback_RESOLVER_STRING_1_double";

  static $exponentialRampToValueAtTime_Callback(mthis, value, time) native "AudioParam_exponentialRampToValueAtTime_Callback_RESOLVER_STRING_2_float_double";

  static $linearRampToValueAtTime_Callback(mthis, value, time) native "AudioParam_linearRampToValueAtTime_Callback_RESOLVER_STRING_2_float_double";

  static $setTargetAtTime_Callback(mthis, target, time, timeConstant) native "AudioParam_setTargetAtTime_Callback_RESOLVER_STRING_3_float_double_double";

  static $setValueAtTime_Callback(mthis, value, time) native "AudioParam_setValueAtTime_Callback_RESOLVER_STRING_2_float_double";

  static $setValueCurveAtTime_Callback(mthis, values, time, duration) native "AudioParam_setValueCurveAtTime_Callback";
}

class BlinkEvent {
  static $bubbles_Getter(mthis) native "Event_bubbles_Getter";

  static $cancelable_Getter(mthis) native "Event_cancelable_Getter";

  static $clipboardData_Getter(mthis) native "Event_clipboardData_Getter";

  static $currentTarget_Getter(mthis) native "Event_currentTarget_Getter";

  static $defaultPrevented_Getter(mthis) native "Event_defaultPrevented_Getter";

  static $eventPhase_Getter(mthis) native "Event_eventPhase_Getter";

  static $path_Getter(mthis) native "Event_path_Getter";

  static $target_Getter(mthis) native "Event_target_Getter";

  static $timeStamp_Getter(mthis) native "Event_timeStamp_Getter";

  static $type_Getter(mthis) native "Event_type_Getter";

  static $initEvent_Callback(mthis, eventTypeArg, canBubbleArg, cancelableArg) native "Event_initEvent_Callback_RESOLVER_STRING_3_DOMString_boolean_boolean";

  static $preventDefault_Callback(mthis) native "Event_preventDefault_Callback_RESOLVER_STRING_0_";

  static $stopImmediatePropagation_Callback(mthis) native "Event_stopImmediatePropagation_Callback_RESOLVER_STRING_0_";

  static $stopPropagation_Callback(mthis) native "Event_stopPropagation_Callback_RESOLVER_STRING_0_";
}

class BlinkAudioProcessingEvent {
  static $inputBuffer_Getter(mthis) native "AudioProcessingEvent_inputBuffer_Getter";

  static $outputBuffer_Getter(mthis) native "AudioProcessingEvent_outputBuffer_Getter";
}

class BlinkAutocompleteErrorEvent {
  static $reason_Getter(mthis) native "AutocompleteErrorEvent_reason_Getter";
}

class BlinkBarProp {
  static $visible_Getter(mthis) native "BarProp_visible_Getter";
}

class BlinkBeforeLoadEvent {}

class BlinkBeforeUnloadEvent {
  static $returnValue_Getter(mthis) native "BeforeUnloadEvent_returnValue_Getter";

  static $returnValue_Setter(mthis, value) native "BeforeUnloadEvent_returnValue_Setter";
}

class BlinkBiquadFilterNode {
  static $Q_Getter(mthis) native "BiquadFilterNode_Q_Getter";

  static $detune_Getter(mthis) native "BiquadFilterNode_detune_Getter";

  static $frequency_Getter(mthis) native "BiquadFilterNode_frequency_Getter";

  static $gain_Getter(mthis) native "BiquadFilterNode_gain_Getter";

  static $type_Getter(mthis) native "BiquadFilterNode_type_Getter";

  static $type_Setter(mthis, value) native "BiquadFilterNode_type_Setter";

  static $getFrequencyResponse_Callback(mthis, frequencyHz, magResponse, phaseResponse) native "BiquadFilterNode_getFrequencyResponse_Callback_RESOLVER_STRING_3_Float32Array_Float32Array_Float32Array";
}

class BlinkBlob {
  static $constructorCallback(blobParts, type, endings) native "Blob_constructorCallback";

  static $size_Getter(mthis) native "Blob_size_Getter";

  static $type_Getter(mthis) native "Blob_type_Getter";

  // Generated overload resolver
  static $slice(mthis, start, end, contentType) {
    if (contentType != null) {
      return $_slice_1_Callback(mthis, start, end, contentType);
    }
    if (end != null) {
      return $_slice_2_Callback(mthis, start, end);
    }
    if (start != null) {
      return $_slice_3_Callback(mthis, start);
    }
    return $_slice_4_Callback(mthis);
  }

  static $_slice_1_Callback(mthis, start, end, contentType) native "Blob_slice_Callback_RESOLVER_STRING_3_long long_long long_DOMString";

  static $_slice_2_Callback(mthis, start, end) native "Blob_slice_Callback_RESOLVER_STRING_2_long long_long long";

  static $_slice_3_Callback(mthis, start) native "Blob_slice_Callback_RESOLVER_STRING_1_long long";

  static $_slice_4_Callback(mthis) native "Blob_slice_Callback_RESOLVER_STRING_0_";
}

class BlinkChildNode {
  static $nextElementSibling_Getter(mthis) native "ChildNode_nextElementSibling_Getter";

  static $previousElementSibling_Getter(mthis) native "ChildNode_previousElementSibling_Getter";

  static $remove_Callback(mthis) native "ChildNode_remove_Callback_RESOLVER_STRING_0_";
}

class BlinkCharacterData {
  static $data_Getter(mthis) native "CharacterData_data_Getter";

  static $data_Setter(mthis, value) native "CharacterData_data_Setter";

  static $length_Getter(mthis) native "CharacterData_length_Getter";

  static $appendData_Callback(mthis, data) native "CharacterData_appendData_Callback_RESOLVER_STRING_1_DOMString";

  static $deleteData_Callback(mthis, offset, length) native "CharacterData_deleteData_Callback_RESOLVER_STRING_2_unsigned long_unsigned long";

  static $insertData_Callback(mthis, offset, data) native "CharacterData_insertData_Callback_RESOLVER_STRING_2_unsigned long_DOMString";

  static $replaceData_Callback(mthis, offset, length, data) native "CharacterData_replaceData_Callback_RESOLVER_STRING_3_unsigned long_unsigned long_DOMString";

  static $substringData_Callback(mthis, offset, length) native "CharacterData_substringData_Callback_RESOLVER_STRING_2_unsigned long_unsigned long";

  static $nextElementSibling_Getter(mthis) native "CharacterData_nextElementSibling_Getter";

  static $previousElementSibling_Getter(mthis) native "CharacterData_previousElementSibling_Getter";
}

class BlinkText {
  static $wholeText_Getter(mthis) native "Text_wholeText_Getter";

  static $getDestinationInsertionPoints_Callback(mthis) native "Text_getDestinationInsertionPoints_Callback_RESOLVER_STRING_0_";

  static $splitText_Callback(mthis, offset) native "Text_splitText_Callback_RESOLVER_STRING_1_unsigned long";
}

class BlinkCDATASection {}

class BlinkCSS {
  static $supports_Callback(mthis, property, value) native "CSS_supports_Callback_RESOLVER_STRING_2_DOMString_DOMString";

  static $supportsCondition_Callback(mthis, conditionText) native "CSS_supports_Callback_RESOLVER_STRING_1_DOMString";
}

class BlinkCSSRule {
  static $cssText_Getter(mthis) native "CSSRule_cssText_Getter";

  static $cssText_Setter(mthis, value) native "CSSRule_cssText_Setter";

  static $parentRule_Getter(mthis) native "CSSRule_parentRule_Getter";

  static $parentStyleSheet_Getter(mthis) native "CSSRule_parentStyleSheet_Getter";

  static $type_Getter(mthis) native "CSSRule_type_Getter";
}

class BlinkCSSCharsetRule {
  static $encoding_Getter(mthis) native "CSSCharsetRule_encoding_Getter";

  static $encoding_Setter(mthis, value) native "CSSCharsetRule_encoding_Setter";
}

class BlinkCSSFontFaceLoadEvent {
  static $fontfaces_Getter(mthis) native "CSSFontFaceLoadEvent_fontfaces_Getter";
}

class BlinkCSSFontFaceRule {
  static $style_Getter(mthis) native "CSSFontFaceRule_style_Getter";
}

class BlinkCSSImportRule {
  static $href_Getter(mthis) native "CSSImportRule_href_Getter";

  static $media_Getter(mthis) native "CSSImportRule_media_Getter";

  static $styleSheet_Getter(mthis) native "CSSImportRule_styleSheet_Getter";
}

class BlinkCSSKeyframeRule {
  static $keyText_Getter(mthis) native "CSSKeyframeRule_keyText_Getter";

  static $keyText_Setter(mthis, value) native "CSSKeyframeRule_keyText_Setter";

  static $style_Getter(mthis) native "CSSKeyframeRule_style_Getter";
}

class BlinkCSSKeyframesRule {
  static $cssRules_Getter(mthis) native "CSSKeyframesRule_cssRules_Getter";

  static $name_Getter(mthis) native "CSSKeyframesRule_name_Getter";

  static $name_Setter(mthis, value) native "CSSKeyframesRule_name_Setter";

  static $__getter___Callback(mthis, index) native "CSSKeyframesRule___getter___Callback_RESOLVER_STRING_1_unsigned long";

  static $deleteRule_Callback(mthis, key) native "CSSKeyframesRule_deleteRule_Callback_RESOLVER_STRING_1_DOMString";

  static $findRule_Callback(mthis, key) native "CSSKeyframesRule_findRule_Callback_RESOLVER_STRING_1_DOMString";

  static $insertRule_Callback(mthis, rule) native "CSSKeyframesRule_insertRule_Callback_RESOLVER_STRING_1_DOMString";
}

class BlinkCSSMediaRule {
  static $cssRules_Getter(mthis) native "CSSMediaRule_cssRules_Getter";

  static $media_Getter(mthis) native "CSSMediaRule_media_Getter";

  static $deleteRule_Callback(mthis, index) native "CSSMediaRule_deleteRule_Callback_RESOLVER_STRING_1_unsigned long";

  static $insertRule_Callback(mthis, rule, index) native "CSSMediaRule_insertRule_Callback_RESOLVER_STRING_2_DOMString_unsigned long";
}

class BlinkCSSPageRule {
  static $selectorText_Getter(mthis) native "CSSPageRule_selectorText_Getter";

  static $selectorText_Setter(mthis, value) native "CSSPageRule_selectorText_Setter";

  static $style_Getter(mthis) native "CSSPageRule_style_Getter";
}

class BlinkCSSValue {}

class BlinkCSSPrimitiveValue {}

class BlinkCSSRuleList {
  static $length_Getter(mthis) native "CSSRuleList_length_Getter";

  static $NativeIndexed_Getter(mthis, index) native "CSSRuleList_item_Callback_RESOLVER_STRING_1_unsigned long";

  static $item_Callback(mthis, index) native "CSSRuleList_item_Callback_RESOLVER_STRING_1_unsigned long";
}

class BlinkCSSStyleDeclaration {
  static $cssText_Getter(mthis) native "CSSStyleDeclaration_cssText_Getter";

  static $cssText_Setter(mthis, value) native "CSSStyleDeclaration_cssText_Setter";

  static $length_Getter(mthis) native "CSSStyleDeclaration_length_Getter";

  static $parentRule_Getter(mthis) native "CSSStyleDeclaration_parentRule_Getter";

  static $__setter___Callback(mthis, propertyName, propertyValue) native "CSSStyleDeclaration___setter___Callback";

  static $getPropertyPriority_Callback(mthis, propertyName) native "CSSStyleDeclaration_getPropertyPriority_Callback_RESOLVER_STRING_1_DOMString";

  static $getPropertyValue_Callback(mthis, propertyName) native "CSSStyleDeclaration_getPropertyValue_Callback_RESOLVER_STRING_1_DOMString";

  static $item_Callback(mthis, index) native "CSSStyleDeclaration_item_Callback_RESOLVER_STRING_1_unsigned long";

  static $removeProperty_Callback(mthis, propertyName) native "CSSStyleDeclaration_removeProperty_Callback_RESOLVER_STRING_1_DOMString";

  static $setProperty_Callback(mthis, propertyName, value, priority) native "CSSStyleDeclaration_setProperty_Callback_RESOLVER_STRING_3_DOMString_DOMString_DOMString";
}

class BlinkCSSStyleRule {
  static $selectorText_Getter(mthis) native "CSSStyleRule_selectorText_Getter";

  static $selectorText_Setter(mthis, value) native "CSSStyleRule_selectorText_Setter";

  static $style_Getter(mthis) native "CSSStyleRule_style_Getter";
}

class BlinkStyleSheet {
  static $disabled_Getter(mthis) native "StyleSheet_disabled_Getter";

  static $disabled_Setter(mthis, value) native "StyleSheet_disabled_Setter";

  static $href_Getter(mthis) native "StyleSheet_href_Getter";

  static $media_Getter(mthis) native "StyleSheet_media_Getter";

  static $ownerNode_Getter(mthis) native "StyleSheet_ownerNode_Getter";

  static $parentStyleSheet_Getter(mthis) native "StyleSheet_parentStyleSheet_Getter";

  static $title_Getter(mthis) native "StyleSheet_title_Getter";

  static $type_Getter(mthis) native "StyleSheet_type_Getter";
}

class BlinkCSSStyleSheet {
  static $cssRules_Getter(mthis) native "CSSStyleSheet_cssRules_Getter";

  static $ownerRule_Getter(mthis) native "CSSStyleSheet_ownerRule_Getter";

  static $rules_Getter(mthis) native "CSSStyleSheet_rules_Getter";

  // Generated overload resolver
  static $addRule(mthis, selector, style, index) {
    if (index != null) {
      return $_addRule_1_Callback(mthis, selector, style, index);
    }
    return $_addRule_2_Callback(mthis, selector, style);
  }

  static $_addRule_1_Callback(mthis, selector, style, index) native "CSSStyleSheet_addRule_Callback_RESOLVER_STRING_3_DOMString_DOMString_unsigned long";

  static $_addRule_2_Callback(mthis, selector, style) native "CSSStyleSheet_addRule_Callback_RESOLVER_STRING_2_DOMString_DOMString";

  static $deleteRule_Callback(mthis, index) native "CSSStyleSheet_deleteRule_Callback_RESOLVER_STRING_1_unsigned long";

  // Generated overload resolver
  static $insertRule(mthis, rule, index) {
    if (index != null) {
      return $_insertRule_1_Callback(mthis, rule, index);
    }
    return $_insertRule_2_Callback(mthis, rule);
  }

  static $_insertRule_1_Callback(mthis, rule, index) native "CSSStyleSheet_insertRule_Callback_RESOLVER_STRING_2_DOMString_unsigned long";

  static $_insertRule_2_Callback(mthis, rule) native "CSSStyleSheet_insertRule_Callback_RESOLVER_STRING_1_DOMString";

  static $removeRule_Callback(mthis, index) native "CSSStyleSheet_removeRule_Callback_RESOLVER_STRING_1_unsigned long";
}

class BlinkCSSSupportsRule {
  static $conditionText_Getter(mthis) native "CSSSupportsRule_conditionText_Getter";

  static $cssRules_Getter(mthis) native "CSSSupportsRule_cssRules_Getter";

  static $deleteRule_Callback(mthis, index) native "CSSSupportsRule_deleteRule_Callback_RESOLVER_STRING_1_unsigned long";

  static $insertRule_Callback(mthis, rule, index) native "CSSSupportsRule_insertRule_Callback_RESOLVER_STRING_2_DOMString_unsigned long";
}

class BlinkCSSUnknownRule {}

class BlinkCSSValueList {
  static $length_Getter(mthis) native "CSSValueList_length_Getter";

  static $NativeIndexed_Getter(mthis, index) native "CSSValueList_item_Callback_RESOLVER_STRING_1_unsigned long";

  static $item_Callback(mthis, index) native "CSSValueList_item_Callback_RESOLVER_STRING_1_unsigned long";
}

class BlinkCSSViewportRule {
  static $style_Getter(mthis) native "CSSViewportRule_style_Getter";
}

class BlinkCanvas2DContextAttributes {
  static $alpha_Getter(mthis) native "Canvas2DContextAttributes_alpha_Getter";

  static $alpha_Setter(mthis, value) native "Canvas2DContextAttributes_alpha_Setter";
}

class BlinkCanvasGradient {
  static $addColorStop_Callback(mthis, offset, color) native "CanvasGradient_addColorStop_Callback_RESOLVER_STRING_2_float_DOMString";
}

class BlinkCanvasPattern {}

class BlinkCanvasRenderingContext {
  static $canvas_Getter(mthis) native "CanvasRenderingContext2D_canvas_Getter";
}

class BlinkCanvasRenderingContext2D {
  static $currentTransform_Getter(mthis) native "CanvasRenderingContext2D_currentTransform_Getter";

  static $currentTransform_Setter(mthis, value) native "CanvasRenderingContext2D_currentTransform_Setter";

  static $fillStyle_Getter(mthis) native "CanvasRenderingContext2D_fillStyle_Getter";

  static $fillStyle_Setter(mthis, value) native "CanvasRenderingContext2D_fillStyle_Setter";

  static $font_Getter(mthis) native "CanvasRenderingContext2D_font_Getter";

  static $font_Setter(mthis, value) native "CanvasRenderingContext2D_font_Setter";

  static $globalAlpha_Getter(mthis) native "CanvasRenderingContext2D_globalAlpha_Getter";

  static $globalAlpha_Setter(mthis, value) native "CanvasRenderingContext2D_globalAlpha_Setter";

  static $globalCompositeOperation_Getter(mthis) native "CanvasRenderingContext2D_globalCompositeOperation_Getter";

  static $globalCompositeOperation_Setter(mthis, value) native "CanvasRenderingContext2D_globalCompositeOperation_Setter";

  static $imageSmoothingEnabled_Getter(mthis) native "CanvasRenderingContext2D_imageSmoothingEnabled_Getter";

  static $imageSmoothingEnabled_Setter(mthis, value) native "CanvasRenderingContext2D_imageSmoothingEnabled_Setter";

  static $lineCap_Getter(mthis) native "CanvasRenderingContext2D_lineCap_Getter";

  static $lineCap_Setter(mthis, value) native "CanvasRenderingContext2D_lineCap_Setter";

  static $lineDashOffset_Getter(mthis) native "CanvasRenderingContext2D_lineDashOffset_Getter";

  static $lineDashOffset_Setter(mthis, value) native "CanvasRenderingContext2D_lineDashOffset_Setter";

  static $lineJoin_Getter(mthis) native "CanvasRenderingContext2D_lineJoin_Getter";

  static $lineJoin_Setter(mthis, value) native "CanvasRenderingContext2D_lineJoin_Setter";

  static $lineWidth_Getter(mthis) native "CanvasRenderingContext2D_lineWidth_Getter";

  static $lineWidth_Setter(mthis, value) native "CanvasRenderingContext2D_lineWidth_Setter";

  static $miterLimit_Getter(mthis) native "CanvasRenderingContext2D_miterLimit_Getter";

  static $miterLimit_Setter(mthis, value) native "CanvasRenderingContext2D_miterLimit_Setter";

  static $shadowBlur_Getter(mthis) native "CanvasRenderingContext2D_shadowBlur_Getter";

  static $shadowBlur_Setter(mthis, value) native "CanvasRenderingContext2D_shadowBlur_Setter";

  static $shadowColor_Getter(mthis) native "CanvasRenderingContext2D_shadowColor_Getter";

  static $shadowColor_Setter(mthis, value) native "CanvasRenderingContext2D_shadowColor_Setter";

  static $shadowOffsetX_Getter(mthis) native "CanvasRenderingContext2D_shadowOffsetX_Getter";

  static $shadowOffsetX_Setter(mthis, value) native "CanvasRenderingContext2D_shadowOffsetX_Setter";

  static $shadowOffsetY_Getter(mthis) native "CanvasRenderingContext2D_shadowOffsetY_Getter";

  static $shadowOffsetY_Setter(mthis, value) native "CanvasRenderingContext2D_shadowOffsetY_Setter";

  static $strokeStyle_Getter(mthis) native "CanvasRenderingContext2D_strokeStyle_Getter";

  static $strokeStyle_Setter(mthis, value) native "CanvasRenderingContext2D_strokeStyle_Setter";

  static $textAlign_Getter(mthis) native "CanvasRenderingContext2D_textAlign_Getter";

  static $textAlign_Setter(mthis, value) native "CanvasRenderingContext2D_textAlign_Setter";

  static $textBaseline_Getter(mthis) native "CanvasRenderingContext2D_textBaseline_Getter";

  static $textBaseline_Setter(mthis, value) native "CanvasRenderingContext2D_textBaseline_Setter";

  static $arc_Callback(mthis, x, y, radius, startAngle, endAngle, anticlockwise) native "CanvasRenderingContext2D_arc_Callback_RESOLVER_STRING_6_float_float_float_float_float_boolean";

  static $arcTo_Callback(mthis, x1, y1, x2, y2, radius) native "CanvasRenderingContext2D_arcTo_Callback_RESOLVER_STRING_5_float_float_float_float_float";

  static $beginPath_Callback(mthis) native "CanvasRenderingContext2D_beginPath_Callback_RESOLVER_STRING_0_";

  static $bezierCurveTo_Callback(mthis, cp1x, cp1y, cp2x, cp2y, x, y) native "CanvasRenderingContext2D_bezierCurveTo_Callback_RESOLVER_STRING_6_float_float_float_float_float_float";

  static $clearRect_Callback(mthis, x, y, width, height) native "CanvasRenderingContext2D_clearRect_Callback_RESOLVER_STRING_4_float_float_float_float";

  // Generated overload resolver
  static $clip(mthis, winding) {
    if (winding != null) {
      $_clip_1_Callback(mthis, winding);
      return;
    }
    $_clip_2_Callback(mthis);
    return;
  }

  static $_clip_1_Callback(mthis, winding) native "CanvasRenderingContext2D_clip_Callback_RESOLVER_STRING_1_DOMString";

  static $_clip_2_Callback(mthis) native "CanvasRenderingContext2D_clip_Callback_RESOLVER_STRING_0_";

  static $closePath_Callback(mthis) native "CanvasRenderingContext2D_closePath_Callback_RESOLVER_STRING_0_";

  static $createImageData_Callback(mthis, sw, sh) native "CanvasRenderingContext2D_createImageData_Callback_RESOLVER_STRING_2_float_float";

  static $createImageDataFromImageData_Callback(mthis, imagedata) native "CanvasRenderingContext2D_createImageData_Callback_RESOLVER_STRING_1_ImageData";

  static $createLinearGradient_Callback(mthis, x0, y0, x1, y1) native "CanvasRenderingContext2D_createLinearGradient_Callback_RESOLVER_STRING_4_float_float_float_float";

  static $createPattern_Callback(mthis, canvas, repetitionType) native "CanvasRenderingContext2D_createPattern_Callback_RESOLVER_STRING_2_HTMLCanvasElement_DOMString";

  static $createPatternFromImage_Callback(mthis, image, repetitionType) native "CanvasRenderingContext2D_createPattern_Callback_RESOLVER_STRING_2_HTMLImageElement_DOMString";

  static $createRadialGradient_Callback(mthis, x0, y0, r0, x1, y1, r1) native "CanvasRenderingContext2D_createRadialGradient_Callback_RESOLVER_STRING_6_float_float_float_float_float_float";

  static $drawCustomFocusRing_Callback(mthis, element) native "CanvasRenderingContext2D_drawCustomFocusRing_Callback_RESOLVER_STRING_1_Element";

  // Generated overload resolver
  static $_drawImage(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh) {
    if ((sy_OR_y is num || sy_OR_y == null) && (sx_OR_x is num || sx_OR_x == null) && (canvas_OR_image_OR_imageBitmap_OR_video is ImageElement || canvas_OR_image_OR_imageBitmap_OR_video == null) && sw_OR_width == null && height_OR_sh == null && dx == null && dy == null && dw == null && dh == null) {
      $_drawImage_1_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y);
      return;
    }
    if ((height_OR_sh is num || height_OR_sh == null) && (sw_OR_width is num || sw_OR_width == null) && (sy_OR_y is num || sy_OR_y == null) && (sx_OR_x is num || sx_OR_x == null) && (canvas_OR_image_OR_imageBitmap_OR_video is ImageElement || canvas_OR_image_OR_imageBitmap_OR_video == null) && dx == null && dy == null && dw == null && dh == null) {
      $_drawImage_2_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh);
      return;
    }
    if ((dh is num || dh == null) && (dw is num || dw == null) && (dy is num || dy == null) && (dx is num || dx == null) && (height_OR_sh is num || height_OR_sh == null) && (sw_OR_width is num || sw_OR_width == null) && (sy_OR_y is num || sy_OR_y == null) && (sx_OR_x is num || sx_OR_x == null) && (canvas_OR_image_OR_imageBitmap_OR_video is ImageElement || canvas_OR_image_OR_imageBitmap_OR_video == null)) {
      $_drawImage_3_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh);
      return;
    }
    if ((sy_OR_y is num || sy_OR_y == null) && (sx_OR_x is num || sx_OR_x == null) && (canvas_OR_image_OR_imageBitmap_OR_video is CanvasElement || canvas_OR_image_OR_imageBitmap_OR_video == null) && sw_OR_width == null && height_OR_sh == null && dx == null && dy == null && dw == null && dh == null) {
      $_drawImage_4_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y);
      return;
    }
    if ((height_OR_sh is num || height_OR_sh == null) && (sw_OR_width is num || sw_OR_width == null) && (sy_OR_y is num || sy_OR_y == null) && (sx_OR_x is num || sx_OR_x == null) && (canvas_OR_image_OR_imageBitmap_OR_video is CanvasElement || canvas_OR_image_OR_imageBitmap_OR_video == null) && dx == null && dy == null && dw == null && dh == null) {
      $_drawImage_5_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh);
      return;
    }
    if ((dh is num || dh == null) && (dw is num || dw == null) && (dy is num || dy == null) && (dx is num || dx == null) && (height_OR_sh is num || height_OR_sh == null) && (sw_OR_width is num || sw_OR_width == null) && (sy_OR_y is num || sy_OR_y == null) && (sx_OR_x is num || sx_OR_x == null) && (canvas_OR_image_OR_imageBitmap_OR_video is CanvasElement || canvas_OR_image_OR_imageBitmap_OR_video == null)) {
      $_drawImage_6_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh);
      return;
    }
    if ((sy_OR_y is num || sy_OR_y == null) && (sx_OR_x is num || sx_OR_x == null) && (canvas_OR_image_OR_imageBitmap_OR_video is VideoElement || canvas_OR_image_OR_imageBitmap_OR_video == null) && sw_OR_width == null && height_OR_sh == null && dx == null && dy == null && dw == null && dh == null) {
      $_drawImage_7_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y);
      return;
    }
    if ((height_OR_sh is num || height_OR_sh == null) && (sw_OR_width is num || sw_OR_width == null) && (sy_OR_y is num || sy_OR_y == null) && (sx_OR_x is num || sx_OR_x == null) && (canvas_OR_image_OR_imageBitmap_OR_video is VideoElement || canvas_OR_image_OR_imageBitmap_OR_video == null) && dx == null && dy == null && dw == null && dh == null) {
      $_drawImage_8_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh);
      return;
    }
    if ((dh is num || dh == null) && (dw is num || dw == null) && (dy is num || dy == null) && (dx is num || dx == null) && (height_OR_sh is num || height_OR_sh == null) && (sw_OR_width is num || sw_OR_width == null) && (sy_OR_y is num || sy_OR_y == null) && (sx_OR_x is num || sx_OR_x == null) && (canvas_OR_image_OR_imageBitmap_OR_video is VideoElement || canvas_OR_image_OR_imageBitmap_OR_video == null)) {
      $_drawImage_9_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh);
      return;
    }
    if ((sy_OR_y is num || sy_OR_y == null) && (sx_OR_x is num || sx_OR_x == null) && (canvas_OR_image_OR_imageBitmap_OR_video is ImageBitmap || canvas_OR_image_OR_imageBitmap_OR_video == null) && sw_OR_width == null && height_OR_sh == null && dx == null && dy == null && dw == null && dh == null) {
      $_drawImage_10_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y);
      return;
    }
    if ((height_OR_sh is num || height_OR_sh == null) && (sw_OR_width is num || sw_OR_width == null) && (sy_OR_y is num || sy_OR_y == null) && (sx_OR_x is num || sx_OR_x == null) && (canvas_OR_image_OR_imageBitmap_OR_video is ImageBitmap || canvas_OR_image_OR_imageBitmap_OR_video == null) && dx == null && dy == null && dw == null && dh == null) {
      $_drawImage_11_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh);
      return;
    }
    if ((dh is num || dh == null) && (dw is num || dw == null) && (dy is num || dy == null) && (dx is num || dx == null) && (height_OR_sh is num || height_OR_sh == null) && (sw_OR_width is num || sw_OR_width == null) && (sy_OR_y is num || sy_OR_y == null) && (sx_OR_x is num || sx_OR_x == null) && (canvas_OR_image_OR_imageBitmap_OR_video is ImageBitmap || canvas_OR_image_OR_imageBitmap_OR_video == null)) {
      $_drawImage_12_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  static $_drawImage_1_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y) native "CanvasRenderingContext2D_drawImage_Callback_RESOLVER_STRING_3_HTMLImageElement_float_float";

  static $_drawImage_2_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh) native "CanvasRenderingContext2D_drawImage_Callback_RESOLVER_STRING_5_HTMLImageElement_float_float_float_float";

  static $_drawImage_3_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh) native "CanvasRenderingContext2D_drawImage_Callback_RESOLVER_STRING_9_HTMLImageElement_float_float_float_float_float_float_float_float";

  static $_drawImage_4_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y) native "CanvasRenderingContext2D_drawImage_Callback_RESOLVER_STRING_3_HTMLCanvasElement_float_float";

  static $_drawImage_5_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh) native "CanvasRenderingContext2D_drawImage_Callback_RESOLVER_STRING_5_HTMLCanvasElement_float_float_float_float";

  static $_drawImage_6_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh) native "CanvasRenderingContext2D_drawImage_Callback_RESOLVER_STRING_9_HTMLCanvasElement_float_float_float_float_float_float_float_float";

  static $_drawImage_7_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y) native "CanvasRenderingContext2D_drawImage_Callback_RESOLVER_STRING_3_HTMLVideoElement_float_float";

  static $_drawImage_8_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh) native "CanvasRenderingContext2D_drawImage_Callback_RESOLVER_STRING_5_HTMLVideoElement_float_float_float_float";

  static $_drawImage_9_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh) native "CanvasRenderingContext2D_drawImage_Callback_RESOLVER_STRING_9_HTMLVideoElement_float_float_float_float_float_float_float_float";

  static $_drawImage_10_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y) native "CanvasRenderingContext2D_drawImage_Callback_RESOLVER_STRING_3_ImageBitmap_float_float";

  static $_drawImage_11_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh) native "CanvasRenderingContext2D_drawImage_Callback_RESOLVER_STRING_5_ImageBitmap_float_float_float_float";

  static $_drawImage_12_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh) native "CanvasRenderingContext2D_drawImage_Callback_RESOLVER_STRING_9_ImageBitmap_float_float_float_float_float_float_float_float";

  static $ellipse_Callback(mthis, x, y, radiusX, radiusY, rotation, startAngle, endAngle, anticlockwise) native "CanvasRenderingContext2D_ellipse_Callback_RESOLVER_STRING_8_float_float_float_float_float_float_float_boolean";

  // Generated overload resolver
  static $fill(mthis, winding) {
    if (winding != null) {
      $_fill_1_Callback(mthis, winding);
      return;
    }
    $_fill_2_Callback(mthis);
    return;
  }

  static $_fill_1_Callback(mthis, winding) native "CanvasRenderingContext2D_fill_Callback_RESOLVER_STRING_1_DOMString";

  static $_fill_2_Callback(mthis) native "CanvasRenderingContext2D_fill_Callback_RESOLVER_STRING_0_";

  static $fillRect_Callback(mthis, x, y, width, height) native "CanvasRenderingContext2D_fillRect_Callback_RESOLVER_STRING_4_float_float_float_float";

  // Generated overload resolver
  static $fillText(mthis, text, x, y, maxWidth) {
    if (maxWidth != null) {
      $_fillText_1_Callback(mthis, text, x, y, maxWidth);
      return;
    }
    $_fillText_2_Callback(mthis, text, x, y);
    return;
  }

  static $_fillText_1_Callback(mthis, text, x, y, maxWidth) native "CanvasRenderingContext2D_fillText_Callback_RESOLVER_STRING_4_DOMString_float_float_float";

  static $_fillText_2_Callback(mthis, text, x, y) native "CanvasRenderingContext2D_fillText_Callback_RESOLVER_STRING_3_DOMString_float_float";

  static $getContextAttributes_Callback(mthis) native "CanvasRenderingContext2D_getContextAttributes_Callback_RESOLVER_STRING_0_";

  static $getImageData_Callback(mthis, sx, sy, sw, sh) native "CanvasRenderingContext2D_getImageData_Callback_RESOLVER_STRING_4_float_float_float_float";

  static $getLineDash_Callback(mthis) native "CanvasRenderingContext2D_getLineDash_Callback_RESOLVER_STRING_0_";

  // Generated overload resolver
  static $isPointInPath(mthis, x, y, winding) {
    if (winding != null) {
      return $_isPointInPath_1_Callback(mthis, x, y, winding);
    }
    return $_isPointInPath_2_Callback(mthis, x, y);
  }

  static $_isPointInPath_1_Callback(mthis, x, y, winding) native "CanvasRenderingContext2D_isPointInPath_Callback_RESOLVER_STRING_3_float_float_DOMString";

  static $_isPointInPath_2_Callback(mthis, x, y) native "CanvasRenderingContext2D_isPointInPath_Callback_RESOLVER_STRING_2_float_float";

  static $isPointInStroke_Callback(mthis, x, y) native "CanvasRenderingContext2D_isPointInStroke_Callback_RESOLVER_STRING_2_float_float";

  static $lineTo_Callback(mthis, x, y) native "CanvasRenderingContext2D_lineTo_Callback_RESOLVER_STRING_2_float_float";

  static $measureText_Callback(mthis, text) native "CanvasRenderingContext2D_measureText_Callback_RESOLVER_STRING_1_DOMString";

  static $moveTo_Callback(mthis, x, y) native "CanvasRenderingContext2D_moveTo_Callback_RESOLVER_STRING_2_float_float";

  // Generated overload resolver
  static $putImageData(mthis, imagedata, dx, dy, dirtyX, dirtyY, dirtyWidth, dirtyHeight) {
    if ((dy is num || dy == null) && (dx is num || dx == null) && (imagedata is ImageData || imagedata == null) && dirtyX == null && dirtyY == null && dirtyWidth == null && dirtyHeight == null) {
      $_putImageData_1_Callback(mthis, imagedata, dx, dy);
      return;
    }
    if ((dirtyHeight is num || dirtyHeight == null) && (dirtyWidth is num || dirtyWidth == null) && (dirtyY is num || dirtyY == null) && (dirtyX is num || dirtyX == null) && (dy is num || dy == null) && (dx is num || dx == null) && (imagedata is ImageData || imagedata == null)) {
      $_putImageData_2_Callback(mthis, imagedata, dx, dy, dirtyX, dirtyY, dirtyWidth, dirtyHeight);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  static $_putImageData_1_Callback(mthis, imagedata, dx, dy) native "CanvasRenderingContext2D_putImageData_Callback_RESOLVER_STRING_3_ImageData_float_float";

  static $_putImageData_2_Callback(mthis, imagedata, dx, dy, dirtyX, dirtyY, dirtyWidth, dirtyHeight) native "CanvasRenderingContext2D_putImageData_Callback_RESOLVER_STRING_7_ImageData_float_float_float_float_float_float";

  static $quadraticCurveTo_Callback(mthis, cpx, cpy, x, y) native "CanvasRenderingContext2D_quadraticCurveTo_Callback_RESOLVER_STRING_4_float_float_float_float";

  static $rect_Callback(mthis, x, y, width, height) native "CanvasRenderingContext2D_rect_Callback_RESOLVER_STRING_4_float_float_float_float";

  static $resetTransform_Callback(mthis) native "CanvasRenderingContext2D_resetTransform_Callback_RESOLVER_STRING_0_";

  static $restore_Callback(mthis) native "CanvasRenderingContext2D_restore_Callback_RESOLVER_STRING_0_";

  static $rotate_Callback(mthis, angle) native "CanvasRenderingContext2D_rotate_Callback_RESOLVER_STRING_1_float";

  static $save_Callback(mthis) native "CanvasRenderingContext2D_save_Callback_RESOLVER_STRING_0_";

  static $scale_Callback(mthis, sx, sy) native "CanvasRenderingContext2D_scale_Callback_RESOLVER_STRING_2_float_float";

  static $setLineDash_Callback(mthis, dash) native "CanvasRenderingContext2D_setLineDash_Callback_RESOLVER_STRING_1_sequence<unrestricted float>";

  static $setTransform_Callback(mthis, m11, m12, m21, m22, dx, dy) native "CanvasRenderingContext2D_setTransform_Callback_RESOLVER_STRING_6_float_float_float_float_float_float";

  static $stroke_Callback(mthis) native "CanvasRenderingContext2D_stroke_Callback_RESOLVER_STRING_0_";

  static $strokeRect_Callback(mthis, x, y, width, height) native "CanvasRenderingContext2D_strokeRect_Callback_RESOLVER_STRING_4_float_float_float_float";

  // Generated overload resolver
  static $strokeText(mthis, text, x, y, maxWidth) {
    if (maxWidth != null) {
      $_strokeText_1_Callback(mthis, text, x, y, maxWidth);
      return;
    }
    $_strokeText_2_Callback(mthis, text, x, y);
    return;
  }

  static $_strokeText_1_Callback(mthis, text, x, y, maxWidth) native "CanvasRenderingContext2D_strokeText_Callback_RESOLVER_STRING_4_DOMString_float_float_float";

  static $_strokeText_2_Callback(mthis, text, x, y) native "CanvasRenderingContext2D_strokeText_Callback_RESOLVER_STRING_3_DOMString_float_float";

  static $transform_Callback(mthis, m11, m12, m21, m22, dx, dy) native "CanvasRenderingContext2D_transform_Callback_RESOLVER_STRING_6_float_float_float_float_float_float";

  static $translate_Callback(mthis, tx, ty) native "CanvasRenderingContext2D_translate_Callback_RESOLVER_STRING_2_float_float";
}

class BlinkChannelMergerNode {}

class BlinkChannelSplitterNode {}

class BlinkClientRect {
  static $bottom_Getter(mthis) native "ClientRect_bottom_Getter";

  static $height_Getter(mthis) native "ClientRect_height_Getter";

  static $left_Getter(mthis) native "ClientRect_left_Getter";

  static $right_Getter(mthis) native "ClientRect_right_Getter";

  static $top_Getter(mthis) native "ClientRect_top_Getter";

  static $width_Getter(mthis) native "ClientRect_width_Getter";
}

class BlinkClientRectList {
  static $length_Getter(mthis) native "ClientRectList_length_Getter";

  static $NativeIndexed_Getter(mthis, index) native "ClientRectList_item_Callback_RESOLVER_STRING_1_unsigned long";

  static $item_Callback(mthis, index) native "ClientRectList_item_Callback_RESOLVER_STRING_1_unsigned long";
}

class BlinkClipboard {
  static $dropEffect_Getter(mthis) native "DataTransfer_dropEffect_Getter";

  static $dropEffect_Setter(mthis, value) native "DataTransfer_dropEffect_Setter";

  static $effectAllowed_Getter(mthis) native "DataTransfer_effectAllowed_Getter";

  static $effectAllowed_Setter(mthis, value) native "DataTransfer_effectAllowed_Setter";

  static $files_Getter(mthis) native "DataTransfer_files_Getter";

  static $items_Getter(mthis) native "DataTransfer_items_Getter";

  static $types_Getter(mthis) native "DataTransfer_types_Getter";

  // Generated overload resolver
  static $clearData(mthis, type) {
    if (type != null) {
      $_clearData_1_Callback(mthis, type);
      return;
    }
    $_clearData_2_Callback(mthis);
    return;
  }

  static $_clearData_1_Callback(mthis, type) native "DataTransfer_clearData_Callback_RESOLVER_STRING_1_DOMString";

  static $_clearData_2_Callback(mthis) native "DataTransfer_clearData_Callback_RESOLVER_STRING_0_";

  static $getData_Callback(mthis, type) native "DataTransfer_getData_Callback_RESOLVER_STRING_1_DOMString";

  static $setData_Callback(mthis, type, data) native "DataTransfer_setData_Callback_RESOLVER_STRING_2_DOMString_DOMString";

  static $setDragImage_Callback(mthis, image, x, y) native "DataTransfer_setDragImage_Callback_RESOLVER_STRING_3_Element_long_long";
}

class BlinkCloseEvent {
  static $code_Getter(mthis) native "CloseEvent_code_Getter";

  static $reason_Getter(mthis) native "CloseEvent_reason_Getter";

  static $wasClean_Getter(mthis) native "CloseEvent_wasClean_Getter";
}

class BlinkComment {
  // Generated overload resolver
  static $mkComment(data) {
    return $_create_1constructorCallback(data);
  }

  static $_create_1constructorCallback(data) native "Comment_constructorCallback_RESOLVER_STRING_1_DOMString";
}

class BlinkUIEvent {
  static $charCode_Getter(mthis) native "UIEvent_charCode_Getter";

  static $detail_Getter(mthis) native "UIEvent_detail_Getter";

  static $keyCode_Getter(mthis) native "UIEvent_keyCode_Getter";

  static $layerX_Getter(mthis) native "UIEvent_layerX_Getter";

  static $layerY_Getter(mthis) native "UIEvent_layerY_Getter";

  static $pageX_Getter(mthis) native "UIEvent_pageX_Getter";

  static $pageY_Getter(mthis) native "UIEvent_pageY_Getter";

  static $view_Getter(mthis) native "UIEvent_view_Getter";

  static $which_Getter(mthis) native "UIEvent_which_Getter";

  static $initUIEvent_Callback(mthis, type, canBubble, cancelable, view, detail) native "UIEvent_initUIEvent_Callback_RESOLVER_STRING_5_DOMString_boolean_boolean_Window_long";
}

class BlinkCompositionEvent {
  static $activeSegmentEnd_Getter(mthis) native "CompositionEvent_activeSegmentEnd_Getter";

  static $activeSegmentStart_Getter(mthis) native "CompositionEvent_activeSegmentStart_Getter";

  static $data_Getter(mthis) native "CompositionEvent_data_Getter";

  static $initCompositionEvent_Callback(mthis, typeArg, canBubbleArg, cancelableArg, viewArg, dataArg) native "CompositionEvent_initCompositionEvent_Callback_RESOLVER_STRING_5_DOMString_boolean_boolean_Window_DOMString";
}

class BlinkConsoleBase {
  static $assertCondition_Callback(mthis, condition, arg) native "ConsoleBase_assert_Callback_RESOLVER_STRING_2_boolean_object";

  static $clear_Callback(mthis, arg) native "ConsoleBase_clear_Callback_RESOLVER_STRING_1_object";

  static $count_Callback(mthis, arg) native "ConsoleBase_count_Callback_RESOLVER_STRING_1_object";

  static $debug_Callback(mthis, arg) native "ConsoleBase_debug_Callback_RESOLVER_STRING_1_object";

  static $dir_Callback(mthis, arg) native "ConsoleBase_dir_Callback_RESOLVER_STRING_1_object";

  static $dirxml_Callback(mthis, arg) native "ConsoleBase_dirxml_Callback_RESOLVER_STRING_1_object";

  static $error_Callback(mthis, arg) native "ConsoleBase_error_Callback_RESOLVER_STRING_1_object";

  static $group_Callback(mthis, arg) native "ConsoleBase_group_Callback_RESOLVER_STRING_1_object";

  static $groupCollapsed_Callback(mthis, arg) native "ConsoleBase_groupCollapsed_Callback_RESOLVER_STRING_1_object";

  static $groupEnd_Callback(mthis) native "ConsoleBase_groupEnd_Callback_RESOLVER_STRING_0_";

  static $info_Callback(mthis, arg) native "ConsoleBase_info_Callback_RESOLVER_STRING_1_object";

  static $log_Callback(mthis, arg) native "ConsoleBase_log_Callback_RESOLVER_STRING_1_object";

  static $markTimeline_Callback(mthis, title) native "ConsoleBase_markTimeline_Callback_RESOLVER_STRING_1_DOMString";

  static $profile_Callback(mthis, title) native "ConsoleBase_profile_Callback_RESOLVER_STRING_1_DOMString";

  static $profileEnd_Callback(mthis, title) native "ConsoleBase_profileEnd_Callback_RESOLVER_STRING_1_DOMString";

  static $table_Callback(mthis, arg) native "ConsoleBase_table_Callback_RESOLVER_STRING_1_object";

  static $time_Callback(mthis, title) native "ConsoleBase_time_Callback_RESOLVER_STRING_1_DOMString";

  static $timeEnd_Callback(mthis, title) native "ConsoleBase_timeEnd_Callback_RESOLVER_STRING_1_DOMString";

  static $timeStamp_Callback(mthis, title) native "ConsoleBase_timeStamp_Callback_RESOLVER_STRING_1_DOMString";

  static $timeline_Callback(mthis, title) native "ConsoleBase_timeline_Callback_RESOLVER_STRING_1_DOMString";

  static $timelineEnd_Callback(mthis, title) native "ConsoleBase_timelineEnd_Callback_RESOLVER_STRING_1_DOMString";

  static $trace_Callback(mthis, arg) native "ConsoleBase_trace_Callback_RESOLVER_STRING_1_object";

  static $warn_Callback(mthis, arg) native "ConsoleBase_warn_Callback_RESOLVER_STRING_1_object";
}

class BlinkConsole {
  static $memory_Getter(mthis) native "Console_memory_Getter";
}

class BlinkConvolverNode {
  static $buffer_Getter(mthis) native "ConvolverNode_buffer_Getter";

  static $buffer_Setter(mthis, value) native "ConvolverNode_buffer_Setter";

  static $normalize_Getter(mthis) native "ConvolverNode_normalize_Getter";

  static $normalize_Setter(mthis, value) native "ConvolverNode_normalize_Setter";
}

class BlinkCoordinates {
  static $accuracy_Getter(mthis) native "Coordinates_accuracy_Getter";

  static $altitude_Getter(mthis) native "Coordinates_altitude_Getter";

  static $altitudeAccuracy_Getter(mthis) native "Coordinates_altitudeAccuracy_Getter";

  static $heading_Getter(mthis) native "Coordinates_heading_Getter";

  static $latitude_Getter(mthis) native "Coordinates_latitude_Getter";

  static $longitude_Getter(mthis) native "Coordinates_longitude_Getter";

  static $speed_Getter(mthis) native "Coordinates_speed_Getter";
}

class BlinkCounter {}

class BlinkCrypto {
  static $subtle_Getter(mthis) native "Crypto_subtle_Getter";

  static $getRandomValues_Callback(mthis, array) native "Crypto_getRandomValues_Callback";
}

class BlinkCustomEvent {
  static $detail_Getter(mthis) native "CustomEvent_detail_Getter";

  static $initCustomEvent_Callback(mthis, typeArg, canBubbleArg, cancelableArg, detailArg) native "CustomEvent_initCustomEvent_Callback";
}

class BlinkDOMError {
  static $message_Getter(mthis) native "DOMError_message_Getter";

  static $name_Getter(mthis) native "DOMError_name_Getter";
}

class BlinkDOMException {
  static $message_Getter(mthis) native "DOMException_message_Getter";

  static $name_Getter(mthis) native "DOMException_name_Getter";

  static $toString_Callback(mthis) native "DOMException_toString_Callback_RESOLVER_STRING_0_";
}

class BlinkDOMFileSystem {
  static $name_Getter(mthis) native "DOMFileSystem_name_Getter";

  static $root_Getter(mthis) native "DOMFileSystem_root_Getter";
}

class BlinkDOMFileSystemSync {}

class BlinkDOMImplementation {
  static $createDocument_Callback(mthis, namespaceURI, qualifiedName, doctype) native "DOMImplementation_createDocument_Callback_RESOLVER_STRING_3_DOMString_DOMString_DocumentType";

  static $createDocumentType_Callback(mthis, qualifiedName, publicId, systemId) native "DOMImplementation_createDocumentType_Callback_RESOLVER_STRING_3_DOMString_DOMString_DOMString";

  static $createHTMLDocument_Callback(mthis, title) native "DOMImplementation_createHTMLDocument_Callback_RESOLVER_STRING_1_DOMString";

  static $hasFeature_Callback(mthis, feature, version) native "DOMImplementation_hasFeature_Callback_RESOLVER_STRING_2_DOMString_DOMString";
}

class BlinkDOMParser {
  // Generated overload resolver
  static $mkDomParser() {
    return $_create_1constructorCallback();
  }

  static $_create_1constructorCallback() native "DOMParser_constructorCallback_RESOLVER_STRING_0_";

  static $parseFromString_Callback(mthis, str, contentType) native "DOMParser_parseFromString_Callback_RESOLVER_STRING_2_DOMString_DOMString";
}

class BlinkDOMTokenList {
  static $length_Getter(mthis) native "DOMTokenList_length_Getter";

  static $contains_Callback(mthis, token) native "DOMTokenList_contains_Callback_RESOLVER_STRING_1_DOMString";

  static $item_Callback(mthis, index) native "DOMTokenList_item_Callback_RESOLVER_STRING_1_unsigned long";

  static $toString_Callback(mthis) native "DOMTokenList_toString_Callback_RESOLVER_STRING_0_";

  // Generated overload resolver
  static $toggle(mthis, token, force) {
    if (force != null) {
      return $_toggle_1_Callback(mthis, token, force);
    }
    return $_toggle_2_Callback(mthis, token);
  }

  static $_toggle_1_Callback(mthis, token, force) native "DOMTokenList_toggle_Callback_RESOLVER_STRING_2_DOMString_boolean";

  static $_toggle_2_Callback(mthis, token) native "DOMTokenList_toggle_Callback_RESOLVER_STRING_1_DOMString";
}

class BlinkDOMSettableTokenList {
  static $value_Getter(mthis) native "DOMSettableTokenList_value_Getter";

  static $value_Setter(mthis, value) native "DOMSettableTokenList_value_Setter";

  static $__getter___Callback(mthis, index) native "DOMSettableTokenList___getter___Callback_RESOLVER_STRING_1_unsigned long";
}

class BlinkDOMStringList {
  static $length_Getter(mthis) native "DOMStringList_length_Getter";

  static $NativeIndexed_Getter(mthis, index) native "DOMStringList_item_Callback_RESOLVER_STRING_1_unsigned long";

  static $contains_Callback(mthis, string) native "DOMStringList_contains_Callback_RESOLVER_STRING_1_DOMString";

  static $item_Callback(mthis, index) native "DOMStringList_item_Callback_RESOLVER_STRING_1_unsigned long";
}

class BlinkDOMStringMap {
  // Generated overload resolver
  static $__delete__(mthis, index_OR_name) {
    if ((index_OR_name is int || index_OR_name == null)) {
      return $___delete___1_Callback(mthis, index_OR_name);
    }
    if ((index_OR_name is String || index_OR_name == null)) {
      return $___delete___2_Callback(mthis, index_OR_name);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  static $___delete___1_Callback(mthis, index_OR_name) native "DOMStringMap___delete___Callback_RESOLVER_STRING_1_unsigned long";

  static $___delete___2_Callback(mthis, index_OR_name) native "DOMStringMap___delete___Callback_RESOLVER_STRING_1_DOMString";

  // Generated overload resolver
  static $__getter__(mthis, index_OR_name) {
    if ((index_OR_name is int || index_OR_name == null)) {
      return $___getter___1_Callback(mthis, index_OR_name);
    }
    if ((index_OR_name is String || index_OR_name == null)) {
      return $___getter___2_Callback(mthis, index_OR_name);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  static $___getter___1_Callback(mthis, index_OR_name) native "DOMStringMap___getter___Callback_RESOLVER_STRING_1_unsigned long";

  static $___getter___2_Callback(mthis, index_OR_name) native "DOMStringMap___getter___Callback_RESOLVER_STRING_1_DOMString";

  // Generated overload resolver
  static $__setter__(mthis, index_OR_name, value) {
    if ((value is String || value == null) && (index_OR_name is int || index_OR_name == null)) {
      $___setter___1_Callback(mthis, index_OR_name, value);
      return;
    }
    if ((value is String || value == null) && (index_OR_name is String || index_OR_name == null)) {
      $___setter___2_Callback(mthis, index_OR_name, value);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  static $___setter___1_Callback(mthis, index_OR_name, value) native "DOMStringMap___setter___Callback_RESOLVER_STRING_2_unsigned long_DOMString";

  static $___setter___2_Callback(mthis, index_OR_name, value) native "DOMStringMap___setter___Callback_RESOLVER_STRING_2_DOMString_DOMString";
}

class BlinkDataTransferItem {
  static $kind_Getter(mthis) native "DataTransferItem_kind_Getter";

  static $type_Getter(mthis) native "DataTransferItem_type_Getter";

  static $getAsFile_Callback(mthis) native "DataTransferItem_getAsFile_Callback_RESOLVER_STRING_0_";

  static $getAsString_Callback(mthis, callback) native "DataTransferItem_getAsString_Callback_RESOLVER_STRING_1_StringCallback";

  static $webkitGetAsEntry_Callback(mthis) native "DataTransferItem_webkitGetAsEntry_Callback_RESOLVER_STRING_0_";
}

class BlinkDataTransferItemList {
  static $length_Getter(mthis) native "DataTransferItemList_length_Getter";

  static $__getter___Callback(mthis, index) native "DataTransferItemList___getter___Callback_RESOLVER_STRING_1_unsigned long";

  // Generated overload resolver
  static $add(mthis, data_OR_file, type) {
    if ((data_OR_file is File || data_OR_file == null) && type == null) {
      return $_add_1_Callback(mthis, data_OR_file);
    }
    if ((type is String || type == null) && (data_OR_file is String || data_OR_file == null)) {
      return $_add_2_Callback(mthis, data_OR_file, type);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  static $_add_1_Callback(mthis, data_OR_file) native "DataTransferItemList_add_Callback_RESOLVER_STRING_1_File";

  static $_add_2_Callback(mthis, data_OR_file, type) native "DataTransferItemList_add_Callback_RESOLVER_STRING_2_DOMString_DOMString";

  static $addData_Callback(mthis, data, type) native "DataTransferItemList_add_Callback_RESOLVER_STRING_2_DOMString_DOMString";

  static $addFile_Callback(mthis, file) native "DataTransferItemList_add_Callback_RESOLVER_STRING_1_File";

  static $clear_Callback(mthis) native "DataTransferItemList_clear_Callback_RESOLVER_STRING_0_";

  static $remove_Callback(mthis, index) native "DataTransferItemList_remove_Callback_RESOLVER_STRING_1_unsigned long";
}

class BlinkDatabase {
  static $version_Getter(mthis) native "Database_version_Getter";

  static $changeVersion_Callback(mthis, oldVersion, newVersion, callback, errorCallback, successCallback) native "Database_changeVersion_Callback_RESOLVER_STRING_5_DOMString_DOMString_SQLTransactionCallback_SQLTransactionErrorCallback_VoidCallback";

  static $readTransaction_Callback(mthis, callback, errorCallback, successCallback) native "Database_readTransaction_Callback_RESOLVER_STRING_3_SQLTransactionCallback_SQLTransactionErrorCallback_VoidCallback";

  static $transaction_Callback(mthis, callback, errorCallback, successCallback) native "Database_transaction_Callback_RESOLVER_STRING_3_SQLTransactionCallback_SQLTransactionErrorCallback_VoidCallback";
}

class BlinkDatabaseSync {}

class BlinkWindowBase64 {
  static $atob_Callback(mthis, string) native "WindowBase64_atob_Callback_RESOLVER_STRING_1_DOMString";

  static $btoa_Callback(mthis, string) native "WindowBase64_btoa_Callback_RESOLVER_STRING_1_DOMString";
}

class BlinkWindowTimers {
  static $clearInterval_Callback(mthis, handle) native "WindowTimers_clearInterval_Callback_RESOLVER_STRING_1_long";

  static $clearTimeout_Callback(mthis, handle) native "WindowTimers_clearTimeout_Callback_RESOLVER_STRING_1_long";

  static $setInterval_Callback(mthis, handler, timeout) native "WindowTimers_setInterval_Callback";

  static $setTimeout_Callback(mthis, handler, timeout) native "WindowTimers_setTimeout_Callback";
}

class BlinkWorkerGlobalScope {
  static $console_Getter(mthis) native "WorkerGlobalScope_console_Getter";

  static $crypto_Getter(mthis) native "WorkerGlobalScope_crypto_Getter";

  static $indexedDB_Getter(mthis) native "WorkerGlobalScope_indexedDB_Getter";

  static $location_Getter(mthis) native "WorkerGlobalScope_location_Getter";

  static $navigator_Getter(mthis) native "WorkerGlobalScope_navigator_Getter";

  static $performance_Getter(mthis) native "WorkerGlobalScope_performance_Getter";

  static $self_Getter(mthis) native "WorkerGlobalScope_self_Getter";

  static $close_Callback(mthis) native "WorkerGlobalScope_close_Callback_RESOLVER_STRING_0_";

  static $openDatabase_Callback(mthis, name, version, displayName, estimatedSize, creationCallback) native "WorkerGlobalScope_openDatabase_Callback_RESOLVER_STRING_5_DOMString_DOMString_DOMString_unsigned long_DatabaseCallback";

  static $openDatabaseSync_Callback(mthis, name, version, displayName, estimatedSize, creationCallback) native "WorkerGlobalScope_openDatabaseSync_Callback_RESOLVER_STRING_5_DOMString_DOMString_DOMString_unsigned long_DatabaseCallback";

  static $webkitRequestFileSystem_Callback(mthis, type, size, successCallback, errorCallback) native "WorkerGlobalScope_webkitRequestFileSystem_Callback_RESOLVER_STRING_4_unsigned short_long long_FileSystemCallback_ErrorCallback";

  static $webkitRequestFileSystemSync_Callback(mthis, type, size) native "WorkerGlobalScope_webkitRequestFileSystemSync_Callback_RESOLVER_STRING_2_unsigned short_long long";

  static $webkitResolveLocalFileSystemSyncURL_Callback(mthis, url) native "WorkerGlobalScope_webkitResolveLocalFileSystemSyncURL_Callback_RESOLVER_STRING_1_DOMString";

  static $webkitResolveLocalFileSystemURL_Callback(mthis, url, successCallback, errorCallback) native "WorkerGlobalScope_webkitResolveLocalFileSystemURL_Callback_RESOLVER_STRING_3_DOMString_EntryCallback_ErrorCallback";

  static $atob_Callback(mthis, string) native "WorkerGlobalScope_atob_Callback_RESOLVER_STRING_1_DOMString";

  static $btoa_Callback(mthis, string) native "WorkerGlobalScope_btoa_Callback_RESOLVER_STRING_1_DOMString";

  static $clearInterval_Callback(mthis, handle) native "WorkerGlobalScope_clearInterval_Callback_RESOLVER_STRING_1_long";

  static $clearTimeout_Callback(mthis, handle) native "WorkerGlobalScope_clearTimeout_Callback_RESOLVER_STRING_1_long";

  static $setInterval_Callback(mthis, handler, timeout) native "WorkerGlobalScope_setInterval_Callback";

  static $setTimeout_Callback(mthis, handler, timeout) native "WorkerGlobalScope_setTimeout_Callback";
}

class BlinkDedicatedWorkerGlobalScope {
  static $postMessage_Callback(mthis, message, messagePorts) native "DedicatedWorkerGlobalScope_postMessage_Callback";
}

class BlinkDelayNode {
  static $delayTime_Getter(mthis) native "DelayNode_delayTime_Getter";
}

class BlinkDeprecatedStorageInfo {
  static $queryUsageAndQuota_Callback(mthis, storageType, usageCallback, errorCallback) native "DeprecatedStorageInfo_queryUsageAndQuota_Callback_RESOLVER_STRING_3_unsigned short_StorageUsageCallback_StorageErrorCallback";

  static $requestQuota_Callback(mthis, storageType, newQuotaInBytes, quotaCallback, errorCallback) native "DeprecatedStorageInfo_requestQuota_Callback_RESOLVER_STRING_4_unsigned short_unsigned long long_StorageQuotaCallback_StorageErrorCallback";
}

class BlinkDeprecatedStorageQuota {
  static $queryUsageAndQuota_Callback(mthis, usageCallback, errorCallback) native "DeprecatedStorageQuota_queryUsageAndQuota_Callback_RESOLVER_STRING_2_StorageUsageCallback_StorageErrorCallback";

  static $requestQuota_Callback(mthis, newQuotaInBytes, quotaCallback, errorCallback) native "DeprecatedStorageQuota_requestQuota_Callback_RESOLVER_STRING_3_unsigned long long_StorageQuotaCallback_StorageErrorCallback";
}

class BlinkDeviceAcceleration {
  static $x_Getter(mthis) native "DeviceAcceleration_x_Getter";

  static $y_Getter(mthis) native "DeviceAcceleration_y_Getter";

  static $z_Getter(mthis) native "DeviceAcceleration_z_Getter";
}

class BlinkDeviceMotionEvent {
  static $acceleration_Getter(mthis) native "DeviceMotionEvent_acceleration_Getter";

  static $accelerationIncludingGravity_Getter(mthis) native "DeviceMotionEvent_accelerationIncludingGravity_Getter";

  static $interval_Getter(mthis) native "DeviceMotionEvent_interval_Getter";

  static $rotationRate_Getter(mthis) native "DeviceMotionEvent_rotationRate_Getter";

  static $initDeviceMotionEvent_Callback(mthis, type, bubbles, cancelable, acceleration, accelerationIncludingGravity, rotationRate, interval) native "DeviceMotionEvent_initDeviceMotionEvent_Callback";
}

class BlinkDeviceOrientationEvent {
  static $absolute_Getter(mthis) native "DeviceOrientationEvent_absolute_Getter";

  static $alpha_Getter(mthis) native "DeviceOrientationEvent_alpha_Getter";

  static $beta_Getter(mthis) native "DeviceOrientationEvent_beta_Getter";

  static $gamma_Getter(mthis) native "DeviceOrientationEvent_gamma_Getter";

  static $initDeviceOrientationEvent_Callback(mthis, type, bubbles, cancelable, alpha, beta, gamma, absolute) native "DeviceOrientationEvent_initDeviceOrientationEvent_Callback";
}

class BlinkDeviceRotationRate {
  static $alpha_Getter(mthis) native "DeviceRotationRate_alpha_Getter";

  static $beta_Getter(mthis) native "DeviceRotationRate_beta_Getter";

  static $gamma_Getter(mthis) native "DeviceRotationRate_gamma_Getter";
}

class BlinkEntry {
  static $filesystem_Getter(mthis) native "Entry_filesystem_Getter";

  static $fullPath_Getter(mthis) native "Entry_fullPath_Getter";

  static $isDirectory_Getter(mthis) native "Entry_isDirectory_Getter";

  static $isFile_Getter(mthis) native "Entry_isFile_Getter";

  static $name_Getter(mthis) native "Entry_name_Getter";

  // Generated overload resolver
  static $_copyTo(mthis, parent, name, successCallback, errorCallback) {
    if (name != null) {
      $_copyTo_1_Callback(mthis, parent, name, successCallback, errorCallback);
      return;
    }
    $_copyTo_2_Callback(mthis, parent);
    return;
  }

  static $_copyTo_1_Callback(mthis, parent, name, successCallback, errorCallback) native "Entry_copyTo_Callback_RESOLVER_STRING_4_DirectoryEntry_DOMString_EntryCallback_ErrorCallback";

  static $_copyTo_2_Callback(mthis, parent) native "Entry_copyTo_Callback_RESOLVER_STRING_1_DirectoryEntry";

  static $getMetadata_Callback(mthis, successCallback, errorCallback) native "Entry_getMetadata_Callback_RESOLVER_STRING_2_MetadataCallback_ErrorCallback";

  static $getParent_Callback(mthis, successCallback, errorCallback) native "Entry_getParent_Callback_RESOLVER_STRING_2_EntryCallback_ErrorCallback";

  // Generated overload resolver
  static $_moveTo(mthis, parent, name, successCallback, errorCallback) {
    if (name != null) {
      $_moveTo_1_Callback(mthis, parent, name, successCallback, errorCallback);
      return;
    }
    $_moveTo_2_Callback(mthis, parent);
    return;
  }

  static $_moveTo_1_Callback(mthis, parent, name, successCallback, errorCallback) native "Entry_moveTo_Callback_RESOLVER_STRING_4_DirectoryEntry_DOMString_EntryCallback_ErrorCallback";

  static $_moveTo_2_Callback(mthis, parent) native "Entry_moveTo_Callback_RESOLVER_STRING_1_DirectoryEntry";

  static $remove_Callback(mthis, successCallback, errorCallback) native "Entry_remove_Callback_RESOLVER_STRING_2_VoidCallback_ErrorCallback";

  static $toURL_Callback(mthis) native "Entry_toURL_Callback_RESOLVER_STRING_0_";
}

class BlinkDirectoryEntry {
  static $createReader_Callback(mthis) native "DirectoryEntry_createReader_Callback_RESOLVER_STRING_0_";

  static $getDirectory_Callback(mthis, path, options, successCallback, errorCallback) native "DirectoryEntry_getDirectory_Callback_RESOLVER_STRING_4_DOMString_Dictionary_EntryCallback_ErrorCallback";

  static $getFile_Callback(mthis, path, options, successCallback, errorCallback) native "DirectoryEntry_getFile_Callback_RESOLVER_STRING_4_DOMString_Dictionary_EntryCallback_ErrorCallback";

  static $removeRecursively_Callback(mthis, successCallback, errorCallback) native "DirectoryEntry_removeRecursively_Callback_RESOLVER_STRING_2_VoidCallback_ErrorCallback";
}

class BlinkEntrySync {}

class BlinkDirectoryEntrySync {}

class BlinkDirectoryReader {
  static $readEntries_Callback(mthis, successCallback, errorCallback) native "DirectoryReader_readEntries_Callback_RESOLVER_STRING_2_EntriesCallback_ErrorCallback";
}

class BlinkDirectoryReaderSync {}

class BlinkGlobalEventHandlers {}

class BlinkParentNode {
  static $childElementCount_Getter(mthis) native "ParentNode_childElementCount_Getter";

  static $children_Getter(mthis) native "ParentNode_children_Getter";

  static $firstElementChild_Getter(mthis) native "ParentNode_firstElementChild_Getter";

  static $lastElementChild_Getter(mthis) native "ParentNode_lastElementChild_Getter";
}

class BlinkDocument {
  static $activeElement_Getter(mthis) native "Document_activeElement_Getter";

  static $body_Getter(mthis) native "Document_body_Getter";

  static $body_Setter(mthis, value) native "Document_body_Setter";

  static $cookie_Getter(mthis) native "Document_cookie_Getter";

  static $cookie_Setter(mthis, value) native "Document_cookie_Setter";

  static $currentScript_Getter(mthis) native "Document_currentScript_Getter";

  static $defaultView_Getter(mthis) native "Document_defaultView_Getter";

  static $documentElement_Getter(mthis) native "Document_documentElement_Getter";

  static $domain_Getter(mthis) native "Document_domain_Getter";

  static $fonts_Getter(mthis) native "Document_fonts_Getter";

  static $head_Getter(mthis) native "Document_head_Getter";

  static $hidden_Getter(mthis) native "Document_hidden_Getter";

  static $implementation_Getter(mthis) native "Document_implementation_Getter";

  static $lastModified_Getter(mthis) native "Document_lastModified_Getter";

  static $preferredStylesheetSet_Getter(mthis) native "Document_preferredStylesheetSet_Getter";

  static $readyState_Getter(mthis) native "Document_readyState_Getter";

  static $referrer_Getter(mthis) native "Document_referrer_Getter";

  static $rootElement_Getter(mthis) native "Document_rootElement_Getter";

  static $selectedStylesheetSet_Getter(mthis) native "Document_selectedStylesheetSet_Getter";

  static $selectedStylesheetSet_Setter(mthis, value) native "Document_selectedStylesheetSet_Setter";

  static $styleSheets_Getter(mthis) native "Document_styleSheets_Getter";

  static $timeline_Getter(mthis) native "Document_timeline_Getter";

  static $title_Getter(mthis) native "Document_title_Getter";

  static $title_Setter(mthis, value) native "Document_title_Setter";

  static $visibilityState_Getter(mthis) native "Document_visibilityState_Getter";

  static $webkitFullscreenElement_Getter(mthis) native "Document_webkitFullscreenElement_Getter";

  static $webkitFullscreenEnabled_Getter(mthis) native "Document_webkitFullscreenEnabled_Getter";

  static $webkitHidden_Getter(mthis) native "Document_webkitHidden_Getter";

  static $webkitPointerLockElement_Getter(mthis) native "Document_webkitPointerLockElement_Getter";

  static $webkitVisibilityState_Getter(mthis) native "Document_webkitVisibilityState_Getter";

  static $adoptNode_Callback(mthis, node) native "Document_adoptNode_Callback_RESOLVER_STRING_1_Node";

  static $caretRangeFromPoint_Callback(mthis, x, y) native "Document_caretRangeFromPoint_Callback_RESOLVER_STRING_2_long_long";

  static $createDocumentFragment_Callback(mthis) native "Document_createDocumentFragment_Callback_RESOLVER_STRING_0_";

  static $createElement_Callback(mthis, localName_OR_tagName, typeExtension) native "Document_createElement_Callback";

  static $createElementNS_Callback(mthis, namespaceURI, qualifiedName, typeExtension) native "Document_createElementNS_Callback";

  // Generated overload resolver
  static $_createEvent(mthis, eventType) {
    if (eventType != null) {
      return $_createEvent_1_Callback(mthis, eventType);
    }
    return $_createEvent_2_Callback(mthis);
  }

  static $_createEvent_1_Callback(mthis, eventType) native "Document_createEvent_Callback_RESOLVER_STRING_1_DOMString";

  static $_createEvent_2_Callback(mthis) native "Document_createEvent_Callback_RESOLVER_STRING_0_";

  // Generated overload resolver
  static $_createNodeIterator(mthis, root, whatToShow, filter) {
    if (filter != null) {
      return $_createNodeIterator_1_Callback(mthis, root, whatToShow, filter);
    }
    if (whatToShow != null) {
      return $_createNodeIterator_2_Callback(mthis, root, whatToShow);
    }
    return $_createNodeIterator_3_Callback(mthis, root);
  }

  static $_createNodeIterator_1_Callback(mthis, root, whatToShow, filter) native "Document_createNodeIterator_Callback_RESOLVER_STRING_3_Node_unsigned long_NodeFilter";

  static $_createNodeIterator_2_Callback(mthis, root, whatToShow) native "Document_createNodeIterator_Callback_RESOLVER_STRING_2_Node_unsigned long";

  static $_createNodeIterator_3_Callback(mthis, root) native "Document_createNodeIterator_Callback_RESOLVER_STRING_1_Node";

  static $createRange_Callback(mthis) native "Document_createRange_Callback_RESOLVER_STRING_0_";

  static $createTextNode_Callback(mthis, data) native "Document_createTextNode_Callback_RESOLVER_STRING_1_DOMString";

  static $createTouch_Callback(mthis, window, target, identifier, pageX, pageY, screenX, screenY, webkitRadiusX, webkitRadiusY, webkitRotationAngle, webkitForce) native "Document_createTouch_Callback_RESOLVER_STRING_11_Window_EventTarget_long_long_long_long_long_long_long_float_float";

  // Generated overload resolver
  static $_createTreeWalker(mthis, root, whatToShow, filter) {
    if (filter != null) {
      return $_createTreeWalker_1_Callback(mthis, root, whatToShow, filter);
    }
    if (whatToShow != null) {
      return $_createTreeWalker_2_Callback(mthis, root, whatToShow);
    }
    return $_createTreeWalker_3_Callback(mthis, root);
  }

  static $_createTreeWalker_1_Callback(mthis, root, whatToShow, filter) native "Document_createTreeWalker_Callback_RESOLVER_STRING_3_Node_unsigned long_NodeFilter";

  static $_createTreeWalker_2_Callback(mthis, root, whatToShow) native "Document_createTreeWalker_Callback_RESOLVER_STRING_2_Node_unsigned long";

  static $_createTreeWalker_3_Callback(mthis, root) native "Document_createTreeWalker_Callback_RESOLVER_STRING_1_Node";

  static $elementFromPoint_Callback(mthis, x, y) native "Document_elementFromPoint_Callback_RESOLVER_STRING_2_long_long";

  static $execCommand_Callback(mthis, command, userInterface, value) native "Document_execCommand_Callback_RESOLVER_STRING_3_DOMString_boolean_DOMString";

  static $getCSSCanvasContext_Callback(mthis, contextId, name, width, height) native "Document_getCSSCanvasContext_Callback_RESOLVER_STRING_4_DOMString_DOMString_long_long";

  static $getElementById_Callback(mthis, elementId) native "Document_getElementById_Callback_RESOLVER_STRING_1_DOMString";

  static $getElementsByClassName_Callback(mthis, classNames) native "Document_getElementsByClassName_Callback_RESOLVER_STRING_1_DOMString";

  static $getElementsByName_Callback(mthis, elementName) native "Document_getElementsByName_Callback_RESOLVER_STRING_1_DOMString";

  static $getElementsByTagName_Callback(mthis, localName) native "Document_getElementsByTagName_Callback_RESOLVER_STRING_1_DOMString";

  // Generated overload resolver
  static $importNode(mthis, node, deep) {
    if (deep != null) {
      return $_importNode_1_Callback(mthis, node, deep);
    }
    return $_importNode_2_Callback(mthis, node);
  }

  static $_importNode_1_Callback(mthis, node, deep) native "Document_importNode_Callback_RESOLVER_STRING_2_Node_boolean";

  static $_importNode_2_Callback(mthis, node) native "Document_importNode_Callback_RESOLVER_STRING_1_Node";

  static $queryCommandEnabled_Callback(mthis, command) native "Document_queryCommandEnabled_Callback_RESOLVER_STRING_1_DOMString";

  static $queryCommandIndeterm_Callback(mthis, command) native "Document_queryCommandIndeterm_Callback_RESOLVER_STRING_1_DOMString";

  static $queryCommandState_Callback(mthis, command) native "Document_queryCommandState_Callback_RESOLVER_STRING_1_DOMString";

  static $queryCommandSupported_Callback(mthis, command) native "Document_queryCommandSupported_Callback_RESOLVER_STRING_1_DOMString";

  static $queryCommandValue_Callback(mthis, command) native "Document_queryCommandValue_Callback_RESOLVER_STRING_1_DOMString";

  static $querySelector_Callback(mthis, selectors) native "Document_querySelector_Callback_RESOLVER_STRING_1_DOMString";

  static $querySelectorAll_Callback(mthis, selectors) native "Document_querySelectorAll_Callback_RESOLVER_STRING_1_DOMString";

  static $webkitExitFullscreen_Callback(mthis) native "Document_webkitExitFullscreen_Callback_RESOLVER_STRING_0_";

  static $webkitExitPointerLock_Callback(mthis) native "Document_webkitExitPointerLock_Callback_RESOLVER_STRING_0_";

  static $childElementCount_Getter(mthis) native "Document_childElementCount_Getter";

  static $children_Getter(mthis) native "Document_children_Getter";

  static $firstElementChild_Getter(mthis) native "Document_firstElementChild_Getter";

  static $lastElementChild_Getter(mthis) native "Document_lastElementChild_Getter";
}

class BlinkDocumentFragment {
  static $querySelector_Callback(mthis, selectors) native "DocumentFragment_querySelector_Callback_RESOLVER_STRING_1_DOMString";

  static $querySelectorAll_Callback(mthis, selectors) native "DocumentFragment_querySelectorAll_Callback_RESOLVER_STRING_1_DOMString";

  static $childElementCount_Getter(mthis) native "DocumentFragment_childElementCount_Getter";

  static $firstElementChild_Getter(mthis) native "DocumentFragment_firstElementChild_Getter";

  static $lastElementChild_Getter(mthis) native "DocumentFragment_lastElementChild_Getter";
}

class BlinkDocumentType {}

class BlinkDynamicsCompressorNode {
  static $attack_Getter(mthis) native "DynamicsCompressorNode_attack_Getter";

  static $knee_Getter(mthis) native "DynamicsCompressorNode_knee_Getter";

  static $ratio_Getter(mthis) native "DynamicsCompressorNode_ratio_Getter";

  static $reduction_Getter(mthis) native "DynamicsCompressorNode_reduction_Getter";

  static $release_Getter(mthis) native "DynamicsCompressorNode_release_Getter";

  static $threshold_Getter(mthis) native "DynamicsCompressorNode_threshold_Getter";
}

class BlinkEXTFragDepth {}

class BlinkEXTTextureFilterAnisotropic {}

class BlinkElement {
  static $attributes_Getter(mthis) native "Element_attributes_Getter";

  static $className_Getter(mthis) native "Element_className_Getter";

  static $className_Setter(mthis, value) native "Element_className_Setter";

  static $clientHeight_Getter(mthis) native "Element_clientHeight_Getter";

  static $clientLeft_Getter(mthis) native "Element_clientLeft_Getter";

  static $clientTop_Getter(mthis) native "Element_clientTop_Getter";

  static $clientWidth_Getter(mthis) native "Element_clientWidth_Getter";

  static $id_Getter(mthis) native "Element_id_Getter";

  static $id_Setter(mthis, value) native "Element_id_Setter";

  static $innerHTML_Getter(mthis) native "Element_innerHTML_Getter";

  static $innerHTML_Setter(mthis, value) native "Element_innerHTML_Setter";

  static $localName_Getter(mthis) native "Element_localName_Getter";

  static $namespaceURI_Getter(mthis) native "Element_namespaceURI_Getter";

  static $offsetHeight_Getter(mthis) native "Element_offsetHeight_Getter";

  static $offsetLeft_Getter(mthis) native "Element_offsetLeft_Getter";

  static $offsetParent_Getter(mthis) native "Element_offsetParent_Getter";

  static $offsetTop_Getter(mthis) native "Element_offsetTop_Getter";

  static $offsetWidth_Getter(mthis) native "Element_offsetWidth_Getter";

  static $outerHTML_Getter(mthis) native "Element_outerHTML_Getter";

  static $scrollHeight_Getter(mthis) native "Element_scrollHeight_Getter";

  static $scrollLeft_Getter(mthis) native "Element_scrollLeft_Getter";

  static $scrollLeft_Setter(mthis, value) native "Element_scrollLeft_Setter";

  static $scrollTop_Getter(mthis) native "Element_scrollTop_Getter";

  static $scrollTop_Setter(mthis, value) native "Element_scrollTop_Setter";

  static $scrollWidth_Getter(mthis) native "Element_scrollWidth_Getter";

  static $shadowRoot_Getter(mthis) native "Element_shadowRoot_Getter";

  static $style_Getter(mthis) native "Element_style_Getter";

  static $tagName_Getter(mthis) native "Element_tagName_Getter";

  // Generated overload resolver
  static $animate(mthis, keyframes, timingInput) {
    if ((timingInput is Map || timingInput == null) && (keyframes is List<Map> || keyframes == null)) {
      return $_animate_1_Callback(mthis, keyframes, timingInput);
    }
    if ((timingInput is num || timingInput == null) && (keyframes is List<Map> || keyframes == null)) {
      return $_animate_2_Callback(mthis, keyframes, timingInput);
    }
    if ((keyframes is List<Map> || keyframes == null) && timingInput == null) {
      return $_animate_3_Callback(mthis, keyframes);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  static $_animate_1_Callback(mthis, keyframes, timingInput) native "Element_animate_Callback_RESOLVER_STRING_2_sequence<Dictionary>_Dictionary";

  static $_animate_2_Callback(mthis, keyframes, timingInput) native "Element_animate_Callback_RESOLVER_STRING_2_sequence<Dictionary>_double";

  static $_animate_3_Callback(mthis, keyframes) native "Element_animate_Callback_RESOLVER_STRING_1_sequence<Dictionary>";

  static $blur_Callback(mthis) native "Element_blur_Callback_RESOLVER_STRING_0_";

  static $createShadowRoot_Callback(mthis) native "Element_createShadowRoot_Callback_RESOLVER_STRING_0_";

  static $focus_Callback(mthis) native "Element_focus_Callback_RESOLVER_STRING_0_";

  static $getAttribute_Callback(mthis, name) native "Element_getAttribute_Callback_RESOLVER_STRING_1_DOMString";

  static $getAttributeNS_Callback(mthis, namespaceURI, localName) native "Element_getAttributeNS_Callback_RESOLVER_STRING_2_DOMString_DOMString";

  static $getBoundingClientRect_Callback(mthis) native "Element_getBoundingClientRect_Callback_RESOLVER_STRING_0_";

  static $getClientRects_Callback(mthis) native "Element_getClientRects_Callback_RESOLVER_STRING_0_";

  static $getDestinationInsertionPoints_Callback(mthis) native "Element_getDestinationInsertionPoints_Callback_RESOLVER_STRING_0_";

  static $getElementsByClassName_Callback(mthis, classNames) native "Element_getElementsByClassName_Callback_RESOLVER_STRING_1_DOMString";

  static $getElementsByTagName_Callback(mthis, name) native "Element_getElementsByTagName_Callback_RESOLVER_STRING_1_DOMString";

  static $hasAttribute_Callback(mthis, name) native "Element_hasAttribute_Callback_RESOLVER_STRING_1_DOMString";

  static $hasAttributeNS_Callback(mthis, namespaceURI, localName) native "Element_hasAttributeNS_Callback_RESOLVER_STRING_2_DOMString_DOMString";

  static $insertAdjacentElement_Callback(mthis, where, element) native "Element_insertAdjacentElement_Callback_RESOLVER_STRING_2_DOMString_Element";

  static $insertAdjacentHTML_Callback(mthis, where, html) native "Element_insertAdjacentHTML_Callback_RESOLVER_STRING_2_DOMString_DOMString";

  static $insertAdjacentText_Callback(mthis, where, text) native "Element_insertAdjacentText_Callback_RESOLVER_STRING_2_DOMString_DOMString";

  static $matches_Callback(mthis, selectors) native "Element_matches_Callback_RESOLVER_STRING_1_DOMString";

  static $querySelector_Callback(mthis, selectors) native "Element_querySelector_Callback_RESOLVER_STRING_1_DOMString";

  static $querySelectorAll_Callback(mthis, selectors) native "Element_querySelectorAll_Callback_RESOLVER_STRING_1_DOMString";

  static $removeAttribute_Callback(mthis, name) native "Element_removeAttribute_Callback_RESOLVER_STRING_1_DOMString";

  static $removeAttributeNS_Callback(mthis, namespaceURI, localName) native "Element_removeAttributeNS_Callback_RESOLVER_STRING_2_DOMString_DOMString";

  static $scrollByLines_Callback(mthis, lines) native "Element_scrollByLines_Callback_RESOLVER_STRING_1_long";

  static $scrollByPages_Callback(mthis, pages) native "Element_scrollByPages_Callback_RESOLVER_STRING_1_long";

  // Generated overload resolver
  static $_scrollIntoView(mthis, alignWithTop) {
    if (alignWithTop != null) {
      $_scrollIntoView_1_Callback(mthis, alignWithTop);
      return;
    }
    $_scrollIntoView_2_Callback(mthis);
    return;
  }

  static $_scrollIntoView_1_Callback(mthis, alignWithTop) native "Element_scrollIntoView_Callback_RESOLVER_STRING_1_boolean";

  static $_scrollIntoView_2_Callback(mthis) native "Element_scrollIntoView_Callback_RESOLVER_STRING_0_";

  // Generated overload resolver
  static $_scrollIntoViewIfNeeded(mthis, centerIfNeeded) {
    if (centerIfNeeded != null) {
      $_scrollIntoViewIfNeeded_1_Callback(mthis, centerIfNeeded);
      return;
    }
    $_scrollIntoViewIfNeeded_2_Callback(mthis);
    return;
  }

  static $_scrollIntoViewIfNeeded_1_Callback(mthis, centerIfNeeded) native "Element_scrollIntoViewIfNeeded_Callback_RESOLVER_STRING_1_boolean";

  static $_scrollIntoViewIfNeeded_2_Callback(mthis) native "Element_scrollIntoViewIfNeeded_Callback_RESOLVER_STRING_0_";

  static $setAttribute_Callback(mthis, name, value) native "Element_setAttribute_Callback_RESOLVER_STRING_2_DOMString_DOMString";

  static $setAttributeNS_Callback(mthis, namespaceURI, qualifiedName, value) native "Element_setAttributeNS_Callback_RESOLVER_STRING_3_DOMString_DOMString_DOMString";

  static $webkitRequestFullscreen_Callback(mthis) native "Element_webkitRequestFullscreen_Callback_RESOLVER_STRING_0_";

  static $webkitRequestPointerLock_Callback(mthis) native "Element_webkitRequestPointerLock_Callback_RESOLVER_STRING_0_";

  static $nextElementSibling_Getter(mthis) native "Element_nextElementSibling_Getter";

  static $previousElementSibling_Getter(mthis) native "Element_previousElementSibling_Getter";

  static $remove_Callback(mthis) native "Element_remove_Callback_RESOLVER_STRING_0_";

  static $childElementCount_Getter(mthis) native "Element_childElementCount_Getter";

  static $children_Getter(mthis) native "Element_children_Getter";

  static $firstElementChild_Getter(mthis) native "Element_firstElementChild_Getter";

  static $lastElementChild_Getter(mthis) native "Element_lastElementChild_Getter";
}

class BlinkErrorEvent {
  static $colno_Getter(mthis) native "ErrorEvent_colno_Getter";

  static $error_Getter(mthis) native "ErrorEvent_error_Getter";

  static $filename_Getter(mthis) native "ErrorEvent_filename_Getter";

  static $lineno_Getter(mthis) native "ErrorEvent_lineno_Getter";

  static $message_Getter(mthis) native "ErrorEvent_message_Getter";
}

class BlinkEventSource {
  // Generated overload resolver
  static $mkEventSource(url, eventSourceInit) {
    return $_create_1constructorCallback(url, eventSourceInit);
  }

  static $_create_1constructorCallback(url, eventSourceInit) native "EventSource_constructorCallback_RESOLVER_STRING_2_DOMString_Dictionary";

  static $readyState_Getter(mthis) native "EventSource_readyState_Getter";

  static $url_Getter(mthis) native "EventSource_url_Getter";

  static $withCredentials_Getter(mthis) native "EventSource_withCredentials_Getter";

  static $close_Callback(mthis) native "EventSource_close_Callback_RESOLVER_STRING_0_";
}

class BlinkFile {
  static $lastModified_Getter(mthis) native "File_lastModified_Getter";

  static $lastModifiedDate_Getter(mthis) native "File_lastModifiedDate_Getter";

  static $name_Getter(mthis) native "File_name_Getter";

  static $webkitRelativePath_Getter(mthis) native "File_webkitRelativePath_Getter";
}

class BlinkFileEntry {
  static $createWriter_Callback(mthis, successCallback, errorCallback) native "FileEntry_createWriter_Callback_RESOLVER_STRING_2_FileWriterCallback_ErrorCallback";

  static $file_Callback(mthis, successCallback, errorCallback) native "FileEntry_file_Callback_RESOLVER_STRING_2_FileCallback_ErrorCallback";
}

class BlinkFileEntrySync {}

class BlinkFileError {
  static $code_Getter(mthis) native "FileError_code_Getter";
}

class BlinkFileList {
  static $length_Getter(mthis) native "FileList_length_Getter";

  static $NativeIndexed_Getter(mthis, index) native "FileList_item_Callback_RESOLVER_STRING_1_unsigned long";

  static $item_Callback(mthis, index) native "FileList_item_Callback_RESOLVER_STRING_1_unsigned long";
}

class BlinkFileReader {
  // Generated overload resolver
  static $mkFileReader() {
    return $_create_1constructorCallback();
  }

  static $_create_1constructorCallback() native "FileReader_constructorCallback_RESOLVER_STRING_0_";

  static $error_Getter(mthis) native "FileReader_error_Getter";

  static $readyState_Getter(mthis) native "FileReader_readyState_Getter";

  static $result_Getter(mthis) native "FileReader_result_Getter";

  static $abort_Callback(mthis) native "FileReader_abort_Callback_RESOLVER_STRING_0_";

  static $readAsArrayBuffer_Callback(mthis, blob) native "FileReader_readAsArrayBuffer_Callback_RESOLVER_STRING_1_Blob";

  static $readAsDataURL_Callback(mthis, blob) native "FileReader_readAsDataURL_Callback_RESOLVER_STRING_1_Blob";

  // Generated overload resolver
  static $readAsText(mthis, blob, encoding) {
    if (encoding != null) {
      $_readAsText_1_Callback(mthis, blob, encoding);
      return;
    }
    $_readAsText_2_Callback(mthis, blob);
    return;
  }

  static $_readAsText_1_Callback(mthis, blob, encoding) native "FileReader_readAsText_Callback_RESOLVER_STRING_2_Blob_DOMString";

  static $_readAsText_2_Callback(mthis, blob) native "FileReader_readAsText_Callback_RESOLVER_STRING_1_Blob";
}

class BlinkFileReaderSync {
  // Generated overload resolver
  static $mk_FileReaderSync() {
    return $_create_1constructorCallback();
  }

  static $_create_1constructorCallback() native "FileReaderSync_constructorCallback_RESOLVER_STRING_0_";
}

class BlinkFileWriter {
  static $error_Getter(mthis) native "FileWriter_error_Getter";

  static $length_Getter(mthis) native "FileWriter_length_Getter";

  static $position_Getter(mthis) native "FileWriter_position_Getter";

  static $readyState_Getter(mthis) native "FileWriter_readyState_Getter";

  static $abort_Callback(mthis) native "FileWriter_abort_Callback_RESOLVER_STRING_0_";

  static $seek_Callback(mthis, position) native "FileWriter_seek_Callback_RESOLVER_STRING_1_long long";

  static $truncate_Callback(mthis, size) native "FileWriter_truncate_Callback_RESOLVER_STRING_1_long long";

  static $write_Callback(mthis, data) native "FileWriter_write_Callback_RESOLVER_STRING_1_Blob";
}

class BlinkFileWriterSync {}

class BlinkFocusEvent {
  static $relatedTarget_Getter(mthis) native "FocusEvent_relatedTarget_Getter";
}

class BlinkFontFace {
  // Generated overload resolver
  static $mkFontFace(family, source, descriptors) {
    return $_create_1constructorCallback(family, source, descriptors);
  }

  static $_create_1constructorCallback(family, source, descriptors) native "FontFace_constructorCallback_RESOLVER_STRING_3_DOMString_DOMString_Dictionary";

  static $family_Getter(mthis) native "FontFace_family_Getter";

  static $family_Setter(mthis, value) native "FontFace_family_Setter";

  static $featureSettings_Getter(mthis) native "FontFace_featureSettings_Getter";

  static $featureSettings_Setter(mthis, value) native "FontFace_featureSettings_Setter";

  static $status_Getter(mthis) native "FontFace_status_Getter";

  static $stretch_Getter(mthis) native "FontFace_stretch_Getter";

  static $stretch_Setter(mthis, value) native "FontFace_stretch_Setter";

  static $style_Getter(mthis) native "FontFace_style_Getter";

  static $style_Setter(mthis, value) native "FontFace_style_Setter";

  static $unicodeRange_Getter(mthis) native "FontFace_unicodeRange_Getter";

  static $unicodeRange_Setter(mthis, value) native "FontFace_unicodeRange_Setter";

  static $variant_Getter(mthis) native "FontFace_variant_Getter";

  static $variant_Setter(mthis, value) native "FontFace_variant_Setter";

  static $weight_Getter(mthis) native "FontFace_weight_Getter";

  static $weight_Setter(mthis, value) native "FontFace_weight_Setter";

  static $load_Callback(mthis) native "FontFace_load_Callback_RESOLVER_STRING_0_";
}

class BlinkFontFaceSet {
  static $size_Getter(mthis) native "FontFaceSet_size_Getter";

  static $status_Getter(mthis) native "FontFaceSet_status_Getter";

  static $add_Callback(mthis, fontFace) native "FontFaceSet_add_Callback_RESOLVER_STRING_1_FontFace";

  static $check_Callback(mthis, font, text) native "FontFaceSet_check_Callback_RESOLVER_STRING_2_DOMString_DOMString";

  static $clear_Callback(mthis) native "FontFaceSet_clear_Callback_RESOLVER_STRING_0_";

  static $delete_Callback(mthis, fontFace) native "FontFaceSet_delete_Callback_RESOLVER_STRING_1_FontFace";

  // Generated overload resolver
  static $forEach(mthis, callback, thisArg) {
    if (thisArg != null) {
      $_forEach_1_Callback(mthis, callback, thisArg);
      return;
    }
    $_forEach_2_Callback(mthis, callback);
    return;
  }

  static $_forEach_1_Callback(mthis, callback, thisArg) native "FontFaceSet_forEach_Callback_RESOLVER_STRING_2_FontFaceSetForEachCallback_ScriptValue";

  static $_forEach_2_Callback(mthis, callback) native "FontFaceSet_forEach_Callback_RESOLVER_STRING_1_FontFaceSetForEachCallback";

  static $has_Callback(mthis, fontFace) native "FontFaceSet_has_Callback_RESOLVER_STRING_1_FontFace";
}

class BlinkFormData {
  static $constructorCallback(form) native "FormData_constructorCallback_RESOLVER_STRING_1_HTMLFormElement";

  static $append_Callback(mthis, name, value) native "FormData_append_Callback";

  static $appendBlob_Callback(mthis, name, value, filename) native "FormData_append_Callback";
}

class BlinkGainNode {
  static $gain_Getter(mthis) native "GainNode_gain_Getter";
}

class BlinkGamepad {
  static $axes_Getter(mthis) native "Gamepad_axes_Getter";

  static $buttons_Getter(mthis) native "WebKitGamepad_buttons_Getter";

  static $id_Getter(mthis) native "Gamepad_id_Getter";

  static $index_Getter(mthis) native "Gamepad_index_Getter";

  static $timestamp_Getter(mthis) native "Gamepad_timestamp_Getter";
}

class BlinkGamepadList {
  static $length_Getter(mthis) native "GamepadList_length_Getter";

  static $NativeIndexed_Getter(mthis, index) native "GamepadList_item_Callback_RESOLVER_STRING_1_unsigned long";

  static $item_Callback(mthis, index) native "GamepadList_item_Callback_RESOLVER_STRING_1_unsigned long";
}

class BlinkGeolocation {
  static $clearWatch_Callback(mthis, watchID) native "Geolocation_clearWatch_Callback_RESOLVER_STRING_1_long";

  static $getCurrentPosition_Callback(mthis, successCallback, errorCallback, options) native "Geolocation_getCurrentPosition_Callback";

  static $watchPosition_Callback(mthis, successCallback, errorCallback, options) native "Geolocation_watchPosition_Callback";
}

class BlinkGeoposition {
  static $coords_Getter(mthis) native "Geoposition_coords_Getter";

  static $timestamp_Getter(mthis) native "Geoposition_timestamp_Getter";
}

class BlinkHTMLAllCollection {
  static $item_Callback(mthis, index) native "HTMLAllCollection_item_Callback";
}

class BlinkHTMLElement {
  static $contentEditable_Getter(mthis) native "HTMLElement_contentEditable_Getter";

  static $contentEditable_Setter(mthis, value) native "HTMLElement_contentEditable_Setter";

  static $dir_Getter(mthis) native "HTMLElement_dir_Getter";

  static $dir_Setter(mthis, value) native "HTMLElement_dir_Setter";

  static $draggable_Getter(mthis) native "HTMLElement_draggable_Getter";

  static $draggable_Setter(mthis, value) native "HTMLElement_draggable_Setter";

  static $hidden_Getter(mthis) native "HTMLElement_hidden_Getter";

  static $hidden_Setter(mthis, value) native "HTMLElement_hidden_Setter";

  static $inputMethodContext_Getter(mthis) native "HTMLElement_inputMethodContext_Getter";

  static $isContentEditable_Getter(mthis) native "HTMLElement_isContentEditable_Getter";

  static $lang_Getter(mthis) native "HTMLElement_lang_Getter";

  static $lang_Setter(mthis, value) native "HTMLElement_lang_Setter";

  static $spellcheck_Getter(mthis) native "HTMLElement_spellcheck_Getter";

  static $spellcheck_Setter(mthis, value) native "HTMLElement_spellcheck_Setter";

  static $tabIndex_Getter(mthis) native "HTMLElement_tabIndex_Getter";

  static $tabIndex_Setter(mthis, value) native "HTMLElement_tabIndex_Setter";

  static $title_Getter(mthis) native "HTMLElement_title_Getter";

  static $title_Setter(mthis, value) native "HTMLElement_title_Setter";

  static $translate_Getter(mthis) native "HTMLElement_translate_Getter";

  static $translate_Setter(mthis, value) native "HTMLElement_translate_Setter";

  static $webkitdropzone_Getter(mthis) native "HTMLElement_webkitdropzone_Getter";

  static $webkitdropzone_Setter(mthis, value) native "HTMLElement_webkitdropzone_Setter";

  static $click_Callback(mthis) native "HTMLElement_click_Callback_RESOLVER_STRING_0_";
}

class BlinkURLUtils {
  static $hash_Getter(mthis) native "URL_hash_Getter";

  static $hash_Setter(mthis, value) native "URL_hash_Setter";

  static $host_Getter(mthis) native "URL_host_Getter";

  static $host_Setter(mthis, value) native "URL_host_Setter";

  static $hostname_Getter(mthis) native "URL_hostname_Getter";

  static $hostname_Setter(mthis, value) native "URL_hostname_Setter";

  static $href_Getter(mthis) native "URL_href_Getter";

  static $href_Setter(mthis, value) native "URL_href_Setter";

  static $origin_Getter(mthis) native "URL_origin_Getter";

  static $password_Getter(mthis) native "URL_password_Getter";

  static $password_Setter(mthis, value) native "URL_password_Setter";

  static $pathname_Getter(mthis) native "URL_pathname_Getter";

  static $pathname_Setter(mthis, value) native "URL_pathname_Setter";

  static $port_Getter(mthis) native "URL_port_Getter";

  static $port_Setter(mthis, value) native "URL_port_Setter";

  static $protocol_Getter(mthis) native "URL_protocol_Getter";

  static $protocol_Setter(mthis, value) native "URL_protocol_Setter";

  static $search_Getter(mthis) native "URL_search_Getter";

  static $search_Setter(mthis, value) native "URL_search_Setter";

  static $username_Getter(mthis) native "URL_username_Getter";

  static $username_Setter(mthis, value) native "URL_username_Setter";

  static $toString_Callback(mthis) native "URL_toString_Callback_RESOLVER_STRING_0_";
}

class BlinkHTMLAnchorElement {
  static $download_Getter(mthis) native "HTMLAnchorElement_download_Getter";

  static $download_Setter(mthis, value) native "HTMLAnchorElement_download_Setter";

  static $hreflang_Getter(mthis) native "HTMLAnchorElement_hreflang_Getter";

  static $hreflang_Setter(mthis, value) native "HTMLAnchorElement_hreflang_Setter";

  static $rel_Getter(mthis) native "HTMLAnchorElement_rel_Getter";

  static $rel_Setter(mthis, value) native "HTMLAnchorElement_rel_Setter";

  static $target_Getter(mthis) native "HTMLAnchorElement_target_Getter";

  static $target_Setter(mthis, value) native "HTMLAnchorElement_target_Setter";

  static $type_Getter(mthis) native "HTMLAnchorElement_type_Getter";

  static $type_Setter(mthis, value) native "HTMLAnchorElement_type_Setter";

  static $hash_Getter(mthis) native "HTMLAnchorElement_hash_Getter";

  static $hash_Setter(mthis, value) native "HTMLAnchorElement_hash_Setter";

  static $host_Getter(mthis) native "HTMLAnchorElement_host_Getter";

  static $host_Setter(mthis, value) native "HTMLAnchorElement_host_Setter";

  static $hostname_Getter(mthis) native "HTMLAnchorElement_hostname_Getter";

  static $hostname_Setter(mthis, value) native "HTMLAnchorElement_hostname_Setter";

  static $href_Getter(mthis) native "HTMLAnchorElement_href_Getter";

  static $href_Setter(mthis, value) native "HTMLAnchorElement_href_Setter";

  static $origin_Getter(mthis) native "HTMLAnchorElement_origin_Getter";

  static $password_Getter(mthis) native "HTMLAnchorElement_password_Getter";

  static $password_Setter(mthis, value) native "HTMLAnchorElement_password_Setter";

  static $pathname_Getter(mthis) native "HTMLAnchorElement_pathname_Getter";

  static $pathname_Setter(mthis, value) native "HTMLAnchorElement_pathname_Setter";

  static $port_Getter(mthis) native "HTMLAnchorElement_port_Getter";

  static $port_Setter(mthis, value) native "HTMLAnchorElement_port_Setter";

  static $protocol_Getter(mthis) native "HTMLAnchorElement_protocol_Getter";

  static $protocol_Setter(mthis, value) native "HTMLAnchorElement_protocol_Setter";

  static $search_Getter(mthis) native "HTMLAnchorElement_search_Getter";

  static $search_Setter(mthis, value) native "HTMLAnchorElement_search_Setter";

  static $username_Getter(mthis) native "HTMLAnchorElement_username_Getter";

  static $username_Setter(mthis, value) native "HTMLAnchorElement_username_Setter";

  static $toString_Callback(mthis) native "HTMLAnchorElement_toString_Callback_RESOLVER_STRING_0_";
}

class BlinkHTMLAppletElement {}

class BlinkHTMLAreaElement {
  static $alt_Getter(mthis) native "HTMLAreaElement_alt_Getter";

  static $alt_Setter(mthis, value) native "HTMLAreaElement_alt_Setter";

  static $coords_Getter(mthis) native "HTMLAreaElement_coords_Getter";

  static $coords_Setter(mthis, value) native "HTMLAreaElement_coords_Setter";

  static $shape_Getter(mthis) native "HTMLAreaElement_shape_Getter";

  static $shape_Setter(mthis, value) native "HTMLAreaElement_shape_Setter";

  static $target_Getter(mthis) native "HTMLAreaElement_target_Getter";

  static $target_Setter(mthis, value) native "HTMLAreaElement_target_Setter";

  static $hash_Getter(mthis) native "HTMLAreaElement_hash_Getter";

  static $hash_Setter(mthis, value) native "HTMLAreaElement_hash_Setter";

  static $host_Getter(mthis) native "HTMLAreaElement_host_Getter";

  static $host_Setter(mthis, value) native "HTMLAreaElement_host_Setter";

  static $hostname_Getter(mthis) native "HTMLAreaElement_hostname_Getter";

  static $hostname_Setter(mthis, value) native "HTMLAreaElement_hostname_Setter";

  static $href_Getter(mthis) native "HTMLAreaElement_href_Getter";

  static $href_Setter(mthis, value) native "HTMLAreaElement_href_Setter";

  static $origin_Getter(mthis) native "HTMLAreaElement_origin_Getter";

  static $password_Getter(mthis) native "HTMLAreaElement_password_Getter";

  static $password_Setter(mthis, value) native "HTMLAreaElement_password_Setter";

  static $pathname_Getter(mthis) native "HTMLAreaElement_pathname_Getter";

  static $pathname_Setter(mthis, value) native "HTMLAreaElement_pathname_Setter";

  static $port_Getter(mthis) native "HTMLAreaElement_port_Getter";

  static $port_Setter(mthis, value) native "HTMLAreaElement_port_Setter";

  static $protocol_Getter(mthis) native "HTMLAreaElement_protocol_Getter";

  static $protocol_Setter(mthis, value) native "HTMLAreaElement_protocol_Setter";

  static $search_Getter(mthis) native "HTMLAreaElement_search_Getter";

  static $search_Setter(mthis, value) native "HTMLAreaElement_search_Setter";

  static $username_Getter(mthis) native "HTMLAreaElement_username_Getter";

  static $username_Setter(mthis, value) native "HTMLAreaElement_username_Setter";

  static $toString_Callback(mthis) native "HTMLAreaElement_toString_Callback_RESOLVER_STRING_0_";
}

class BlinkHTMLMediaElement {
  static $autoplay_Getter(mthis) native "HTMLMediaElement_autoplay_Getter";

  static $autoplay_Setter(mthis, value) native "HTMLMediaElement_autoplay_Setter";

  static $buffered_Getter(mthis) native "HTMLMediaElement_buffered_Getter";

  static $controller_Getter(mthis) native "HTMLMediaElement_controller_Getter";

  static $controller_Setter(mthis, value) native "HTMLMediaElement_controller_Setter";

  static $controls_Getter(mthis) native "HTMLMediaElement_controls_Getter";

  static $controls_Setter(mthis, value) native "HTMLMediaElement_controls_Setter";

  static $crossOrigin_Getter(mthis) native "HTMLMediaElement_crossOrigin_Getter";

  static $crossOrigin_Setter(mthis, value) native "HTMLMediaElement_crossOrigin_Setter";

  static $currentSrc_Getter(mthis) native "HTMLMediaElement_currentSrc_Getter";

  static $currentTime_Getter(mthis) native "HTMLMediaElement_currentTime_Getter";

  static $currentTime_Setter(mthis, value) native "HTMLMediaElement_currentTime_Setter";

  static $defaultMuted_Getter(mthis) native "HTMLMediaElement_defaultMuted_Getter";

  static $defaultMuted_Setter(mthis, value) native "HTMLMediaElement_defaultMuted_Setter";

  static $defaultPlaybackRate_Getter(mthis) native "HTMLMediaElement_defaultPlaybackRate_Getter";

  static $defaultPlaybackRate_Setter(mthis, value) native "HTMLMediaElement_defaultPlaybackRate_Setter";

  static $duration_Getter(mthis) native "HTMLMediaElement_duration_Getter";

  static $ended_Getter(mthis) native "HTMLMediaElement_ended_Getter";

  static $error_Getter(mthis) native "HTMLMediaElement_error_Getter";

  static $loop_Getter(mthis) native "HTMLMediaElement_loop_Getter";

  static $loop_Setter(mthis, value) native "HTMLMediaElement_loop_Setter";

  static $mediaGroup_Getter(mthis) native "HTMLMediaElement_mediaGroup_Getter";

  static $mediaGroup_Setter(mthis, value) native "HTMLMediaElement_mediaGroup_Setter";

  static $mediaKeys_Getter(mthis) native "HTMLMediaElement_mediaKeys_Getter";

  static $muted_Getter(mthis) native "HTMLMediaElement_muted_Getter";

  static $muted_Setter(mthis, value) native "HTMLMediaElement_muted_Setter";

  static $networkState_Getter(mthis) native "HTMLMediaElement_networkState_Getter";

  static $paused_Getter(mthis) native "HTMLMediaElement_paused_Getter";

  static $playbackRate_Getter(mthis) native "HTMLMediaElement_playbackRate_Getter";

  static $playbackRate_Setter(mthis, value) native "HTMLMediaElement_playbackRate_Setter";

  static $played_Getter(mthis) native "HTMLMediaElement_played_Getter";

  static $preload_Getter(mthis) native "HTMLMediaElement_preload_Getter";

  static $preload_Setter(mthis, value) native "HTMLMediaElement_preload_Setter";

  static $readyState_Getter(mthis) native "HTMLMediaElement_readyState_Getter";

  static $seekable_Getter(mthis) native "HTMLMediaElement_seekable_Getter";

  static $seeking_Getter(mthis) native "HTMLMediaElement_seeking_Getter";

  static $src_Getter(mthis) native "HTMLMediaElement_src_Getter";

  static $src_Setter(mthis, value) native "HTMLMediaElement_src_Setter";

  static $textTracks_Getter(mthis) native "HTMLMediaElement_textTracks_Getter";

  static $volume_Getter(mthis) native "HTMLMediaElement_volume_Getter";

  static $volume_Setter(mthis, value) native "HTMLMediaElement_volume_Setter";

  static $webkitAudioDecodedByteCount_Getter(mthis) native "HTMLMediaElement_webkitAudioDecodedByteCount_Getter";

  static $webkitVideoDecodedByteCount_Getter(mthis) native "HTMLMediaElement_webkitVideoDecodedByteCount_Getter";

  // Generated overload resolver
  static $addTextTrack(mthis, kind, label, language) {
    if (language != null) {
      return $_addTextTrack_1_Callback(mthis, kind, label, language);
    }
    if (label != null) {
      return $_addTextTrack_2_Callback(mthis, kind, label);
    }
    return $_addTextTrack_3_Callback(mthis, kind);
  }

  static $_addTextTrack_1_Callback(mthis, kind, label, language) native "HTMLMediaElement_addTextTrack_Callback_RESOLVER_STRING_3_DOMString_DOMString_DOMString";

  static $_addTextTrack_2_Callback(mthis, kind, label) native "HTMLMediaElement_addTextTrack_Callback_RESOLVER_STRING_2_DOMString_DOMString";

  static $_addTextTrack_3_Callback(mthis, kind) native "HTMLMediaElement_addTextTrack_Callback_RESOLVER_STRING_1_DOMString";

  static $canPlayType_Callback(mthis, type, keySystem) native "HTMLMediaElement_canPlayType_Callback_RESOLVER_STRING_2_DOMString_DOMString";

  static $load_Callback(mthis) native "HTMLMediaElement_load_Callback_RESOLVER_STRING_0_";

  static $pause_Callback(mthis) native "HTMLMediaElement_pause_Callback_RESOLVER_STRING_0_";

  static $play_Callback(mthis) native "HTMLMediaElement_play_Callback_RESOLVER_STRING_0_";

  static $setMediaKeys_Callback(mthis, mediaKeys) native "HTMLMediaElement_setMediaKeys_Callback_RESOLVER_STRING_1_MediaKeys";

  // Generated overload resolver
  static $addKey(mthis, keySystem, key, initData, sessionId) {
    if (initData != null) {
      $_webkitAddKey_1_Callback(mthis, keySystem, key, initData, sessionId);
      return;
    }
    $_webkitAddKey_2_Callback(mthis, keySystem, key);
    return;
  }

  static $_webkitAddKey_1_Callback(mthis, keySystem, key, initData, sessionId) native "HTMLMediaElement_webkitAddKey_Callback_RESOLVER_STRING_4_DOMString_Uint8Array_Uint8Array_DOMString";

  static $_webkitAddKey_2_Callback(mthis, keySystem, key) native "HTMLMediaElement_webkitAddKey_Callback_RESOLVER_STRING_2_DOMString_Uint8Array";

  static $webkitCancelKeyRequest_Callback(mthis, keySystem, sessionId) native "HTMLMediaElement_webkitCancelKeyRequest_Callback_RESOLVER_STRING_2_DOMString_DOMString";

  // Generated overload resolver
  static $generateKeyRequest(mthis, keySystem, initData) {
    if (initData != null) {
      $_webkitGenerateKeyRequest_1_Callback(mthis, keySystem, initData);
      return;
    }
    $_webkitGenerateKeyRequest_2_Callback(mthis, keySystem);
    return;
  }

  static $_webkitGenerateKeyRequest_1_Callback(mthis, keySystem, initData) native "HTMLMediaElement_webkitGenerateKeyRequest_Callback_RESOLVER_STRING_2_DOMString_Uint8Array";

  static $_webkitGenerateKeyRequest_2_Callback(mthis, keySystem) native "HTMLMediaElement_webkitGenerateKeyRequest_Callback_RESOLVER_STRING_1_DOMString";
}

class BlinkHTMLAudioElement {
  // Generated overload resolver
  static $mkAudioElement(src) {
    return $_create_1constructorCallback(src);
  }

  static $_create_1constructorCallback(src) native "HTMLAudioElement_constructorCallback_RESOLVER_STRING_1_DOMString";
}

class BlinkHTMLBRElement {}

class BlinkHTMLBaseElement {
  static $href_Getter(mthis) native "HTMLBaseElement_href_Getter";

  static $href_Setter(mthis, value) native "HTMLBaseElement_href_Setter";

  static $target_Getter(mthis) native "HTMLBaseElement_target_Getter";

  static $target_Setter(mthis, value) native "HTMLBaseElement_target_Setter";
}

class BlinkWindowEventHandlers {}

class BlinkHTMLBodyElement {}

class BlinkHTMLButtonElement {
  static $autofocus_Getter(mthis) native "HTMLButtonElement_autofocus_Getter";

  static $autofocus_Setter(mthis, value) native "HTMLButtonElement_autofocus_Setter";

  static $disabled_Getter(mthis) native "HTMLButtonElement_disabled_Getter";

  static $disabled_Setter(mthis, value) native "HTMLButtonElement_disabled_Setter";

  static $form_Getter(mthis) native "HTMLButtonElement_form_Getter";

  static $formAction_Getter(mthis) native "HTMLButtonElement_formAction_Getter";

  static $formAction_Setter(mthis, value) native "HTMLButtonElement_formAction_Setter";

  static $formEnctype_Getter(mthis) native "HTMLButtonElement_formEnctype_Getter";

  static $formEnctype_Setter(mthis, value) native "HTMLButtonElement_formEnctype_Setter";

  static $formMethod_Getter(mthis) native "HTMLButtonElement_formMethod_Getter";

  static $formMethod_Setter(mthis, value) native "HTMLButtonElement_formMethod_Setter";

  static $formNoValidate_Getter(mthis) native "HTMLButtonElement_formNoValidate_Getter";

  static $formNoValidate_Setter(mthis, value) native "HTMLButtonElement_formNoValidate_Setter";

  static $formTarget_Getter(mthis) native "HTMLButtonElement_formTarget_Getter";

  static $formTarget_Setter(mthis, value) native "HTMLButtonElement_formTarget_Setter";

  static $labels_Getter(mthis) native "HTMLButtonElement_labels_Getter";

  static $name_Getter(mthis) native "HTMLButtonElement_name_Getter";

  static $name_Setter(mthis, value) native "HTMLButtonElement_name_Setter";

  static $type_Getter(mthis) native "HTMLButtonElement_type_Getter";

  static $type_Setter(mthis, value) native "HTMLButtonElement_type_Setter";

  static $validationMessage_Getter(mthis) native "HTMLButtonElement_validationMessage_Getter";

  static $validity_Getter(mthis) native "HTMLButtonElement_validity_Getter";

  static $value_Getter(mthis) native "HTMLButtonElement_value_Getter";

  static $value_Setter(mthis, value) native "HTMLButtonElement_value_Setter";

  static $willValidate_Getter(mthis) native "HTMLButtonElement_willValidate_Getter";

  static $checkValidity_Callback(mthis) native "HTMLButtonElement_checkValidity_Callback_RESOLVER_STRING_0_";

  static $setCustomValidity_Callback(mthis, error) native "HTMLButtonElement_setCustomValidity_Callback_RESOLVER_STRING_1_DOMString";
}

class BlinkHTMLCanvasElement {
  static $height_Getter(mthis) native "HTMLCanvasElement_height_Getter";

  static $height_Setter(mthis, value) native "HTMLCanvasElement_height_Setter";

  static $width_Getter(mthis) native "HTMLCanvasElement_width_Getter";

  static $width_Setter(mthis, value) native "HTMLCanvasElement_width_Setter";

  static $getContext_Callback(mthis, contextId, attrs) native "HTMLCanvasElement_getContext_Callback";

  static $toDataURL_Callback(mthis, type, quality) native "HTMLCanvasElement_toDataURL_Callback";
}

class BlinkHTMLCollection {
  static $length_Getter(mthis) native "HTMLCollection_length_Getter";

  static $NativeIndexed_Getter(mthis, index) native "HTMLCollection_item_Callback_RESOLVER_STRING_1_unsigned long";

  static $item_Callback(mthis, index) native "HTMLCollection_item_Callback_RESOLVER_STRING_1_unsigned long";

  static $namedItem_Callback(mthis, name) native "HTMLCollection_namedItem_Callback_RESOLVER_STRING_1_DOMString";
}

class BlinkHTMLContentElement {
  static $resetStyleInheritance_Getter(mthis) native "HTMLContentElement_resetStyleInheritance_Getter";

  static $resetStyleInheritance_Setter(mthis, value) native "HTMLContentElement_resetStyleInheritance_Setter";

  static $select_Getter(mthis) native "HTMLContentElement_select_Getter";

  static $select_Setter(mthis, value) native "HTMLContentElement_select_Setter";

  static $getDistributedNodes_Callback(mthis) native "HTMLContentElement_getDistributedNodes_Callback_RESOLVER_STRING_0_";
}

class BlinkHTMLDListElement {}

class BlinkHTMLDataListElement {
  static $options_Getter(mthis) native "HTMLDataListElement_options_Getter";
}

class BlinkHTMLDetailsElement {
  static $open_Getter(mthis) native "HTMLDetailsElement_open_Getter";

  static $open_Setter(mthis, value) native "HTMLDetailsElement_open_Setter";
}

class BlinkHTMLDialogElement {
  static $open_Getter(mthis) native "HTMLDialogElement_open_Getter";

  static $open_Setter(mthis, value) native "HTMLDialogElement_open_Setter";

  static $returnValue_Getter(mthis) native "HTMLDialogElement_returnValue_Getter";

  static $returnValue_Setter(mthis, value) native "HTMLDialogElement_returnValue_Setter";

  static $close_Callback(mthis, returnValue) native "HTMLDialogElement_close_Callback_RESOLVER_STRING_1_DOMString";

  static $show_Callback(mthis) native "HTMLDialogElement_show_Callback_RESOLVER_STRING_0_";

  static $showModal_Callback(mthis) native "HTMLDialogElement_showModal_Callback_RESOLVER_STRING_0_";
}

class BlinkHTMLDirectoryElement {}

class BlinkHTMLDivElement {}

class BlinkHTMLDocument {}

class BlinkHTMLEmbedElement {
  static $height_Getter(mthis) native "HTMLEmbedElement_height_Getter";

  static $height_Setter(mthis, value) native "HTMLEmbedElement_height_Setter";

  static $name_Getter(mthis) native "HTMLEmbedElement_name_Getter";

  static $name_Setter(mthis, value) native "HTMLEmbedElement_name_Setter";

  static $src_Getter(mthis) native "HTMLEmbedElement_src_Getter";

  static $src_Setter(mthis, value) native "HTMLEmbedElement_src_Setter";

  static $type_Getter(mthis) native "HTMLEmbedElement_type_Getter";

  static $type_Setter(mthis, value) native "HTMLEmbedElement_type_Setter";

  static $width_Getter(mthis) native "HTMLEmbedElement_width_Getter";

  static $width_Setter(mthis, value) native "HTMLEmbedElement_width_Setter";

  static $__getter___Callback(mthis, index_OR_name) native "HTMLEmbedElement___getter___Callback";

  static $__setter___Callback(mthis, index_OR_name, value) native "HTMLEmbedElement___setter___Callback";
}

class BlinkHTMLFieldSetElement {
  static $disabled_Getter(mthis) native "HTMLFieldSetElement_disabled_Getter";

  static $disabled_Setter(mthis, value) native "HTMLFieldSetElement_disabled_Setter";

  static $elements_Getter(mthis) native "HTMLFieldSetElement_elements_Getter";

  static $form_Getter(mthis) native "HTMLFieldSetElement_form_Getter";

  static $name_Getter(mthis) native "HTMLFieldSetElement_name_Getter";

  static $name_Setter(mthis, value) native "HTMLFieldSetElement_name_Setter";

  static $type_Getter(mthis) native "HTMLFieldSetElement_type_Getter";

  static $validationMessage_Getter(mthis) native "HTMLFieldSetElement_validationMessage_Getter";

  static $validity_Getter(mthis) native "HTMLFieldSetElement_validity_Getter";

  static $willValidate_Getter(mthis) native "HTMLFieldSetElement_willValidate_Getter";

  static $checkValidity_Callback(mthis) native "HTMLFieldSetElement_checkValidity_Callback_RESOLVER_STRING_0_";

  static $setCustomValidity_Callback(mthis, error) native "HTMLFieldSetElement_setCustomValidity_Callback_RESOLVER_STRING_1_DOMString";
}

class BlinkHTMLFontElement {}

class BlinkHTMLFormControlsCollection {}

class BlinkHTMLFormElement {
  static $acceptCharset_Getter(mthis) native "HTMLFormElement_acceptCharset_Getter";

  static $acceptCharset_Setter(mthis, value) native "HTMLFormElement_acceptCharset_Setter";

  static $action_Getter(mthis) native "HTMLFormElement_action_Getter";

  static $action_Setter(mthis, value) native "HTMLFormElement_action_Setter";

  static $autocomplete_Getter(mthis) native "HTMLFormElement_autocomplete_Getter";

  static $autocomplete_Setter(mthis, value) native "HTMLFormElement_autocomplete_Setter";

  static $encoding_Getter(mthis) native "HTMLFormElement_encoding_Getter";

  static $encoding_Setter(mthis, value) native "HTMLFormElement_encoding_Setter";

  static $enctype_Getter(mthis) native "HTMLFormElement_enctype_Getter";

  static $enctype_Setter(mthis, value) native "HTMLFormElement_enctype_Setter";

  static $length_Getter(mthis) native "HTMLFormElement_length_Getter";

  static $method_Getter(mthis) native "HTMLFormElement_method_Getter";

  static $method_Setter(mthis, value) native "HTMLFormElement_method_Setter";

  static $name_Getter(mthis) native "HTMLFormElement_name_Getter";

  static $name_Setter(mthis, value) native "HTMLFormElement_name_Setter";

  static $noValidate_Getter(mthis) native "HTMLFormElement_noValidate_Getter";

  static $noValidate_Setter(mthis, value) native "HTMLFormElement_noValidate_Setter";

  static $target_Getter(mthis) native "HTMLFormElement_target_Getter";

  static $target_Setter(mthis, value) native "HTMLFormElement_target_Setter";

  static $__getter___Callback(mthis, index) native "HTMLFormElement___getter___Callback_RESOLVER_STRING_1_unsigned long";

  static $checkValidity_Callback(mthis) native "HTMLFormElement_checkValidity_Callback_RESOLVER_STRING_0_";

  static $requestAutocomplete_Callback(mthis, details) native "HTMLFormElement_requestAutocomplete_Callback_RESOLVER_STRING_1_Dictionary";

  static $reset_Callback(mthis) native "HTMLFormElement_reset_Callback_RESOLVER_STRING_0_";

  static $submit_Callback(mthis) native "HTMLFormElement_submit_Callback_RESOLVER_STRING_0_";
}

class BlinkHTMLFrameElement {}

class BlinkHTMLFrameSetElement {}

class BlinkHTMLHRElement {
  static $color_Getter(mthis) native "HTMLHRElement_color_Getter";

  static $color_Setter(mthis, value) native "HTMLHRElement_color_Setter";
}

class BlinkHTMLHeadElement {}

class BlinkHTMLHeadingElement {}

class BlinkHTMLHtmlElement {}

class BlinkHTMLIFrameElement {
  static $contentWindow_Getter(mthis) native "HTMLIFrameElement_contentWindow_Getter";

  static $height_Getter(mthis) native "HTMLIFrameElement_height_Getter";

  static $height_Setter(mthis, value) native "HTMLIFrameElement_height_Setter";

  static $name_Getter(mthis) native "HTMLIFrameElement_name_Getter";

  static $name_Setter(mthis, value) native "HTMLIFrameElement_name_Setter";

  static $sandbox_Getter(mthis) native "HTMLIFrameElement_sandbox_Getter";

  static $sandbox_Setter(mthis, value) native "HTMLIFrameElement_sandbox_Setter";

  static $src_Getter(mthis) native "HTMLIFrameElement_src_Getter";

  static $src_Setter(mthis, value) native "HTMLIFrameElement_src_Setter";

  static $srcdoc_Getter(mthis) native "HTMLIFrameElement_srcdoc_Getter";

  static $srcdoc_Setter(mthis, value) native "HTMLIFrameElement_srcdoc_Setter";

  static $width_Getter(mthis) native "HTMLIFrameElement_width_Getter";

  static $width_Setter(mthis, value) native "HTMLIFrameElement_width_Setter";
}

class BlinkHTMLImageElement {
  static $alt_Getter(mthis) native "HTMLImageElement_alt_Getter";

  static $alt_Setter(mthis, value) native "HTMLImageElement_alt_Setter";

  static $complete_Getter(mthis) native "HTMLImageElement_complete_Getter";

  static $crossOrigin_Getter(mthis) native "HTMLImageElement_crossOrigin_Getter";

  static $crossOrigin_Setter(mthis, value) native "HTMLImageElement_crossOrigin_Setter";

  static $height_Getter(mthis) native "HTMLImageElement_height_Getter";

  static $height_Setter(mthis, value) native "HTMLImageElement_height_Setter";

  static $isMap_Getter(mthis) native "HTMLImageElement_isMap_Getter";

  static $isMap_Setter(mthis, value) native "HTMLImageElement_isMap_Setter";

  static $naturalHeight_Getter(mthis) native "HTMLImageElement_naturalHeight_Getter";

  static $naturalWidth_Getter(mthis) native "HTMLImageElement_naturalWidth_Getter";

  static $src_Getter(mthis) native "HTMLImageElement_src_Getter";

  static $src_Setter(mthis, value) native "HTMLImageElement_src_Setter";

  static $srcset_Getter(mthis) native "HTMLImageElement_srcset_Getter";

  static $srcset_Setter(mthis, value) native "HTMLImageElement_srcset_Setter";

  static $useMap_Getter(mthis) native "HTMLImageElement_useMap_Getter";

  static $useMap_Setter(mthis, value) native "HTMLImageElement_useMap_Setter";

  static $width_Getter(mthis) native "HTMLImageElement_width_Getter";

  static $width_Setter(mthis, value) native "HTMLImageElement_width_Setter";
}

class BlinkHTMLInputElement {
  static $accept_Getter(mthis) native "HTMLInputElement_accept_Getter";

  static $accept_Setter(mthis, value) native "HTMLInputElement_accept_Setter";

  static $alt_Getter(mthis) native "HTMLInputElement_alt_Getter";

  static $alt_Setter(mthis, value) native "HTMLInputElement_alt_Setter";

  static $autocomplete_Getter(mthis) native "HTMLInputElement_autocomplete_Getter";

  static $autocomplete_Setter(mthis, value) native "HTMLInputElement_autocomplete_Setter";

  static $autofocus_Getter(mthis) native "HTMLInputElement_autofocus_Getter";

  static $autofocus_Setter(mthis, value) native "HTMLInputElement_autofocus_Setter";

  static $checked_Getter(mthis) native "HTMLInputElement_checked_Getter";

  static $checked_Setter(mthis, value) native "HTMLInputElement_checked_Setter";

  static $defaultChecked_Getter(mthis) native "HTMLInputElement_defaultChecked_Getter";

  static $defaultChecked_Setter(mthis, value) native "HTMLInputElement_defaultChecked_Setter";

  static $defaultValue_Getter(mthis) native "HTMLInputElement_defaultValue_Getter";

  static $defaultValue_Setter(mthis, value) native "HTMLInputElement_defaultValue_Setter";

  static $dirName_Getter(mthis) native "HTMLInputElement_dirName_Getter";

  static $dirName_Setter(mthis, value) native "HTMLInputElement_dirName_Setter";

  static $disabled_Getter(mthis) native "HTMLInputElement_disabled_Getter";

  static $disabled_Setter(mthis, value) native "HTMLInputElement_disabled_Setter";

  static $files_Getter(mthis) native "HTMLInputElement_files_Getter";

  static $files_Setter(mthis, value) native "HTMLInputElement_files_Setter";

  static $form_Getter(mthis) native "HTMLInputElement_form_Getter";

  static $formAction_Getter(mthis) native "HTMLInputElement_formAction_Getter";

  static $formAction_Setter(mthis, value) native "HTMLInputElement_formAction_Setter";

  static $formEnctype_Getter(mthis) native "HTMLInputElement_formEnctype_Getter";

  static $formEnctype_Setter(mthis, value) native "HTMLInputElement_formEnctype_Setter";

  static $formMethod_Getter(mthis) native "HTMLInputElement_formMethod_Getter";

  static $formMethod_Setter(mthis, value) native "HTMLInputElement_formMethod_Setter";

  static $formNoValidate_Getter(mthis) native "HTMLInputElement_formNoValidate_Getter";

  static $formNoValidate_Setter(mthis, value) native "HTMLInputElement_formNoValidate_Setter";

  static $formTarget_Getter(mthis) native "HTMLInputElement_formTarget_Getter";

  static $formTarget_Setter(mthis, value) native "HTMLInputElement_formTarget_Setter";

  static $height_Getter(mthis) native "HTMLInputElement_height_Getter";

  static $height_Setter(mthis, value) native "HTMLInputElement_height_Setter";

  static $incremental_Getter(mthis) native "HTMLInputElement_incremental_Getter";

  static $incremental_Setter(mthis, value) native "HTMLInputElement_incremental_Setter";

  static $indeterminate_Getter(mthis) native "HTMLInputElement_indeterminate_Getter";

  static $indeterminate_Setter(mthis, value) native "HTMLInputElement_indeterminate_Setter";

  static $inputMode_Getter(mthis) native "HTMLInputElement_inputMode_Getter";

  static $inputMode_Setter(mthis, value) native "HTMLInputElement_inputMode_Setter";

  static $labels_Getter(mthis) native "HTMLInputElement_labels_Getter";

  static $list_Getter(mthis) native "HTMLInputElement_list_Getter";

  static $max_Getter(mthis) native "HTMLInputElement_max_Getter";

  static $max_Setter(mthis, value) native "HTMLInputElement_max_Setter";

  static $maxLength_Getter(mthis) native "HTMLInputElement_maxLength_Getter";

  static $maxLength_Setter(mthis, value) native "HTMLInputElement_maxLength_Setter";

  static $min_Getter(mthis) native "HTMLInputElement_min_Getter";

  static $min_Setter(mthis, value) native "HTMLInputElement_min_Setter";

  static $multiple_Getter(mthis) native "HTMLInputElement_multiple_Getter";

  static $multiple_Setter(mthis, value) native "HTMLInputElement_multiple_Setter";

  static $name_Getter(mthis) native "HTMLInputElement_name_Getter";

  static $name_Setter(mthis, value) native "HTMLInputElement_name_Setter";

  static $pattern_Getter(mthis) native "HTMLInputElement_pattern_Getter";

  static $pattern_Setter(mthis, value) native "HTMLInputElement_pattern_Setter";

  static $placeholder_Getter(mthis) native "HTMLInputElement_placeholder_Getter";

  static $placeholder_Setter(mthis, value) native "HTMLInputElement_placeholder_Setter";

  static $readOnly_Getter(mthis) native "HTMLInputElement_readOnly_Getter";

  static $readOnly_Setter(mthis, value) native "HTMLInputElement_readOnly_Setter";

  static $required_Getter(mthis) native "HTMLInputElement_required_Getter";

  static $required_Setter(mthis, value) native "HTMLInputElement_required_Setter";

  static $selectionDirection_Getter(mthis) native "HTMLInputElement_selectionDirection_Getter";

  static $selectionDirection_Setter(mthis, value) native "HTMLInputElement_selectionDirection_Setter";

  static $selectionEnd_Getter(mthis) native "HTMLInputElement_selectionEnd_Getter";

  static $selectionEnd_Setter(mthis, value) native "HTMLInputElement_selectionEnd_Setter";

  static $selectionStart_Getter(mthis) native "HTMLInputElement_selectionStart_Getter";

  static $selectionStart_Setter(mthis, value) native "HTMLInputElement_selectionStart_Setter";

  static $size_Getter(mthis) native "HTMLInputElement_size_Getter";

  static $size_Setter(mthis, value) native "HTMLInputElement_size_Setter";

  static $src_Getter(mthis) native "HTMLInputElement_src_Getter";

  static $src_Setter(mthis, value) native "HTMLInputElement_src_Setter";

  static $step_Getter(mthis) native "HTMLInputElement_step_Getter";

  static $step_Setter(mthis, value) native "HTMLInputElement_step_Setter";

  static $type_Getter(mthis) native "HTMLInputElement_type_Getter";

  static $type_Setter(mthis, value) native "HTMLInputElement_type_Setter";

  static $validationMessage_Getter(mthis) native "HTMLInputElement_validationMessage_Getter";

  static $validity_Getter(mthis) native "HTMLInputElement_validity_Getter";

  static $value_Getter(mthis) native "HTMLInputElement_value_Getter";

  static $value_Setter(mthis, value) native "HTMLInputElement_value_Setter";

  static $valueAsDate_Getter(mthis) native "HTMLInputElement_valueAsDate_Getter";

  static $valueAsDate_Setter(mthis, value) native "HTMLInputElement_valueAsDate_Setter";

  static $valueAsNumber_Getter(mthis) native "HTMLInputElement_valueAsNumber_Getter";

  static $valueAsNumber_Setter(mthis, value) native "HTMLInputElement_valueAsNumber_Setter";

  static $webkitEntries_Getter(mthis) native "HTMLInputElement_webkitEntries_Getter";

  static $webkitdirectory_Getter(mthis) native "HTMLInputElement_webkitdirectory_Getter";

  static $webkitdirectory_Setter(mthis, value) native "HTMLInputElement_webkitdirectory_Setter";

  static $width_Getter(mthis) native "HTMLInputElement_width_Getter";

  static $width_Setter(mthis, value) native "HTMLInputElement_width_Setter";

  static $willValidate_Getter(mthis) native "HTMLInputElement_willValidate_Getter";

  static $checkValidity_Callback(mthis) native "HTMLInputElement_checkValidity_Callback_RESOLVER_STRING_0_";

  static $select_Callback(mthis) native "HTMLInputElement_select_Callback_RESOLVER_STRING_0_";

  static $setCustomValidity_Callback(mthis, error) native "HTMLInputElement_setCustomValidity_Callback_RESOLVER_STRING_1_DOMString";

  // Generated overload resolver
  static $setRangeText(mthis, replacement, start, end, selectionMode) {
    if ((replacement is String || replacement == null) && start == null && end == null && selectionMode == null) {
      $_setRangeText_1_Callback(mthis, replacement);
      return;
    }
    if ((selectionMode is String || selectionMode == null) && (end is int || end == null) && (start is int || start == null) && (replacement is String || replacement == null)) {
      $_setRangeText_2_Callback(mthis, replacement, start, end, selectionMode);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  static $_setRangeText_1_Callback(mthis, replacement) native "HTMLInputElement_setRangeText_Callback_RESOLVER_STRING_1_DOMString";

  static $_setRangeText_2_Callback(mthis, replacement, start, end, selectionMode) native "HTMLInputElement_setRangeText_Callback_RESOLVER_STRING_4_DOMString_unsigned long_unsigned long_DOMString";

  // Generated overload resolver
  static $setSelectionRange(mthis, start, end, direction) {
    if (direction != null) {
      $_setSelectionRange_1_Callback(mthis, start, end, direction);
      return;
    }
    $_setSelectionRange_2_Callback(mthis, start, end);
    return;
  }

  static $_setSelectionRange_1_Callback(mthis, start, end, direction) native "HTMLInputElement_setSelectionRange_Callback_RESOLVER_STRING_3_long_long_DOMString";

  static $_setSelectionRange_2_Callback(mthis, start, end) native "HTMLInputElement_setSelectionRange_Callback_RESOLVER_STRING_2_long_long";

  // Generated overload resolver
  static $stepDown(mthis, n) {
    if (n != null) {
      $_stepDown_1_Callback(mthis, n);
      return;
    }
    $_stepDown_2_Callback(mthis);
    return;
  }

  static $_stepDown_1_Callback(mthis, n) native "HTMLInputElement_stepDown_Callback_RESOLVER_STRING_1_long";

  static $_stepDown_2_Callback(mthis) native "HTMLInputElement_stepDown_Callback_RESOLVER_STRING_0_";

  // Generated overload resolver
  static $stepUp(mthis, n) {
    if (n != null) {
      $_stepUp_1_Callback(mthis, n);
      return;
    }
    $_stepUp_2_Callback(mthis);
    return;
  }

  static $_stepUp_1_Callback(mthis, n) native "HTMLInputElement_stepUp_Callback_RESOLVER_STRING_1_long";

  static $_stepUp_2_Callback(mthis) native "HTMLInputElement_stepUp_Callback_RESOLVER_STRING_0_";
}

class BlinkHTMLKeygenElement {
  static $autofocus_Getter(mthis) native "HTMLKeygenElement_autofocus_Getter";

  static $autofocus_Setter(mthis, value) native "HTMLKeygenElement_autofocus_Setter";

  static $challenge_Getter(mthis) native "HTMLKeygenElement_challenge_Getter";

  static $challenge_Setter(mthis, value) native "HTMLKeygenElement_challenge_Setter";

  static $disabled_Getter(mthis) native "HTMLKeygenElement_disabled_Getter";

  static $disabled_Setter(mthis, value) native "HTMLKeygenElement_disabled_Setter";

  static $form_Getter(mthis) native "HTMLKeygenElement_form_Getter";

  static $keytype_Getter(mthis) native "HTMLKeygenElement_keytype_Getter";

  static $keytype_Setter(mthis, value) native "HTMLKeygenElement_keytype_Setter";

  static $labels_Getter(mthis) native "HTMLKeygenElement_labels_Getter";

  static $name_Getter(mthis) native "HTMLKeygenElement_name_Getter";

  static $name_Setter(mthis, value) native "HTMLKeygenElement_name_Setter";

  static $type_Getter(mthis) native "HTMLKeygenElement_type_Getter";

  static $validationMessage_Getter(mthis) native "HTMLKeygenElement_validationMessage_Getter";

  static $validity_Getter(mthis) native "HTMLKeygenElement_validity_Getter";

  static $willValidate_Getter(mthis) native "HTMLKeygenElement_willValidate_Getter";

  static $checkValidity_Callback(mthis) native "HTMLKeygenElement_checkValidity_Callback_RESOLVER_STRING_0_";

  static $setCustomValidity_Callback(mthis, error) native "HTMLKeygenElement_setCustomValidity_Callback_RESOLVER_STRING_1_DOMString";
}

class BlinkHTMLLIElement {
  static $value_Getter(mthis) native "HTMLLIElement_value_Getter";

  static $value_Setter(mthis, value) native "HTMLLIElement_value_Setter";
}

class BlinkHTMLLabelElement {
  static $control_Getter(mthis) native "HTMLLabelElement_control_Getter";

  static $form_Getter(mthis) native "HTMLLabelElement_form_Getter";

  static $htmlFor_Getter(mthis) native "HTMLLabelElement_htmlFor_Getter";

  static $htmlFor_Setter(mthis, value) native "HTMLLabelElement_htmlFor_Setter";
}

class BlinkHTMLLegendElement {
  static $form_Getter(mthis) native "HTMLLegendElement_form_Getter";
}

class BlinkHTMLLinkElement {
  static $crossOrigin_Getter(mthis) native "HTMLLinkElement_crossOrigin_Getter";

  static $crossOrigin_Setter(mthis, value) native "HTMLLinkElement_crossOrigin_Setter";

  static $disabled_Getter(mthis) native "HTMLLinkElement_disabled_Getter";

  static $disabled_Setter(mthis, value) native "HTMLLinkElement_disabled_Setter";

  static $href_Getter(mthis) native "HTMLLinkElement_href_Getter";

  static $href_Setter(mthis, value) native "HTMLLinkElement_href_Setter";

  static $hreflang_Getter(mthis) native "HTMLLinkElement_hreflang_Getter";

  static $hreflang_Setter(mthis, value) native "HTMLLinkElement_hreflang_Setter";

  static $import_Getter(mthis) native "HTMLLinkElement_import_Getter";

  static $media_Getter(mthis) native "HTMLLinkElement_media_Getter";

  static $media_Setter(mthis, value) native "HTMLLinkElement_media_Setter";

  static $rel_Getter(mthis) native "HTMLLinkElement_rel_Getter";

  static $rel_Setter(mthis, value) native "HTMLLinkElement_rel_Setter";

  static $sheet_Getter(mthis) native "HTMLLinkElement_sheet_Getter";

  static $sizes_Getter(mthis) native "HTMLLinkElement_sizes_Getter";

  static $type_Getter(mthis) native "HTMLLinkElement_type_Getter";

  static $type_Setter(mthis, value) native "HTMLLinkElement_type_Setter";
}

class BlinkHTMLMapElement {
  static $areas_Getter(mthis) native "HTMLMapElement_areas_Getter";

  static $name_Getter(mthis) native "HTMLMapElement_name_Getter";

  static $name_Setter(mthis, value) native "HTMLMapElement_name_Setter";
}

class BlinkHTMLMarqueeElement {}

class BlinkHTMLMenuElement {}

class BlinkHTMLMetaElement {
  static $content_Getter(mthis) native "HTMLMetaElement_content_Getter";

  static $content_Setter(mthis, value) native "HTMLMetaElement_content_Setter";

  static $httpEquiv_Getter(mthis) native "HTMLMetaElement_httpEquiv_Getter";

  static $httpEquiv_Setter(mthis, value) native "HTMLMetaElement_httpEquiv_Setter";

  static $name_Getter(mthis) native "HTMLMetaElement_name_Getter";

  static $name_Setter(mthis, value) native "HTMLMetaElement_name_Setter";
}

class BlinkHTMLMeterElement {
  static $high_Getter(mthis) native "HTMLMeterElement_high_Getter";

  static $high_Setter(mthis, value) native "HTMLMeterElement_high_Setter";

  static $labels_Getter(mthis) native "HTMLMeterElement_labels_Getter";

  static $low_Getter(mthis) native "HTMLMeterElement_low_Getter";

  static $low_Setter(mthis, value) native "HTMLMeterElement_low_Setter";

  static $max_Getter(mthis) native "HTMLMeterElement_max_Getter";

  static $max_Setter(mthis, value) native "HTMLMeterElement_max_Setter";

  static $min_Getter(mthis) native "HTMLMeterElement_min_Getter";

  static $min_Setter(mthis, value) native "HTMLMeterElement_min_Setter";

  static $optimum_Getter(mthis) native "HTMLMeterElement_optimum_Getter";

  static $optimum_Setter(mthis, value) native "HTMLMeterElement_optimum_Setter";

  static $value_Getter(mthis) native "HTMLMeterElement_value_Getter";

  static $value_Setter(mthis, value) native "HTMLMeterElement_value_Setter";
}

class BlinkHTMLModElement {
  static $cite_Getter(mthis) native "HTMLModElement_cite_Getter";

  static $cite_Setter(mthis, value) native "HTMLModElement_cite_Setter";

  static $dateTime_Getter(mthis) native "HTMLModElement_dateTime_Getter";

  static $dateTime_Setter(mthis, value) native "HTMLModElement_dateTime_Setter";
}

class BlinkHTMLOListElement {
  static $reversed_Getter(mthis) native "HTMLOListElement_reversed_Getter";

  static $reversed_Setter(mthis, value) native "HTMLOListElement_reversed_Setter";

  static $start_Getter(mthis) native "HTMLOListElement_start_Getter";

  static $start_Setter(mthis, value) native "HTMLOListElement_start_Setter";

  static $type_Getter(mthis) native "HTMLOListElement_type_Getter";

  static $type_Setter(mthis, value) native "HTMLOListElement_type_Setter";
}

class BlinkHTMLObjectElement {
  static $data_Getter(mthis) native "HTMLObjectElement_data_Getter";

  static $data_Setter(mthis, value) native "HTMLObjectElement_data_Setter";

  static $form_Getter(mthis) native "HTMLObjectElement_form_Getter";

  static $height_Getter(mthis) native "HTMLObjectElement_height_Getter";

  static $height_Setter(mthis, value) native "HTMLObjectElement_height_Setter";

  static $name_Getter(mthis) native "HTMLObjectElement_name_Getter";

  static $name_Setter(mthis, value) native "HTMLObjectElement_name_Setter";

  static $type_Getter(mthis) native "HTMLObjectElement_type_Getter";

  static $type_Setter(mthis, value) native "HTMLObjectElement_type_Setter";

  static $useMap_Getter(mthis) native "HTMLObjectElement_useMap_Getter";

  static $useMap_Setter(mthis, value) native "HTMLObjectElement_useMap_Setter";

  static $validationMessage_Getter(mthis) native "HTMLObjectElement_validationMessage_Getter";

  static $validity_Getter(mthis) native "HTMLObjectElement_validity_Getter";

  static $width_Getter(mthis) native "HTMLObjectElement_width_Getter";

  static $width_Setter(mthis, value) native "HTMLObjectElement_width_Setter";

  static $willValidate_Getter(mthis) native "HTMLObjectElement_willValidate_Getter";

  static $__getter___Callback(mthis, index_OR_name) native "HTMLObjectElement___getter___Callback";

  static $__setter___Callback(mthis, index_OR_name, value) native "HTMLObjectElement___setter___Callback";

  static $checkValidity_Callback(mthis) native "HTMLObjectElement_checkValidity_Callback_RESOLVER_STRING_0_";

  static $setCustomValidity_Callback(mthis, error) native "HTMLObjectElement_setCustomValidity_Callback_RESOLVER_STRING_1_DOMString";
}

class BlinkHTMLOptGroupElement {
  static $disabled_Getter(mthis) native "HTMLOptGroupElement_disabled_Getter";

  static $disabled_Setter(mthis, value) native "HTMLOptGroupElement_disabled_Setter";

  static $label_Getter(mthis) native "HTMLOptGroupElement_label_Getter";

  static $label_Setter(mthis, value) native "HTMLOptGroupElement_label_Setter";
}

class BlinkHTMLOptionElement {
  // Generated overload resolver
  static $mkOptionElement__(data, value, defaultSelected, selected) {
    return $_create_1constructorCallback(data, value, defaultSelected, selected);
  }

  static $_create_1constructorCallback(data, value, defaultSelected, selected) native "HTMLOptionElement_constructorCallback_RESOLVER_STRING_4_DOMString_DOMString_boolean_boolean";

  static $defaultSelected_Getter(mthis) native "HTMLOptionElement_defaultSelected_Getter";

  static $defaultSelected_Setter(mthis, value) native "HTMLOptionElement_defaultSelected_Setter";

  static $disabled_Getter(mthis) native "HTMLOptionElement_disabled_Getter";

  static $disabled_Setter(mthis, value) native "HTMLOptionElement_disabled_Setter";

  static $form_Getter(mthis) native "HTMLOptionElement_form_Getter";

  static $index_Getter(mthis) native "HTMLOptionElement_index_Getter";

  static $label_Getter(mthis) native "HTMLOptionElement_label_Getter";

  static $label_Setter(mthis, value) native "HTMLOptionElement_label_Setter";

  static $selected_Getter(mthis) native "HTMLOptionElement_selected_Getter";

  static $selected_Setter(mthis, value) native "HTMLOptionElement_selected_Setter";

  static $value_Getter(mthis) native "HTMLOptionElement_value_Getter";

  static $value_Setter(mthis, value) native "HTMLOptionElement_value_Setter";
}

class BlinkHTMLOptionsCollection {}

class BlinkHTMLOutputElement {
  static $defaultValue_Getter(mthis) native "HTMLOutputElement_defaultValue_Getter";

  static $defaultValue_Setter(mthis, value) native "HTMLOutputElement_defaultValue_Setter";

  static $form_Getter(mthis) native "HTMLOutputElement_form_Getter";

  static $htmlFor_Getter(mthis) native "HTMLOutputElement_htmlFor_Getter";

  static $labels_Getter(mthis) native "HTMLOutputElement_labels_Getter";

  static $name_Getter(mthis) native "HTMLOutputElement_name_Getter";

  static $name_Setter(mthis, value) native "HTMLOutputElement_name_Setter";

  static $type_Getter(mthis) native "HTMLOutputElement_type_Getter";

  static $validationMessage_Getter(mthis) native "HTMLOutputElement_validationMessage_Getter";

  static $validity_Getter(mthis) native "HTMLOutputElement_validity_Getter";

  static $value_Getter(mthis) native "HTMLOutputElement_value_Getter";

  static $value_Setter(mthis, value) native "HTMLOutputElement_value_Setter";

  static $willValidate_Getter(mthis) native "HTMLOutputElement_willValidate_Getter";

  static $checkValidity_Callback(mthis) native "HTMLOutputElement_checkValidity_Callback_RESOLVER_STRING_0_";

  static $setCustomValidity_Callback(mthis, error) native "HTMLOutputElement_setCustomValidity_Callback_RESOLVER_STRING_1_DOMString";
}

class BlinkHTMLParagraphElement {}

class BlinkHTMLParamElement {
  static $name_Getter(mthis) native "HTMLParamElement_name_Getter";

  static $name_Setter(mthis, value) native "HTMLParamElement_name_Setter";

  static $value_Getter(mthis) native "HTMLParamElement_value_Getter";

  static $value_Setter(mthis, value) native "HTMLParamElement_value_Setter";
}

class BlinkHTMLPreElement {}

class BlinkHTMLProgressElement {
  static $labels_Getter(mthis) native "HTMLProgressElement_labels_Getter";

  static $max_Getter(mthis) native "HTMLProgressElement_max_Getter";

  static $max_Setter(mthis, value) native "HTMLProgressElement_max_Setter";

  static $position_Getter(mthis) native "HTMLProgressElement_position_Getter";

  static $value_Getter(mthis) native "HTMLProgressElement_value_Getter";

  static $value_Setter(mthis, value) native "HTMLProgressElement_value_Setter";
}

class BlinkHTMLQuoteElement {
  static $cite_Getter(mthis) native "HTMLQuoteElement_cite_Getter";

  static $cite_Setter(mthis, value) native "HTMLQuoteElement_cite_Setter";
}

class BlinkHTMLScriptElement {
  static $async_Getter(mthis) native "HTMLScriptElement_async_Getter";

  static $async_Setter(mthis, value) native "HTMLScriptElement_async_Setter";

  static $charset_Getter(mthis) native "HTMLScriptElement_charset_Getter";

  static $charset_Setter(mthis, value) native "HTMLScriptElement_charset_Setter";

  static $crossOrigin_Getter(mthis) native "HTMLScriptElement_crossOrigin_Getter";

  static $crossOrigin_Setter(mthis, value) native "HTMLScriptElement_crossOrigin_Setter";

  static $defer_Getter(mthis) native "HTMLScriptElement_defer_Getter";

  static $defer_Setter(mthis, value) native "HTMLScriptElement_defer_Setter";

  static $nonce_Getter(mthis) native "HTMLScriptElement_nonce_Getter";

  static $nonce_Setter(mthis, value) native "HTMLScriptElement_nonce_Setter";

  static $src_Getter(mthis) native "HTMLScriptElement_src_Getter";

  static $src_Setter(mthis, value) native "HTMLScriptElement_src_Setter";

  static $type_Getter(mthis) native "HTMLScriptElement_type_Getter";

  static $type_Setter(mthis, value) native "HTMLScriptElement_type_Setter";
}

class BlinkHTMLSelectElement {
  static $autofocus_Getter(mthis) native "HTMLSelectElement_autofocus_Getter";

  static $autofocus_Setter(mthis, value) native "HTMLSelectElement_autofocus_Setter";

  static $disabled_Getter(mthis) native "HTMLSelectElement_disabled_Getter";

  static $disabled_Setter(mthis, value) native "HTMLSelectElement_disabled_Setter";

  static $form_Getter(mthis) native "HTMLSelectElement_form_Getter";

  static $labels_Getter(mthis) native "HTMLSelectElement_labels_Getter";

  static $length_Getter(mthis) native "HTMLSelectElement_length_Getter";

  static $length_Setter(mthis, value) native "HTMLSelectElement_length_Setter";

  static $multiple_Getter(mthis) native "HTMLSelectElement_multiple_Getter";

  static $multiple_Setter(mthis, value) native "HTMLSelectElement_multiple_Setter";

  static $name_Getter(mthis) native "HTMLSelectElement_name_Getter";

  static $name_Setter(mthis, value) native "HTMLSelectElement_name_Setter";

  static $required_Getter(mthis) native "HTMLSelectElement_required_Getter";

  static $required_Setter(mthis, value) native "HTMLSelectElement_required_Setter";

  static $selectedIndex_Getter(mthis) native "HTMLSelectElement_selectedIndex_Getter";

  static $selectedIndex_Setter(mthis, value) native "HTMLSelectElement_selectedIndex_Setter";

  static $size_Getter(mthis) native "HTMLSelectElement_size_Getter";

  static $size_Setter(mthis, value) native "HTMLSelectElement_size_Setter";

  static $type_Getter(mthis) native "HTMLSelectElement_type_Getter";

  static $validationMessage_Getter(mthis) native "HTMLSelectElement_validationMessage_Getter";

  static $validity_Getter(mthis) native "HTMLSelectElement_validity_Getter";

  static $value_Getter(mthis) native "HTMLSelectElement_value_Getter";

  static $value_Setter(mthis, value) native "HTMLSelectElement_value_Setter";

  static $willValidate_Getter(mthis) native "HTMLSelectElement_willValidate_Getter";

  static $__setter___Callback(mthis, index, value) native "HTMLSelectElement___setter___Callback_RESOLVER_STRING_2_unsigned long_HTMLOptionElement";

  static $checkValidity_Callback(mthis) native "HTMLSelectElement_checkValidity_Callback_RESOLVER_STRING_0_";

  static $item_Callback(mthis, index) native "HTMLSelectElement_item_Callback_RESOLVER_STRING_1_unsigned long";

  static $namedItem_Callback(mthis, name) native "HTMLSelectElement_namedItem_Callback_RESOLVER_STRING_1_DOMString";

  static $setCustomValidity_Callback(mthis, error) native "HTMLSelectElement_setCustomValidity_Callback_RESOLVER_STRING_1_DOMString";
}

class BlinkHTMLShadowElement {
  static $resetStyleInheritance_Getter(mthis) native "HTMLShadowElement_resetStyleInheritance_Getter";

  static $resetStyleInheritance_Setter(mthis, value) native "HTMLShadowElement_resetStyleInheritance_Setter";

  static $getDistributedNodes_Callback(mthis) native "HTMLShadowElement_getDistributedNodes_Callback_RESOLVER_STRING_0_";
}

class BlinkHTMLSourceElement {
  static $media_Getter(mthis) native "HTMLSourceElement_media_Getter";

  static $media_Setter(mthis, value) native "HTMLSourceElement_media_Setter";

  static $src_Getter(mthis) native "HTMLSourceElement_src_Getter";

  static $src_Setter(mthis, value) native "HTMLSourceElement_src_Setter";

  static $type_Getter(mthis) native "HTMLSourceElement_type_Getter";

  static $type_Setter(mthis, value) native "HTMLSourceElement_type_Setter";
}

class BlinkHTMLSpanElement {}

class BlinkHTMLStyleElement {
  static $disabled_Getter(mthis) native "HTMLStyleElement_disabled_Getter";

  static $disabled_Setter(mthis, value) native "HTMLStyleElement_disabled_Setter";

  static $media_Getter(mthis) native "HTMLStyleElement_media_Getter";

  static $media_Setter(mthis, value) native "HTMLStyleElement_media_Setter";

  static $scoped_Getter(mthis) native "HTMLStyleElement_scoped_Getter";

  static $scoped_Setter(mthis, value) native "HTMLStyleElement_scoped_Setter";

  static $sheet_Getter(mthis) native "HTMLStyleElement_sheet_Getter";

  static $type_Getter(mthis) native "HTMLStyleElement_type_Getter";

  static $type_Setter(mthis, value) native "HTMLStyleElement_type_Setter";
}

class BlinkHTMLTableCaptionElement {}

class BlinkHTMLTableCellElement {
  static $cellIndex_Getter(mthis) native "HTMLTableCellElement_cellIndex_Getter";

  static $colSpan_Getter(mthis) native "HTMLTableCellElement_colSpan_Getter";

  static $colSpan_Setter(mthis, value) native "HTMLTableCellElement_colSpan_Setter";

  static $headers_Getter(mthis) native "HTMLTableCellElement_headers_Getter";

  static $headers_Setter(mthis, value) native "HTMLTableCellElement_headers_Setter";

  static $rowSpan_Getter(mthis) native "HTMLTableCellElement_rowSpan_Getter";

  static $rowSpan_Setter(mthis, value) native "HTMLTableCellElement_rowSpan_Setter";
}

class BlinkHTMLTableColElement {
  static $span_Getter(mthis) native "HTMLTableColElement_span_Getter";

  static $span_Setter(mthis, value) native "HTMLTableColElement_span_Setter";
}

class BlinkHTMLTableElement {
  static $caption_Getter(mthis) native "HTMLTableElement_caption_Getter";

  static $caption_Setter(mthis, value) native "HTMLTableElement_caption_Setter";

  static $rows_Getter(mthis) native "HTMLTableElement_rows_Getter";

  static $tBodies_Getter(mthis) native "HTMLTableElement_tBodies_Getter";

  static $tFoot_Getter(mthis) native "HTMLTableElement_tFoot_Getter";

  static $tFoot_Setter(mthis, value) native "HTMLTableElement_tFoot_Setter";

  static $tHead_Getter(mthis) native "HTMLTableElement_tHead_Getter";

  static $tHead_Setter(mthis, value) native "HTMLTableElement_tHead_Setter";

  static $createCaption_Callback(mthis) native "HTMLTableElement_createCaption_Callback_RESOLVER_STRING_0_";

  static $createTBody_Callback(mthis) native "HTMLTableElement_createTBody_Callback_RESOLVER_STRING_0_";

  static $createTFoot_Callback(mthis) native "HTMLTableElement_createTFoot_Callback_RESOLVER_STRING_0_";

  static $createTHead_Callback(mthis) native "HTMLTableElement_createTHead_Callback_RESOLVER_STRING_0_";

  static $deleteCaption_Callback(mthis) native "HTMLTableElement_deleteCaption_Callback_RESOLVER_STRING_0_";

  static $deleteRow_Callback(mthis, index) native "HTMLTableElement_deleteRow_Callback_RESOLVER_STRING_1_long";

  static $deleteTFoot_Callback(mthis) native "HTMLTableElement_deleteTFoot_Callback_RESOLVER_STRING_0_";

  static $deleteTHead_Callback(mthis) native "HTMLTableElement_deleteTHead_Callback_RESOLVER_STRING_0_";

  static $insertRow_Callback(mthis, index) native "HTMLTableElement_insertRow_Callback_RESOLVER_STRING_1_long";
}

class BlinkHTMLTableRowElement {
  static $cells_Getter(mthis) native "HTMLTableRowElement_cells_Getter";

  static $rowIndex_Getter(mthis) native "HTMLTableRowElement_rowIndex_Getter";

  static $sectionRowIndex_Getter(mthis) native "HTMLTableRowElement_sectionRowIndex_Getter";

  static $deleteCell_Callback(mthis, index) native "HTMLTableRowElement_deleteCell_Callback_RESOLVER_STRING_1_long";

  static $insertCell_Callback(mthis, index) native "HTMLTableRowElement_insertCell_Callback_RESOLVER_STRING_1_long";
}

class BlinkHTMLTableSectionElement {
  static $rows_Getter(mthis) native "HTMLTableSectionElement_rows_Getter";

  static $deleteRow_Callback(mthis, index) native "HTMLTableSectionElement_deleteRow_Callback_RESOLVER_STRING_1_long";

  static $insertRow_Callback(mthis, index) native "HTMLTableSectionElement_insertRow_Callback_RESOLVER_STRING_1_long";
}

class BlinkHTMLTemplateElement {
  static $content_Getter(mthis) native "HTMLTemplateElement_content_Getter";
}

class BlinkHTMLTextAreaElement {
  static $autofocus_Getter(mthis) native "HTMLTextAreaElement_autofocus_Getter";

  static $autofocus_Setter(mthis, value) native "HTMLTextAreaElement_autofocus_Setter";

  static $cols_Getter(mthis) native "HTMLTextAreaElement_cols_Getter";

  static $cols_Setter(mthis, value) native "HTMLTextAreaElement_cols_Setter";

  static $defaultValue_Getter(mthis) native "HTMLTextAreaElement_defaultValue_Getter";

  static $defaultValue_Setter(mthis, value) native "HTMLTextAreaElement_defaultValue_Setter";

  static $dirName_Getter(mthis) native "HTMLTextAreaElement_dirName_Getter";

  static $dirName_Setter(mthis, value) native "HTMLTextAreaElement_dirName_Setter";

  static $disabled_Getter(mthis) native "HTMLTextAreaElement_disabled_Getter";

  static $disabled_Setter(mthis, value) native "HTMLTextAreaElement_disabled_Setter";

  static $form_Getter(mthis) native "HTMLTextAreaElement_form_Getter";

  static $inputMode_Getter(mthis) native "HTMLTextAreaElement_inputMode_Getter";

  static $inputMode_Setter(mthis, value) native "HTMLTextAreaElement_inputMode_Setter";

  static $labels_Getter(mthis) native "HTMLTextAreaElement_labels_Getter";

  static $maxLength_Getter(mthis) native "HTMLTextAreaElement_maxLength_Getter";

  static $maxLength_Setter(mthis, value) native "HTMLTextAreaElement_maxLength_Setter";

  static $name_Getter(mthis) native "HTMLTextAreaElement_name_Getter";

  static $name_Setter(mthis, value) native "HTMLTextAreaElement_name_Setter";

  static $placeholder_Getter(mthis) native "HTMLTextAreaElement_placeholder_Getter";

  static $placeholder_Setter(mthis, value) native "HTMLTextAreaElement_placeholder_Setter";

  static $readOnly_Getter(mthis) native "HTMLTextAreaElement_readOnly_Getter";

  static $readOnly_Setter(mthis, value) native "HTMLTextAreaElement_readOnly_Setter";

  static $required_Getter(mthis) native "HTMLTextAreaElement_required_Getter";

  static $required_Setter(mthis, value) native "HTMLTextAreaElement_required_Setter";

  static $rows_Getter(mthis) native "HTMLTextAreaElement_rows_Getter";

  static $rows_Setter(mthis, value) native "HTMLTextAreaElement_rows_Setter";

  static $selectionDirection_Getter(mthis) native "HTMLTextAreaElement_selectionDirection_Getter";

  static $selectionDirection_Setter(mthis, value) native "HTMLTextAreaElement_selectionDirection_Setter";

  static $selectionEnd_Getter(mthis) native "HTMLTextAreaElement_selectionEnd_Getter";

  static $selectionEnd_Setter(mthis, value) native "HTMLTextAreaElement_selectionEnd_Setter";

  static $selectionStart_Getter(mthis) native "HTMLTextAreaElement_selectionStart_Getter";

  static $selectionStart_Setter(mthis, value) native "HTMLTextAreaElement_selectionStart_Setter";

  static $textLength_Getter(mthis) native "HTMLTextAreaElement_textLength_Getter";

  static $type_Getter(mthis) native "HTMLTextAreaElement_type_Getter";

  static $validationMessage_Getter(mthis) native "HTMLTextAreaElement_validationMessage_Getter";

  static $validity_Getter(mthis) native "HTMLTextAreaElement_validity_Getter";

  static $value_Getter(mthis) native "HTMLTextAreaElement_value_Getter";

  static $value_Setter(mthis, value) native "HTMLTextAreaElement_value_Setter";

  static $willValidate_Getter(mthis) native "HTMLTextAreaElement_willValidate_Getter";

  static $wrap_Getter(mthis) native "HTMLTextAreaElement_wrap_Getter";

  static $wrap_Setter(mthis, value) native "HTMLTextAreaElement_wrap_Setter";

  static $checkValidity_Callback(mthis) native "HTMLTextAreaElement_checkValidity_Callback_RESOLVER_STRING_0_";

  static $select_Callback(mthis) native "HTMLTextAreaElement_select_Callback_RESOLVER_STRING_0_";

  static $setCustomValidity_Callback(mthis, error) native "HTMLTextAreaElement_setCustomValidity_Callback_RESOLVER_STRING_1_DOMString";

  // Generated overload resolver
  static $setRangeText(mthis, replacement, start, end, selectionMode) {
    if ((replacement is String || replacement == null) && start == null && end == null && selectionMode == null) {
      $_setRangeText_1_Callback(mthis, replacement);
      return;
    }
    if ((selectionMode is String || selectionMode == null) && (end is int || end == null) && (start is int || start == null) && (replacement is String || replacement == null)) {
      $_setRangeText_2_Callback(mthis, replacement, start, end, selectionMode);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  static $_setRangeText_1_Callback(mthis, replacement) native "HTMLTextAreaElement_setRangeText_Callback_RESOLVER_STRING_1_DOMString";

  static $_setRangeText_2_Callback(mthis, replacement, start, end, selectionMode) native "HTMLTextAreaElement_setRangeText_Callback_RESOLVER_STRING_4_DOMString_unsigned long_unsigned long_DOMString";

  // Generated overload resolver
  static $setSelectionRange(mthis, start, end, direction) {
    if (direction != null) {
      $_setSelectionRange_1_Callback(mthis, start, end, direction);
      return;
    }
    $_setSelectionRange_2_Callback(mthis, start, end);
    return;
  }

  static $_setSelectionRange_1_Callback(mthis, start, end, direction) native "HTMLTextAreaElement_setSelectionRange_Callback_RESOLVER_STRING_3_long_long_DOMString";

  static $_setSelectionRange_2_Callback(mthis, start, end) native "HTMLTextAreaElement_setSelectionRange_Callback_RESOLVER_STRING_2_long_long";
}

class BlinkHTMLTitleElement {}

class BlinkHTMLTrackElement {
  static $default_Getter(mthis) native "HTMLTrackElement_default_Getter";

  static $default_Setter(mthis, value) native "HTMLTrackElement_default_Setter";

  static $kind_Getter(mthis) native "HTMLTrackElement_kind_Getter";

  static $kind_Setter(mthis, value) native "HTMLTrackElement_kind_Setter";

  static $label_Getter(mthis) native "HTMLTrackElement_label_Getter";

  static $label_Setter(mthis, value) native "HTMLTrackElement_label_Setter";

  static $readyState_Getter(mthis) native "HTMLTrackElement_readyState_Getter";

  static $src_Getter(mthis) native "HTMLTrackElement_src_Getter";

  static $src_Setter(mthis, value) native "HTMLTrackElement_src_Setter";

  static $srclang_Getter(mthis) native "HTMLTrackElement_srclang_Getter";

  static $srclang_Setter(mthis, value) native "HTMLTrackElement_srclang_Setter";

  static $track_Getter(mthis) native "HTMLTrackElement_track_Getter";
}

class BlinkHTMLUListElement {}

class BlinkHTMLUnknownElement {}

class BlinkHTMLVideoElement {
  static $height_Getter(mthis) native "HTMLVideoElement_height_Getter";

  static $height_Setter(mthis, value) native "HTMLVideoElement_height_Setter";

  static $poster_Getter(mthis) native "HTMLVideoElement_poster_Getter";

  static $poster_Setter(mthis, value) native "HTMLVideoElement_poster_Setter";

  static $videoHeight_Getter(mthis) native "HTMLVideoElement_videoHeight_Getter";

  static $videoWidth_Getter(mthis) native "HTMLVideoElement_videoWidth_Getter";

  static $webkitDecodedFrameCount_Getter(mthis) native "HTMLVideoElement_webkitDecodedFrameCount_Getter";

  static $webkitDroppedFrameCount_Getter(mthis) native "HTMLVideoElement_webkitDroppedFrameCount_Getter";

  static $width_Getter(mthis) native "HTMLVideoElement_width_Getter";

  static $width_Setter(mthis, value) native "HTMLVideoElement_width_Setter";

  static $getVideoPlaybackQuality_Callback(mthis) native "HTMLVideoElement_getVideoPlaybackQuality_Callback_RESOLVER_STRING_0_";

  static $webkitEnterFullscreen_Callback(mthis) native "HTMLVideoElement_webkitEnterFullscreen_Callback_RESOLVER_STRING_0_";

  static $webkitExitFullscreen_Callback(mthis) native "HTMLVideoElement_webkitExitFullscreen_Callback_RESOLVER_STRING_0_";
}

class BlinkHashChangeEvent {
  static $newURL_Getter(mthis) native "HashChangeEvent_newURL_Getter";

  static $oldURL_Getter(mthis) native "HashChangeEvent_oldURL_Getter";

  static $initHashChangeEvent_Callback(mthis, type, canBubble, cancelable, oldURL, newURL) native "HashChangeEvent_initHashChangeEvent_Callback_RESOLVER_STRING_5_DOMString_boolean_boolean_DOMString_DOMString";
}

class BlinkHistory {
  static $length_Getter(mthis) native "History_length_Getter";

  static $state_Getter(mthis) native "History_state_Getter";

  static $back_Callback(mthis) native "History_back_Callback_RESOLVER_STRING_0_";

  static $forward_Callback(mthis) native "History_forward_Callback_RESOLVER_STRING_0_";

  static $go_Callback(mthis, distance) native "History_go_Callback_RESOLVER_STRING_1_long";

  static $pushState_Callback(mthis, data, title, url) native "History_pushState_Callback";

  static $replaceState_Callback(mthis, data, title, url) native "History_replaceState_Callback";
}

class BlinkIDBCursor {
  static $direction_Getter(mthis) native "IDBCursor_direction_Getter";

  static $key_Getter(mthis) native "IDBCursor_key_Getter";

  static $primaryKey_Getter(mthis) native "IDBCursor_primaryKey_Getter";

  static $source_Getter(mthis) native "IDBCursor_source_Getter";

  static $advance_Callback(mthis, count) native "IDBCursor_advance_Callback_RESOLVER_STRING_1_unsigned long";

  static $continuePrimaryKey_Callback(mthis, key, primaryKey) native "IDBCursor_continuePrimaryKey_Callback_RESOLVER_STRING_2_ScriptValue_ScriptValue";

  static $delete_Callback(mthis) native "IDBCursor_delete_Callback_RESOLVER_STRING_0_";

  static $next_Callback(mthis, key) native "IDBCursor_continue_Callback_RESOLVER_STRING_1_ScriptValue";

  static $update_Callback(mthis, value) native "IDBCursor_update_Callback_RESOLVER_STRING_1_ScriptValue";
}

class BlinkIDBCursorWithValue {
  static $value_Getter(mthis) native "IDBCursorWithValue_value_Getter";
}

class BlinkIDBDatabase {
  static $name_Getter(mthis) native "IDBDatabase_name_Getter";

  static $objectStoreNames_Getter(mthis) native "IDBDatabase_objectStoreNames_Getter";

  static $version_Getter(mthis) native "IDBDatabase_version_Getter";

  static $close_Callback(mthis) native "IDBDatabase_close_Callback_RESOLVER_STRING_0_";

  static $createObjectStore_Callback(mthis, name, options) native "IDBDatabase_createObjectStore_Callback_RESOLVER_STRING_2_DOMString_Dictionary";

  static $deleteObjectStore_Callback(mthis, name) native "IDBDatabase_deleteObjectStore_Callback_RESOLVER_STRING_1_DOMString";

  // Generated overload resolver
  static $transaction(mthis, storeName_OR_storeNames, mode) {
    if ((mode is String || mode == null) && (storeName_OR_storeNames is List<String> || storeName_OR_storeNames == null)) {
      return $_transaction_1_Callback(mthis, storeName_OR_storeNames, mode);
    }
    if ((mode is String || mode == null) && (storeName_OR_storeNames is List<String> || storeName_OR_storeNames == null)) {
      return $_transaction_2_Callback(mthis, storeName_OR_storeNames, mode);
    }
    if ((mode is String || mode == null) && (storeName_OR_storeNames is String || storeName_OR_storeNames == null)) {
      return $_transaction_3_Callback(mthis, storeName_OR_storeNames, mode);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  static $_transaction_1_Callback(mthis, storeName_OR_storeNames, mode) native "IDBDatabase_transaction_Callback_RESOLVER_STRING_2_DOMStringList_DOMString";

  static $_transaction_2_Callback(mthis, storeName_OR_storeNames, mode) native "IDBDatabase_transaction_Callback_RESOLVER_STRING_2_sequence<DOMString>_DOMString";

  static $_transaction_3_Callback(mthis, storeName_OR_storeNames, mode) native "IDBDatabase_transaction_Callback_RESOLVER_STRING_2_DOMString_DOMString";

  static $transactionList_Callback(mthis, storeNames, mode) native "IDBDatabase_transaction_Callback_RESOLVER_STRING_2_sequence<DOMString>_DOMString";

  static $transactionStore_Callback(mthis, storeName, mode) native "IDBDatabase_transaction_Callback_RESOLVER_STRING_2_DOMString_DOMString";

  static $transactionStores_Callback(mthis, storeNames, mode) native "IDBDatabase_transaction_Callback_RESOLVER_STRING_2_DOMStringList_DOMString";
}

class BlinkIDBFactory {
  static $cmp_Callback(mthis, first, second) native "IDBFactory_cmp_Callback_RESOLVER_STRING_2_ScriptValue_ScriptValue";

  static $deleteDatabase_Callback(mthis, name) native "IDBFactory_deleteDatabase_Callback_RESOLVER_STRING_1_DOMString";

  // Generated overload resolver
  static $_open(mthis, name, version) {
    if (version != null) {
      return $_open_1_Callback(mthis, name, version);
    }
    return $_open_2_Callback(mthis, name);
  }

  static $_open_1_Callback(mthis, name, version) native "IDBFactory_open_Callback_RESOLVER_STRING_2_DOMString_unsigned long long";

  static $_open_2_Callback(mthis, name) native "IDBFactory_open_Callback_RESOLVER_STRING_1_DOMString";

  static $webkitGetDatabaseNames_Callback(mthis) native "IDBFactory_webkitGetDatabaseNames_Callback_RESOLVER_STRING_0_";
}

class BlinkIDBIndex {
  static $keyPath_Getter(mthis) native "IDBIndex_keyPath_Getter";

  static $multiEntry_Getter(mthis) native "IDBIndex_multiEntry_Getter";

  static $name_Getter(mthis) native "IDBIndex_name_Getter";

  static $objectStore_Getter(mthis) native "IDBIndex_objectStore_Getter";

  static $unique_Getter(mthis) native "IDBIndex_unique_Getter";

  static $count_Callback(mthis, key) native "IDBIndex_count_Callback_RESOLVER_STRING_1_ScriptValue";

  static $get_Callback(mthis, key) native "IDBIndex_get_Callback_RESOLVER_STRING_1_ScriptValue";

  static $getKey_Callback(mthis, key) native "IDBIndex_getKey_Callback_RESOLVER_STRING_1_ScriptValue";

  static $openCursor_Callback(mthis, key, direction) native "IDBIndex_openCursor_Callback_RESOLVER_STRING_2_ScriptValue_DOMString";

  static $openKeyCursor_Callback(mthis, key, direction) native "IDBIndex_openKeyCursor_Callback_RESOLVER_STRING_2_ScriptValue_DOMString";
}

class BlinkIDBKeyRange {
  static $lower_Getter(mthis) native "IDBKeyRange_lower_Getter";

  static $lowerOpen_Getter(mthis) native "IDBKeyRange_lowerOpen_Getter";

  static $upper_Getter(mthis) native "IDBKeyRange_upper_Getter";

  static $upperOpen_Getter(mthis) native "IDBKeyRange_upperOpen_Getter";

  static $bound__Callback(lower, upper, lowerOpen, upperOpen) native "IDBKeyRange_bound_Callback_RESOLVER_STRING_4_ScriptValue_ScriptValue_boolean_boolean";

  static $lowerBound__Callback(bound, open) native "IDBKeyRange_lowerBound_Callback_RESOLVER_STRING_2_ScriptValue_boolean";

  static $only__Callback(value) native "IDBKeyRange_only_Callback_RESOLVER_STRING_1_ScriptValue";

  static $upperBound__Callback(bound, open) native "IDBKeyRange_upperBound_Callback_RESOLVER_STRING_2_ScriptValue_boolean";
}

class BlinkIDBObjectStore {
  static $autoIncrement_Getter(mthis) native "IDBObjectStore_autoIncrement_Getter";

  static $indexNames_Getter(mthis) native "IDBObjectStore_indexNames_Getter";

  static $keyPath_Getter(mthis) native "IDBObjectStore_keyPath_Getter";

  static $name_Getter(mthis) native "IDBObjectStore_name_Getter";

  static $transaction_Getter(mthis) native "IDBObjectStore_transaction_Getter";

  static $add_Callback(mthis, value, key) native "IDBObjectStore_add_Callback_RESOLVER_STRING_2_ScriptValue_ScriptValue";

  static $clear_Callback(mthis) native "IDBObjectStore_clear_Callback_RESOLVER_STRING_0_";

  static $count_Callback(mthis, key) native "IDBObjectStore_count_Callback_RESOLVER_STRING_1_ScriptValue";

  // Generated overload resolver
  static $_createIndex(mthis, name, keyPath, options) {
    if ((options is Map || options == null) && (keyPath is List<String> || keyPath == null) && (name is String || name == null)) {
      return $_createIndex_1_Callback(mthis, name, keyPath, options);
    }
    if ((options is Map || options == null) && (keyPath is String || keyPath == null) && (name is String || name == null)) {
      return $_createIndex_2_Callback(mthis, name, keyPath, options);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  static $_createIndex_1_Callback(mthis, name, keyPath, options) native "IDBObjectStore_createIndex_Callback_RESOLVER_STRING_3_DOMString_sequence<DOMString>_Dictionary";

  static $_createIndex_2_Callback(mthis, name, keyPath, options) native "IDBObjectStore_createIndex_Callback_RESOLVER_STRING_3_DOMString_DOMString_Dictionary";

  static $delete_Callback(mthis, key) native "IDBObjectStore_delete_Callback_RESOLVER_STRING_1_ScriptValue";

  static $deleteIndex_Callback(mthis, name) native "IDBObjectStore_deleteIndex_Callback_RESOLVER_STRING_1_DOMString";

  static $get_Callback(mthis, key) native "IDBObjectStore_get_Callback_RESOLVER_STRING_1_ScriptValue";

  static $index_Callback(mthis, name) native "IDBObjectStore_index_Callback_RESOLVER_STRING_1_DOMString";

  static $openCursor_Callback(mthis, key, direction) native "IDBObjectStore_openCursor_Callback_RESOLVER_STRING_2_ScriptValue_DOMString";

  static $openKeyCursor_Callback(mthis, range, direction) native "IDBObjectStore_openKeyCursor_Callback_RESOLVER_STRING_2_ScriptValue_DOMString";

  static $put_Callback(mthis, value, key) native "IDBObjectStore_put_Callback_RESOLVER_STRING_2_ScriptValue_ScriptValue";
}

class BlinkIDBRequest {
  static $error_Getter(mthis) native "IDBRequest_error_Getter";

  static $readyState_Getter(mthis) native "IDBRequest_readyState_Getter";

  static $result_Getter(mthis) native "IDBRequest_result_Getter";

  static $source_Getter(mthis) native "IDBRequest_source_Getter";

  static $transaction_Getter(mthis) native "IDBRequest_transaction_Getter";
}

class BlinkIDBOpenDBRequest {}

class BlinkIDBTransaction {
  static $db_Getter(mthis) native "IDBTransaction_db_Getter";

  static $error_Getter(mthis) native "IDBTransaction_error_Getter";

  static $mode_Getter(mthis) native "IDBTransaction_mode_Getter";

  static $abort_Callback(mthis) native "IDBTransaction_abort_Callback_RESOLVER_STRING_0_";

  static $objectStore_Callback(mthis, name) native "IDBTransaction_objectStore_Callback_RESOLVER_STRING_1_DOMString";
}

class BlinkIDBVersionChangeEvent {
  static $dataLoss_Getter(mthis) native "IDBVersionChangeEvent_dataLoss_Getter";

  static $dataLossMessage_Getter(mthis) native "IDBVersionChangeEvent_dataLossMessage_Getter";

  static $newVersion_Getter(mthis) native "IDBVersionChangeEvent_newVersion_Getter";

  static $oldVersion_Getter(mthis) native "IDBVersionChangeEvent_oldVersion_Getter";
}

class BlinkImageBitmap {
  static $height_Getter(mthis) native "ImageBitmap_height_Getter";

  static $width_Getter(mthis) native "ImageBitmap_width_Getter";
}

class BlinkImageData {
  static $data_Getter(mthis) native "ImageData_data_Getter";

  static $height_Getter(mthis) native "ImageData_height_Getter";

  static $width_Getter(mthis) native "ImageData_width_Getter";
}

class BlinkInjectedScriptHost {
  static $inspect_Callback(mthis, objectId, hints) native "InjectedScriptHost_inspect_Callback";
}

class BlinkInputMethodContext {
  static $compositionEndOffset_Getter(mthis) native "InputMethodContext_compositionEndOffset_Getter";

  static $compositionStartOffset_Getter(mthis) native "InputMethodContext_compositionStartOffset_Getter";

  static $locale_Getter(mthis) native "InputMethodContext_locale_Getter";

  static $target_Getter(mthis) native "InputMethodContext_target_Getter";

  static $confirmComposition_Callback(mthis) native "InputMethodContext_confirmComposition_Callback_RESOLVER_STRING_0_";
}

class BlinkInstallPhaseEvent {
  static $waitUntil_Callback(mthis, value) native "InstallPhaseEvent_waitUntil_Callback_RESOLVER_STRING_1_ScriptValue";
}

class BlinkInstallEvent {
  static $replace_Callback(mthis) native "InstallEvent_replace_Callback_RESOLVER_STRING_0_";
}

class BlinkKey {
  static $algorithm_Getter(mthis) native "Key_algorithm_Getter";

  static $extractable_Getter(mthis) native "Key_extractable_Getter";

  static $type_Getter(mthis) native "Key_type_Getter";

  static $usages_Getter(mthis) native "Key_usages_Getter";
}

class BlinkKeyPair {
  static $privateKey_Getter(mthis) native "KeyPair_privateKey_Getter";

  static $publicKey_Getter(mthis) native "KeyPair_publicKey_Getter";
}

class BlinkKeyboardEvent {
  static $altGraphKey_Getter(mthis) native "KeyboardEvent_altGraphKey_Getter";

  static $altKey_Getter(mthis) native "KeyboardEvent_altKey_Getter";

  static $ctrlKey_Getter(mthis) native "KeyboardEvent_ctrlKey_Getter";

  static $keyIdentifier_Getter(mthis) native "KeyboardEvent_keyIdentifier_Getter";

  static $keyLocation_Getter(mthis) native "KeyboardEvent_keyLocation_Getter";

  static $location_Getter(mthis) native "KeyboardEvent_location_Getter";

  static $metaKey_Getter(mthis) native "KeyboardEvent_metaKey_Getter";

  static $repeat_Getter(mthis) native "KeyboardEvent_repeat_Getter";

  static $shiftKey_Getter(mthis) native "KeyboardEvent_shiftKey_Getter";

  static $getModifierState_Callback(mthis, keyArgument) native "KeyboardEvent_getModifierState_Callback_RESOLVER_STRING_1_DOMString";

  static $initKeyboardEvent_Callback(mthis, type, canBubble, cancelable, view, keyIdentifier, location, ctrlKey, altKey, shiftKey, metaKey, altGraphKey) native "KeyboardEvent_initKeyboardEvent_Callback_RESOLVER_STRING_11_DOMString_boolean_boolean_Window_DOMString_unsigned long_boolean_boolean_boolean_boolean_boolean";
}

class BlinkLocation {
  static $ancestorOrigins_Getter(mthis) native "Location_ancestorOrigins_Getter";

  static $hash_Getter(mthis) native "Location_hash_Getter";

  static $hash_Setter(mthis, value) native "Location_hash_Setter";

  static $host_Getter(mthis) native "Location_host_Getter";

  static $host_Setter(mthis, value) native "Location_host_Setter";

  static $hostname_Getter(mthis) native "Location_hostname_Getter";

  static $hostname_Setter(mthis, value) native "Location_hostname_Setter";

  static $href_Getter(mthis) native "Location_href_Getter";

  static $href_Setter(mthis, value) native "Location_href_Setter";

  static $origin_Getter(mthis) native "Location_origin_Getter";

  static $pathname_Getter(mthis) native "Location_pathname_Getter";

  static $pathname_Setter(mthis, value) native "Location_pathname_Setter";

  static $port_Getter(mthis) native "Location_port_Getter";

  static $port_Setter(mthis, value) native "Location_port_Setter";

  static $protocol_Getter(mthis) native "Location_protocol_Getter";

  static $protocol_Setter(mthis, value) native "Location_protocol_Setter";

  static $search_Getter(mthis) native "Location_search_Getter";

  static $search_Setter(mthis, value) native "Location_search_Setter";

  static $assign_Callback(mthis, url) native "Location_assign_Callback";

  static $reload_Callback(mthis) native "Location_reload_Callback";

  static $replace_Callback(mthis, url) native "Location_replace_Callback";

  static $toString_Callback(mthis) native "Location_toString_Callback_RESOLVER_STRING_0_";
}

class BlinkMIDIAccess {
  static $inputs_Callback(mthis) native "MIDIAccess_inputs_Callback_RESOLVER_STRING_0_";

  static $outputs_Callback(mthis) native "MIDIAccess_outputs_Callback_RESOLVER_STRING_0_";
}

class BlinkMIDIAccessPromise {
  static $then_Callback(mthis, successCallback, errorCallback) native "MIDIAccessPromise_then_Callback_RESOLVER_STRING_2_MIDISuccessCallback_MIDIErrorCallback";
}

class BlinkMIDIConnectionEvent {
  static $port_Getter(mthis) native "MIDIConnectionEvent_port_Getter";
}

class BlinkMIDIPort {
  static $id_Getter(mthis) native "MIDIPort_id_Getter";

  static $manufacturer_Getter(mthis) native "MIDIPort_manufacturer_Getter";

  static $name_Getter(mthis) native "MIDIPort_name_Getter";

  static $type_Getter(mthis) native "MIDIPort_type_Getter";

  static $version_Getter(mthis) native "MIDIPort_version_Getter";
}

class BlinkMIDIInput {}

class BlinkMIDIMessageEvent {
  static $data_Getter(mthis) native "MIDIMessageEvent_data_Getter";

  static $receivedTime_Getter(mthis) native "MIDIMessageEvent_receivedTime_Getter";
}

class BlinkMIDIOutput {
  // Generated overload resolver
  static $send(mthis, data, timestamp) {
    if (timestamp != null) {
      $_send_1_Callback(mthis, data, timestamp);
      return;
    }
    $_send_2_Callback(mthis, data);
    return;
  }

  static $_send_1_Callback(mthis, data, timestamp) native "MIDIOutput_send_Callback_RESOLVER_STRING_2_Uint8Array_double";

  static $_send_2_Callback(mthis, data) native "MIDIOutput_send_Callback_RESOLVER_STRING_1_Uint8Array";
}

class BlinkMediaController {
  // Generated overload resolver
  static $mkMediaController() {
    return $_create_1constructorCallback();
  }

  static $_create_1constructorCallback() native "MediaController_constructorCallback_RESOLVER_STRING_0_";

  static $buffered_Getter(mthis) native "MediaController_buffered_Getter";

  static $currentTime_Getter(mthis) native "MediaController_currentTime_Getter";

  static $currentTime_Setter(mthis, value) native "MediaController_currentTime_Setter";

  static $defaultPlaybackRate_Getter(mthis) native "MediaController_defaultPlaybackRate_Getter";

  static $defaultPlaybackRate_Setter(mthis, value) native "MediaController_defaultPlaybackRate_Setter";

  static $duration_Getter(mthis) native "MediaController_duration_Getter";

  static $muted_Getter(mthis) native "MediaController_muted_Getter";

  static $muted_Setter(mthis, value) native "MediaController_muted_Setter";

  static $paused_Getter(mthis) native "MediaController_paused_Getter";

  static $playbackRate_Getter(mthis) native "MediaController_playbackRate_Getter";

  static $playbackRate_Setter(mthis, value) native "MediaController_playbackRate_Setter";

  static $playbackState_Getter(mthis) native "MediaController_playbackState_Getter";

  static $played_Getter(mthis) native "MediaController_played_Getter";

  static $seekable_Getter(mthis) native "MediaController_seekable_Getter";

  static $volume_Getter(mthis) native "MediaController_volume_Getter";

  static $volume_Setter(mthis, value) native "MediaController_volume_Setter";

  static $pause_Callback(mthis) native "MediaController_pause_Callback_RESOLVER_STRING_0_";

  static $play_Callback(mthis) native "MediaController_play_Callback_RESOLVER_STRING_0_";

  static $unpause_Callback(mthis) native "MediaController_unpause_Callback_RESOLVER_STRING_0_";
}

class BlinkMediaElementAudioSourceNode {
  static $mediaElement_Getter(mthis) native "MediaElementAudioSourceNode_mediaElement_Getter";
}

class BlinkMediaError {
  static $code_Getter(mthis) native "MediaError_code_Getter";
}

class BlinkMediaKeyError {
  static $code_Getter(mthis) native "MediaKeyError_code_Getter";

  static $systemCode_Getter(mthis) native "MediaKeyError_systemCode_Getter";
}

class BlinkMediaKeyEvent {
  static $defaultURL_Getter(mthis) native "MediaKeyEvent_defaultURL_Getter";

  static $errorCode_Getter(mthis) native "MediaKeyEvent_errorCode_Getter";

  static $initData_Getter(mthis) native "MediaKeyEvent_initData_Getter";

  static $keySystem_Getter(mthis) native "MediaKeyEvent_keySystem_Getter";

  static $message_Getter(mthis) native "MediaKeyEvent_message_Getter";

  static $sessionId_Getter(mthis) native "MediaKeyEvent_sessionId_Getter";

  static $systemCode_Getter(mthis) native "MediaKeyEvent_systemCode_Getter";
}

class BlinkMediaKeyMessageEvent {
  static $destinationURL_Getter(mthis) native "MediaKeyMessageEvent_destinationURL_Getter";

  static $message_Getter(mthis) native "MediaKeyMessageEvent_message_Getter";
}

class BlinkMediaKeyNeededEvent {
  static $contentType_Getter(mthis) native "MediaKeyNeededEvent_contentType_Getter";

  static $initData_Getter(mthis) native "MediaKeyNeededEvent_initData_Getter";
}

class BlinkMediaKeySession {
  static $error_Getter(mthis) native "MediaKeySession_error_Getter";

  static $keySystem_Getter(mthis) native "MediaKeySession_keySystem_Getter";

  static $sessionId_Getter(mthis) native "MediaKeySession_sessionId_Getter";

  static $release_Callback(mthis) native "MediaKeySession_release_Callback_RESOLVER_STRING_0_";

  static $update_Callback(mthis, response) native "MediaKeySession_update_Callback_RESOLVER_STRING_1_Uint8Array";
}

class BlinkMediaKeys {
  // Generated overload resolver
  static $mkMediaKeys(keySystem) {
    return $_create_1constructorCallback(keySystem);
  }

  static $_create_1constructorCallback(keySystem) native "MediaKeys_constructorCallback_RESOLVER_STRING_1_DOMString";

  static $keySystem_Getter(mthis) native "MediaKeys_keySystem_Getter";

  static $createSession_Callback(mthis, type, initData) native "MediaKeys_createSession_Callback_RESOLVER_STRING_2_DOMString_Uint8Array";
}

class BlinkMediaList {
  static $length_Getter(mthis) native "MediaList_length_Getter";

  static $mediaText_Getter(mthis) native "MediaList_mediaText_Getter";

  static $mediaText_Setter(mthis, value) native "MediaList_mediaText_Setter";

  static $appendMedium_Callback(mthis, newMedium) native "MediaList_appendMedium_Callback_RESOLVER_STRING_1_DOMString";

  static $deleteMedium_Callback(mthis, oldMedium) native "MediaList_deleteMedium_Callback_RESOLVER_STRING_1_DOMString";

  static $item_Callback(mthis, index) native "MediaList_item_Callback_RESOLVER_STRING_1_unsigned long";
}

class BlinkMediaQueryList {
  static $matches_Getter(mthis) native "MediaQueryList_matches_Getter";

  static $media_Getter(mthis) native "MediaQueryList_media_Getter";
}

class BlinkMediaSource {
  // Generated overload resolver
  static $mkMediaSource() {
    return $_create_1constructorCallback();
  }

  static $_create_1constructorCallback() native "MediaSource_constructorCallback_RESOLVER_STRING_0_";

  static $activeSourceBuffers_Getter(mthis) native "MediaSource_activeSourceBuffers_Getter";

  static $duration_Getter(mthis) native "MediaSource_duration_Getter";

  static $duration_Setter(mthis, value) native "MediaSource_duration_Setter";

  static $readyState_Getter(mthis) native "MediaSource_readyState_Getter";

  static $sourceBuffers_Getter(mthis) native "MediaSource_sourceBuffers_Getter";

  static $addSourceBuffer_Callback(mthis, type) native "MediaSource_addSourceBuffer_Callback_RESOLVER_STRING_1_DOMString";

  // Generated overload resolver
  static $endOfStream(mthis, error) {
    if (error != null) {
      $_endOfStream_1_Callback(mthis, error);
      return;
    }
    $_endOfStream_2_Callback(mthis);
    return;
  }

  static $_endOfStream_1_Callback(mthis, error) native "MediaSource_endOfStream_Callback_RESOLVER_STRING_1_DOMString";

  static $_endOfStream_2_Callback(mthis) native "MediaSource_endOfStream_Callback_RESOLVER_STRING_0_";

  static $isTypeSupported_Callback(type) native "MediaSource_isTypeSupported_Callback_RESOLVER_STRING_1_DOMString";

  static $removeSourceBuffer_Callback(mthis, buffer) native "MediaSource_removeSourceBuffer_Callback_RESOLVER_STRING_1_SourceBuffer";
}

class BlinkMediaStream {
  // Generated overload resolver
  static $mkMediaStream(stream_OR_tracks) {
    if (stream_OR_tracks == null) {
      return $_create_1constructorCallback();
    }
    if ((stream_OR_tracks is MediaStream || stream_OR_tracks == null)) {
      return $_create_2constructorCallback(stream_OR_tracks);
    }
    if ((stream_OR_tracks is List<MediaStreamTrack> || stream_OR_tracks == null)) {
      return $_create_3constructorCallback(stream_OR_tracks);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  static $_create_1constructorCallback() native "MediaStream_constructorCallback_RESOLVER_STRING_0_";

  static $_create_2constructorCallback(stream_OR_tracks) native "MediaStream_constructorCallback_RESOLVER_STRING_1_MediaStream";

  static $_create_3constructorCallback(stream_OR_tracks) native "MediaStream_constructorCallback_RESOLVER_STRING_1_MediaStreamTrack[]";

  static $ended_Getter(mthis) native "MediaStream_ended_Getter";

  static $id_Getter(mthis) native "MediaStream_id_Getter";

  static $label_Getter(mthis) native "MediaStream_label_Getter";

  static $addTrack_Callback(mthis, track) native "MediaStream_addTrack_Callback_RESOLVER_STRING_1_MediaStreamTrack";

  static $getAudioTracks_Callback(mthis) native "MediaStream_getAudioTracks_Callback_RESOLVER_STRING_0_";

  static $getTrackById_Callback(mthis, trackId) native "MediaStream_getTrackById_Callback_RESOLVER_STRING_1_DOMString";

  static $getVideoTracks_Callback(mthis) native "MediaStream_getVideoTracks_Callback_RESOLVER_STRING_0_";

  static $removeTrack_Callback(mthis, track) native "MediaStream_removeTrack_Callback_RESOLVER_STRING_1_MediaStreamTrack";

  static $stop_Callback(mthis) native "MediaStream_stop_Callback_RESOLVER_STRING_0_";
}

class BlinkMediaStreamAudioDestinationNode {
  static $stream_Getter(mthis) native "MediaStreamAudioDestinationNode_stream_Getter";
}

class BlinkMediaStreamAudioSourceNode {
  static $mediaStream_Getter(mthis) native "MediaStreamAudioSourceNode_mediaStream_Getter";
}

class BlinkMediaStreamEvent {
  static $stream_Getter(mthis) native "MediaStreamEvent_stream_Getter";
}

class BlinkMediaStreamTrack {
  static $enabled_Getter(mthis) native "MediaStreamTrack_enabled_Getter";

  static $enabled_Setter(mthis, value) native "MediaStreamTrack_enabled_Setter";

  static $id_Getter(mthis) native "MediaStreamTrack_id_Getter";

  static $kind_Getter(mthis) native "MediaStreamTrack_kind_Getter";

  static $label_Getter(mthis) native "MediaStreamTrack_label_Getter";

  static $readyState_Getter(mthis) native "MediaStreamTrack_readyState_Getter";

  static $getSources_Callback(callback) native "MediaStreamTrack_getSources_Callback_RESOLVER_STRING_1_MediaStreamTrackSourcesCallback";

  static $stop_Callback(mthis) native "MediaStreamTrack_stop_Callback_RESOLVER_STRING_0_";
}

class BlinkMediaStreamTrackEvent {
  static $track_Getter(mthis) native "MediaStreamTrackEvent_track_Getter";
}

class BlinkMemoryInfo {
  static $jsHeapSizeLimit_Getter(mthis) native "MemoryInfo_jsHeapSizeLimit_Getter";

  static $totalJSHeapSize_Getter(mthis) native "MemoryInfo_totalJSHeapSize_Getter";

  static $usedJSHeapSize_Getter(mthis) native "MemoryInfo_usedJSHeapSize_Getter";
}

class BlinkMessageChannel {
  static $port1_Getter(mthis) native "MessageChannel_port1_Getter";

  static $port2_Getter(mthis) native "MessageChannel_port2_Getter";
}

class BlinkMessageEvent {
  static $data_Getter(mthis) native "MessageEvent_data_Getter";

  static $lastEventId_Getter(mthis) native "MessageEvent_lastEventId_Getter";

  static $origin_Getter(mthis) native "MessageEvent_origin_Getter";

  static $source_Getter(mthis) native "MessageEvent_source_Getter";

  static $initMessageEvent_Callback(mthis, typeArg, canBubbleArg, cancelableArg, dataArg, originArg, lastEventIdArg, sourceArg, messagePorts) native "MessageEvent_initMessageEvent_Callback";
}

class BlinkMessagePort {
  static $close_Callback(mthis) native "MessagePort_close_Callback_RESOLVER_STRING_0_";

  static $postMessage_Callback(mthis, message, messagePorts) native "MessagePort_postMessage_Callback";

  static $start_Callback(mthis) native "MessagePort_start_Callback_RESOLVER_STRING_0_";
}

class BlinkMetadata {
  static $modificationTime_Getter(mthis) native "Metadata_modificationTime_Getter";

  static $size_Getter(mthis) native "Metadata_size_Getter";
}

class BlinkMimeType {
  static $description_Getter(mthis) native "MimeType_description_Getter";

  static $enabledPlugin_Getter(mthis) native "MimeType_enabledPlugin_Getter";

  static $suffixes_Getter(mthis) native "MimeType_suffixes_Getter";

  static $type_Getter(mthis) native "MimeType_type_Getter";
}

class BlinkMimeTypeArray {
  static $length_Getter(mthis) native "MimeTypeArray_length_Getter";

  static $NativeIndexed_Getter(mthis, index) native "MimeTypeArray_item_Callback_RESOLVER_STRING_1_unsigned long";

  static $__getter___Callback(mthis, name) native "MimeTypeArray___getter___Callback_RESOLVER_STRING_1_DOMString";

  static $item_Callback(mthis, index) native "MimeTypeArray_item_Callback_RESOLVER_STRING_1_unsigned long";

  static $namedItem_Callback(mthis, name) native "MimeTypeArray_namedItem_Callback_RESOLVER_STRING_1_DOMString";
}

class BlinkMouseEvent {
  static $altKey_Getter(mthis) native "MouseEvent_altKey_Getter";

  static $button_Getter(mthis) native "MouseEvent_button_Getter";

  static $clientX_Getter(mthis) native "MouseEvent_clientX_Getter";

  static $clientY_Getter(mthis) native "MouseEvent_clientY_Getter";

  static $ctrlKey_Getter(mthis) native "MouseEvent_ctrlKey_Getter";

  static $dataTransfer_Getter(mthis) native "MouseEvent_dataTransfer_Getter";

  static $fromElement_Getter(mthis) native "MouseEvent_fromElement_Getter";

  static $metaKey_Getter(mthis) native "MouseEvent_metaKey_Getter";

  static $offsetX_Getter(mthis) native "MouseEvent_offsetX_Getter";

  static $offsetY_Getter(mthis) native "MouseEvent_offsetY_Getter";

  static $relatedTarget_Getter(mthis) native "MouseEvent_relatedTarget_Getter";

  static $screenX_Getter(mthis) native "MouseEvent_screenX_Getter";

  static $screenY_Getter(mthis) native "MouseEvent_screenY_Getter";

  static $shiftKey_Getter(mthis) native "MouseEvent_shiftKey_Getter";

  static $toElement_Getter(mthis) native "MouseEvent_toElement_Getter";

  static $webkitMovementX_Getter(mthis) native "MouseEvent_webkitMovementX_Getter";

  static $webkitMovementY_Getter(mthis) native "MouseEvent_webkitMovementY_Getter";

  static $initMouseEvent_Callback(mthis, type, canBubble, cancelable, view, detail, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey, button, relatedTarget) native "MouseEvent_initMouseEvent_Callback_RESOLVER_STRING_15_DOMString_boolean_boolean_Window_long_long_long_long_long_boolean_boolean_boolean_boolean_unsigned short_EventTarget";
}

class BlinkMutationEvent {}

class BlinkMutationObserver {
  static $constructorCallback(callback) native "MutationObserver_constructorCallback";

  static $disconnect_Callback(mthis) native "MutationObserver_disconnect_Callback_RESOLVER_STRING_0_";

  static $observe_Callback(mthis, target, options) native "MutationObserver_observe_Callback_RESOLVER_STRING_2_Node_Dictionary";

  static $takeRecords_Callback(mthis) native "MutationObserver_takeRecords_Callback_RESOLVER_STRING_0_";
}

class BlinkMutationRecord {
  static $addedNodes_Getter(mthis) native "MutationRecord_addedNodes_Getter";

  static $attributeName_Getter(mthis) native "MutationRecord_attributeName_Getter";

  static $attributeNamespace_Getter(mthis) native "MutationRecord_attributeNamespace_Getter";

  static $nextSibling_Getter(mthis) native "MutationRecord_nextSibling_Getter";

  static $oldValue_Getter(mthis) native "MutationRecord_oldValue_Getter";

  static $previousSibling_Getter(mthis) native "MutationRecord_previousSibling_Getter";

  static $removedNodes_Getter(mthis) native "MutationRecord_removedNodes_Getter";

  static $target_Getter(mthis) native "MutationRecord_target_Getter";

  static $type_Getter(mthis) native "MutationRecord_type_Getter";
}

class BlinkNamedNodeMap {
  static $length_Getter(mthis) native "NamedNodeMap_length_Getter";

  static $NativeIndexed_Getter(mthis, index) native "NamedNodeMap_item_Callback_RESOLVER_STRING_1_unsigned long";

  static $__getter___Callback(mthis, name) native "NamedNodeMap___getter___Callback_RESOLVER_STRING_1_DOMString";

  static $getNamedItem_Callback(mthis, name) native "NamedNodeMap_getNamedItem_Callback_RESOLVER_STRING_1_DOMString";

  static $getNamedItemNS_Callback(mthis, namespaceURI, localName) native "NamedNodeMap_getNamedItemNS_Callback_RESOLVER_STRING_2_DOMString_DOMString";

  static $item_Callback(mthis, index) native "NamedNodeMap_item_Callback_RESOLVER_STRING_1_unsigned long";

  static $removeNamedItem_Callback(mthis, name) native "NamedNodeMap_removeNamedItem_Callback_RESOLVER_STRING_1_DOMString";

  static $removeNamedItemNS_Callback(mthis, namespaceURI, localName) native "NamedNodeMap_removeNamedItemNS_Callback_RESOLVER_STRING_2_DOMString_DOMString";

  static $setNamedItem_Callback(mthis, node) native "NamedNodeMap_setNamedItem_Callback_RESOLVER_STRING_1_Node";

  static $setNamedItemNS_Callback(mthis, node) native "NamedNodeMap_setNamedItemNS_Callback_RESOLVER_STRING_1_Node";
}

class BlinkNavigatorID {
  static $appCodeName_Getter(mthis) native "Navigator_appCodeName_Getter";

  static $appName_Getter(mthis) native "Navigator_appName_Getter";

  static $appVersion_Getter(mthis) native "Navigator_appVersion_Getter";

  static $platform_Getter(mthis) native "Navigator_platform_Getter";

  static $product_Getter(mthis) native "Navigator_product_Getter";

  static $userAgent_Getter(mthis) native "Navigator_userAgent_Getter";
}

class BlinkNavigatorOnLine {
  static $onLine_Getter(mthis) native "NavigatorOnLine_onLine_Getter";
}

class BlinkNavigator {
  static $cookieEnabled_Getter(mthis) native "Navigator_cookieEnabled_Getter";

  static $doNotTrack_Getter(mthis) native "Navigator_doNotTrack_Getter";

  static $geolocation_Getter(mthis) native "Navigator_geolocation_Getter";

  static $language_Getter(mthis) native "Navigator_language_Getter";

  static $maxTouchPoints_Getter(mthis) native "Navigator_maxTouchPoints_Getter";

  static $mimeTypes_Getter(mthis) native "Navigator_mimeTypes_Getter";

  static $productSub_Getter(mthis) native "Navigator_productSub_Getter";

  static $serviceWorker_Getter(mthis) native "Navigator_serviceWorker_Getter";

  static $storageQuota_Getter(mthis) native "Navigator_storageQuota_Getter";

  static $vendor_Getter(mthis) native "Navigator_vendor_Getter";

  static $vendorSub_Getter(mthis) native "Navigator_vendorSub_Getter";

  static $webkitPersistentStorage_Getter(mthis) native "Navigator_webkitPersistentStorage_Getter";

  static $webkitTemporaryStorage_Getter(mthis) native "Navigator_webkitTemporaryStorage_Getter";

  static $getStorageUpdates_Callback(mthis) native "Navigator_getStorageUpdates_Callback_RESOLVER_STRING_0_";

  static $isProtocolHandlerRegistered_Callback(mthis, scheme, url) native "Navigator_isProtocolHandlerRegistered_Callback_RESOLVER_STRING_2_DOMString_DOMString";

  static $registerProtocolHandler_Callback(mthis, scheme, url, title) native "Navigator_registerProtocolHandler_Callback_RESOLVER_STRING_3_DOMString_DOMString_DOMString";

  static $requestMIDIAccess_Callback(mthis, options) native "Navigator_requestMIDIAccess_Callback_RESOLVER_STRING_1_Dictionary";

  static $unregisterProtocolHandler_Callback(mthis, scheme, url) native "Navigator_unregisterProtocolHandler_Callback_RESOLVER_STRING_2_DOMString_DOMString";

  static $webkitGetGamepads_Callback(mthis) native "Navigator_webkitGetGamepads_Callback_RESOLVER_STRING_0_";

  static $webkitGetUserMedia_Callback(mthis, options, successCallback, errorCallback) native "Navigator_webkitGetUserMedia_Callback_RESOLVER_STRING_3_Dictionary_NavigatorUserMediaSuccessCallback_NavigatorUserMediaErrorCallback";

  static $appCodeName_Getter(mthis) native "Navigator_appCodeName_Getter";

  static $appName_Getter(mthis) native "Navigator_appName_Getter";

  static $appVersion_Getter(mthis) native "Navigator_appVersion_Getter";

  static $platform_Getter(mthis) native "Navigator_platform_Getter";

  static $product_Getter(mthis) native "Navigator_product_Getter";

  static $userAgent_Getter(mthis) native "Navigator_userAgent_Getter";

  static $onLine_Getter(mthis) native "Navigator_onLine_Getter";
}

class BlinkNavigatorUserMediaError {
  static $constraintName_Getter(mthis) native "NavigatorUserMediaError_constraintName_Getter";

  static $message_Getter(mthis) native "NavigatorUserMediaError_message_Getter";

  static $name_Getter(mthis) native "NavigatorUserMediaError_name_Getter";
}

class BlinkNodeFilter {}

class BlinkNodeIterator {
  static $pointerBeforeReferenceNode_Getter(mthis) native "NodeIterator_pointerBeforeReferenceNode_Getter";

  static $referenceNode_Getter(mthis) native "NodeIterator_referenceNode_Getter";

  static $root_Getter(mthis) native "NodeIterator_root_Getter";

  static $whatToShow_Getter(mthis) native "NodeIterator_whatToShow_Getter";

  static $detach_Callback(mthis) native "NodeIterator_detach_Callback_RESOLVER_STRING_0_";

  static $nextNode_Callback(mthis) native "NodeIterator_nextNode_Callback_RESOLVER_STRING_0_";

  static $previousNode_Callback(mthis) native "NodeIterator_previousNode_Callback_RESOLVER_STRING_0_";
}

class BlinkNodeList {
  static $length_Getter(mthis) native "NodeList_length_Getter";

  static $NativeIndexed_Getter(mthis, index) native "NodeList_item_Callback_RESOLVER_STRING_1_unsigned long";

  static $item_Callback(mthis, index) native "NodeList_item_Callback_RESOLVER_STRING_1_unsigned long";
}

class BlinkNotation {}

class BlinkNotification {
  // Generated overload resolver
  static $mkNotification(title, options) {
    return $_create_1constructorCallback(title, options);
  }

  static $_create_1constructorCallback(title, options) native "Notification_constructorCallback_RESOLVER_STRING_2_DOMString_Dictionary";

  static $body_Getter(mthis) native "Notification_body_Getter";

  static $dir_Getter(mthis) native "Notification_dir_Getter";

  static $icon_Getter(mthis) native "Notification_icon_Getter";

  static $lang_Getter(mthis) native "Notification_lang_Getter";

  static $permission_Getter(mthis) native "Notification_permission_Getter";

  static $tag_Getter(mthis) native "Notification_tag_Getter";

  static $title_Getter(mthis) native "Notification_title_Getter";

  static $close_Callback(mthis) native "Notification_close_Callback_RESOLVER_STRING_0_";

  static $requestPermission_Callback(callback) native "Notification_requestPermission_Callback_RESOLVER_STRING_1_NotificationPermissionCallback";
}

class BlinkNotificationCenter {}

class BlinkOESElementIndexUint {}

class BlinkOESStandardDerivatives {}

class BlinkOESTextureFloat {}

class BlinkOESTextureFloatLinear {}

class BlinkOESTextureHalfFloat {}

class BlinkOESTextureHalfFloatLinear {}

class BlinkOESVertexArrayObject {
  static $bindVertexArrayOES_Callback(mthis, arrayObject) native "OESVertexArrayObject_bindVertexArrayOES_Callback_RESOLVER_STRING_1_WebGLVertexArrayObjectOES";

  static $createVertexArrayOES_Callback(mthis) native "OESVertexArrayObject_createVertexArrayOES_Callback_RESOLVER_STRING_0_";

  static $deleteVertexArrayOES_Callback(mthis, arrayObject) native "OESVertexArrayObject_deleteVertexArrayOES_Callback_RESOLVER_STRING_1_WebGLVertexArrayObjectOES";

  static $isVertexArrayOES_Callback(mthis, arrayObject) native "OESVertexArrayObject_isVertexArrayOES_Callback_RESOLVER_STRING_1_WebGLVertexArrayObjectOES";
}

class BlinkOfflineAudioCompletionEvent {
  static $renderedBuffer_Getter(mthis) native "OfflineAudioCompletionEvent_renderedBuffer_Getter";
}

class BlinkOfflineAudioContext {
  // Generated overload resolver
  static $mkOfflineAudioContext(numberOfChannels, numberOfFrames, sampleRate) {
    return $_create_1constructorCallback(numberOfChannels, numberOfFrames, sampleRate);
  }

  static $_create_1constructorCallback(numberOfChannels, numberOfFrames, sampleRate) native "OfflineAudioContext_constructorCallback_RESOLVER_STRING_3_unsigned long_unsigned long_float";
}

class BlinkOscillatorNode {
  static $detune_Getter(mthis) native "OscillatorNode_detune_Getter";

  static $frequency_Getter(mthis) native "OscillatorNode_frequency_Getter";

  static $type_Getter(mthis) native "OscillatorNode_type_Getter";

  static $type_Setter(mthis, value) native "OscillatorNode_type_Setter";

  static $noteOff_Callback(mthis, when) native "OscillatorNode_noteOff_Callback_RESOLVER_STRING_1_double";

  static $noteOn_Callback(mthis, when) native "OscillatorNode_noteOn_Callback_RESOLVER_STRING_1_double";

  static $setPeriodicWave_Callback(mthis, periodicWave) native "OscillatorNode_setPeriodicWave_Callback_RESOLVER_STRING_1_PeriodicWave";

  // Generated overload resolver
  static $start(mthis, when) {
    if (when != null) {
      $_start_1_Callback(mthis, when);
      return;
    }
    $_start_2_Callback(mthis);
    return;
  }

  static $_start_1_Callback(mthis, when) native "OscillatorNode_start_Callback_RESOLVER_STRING_1_double";

  static $_start_2_Callback(mthis) native "OscillatorNode_start_Callback_RESOLVER_STRING_0_";

  // Generated overload resolver
  static $stop(mthis, when) {
    if (when != null) {
      $_stop_1_Callback(mthis, when);
      return;
    }
    $_stop_2_Callback(mthis);
    return;
  }

  static $_stop_1_Callback(mthis, when) native "OscillatorNode_stop_Callback_RESOLVER_STRING_1_double";

  static $_stop_2_Callback(mthis) native "OscillatorNode_stop_Callback_RESOLVER_STRING_0_";
}

class BlinkOverflowEvent {
  static $horizontalOverflow_Getter(mthis) native "OverflowEvent_horizontalOverflow_Getter";

  static $orient_Getter(mthis) native "OverflowEvent_orient_Getter";

  static $verticalOverflow_Getter(mthis) native "OverflowEvent_verticalOverflow_Getter";
}

class BlinkPagePopupController {}

class BlinkPageTransitionEvent {
  static $persisted_Getter(mthis) native "PageTransitionEvent_persisted_Getter";
}

class BlinkPannerNode {
  static $coneInnerAngle_Getter(mthis) native "PannerNode_coneInnerAngle_Getter";

  static $coneInnerAngle_Setter(mthis, value) native "PannerNode_coneInnerAngle_Setter";

  static $coneOuterAngle_Getter(mthis) native "PannerNode_coneOuterAngle_Getter";

  static $coneOuterAngle_Setter(mthis, value) native "PannerNode_coneOuterAngle_Setter";

  static $coneOuterGain_Getter(mthis) native "PannerNode_coneOuterGain_Getter";

  static $coneOuterGain_Setter(mthis, value) native "PannerNode_coneOuterGain_Setter";

  static $distanceModel_Getter(mthis) native "PannerNode_distanceModel_Getter";

  static $distanceModel_Setter(mthis, value) native "PannerNode_distanceModel_Setter";

  static $maxDistance_Getter(mthis) native "PannerNode_maxDistance_Getter";

  static $maxDistance_Setter(mthis, value) native "PannerNode_maxDistance_Setter";

  static $panningModel_Getter(mthis) native "PannerNode_panningModel_Getter";

  static $panningModel_Setter(mthis, value) native "PannerNode_panningModel_Setter";

  static $refDistance_Getter(mthis) native "PannerNode_refDistance_Getter";

  static $refDistance_Setter(mthis, value) native "PannerNode_refDistance_Setter";

  static $rolloffFactor_Getter(mthis) native "PannerNode_rolloffFactor_Getter";

  static $rolloffFactor_Setter(mthis, value) native "PannerNode_rolloffFactor_Setter";

  static $setOrientation_Callback(mthis, x, y, z) native "PannerNode_setOrientation_Callback_RESOLVER_STRING_3_float_float_float";

  static $setPosition_Callback(mthis, x, y, z) native "PannerNode_setPosition_Callback_RESOLVER_STRING_3_float_float_float";

  static $setVelocity_Callback(mthis, x, y, z) native "PannerNode_setVelocity_Callback_RESOLVER_STRING_3_float_float_float";
}

class BlinkPath {
  // Generated overload resolver
  static $mkPath(path_OR_text) {
    if (path_OR_text == null) {
      return $_create_1constructorCallback();
    }
    if ((path_OR_text is Path || path_OR_text == null)) {
      return $_create_2constructorCallback(path_OR_text);
    }
    if ((path_OR_text is String || path_OR_text == null)) {
      return $_create_3constructorCallback(path_OR_text);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  static $_create_1constructorCallback() native "Path2D_constructorCallback_RESOLVER_STRING_0_";

  static $_create_2constructorCallback(path_OR_text) native "Path2D_constructorCallback_RESOLVER_STRING_1_Path2D";

  static $_create_3constructorCallback(path_OR_text) native "Path2D_constructorCallback_RESOLVER_STRING_1_DOMString";

  static $arc_Callback(mthis, x, y, radius, startAngle, endAngle, anticlockwise) native "Path2D_arc_Callback_RESOLVER_STRING_6_float_float_float_float_float_boolean";

  static $arcTo_Callback(mthis, x1, y1, x2, y2, radius) native "Path2D_arcTo_Callback_RESOLVER_STRING_5_float_float_float_float_float";

  static $bezierCurveTo_Callback(mthis, cp1x, cp1y, cp2x, cp2y, x, y) native "Path2D_bezierCurveTo_Callback_RESOLVER_STRING_6_float_float_float_float_float_float";

  static $closePath_Callback(mthis) native "Path2D_closePath_Callback_RESOLVER_STRING_0_";

  static $lineTo_Callback(mthis, x, y) native "Path2D_lineTo_Callback_RESOLVER_STRING_2_float_float";

  static $moveTo_Callback(mthis, x, y) native "Path2D_moveTo_Callback_RESOLVER_STRING_2_float_float";

  static $quadraticCurveTo_Callback(mthis, cpx, cpy, x, y) native "Path2D_quadraticCurveTo_Callback_RESOLVER_STRING_4_float_float_float_float";

  static $rect_Callback(mthis, x, y, width, height) native "Path2D_rect_Callback_RESOLVER_STRING_4_float_float_float_float";
}

class BlinkPerformance {
  static $memory_Getter(mthis) native "Performance_memory_Getter";

  static $navigation_Getter(mthis) native "Performance_navigation_Getter";

  static $timing_Getter(mthis) native "Performance_timing_Getter";

  static $clearMarks_Callback(mthis, markName) native "Performance_clearMarks_Callback_RESOLVER_STRING_1_DOMString";

  static $clearMeasures_Callback(mthis, measureName) native "Performance_clearMeasures_Callback_RESOLVER_STRING_1_DOMString";

  static $getEntries_Callback(mthis) native "Performance_getEntries_Callback_RESOLVER_STRING_0_";

  static $getEntriesByName_Callback(mthis, name, entryType) native "Performance_getEntriesByName_Callback_RESOLVER_STRING_2_DOMString_DOMString";

  static $getEntriesByType_Callback(mthis, entryType) native "Performance_getEntriesByType_Callback_RESOLVER_STRING_1_DOMString";

  static $mark_Callback(mthis, markName) native "Performance_mark_Callback_RESOLVER_STRING_1_DOMString";

  static $measure_Callback(mthis, measureName, startMark, endMark) native "Performance_measure_Callback_RESOLVER_STRING_3_DOMString_DOMString_DOMString";

  static $now_Callback(mthis) native "Performance_now_Callback_RESOLVER_STRING_0_";

  static $webkitClearResourceTimings_Callback(mthis) native "Performance_webkitClearResourceTimings_Callback_RESOLVER_STRING_0_";

  static $webkitSetResourceTimingBufferSize_Callback(mthis, maxSize) native "Performance_webkitSetResourceTimingBufferSize_Callback_RESOLVER_STRING_1_unsigned long";
}

class BlinkPerformanceEntry {
  static $duration_Getter(mthis) native "PerformanceEntry_duration_Getter";

  static $entryType_Getter(mthis) native "PerformanceEntry_entryType_Getter";

  static $name_Getter(mthis) native "PerformanceEntry_name_Getter";

  static $startTime_Getter(mthis) native "PerformanceEntry_startTime_Getter";
}

class BlinkPerformanceMark {}

class BlinkPerformanceMeasure {}

class BlinkPerformanceNavigation {
  static $redirectCount_Getter(mthis) native "PerformanceNavigation_redirectCount_Getter";

  static $type_Getter(mthis) native "PerformanceNavigation_type_Getter";
}

class BlinkPerformanceResourceTiming {
  static $connectEnd_Getter(mthis) native "PerformanceResourceTiming_connectEnd_Getter";

  static $connectStart_Getter(mthis) native "PerformanceResourceTiming_connectStart_Getter";

  static $domainLookupEnd_Getter(mthis) native "PerformanceResourceTiming_domainLookupEnd_Getter";

  static $domainLookupStart_Getter(mthis) native "PerformanceResourceTiming_domainLookupStart_Getter";

  static $fetchStart_Getter(mthis) native "PerformanceResourceTiming_fetchStart_Getter";

  static $initiatorType_Getter(mthis) native "PerformanceResourceTiming_initiatorType_Getter";

  static $redirectEnd_Getter(mthis) native "PerformanceResourceTiming_redirectEnd_Getter";

  static $redirectStart_Getter(mthis) native "PerformanceResourceTiming_redirectStart_Getter";

  static $requestStart_Getter(mthis) native "PerformanceResourceTiming_requestStart_Getter";

  static $responseEnd_Getter(mthis) native "PerformanceResourceTiming_responseEnd_Getter";

  static $responseStart_Getter(mthis) native "PerformanceResourceTiming_responseStart_Getter";

  static $secureConnectionStart_Getter(mthis) native "PerformanceResourceTiming_secureConnectionStart_Getter";
}

class BlinkPerformanceTiming {
  static $connectEnd_Getter(mthis) native "PerformanceTiming_connectEnd_Getter";

  static $connectStart_Getter(mthis) native "PerformanceTiming_connectStart_Getter";

  static $domComplete_Getter(mthis) native "PerformanceTiming_domComplete_Getter";

  static $domContentLoadedEventEnd_Getter(mthis) native "PerformanceTiming_domContentLoadedEventEnd_Getter";

  static $domContentLoadedEventStart_Getter(mthis) native "PerformanceTiming_domContentLoadedEventStart_Getter";

  static $domInteractive_Getter(mthis) native "PerformanceTiming_domInteractive_Getter";

  static $domLoading_Getter(mthis) native "PerformanceTiming_domLoading_Getter";

  static $domainLookupEnd_Getter(mthis) native "PerformanceTiming_domainLookupEnd_Getter";

  static $domainLookupStart_Getter(mthis) native "PerformanceTiming_domainLookupStart_Getter";

  static $fetchStart_Getter(mthis) native "PerformanceTiming_fetchStart_Getter";

  static $loadEventEnd_Getter(mthis) native "PerformanceTiming_loadEventEnd_Getter";

  static $loadEventStart_Getter(mthis) native "PerformanceTiming_loadEventStart_Getter";

  static $navigationStart_Getter(mthis) native "PerformanceTiming_navigationStart_Getter";

  static $redirectEnd_Getter(mthis) native "PerformanceTiming_redirectEnd_Getter";

  static $redirectStart_Getter(mthis) native "PerformanceTiming_redirectStart_Getter";

  static $requestStart_Getter(mthis) native "PerformanceTiming_requestStart_Getter";

  static $responseEnd_Getter(mthis) native "PerformanceTiming_responseEnd_Getter";

  static $responseStart_Getter(mthis) native "PerformanceTiming_responseStart_Getter";

  static $secureConnectionStart_Getter(mthis) native "PerformanceTiming_secureConnectionStart_Getter";

  static $unloadEventEnd_Getter(mthis) native "PerformanceTiming_unloadEventEnd_Getter";

  static $unloadEventStart_Getter(mthis) native "PerformanceTiming_unloadEventStart_Getter";
}

class BlinkPeriodicWave {}

class BlinkPlayer {
  static $currentTime_Getter(mthis) native "AnimationPlayer_currentTime_Getter";

  static $currentTime_Setter(mthis, value) native "AnimationPlayer_currentTime_Setter";

  static $finished_Getter(mthis) native "AnimationPlayer_finished_Getter";

  static $paused_Getter(mthis) native "AnimationPlayer_paused_Getter";

  static $playbackRate_Getter(mthis) native "AnimationPlayer_playbackRate_Getter";

  static $playbackRate_Setter(mthis, value) native "AnimationPlayer_playbackRate_Setter";

  static $source_Getter(mthis) native "AnimationPlayer_source_Getter";

  static $source_Setter(mthis, value) native "AnimationPlayer_source_Setter";

  static $startTime_Getter(mthis) native "AnimationPlayer_startTime_Getter";

  static $startTime_Setter(mthis, value) native "AnimationPlayer_startTime_Setter";

  static $timeLag_Getter(mthis) native "AnimationPlayer_timeLag_Getter";

  static $cancel_Callback(mthis) native "AnimationPlayer_cancel_Callback_RESOLVER_STRING_0_";

  static $finish_Callback(mthis) native "AnimationPlayer_finish_Callback_RESOLVER_STRING_0_";

  static $pause_Callback(mthis) native "AnimationPlayer_pause_Callback_RESOLVER_STRING_0_";

  static $play_Callback(mthis) native "AnimationPlayer_play_Callback_RESOLVER_STRING_0_";

  static $reverse_Callback(mthis) native "AnimationPlayer_reverse_Callback_RESOLVER_STRING_0_";
}

class BlinkPlugin {
  static $description_Getter(mthis) native "Plugin_description_Getter";

  static $filename_Getter(mthis) native "Plugin_filename_Getter";

  static $length_Getter(mthis) native "Plugin_length_Getter";

  static $name_Getter(mthis) native "Plugin_name_Getter";

  static $__getter___Callback(mthis, name) native "Plugin___getter___Callback_RESOLVER_STRING_1_DOMString";

  static $item_Callback(mthis, index) native "Plugin_item_Callback_RESOLVER_STRING_1_unsigned long";

  static $namedItem_Callback(mthis, name) native "Plugin_namedItem_Callback_RESOLVER_STRING_1_DOMString";
}

class BlinkPluginArray {
  static $length_Getter(mthis) native "PluginArray_length_Getter";

  static $NativeIndexed_Getter(mthis, index) native "PluginArray_item_Callback_RESOLVER_STRING_1_unsigned long";

  static $__getter___Callback(mthis, name) native "PluginArray___getter___Callback_RESOLVER_STRING_1_DOMString";

  static $item_Callback(mthis, index) native "PluginArray_item_Callback_RESOLVER_STRING_1_unsigned long";

  static $namedItem_Callback(mthis, name) native "PluginArray_namedItem_Callback_RESOLVER_STRING_1_DOMString";

  static $refresh_Callback(mthis, reload) native "PluginArray_refresh_Callback_RESOLVER_STRING_1_boolean";
}

class BlinkPopStateEvent {
  static $state_Getter(mthis) native "PopStateEvent_state_Getter";
}

class BlinkPositionError {
  static $code_Getter(mthis) native "PositionError_code_Getter";

  static $message_Getter(mthis) native "PositionError_message_Getter";
}

class BlinkProcessingInstruction {
  static $sheet_Getter(mthis) native "ProcessingInstruction_sheet_Getter";

  static $target_Getter(mthis) native "ProcessingInstruction_target_Getter";
}

class BlinkProgressEvent {
  static $lengthComputable_Getter(mthis) native "ProgressEvent_lengthComputable_Getter";

  static $loaded_Getter(mthis) native "ProgressEvent_loaded_Getter";

  static $total_Getter(mthis) native "ProgressEvent_total_Getter";
}

class BlinkRGBColor {}

class BlinkRTCDTMFSender {
  static $canInsertDTMF_Getter(mthis) native "RTCDTMFSender_canInsertDTMF_Getter";

  static $duration_Getter(mthis) native "RTCDTMFSender_duration_Getter";

  static $interToneGap_Getter(mthis) native "RTCDTMFSender_interToneGap_Getter";

  static $toneBuffer_Getter(mthis) native "RTCDTMFSender_toneBuffer_Getter";

  static $track_Getter(mthis) native "RTCDTMFSender_track_Getter";

  // Generated overload resolver
  static $insertDtmf(mthis, tones, duration, interToneGap) {
    if (interToneGap != null) {
      $_insertDTMF_1_Callback(mthis, tones, duration, interToneGap);
      return;
    }
    if (duration != null) {
      $_insertDTMF_2_Callback(mthis, tones, duration);
      return;
    }
    $_insertDTMF_3_Callback(mthis, tones);
    return;
  }

  static $_insertDTMF_1_Callback(mthis, tones, duration, interToneGap) native "RTCDTMFSender_insertDTMF_Callback_RESOLVER_STRING_3_DOMString_long_long";

  static $_insertDTMF_2_Callback(mthis, tones, duration) native "RTCDTMFSender_insertDTMF_Callback_RESOLVER_STRING_2_DOMString_long";

  static $_insertDTMF_3_Callback(mthis, tones) native "RTCDTMFSender_insertDTMF_Callback_RESOLVER_STRING_1_DOMString";
}

class BlinkRTCDTMFToneChangeEvent {
  static $tone_Getter(mthis) native "RTCDTMFToneChangeEvent_tone_Getter";
}

class BlinkRTCDataChannel {
  static $binaryType_Getter(mthis) native "RTCDataChannel_binaryType_Getter";

  static $binaryType_Setter(mthis, value) native "RTCDataChannel_binaryType_Setter";

  static $bufferedAmount_Getter(mthis) native "RTCDataChannel_bufferedAmount_Getter";

  static $id_Getter(mthis) native "RTCDataChannel_id_Getter";

  static $label_Getter(mthis) native "RTCDataChannel_label_Getter";

  static $maxRetransmitTime_Getter(mthis) native "RTCDataChannel_maxRetransmitTime_Getter";

  static $maxRetransmits_Getter(mthis) native "RTCDataChannel_maxRetransmits_Getter";

  static $negotiated_Getter(mthis) native "RTCDataChannel_negotiated_Getter";

  static $ordered_Getter(mthis) native "RTCDataChannel_ordered_Getter";

  static $protocol_Getter(mthis) native "RTCDataChannel_protocol_Getter";

  static $readyState_Getter(mthis) native "RTCDataChannel_readyState_Getter";

  static $reliable_Getter(mthis) native "RTCDataChannel_reliable_Getter";

  static $close_Callback(mthis) native "RTCDataChannel_close_Callback_RESOLVER_STRING_0_";

  // Generated overload resolver
  static $send(mthis, data) {
    if ((data is TypedData || data == null)) {
      $_send_1_Callback(mthis, data);
      return;
    }
    if ((data is ByteBuffer || data == null)) {
      $_send_2_Callback(mthis, data);
      return;
    }
    if ((data is Blob || data == null)) {
      $_send_3_Callback(mthis, data);
      return;
    }
    if ((data is String || data == null)) {
      $_send_4_Callback(mthis, data);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  static $_send_1_Callback(mthis, data) native "RTCDataChannel_send_Callback_RESOLVER_STRING_1_ArrayBufferView";

  static $_send_2_Callback(mthis, data) native "RTCDataChannel_send_Callback_RESOLVER_STRING_1_ArrayBuffer";

  static $_send_3_Callback(mthis, data) native "RTCDataChannel_send_Callback_RESOLVER_STRING_1_Blob";

  static $_send_4_Callback(mthis, data) native "RTCDataChannel_send_Callback_RESOLVER_STRING_1_DOMString";

  static $sendBlob_Callback(mthis, data) native "RTCDataChannel_send_Callback_RESOLVER_STRING_1_Blob";

  static $sendByteBuffer_Callback(mthis, data) native "RTCDataChannel_send_Callback_RESOLVER_STRING_1_ArrayBuffer";

  static $sendString_Callback(mthis, data) native "RTCDataChannel_send_Callback_RESOLVER_STRING_1_DOMString";

  static $sendTypedData_Callback(mthis, data) native "RTCDataChannel_send_Callback_RESOLVER_STRING_1_ArrayBufferView";
}

class BlinkRTCDataChannelEvent {
  static $channel_Getter(mthis) native "RTCDataChannelEvent_channel_Getter";
}

class BlinkRTCIceCandidate {
  // Generated overload resolver
  static $mkRtcIceCandidate(dictionary) {
    return $_create_1constructorCallback(dictionary);
  }

  static $_create_1constructorCallback(dictionary) native "RTCIceCandidate_constructorCallback_RESOLVER_STRING_1_Dictionary";

  static $candidate_Getter(mthis) native "RTCIceCandidate_candidate_Getter";

  static $sdpMLineIndex_Getter(mthis) native "RTCIceCandidate_sdpMLineIndex_Getter";

  static $sdpMid_Getter(mthis) native "RTCIceCandidate_sdpMid_Getter";
}

class BlinkRTCIceCandidateEvent {
  static $candidate_Getter(mthis) native "RTCIceCandidateEvent_candidate_Getter";
}

class BlinkRTCPeerConnection {
  // Generated overload resolver
  static $mkRtcPeerConnection(rtcIceServers, mediaConstraints) {
    return $_create_1constructorCallback(rtcIceServers, mediaConstraints);
  }

  static $_create_1constructorCallback(rtcIceServers, mediaConstraints) native "RTCPeerConnection_constructorCallback_RESOLVER_STRING_2_Dictionary_Dictionary";

  static $iceConnectionState_Getter(mthis) native "RTCPeerConnection_iceConnectionState_Getter";

  static $iceGatheringState_Getter(mthis) native "RTCPeerConnection_iceGatheringState_Getter";

  static $localDescription_Getter(mthis) native "RTCPeerConnection_localDescription_Getter";

  static $remoteDescription_Getter(mthis) native "RTCPeerConnection_remoteDescription_Getter";

  static $signalingState_Getter(mthis) native "RTCPeerConnection_signalingState_Getter";

  static $addIceCandidate_Callback(mthis, candidate, successCallback, failureCallback) native "RTCPeerConnection_addIceCandidate_Callback_RESOLVER_STRING_3_RTCIceCandidate_VoidCallback_RTCErrorCallback";

  static $addStream_Callback(mthis, stream, mediaConstraints) native "RTCPeerConnection_addStream_Callback_RESOLVER_STRING_2_MediaStream_Dictionary";

  static $close_Callback(mthis) native "RTCPeerConnection_close_Callback_RESOLVER_STRING_0_";

  static $createAnswer_Callback(mthis, successCallback, failureCallback, mediaConstraints) native "RTCPeerConnection_createAnswer_Callback_RESOLVER_STRING_3_RTCSessionDescriptionCallback_RTCErrorCallback_Dictionary";

  static $createDTMFSender_Callback(mthis, track) native "RTCPeerConnection_createDTMFSender_Callback_RESOLVER_STRING_1_MediaStreamTrack";

  static $createDataChannel_Callback(mthis, label, options) native "RTCPeerConnection_createDataChannel_Callback_RESOLVER_STRING_2_DOMString_Dictionary";

  static $createOffer_Callback(mthis, successCallback, failureCallback, mediaConstraints) native "RTCPeerConnection_createOffer_Callback_RESOLVER_STRING_3_RTCSessionDescriptionCallback_RTCErrorCallback_Dictionary";

  static $getLocalStreams_Callback(mthis) native "RTCPeerConnection_getLocalStreams_Callback_RESOLVER_STRING_0_";

  static $getRemoteStreams_Callback(mthis) native "RTCPeerConnection_getRemoteStreams_Callback_RESOLVER_STRING_0_";

  static $getStats_Callback(mthis, successCallback, selector) native "RTCPeerConnection_getStats_Callback_RESOLVER_STRING_2_RTCStatsCallback_MediaStreamTrack";

  static $getStreamById_Callback(mthis, streamId) native "RTCPeerConnection_getStreamById_Callback_RESOLVER_STRING_1_DOMString";

  static $removeStream_Callback(mthis, stream) native "RTCPeerConnection_removeStream_Callback_RESOLVER_STRING_1_MediaStream";

  static $setLocalDescription_Callback(mthis, description, successCallback, failureCallback) native "RTCPeerConnection_setLocalDescription_Callback_RESOLVER_STRING_3_RTCSessionDescription_VoidCallback_RTCErrorCallback";

  static $setRemoteDescription_Callback(mthis, description, successCallback, failureCallback) native "RTCPeerConnection_setRemoteDescription_Callback_RESOLVER_STRING_3_RTCSessionDescription_VoidCallback_RTCErrorCallback";

  static $updateIce_Callback(mthis, configuration, mediaConstraints) native "RTCPeerConnection_updateIce_Callback_RESOLVER_STRING_2_Dictionary_Dictionary";
}

class BlinkRTCSessionDescription {
  // Generated overload resolver
  static $mkRtcSessionDescription(descriptionInitDict) {
    return $_create_1constructorCallback(descriptionInitDict);
  }

  static $_create_1constructorCallback(descriptionInitDict) native "RTCSessionDescription_constructorCallback_RESOLVER_STRING_1_Dictionary";

  static $sdp_Getter(mthis) native "RTCSessionDescription_sdp_Getter";

  static $sdp_Setter(mthis, value) native "RTCSessionDescription_sdp_Setter";

  static $type_Getter(mthis) native "RTCSessionDescription_type_Getter";

  static $type_Setter(mthis, value) native "RTCSessionDescription_type_Setter";
}

class BlinkRTCStatsReport {
  static $id_Getter(mthis) native "RTCStatsReport_id_Getter";

  static $local_Getter(mthis) native "RTCStatsReport_local_Getter";

  static $remote_Getter(mthis) native "RTCStatsReport_remote_Getter";

  static $timestamp_Getter(mthis) native "RTCStatsReport_timestamp_Getter";

  static $type_Getter(mthis) native "RTCStatsReport_type_Getter";

  static $names_Callback(mthis) native "RTCStatsReport_names_Callback_RESOLVER_STRING_0_";

  static $stat_Callback(mthis, name) native "RTCStatsReport_stat_Callback_RESOLVER_STRING_1_DOMString";
}

class BlinkRTCStatsResponse {
  static $__getter___Callback(mthis, name) native "RTCStatsResponse___getter___Callback_RESOLVER_STRING_1_DOMString";

  static $namedItem_Callback(mthis, name) native "RTCStatsResponse_namedItem_Callback_RESOLVER_STRING_1_DOMString";

  static $result_Callback(mthis) native "RTCStatsResponse_result_Callback_RESOLVER_STRING_0_";
}

class BlinkRadioNodeList {}

class BlinkRange {
  static $collapsed_Getter(mthis) native "Range_collapsed_Getter";

  static $commonAncestorContainer_Getter(mthis) native "Range_commonAncestorContainer_Getter";

  static $endContainer_Getter(mthis) native "Range_endContainer_Getter";

  static $endOffset_Getter(mthis) native "Range_endOffset_Getter";

  static $startContainer_Getter(mthis) native "Range_startContainer_Getter";

  static $startOffset_Getter(mthis) native "Range_startOffset_Getter";

  static $cloneContents_Callback(mthis) native "Range_cloneContents_Callback_RESOLVER_STRING_0_";

  static $cloneRange_Callback(mthis) native "Range_cloneRange_Callback_RESOLVER_STRING_0_";

  static $collapse_Callback(mthis, toStart) native "Range_collapse_Callback_RESOLVER_STRING_1_boolean";

  static $comparePoint_Callback(mthis, refNode, offset) native "Range_comparePoint_Callback_RESOLVER_STRING_2_Node_long";

  static $createContextualFragment_Callback(mthis, html) native "Range_createContextualFragment_Callback_RESOLVER_STRING_1_DOMString";

  static $deleteContents_Callback(mthis) native "Range_deleteContents_Callback_RESOLVER_STRING_0_";

  static $detach_Callback(mthis) native "Range_detach_Callback_RESOLVER_STRING_0_";

  static $expand_Callback(mthis, unit) native "Range_expand_Callback_RESOLVER_STRING_1_DOMString";

  static $extractContents_Callback(mthis) native "Range_extractContents_Callback_RESOLVER_STRING_0_";

  static $getBoundingClientRect_Callback(mthis) native "Range_getBoundingClientRect_Callback_RESOLVER_STRING_0_";

  static $getClientRects_Callback(mthis) native "Range_getClientRects_Callback_RESOLVER_STRING_0_";

  static $insertNode_Callback(mthis, newNode) native "Range_insertNode_Callback_RESOLVER_STRING_1_Node";

  static $isPointInRange_Callback(mthis, refNode, offset) native "Range_isPointInRange_Callback_RESOLVER_STRING_2_Node_long";

  static $selectNode_Callback(mthis, refNode) native "Range_selectNode_Callback_RESOLVER_STRING_1_Node";

  static $selectNodeContents_Callback(mthis, refNode) native "Range_selectNodeContents_Callback_RESOLVER_STRING_1_Node";

  static $setEnd_Callback(mthis, refNode, offset) native "Range_setEnd_Callback_RESOLVER_STRING_2_Node_long";

  static $setEndAfter_Callback(mthis, refNode) native "Range_setEndAfter_Callback_RESOLVER_STRING_1_Node";

  static $setEndBefore_Callback(mthis, refNode) native "Range_setEndBefore_Callback_RESOLVER_STRING_1_Node";

  static $setStart_Callback(mthis, refNode, offset) native "Range_setStart_Callback_RESOLVER_STRING_2_Node_long";

  static $setStartAfter_Callback(mthis, refNode) native "Range_setStartAfter_Callback_RESOLVER_STRING_1_Node";

  static $setStartBefore_Callback(mthis, refNode) native "Range_setStartBefore_Callback_RESOLVER_STRING_1_Node";

  static $surroundContents_Callback(mthis, newParent) native "Range_surroundContents_Callback_RESOLVER_STRING_1_Node";

  static $toString_Callback(mthis) native "Range_toString_Callback_RESOLVER_STRING_0_";
}

class BlinkRect {}

class BlinkResourceProgressEvent {
  static $url_Getter(mthis) native "ResourceProgressEvent_url_Getter";
}

class BlinkSQLError {
  static $code_Getter(mthis) native "SQLError_code_Getter";

  static $message_Getter(mthis) native "SQLError_message_Getter";
}

class BlinkSQLResultSet {
  static $insertId_Getter(mthis) native "SQLResultSet_insertId_Getter";

  static $rows_Getter(mthis) native "SQLResultSet_rows_Getter";

  static $rowsAffected_Getter(mthis) native "SQLResultSet_rowsAffected_Getter";
}

class BlinkSQLResultSetRowList {
  static $length_Getter(mthis) native "SQLResultSetRowList_length_Getter";

  static $NativeIndexed_Getter(mthis, index) native "SQLResultSetRowList_item_Callback";

  static $item_Callback(mthis, index) native "SQLResultSetRowList_item_Callback";
}

class BlinkSQLTransaction {
  static $executeSql_Callback(mthis, sqlStatement, arguments, callback, errorCallback) native "SQLTransaction_executeSql_Callback";
}

class BlinkSQLTransactionSync {}

class BlinkSVGElement {
  static $className_Getter(mthis) native "SVGElement_className_Getter";

  static $ownerSVGElement_Getter(mthis) native "SVGElement_ownerSVGElement_Getter";

  static $style_Getter(mthis) native "SVGElement_style_Getter";

  static $viewportElement_Getter(mthis) native "SVGElement_viewportElement_Getter";

  static $xmlbase_Getter(mthis) native "SVGElement_xmlbase_Getter";

  static $xmlbase_Setter(mthis, value) native "SVGElement_xmlbase_Setter";

  static $xmllang_Getter(mthis) native "SVGElement_xmllang_Getter";

  static $xmllang_Setter(mthis, value) native "SVGElement_xmllang_Setter";

  static $xmlspace_Getter(mthis) native "SVGElement_xmlspace_Getter";

  static $xmlspace_Setter(mthis, value) native "SVGElement_xmlspace_Setter";
}

class BlinkSVGTests {
  static $requiredExtensions_Getter(mthis) native "SVGTests_requiredExtensions_Getter";

  static $requiredFeatures_Getter(mthis) native "SVGTests_requiredFeatures_Getter";

  static $systemLanguage_Getter(mthis) native "SVGTests_systemLanguage_Getter";

  static $hasExtension_Callback(mthis, extension) native "SVGTests_hasExtension_Callback_RESOLVER_STRING_1_DOMString";
}

class BlinkSVGGraphicsElement {
  static $farthestViewportElement_Getter(mthis) native "SVGGraphicsElement_farthestViewportElement_Getter";

  static $nearestViewportElement_Getter(mthis) native "SVGGraphicsElement_nearestViewportElement_Getter";

  static $transform_Getter(mthis) native "SVGGraphicsElement_transform_Getter";

  static $getBBox_Callback(mthis) native "SVGGraphicsElement_getBBox_Callback_RESOLVER_STRING_0_";

  static $getCTM_Callback(mthis) native "SVGGraphicsElement_getCTM_Callback_RESOLVER_STRING_0_";

  static $getScreenCTM_Callback(mthis) native "SVGGraphicsElement_getScreenCTM_Callback_RESOLVER_STRING_0_";

  static $getTransformToElement_Callback(mthis, element) native "SVGGraphicsElement_getTransformToElement_Callback_RESOLVER_STRING_1_SVGElement";

  static $requiredExtensions_Getter(mthis) native "SVGGraphicsElement_requiredExtensions_Getter";

  static $requiredFeatures_Getter(mthis) native "SVGGraphicsElement_requiredFeatures_Getter";

  static $systemLanguage_Getter(mthis) native "SVGGraphicsElement_systemLanguage_Getter";

  static $hasExtension_Callback(mthis, extension) native "SVGGraphicsElement_hasExtension_Callback_RESOLVER_STRING_1_DOMString";
}

class BlinkSVGURIReference {
  static $href_Getter(mthis) native "SVGURIReference_href_Getter";
}

class BlinkSVGAElement {
  static $target_Getter(mthis) native "SVGAElement_target_Getter";

  static $href_Getter(mthis) native "SVGAElement_href_Getter";
}

class BlinkSVGAltGlyphDefElement {}

class BlinkSVGTextContentElement {
  static $lengthAdjust_Getter(mthis) native "SVGTextContentElement_lengthAdjust_Getter";

  static $textLength_Getter(mthis) native "SVGTextContentElement_textLength_Getter";

  static $getCharNumAtPosition_Callback(mthis, point) native "SVGTextContentElement_getCharNumAtPosition_Callback_RESOLVER_STRING_1_SVGPoint";

  static $getComputedTextLength_Callback(mthis) native "SVGTextContentElement_getComputedTextLength_Callback_RESOLVER_STRING_0_";

  static $getEndPositionOfChar_Callback(mthis, offset) native "SVGTextContentElement_getEndPositionOfChar_Callback_RESOLVER_STRING_1_unsigned long";

  static $getExtentOfChar_Callback(mthis, offset) native "SVGTextContentElement_getExtentOfChar_Callback_RESOLVER_STRING_1_unsigned long";

  static $getNumberOfChars_Callback(mthis) native "SVGTextContentElement_getNumberOfChars_Callback_RESOLVER_STRING_0_";

  static $getRotationOfChar_Callback(mthis, offset) native "SVGTextContentElement_getRotationOfChar_Callback_RESOLVER_STRING_1_unsigned long";

  static $getStartPositionOfChar_Callback(mthis, offset) native "SVGTextContentElement_getStartPositionOfChar_Callback_RESOLVER_STRING_1_unsigned long";

  static $getSubStringLength_Callback(mthis, offset, length) native "SVGTextContentElement_getSubStringLength_Callback_RESOLVER_STRING_2_unsigned long_unsigned long";

  static $selectSubString_Callback(mthis, offset, length) native "SVGTextContentElement_selectSubString_Callback_RESOLVER_STRING_2_unsigned long_unsigned long";
}

class BlinkSVGTextPositioningElement {
  static $dx_Getter(mthis) native "SVGTextPositioningElement_dx_Getter";

  static $dy_Getter(mthis) native "SVGTextPositioningElement_dy_Getter";

  static $rotate_Getter(mthis) native "SVGTextPositioningElement_rotate_Getter";

  static $x_Getter(mthis) native "SVGTextPositioningElement_x_Getter";

  static $y_Getter(mthis) native "SVGTextPositioningElement_y_Getter";
}

class BlinkSVGAltGlyphElement {
  static $format_Getter(mthis) native "SVGAltGlyphElement_format_Getter";

  static $format_Setter(mthis, value) native "SVGAltGlyphElement_format_Setter";

  static $glyphRef_Getter(mthis) native "SVGAltGlyphElement_glyphRef_Getter";

  static $glyphRef_Setter(mthis, value) native "SVGAltGlyphElement_glyphRef_Setter";

  static $href_Getter(mthis) native "SVGAltGlyphElement_href_Getter";
}

class BlinkSVGAltGlyphItemElement {}

class BlinkSVGAngle {
  static $unitType_Getter(mthis) native "SVGAngle_unitType_Getter";

  static $value_Getter(mthis) native "SVGAngle_value_Getter";

  static $value_Setter(mthis, value) native "SVGAngle_value_Setter";

  static $valueAsString_Getter(mthis) native "SVGAngle_valueAsString_Getter";

  static $valueAsString_Setter(mthis, value) native "SVGAngle_valueAsString_Setter";

  static $valueInSpecifiedUnits_Getter(mthis) native "SVGAngle_valueInSpecifiedUnits_Getter";

  static $valueInSpecifiedUnits_Setter(mthis, value) native "SVGAngle_valueInSpecifiedUnits_Setter";

  static $convertToSpecifiedUnits_Callback(mthis, unitType) native "SVGAngle_convertToSpecifiedUnits_Callback_RESOLVER_STRING_1_unsigned short";

  static $newValueSpecifiedUnits_Callback(mthis, unitType, valueInSpecifiedUnits) native "SVGAngle_newValueSpecifiedUnits_Callback_RESOLVER_STRING_2_unsigned short_float";
}

class BlinkSVGAnimationElement {
  static $targetElement_Getter(mthis) native "SVGAnimationElement_targetElement_Getter";

  static $beginElement_Callback(mthis) native "SVGAnimationElement_beginElement_Callback_RESOLVER_STRING_0_";

  static $beginElementAt_Callback(mthis, offset) native "SVGAnimationElement_beginElementAt_Callback_RESOLVER_STRING_1_float";

  static $endElement_Callback(mthis) native "SVGAnimationElement_endElement_Callback_RESOLVER_STRING_0_";

  static $endElementAt_Callback(mthis, offset) native "SVGAnimationElement_endElementAt_Callback_RESOLVER_STRING_1_float";

  static $getCurrentTime_Callback(mthis) native "SVGAnimationElement_getCurrentTime_Callback_RESOLVER_STRING_0_";

  static $getSimpleDuration_Callback(mthis) native "SVGAnimationElement_getSimpleDuration_Callback_RESOLVER_STRING_0_";

  static $getStartTime_Callback(mthis) native "SVGAnimationElement_getStartTime_Callback_RESOLVER_STRING_0_";

  static $requiredExtensions_Getter(mthis) native "SVGAnimationElement_requiredExtensions_Getter";

  static $requiredFeatures_Getter(mthis) native "SVGAnimationElement_requiredFeatures_Getter";

  static $systemLanguage_Getter(mthis) native "SVGAnimationElement_systemLanguage_Getter";

  static $hasExtension_Callback(mthis, extension) native "SVGAnimationElement_hasExtension_Callback_RESOLVER_STRING_1_DOMString";
}

class BlinkSVGAnimateElement {}

class BlinkSVGAnimateMotionElement {}

class BlinkSVGAnimateTransformElement {}

class BlinkSVGAnimatedAngle {
  static $animVal_Getter(mthis) native "SVGAnimatedAngle_animVal_Getter";

  static $baseVal_Getter(mthis) native "SVGAnimatedAngle_baseVal_Getter";
}

class BlinkSVGAnimatedBoolean {
  static $animVal_Getter(mthis) native "SVGAnimatedBoolean_animVal_Getter";

  static $baseVal_Getter(mthis) native "SVGAnimatedBoolean_baseVal_Getter";

  static $baseVal_Setter(mthis, value) native "SVGAnimatedBoolean_baseVal_Setter";
}

class BlinkSVGAnimatedEnumeration {
  static $animVal_Getter(mthis) native "SVGAnimatedEnumeration_animVal_Getter";

  static $baseVal_Getter(mthis) native "SVGAnimatedEnumeration_baseVal_Getter";

  static $baseVal_Setter(mthis, value) native "SVGAnimatedEnumeration_baseVal_Setter";
}

class BlinkSVGAnimatedInteger {
  static $animVal_Getter(mthis) native "SVGAnimatedInteger_animVal_Getter";

  static $baseVal_Getter(mthis) native "SVGAnimatedInteger_baseVal_Getter";

  static $baseVal_Setter(mthis, value) native "SVGAnimatedInteger_baseVal_Setter";
}

class BlinkSVGAnimatedLength {
  static $animVal_Getter(mthis) native "SVGAnimatedLength_animVal_Getter";

  static $baseVal_Getter(mthis) native "SVGAnimatedLength_baseVal_Getter";
}

class BlinkSVGAnimatedLengthList {
  static $animVal_Getter(mthis) native "SVGAnimatedLengthList_animVal_Getter";

  static $baseVal_Getter(mthis) native "SVGAnimatedLengthList_baseVal_Getter";
}

class BlinkSVGAnimatedNumber {
  static $animVal_Getter(mthis) native "SVGAnimatedNumber_animVal_Getter";

  static $baseVal_Getter(mthis) native "SVGAnimatedNumber_baseVal_Getter";

  static $baseVal_Setter(mthis, value) native "SVGAnimatedNumber_baseVal_Setter";
}

class BlinkSVGAnimatedNumberList {
  static $animVal_Getter(mthis) native "SVGAnimatedNumberList_animVal_Getter";

  static $baseVal_Getter(mthis) native "SVGAnimatedNumberList_baseVal_Getter";
}

class BlinkSVGAnimatedPreserveAspectRatio {
  static $animVal_Getter(mthis) native "SVGAnimatedPreserveAspectRatio_animVal_Getter";

  static $baseVal_Getter(mthis) native "SVGAnimatedPreserveAspectRatio_baseVal_Getter";
}

class BlinkSVGAnimatedRect {
  static $animVal_Getter(mthis) native "SVGAnimatedRect_animVal_Getter";

  static $baseVal_Getter(mthis) native "SVGAnimatedRect_baseVal_Getter";
}

class BlinkSVGAnimatedString {
  static $animVal_Getter(mthis) native "SVGAnimatedString_animVal_Getter";

  static $baseVal_Getter(mthis) native "SVGAnimatedString_baseVal_Getter";

  static $baseVal_Setter(mthis, value) native "SVGAnimatedString_baseVal_Setter";
}

class BlinkSVGAnimatedTransformList {
  static $animVal_Getter(mthis) native "SVGAnimatedTransformList_animVal_Getter";

  static $baseVal_Getter(mthis) native "SVGAnimatedTransformList_baseVal_Getter";
}

class BlinkSVGGeometryElement {
  static $isPointInFill_Callback(mthis, point) native "SVGGeometryElement_isPointInFill_Callback_RESOLVER_STRING_1_SVGPoint";

  static $isPointInStroke_Callback(mthis, point) native "SVGGeometryElement_isPointInStroke_Callback_RESOLVER_STRING_1_SVGPoint";
}

class BlinkSVGCircleElement {
  static $cx_Getter(mthis) native "SVGCircleElement_cx_Getter";

  static $cy_Getter(mthis) native "SVGCircleElement_cy_Getter";

  static $r_Getter(mthis) native "SVGCircleElement_r_Getter";
}

class BlinkSVGClipPathElement {
  static $clipPathUnits_Getter(mthis) native "SVGClipPathElement_clipPathUnits_Getter";
}

class BlinkSVGComponentTransferFunctionElement {}

class BlinkSVGCursorElement {}

class BlinkSVGDefsElement {}

class BlinkSVGDescElement {}

class BlinkSVGDiscardElement {}

class BlinkSVGElementInstance {
  static $correspondingElement_Getter(mthis) native "SVGElementInstance_correspondingElement_Getter";

  static $correspondingUseElement_Getter(mthis) native "SVGElementInstance_correspondingUseElement_Getter";

  static $firstChild_Getter(mthis) native "SVGElementInstance_firstChild_Getter";

  static $lastChild_Getter(mthis) native "SVGElementInstance_lastChild_Getter";

  static $nextSibling_Getter(mthis) native "SVGElementInstance_nextSibling_Getter";

  static $parentNode_Getter(mthis) native "SVGElementInstance_parentNode_Getter";

  static $previousSibling_Getter(mthis) native "SVGElementInstance_previousSibling_Getter";
}

class BlinkSVGElementInstanceList {
  static $length_Getter(mthis) native "SVGElementInstanceList_length_Getter";

  static $NativeIndexed_Getter(mthis, index) native "SVGElementInstanceList_item_Callback_RESOLVER_STRING_1_unsigned long";

  static $item_Callback(mthis, index) native "SVGElementInstanceList_item_Callback_RESOLVER_STRING_1_unsigned long";
}

class BlinkSVGEllipseElement {
  static $cx_Getter(mthis) native "SVGEllipseElement_cx_Getter";

  static $cy_Getter(mthis) native "SVGEllipseElement_cy_Getter";

  static $rx_Getter(mthis) native "SVGEllipseElement_rx_Getter";

  static $ry_Getter(mthis) native "SVGEllipseElement_ry_Getter";
}

class BlinkSVGFilterPrimitiveStandardAttributes {
  static $height_Getter(mthis) native "SVGFilterPrimitiveStandardAttributes_height_Getter";

  static $result_Getter(mthis) native "SVGFilterPrimitiveStandardAttributes_result_Getter";

  static $width_Getter(mthis) native "SVGFilterPrimitiveStandardAttributes_width_Getter";

  static $x_Getter(mthis) native "SVGFilterPrimitiveStandardAttributes_x_Getter";

  static $y_Getter(mthis) native "SVGFilterPrimitiveStandardAttributes_y_Getter";
}

class BlinkSVGFEBlendElement {
  static $in1_Getter(mthis) native "SVGFEBlendElement_in1_Getter";

  static $in2_Getter(mthis) native "SVGFEBlendElement_in2_Getter";

  static $mode_Getter(mthis) native "SVGFEBlendElement_mode_Getter";

  static $height_Getter(mthis) native "SVGFEBlendElement_height_Getter";

  static $result_Getter(mthis) native "SVGFEBlendElement_result_Getter";

  static $width_Getter(mthis) native "SVGFEBlendElement_width_Getter";

  static $x_Getter(mthis) native "SVGFEBlendElement_x_Getter";

  static $y_Getter(mthis) native "SVGFEBlendElement_y_Getter";
}

class BlinkSVGFEColorMatrixElement {
  static $in1_Getter(mthis) native "SVGFEColorMatrixElement_in1_Getter";

  static $type_Getter(mthis) native "SVGFEColorMatrixElement_type_Getter";

  static $values_Getter(mthis) native "SVGFEColorMatrixElement_values_Getter";

  static $height_Getter(mthis) native "SVGFEColorMatrixElement_height_Getter";

  static $result_Getter(mthis) native "SVGFEColorMatrixElement_result_Getter";

  static $width_Getter(mthis) native "SVGFEColorMatrixElement_width_Getter";

  static $x_Getter(mthis) native "SVGFEColorMatrixElement_x_Getter";

  static $y_Getter(mthis) native "SVGFEColorMatrixElement_y_Getter";
}

class BlinkSVGFEComponentTransferElement {
  static $in1_Getter(mthis) native "SVGFEComponentTransferElement_in1_Getter";

  static $height_Getter(mthis) native "SVGFEComponentTransferElement_height_Getter";

  static $result_Getter(mthis) native "SVGFEComponentTransferElement_result_Getter";

  static $width_Getter(mthis) native "SVGFEComponentTransferElement_width_Getter";

  static $x_Getter(mthis) native "SVGFEComponentTransferElement_x_Getter";

  static $y_Getter(mthis) native "SVGFEComponentTransferElement_y_Getter";
}

class BlinkSVGFECompositeElement {
  static $in1_Getter(mthis) native "SVGFECompositeElement_in1_Getter";

  static $in2_Getter(mthis) native "SVGFECompositeElement_in2_Getter";

  static $k1_Getter(mthis) native "SVGFECompositeElement_k1_Getter";

  static $k2_Getter(mthis) native "SVGFECompositeElement_k2_Getter";

  static $k3_Getter(mthis) native "SVGFECompositeElement_k3_Getter";

  static $k4_Getter(mthis) native "SVGFECompositeElement_k4_Getter";

  static $operator_Getter(mthis) native "SVGFECompositeElement_operator_Getter";

  static $height_Getter(mthis) native "SVGFECompositeElement_height_Getter";

  static $result_Getter(mthis) native "SVGFECompositeElement_result_Getter";

  static $width_Getter(mthis) native "SVGFECompositeElement_width_Getter";

  static $x_Getter(mthis) native "SVGFECompositeElement_x_Getter";

  static $y_Getter(mthis) native "SVGFECompositeElement_y_Getter";
}

class BlinkSVGFEConvolveMatrixElement {
  static $bias_Getter(mthis) native "SVGFEConvolveMatrixElement_bias_Getter";

  static $divisor_Getter(mthis) native "SVGFEConvolveMatrixElement_divisor_Getter";

  static $edgeMode_Getter(mthis) native "SVGFEConvolveMatrixElement_edgeMode_Getter";

  static $in1_Getter(mthis) native "SVGFEConvolveMatrixElement_in1_Getter";

  static $kernelMatrix_Getter(mthis) native "SVGFEConvolveMatrixElement_kernelMatrix_Getter";

  static $kernelUnitLengthX_Getter(mthis) native "SVGFEConvolveMatrixElement_kernelUnitLengthX_Getter";

  static $kernelUnitLengthY_Getter(mthis) native "SVGFEConvolveMatrixElement_kernelUnitLengthY_Getter";

  static $orderX_Getter(mthis) native "SVGFEConvolveMatrixElement_orderX_Getter";

  static $orderY_Getter(mthis) native "SVGFEConvolveMatrixElement_orderY_Getter";

  static $preserveAlpha_Getter(mthis) native "SVGFEConvolveMatrixElement_preserveAlpha_Getter";

  static $targetX_Getter(mthis) native "SVGFEConvolveMatrixElement_targetX_Getter";

  static $targetY_Getter(mthis) native "SVGFEConvolveMatrixElement_targetY_Getter";

  static $height_Getter(mthis) native "SVGFEConvolveMatrixElement_height_Getter";

  static $result_Getter(mthis) native "SVGFEConvolveMatrixElement_result_Getter";

  static $width_Getter(mthis) native "SVGFEConvolveMatrixElement_width_Getter";

  static $x_Getter(mthis) native "SVGFEConvolveMatrixElement_x_Getter";

  static $y_Getter(mthis) native "SVGFEConvolveMatrixElement_y_Getter";
}

class BlinkSVGFEDiffuseLightingElement {
  static $diffuseConstant_Getter(mthis) native "SVGFEDiffuseLightingElement_diffuseConstant_Getter";

  static $in1_Getter(mthis) native "SVGFEDiffuseLightingElement_in1_Getter";

  static $kernelUnitLengthX_Getter(mthis) native "SVGFEDiffuseLightingElement_kernelUnitLengthX_Getter";

  static $kernelUnitLengthY_Getter(mthis) native "SVGFEDiffuseLightingElement_kernelUnitLengthY_Getter";

  static $surfaceScale_Getter(mthis) native "SVGFEDiffuseLightingElement_surfaceScale_Getter";

  static $height_Getter(mthis) native "SVGFEDiffuseLightingElement_height_Getter";

  static $result_Getter(mthis) native "SVGFEDiffuseLightingElement_result_Getter";

  static $width_Getter(mthis) native "SVGFEDiffuseLightingElement_width_Getter";

  static $x_Getter(mthis) native "SVGFEDiffuseLightingElement_x_Getter";

  static $y_Getter(mthis) native "SVGFEDiffuseLightingElement_y_Getter";
}

class BlinkSVGFEDisplacementMapElement {
  static $in1_Getter(mthis) native "SVGFEDisplacementMapElement_in1_Getter";

  static $in2_Getter(mthis) native "SVGFEDisplacementMapElement_in2_Getter";

  static $scale_Getter(mthis) native "SVGFEDisplacementMapElement_scale_Getter";

  static $xChannelSelector_Getter(mthis) native "SVGFEDisplacementMapElement_xChannelSelector_Getter";

  static $yChannelSelector_Getter(mthis) native "SVGFEDisplacementMapElement_yChannelSelector_Getter";

  static $height_Getter(mthis) native "SVGFEDisplacementMapElement_height_Getter";

  static $result_Getter(mthis) native "SVGFEDisplacementMapElement_result_Getter";

  static $width_Getter(mthis) native "SVGFEDisplacementMapElement_width_Getter";

  static $x_Getter(mthis) native "SVGFEDisplacementMapElement_x_Getter";

  static $y_Getter(mthis) native "SVGFEDisplacementMapElement_y_Getter";
}

class BlinkSVGFEDistantLightElement {
  static $azimuth_Getter(mthis) native "SVGFEDistantLightElement_azimuth_Getter";

  static $elevation_Getter(mthis) native "SVGFEDistantLightElement_elevation_Getter";
}

class BlinkSVGFEDropShadowElement {}

class BlinkSVGFEFloodElement {
  static $height_Getter(mthis) native "SVGFEFloodElement_height_Getter";

  static $result_Getter(mthis) native "SVGFEFloodElement_result_Getter";

  static $width_Getter(mthis) native "SVGFEFloodElement_width_Getter";

  static $x_Getter(mthis) native "SVGFEFloodElement_x_Getter";

  static $y_Getter(mthis) native "SVGFEFloodElement_y_Getter";
}

class BlinkSVGFEFuncAElement {}

class BlinkSVGFEFuncBElement {}

class BlinkSVGFEFuncGElement {}

class BlinkSVGFEFuncRElement {}

class BlinkSVGFEGaussianBlurElement {
  static $in1_Getter(mthis) native "SVGFEGaussianBlurElement_in1_Getter";

  static $stdDeviationX_Getter(mthis) native "SVGFEGaussianBlurElement_stdDeviationX_Getter";

  static $stdDeviationY_Getter(mthis) native "SVGFEGaussianBlurElement_stdDeviationY_Getter";

  static $setStdDeviation_Callback(mthis, stdDeviationX, stdDeviationY) native "SVGFEGaussianBlurElement_setStdDeviation_Callback_RESOLVER_STRING_2_float_float";

  static $height_Getter(mthis) native "SVGFEGaussianBlurElement_height_Getter";

  static $result_Getter(mthis) native "SVGFEGaussianBlurElement_result_Getter";

  static $width_Getter(mthis) native "SVGFEGaussianBlurElement_width_Getter";

  static $x_Getter(mthis) native "SVGFEGaussianBlurElement_x_Getter";

  static $y_Getter(mthis) native "SVGFEGaussianBlurElement_y_Getter";
}

class BlinkSVGFEImageElement {
  static $preserveAspectRatio_Getter(mthis) native "SVGFEImageElement_preserveAspectRatio_Getter";

  static $height_Getter(mthis) native "SVGFEImageElement_height_Getter";

  static $result_Getter(mthis) native "SVGFEImageElement_result_Getter";

  static $width_Getter(mthis) native "SVGFEImageElement_width_Getter";

  static $x_Getter(mthis) native "SVGFEImageElement_x_Getter";

  static $y_Getter(mthis) native "SVGFEImageElement_y_Getter";

  static $href_Getter(mthis) native "SVGFEImageElement_href_Getter";
}

class BlinkSVGFEMergeElement {
  static $height_Getter(mthis) native "SVGFEMergeElement_height_Getter";

  static $result_Getter(mthis) native "SVGFEMergeElement_result_Getter";

  static $width_Getter(mthis) native "SVGFEMergeElement_width_Getter";

  static $x_Getter(mthis) native "SVGFEMergeElement_x_Getter";

  static $y_Getter(mthis) native "SVGFEMergeElement_y_Getter";
}

class BlinkSVGFEMergeNodeElement {
  static $in1_Getter(mthis) native "SVGFEMergeNodeElement_in1_Getter";
}

class BlinkSVGFEMorphologyElement {
  static $in1_Getter(mthis) native "SVGFEMorphologyElement_in1_Getter";

  static $operator_Getter(mthis) native "SVGFEMorphologyElement_operator_Getter";

  static $radiusX_Getter(mthis) native "SVGFEMorphologyElement_radiusX_Getter";

  static $radiusY_Getter(mthis) native "SVGFEMorphologyElement_radiusY_Getter";

  static $setRadius_Callback(mthis, radiusX, radiusY) native "SVGFEMorphologyElement_setRadius_Callback_RESOLVER_STRING_2_float_float";

  static $height_Getter(mthis) native "SVGFEMorphologyElement_height_Getter";

  static $result_Getter(mthis) native "SVGFEMorphologyElement_result_Getter";

  static $width_Getter(mthis) native "SVGFEMorphologyElement_width_Getter";

  static $x_Getter(mthis) native "SVGFEMorphologyElement_x_Getter";

  static $y_Getter(mthis) native "SVGFEMorphologyElement_y_Getter";
}

class BlinkSVGFEOffsetElement {
  static $dx_Getter(mthis) native "SVGFEOffsetElement_dx_Getter";

  static $dy_Getter(mthis) native "SVGFEOffsetElement_dy_Getter";

  static $in1_Getter(mthis) native "SVGFEOffsetElement_in1_Getter";

  static $height_Getter(mthis) native "SVGFEOffsetElement_height_Getter";

  static $result_Getter(mthis) native "SVGFEOffsetElement_result_Getter";

  static $width_Getter(mthis) native "SVGFEOffsetElement_width_Getter";

  static $x_Getter(mthis) native "SVGFEOffsetElement_x_Getter";

  static $y_Getter(mthis) native "SVGFEOffsetElement_y_Getter";
}

class BlinkSVGFEPointLightElement {
  static $x_Getter(mthis) native "SVGFEPointLightElement_x_Getter";

  static $y_Getter(mthis) native "SVGFEPointLightElement_y_Getter";

  static $z_Getter(mthis) native "SVGFEPointLightElement_z_Getter";
}

class BlinkSVGFESpecularLightingElement {
  static $in1_Getter(mthis) native "SVGFESpecularLightingElement_in1_Getter";

  static $specularConstant_Getter(mthis) native "SVGFESpecularLightingElement_specularConstant_Getter";

  static $specularExponent_Getter(mthis) native "SVGFESpecularLightingElement_specularExponent_Getter";

  static $surfaceScale_Getter(mthis) native "SVGFESpecularLightingElement_surfaceScale_Getter";

  static $height_Getter(mthis) native "SVGFESpecularLightingElement_height_Getter";

  static $result_Getter(mthis) native "SVGFESpecularLightingElement_result_Getter";

  static $width_Getter(mthis) native "SVGFESpecularLightingElement_width_Getter";

  static $x_Getter(mthis) native "SVGFESpecularLightingElement_x_Getter";

  static $y_Getter(mthis) native "SVGFESpecularLightingElement_y_Getter";
}

class BlinkSVGFESpotLightElement {
  static $limitingConeAngle_Getter(mthis) native "SVGFESpotLightElement_limitingConeAngle_Getter";

  static $pointsAtX_Getter(mthis) native "SVGFESpotLightElement_pointsAtX_Getter";

  static $pointsAtY_Getter(mthis) native "SVGFESpotLightElement_pointsAtY_Getter";

  static $pointsAtZ_Getter(mthis) native "SVGFESpotLightElement_pointsAtZ_Getter";

  static $specularExponent_Getter(mthis) native "SVGFESpotLightElement_specularExponent_Getter";

  static $x_Getter(mthis) native "SVGFESpotLightElement_x_Getter";

  static $y_Getter(mthis) native "SVGFESpotLightElement_y_Getter";

  static $z_Getter(mthis) native "SVGFESpotLightElement_z_Getter";
}

class BlinkSVGFETileElement {
  static $in1_Getter(mthis) native "SVGFETileElement_in1_Getter";

  static $height_Getter(mthis) native "SVGFETileElement_height_Getter";

  static $result_Getter(mthis) native "SVGFETileElement_result_Getter";

  static $width_Getter(mthis) native "SVGFETileElement_width_Getter";

  static $x_Getter(mthis) native "SVGFETileElement_x_Getter";

  static $y_Getter(mthis) native "SVGFETileElement_y_Getter";
}

class BlinkSVGFETurbulenceElement {
  static $baseFrequencyX_Getter(mthis) native "SVGFETurbulenceElement_baseFrequencyX_Getter";

  static $baseFrequencyY_Getter(mthis) native "SVGFETurbulenceElement_baseFrequencyY_Getter";

  static $numOctaves_Getter(mthis) native "SVGFETurbulenceElement_numOctaves_Getter";

  static $seed_Getter(mthis) native "SVGFETurbulenceElement_seed_Getter";

  static $stitchTiles_Getter(mthis) native "SVGFETurbulenceElement_stitchTiles_Getter";

  static $type_Getter(mthis) native "SVGFETurbulenceElement_type_Getter";

  static $height_Getter(mthis) native "SVGFETurbulenceElement_height_Getter";

  static $result_Getter(mthis) native "SVGFETurbulenceElement_result_Getter";

  static $width_Getter(mthis) native "SVGFETurbulenceElement_width_Getter";

  static $x_Getter(mthis) native "SVGFETurbulenceElement_x_Getter";

  static $y_Getter(mthis) native "SVGFETurbulenceElement_y_Getter";
}

class BlinkSVGFilterElement {
  static $filterResX_Getter(mthis) native "SVGFilterElement_filterResX_Getter";

  static $filterResY_Getter(mthis) native "SVGFilterElement_filterResY_Getter";

  static $filterUnits_Getter(mthis) native "SVGFilterElement_filterUnits_Getter";

  static $height_Getter(mthis) native "SVGFilterElement_height_Getter";

  static $primitiveUnits_Getter(mthis) native "SVGFilterElement_primitiveUnits_Getter";

  static $width_Getter(mthis) native "SVGFilterElement_width_Getter";

  static $x_Getter(mthis) native "SVGFilterElement_x_Getter";

  static $y_Getter(mthis) native "SVGFilterElement_y_Getter";

  static $setFilterRes_Callback(mthis, filterResX, filterResY) native "SVGFilterElement_setFilterRes_Callback_RESOLVER_STRING_2_unsigned long_unsigned long";

  static $href_Getter(mthis) native "SVGFilterElement_href_Getter";
}

class BlinkSVGFitToViewBox {
  static $preserveAspectRatio_Getter(mthis) native "SVGFitToViewBox_preserveAspectRatio_Getter";

  static $viewBox_Getter(mthis) native "SVGFitToViewBox_viewBox_Getter";
}

class BlinkSVGFontElement {}

class BlinkSVGFontFaceElement {}

class BlinkSVGFontFaceFormatElement {}

class BlinkSVGFontFaceNameElement {}

class BlinkSVGFontFaceSrcElement {}

class BlinkSVGFontFaceUriElement {}

class BlinkSVGForeignObjectElement {
  static $height_Getter(mthis) native "SVGForeignObjectElement_height_Getter";

  static $width_Getter(mthis) native "SVGForeignObjectElement_width_Getter";

  static $x_Getter(mthis) native "SVGForeignObjectElement_x_Getter";

  static $y_Getter(mthis) native "SVGForeignObjectElement_y_Getter";
}

class BlinkSVGGElement {}

class BlinkSVGGlyphElement {}

class BlinkSVGGlyphRefElement {}

class BlinkSVGGradientElement {
  static $gradientTransform_Getter(mthis) native "SVGGradientElement_gradientTransform_Getter";

  static $gradientUnits_Getter(mthis) native "SVGGradientElement_gradientUnits_Getter";

  static $spreadMethod_Getter(mthis) native "SVGGradientElement_spreadMethod_Getter";

  static $href_Getter(mthis) native "SVGGradientElement_href_Getter";
}

class BlinkSVGHKernElement {}

class BlinkSVGImageElement {
  static $height_Getter(mthis) native "SVGImageElement_height_Getter";

  static $preserveAspectRatio_Getter(mthis) native "SVGImageElement_preserveAspectRatio_Getter";

  static $width_Getter(mthis) native "SVGImageElement_width_Getter";

  static $x_Getter(mthis) native "SVGImageElement_x_Getter";

  static $y_Getter(mthis) native "SVGImageElement_y_Getter";

  static $href_Getter(mthis) native "SVGImageElement_href_Getter";
}

class BlinkSVGLength {
  static $unitType_Getter(mthis) native "SVGLength_unitType_Getter";

  static $value_Getter(mthis) native "SVGLength_value_Getter";

  static $value_Setter(mthis, value) native "SVGLength_value_Setter";

  static $valueAsString_Getter(mthis) native "SVGLength_valueAsString_Getter";

  static $valueAsString_Setter(mthis, value) native "SVGLength_valueAsString_Setter";

  static $valueInSpecifiedUnits_Getter(mthis) native "SVGLength_valueInSpecifiedUnits_Getter";

  static $valueInSpecifiedUnits_Setter(mthis, value) native "SVGLength_valueInSpecifiedUnits_Setter";

  static $convertToSpecifiedUnits_Callback(mthis, unitType) native "SVGLength_convertToSpecifiedUnits_Callback_RESOLVER_STRING_1_unsigned short";

  static $newValueSpecifiedUnits_Callback(mthis, unitType, valueInSpecifiedUnits) native "SVGLength_newValueSpecifiedUnits_Callback_RESOLVER_STRING_2_unsigned short_float";
}

class BlinkSVGLengthList {
  static $numberOfItems_Getter(mthis) native "SVGLengthList_numberOfItems_Getter";

  static $appendItem_Callback(mthis, item) native "SVGLengthList_appendItem_Callback_RESOLVER_STRING_1_SVGLength";

  static $clear_Callback(mthis) native "SVGLengthList_clear_Callback_RESOLVER_STRING_0_";

  static $getItem_Callback(mthis, index) native "SVGLengthList_getItem_Callback_RESOLVER_STRING_1_unsigned long";

  static $initialize_Callback(mthis, item) native "SVGLengthList_initialize_Callback_RESOLVER_STRING_1_SVGLength";

  static $insertItemBefore_Callback(mthis, item, index) native "SVGLengthList_insertItemBefore_Callback_RESOLVER_STRING_2_SVGLength_unsigned long";

  static $removeItem_Callback(mthis, index) native "SVGLengthList_removeItem_Callback_RESOLVER_STRING_1_unsigned long";

  static $replaceItem_Callback(mthis, item, index) native "SVGLengthList_replaceItem_Callback_RESOLVER_STRING_2_SVGLength_unsigned long";
}

class BlinkSVGLineElement {
  static $x1_Getter(mthis) native "SVGLineElement_x1_Getter";

  static $x2_Getter(mthis) native "SVGLineElement_x2_Getter";

  static $y1_Getter(mthis) native "SVGLineElement_y1_Getter";

  static $y2_Getter(mthis) native "SVGLineElement_y2_Getter";
}

class BlinkSVGLinearGradientElement {
  static $x1_Getter(mthis) native "SVGLinearGradientElement_x1_Getter";

  static $x2_Getter(mthis) native "SVGLinearGradientElement_x2_Getter";

  static $y1_Getter(mthis) native "SVGLinearGradientElement_y1_Getter";

  static $y2_Getter(mthis) native "SVGLinearGradientElement_y2_Getter";
}

class BlinkSVGMPathElement {}

class BlinkSVGMarkerElement {
  static $markerHeight_Getter(mthis) native "SVGMarkerElement_markerHeight_Getter";

  static $markerUnits_Getter(mthis) native "SVGMarkerElement_markerUnits_Getter";

  static $markerWidth_Getter(mthis) native "SVGMarkerElement_markerWidth_Getter";

  static $orientAngle_Getter(mthis) native "SVGMarkerElement_orientAngle_Getter";

  static $orientType_Getter(mthis) native "SVGMarkerElement_orientType_Getter";

  static $refX_Getter(mthis) native "SVGMarkerElement_refX_Getter";

  static $refY_Getter(mthis) native "SVGMarkerElement_refY_Getter";

  static $setOrientToAngle_Callback(mthis, angle) native "SVGMarkerElement_setOrientToAngle_Callback_RESOLVER_STRING_1_SVGAngle";

  static $setOrientToAuto_Callback(mthis) native "SVGMarkerElement_setOrientToAuto_Callback_RESOLVER_STRING_0_";

  static $preserveAspectRatio_Getter(mthis) native "SVGMarkerElement_preserveAspectRatio_Getter";

  static $viewBox_Getter(mthis) native "SVGMarkerElement_viewBox_Getter";
}

class BlinkSVGMaskElement {
  static $height_Getter(mthis) native "SVGMaskElement_height_Getter";

  static $maskContentUnits_Getter(mthis) native "SVGMaskElement_maskContentUnits_Getter";

  static $maskUnits_Getter(mthis) native "SVGMaskElement_maskUnits_Getter";

  static $width_Getter(mthis) native "SVGMaskElement_width_Getter";

  static $x_Getter(mthis) native "SVGMaskElement_x_Getter";

  static $y_Getter(mthis) native "SVGMaskElement_y_Getter";

  static $requiredExtensions_Getter(mthis) native "SVGMaskElement_requiredExtensions_Getter";

  static $requiredFeatures_Getter(mthis) native "SVGMaskElement_requiredFeatures_Getter";

  static $systemLanguage_Getter(mthis) native "SVGMaskElement_systemLanguage_Getter";

  static $hasExtension_Callback(mthis, extension) native "SVGMaskElement_hasExtension_Callback_RESOLVER_STRING_1_DOMString";
}

class BlinkSVGMatrix {
  static $a_Getter(mthis) native "SVGMatrix_a_Getter";

  static $a_Setter(mthis, value) native "SVGMatrix_a_Setter";

  static $b_Getter(mthis) native "SVGMatrix_b_Getter";

  static $b_Setter(mthis, value) native "SVGMatrix_b_Setter";

  static $c_Getter(mthis) native "SVGMatrix_c_Getter";

  static $c_Setter(mthis, value) native "SVGMatrix_c_Setter";

  static $d_Getter(mthis) native "SVGMatrix_d_Getter";

  static $d_Setter(mthis, value) native "SVGMatrix_d_Setter";

  static $e_Getter(mthis) native "SVGMatrix_e_Getter";

  static $e_Setter(mthis, value) native "SVGMatrix_e_Setter";

  static $f_Getter(mthis) native "SVGMatrix_f_Getter";

  static $f_Setter(mthis, value) native "SVGMatrix_f_Setter";

  static $flipX_Callback(mthis) native "SVGMatrix_flipX_Callback_RESOLVER_STRING_0_";

  static $flipY_Callback(mthis) native "SVGMatrix_flipY_Callback_RESOLVER_STRING_0_";

  static $inverse_Callback(mthis) native "SVGMatrix_inverse_Callback_RESOLVER_STRING_0_";

  static $multiply_Callback(mthis, secondMatrix) native "SVGMatrix_multiply_Callback_RESOLVER_STRING_1_SVGMatrix";

  static $rotate_Callback(mthis, angle) native "SVGMatrix_rotate_Callback_RESOLVER_STRING_1_float";

  static $rotateFromVector_Callback(mthis, x, y) native "SVGMatrix_rotateFromVector_Callback_RESOLVER_STRING_2_float_float";

  static $scale_Callback(mthis, scaleFactor) native "SVGMatrix_scale_Callback_RESOLVER_STRING_1_float";

  static $scaleNonUniform_Callback(mthis, scaleFactorX, scaleFactorY) native "SVGMatrix_scaleNonUniform_Callback_RESOLVER_STRING_2_float_float";

  static $skewX_Callback(mthis, angle) native "SVGMatrix_skewX_Callback_RESOLVER_STRING_1_float";

  static $skewY_Callback(mthis, angle) native "SVGMatrix_skewY_Callback_RESOLVER_STRING_1_float";

  static $translate_Callback(mthis, x, y) native "SVGMatrix_translate_Callback_RESOLVER_STRING_2_float_float";
}

class BlinkSVGMetadataElement {}

class BlinkSVGMissingGlyphElement {}

class BlinkSVGNumber {
  static $value_Getter(mthis) native "SVGNumber_value_Getter";

  static $value_Setter(mthis, value) native "SVGNumber_value_Setter";
}

class BlinkSVGNumberList {
  static $numberOfItems_Getter(mthis) native "SVGNumberList_numberOfItems_Getter";

  static $appendItem_Callback(mthis, item) native "SVGNumberList_appendItem_Callback_RESOLVER_STRING_1_SVGNumber";

  static $clear_Callback(mthis) native "SVGNumberList_clear_Callback_RESOLVER_STRING_0_";

  static $getItem_Callback(mthis, index) native "SVGNumberList_getItem_Callback_RESOLVER_STRING_1_unsigned long";

  static $initialize_Callback(mthis, item) native "SVGNumberList_initialize_Callback_RESOLVER_STRING_1_SVGNumber";

  static $insertItemBefore_Callback(mthis, item, index) native "SVGNumberList_insertItemBefore_Callback_RESOLVER_STRING_2_SVGNumber_unsigned long";

  static $removeItem_Callback(mthis, index) native "SVGNumberList_removeItem_Callback_RESOLVER_STRING_1_unsigned long";

  static $replaceItem_Callback(mthis, item, index) native "SVGNumberList_replaceItem_Callback_RESOLVER_STRING_2_SVGNumber_unsigned long";
}

class BlinkSVGPathElement {
  static $animatedNormalizedPathSegList_Getter(mthis) native "SVGPathElement_animatedNormalizedPathSegList_Getter";

  static $animatedPathSegList_Getter(mthis) native "SVGPathElement_animatedPathSegList_Getter";

  static $normalizedPathSegList_Getter(mthis) native "SVGPathElement_normalizedPathSegList_Getter";

  static $pathLength_Getter(mthis) native "SVGPathElement_pathLength_Getter";

  static $pathSegList_Getter(mthis) native "SVGPathElement_pathSegList_Getter";

  static $createSVGPathSegArcAbs_Callback(mthis, x, y, r1, r2, angle, largeArcFlag, sweepFlag) native "SVGPathElement_createSVGPathSegArcAbs_Callback_RESOLVER_STRING_7_float_float_float_float_float_boolean_boolean";

  static $createSVGPathSegArcRel_Callback(mthis, x, y, r1, r2, angle, largeArcFlag, sweepFlag) native "SVGPathElement_createSVGPathSegArcRel_Callback_RESOLVER_STRING_7_float_float_float_float_float_boolean_boolean";

  static $createSVGPathSegClosePath_Callback(mthis) native "SVGPathElement_createSVGPathSegClosePath_Callback_RESOLVER_STRING_0_";

  static $createSVGPathSegCurvetoCubicAbs_Callback(mthis, x, y, x1, y1, x2, y2) native "SVGPathElement_createSVGPathSegCurvetoCubicAbs_Callback_RESOLVER_STRING_6_float_float_float_float_float_float";

  static $createSVGPathSegCurvetoCubicRel_Callback(mthis, x, y, x1, y1, x2, y2) native "SVGPathElement_createSVGPathSegCurvetoCubicRel_Callback_RESOLVER_STRING_6_float_float_float_float_float_float";

  static $createSVGPathSegCurvetoCubicSmoothAbs_Callback(mthis, x, y, x2, y2) native "SVGPathElement_createSVGPathSegCurvetoCubicSmoothAbs_Callback_RESOLVER_STRING_4_float_float_float_float";

  static $createSVGPathSegCurvetoCubicSmoothRel_Callback(mthis, x, y, x2, y2) native "SVGPathElement_createSVGPathSegCurvetoCubicSmoothRel_Callback_RESOLVER_STRING_4_float_float_float_float";

  static $createSVGPathSegCurvetoQuadraticAbs_Callback(mthis, x, y, x1, y1) native "SVGPathElement_createSVGPathSegCurvetoQuadraticAbs_Callback_RESOLVER_STRING_4_float_float_float_float";

  static $createSVGPathSegCurvetoQuadraticRel_Callback(mthis, x, y, x1, y1) native "SVGPathElement_createSVGPathSegCurvetoQuadraticRel_Callback_RESOLVER_STRING_4_float_float_float_float";

  static $createSVGPathSegCurvetoQuadraticSmoothAbs_Callback(mthis, x, y) native "SVGPathElement_createSVGPathSegCurvetoQuadraticSmoothAbs_Callback_RESOLVER_STRING_2_float_float";

  static $createSVGPathSegCurvetoQuadraticSmoothRel_Callback(mthis, x, y) native "SVGPathElement_createSVGPathSegCurvetoQuadraticSmoothRel_Callback_RESOLVER_STRING_2_float_float";

  static $createSVGPathSegLinetoAbs_Callback(mthis, x, y) native "SVGPathElement_createSVGPathSegLinetoAbs_Callback_RESOLVER_STRING_2_float_float";

  static $createSVGPathSegLinetoHorizontalAbs_Callback(mthis, x) native "SVGPathElement_createSVGPathSegLinetoHorizontalAbs_Callback_RESOLVER_STRING_1_float";

  static $createSVGPathSegLinetoHorizontalRel_Callback(mthis, x) native "SVGPathElement_createSVGPathSegLinetoHorizontalRel_Callback_RESOLVER_STRING_1_float";

  static $createSVGPathSegLinetoRel_Callback(mthis, x, y) native "SVGPathElement_createSVGPathSegLinetoRel_Callback_RESOLVER_STRING_2_float_float";

  static $createSVGPathSegLinetoVerticalAbs_Callback(mthis, y) native "SVGPathElement_createSVGPathSegLinetoVerticalAbs_Callback_RESOLVER_STRING_1_float";

  static $createSVGPathSegLinetoVerticalRel_Callback(mthis, y) native "SVGPathElement_createSVGPathSegLinetoVerticalRel_Callback_RESOLVER_STRING_1_float";

  static $createSVGPathSegMovetoAbs_Callback(mthis, x, y) native "SVGPathElement_createSVGPathSegMovetoAbs_Callback_RESOLVER_STRING_2_float_float";

  static $createSVGPathSegMovetoRel_Callback(mthis, x, y) native "SVGPathElement_createSVGPathSegMovetoRel_Callback_RESOLVER_STRING_2_float_float";

  static $getPathSegAtLength_Callback(mthis, distance) native "SVGPathElement_getPathSegAtLength_Callback_RESOLVER_STRING_1_float";

  static $getPointAtLength_Callback(mthis, distance) native "SVGPathElement_getPointAtLength_Callback_RESOLVER_STRING_1_float";

  static $getTotalLength_Callback(mthis) native "SVGPathElement_getTotalLength_Callback_RESOLVER_STRING_0_";
}

class BlinkSVGPathSeg {
  static $pathSegType_Getter(mthis) native "SVGPathSeg_pathSegType_Getter";

  static $pathSegTypeAsLetter_Getter(mthis) native "SVGPathSeg_pathSegTypeAsLetter_Getter";
}

class BlinkSVGPathSegArcAbs {
  static $angle_Getter(mthis) native "SVGPathSegArcAbs_angle_Getter";

  static $angle_Setter(mthis, value) native "SVGPathSegArcAbs_angle_Setter";

  static $largeArcFlag_Getter(mthis) native "SVGPathSegArcAbs_largeArcFlag_Getter";

  static $largeArcFlag_Setter(mthis, value) native "SVGPathSegArcAbs_largeArcFlag_Setter";

  static $r1_Getter(mthis) native "SVGPathSegArcAbs_r1_Getter";

  static $r1_Setter(mthis, value) native "SVGPathSegArcAbs_r1_Setter";

  static $r2_Getter(mthis) native "SVGPathSegArcAbs_r2_Getter";

  static $r2_Setter(mthis, value) native "SVGPathSegArcAbs_r2_Setter";

  static $sweepFlag_Getter(mthis) native "SVGPathSegArcAbs_sweepFlag_Getter";

  static $sweepFlag_Setter(mthis, value) native "SVGPathSegArcAbs_sweepFlag_Setter";

  static $x_Getter(mthis) native "SVGPathSegArcAbs_x_Getter";

  static $x_Setter(mthis, value) native "SVGPathSegArcAbs_x_Setter";

  static $y_Getter(mthis) native "SVGPathSegArcAbs_y_Getter";

  static $y_Setter(mthis, value) native "SVGPathSegArcAbs_y_Setter";
}

class BlinkSVGPathSegArcRel {
  static $angle_Getter(mthis) native "SVGPathSegArcRel_angle_Getter";

  static $angle_Setter(mthis, value) native "SVGPathSegArcRel_angle_Setter";

  static $largeArcFlag_Getter(mthis) native "SVGPathSegArcRel_largeArcFlag_Getter";

  static $largeArcFlag_Setter(mthis, value) native "SVGPathSegArcRel_largeArcFlag_Setter";

  static $r1_Getter(mthis) native "SVGPathSegArcRel_r1_Getter";

  static $r1_Setter(mthis, value) native "SVGPathSegArcRel_r1_Setter";

  static $r2_Getter(mthis) native "SVGPathSegArcRel_r2_Getter";

  static $r2_Setter(mthis, value) native "SVGPathSegArcRel_r2_Setter";

  static $sweepFlag_Getter(mthis) native "SVGPathSegArcRel_sweepFlag_Getter";

  static $sweepFlag_Setter(mthis, value) native "SVGPathSegArcRel_sweepFlag_Setter";

  static $x_Getter(mthis) native "SVGPathSegArcRel_x_Getter";

  static $x_Setter(mthis, value) native "SVGPathSegArcRel_x_Setter";

  static $y_Getter(mthis) native "SVGPathSegArcRel_y_Getter";

  static $y_Setter(mthis, value) native "SVGPathSegArcRel_y_Setter";
}

class BlinkSVGPathSegClosePath {}

class BlinkSVGPathSegCurvetoCubicAbs {
  static $x_Getter(mthis) native "SVGPathSegCurvetoCubicAbs_x_Getter";

  static $x_Setter(mthis, value) native "SVGPathSegCurvetoCubicAbs_x_Setter";

  static $x1_Getter(mthis) native "SVGPathSegCurvetoCubicAbs_x1_Getter";

  static $x1_Setter(mthis, value) native "SVGPathSegCurvetoCubicAbs_x1_Setter";

  static $x2_Getter(mthis) native "SVGPathSegCurvetoCubicAbs_x2_Getter";

  static $x2_Setter(mthis, value) native "SVGPathSegCurvetoCubicAbs_x2_Setter";

  static $y_Getter(mthis) native "SVGPathSegCurvetoCubicAbs_y_Getter";

  static $y_Setter(mthis, value) native "SVGPathSegCurvetoCubicAbs_y_Setter";

  static $y1_Getter(mthis) native "SVGPathSegCurvetoCubicAbs_y1_Getter";

  static $y1_Setter(mthis, value) native "SVGPathSegCurvetoCubicAbs_y1_Setter";

  static $y2_Getter(mthis) native "SVGPathSegCurvetoCubicAbs_y2_Getter";

  static $y2_Setter(mthis, value) native "SVGPathSegCurvetoCubicAbs_y2_Setter";
}

class BlinkSVGPathSegCurvetoCubicRel {
  static $x_Getter(mthis) native "SVGPathSegCurvetoCubicRel_x_Getter";

  static $x_Setter(mthis, value) native "SVGPathSegCurvetoCubicRel_x_Setter";

  static $x1_Getter(mthis) native "SVGPathSegCurvetoCubicRel_x1_Getter";

  static $x1_Setter(mthis, value) native "SVGPathSegCurvetoCubicRel_x1_Setter";

  static $x2_Getter(mthis) native "SVGPathSegCurvetoCubicRel_x2_Getter";

  static $x2_Setter(mthis, value) native "SVGPathSegCurvetoCubicRel_x2_Setter";

  static $y_Getter(mthis) native "SVGPathSegCurvetoCubicRel_y_Getter";

  static $y_Setter(mthis, value) native "SVGPathSegCurvetoCubicRel_y_Setter";

  static $y1_Getter(mthis) native "SVGPathSegCurvetoCubicRel_y1_Getter";

  static $y1_Setter(mthis, value) native "SVGPathSegCurvetoCubicRel_y1_Setter";

  static $y2_Getter(mthis) native "SVGPathSegCurvetoCubicRel_y2_Getter";

  static $y2_Setter(mthis, value) native "SVGPathSegCurvetoCubicRel_y2_Setter";
}

class BlinkSVGPathSegCurvetoCubicSmoothAbs {
  static $x_Getter(mthis) native "SVGPathSegCurvetoCubicSmoothAbs_x_Getter";

  static $x_Setter(mthis, value) native "SVGPathSegCurvetoCubicSmoothAbs_x_Setter";

  static $x2_Getter(mthis) native "SVGPathSegCurvetoCubicSmoothAbs_x2_Getter";

  static $x2_Setter(mthis, value) native "SVGPathSegCurvetoCubicSmoothAbs_x2_Setter";

  static $y_Getter(mthis) native "SVGPathSegCurvetoCubicSmoothAbs_y_Getter";

  static $y_Setter(mthis, value) native "SVGPathSegCurvetoCubicSmoothAbs_y_Setter";

  static $y2_Getter(mthis) native "SVGPathSegCurvetoCubicSmoothAbs_y2_Getter";

  static $y2_Setter(mthis, value) native "SVGPathSegCurvetoCubicSmoothAbs_y2_Setter";
}

class BlinkSVGPathSegCurvetoCubicSmoothRel {
  static $x_Getter(mthis) native "SVGPathSegCurvetoCubicSmoothRel_x_Getter";

  static $x_Setter(mthis, value) native "SVGPathSegCurvetoCubicSmoothRel_x_Setter";

  static $x2_Getter(mthis) native "SVGPathSegCurvetoCubicSmoothRel_x2_Getter";

  static $x2_Setter(mthis, value) native "SVGPathSegCurvetoCubicSmoothRel_x2_Setter";

  static $y_Getter(mthis) native "SVGPathSegCurvetoCubicSmoothRel_y_Getter";

  static $y_Setter(mthis, value) native "SVGPathSegCurvetoCubicSmoothRel_y_Setter";

  static $y2_Getter(mthis) native "SVGPathSegCurvetoCubicSmoothRel_y2_Getter";

  static $y2_Setter(mthis, value) native "SVGPathSegCurvetoCubicSmoothRel_y2_Setter";
}

class BlinkSVGPathSegCurvetoQuadraticAbs {
  static $x_Getter(mthis) native "SVGPathSegCurvetoQuadraticAbs_x_Getter";

  static $x_Setter(mthis, value) native "SVGPathSegCurvetoQuadraticAbs_x_Setter";

  static $x1_Getter(mthis) native "SVGPathSegCurvetoQuadraticAbs_x1_Getter";

  static $x1_Setter(mthis, value) native "SVGPathSegCurvetoQuadraticAbs_x1_Setter";

  static $y_Getter(mthis) native "SVGPathSegCurvetoQuadraticAbs_y_Getter";

  static $y_Setter(mthis, value) native "SVGPathSegCurvetoQuadraticAbs_y_Setter";

  static $y1_Getter(mthis) native "SVGPathSegCurvetoQuadraticAbs_y1_Getter";

  static $y1_Setter(mthis, value) native "SVGPathSegCurvetoQuadraticAbs_y1_Setter";
}

class BlinkSVGPathSegCurvetoQuadraticRel {
  static $x_Getter(mthis) native "SVGPathSegCurvetoQuadraticRel_x_Getter";

  static $x_Setter(mthis, value) native "SVGPathSegCurvetoQuadraticRel_x_Setter";

  static $x1_Getter(mthis) native "SVGPathSegCurvetoQuadraticRel_x1_Getter";

  static $x1_Setter(mthis, value) native "SVGPathSegCurvetoQuadraticRel_x1_Setter";

  static $y_Getter(mthis) native "SVGPathSegCurvetoQuadraticRel_y_Getter";

  static $y_Setter(mthis, value) native "SVGPathSegCurvetoQuadraticRel_y_Setter";

  static $y1_Getter(mthis) native "SVGPathSegCurvetoQuadraticRel_y1_Getter";

  static $y1_Setter(mthis, value) native "SVGPathSegCurvetoQuadraticRel_y1_Setter";
}

class BlinkSVGPathSegCurvetoQuadraticSmoothAbs {
  static $x_Getter(mthis) native "SVGPathSegCurvetoQuadraticSmoothAbs_x_Getter";

  static $x_Setter(mthis, value) native "SVGPathSegCurvetoQuadraticSmoothAbs_x_Setter";

  static $y_Getter(mthis) native "SVGPathSegCurvetoQuadraticSmoothAbs_y_Getter";

  static $y_Setter(mthis, value) native "SVGPathSegCurvetoQuadraticSmoothAbs_y_Setter";
}

class BlinkSVGPathSegCurvetoQuadraticSmoothRel {
  static $x_Getter(mthis) native "SVGPathSegCurvetoQuadraticSmoothRel_x_Getter";

  static $x_Setter(mthis, value) native "SVGPathSegCurvetoQuadraticSmoothRel_x_Setter";

  static $y_Getter(mthis) native "SVGPathSegCurvetoQuadraticSmoothRel_y_Getter";

  static $y_Setter(mthis, value) native "SVGPathSegCurvetoQuadraticSmoothRel_y_Setter";
}

class BlinkSVGPathSegLinetoAbs {
  static $x_Getter(mthis) native "SVGPathSegLinetoAbs_x_Getter";

  static $x_Setter(mthis, value) native "SVGPathSegLinetoAbs_x_Setter";

  static $y_Getter(mthis) native "SVGPathSegLinetoAbs_y_Getter";

  static $y_Setter(mthis, value) native "SVGPathSegLinetoAbs_y_Setter";
}

class BlinkSVGPathSegLinetoHorizontalAbs {
  static $x_Getter(mthis) native "SVGPathSegLinetoHorizontalAbs_x_Getter";

  static $x_Setter(mthis, value) native "SVGPathSegLinetoHorizontalAbs_x_Setter";
}

class BlinkSVGPathSegLinetoHorizontalRel {
  static $x_Getter(mthis) native "SVGPathSegLinetoHorizontalRel_x_Getter";

  static $x_Setter(mthis, value) native "SVGPathSegLinetoHorizontalRel_x_Setter";
}

class BlinkSVGPathSegLinetoRel {
  static $x_Getter(mthis) native "SVGPathSegLinetoRel_x_Getter";

  static $x_Setter(mthis, value) native "SVGPathSegLinetoRel_x_Setter";

  static $y_Getter(mthis) native "SVGPathSegLinetoRel_y_Getter";

  static $y_Setter(mthis, value) native "SVGPathSegLinetoRel_y_Setter";
}

class BlinkSVGPathSegLinetoVerticalAbs {
  static $y_Getter(mthis) native "SVGPathSegLinetoVerticalAbs_y_Getter";

  static $y_Setter(mthis, value) native "SVGPathSegLinetoVerticalAbs_y_Setter";
}

class BlinkSVGPathSegLinetoVerticalRel {
  static $y_Getter(mthis) native "SVGPathSegLinetoVerticalRel_y_Getter";

  static $y_Setter(mthis, value) native "SVGPathSegLinetoVerticalRel_y_Setter";
}

class BlinkSVGPathSegList {
  static $numberOfItems_Getter(mthis) native "SVGPathSegList_numberOfItems_Getter";

  static $appendItem_Callback(mthis, newItem) native "SVGPathSegList_appendItem_Callback_RESOLVER_STRING_1_SVGPathSeg";

  static $clear_Callback(mthis) native "SVGPathSegList_clear_Callback_RESOLVER_STRING_0_";

  static $getItem_Callback(mthis, index) native "SVGPathSegList_getItem_Callback_RESOLVER_STRING_1_unsigned long";

  static $initialize_Callback(mthis, newItem) native "SVGPathSegList_initialize_Callback_RESOLVER_STRING_1_SVGPathSeg";

  static $insertItemBefore_Callback(mthis, newItem, index) native "SVGPathSegList_insertItemBefore_Callback_RESOLVER_STRING_2_SVGPathSeg_unsigned long";

  static $removeItem_Callback(mthis, index) native "SVGPathSegList_removeItem_Callback_RESOLVER_STRING_1_unsigned long";

  static $replaceItem_Callback(mthis, newItem, index) native "SVGPathSegList_replaceItem_Callback_RESOLVER_STRING_2_SVGPathSeg_unsigned long";
}

class BlinkSVGPathSegMovetoAbs {
  static $x_Getter(mthis) native "SVGPathSegMovetoAbs_x_Getter";

  static $x_Setter(mthis, value) native "SVGPathSegMovetoAbs_x_Setter";

  static $y_Getter(mthis) native "SVGPathSegMovetoAbs_y_Getter";

  static $y_Setter(mthis, value) native "SVGPathSegMovetoAbs_y_Setter";
}

class BlinkSVGPathSegMovetoRel {
  static $x_Getter(mthis) native "SVGPathSegMovetoRel_x_Getter";

  static $x_Setter(mthis, value) native "SVGPathSegMovetoRel_x_Setter";

  static $y_Getter(mthis) native "SVGPathSegMovetoRel_y_Getter";

  static $y_Setter(mthis, value) native "SVGPathSegMovetoRel_y_Setter";
}

class BlinkSVGPatternElement {
  static $height_Getter(mthis) native "SVGPatternElement_height_Getter";

  static $patternContentUnits_Getter(mthis) native "SVGPatternElement_patternContentUnits_Getter";

  static $patternTransform_Getter(mthis) native "SVGPatternElement_patternTransform_Getter";

  static $patternUnits_Getter(mthis) native "SVGPatternElement_patternUnits_Getter";

  static $width_Getter(mthis) native "SVGPatternElement_width_Getter";

  static $x_Getter(mthis) native "SVGPatternElement_x_Getter";

  static $y_Getter(mthis) native "SVGPatternElement_y_Getter";

  static $preserveAspectRatio_Getter(mthis) native "SVGPatternElement_preserveAspectRatio_Getter";

  static $viewBox_Getter(mthis) native "SVGPatternElement_viewBox_Getter";

  static $requiredExtensions_Getter(mthis) native "SVGPatternElement_requiredExtensions_Getter";

  static $requiredFeatures_Getter(mthis) native "SVGPatternElement_requiredFeatures_Getter";

  static $systemLanguage_Getter(mthis) native "SVGPatternElement_systemLanguage_Getter";

  static $hasExtension_Callback(mthis, extension) native "SVGPatternElement_hasExtension_Callback_RESOLVER_STRING_1_DOMString";

  static $href_Getter(mthis) native "SVGPatternElement_href_Getter";
}

class BlinkSVGPoint {
  static $x_Getter(mthis) native "SVGPoint_x_Getter";

  static $x_Setter(mthis, value) native "SVGPoint_x_Setter";

  static $y_Getter(mthis) native "SVGPoint_y_Getter";

  static $y_Setter(mthis, value) native "SVGPoint_y_Setter";

  static $matrixTransform_Callback(mthis, matrix) native "SVGPoint_matrixTransform_Callback_RESOLVER_STRING_1_SVGMatrix";
}

class BlinkSVGPointList {
  static $numberOfItems_Getter(mthis) native "SVGPointList_numberOfItems_Getter";

  static $appendItem_Callback(mthis, item) native "SVGPointList_appendItem_Callback_RESOLVER_STRING_1_SVGPoint";

  static $clear_Callback(mthis) native "SVGPointList_clear_Callback_RESOLVER_STRING_0_";

  static $getItem_Callback(mthis, index) native "SVGPointList_getItem_Callback_RESOLVER_STRING_1_unsigned long";

  static $initialize_Callback(mthis, item) native "SVGPointList_initialize_Callback_RESOLVER_STRING_1_SVGPoint";

  static $insertItemBefore_Callback(mthis, item, index) native "SVGPointList_insertItemBefore_Callback_RESOLVER_STRING_2_SVGPoint_unsigned long";

  static $removeItem_Callback(mthis, index) native "SVGPointList_removeItem_Callback_RESOLVER_STRING_1_unsigned long";

  static $replaceItem_Callback(mthis, item, index) native "SVGPointList_replaceItem_Callback_RESOLVER_STRING_2_SVGPoint_unsigned long";
}

class BlinkSVGPolygonElement {
  static $animatedPoints_Getter(mthis) native "SVGPolygonElement_animatedPoints_Getter";

  static $points_Getter(mthis) native "SVGPolygonElement_points_Getter";
}

class BlinkSVGPolylineElement {
  static $animatedPoints_Getter(mthis) native "SVGPolylineElement_animatedPoints_Getter";

  static $points_Getter(mthis) native "SVGPolylineElement_points_Getter";
}

class BlinkSVGPreserveAspectRatio {
  static $align_Getter(mthis) native "SVGPreserveAspectRatio_align_Getter";

  static $align_Setter(mthis, value) native "SVGPreserveAspectRatio_align_Setter";

  static $meetOrSlice_Getter(mthis) native "SVGPreserveAspectRatio_meetOrSlice_Getter";

  static $meetOrSlice_Setter(mthis, value) native "SVGPreserveAspectRatio_meetOrSlice_Setter";
}

class BlinkSVGRadialGradientElement {
  static $cx_Getter(mthis) native "SVGRadialGradientElement_cx_Getter";

  static $cy_Getter(mthis) native "SVGRadialGradientElement_cy_Getter";

  static $fr_Getter(mthis) native "SVGRadialGradientElement_fr_Getter";

  static $fx_Getter(mthis) native "SVGRadialGradientElement_fx_Getter";

  static $fy_Getter(mthis) native "SVGRadialGradientElement_fy_Getter";

  static $r_Getter(mthis) native "SVGRadialGradientElement_r_Getter";
}

class BlinkSVGRect {
  static $height_Getter(mthis) native "SVGRect_height_Getter";

  static $height_Setter(mthis, value) native "SVGRect_height_Setter";

  static $width_Getter(mthis) native "SVGRect_width_Getter";

  static $width_Setter(mthis, value) native "SVGRect_width_Setter";

  static $x_Getter(mthis) native "SVGRect_x_Getter";

  static $x_Setter(mthis, value) native "SVGRect_x_Setter";

  static $y_Getter(mthis) native "SVGRect_y_Getter";

  static $y_Setter(mthis, value) native "SVGRect_y_Setter";
}

class BlinkSVGRectElement {
  static $height_Getter(mthis) native "SVGRectElement_height_Getter";

  static $rx_Getter(mthis) native "SVGRectElement_rx_Getter";

  static $ry_Getter(mthis) native "SVGRectElement_ry_Getter";

  static $width_Getter(mthis) native "SVGRectElement_width_Getter";

  static $x_Getter(mthis) native "SVGRectElement_x_Getter";

  static $y_Getter(mthis) native "SVGRectElement_y_Getter";
}

class BlinkSVGRenderingIntent {}

class BlinkSVGZoomAndPan {
  static $zoomAndPan_Getter(mthis) native "SVGZoomAndPan_zoomAndPan_Getter";

  static $zoomAndPan_Setter(mthis, value) native "SVGZoomAndPan_zoomAndPan_Setter";
}

class BlinkSVGSVGElement {
  static $currentScale_Getter(mthis) native "SVGSVGElement_currentScale_Getter";

  static $currentScale_Setter(mthis, value) native "SVGSVGElement_currentScale_Setter";

  static $currentTranslate_Getter(mthis) native "SVGSVGElement_currentTranslate_Getter";

  static $currentView_Getter(mthis) native "SVGSVGElement_currentView_Getter";

  static $height_Getter(mthis) native "SVGSVGElement_height_Getter";

  static $pixelUnitToMillimeterX_Getter(mthis) native "SVGSVGElement_pixelUnitToMillimeterX_Getter";

  static $pixelUnitToMillimeterY_Getter(mthis) native "SVGSVGElement_pixelUnitToMillimeterY_Getter";

  static $screenPixelToMillimeterX_Getter(mthis) native "SVGSVGElement_screenPixelToMillimeterX_Getter";

  static $screenPixelToMillimeterY_Getter(mthis) native "SVGSVGElement_screenPixelToMillimeterY_Getter";

  static $useCurrentView_Getter(mthis) native "SVGSVGElement_useCurrentView_Getter";

  static $viewport_Getter(mthis) native "SVGSVGElement_viewport_Getter";

  static $width_Getter(mthis) native "SVGSVGElement_width_Getter";

  static $x_Getter(mthis) native "SVGSVGElement_x_Getter";

  static $y_Getter(mthis) native "SVGSVGElement_y_Getter";

  static $animationsPaused_Callback(mthis) native "SVGSVGElement_animationsPaused_Callback_RESOLVER_STRING_0_";

  static $checkEnclosure_Callback(mthis, element, rect) native "SVGSVGElement_checkEnclosure_Callback_RESOLVER_STRING_2_SVGElement_SVGRect";

  static $checkIntersection_Callback(mthis, element, rect) native "SVGSVGElement_checkIntersection_Callback_RESOLVER_STRING_2_SVGElement_SVGRect";

  static $createSVGAngle_Callback(mthis) native "SVGSVGElement_createSVGAngle_Callback_RESOLVER_STRING_0_";

  static $createSVGLength_Callback(mthis) native "SVGSVGElement_createSVGLength_Callback_RESOLVER_STRING_0_";

  static $createSVGMatrix_Callback(mthis) native "SVGSVGElement_createSVGMatrix_Callback_RESOLVER_STRING_0_";

  static $createSVGNumber_Callback(mthis) native "SVGSVGElement_createSVGNumber_Callback_RESOLVER_STRING_0_";

  static $createSVGPoint_Callback(mthis) native "SVGSVGElement_createSVGPoint_Callback_RESOLVER_STRING_0_";

  static $createSVGRect_Callback(mthis) native "SVGSVGElement_createSVGRect_Callback_RESOLVER_STRING_0_";

  static $createSVGTransform_Callback(mthis) native "SVGSVGElement_createSVGTransform_Callback_RESOLVER_STRING_0_";

  static $createSVGTransformFromMatrix_Callback(mthis, matrix) native "SVGSVGElement_createSVGTransformFromMatrix_Callback_RESOLVER_STRING_1_SVGMatrix";

  static $deselectAll_Callback(mthis) native "SVGSVGElement_deselectAll_Callback_RESOLVER_STRING_0_";

  static $forceRedraw_Callback(mthis) native "SVGSVGElement_forceRedraw_Callback_RESOLVER_STRING_0_";

  static $getCurrentTime_Callback(mthis) native "SVGSVGElement_getCurrentTime_Callback_RESOLVER_STRING_0_";

  static $getElementById_Callback(mthis, elementId) native "SVGSVGElement_getElementById_Callback_RESOLVER_STRING_1_DOMString";

  static $getEnclosureList_Callback(mthis, rect, referenceElement) native "SVGSVGElement_getEnclosureList_Callback_RESOLVER_STRING_2_SVGRect_SVGElement";

  static $getIntersectionList_Callback(mthis, rect, referenceElement) native "SVGSVGElement_getIntersectionList_Callback_RESOLVER_STRING_2_SVGRect_SVGElement";

  static $pauseAnimations_Callback(mthis) native "SVGSVGElement_pauseAnimations_Callback_RESOLVER_STRING_0_";

  static $setCurrentTime_Callback(mthis, seconds) native "SVGSVGElement_setCurrentTime_Callback_RESOLVER_STRING_1_float";

  static $suspendRedraw_Callback(mthis, maxWaitMilliseconds) native "SVGSVGElement_suspendRedraw_Callback_RESOLVER_STRING_1_unsigned long";

  static $unpauseAnimations_Callback(mthis) native "SVGSVGElement_unpauseAnimations_Callback_RESOLVER_STRING_0_";

  static $unsuspendRedraw_Callback(mthis, suspendHandleId) native "SVGSVGElement_unsuspendRedraw_Callback_RESOLVER_STRING_1_unsigned long";

  static $unsuspendRedrawAll_Callback(mthis) native "SVGSVGElement_unsuspendRedrawAll_Callback_RESOLVER_STRING_0_";

  static $preserveAspectRatio_Getter(mthis) native "SVGSVGElement_preserveAspectRatio_Getter";

  static $viewBox_Getter(mthis) native "SVGSVGElement_viewBox_Getter";

  static $zoomAndPan_Getter(mthis) native "SVGSVGElement_zoomAndPan_Getter";

  static $zoomAndPan_Setter(mthis, value) native "SVGSVGElement_zoomAndPan_Setter";
}

class BlinkSVGScriptElement {
  static $type_Getter(mthis) native "SVGScriptElement_type_Getter";

  static $type_Setter(mthis, value) native "SVGScriptElement_type_Setter";

  static $href_Getter(mthis) native "SVGScriptElement_href_Getter";
}

class BlinkSVGSetElement {}

class BlinkSVGStopElement {
  static $offset_Getter(mthis) native "SVGStopElement_offset_Getter";
}

class BlinkSVGStringList {
  static $numberOfItems_Getter(mthis) native "SVGStringList_numberOfItems_Getter";

  static $appendItem_Callback(mthis, item) native "SVGStringList_appendItem_Callback_RESOLVER_STRING_1_DOMString";

  static $clear_Callback(mthis) native "SVGStringList_clear_Callback_RESOLVER_STRING_0_";

  static $getItem_Callback(mthis, index) native "SVGStringList_getItem_Callback_RESOLVER_STRING_1_unsigned long";

  static $initialize_Callback(mthis, item) native "SVGStringList_initialize_Callback_RESOLVER_STRING_1_DOMString";

  static $insertItemBefore_Callback(mthis, item, index) native "SVGStringList_insertItemBefore_Callback_RESOLVER_STRING_2_DOMString_unsigned long";

  static $removeItem_Callback(mthis, index) native "SVGStringList_removeItem_Callback_RESOLVER_STRING_1_unsigned long";

  static $replaceItem_Callback(mthis, item, index) native "SVGStringList_replaceItem_Callback_RESOLVER_STRING_2_DOMString_unsigned long";
}

class BlinkSVGStyleElement {
  static $disabled_Getter(mthis) native "SVGStyleElement_disabled_Getter";

  static $disabled_Setter(mthis, value) native "SVGStyleElement_disabled_Setter";

  static $media_Getter(mthis) native "SVGStyleElement_media_Getter";

  static $media_Setter(mthis, value) native "SVGStyleElement_media_Setter";

  static $title_Getter(mthis) native "SVGStyleElement_title_Getter";

  static $title_Setter(mthis, value) native "SVGStyleElement_title_Setter";

  static $type_Getter(mthis) native "SVGStyleElement_type_Getter";

  static $type_Setter(mthis, value) native "SVGStyleElement_type_Setter";
}

class BlinkSVGSwitchElement {}

class BlinkSVGSymbolElement {
  static $preserveAspectRatio_Getter(mthis) native "SVGSymbolElement_preserveAspectRatio_Getter";

  static $viewBox_Getter(mthis) native "SVGSymbolElement_viewBox_Getter";
}

class BlinkSVGTSpanElement {}

class BlinkSVGTextElement {}

class BlinkSVGTextPathElement {
  static $method_Getter(mthis) native "SVGTextPathElement_method_Getter";

  static $spacing_Getter(mthis) native "SVGTextPathElement_spacing_Getter";

  static $startOffset_Getter(mthis) native "SVGTextPathElement_startOffset_Getter";

  static $href_Getter(mthis) native "SVGTextPathElement_href_Getter";
}

class BlinkSVGTitleElement {}

class BlinkSVGTransform {
  static $angle_Getter(mthis) native "SVGTransform_angle_Getter";

  static $matrix_Getter(mthis) native "SVGTransform_matrix_Getter";

  static $type_Getter(mthis) native "SVGTransform_type_Getter";

  static $setMatrix_Callback(mthis, matrix) native "SVGTransform_setMatrix_Callback_RESOLVER_STRING_1_SVGMatrix";

  static $setRotate_Callback(mthis, angle, cx, cy) native "SVGTransform_setRotate_Callback_RESOLVER_STRING_3_float_float_float";

  static $setScale_Callback(mthis, sx, sy) native "SVGTransform_setScale_Callback_RESOLVER_STRING_2_float_float";

  static $setSkewX_Callback(mthis, angle) native "SVGTransform_setSkewX_Callback_RESOLVER_STRING_1_float";

  static $setSkewY_Callback(mthis, angle) native "SVGTransform_setSkewY_Callback_RESOLVER_STRING_1_float";

  static $setTranslate_Callback(mthis, tx, ty) native "SVGTransform_setTranslate_Callback_RESOLVER_STRING_2_float_float";
}

class BlinkSVGTransformList {
  static $numberOfItems_Getter(mthis) native "SVGTransformList_numberOfItems_Getter";

  static $appendItem_Callback(mthis, item) native "SVGTransformList_appendItem_Callback_RESOLVER_STRING_1_SVGTransform";

  static $clear_Callback(mthis) native "SVGTransformList_clear_Callback_RESOLVER_STRING_0_";

  static $consolidate_Callback(mthis) native "SVGTransformList_consolidate_Callback_RESOLVER_STRING_0_";

  static $createSVGTransformFromMatrix_Callback(mthis, matrix) native "SVGTransformList_createSVGTransformFromMatrix_Callback_RESOLVER_STRING_1_SVGMatrix";

  static $getItem_Callback(mthis, index) native "SVGTransformList_getItem_Callback_RESOLVER_STRING_1_unsigned long";

  static $initialize_Callback(mthis, item) native "SVGTransformList_initialize_Callback_RESOLVER_STRING_1_SVGTransform";

  static $insertItemBefore_Callback(mthis, item, index) native "SVGTransformList_insertItemBefore_Callback_RESOLVER_STRING_2_SVGTransform_unsigned long";

  static $removeItem_Callback(mthis, index) native "SVGTransformList_removeItem_Callback_RESOLVER_STRING_1_unsigned long";

  static $replaceItem_Callback(mthis, item, index) native "SVGTransformList_replaceItem_Callback_RESOLVER_STRING_2_SVGTransform_unsigned long";
}

class BlinkSVGUnitTypes {}

class BlinkSVGUseElement {
  static $animatedInstanceRoot_Getter(mthis) native "SVGUseElement_animatedInstanceRoot_Getter";

  static $height_Getter(mthis) native "SVGUseElement_height_Getter";

  static $instanceRoot_Getter(mthis) native "SVGUseElement_instanceRoot_Getter";

  static $width_Getter(mthis) native "SVGUseElement_width_Getter";

  static $x_Getter(mthis) native "SVGUseElement_x_Getter";

  static $y_Getter(mthis) native "SVGUseElement_y_Getter";

  static $requiredExtensions_Getter(mthis) native "SVGGraphicsElement_requiredExtensions_Getter";

  static $requiredFeatures_Getter(mthis) native "SVGGraphicsElement_requiredFeatures_Getter";

  static $systemLanguage_Getter(mthis) native "SVGGraphicsElement_systemLanguage_Getter";

  static $hasExtension_Callback(mthis, extension) native "SVGGraphicsElement_hasExtension_Callback_RESOLVER_STRING_1_DOMString";

  static $href_Getter(mthis) native "SVGUseElement_href_Getter";
}

class BlinkSVGVKernElement {}

class BlinkSVGViewElement {
  static $viewTarget_Getter(mthis) native "SVGViewElement_viewTarget_Getter";

  static $preserveAspectRatio_Getter(mthis) native "SVGViewElement_preserveAspectRatio_Getter";

  static $viewBox_Getter(mthis) native "SVGViewElement_viewBox_Getter";

  static $zoomAndPan_Getter(mthis) native "SVGViewElement_zoomAndPan_Getter";

  static $zoomAndPan_Setter(mthis, value) native "SVGViewElement_zoomAndPan_Setter";
}

class BlinkSVGViewSpec {
  static $preserveAspectRatioString_Getter(mthis) native "SVGViewSpec_preserveAspectRatioString_Getter";

  static $transform_Getter(mthis) native "SVGViewSpec_transform_Getter";

  static $transformString_Getter(mthis) native "SVGViewSpec_transformString_Getter";

  static $viewBoxString_Getter(mthis) native "SVGViewSpec_viewBoxString_Getter";

  static $viewTarget_Getter(mthis) native "SVGViewSpec_viewTarget_Getter";

  static $viewTargetString_Getter(mthis) native "SVGViewSpec_viewTargetString_Getter";

  static $preserveAspectRatio_Getter(mthis) native "SVGViewSpec_preserveAspectRatio_Getter";

  static $viewBox_Getter(mthis) native "SVGViewSpec_viewBox_Getter";

  static $zoomAndPan_Getter(mthis) native "SVGViewSpec_zoomAndPan_Getter";

  static $zoomAndPan_Setter(mthis, value) native "SVGViewSpec_zoomAndPan_Setter";
}

class BlinkSVGZoomEvent {
  static $newScale_Getter(mthis) native "SVGZoomEvent_newScale_Getter";

  static $newTranslate_Getter(mthis) native "SVGZoomEvent_newTranslate_Getter";

  static $previousScale_Getter(mthis) native "SVGZoomEvent_previousScale_Getter";

  static $previousTranslate_Getter(mthis) native "SVGZoomEvent_previousTranslate_Getter";

  static $zoomRectScreen_Getter(mthis) native "SVGZoomEvent_zoomRectScreen_Getter";
}

class BlinkScreen {
  static $availHeight_Getter(mthis) native "Screen_availHeight_Getter";

  static $availLeft_Getter(mthis) native "Screen_availLeft_Getter";

  static $availTop_Getter(mthis) native "Screen_availTop_Getter";

  static $availWidth_Getter(mthis) native "Screen_availWidth_Getter";

  static $colorDepth_Getter(mthis) native "Screen_colorDepth_Getter";

  static $height_Getter(mthis) native "Screen_height_Getter";

  static $orientation_Getter(mthis) native "Screen_orientation_Getter";

  static $pixelDepth_Getter(mthis) native "Screen_pixelDepth_Getter";

  static $width_Getter(mthis) native "Screen_width_Getter";

  static $lockOrientation_Callback(mthis, orientation) native "Screen_lockOrientation_Callback_RESOLVER_STRING_1_DOMString";

  static $unlockOrientation_Callback(mthis) native "Screen_unlockOrientation_Callback_RESOLVER_STRING_0_";
}

class BlinkScriptProcessorNode {
  static $bufferSize_Getter(mthis) native "ScriptProcessorNode_bufferSize_Getter";

  static $_setEventListener_Callback(mthis, eventListener) native "ScriptProcessorNode_setEventListener_Callback";
}

class BlinkSecurityPolicyViolationEvent {
  static $blockedURI_Getter(mthis) native "SecurityPolicyViolationEvent_blockedURI_Getter";

  static $columnNumber_Getter(mthis) native "SecurityPolicyViolationEvent_columnNumber_Getter";

  static $documentURI_Getter(mthis) native "SecurityPolicyViolationEvent_documentURI_Getter";

  static $effectiveDirective_Getter(mthis) native "SecurityPolicyViolationEvent_effectiveDirective_Getter";

  static $lineNumber_Getter(mthis) native "SecurityPolicyViolationEvent_lineNumber_Getter";

  static $originalPolicy_Getter(mthis) native "SecurityPolicyViolationEvent_originalPolicy_Getter";

  static $referrer_Getter(mthis) native "SecurityPolicyViolationEvent_referrer_Getter";

  static $sourceFile_Getter(mthis) native "SecurityPolicyViolationEvent_sourceFile_Getter";

  static $statusCode_Getter(mthis) native "SecurityPolicyViolationEvent_statusCode_Getter";

  static $violatedDirective_Getter(mthis) native "SecurityPolicyViolationEvent_violatedDirective_Getter";
}

class BlinkSelection {
  static $anchorNode_Getter(mthis) native "Selection_anchorNode_Getter";

  static $anchorOffset_Getter(mthis) native "Selection_anchorOffset_Getter";

  static $baseNode_Getter(mthis) native "Selection_baseNode_Getter";

  static $baseOffset_Getter(mthis) native "Selection_baseOffset_Getter";

  static $extentNode_Getter(mthis) native "Selection_extentNode_Getter";

  static $extentOffset_Getter(mthis) native "Selection_extentOffset_Getter";

  static $focusNode_Getter(mthis) native "Selection_focusNode_Getter";

  static $focusOffset_Getter(mthis) native "Selection_focusOffset_Getter";

  static $isCollapsed_Getter(mthis) native "Selection_isCollapsed_Getter";

  static $rangeCount_Getter(mthis) native "Selection_rangeCount_Getter";

  static $type_Getter(mthis) native "Selection_type_Getter";

  static $addRange_Callback(mthis, range) native "Selection_addRange_Callback_RESOLVER_STRING_1_Range";

  static $collapse_Callback(mthis, node, index) native "Selection_collapse_Callback_RESOLVER_STRING_2_Node_long";

  static $collapseToEnd_Callback(mthis) native "Selection_collapseToEnd_Callback_RESOLVER_STRING_0_";

  static $collapseToStart_Callback(mthis) native "Selection_collapseToStart_Callback_RESOLVER_STRING_0_";

  static $containsNode_Callback(mthis, node, allowPartial) native "Selection_containsNode_Callback_RESOLVER_STRING_2_Node_boolean";

  static $deleteFromDocument_Callback(mthis) native "Selection_deleteFromDocument_Callback_RESOLVER_STRING_0_";

  static $empty_Callback(mthis) native "Selection_empty_Callback_RESOLVER_STRING_0_";

  static $extend_Callback(mthis, node, offset) native "Selection_extend_Callback_RESOLVER_STRING_2_Node_long";

  static $getRangeAt_Callback(mthis, index) native "Selection_getRangeAt_Callback_RESOLVER_STRING_1_long";

  static $modify_Callback(mthis, alter, direction, granularity) native "Selection_modify_Callback_RESOLVER_STRING_3_DOMString_DOMString_DOMString";

  static $removeAllRanges_Callback(mthis) native "Selection_removeAllRanges_Callback_RESOLVER_STRING_0_";

  static $selectAllChildren_Callback(mthis, node) native "Selection_selectAllChildren_Callback_RESOLVER_STRING_1_Node";

  static $setBaseAndExtent_Callback(mthis, baseNode, baseOffset, extentNode, extentOffset) native "Selection_setBaseAndExtent_Callback_RESOLVER_STRING_4_Node_long_Node_long";

  static $setPosition_Callback(mthis, node, offset) native "Selection_setPosition_Callback_RESOLVER_STRING_2_Node_long";

  static $toString_Callback(mthis) native "Selection_toString_Callback_RESOLVER_STRING_0_";
}

class BlinkServiceWorker {}

class BlinkServiceWorkerContainer {}

class BlinkServiceWorkerGlobalScope {}

class BlinkShadowRoot {
  static $activeElement_Getter(mthis) native "ShadowRoot_activeElement_Getter";

  static $host_Getter(mthis) native "ShadowRoot_host_Getter";

  static $innerHTML_Getter(mthis) native "ShadowRoot_innerHTML_Getter";

  static $innerHTML_Setter(mthis, value) native "ShadowRoot_innerHTML_Setter";

  static $olderShadowRoot_Getter(mthis) native "ShadowRoot_olderShadowRoot_Getter";

  static $resetStyleInheritance_Getter(mthis) native "ShadowRoot_resetStyleInheritance_Getter";

  static $resetStyleInheritance_Setter(mthis, value) native "ShadowRoot_resetStyleInheritance_Setter";

  static $styleSheets_Getter(mthis) native "ShadowRoot_styleSheets_Getter";

  static $cloneNode_Callback(mthis, deep) native "ShadowRoot_cloneNode_Callback_RESOLVER_STRING_1_boolean";

  static $elementFromPoint_Callback(mthis, x, y) native "ShadowRoot_elementFromPoint_Callback_RESOLVER_STRING_2_long_long";

  static $getElementById_Callback(mthis, elementId) native "ShadowRoot_getElementById_Callback_RESOLVER_STRING_1_DOMString";

  static $getElementsByClassName_Callback(mthis, className) native "ShadowRoot_getElementsByClassName_Callback_RESOLVER_STRING_1_DOMString";

  static $getElementsByTagName_Callback(mthis, tagName) native "ShadowRoot_getElementsByTagName_Callback_RESOLVER_STRING_1_DOMString";

  static $getSelection_Callback(mthis) native "ShadowRoot_getSelection_Callback_RESOLVER_STRING_0_";
}

class BlinkSharedWorker {
  // Generated overload resolver
  static $mkSharedWorker(scriptURL, name) {
    return $_create_1constructorCallback(scriptURL, name);
  }

  static $_create_1constructorCallback(scriptURL, name) native "SharedWorker_constructorCallback_RESOLVER_STRING_2_DOMString_DOMString";

  static $port_Getter(mthis) native "SharedWorker_port_Getter";

  static $workerStart_Getter(mthis) native "SharedWorker_workerStart_Getter";
}

class BlinkSharedWorkerGlobalScope {
  static $name_Getter(mthis) native "SharedWorkerGlobalScope_name_Getter";
}

class BlinkSourceBuffer {
  static $appendWindowEnd_Getter(mthis) native "SourceBuffer_appendWindowEnd_Getter";

  static $appendWindowEnd_Setter(mthis, value) native "SourceBuffer_appendWindowEnd_Setter";

  static $appendWindowStart_Getter(mthis) native "SourceBuffer_appendWindowStart_Getter";

  static $appendWindowStart_Setter(mthis, value) native "SourceBuffer_appendWindowStart_Setter";

  static $buffered_Getter(mthis) native "SourceBuffer_buffered_Getter";

  static $mode_Getter(mthis) native "SourceBuffer_mode_Getter";

  static $mode_Setter(mthis, value) native "SourceBuffer_mode_Setter";

  static $timestampOffset_Getter(mthis) native "SourceBuffer_timestampOffset_Getter";

  static $timestampOffset_Setter(mthis, value) native "SourceBuffer_timestampOffset_Setter";

  static $updating_Getter(mthis) native "SourceBuffer_updating_Getter";

  static $abort_Callback(mthis) native "SourceBuffer_abort_Callback_RESOLVER_STRING_0_";

  static $appendBuffer_Callback(mthis, data) native "SourceBuffer_appendBuffer_Callback_RESOLVER_STRING_1_ArrayBuffer";

  // Generated overload resolver
  static $appendStream(mthis, stream, maxSize) {
    if (maxSize != null) {
      $_appendStream_1_Callback(mthis, stream, maxSize);
      return;
    }
    $_appendStream_2_Callback(mthis, stream);
    return;
  }

  static $_appendStream_1_Callback(mthis, stream, maxSize) native "SourceBuffer_appendStream_Callback_RESOLVER_STRING_2_Stream_unsigned long long";

  static $_appendStream_2_Callback(mthis, stream) native "SourceBuffer_appendStream_Callback_RESOLVER_STRING_1_Stream";

  static $appendTypedData_Callback(mthis, data) native "SourceBuffer_appendBuffer_Callback_RESOLVER_STRING_1_ArrayBufferView";

  static $remove_Callback(mthis, start, end) native "SourceBuffer_remove_Callback_RESOLVER_STRING_2_double_double";
}

class BlinkSourceBufferList {
  static $length_Getter(mthis) native "SourceBufferList_length_Getter";

  static $NativeIndexed_Getter(mthis, index) native "SourceBufferList_item_Callback_RESOLVER_STRING_1_unsigned long";

  static $item_Callback(mthis, index) native "SourceBufferList_item_Callback_RESOLVER_STRING_1_unsigned long";
}

class BlinkSourceInfo {
  static $facing_Getter(mthis) native "SourceInfo_facing_Getter";

  static $id_Getter(mthis) native "SourceInfo_id_Getter";

  static $kind_Getter(mthis) native "SourceInfo_kind_Getter";

  static $label_Getter(mthis) native "SourceInfo_label_Getter";
}

class BlinkSpeechGrammar {
  // Generated overload resolver
  static $mkSpeechGrammar() {
    return $_create_1constructorCallback();
  }

  static $_create_1constructorCallback() native "SpeechGrammar_constructorCallback_RESOLVER_STRING_0_";

  static $src_Getter(mthis) native "SpeechGrammar_src_Getter";

  static $src_Setter(mthis, value) native "SpeechGrammar_src_Setter";

  static $weight_Getter(mthis) native "SpeechGrammar_weight_Getter";

  static $weight_Setter(mthis, value) native "SpeechGrammar_weight_Setter";
}

class BlinkSpeechGrammarList {
  // Generated overload resolver
  static $mkSpeechGrammarList() {
    return $_create_1constructorCallback();
  }

  static $_create_1constructorCallback() native "SpeechGrammarList_constructorCallback_RESOLVER_STRING_0_";

  static $length_Getter(mthis) native "SpeechGrammarList_length_Getter";

  static $NativeIndexed_Getter(mthis, index) native "SpeechGrammarList_item_Callback_RESOLVER_STRING_1_unsigned long";

  // Generated overload resolver
  static $addFromString(mthis, string, weight) {
    if (weight != null) {
      $_addFromString_1_Callback(mthis, string, weight);
      return;
    }
    $_addFromString_2_Callback(mthis, string);
    return;
  }

  static $_addFromString_1_Callback(mthis, string, weight) native "SpeechGrammarList_addFromString_Callback_RESOLVER_STRING_2_DOMString_float";

  static $_addFromString_2_Callback(mthis, string) native "SpeechGrammarList_addFromString_Callback_RESOLVER_STRING_1_DOMString";

  // Generated overload resolver
  static $addFromUri(mthis, src, weight) {
    if (weight != null) {
      $_addFromUri_1_Callback(mthis, src, weight);
      return;
    }
    $_addFromUri_2_Callback(mthis, src);
    return;
  }

  static $_addFromUri_1_Callback(mthis, src, weight) native "SpeechGrammarList_addFromUri_Callback_RESOLVER_STRING_2_DOMString_float";

  static $_addFromUri_2_Callback(mthis, src) native "SpeechGrammarList_addFromUri_Callback_RESOLVER_STRING_1_DOMString";

  static $item_Callback(mthis, index) native "SpeechGrammarList_item_Callback_RESOLVER_STRING_1_unsigned long";
}

class BlinkSpeechInputEvent {}

class BlinkSpeechInputResult {}

class BlinkSpeechInputResultList {
  static $length_Getter(mthis) native "SpeechInputResultList_length_Getter";

  static $NativeIndexed_Getter(mthis, index) native "SpeechInputResultList_item_Callback_RESOLVER_STRING_1_unsigned long";

  static $item_Callback(mthis, index) native "SpeechInputResultList_item_Callback_RESOLVER_STRING_1_unsigned long";
}

class BlinkSpeechRecognition {
  // Generated overload resolver
  static $mkSpeechRecognition() {
    return $_create_1constructorCallback();
  }

  static $_create_1constructorCallback() native "SpeechRecognition_constructorCallback_RESOLVER_STRING_0_";

  static $continuous_Getter(mthis) native "SpeechRecognition_continuous_Getter";

  static $continuous_Setter(mthis, value) native "SpeechRecognition_continuous_Setter";

  static $grammars_Getter(mthis) native "SpeechRecognition_grammars_Getter";

  static $grammars_Setter(mthis, value) native "SpeechRecognition_grammars_Setter";

  static $interimResults_Getter(mthis) native "SpeechRecognition_interimResults_Getter";

  static $interimResults_Setter(mthis, value) native "SpeechRecognition_interimResults_Setter";

  static $lang_Getter(mthis) native "SpeechRecognition_lang_Getter";

  static $lang_Setter(mthis, value) native "SpeechRecognition_lang_Setter";

  static $maxAlternatives_Getter(mthis) native "SpeechRecognition_maxAlternatives_Getter";

  static $maxAlternatives_Setter(mthis, value) native "SpeechRecognition_maxAlternatives_Setter";

  static $abort_Callback(mthis) native "SpeechRecognition_abort_Callback_RESOLVER_STRING_0_";

  static $start_Callback(mthis) native "SpeechRecognition_start_Callback_RESOLVER_STRING_0_";

  static $stop_Callback(mthis) native "SpeechRecognition_stop_Callback_RESOLVER_STRING_0_";
}

class BlinkSpeechRecognitionAlternative {
  static $confidence_Getter(mthis) native "SpeechRecognitionAlternative_confidence_Getter";

  static $transcript_Getter(mthis) native "SpeechRecognitionAlternative_transcript_Getter";
}

class BlinkSpeechRecognitionError {
  static $error_Getter(mthis) native "SpeechRecognitionError_error_Getter";

  static $message_Getter(mthis) native "SpeechRecognitionError_message_Getter";
}

class BlinkSpeechRecognitionEvent {
  static $emma_Getter(mthis) native "SpeechRecognitionEvent_emma_Getter";

  static $interpretation_Getter(mthis) native "SpeechRecognitionEvent_interpretation_Getter";

  static $resultIndex_Getter(mthis) native "SpeechRecognitionEvent_resultIndex_Getter";

  static $results_Getter(mthis) native "SpeechRecognitionEvent_results_Getter";
}

class BlinkSpeechRecognitionResult {
  static $isFinal_Getter(mthis) native "SpeechRecognitionResult_isFinal_Getter";

  static $length_Getter(mthis) native "SpeechRecognitionResult_length_Getter";

  static $item_Callback(mthis, index) native "SpeechRecognitionResult_item_Callback_RESOLVER_STRING_1_unsigned long";
}

class BlinkSpeechRecognitionResultList {
  static $length_Getter(mthis) native "SpeechRecognitionResultList_length_Getter";

  static $NativeIndexed_Getter(mthis, index) native "SpeechRecognitionResultList_item_Callback_RESOLVER_STRING_1_unsigned long";

  static $item_Callback(mthis, index) native "SpeechRecognitionResultList_item_Callback_RESOLVER_STRING_1_unsigned long";
}

class BlinkSpeechSynthesis {
  static $paused_Getter(mthis) native "SpeechSynthesis_paused_Getter";

  static $pending_Getter(mthis) native "SpeechSynthesis_pending_Getter";

  static $speaking_Getter(mthis) native "SpeechSynthesis_speaking_Getter";

  static $cancel_Callback(mthis) native "SpeechSynthesis_cancel_Callback_RESOLVER_STRING_0_";

  static $getVoices_Callback(mthis) native "SpeechSynthesis_getVoices_Callback_RESOLVER_STRING_0_";

  static $pause_Callback(mthis) native "SpeechSynthesis_pause_Callback_RESOLVER_STRING_0_";

  static $resume_Callback(mthis) native "SpeechSynthesis_resume_Callback_RESOLVER_STRING_0_";

  static $speak_Callback(mthis, utterance) native "SpeechSynthesis_speak_Callback_RESOLVER_STRING_1_SpeechSynthesisUtterance";
}

class BlinkSpeechSynthesisEvent {
  static $charIndex_Getter(mthis) native "SpeechSynthesisEvent_charIndex_Getter";

  static $elapsedTime_Getter(mthis) native "SpeechSynthesisEvent_elapsedTime_Getter";

  static $name_Getter(mthis) native "SpeechSynthesisEvent_name_Getter";
}

class BlinkSpeechSynthesisUtterance {
  // Generated overload resolver
  static $mkSpeechSynthesisUtterance(text) {
    return $_create_1constructorCallback(text);
  }

  static $_create_1constructorCallback(text) native "SpeechSynthesisUtterance_constructorCallback_RESOLVER_STRING_1_DOMString";

  static $lang_Getter(mthis) native "SpeechSynthesisUtterance_lang_Getter";

  static $lang_Setter(mthis, value) native "SpeechSynthesisUtterance_lang_Setter";

  static $pitch_Getter(mthis) native "SpeechSynthesisUtterance_pitch_Getter";

  static $pitch_Setter(mthis, value) native "SpeechSynthesisUtterance_pitch_Setter";

  static $rate_Getter(mthis) native "SpeechSynthesisUtterance_rate_Getter";

  static $rate_Setter(mthis, value) native "SpeechSynthesisUtterance_rate_Setter";

  static $text_Getter(mthis) native "SpeechSynthesisUtterance_text_Getter";

  static $text_Setter(mthis, value) native "SpeechSynthesisUtterance_text_Setter";

  static $voice_Getter(mthis) native "SpeechSynthesisUtterance_voice_Getter";

  static $voice_Setter(mthis, value) native "SpeechSynthesisUtterance_voice_Setter";

  static $volume_Getter(mthis) native "SpeechSynthesisUtterance_volume_Getter";

  static $volume_Setter(mthis, value) native "SpeechSynthesisUtterance_volume_Setter";
}

class BlinkSpeechSynthesisVoice {
  static $default_Getter(mthis) native "SpeechSynthesisVoice_default_Getter";

  static $lang_Getter(mthis) native "SpeechSynthesisVoice_lang_Getter";

  static $localService_Getter(mthis) native "SpeechSynthesisVoice_localService_Getter";

  static $name_Getter(mthis) native "SpeechSynthesisVoice_name_Getter";

  static $voiceURI_Getter(mthis) native "SpeechSynthesisVoice_voiceURI_Getter";
}

class BlinkStorage {
  static $length_Getter(mthis) native "Storage_length_Getter";

  // Generated overload resolver
  static $__delete__(mthis, index_OR_name) {
    if ((index_OR_name is int || index_OR_name == null)) {
      return $___delete___1_Callback(mthis, index_OR_name);
    }
    if ((index_OR_name is String || index_OR_name == null)) {
      return $___delete___2_Callback(mthis, index_OR_name);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  static $___delete___1_Callback(mthis, index_OR_name) native "Storage___delete___Callback_RESOLVER_STRING_1_unsigned long";

  static $___delete___2_Callback(mthis, index_OR_name) native "Storage___delete___Callback_RESOLVER_STRING_1_DOMString";

  // Generated overload resolver
  static $__getter__(mthis, index_OR_name) {
    if ((index_OR_name is int || index_OR_name == null)) {
      return $___getter___1_Callback(mthis, index_OR_name);
    }
    if ((index_OR_name is String || index_OR_name == null)) {
      return $___getter___2_Callback(mthis, index_OR_name);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  static $___getter___1_Callback(mthis, index_OR_name) native "Storage___getter___Callback_RESOLVER_STRING_1_unsigned long";

  static $___getter___2_Callback(mthis, index_OR_name) native "Storage___getter___Callback_RESOLVER_STRING_1_DOMString";

  // Generated overload resolver
  static $__setter__(mthis, index_OR_name, value) {
    if ((value is String || value == null) && (index_OR_name is int || index_OR_name == null)) {
      $___setter___1_Callback(mthis, index_OR_name, value);
      return;
    }
    if ((value is String || value == null) && (index_OR_name is String || index_OR_name == null)) {
      $___setter___2_Callback(mthis, index_OR_name, value);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  static $___setter___1_Callback(mthis, index_OR_name, value) native "Storage___setter___Callback_RESOLVER_STRING_2_unsigned long_DOMString";

  static $___setter___2_Callback(mthis, index_OR_name, value) native "Storage___setter___Callback_RESOLVER_STRING_2_DOMString_DOMString";

  static $clear_Callback(mthis) native "Storage_clear_Callback_RESOLVER_STRING_0_";

  static $getItem_Callback(mthis, key) native "Storage_getItem_Callback_RESOLVER_STRING_1_DOMString";

  static $key_Callback(mthis, index) native "Storage_key_Callback_RESOLVER_STRING_1_unsigned long";

  static $removeItem_Callback(mthis, key) native "Storage_removeItem_Callback_RESOLVER_STRING_1_DOMString";

  static $setItem_Callback(mthis, key, data) native "Storage_setItem_Callback_RESOLVER_STRING_2_DOMString_DOMString";
}

class BlinkStorageEvent {
  static $key_Getter(mthis) native "StorageEvent_key_Getter";

  static $newValue_Getter(mthis) native "StorageEvent_newValue_Getter";

  static $oldValue_Getter(mthis) native "StorageEvent_oldValue_Getter";

  static $storageArea_Getter(mthis) native "StorageEvent_storageArea_Getter";

  static $url_Getter(mthis) native "StorageEvent_url_Getter";

  static $initStorageEvent_Callback(mthis, typeArg, canBubbleArg, cancelableArg, keyArg, oldValueArg, newValueArg, urlArg, storageAreaArg) native "StorageEvent_initStorageEvent_Callback_RESOLVER_STRING_8_DOMString_boolean_boolean_DOMString_DOMString_DOMString_DOMString_Storage";
}

class BlinkStorageInfo {
  static $quota_Getter(mthis) native "StorageInfo_quota_Getter";

  static $usage_Getter(mthis) native "StorageInfo_usage_Getter";
}

class BlinkStorageQuota {
  static $supportedTypes_Getter(mthis) native "StorageQuota_supportedTypes_Getter";
}

class BlinkStream {
  static $type_Getter(mthis) native "Stream_type_Getter";
}

class BlinkStyleMedia {
  static $type_Getter(mthis) native "StyleMedia_type_Getter";

  static $matchMedium_Callback(mthis, mediaquery) native "StyleMedia_matchMedium_Callback_RESOLVER_STRING_1_DOMString";
}

class BlinkStyleSheetList {
  static $length_Getter(mthis) native "StyleSheetList_length_Getter";

  static $NativeIndexed_Getter(mthis, index) native "StyleSheetList_item_Callback_RESOLVER_STRING_1_unsigned long";

  static $__getter___Callback(mthis, name) native "StyleSheetList___getter___Callback_RESOLVER_STRING_1_DOMString";

  static $item_Callback(mthis, index) native "StyleSheetList_item_Callback_RESOLVER_STRING_1_unsigned long";
}

class BlinkSubtleCrypto {}

class BlinkTextEvent {
  static $data_Getter(mthis) native "TextEvent_data_Getter";

  static $initTextEvent_Callback(mthis, typeArg, canBubbleArg, cancelableArg, viewArg, dataArg) native "TextEvent_initTextEvent_Callback_RESOLVER_STRING_5_DOMString_boolean_boolean_Window_DOMString";
}

class BlinkTextMetrics {
  static $width_Getter(mthis) native "TextMetrics_width_Getter";
}

class BlinkTextTrack {
  static $activeCues_Getter(mthis) native "TextTrack_activeCues_Getter";

  static $cues_Getter(mthis) native "TextTrack_cues_Getter";

  static $id_Getter(mthis) native "TextTrack_id_Getter";

  static $kind_Getter(mthis) native "TextTrack_kind_Getter";

  static $label_Getter(mthis) native "TextTrack_label_Getter";

  static $language_Getter(mthis) native "TextTrack_language_Getter";

  static $mode_Getter(mthis) native "TextTrack_mode_Getter";

  static $mode_Setter(mthis, value) native "TextTrack_mode_Setter";

  static $regions_Getter(mthis) native "TextTrack_regions_Getter";

  static $addCue_Callback(mthis, cue) native "TextTrack_addCue_Callback_RESOLVER_STRING_1_TextTrackCue";

  static $addRegion_Callback(mthis, region) native "TextTrack_addRegion_Callback_RESOLVER_STRING_1_VTTRegion";

  static $removeCue_Callback(mthis, cue) native "TextTrack_removeCue_Callback_RESOLVER_STRING_1_TextTrackCue";

  static $removeRegion_Callback(mthis, region) native "TextTrack_removeRegion_Callback_RESOLVER_STRING_1_VTTRegion";
}

class BlinkTextTrackCue {
  static $endTime_Getter(mthis) native "TextTrackCue_endTime_Getter";

  static $endTime_Setter(mthis, value) native "TextTrackCue_endTime_Setter";

  static $id_Getter(mthis) native "TextTrackCue_id_Getter";

  static $id_Setter(mthis, value) native "TextTrackCue_id_Setter";

  static $pauseOnExit_Getter(mthis) native "TextTrackCue_pauseOnExit_Getter";

  static $pauseOnExit_Setter(mthis, value) native "TextTrackCue_pauseOnExit_Setter";

  static $startTime_Getter(mthis) native "TextTrackCue_startTime_Getter";

  static $startTime_Setter(mthis, value) native "TextTrackCue_startTime_Setter";

  static $track_Getter(mthis) native "TextTrackCue_track_Getter";
}

class BlinkTextTrackCueList {
  static $length_Getter(mthis) native "TextTrackCueList_length_Getter";

  static $NativeIndexed_Getter(mthis, index) native "TextTrackCueList_item_Callback_RESOLVER_STRING_1_unsigned long";

  static $getCueById_Callback(mthis, id) native "TextTrackCueList_getCueById_Callback_RESOLVER_STRING_1_DOMString";

  static $item_Callback(mthis, index) native "TextTrackCueList_item_Callback_RESOLVER_STRING_1_unsigned long";
}

class BlinkTextTrackList {
  static $length_Getter(mthis) native "TextTrackList_length_Getter";

  static $NativeIndexed_Getter(mthis, index) native "TextTrackList_item_Callback_RESOLVER_STRING_1_unsigned long";

  static $getTrackById_Callback(mthis, id) native "TextTrackList_getTrackById_Callback_RESOLVER_STRING_1_DOMString";

  static $item_Callback(mthis, index) native "TextTrackList_item_Callback_RESOLVER_STRING_1_unsigned long";
}

class BlinkTimeRanges {
  static $length_Getter(mthis) native "TimeRanges_length_Getter";

  static $end_Callback(mthis, index) native "TimeRanges_end_Callback_RESOLVER_STRING_1_unsigned long";

  static $start_Callback(mthis, index) native "TimeRanges_start_Callback_RESOLVER_STRING_1_unsigned long";
}

class BlinkTimeline {
  static $play_Callback(mthis, source) native "Timeline_play_Callback_RESOLVER_STRING_1_TimedItem";
}

class BlinkTiming {
  static $delay_Getter(mthis) native "Timing_delay_Getter";

  static $delay_Setter(mthis, value) native "Timing_delay_Setter";

  static $direction_Getter(mthis) native "Timing_direction_Getter";

  static $direction_Setter(mthis, value) native "Timing_direction_Setter";

  static $easing_Getter(mthis) native "Timing_easing_Getter";

  static $easing_Setter(mthis, value) native "Timing_easing_Setter";

  static $endDelay_Getter(mthis) native "Timing_endDelay_Getter";

  static $endDelay_Setter(mthis, value) native "Timing_endDelay_Setter";

  static $fill_Getter(mthis) native "Timing_fill_Getter";

  static $fill_Setter(mthis, value) native "Timing_fill_Setter";

  static $iterationStart_Getter(mthis) native "Timing_iterationStart_Getter";

  static $iterationStart_Setter(mthis, value) native "Timing_iterationStart_Setter";

  static $iterations_Getter(mthis) native "Timing_iterations_Getter";

  static $iterations_Setter(mthis, value) native "Timing_iterations_Setter";

  static $playbackRate_Getter(mthis) native "Timing_playbackRate_Getter";

  static $playbackRate_Setter(mthis, value) native "Timing_playbackRate_Setter";

  static $__setter___Callback(mthis, name, duration) native "Timing___setter___Callback_RESOLVER_STRING_2_DOMString_double";
}

class BlinkTouch {
  static $clientX_Getter(mthis) native "Touch_clientX_Getter";

  static $clientY_Getter(mthis) native "Touch_clientY_Getter";

  static $identifier_Getter(mthis) native "Touch_identifier_Getter";

  static $pageX_Getter(mthis) native "Touch_pageX_Getter";

  static $pageY_Getter(mthis) native "Touch_pageY_Getter";

  static $screenX_Getter(mthis) native "Touch_screenX_Getter";

  static $screenY_Getter(mthis) native "Touch_screenY_Getter";

  static $target_Getter(mthis) native "Touch_target_Getter";

  static $webkitForce_Getter(mthis) native "Touch_webkitForce_Getter";

  static $webkitRadiusX_Getter(mthis) native "Touch_webkitRadiusX_Getter";

  static $webkitRadiusY_Getter(mthis) native "Touch_webkitRadiusY_Getter";

  static $webkitRotationAngle_Getter(mthis) native "Touch_webkitRotationAngle_Getter";
}

class BlinkTouchEvent {
  static $altKey_Getter(mthis) native "TouchEvent_altKey_Getter";

  static $changedTouches_Getter(mthis) native "TouchEvent_changedTouches_Getter";

  static $ctrlKey_Getter(mthis) native "TouchEvent_ctrlKey_Getter";

  static $metaKey_Getter(mthis) native "TouchEvent_metaKey_Getter";

  static $shiftKey_Getter(mthis) native "TouchEvent_shiftKey_Getter";

  static $targetTouches_Getter(mthis) native "TouchEvent_targetTouches_Getter";

  static $touches_Getter(mthis) native "TouchEvent_touches_Getter";

  static $initTouchEvent_Callback(mthis, touches, targetTouches, changedTouches, type, view, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey) native "TouchEvent_initTouchEvent_Callback_RESOLVER_STRING_13_TouchList_TouchList_TouchList_DOMString_Window_long_long_long_long_boolean_boolean_boolean_boolean";
}

class BlinkTouchList {
  static $length_Getter(mthis) native "TouchList_length_Getter";

  static $NativeIndexed_Getter(mthis, index) native "TouchList_item_Callback_RESOLVER_STRING_1_unsigned long";

  static $item_Callback(mthis, index) native "TouchList_item_Callback_RESOLVER_STRING_1_unsigned long";
}

class BlinkTrackEvent {
  static $track_Getter(mthis) native "TrackEvent_track_Getter";
}

class BlinkTransitionEvent {
  static $elapsedTime_Getter(mthis) native "TransitionEvent_elapsedTime_Getter";

  static $propertyName_Getter(mthis) native "TransitionEvent_propertyName_Getter";

  static $pseudoElement_Getter(mthis) native "TransitionEvent_pseudoElement_Getter";
}

class BlinkTreeWalker {
  static $currentNode_Getter(mthis) native "TreeWalker_currentNode_Getter";

  static $currentNode_Setter(mthis, value) native "TreeWalker_currentNode_Setter";

  static $filter_Getter(mthis) native "TreeWalker_filter_Getter";

  static $root_Getter(mthis) native "TreeWalker_root_Getter";

  static $whatToShow_Getter(mthis) native "TreeWalker_whatToShow_Getter";

  static $firstChild_Callback(mthis) native "TreeWalker_firstChild_Callback_RESOLVER_STRING_0_";

  static $lastChild_Callback(mthis) native "TreeWalker_lastChild_Callback_RESOLVER_STRING_0_";

  static $nextNode_Callback(mthis) native "TreeWalker_nextNode_Callback_RESOLVER_STRING_0_";

  static $nextSibling_Callback(mthis) native "TreeWalker_nextSibling_Callback_RESOLVER_STRING_0_";

  static $parentNode_Callback(mthis) native "TreeWalker_parentNode_Callback_RESOLVER_STRING_0_";

  static $previousNode_Callback(mthis) native "TreeWalker_previousNode_Callback_RESOLVER_STRING_0_";

  static $previousSibling_Callback(mthis) native "TreeWalker_previousSibling_Callback_RESOLVER_STRING_0_";
}

class BlinkURL {
  // Generated overload resolver
  static $createObjectUrl(blob_OR_source_OR_stream) {
    if ((blob_OR_source_OR_stream is Blob || blob_OR_source_OR_stream == null)) {
      return $_createObjectURL_1_Callback(blob_OR_source_OR_stream);
    }
    if ((blob_OR_source_OR_stream is MediaSource || blob_OR_source_OR_stream == null)) {
      return $_createObjectURL_2_Callback(blob_OR_source_OR_stream);
    }
    if ((blob_OR_source_OR_stream is MediaStream || blob_OR_source_OR_stream == null)) {
      return $_createObjectURL_3_Callback(blob_OR_source_OR_stream);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  static $_createObjectURL_1_Callback(blob_OR_source_OR_stream) native "URL_createObjectURL_Callback_RESOLVER_STRING_1_Blob";

  static $_createObjectURL_2_Callback(blob_OR_source_OR_stream) native "URL_createObjectURL_Callback_RESOLVER_STRING_1_MediaSource";

  static $_createObjectURL_3_Callback(blob_OR_source_OR_stream) native "URL_createObjectURL_Callback_RESOLVER_STRING_1_MediaStream";

  static $createObjectUrlFromBlob_Callback(blob) native "URL_createObjectURL_Callback_RESOLVER_STRING_1_Blob";

  static $createObjectUrlFromSource_Callback(source) native "URL_createObjectURL_Callback_RESOLVER_STRING_1_MediaSource";

  static $createObjectUrlFromStream_Callback(stream) native "URL_createObjectURL_Callback_RESOLVER_STRING_1_MediaStream";

  static $revokeObjectURL_Callback(url) native "URL_revokeObjectURL_Callback_RESOLVER_STRING_1_DOMString";

  static $hash_Getter(mthis) native "URL_hash_Getter";

  static $hash_Setter(mthis, value) native "URL_hash_Setter";

  static $host_Getter(mthis) native "URL_host_Getter";

  static $host_Setter(mthis, value) native "URL_host_Setter";

  static $hostname_Getter(mthis) native "URL_hostname_Getter";

  static $hostname_Setter(mthis, value) native "URL_hostname_Setter";

  static $href_Getter(mthis) native "URL_href_Getter";

  static $href_Setter(mthis, value) native "URL_href_Setter";

  static $origin_Getter(mthis) native "URL_origin_Getter";

  static $password_Getter(mthis) native "URL_password_Getter";

  static $password_Setter(mthis, value) native "URL_password_Setter";

  static $pathname_Getter(mthis) native "URL_pathname_Getter";

  static $pathname_Setter(mthis, value) native "URL_pathname_Setter";

  static $port_Getter(mthis) native "URL_port_Getter";

  static $port_Setter(mthis, value) native "URL_port_Setter";

  static $protocol_Getter(mthis) native "URL_protocol_Getter";

  static $protocol_Setter(mthis, value) native "URL_protocol_Setter";

  static $search_Getter(mthis) native "URL_search_Getter";

  static $search_Setter(mthis, value) native "URL_search_Setter";

  static $username_Getter(mthis) native "URL_username_Getter";

  static $username_Setter(mthis, value) native "URL_username_Setter";

  static $toString_Callback(mthis) native "URL_toString_Callback_RESOLVER_STRING_0_";
}

class BlinkURLUtilsReadOnly {
  static $hash_Getter(mthis) native "WorkerLocation_hash_Getter";

  static $host_Getter(mthis) native "WorkerLocation_host_Getter";

  static $hostname_Getter(mthis) native "WorkerLocation_hostname_Getter";

  static $href_Getter(mthis) native "WorkerLocation_href_Getter";

  static $pathname_Getter(mthis) native "WorkerLocation_pathname_Getter";

  static $port_Getter(mthis) native "WorkerLocation_port_Getter";

  static $protocol_Getter(mthis) native "WorkerLocation_protocol_Getter";

  static $search_Getter(mthis) native "WorkerLocation_search_Getter";

  static $toString_Callback(mthis) native "WorkerLocation_toString_Callback_RESOLVER_STRING_0_";
}

class BlinkVTTCue {
  // Generated overload resolver
  static $mkVttCue(startTime, endTime, text) {
    return $_create_1constructorCallback(startTime, endTime, text);
  }

  static $_create_1constructorCallback(startTime, endTime, text) native "VTTCue_constructorCallback_RESOLVER_STRING_3_double_double_DOMString";

  static $align_Getter(mthis) native "VTTCue_align_Getter";

  static $align_Setter(mthis, value) native "VTTCue_align_Setter";

  static $line_Getter(mthis) native "VTTCue_line_Getter";

  static $line_Setter(mthis, value) native "VTTCue_line_Setter";

  static $position_Getter(mthis) native "VTTCue_position_Getter";

  static $position_Setter(mthis, value) native "VTTCue_position_Setter";

  static $regionId_Getter(mthis) native "VTTCue_regionId_Getter";

  static $regionId_Setter(mthis, value) native "VTTCue_regionId_Setter";

  static $size_Getter(mthis) native "VTTCue_size_Getter";

  static $size_Setter(mthis, value) native "VTTCue_size_Setter";

  static $snapToLines_Getter(mthis) native "VTTCue_snapToLines_Getter";

  static $snapToLines_Setter(mthis, value) native "VTTCue_snapToLines_Setter";

  static $text_Getter(mthis) native "VTTCue_text_Getter";

  static $text_Setter(mthis, value) native "VTTCue_text_Setter";

  static $vertical_Getter(mthis) native "VTTCue_vertical_Getter";

  static $vertical_Setter(mthis, value) native "VTTCue_vertical_Setter";

  static $getCueAsHTML_Callback(mthis) native "VTTCue_getCueAsHTML_Callback_RESOLVER_STRING_0_";
}

class BlinkVTTRegion {
  // Generated overload resolver
  static $mkVttRegion() {
    return $_create_1constructorCallback();
  }

  static $_create_1constructorCallback() native "VTTRegion_constructorCallback_RESOLVER_STRING_0_";

  static $height_Getter(mthis) native "VTTRegion_height_Getter";

  static $height_Setter(mthis, value) native "VTTRegion_height_Setter";

  static $id_Getter(mthis) native "VTTRegion_id_Getter";

  static $id_Setter(mthis, value) native "VTTRegion_id_Setter";

  static $regionAnchorX_Getter(mthis) native "VTTRegion_regionAnchorX_Getter";

  static $regionAnchorX_Setter(mthis, value) native "VTTRegion_regionAnchorX_Setter";

  static $regionAnchorY_Getter(mthis) native "VTTRegion_regionAnchorY_Getter";

  static $regionAnchorY_Setter(mthis, value) native "VTTRegion_regionAnchorY_Setter";

  static $scroll_Getter(mthis) native "VTTRegion_scroll_Getter";

  static $scroll_Setter(mthis, value) native "VTTRegion_scroll_Setter";

  static $track_Getter(mthis) native "VTTRegion_track_Getter";

  static $viewportAnchorX_Getter(mthis) native "VTTRegion_viewportAnchorX_Getter";

  static $viewportAnchorX_Setter(mthis, value) native "VTTRegion_viewportAnchorX_Setter";

  static $viewportAnchorY_Getter(mthis) native "VTTRegion_viewportAnchorY_Getter";

  static $viewportAnchorY_Setter(mthis, value) native "VTTRegion_viewportAnchorY_Setter";

  static $width_Getter(mthis) native "VTTRegion_width_Getter";

  static $width_Setter(mthis, value) native "VTTRegion_width_Setter";
}

class BlinkVTTRegionList {
  static $length_Getter(mthis) native "VTTRegionList_length_Getter";

  static $getRegionById_Callback(mthis, id) native "VTTRegionList_getRegionById_Callback_RESOLVER_STRING_1_DOMString";

  static $item_Callback(mthis, index) native "VTTRegionList_item_Callback_RESOLVER_STRING_1_unsigned long";
}

class BlinkValidityState {
  static $badInput_Getter(mthis) native "ValidityState_badInput_Getter";

  static $customError_Getter(mthis) native "ValidityState_customError_Getter";

  static $patternMismatch_Getter(mthis) native "ValidityState_patternMismatch_Getter";

  static $rangeOverflow_Getter(mthis) native "ValidityState_rangeOverflow_Getter";

  static $rangeUnderflow_Getter(mthis) native "ValidityState_rangeUnderflow_Getter";

  static $stepMismatch_Getter(mthis) native "ValidityState_stepMismatch_Getter";

  static $tooLong_Getter(mthis) native "ValidityState_tooLong_Getter";

  static $typeMismatch_Getter(mthis) native "ValidityState_typeMismatch_Getter";

  static $valid_Getter(mthis) native "ValidityState_valid_Getter";

  static $valueMissing_Getter(mthis) native "ValidityState_valueMissing_Getter";
}

class BlinkVideoPlaybackQuality {
  static $corruptedVideoFrames_Getter(mthis) native "VideoPlaybackQuality_corruptedVideoFrames_Getter";

  static $creationTime_Getter(mthis) native "VideoPlaybackQuality_creationTime_Getter";

  static $droppedVideoFrames_Getter(mthis) native "VideoPlaybackQuality_droppedVideoFrames_Getter";

  static $totalVideoFrames_Getter(mthis) native "VideoPlaybackQuality_totalVideoFrames_Getter";
}

class BlinkWaveShaperNode {
  static $curve_Getter(mthis) native "WaveShaperNode_curve_Getter";

  static $curve_Setter(mthis, value) native "WaveShaperNode_curve_Setter";

  static $oversample_Getter(mthis) native "WaveShaperNode_oversample_Getter";

  static $oversample_Setter(mthis, value) native "WaveShaperNode_oversample_Setter";
}

class BlinkWebGLActiveInfo {
  static $name_Getter(mthis) native "WebGLActiveInfo_name_Getter";

  static $size_Getter(mthis) native "WebGLActiveInfo_size_Getter";

  static $type_Getter(mthis) native "WebGLActiveInfo_type_Getter";
}

class BlinkWebGLBuffer {}

class BlinkWebGLCompressedTextureATC {}

class BlinkWebGLCompressedTexturePVRTC {}

class BlinkWebGLCompressedTextureS3TC {}

class BlinkWebGLContextAttributes {
  static $alpha_Getter(mthis) native "WebGLContextAttributes_alpha_Getter";

  static $alpha_Setter(mthis, value) native "WebGLContextAttributes_alpha_Setter";

  static $antialias_Getter(mthis) native "WebGLContextAttributes_antialias_Getter";

  static $antialias_Setter(mthis, value) native "WebGLContextAttributes_antialias_Setter";

  static $depth_Getter(mthis) native "WebGLContextAttributes_depth_Getter";

  static $depth_Setter(mthis, value) native "WebGLContextAttributes_depth_Setter";

  static $failIfMajorPerformanceCaveat_Getter(mthis) native "WebGLContextAttributes_failIfMajorPerformanceCaveat_Getter";

  static $failIfMajorPerformanceCaveat_Setter(mthis, value) native "WebGLContextAttributes_failIfMajorPerformanceCaveat_Setter";

  static $premultipliedAlpha_Getter(mthis) native "WebGLContextAttributes_premultipliedAlpha_Getter";

  static $premultipliedAlpha_Setter(mthis, value) native "WebGLContextAttributes_premultipliedAlpha_Setter";

  static $preserveDrawingBuffer_Getter(mthis) native "WebGLContextAttributes_preserveDrawingBuffer_Getter";

  static $preserveDrawingBuffer_Setter(mthis, value) native "WebGLContextAttributes_preserveDrawingBuffer_Setter";

  static $stencil_Getter(mthis) native "WebGLContextAttributes_stencil_Getter";

  static $stencil_Setter(mthis, value) native "WebGLContextAttributes_stencil_Setter";
}

class BlinkWebGLContextEvent {
  static $statusMessage_Getter(mthis) native "WebGLContextEvent_statusMessage_Getter";
}

class BlinkWebGLDebugRendererInfo {}

class BlinkWebGLDebugShaders {
  static $getTranslatedShaderSource_Callback(mthis, shader) native "WebGLDebugShaders_getTranslatedShaderSource_Callback_RESOLVER_STRING_1_WebGLShader";
}

class BlinkWebGLDepthTexture {}

class BlinkWebGLDrawBuffers {
  static $drawBuffersWEBGL_Callback(mthis, buffers) native "WebGLDrawBuffers_drawBuffersWEBGL_Callback_RESOLVER_STRING_1_sequence<unsigned long>";
}

class BlinkWebGLFramebuffer {}

class BlinkWebGLLoseContext {
  static $loseContext_Callback(mthis) native "WebGLLoseContext_loseContext_Callback_RESOLVER_STRING_0_";

  static $restoreContext_Callback(mthis) native "WebGLLoseContext_restoreContext_Callback_RESOLVER_STRING_0_";
}

class BlinkWebGLProgram {}

class BlinkWebGLRenderbuffer {}

class BlinkWebGLRenderingContext {
  static $drawingBufferHeight_Getter(mthis) native "WebGLRenderingContext_drawingBufferHeight_Getter";

  static $drawingBufferWidth_Getter(mthis) native "WebGLRenderingContext_drawingBufferWidth_Getter";

  static $activeTexture_Callback(mthis, texture) native "WebGLRenderingContext_activeTexture_Callback_RESOLVER_STRING_1_unsigned long";

  static $attachShader_Callback(mthis, program, shader) native "WebGLRenderingContext_attachShader_Callback_RESOLVER_STRING_2_WebGLProgram_WebGLShader";

  static $bindAttribLocation_Callback(mthis, program, index, name) native "WebGLRenderingContext_bindAttribLocation_Callback_RESOLVER_STRING_3_WebGLProgram_unsigned long_DOMString";

  static $bindBuffer_Callback(mthis, target, buffer) native "WebGLRenderingContext_bindBuffer_Callback_RESOLVER_STRING_2_unsigned long_WebGLBuffer";

  static $bindFramebuffer_Callback(mthis, target, framebuffer) native "WebGLRenderingContext_bindFramebuffer_Callback_RESOLVER_STRING_2_unsigned long_WebGLFramebuffer";

  static $bindRenderbuffer_Callback(mthis, target, renderbuffer) native "WebGLRenderingContext_bindRenderbuffer_Callback_RESOLVER_STRING_2_unsigned long_WebGLRenderbuffer";

  static $bindTexture_Callback(mthis, target, texture) native "WebGLRenderingContext_bindTexture_Callback_RESOLVER_STRING_2_unsigned long_WebGLTexture";

  static $blendColor_Callback(mthis, red, green, blue, alpha) native "WebGLRenderingContext_blendColor_Callback_RESOLVER_STRING_4_float_float_float_float";

  static $blendEquation_Callback(mthis, mode) native "WebGLRenderingContext_blendEquation_Callback_RESOLVER_STRING_1_unsigned long";

  static $blendEquationSeparate_Callback(mthis, modeRGB, modeAlpha) native "WebGLRenderingContext_blendEquationSeparate_Callback_RESOLVER_STRING_2_unsigned long_unsigned long";

  static $blendFunc_Callback(mthis, sfactor, dfactor) native "WebGLRenderingContext_blendFunc_Callback_RESOLVER_STRING_2_unsigned long_unsigned long";

  static $blendFuncSeparate_Callback(mthis, srcRGB, dstRGB, srcAlpha, dstAlpha) native "WebGLRenderingContext_blendFuncSeparate_Callback_RESOLVER_STRING_4_unsigned long_unsigned long_unsigned long_unsigned long";

  static $bufferByteData_Callback(mthis, target, data, usage) native "WebGLRenderingContext_bufferData_Callback_RESOLVER_STRING_3_unsigned long_ArrayBuffer_unsigned long";

  // Generated overload resolver
  static $bufferData(mthis, target, data_OR_size, usage) {
    if ((usage is int || usage == null) && (data_OR_size is TypedData || data_OR_size == null) && (target is int || target == null)) {
      $_bufferData_1_Callback(mthis, target, data_OR_size, usage);
      return;
    }
    if ((usage is int || usage == null) && (data_OR_size is ByteBuffer || data_OR_size == null) && (target is int || target == null)) {
      $_bufferData_2_Callback(mthis, target, data_OR_size, usage);
      return;
    }
    if ((usage is int || usage == null) && (data_OR_size is int || data_OR_size == null) && (target is int || target == null)) {
      $_bufferData_3_Callback(mthis, target, data_OR_size, usage);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  static $_bufferData_1_Callback(mthis, target, data_OR_size, usage) native "WebGLRenderingContext_bufferData_Callback_RESOLVER_STRING_3_unsigned long_ArrayBufferView_unsigned long";

  static $_bufferData_2_Callback(mthis, target, data_OR_size, usage) native "WebGLRenderingContext_bufferData_Callback_RESOLVER_STRING_3_unsigned long_ArrayBuffer_unsigned long";

  static $_bufferData_3_Callback(mthis, target, data_OR_size, usage) native "WebGLRenderingContext_bufferData_Callback_RESOLVER_STRING_3_unsigned long_long long_unsigned long";

  static $bufferDataTyped_Callback(mthis, target, data, usage) native "WebGLRenderingContext_bufferData_Callback_RESOLVER_STRING_3_unsigned long_ArrayBufferView_unsigned long";

  static $bufferSubByteData_Callback(mthis, target, offset, data) native "WebGLRenderingContext_bufferSubData_Callback_RESOLVER_STRING_3_unsigned long_long long_ArrayBuffer";

  // Generated overload resolver
  static $bufferSubData(mthis, target, offset, data) {
    if ((data is TypedData || data == null) && (offset is int || offset == null) && (target is int || target == null)) {
      $_bufferSubData_1_Callback(mthis, target, offset, data);
      return;
    }
    if ((data is ByteBuffer || data == null) && (offset is int || offset == null) && (target is int || target == null)) {
      $_bufferSubData_2_Callback(mthis, target, offset, data);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  static $_bufferSubData_1_Callback(mthis, target, offset, data) native "WebGLRenderingContext_bufferSubData_Callback_RESOLVER_STRING_3_unsigned long_long long_ArrayBufferView";

  static $_bufferSubData_2_Callback(mthis, target, offset, data) native "WebGLRenderingContext_bufferSubData_Callback_RESOLVER_STRING_3_unsigned long_long long_ArrayBuffer";

  static $bufferSubDataTyped_Callback(mthis, target, offset, data) native "WebGLRenderingContext_bufferSubData_Callback_RESOLVER_STRING_3_unsigned long_long long_ArrayBufferView";

  static $checkFramebufferStatus_Callback(mthis, target) native "WebGLRenderingContext_checkFramebufferStatus_Callback_RESOLVER_STRING_1_unsigned long";

  static $clear_Callback(mthis, mask) native "WebGLRenderingContext_clear_Callback_RESOLVER_STRING_1_unsigned long";

  static $clearColor_Callback(mthis, red, green, blue, alpha) native "WebGLRenderingContext_clearColor_Callback_RESOLVER_STRING_4_float_float_float_float";

  static $clearDepth_Callback(mthis, depth) native "WebGLRenderingContext_clearDepth_Callback_RESOLVER_STRING_1_float";

  static $clearStencil_Callback(mthis, s) native "WebGLRenderingContext_clearStencil_Callback_RESOLVER_STRING_1_long";

  static $colorMask_Callback(mthis, red, green, blue, alpha) native "WebGLRenderingContext_colorMask_Callback_RESOLVER_STRING_4_boolean_boolean_boolean_boolean";

  static $compileShader_Callback(mthis, shader) native "WebGLRenderingContext_compileShader_Callback_RESOLVER_STRING_1_WebGLShader";

  static $compressedTexImage2D_Callback(mthis, target, level, internalformat, width, height, border, data) native "WebGLRenderingContext_compressedTexImage2D_Callback_RESOLVER_STRING_7_unsigned long_long_unsigned long_long_long_long_ArrayBufferView";

  static $compressedTexSubImage2D_Callback(mthis, target, level, xoffset, yoffset, width, height, format, data) native "WebGLRenderingContext_compressedTexSubImage2D_Callback_RESOLVER_STRING_8_unsigned long_long_long_long_long_long_unsigned long_ArrayBufferView";

  static $copyTexImage2D_Callback(mthis, target, level, internalformat, x, y, width, height, border) native "WebGLRenderingContext_copyTexImage2D_Callback_RESOLVER_STRING_8_unsigned long_long_unsigned long_long_long_long_long_long";

  static $copyTexSubImage2D_Callback(mthis, target, level, xoffset, yoffset, x, y, width, height) native "WebGLRenderingContext_copyTexSubImage2D_Callback_RESOLVER_STRING_8_unsigned long_long_long_long_long_long_long_long";

  static $createBuffer_Callback(mthis) native "WebGLRenderingContext_createBuffer_Callback_RESOLVER_STRING_0_";

  static $createFramebuffer_Callback(mthis) native "WebGLRenderingContext_createFramebuffer_Callback_RESOLVER_STRING_0_";

  static $createProgram_Callback(mthis) native "WebGLRenderingContext_createProgram_Callback_RESOLVER_STRING_0_";

  static $createRenderbuffer_Callback(mthis) native "WebGLRenderingContext_createRenderbuffer_Callback_RESOLVER_STRING_0_";

  static $createShader_Callback(mthis, type) native "WebGLRenderingContext_createShader_Callback_RESOLVER_STRING_1_unsigned long";

  static $createTexture_Callback(mthis) native "WebGLRenderingContext_createTexture_Callback_RESOLVER_STRING_0_";

  static $cullFace_Callback(mthis, mode) native "WebGLRenderingContext_cullFace_Callback_RESOLVER_STRING_1_unsigned long";

  static $deleteBuffer_Callback(mthis, buffer) native "WebGLRenderingContext_deleteBuffer_Callback_RESOLVER_STRING_1_WebGLBuffer";

  static $deleteFramebuffer_Callback(mthis, framebuffer) native "WebGLRenderingContext_deleteFramebuffer_Callback_RESOLVER_STRING_1_WebGLFramebuffer";

  static $deleteProgram_Callback(mthis, program) native "WebGLRenderingContext_deleteProgram_Callback_RESOLVER_STRING_1_WebGLProgram";

  static $deleteRenderbuffer_Callback(mthis, renderbuffer) native "WebGLRenderingContext_deleteRenderbuffer_Callback_RESOLVER_STRING_1_WebGLRenderbuffer";

  static $deleteShader_Callback(mthis, shader) native "WebGLRenderingContext_deleteShader_Callback_RESOLVER_STRING_1_WebGLShader";

  static $deleteTexture_Callback(mthis, texture) native "WebGLRenderingContext_deleteTexture_Callback_RESOLVER_STRING_1_WebGLTexture";

  static $depthFunc_Callback(mthis, func) native "WebGLRenderingContext_depthFunc_Callback_RESOLVER_STRING_1_unsigned long";

  static $depthMask_Callback(mthis, flag) native "WebGLRenderingContext_depthMask_Callback_RESOLVER_STRING_1_boolean";

  static $depthRange_Callback(mthis, zNear, zFar) native "WebGLRenderingContext_depthRange_Callback_RESOLVER_STRING_2_float_float";

  static $detachShader_Callback(mthis, program, shader) native "WebGLRenderingContext_detachShader_Callback_RESOLVER_STRING_2_WebGLProgram_WebGLShader";

  static $disable_Callback(mthis, cap) native "WebGLRenderingContext_disable_Callback_RESOLVER_STRING_1_unsigned long";

  static $disableVertexAttribArray_Callback(mthis, index) native "WebGLRenderingContext_disableVertexAttribArray_Callback_RESOLVER_STRING_1_unsigned long";

  static $drawArrays_Callback(mthis, mode, first, count) native "WebGLRenderingContext_drawArrays_Callback_RESOLVER_STRING_3_unsigned long_long_long";

  static $drawElements_Callback(mthis, mode, count, type, offset) native "WebGLRenderingContext_drawElements_Callback_RESOLVER_STRING_4_unsigned long_long_unsigned long_long long";

  static $enable_Callback(mthis, cap) native "WebGLRenderingContext_enable_Callback_RESOLVER_STRING_1_unsigned long";

  static $enableVertexAttribArray_Callback(mthis, index) native "WebGLRenderingContext_enableVertexAttribArray_Callback_RESOLVER_STRING_1_unsigned long";

  static $finish_Callback(mthis) native "WebGLRenderingContext_finish_Callback_RESOLVER_STRING_0_";

  static $flush_Callback(mthis) native "WebGLRenderingContext_flush_Callback_RESOLVER_STRING_0_";

  static $framebufferRenderbuffer_Callback(mthis, target, attachment, renderbuffertarget, renderbuffer) native "WebGLRenderingContext_framebufferRenderbuffer_Callback_RESOLVER_STRING_4_unsigned long_unsigned long_unsigned long_WebGLRenderbuffer";

  static $framebufferTexture2D_Callback(mthis, target, attachment, textarget, texture, level) native "WebGLRenderingContext_framebufferTexture2D_Callback_RESOLVER_STRING_5_unsigned long_unsigned long_unsigned long_WebGLTexture_long";

  static $frontFace_Callback(mthis, mode) native "WebGLRenderingContext_frontFace_Callback_RESOLVER_STRING_1_unsigned long";

  static $generateMipmap_Callback(mthis, target) native "WebGLRenderingContext_generateMipmap_Callback_RESOLVER_STRING_1_unsigned long";

  static $getActiveAttrib_Callback(mthis, program, index) native "WebGLRenderingContext_getActiveAttrib_Callback_RESOLVER_STRING_2_WebGLProgram_unsigned long";

  static $getActiveUniform_Callback(mthis, program, index) native "WebGLRenderingContext_getActiveUniform_Callback_RESOLVER_STRING_2_WebGLProgram_unsigned long";

  static $getAttachedShaders_Callback(mthis, program) native "WebGLRenderingContext_getAttachedShaders_Callback";

  static $getAttribLocation_Callback(mthis, program, name) native "WebGLRenderingContext_getAttribLocation_Callback_RESOLVER_STRING_2_WebGLProgram_DOMString";

  static $getBufferParameter_Callback(mthis, target, pname) native "WebGLRenderingContext_getBufferParameter_Callback";

  static $getContextAttributes_Callback(mthis) native "WebGLRenderingContext_getContextAttributes_Callback_RESOLVER_STRING_0_";

  static $getError_Callback(mthis) native "WebGLRenderingContext_getError_Callback_RESOLVER_STRING_0_";

  static $getExtension_Callback(mthis, name) native "WebGLRenderingContext_getExtension_Callback";

  static $getFramebufferAttachmentParameter_Callback(mthis, target, attachment, pname) native "WebGLRenderingContext_getFramebufferAttachmentParameter_Callback";

  static $getParameter_Callback(mthis, pname) native "WebGLRenderingContext_getParameter_Callback";

  static $getProgramInfoLog_Callback(mthis, program) native "WebGLRenderingContext_getProgramInfoLog_Callback_RESOLVER_STRING_1_WebGLProgram";

  static $getProgramParameter_Callback(mthis, program, pname) native "WebGLRenderingContext_getProgramParameter_Callback";

  static $getRenderbufferParameter_Callback(mthis, target, pname) native "WebGLRenderingContext_getRenderbufferParameter_Callback";

  static $getShaderInfoLog_Callback(mthis, shader) native "WebGLRenderingContext_getShaderInfoLog_Callback_RESOLVER_STRING_1_WebGLShader";

  static $getShaderParameter_Callback(mthis, shader, pname) native "WebGLRenderingContext_getShaderParameter_Callback";

  static $getShaderPrecisionFormat_Callback(mthis, shadertype, precisiontype) native "WebGLRenderingContext_getShaderPrecisionFormat_Callback_RESOLVER_STRING_2_unsigned long_unsigned long";

  static $getShaderSource_Callback(mthis, shader) native "WebGLRenderingContext_getShaderSource_Callback_RESOLVER_STRING_1_WebGLShader";

  static $getSupportedExtensions_Callback(mthis) native "WebGLRenderingContext_getSupportedExtensions_Callback";

  static $getTexParameter_Callback(mthis, target, pname) native "WebGLRenderingContext_getTexParameter_Callback";

  static $getUniform_Callback(mthis, program, location) native "WebGLRenderingContext_getUniform_Callback";

  static $getUniformLocation_Callback(mthis, program, name) native "WebGLRenderingContext_getUniformLocation_Callback_RESOLVER_STRING_2_WebGLProgram_DOMString";

  static $getVertexAttrib_Callback(mthis, index, pname) native "WebGLRenderingContext_getVertexAttrib_Callback";

  static $getVertexAttribOffset_Callback(mthis, index, pname) native "WebGLRenderingContext_getVertexAttribOffset_Callback_RESOLVER_STRING_2_unsigned long_unsigned long";

  static $hint_Callback(mthis, target, mode) native "WebGLRenderingContext_hint_Callback_RESOLVER_STRING_2_unsigned long_unsigned long";

  static $isBuffer_Callback(mthis, buffer) native "WebGLRenderingContext_isBuffer_Callback_RESOLVER_STRING_1_WebGLBuffer";

  static $isContextLost_Callback(mthis) native "WebGLRenderingContext_isContextLost_Callback_RESOLVER_STRING_0_";

  static $isEnabled_Callback(mthis, cap) native "WebGLRenderingContext_isEnabled_Callback_RESOLVER_STRING_1_unsigned long";

  static $isFramebuffer_Callback(mthis, framebuffer) native "WebGLRenderingContext_isFramebuffer_Callback_RESOLVER_STRING_1_WebGLFramebuffer";

  static $isProgram_Callback(mthis, program) native "WebGLRenderingContext_isProgram_Callback_RESOLVER_STRING_1_WebGLProgram";

  static $isRenderbuffer_Callback(mthis, renderbuffer) native "WebGLRenderingContext_isRenderbuffer_Callback_RESOLVER_STRING_1_WebGLRenderbuffer";

  static $isShader_Callback(mthis, shader) native "WebGLRenderingContext_isShader_Callback_RESOLVER_STRING_1_WebGLShader";

  static $isTexture_Callback(mthis, texture) native "WebGLRenderingContext_isTexture_Callback_RESOLVER_STRING_1_WebGLTexture";

  static $lineWidth_Callback(mthis, width) native "WebGLRenderingContext_lineWidth_Callback_RESOLVER_STRING_1_float";

  static $linkProgram_Callback(mthis, program) native "WebGLRenderingContext_linkProgram_Callback_RESOLVER_STRING_1_WebGLProgram";

  static $pixelStorei_Callback(mthis, pname, param) native "WebGLRenderingContext_pixelStorei_Callback_RESOLVER_STRING_2_unsigned long_long";

  static $polygonOffset_Callback(mthis, factor, units) native "WebGLRenderingContext_polygonOffset_Callback_RESOLVER_STRING_2_float_float";

  static $readPixels_Callback(mthis, x, y, width, height, format, type, pixels) native "WebGLRenderingContext_readPixels_Callback_RESOLVER_STRING_7_long_long_long_long_unsigned long_unsigned long_ArrayBufferView";

  static $renderbufferStorage_Callback(mthis, target, internalformat, width, height) native "WebGLRenderingContext_renderbufferStorage_Callback_RESOLVER_STRING_4_unsigned long_unsigned long_long_long";

  static $sampleCoverage_Callback(mthis, value, invert) native "WebGLRenderingContext_sampleCoverage_Callback_RESOLVER_STRING_2_float_boolean";

  static $scissor_Callback(mthis, x, y, width, height) native "WebGLRenderingContext_scissor_Callback_RESOLVER_STRING_4_long_long_long_long";

  static $shaderSource_Callback(mthis, shader, string) native "WebGLRenderingContext_shaderSource_Callback_RESOLVER_STRING_2_WebGLShader_DOMString";

  static $stencilFunc_Callback(mthis, func, ref, mask) native "WebGLRenderingContext_stencilFunc_Callback_RESOLVER_STRING_3_unsigned long_long_unsigned long";

  static $stencilFuncSeparate_Callback(mthis, face, func, ref, mask) native "WebGLRenderingContext_stencilFuncSeparate_Callback_RESOLVER_STRING_4_unsigned long_unsigned long_long_unsigned long";

  static $stencilMask_Callback(mthis, mask) native "WebGLRenderingContext_stencilMask_Callback_RESOLVER_STRING_1_unsigned long";

  static $stencilMaskSeparate_Callback(mthis, face, mask) native "WebGLRenderingContext_stencilMaskSeparate_Callback_RESOLVER_STRING_2_unsigned long_unsigned long";

  static $stencilOp_Callback(mthis, fail, zfail, zpass) native "WebGLRenderingContext_stencilOp_Callback_RESOLVER_STRING_3_unsigned long_unsigned long_unsigned long";

  static $stencilOpSeparate_Callback(mthis, face, fail, zfail, zpass) native "WebGLRenderingContext_stencilOpSeparate_Callback_RESOLVER_STRING_4_unsigned long_unsigned long_unsigned long_unsigned long";

  // Generated overload resolver
  static $texImage2D(mthis, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video, format, type, pixels) {
    if ((pixels is TypedData || pixels == null) && (type is int || type == null) && (format is int || format == null) && (border_OR_canvas_OR_image_OR_pixels_OR_video is int || border_OR_canvas_OR_image_OR_pixels_OR_video == null) && (height_OR_type is int || height_OR_type == null) && (format_OR_width is int || format_OR_width == null) && (internalformat is int || internalformat == null) && (level is int || level == null) && (target is int || target == null)) {
      $_texImage2D_1_Callback(mthis, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video, format, type, pixels);
      return;
    }
    if ((border_OR_canvas_OR_image_OR_pixels_OR_video is ImageData || border_OR_canvas_OR_image_OR_pixels_OR_video == null) && (height_OR_type is int || height_OR_type == null) && (format_OR_width is int || format_OR_width == null) && (internalformat is int || internalformat == null) && (level is int || level == null) && (target is int || target == null) && format == null && type == null && pixels == null) {
      $_texImage2D_2_Callback(mthis, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((border_OR_canvas_OR_image_OR_pixels_OR_video is ImageElement || border_OR_canvas_OR_image_OR_pixels_OR_video == null) && (height_OR_type is int || height_OR_type == null) && (format_OR_width is int || format_OR_width == null) && (internalformat is int || internalformat == null) && (level is int || level == null) && (target is int || target == null) && format == null && type == null && pixels == null) {
      $_texImage2D_3_Callback(mthis, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((border_OR_canvas_OR_image_OR_pixels_OR_video is CanvasElement || border_OR_canvas_OR_image_OR_pixels_OR_video == null) && (height_OR_type is int || height_OR_type == null) && (format_OR_width is int || format_OR_width == null) && (internalformat is int || internalformat == null) && (level is int || level == null) && (target is int || target == null) && format == null && type == null && pixels == null) {
      $_texImage2D_4_Callback(mthis, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((border_OR_canvas_OR_image_OR_pixels_OR_video is VideoElement || border_OR_canvas_OR_image_OR_pixels_OR_video == null) && (height_OR_type is int || height_OR_type == null) && (format_OR_width is int || format_OR_width == null) && (internalformat is int || internalformat == null) && (level is int || level == null) && (target is int || target == null) && format == null && type == null && pixels == null) {
      $_texImage2D_5_Callback(mthis, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  static $_texImage2D_1_Callback(mthis, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video, format, type, pixels) native "WebGLRenderingContext_texImage2D_Callback_RESOLVER_STRING_9_unsigned long_long_unsigned long_long_long_long_unsigned long_unsigned long_ArrayBufferView";

  static $_texImage2D_2_Callback(mthis, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext_texImage2D_Callback_RESOLVER_STRING_6_unsigned long_long_unsigned long_unsigned long_unsigned long_ImageData";

  static $_texImage2D_3_Callback(mthis, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext_texImage2D_Callback_RESOLVER_STRING_6_unsigned long_long_unsigned long_unsigned long_unsigned long_HTMLImageElement";

  static $_texImage2D_4_Callback(mthis, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext_texImage2D_Callback_RESOLVER_STRING_6_unsigned long_long_unsigned long_unsigned long_unsigned long_HTMLCanvasElement";

  static $_texImage2D_5_Callback(mthis, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext_texImage2D_Callback_RESOLVER_STRING_6_unsigned long_long_unsigned long_unsigned long_unsigned long_HTMLVideoElement";

  static $texImage2DCanvas_Callback(mthis, target, level, internalformat, format, type, canvas) native "WebGLRenderingContext_texImage2D_Callback_RESOLVER_STRING_6_unsigned long_long_unsigned long_unsigned long_unsigned long_HTMLCanvasElement";

  static $texImage2DImage_Callback(mthis, target, level, internalformat, format, type, image) native "WebGLRenderingContext_texImage2D_Callback_RESOLVER_STRING_6_unsigned long_long_unsigned long_unsigned long_unsigned long_HTMLImageElement";

  static $texImage2DImageData_Callback(mthis, target, level, internalformat, format, type, pixels) native "WebGLRenderingContext_texImage2D_Callback_RESOLVER_STRING_6_unsigned long_long_unsigned long_unsigned long_unsigned long_ImageData";

  static $texImage2DVideo_Callback(mthis, target, level, internalformat, format, type, video) native "WebGLRenderingContext_texImage2D_Callback_RESOLVER_STRING_6_unsigned long_long_unsigned long_unsigned long_unsigned long_HTMLVideoElement";

  static $texParameterf_Callback(mthis, target, pname, param) native "WebGLRenderingContext_texParameterf_Callback_RESOLVER_STRING_3_unsigned long_unsigned long_float";

  static $texParameteri_Callback(mthis, target, pname, param) native "WebGLRenderingContext_texParameteri_Callback_RESOLVER_STRING_3_unsigned long_unsigned long_long";

  // Generated overload resolver
  static $texSubImage2D(mthis, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video, type, pixels) {
    if ((pixels is TypedData || pixels == null) && (type is int || type == null) && (canvas_OR_format_OR_image_OR_pixels_OR_video is int || canvas_OR_format_OR_image_OR_pixels_OR_video == null) && (height_OR_type is int || height_OR_type == null) && (format_OR_width is int || format_OR_width == null) && (yoffset is int || yoffset == null) && (xoffset is int || xoffset == null) && (level is int || level == null) && (target is int || target == null)) {
      $_texSubImage2D_1_Callback(mthis, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video, type, pixels);
      return;
    }
    if ((canvas_OR_format_OR_image_OR_pixels_OR_video is ImageData || canvas_OR_format_OR_image_OR_pixels_OR_video == null) && (height_OR_type is int || height_OR_type == null) && (format_OR_width is int || format_OR_width == null) && (yoffset is int || yoffset == null) && (xoffset is int || xoffset == null) && (level is int || level == null) && (target is int || target == null) && type == null && pixels == null) {
      $_texSubImage2D_2_Callback(mthis, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((canvas_OR_format_OR_image_OR_pixels_OR_video is ImageElement || canvas_OR_format_OR_image_OR_pixels_OR_video == null) && (height_OR_type is int || height_OR_type == null) && (format_OR_width is int || format_OR_width == null) && (yoffset is int || yoffset == null) && (xoffset is int || xoffset == null) && (level is int || level == null) && (target is int || target == null) && type == null && pixels == null) {
      $_texSubImage2D_3_Callback(mthis, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((canvas_OR_format_OR_image_OR_pixels_OR_video is CanvasElement || canvas_OR_format_OR_image_OR_pixels_OR_video == null) && (height_OR_type is int || height_OR_type == null) && (format_OR_width is int || format_OR_width == null) && (yoffset is int || yoffset == null) && (xoffset is int || xoffset == null) && (level is int || level == null) && (target is int || target == null) && type == null && pixels == null) {
      $_texSubImage2D_4_Callback(mthis, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((canvas_OR_format_OR_image_OR_pixels_OR_video is VideoElement || canvas_OR_format_OR_image_OR_pixels_OR_video == null) && (height_OR_type is int || height_OR_type == null) && (format_OR_width is int || format_OR_width == null) && (yoffset is int || yoffset == null) && (xoffset is int || xoffset == null) && (level is int || level == null) && (target is int || target == null) && type == null && pixels == null) {
      $_texSubImage2D_5_Callback(mthis, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  static $_texSubImage2D_1_Callback(mthis, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video, type, pixels) native "WebGLRenderingContext_texSubImage2D_Callback_RESOLVER_STRING_9_unsigned long_long_long_long_long_long_unsigned long_unsigned long_ArrayBufferView";

  static $_texSubImage2D_2_Callback(mthis, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext_texSubImage2D_Callback_RESOLVER_STRING_7_unsigned long_long_long_long_unsigned long_unsigned long_ImageData";

  static $_texSubImage2D_3_Callback(mthis, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext_texSubImage2D_Callback_RESOLVER_STRING_7_unsigned long_long_long_long_unsigned long_unsigned long_HTMLImageElement";

  static $_texSubImage2D_4_Callback(mthis, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext_texSubImage2D_Callback_RESOLVER_STRING_7_unsigned long_long_long_long_unsigned long_unsigned long_HTMLCanvasElement";

  static $_texSubImage2D_5_Callback(mthis, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext_texSubImage2D_Callback_RESOLVER_STRING_7_unsigned long_long_long_long_unsigned long_unsigned long_HTMLVideoElement";

  static $texSubImage2DCanvas_Callback(mthis, target, level, xoffset, yoffset, format, type, canvas) native "WebGLRenderingContext_texSubImage2D_Callback_RESOLVER_STRING_7_unsigned long_long_long_long_unsigned long_unsigned long_HTMLCanvasElement";

  static $texSubImage2DImage_Callback(mthis, target, level, xoffset, yoffset, format, type, image) native "WebGLRenderingContext_texSubImage2D_Callback_RESOLVER_STRING_7_unsigned long_long_long_long_unsigned long_unsigned long_HTMLImageElement";

  static $texSubImage2DImageData_Callback(mthis, target, level, xoffset, yoffset, format, type, pixels) native "WebGLRenderingContext_texSubImage2D_Callback_RESOLVER_STRING_7_unsigned long_long_long_long_unsigned long_unsigned long_ImageData";

  static $texSubImage2DVideo_Callback(mthis, target, level, xoffset, yoffset, format, type, video) native "WebGLRenderingContext_texSubImage2D_Callback_RESOLVER_STRING_7_unsigned long_long_long_long_unsigned long_unsigned long_HTMLVideoElement";

  static $uniform1f_Callback(mthis, location, x) native "WebGLRenderingContext_uniform1f_Callback_RESOLVER_STRING_2_WebGLUniformLocation_float";

  static $uniform1fv_Callback(mthis, location, v) native "WebGLRenderingContext_uniform1fv_Callback";

  static $uniform1i_Callback(mthis, location, x) native "WebGLRenderingContext_uniform1i_Callback_RESOLVER_STRING_2_WebGLUniformLocation_long";

  static $uniform1iv_Callback(mthis, location, v) native "WebGLRenderingContext_uniform1iv_Callback";

  static $uniform2f_Callback(mthis, location, x, y) native "WebGLRenderingContext_uniform2f_Callback_RESOLVER_STRING_3_WebGLUniformLocation_float_float";

  static $uniform2fv_Callback(mthis, location, v) native "WebGLRenderingContext_uniform2fv_Callback";

  static $uniform2i_Callback(mthis, location, x, y) native "WebGLRenderingContext_uniform2i_Callback_RESOLVER_STRING_3_WebGLUniformLocation_long_long";

  static $uniform2iv_Callback(mthis, location, v) native "WebGLRenderingContext_uniform2iv_Callback";

  static $uniform3f_Callback(mthis, location, x, y, z) native "WebGLRenderingContext_uniform3f_Callback_RESOLVER_STRING_4_WebGLUniformLocation_float_float_float";

  static $uniform3fv_Callback(mthis, location, v) native "WebGLRenderingContext_uniform3fv_Callback";

  static $uniform3i_Callback(mthis, location, x, y, z) native "WebGLRenderingContext_uniform3i_Callback_RESOLVER_STRING_4_WebGLUniformLocation_long_long_long";

  static $uniform3iv_Callback(mthis, location, v) native "WebGLRenderingContext_uniform3iv_Callback";

  static $uniform4f_Callback(mthis, location, x, y, z, w) native "WebGLRenderingContext_uniform4f_Callback_RESOLVER_STRING_5_WebGLUniformLocation_float_float_float_float";

  static $uniform4fv_Callback(mthis, location, v) native "WebGLRenderingContext_uniform4fv_Callback";

  static $uniform4i_Callback(mthis, location, x, y, z, w) native "WebGLRenderingContext_uniform4i_Callback_RESOLVER_STRING_5_WebGLUniformLocation_long_long_long_long";

  static $uniform4iv_Callback(mthis, location, v) native "WebGLRenderingContext_uniform4iv_Callback";

  static $uniformMatrix2fv_Callback(mthis, location, transpose, array) native "WebGLRenderingContext_uniformMatrix2fv_Callback";

  static $uniformMatrix3fv_Callback(mthis, location, transpose, array) native "WebGLRenderingContext_uniformMatrix3fv_Callback";

  static $uniformMatrix4fv_Callback(mthis, location, transpose, array) native "WebGLRenderingContext_uniformMatrix4fv_Callback";

  static $useProgram_Callback(mthis, program) native "WebGLRenderingContext_useProgram_Callback_RESOLVER_STRING_1_WebGLProgram";

  static $validateProgram_Callback(mthis, program) native "WebGLRenderingContext_validateProgram_Callback_RESOLVER_STRING_1_WebGLProgram";

  static $vertexAttrib1f_Callback(mthis, indx, x) native "WebGLRenderingContext_vertexAttrib1f_Callback_RESOLVER_STRING_2_unsigned long_float";

  static $vertexAttrib1fv_Callback(mthis, indx, values) native "WebGLRenderingContext_vertexAttrib1fv_Callback";

  static $vertexAttrib2f_Callback(mthis, indx, x, y) native "WebGLRenderingContext_vertexAttrib2f_Callback_RESOLVER_STRING_3_unsigned long_float_float";

  static $vertexAttrib2fv_Callback(mthis, indx, values) native "WebGLRenderingContext_vertexAttrib2fv_Callback";

  static $vertexAttrib3f_Callback(mthis, indx, x, y, z) native "WebGLRenderingContext_vertexAttrib3f_Callback_RESOLVER_STRING_4_unsigned long_float_float_float";

  static $vertexAttrib3fv_Callback(mthis, indx, values) native "WebGLRenderingContext_vertexAttrib3fv_Callback";

  static $vertexAttrib4f_Callback(mthis, indx, x, y, z, w) native "WebGLRenderingContext_vertexAttrib4f_Callback_RESOLVER_STRING_5_unsigned long_float_float_float_float";

  static $vertexAttrib4fv_Callback(mthis, indx, values) native "WebGLRenderingContext_vertexAttrib4fv_Callback";

  static $vertexAttribPointer_Callback(mthis, indx, size, type, normalized, stride, offset) native "WebGLRenderingContext_vertexAttribPointer_Callback_RESOLVER_STRING_6_unsigned long_long_unsigned long_boolean_long_long long";

  static $viewport_Callback(mthis, x, y, width, height) native "WebGLRenderingContext_viewport_Callback_RESOLVER_STRING_4_long_long_long_long";
}

class BlinkWebGLShader {}

class BlinkWebGLShaderPrecisionFormat {
  static $precision_Getter(mthis) native "WebGLShaderPrecisionFormat_precision_Getter";

  static $rangeMax_Getter(mthis) native "WebGLShaderPrecisionFormat_rangeMax_Getter";

  static $rangeMin_Getter(mthis) native "WebGLShaderPrecisionFormat_rangeMin_Getter";
}

class BlinkWebGLTexture {}

class BlinkWebGLUniformLocation {}

class BlinkWebGLVertexArrayObjectOES {}

class BlinkWebKitAnimationEvent {
  static $animationName_Getter(mthis) native "WebKitAnimationEvent_animationName_Getter";

  static $elapsedTime_Getter(mthis) native "WebKitAnimationEvent_elapsedTime_Getter";
}

class BlinkWebKitCSSFilterRule {
  static $style_Getter(mthis) native "WebKitCSSFilterRule_style_Getter";
}

class BlinkWebKitCSSFilterValue {}

class BlinkWebKitCSSMatrix {
  // Generated overload resolver
  static $mk_WebKitCSSMatrix(cssValue) {
    return $_create_1constructorCallback(cssValue);
  }

  static $_create_1constructorCallback(cssValue) native "WebKitCSSMatrix_constructorCallback_RESOLVER_STRING_1_DOMString";
}

class BlinkWebKitCSSTransformValue {}

class BlinkWebKitMediaSource {
  // Generated overload resolver
  static $mk_WebKitMediaSource() {
    return $_create_1constructorCallback();
  }

  static $_create_1constructorCallback() native "WebKitMediaSource_constructorCallback_RESOLVER_STRING_0_";
}

class BlinkWebKitNotification {}

class BlinkWebKitPoint {
  static $constructorCallback(x, y) native "WebKitPoint_constructorCallback";

  static $x_Getter(mthis) native "WebKitPoint_x_Getter";

  static $x_Setter(mthis, value) native "WebKitPoint_x_Setter";

  static $y_Getter(mthis) native "WebKitPoint_y_Getter";

  static $y_Setter(mthis, value) native "WebKitPoint_y_Setter";
}

class BlinkWebKitSourceBuffer {}

class BlinkWebKitSourceBufferList {
  static $item_Callback(mthis, index) native "WebKitSourceBufferList_item_Callback_RESOLVER_STRING_1_unsigned long";
}

class BlinkWebSocket {
  // Generated overload resolver
  static $mkWebSocket(url, protocol_OR_protocols) {
    if ((url is String || url == null) && protocol_OR_protocols == null) {
      return $_create_1constructorCallback(url);
    }
    if ((protocol_OR_protocols is List<String> || protocol_OR_protocols == null) && (url is String || url == null)) {
      return $_create_2constructorCallback(url, protocol_OR_protocols);
    }
    if ((protocol_OR_protocols is String || protocol_OR_protocols == null) && (url is String || url == null)) {
      return $_create_3constructorCallback(url, protocol_OR_protocols);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  static $_create_1constructorCallback(url) native "WebSocket_constructorCallback_RESOLVER_STRING_1_DOMString";

  static $_create_2constructorCallback(url, protocol_OR_protocols) native "WebSocket_constructorCallback_RESOLVER_STRING_2_DOMString_sequence<DOMString>";

  static $_create_3constructorCallback(url, protocol_OR_protocols) native "WebSocket_constructorCallback_RESOLVER_STRING_2_DOMString_DOMString";

  static $binaryType_Getter(mthis) native "WebSocket_binaryType_Getter";

  static $binaryType_Setter(mthis, value) native "WebSocket_binaryType_Setter";

  static $bufferedAmount_Getter(mthis) native "WebSocket_bufferedAmount_Getter";

  static $extensions_Getter(mthis) native "WebSocket_extensions_Getter";

  static $protocol_Getter(mthis) native "WebSocket_protocol_Getter";

  static $readyState_Getter(mthis) native "WebSocket_readyState_Getter";

  static $url_Getter(mthis) native "WebSocket_url_Getter";

  // Generated overload resolver
  static $close(mthis, code, reason) {
    if (reason != null) {
      $_close_1_Callback(mthis, code, reason);
      return;
    }
    if (code != null) {
      $_close_2_Callback(mthis, code);
      return;
    }
    $_close_3_Callback(mthis);
    return;
  }

  static $_close_1_Callback(mthis, code, reason) native "WebSocket_close_Callback_RESOLVER_STRING_2_unsigned short_DOMString";

  static $_close_2_Callback(mthis, code) native "WebSocket_close_Callback_RESOLVER_STRING_1_unsigned short";

  static $_close_3_Callback(mthis) native "WebSocket_close_Callback_RESOLVER_STRING_0_";

  // Generated overload resolver
  static $send(mthis, data) {
    if ((data is TypedData || data == null)) {
      $_send_1_Callback(mthis, data);
      return;
    }
    if ((data is ByteBuffer || data == null)) {
      $_send_2_Callback(mthis, data);
      return;
    }
    if ((data is Blob || data == null)) {
      $_send_3_Callback(mthis, data);
      return;
    }
    if ((data is String || data == null)) {
      $_send_4_Callback(mthis, data);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  static $_send_1_Callback(mthis, data) native "WebSocket_send_Callback_RESOLVER_STRING_1_ArrayBufferView";

  static $_send_2_Callback(mthis, data) native "WebSocket_send_Callback_RESOLVER_STRING_1_ArrayBuffer";

  static $_send_3_Callback(mthis, data) native "WebSocket_send_Callback_RESOLVER_STRING_1_Blob";

  static $_send_4_Callback(mthis, data) native "WebSocket_send_Callback_RESOLVER_STRING_1_DOMString";

  static $sendBlob_Callback(mthis, data) native "WebSocket_send_Callback_RESOLVER_STRING_1_Blob";

  static $sendByteBuffer_Callback(mthis, data) native "WebSocket_send_Callback_RESOLVER_STRING_1_ArrayBuffer";

  static $sendString_Callback(mthis, data) native "WebSocket_send_Callback_RESOLVER_STRING_1_DOMString";

  static $sendTypedData_Callback(mthis, data) native "WebSocket_send_Callback_RESOLVER_STRING_1_ArrayBufferView";
}

class BlinkWheelEvent {
  static $deltaMode_Getter(mthis) native "WheelEvent_deltaMode_Getter";

  static $deltaX_Getter(mthis) native "WheelEvent_deltaX_Getter";

  static $deltaY_Getter(mthis) native "WheelEvent_deltaY_Getter";

  static $deltaZ_Getter(mthis) native "WheelEvent_deltaZ_Getter";

  static $webkitDirectionInvertedFromDevice_Getter(mthis) native "WheelEvent_webkitDirectionInvertedFromDevice_Getter";

  static $wheelDeltaX_Getter(mthis) native "WheelEvent_wheelDeltaX_Getter";

  static $wheelDeltaY_Getter(mthis) native "WheelEvent_wheelDeltaY_Getter";

  static $initWebKitWheelEvent_Callback(mthis, wheelDeltaX, wheelDeltaY, view, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey) native "WheelEvent_initWebKitWheelEvent_Callback_RESOLVER_STRING_11_long_long_Window_long_long_long_long_boolean_boolean_boolean_boolean";
}

class BlinkWindow {
  static $CSS_Getter(mthis) native "Window_CSS_Getter";

  static $applicationCache_Getter(mthis) native "Window_applicationCache_Getter";

  static $closed_Getter(mthis) native "Window_closed_Getter";

  static $console_Getter(mthis) native "Window_console_Getter";

  static $crypto_Getter(mthis) native "Window_crypto_Getter";

  static $defaultStatus_Getter(mthis) native "Window_defaultStatus_Getter";

  static $defaultStatus_Setter(mthis, value) native "Window_defaultStatus_Setter";

  static $defaultstatus_Getter(mthis) native "Window_defaultstatus_Getter";

  static $defaultstatus_Setter(mthis, value) native "Window_defaultstatus_Setter";

  static $devicePixelRatio_Getter(mthis) native "Window_devicePixelRatio_Getter";

  static $document_Getter(mthis) native "Window_document_Getter";

  static $history_Getter(mthis) native "Window_history_Getter";

  static $indexedDB_Getter(mthis) native "Window_indexedDB_Getter";

  static $innerHeight_Getter(mthis) native "Window_innerHeight_Getter";

  static $innerWidth_Getter(mthis) native "Window_innerWidth_Getter";

  static $localStorage_Getter(mthis) native "Window_localStorage_Getter";

  static $location_Getter(mthis) native "Window_location_Getter";

  static $locationbar_Getter(mthis) native "Window_locationbar_Getter";

  static $menubar_Getter(mthis) native "Window_menubar_Getter";

  static $name_Getter(mthis) native "Window_name_Getter";

  static $name_Setter(mthis, value) native "Window_name_Setter";

  static $navigator_Getter(mthis) native "Window_navigator_Getter";

  static $offscreenBuffering_Getter(mthis) native "Window_offscreenBuffering_Getter";

  static $opener_Getter(mthis) native "Window_opener_Getter";

  static $opener_Setter(mthis, value) native "Window_opener_Setter";

  static $orientation_Getter(mthis) native "Window_orientation_Getter";

  static $outerHeight_Getter(mthis) native "Window_outerHeight_Getter";

  static $outerWidth_Getter(mthis) native "Window_outerWidth_Getter";

  static $pageXOffset_Getter(mthis) native "Window_pageXOffset_Getter";

  static $pageYOffset_Getter(mthis) native "Window_pageYOffset_Getter";

  static $parent_Getter(mthis) native "Window_parent_Getter";

  static $performance_Getter(mthis) native "Window_performance_Getter";

  static $screen_Getter(mthis) native "Window_screen_Getter";

  static $screenLeft_Getter(mthis) native "Window_screenLeft_Getter";

  static $screenTop_Getter(mthis) native "Window_screenTop_Getter";

  static $screenX_Getter(mthis) native "Window_screenX_Getter";

  static $screenY_Getter(mthis) native "Window_screenY_Getter";

  static $scrollX_Getter(mthis) native "Window_scrollX_Getter";

  static $scrollY_Getter(mthis) native "Window_scrollY_Getter";

  static $scrollbars_Getter(mthis) native "Window_scrollbars_Getter";

  static $self_Getter(mthis) native "Window_self_Getter";

  static $sessionStorage_Getter(mthis) native "Window_sessionStorage_Getter";

  static $speechSynthesis_Getter(mthis) native "Window_speechSynthesis_Getter";

  static $status_Getter(mthis) native "Window_status_Getter";

  static $status_Setter(mthis, value) native "Window_status_Setter";

  static $statusbar_Getter(mthis) native "Window_statusbar_Getter";

  static $styleMedia_Getter(mthis) native "Window_styleMedia_Getter";

  static $toolbar_Getter(mthis) native "Window_toolbar_Getter";

  static $top_Getter(mthis) native "Window_top_Getter";

  static $window_Getter(mthis) native "Window_window_Getter";

  // Generated overload resolver
  static $__getter__(mthis, index_OR_name) {
    if ((index_OR_name is int || index_OR_name == null)) {
      return $___getter___1_Callback(mthis, index_OR_name);
    }
    if ((index_OR_name is String || index_OR_name == null)) {
      return $___getter___2_Callback(mthis, index_OR_name);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  static $___getter___1_Callback(mthis, index_OR_name) native "Window___getter___Callback_RESOLVER_STRING_1_unsigned long";

  static $___getter___2_Callback(mthis, index_OR_name) native "Window___getter___Callback";

  static $alert_Callback(mthis, message) native "Window_alert_Callback_RESOLVER_STRING_1_DOMString";

  static $cancelAnimationFrame_Callback(mthis, id) native "Window_cancelAnimationFrame_Callback_RESOLVER_STRING_1_long";

  static $close_Callback(mthis) native "Window_close_Callback_RESOLVER_STRING_0_";

  static $confirm_Callback(mthis, message) native "Window_confirm_Callback_RESOLVER_STRING_1_DOMString";

  static $find_Callback(mthis, string, caseSensitive, backwards, wrap, wholeWord, searchInFrames, showDialog) native "Window_find_Callback_RESOLVER_STRING_7_DOMString_boolean_boolean_boolean_boolean_boolean_boolean";

  static $getComputedStyle_Callback(mthis, element, pseudoElement) native "Window_getComputedStyle_Callback_RESOLVER_STRING_2_Element_DOMString";

  static $getMatchedCSSRules_Callback(mthis, element, pseudoElement) native "Window_getMatchedCSSRules_Callback_RESOLVER_STRING_2_Element_DOMString";

  static $getSelection_Callback(mthis) native "Window_getSelection_Callback_RESOLVER_STRING_0_";

  static $matchMedia_Callback(mthis, query) native "Window_matchMedia_Callback_RESOLVER_STRING_1_DOMString";

  static $moveBy_Callback(mthis, x, y) native "Window_moveBy_Callback_RESOLVER_STRING_2_float_float";

  static $moveTo_Callback(mthis, x, y) native "Window_moveTo_Callback_RESOLVER_STRING_2_float_float";

  static $open_Callback(mthis, url, name, options) native "Window_open_Callback";

  static $openDatabase_Callback(mthis, name, version, displayName, estimatedSize, creationCallback) native "Window_openDatabase_Callback_RESOLVER_STRING_5_DOMString_DOMString_DOMString_unsigned long_DatabaseCallback";

  static $postMessage_Callback(mthis, message, targetOrigin, messagePorts) native "Window_postMessage_Callback";

  static $print_Callback(mthis) native "Window_print_Callback_RESOLVER_STRING_0_";

  static $requestAnimationFrame_Callback(mthis, callback) native "Window_requestAnimationFrame_Callback_RESOLVER_STRING_1_RequestAnimationFrameCallback";

  static $resizeBy_Callback(mthis, x, y) native "Window_resizeBy_Callback_RESOLVER_STRING_2_float_float";

  static $resizeTo_Callback(mthis, width, height) native "Window_resizeTo_Callback_RESOLVER_STRING_2_float_float";

  static $scroll_Callback(mthis, x, y, scrollOptions) native "Window_scroll_Callback_RESOLVER_STRING_3_long_long_Dictionary";

  static $scrollBy_Callback(mthis, x, y, scrollOptions) native "Window_scrollBy_Callback_RESOLVER_STRING_3_long_long_Dictionary";

  static $scrollTo_Callback(mthis, x, y, scrollOptions) native "Window_scrollTo_Callback_RESOLVER_STRING_3_long_long_Dictionary";

  static $showModalDialog_Callback(mthis, url, dialogArgs, featureArgs) native "Window_showModalDialog_Callback";

  static $stop_Callback(mthis) native "Window_stop_Callback_RESOLVER_STRING_0_";

  static $toString_Callback(mthis) native "Window_toString_Callback";

  static $webkitConvertPointFromNodeToPage_Callback(mthis, node, p) native "Window_webkitConvertPointFromNodeToPage_Callback_RESOLVER_STRING_2_Node_WebKitPoint";

  static $webkitConvertPointFromPageToNode_Callback(mthis, node, p) native "Window_webkitConvertPointFromPageToNode_Callback_RESOLVER_STRING_2_Node_WebKitPoint";

  static $webkitRequestFileSystem_Callback(mthis, type, size, successCallback, errorCallback) native "Window_webkitRequestFileSystem_Callback_RESOLVER_STRING_4_unsigned short_long long_FileSystemCallback_ErrorCallback";

  static $webkitResolveLocalFileSystemURL_Callback(mthis, url, successCallback, errorCallback) native "Window_webkitResolveLocalFileSystemURL_Callback_RESOLVER_STRING_3_DOMString_EntryCallback_ErrorCallback";

  static $atob_Callback(mthis, string) native "Window_atob_Callback_RESOLVER_STRING_1_DOMString";

  static $btoa_Callback(mthis, string) native "Window_btoa_Callback_RESOLVER_STRING_1_DOMString";

  static $clearInterval_Callback(mthis, handle) native "Window_clearInterval_Callback_RESOLVER_STRING_1_long";

  static $clearTimeout_Callback(mthis, handle) native "Window_clearTimeout_Callback_RESOLVER_STRING_1_long";

  static $setInterval_Callback(mthis, handler, timeout) native "Window_setInterval_Callback";

  static $setTimeout_Callback(mthis, handler, timeout) native "Window_setTimeout_Callback";
}

class BlinkWorker {
  // Generated overload resolver
  static $mkWorker(scriptUrl) {
    return $_create_1constructorCallback(scriptUrl);
  }

  static $_create_1constructorCallback(scriptUrl) native "Worker_constructorCallback_RESOLVER_STRING_1_DOMString";

  static $postMessage_Callback(mthis, message, messagePorts) native "Worker_postMessage_Callback";

  static $terminate_Callback(mthis) native "Worker_terminate_Callback_RESOLVER_STRING_0_";
}

class BlinkWorkerConsole {}

class BlinkWorkerCrypto {}

class BlinkWorkerLocation {}

class BlinkWorkerNavigator {}

class BlinkWorkerPerformance {
  static $now_Callback(mthis) native "WorkerPerformance_now_Callback_RESOLVER_STRING_0_";
}

class BlinkXMLDocument {}

class BlinkXMLHttpRequestEventTarget {}

class BlinkXMLHttpRequest {
  static $constructorCallback() native "XMLHttpRequest_constructorCallback";

  static $readyState_Getter(mthis) native "XMLHttpRequest_readyState_Getter";

  static $response_Getter(mthis) native "XMLHttpRequest_response_Getter";

  static $responseText_Getter(mthis) native "XMLHttpRequest_responseText_Getter";

  static $responseType_Getter(mthis) native "XMLHttpRequest_responseType_Getter";

  static $responseType_Setter(mthis, value) native "XMLHttpRequest_responseType_Setter";

  static $responseXML_Getter(mthis) native "XMLHttpRequest_responseXML_Getter";

  static $status_Getter(mthis) native "XMLHttpRequest_status_Getter";

  static $statusText_Getter(mthis) native "XMLHttpRequest_statusText_Getter";

  static $timeout_Getter(mthis) native "XMLHttpRequest_timeout_Getter";

  static $timeout_Setter(mthis, value) native "XMLHttpRequest_timeout_Setter";

  static $upload_Getter(mthis) native "XMLHttpRequest_upload_Getter";

  static $withCredentials_Getter(mthis) native "XMLHttpRequest_withCredentials_Getter";

  static $withCredentials_Setter(mthis, value) native "XMLHttpRequest_withCredentials_Setter";

  static $abort_Callback(mthis) native "XMLHttpRequest_abort_Callback_RESOLVER_STRING_0_";

  static $getAllResponseHeaders_Callback(mthis) native "XMLHttpRequest_getAllResponseHeaders_Callback_RESOLVER_STRING_0_";

  static $getResponseHeader_Callback(mthis, header) native "XMLHttpRequest_getResponseHeader_Callback_RESOLVER_STRING_1_DOMString";

  static $open_Callback(mthis, method, url, async, user, password) native "XMLHttpRequest_open_Callback";

  static $overrideMimeType_Callback(mthis, override) native "XMLHttpRequest_overrideMimeType_Callback_RESOLVER_STRING_1_DOMString";

  static $send_Callback(mthis, data) native "XMLHttpRequest_send_Callback";

  static $setRequestHeader_Callback(mthis, header, value) native "XMLHttpRequest_setRequestHeader_Callback_RESOLVER_STRING_2_DOMString_DOMString";
}

class BlinkXMLHttpRequestProgressEvent {}

class BlinkXMLHttpRequestUpload {}

class BlinkXMLSerializer {
  // Generated overload resolver
  static $mkXmlSerializer() {
    return $_create_1constructorCallback();
  }

  static $_create_1constructorCallback() native "XMLSerializer_constructorCallback_RESOLVER_STRING_0_";

  static $serializeToString_Callback(mthis, node) native "XMLSerializer_serializeToString_Callback_RESOLVER_STRING_1_Node";
}

class BlinkXPathEvaluator {
  // Generated overload resolver
  static $mkXPathEvaluator() {
    return $_create_1constructorCallback();
  }

  static $_create_1constructorCallback() native "XPathEvaluator_constructorCallback_RESOLVER_STRING_0_";

  static $createExpression_Callback(mthis, expression, resolver) native "XPathEvaluator_createExpression_Callback_RESOLVER_STRING_2_DOMString_XPathNSResolver";

  static $createNSResolver_Callback(mthis, nodeResolver) native "XPathEvaluator_createNSResolver_Callback_RESOLVER_STRING_1_Node";

  static $evaluate_Callback(mthis, expression, contextNode, resolver, type, inResult) native "XPathEvaluator_evaluate_Callback_RESOLVER_STRING_5_DOMString_Node_XPathNSResolver_unsigned short_XPathResult";
}

class BlinkXPathExpression {
  static $evaluate_Callback(mthis, contextNode, type, inResult) native "XPathExpression_evaluate_Callback_RESOLVER_STRING_3_Node_unsigned short_XPathResult";
}

class BlinkXPathNSResolver {
  static $lookupNamespaceURI_Callback(mthis, prefix) native "XPathNSResolver_lookupNamespaceURI_Callback_RESOLVER_STRING_1_DOMString";
}

class BlinkXPathResult {
  static $booleanValue_Getter(mthis) native "XPathResult_booleanValue_Getter";

  static $invalidIteratorState_Getter(mthis) native "XPathResult_invalidIteratorState_Getter";

  static $numberValue_Getter(mthis) native "XPathResult_numberValue_Getter";

  static $resultType_Getter(mthis) native "XPathResult_resultType_Getter";

  static $singleNodeValue_Getter(mthis) native "XPathResult_singleNodeValue_Getter";

  static $snapshotLength_Getter(mthis) native "XPathResult_snapshotLength_Getter";

  static $stringValue_Getter(mthis) native "XPathResult_stringValue_Getter";

  static $iterateNext_Callback(mthis) native "XPathResult_iterateNext_Callback_RESOLVER_STRING_0_";

  static $snapshotItem_Callback(mthis, index) native "XPathResult_snapshotItem_Callback_RESOLVER_STRING_1_unsigned long";
}

class BlinkXSLTProcessor {
  // Generated overload resolver
  static $mkXsltProcessor() {
    return $_create_1constructorCallback();
  }

  static $_create_1constructorCallback() native "XSLTProcessor_constructorCallback_RESOLVER_STRING_0_";

  static $clearParameters_Callback(mthis) native "XSLTProcessor_clearParameters_Callback_RESOLVER_STRING_0_";

  static $getParameter_Callback(mthis, namespaceURI, localName) native "XSLTProcessor_getParameter_Callback";

  static $importStylesheet_Callback(mthis, stylesheet) native "XSLTProcessor_importStylesheet_Callback_RESOLVER_STRING_1_Node";

  static $removeParameter_Callback(mthis, namespaceURI, localName) native "XSLTProcessor_removeParameter_Callback";

  static $reset_Callback(mthis) native "XSLTProcessor_reset_Callback_RESOLVER_STRING_0_";

  static $setParameter_Callback(mthis, namespaceURI, localName, value) native "XSLTProcessor_setParameter_Callback";

  static $transformToDocument_Callback(mthis, source) native "XSLTProcessor_transformToDocument_Callback_RESOLVER_STRING_1_Node";

  static $transformToFragment_Callback(mthis, source, docVal) native "XSLTProcessor_transformToFragment_Callback_RESOLVER_STRING_2_Node_Document";
}


// TODO(vsm): This should be moved out of this library.  Into dart:html?
Type _getType(String key) {
  // TODO(vsm): Add Cross Frame and JS types here as well.
  if (htmlBlinkMap.containsKey(key))
    return htmlBlinkMap[key]();
  if (indexed_dbBlinkMap.containsKey(key))
    return indexed_dbBlinkMap[key]();
  if (web_audioBlinkMap.containsKey(key))
    return web_audioBlinkMap[key]();
  if (web_glBlinkMap.containsKey(key))
    return web_glBlinkMap[key]();
  if (web_sqlBlinkMap.containsKey(key))
    return web_sqlBlinkMap[key]();
  if (svgBlinkMap.containsKey(key))
    return svgBlinkMap[key]();
  return null;
}// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// _Utils native entry points
class Blink_Utils {
  static window() native "Utils_window";

  static forwardingPrint(message) native "Utils_forwardingPrint";

  static spawnDomUri(uri) native "Utils_spawnDomUri";

  static register(document, tag, customType, extendsTagName) native "Utils_register";

  static createElement(document, tagName) native "Utils_createElement";

  static initializeCustomElement(element) native "Utils_initializeCustomElement";

  static changeElementWrapper(element, type) native "Utils_changeElementWrapper";
}

class Blink_DOMWindowCrossFrame {
  // FIXME: Return to using explicit cross frame entry points after roll to M35
  static get_history(_DOMWindowCrossFrame) native "Window_history_cross_frame_Getter";

  static get_location(_DOMWindowCrossFrame) native "Window_location_cross_frame_Getter";

  static get_closed(_DOMWindowCrossFrame) native "Window_closed_Getter";

  static get_opener(_DOMWindowCrossFrame) native "Window_opener_Getter";

  static get_parent(_DOMWindowCrossFrame) native "Window_parent_Getter";

  static get_top(_DOMWindowCrossFrame) native "Window_top_Getter";

  static close(_DOMWindowCrossFrame) native "Window_close_Callback_RESOLVER_STRING_0_";

  static postMessage(_DOMWindowCrossFrame, message, targetOrigin, [messagePorts]) native "Window_postMessage_Callback";
}

class Blink_HistoryCrossFrame {
  // _HistoryCrossFrame native entry points
  static back(_HistoryCrossFrame) native "History_back_Callback_RESOLVER_STRING_0_";

  static forward(_HistoryCrossFrame) native "History_forward_Callback_RESOLVER_STRING_0_";

  static go(_HistoryCrossFrame, distance) native "History_go_Callback_RESOLVER_STRING_1_long";
}

class Blink_LocationCrossFrame {
  // _LocationCrossFrame native entry points
  static set_href(_LocationCrossFrame, h) native "Location_href_Setter";
}

class Blink_DOMStringMap {
  // _DOMStringMap native entry  points
  static containsKey(_DOMStringMap, key) native "DOMStringMap_containsKey_Callback";

  static item(_DOMStringMap, key) native "DOMStringMap_item_Callback";

  static setItem(_DOMStringMap, key, value) native "DOMStringMap_setItem_Callback";

  static remove(_DOMStringMap, key) native "DOMStringMap_remove_Callback";

  static get_keys(_DOMStringMap) native "DOMStringMap_getKeys_Callback";
}