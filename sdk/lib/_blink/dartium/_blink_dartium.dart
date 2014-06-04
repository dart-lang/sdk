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



Native_ANGLEInstancedArrays_drawArraysInstancedANGLE_Callback(mthis, mode, first, count, primcount) native "ANGLEInstancedArrays_drawArraysInstancedANGLE_Callback_RESOLVER_STRING_4_unsigned long_long_long_long";

Native_ANGLEInstancedArrays_drawElementsInstancedANGLE_Callback(mthis, mode, count, type, offset, primcount) native "ANGLEInstancedArrays_drawElementsInstancedANGLE_Callback_RESOLVER_STRING_5_unsigned long_long_unsigned long_long long_long";

Native_ANGLEInstancedArrays_vertexAttribDivisorANGLE_Callback(mthis, index, divisor) native "ANGLEInstancedArrays_vertexAttribDivisorANGLE_Callback_RESOLVER_STRING_2_unsigned long_long";

Native_Algorithm_name_Getter(mthis) native "KeyAlgorithm_name_Getter";

Native_EventTarget_addEventListener_Callback(mthis, type, listener, useCapture) native "EventTarget_addEventListener_Callback_RESOLVER_STRING_3_DOMString_EventListener_boolean";

Native_EventTarget_dispatchEvent_Callback(mthis, event) native "EventTarget_dispatchEvent_Callback_RESOLVER_STRING_1_Event";

Native_EventTarget_removeEventListener_Callback(mthis, type, listener, useCapture) native "EventTarget_removeEventListener_Callback_RESOLVER_STRING_3_DOMString_EventListener_boolean";

Native_AudioNode_channelCount_Getter(mthis) native "AudioNode_channelCount_Getter";

Native_AudioNode_channelCount_Setter(mthis, value) native "AudioNode_channelCount_Setter";

Native_AudioNode_channelCountMode_Getter(mthis) native "AudioNode_channelCountMode_Getter";

Native_AudioNode_channelCountMode_Setter(mthis, value) native "AudioNode_channelCountMode_Setter";

Native_AudioNode_channelInterpretation_Getter(mthis) native "AudioNode_channelInterpretation_Getter";

Native_AudioNode_channelInterpretation_Setter(mthis, value) native "AudioNode_channelInterpretation_Setter";

Native_AudioNode_context_Getter(mthis) native "AudioNode_context_Getter";

Native_AudioNode_numberOfInputs_Getter(mthis) native "AudioNode_numberOfInputs_Getter";

Native_AudioNode_numberOfOutputs_Getter(mthis) native "AudioNode_numberOfOutputs_Getter";

  // Generated overload resolver
Native_AudioNode__connect(mthis, destination, output, input) {
    if ((input is int || input == null) && (output is int || output == null) && (destination is AudioNode || destination == null)) {
      Native_AudioNode__connect_1_Callback(mthis, destination, output, input);
      return;
    }
    if ((output is int || output == null) && (destination is AudioParam || destination == null) && input == null) {
      Native_AudioNode__connect_2_Callback(mthis, destination, output);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

Native_AudioNode__connect_1_Callback(mthis, destination, output, input) native "AudioNode_connect_Callback_RESOLVER_STRING_3_AudioNode_unsigned long_unsigned long";

Native_AudioNode__connect_2_Callback(mthis, destination, output) native "AudioNode_connect_Callback_RESOLVER_STRING_2_AudioParam_unsigned long";

Native_AudioNode_disconnect_Callback(mthis, output) native "AudioNode_disconnect_Callback_RESOLVER_STRING_1_unsigned long";

Native_AnalyserNode_fftSize_Getter(mthis) native "AnalyserNode_fftSize_Getter";

Native_AnalyserNode_fftSize_Setter(mthis, value) native "AnalyserNode_fftSize_Setter";

Native_AnalyserNode_frequencyBinCount_Getter(mthis) native "AnalyserNode_frequencyBinCount_Getter";

Native_AnalyserNode_maxDecibels_Getter(mthis) native "AnalyserNode_maxDecibels_Getter";

Native_AnalyserNode_maxDecibels_Setter(mthis, value) native "AnalyserNode_maxDecibels_Setter";

Native_AnalyserNode_minDecibels_Getter(mthis) native "AnalyserNode_minDecibels_Getter";

Native_AnalyserNode_minDecibels_Setter(mthis, value) native "AnalyserNode_minDecibels_Setter";

Native_AnalyserNode_smoothingTimeConstant_Getter(mthis) native "AnalyserNode_smoothingTimeConstant_Getter";

Native_AnalyserNode_smoothingTimeConstant_Setter(mthis, value) native "AnalyserNode_smoothingTimeConstant_Setter";

Native_AnalyserNode_getByteFrequencyData_Callback(mthis, array) native "AnalyserNode_getByteFrequencyData_Callback_RESOLVER_STRING_1_Uint8Array";

Native_AnalyserNode_getByteTimeDomainData_Callback(mthis, array) native "AnalyserNode_getByteTimeDomainData_Callback_RESOLVER_STRING_1_Uint8Array";

Native_AnalyserNode_getFloatFrequencyData_Callback(mthis, array) native "AnalyserNode_getFloatFrequencyData_Callback_RESOLVER_STRING_1_Float32Array";

Native_TimedItem_activeDuration_Getter(mthis) native "TimedItem_activeDuration_Getter";

Native_TimedItem_currentIteration_Getter(mthis) native "TimedItem_currentIteration_Getter";

Native_TimedItem_duration_Getter(mthis) native "TimedItem_duration_Getter";

Native_TimedItem_endTime_Getter(mthis) native "TimedItem_endTime_Getter";

Native_TimedItem_localTime_Getter(mthis) native "TimedItem_localTime_Getter";

Native_TimedItem_player_Getter(mthis) native "TimedItem_player_Getter";

Native_TimedItem_specified_Getter(mthis) native "TimedItem_specified_Getter";

Native_TimedItem_startTime_Getter(mthis) native "TimedItem_startTime_Getter";

  // Generated overload resolver
Native_Animation_Animation(target, keyframes, timingInput) {
    if ((timingInput is Map || timingInput == null) && (keyframes is List<Map> || keyframes == null) && (target is Element || target == null)) {
      return Native_Animation__create_1constructorCallback(target, keyframes, timingInput);
    }
    if ((timingInput is num || timingInput == null) && (keyframes is List<Map> || keyframes == null) && (target is Element || target == null)) {
      return Native_Animation__create_2constructorCallback(target, keyframes, timingInput);
    }
    if ((keyframes is List<Map> || keyframes == null) && (target is Element || target == null) && timingInput == null) {
      return Native_Animation__create_3constructorCallback(target, keyframes);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

Native_Animation__create_1constructorCallback(target, keyframes, timingInput) native "Animation_constructorCallback_RESOLVER_STRING_3_Element_sequence<Dictionary>_Dictionary";

Native_Animation__create_2constructorCallback(target, keyframes, timingInput) native "Animation_constructorCallback_RESOLVER_STRING_3_Element_sequence<Dictionary>_double";

Native_Animation__create_3constructorCallback(target, keyframes) native "Animation_constructorCallback_RESOLVER_STRING_2_Element_sequence<Dictionary>";

Native_ApplicationCache_status_Getter(mthis) native "ApplicationCache_status_Getter";

Native_ApplicationCache_abort_Callback(mthis) native "ApplicationCache_abort_Callback_RESOLVER_STRING_0_";

Native_ApplicationCache_swapCache_Callback(mthis) native "ApplicationCache_swapCache_Callback_RESOLVER_STRING_0_";

Native_ApplicationCache_update_Callback(mthis) native "ApplicationCache_update_Callback_RESOLVER_STRING_0_";

Native_Node_baseURI_Getter(mthis) native "Node_baseURI_Getter";

Native_Node_childNodes_Getter(mthis) native "Node_childNodes_Getter";

Native_Node_firstChild_Getter(mthis) native "Node_firstChild_Getter";

Native_Node_lastChild_Getter(mthis) native "Node_lastChild_Getter";

Native_Node_localName_Getter(mthis) native "Node_localName_Getter";

Native_Node_namespaceURI_Getter(mthis) native "Node_namespaceURI_Getter";

Native_Node_nextSibling_Getter(mthis) native "Node_nextSibling_Getter";

Native_Node_nodeName_Getter(mthis) native "Node_nodeName_Getter";

Native_Node_nodeType_Getter(mthis) native "Node_nodeType_Getter";

Native_Node_nodeValue_Getter(mthis) native "Node_nodeValue_Getter";

Native_Node_ownerDocument_Getter(mthis) native "Node_ownerDocument_Getter";

Native_Node_parentElement_Getter(mthis) native "Node_parentElement_Getter";

Native_Node_parentNode_Getter(mthis) native "Node_parentNode_Getter";

Native_Node_previousSibling_Getter(mthis) native "Node_previousSibling_Getter";

Native_Node_textContent_Getter(mthis) native "Node_textContent_Getter";

Native_Node_textContent_Setter(mthis, value) native "Node_textContent_Setter";

Native_Node_appendChild_Callback(mthis, newChild) native "Node_appendChild_Callback";

Native_Node_cloneNode_Callback(mthis, deep) native "Node_cloneNode_Callback";

Native_Node_contains_Callback(mthis, other) native "Node_contains_Callback_RESOLVER_STRING_1_Node";

Native_Node_hasChildNodes_Callback(mthis) native "Node_hasChildNodes_Callback_RESOLVER_STRING_0_";

Native_Node_insertBefore_Callback(mthis, newChild, refChild) native "Node_insertBefore_Callback";

Native_Node_removeChild_Callback(mthis, oldChild) native "Node_removeChild_Callback";

Native_Node_replaceChild_Callback(mthis, newChild, oldChild) native "Node_replaceChild_Callback";

Native_Attr_localName_Getter(mthis) native "Attr_localName_Getter";

Native_Attr_name_Getter(mthis) native "Attr_name_Getter";

Native_Attr_namespaceURI_Getter(mthis) native "Attr_namespaceURI_Getter";

Native_Attr_value_Getter(mthis) native "Attr_value_Getter";

Native_Attr_value_Setter(mthis, value) native "Attr_value_Setter";

Native_AudioBuffer_duration_Getter(mthis) native "AudioBuffer_duration_Getter";

Native_AudioBuffer_gain_Getter(mthis) native "AudioBuffer_gain_Getter";

Native_AudioBuffer_gain_Setter(mthis, value) native "AudioBuffer_gain_Setter";

Native_AudioBuffer_length_Getter(mthis) native "AudioBuffer_length_Getter";

Native_AudioBuffer_numberOfChannels_Getter(mthis) native "AudioBuffer_numberOfChannels_Getter";

Native_AudioBuffer_sampleRate_Getter(mthis) native "AudioBuffer_sampleRate_Getter";

Native_AudioBuffer_getChannelData_Callback(mthis, channelIndex) native "AudioBuffer_getChannelData_Callback_RESOLVER_STRING_1_unsigned long";

Native_AudioBufferSourceNode_buffer_Getter(mthis) native "AudioBufferSourceNode_buffer_Getter";

Native_AudioBufferSourceNode_buffer_Setter(mthis, value) native "AudioBufferSourceNode_buffer_Setter";

Native_AudioBufferSourceNode_gain_Getter(mthis) native "AudioBufferSourceNode_gain_Getter";

Native_AudioBufferSourceNode_loop_Getter(mthis) native "AudioBufferSourceNode_loop_Getter";

Native_AudioBufferSourceNode_loop_Setter(mthis, value) native "AudioBufferSourceNode_loop_Setter";

Native_AudioBufferSourceNode_loopEnd_Getter(mthis) native "AudioBufferSourceNode_loopEnd_Getter";

Native_AudioBufferSourceNode_loopEnd_Setter(mthis, value) native "AudioBufferSourceNode_loopEnd_Setter";

Native_AudioBufferSourceNode_loopStart_Getter(mthis) native "AudioBufferSourceNode_loopStart_Getter";

Native_AudioBufferSourceNode_loopStart_Setter(mthis, value) native "AudioBufferSourceNode_loopStart_Setter";

Native_AudioBufferSourceNode_playbackRate_Getter(mthis) native "AudioBufferSourceNode_playbackRate_Getter";

Native_AudioBufferSourceNode_playbackState_Getter(mthis) native "AudioBufferSourceNode_playbackState_Getter";

Native_AudioBufferSourceNode_noteGrainOn_Callback(mthis, when, grainOffset, grainDuration) native "AudioBufferSourceNode_noteGrainOn_Callback_RESOLVER_STRING_3_double_double_double";

Native_AudioBufferSourceNode_noteOff_Callback(mthis, when) native "AudioBufferSourceNode_noteOff_Callback_RESOLVER_STRING_1_double";

Native_AudioBufferSourceNode_noteOn_Callback(mthis, when) native "AudioBufferSourceNode_noteOn_Callback_RESOLVER_STRING_1_double";

  // Generated overload resolver
Native_AudioBufferSourceNode_start(mthis, when, grainOffset, grainDuration) {
    if (grainDuration != null) {
      Native_AudioBufferSourceNode__start_1_Callback(mthis, when, grainOffset, grainDuration);
      return;
    }
    if (grainOffset != null) {
      Native_AudioBufferSourceNode__start_2_Callback(mthis, when, grainOffset);
      return;
    }
    if (when != null) {
      Native_AudioBufferSourceNode__start_3_Callback(mthis, when);
      return;
    }
    Native_AudioBufferSourceNode__start_4_Callback(mthis);
    return;
  }

Native_AudioBufferSourceNode__start_1_Callback(mthis, when, grainOffset, grainDuration) native "AudioBufferSourceNode_start_Callback_RESOLVER_STRING_3_double_double_double";

Native_AudioBufferSourceNode__start_2_Callback(mthis, when, grainOffset) native "AudioBufferSourceNode_start_Callback_RESOLVER_STRING_2_double_double";

Native_AudioBufferSourceNode__start_3_Callback(mthis, when) native "AudioBufferSourceNode_start_Callback_RESOLVER_STRING_1_double";

Native_AudioBufferSourceNode__start_4_Callback(mthis) native "AudioBufferSourceNode_start_Callback_RESOLVER_STRING_0_";

  // Generated overload resolver
Native_AudioBufferSourceNode_stop(mthis, when) {
    if (when != null) {
      Native_AudioBufferSourceNode__stop_1_Callback(mthis, when);
      return;
    }
    Native_AudioBufferSourceNode__stop_2_Callback(mthis);
    return;
  }

Native_AudioBufferSourceNode__stop_1_Callback(mthis, when) native "AudioBufferSourceNode_stop_Callback_RESOLVER_STRING_1_double";

Native_AudioBufferSourceNode__stop_2_Callback(mthis) native "AudioBufferSourceNode_stop_Callback_RESOLVER_STRING_0_";

  // Generated overload resolver
Native_AudioContext_AudioContext() {
    return Native_AudioContext__create_1constructorCallback();
  }

Native_AudioContext__create_1constructorCallback() native "AudioContext_constructorCallback_RESOLVER_STRING_0_";

Native_AudioContext_activeSourceCount_Getter(mthis) native "AudioContext_activeSourceCount_Getter";

Native_AudioContext_currentTime_Getter(mthis) native "AudioContext_currentTime_Getter";

Native_AudioContext_destination_Getter(mthis) native "AudioContext_destination_Getter";

Native_AudioContext_listener_Getter(mthis) native "AudioContext_listener_Getter";

Native_AudioContext_sampleRate_Getter(mthis) native "AudioContext_sampleRate_Getter";

Native_AudioContext_createAnalyser_Callback(mthis) native "AudioContext_createAnalyser_Callback_RESOLVER_STRING_0_";

Native_AudioContext_createBiquadFilter_Callback(mthis) native "AudioContext_createBiquadFilter_Callback_RESOLVER_STRING_0_";

Native_AudioContext_createBuffer_Callback(mthis, numberOfChannels, numberOfFrames, sampleRate) native "AudioContext_createBuffer_Callback_RESOLVER_STRING_3_unsigned long_unsigned long_float";

Native_AudioContext_createBufferFromBuffer_Callback(mthis, buffer, mixToMono) native "AudioContext_createBuffer_Callback_RESOLVER_STRING_2_ArrayBuffer_boolean";

Native_AudioContext_createBufferSource_Callback(mthis) native "AudioContext_createBufferSource_Callback_RESOLVER_STRING_0_";

  // Generated overload resolver
Native_AudioContext_createChannelMerger(mthis, numberOfInputs) {
    if (numberOfInputs != null) {
      return Native_AudioContext__createChannelMerger_1_Callback(mthis, numberOfInputs);
    }
    return Native_AudioContext__createChannelMerger_2_Callback(mthis);
  }

Native_AudioContext__createChannelMerger_1_Callback(mthis, numberOfInputs) native "AudioContext_createChannelMerger_Callback_RESOLVER_STRING_1_unsigned long";

Native_AudioContext__createChannelMerger_2_Callback(mthis) native "AudioContext_createChannelMerger_Callback_RESOLVER_STRING_0_";

  // Generated overload resolver
Native_AudioContext_createChannelSplitter(mthis, numberOfOutputs) {
    if (numberOfOutputs != null) {
      return Native_AudioContext__createChannelSplitter_1_Callback(mthis, numberOfOutputs);
    }
    return Native_AudioContext__createChannelSplitter_2_Callback(mthis);
  }

Native_AudioContext__createChannelSplitter_1_Callback(mthis, numberOfOutputs) native "AudioContext_createChannelSplitter_Callback_RESOLVER_STRING_1_unsigned long";

Native_AudioContext__createChannelSplitter_2_Callback(mthis) native "AudioContext_createChannelSplitter_Callback_RESOLVER_STRING_0_";

Native_AudioContext_createConvolver_Callback(mthis) native "AudioContext_createConvolver_Callback_RESOLVER_STRING_0_";

  // Generated overload resolver
Native_AudioContext_createDelay(mthis, maxDelayTime) {
    if (maxDelayTime != null) {
      return Native_AudioContext__createDelay_1_Callback(mthis, maxDelayTime);
    }
    return Native_AudioContext__createDelay_2_Callback(mthis);
  }

Native_AudioContext__createDelay_1_Callback(mthis, maxDelayTime) native "AudioContext_createDelay_Callback_RESOLVER_STRING_1_double";

Native_AudioContext__createDelay_2_Callback(mthis) native "AudioContext_createDelay_Callback_RESOLVER_STRING_0_";

  // Generated overload resolver
Native_AudioContext_createDelayNode(mthis, maxDelayTime) {
    if (maxDelayTime != null) {
      return Native_AudioContext__createDelayNode_1_Callback(mthis, maxDelayTime);
    }
    return Native_AudioContext__createDelayNode_2_Callback(mthis);
  }

Native_AudioContext__createDelayNode_1_Callback(mthis, maxDelayTime) native "AudioContext_createDelayNode_Callback_RESOLVER_STRING_1_double";

Native_AudioContext__createDelayNode_2_Callback(mthis) native "AudioContext_createDelayNode_Callback_RESOLVER_STRING_0_";

Native_AudioContext_createDynamicsCompressor_Callback(mthis) native "AudioContext_createDynamicsCompressor_Callback_RESOLVER_STRING_0_";

Native_AudioContext_createGain_Callback(mthis) native "AudioContext_createGain_Callback_RESOLVER_STRING_0_";

Native_AudioContext_createGainNode_Callback(mthis) native "AudioContext_createGainNode_Callback_RESOLVER_STRING_0_";

  // Generated overload resolver
Native_AudioContext_createJavaScriptNode(mthis, bufferSize, numberOfInputChannels, numberOfOutputChannels) {
    if (numberOfOutputChannels != null) {
      return Native_AudioContext__createJavaScriptNode_1_Callback(mthis, bufferSize, numberOfInputChannels, numberOfOutputChannels);
    }
    if (numberOfInputChannels != null) {
      return Native_AudioContext__createJavaScriptNode_2_Callback(mthis, bufferSize, numberOfInputChannels);
    }
    return Native_AudioContext__createJavaScriptNode_3_Callback(mthis, bufferSize);
  }

Native_AudioContext__createJavaScriptNode_1_Callback(mthis, bufferSize, numberOfInputChannels, numberOfOutputChannels) native "AudioContext_createJavaScriptNode_Callback_RESOLVER_STRING_3_unsigned long_unsigned long_unsigned long";

Native_AudioContext__createJavaScriptNode_2_Callback(mthis, bufferSize, numberOfInputChannels) native "AudioContext_createJavaScriptNode_Callback_RESOLVER_STRING_2_unsigned long_unsigned long";

Native_AudioContext__createJavaScriptNode_3_Callback(mthis, bufferSize) native "AudioContext_createJavaScriptNode_Callback_RESOLVER_STRING_1_unsigned long";

Native_AudioContext_createMediaElementSource_Callback(mthis, mediaElement) native "AudioContext_createMediaElementSource_Callback_RESOLVER_STRING_1_HTMLMediaElement";

Native_AudioContext_createMediaStreamDestination_Callback(mthis) native "AudioContext_createMediaStreamDestination_Callback_RESOLVER_STRING_0_";

Native_AudioContext_createMediaStreamSource_Callback(mthis, mediaStream) native "AudioContext_createMediaStreamSource_Callback_RESOLVER_STRING_1_MediaStream";

Native_AudioContext_createOscillator_Callback(mthis) native "AudioContext_createOscillator_Callback_RESOLVER_STRING_0_";

Native_AudioContext_createPanner_Callback(mthis) native "AudioContext_createPanner_Callback_RESOLVER_STRING_0_";

Native_AudioContext_createPeriodicWave_Callback(mthis, real, imag) native "AudioContext_createPeriodicWave_Callback_RESOLVER_STRING_2_Float32Array_Float32Array";

  // Generated overload resolver
Native_AudioContext_createScriptProcessor(mthis, bufferSize, numberOfInputChannels, numberOfOutputChannels) {
    if (numberOfOutputChannels != null) {
      return Native_AudioContext__createScriptProcessor_1_Callback(mthis, bufferSize, numberOfInputChannels, numberOfOutputChannels);
    }
    if (numberOfInputChannels != null) {
      return Native_AudioContext__createScriptProcessor_2_Callback(mthis, bufferSize, numberOfInputChannels);
    }
    if (bufferSize != null) {
      return Native_AudioContext__createScriptProcessor_3_Callback(mthis, bufferSize);
    }
    return Native_AudioContext__createScriptProcessor_4_Callback(mthis);
  }

Native_AudioContext__createScriptProcessor_1_Callback(mthis, bufferSize, numberOfInputChannels, numberOfOutputChannels) native "AudioContext_createScriptProcessor_Callback_RESOLVER_STRING_3_unsigned long_unsigned long_unsigned long";

Native_AudioContext__createScriptProcessor_2_Callback(mthis, bufferSize, numberOfInputChannels) native "AudioContext_createScriptProcessor_Callback_RESOLVER_STRING_2_unsigned long_unsigned long";

Native_AudioContext__createScriptProcessor_3_Callback(mthis, bufferSize) native "AudioContext_createScriptProcessor_Callback_RESOLVER_STRING_1_unsigned long";

Native_AudioContext__createScriptProcessor_4_Callback(mthis) native "AudioContext_createScriptProcessor_Callback_RESOLVER_STRING_0_";

Native_AudioContext_createWaveShaper_Callback(mthis) native "AudioContext_createWaveShaper_Callback_RESOLVER_STRING_0_";

Native_AudioContext_decodeAudioData_Callback(mthis, audioData, successCallback, errorCallback) native "AudioContext_decodeAudioData_Callback";

Native_AudioContext_startRendering_Callback(mthis) native "AudioContext_startRendering_Callback_RESOLVER_STRING_0_";

Native_AudioDestinationNode_maxChannelCount_Getter(mthis) native "AudioDestinationNode_maxChannelCount_Getter";

Native_AudioListener_dopplerFactor_Getter(mthis) native "AudioListener_dopplerFactor_Getter";

Native_AudioListener_dopplerFactor_Setter(mthis, value) native "AudioListener_dopplerFactor_Setter";

Native_AudioListener_speedOfSound_Getter(mthis) native "AudioListener_speedOfSound_Getter";

Native_AudioListener_speedOfSound_Setter(mthis, value) native "AudioListener_speedOfSound_Setter";

Native_AudioListener_setOrientation_Callback(mthis, x, y, z, xUp, yUp, zUp) native "AudioListener_setOrientation_Callback_RESOLVER_STRING_6_float_float_float_float_float_float";

Native_AudioListener_setPosition_Callback(mthis, x, y, z) native "AudioListener_setPosition_Callback_RESOLVER_STRING_3_float_float_float";

Native_AudioListener_setVelocity_Callback(mthis, x, y, z) native "AudioListener_setVelocity_Callback_RESOLVER_STRING_3_float_float_float";

Native_AudioParam_defaultValue_Getter(mthis) native "AudioParam_defaultValue_Getter";

Native_AudioParam_maxValue_Getter(mthis) native "AudioParam_maxValue_Getter";

Native_AudioParam_minValue_Getter(mthis) native "AudioParam_minValue_Getter";

Native_AudioParam_name_Getter(mthis) native "AudioParam_name_Getter";

Native_AudioParam_units_Getter(mthis) native "AudioParam_units_Getter";

Native_AudioParam_value_Getter(mthis) native "AudioParam_value_Getter";

Native_AudioParam_value_Setter(mthis, value) native "AudioParam_value_Setter";

Native_AudioParam_cancelScheduledValues_Callback(mthis, startTime) native "AudioParam_cancelScheduledValues_Callback_RESOLVER_STRING_1_double";

Native_AudioParam_exponentialRampToValueAtTime_Callback(mthis, value, time) native "AudioParam_exponentialRampToValueAtTime_Callback_RESOLVER_STRING_2_float_double";

Native_AudioParam_linearRampToValueAtTime_Callback(mthis, value, time) native "AudioParam_linearRampToValueAtTime_Callback_RESOLVER_STRING_2_float_double";

Native_AudioParam_setTargetAtTime_Callback(mthis, target, time, timeConstant) native "AudioParam_setTargetAtTime_Callback_RESOLVER_STRING_3_float_double_double";

Native_AudioParam_setTargetValueAtTime_Callback(mthis, targetValue, time, timeConstant) native "AudioParam_setTargetValueAtTime_Callback_RESOLVER_STRING_3_float_double_double";

Native_AudioParam_setValueAtTime_Callback(mthis, value, time) native "AudioParam_setValueAtTime_Callback_RESOLVER_STRING_2_float_double";

Native_AudioParam_setValueCurveAtTime_Callback(mthis, values, time, duration) native "AudioParam_setValueCurveAtTime_Callback";

Native_Event_bubbles_Getter(mthis) native "Event_bubbles_Getter";

Native_Event_cancelable_Getter(mthis) native "Event_cancelable_Getter";

Native_Event_clipboardData_Getter(mthis) native "Event_clipboardData_Getter";

Native_Event_currentTarget_Getter(mthis) native "Event_currentTarget_Getter";

Native_Event_defaultPrevented_Getter(mthis) native "Event_defaultPrevented_Getter";

Native_Event_eventPhase_Getter(mthis) native "Event_eventPhase_Getter";

Native_Event_path_Getter(mthis) native "Event_path_Getter";

Native_Event_target_Getter(mthis) native "Event_target_Getter";

Native_Event_timeStamp_Getter(mthis) native "Event_timeStamp_Getter";

Native_Event_type_Getter(mthis) native "Event_type_Getter";

Native_Event_initEvent_Callback(mthis, eventTypeArg, canBubbleArg, cancelableArg) native "Event_initEvent_Callback_RESOLVER_STRING_3_DOMString_boolean_boolean";

Native_Event_preventDefault_Callback(mthis) native "Event_preventDefault_Callback_RESOLVER_STRING_0_";

Native_Event_stopImmediatePropagation_Callback(mthis) native "Event_stopImmediatePropagation_Callback_RESOLVER_STRING_0_";

Native_Event_stopPropagation_Callback(mthis) native "Event_stopPropagation_Callback_RESOLVER_STRING_0_";

Native_AudioProcessingEvent_inputBuffer_Getter(mthis) native "AudioProcessingEvent_inputBuffer_Getter";

Native_AudioProcessingEvent_outputBuffer_Getter(mthis) native "AudioProcessingEvent_outputBuffer_Getter";

Native_AutocompleteErrorEvent_reason_Getter(mthis) native "AutocompleteErrorEvent_reason_Getter";

Native_BarProp_visible_Getter(mthis) native "BarProp_visible_Getter";

Native_BeforeLoadEvent_url_Getter(mthis) native "BeforeLoadEvent_url_Getter";

Native_BeforeUnloadEvent_returnValue_Getter(mthis) native "BeforeUnloadEvent_returnValue_Getter";

Native_BeforeUnloadEvent_returnValue_Setter(mthis, value) native "BeforeUnloadEvent_returnValue_Setter";

Native_BiquadFilterNode_Q_Getter(mthis) native "BiquadFilterNode_Q_Getter";

Native_BiquadFilterNode_detune_Getter(mthis) native "BiquadFilterNode_detune_Getter";

Native_BiquadFilterNode_frequency_Getter(mthis) native "BiquadFilterNode_frequency_Getter";

Native_BiquadFilterNode_gain_Getter(mthis) native "BiquadFilterNode_gain_Getter";

Native_BiquadFilterNode_type_Getter(mthis) native "BiquadFilterNode_type_Getter";

Native_BiquadFilterNode_type_Setter(mthis, value) native "BiquadFilterNode_type_Setter";

Native_BiquadFilterNode_getFrequencyResponse_Callback(mthis, frequencyHz, magResponse, phaseResponse) native "BiquadFilterNode_getFrequencyResponse_Callback_RESOLVER_STRING_3_Float32Array_Float32Array_Float32Array";

Native_Blob_constructorCallback(blobParts, type, endings) native "Blob_constructorCallback";

Native_Blob_size_Getter(mthis) native "Blob_size_Getter";

Native_Blob_type_Getter(mthis) native "Blob_type_Getter";

  // Generated overload resolver
Native_Blob_slice(mthis, start, end, contentType) {
    if (contentType != null) {
      return Native_Blob__slice_1_Callback(mthis, start, end, contentType);
    }
    if (end != null) {
      return Native_Blob__slice_2_Callback(mthis, start, end);
    }
    if (start != null) {
      return Native_Blob__slice_3_Callback(mthis, start);
    }
    return Native_Blob__slice_4_Callback(mthis);
  }

Native_Blob__slice_1_Callback(mthis, start, end, contentType) native "Blob_slice_Callback_RESOLVER_STRING_3_long long_long long_DOMString";

Native_Blob__slice_2_Callback(mthis, start, end) native "Blob_slice_Callback_RESOLVER_STRING_2_long long_long long";

Native_Blob__slice_3_Callback(mthis, start) native "Blob_slice_Callback_RESOLVER_STRING_1_long long";

Native_Blob__slice_4_Callback(mthis) native "Blob_slice_Callback_RESOLVER_STRING_0_";

Native_ChildNode_nextElementSibling_Getter(mthis) native "ChildNode_nextElementSibling_Getter";

Native_ChildNode_previousElementSibling_Getter(mthis) native "ChildNode_previousElementSibling_Getter";

Native_ChildNode_remove_Callback(mthis) native "ChildNode_remove_Callback_RESOLVER_STRING_0_";

Native_CharacterData_data_Getter(mthis) native "CharacterData_data_Getter";

Native_CharacterData_data_Setter(mthis, value) native "CharacterData_data_Setter";

Native_CharacterData_length_Getter(mthis) native "CharacterData_length_Getter";

Native_CharacterData_appendData_Callback(mthis, data) native "CharacterData_appendData_Callback_RESOLVER_STRING_1_DOMString";

Native_CharacterData_deleteData_Callback(mthis, offset, length) native "CharacterData_deleteData_Callback_RESOLVER_STRING_2_unsigned long_unsigned long";

Native_CharacterData_insertData_Callback(mthis, offset, data) native "CharacterData_insertData_Callback_RESOLVER_STRING_2_unsigned long_DOMString";

Native_CharacterData_replaceData_Callback(mthis, offset, length, data) native "CharacterData_replaceData_Callback_RESOLVER_STRING_3_unsigned long_unsigned long_DOMString";

Native_CharacterData_substringData_Callback(mthis, offset, length) native "CharacterData_substringData_Callback_RESOLVER_STRING_2_unsigned long_unsigned long";

Native_CharacterData_nextElementSibling_Getter(mthis) native "CharacterData_nextElementSibling_Getter";

Native_CharacterData_previousElementSibling_Getter(mthis) native "CharacterData_previousElementSibling_Getter";

Native_Text_wholeText_Getter(mthis) native "Text_wholeText_Getter";

Native_Text_getDestinationInsertionPoints_Callback(mthis) native "Text_getDestinationInsertionPoints_Callback_RESOLVER_STRING_0_";

Native_Text_splitText_Callback(mthis, offset) native "Text_splitText_Callback_RESOLVER_STRING_1_unsigned long";

Native_CSS_supports_Callback(mthis, property, value) native "CSS_supports_Callback_RESOLVER_STRING_2_DOMString_DOMString";

Native_CSS_supportsCondition_Callback(mthis, conditionText) native "CSS_supports_Callback_RESOLVER_STRING_1_DOMString";

Native_CSSRule_cssText_Getter(mthis) native "CSSRule_cssText_Getter";

Native_CSSRule_cssText_Setter(mthis, value) native "CSSRule_cssText_Setter";

Native_CSSRule_parentRule_Getter(mthis) native "CSSRule_parentRule_Getter";

Native_CSSRule_parentStyleSheet_Getter(mthis) native "CSSRule_parentStyleSheet_Getter";

Native_CSSRule_type_Getter(mthis) native "CSSRule_type_Getter";

Native_CSSCharsetRule_encoding_Getter(mthis) native "CSSCharsetRule_encoding_Getter";

Native_CSSCharsetRule_encoding_Setter(mthis, value) native "CSSCharsetRule_encoding_Setter";

Native_CSSFontFaceLoadEvent_fontfaces_Getter(mthis) native "CSSFontFaceLoadEvent_fontfaces_Getter";

Native_CSSFontFaceRule_style_Getter(mthis) native "CSSFontFaceRule_style_Getter";

Native_CSSImportRule_href_Getter(mthis) native "CSSImportRule_href_Getter";

Native_CSSImportRule_media_Getter(mthis) native "CSSImportRule_media_Getter";

Native_CSSImportRule_styleSheet_Getter(mthis) native "CSSImportRule_styleSheet_Getter";

Native_CSSKeyframeRule_keyText_Getter(mthis) native "CSSKeyframeRule_keyText_Getter";

Native_CSSKeyframeRule_keyText_Setter(mthis, value) native "CSSKeyframeRule_keyText_Setter";

Native_CSSKeyframeRule_style_Getter(mthis) native "CSSKeyframeRule_style_Getter";

Native_CSSKeyframesRule_cssRules_Getter(mthis) native "CSSKeyframesRule_cssRules_Getter";

Native_CSSKeyframesRule_name_Getter(mthis) native "CSSKeyframesRule_name_Getter";

Native_CSSKeyframesRule_name_Setter(mthis, value) native "CSSKeyframesRule_name_Setter";

Native_CSSKeyframesRule___getter___Callback(mthis, index) native "CSSKeyframesRule___getter___Callback_RESOLVER_STRING_1_unsigned long";

Native_CSSKeyframesRule_deleteRule_Callback(mthis, key) native "CSSKeyframesRule_deleteRule_Callback_RESOLVER_STRING_1_DOMString";

Native_CSSKeyframesRule_findRule_Callback(mthis, key) native "CSSKeyframesRule_findRule_Callback_RESOLVER_STRING_1_DOMString";

Native_CSSKeyframesRule_insertRule_Callback(mthis, rule) native "CSSKeyframesRule_insertRule_Callback_RESOLVER_STRING_1_DOMString";

Native_CSSMediaRule_cssRules_Getter(mthis) native "CSSMediaRule_cssRules_Getter";

Native_CSSMediaRule_media_Getter(mthis) native "CSSMediaRule_media_Getter";

Native_CSSMediaRule_deleteRule_Callback(mthis, index) native "CSSMediaRule_deleteRule_Callback_RESOLVER_STRING_1_unsigned long";

Native_CSSMediaRule_insertRule_Callback(mthis, rule, index) native "CSSMediaRule_insertRule_Callback_RESOLVER_STRING_2_DOMString_unsigned long";

Native_CSSPageRule_selectorText_Getter(mthis) native "CSSPageRule_selectorText_Getter";

Native_CSSPageRule_selectorText_Setter(mthis, value) native "CSSPageRule_selectorText_Setter";

Native_CSSPageRule_style_Getter(mthis) native "CSSPageRule_style_Getter";

Native_CSSRuleList_length_Getter(mthis) native "CSSRuleList_length_Getter";

Native_CSSRuleList_NativeIndexed_Getter(mthis, index) native "CSSRuleList_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_CSSRuleList_item_Callback(mthis, index) native "CSSRuleList_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_CSSStyleDeclaration_cssText_Getter(mthis) native "CSSStyleDeclaration_cssText_Getter";

Native_CSSStyleDeclaration_cssText_Setter(mthis, value) native "CSSStyleDeclaration_cssText_Setter";

Native_CSSStyleDeclaration_length_Getter(mthis) native "CSSStyleDeclaration_length_Getter";

Native_CSSStyleDeclaration_parentRule_Getter(mthis) native "CSSStyleDeclaration_parentRule_Getter";

Native_CSSStyleDeclaration___setter___Callback(mthis, propertyName, propertyValue) native "CSSStyleDeclaration___setter___Callback";

Native_CSSStyleDeclaration_getPropertyPriority_Callback(mthis, propertyName) native "CSSStyleDeclaration_getPropertyPriority_Callback_RESOLVER_STRING_1_DOMString";

Native_CSSStyleDeclaration_getPropertyValue_Callback(mthis, propertyName) native "CSSStyleDeclaration_getPropertyValue_Callback_RESOLVER_STRING_1_DOMString";

Native_CSSStyleDeclaration_item_Callback(mthis, index) native "CSSStyleDeclaration_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_CSSStyleDeclaration_removeProperty_Callback(mthis, propertyName) native "CSSStyleDeclaration_removeProperty_Callback_RESOLVER_STRING_1_DOMString";

Native_CSSStyleDeclaration_setProperty_Callback(mthis, propertyName, value, priority) native "CSSStyleDeclaration_setProperty_Callback_RESOLVER_STRING_3_DOMString_DOMString_DOMString";

Native_CSSStyleRule_selectorText_Getter(mthis) native "CSSStyleRule_selectorText_Getter";

Native_CSSStyleRule_selectorText_Setter(mthis, value) native "CSSStyleRule_selectorText_Setter";

Native_CSSStyleRule_style_Getter(mthis) native "CSSStyleRule_style_Getter";

Native_StyleSheet_disabled_Getter(mthis) native "StyleSheet_disabled_Getter";

Native_StyleSheet_disabled_Setter(mthis, value) native "StyleSheet_disabled_Setter";

Native_StyleSheet_href_Getter(mthis) native "StyleSheet_href_Getter";

Native_StyleSheet_media_Getter(mthis) native "StyleSheet_media_Getter";

Native_StyleSheet_ownerNode_Getter(mthis) native "StyleSheet_ownerNode_Getter";

Native_StyleSheet_parentStyleSheet_Getter(mthis) native "StyleSheet_parentStyleSheet_Getter";

Native_StyleSheet_title_Getter(mthis) native "StyleSheet_title_Getter";

Native_StyleSheet_type_Getter(mthis) native "StyleSheet_type_Getter";

Native_CSSStyleSheet_cssRules_Getter(mthis) native "CSSStyleSheet_cssRules_Getter";

Native_CSSStyleSheet_ownerRule_Getter(mthis) native "CSSStyleSheet_ownerRule_Getter";

Native_CSSStyleSheet_rules_Getter(mthis) native "CSSStyleSheet_rules_Getter";

  // Generated overload resolver
Native_CSSStyleSheet_addRule(mthis, selector, style, index) {
    if (index != null) {
      return Native_CSSStyleSheet__addRule_1_Callback(mthis, selector, style, index);
    }
    return Native_CSSStyleSheet__addRule_2_Callback(mthis, selector, style);
  }

Native_CSSStyleSheet__addRule_1_Callback(mthis, selector, style, index) native "CSSStyleSheet_addRule_Callback_RESOLVER_STRING_3_DOMString_DOMString_unsigned long";

Native_CSSStyleSheet__addRule_2_Callback(mthis, selector, style) native "CSSStyleSheet_addRule_Callback_RESOLVER_STRING_2_DOMString_DOMString";

Native_CSSStyleSheet_deleteRule_Callback(mthis, index) native "CSSStyleSheet_deleteRule_Callback_RESOLVER_STRING_1_unsigned long";

  // Generated overload resolver
Native_CSSStyleSheet_insertRule(mthis, rule, index) {
    if (index != null) {
      return Native_CSSStyleSheet__insertRule_1_Callback(mthis, rule, index);
    }
    return Native_CSSStyleSheet__insertRule_2_Callback(mthis, rule);
  }

Native_CSSStyleSheet__insertRule_1_Callback(mthis, rule, index) native "CSSStyleSheet_insertRule_Callback_RESOLVER_STRING_2_DOMString_unsigned long";

Native_CSSStyleSheet__insertRule_2_Callback(mthis, rule) native "CSSStyleSheet_insertRule_Callback_RESOLVER_STRING_1_DOMString";

Native_CSSStyleSheet_removeRule_Callback(mthis, index) native "CSSStyleSheet_removeRule_Callback_RESOLVER_STRING_1_unsigned long";

Native_CSSSupportsRule_conditionText_Getter(mthis) native "CSSSupportsRule_conditionText_Getter";

Native_CSSSupportsRule_cssRules_Getter(mthis) native "CSSSupportsRule_cssRules_Getter";

Native_CSSSupportsRule_deleteRule_Callback(mthis, index) native "CSSSupportsRule_deleteRule_Callback_RESOLVER_STRING_1_unsigned long";

Native_CSSSupportsRule_insertRule_Callback(mthis, rule, index) native "CSSSupportsRule_insertRule_Callback_RESOLVER_STRING_2_DOMString_unsigned long";

Native_CSSValueList_length_Getter(mthis) native "CSSValueList_length_Getter";

Native_CSSValueList_NativeIndexed_Getter(mthis, index) native "CSSValueList_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_CSSValueList_item_Callback(mthis, index) native "CSSValueList_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_CSSViewportRule_style_Getter(mthis) native "CSSViewportRule_style_Getter";

Native_Canvas2DContextAttributes_alpha_Getter(mthis) native "Canvas2DContextAttributes_alpha_Getter";

Native_Canvas2DContextAttributes_alpha_Setter(mthis, value) native "Canvas2DContextAttributes_alpha_Setter";

Native_CanvasGradient_addColorStop_Callback(mthis, offset, color) native "CanvasGradient_addColorStop_Callback_RESOLVER_STRING_2_float_DOMString";

Native_CanvasRenderingContext_canvas_Getter(mthis) native "CanvasRenderingContext2D_canvas_Getter";

Native_CanvasRenderingContext2D_currentPath_Getter(mthis) native "CanvasRenderingContext2D_currentPath_Getter";

Native_CanvasRenderingContext2D_currentPath_Setter(mthis, value) native "CanvasRenderingContext2D_currentPath_Setter";

Native_CanvasRenderingContext2D_currentTransform_Getter(mthis) native "CanvasRenderingContext2D_currentTransform_Getter";

Native_CanvasRenderingContext2D_currentTransform_Setter(mthis, value) native "CanvasRenderingContext2D_currentTransform_Setter";

Native_CanvasRenderingContext2D_fillStyle_Getter(mthis) native "CanvasRenderingContext2D_fillStyle_Getter";

Native_CanvasRenderingContext2D_fillStyle_Setter(mthis, value) native "CanvasRenderingContext2D_fillStyle_Setter";

Native_CanvasRenderingContext2D_font_Getter(mthis) native "CanvasRenderingContext2D_font_Getter";

Native_CanvasRenderingContext2D_font_Setter(mthis, value) native "CanvasRenderingContext2D_font_Setter";

Native_CanvasRenderingContext2D_globalAlpha_Getter(mthis) native "CanvasRenderingContext2D_globalAlpha_Getter";

Native_CanvasRenderingContext2D_globalAlpha_Setter(mthis, value) native "CanvasRenderingContext2D_globalAlpha_Setter";

Native_CanvasRenderingContext2D_globalCompositeOperation_Getter(mthis) native "CanvasRenderingContext2D_globalCompositeOperation_Getter";

Native_CanvasRenderingContext2D_globalCompositeOperation_Setter(mthis, value) native "CanvasRenderingContext2D_globalCompositeOperation_Setter";

Native_CanvasRenderingContext2D_imageSmoothingEnabled_Getter(mthis) native "CanvasRenderingContext2D_imageSmoothingEnabled_Getter";

Native_CanvasRenderingContext2D_imageSmoothingEnabled_Setter(mthis, value) native "CanvasRenderingContext2D_imageSmoothingEnabled_Setter";

Native_CanvasRenderingContext2D_lineCap_Getter(mthis) native "CanvasRenderingContext2D_lineCap_Getter";

Native_CanvasRenderingContext2D_lineCap_Setter(mthis, value) native "CanvasRenderingContext2D_lineCap_Setter";

Native_CanvasRenderingContext2D_lineDashOffset_Getter(mthis) native "CanvasRenderingContext2D_lineDashOffset_Getter";

Native_CanvasRenderingContext2D_lineDashOffset_Setter(mthis, value) native "CanvasRenderingContext2D_lineDashOffset_Setter";

Native_CanvasRenderingContext2D_lineJoin_Getter(mthis) native "CanvasRenderingContext2D_lineJoin_Getter";

Native_CanvasRenderingContext2D_lineJoin_Setter(mthis, value) native "CanvasRenderingContext2D_lineJoin_Setter";

Native_CanvasRenderingContext2D_lineWidth_Getter(mthis) native "CanvasRenderingContext2D_lineWidth_Getter";

Native_CanvasRenderingContext2D_lineWidth_Setter(mthis, value) native "CanvasRenderingContext2D_lineWidth_Setter";

Native_CanvasRenderingContext2D_miterLimit_Getter(mthis) native "CanvasRenderingContext2D_miterLimit_Getter";

Native_CanvasRenderingContext2D_miterLimit_Setter(mthis, value) native "CanvasRenderingContext2D_miterLimit_Setter";

Native_CanvasRenderingContext2D_shadowBlur_Getter(mthis) native "CanvasRenderingContext2D_shadowBlur_Getter";

Native_CanvasRenderingContext2D_shadowBlur_Setter(mthis, value) native "CanvasRenderingContext2D_shadowBlur_Setter";

Native_CanvasRenderingContext2D_shadowColor_Getter(mthis) native "CanvasRenderingContext2D_shadowColor_Getter";

Native_CanvasRenderingContext2D_shadowColor_Setter(mthis, value) native "CanvasRenderingContext2D_shadowColor_Setter";

Native_CanvasRenderingContext2D_shadowOffsetX_Getter(mthis) native "CanvasRenderingContext2D_shadowOffsetX_Getter";

Native_CanvasRenderingContext2D_shadowOffsetX_Setter(mthis, value) native "CanvasRenderingContext2D_shadowOffsetX_Setter";

Native_CanvasRenderingContext2D_shadowOffsetY_Getter(mthis) native "CanvasRenderingContext2D_shadowOffsetY_Getter";

Native_CanvasRenderingContext2D_shadowOffsetY_Setter(mthis, value) native "CanvasRenderingContext2D_shadowOffsetY_Setter";

Native_CanvasRenderingContext2D_strokeStyle_Getter(mthis) native "CanvasRenderingContext2D_strokeStyle_Getter";

Native_CanvasRenderingContext2D_strokeStyle_Setter(mthis, value) native "CanvasRenderingContext2D_strokeStyle_Setter";

Native_CanvasRenderingContext2D_textAlign_Getter(mthis) native "CanvasRenderingContext2D_textAlign_Getter";

Native_CanvasRenderingContext2D_textAlign_Setter(mthis, value) native "CanvasRenderingContext2D_textAlign_Setter";

Native_CanvasRenderingContext2D_textBaseline_Getter(mthis) native "CanvasRenderingContext2D_textBaseline_Getter";

Native_CanvasRenderingContext2D_textBaseline_Setter(mthis, value) native "CanvasRenderingContext2D_textBaseline_Setter";

Native_CanvasRenderingContext2D_arc_Callback(mthis, x, y, radius, startAngle, endAngle, anticlockwise) native "CanvasRenderingContext2D_arc_Callback_RESOLVER_STRING_6_float_float_float_float_float_boolean";

Native_CanvasRenderingContext2D_arcTo_Callback(mthis, x1, y1, x2, y2, radius) native "CanvasRenderingContext2D_arcTo_Callback_RESOLVER_STRING_5_float_float_float_float_float";

Native_CanvasRenderingContext2D_beginPath_Callback(mthis) native "CanvasRenderingContext2D_beginPath_Callback_RESOLVER_STRING_0_";

Native_CanvasRenderingContext2D_bezierCurveTo_Callback(mthis, cp1x, cp1y, cp2x, cp2y, x, y) native "CanvasRenderingContext2D_bezierCurveTo_Callback_RESOLVER_STRING_6_float_float_float_float_float_float";

Native_CanvasRenderingContext2D_clearRect_Callback(mthis, x, y, width, height) native "CanvasRenderingContext2D_clearRect_Callback_RESOLVER_STRING_4_float_float_float_float";

  // Generated overload resolver
Native_CanvasRenderingContext2D_clip(mthis, winding) {
    if (winding != null) {
      Native_CanvasRenderingContext2D__clip_1_Callback(mthis, winding);
      return;
    }
    Native_CanvasRenderingContext2D__clip_2_Callback(mthis);
    return;
  }

Native_CanvasRenderingContext2D__clip_1_Callback(mthis, winding) native "CanvasRenderingContext2D_clip_Callback_RESOLVER_STRING_1_DOMString";

Native_CanvasRenderingContext2D__clip_2_Callback(mthis) native "CanvasRenderingContext2D_clip_Callback_RESOLVER_STRING_0_";

Native_CanvasRenderingContext2D_closePath_Callback(mthis) native "CanvasRenderingContext2D_closePath_Callback_RESOLVER_STRING_0_";

Native_CanvasRenderingContext2D_createImageData_Callback(mthis, sw, sh) native "CanvasRenderingContext2D_createImageData_Callback_RESOLVER_STRING_2_float_float";

Native_CanvasRenderingContext2D_createImageDataFromImageData_Callback(mthis, imagedata) native "CanvasRenderingContext2D_createImageData_Callback_RESOLVER_STRING_1_ImageData";

Native_CanvasRenderingContext2D_createLinearGradient_Callback(mthis, x0, y0, x1, y1) native "CanvasRenderingContext2D_createLinearGradient_Callback_RESOLVER_STRING_4_float_float_float_float";

Native_CanvasRenderingContext2D_createPattern_Callback(mthis, canvas, repetitionType) native "CanvasRenderingContext2D_createPattern_Callback_RESOLVER_STRING_2_HTMLCanvasElement_DOMString";

Native_CanvasRenderingContext2D_createPatternFromImage_Callback(mthis, image, repetitionType) native "CanvasRenderingContext2D_createPattern_Callback_RESOLVER_STRING_2_HTMLImageElement_DOMString";

Native_CanvasRenderingContext2D_createRadialGradient_Callback(mthis, x0, y0, r0, x1, y1, r1) native "CanvasRenderingContext2D_createRadialGradient_Callback_RESOLVER_STRING_6_float_float_float_float_float_float";

Native_CanvasRenderingContext2D_drawCustomFocusRing_Callback(mthis, element) native "CanvasRenderingContext2D_drawCustomFocusRing_Callback_RESOLVER_STRING_1_Element";

  // Generated overload resolver
Native_CanvasRenderingContext2D__drawImage(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh) {
    if ((sy_OR_y is num || sy_OR_y == null) && (sx_OR_x is num || sx_OR_x == null) && (canvas_OR_image_OR_imageBitmap_OR_video is ImageElement || canvas_OR_image_OR_imageBitmap_OR_video == null) && sw_OR_width == null && height_OR_sh == null && dx == null && dy == null && dw == null && dh == null) {
      Native_CanvasRenderingContext2D__drawImage_1_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y);
      return;
    }
    if ((height_OR_sh is num || height_OR_sh == null) && (sw_OR_width is num || sw_OR_width == null) && (sy_OR_y is num || sy_OR_y == null) && (sx_OR_x is num || sx_OR_x == null) && (canvas_OR_image_OR_imageBitmap_OR_video is ImageElement || canvas_OR_image_OR_imageBitmap_OR_video == null) && dx == null && dy == null && dw == null && dh == null) {
      Native_CanvasRenderingContext2D__drawImage_2_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh);
      return;
    }
    if ((dh is num || dh == null) && (dw is num || dw == null) && (dy is num || dy == null) && (dx is num || dx == null) && (height_OR_sh is num || height_OR_sh == null) && (sw_OR_width is num || sw_OR_width == null) && (sy_OR_y is num || sy_OR_y == null) && (sx_OR_x is num || sx_OR_x == null) && (canvas_OR_image_OR_imageBitmap_OR_video is ImageElement || canvas_OR_image_OR_imageBitmap_OR_video == null)) {
      Native_CanvasRenderingContext2D__drawImage_3_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh);
      return;
    }
    if ((sy_OR_y is num || sy_OR_y == null) && (sx_OR_x is num || sx_OR_x == null) && (canvas_OR_image_OR_imageBitmap_OR_video is CanvasElement || canvas_OR_image_OR_imageBitmap_OR_video == null) && sw_OR_width == null && height_OR_sh == null && dx == null && dy == null && dw == null && dh == null) {
      Native_CanvasRenderingContext2D__drawImage_4_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y);
      return;
    }
    if ((height_OR_sh is num || height_OR_sh == null) && (sw_OR_width is num || sw_OR_width == null) && (sy_OR_y is num || sy_OR_y == null) && (sx_OR_x is num || sx_OR_x == null) && (canvas_OR_image_OR_imageBitmap_OR_video is CanvasElement || canvas_OR_image_OR_imageBitmap_OR_video == null) && dx == null && dy == null && dw == null && dh == null) {
      Native_CanvasRenderingContext2D__drawImage_5_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh);
      return;
    }
    if ((dh is num || dh == null) && (dw is num || dw == null) && (dy is num || dy == null) && (dx is num || dx == null) && (height_OR_sh is num || height_OR_sh == null) && (sw_OR_width is num || sw_OR_width == null) && (sy_OR_y is num || sy_OR_y == null) && (sx_OR_x is num || sx_OR_x == null) && (canvas_OR_image_OR_imageBitmap_OR_video is CanvasElement || canvas_OR_image_OR_imageBitmap_OR_video == null)) {
      Native_CanvasRenderingContext2D__drawImage_6_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh);
      return;
    }
    if ((sy_OR_y is num || sy_OR_y == null) && (sx_OR_x is num || sx_OR_x == null) && (canvas_OR_image_OR_imageBitmap_OR_video is VideoElement || canvas_OR_image_OR_imageBitmap_OR_video == null) && sw_OR_width == null && height_OR_sh == null && dx == null && dy == null && dw == null && dh == null) {
      Native_CanvasRenderingContext2D__drawImage_7_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y);
      return;
    }
    if ((height_OR_sh is num || height_OR_sh == null) && (sw_OR_width is num || sw_OR_width == null) && (sy_OR_y is num || sy_OR_y == null) && (sx_OR_x is num || sx_OR_x == null) && (canvas_OR_image_OR_imageBitmap_OR_video is VideoElement || canvas_OR_image_OR_imageBitmap_OR_video == null) && dx == null && dy == null && dw == null && dh == null) {
      Native_CanvasRenderingContext2D__drawImage_8_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh);
      return;
    }
    if ((dh is num || dh == null) && (dw is num || dw == null) && (dy is num || dy == null) && (dx is num || dx == null) && (height_OR_sh is num || height_OR_sh == null) && (sw_OR_width is num || sw_OR_width == null) && (sy_OR_y is num || sy_OR_y == null) && (sx_OR_x is num || sx_OR_x == null) && (canvas_OR_image_OR_imageBitmap_OR_video is VideoElement || canvas_OR_image_OR_imageBitmap_OR_video == null)) {
      Native_CanvasRenderingContext2D__drawImage_9_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh);
      return;
    }
    if ((sy_OR_y is num || sy_OR_y == null) && (sx_OR_x is num || sx_OR_x == null) && (canvas_OR_image_OR_imageBitmap_OR_video is ImageBitmap || canvas_OR_image_OR_imageBitmap_OR_video == null) && sw_OR_width == null && height_OR_sh == null && dx == null && dy == null && dw == null && dh == null) {
      Native_CanvasRenderingContext2D__drawImage_10_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y);
      return;
    }
    if ((height_OR_sh is num || height_OR_sh == null) && (sw_OR_width is num || sw_OR_width == null) && (sy_OR_y is num || sy_OR_y == null) && (sx_OR_x is num || sx_OR_x == null) && (canvas_OR_image_OR_imageBitmap_OR_video is ImageBitmap || canvas_OR_image_OR_imageBitmap_OR_video == null) && dx == null && dy == null && dw == null && dh == null) {
      Native_CanvasRenderingContext2D__drawImage_11_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh);
      return;
    }
    if ((dh is num || dh == null) && (dw is num || dw == null) && (dy is num || dy == null) && (dx is num || dx == null) && (height_OR_sh is num || height_OR_sh == null) && (sw_OR_width is num || sw_OR_width == null) && (sy_OR_y is num || sy_OR_y == null) && (sx_OR_x is num || sx_OR_x == null) && (canvas_OR_image_OR_imageBitmap_OR_video is ImageBitmap || canvas_OR_image_OR_imageBitmap_OR_video == null)) {
      Native_CanvasRenderingContext2D__drawImage_12_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

Native_CanvasRenderingContext2D__drawImage_1_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y) native "CanvasRenderingContext2D_drawImage_Callback_RESOLVER_STRING_3_HTMLImageElement_float_float";

Native_CanvasRenderingContext2D__drawImage_2_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh) native "CanvasRenderingContext2D_drawImage_Callback_RESOLVER_STRING_5_HTMLImageElement_float_float_float_float";

Native_CanvasRenderingContext2D__drawImage_3_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh) native "CanvasRenderingContext2D_drawImage_Callback_RESOLVER_STRING_9_HTMLImageElement_float_float_float_float_float_float_float_float";

Native_CanvasRenderingContext2D__drawImage_4_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y) native "CanvasRenderingContext2D_drawImage_Callback_RESOLVER_STRING_3_HTMLCanvasElement_float_float";

Native_CanvasRenderingContext2D__drawImage_5_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh) native "CanvasRenderingContext2D_drawImage_Callback_RESOLVER_STRING_5_HTMLCanvasElement_float_float_float_float";

Native_CanvasRenderingContext2D__drawImage_6_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh) native "CanvasRenderingContext2D_drawImage_Callback_RESOLVER_STRING_9_HTMLCanvasElement_float_float_float_float_float_float_float_float";

Native_CanvasRenderingContext2D__drawImage_7_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y) native "CanvasRenderingContext2D_drawImage_Callback_RESOLVER_STRING_3_HTMLVideoElement_float_float";

Native_CanvasRenderingContext2D__drawImage_8_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh) native "CanvasRenderingContext2D_drawImage_Callback_RESOLVER_STRING_5_HTMLVideoElement_float_float_float_float";

Native_CanvasRenderingContext2D__drawImage_9_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh) native "CanvasRenderingContext2D_drawImage_Callback_RESOLVER_STRING_9_HTMLVideoElement_float_float_float_float_float_float_float_float";

Native_CanvasRenderingContext2D__drawImage_10_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y) native "CanvasRenderingContext2D_drawImage_Callback_RESOLVER_STRING_3_ImageBitmap_float_float";

Native_CanvasRenderingContext2D__drawImage_11_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh) native "CanvasRenderingContext2D_drawImage_Callback_RESOLVER_STRING_5_ImageBitmap_float_float_float_float";

Native_CanvasRenderingContext2D__drawImage_12_Callback(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh) native "CanvasRenderingContext2D_drawImage_Callback_RESOLVER_STRING_9_ImageBitmap_float_float_float_float_float_float_float_float";

Native_CanvasRenderingContext2D_ellipse_Callback(mthis, x, y, radiusX, radiusY, rotation, startAngle, endAngle, anticlockwise) native "CanvasRenderingContext2D_ellipse_Callback_RESOLVER_STRING_8_float_float_float_float_float_float_float_boolean";

  // Generated overload resolver
Native_CanvasRenderingContext2D_fill(mthis, winding) {
    if (winding != null) {
      Native_CanvasRenderingContext2D__fill_1_Callback(mthis, winding);
      return;
    }
    Native_CanvasRenderingContext2D__fill_2_Callback(mthis);
    return;
  }

Native_CanvasRenderingContext2D__fill_1_Callback(mthis, winding) native "CanvasRenderingContext2D_fill_Callback_RESOLVER_STRING_1_DOMString";

Native_CanvasRenderingContext2D__fill_2_Callback(mthis) native "CanvasRenderingContext2D_fill_Callback_RESOLVER_STRING_0_";

Native_CanvasRenderingContext2D_fillRect_Callback(mthis, x, y, width, height) native "CanvasRenderingContext2D_fillRect_Callback_RESOLVER_STRING_4_float_float_float_float";

  // Generated overload resolver
Native_CanvasRenderingContext2D_fillText(mthis, text, x, y, maxWidth) {
    if (maxWidth != null) {
      Native_CanvasRenderingContext2D__fillText_1_Callback(mthis, text, x, y, maxWidth);
      return;
    }
    Native_CanvasRenderingContext2D__fillText_2_Callback(mthis, text, x, y);
    return;
  }

Native_CanvasRenderingContext2D__fillText_1_Callback(mthis, text, x, y, maxWidth) native "CanvasRenderingContext2D_fillText_Callback_RESOLVER_STRING_4_DOMString_float_float_float";

Native_CanvasRenderingContext2D__fillText_2_Callback(mthis, text, x, y) native "CanvasRenderingContext2D_fillText_Callback_RESOLVER_STRING_3_DOMString_float_float";

Native_CanvasRenderingContext2D_getContextAttributes_Callback(mthis) native "CanvasRenderingContext2D_getContextAttributes_Callback_RESOLVER_STRING_0_";

Native_CanvasRenderingContext2D_getImageData_Callback(mthis, sx, sy, sw, sh) native "CanvasRenderingContext2D_getImageData_Callback_RESOLVER_STRING_4_float_float_float_float";

Native_CanvasRenderingContext2D_getLineDash_Callback(mthis) native "CanvasRenderingContext2D_getLineDash_Callback_RESOLVER_STRING_0_";

  // Generated overload resolver
Native_CanvasRenderingContext2D_isPointInPath(mthis, x, y, winding) {
    if (winding != null) {
      return Native_CanvasRenderingContext2D__isPointInPath_1_Callback(mthis, x, y, winding);
    }
    return Native_CanvasRenderingContext2D__isPointInPath_2_Callback(mthis, x, y);
  }

Native_CanvasRenderingContext2D__isPointInPath_1_Callback(mthis, x, y, winding) native "CanvasRenderingContext2D_isPointInPath_Callback_RESOLVER_STRING_3_float_float_DOMString";

Native_CanvasRenderingContext2D__isPointInPath_2_Callback(mthis, x, y) native "CanvasRenderingContext2D_isPointInPath_Callback_RESOLVER_STRING_2_float_float";

Native_CanvasRenderingContext2D_isPointInStroke_Callback(mthis, x, y) native "CanvasRenderingContext2D_isPointInStroke_Callback_RESOLVER_STRING_2_float_float";

Native_CanvasRenderingContext2D_lineTo_Callback(mthis, x, y) native "CanvasRenderingContext2D_lineTo_Callback_RESOLVER_STRING_2_float_float";

Native_CanvasRenderingContext2D_measureText_Callback(mthis, text) native "CanvasRenderingContext2D_measureText_Callback_RESOLVER_STRING_1_DOMString";

Native_CanvasRenderingContext2D_moveTo_Callback(mthis, x, y) native "CanvasRenderingContext2D_moveTo_Callback_RESOLVER_STRING_2_float_float";

  // Generated overload resolver
Native_CanvasRenderingContext2D_putImageData(mthis, imagedata, dx, dy, dirtyX, dirtyY, dirtyWidth, dirtyHeight) {
    if ((dy is num || dy == null) && (dx is num || dx == null) && (imagedata is ImageData || imagedata == null) && dirtyX == null && dirtyY == null && dirtyWidth == null && dirtyHeight == null) {
      Native_CanvasRenderingContext2D__putImageData_1_Callback(mthis, imagedata, dx, dy);
      return;
    }
    if ((dirtyHeight is num || dirtyHeight == null) && (dirtyWidth is num || dirtyWidth == null) && (dirtyY is num || dirtyY == null) && (dirtyX is num || dirtyX == null) && (dy is num || dy == null) && (dx is num || dx == null) && (imagedata is ImageData || imagedata == null)) {
      Native_CanvasRenderingContext2D__putImageData_2_Callback(mthis, imagedata, dx, dy, dirtyX, dirtyY, dirtyWidth, dirtyHeight);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

Native_CanvasRenderingContext2D__putImageData_1_Callback(mthis, imagedata, dx, dy) native "CanvasRenderingContext2D_putImageData_Callback_RESOLVER_STRING_3_ImageData_float_float";

Native_CanvasRenderingContext2D__putImageData_2_Callback(mthis, imagedata, dx, dy, dirtyX, dirtyY, dirtyWidth, dirtyHeight) native "CanvasRenderingContext2D_putImageData_Callback_RESOLVER_STRING_7_ImageData_float_float_float_float_float_float";

Native_CanvasRenderingContext2D_quadraticCurveTo_Callback(mthis, cpx, cpy, x, y) native "CanvasRenderingContext2D_quadraticCurveTo_Callback_RESOLVER_STRING_4_float_float_float_float";

Native_CanvasRenderingContext2D_rect_Callback(mthis, x, y, width, height) native "CanvasRenderingContext2D_rect_Callback_RESOLVER_STRING_4_float_float_float_float";

Native_CanvasRenderingContext2D_resetTransform_Callback(mthis) native "CanvasRenderingContext2D_resetTransform_Callback_RESOLVER_STRING_0_";

Native_CanvasRenderingContext2D_restore_Callback(mthis) native "CanvasRenderingContext2D_restore_Callback_RESOLVER_STRING_0_";

Native_CanvasRenderingContext2D_rotate_Callback(mthis, angle) native "CanvasRenderingContext2D_rotate_Callback_RESOLVER_STRING_1_float";

Native_CanvasRenderingContext2D_save_Callback(mthis) native "CanvasRenderingContext2D_save_Callback_RESOLVER_STRING_0_";

Native_CanvasRenderingContext2D_scale_Callback(mthis, sx, sy) native "CanvasRenderingContext2D_scale_Callback_RESOLVER_STRING_2_float_float";

Native_CanvasRenderingContext2D_setLineDash_Callback(mthis, dash) native "CanvasRenderingContext2D_setLineDash_Callback_RESOLVER_STRING_1_sequence<float>";

Native_CanvasRenderingContext2D_setTransform_Callback(mthis, m11, m12, m21, m22, dx, dy) native "CanvasRenderingContext2D_setTransform_Callback_RESOLVER_STRING_6_float_float_float_float_float_float";

Native_CanvasRenderingContext2D_stroke_Callback(mthis) native "CanvasRenderingContext2D_stroke_Callback_RESOLVER_STRING_0_";

Native_CanvasRenderingContext2D_strokeRect_Callback(mthis, x, y, width, height) native "CanvasRenderingContext2D_strokeRect_Callback_RESOLVER_STRING_4_float_float_float_float";

  // Generated overload resolver
Native_CanvasRenderingContext2D_strokeText(mthis, text, x, y, maxWidth) {
    if (maxWidth != null) {
      Native_CanvasRenderingContext2D__strokeText_1_Callback(mthis, text, x, y, maxWidth);
      return;
    }
    Native_CanvasRenderingContext2D__strokeText_2_Callback(mthis, text, x, y);
    return;
  }

Native_CanvasRenderingContext2D__strokeText_1_Callback(mthis, text, x, y, maxWidth) native "CanvasRenderingContext2D_strokeText_Callback_RESOLVER_STRING_4_DOMString_float_float_float";

Native_CanvasRenderingContext2D__strokeText_2_Callback(mthis, text, x, y) native "CanvasRenderingContext2D_strokeText_Callback_RESOLVER_STRING_3_DOMString_float_float";

Native_CanvasRenderingContext2D_transform_Callback(mthis, m11, m12, m21, m22, dx, dy) native "CanvasRenderingContext2D_transform_Callback_RESOLVER_STRING_6_float_float_float_float_float_float";

Native_CanvasRenderingContext2D_translate_Callback(mthis, tx, ty) native "CanvasRenderingContext2D_translate_Callback_RESOLVER_STRING_2_float_float";

Native_CanvasRenderingContext2D_webkitGetImageDataHD_Callback(mthis, sx, sy, sw, sh) native "CanvasRenderingContext2D_webkitGetImageDataHD_Callback_RESOLVER_STRING_4_float_float_float_float";

  // Generated overload resolver
Native_CanvasRenderingContext2D_putImageDataHD(mthis, imagedata, dx, dy, dirtyX, dirtyY, dirtyWidth, dirtyHeight) {
    if ((dy is num || dy == null) && (dx is num || dx == null) && (imagedata is ImageData || imagedata == null) && dirtyX == null && dirtyY == null && dirtyWidth == null && dirtyHeight == null) {
      Native_CanvasRenderingContext2D__webkitPutImageDataHD_1_Callback(mthis, imagedata, dx, dy);
      return;
    }
    if ((dirtyHeight is num || dirtyHeight == null) && (dirtyWidth is num || dirtyWidth == null) && (dirtyY is num || dirtyY == null) && (dirtyX is num || dirtyX == null) && (dy is num || dy == null) && (dx is num || dx == null) && (imagedata is ImageData || imagedata == null)) {
      Native_CanvasRenderingContext2D__webkitPutImageDataHD_2_Callback(mthis, imagedata, dx, dy, dirtyX, dirtyY, dirtyWidth, dirtyHeight);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

Native_CanvasRenderingContext2D__webkitPutImageDataHD_1_Callback(mthis, imagedata, dx, dy) native "CanvasRenderingContext2D_webkitPutImageDataHD_Callback_RESOLVER_STRING_3_ImageData_float_float";

Native_CanvasRenderingContext2D__webkitPutImageDataHD_2_Callback(mthis, imagedata, dx, dy, dirtyX, dirtyY, dirtyWidth, dirtyHeight) native "CanvasRenderingContext2D_webkitPutImageDataHD_Callback_RESOLVER_STRING_7_ImageData_float_float_float_float_float_float";

Native_ClientRect_bottom_Getter(mthis) native "ClientRect_bottom_Getter";

Native_ClientRect_height_Getter(mthis) native "ClientRect_height_Getter";

Native_ClientRect_left_Getter(mthis) native "ClientRect_left_Getter";

Native_ClientRect_right_Getter(mthis) native "ClientRect_right_Getter";

Native_ClientRect_top_Getter(mthis) native "ClientRect_top_Getter";

Native_ClientRect_width_Getter(mthis) native "ClientRect_width_Getter";

Native_ClientRectList_length_Getter(mthis) native "ClientRectList_length_Getter";

Native_ClientRectList_NativeIndexed_Getter(mthis, index) native "ClientRectList_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_ClientRectList_item_Callback(mthis, index) native "ClientRectList_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_Clipboard_dropEffect_Getter(mthis) native "DataTransfer_dropEffect_Getter";

Native_Clipboard_dropEffect_Setter(mthis, value) native "DataTransfer_dropEffect_Setter";

Native_Clipboard_effectAllowed_Getter(mthis) native "DataTransfer_effectAllowed_Getter";

Native_Clipboard_effectAllowed_Setter(mthis, value) native "DataTransfer_effectAllowed_Setter";

Native_Clipboard_files_Getter(mthis) native "DataTransfer_files_Getter";

Native_Clipboard_items_Getter(mthis) native "DataTransfer_items_Getter";

Native_Clipboard_types_Getter(mthis) native "DataTransfer_types_Getter";

  // Generated overload resolver
Native_Clipboard_clearData(mthis, type) {
    if (type != null) {
      Native_Clipboard__clearData_1_Callback(mthis, type);
      return;
    }
    Native_Clipboard__clearData_2_Callback(mthis);
    return;
  }

Native_Clipboard__clearData_1_Callback(mthis, type) native "DataTransfer_clearData_Callback_RESOLVER_STRING_1_DOMString";

Native_Clipboard__clearData_2_Callback(mthis) native "DataTransfer_clearData_Callback_RESOLVER_STRING_0_";

Native_Clipboard_getData_Callback(mthis, type) native "DataTransfer_getData_Callback_RESOLVER_STRING_1_DOMString";

Native_Clipboard_setData_Callback(mthis, type, data) native "DataTransfer_setData_Callback_RESOLVER_STRING_2_DOMString_DOMString";

Native_Clipboard_setDragImage_Callback(mthis, image, x, y) native "DataTransfer_setDragImage_Callback_RESOLVER_STRING_3_Element_long_long";

Native_CloseEvent_code_Getter(mthis) native "CloseEvent_code_Getter";

Native_CloseEvent_reason_Getter(mthis) native "CloseEvent_reason_Getter";

Native_CloseEvent_wasClean_Getter(mthis) native "CloseEvent_wasClean_Getter";

  // Generated overload resolver
Native_Comment_Comment(data) {
    return Native_Comment__create_1constructorCallback(data);
  }

Native_Comment__create_1constructorCallback(data) native "Comment_constructorCallback_RESOLVER_STRING_1_DOMString";

Native_UIEvent_charCode_Getter(mthis) native "UIEvent_charCode_Getter";

Native_UIEvent_detail_Getter(mthis) native "UIEvent_detail_Getter";

Native_UIEvent_keyCode_Getter(mthis) native "UIEvent_keyCode_Getter";

Native_UIEvent_layerX_Getter(mthis) native "UIEvent_layerX_Getter";

Native_UIEvent_layerY_Getter(mthis) native "UIEvent_layerY_Getter";

Native_UIEvent_pageX_Getter(mthis) native "UIEvent_pageX_Getter";

Native_UIEvent_pageY_Getter(mthis) native "UIEvent_pageY_Getter";

Native_UIEvent_view_Getter(mthis) native "UIEvent_view_Getter";

Native_UIEvent_which_Getter(mthis) native "UIEvent_which_Getter";

Native_UIEvent_initUIEvent_Callback(mthis, type, canBubble, cancelable, view, detail) native "UIEvent_initUIEvent_Callback_RESOLVER_STRING_5_DOMString_boolean_boolean_Window_long";

Native_CompositionEvent_activeSegmentEnd_Getter(mthis) native "CompositionEvent_activeSegmentEnd_Getter";

Native_CompositionEvent_activeSegmentStart_Getter(mthis) native "CompositionEvent_activeSegmentStart_Getter";

Native_CompositionEvent_data_Getter(mthis) native "CompositionEvent_data_Getter";

Native_CompositionEvent_initCompositionEvent_Callback(mthis, typeArg, canBubbleArg, cancelableArg, viewArg, dataArg) native "CompositionEvent_initCompositionEvent_Callback_RESOLVER_STRING_5_DOMString_boolean_boolean_Window_DOMString";

Native_ConsoleBase_assertCondition_Callback(mthis, condition, arg) native "ConsoleBase_assert_Callback_RESOLVER_STRING_2_boolean_object";

Native_ConsoleBase_clear_Callback(mthis, arg) native "ConsoleBase_clear_Callback_RESOLVER_STRING_1_object";

Native_ConsoleBase_count_Callback(mthis, arg) native "ConsoleBase_count_Callback_RESOLVER_STRING_1_object";

Native_ConsoleBase_debug_Callback(mthis, arg) native "ConsoleBase_debug_Callback_RESOLVER_STRING_1_object";

Native_ConsoleBase_dir_Callback(mthis, arg) native "ConsoleBase_dir_Callback_RESOLVER_STRING_1_object";

Native_ConsoleBase_dirxml_Callback(mthis, arg) native "ConsoleBase_dirxml_Callback_RESOLVER_STRING_1_object";

Native_ConsoleBase_error_Callback(mthis, arg) native "ConsoleBase_error_Callback_RESOLVER_STRING_1_object";

Native_ConsoleBase_group_Callback(mthis, arg) native "ConsoleBase_group_Callback_RESOLVER_STRING_1_object";

Native_ConsoleBase_groupCollapsed_Callback(mthis, arg) native "ConsoleBase_groupCollapsed_Callback_RESOLVER_STRING_1_object";

Native_ConsoleBase_groupEnd_Callback(mthis) native "ConsoleBase_groupEnd_Callback_RESOLVER_STRING_0_";

Native_ConsoleBase_info_Callback(mthis, arg) native "ConsoleBase_info_Callback_RESOLVER_STRING_1_object";

Native_ConsoleBase_log_Callback(mthis, arg) native "ConsoleBase_log_Callback_RESOLVER_STRING_1_object";

Native_ConsoleBase_markTimeline_Callback(mthis, title) native "ConsoleBase_markTimeline_Callback_RESOLVER_STRING_1_DOMString";

Native_ConsoleBase_profile_Callback(mthis, title) native "ConsoleBase_profile_Callback_RESOLVER_STRING_1_DOMString";

Native_ConsoleBase_profileEnd_Callback(mthis, title) native "ConsoleBase_profileEnd_Callback_RESOLVER_STRING_1_DOMString";

Native_ConsoleBase_table_Callback(mthis, arg) native "ConsoleBase_table_Callback_RESOLVER_STRING_1_object";

Native_ConsoleBase_time_Callback(mthis, title) native "ConsoleBase_time_Callback_RESOLVER_STRING_1_DOMString";

Native_ConsoleBase_timeEnd_Callback(mthis, title) native "ConsoleBase_timeEnd_Callback_RESOLVER_STRING_1_DOMString";

Native_ConsoleBase_timeStamp_Callback(mthis, title) native "ConsoleBase_timeStamp_Callback_RESOLVER_STRING_1_DOMString";

Native_ConsoleBase_timeline_Callback(mthis, title) native "ConsoleBase_timeline_Callback_RESOLVER_STRING_1_DOMString";

Native_ConsoleBase_timelineEnd_Callback(mthis, title) native "ConsoleBase_timelineEnd_Callback_RESOLVER_STRING_1_DOMString";

Native_ConsoleBase_trace_Callback(mthis, arg) native "ConsoleBase_trace_Callback_RESOLVER_STRING_1_object";

Native_ConsoleBase_warn_Callback(mthis, arg) native "ConsoleBase_warn_Callback_RESOLVER_STRING_1_object";

Native_Console_memory_Getter(mthis) native "Console_memory_Getter";

Native_ConvolverNode_buffer_Getter(mthis) native "ConvolverNode_buffer_Getter";

Native_ConvolverNode_buffer_Setter(mthis, value) native "ConvolverNode_buffer_Setter";

Native_ConvolverNode_normalize_Getter(mthis) native "ConvolverNode_normalize_Getter";

Native_ConvolverNode_normalize_Setter(mthis, value) native "ConvolverNode_normalize_Setter";

Native_Coordinates_accuracy_Getter(mthis) native "Coordinates_accuracy_Getter";

Native_Coordinates_altitude_Getter(mthis) native "Coordinates_altitude_Getter";

Native_Coordinates_altitudeAccuracy_Getter(mthis) native "Coordinates_altitudeAccuracy_Getter";

Native_Coordinates_heading_Getter(mthis) native "Coordinates_heading_Getter";

Native_Coordinates_latitude_Getter(mthis) native "Coordinates_latitude_Getter";

Native_Coordinates_longitude_Getter(mthis) native "Coordinates_longitude_Getter";

Native_Coordinates_speed_Getter(mthis) native "Coordinates_speed_Getter";

Native_Crypto_subtle_Getter(mthis) native "Crypto_subtle_Getter";

Native_Crypto_getRandomValues_Callback(mthis, array) native "Crypto_getRandomValues_Callback";

Native_CustomEvent_detail_Getter(mthis) native "CustomEvent_detail_Getter";

Native_CustomEvent_initCustomEvent_Callback(mthis, typeArg, canBubbleArg, cancelableArg, detailArg) native "CustomEvent_initCustomEvent_Callback";

Native_DOMError_message_Getter(mthis) native "DOMError_message_Getter";

Native_DOMError_name_Getter(mthis) native "DOMError_name_Getter";

Native_DOMException_message_Getter(mthis) native "DOMException_message_Getter";

Native_DOMException_name_Getter(mthis) native "DOMException_name_Getter";

Native_DOMException_toString_Callback(mthis) native "DOMException_toString_Callback_RESOLVER_STRING_0_";

Native_DOMFileSystem_name_Getter(mthis) native "DOMFileSystem_name_Getter";

Native_DOMFileSystem_root_Getter(mthis) native "DOMFileSystem_root_Getter";

Native_DOMImplementation_createCSSStyleSheet_Callback(mthis, title, media) native "DOMImplementation_createCSSStyleSheet_Callback_RESOLVER_STRING_2_DOMString_DOMString";

Native_DOMImplementation_createDocument_Callback(mthis, namespaceURI, qualifiedName, doctype) native "DOMImplementation_createDocument_Callback_RESOLVER_STRING_3_DOMString_DOMString_DocumentType";

Native_DOMImplementation_createDocumentType_Callback(mthis, qualifiedName, publicId, systemId) native "DOMImplementation_createDocumentType_Callback_RESOLVER_STRING_3_DOMString_DOMString_DOMString";

Native_DOMImplementation_createHTMLDocument_Callback(mthis, title) native "DOMImplementation_createHTMLDocument_Callback_RESOLVER_STRING_1_DOMString";

Native_DOMImplementation_hasFeature_Callback(mthis, feature, version) native "DOMImplementation_hasFeature_Callback_RESOLVER_STRING_2_DOMString_DOMString";

  // Generated overload resolver
Native_DOMParser_DomParser() {
    return Native_DOMParser__create_1constructorCallback();
  }

Native_DOMParser__create_1constructorCallback() native "DOMParser_constructorCallback_RESOLVER_STRING_0_";

Native_DOMParser_parseFromString_Callback(mthis, str, contentType) native "DOMParser_parseFromString_Callback_RESOLVER_STRING_2_DOMString_DOMString";

Native_DOMTokenList_length_Getter(mthis) native "DOMTokenList_length_Getter";

Native_DOMTokenList_contains_Callback(mthis, token) native "DOMTokenList_contains_Callback_RESOLVER_STRING_1_DOMString";

Native_DOMTokenList_item_Callback(mthis, index) native "DOMTokenList_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_DOMTokenList_toString_Callback(mthis) native "DOMTokenList_toString_Callback_RESOLVER_STRING_0_";

  // Generated overload resolver
Native_DOMTokenList_toggle(mthis, token, force) {
    if (force != null) {
      return Native_DOMTokenList__toggle_1_Callback(mthis, token, force);
    }
    return Native_DOMTokenList__toggle_2_Callback(mthis, token);
  }

Native_DOMTokenList__toggle_1_Callback(mthis, token, force) native "DOMTokenList_toggle_Callback_RESOLVER_STRING_2_DOMString_boolean";

Native_DOMTokenList__toggle_2_Callback(mthis, token) native "DOMTokenList_toggle_Callback_RESOLVER_STRING_1_DOMString";

Native_DOMSettableTokenList_value_Getter(mthis) native "DOMSettableTokenList_value_Getter";

Native_DOMSettableTokenList_value_Setter(mthis, value) native "DOMSettableTokenList_value_Setter";

Native_DOMSettableTokenList___getter___Callback(mthis, index) native "DOMSettableTokenList___getter___Callback_RESOLVER_STRING_1_unsigned long";

Native_DOMStringList_length_Getter(mthis) native "DOMStringList_length_Getter";

Native_DOMStringList_NativeIndexed_Getter(mthis, index) native "DOMStringList_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_DOMStringList_contains_Callback(mthis, string) native "DOMStringList_contains_Callback_RESOLVER_STRING_1_DOMString";

Native_DOMStringList_item_Callback(mthis, index) native "DOMStringList_item_Callback_RESOLVER_STRING_1_unsigned long";

  // Generated overload resolver
Native_DOMStringMap___delete__(mthis, index_OR_name) {
    if ((index_OR_name is int || index_OR_name == null)) {
      return Native_DOMStringMap____delete___1_Callback(mthis, index_OR_name);
    }
    if ((index_OR_name is String || index_OR_name == null)) {
      return Native_DOMStringMap____delete___2_Callback(mthis, index_OR_name);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

Native_DOMStringMap____delete___1_Callback(mthis, index_OR_name) native "DOMStringMap___delete___Callback_RESOLVER_STRING_1_unsigned long";

Native_DOMStringMap____delete___2_Callback(mthis, index_OR_name) native "DOMStringMap___delete___Callback_RESOLVER_STRING_1_DOMString";

  // Generated overload resolver
Native_DOMStringMap___getter__(mthis, index_OR_name) {
    if ((index_OR_name is int || index_OR_name == null)) {
      return Native_DOMStringMap____getter___1_Callback(mthis, index_OR_name);
    }
    if ((index_OR_name is String || index_OR_name == null)) {
      return Native_DOMStringMap____getter___2_Callback(mthis, index_OR_name);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

Native_DOMStringMap____getter___1_Callback(mthis, index_OR_name) native "DOMStringMap___getter___Callback_RESOLVER_STRING_1_unsigned long";

Native_DOMStringMap____getter___2_Callback(mthis, index_OR_name) native "DOMStringMap___getter___Callback_RESOLVER_STRING_1_DOMString";

  // Generated overload resolver
Native_DOMStringMap___setter__(mthis, index_OR_name, value) {
    if ((value is String || value == null) && (index_OR_name is int || index_OR_name == null)) {
      Native_DOMStringMap____setter___1_Callback(mthis, index_OR_name, value);
      return;
    }
    if ((value is String || value == null) && (index_OR_name is String || index_OR_name == null)) {
      Native_DOMStringMap____setter___2_Callback(mthis, index_OR_name, value);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

Native_DOMStringMap____setter___1_Callback(mthis, index_OR_name, value) native "DOMStringMap___setter___Callback_RESOLVER_STRING_2_unsigned long_DOMString";

Native_DOMStringMap____setter___2_Callback(mthis, index_OR_name, value) native "DOMStringMap___setter___Callback_RESOLVER_STRING_2_DOMString_DOMString";

Native_DataTransferItem_kind_Getter(mthis) native "DataTransferItem_kind_Getter";

Native_DataTransferItem_type_Getter(mthis) native "DataTransferItem_type_Getter";

Native_DataTransferItem_getAsFile_Callback(mthis) native "DataTransferItem_getAsFile_Callback_RESOLVER_STRING_0_";

Native_DataTransferItem_getAsString_Callback(mthis, callback) native "DataTransferItem_getAsString_Callback_RESOLVER_STRING_1_StringCallback";

Native_DataTransferItem_webkitGetAsEntry_Callback(mthis) native "DataTransferItem_webkitGetAsEntry_Callback_RESOLVER_STRING_0_";

Native_DataTransferItemList_length_Getter(mthis) native "DataTransferItemList_length_Getter";

Native_DataTransferItemList___getter___Callback(mthis, index) native "DataTransferItemList___getter___Callback_RESOLVER_STRING_1_unsigned long";

  // Generated overload resolver
Native_DataTransferItemList_add(mthis, data_OR_file, type) {
    if ((data_OR_file is File || data_OR_file == null) && type == null) {
      return Native_DataTransferItemList__add_1_Callback(mthis, data_OR_file);
    }
    if ((type is String || type == null) && (data_OR_file is String || data_OR_file == null)) {
      return Native_DataTransferItemList__add_2_Callback(mthis, data_OR_file, type);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

Native_DataTransferItemList__add_1_Callback(mthis, data_OR_file) native "DataTransferItemList_add_Callback_RESOLVER_STRING_1_File";

Native_DataTransferItemList__add_2_Callback(mthis, data_OR_file, type) native "DataTransferItemList_add_Callback_RESOLVER_STRING_2_DOMString_DOMString";

Native_DataTransferItemList_addData_Callback(mthis, data, type) native "DataTransferItemList_add_Callback_RESOLVER_STRING_2_DOMString_DOMString";

Native_DataTransferItemList_addFile_Callback(mthis, file) native "DataTransferItemList_add_Callback_RESOLVER_STRING_1_File";

Native_DataTransferItemList_clear_Callback(mthis) native "DataTransferItemList_clear_Callback_RESOLVER_STRING_0_";

Native_DataTransferItemList_remove_Callback(mthis, index) native "DataTransferItemList_remove_Callback_RESOLVER_STRING_1_unsigned long";

Native_Database_version_Getter(mthis) native "Database_version_Getter";

Native_Database_changeVersion_Callback(mthis, oldVersion, newVersion, callback, errorCallback, successCallback) native "Database_changeVersion_Callback_RESOLVER_STRING_5_DOMString_DOMString_SQLTransactionCallback_SQLTransactionErrorCallback_VoidCallback";

Native_Database_readTransaction_Callback(mthis, callback, errorCallback, successCallback) native "Database_readTransaction_Callback_RESOLVER_STRING_3_SQLTransactionCallback_SQLTransactionErrorCallback_VoidCallback";

Native_Database_transaction_Callback(mthis, callback, errorCallback, successCallback) native "Database_transaction_Callback_RESOLVER_STRING_3_SQLTransactionCallback_SQLTransactionErrorCallback_VoidCallback";

Native_WindowBase64_atob_Callback(mthis, string) native "WindowBase64_atob_Callback_RESOLVER_STRING_1_DOMString";

Native_WindowBase64_btoa_Callback(mthis, string) native "WindowBase64_btoa_Callback_RESOLVER_STRING_1_DOMString";

Native_WindowTimers_clearInterval_Callback(mthis, handle) native "WindowTimers_clearInterval_Callback_RESOLVER_STRING_1_long";

Native_WindowTimers_clearTimeout_Callback(mthis, handle) native "WindowTimers_clearTimeout_Callback_RESOLVER_STRING_1_long";

Native_WindowTimers_setInterval_Callback(mthis, handler, timeout) native "WindowTimers_setInterval_Callback";

Native_WindowTimers_setTimeout_Callback(mthis, handler, timeout) native "WindowTimers_setTimeout_Callback";

Native_WorkerGlobalScope_console_Getter(mthis) native "WorkerGlobalScope_console_Getter";

Native_WorkerGlobalScope_crypto_Getter(mthis) native "WorkerGlobalScope_crypto_Getter";

Native_WorkerGlobalScope_indexedDB_Getter(mthis) native "WorkerGlobalScope_indexedDB_Getter";

Native_WorkerGlobalScope_location_Getter(mthis) native "WorkerGlobalScope_location_Getter";

Native_WorkerGlobalScope_navigator_Getter(mthis) native "WorkerGlobalScope_navigator_Getter";

Native_WorkerGlobalScope_performance_Getter(mthis) native "WorkerGlobalScope_performance_Getter";

Native_WorkerGlobalScope_self_Getter(mthis) native "WorkerGlobalScope_self_Getter";

Native_WorkerGlobalScope_webkitNotifications_Getter(mthis) native "WorkerGlobalScope_webkitNotifications_Getter";

Native_WorkerGlobalScope_close_Callback(mthis) native "WorkerGlobalScope_close_Callback_RESOLVER_STRING_0_";

Native_WorkerGlobalScope_openDatabase_Callback(mthis, name, version, displayName, estimatedSize, creationCallback) native "WorkerGlobalScope_openDatabase_Callback_RESOLVER_STRING_5_DOMString_DOMString_DOMString_unsigned long_DatabaseCallback";

Native_WorkerGlobalScope_openDatabaseSync_Callback(mthis, name, version, displayName, estimatedSize, creationCallback) native "WorkerGlobalScope_openDatabaseSync_Callback_RESOLVER_STRING_5_DOMString_DOMString_DOMString_unsigned long_DatabaseCallback";

Native_WorkerGlobalScope_webkitRequestFileSystem_Callback(mthis, type, size, successCallback, errorCallback) native "WorkerGlobalScope_webkitRequestFileSystem_Callback_RESOLVER_STRING_4_unsigned short_long long_FileSystemCallback_ErrorCallback";

Native_WorkerGlobalScope_webkitRequestFileSystemSync_Callback(mthis, type, size) native "WorkerGlobalScope_webkitRequestFileSystemSync_Callback_RESOLVER_STRING_2_unsigned short_long long";

Native_WorkerGlobalScope_webkitResolveLocalFileSystemSyncURL_Callback(mthis, url) native "WorkerGlobalScope_webkitResolveLocalFileSystemSyncURL_Callback_RESOLVER_STRING_1_DOMString";

Native_WorkerGlobalScope_webkitResolveLocalFileSystemURL_Callback(mthis, url, successCallback, errorCallback) native "WorkerGlobalScope_webkitResolveLocalFileSystemURL_Callback_RESOLVER_STRING_3_DOMString_EntryCallback_ErrorCallback";

Native_WorkerGlobalScope_atob_Callback(mthis, string) native "WorkerGlobalScope_atob_Callback_RESOLVER_STRING_1_DOMString";

Native_WorkerGlobalScope_btoa_Callback(mthis, string) native "WorkerGlobalScope_btoa_Callback_RESOLVER_STRING_1_DOMString";

Native_WorkerGlobalScope_clearInterval_Callback(mthis, handle) native "WorkerGlobalScope_clearInterval_Callback_RESOLVER_STRING_1_long";

Native_WorkerGlobalScope_clearTimeout_Callback(mthis, handle) native "WorkerGlobalScope_clearTimeout_Callback_RESOLVER_STRING_1_long";

Native_WorkerGlobalScope_setInterval_Callback(mthis, handler, timeout) native "WorkerGlobalScope_setInterval_Callback";

Native_WorkerGlobalScope_setTimeout_Callback(mthis, handler, timeout) native "WorkerGlobalScope_setTimeout_Callback";

Native_DedicatedWorkerGlobalScope_postMessage_Callback(mthis, message, messagePorts) native "DedicatedWorkerGlobalScope_postMessage_Callback";

Native_DelayNode_delayTime_Getter(mthis) native "DelayNode_delayTime_Getter";

Native_DeprecatedStorageInfo_queryUsageAndQuota_Callback(mthis, storageType, usageCallback, errorCallback) native "DeprecatedStorageInfo_queryUsageAndQuota_Callback_RESOLVER_STRING_3_unsigned short_StorageUsageCallback_StorageErrorCallback";

Native_DeprecatedStorageInfo_requestQuota_Callback(mthis, storageType, newQuotaInBytes, quotaCallback, errorCallback) native "DeprecatedStorageInfo_requestQuota_Callback_RESOLVER_STRING_4_unsigned short_unsigned long long_StorageQuotaCallback_StorageErrorCallback";

Native_DeprecatedStorageQuota_queryUsageAndQuota_Callback(mthis, usageCallback, errorCallback) native "DeprecatedStorageQuota_queryUsageAndQuota_Callback_RESOLVER_STRING_2_StorageUsageCallback_StorageErrorCallback";

Native_DeprecatedStorageQuota_requestQuota_Callback(mthis, newQuotaInBytes, quotaCallback, errorCallback) native "DeprecatedStorageQuota_requestQuota_Callback_RESOLVER_STRING_3_unsigned long long_StorageQuotaCallback_StorageErrorCallback";

Native_DeviceAcceleration_x_Getter(mthis) native "DeviceAcceleration_x_Getter";

Native_DeviceAcceleration_y_Getter(mthis) native "DeviceAcceleration_y_Getter";

Native_DeviceAcceleration_z_Getter(mthis) native "DeviceAcceleration_z_Getter";

Native_DeviceMotionEvent_acceleration_Getter(mthis) native "DeviceMotionEvent_acceleration_Getter";

Native_DeviceMotionEvent_accelerationIncludingGravity_Getter(mthis) native "DeviceMotionEvent_accelerationIncludingGravity_Getter";

Native_DeviceMotionEvent_interval_Getter(mthis) native "DeviceMotionEvent_interval_Getter";

Native_DeviceMotionEvent_rotationRate_Getter(mthis) native "DeviceMotionEvent_rotationRate_Getter";

Native_DeviceMotionEvent_initDeviceMotionEvent_Callback(mthis, type, bubbles, cancelable, acceleration, accelerationIncludingGravity, rotationRate, interval) native "DeviceMotionEvent_initDeviceMotionEvent_Callback";

Native_DeviceOrientationEvent_absolute_Getter(mthis) native "DeviceOrientationEvent_absolute_Getter";

Native_DeviceOrientationEvent_alpha_Getter(mthis) native "DeviceOrientationEvent_alpha_Getter";

Native_DeviceOrientationEvent_beta_Getter(mthis) native "DeviceOrientationEvent_beta_Getter";

Native_DeviceOrientationEvent_gamma_Getter(mthis) native "DeviceOrientationEvent_gamma_Getter";

Native_DeviceOrientationEvent_initDeviceOrientationEvent_Callback(mthis, type, bubbles, cancelable, alpha, beta, gamma, absolute) native "DeviceOrientationEvent_initDeviceOrientationEvent_Callback";

Native_DeviceRotationRate_alpha_Getter(mthis) native "DeviceRotationRate_alpha_Getter";

Native_DeviceRotationRate_beta_Getter(mthis) native "DeviceRotationRate_beta_Getter";

Native_DeviceRotationRate_gamma_Getter(mthis) native "DeviceRotationRate_gamma_Getter";

Native_Entry_filesystem_Getter(mthis) native "Entry_filesystem_Getter";

Native_Entry_fullPath_Getter(mthis) native "Entry_fullPath_Getter";

Native_Entry_isDirectory_Getter(mthis) native "Entry_isDirectory_Getter";

Native_Entry_isFile_Getter(mthis) native "Entry_isFile_Getter";

Native_Entry_name_Getter(mthis) native "Entry_name_Getter";

  // Generated overload resolver
Native_Entry__copyTo(mthis, parent, name, successCallback, errorCallback) {
    if (name != null) {
      Native_Entry__copyTo_1_Callback(mthis, parent, name, successCallback, errorCallback);
      return;
    }
    Native_Entry__copyTo_2_Callback(mthis, parent);
    return;
  }

Native_Entry__copyTo_1_Callback(mthis, parent, name, successCallback, errorCallback) native "Entry_copyTo_Callback_RESOLVER_STRING_4_DirectoryEntry_DOMString_EntryCallback_ErrorCallback";

Native_Entry__copyTo_2_Callback(mthis, parent) native "Entry_copyTo_Callback_RESOLVER_STRING_1_DirectoryEntry";

Native_Entry_getMetadata_Callback(mthis, successCallback, errorCallback) native "Entry_getMetadata_Callback_RESOLVER_STRING_2_MetadataCallback_ErrorCallback";

Native_Entry_getParent_Callback(mthis, successCallback, errorCallback) native "Entry_getParent_Callback_RESOLVER_STRING_2_EntryCallback_ErrorCallback";

  // Generated overload resolver
Native_Entry__moveTo(mthis, parent, name, successCallback, errorCallback) {
    if (name != null) {
      Native_Entry__moveTo_1_Callback(mthis, parent, name, successCallback, errorCallback);
      return;
    }
    Native_Entry__moveTo_2_Callback(mthis, parent);
    return;
  }

Native_Entry__moveTo_1_Callback(mthis, parent, name, successCallback, errorCallback) native "Entry_moveTo_Callback_RESOLVER_STRING_4_DirectoryEntry_DOMString_EntryCallback_ErrorCallback";

Native_Entry__moveTo_2_Callback(mthis, parent) native "Entry_moveTo_Callback_RESOLVER_STRING_1_DirectoryEntry";

Native_Entry_remove_Callback(mthis, successCallback, errorCallback) native "Entry_remove_Callback_RESOLVER_STRING_2_VoidCallback_ErrorCallback";

Native_Entry_toURL_Callback(mthis) native "Entry_toURL_Callback_RESOLVER_STRING_0_";

Native_DirectoryEntry_createReader_Callback(mthis) native "DirectoryEntry_createReader_Callback_RESOLVER_STRING_0_";

Native_DirectoryEntry_getDirectory_Callback(mthis, path, options, successCallback, errorCallback) native "DirectoryEntry_getDirectory_Callback_RESOLVER_STRING_4_DOMString_Dictionary_EntryCallback_ErrorCallback";

Native_DirectoryEntry_getFile_Callback(mthis, path, options, successCallback, errorCallback) native "DirectoryEntry_getFile_Callback_RESOLVER_STRING_4_DOMString_Dictionary_EntryCallback_ErrorCallback";

Native_DirectoryEntry_removeRecursively_Callback(mthis, successCallback, errorCallback) native "DirectoryEntry_removeRecursively_Callback_RESOLVER_STRING_2_VoidCallback_ErrorCallback";

Native_DirectoryReader_readEntries_Callback(mthis, successCallback, errorCallback) native "DirectoryReader_readEntries_Callback_RESOLVER_STRING_2_EntriesCallback_ErrorCallback";

Native_ParentNode_childElementCount_Getter(mthis) native "ParentNode_childElementCount_Getter";

Native_ParentNode_children_Getter(mthis) native "ParentNode_children_Getter";

Native_ParentNode_firstElementChild_Getter(mthis) native "ParentNode_firstElementChild_Getter";

Native_ParentNode_lastElementChild_Getter(mthis) native "ParentNode_lastElementChild_Getter";

Native_Document_activeElement_Getter(mthis) native "Document_activeElement_Getter";

Native_Document_body_Getter(mthis) native "Document_body_Getter";

Native_Document_body_Setter(mthis, value) native "Document_body_Setter";

Native_Document_cookie_Getter(mthis) native "Document_cookie_Getter";

Native_Document_cookie_Setter(mthis, value) native "Document_cookie_Setter";

Native_Document_currentScript_Getter(mthis) native "Document_currentScript_Getter";

Native_Document_defaultView_Getter(mthis) native "Document_defaultView_Getter";

Native_Document_documentElement_Getter(mthis) native "Document_documentElement_Getter";

Native_Document_domain_Getter(mthis) native "Document_domain_Getter";

Native_Document_fonts_Getter(mthis) native "Document_fonts_Getter";

Native_Document_head_Getter(mthis) native "Document_head_Getter";

Native_Document_hidden_Getter(mthis) native "Document_hidden_Getter";

Native_Document_implementation_Getter(mthis) native "Document_implementation_Getter";

Native_Document_lastModified_Getter(mthis) native "Document_lastModified_Getter";

Native_Document_preferredStylesheetSet_Getter(mthis) native "Document_preferredStylesheetSet_Getter";

Native_Document_readyState_Getter(mthis) native "Document_readyState_Getter";

Native_Document_referrer_Getter(mthis) native "Document_referrer_Getter";

Native_Document_rootElement_Getter(mthis) native "Document_rootElement_Getter";

Native_Document_selectedStylesheetSet_Getter(mthis) native "Document_selectedStylesheetSet_Getter";

Native_Document_selectedStylesheetSet_Setter(mthis, value) native "Document_selectedStylesheetSet_Setter";

Native_Document_styleSheets_Getter(mthis) native "Document_styleSheets_Getter";

Native_Document_timeline_Getter(mthis) native "Document_timeline_Getter";

Native_Document_title_Getter(mthis) native "Document_title_Getter";

Native_Document_title_Setter(mthis, value) native "Document_title_Setter";

Native_Document_visibilityState_Getter(mthis) native "Document_visibilityState_Getter";

Native_Document_webkitFullscreenElement_Getter(mthis) native "Document_webkitFullscreenElement_Getter";

Native_Document_webkitFullscreenEnabled_Getter(mthis) native "Document_webkitFullscreenEnabled_Getter";

Native_Document_webkitHidden_Getter(mthis) native "Document_webkitHidden_Getter";

Native_Document_webkitPointerLockElement_Getter(mthis) native "Document_webkitPointerLockElement_Getter";

Native_Document_webkitVisibilityState_Getter(mthis) native "Document_webkitVisibilityState_Getter";

Native_Document_adoptNode_Callback(mthis, node) native "Document_adoptNode_Callback_RESOLVER_STRING_1_Node";

Native_Document_caretRangeFromPoint_Callback(mthis, x, y) native "Document_caretRangeFromPoint_Callback_RESOLVER_STRING_2_long_long";

Native_Document_createDocumentFragment_Callback(mthis) native "Document_createDocumentFragment_Callback_RESOLVER_STRING_0_";

Native_Document_createElement_Callback(mthis, localName_OR_tagName, typeExtension) native "Document_createElement_Callback";

Native_Document_createElementNS_Callback(mthis, namespaceURI, qualifiedName, typeExtension) native "Document_createElementNS_Callback";

  // Generated overload resolver
Native_Document__createEvent(mthis, eventType) {
    if (eventType != null) {
      return Native_Document__createEvent_1_Callback(mthis, eventType);
    }
    return Native_Document__createEvent_2_Callback(mthis);
  }

Native_Document__createEvent_1_Callback(mthis, eventType) native "Document_createEvent_Callback_RESOLVER_STRING_1_DOMString";

Native_Document__createEvent_2_Callback(mthis) native "Document_createEvent_Callback_RESOLVER_STRING_0_";

  // Generated overload resolver
Native_Document__createNodeIterator(mthis, root, whatToShow, filter) {
    if (filter != null) {
      return Native_Document__createNodeIterator_1_Callback(mthis, root, whatToShow, filter);
    }
    if (whatToShow != null) {
      return Native_Document__createNodeIterator_2_Callback(mthis, root, whatToShow);
    }
    return Native_Document__createNodeIterator_3_Callback(mthis, root);
  }

Native_Document__createNodeIterator_1_Callback(mthis, root, whatToShow, filter) native "Document_createNodeIterator_Callback_RESOLVER_STRING_3_Node_unsigned long_NodeFilter";

Native_Document__createNodeIterator_2_Callback(mthis, root, whatToShow) native "Document_createNodeIterator_Callback_RESOLVER_STRING_2_Node_unsigned long";

Native_Document__createNodeIterator_3_Callback(mthis, root) native "Document_createNodeIterator_Callback_RESOLVER_STRING_1_Node";

Native_Document_createRange_Callback(mthis) native "Document_createRange_Callback_RESOLVER_STRING_0_";

Native_Document_createTextNode_Callback(mthis, data) native "Document_createTextNode_Callback_RESOLVER_STRING_1_DOMString";

Native_Document_createTouch_Callback(mthis, window, target, identifier, pageX, pageY, screenX, screenY, webkitRadiusX, webkitRadiusY, webkitRotationAngle, webkitForce) native "Document_createTouch_Callback_RESOLVER_STRING_11_Window_EventTarget_long_long_long_long_long_long_long_float_float";

  // Generated overload resolver
Native_Document__createTreeWalker(mthis, root, whatToShow, filter) {
    if (filter != null) {
      return Native_Document__createTreeWalker_1_Callback(mthis, root, whatToShow, filter);
    }
    if (whatToShow != null) {
      return Native_Document__createTreeWalker_2_Callback(mthis, root, whatToShow);
    }
    return Native_Document__createTreeWalker_3_Callback(mthis, root);
  }

Native_Document__createTreeWalker_1_Callback(mthis, root, whatToShow, filter) native "Document_createTreeWalker_Callback_RESOLVER_STRING_3_Node_unsigned long_NodeFilter";

Native_Document__createTreeWalker_2_Callback(mthis, root, whatToShow) native "Document_createTreeWalker_Callback_RESOLVER_STRING_2_Node_unsigned long";

Native_Document__createTreeWalker_3_Callback(mthis, root) native "Document_createTreeWalker_Callback_RESOLVER_STRING_1_Node";

Native_Document_elementFromPoint_Callback(mthis, x, y) native "Document_elementFromPoint_Callback_RESOLVER_STRING_2_long_long";

Native_Document_execCommand_Callback(mthis, command, userInterface, value) native "Document_execCommand_Callback_RESOLVER_STRING_3_DOMString_boolean_DOMString";

Native_Document_getCSSCanvasContext_Callback(mthis, contextId, name, width, height) native "Document_getCSSCanvasContext_Callback_RESOLVER_STRING_4_DOMString_DOMString_long_long";

Native_Document_getElementById_Callback(mthis, elementId) native "Document_getElementById_Callback_RESOLVER_STRING_1_DOMString";

Native_Document_getElementsByClassName_Callback(mthis, classNames) native "Document_getElementsByClassName_Callback_RESOLVER_STRING_1_DOMString";

Native_Document_getElementsByName_Callback(mthis, elementName) native "Document_getElementsByName_Callback_RESOLVER_STRING_1_DOMString";

Native_Document_getElementsByTagName_Callback(mthis, localName) native "Document_getElementsByTagName_Callback_RESOLVER_STRING_1_DOMString";

  // Generated overload resolver
Native_Document_importNode(mthis, node, deep) {
    if (deep != null) {
      return Native_Document__importNode_1_Callback(mthis, node, deep);
    }
    return Native_Document__importNode_2_Callback(mthis, node);
  }

Native_Document__importNode_1_Callback(mthis, node, deep) native "Document_importNode_Callback_RESOLVER_STRING_2_Node_boolean";

Native_Document__importNode_2_Callback(mthis, node) native "Document_importNode_Callback_RESOLVER_STRING_1_Node";

Native_Document_queryCommandEnabled_Callback(mthis, command) native "Document_queryCommandEnabled_Callback_RESOLVER_STRING_1_DOMString";

Native_Document_queryCommandIndeterm_Callback(mthis, command) native "Document_queryCommandIndeterm_Callback_RESOLVER_STRING_1_DOMString";

Native_Document_queryCommandState_Callback(mthis, command) native "Document_queryCommandState_Callback_RESOLVER_STRING_1_DOMString";

Native_Document_queryCommandSupported_Callback(mthis, command) native "Document_queryCommandSupported_Callback_RESOLVER_STRING_1_DOMString";

Native_Document_queryCommandValue_Callback(mthis, command) native "Document_queryCommandValue_Callback_RESOLVER_STRING_1_DOMString";

Native_Document_querySelector_Callback(mthis, selectors) native "Document_querySelector_Callback_RESOLVER_STRING_1_DOMString";

Native_Document_querySelectorAll_Callback(mthis, selectors) native "Document_querySelectorAll_Callback_RESOLVER_STRING_1_DOMString";

Native_Document_webkitExitFullscreen_Callback(mthis) native "Document_webkitExitFullscreen_Callback_RESOLVER_STRING_0_";

Native_Document_webkitExitPointerLock_Callback(mthis) native "Document_webkitExitPointerLock_Callback_RESOLVER_STRING_0_";

Native_Document_childElementCount_Getter(mthis) native "Document_childElementCount_Getter";

Native_Document_children_Getter(mthis) native "Document_children_Getter";

Native_Document_firstElementChild_Getter(mthis) native "Document_firstElementChild_Getter";

Native_Document_lastElementChild_Getter(mthis) native "Document_lastElementChild_Getter";

Native_DocumentFragment_querySelector_Callback(mthis, selectors) native "DocumentFragment_querySelector_Callback_RESOLVER_STRING_1_DOMString";

Native_DocumentFragment_querySelectorAll_Callback(mthis, selectors) native "DocumentFragment_querySelectorAll_Callback_RESOLVER_STRING_1_DOMString";

Native_DocumentFragment_childElementCount_Getter(mthis) native "DocumentFragment_childElementCount_Getter";

Native_DocumentFragment_firstElementChild_Getter(mthis) native "DocumentFragment_firstElementChild_Getter";

Native_DocumentFragment_lastElementChild_Getter(mthis) native "DocumentFragment_lastElementChild_Getter";

Native_DynamicsCompressorNode_attack_Getter(mthis) native "DynamicsCompressorNode_attack_Getter";

Native_DynamicsCompressorNode_knee_Getter(mthis) native "DynamicsCompressorNode_knee_Getter";

Native_DynamicsCompressorNode_ratio_Getter(mthis) native "DynamicsCompressorNode_ratio_Getter";

Native_DynamicsCompressorNode_reduction_Getter(mthis) native "DynamicsCompressorNode_reduction_Getter";

Native_DynamicsCompressorNode_release_Getter(mthis) native "DynamicsCompressorNode_release_Getter";

Native_DynamicsCompressorNode_threshold_Getter(mthis) native "DynamicsCompressorNode_threshold_Getter";

Native_Element_attributes_Getter(mthis) native "Element_attributes_Getter";

Native_Element_className_Getter(mthis) native "Element_className_Getter";

Native_Element_className_Setter(mthis, value) native "Element_className_Setter";

Native_Element_clientHeight_Getter(mthis) native "Element_clientHeight_Getter";

Native_Element_clientLeft_Getter(mthis) native "Element_clientLeft_Getter";

Native_Element_clientTop_Getter(mthis) native "Element_clientTop_Getter";

Native_Element_clientWidth_Getter(mthis) native "Element_clientWidth_Getter";

Native_Element_id_Getter(mthis) native "Element_id_Getter";

Native_Element_id_Setter(mthis, value) native "Element_id_Setter";

Native_Element_innerHTML_Getter(mthis) native "Element_innerHTML_Getter";

Native_Element_innerHTML_Setter(mthis, value) native "Element_innerHTML_Setter";

Native_Element_localName_Getter(mthis) native "Element_localName_Getter";

Native_Element_namespaceURI_Getter(mthis) native "Element_namespaceURI_Getter";

Native_Element_offsetHeight_Getter(mthis) native "Element_offsetHeight_Getter";

Native_Element_offsetLeft_Getter(mthis) native "Element_offsetLeft_Getter";

Native_Element_offsetParent_Getter(mthis) native "Element_offsetParent_Getter";

Native_Element_offsetTop_Getter(mthis) native "Element_offsetTop_Getter";

Native_Element_offsetWidth_Getter(mthis) native "Element_offsetWidth_Getter";

Native_Element_outerHTML_Getter(mthis) native "Element_outerHTML_Getter";

Native_Element_scrollHeight_Getter(mthis) native "Element_scrollHeight_Getter";

Native_Element_scrollLeft_Getter(mthis) native "Element_scrollLeft_Getter";

Native_Element_scrollLeft_Setter(mthis, value) native "Element_scrollLeft_Setter";

Native_Element_scrollTop_Getter(mthis) native "Element_scrollTop_Getter";

Native_Element_scrollTop_Setter(mthis, value) native "Element_scrollTop_Setter";

Native_Element_scrollWidth_Getter(mthis) native "Element_scrollWidth_Getter";

Native_Element_shadowRoot_Getter(mthis) native "Element_shadowRoot_Getter";

Native_Element_style_Getter(mthis) native "Element_style_Getter";

Native_Element_tagName_Getter(mthis) native "Element_tagName_Getter";

  // Generated overload resolver
Native_Element_animate(mthis, keyframes, timingInput) {
    if ((timingInput is Map || timingInput == null) && (keyframes is List<Map> || keyframes == null)) {
      return Native_Element__animate_1_Callback(mthis, keyframes, timingInput);
    }
    if ((timingInput is num || timingInput == null) && (keyframes is List<Map> || keyframes == null)) {
      return Native_Element__animate_2_Callback(mthis, keyframes, timingInput);
    }
    if ((keyframes is List<Map> || keyframes == null) && timingInput == null) {
      return Native_Element__animate_3_Callback(mthis, keyframes);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

Native_Element__animate_1_Callback(mthis, keyframes, timingInput) native "Element_animate_Callback_RESOLVER_STRING_2_sequence<Dictionary>_Dictionary";

Native_Element__animate_2_Callback(mthis, keyframes, timingInput) native "Element_animate_Callback_RESOLVER_STRING_2_sequence<Dictionary>_double";

Native_Element__animate_3_Callback(mthis, keyframes) native "Element_animate_Callback_RESOLVER_STRING_1_sequence<Dictionary>";

Native_Element_blur_Callback(mthis) native "Element_blur_Callback_RESOLVER_STRING_0_";

Native_Element_createShadowRoot_Callback(mthis) native "Element_createShadowRoot_Callback_RESOLVER_STRING_0_";

Native_Element_focus_Callback(mthis) native "Element_focus_Callback_RESOLVER_STRING_0_";

Native_Element_getAttribute_Callback(mthis, name) native "Element_getAttribute_Callback_RESOLVER_STRING_1_DOMString";

Native_Element_getAttributeNS_Callback(mthis, namespaceURI, localName) native "Element_getAttributeNS_Callback_RESOLVER_STRING_2_DOMString_DOMString";

Native_Element_getBoundingClientRect_Callback(mthis) native "Element_getBoundingClientRect_Callback_RESOLVER_STRING_0_";

Native_Element_getClientRects_Callback(mthis) native "Element_getClientRects_Callback_RESOLVER_STRING_0_";

Native_Element_getDestinationInsertionPoints_Callback(mthis) native "Element_getDestinationInsertionPoints_Callback_RESOLVER_STRING_0_";

Native_Element_getElementsByClassName_Callback(mthis, classNames) native "Element_getElementsByClassName_Callback_RESOLVER_STRING_1_DOMString";

Native_Element_getElementsByTagName_Callback(mthis, name) native "Element_getElementsByTagName_Callback_RESOLVER_STRING_1_DOMString";

Native_Element_hasAttribute_Callback(mthis, name) native "Element_hasAttribute_Callback_RESOLVER_STRING_1_DOMString";

Native_Element_hasAttributeNS_Callback(mthis, namespaceURI, localName) native "Element_hasAttributeNS_Callback_RESOLVER_STRING_2_DOMString_DOMString";

Native_Element_insertAdjacentElement_Callback(mthis, where, element) native "Element_insertAdjacentElement_Callback_RESOLVER_STRING_2_DOMString_Element";

Native_Element_insertAdjacentHTML_Callback(mthis, where, html) native "Element_insertAdjacentHTML_Callback_RESOLVER_STRING_2_DOMString_DOMString";

Native_Element_insertAdjacentText_Callback(mthis, where, text) native "Element_insertAdjacentText_Callback_RESOLVER_STRING_2_DOMString_DOMString";

Native_Element_matches_Callback(mthis, selectors) native "Element_matches_Callback_RESOLVER_STRING_1_DOMString";

Native_Element_querySelector_Callback(mthis, selectors) native "Element_querySelector_Callback_RESOLVER_STRING_1_DOMString";

Native_Element_querySelectorAll_Callback(mthis, selectors) native "Element_querySelectorAll_Callback_RESOLVER_STRING_1_DOMString";

Native_Element_removeAttribute_Callback(mthis, name) native "Element_removeAttribute_Callback_RESOLVER_STRING_1_DOMString";

Native_Element_removeAttributeNS_Callback(mthis, namespaceURI, localName) native "Element_removeAttributeNS_Callback_RESOLVER_STRING_2_DOMString_DOMString";

Native_Element_scrollByLines_Callback(mthis, lines) native "Element_scrollByLines_Callback_RESOLVER_STRING_1_long";

Native_Element_scrollByPages_Callback(mthis, pages) native "Element_scrollByPages_Callback_RESOLVER_STRING_1_long";

  // Generated overload resolver
Native_Element__scrollIntoView(mthis, alignWithTop) {
    if (alignWithTop != null) {
      Native_Element__scrollIntoView_1_Callback(mthis, alignWithTop);
      return;
    }
    Native_Element__scrollIntoView_2_Callback(mthis);
    return;
  }

Native_Element__scrollIntoView_1_Callback(mthis, alignWithTop) native "Element_scrollIntoView_Callback_RESOLVER_STRING_1_boolean";

Native_Element__scrollIntoView_2_Callback(mthis) native "Element_scrollIntoView_Callback_RESOLVER_STRING_0_";

  // Generated overload resolver
Native_Element__scrollIntoViewIfNeeded(mthis, centerIfNeeded) {
    if (centerIfNeeded != null) {
      Native_Element__scrollIntoViewIfNeeded_1_Callback(mthis, centerIfNeeded);
      return;
    }
    Native_Element__scrollIntoViewIfNeeded_2_Callback(mthis);
    return;
  }

Native_Element__scrollIntoViewIfNeeded_1_Callback(mthis, centerIfNeeded) native "Element_scrollIntoViewIfNeeded_Callback_RESOLVER_STRING_1_boolean";

Native_Element__scrollIntoViewIfNeeded_2_Callback(mthis) native "Element_scrollIntoViewIfNeeded_Callback_RESOLVER_STRING_0_";

Native_Element_setAttribute_Callback(mthis, name, value) native "Element_setAttribute_Callback_RESOLVER_STRING_2_DOMString_DOMString";

Native_Element_setAttributeNS_Callback(mthis, namespaceURI, qualifiedName, value) native "Element_setAttributeNS_Callback_RESOLVER_STRING_3_DOMString_DOMString_DOMString";

Native_Element_webkitRequestFullscreen_Callback(mthis) native "Element_webkitRequestFullscreen_Callback_RESOLVER_STRING_0_";

Native_Element_webkitRequestPointerLock_Callback(mthis) native "Element_webkitRequestPointerLock_Callback_RESOLVER_STRING_0_";

Native_Element_nextElementSibling_Getter(mthis) native "Element_nextElementSibling_Getter";

Native_Element_previousElementSibling_Getter(mthis) native "Element_previousElementSibling_Getter";

Native_Element_remove_Callback(mthis) native "Element_remove_Callback_RESOLVER_STRING_0_";

Native_Element_childElementCount_Getter(mthis) native "Element_childElementCount_Getter";

Native_Element_children_Getter(mthis) native "Element_children_Getter";

Native_Element_firstElementChild_Getter(mthis) native "Element_firstElementChild_Getter";

Native_Element_lastElementChild_Getter(mthis) native "Element_lastElementChild_Getter";

Native_ErrorEvent_colno_Getter(mthis) native "ErrorEvent_colno_Getter";

Native_ErrorEvent_error_Getter(mthis) native "ErrorEvent_error_Getter";

Native_ErrorEvent_filename_Getter(mthis) native "ErrorEvent_filename_Getter";

Native_ErrorEvent_lineno_Getter(mthis) native "ErrorEvent_lineno_Getter";

Native_ErrorEvent_message_Getter(mthis) native "ErrorEvent_message_Getter";

  // Generated overload resolver
Native_EventSource_EventSource(url, eventSourceInit) {
    return Native_EventSource__create_1constructorCallback(url, eventSourceInit);
  }

Native_EventSource__create_1constructorCallback(url, eventSourceInit) native "EventSource_constructorCallback_RESOLVER_STRING_2_DOMString_Dictionary";

Native_EventSource_readyState_Getter(mthis) native "EventSource_readyState_Getter";

Native_EventSource_url_Getter(mthis) native "EventSource_url_Getter";

Native_EventSource_withCredentials_Getter(mthis) native "EventSource_withCredentials_Getter";

Native_EventSource_close_Callback(mthis) native "EventSource_close_Callback_RESOLVER_STRING_0_";

Native_File_lastModified_Getter(mthis) native "File_lastModified_Getter";

Native_File_lastModifiedDate_Getter(mthis) native "File_lastModifiedDate_Getter";

Native_File_name_Getter(mthis) native "File_name_Getter";

Native_File_webkitRelativePath_Getter(mthis) native "File_webkitRelativePath_Getter";

Native_FileEntry_createWriter_Callback(mthis, successCallback, errorCallback) native "FileEntry_createWriter_Callback_RESOLVER_STRING_2_FileWriterCallback_ErrorCallback";

Native_FileEntry_file_Callback(mthis, successCallback, errorCallback) native "FileEntry_file_Callback_RESOLVER_STRING_2_FileCallback_ErrorCallback";

Native_FileError_code_Getter(mthis) native "FileError_code_Getter";

Native_FileList_length_Getter(mthis) native "FileList_length_Getter";

Native_FileList_NativeIndexed_Getter(mthis, index) native "FileList_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_FileList_item_Callback(mthis, index) native "FileList_item_Callback_RESOLVER_STRING_1_unsigned long";

  // Generated overload resolver
Native_FileReader_FileReader() {
    return Native_FileReader__create_1constructorCallback();
  }

Native_FileReader__create_1constructorCallback() native "FileReader_constructorCallback_RESOLVER_STRING_0_";

Native_FileReader_error_Getter(mthis) native "FileReader_error_Getter";

Native_FileReader_readyState_Getter(mthis) native "FileReader_readyState_Getter";

Native_FileReader_result_Getter(mthis) native "FileReader_result_Getter";

Native_FileReader_abort_Callback(mthis) native "FileReader_abort_Callback_RESOLVER_STRING_0_";

Native_FileReader_readAsArrayBuffer_Callback(mthis, blob) native "FileReader_readAsArrayBuffer_Callback_RESOLVER_STRING_1_Blob";

Native_FileReader_readAsDataURL_Callback(mthis, blob) native "FileReader_readAsDataURL_Callback_RESOLVER_STRING_1_Blob";

  // Generated overload resolver
Native_FileReader_readAsText(mthis, blob, encoding) {
    if (encoding != null) {
      Native_FileReader__readAsText_1_Callback(mthis, blob, encoding);
      return;
    }
    Native_FileReader__readAsText_2_Callback(mthis, blob);
    return;
  }

Native_FileReader__readAsText_1_Callback(mthis, blob, encoding) native "FileReader_readAsText_Callback_RESOLVER_STRING_2_Blob_DOMString";

Native_FileReader__readAsText_2_Callback(mthis, blob) native "FileReader_readAsText_Callback_RESOLVER_STRING_1_Blob";

  // Generated overload resolver
Native_FileReaderSync__FileReaderSync() {
    return Native_FileReaderSync__create_1constructorCallback();
  }

Native_FileReaderSync__create_1constructorCallback() native "FileReaderSync_constructorCallback_RESOLVER_STRING_0_";

Native_FileWriter_error_Getter(mthis) native "FileWriter_error_Getter";

Native_FileWriter_length_Getter(mthis) native "FileWriter_length_Getter";

Native_FileWriter_position_Getter(mthis) native "FileWriter_position_Getter";

Native_FileWriter_readyState_Getter(mthis) native "FileWriter_readyState_Getter";

Native_FileWriter_abort_Callback(mthis) native "FileWriter_abort_Callback_RESOLVER_STRING_0_";

Native_FileWriter_seek_Callback(mthis, position) native "FileWriter_seek_Callback_RESOLVER_STRING_1_long long";

Native_FileWriter_truncate_Callback(mthis, size) native "FileWriter_truncate_Callback_RESOLVER_STRING_1_long long";

Native_FileWriter_write_Callback(mthis, data) native "FileWriter_write_Callback_RESOLVER_STRING_1_Blob";

Native_FocusEvent_relatedTarget_Getter(mthis) native "FocusEvent_relatedTarget_Getter";

  // Generated overload resolver
Native_FontFace_FontFace(family, source, descriptors) {
    return Native_FontFace__create_1constructorCallback(family, source, descriptors);
  }

Native_FontFace__create_1constructorCallback(family, source, descriptors) native "FontFace_constructorCallback_RESOLVER_STRING_3_DOMString_DOMString_Dictionary";

Native_FontFace_family_Getter(mthis) native "FontFace_family_Getter";

Native_FontFace_family_Setter(mthis, value) native "FontFace_family_Setter";

Native_FontFace_featureSettings_Getter(mthis) native "FontFace_featureSettings_Getter";

Native_FontFace_featureSettings_Setter(mthis, value) native "FontFace_featureSettings_Setter";

Native_FontFace_status_Getter(mthis) native "FontFace_status_Getter";

Native_FontFace_stretch_Getter(mthis) native "FontFace_stretch_Getter";

Native_FontFace_stretch_Setter(mthis, value) native "FontFace_stretch_Setter";

Native_FontFace_style_Getter(mthis) native "FontFace_style_Getter";

Native_FontFace_style_Setter(mthis, value) native "FontFace_style_Setter";

Native_FontFace_unicodeRange_Getter(mthis) native "FontFace_unicodeRange_Getter";

Native_FontFace_unicodeRange_Setter(mthis, value) native "FontFace_unicodeRange_Setter";

Native_FontFace_variant_Getter(mthis) native "FontFace_variant_Getter";

Native_FontFace_variant_Setter(mthis, value) native "FontFace_variant_Setter";

Native_FontFace_weight_Getter(mthis) native "FontFace_weight_Getter";

Native_FontFace_weight_Setter(mthis, value) native "FontFace_weight_Setter";

Native_FontFace_load_Callback(mthis) native "FontFace_load_Callback_RESOLVER_STRING_0_";

Native_FontFaceSet_size_Getter(mthis) native "FontFaceSet_size_Getter";

Native_FontFaceSet_status_Getter(mthis) native "FontFaceSet_status_Getter";

Native_FontFaceSet_add_Callback(mthis, fontFace) native "FontFaceSet_add_Callback_RESOLVER_STRING_1_FontFace";

Native_FontFaceSet_check_Callback(mthis, font, text) native "FontFaceSet_check_Callback_RESOLVER_STRING_2_DOMString_DOMString";

Native_FontFaceSet_clear_Callback(mthis) native "FontFaceSet_clear_Callback_RESOLVER_STRING_0_";

Native_FontFaceSet_delete_Callback(mthis, fontFace) native "FontFaceSet_delete_Callback_RESOLVER_STRING_1_FontFace";

  // Generated overload resolver
Native_FontFaceSet_forEach(mthis, callback, thisArg) {
    if (thisArg != null) {
      Native_FontFaceSet__forEach_1_Callback(mthis, callback, thisArg);
      return;
    }
    Native_FontFaceSet__forEach_2_Callback(mthis, callback);
    return;
  }

Native_FontFaceSet__forEach_1_Callback(mthis, callback, thisArg) native "FontFaceSet_forEach_Callback_RESOLVER_STRING_2_FontFaceSetForEachCallback_ScriptValue";

Native_FontFaceSet__forEach_2_Callback(mthis, callback) native "FontFaceSet_forEach_Callback_RESOLVER_STRING_1_FontFaceSetForEachCallback";

Native_FontFaceSet_has_Callback(mthis, fontFace) native "FontFaceSet_has_Callback_RESOLVER_STRING_1_FontFace";

Native_FormData_constructorCallback(form) native "FormData_constructorCallback_RESOLVER_STRING_1_HTMLFormElement";

Native_FormData_append_Callback(mthis, name, value) native "FormData_append_Callback";

Native_FormData_appendBlob_Callback(mthis, name, value, filename) native "FormData_append_Callback";

Native_GainNode_gain_Getter(mthis) native "GainNode_gain_Getter";

Native_Gamepad_axes_Getter(mthis) native "Gamepad_axes_Getter";

Native_Gamepad_buttons_Getter(mthis) native "Gamepad_buttons_Getter";

Native_Gamepad_id_Getter(mthis) native "Gamepad_id_Getter";

Native_Gamepad_index_Getter(mthis) native "Gamepad_index_Getter";

Native_Gamepad_timestamp_Getter(mthis) native "Gamepad_timestamp_Getter";

Native_GamepadList_length_Getter(mthis) native "GamepadList_length_Getter";

Native_GamepadList_NativeIndexed_Getter(mthis, index) native "GamepadList_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_GamepadList_item_Callback(mthis, index) native "GamepadList_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_Geolocation_clearWatch_Callback(mthis, watchID) native "Geolocation_clearWatch_Callback_RESOLVER_STRING_1_long";

Native_Geolocation_getCurrentPosition_Callback(mthis, successCallback, errorCallback, options) native "Geolocation_getCurrentPosition_Callback";

Native_Geolocation_watchPosition_Callback(mthis, successCallback, errorCallback, options) native "Geolocation_watchPosition_Callback";

Native_Geoposition_coords_Getter(mthis) native "Geoposition_coords_Getter";

Native_Geoposition_timestamp_Getter(mthis) native "Geoposition_timestamp_Getter";

Native_HTMLAllCollection_item_Callback(mthis, index) native "HTMLAllCollection_item_Callback";

Native_HTMLElement_contentEditable_Getter(mthis) native "HTMLElement_contentEditable_Getter";

Native_HTMLElement_contentEditable_Setter(mthis, value) native "HTMLElement_contentEditable_Setter";

Native_HTMLElement_dir_Getter(mthis) native "HTMLElement_dir_Getter";

Native_HTMLElement_dir_Setter(mthis, value) native "HTMLElement_dir_Setter";

Native_HTMLElement_draggable_Getter(mthis) native "HTMLElement_draggable_Getter";

Native_HTMLElement_draggable_Setter(mthis, value) native "HTMLElement_draggable_Setter";

Native_HTMLElement_hidden_Getter(mthis) native "HTMLElement_hidden_Getter";

Native_HTMLElement_hidden_Setter(mthis, value) native "HTMLElement_hidden_Setter";

Native_HTMLElement_inputMethodContext_Getter(mthis) native "HTMLElement_inputMethodContext_Getter";

Native_HTMLElement_isContentEditable_Getter(mthis) native "HTMLElement_isContentEditable_Getter";

Native_HTMLElement_lang_Getter(mthis) native "HTMLElement_lang_Getter";

Native_HTMLElement_lang_Setter(mthis, value) native "HTMLElement_lang_Setter";

Native_HTMLElement_spellcheck_Getter(mthis) native "HTMLElement_spellcheck_Getter";

Native_HTMLElement_spellcheck_Setter(mthis, value) native "HTMLElement_spellcheck_Setter";

Native_HTMLElement_tabIndex_Getter(mthis) native "HTMLElement_tabIndex_Getter";

Native_HTMLElement_tabIndex_Setter(mthis, value) native "HTMLElement_tabIndex_Setter";

Native_HTMLElement_title_Getter(mthis) native "HTMLElement_title_Getter";

Native_HTMLElement_title_Setter(mthis, value) native "HTMLElement_title_Setter";

Native_HTMLElement_translate_Getter(mthis) native "HTMLElement_translate_Getter";

Native_HTMLElement_translate_Setter(mthis, value) native "HTMLElement_translate_Setter";

Native_HTMLElement_webkitdropzone_Getter(mthis) native "HTMLElement_webkitdropzone_Getter";

Native_HTMLElement_webkitdropzone_Setter(mthis, value) native "HTMLElement_webkitdropzone_Setter";

Native_HTMLElement_click_Callback(mthis) native "HTMLElement_click_Callback_RESOLVER_STRING_0_";

Native_URLUtils_hash_Getter(mthis) native "URL_hash_Getter";

Native_URLUtils_hash_Setter(mthis, value) native "URL_hash_Setter";

Native_URLUtils_host_Getter(mthis) native "URL_host_Getter";

Native_URLUtils_host_Setter(mthis, value) native "URL_host_Setter";

Native_URLUtils_hostname_Getter(mthis) native "URL_hostname_Getter";

Native_URLUtils_hostname_Setter(mthis, value) native "URL_hostname_Setter";

Native_URLUtils_href_Getter(mthis) native "URL_href_Getter";

Native_URLUtils_href_Setter(mthis, value) native "URL_href_Setter";

Native_URLUtils_origin_Getter(mthis) native "URL_origin_Getter";

Native_URLUtils_password_Getter(mthis) native "URL_password_Getter";

Native_URLUtils_password_Setter(mthis, value) native "URL_password_Setter";

Native_URLUtils_pathname_Getter(mthis) native "URL_pathname_Getter";

Native_URLUtils_pathname_Setter(mthis, value) native "URL_pathname_Setter";

Native_URLUtils_port_Getter(mthis) native "URL_port_Getter";

Native_URLUtils_port_Setter(mthis, value) native "URL_port_Setter";

Native_URLUtils_protocol_Getter(mthis) native "URL_protocol_Getter";

Native_URLUtils_protocol_Setter(mthis, value) native "URL_protocol_Setter";

Native_URLUtils_search_Getter(mthis) native "URL_search_Getter";

Native_URLUtils_search_Setter(mthis, value) native "URL_search_Setter";

Native_URLUtils_username_Getter(mthis) native "URL_username_Getter";

Native_URLUtils_username_Setter(mthis, value) native "URL_username_Setter";

Native_URLUtils_toString_Callback(mthis) native "URL_toString_Callback_RESOLVER_STRING_0_";

Native_HTMLAnchorElement_download_Getter(mthis) native "HTMLAnchorElement_download_Getter";

Native_HTMLAnchorElement_download_Setter(mthis, value) native "HTMLAnchorElement_download_Setter";

Native_HTMLAnchorElement_hreflang_Getter(mthis) native "HTMLAnchorElement_hreflang_Getter";

Native_HTMLAnchorElement_hreflang_Setter(mthis, value) native "HTMLAnchorElement_hreflang_Setter";

Native_HTMLAnchorElement_rel_Getter(mthis) native "HTMLAnchorElement_rel_Getter";

Native_HTMLAnchorElement_rel_Setter(mthis, value) native "HTMLAnchorElement_rel_Setter";

Native_HTMLAnchorElement_target_Getter(mthis) native "HTMLAnchorElement_target_Getter";

Native_HTMLAnchorElement_target_Setter(mthis, value) native "HTMLAnchorElement_target_Setter";

Native_HTMLAnchorElement_type_Getter(mthis) native "HTMLAnchorElement_type_Getter";

Native_HTMLAnchorElement_type_Setter(mthis, value) native "HTMLAnchorElement_type_Setter";

Native_HTMLAnchorElement_hash_Getter(mthis) native "HTMLAnchorElement_hash_Getter";

Native_HTMLAnchorElement_hash_Setter(mthis, value) native "HTMLAnchorElement_hash_Setter";

Native_HTMLAnchorElement_host_Getter(mthis) native "HTMLAnchorElement_host_Getter";

Native_HTMLAnchorElement_host_Setter(mthis, value) native "HTMLAnchorElement_host_Setter";

Native_HTMLAnchorElement_hostname_Getter(mthis) native "HTMLAnchorElement_hostname_Getter";

Native_HTMLAnchorElement_hostname_Setter(mthis, value) native "HTMLAnchorElement_hostname_Setter";

Native_HTMLAnchorElement_href_Getter(mthis) native "HTMLAnchorElement_href_Getter";

Native_HTMLAnchorElement_href_Setter(mthis, value) native "HTMLAnchorElement_href_Setter";

Native_HTMLAnchorElement_origin_Getter(mthis) native "HTMLAnchorElement_origin_Getter";

Native_HTMLAnchorElement_password_Getter(mthis) native "HTMLAnchorElement_password_Getter";

Native_HTMLAnchorElement_password_Setter(mthis, value) native "HTMLAnchorElement_password_Setter";

Native_HTMLAnchorElement_pathname_Getter(mthis) native "HTMLAnchorElement_pathname_Getter";

Native_HTMLAnchorElement_pathname_Setter(mthis, value) native "HTMLAnchorElement_pathname_Setter";

Native_HTMLAnchorElement_port_Getter(mthis) native "HTMLAnchorElement_port_Getter";

Native_HTMLAnchorElement_port_Setter(mthis, value) native "HTMLAnchorElement_port_Setter";

Native_HTMLAnchorElement_protocol_Getter(mthis) native "HTMLAnchorElement_protocol_Getter";

Native_HTMLAnchorElement_protocol_Setter(mthis, value) native "HTMLAnchorElement_protocol_Setter";

Native_HTMLAnchorElement_search_Getter(mthis) native "HTMLAnchorElement_search_Getter";

Native_HTMLAnchorElement_search_Setter(mthis, value) native "HTMLAnchorElement_search_Setter";

Native_HTMLAnchorElement_username_Getter(mthis) native "HTMLAnchorElement_username_Getter";

Native_HTMLAnchorElement_username_Setter(mthis, value) native "HTMLAnchorElement_username_Setter";

Native_HTMLAnchorElement_toString_Callback(mthis) native "HTMLAnchorElement_toString_Callback_RESOLVER_STRING_0_";

Native_HTMLAreaElement_alt_Getter(mthis) native "HTMLAreaElement_alt_Getter";

Native_HTMLAreaElement_alt_Setter(mthis, value) native "HTMLAreaElement_alt_Setter";

Native_HTMLAreaElement_coords_Getter(mthis) native "HTMLAreaElement_coords_Getter";

Native_HTMLAreaElement_coords_Setter(mthis, value) native "HTMLAreaElement_coords_Setter";

Native_HTMLAreaElement_shape_Getter(mthis) native "HTMLAreaElement_shape_Getter";

Native_HTMLAreaElement_shape_Setter(mthis, value) native "HTMLAreaElement_shape_Setter";

Native_HTMLAreaElement_target_Getter(mthis) native "HTMLAreaElement_target_Getter";

Native_HTMLAreaElement_target_Setter(mthis, value) native "HTMLAreaElement_target_Setter";

Native_HTMLAreaElement_hash_Getter(mthis) native "HTMLAreaElement_hash_Getter";

Native_HTMLAreaElement_hash_Setter(mthis, value) native "HTMLAreaElement_hash_Setter";

Native_HTMLAreaElement_host_Getter(mthis) native "HTMLAreaElement_host_Getter";

Native_HTMLAreaElement_host_Setter(mthis, value) native "HTMLAreaElement_host_Setter";

Native_HTMLAreaElement_hostname_Getter(mthis) native "HTMLAreaElement_hostname_Getter";

Native_HTMLAreaElement_hostname_Setter(mthis, value) native "HTMLAreaElement_hostname_Setter";

Native_HTMLAreaElement_href_Getter(mthis) native "HTMLAreaElement_href_Getter";

Native_HTMLAreaElement_href_Setter(mthis, value) native "HTMLAreaElement_href_Setter";

Native_HTMLAreaElement_origin_Getter(mthis) native "HTMLAreaElement_origin_Getter";

Native_HTMLAreaElement_password_Getter(mthis) native "HTMLAreaElement_password_Getter";

Native_HTMLAreaElement_password_Setter(mthis, value) native "HTMLAreaElement_password_Setter";

Native_HTMLAreaElement_pathname_Getter(mthis) native "HTMLAreaElement_pathname_Getter";

Native_HTMLAreaElement_pathname_Setter(mthis, value) native "HTMLAreaElement_pathname_Setter";

Native_HTMLAreaElement_port_Getter(mthis) native "HTMLAreaElement_port_Getter";

Native_HTMLAreaElement_port_Setter(mthis, value) native "HTMLAreaElement_port_Setter";

Native_HTMLAreaElement_protocol_Getter(mthis) native "HTMLAreaElement_protocol_Getter";

Native_HTMLAreaElement_protocol_Setter(mthis, value) native "HTMLAreaElement_protocol_Setter";

Native_HTMLAreaElement_search_Getter(mthis) native "HTMLAreaElement_search_Getter";

Native_HTMLAreaElement_search_Setter(mthis, value) native "HTMLAreaElement_search_Setter";

Native_HTMLAreaElement_username_Getter(mthis) native "HTMLAreaElement_username_Getter";

Native_HTMLAreaElement_username_Setter(mthis, value) native "HTMLAreaElement_username_Setter";

Native_HTMLAreaElement_toString_Callback(mthis) native "HTMLAreaElement_toString_Callback_RESOLVER_STRING_0_";

Native_HTMLMediaElement_autoplay_Getter(mthis) native "HTMLMediaElement_autoplay_Getter";

Native_HTMLMediaElement_autoplay_Setter(mthis, value) native "HTMLMediaElement_autoplay_Setter";

Native_HTMLMediaElement_buffered_Getter(mthis) native "HTMLMediaElement_buffered_Getter";

Native_HTMLMediaElement_controller_Getter(mthis) native "HTMLMediaElement_controller_Getter";

Native_HTMLMediaElement_controller_Setter(mthis, value) native "HTMLMediaElement_controller_Setter";

Native_HTMLMediaElement_controls_Getter(mthis) native "HTMLMediaElement_controls_Getter";

Native_HTMLMediaElement_controls_Setter(mthis, value) native "HTMLMediaElement_controls_Setter";

Native_HTMLMediaElement_crossOrigin_Getter(mthis) native "HTMLMediaElement_crossOrigin_Getter";

Native_HTMLMediaElement_crossOrigin_Setter(mthis, value) native "HTMLMediaElement_crossOrigin_Setter";

Native_HTMLMediaElement_currentSrc_Getter(mthis) native "HTMLMediaElement_currentSrc_Getter";

Native_HTMLMediaElement_currentTime_Getter(mthis) native "HTMLMediaElement_currentTime_Getter";

Native_HTMLMediaElement_currentTime_Setter(mthis, value) native "HTMLMediaElement_currentTime_Setter";

Native_HTMLMediaElement_defaultMuted_Getter(mthis) native "HTMLMediaElement_defaultMuted_Getter";

Native_HTMLMediaElement_defaultMuted_Setter(mthis, value) native "HTMLMediaElement_defaultMuted_Setter";

Native_HTMLMediaElement_defaultPlaybackRate_Getter(mthis) native "HTMLMediaElement_defaultPlaybackRate_Getter";

Native_HTMLMediaElement_defaultPlaybackRate_Setter(mthis, value) native "HTMLMediaElement_defaultPlaybackRate_Setter";

Native_HTMLMediaElement_duration_Getter(mthis) native "HTMLMediaElement_duration_Getter";

Native_HTMLMediaElement_ended_Getter(mthis) native "HTMLMediaElement_ended_Getter";

Native_HTMLMediaElement_error_Getter(mthis) native "HTMLMediaElement_error_Getter";

Native_HTMLMediaElement_loop_Getter(mthis) native "HTMLMediaElement_loop_Getter";

Native_HTMLMediaElement_loop_Setter(mthis, value) native "HTMLMediaElement_loop_Setter";

Native_HTMLMediaElement_mediaGroup_Getter(mthis) native "HTMLMediaElement_mediaGroup_Getter";

Native_HTMLMediaElement_mediaGroup_Setter(mthis, value) native "HTMLMediaElement_mediaGroup_Setter";

Native_HTMLMediaElement_mediaKeys_Getter(mthis) native "HTMLMediaElement_mediaKeys_Getter";

Native_HTMLMediaElement_muted_Getter(mthis) native "HTMLMediaElement_muted_Getter";

Native_HTMLMediaElement_muted_Setter(mthis, value) native "HTMLMediaElement_muted_Setter";

Native_HTMLMediaElement_networkState_Getter(mthis) native "HTMLMediaElement_networkState_Getter";

Native_HTMLMediaElement_paused_Getter(mthis) native "HTMLMediaElement_paused_Getter";

Native_HTMLMediaElement_playbackRate_Getter(mthis) native "HTMLMediaElement_playbackRate_Getter";

Native_HTMLMediaElement_playbackRate_Setter(mthis, value) native "HTMLMediaElement_playbackRate_Setter";

Native_HTMLMediaElement_played_Getter(mthis) native "HTMLMediaElement_played_Getter";

Native_HTMLMediaElement_preload_Getter(mthis) native "HTMLMediaElement_preload_Getter";

Native_HTMLMediaElement_preload_Setter(mthis, value) native "HTMLMediaElement_preload_Setter";

Native_HTMLMediaElement_readyState_Getter(mthis) native "HTMLMediaElement_readyState_Getter";

Native_HTMLMediaElement_seekable_Getter(mthis) native "HTMLMediaElement_seekable_Getter";

Native_HTMLMediaElement_seeking_Getter(mthis) native "HTMLMediaElement_seeking_Getter";

Native_HTMLMediaElement_src_Getter(mthis) native "HTMLMediaElement_src_Getter";

Native_HTMLMediaElement_src_Setter(mthis, value) native "HTMLMediaElement_src_Setter";

Native_HTMLMediaElement_textTracks_Getter(mthis) native "HTMLMediaElement_textTracks_Getter";

Native_HTMLMediaElement_volume_Getter(mthis) native "HTMLMediaElement_volume_Getter";

Native_HTMLMediaElement_volume_Setter(mthis, value) native "HTMLMediaElement_volume_Setter";

Native_HTMLMediaElement_webkitAudioDecodedByteCount_Getter(mthis) native "HTMLMediaElement_webkitAudioDecodedByteCount_Getter";

Native_HTMLMediaElement_webkitVideoDecodedByteCount_Getter(mthis) native "HTMLMediaElement_webkitVideoDecodedByteCount_Getter";

  // Generated overload resolver
Native_HTMLMediaElement_addTextTrack(mthis, kind, label, language) {
    if (language != null) {
      return Native_HTMLMediaElement__addTextTrack_1_Callback(mthis, kind, label, language);
    }
    if (label != null) {
      return Native_HTMLMediaElement__addTextTrack_2_Callback(mthis, kind, label);
    }
    return Native_HTMLMediaElement__addTextTrack_3_Callback(mthis, kind);
  }

Native_HTMLMediaElement__addTextTrack_1_Callback(mthis, kind, label, language) native "HTMLMediaElement_addTextTrack_Callback_RESOLVER_STRING_3_DOMString_DOMString_DOMString";

Native_HTMLMediaElement__addTextTrack_2_Callback(mthis, kind, label) native "HTMLMediaElement_addTextTrack_Callback_RESOLVER_STRING_2_DOMString_DOMString";

Native_HTMLMediaElement__addTextTrack_3_Callback(mthis, kind) native "HTMLMediaElement_addTextTrack_Callback_RESOLVER_STRING_1_DOMString";

Native_HTMLMediaElement_canPlayType_Callback(mthis, type, keySystem) native "HTMLMediaElement_canPlayType_Callback_RESOLVER_STRING_2_DOMString_DOMString";

Native_HTMLMediaElement_load_Callback(mthis) native "HTMLMediaElement_load_Callback_RESOLVER_STRING_0_";

Native_HTMLMediaElement_pause_Callback(mthis) native "HTMLMediaElement_pause_Callback_RESOLVER_STRING_0_";

Native_HTMLMediaElement_play_Callback(mthis) native "HTMLMediaElement_play_Callback_RESOLVER_STRING_0_";

Native_HTMLMediaElement_setMediaKeys_Callback(mthis, mediaKeys) native "HTMLMediaElement_setMediaKeys_Callback_RESOLVER_STRING_1_MediaKeys";

  // Generated overload resolver
Native_HTMLMediaElement_addKey(mthis, keySystem, key, initData, sessionId) {
    if (initData != null) {
      Native_HTMLMediaElement__webkitAddKey_1_Callback(mthis, keySystem, key, initData, sessionId);
      return;
    }
    Native_HTMLMediaElement__webkitAddKey_2_Callback(mthis, keySystem, key);
    return;
  }

Native_HTMLMediaElement__webkitAddKey_1_Callback(mthis, keySystem, key, initData, sessionId) native "HTMLMediaElement_webkitAddKey_Callback_RESOLVER_STRING_4_DOMString_Uint8Array_Uint8Array_DOMString";

Native_HTMLMediaElement__webkitAddKey_2_Callback(mthis, keySystem, key) native "HTMLMediaElement_webkitAddKey_Callback_RESOLVER_STRING_2_DOMString_Uint8Array";

Native_HTMLMediaElement_webkitCancelKeyRequest_Callback(mthis, keySystem, sessionId) native "HTMLMediaElement_webkitCancelKeyRequest_Callback_RESOLVER_STRING_2_DOMString_DOMString";

  // Generated overload resolver
Native_HTMLMediaElement_generateKeyRequest(mthis, keySystem, initData) {
    if (initData != null) {
      Native_HTMLMediaElement__webkitGenerateKeyRequest_1_Callback(mthis, keySystem, initData);
      return;
    }
    Native_HTMLMediaElement__webkitGenerateKeyRequest_2_Callback(mthis, keySystem);
    return;
  }

Native_HTMLMediaElement__webkitGenerateKeyRequest_1_Callback(mthis, keySystem, initData) native "HTMLMediaElement_webkitGenerateKeyRequest_Callback_RESOLVER_STRING_2_DOMString_Uint8Array";

Native_HTMLMediaElement__webkitGenerateKeyRequest_2_Callback(mthis, keySystem) native "HTMLMediaElement_webkitGenerateKeyRequest_Callback_RESOLVER_STRING_1_DOMString";

  // Generated overload resolver
Native_HTMLAudioElement_AudioElement(src) {
    return Native_HTMLAudioElement__create_1constructorCallback(src);
  }

Native_HTMLAudioElement__create_1constructorCallback(src) native "HTMLAudioElement_constructorCallback_RESOLVER_STRING_1_DOMString";

Native_HTMLBaseElement_href_Getter(mthis) native "HTMLBaseElement_href_Getter";

Native_HTMLBaseElement_href_Setter(mthis, value) native "HTMLBaseElement_href_Setter";

Native_HTMLBaseElement_target_Getter(mthis) native "HTMLBaseElement_target_Getter";

Native_HTMLBaseElement_target_Setter(mthis, value) native "HTMLBaseElement_target_Setter";

Native_HTMLButtonElement_autofocus_Getter(mthis) native "HTMLButtonElement_autofocus_Getter";

Native_HTMLButtonElement_autofocus_Setter(mthis, value) native "HTMLButtonElement_autofocus_Setter";

Native_HTMLButtonElement_disabled_Getter(mthis) native "HTMLButtonElement_disabled_Getter";

Native_HTMLButtonElement_disabled_Setter(mthis, value) native "HTMLButtonElement_disabled_Setter";

Native_HTMLButtonElement_form_Getter(mthis) native "HTMLButtonElement_form_Getter";

Native_HTMLButtonElement_formAction_Getter(mthis) native "HTMLButtonElement_formAction_Getter";

Native_HTMLButtonElement_formAction_Setter(mthis, value) native "HTMLButtonElement_formAction_Setter";

Native_HTMLButtonElement_formEnctype_Getter(mthis) native "HTMLButtonElement_formEnctype_Getter";

Native_HTMLButtonElement_formEnctype_Setter(mthis, value) native "HTMLButtonElement_formEnctype_Setter";

Native_HTMLButtonElement_formMethod_Getter(mthis) native "HTMLButtonElement_formMethod_Getter";

Native_HTMLButtonElement_formMethod_Setter(mthis, value) native "HTMLButtonElement_formMethod_Setter";

Native_HTMLButtonElement_formNoValidate_Getter(mthis) native "HTMLButtonElement_formNoValidate_Getter";

Native_HTMLButtonElement_formNoValidate_Setter(mthis, value) native "HTMLButtonElement_formNoValidate_Setter";

Native_HTMLButtonElement_formTarget_Getter(mthis) native "HTMLButtonElement_formTarget_Getter";

Native_HTMLButtonElement_formTarget_Setter(mthis, value) native "HTMLButtonElement_formTarget_Setter";

Native_HTMLButtonElement_labels_Getter(mthis) native "HTMLButtonElement_labels_Getter";

Native_HTMLButtonElement_name_Getter(mthis) native "HTMLButtonElement_name_Getter";

Native_HTMLButtonElement_name_Setter(mthis, value) native "HTMLButtonElement_name_Setter";

Native_HTMLButtonElement_type_Getter(mthis) native "HTMLButtonElement_type_Getter";

Native_HTMLButtonElement_type_Setter(mthis, value) native "HTMLButtonElement_type_Setter";

Native_HTMLButtonElement_validationMessage_Getter(mthis) native "HTMLButtonElement_validationMessage_Getter";

Native_HTMLButtonElement_validity_Getter(mthis) native "HTMLButtonElement_validity_Getter";

Native_HTMLButtonElement_value_Getter(mthis) native "HTMLButtonElement_value_Getter";

Native_HTMLButtonElement_value_Setter(mthis, value) native "HTMLButtonElement_value_Setter";

Native_HTMLButtonElement_willValidate_Getter(mthis) native "HTMLButtonElement_willValidate_Getter";

Native_HTMLButtonElement_checkValidity_Callback(mthis) native "HTMLButtonElement_checkValidity_Callback_RESOLVER_STRING_0_";

Native_HTMLButtonElement_setCustomValidity_Callback(mthis, error) native "HTMLButtonElement_setCustomValidity_Callback_RESOLVER_STRING_1_DOMString";

Native_HTMLCanvasElement_height_Getter(mthis) native "HTMLCanvasElement_height_Getter";

Native_HTMLCanvasElement_height_Setter(mthis, value) native "HTMLCanvasElement_height_Setter";

Native_HTMLCanvasElement_width_Getter(mthis) native "HTMLCanvasElement_width_Getter";

Native_HTMLCanvasElement_width_Setter(mthis, value) native "HTMLCanvasElement_width_Setter";

Native_HTMLCanvasElement_getContext_Callback(mthis, contextId, attrs) native "HTMLCanvasElement_getContext_Callback";

Native_HTMLCanvasElement_toDataURL_Callback(mthis, type, quality) native "HTMLCanvasElement_toDataURL_Callback";

Native_HTMLCollection_length_Getter(mthis) native "HTMLCollection_length_Getter";

Native_HTMLCollection_NativeIndexed_Getter(mthis, index) native "HTMLCollection_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_HTMLCollection_item_Callback(mthis, index) native "HTMLCollection_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_HTMLCollection_namedItem_Callback(mthis, name) native "HTMLCollection_namedItem_Callback_RESOLVER_STRING_1_DOMString";

Native_HTMLContentElement_resetStyleInheritance_Getter(mthis) native "HTMLContentElement_resetStyleInheritance_Getter";

Native_HTMLContentElement_resetStyleInheritance_Setter(mthis, value) native "HTMLContentElement_resetStyleInheritance_Setter";

Native_HTMLContentElement_select_Getter(mthis) native "HTMLContentElement_select_Getter";

Native_HTMLContentElement_select_Setter(mthis, value) native "HTMLContentElement_select_Setter";

Native_HTMLContentElement_getDistributedNodes_Callback(mthis) native "HTMLContentElement_getDistributedNodes_Callback_RESOLVER_STRING_0_";

Native_HTMLDataListElement_options_Getter(mthis) native "HTMLDataListElement_options_Getter";

Native_HTMLDetailsElement_open_Getter(mthis) native "HTMLDetailsElement_open_Getter";

Native_HTMLDetailsElement_open_Setter(mthis, value) native "HTMLDetailsElement_open_Setter";

Native_HTMLDialogElement_open_Getter(mthis) native "HTMLDialogElement_open_Getter";

Native_HTMLDialogElement_open_Setter(mthis, value) native "HTMLDialogElement_open_Setter";

Native_HTMLDialogElement_returnValue_Getter(mthis) native "HTMLDialogElement_returnValue_Getter";

Native_HTMLDialogElement_returnValue_Setter(mthis, value) native "HTMLDialogElement_returnValue_Setter";

Native_HTMLDialogElement_close_Callback(mthis, returnValue) native "HTMLDialogElement_close_Callback_RESOLVER_STRING_1_DOMString";

Native_HTMLDialogElement_show_Callback(mthis) native "HTMLDialogElement_show_Callback_RESOLVER_STRING_0_";

Native_HTMLDialogElement_showModal_Callback(mthis) native "HTMLDialogElement_showModal_Callback_RESOLVER_STRING_0_";

Native_HTMLEmbedElement_height_Getter(mthis) native "HTMLEmbedElement_height_Getter";

Native_HTMLEmbedElement_height_Setter(mthis, value) native "HTMLEmbedElement_height_Setter";

Native_HTMLEmbedElement_name_Getter(mthis) native "HTMLEmbedElement_name_Getter";

Native_HTMLEmbedElement_name_Setter(mthis, value) native "HTMLEmbedElement_name_Setter";

Native_HTMLEmbedElement_src_Getter(mthis) native "HTMLEmbedElement_src_Getter";

Native_HTMLEmbedElement_src_Setter(mthis, value) native "HTMLEmbedElement_src_Setter";

Native_HTMLEmbedElement_type_Getter(mthis) native "HTMLEmbedElement_type_Getter";

Native_HTMLEmbedElement_type_Setter(mthis, value) native "HTMLEmbedElement_type_Setter";

Native_HTMLEmbedElement_width_Getter(mthis) native "HTMLEmbedElement_width_Getter";

Native_HTMLEmbedElement_width_Setter(mthis, value) native "HTMLEmbedElement_width_Setter";

Native_HTMLEmbedElement___getter___Callback(mthis, index_OR_name) native "HTMLEmbedElement___getter___Callback";

Native_HTMLEmbedElement___setter___Callback(mthis, index_OR_name, value) native "HTMLEmbedElement___setter___Callback";

Native_HTMLFieldSetElement_disabled_Getter(mthis) native "HTMLFieldSetElement_disabled_Getter";

Native_HTMLFieldSetElement_disabled_Setter(mthis, value) native "HTMLFieldSetElement_disabled_Setter";

Native_HTMLFieldSetElement_elements_Getter(mthis) native "HTMLFieldSetElement_elements_Getter";

Native_HTMLFieldSetElement_form_Getter(mthis) native "HTMLFieldSetElement_form_Getter";

Native_HTMLFieldSetElement_name_Getter(mthis) native "HTMLFieldSetElement_name_Getter";

Native_HTMLFieldSetElement_name_Setter(mthis, value) native "HTMLFieldSetElement_name_Setter";

Native_HTMLFieldSetElement_type_Getter(mthis) native "HTMLFieldSetElement_type_Getter";

Native_HTMLFieldSetElement_validationMessage_Getter(mthis) native "HTMLFieldSetElement_validationMessage_Getter";

Native_HTMLFieldSetElement_validity_Getter(mthis) native "HTMLFieldSetElement_validity_Getter";

Native_HTMLFieldSetElement_willValidate_Getter(mthis) native "HTMLFieldSetElement_willValidate_Getter";

Native_HTMLFieldSetElement_checkValidity_Callback(mthis) native "HTMLFieldSetElement_checkValidity_Callback_RESOLVER_STRING_0_";

Native_HTMLFieldSetElement_setCustomValidity_Callback(mthis, error) native "HTMLFieldSetElement_setCustomValidity_Callback_RESOLVER_STRING_1_DOMString";

Native_HTMLFormElement_acceptCharset_Getter(mthis) native "HTMLFormElement_acceptCharset_Getter";

Native_HTMLFormElement_acceptCharset_Setter(mthis, value) native "HTMLFormElement_acceptCharset_Setter";

Native_HTMLFormElement_action_Getter(mthis) native "HTMLFormElement_action_Getter";

Native_HTMLFormElement_action_Setter(mthis, value) native "HTMLFormElement_action_Setter";

Native_HTMLFormElement_autocomplete_Getter(mthis) native "HTMLFormElement_autocomplete_Getter";

Native_HTMLFormElement_autocomplete_Setter(mthis, value) native "HTMLFormElement_autocomplete_Setter";

Native_HTMLFormElement_encoding_Getter(mthis) native "HTMLFormElement_encoding_Getter";

Native_HTMLFormElement_encoding_Setter(mthis, value) native "HTMLFormElement_encoding_Setter";

Native_HTMLFormElement_enctype_Getter(mthis) native "HTMLFormElement_enctype_Getter";

Native_HTMLFormElement_enctype_Setter(mthis, value) native "HTMLFormElement_enctype_Setter";

Native_HTMLFormElement_length_Getter(mthis) native "HTMLFormElement_length_Getter";

Native_HTMLFormElement_method_Getter(mthis) native "HTMLFormElement_method_Getter";

Native_HTMLFormElement_method_Setter(mthis, value) native "HTMLFormElement_method_Setter";

Native_HTMLFormElement_name_Getter(mthis) native "HTMLFormElement_name_Getter";

Native_HTMLFormElement_name_Setter(mthis, value) native "HTMLFormElement_name_Setter";

Native_HTMLFormElement_noValidate_Getter(mthis) native "HTMLFormElement_noValidate_Getter";

Native_HTMLFormElement_noValidate_Setter(mthis, value) native "HTMLFormElement_noValidate_Setter";

Native_HTMLFormElement_target_Getter(mthis) native "HTMLFormElement_target_Getter";

Native_HTMLFormElement_target_Setter(mthis, value) native "HTMLFormElement_target_Setter";

Native_HTMLFormElement___getter___Callback(mthis, index) native "HTMLFormElement___getter___Callback_RESOLVER_STRING_1_unsigned long";

Native_HTMLFormElement_checkValidity_Callback(mthis) native "HTMLFormElement_checkValidity_Callback_RESOLVER_STRING_0_";

Native_HTMLFormElement_requestAutocomplete_Callback(mthis) native "HTMLFormElement_requestAutocomplete_Callback_RESOLVER_STRING_0_";

Native_HTMLFormElement_reset_Callback(mthis) native "HTMLFormElement_reset_Callback_RESOLVER_STRING_0_";

Native_HTMLFormElement_submit_Callback(mthis) native "HTMLFormElement_submit_Callback_RESOLVER_STRING_0_";

Native_HTMLHRElement_color_Getter(mthis) native "HTMLHRElement_color_Getter";

Native_HTMLHRElement_color_Setter(mthis, value) native "HTMLHRElement_color_Setter";

Native_HTMLIFrameElement_contentWindow_Getter(mthis) native "HTMLIFrameElement_contentWindow_Getter";

Native_HTMLIFrameElement_height_Getter(mthis) native "HTMLIFrameElement_height_Getter";

Native_HTMLIFrameElement_height_Setter(mthis, value) native "HTMLIFrameElement_height_Setter";

Native_HTMLIFrameElement_name_Getter(mthis) native "HTMLIFrameElement_name_Getter";

Native_HTMLIFrameElement_name_Setter(mthis, value) native "HTMLIFrameElement_name_Setter";

Native_HTMLIFrameElement_sandbox_Getter(mthis) native "HTMLIFrameElement_sandbox_Getter";

Native_HTMLIFrameElement_sandbox_Setter(mthis, value) native "HTMLIFrameElement_sandbox_Setter";

Native_HTMLIFrameElement_src_Getter(mthis) native "HTMLIFrameElement_src_Getter";

Native_HTMLIFrameElement_src_Setter(mthis, value) native "HTMLIFrameElement_src_Setter";

Native_HTMLIFrameElement_srcdoc_Getter(mthis) native "HTMLIFrameElement_srcdoc_Getter";

Native_HTMLIFrameElement_srcdoc_Setter(mthis, value) native "HTMLIFrameElement_srcdoc_Setter";

Native_HTMLIFrameElement_width_Getter(mthis) native "HTMLIFrameElement_width_Getter";

Native_HTMLIFrameElement_width_Setter(mthis, value) native "HTMLIFrameElement_width_Setter";

Native_HTMLImageElement_alt_Getter(mthis) native "HTMLImageElement_alt_Getter";

Native_HTMLImageElement_alt_Setter(mthis, value) native "HTMLImageElement_alt_Setter";

Native_HTMLImageElement_complete_Getter(mthis) native "HTMLImageElement_complete_Getter";

Native_HTMLImageElement_crossOrigin_Getter(mthis) native "HTMLImageElement_crossOrigin_Getter";

Native_HTMLImageElement_crossOrigin_Setter(mthis, value) native "HTMLImageElement_crossOrigin_Setter";

Native_HTMLImageElement_height_Getter(mthis) native "HTMLImageElement_height_Getter";

Native_HTMLImageElement_height_Setter(mthis, value) native "HTMLImageElement_height_Setter";

Native_HTMLImageElement_isMap_Getter(mthis) native "HTMLImageElement_isMap_Getter";

Native_HTMLImageElement_isMap_Setter(mthis, value) native "HTMLImageElement_isMap_Setter";

Native_HTMLImageElement_naturalHeight_Getter(mthis) native "HTMLImageElement_naturalHeight_Getter";

Native_HTMLImageElement_naturalWidth_Getter(mthis) native "HTMLImageElement_naturalWidth_Getter";

Native_HTMLImageElement_src_Getter(mthis) native "HTMLImageElement_src_Getter";

Native_HTMLImageElement_src_Setter(mthis, value) native "HTMLImageElement_src_Setter";

Native_HTMLImageElement_srcset_Getter(mthis) native "HTMLImageElement_srcset_Getter";

Native_HTMLImageElement_srcset_Setter(mthis, value) native "HTMLImageElement_srcset_Setter";

Native_HTMLImageElement_useMap_Getter(mthis) native "HTMLImageElement_useMap_Getter";

Native_HTMLImageElement_useMap_Setter(mthis, value) native "HTMLImageElement_useMap_Setter";

Native_HTMLImageElement_width_Getter(mthis) native "HTMLImageElement_width_Getter";

Native_HTMLImageElement_width_Setter(mthis, value) native "HTMLImageElement_width_Setter";

Native_HTMLInputElement_accept_Getter(mthis) native "HTMLInputElement_accept_Getter";

Native_HTMLInputElement_accept_Setter(mthis, value) native "HTMLInputElement_accept_Setter";

Native_HTMLInputElement_alt_Getter(mthis) native "HTMLInputElement_alt_Getter";

Native_HTMLInputElement_alt_Setter(mthis, value) native "HTMLInputElement_alt_Setter";

Native_HTMLInputElement_autocomplete_Getter(mthis) native "HTMLInputElement_autocomplete_Getter";

Native_HTMLInputElement_autocomplete_Setter(mthis, value) native "HTMLInputElement_autocomplete_Setter";

Native_HTMLInputElement_autofocus_Getter(mthis) native "HTMLInputElement_autofocus_Getter";

Native_HTMLInputElement_autofocus_Setter(mthis, value) native "HTMLInputElement_autofocus_Setter";

Native_HTMLInputElement_checked_Getter(mthis) native "HTMLInputElement_checked_Getter";

Native_HTMLInputElement_checked_Setter(mthis, value) native "HTMLInputElement_checked_Setter";

Native_HTMLInputElement_defaultChecked_Getter(mthis) native "HTMLInputElement_defaultChecked_Getter";

Native_HTMLInputElement_defaultChecked_Setter(mthis, value) native "HTMLInputElement_defaultChecked_Setter";

Native_HTMLInputElement_defaultValue_Getter(mthis) native "HTMLInputElement_defaultValue_Getter";

Native_HTMLInputElement_defaultValue_Setter(mthis, value) native "HTMLInputElement_defaultValue_Setter";

Native_HTMLInputElement_dirName_Getter(mthis) native "HTMLInputElement_dirName_Getter";

Native_HTMLInputElement_dirName_Setter(mthis, value) native "HTMLInputElement_dirName_Setter";

Native_HTMLInputElement_disabled_Getter(mthis) native "HTMLInputElement_disabled_Getter";

Native_HTMLInputElement_disabled_Setter(mthis, value) native "HTMLInputElement_disabled_Setter";

Native_HTMLInputElement_files_Getter(mthis) native "HTMLInputElement_files_Getter";

Native_HTMLInputElement_files_Setter(mthis, value) native "HTMLInputElement_files_Setter";

Native_HTMLInputElement_form_Getter(mthis) native "HTMLInputElement_form_Getter";

Native_HTMLInputElement_formAction_Getter(mthis) native "HTMLInputElement_formAction_Getter";

Native_HTMLInputElement_formAction_Setter(mthis, value) native "HTMLInputElement_formAction_Setter";

Native_HTMLInputElement_formEnctype_Getter(mthis) native "HTMLInputElement_formEnctype_Getter";

Native_HTMLInputElement_formEnctype_Setter(mthis, value) native "HTMLInputElement_formEnctype_Setter";

Native_HTMLInputElement_formMethod_Getter(mthis) native "HTMLInputElement_formMethod_Getter";

Native_HTMLInputElement_formMethod_Setter(mthis, value) native "HTMLInputElement_formMethod_Setter";

Native_HTMLInputElement_formNoValidate_Getter(mthis) native "HTMLInputElement_formNoValidate_Getter";

Native_HTMLInputElement_formNoValidate_Setter(mthis, value) native "HTMLInputElement_formNoValidate_Setter";

Native_HTMLInputElement_formTarget_Getter(mthis) native "HTMLInputElement_formTarget_Getter";

Native_HTMLInputElement_formTarget_Setter(mthis, value) native "HTMLInputElement_formTarget_Setter";

Native_HTMLInputElement_height_Getter(mthis) native "HTMLInputElement_height_Getter";

Native_HTMLInputElement_height_Setter(mthis, value) native "HTMLInputElement_height_Setter";

Native_HTMLInputElement_incremental_Getter(mthis) native "HTMLInputElement_incremental_Getter";

Native_HTMLInputElement_incremental_Setter(mthis, value) native "HTMLInputElement_incremental_Setter";

Native_HTMLInputElement_indeterminate_Getter(mthis) native "HTMLInputElement_indeterminate_Getter";

Native_HTMLInputElement_indeterminate_Setter(mthis, value) native "HTMLInputElement_indeterminate_Setter";

Native_HTMLInputElement_inputMode_Getter(mthis) native "HTMLInputElement_inputMode_Getter";

Native_HTMLInputElement_inputMode_Setter(mthis, value) native "HTMLInputElement_inputMode_Setter";

Native_HTMLInputElement_labels_Getter(mthis) native "HTMLInputElement_labels_Getter";

Native_HTMLInputElement_list_Getter(mthis) native "HTMLInputElement_list_Getter";

Native_HTMLInputElement_max_Getter(mthis) native "HTMLInputElement_max_Getter";

Native_HTMLInputElement_max_Setter(mthis, value) native "HTMLInputElement_max_Setter";

Native_HTMLInputElement_maxLength_Getter(mthis) native "HTMLInputElement_maxLength_Getter";

Native_HTMLInputElement_maxLength_Setter(mthis, value) native "HTMLInputElement_maxLength_Setter";

Native_HTMLInputElement_min_Getter(mthis) native "HTMLInputElement_min_Getter";

Native_HTMLInputElement_min_Setter(mthis, value) native "HTMLInputElement_min_Setter";

Native_HTMLInputElement_multiple_Getter(mthis) native "HTMLInputElement_multiple_Getter";

Native_HTMLInputElement_multiple_Setter(mthis, value) native "HTMLInputElement_multiple_Setter";

Native_HTMLInputElement_name_Getter(mthis) native "HTMLInputElement_name_Getter";

Native_HTMLInputElement_name_Setter(mthis, value) native "HTMLInputElement_name_Setter";

Native_HTMLInputElement_pattern_Getter(mthis) native "HTMLInputElement_pattern_Getter";

Native_HTMLInputElement_pattern_Setter(mthis, value) native "HTMLInputElement_pattern_Setter";

Native_HTMLInputElement_placeholder_Getter(mthis) native "HTMLInputElement_placeholder_Getter";

Native_HTMLInputElement_placeholder_Setter(mthis, value) native "HTMLInputElement_placeholder_Setter";

Native_HTMLInputElement_readOnly_Getter(mthis) native "HTMLInputElement_readOnly_Getter";

Native_HTMLInputElement_readOnly_Setter(mthis, value) native "HTMLInputElement_readOnly_Setter";

Native_HTMLInputElement_required_Getter(mthis) native "HTMLInputElement_required_Getter";

Native_HTMLInputElement_required_Setter(mthis, value) native "HTMLInputElement_required_Setter";

Native_HTMLInputElement_selectionDirection_Getter(mthis) native "HTMLInputElement_selectionDirection_Getter";

Native_HTMLInputElement_selectionDirection_Setter(mthis, value) native "HTMLInputElement_selectionDirection_Setter";

Native_HTMLInputElement_selectionEnd_Getter(mthis) native "HTMLInputElement_selectionEnd_Getter";

Native_HTMLInputElement_selectionEnd_Setter(mthis, value) native "HTMLInputElement_selectionEnd_Setter";

Native_HTMLInputElement_selectionStart_Getter(mthis) native "HTMLInputElement_selectionStart_Getter";

Native_HTMLInputElement_selectionStart_Setter(mthis, value) native "HTMLInputElement_selectionStart_Setter";

Native_HTMLInputElement_size_Getter(mthis) native "HTMLInputElement_size_Getter";

Native_HTMLInputElement_size_Setter(mthis, value) native "HTMLInputElement_size_Setter";

Native_HTMLInputElement_src_Getter(mthis) native "HTMLInputElement_src_Getter";

Native_HTMLInputElement_src_Setter(mthis, value) native "HTMLInputElement_src_Setter";

Native_HTMLInputElement_step_Getter(mthis) native "HTMLInputElement_step_Getter";

Native_HTMLInputElement_step_Setter(mthis, value) native "HTMLInputElement_step_Setter";

Native_HTMLInputElement_type_Getter(mthis) native "HTMLInputElement_type_Getter";

Native_HTMLInputElement_type_Setter(mthis, value) native "HTMLInputElement_type_Setter";

Native_HTMLInputElement_validationMessage_Getter(mthis) native "HTMLInputElement_validationMessage_Getter";

Native_HTMLInputElement_validity_Getter(mthis) native "HTMLInputElement_validity_Getter";

Native_HTMLInputElement_value_Getter(mthis) native "HTMLInputElement_value_Getter";

Native_HTMLInputElement_value_Setter(mthis, value) native "HTMLInputElement_value_Setter";

Native_HTMLInputElement_valueAsDate_Getter(mthis) native "HTMLInputElement_valueAsDate_Getter";

Native_HTMLInputElement_valueAsDate_Setter(mthis, value) native "HTMLInputElement_valueAsDate_Setter";

Native_HTMLInputElement_valueAsNumber_Getter(mthis) native "HTMLInputElement_valueAsNumber_Getter";

Native_HTMLInputElement_valueAsNumber_Setter(mthis, value) native "HTMLInputElement_valueAsNumber_Setter";

Native_HTMLInputElement_webkitEntries_Getter(mthis) native "HTMLInputElement_webkitEntries_Getter";

Native_HTMLInputElement_webkitGrammar_Getter(mthis) native "HTMLInputElement_webkitGrammar_Getter";

Native_HTMLInputElement_webkitGrammar_Setter(mthis, value) native "HTMLInputElement_webkitGrammar_Setter";

Native_HTMLInputElement_webkitSpeech_Getter(mthis) native "HTMLInputElement_webkitSpeech_Getter";

Native_HTMLInputElement_webkitSpeech_Setter(mthis, value) native "HTMLInputElement_webkitSpeech_Setter";

Native_HTMLInputElement_webkitdirectory_Getter(mthis) native "HTMLInputElement_webkitdirectory_Getter";

Native_HTMLInputElement_webkitdirectory_Setter(mthis, value) native "HTMLInputElement_webkitdirectory_Setter";

Native_HTMLInputElement_width_Getter(mthis) native "HTMLInputElement_width_Getter";

Native_HTMLInputElement_width_Setter(mthis, value) native "HTMLInputElement_width_Setter";

Native_HTMLInputElement_willValidate_Getter(mthis) native "HTMLInputElement_willValidate_Getter";

Native_HTMLInputElement_checkValidity_Callback(mthis) native "HTMLInputElement_checkValidity_Callback_RESOLVER_STRING_0_";

Native_HTMLInputElement_select_Callback(mthis) native "HTMLInputElement_select_Callback_RESOLVER_STRING_0_";

Native_HTMLInputElement_setCustomValidity_Callback(mthis, error) native "HTMLInputElement_setCustomValidity_Callback_RESOLVER_STRING_1_DOMString";

  // Generated overload resolver
Native_HTMLInputElement_setRangeText(mthis, replacement, start, end, selectionMode) {
    if ((replacement is String || replacement == null) && start == null && end == null && selectionMode == null) {
      Native_HTMLInputElement__setRangeText_1_Callback(mthis, replacement);
      return;
    }
    if ((selectionMode is String || selectionMode == null) && (end is int || end == null) && (start is int || start == null) && (replacement is String || replacement == null)) {
      Native_HTMLInputElement__setRangeText_2_Callback(mthis, replacement, start, end, selectionMode);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

Native_HTMLInputElement__setRangeText_1_Callback(mthis, replacement) native "HTMLInputElement_setRangeText_Callback_RESOLVER_STRING_1_DOMString";

Native_HTMLInputElement__setRangeText_2_Callback(mthis, replacement, start, end, selectionMode) native "HTMLInputElement_setRangeText_Callback_RESOLVER_STRING_4_DOMString_unsigned long_unsigned long_DOMString";

  // Generated overload resolver
Native_HTMLInputElement_setSelectionRange(mthis, start, end, direction) {
    if (direction != null) {
      Native_HTMLInputElement__setSelectionRange_1_Callback(mthis, start, end, direction);
      return;
    }
    Native_HTMLInputElement__setSelectionRange_2_Callback(mthis, start, end);
    return;
  }

Native_HTMLInputElement__setSelectionRange_1_Callback(mthis, start, end, direction) native "HTMLInputElement_setSelectionRange_Callback_RESOLVER_STRING_3_long_long_DOMString";

Native_HTMLInputElement__setSelectionRange_2_Callback(mthis, start, end) native "HTMLInputElement_setSelectionRange_Callback_RESOLVER_STRING_2_long_long";

  // Generated overload resolver
Native_HTMLInputElement_stepDown(mthis, n) {
    if (n != null) {
      Native_HTMLInputElement__stepDown_1_Callback(mthis, n);
      return;
    }
    Native_HTMLInputElement__stepDown_2_Callback(mthis);
    return;
  }

Native_HTMLInputElement__stepDown_1_Callback(mthis, n) native "HTMLInputElement_stepDown_Callback_RESOLVER_STRING_1_long";

Native_HTMLInputElement__stepDown_2_Callback(mthis) native "HTMLInputElement_stepDown_Callback_RESOLVER_STRING_0_";

  // Generated overload resolver
Native_HTMLInputElement_stepUp(mthis, n) {
    if (n != null) {
      Native_HTMLInputElement__stepUp_1_Callback(mthis, n);
      return;
    }
    Native_HTMLInputElement__stepUp_2_Callback(mthis);
    return;
  }

Native_HTMLInputElement__stepUp_1_Callback(mthis, n) native "HTMLInputElement_stepUp_Callback_RESOLVER_STRING_1_long";

Native_HTMLInputElement__stepUp_2_Callback(mthis) native "HTMLInputElement_stepUp_Callback_RESOLVER_STRING_0_";

Native_HTMLKeygenElement_autofocus_Getter(mthis) native "HTMLKeygenElement_autofocus_Getter";

Native_HTMLKeygenElement_autofocus_Setter(mthis, value) native "HTMLKeygenElement_autofocus_Setter";

Native_HTMLKeygenElement_challenge_Getter(mthis) native "HTMLKeygenElement_challenge_Getter";

Native_HTMLKeygenElement_challenge_Setter(mthis, value) native "HTMLKeygenElement_challenge_Setter";

Native_HTMLKeygenElement_disabled_Getter(mthis) native "HTMLKeygenElement_disabled_Getter";

Native_HTMLKeygenElement_disabled_Setter(mthis, value) native "HTMLKeygenElement_disabled_Setter";

Native_HTMLKeygenElement_form_Getter(mthis) native "HTMLKeygenElement_form_Getter";

Native_HTMLKeygenElement_keytype_Getter(mthis) native "HTMLKeygenElement_keytype_Getter";

Native_HTMLKeygenElement_keytype_Setter(mthis, value) native "HTMLKeygenElement_keytype_Setter";

Native_HTMLKeygenElement_labels_Getter(mthis) native "HTMLKeygenElement_labels_Getter";

Native_HTMLKeygenElement_name_Getter(mthis) native "HTMLKeygenElement_name_Getter";

Native_HTMLKeygenElement_name_Setter(mthis, value) native "HTMLKeygenElement_name_Setter";

Native_HTMLKeygenElement_type_Getter(mthis) native "HTMLKeygenElement_type_Getter";

Native_HTMLKeygenElement_validationMessage_Getter(mthis) native "HTMLKeygenElement_validationMessage_Getter";

Native_HTMLKeygenElement_validity_Getter(mthis) native "HTMLKeygenElement_validity_Getter";

Native_HTMLKeygenElement_willValidate_Getter(mthis) native "HTMLKeygenElement_willValidate_Getter";

Native_HTMLKeygenElement_checkValidity_Callback(mthis) native "HTMLKeygenElement_checkValidity_Callback_RESOLVER_STRING_0_";

Native_HTMLKeygenElement_setCustomValidity_Callback(mthis, error) native "HTMLKeygenElement_setCustomValidity_Callback_RESOLVER_STRING_1_DOMString";

Native_HTMLLIElement_value_Getter(mthis) native "HTMLLIElement_value_Getter";

Native_HTMLLIElement_value_Setter(mthis, value) native "HTMLLIElement_value_Setter";

Native_HTMLLabelElement_control_Getter(mthis) native "HTMLLabelElement_control_Getter";

Native_HTMLLabelElement_form_Getter(mthis) native "HTMLLabelElement_form_Getter";

Native_HTMLLabelElement_htmlFor_Getter(mthis) native "HTMLLabelElement_htmlFor_Getter";

Native_HTMLLabelElement_htmlFor_Setter(mthis, value) native "HTMLLabelElement_htmlFor_Setter";

Native_HTMLLegendElement_form_Getter(mthis) native "HTMLLegendElement_form_Getter";

Native_HTMLLinkElement_crossOrigin_Getter(mthis) native "HTMLLinkElement_crossOrigin_Getter";

Native_HTMLLinkElement_crossOrigin_Setter(mthis, value) native "HTMLLinkElement_crossOrigin_Setter";

Native_HTMLLinkElement_disabled_Getter(mthis) native "HTMLLinkElement_disabled_Getter";

Native_HTMLLinkElement_disabled_Setter(mthis, value) native "HTMLLinkElement_disabled_Setter";

Native_HTMLLinkElement_href_Getter(mthis) native "HTMLLinkElement_href_Getter";

Native_HTMLLinkElement_href_Setter(mthis, value) native "HTMLLinkElement_href_Setter";

Native_HTMLLinkElement_hreflang_Getter(mthis) native "HTMLLinkElement_hreflang_Getter";

Native_HTMLLinkElement_hreflang_Setter(mthis, value) native "HTMLLinkElement_hreflang_Setter";

Native_HTMLLinkElement_import_Getter(mthis) native "HTMLLinkElement_import_Getter";

Native_HTMLLinkElement_media_Getter(mthis) native "HTMLLinkElement_media_Getter";

Native_HTMLLinkElement_media_Setter(mthis, value) native "HTMLLinkElement_media_Setter";

Native_HTMLLinkElement_rel_Getter(mthis) native "HTMLLinkElement_rel_Getter";

Native_HTMLLinkElement_rel_Setter(mthis, value) native "HTMLLinkElement_rel_Setter";

Native_HTMLLinkElement_sheet_Getter(mthis) native "HTMLLinkElement_sheet_Getter";

Native_HTMLLinkElement_sizes_Getter(mthis) native "HTMLLinkElement_sizes_Getter";

Native_HTMLLinkElement_type_Getter(mthis) native "HTMLLinkElement_type_Getter";

Native_HTMLLinkElement_type_Setter(mthis, value) native "HTMLLinkElement_type_Setter";

Native_HTMLMapElement_areas_Getter(mthis) native "HTMLMapElement_areas_Getter";

Native_HTMLMapElement_name_Getter(mthis) native "HTMLMapElement_name_Getter";

Native_HTMLMapElement_name_Setter(mthis, value) native "HTMLMapElement_name_Setter";

Native_HTMLMetaElement_content_Getter(mthis) native "HTMLMetaElement_content_Getter";

Native_HTMLMetaElement_content_Setter(mthis, value) native "HTMLMetaElement_content_Setter";

Native_HTMLMetaElement_httpEquiv_Getter(mthis) native "HTMLMetaElement_httpEquiv_Getter";

Native_HTMLMetaElement_httpEquiv_Setter(mthis, value) native "HTMLMetaElement_httpEquiv_Setter";

Native_HTMLMetaElement_name_Getter(mthis) native "HTMLMetaElement_name_Getter";

Native_HTMLMetaElement_name_Setter(mthis, value) native "HTMLMetaElement_name_Setter";

Native_HTMLMeterElement_high_Getter(mthis) native "HTMLMeterElement_high_Getter";

Native_HTMLMeterElement_high_Setter(mthis, value) native "HTMLMeterElement_high_Setter";

Native_HTMLMeterElement_labels_Getter(mthis) native "HTMLMeterElement_labels_Getter";

Native_HTMLMeterElement_low_Getter(mthis) native "HTMLMeterElement_low_Getter";

Native_HTMLMeterElement_low_Setter(mthis, value) native "HTMLMeterElement_low_Setter";

Native_HTMLMeterElement_max_Getter(mthis) native "HTMLMeterElement_max_Getter";

Native_HTMLMeterElement_max_Setter(mthis, value) native "HTMLMeterElement_max_Setter";

Native_HTMLMeterElement_min_Getter(mthis) native "HTMLMeterElement_min_Getter";

Native_HTMLMeterElement_min_Setter(mthis, value) native "HTMLMeterElement_min_Setter";

Native_HTMLMeterElement_optimum_Getter(mthis) native "HTMLMeterElement_optimum_Getter";

Native_HTMLMeterElement_optimum_Setter(mthis, value) native "HTMLMeterElement_optimum_Setter";

Native_HTMLMeterElement_value_Getter(mthis) native "HTMLMeterElement_value_Getter";

Native_HTMLMeterElement_value_Setter(mthis, value) native "HTMLMeterElement_value_Setter";

Native_HTMLModElement_cite_Getter(mthis) native "HTMLModElement_cite_Getter";

Native_HTMLModElement_cite_Setter(mthis, value) native "HTMLModElement_cite_Setter";

Native_HTMLModElement_dateTime_Getter(mthis) native "HTMLModElement_dateTime_Getter";

Native_HTMLModElement_dateTime_Setter(mthis, value) native "HTMLModElement_dateTime_Setter";

Native_HTMLOListElement_reversed_Getter(mthis) native "HTMLOListElement_reversed_Getter";

Native_HTMLOListElement_reversed_Setter(mthis, value) native "HTMLOListElement_reversed_Setter";

Native_HTMLOListElement_start_Getter(mthis) native "HTMLOListElement_start_Getter";

Native_HTMLOListElement_start_Setter(mthis, value) native "HTMLOListElement_start_Setter";

Native_HTMLOListElement_type_Getter(mthis) native "HTMLOListElement_type_Getter";

Native_HTMLOListElement_type_Setter(mthis, value) native "HTMLOListElement_type_Setter";

Native_HTMLObjectElement_data_Getter(mthis) native "HTMLObjectElement_data_Getter";

Native_HTMLObjectElement_data_Setter(mthis, value) native "HTMLObjectElement_data_Setter";

Native_HTMLObjectElement_form_Getter(mthis) native "HTMLObjectElement_form_Getter";

Native_HTMLObjectElement_height_Getter(mthis) native "HTMLObjectElement_height_Getter";

Native_HTMLObjectElement_height_Setter(mthis, value) native "HTMLObjectElement_height_Setter";

Native_HTMLObjectElement_name_Getter(mthis) native "HTMLObjectElement_name_Getter";

Native_HTMLObjectElement_name_Setter(mthis, value) native "HTMLObjectElement_name_Setter";

Native_HTMLObjectElement_type_Getter(mthis) native "HTMLObjectElement_type_Getter";

Native_HTMLObjectElement_type_Setter(mthis, value) native "HTMLObjectElement_type_Setter";

Native_HTMLObjectElement_useMap_Getter(mthis) native "HTMLObjectElement_useMap_Getter";

Native_HTMLObjectElement_useMap_Setter(mthis, value) native "HTMLObjectElement_useMap_Setter";

Native_HTMLObjectElement_validationMessage_Getter(mthis) native "HTMLObjectElement_validationMessage_Getter";

Native_HTMLObjectElement_validity_Getter(mthis) native "HTMLObjectElement_validity_Getter";

Native_HTMLObjectElement_width_Getter(mthis) native "HTMLObjectElement_width_Getter";

Native_HTMLObjectElement_width_Setter(mthis, value) native "HTMLObjectElement_width_Setter";

Native_HTMLObjectElement_willValidate_Getter(mthis) native "HTMLObjectElement_willValidate_Getter";

Native_HTMLObjectElement___getter___Callback(mthis, index_OR_name) native "HTMLObjectElement___getter___Callback";

Native_HTMLObjectElement___setter___Callback(mthis, index_OR_name, value) native "HTMLObjectElement___setter___Callback";

Native_HTMLObjectElement_checkValidity_Callback(mthis) native "HTMLObjectElement_checkValidity_Callback_RESOLVER_STRING_0_";

Native_HTMLObjectElement_setCustomValidity_Callback(mthis, error) native "HTMLObjectElement_setCustomValidity_Callback_RESOLVER_STRING_1_DOMString";

Native_HTMLOptGroupElement_disabled_Getter(mthis) native "HTMLOptGroupElement_disabled_Getter";

Native_HTMLOptGroupElement_disabled_Setter(mthis, value) native "HTMLOptGroupElement_disabled_Setter";

Native_HTMLOptGroupElement_label_Getter(mthis) native "HTMLOptGroupElement_label_Getter";

Native_HTMLOptGroupElement_label_Setter(mthis, value) native "HTMLOptGroupElement_label_Setter";

  // Generated overload resolver
Native_HTMLOptionElement_OptionElement__(data, value, defaultSelected, selected) {
    return Native_HTMLOptionElement__create_1constructorCallback(data, value, defaultSelected, selected);
  }

Native_HTMLOptionElement__create_1constructorCallback(data, value, defaultSelected, selected) native "HTMLOptionElement_constructorCallback_RESOLVER_STRING_4_DOMString_DOMString_boolean_boolean";

Native_HTMLOptionElement_defaultSelected_Getter(mthis) native "HTMLOptionElement_defaultSelected_Getter";

Native_HTMLOptionElement_defaultSelected_Setter(mthis, value) native "HTMLOptionElement_defaultSelected_Setter";

Native_HTMLOptionElement_disabled_Getter(mthis) native "HTMLOptionElement_disabled_Getter";

Native_HTMLOptionElement_disabled_Setter(mthis, value) native "HTMLOptionElement_disabled_Setter";

Native_HTMLOptionElement_form_Getter(mthis) native "HTMLOptionElement_form_Getter";

Native_HTMLOptionElement_index_Getter(mthis) native "HTMLOptionElement_index_Getter";

Native_HTMLOptionElement_label_Getter(mthis) native "HTMLOptionElement_label_Getter";

Native_HTMLOptionElement_label_Setter(mthis, value) native "HTMLOptionElement_label_Setter";

Native_HTMLOptionElement_selected_Getter(mthis) native "HTMLOptionElement_selected_Getter";

Native_HTMLOptionElement_selected_Setter(mthis, value) native "HTMLOptionElement_selected_Setter";

Native_HTMLOptionElement_value_Getter(mthis) native "HTMLOptionElement_value_Getter";

Native_HTMLOptionElement_value_Setter(mthis, value) native "HTMLOptionElement_value_Setter";

Native_HTMLOutputElement_defaultValue_Getter(mthis) native "HTMLOutputElement_defaultValue_Getter";

Native_HTMLOutputElement_defaultValue_Setter(mthis, value) native "HTMLOutputElement_defaultValue_Setter";

Native_HTMLOutputElement_form_Getter(mthis) native "HTMLOutputElement_form_Getter";

Native_HTMLOutputElement_htmlFor_Getter(mthis) native "HTMLOutputElement_htmlFor_Getter";

Native_HTMLOutputElement_labels_Getter(mthis) native "HTMLOutputElement_labels_Getter";

Native_HTMLOutputElement_name_Getter(mthis) native "HTMLOutputElement_name_Getter";

Native_HTMLOutputElement_name_Setter(mthis, value) native "HTMLOutputElement_name_Setter";

Native_HTMLOutputElement_type_Getter(mthis) native "HTMLOutputElement_type_Getter";

Native_HTMLOutputElement_validationMessage_Getter(mthis) native "HTMLOutputElement_validationMessage_Getter";

Native_HTMLOutputElement_validity_Getter(mthis) native "HTMLOutputElement_validity_Getter";

Native_HTMLOutputElement_value_Getter(mthis) native "HTMLOutputElement_value_Getter";

Native_HTMLOutputElement_value_Setter(mthis, value) native "HTMLOutputElement_value_Setter";

Native_HTMLOutputElement_willValidate_Getter(mthis) native "HTMLOutputElement_willValidate_Getter";

Native_HTMLOutputElement_checkValidity_Callback(mthis) native "HTMLOutputElement_checkValidity_Callback_RESOLVER_STRING_0_";

Native_HTMLOutputElement_setCustomValidity_Callback(mthis, error) native "HTMLOutputElement_setCustomValidity_Callback_RESOLVER_STRING_1_DOMString";

Native_HTMLParamElement_name_Getter(mthis) native "HTMLParamElement_name_Getter";

Native_HTMLParamElement_name_Setter(mthis, value) native "HTMLParamElement_name_Setter";

Native_HTMLParamElement_value_Getter(mthis) native "HTMLParamElement_value_Getter";

Native_HTMLParamElement_value_Setter(mthis, value) native "HTMLParamElement_value_Setter";

Native_HTMLProgressElement_labels_Getter(mthis) native "HTMLProgressElement_labels_Getter";

Native_HTMLProgressElement_max_Getter(mthis) native "HTMLProgressElement_max_Getter";

Native_HTMLProgressElement_max_Setter(mthis, value) native "HTMLProgressElement_max_Setter";

Native_HTMLProgressElement_position_Getter(mthis) native "HTMLProgressElement_position_Getter";

Native_HTMLProgressElement_value_Getter(mthis) native "HTMLProgressElement_value_Getter";

Native_HTMLProgressElement_value_Setter(mthis, value) native "HTMLProgressElement_value_Setter";

Native_HTMLQuoteElement_cite_Getter(mthis) native "HTMLQuoteElement_cite_Getter";

Native_HTMLQuoteElement_cite_Setter(mthis, value) native "HTMLQuoteElement_cite_Setter";

Native_HTMLScriptElement_async_Getter(mthis) native "HTMLScriptElement_async_Getter";

Native_HTMLScriptElement_async_Setter(mthis, value) native "HTMLScriptElement_async_Setter";

Native_HTMLScriptElement_charset_Getter(mthis) native "HTMLScriptElement_charset_Getter";

Native_HTMLScriptElement_charset_Setter(mthis, value) native "HTMLScriptElement_charset_Setter";

Native_HTMLScriptElement_crossOrigin_Getter(mthis) native "HTMLScriptElement_crossOrigin_Getter";

Native_HTMLScriptElement_crossOrigin_Setter(mthis, value) native "HTMLScriptElement_crossOrigin_Setter";

Native_HTMLScriptElement_defer_Getter(mthis) native "HTMLScriptElement_defer_Getter";

Native_HTMLScriptElement_defer_Setter(mthis, value) native "HTMLScriptElement_defer_Setter";

Native_HTMLScriptElement_nonce_Getter(mthis) native "HTMLScriptElement_nonce_Getter";

Native_HTMLScriptElement_nonce_Setter(mthis, value) native "HTMLScriptElement_nonce_Setter";

Native_HTMLScriptElement_src_Getter(mthis) native "HTMLScriptElement_src_Getter";

Native_HTMLScriptElement_src_Setter(mthis, value) native "HTMLScriptElement_src_Setter";

Native_HTMLScriptElement_type_Getter(mthis) native "HTMLScriptElement_type_Getter";

Native_HTMLScriptElement_type_Setter(mthis, value) native "HTMLScriptElement_type_Setter";

Native_HTMLSelectElement_autofocus_Getter(mthis) native "HTMLSelectElement_autofocus_Getter";

Native_HTMLSelectElement_autofocus_Setter(mthis, value) native "HTMLSelectElement_autofocus_Setter";

Native_HTMLSelectElement_disabled_Getter(mthis) native "HTMLSelectElement_disabled_Getter";

Native_HTMLSelectElement_disabled_Setter(mthis, value) native "HTMLSelectElement_disabled_Setter";

Native_HTMLSelectElement_form_Getter(mthis) native "HTMLSelectElement_form_Getter";

Native_HTMLSelectElement_labels_Getter(mthis) native "HTMLSelectElement_labels_Getter";

Native_HTMLSelectElement_length_Getter(mthis) native "HTMLSelectElement_length_Getter";

Native_HTMLSelectElement_length_Setter(mthis, value) native "HTMLSelectElement_length_Setter";

Native_HTMLSelectElement_multiple_Getter(mthis) native "HTMLSelectElement_multiple_Getter";

Native_HTMLSelectElement_multiple_Setter(mthis, value) native "HTMLSelectElement_multiple_Setter";

Native_HTMLSelectElement_name_Getter(mthis) native "HTMLSelectElement_name_Getter";

Native_HTMLSelectElement_name_Setter(mthis, value) native "HTMLSelectElement_name_Setter";

Native_HTMLSelectElement_required_Getter(mthis) native "HTMLSelectElement_required_Getter";

Native_HTMLSelectElement_required_Setter(mthis, value) native "HTMLSelectElement_required_Setter";

Native_HTMLSelectElement_selectedIndex_Getter(mthis) native "HTMLSelectElement_selectedIndex_Getter";

Native_HTMLSelectElement_selectedIndex_Setter(mthis, value) native "HTMLSelectElement_selectedIndex_Setter";

Native_HTMLSelectElement_size_Getter(mthis) native "HTMLSelectElement_size_Getter";

Native_HTMLSelectElement_size_Setter(mthis, value) native "HTMLSelectElement_size_Setter";

Native_HTMLSelectElement_type_Getter(mthis) native "HTMLSelectElement_type_Getter";

Native_HTMLSelectElement_validationMessage_Getter(mthis) native "HTMLSelectElement_validationMessage_Getter";

Native_HTMLSelectElement_validity_Getter(mthis) native "HTMLSelectElement_validity_Getter";

Native_HTMLSelectElement_value_Getter(mthis) native "HTMLSelectElement_value_Getter";

Native_HTMLSelectElement_value_Setter(mthis, value) native "HTMLSelectElement_value_Setter";

Native_HTMLSelectElement_willValidate_Getter(mthis) native "HTMLSelectElement_willValidate_Getter";

Native_HTMLSelectElement___setter___Callback(mthis, index, value) native "HTMLSelectElement___setter___Callback_RESOLVER_STRING_2_unsigned long_HTMLOptionElement";

Native_HTMLSelectElement_checkValidity_Callback(mthis) native "HTMLSelectElement_checkValidity_Callback_RESOLVER_STRING_0_";

Native_HTMLSelectElement_item_Callback(mthis, index) native "HTMLSelectElement_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_HTMLSelectElement_namedItem_Callback(mthis, name) native "HTMLSelectElement_namedItem_Callback_RESOLVER_STRING_1_DOMString";

Native_HTMLSelectElement_setCustomValidity_Callback(mthis, error) native "HTMLSelectElement_setCustomValidity_Callback_RESOLVER_STRING_1_DOMString";

Native_HTMLShadowElement_resetStyleInheritance_Getter(mthis) native "HTMLShadowElement_resetStyleInheritance_Getter";

Native_HTMLShadowElement_resetStyleInheritance_Setter(mthis, value) native "HTMLShadowElement_resetStyleInheritance_Setter";

Native_HTMLShadowElement_getDistributedNodes_Callback(mthis) native "HTMLShadowElement_getDistributedNodes_Callback_RESOLVER_STRING_0_";

Native_HTMLSourceElement_media_Getter(mthis) native "HTMLSourceElement_media_Getter";

Native_HTMLSourceElement_media_Setter(mthis, value) native "HTMLSourceElement_media_Setter";

Native_HTMLSourceElement_src_Getter(mthis) native "HTMLSourceElement_src_Getter";

Native_HTMLSourceElement_src_Setter(mthis, value) native "HTMLSourceElement_src_Setter";

Native_HTMLSourceElement_type_Getter(mthis) native "HTMLSourceElement_type_Getter";

Native_HTMLSourceElement_type_Setter(mthis, value) native "HTMLSourceElement_type_Setter";

Native_HTMLStyleElement_disabled_Getter(mthis) native "HTMLStyleElement_disabled_Getter";

Native_HTMLStyleElement_disabled_Setter(mthis, value) native "HTMLStyleElement_disabled_Setter";

Native_HTMLStyleElement_media_Getter(mthis) native "HTMLStyleElement_media_Getter";

Native_HTMLStyleElement_media_Setter(mthis, value) native "HTMLStyleElement_media_Setter";

Native_HTMLStyleElement_scoped_Getter(mthis) native "HTMLStyleElement_scoped_Getter";

Native_HTMLStyleElement_scoped_Setter(mthis, value) native "HTMLStyleElement_scoped_Setter";

Native_HTMLStyleElement_sheet_Getter(mthis) native "HTMLStyleElement_sheet_Getter";

Native_HTMLStyleElement_type_Getter(mthis) native "HTMLStyleElement_type_Getter";

Native_HTMLStyleElement_type_Setter(mthis, value) native "HTMLStyleElement_type_Setter";

Native_HTMLTableCellElement_cellIndex_Getter(mthis) native "HTMLTableCellElement_cellIndex_Getter";

Native_HTMLTableCellElement_colSpan_Getter(mthis) native "HTMLTableCellElement_colSpan_Getter";

Native_HTMLTableCellElement_colSpan_Setter(mthis, value) native "HTMLTableCellElement_colSpan_Setter";

Native_HTMLTableCellElement_headers_Getter(mthis) native "HTMLTableCellElement_headers_Getter";

Native_HTMLTableCellElement_headers_Setter(mthis, value) native "HTMLTableCellElement_headers_Setter";

Native_HTMLTableCellElement_rowSpan_Getter(mthis) native "HTMLTableCellElement_rowSpan_Getter";

Native_HTMLTableCellElement_rowSpan_Setter(mthis, value) native "HTMLTableCellElement_rowSpan_Setter";

Native_HTMLTableColElement_span_Getter(mthis) native "HTMLTableColElement_span_Getter";

Native_HTMLTableColElement_span_Setter(mthis, value) native "HTMLTableColElement_span_Setter";

Native_HTMLTableElement_caption_Getter(mthis) native "HTMLTableElement_caption_Getter";

Native_HTMLTableElement_caption_Setter(mthis, value) native "HTMLTableElement_caption_Setter";

Native_HTMLTableElement_rows_Getter(mthis) native "HTMLTableElement_rows_Getter";

Native_HTMLTableElement_tBodies_Getter(mthis) native "HTMLTableElement_tBodies_Getter";

Native_HTMLTableElement_tFoot_Getter(mthis) native "HTMLTableElement_tFoot_Getter";

Native_HTMLTableElement_tFoot_Setter(mthis, value) native "HTMLTableElement_tFoot_Setter";

Native_HTMLTableElement_tHead_Getter(mthis) native "HTMLTableElement_tHead_Getter";

Native_HTMLTableElement_tHead_Setter(mthis, value) native "HTMLTableElement_tHead_Setter";

Native_HTMLTableElement_createCaption_Callback(mthis) native "HTMLTableElement_createCaption_Callback_RESOLVER_STRING_0_";

Native_HTMLTableElement_createTBody_Callback(mthis) native "HTMLTableElement_createTBody_Callback_RESOLVER_STRING_0_";

Native_HTMLTableElement_createTFoot_Callback(mthis) native "HTMLTableElement_createTFoot_Callback_RESOLVER_STRING_0_";

Native_HTMLTableElement_createTHead_Callback(mthis) native "HTMLTableElement_createTHead_Callback_RESOLVER_STRING_0_";

Native_HTMLTableElement_deleteCaption_Callback(mthis) native "HTMLTableElement_deleteCaption_Callback_RESOLVER_STRING_0_";

Native_HTMLTableElement_deleteRow_Callback(mthis, index) native "HTMLTableElement_deleteRow_Callback_RESOLVER_STRING_1_long";

Native_HTMLTableElement_deleteTFoot_Callback(mthis) native "HTMLTableElement_deleteTFoot_Callback_RESOLVER_STRING_0_";

Native_HTMLTableElement_deleteTHead_Callback(mthis) native "HTMLTableElement_deleteTHead_Callback_RESOLVER_STRING_0_";

Native_HTMLTableElement_insertRow_Callback(mthis, index) native "HTMLTableElement_insertRow_Callback_RESOLVER_STRING_1_long";

Native_HTMLTableRowElement_cells_Getter(mthis) native "HTMLTableRowElement_cells_Getter";

Native_HTMLTableRowElement_rowIndex_Getter(mthis) native "HTMLTableRowElement_rowIndex_Getter";

Native_HTMLTableRowElement_sectionRowIndex_Getter(mthis) native "HTMLTableRowElement_sectionRowIndex_Getter";

Native_HTMLTableRowElement_deleteCell_Callback(mthis, index) native "HTMLTableRowElement_deleteCell_Callback_RESOLVER_STRING_1_long";

Native_HTMLTableRowElement_insertCell_Callback(mthis, index) native "HTMLTableRowElement_insertCell_Callback_RESOLVER_STRING_1_long";

Native_HTMLTableSectionElement_rows_Getter(mthis) native "HTMLTableSectionElement_rows_Getter";

Native_HTMLTableSectionElement_deleteRow_Callback(mthis, index) native "HTMLTableSectionElement_deleteRow_Callback_RESOLVER_STRING_1_long";

Native_HTMLTableSectionElement_insertRow_Callback(mthis, index) native "HTMLTableSectionElement_insertRow_Callback_RESOLVER_STRING_1_long";

Native_HTMLTemplateElement_content_Getter(mthis) native "HTMLTemplateElement_content_Getter";

Native_HTMLTextAreaElement_autofocus_Getter(mthis) native "HTMLTextAreaElement_autofocus_Getter";

Native_HTMLTextAreaElement_autofocus_Setter(mthis, value) native "HTMLTextAreaElement_autofocus_Setter";

Native_HTMLTextAreaElement_cols_Getter(mthis) native "HTMLTextAreaElement_cols_Getter";

Native_HTMLTextAreaElement_cols_Setter(mthis, value) native "HTMLTextAreaElement_cols_Setter";

Native_HTMLTextAreaElement_defaultValue_Getter(mthis) native "HTMLTextAreaElement_defaultValue_Getter";

Native_HTMLTextAreaElement_defaultValue_Setter(mthis, value) native "HTMLTextAreaElement_defaultValue_Setter";

Native_HTMLTextAreaElement_dirName_Getter(mthis) native "HTMLTextAreaElement_dirName_Getter";

Native_HTMLTextAreaElement_dirName_Setter(mthis, value) native "HTMLTextAreaElement_dirName_Setter";

Native_HTMLTextAreaElement_disabled_Getter(mthis) native "HTMLTextAreaElement_disabled_Getter";

Native_HTMLTextAreaElement_disabled_Setter(mthis, value) native "HTMLTextAreaElement_disabled_Setter";

Native_HTMLTextAreaElement_form_Getter(mthis) native "HTMLTextAreaElement_form_Getter";

Native_HTMLTextAreaElement_inputMode_Getter(mthis) native "HTMLTextAreaElement_inputMode_Getter";

Native_HTMLTextAreaElement_inputMode_Setter(mthis, value) native "HTMLTextAreaElement_inputMode_Setter";

Native_HTMLTextAreaElement_labels_Getter(mthis) native "HTMLTextAreaElement_labels_Getter";

Native_HTMLTextAreaElement_maxLength_Getter(mthis) native "HTMLTextAreaElement_maxLength_Getter";

Native_HTMLTextAreaElement_maxLength_Setter(mthis, value) native "HTMLTextAreaElement_maxLength_Setter";

Native_HTMLTextAreaElement_name_Getter(mthis) native "HTMLTextAreaElement_name_Getter";

Native_HTMLTextAreaElement_name_Setter(mthis, value) native "HTMLTextAreaElement_name_Setter";

Native_HTMLTextAreaElement_placeholder_Getter(mthis) native "HTMLTextAreaElement_placeholder_Getter";

Native_HTMLTextAreaElement_placeholder_Setter(mthis, value) native "HTMLTextAreaElement_placeholder_Setter";

Native_HTMLTextAreaElement_readOnly_Getter(mthis) native "HTMLTextAreaElement_readOnly_Getter";

Native_HTMLTextAreaElement_readOnly_Setter(mthis, value) native "HTMLTextAreaElement_readOnly_Setter";

Native_HTMLTextAreaElement_required_Getter(mthis) native "HTMLTextAreaElement_required_Getter";

Native_HTMLTextAreaElement_required_Setter(mthis, value) native "HTMLTextAreaElement_required_Setter";

Native_HTMLTextAreaElement_rows_Getter(mthis) native "HTMLTextAreaElement_rows_Getter";

Native_HTMLTextAreaElement_rows_Setter(mthis, value) native "HTMLTextAreaElement_rows_Setter";

Native_HTMLTextAreaElement_selectionDirection_Getter(mthis) native "HTMLTextAreaElement_selectionDirection_Getter";

Native_HTMLTextAreaElement_selectionDirection_Setter(mthis, value) native "HTMLTextAreaElement_selectionDirection_Setter";

Native_HTMLTextAreaElement_selectionEnd_Getter(mthis) native "HTMLTextAreaElement_selectionEnd_Getter";

Native_HTMLTextAreaElement_selectionEnd_Setter(mthis, value) native "HTMLTextAreaElement_selectionEnd_Setter";

Native_HTMLTextAreaElement_selectionStart_Getter(mthis) native "HTMLTextAreaElement_selectionStart_Getter";

Native_HTMLTextAreaElement_selectionStart_Setter(mthis, value) native "HTMLTextAreaElement_selectionStart_Setter";

Native_HTMLTextAreaElement_textLength_Getter(mthis) native "HTMLTextAreaElement_textLength_Getter";

Native_HTMLTextAreaElement_type_Getter(mthis) native "HTMLTextAreaElement_type_Getter";

Native_HTMLTextAreaElement_validationMessage_Getter(mthis) native "HTMLTextAreaElement_validationMessage_Getter";

Native_HTMLTextAreaElement_validity_Getter(mthis) native "HTMLTextAreaElement_validity_Getter";

Native_HTMLTextAreaElement_value_Getter(mthis) native "HTMLTextAreaElement_value_Getter";

Native_HTMLTextAreaElement_value_Setter(mthis, value) native "HTMLTextAreaElement_value_Setter";

Native_HTMLTextAreaElement_willValidate_Getter(mthis) native "HTMLTextAreaElement_willValidate_Getter";

Native_HTMLTextAreaElement_wrap_Getter(mthis) native "HTMLTextAreaElement_wrap_Getter";

Native_HTMLTextAreaElement_wrap_Setter(mthis, value) native "HTMLTextAreaElement_wrap_Setter";

Native_HTMLTextAreaElement_checkValidity_Callback(mthis) native "HTMLTextAreaElement_checkValidity_Callback_RESOLVER_STRING_0_";

Native_HTMLTextAreaElement_select_Callback(mthis) native "HTMLTextAreaElement_select_Callback_RESOLVER_STRING_0_";

Native_HTMLTextAreaElement_setCustomValidity_Callback(mthis, error) native "HTMLTextAreaElement_setCustomValidity_Callback_RESOLVER_STRING_1_DOMString";

  // Generated overload resolver
Native_HTMLTextAreaElement_setRangeText(mthis, replacement, start, end, selectionMode) {
    if ((replacement is String || replacement == null) && start == null && end == null && selectionMode == null) {
      Native_HTMLTextAreaElement__setRangeText_1_Callback(mthis, replacement);
      return;
    }
    if ((selectionMode is String || selectionMode == null) && (end is int || end == null) && (start is int || start == null) && (replacement is String || replacement == null)) {
      Native_HTMLTextAreaElement__setRangeText_2_Callback(mthis, replacement, start, end, selectionMode);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

Native_HTMLTextAreaElement__setRangeText_1_Callback(mthis, replacement) native "HTMLTextAreaElement_setRangeText_Callback_RESOLVER_STRING_1_DOMString";

Native_HTMLTextAreaElement__setRangeText_2_Callback(mthis, replacement, start, end, selectionMode) native "HTMLTextAreaElement_setRangeText_Callback_RESOLVER_STRING_4_DOMString_unsigned long_unsigned long_DOMString";

  // Generated overload resolver
Native_HTMLTextAreaElement_setSelectionRange(mthis, start, end, direction) {
    if (direction != null) {
      Native_HTMLTextAreaElement__setSelectionRange_1_Callback(mthis, start, end, direction);
      return;
    }
    Native_HTMLTextAreaElement__setSelectionRange_2_Callback(mthis, start, end);
    return;
  }

Native_HTMLTextAreaElement__setSelectionRange_1_Callback(mthis, start, end, direction) native "HTMLTextAreaElement_setSelectionRange_Callback_RESOLVER_STRING_3_long_long_DOMString";

Native_HTMLTextAreaElement__setSelectionRange_2_Callback(mthis, start, end) native "HTMLTextAreaElement_setSelectionRange_Callback_RESOLVER_STRING_2_long_long";

Native_HTMLTrackElement_default_Getter(mthis) native "HTMLTrackElement_default_Getter";

Native_HTMLTrackElement_default_Setter(mthis, value) native "HTMLTrackElement_default_Setter";

Native_HTMLTrackElement_kind_Getter(mthis) native "HTMLTrackElement_kind_Getter";

Native_HTMLTrackElement_kind_Setter(mthis, value) native "HTMLTrackElement_kind_Setter";

Native_HTMLTrackElement_label_Getter(mthis) native "HTMLTrackElement_label_Getter";

Native_HTMLTrackElement_label_Setter(mthis, value) native "HTMLTrackElement_label_Setter";

Native_HTMLTrackElement_readyState_Getter(mthis) native "HTMLTrackElement_readyState_Getter";

Native_HTMLTrackElement_src_Getter(mthis) native "HTMLTrackElement_src_Getter";

Native_HTMLTrackElement_src_Setter(mthis, value) native "HTMLTrackElement_src_Setter";

Native_HTMLTrackElement_srclang_Getter(mthis) native "HTMLTrackElement_srclang_Getter";

Native_HTMLTrackElement_srclang_Setter(mthis, value) native "HTMLTrackElement_srclang_Setter";

Native_HTMLTrackElement_track_Getter(mthis) native "HTMLTrackElement_track_Getter";

Native_HTMLVideoElement_height_Getter(mthis) native "HTMLVideoElement_height_Getter";

Native_HTMLVideoElement_height_Setter(mthis, value) native "HTMLVideoElement_height_Setter";

Native_HTMLVideoElement_poster_Getter(mthis) native "HTMLVideoElement_poster_Getter";

Native_HTMLVideoElement_poster_Setter(mthis, value) native "HTMLVideoElement_poster_Setter";

Native_HTMLVideoElement_videoHeight_Getter(mthis) native "HTMLVideoElement_videoHeight_Getter";

Native_HTMLVideoElement_videoWidth_Getter(mthis) native "HTMLVideoElement_videoWidth_Getter";

Native_HTMLVideoElement_webkitDecodedFrameCount_Getter(mthis) native "HTMLVideoElement_webkitDecodedFrameCount_Getter";

Native_HTMLVideoElement_webkitDroppedFrameCount_Getter(mthis) native "HTMLVideoElement_webkitDroppedFrameCount_Getter";

Native_HTMLVideoElement_width_Getter(mthis) native "HTMLVideoElement_width_Getter";

Native_HTMLVideoElement_width_Setter(mthis, value) native "HTMLVideoElement_width_Setter";

Native_HTMLVideoElement_getVideoPlaybackQuality_Callback(mthis) native "HTMLVideoElement_getVideoPlaybackQuality_Callback_RESOLVER_STRING_0_";

Native_HTMLVideoElement_webkitEnterFullscreen_Callback(mthis) native "HTMLVideoElement_webkitEnterFullscreen_Callback_RESOLVER_STRING_0_";

Native_HTMLVideoElement_webkitExitFullscreen_Callback(mthis) native "HTMLVideoElement_webkitExitFullscreen_Callback_RESOLVER_STRING_0_";

Native_HashChangeEvent_newURL_Getter(mthis) native "HashChangeEvent_newURL_Getter";

Native_HashChangeEvent_oldURL_Getter(mthis) native "HashChangeEvent_oldURL_Getter";

Native_HashChangeEvent_initHashChangeEvent_Callback(mthis, type, canBubble, cancelable, oldURL, newURL) native "HashChangeEvent_initHashChangeEvent_Callback_RESOLVER_STRING_5_DOMString_boolean_boolean_DOMString_DOMString";

Native_History_length_Getter(mthis) native "History_length_Getter";

Native_History_state_Getter(mthis) native "History_state_Getter";

Native_History_back_Callback(mthis) native "History_back_Callback_RESOLVER_STRING_0_";

Native_History_forward_Callback(mthis) native "History_forward_Callback_RESOLVER_STRING_0_";

Native_History_go_Callback(mthis, distance) native "History_go_Callback_RESOLVER_STRING_1_long";

Native_History_pushState_Callback(mthis, data, title, url) native "History_pushState_Callback";

Native_History_replaceState_Callback(mthis, data, title, url) native "History_replaceState_Callback";

Native_IDBCursor_direction_Getter(mthis) native "IDBCursor_direction_Getter";

Native_IDBCursor_key_Getter(mthis) native "IDBCursor_key_Getter";

Native_IDBCursor_primaryKey_Getter(mthis) native "IDBCursor_primaryKey_Getter";

Native_IDBCursor_source_Getter(mthis) native "IDBCursor_source_Getter";

Native_IDBCursor_advance_Callback(mthis, count) native "IDBCursor_advance_Callback_RESOLVER_STRING_1_unsigned long";

Native_IDBCursor_continuePrimaryKey_Callback(mthis, key, primaryKey) native "IDBCursor_continuePrimaryKey_Callback_RESOLVER_STRING_2_ScriptValue_ScriptValue";

Native_IDBCursor_delete_Callback(mthis) native "IDBCursor_delete_Callback_RESOLVER_STRING_0_";

Native_IDBCursor_next_Callback(mthis, key) native "IDBCursor_continue_Callback_RESOLVER_STRING_1_ScriptValue";

Native_IDBCursor_update_Callback(mthis, value) native "IDBCursor_update_Callback_RESOLVER_STRING_1_ScriptValue";

Native_IDBCursorWithValue_value_Getter(mthis) native "IDBCursorWithValue_value_Getter";

Native_IDBDatabase_name_Getter(mthis) native "IDBDatabase_name_Getter";

Native_IDBDatabase_objectStoreNames_Getter(mthis) native "IDBDatabase_objectStoreNames_Getter";

Native_IDBDatabase_version_Getter(mthis) native "IDBDatabase_version_Getter";

Native_IDBDatabase_close_Callback(mthis) native "IDBDatabase_close_Callback_RESOLVER_STRING_0_";

Native_IDBDatabase_createObjectStore_Callback(mthis, name, options) native "IDBDatabase_createObjectStore_Callback_RESOLVER_STRING_2_DOMString_Dictionary";

Native_IDBDatabase_deleteObjectStore_Callback(mthis, name) native "IDBDatabase_deleteObjectStore_Callback_RESOLVER_STRING_1_DOMString";

  // Generated overload resolver
Native_IDBDatabase_transaction(mthis, storeName_OR_storeNames, mode) {
    if ((mode is String || mode == null) && (storeName_OR_storeNames is List<String> || storeName_OR_storeNames == null)) {
      return Native_IDBDatabase__transaction_1_Callback(mthis, storeName_OR_storeNames, mode);
    }
    if ((mode is String || mode == null) && (storeName_OR_storeNames is List<String> || storeName_OR_storeNames == null)) {
      return Native_IDBDatabase__transaction_2_Callback(mthis, storeName_OR_storeNames, mode);
    }
    if ((mode is String || mode == null) && (storeName_OR_storeNames is String || storeName_OR_storeNames == null)) {
      return Native_IDBDatabase__transaction_3_Callback(mthis, storeName_OR_storeNames, mode);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

Native_IDBDatabase__transaction_1_Callback(mthis, storeName_OR_storeNames, mode) native "IDBDatabase_transaction_Callback_RESOLVER_STRING_2_DOMStringList_DOMString";

Native_IDBDatabase__transaction_2_Callback(mthis, storeName_OR_storeNames, mode) native "IDBDatabase_transaction_Callback_RESOLVER_STRING_2_sequence<DOMString>_DOMString";

Native_IDBDatabase__transaction_3_Callback(mthis, storeName_OR_storeNames, mode) native "IDBDatabase_transaction_Callback_RESOLVER_STRING_2_DOMString_DOMString";

Native_IDBDatabase_transactionList_Callback(mthis, storeNames, mode) native "IDBDatabase_transaction_Callback_RESOLVER_STRING_2_sequence<DOMString>_DOMString";

Native_IDBDatabase_transactionStore_Callback(mthis, storeName, mode) native "IDBDatabase_transaction_Callback_RESOLVER_STRING_2_DOMString_DOMString";

Native_IDBDatabase_transactionStores_Callback(mthis, storeNames, mode) native "IDBDatabase_transaction_Callback_RESOLVER_STRING_2_DOMStringList_DOMString";

Native_IDBFactory_cmp_Callback(mthis, first, second) native "IDBFactory_cmp_Callback_RESOLVER_STRING_2_ScriptValue_ScriptValue";

Native_IDBFactory_deleteDatabase_Callback(mthis, name) native "IDBFactory_deleteDatabase_Callback_RESOLVER_STRING_1_DOMString";

  // Generated overload resolver
Native_IDBFactory__open(mthis, name, version) {
    if (version != null) {
      return Native_IDBFactory__open_1_Callback(mthis, name, version);
    }
    return Native_IDBFactory__open_2_Callback(mthis, name);
  }

Native_IDBFactory__open_1_Callback(mthis, name, version) native "IDBFactory_open_Callback_RESOLVER_STRING_2_DOMString_unsigned long long";

Native_IDBFactory__open_2_Callback(mthis, name) native "IDBFactory_open_Callback_RESOLVER_STRING_1_DOMString";

Native_IDBFactory_webkitGetDatabaseNames_Callback(mthis) native "IDBFactory_webkitGetDatabaseNames_Callback_RESOLVER_STRING_0_";

Native_IDBIndex_keyPath_Getter(mthis) native "IDBIndex_keyPath_Getter";

Native_IDBIndex_multiEntry_Getter(mthis) native "IDBIndex_multiEntry_Getter";

Native_IDBIndex_name_Getter(mthis) native "IDBIndex_name_Getter";

Native_IDBIndex_objectStore_Getter(mthis) native "IDBIndex_objectStore_Getter";

Native_IDBIndex_unique_Getter(mthis) native "IDBIndex_unique_Getter";

Native_IDBIndex_count_Callback(mthis, key) native "IDBIndex_count_Callback_RESOLVER_STRING_1_ScriptValue";

Native_IDBIndex_get_Callback(mthis, key) native "IDBIndex_get_Callback_RESOLVER_STRING_1_ScriptValue";

Native_IDBIndex_getKey_Callback(mthis, key) native "IDBIndex_getKey_Callback_RESOLVER_STRING_1_ScriptValue";

Native_IDBIndex_openCursor_Callback(mthis, key, direction) native "IDBIndex_openCursor_Callback_RESOLVER_STRING_2_ScriptValue_DOMString";

Native_IDBIndex_openKeyCursor_Callback(mthis, key, direction) native "IDBIndex_openKeyCursor_Callback_RESOLVER_STRING_2_ScriptValue_DOMString";

Native_IDBKeyRange_lower_Getter(mthis) native "IDBKeyRange_lower_Getter";

Native_IDBKeyRange_lowerOpen_Getter(mthis) native "IDBKeyRange_lowerOpen_Getter";

Native_IDBKeyRange_upper_Getter(mthis) native "IDBKeyRange_upper_Getter";

Native_IDBKeyRange_upperOpen_Getter(mthis) native "IDBKeyRange_upperOpen_Getter";

Native_IDBKeyRange_bound__Callback(lower, upper, lowerOpen, upperOpen) native "IDBKeyRange_bound_Callback_RESOLVER_STRING_4_ScriptValue_ScriptValue_boolean_boolean";

Native_IDBKeyRange_lowerBound__Callback(bound, open) native "IDBKeyRange_lowerBound_Callback_RESOLVER_STRING_2_ScriptValue_boolean";

Native_IDBKeyRange_only__Callback(value) native "IDBKeyRange_only_Callback_RESOLVER_STRING_1_ScriptValue";

Native_IDBKeyRange_upperBound__Callback(bound, open) native "IDBKeyRange_upperBound_Callback_RESOLVER_STRING_2_ScriptValue_boolean";

Native_IDBObjectStore_autoIncrement_Getter(mthis) native "IDBObjectStore_autoIncrement_Getter";

Native_IDBObjectStore_indexNames_Getter(mthis) native "IDBObjectStore_indexNames_Getter";

Native_IDBObjectStore_keyPath_Getter(mthis) native "IDBObjectStore_keyPath_Getter";

Native_IDBObjectStore_name_Getter(mthis) native "IDBObjectStore_name_Getter";

Native_IDBObjectStore_transaction_Getter(mthis) native "IDBObjectStore_transaction_Getter";

Native_IDBObjectStore_add_Callback(mthis, value, key) native "IDBObjectStore_add_Callback_RESOLVER_STRING_2_ScriptValue_ScriptValue";

Native_IDBObjectStore_clear_Callback(mthis) native "IDBObjectStore_clear_Callback_RESOLVER_STRING_0_";

Native_IDBObjectStore_count_Callback(mthis, key) native "IDBObjectStore_count_Callback_RESOLVER_STRING_1_ScriptValue";

  // Generated overload resolver
Native_IDBObjectStore__createIndex(mthis, name, keyPath, options) {
    if ((options is Map || options == null) && (keyPath is List<String> || keyPath == null) && (name is String || name == null)) {
      return Native_IDBObjectStore__createIndex_1_Callback(mthis, name, keyPath, options);
    }
    if ((options is Map || options == null) && (keyPath is String || keyPath == null) && (name is String || name == null)) {
      return Native_IDBObjectStore__createIndex_2_Callback(mthis, name, keyPath, options);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

Native_IDBObjectStore__createIndex_1_Callback(mthis, name, keyPath, options) native "IDBObjectStore_createIndex_Callback_RESOLVER_STRING_3_DOMString_sequence<DOMString>_Dictionary";

Native_IDBObjectStore__createIndex_2_Callback(mthis, name, keyPath, options) native "IDBObjectStore_createIndex_Callback_RESOLVER_STRING_3_DOMString_DOMString_Dictionary";

Native_IDBObjectStore_delete_Callback(mthis, key) native "IDBObjectStore_delete_Callback_RESOLVER_STRING_1_ScriptValue";

Native_IDBObjectStore_deleteIndex_Callback(mthis, name) native "IDBObjectStore_deleteIndex_Callback_RESOLVER_STRING_1_DOMString";

Native_IDBObjectStore_get_Callback(mthis, key) native "IDBObjectStore_get_Callback_RESOLVER_STRING_1_ScriptValue";

Native_IDBObjectStore_index_Callback(mthis, name) native "IDBObjectStore_index_Callback_RESOLVER_STRING_1_DOMString";

Native_IDBObjectStore_openCursor_Callback(mthis, key, direction) native "IDBObjectStore_openCursor_Callback_RESOLVER_STRING_2_ScriptValue_DOMString";

Native_IDBObjectStore_openKeyCursor_Callback(mthis, range, direction) native "IDBObjectStore_openKeyCursor_Callback_RESOLVER_STRING_2_ScriptValue_DOMString";

Native_IDBObjectStore_put_Callback(mthis, value, key) native "IDBObjectStore_put_Callback_RESOLVER_STRING_2_ScriptValue_ScriptValue";

Native_IDBRequest_error_Getter(mthis) native "IDBRequest_error_Getter";

Native_IDBRequest_readyState_Getter(mthis) native "IDBRequest_readyState_Getter";

Native_IDBRequest_result_Getter(mthis) native "IDBRequest_result_Getter";

Native_IDBRequest_source_Getter(mthis) native "IDBRequest_source_Getter";

Native_IDBRequest_transaction_Getter(mthis) native "IDBRequest_transaction_Getter";

Native_IDBTransaction_db_Getter(mthis) native "IDBTransaction_db_Getter";

Native_IDBTransaction_error_Getter(mthis) native "IDBTransaction_error_Getter";

Native_IDBTransaction_mode_Getter(mthis) native "IDBTransaction_mode_Getter";

Native_IDBTransaction_abort_Callback(mthis) native "IDBTransaction_abort_Callback_RESOLVER_STRING_0_";

Native_IDBTransaction_objectStore_Callback(mthis, name) native "IDBTransaction_objectStore_Callback_RESOLVER_STRING_1_DOMString";

Native_IDBVersionChangeEvent_dataLoss_Getter(mthis) native "IDBVersionChangeEvent_dataLoss_Getter";

Native_IDBVersionChangeEvent_dataLossMessage_Getter(mthis) native "IDBVersionChangeEvent_dataLossMessage_Getter";

Native_IDBVersionChangeEvent_newVersion_Getter(mthis) native "IDBVersionChangeEvent_newVersion_Getter";

Native_IDBVersionChangeEvent_oldVersion_Getter(mthis) native "IDBVersionChangeEvent_oldVersion_Getter";

Native_ImageBitmap_height_Getter(mthis) native "ImageBitmap_height_Getter";

Native_ImageBitmap_width_Getter(mthis) native "ImageBitmap_width_Getter";

Native_ImageData_data_Getter(mthis) native "ImageData_data_Getter";

Native_ImageData_height_Getter(mthis) native "ImageData_height_Getter";

Native_ImageData_width_Getter(mthis) native "ImageData_width_Getter";

Native_InjectedScriptHost_inspect_Callback(mthis, objectId, hints) native "InjectedScriptHost_inspect_Callback";

Native_InputMethodContext_compositionEndOffset_Getter(mthis) native "InputMethodContext_compositionEndOffset_Getter";

Native_InputMethodContext_compositionStartOffset_Getter(mthis) native "InputMethodContext_compositionStartOffset_Getter";

Native_InputMethodContext_locale_Getter(mthis) native "InputMethodContext_locale_Getter";

Native_InputMethodContext_target_Getter(mthis) native "InputMethodContext_target_Getter";

Native_InputMethodContext_confirmComposition_Callback(mthis) native "InputMethodContext_confirmComposition_Callback_RESOLVER_STRING_0_";

Native_InstallPhaseEvent_waitUntil_Callback(mthis, value) native "InstallPhaseEvent_waitUntil_Callback_RESOLVER_STRING_1_ScriptValue";

Native_InstallEvent_replace_Callback(mthis) native "InstallEvent_replace_Callback_RESOLVER_STRING_0_";

Native_Key_algorithm_Getter(mthis) native "Key_algorithm_Getter";

Native_Key_extractable_Getter(mthis) native "Key_extractable_Getter";

Native_Key_type_Getter(mthis) native "Key_type_Getter";

Native_Key_usages_Getter(mthis) native "Key_usages_Getter";

Native_KeyPair_privateKey_Getter(mthis) native "KeyPair_privateKey_Getter";

Native_KeyPair_publicKey_Getter(mthis) native "KeyPair_publicKey_Getter";

Native_KeyboardEvent_altGraphKey_Getter(mthis) native "KeyboardEvent_altGraphKey_Getter";

Native_KeyboardEvent_altKey_Getter(mthis) native "KeyboardEvent_altKey_Getter";

Native_KeyboardEvent_ctrlKey_Getter(mthis) native "KeyboardEvent_ctrlKey_Getter";

Native_KeyboardEvent_keyIdentifier_Getter(mthis) native "KeyboardEvent_keyIdentifier_Getter";

Native_KeyboardEvent_keyLocation_Getter(mthis) native "KeyboardEvent_keyLocation_Getter";

Native_KeyboardEvent_location_Getter(mthis) native "KeyboardEvent_location_Getter";

Native_KeyboardEvent_metaKey_Getter(mthis) native "KeyboardEvent_metaKey_Getter";

Native_KeyboardEvent_repeat_Getter(mthis) native "KeyboardEvent_repeat_Getter";

Native_KeyboardEvent_shiftKey_Getter(mthis) native "KeyboardEvent_shiftKey_Getter";

Native_KeyboardEvent_getModifierState_Callback(mthis, keyArgument) native "KeyboardEvent_getModifierState_Callback_RESOLVER_STRING_1_DOMString";

Native_KeyboardEvent_initKeyboardEvent_Callback(mthis, type, canBubble, cancelable, view, keyIdentifier, location, ctrlKey, altKey, shiftKey, metaKey, altGraphKey) native "KeyboardEvent_initKeyboardEvent_Callback_RESOLVER_STRING_11_DOMString_boolean_boolean_Window_DOMString_unsigned long_boolean_boolean_boolean_boolean_boolean";

Native_Location_ancestorOrigins_Getter(mthis) native "Location_ancestorOrigins_Getter";

Native_Location_hash_Getter(mthis) native "Location_hash_Getter";

Native_Location_hash_Setter(mthis, value) native "Location_hash_Setter";

Native_Location_host_Getter(mthis) native "Location_host_Getter";

Native_Location_host_Setter(mthis, value) native "Location_host_Setter";

Native_Location_hostname_Getter(mthis) native "Location_hostname_Getter";

Native_Location_hostname_Setter(mthis, value) native "Location_hostname_Setter";

Native_Location_href_Getter(mthis) native "Location_href_Getter";

Native_Location_href_Setter(mthis, value) native "Location_href_Setter";

Native_Location_origin_Getter(mthis) native "Location_origin_Getter";

Native_Location_pathname_Getter(mthis) native "Location_pathname_Getter";

Native_Location_pathname_Setter(mthis, value) native "Location_pathname_Setter";

Native_Location_port_Getter(mthis) native "Location_port_Getter";

Native_Location_port_Setter(mthis, value) native "Location_port_Setter";

Native_Location_protocol_Getter(mthis) native "Location_protocol_Getter";

Native_Location_protocol_Setter(mthis, value) native "Location_protocol_Setter";

Native_Location_search_Getter(mthis) native "Location_search_Getter";

Native_Location_search_Setter(mthis, value) native "Location_search_Setter";

Native_Location_assign_Callback(mthis, url) native "Location_assign_Callback";

Native_Location_reload_Callback(mthis) native "Location_reload_Callback";

Native_Location_replace_Callback(mthis, url) native "Location_replace_Callback";

Native_Location_toString_Callback(mthis) native "Location_toString_Callback_RESOLVER_STRING_0_";

Native_MIDIAccess_inputs_Callback(mthis) native "MIDIAccess_inputs_Callback_RESOLVER_STRING_0_";

Native_MIDIAccess_outputs_Callback(mthis) native "MIDIAccess_outputs_Callback_RESOLVER_STRING_0_";

Native_MIDIAccessPromise_then_Callback(mthis, successCallback, errorCallback) native "MIDIAccessPromise_then_Callback_RESOLVER_STRING_2_MIDISuccessCallback_MIDIErrorCallback";

Native_MIDIConnectionEvent_port_Getter(mthis) native "MIDIConnectionEvent_port_Getter";

Native_MIDIPort_id_Getter(mthis) native "MIDIPort_id_Getter";

Native_MIDIPort_manufacturer_Getter(mthis) native "MIDIPort_manufacturer_Getter";

Native_MIDIPort_name_Getter(mthis) native "MIDIPort_name_Getter";

Native_MIDIPort_type_Getter(mthis) native "MIDIPort_type_Getter";

Native_MIDIPort_version_Getter(mthis) native "MIDIPort_version_Getter";

Native_MIDIMessageEvent_data_Getter(mthis) native "MIDIMessageEvent_data_Getter";

Native_MIDIMessageEvent_receivedTime_Getter(mthis) native "MIDIMessageEvent_receivedTime_Getter";

  // Generated overload resolver
Native_MIDIOutput_send(mthis, data, timestamp) {
    if (timestamp != null) {
      Native_MIDIOutput__send_1_Callback(mthis, data, timestamp);
      return;
    }
    Native_MIDIOutput__send_2_Callback(mthis, data);
    return;
  }

Native_MIDIOutput__send_1_Callback(mthis, data, timestamp) native "MIDIOutput_send_Callback_RESOLVER_STRING_2_Uint8Array_double";

Native_MIDIOutput__send_2_Callback(mthis, data) native "MIDIOutput_send_Callback_RESOLVER_STRING_1_Uint8Array";

  // Generated overload resolver
Native_MediaController_MediaController() {
    return Native_MediaController__create_1constructorCallback();
  }

Native_MediaController__create_1constructorCallback() native "MediaController_constructorCallback_RESOLVER_STRING_0_";

Native_MediaController_buffered_Getter(mthis) native "MediaController_buffered_Getter";

Native_MediaController_currentTime_Getter(mthis) native "MediaController_currentTime_Getter";

Native_MediaController_currentTime_Setter(mthis, value) native "MediaController_currentTime_Setter";

Native_MediaController_defaultPlaybackRate_Getter(mthis) native "MediaController_defaultPlaybackRate_Getter";

Native_MediaController_defaultPlaybackRate_Setter(mthis, value) native "MediaController_defaultPlaybackRate_Setter";

Native_MediaController_duration_Getter(mthis) native "MediaController_duration_Getter";

Native_MediaController_muted_Getter(mthis) native "MediaController_muted_Getter";

Native_MediaController_muted_Setter(mthis, value) native "MediaController_muted_Setter";

Native_MediaController_paused_Getter(mthis) native "MediaController_paused_Getter";

Native_MediaController_playbackRate_Getter(mthis) native "MediaController_playbackRate_Getter";

Native_MediaController_playbackRate_Setter(mthis, value) native "MediaController_playbackRate_Setter";

Native_MediaController_playbackState_Getter(mthis) native "MediaController_playbackState_Getter";

Native_MediaController_played_Getter(mthis) native "MediaController_played_Getter";

Native_MediaController_seekable_Getter(mthis) native "MediaController_seekable_Getter";

Native_MediaController_volume_Getter(mthis) native "MediaController_volume_Getter";

Native_MediaController_volume_Setter(mthis, value) native "MediaController_volume_Setter";

Native_MediaController_pause_Callback(mthis) native "MediaController_pause_Callback_RESOLVER_STRING_0_";

Native_MediaController_play_Callback(mthis) native "MediaController_play_Callback_RESOLVER_STRING_0_";

Native_MediaController_unpause_Callback(mthis) native "MediaController_unpause_Callback_RESOLVER_STRING_0_";

Native_MediaElementAudioSourceNode_mediaElement_Getter(mthis) native "MediaElementAudioSourceNode_mediaElement_Getter";

Native_MediaError_code_Getter(mthis) native "MediaError_code_Getter";

Native_MediaKeyError_code_Getter(mthis) native "MediaKeyError_code_Getter";

Native_MediaKeyError_systemCode_Getter(mthis) native "MediaKeyError_systemCode_Getter";

Native_MediaKeyEvent_defaultURL_Getter(mthis) native "MediaKeyEvent_defaultURL_Getter";

Native_MediaKeyEvent_errorCode_Getter(mthis) native "MediaKeyEvent_errorCode_Getter";

Native_MediaKeyEvent_initData_Getter(mthis) native "MediaKeyEvent_initData_Getter";

Native_MediaKeyEvent_keySystem_Getter(mthis) native "MediaKeyEvent_keySystem_Getter";

Native_MediaKeyEvent_message_Getter(mthis) native "MediaKeyEvent_message_Getter";

Native_MediaKeyEvent_sessionId_Getter(mthis) native "MediaKeyEvent_sessionId_Getter";

Native_MediaKeyEvent_systemCode_Getter(mthis) native "MediaKeyEvent_systemCode_Getter";

Native_MediaKeyMessageEvent_destinationURL_Getter(mthis) native "MediaKeyMessageEvent_destinationURL_Getter";

Native_MediaKeyMessageEvent_message_Getter(mthis) native "MediaKeyMessageEvent_message_Getter";

Native_MediaKeyNeededEvent_contentType_Getter(mthis) native "MediaKeyNeededEvent_contentType_Getter";

Native_MediaKeyNeededEvent_initData_Getter(mthis) native "MediaKeyNeededEvent_initData_Getter";

Native_MediaKeySession_error_Getter(mthis) native "MediaKeySession_error_Getter";

Native_MediaKeySession_keySystem_Getter(mthis) native "MediaKeySession_keySystem_Getter";

Native_MediaKeySession_sessionId_Getter(mthis) native "MediaKeySession_sessionId_Getter";

Native_MediaKeySession_release_Callback(mthis) native "MediaKeySession_release_Callback_RESOLVER_STRING_0_";

Native_MediaKeySession_update_Callback(mthis, response) native "MediaKeySession_update_Callback_RESOLVER_STRING_1_Uint8Array";

  // Generated overload resolver
Native_MediaKeys_MediaKeys(keySystem) {
    return Native_MediaKeys__create_1constructorCallback(keySystem);
  }

Native_MediaKeys__create_1constructorCallback(keySystem) native "MediaKeys_constructorCallback_RESOLVER_STRING_1_DOMString";

Native_MediaKeys_keySystem_Getter(mthis) native "MediaKeys_keySystem_Getter";

Native_MediaKeys_createSession_Callback(mthis, type, initData) native "MediaKeys_createSession_Callback_RESOLVER_STRING_2_DOMString_Uint8Array";

Native_MediaList_length_Getter(mthis) native "MediaList_length_Getter";

Native_MediaList_mediaText_Getter(mthis) native "MediaList_mediaText_Getter";

Native_MediaList_mediaText_Setter(mthis, value) native "MediaList_mediaText_Setter";

Native_MediaList_appendMedium_Callback(mthis, newMedium) native "MediaList_appendMedium_Callback_RESOLVER_STRING_1_DOMString";

Native_MediaList_deleteMedium_Callback(mthis, oldMedium) native "MediaList_deleteMedium_Callback_RESOLVER_STRING_1_DOMString";

Native_MediaList_item_Callback(mthis, index) native "MediaList_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_MediaQueryList_matches_Getter(mthis) native "MediaQueryList_matches_Getter";

Native_MediaQueryList_media_Getter(mthis) native "MediaQueryList_media_Getter";

  // Generated overload resolver
Native_MediaSource_MediaSource() {
    return Native_MediaSource__create_1constructorCallback();
  }

Native_MediaSource__create_1constructorCallback() native "MediaSource_constructorCallback_RESOLVER_STRING_0_";

Native_MediaSource_activeSourceBuffers_Getter(mthis) native "MediaSource_activeSourceBuffers_Getter";

Native_MediaSource_duration_Getter(mthis) native "MediaSource_duration_Getter";

Native_MediaSource_duration_Setter(mthis, value) native "MediaSource_duration_Setter";

Native_MediaSource_readyState_Getter(mthis) native "MediaSource_readyState_Getter";

Native_MediaSource_sourceBuffers_Getter(mthis) native "MediaSource_sourceBuffers_Getter";

Native_MediaSource_addSourceBuffer_Callback(mthis, type) native "MediaSource_addSourceBuffer_Callback_RESOLVER_STRING_1_DOMString";

  // Generated overload resolver
Native_MediaSource_endOfStream(mthis, error) {
    if (error != null) {
      Native_MediaSource__endOfStream_1_Callback(mthis, error);
      return;
    }
    Native_MediaSource__endOfStream_2_Callback(mthis);
    return;
  }

Native_MediaSource__endOfStream_1_Callback(mthis, error) native "MediaSource_endOfStream_Callback_RESOLVER_STRING_1_DOMString";

Native_MediaSource__endOfStream_2_Callback(mthis) native "MediaSource_endOfStream_Callback_RESOLVER_STRING_0_";

Native_MediaSource_isTypeSupported_Callback(type) native "MediaSource_isTypeSupported_Callback_RESOLVER_STRING_1_DOMString";

Native_MediaSource_removeSourceBuffer_Callback(mthis, buffer) native "MediaSource_removeSourceBuffer_Callback_RESOLVER_STRING_1_SourceBuffer";

  // Generated overload resolver
Native_MediaStream_MediaStream(stream_OR_tracks) {
    if (stream_OR_tracks == null) {
      return Native_MediaStream__create_1constructorCallback();
    }
    if ((stream_OR_tracks is MediaStream || stream_OR_tracks == null)) {
      return Native_MediaStream__create_2constructorCallback(stream_OR_tracks);
    }
    if ((stream_OR_tracks is List<MediaStreamTrack> || stream_OR_tracks == null)) {
      return Native_MediaStream__create_3constructorCallback(stream_OR_tracks);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

Native_MediaStream__create_1constructorCallback() native "MediaStream_constructorCallback_RESOLVER_STRING_0_";

Native_MediaStream__create_2constructorCallback(stream_OR_tracks) native "MediaStream_constructorCallback_RESOLVER_STRING_1_MediaStream";

Native_MediaStream__create_3constructorCallback(stream_OR_tracks) native "MediaStream_constructorCallback_RESOLVER_STRING_1_MediaStreamTrack[]";

Native_MediaStream_ended_Getter(mthis) native "MediaStream_ended_Getter";

Native_MediaStream_id_Getter(mthis) native "MediaStream_id_Getter";

Native_MediaStream_label_Getter(mthis) native "MediaStream_label_Getter";

Native_MediaStream_addTrack_Callback(mthis, track) native "MediaStream_addTrack_Callback_RESOLVER_STRING_1_MediaStreamTrack";

Native_MediaStream_getAudioTracks_Callback(mthis) native "MediaStream_getAudioTracks_Callback_RESOLVER_STRING_0_";

Native_MediaStream_getTrackById_Callback(mthis, trackId) native "MediaStream_getTrackById_Callback_RESOLVER_STRING_1_DOMString";

Native_MediaStream_getVideoTracks_Callback(mthis) native "MediaStream_getVideoTracks_Callback_RESOLVER_STRING_0_";

Native_MediaStream_removeTrack_Callback(mthis, track) native "MediaStream_removeTrack_Callback_RESOLVER_STRING_1_MediaStreamTrack";

Native_MediaStream_stop_Callback(mthis) native "MediaStream_stop_Callback_RESOLVER_STRING_0_";

Native_MediaStreamAudioDestinationNode_stream_Getter(mthis) native "MediaStreamAudioDestinationNode_stream_Getter";

Native_MediaStreamAudioSourceNode_mediaStream_Getter(mthis) native "MediaStreamAudioSourceNode_mediaStream_Getter";

Native_MediaStreamEvent_stream_Getter(mthis) native "MediaStreamEvent_stream_Getter";

Native_MediaStreamTrack_enabled_Getter(mthis) native "MediaStreamTrack_enabled_Getter";

Native_MediaStreamTrack_enabled_Setter(mthis, value) native "MediaStreamTrack_enabled_Setter";

Native_MediaStreamTrack_id_Getter(mthis) native "MediaStreamTrack_id_Getter";

Native_MediaStreamTrack_kind_Getter(mthis) native "MediaStreamTrack_kind_Getter";

Native_MediaStreamTrack_label_Getter(mthis) native "MediaStreamTrack_label_Getter";

Native_MediaStreamTrack_readyState_Getter(mthis) native "MediaStreamTrack_readyState_Getter";

Native_MediaStreamTrack_getSources_Callback(callback) native "MediaStreamTrack_getSources_Callback_RESOLVER_STRING_1_MediaStreamTrackSourcesCallback";

Native_MediaStreamTrack_stop_Callback(mthis) native "MediaStreamTrack_stop_Callback_RESOLVER_STRING_0_";

Native_MediaStreamTrackEvent_track_Getter(mthis) native "MediaStreamTrackEvent_track_Getter";

Native_MemoryInfo_jsHeapSizeLimit_Getter(mthis) native "MemoryInfo_jsHeapSizeLimit_Getter";

Native_MemoryInfo_totalJSHeapSize_Getter(mthis) native "MemoryInfo_totalJSHeapSize_Getter";

Native_MemoryInfo_usedJSHeapSize_Getter(mthis) native "MemoryInfo_usedJSHeapSize_Getter";

Native_MessageChannel_port1_Getter(mthis) native "MessageChannel_port1_Getter";

Native_MessageChannel_port2_Getter(mthis) native "MessageChannel_port2_Getter";

Native_MessageEvent_data_Getter(mthis) native "MessageEvent_data_Getter";

Native_MessageEvent_lastEventId_Getter(mthis) native "MessageEvent_lastEventId_Getter";

Native_MessageEvent_origin_Getter(mthis) native "MessageEvent_origin_Getter";

Native_MessageEvent_source_Getter(mthis) native "MessageEvent_source_Getter";

Native_MessageEvent_initMessageEvent_Callback(mthis, typeArg, canBubbleArg, cancelableArg, dataArg, originArg, lastEventIdArg, sourceArg, messagePorts) native "MessageEvent_initMessageEvent_Callback";

Native_MessagePort_close_Callback(mthis) native "MessagePort_close_Callback_RESOLVER_STRING_0_";

Native_MessagePort_postMessage_Callback(mthis, message, messagePorts) native "MessagePort_postMessage_Callback";

Native_MessagePort_start_Callback(mthis) native "MessagePort_start_Callback_RESOLVER_STRING_0_";

Native_Metadata_modificationTime_Getter(mthis) native "Metadata_modificationTime_Getter";

Native_Metadata_size_Getter(mthis) native "Metadata_size_Getter";

Native_MimeType_description_Getter(mthis) native "MimeType_description_Getter";

Native_MimeType_enabledPlugin_Getter(mthis) native "MimeType_enabledPlugin_Getter";

Native_MimeType_suffixes_Getter(mthis) native "MimeType_suffixes_Getter";

Native_MimeType_type_Getter(mthis) native "MimeType_type_Getter";

Native_MimeTypeArray_length_Getter(mthis) native "MimeTypeArray_length_Getter";

Native_MimeTypeArray_NativeIndexed_Getter(mthis, index) native "MimeTypeArray_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_MimeTypeArray___getter___Callback(mthis, name) native "MimeTypeArray___getter___Callback_RESOLVER_STRING_1_DOMString";

Native_MimeTypeArray_item_Callback(mthis, index) native "MimeTypeArray_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_MimeTypeArray_namedItem_Callback(mthis, name) native "MimeTypeArray_namedItem_Callback_RESOLVER_STRING_1_DOMString";

Native_MouseEvent_altKey_Getter(mthis) native "MouseEvent_altKey_Getter";

Native_MouseEvent_button_Getter(mthis) native "MouseEvent_button_Getter";

Native_MouseEvent_clientX_Getter(mthis) native "MouseEvent_clientX_Getter";

Native_MouseEvent_clientY_Getter(mthis) native "MouseEvent_clientY_Getter";

Native_MouseEvent_ctrlKey_Getter(mthis) native "MouseEvent_ctrlKey_Getter";

Native_MouseEvent_dataTransfer_Getter(mthis) native "MouseEvent_dataTransfer_Getter";

Native_MouseEvent_fromElement_Getter(mthis) native "MouseEvent_fromElement_Getter";

Native_MouseEvent_metaKey_Getter(mthis) native "MouseEvent_metaKey_Getter";

Native_MouseEvent_offsetX_Getter(mthis) native "MouseEvent_offsetX_Getter";

Native_MouseEvent_offsetY_Getter(mthis) native "MouseEvent_offsetY_Getter";

Native_MouseEvent_relatedTarget_Getter(mthis) native "MouseEvent_relatedTarget_Getter";

Native_MouseEvent_screenX_Getter(mthis) native "MouseEvent_screenX_Getter";

Native_MouseEvent_screenY_Getter(mthis) native "MouseEvent_screenY_Getter";

Native_MouseEvent_shiftKey_Getter(mthis) native "MouseEvent_shiftKey_Getter";

Native_MouseEvent_toElement_Getter(mthis) native "MouseEvent_toElement_Getter";

Native_MouseEvent_webkitMovementX_Getter(mthis) native "MouseEvent_webkitMovementX_Getter";

Native_MouseEvent_webkitMovementY_Getter(mthis) native "MouseEvent_webkitMovementY_Getter";

Native_MouseEvent_initMouseEvent_Callback(mthis, type, canBubble, cancelable, view, detail, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey, button, relatedTarget) native "MouseEvent_initMouseEvent_Callback_RESOLVER_STRING_15_DOMString_boolean_boolean_Window_long_long_long_long_long_boolean_boolean_boolean_boolean_unsigned short_EventTarget";

Native_MutationObserver_constructorCallback(callback) native "MutationObserver_constructorCallback";

Native_MutationObserver_disconnect_Callback(mthis) native "MutationObserver_disconnect_Callback_RESOLVER_STRING_0_";

Native_MutationObserver_observe_Callback(mthis, target, options) native "MutationObserver_observe_Callback_RESOLVER_STRING_2_Node_Dictionary";

Native_MutationObserver_takeRecords_Callback(mthis) native "MutationObserver_takeRecords_Callback_RESOLVER_STRING_0_";

Native_MutationRecord_addedNodes_Getter(mthis) native "MutationRecord_addedNodes_Getter";

Native_MutationRecord_attributeName_Getter(mthis) native "MutationRecord_attributeName_Getter";

Native_MutationRecord_attributeNamespace_Getter(mthis) native "MutationRecord_attributeNamespace_Getter";

Native_MutationRecord_nextSibling_Getter(mthis) native "MutationRecord_nextSibling_Getter";

Native_MutationRecord_oldValue_Getter(mthis) native "MutationRecord_oldValue_Getter";

Native_MutationRecord_previousSibling_Getter(mthis) native "MutationRecord_previousSibling_Getter";

Native_MutationRecord_removedNodes_Getter(mthis) native "MutationRecord_removedNodes_Getter";

Native_MutationRecord_target_Getter(mthis) native "MutationRecord_target_Getter";

Native_MutationRecord_type_Getter(mthis) native "MutationRecord_type_Getter";

Native_NamedNodeMap_length_Getter(mthis) native "NamedNodeMap_length_Getter";

Native_NamedNodeMap_NativeIndexed_Getter(mthis, index) native "NamedNodeMap_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_NamedNodeMap___getter___Callback(mthis, name) native "NamedNodeMap___getter___Callback_RESOLVER_STRING_1_DOMString";

Native_NamedNodeMap_getNamedItem_Callback(mthis, name) native "NamedNodeMap_getNamedItem_Callback_RESOLVER_STRING_1_DOMString";

Native_NamedNodeMap_getNamedItemNS_Callback(mthis, namespaceURI, localName) native "NamedNodeMap_getNamedItemNS_Callback_RESOLVER_STRING_2_DOMString_DOMString";

Native_NamedNodeMap_item_Callback(mthis, index) native "NamedNodeMap_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_NamedNodeMap_removeNamedItem_Callback(mthis, name) native "NamedNodeMap_removeNamedItem_Callback_RESOLVER_STRING_1_DOMString";

Native_NamedNodeMap_removeNamedItemNS_Callback(mthis, namespaceURI, localName) native "NamedNodeMap_removeNamedItemNS_Callback_RESOLVER_STRING_2_DOMString_DOMString";

Native_NamedNodeMap_setNamedItem_Callback(mthis, node) native "NamedNodeMap_setNamedItem_Callback_RESOLVER_STRING_1_Node";

Native_NamedNodeMap_setNamedItemNS_Callback(mthis, node) native "NamedNodeMap_setNamedItemNS_Callback_RESOLVER_STRING_1_Node";

Native_NavigatorID_appCodeName_Getter(mthis) native "Navigator_appCodeName_Getter";

Native_NavigatorID_appName_Getter(mthis) native "Navigator_appName_Getter";

Native_NavigatorID_appVersion_Getter(mthis) native "Navigator_appVersion_Getter";

Native_NavigatorID_platform_Getter(mthis) native "Navigator_platform_Getter";

Native_NavigatorID_product_Getter(mthis) native "Navigator_product_Getter";

Native_NavigatorID_userAgent_Getter(mthis) native "Navigator_userAgent_Getter";

Native_NavigatorOnLine_onLine_Getter(mthis) native "NavigatorOnLine_onLine_Getter";

Native_Navigator_cookieEnabled_Getter(mthis) native "Navigator_cookieEnabled_Getter";

Native_Navigator_doNotTrack_Getter(mthis) native "Navigator_doNotTrack_Getter";

Native_Navigator_geolocation_Getter(mthis) native "Navigator_geolocation_Getter";

Native_Navigator_language_Getter(mthis) native "Navigator_language_Getter";

Native_Navigator_maxTouchPoints_Getter(mthis) native "Navigator_maxTouchPoints_Getter";

Native_Navigator_mimeTypes_Getter(mthis) native "Navigator_mimeTypes_Getter";

Native_Navigator_productSub_Getter(mthis) native "Navigator_productSub_Getter";

Native_Navigator_serviceWorker_Getter(mthis) native "Navigator_serviceWorker_Getter";

Native_Navigator_storageQuota_Getter(mthis) native "Navigator_storageQuota_Getter";

Native_Navigator_vendor_Getter(mthis) native "Navigator_vendor_Getter";

Native_Navigator_vendorSub_Getter(mthis) native "Navigator_vendorSub_Getter";

Native_Navigator_webkitPersistentStorage_Getter(mthis) native "Navigator_webkitPersistentStorage_Getter";

Native_Navigator_webkitTemporaryStorage_Getter(mthis) native "Navigator_webkitTemporaryStorage_Getter";

Native_Navigator_getStorageUpdates_Callback(mthis) native "Navigator_getStorageUpdates_Callback_RESOLVER_STRING_0_";

Native_Navigator_isProtocolHandlerRegistered_Callback(mthis, scheme, url) native "Navigator_isProtocolHandlerRegistered_Callback_RESOLVER_STRING_2_DOMString_DOMString";

Native_Navigator_registerProtocolHandler_Callback(mthis, scheme, url, title) native "Navigator_registerProtocolHandler_Callback_RESOLVER_STRING_3_DOMString_DOMString_DOMString";

Native_Navigator_requestMIDIAccess_Callback(mthis, options) native "Navigator_requestMIDIAccess_Callback_RESOLVER_STRING_1_Dictionary";

Native_Navigator_unregisterProtocolHandler_Callback(mthis, scheme, url) native "Navigator_unregisterProtocolHandler_Callback_RESOLVER_STRING_2_DOMString_DOMString";

Native_Navigator_webkitGetGamepads_Callback(mthis) native "Navigator_webkitGetGamepads_Callback_RESOLVER_STRING_0_";

Native_Navigator_webkitGetUserMedia_Callback(mthis, options, successCallback, errorCallback) native "Navigator_webkitGetUserMedia_Callback_RESOLVER_STRING_3_Dictionary_NavigatorUserMediaSuccessCallback_NavigatorUserMediaErrorCallback";

Native_Navigator_appCodeName_Getter(mthis) native "Navigator_appCodeName_Getter";

Native_Navigator_appName_Getter(mthis) native "Navigator_appName_Getter";

Native_Navigator_appVersion_Getter(mthis) native "Navigator_appVersion_Getter";

Native_Navigator_platform_Getter(mthis) native "Navigator_platform_Getter";

Native_Navigator_product_Getter(mthis) native "Navigator_product_Getter";

Native_Navigator_userAgent_Getter(mthis) native "Navigator_userAgent_Getter";

Native_Navigator_onLine_Getter(mthis) native "Navigator_onLine_Getter";

Native_NavigatorUserMediaError_constraintName_Getter(mthis) native "NavigatorUserMediaError_constraintName_Getter";

Native_NavigatorUserMediaError_message_Getter(mthis) native "NavigatorUserMediaError_message_Getter";

Native_NavigatorUserMediaError_name_Getter(mthis) native "NavigatorUserMediaError_name_Getter";

Native_NodeIterator_pointerBeforeReferenceNode_Getter(mthis) native "NodeIterator_pointerBeforeReferenceNode_Getter";

Native_NodeIterator_referenceNode_Getter(mthis) native "NodeIterator_referenceNode_Getter";

Native_NodeIterator_root_Getter(mthis) native "NodeIterator_root_Getter";

Native_NodeIterator_whatToShow_Getter(mthis) native "NodeIterator_whatToShow_Getter";

Native_NodeIterator_detach_Callback(mthis) native "NodeIterator_detach_Callback_RESOLVER_STRING_0_";

Native_NodeIterator_nextNode_Callback(mthis) native "NodeIterator_nextNode_Callback_RESOLVER_STRING_0_";

Native_NodeIterator_previousNode_Callback(mthis) native "NodeIterator_previousNode_Callback_RESOLVER_STRING_0_";

Native_NodeList_length_Getter(mthis) native "NodeList_length_Getter";

Native_NodeList_NativeIndexed_Getter(mthis, index) native "NodeList_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_NodeList_item_Callback(mthis, index) native "NodeList_item_Callback_RESOLVER_STRING_1_unsigned long";

  // Generated overload resolver
Native_Notification_Notification(title, options) {
    return Native_Notification__create_1constructorCallback(title, options);
  }

Native_Notification__create_1constructorCallback(title, options) native "Notification_constructorCallback_RESOLVER_STRING_2_DOMString_Dictionary";

Native_Notification_body_Getter(mthis) native "Notification_body_Getter";

Native_Notification_dir_Getter(mthis) native "Notification_dir_Getter";

Native_Notification_icon_Getter(mthis) native "Notification_icon_Getter";

Native_Notification_lang_Getter(mthis) native "Notification_lang_Getter";

Native_Notification_permission_Getter(mthis) native "Notification_permission_Getter";

Native_Notification_tag_Getter(mthis) native "Notification_tag_Getter";

Native_Notification_title_Getter(mthis) native "Notification_title_Getter";

Native_Notification_close_Callback(mthis) native "Notification_close_Callback_RESOLVER_STRING_0_";

Native_Notification_requestPermission_Callback(callback) native "Notification_requestPermission_Callback_RESOLVER_STRING_1_NotificationPermissionCallback";

Native_OESVertexArrayObject_bindVertexArrayOES_Callback(mthis, arrayObject) native "OESVertexArrayObject_bindVertexArrayOES_Callback_RESOLVER_STRING_1_WebGLVertexArrayObjectOES";

Native_OESVertexArrayObject_createVertexArrayOES_Callback(mthis) native "OESVertexArrayObject_createVertexArrayOES_Callback_RESOLVER_STRING_0_";

Native_OESVertexArrayObject_deleteVertexArrayOES_Callback(mthis, arrayObject) native "OESVertexArrayObject_deleteVertexArrayOES_Callback_RESOLVER_STRING_1_WebGLVertexArrayObjectOES";

Native_OESVertexArrayObject_isVertexArrayOES_Callback(mthis, arrayObject) native "OESVertexArrayObject_isVertexArrayOES_Callback_RESOLVER_STRING_1_WebGLVertexArrayObjectOES";

Native_OfflineAudioCompletionEvent_renderedBuffer_Getter(mthis) native "OfflineAudioCompletionEvent_renderedBuffer_Getter";

  // Generated overload resolver
Native_OfflineAudioContext_OfflineAudioContext(numberOfChannels, numberOfFrames, sampleRate) {
    return Native_OfflineAudioContext__create_1constructorCallback(numberOfChannels, numberOfFrames, sampleRate);
  }

Native_OfflineAudioContext__create_1constructorCallback(numberOfChannels, numberOfFrames, sampleRate) native "OfflineAudioContext_constructorCallback_RESOLVER_STRING_3_unsigned long_unsigned long_float";

Native_OscillatorNode_detune_Getter(mthis) native "OscillatorNode_detune_Getter";

Native_OscillatorNode_frequency_Getter(mthis) native "OscillatorNode_frequency_Getter";

Native_OscillatorNode_playbackState_Getter(mthis) native "OscillatorNode_playbackState_Getter";

Native_OscillatorNode_type_Getter(mthis) native "OscillatorNode_type_Getter";

Native_OscillatorNode_type_Setter(mthis, value) native "OscillatorNode_type_Setter";

Native_OscillatorNode_noteOff_Callback(mthis, when) native "OscillatorNode_noteOff_Callback_RESOLVER_STRING_1_double";

Native_OscillatorNode_noteOn_Callback(mthis, when) native "OscillatorNode_noteOn_Callback_RESOLVER_STRING_1_double";

Native_OscillatorNode_setPeriodicWave_Callback(mthis, periodicWave) native "OscillatorNode_setPeriodicWave_Callback_RESOLVER_STRING_1_PeriodicWave";

  // Generated overload resolver
Native_OscillatorNode_start(mthis, when) {
    if (when != null) {
      Native_OscillatorNode__start_1_Callback(mthis, when);
      return;
    }
    Native_OscillatorNode__start_2_Callback(mthis);
    return;
  }

Native_OscillatorNode__start_1_Callback(mthis, when) native "OscillatorNode_start_Callback_RESOLVER_STRING_1_double";

Native_OscillatorNode__start_2_Callback(mthis) native "OscillatorNode_start_Callback_RESOLVER_STRING_0_";

  // Generated overload resolver
Native_OscillatorNode_stop(mthis, when) {
    if (when != null) {
      Native_OscillatorNode__stop_1_Callback(mthis, when);
      return;
    }
    Native_OscillatorNode__stop_2_Callback(mthis);
    return;
  }

Native_OscillatorNode__stop_1_Callback(mthis, when) native "OscillatorNode_stop_Callback_RESOLVER_STRING_1_double";

Native_OscillatorNode__stop_2_Callback(mthis) native "OscillatorNode_stop_Callback_RESOLVER_STRING_0_";

Native_OverflowEvent_horizontalOverflow_Getter(mthis) native "OverflowEvent_horizontalOverflow_Getter";

Native_OverflowEvent_orient_Getter(mthis) native "OverflowEvent_orient_Getter";

Native_OverflowEvent_verticalOverflow_Getter(mthis) native "OverflowEvent_verticalOverflow_Getter";

Native_PageTransitionEvent_persisted_Getter(mthis) native "PageTransitionEvent_persisted_Getter";

Native_PannerNode_coneInnerAngle_Getter(mthis) native "PannerNode_coneInnerAngle_Getter";

Native_PannerNode_coneInnerAngle_Setter(mthis, value) native "PannerNode_coneInnerAngle_Setter";

Native_PannerNode_coneOuterAngle_Getter(mthis) native "PannerNode_coneOuterAngle_Getter";

Native_PannerNode_coneOuterAngle_Setter(mthis, value) native "PannerNode_coneOuterAngle_Setter";

Native_PannerNode_coneOuterGain_Getter(mthis) native "PannerNode_coneOuterGain_Getter";

Native_PannerNode_coneOuterGain_Setter(mthis, value) native "PannerNode_coneOuterGain_Setter";

Native_PannerNode_distanceModel_Getter(mthis) native "PannerNode_distanceModel_Getter";

Native_PannerNode_distanceModel_Setter(mthis, value) native "PannerNode_distanceModel_Setter";

Native_PannerNode_maxDistance_Getter(mthis) native "PannerNode_maxDistance_Getter";

Native_PannerNode_maxDistance_Setter(mthis, value) native "PannerNode_maxDistance_Setter";

Native_PannerNode_panningModel_Getter(mthis) native "PannerNode_panningModel_Getter";

Native_PannerNode_panningModel_Setter(mthis, value) native "PannerNode_panningModel_Setter";

Native_PannerNode_refDistance_Getter(mthis) native "PannerNode_refDistance_Getter";

Native_PannerNode_refDistance_Setter(mthis, value) native "PannerNode_refDistance_Setter";

Native_PannerNode_rolloffFactor_Getter(mthis) native "PannerNode_rolloffFactor_Getter";

Native_PannerNode_rolloffFactor_Setter(mthis, value) native "PannerNode_rolloffFactor_Setter";

Native_PannerNode_setOrientation_Callback(mthis, x, y, z) native "PannerNode_setOrientation_Callback_RESOLVER_STRING_3_float_float_float";

Native_PannerNode_setPosition_Callback(mthis, x, y, z) native "PannerNode_setPosition_Callback_RESOLVER_STRING_3_float_float_float";

Native_PannerNode_setVelocity_Callback(mthis, x, y, z) native "PannerNode_setVelocity_Callback_RESOLVER_STRING_3_float_float_float";

  // Generated overload resolver
Native_Path_Path(path_OR_text) {
    if (path_OR_text == null) {
      return Native_Path__create_1constructorCallback();
    }
    if ((path_OR_text is Path || path_OR_text == null)) {
      return Native_Path__create_2constructorCallback(path_OR_text);
    }
    if ((path_OR_text is String || path_OR_text == null)) {
      return Native_Path__create_3constructorCallback(path_OR_text);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

Native_Path__create_1constructorCallback() native "Path2D_constructorCallback_RESOLVER_STRING_0_";

Native_Path__create_2constructorCallback(path_OR_text) native "Path2D_constructorCallback_RESOLVER_STRING_1_Path2D";

Native_Path__create_3constructorCallback(path_OR_text) native "Path2D_constructorCallback_RESOLVER_STRING_1_DOMString";

Native_Path_arc_Callback(mthis, x, y, radius, startAngle, endAngle, anticlockwise) native "Path2D_arc_Callback_RESOLVER_STRING_6_float_float_float_float_float_boolean";

Native_Path_arcTo_Callback(mthis, x1, y1, x2, y2, radius) native "Path2D_arcTo_Callback_RESOLVER_STRING_5_float_float_float_float_float";

Native_Path_bezierCurveTo_Callback(mthis, cp1x, cp1y, cp2x, cp2y, x, y) native "Path2D_bezierCurveTo_Callback_RESOLVER_STRING_6_float_float_float_float_float_float";

Native_Path_closePath_Callback(mthis) native "Path2D_closePath_Callback_RESOLVER_STRING_0_";

Native_Path_lineTo_Callback(mthis, x, y) native "Path2D_lineTo_Callback_RESOLVER_STRING_2_float_float";

Native_Path_moveTo_Callback(mthis, x, y) native "Path2D_moveTo_Callback_RESOLVER_STRING_2_float_float";

Native_Path_quadraticCurveTo_Callback(mthis, cpx, cpy, x, y) native "Path2D_quadraticCurveTo_Callback_RESOLVER_STRING_4_float_float_float_float";

Native_Path_rect_Callback(mthis, x, y, width, height) native "Path2D_rect_Callback_RESOLVER_STRING_4_float_float_float_float";

Native_Performance_memory_Getter(mthis) native "Performance_memory_Getter";

Native_Performance_navigation_Getter(mthis) native "Performance_navigation_Getter";

Native_Performance_timing_Getter(mthis) native "Performance_timing_Getter";

Native_Performance_clearMarks_Callback(mthis, markName) native "Performance_clearMarks_Callback_RESOLVER_STRING_1_DOMString";

Native_Performance_clearMeasures_Callback(mthis, measureName) native "Performance_clearMeasures_Callback_RESOLVER_STRING_1_DOMString";

Native_Performance_getEntries_Callback(mthis) native "Performance_getEntries_Callback_RESOLVER_STRING_0_";

Native_Performance_getEntriesByName_Callback(mthis, name, entryType) native "Performance_getEntriesByName_Callback_RESOLVER_STRING_2_DOMString_DOMString";

Native_Performance_getEntriesByType_Callback(mthis, entryType) native "Performance_getEntriesByType_Callback_RESOLVER_STRING_1_DOMString";

Native_Performance_mark_Callback(mthis, markName) native "Performance_mark_Callback_RESOLVER_STRING_1_DOMString";

Native_Performance_measure_Callback(mthis, measureName, startMark, endMark) native "Performance_measure_Callback_RESOLVER_STRING_3_DOMString_DOMString_DOMString";

Native_Performance_now_Callback(mthis) native "Performance_now_Callback_RESOLVER_STRING_0_";

Native_Performance_webkitClearResourceTimings_Callback(mthis) native "Performance_webkitClearResourceTimings_Callback_RESOLVER_STRING_0_";

Native_Performance_webkitSetResourceTimingBufferSize_Callback(mthis, maxSize) native "Performance_webkitSetResourceTimingBufferSize_Callback_RESOLVER_STRING_1_unsigned long";

Native_PerformanceEntry_duration_Getter(mthis) native "PerformanceEntry_duration_Getter";

Native_PerformanceEntry_entryType_Getter(mthis) native "PerformanceEntry_entryType_Getter";

Native_PerformanceEntry_name_Getter(mthis) native "PerformanceEntry_name_Getter";

Native_PerformanceEntry_startTime_Getter(mthis) native "PerformanceEntry_startTime_Getter";

Native_PerformanceNavigation_redirectCount_Getter(mthis) native "PerformanceNavigation_redirectCount_Getter";

Native_PerformanceNavigation_type_Getter(mthis) native "PerformanceNavigation_type_Getter";

Native_PerformanceResourceTiming_connectEnd_Getter(mthis) native "PerformanceResourceTiming_connectEnd_Getter";

Native_PerformanceResourceTiming_connectStart_Getter(mthis) native "PerformanceResourceTiming_connectStart_Getter";

Native_PerformanceResourceTiming_domainLookupEnd_Getter(mthis) native "PerformanceResourceTiming_domainLookupEnd_Getter";

Native_PerformanceResourceTiming_domainLookupStart_Getter(mthis) native "PerformanceResourceTiming_domainLookupStart_Getter";

Native_PerformanceResourceTiming_fetchStart_Getter(mthis) native "PerformanceResourceTiming_fetchStart_Getter";

Native_PerformanceResourceTiming_initiatorType_Getter(mthis) native "PerformanceResourceTiming_initiatorType_Getter";

Native_PerformanceResourceTiming_redirectEnd_Getter(mthis) native "PerformanceResourceTiming_redirectEnd_Getter";

Native_PerformanceResourceTiming_redirectStart_Getter(mthis) native "PerformanceResourceTiming_redirectStart_Getter";

Native_PerformanceResourceTiming_requestStart_Getter(mthis) native "PerformanceResourceTiming_requestStart_Getter";

Native_PerformanceResourceTiming_responseEnd_Getter(mthis) native "PerformanceResourceTiming_responseEnd_Getter";

Native_PerformanceResourceTiming_responseStart_Getter(mthis) native "PerformanceResourceTiming_responseStart_Getter";

Native_PerformanceResourceTiming_secureConnectionStart_Getter(mthis) native "PerformanceResourceTiming_secureConnectionStart_Getter";

Native_PerformanceTiming_connectEnd_Getter(mthis) native "PerformanceTiming_connectEnd_Getter";

Native_PerformanceTiming_connectStart_Getter(mthis) native "PerformanceTiming_connectStart_Getter";

Native_PerformanceTiming_domComplete_Getter(mthis) native "PerformanceTiming_domComplete_Getter";

Native_PerformanceTiming_domContentLoadedEventEnd_Getter(mthis) native "PerformanceTiming_domContentLoadedEventEnd_Getter";

Native_PerformanceTiming_domContentLoadedEventStart_Getter(mthis) native "PerformanceTiming_domContentLoadedEventStart_Getter";

Native_PerformanceTiming_domInteractive_Getter(mthis) native "PerformanceTiming_domInteractive_Getter";

Native_PerformanceTiming_domLoading_Getter(mthis) native "PerformanceTiming_domLoading_Getter";

Native_PerformanceTiming_domainLookupEnd_Getter(mthis) native "PerformanceTiming_domainLookupEnd_Getter";

Native_PerformanceTiming_domainLookupStart_Getter(mthis) native "PerformanceTiming_domainLookupStart_Getter";

Native_PerformanceTiming_fetchStart_Getter(mthis) native "PerformanceTiming_fetchStart_Getter";

Native_PerformanceTiming_loadEventEnd_Getter(mthis) native "PerformanceTiming_loadEventEnd_Getter";

Native_PerformanceTiming_loadEventStart_Getter(mthis) native "PerformanceTiming_loadEventStart_Getter";

Native_PerformanceTiming_navigationStart_Getter(mthis) native "PerformanceTiming_navigationStart_Getter";

Native_PerformanceTiming_redirectEnd_Getter(mthis) native "PerformanceTiming_redirectEnd_Getter";

Native_PerformanceTiming_redirectStart_Getter(mthis) native "PerformanceTiming_redirectStart_Getter";

Native_PerformanceTiming_requestStart_Getter(mthis) native "PerformanceTiming_requestStart_Getter";

Native_PerformanceTiming_responseEnd_Getter(mthis) native "PerformanceTiming_responseEnd_Getter";

Native_PerformanceTiming_responseStart_Getter(mthis) native "PerformanceTiming_responseStart_Getter";

Native_PerformanceTiming_secureConnectionStart_Getter(mthis) native "PerformanceTiming_secureConnectionStart_Getter";

Native_PerformanceTiming_unloadEventEnd_Getter(mthis) native "PerformanceTiming_unloadEventEnd_Getter";

Native_PerformanceTiming_unloadEventStart_Getter(mthis) native "PerformanceTiming_unloadEventStart_Getter";

Native_Player_currentTime_Getter(mthis) native "AnimationPlayer_currentTime_Getter";

Native_Player_currentTime_Setter(mthis, value) native "AnimationPlayer_currentTime_Setter";

Native_Player_finished_Getter(mthis) native "AnimationPlayer_finished_Getter";

Native_Player_paused_Getter(mthis) native "AnimationPlayer_paused_Getter";

Native_Player_playbackRate_Getter(mthis) native "AnimationPlayer_playbackRate_Getter";

Native_Player_playbackRate_Setter(mthis, value) native "AnimationPlayer_playbackRate_Setter";

Native_Player_source_Getter(mthis) native "AnimationPlayer_source_Getter";

Native_Player_source_Setter(mthis, value) native "AnimationPlayer_source_Setter";

Native_Player_startTime_Getter(mthis) native "AnimationPlayer_startTime_Getter";

Native_Player_startTime_Setter(mthis, value) native "AnimationPlayer_startTime_Setter";

Native_Player_timeLag_Getter(mthis) native "AnimationPlayer_timeLag_Getter";

Native_Player_cancel_Callback(mthis) native "AnimationPlayer_cancel_Callback_RESOLVER_STRING_0_";

Native_Player_finish_Callback(mthis) native "AnimationPlayer_finish_Callback_RESOLVER_STRING_0_";

Native_Player_pause_Callback(mthis) native "AnimationPlayer_pause_Callback_RESOLVER_STRING_0_";

Native_Player_play_Callback(mthis) native "AnimationPlayer_play_Callback_RESOLVER_STRING_0_";

Native_Player_reverse_Callback(mthis) native "AnimationPlayer_reverse_Callback_RESOLVER_STRING_0_";

Native_Plugin_description_Getter(mthis) native "Plugin_description_Getter";

Native_Plugin_filename_Getter(mthis) native "Plugin_filename_Getter";

Native_Plugin_length_Getter(mthis) native "Plugin_length_Getter";

Native_Plugin_name_Getter(mthis) native "Plugin_name_Getter";

Native_Plugin___getter___Callback(mthis, name) native "Plugin___getter___Callback_RESOLVER_STRING_1_DOMString";

Native_Plugin_item_Callback(mthis, index) native "Plugin_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_Plugin_namedItem_Callback(mthis, name) native "Plugin_namedItem_Callback_RESOLVER_STRING_1_DOMString";

Native_PluginArray_length_Getter(mthis) native "PluginArray_length_Getter";

Native_PluginArray_NativeIndexed_Getter(mthis, index) native "PluginArray_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_PluginArray___getter___Callback(mthis, name) native "PluginArray___getter___Callback_RESOLVER_STRING_1_DOMString";

Native_PluginArray_item_Callback(mthis, index) native "PluginArray_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_PluginArray_namedItem_Callback(mthis, name) native "PluginArray_namedItem_Callback_RESOLVER_STRING_1_DOMString";

Native_PluginArray_refresh_Callback(mthis, reload) native "PluginArray_refresh_Callback_RESOLVER_STRING_1_boolean";

Native_PopStateEvent_state_Getter(mthis) native "PopStateEvent_state_Getter";

Native_PositionError_code_Getter(mthis) native "PositionError_code_Getter";

Native_PositionError_message_Getter(mthis) native "PositionError_message_Getter";

Native_ProcessingInstruction_sheet_Getter(mthis) native "ProcessingInstruction_sheet_Getter";

Native_ProcessingInstruction_target_Getter(mthis) native "ProcessingInstruction_target_Getter";

Native_ProgressEvent_lengthComputable_Getter(mthis) native "ProgressEvent_lengthComputable_Getter";

Native_ProgressEvent_loaded_Getter(mthis) native "ProgressEvent_loaded_Getter";

Native_ProgressEvent_total_Getter(mthis) native "ProgressEvent_total_Getter";

Native_RTCDTMFSender_canInsertDTMF_Getter(mthis) native "RTCDTMFSender_canInsertDTMF_Getter";

Native_RTCDTMFSender_duration_Getter(mthis) native "RTCDTMFSender_duration_Getter";

Native_RTCDTMFSender_interToneGap_Getter(mthis) native "RTCDTMFSender_interToneGap_Getter";

Native_RTCDTMFSender_toneBuffer_Getter(mthis) native "RTCDTMFSender_toneBuffer_Getter";

Native_RTCDTMFSender_track_Getter(mthis) native "RTCDTMFSender_track_Getter";

  // Generated overload resolver
Native_RTCDTMFSender_insertDtmf(mthis, tones, duration, interToneGap) {
    if (interToneGap != null) {
      Native_RTCDTMFSender__insertDTMF_1_Callback(mthis, tones, duration, interToneGap);
      return;
    }
    if (duration != null) {
      Native_RTCDTMFSender__insertDTMF_2_Callback(mthis, tones, duration);
      return;
    }
    Native_RTCDTMFSender__insertDTMF_3_Callback(mthis, tones);
    return;
  }

Native_RTCDTMFSender__insertDTMF_1_Callback(mthis, tones, duration, interToneGap) native "RTCDTMFSender_insertDTMF_Callback_RESOLVER_STRING_3_DOMString_long_long";

Native_RTCDTMFSender__insertDTMF_2_Callback(mthis, tones, duration) native "RTCDTMFSender_insertDTMF_Callback_RESOLVER_STRING_2_DOMString_long";

Native_RTCDTMFSender__insertDTMF_3_Callback(mthis, tones) native "RTCDTMFSender_insertDTMF_Callback_RESOLVER_STRING_1_DOMString";

Native_RTCDTMFToneChangeEvent_tone_Getter(mthis) native "RTCDTMFToneChangeEvent_tone_Getter";

Native_RTCDataChannel_binaryType_Getter(mthis) native "RTCDataChannel_binaryType_Getter";

Native_RTCDataChannel_binaryType_Setter(mthis, value) native "RTCDataChannel_binaryType_Setter";

Native_RTCDataChannel_bufferedAmount_Getter(mthis) native "RTCDataChannel_bufferedAmount_Getter";

Native_RTCDataChannel_id_Getter(mthis) native "RTCDataChannel_id_Getter";

Native_RTCDataChannel_label_Getter(mthis) native "RTCDataChannel_label_Getter";

Native_RTCDataChannel_maxRetransmitTime_Getter(mthis) native "RTCDataChannel_maxRetransmitTime_Getter";

Native_RTCDataChannel_maxRetransmits_Getter(mthis) native "RTCDataChannel_maxRetransmits_Getter";

Native_RTCDataChannel_negotiated_Getter(mthis) native "RTCDataChannel_negotiated_Getter";

Native_RTCDataChannel_ordered_Getter(mthis) native "RTCDataChannel_ordered_Getter";

Native_RTCDataChannel_protocol_Getter(mthis) native "RTCDataChannel_protocol_Getter";

Native_RTCDataChannel_readyState_Getter(mthis) native "RTCDataChannel_readyState_Getter";

Native_RTCDataChannel_reliable_Getter(mthis) native "RTCDataChannel_reliable_Getter";

Native_RTCDataChannel_close_Callback(mthis) native "RTCDataChannel_close_Callback_RESOLVER_STRING_0_";

  // Generated overload resolver
Native_RTCDataChannel_send(mthis, data) {
    if ((data is TypedData || data == null)) {
      Native_RTCDataChannel__send_1_Callback(mthis, data);
      return;
    }
    if ((data is ByteBuffer || data == null)) {
      Native_RTCDataChannel__send_2_Callback(mthis, data);
      return;
    }
    if ((data is Blob || data == null)) {
      Native_RTCDataChannel__send_3_Callback(mthis, data);
      return;
    }
    if ((data is String || data == null)) {
      Native_RTCDataChannel__send_4_Callback(mthis, data);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

Native_RTCDataChannel__send_1_Callback(mthis, data) native "RTCDataChannel_send_Callback_RESOLVER_STRING_1_ArrayBufferView";

Native_RTCDataChannel__send_2_Callback(mthis, data) native "RTCDataChannel_send_Callback_RESOLVER_STRING_1_ArrayBuffer";

Native_RTCDataChannel__send_3_Callback(mthis, data) native "RTCDataChannel_send_Callback_RESOLVER_STRING_1_Blob";

Native_RTCDataChannel__send_4_Callback(mthis, data) native "RTCDataChannel_send_Callback_RESOLVER_STRING_1_DOMString";

Native_RTCDataChannel_sendBlob_Callback(mthis, data) native "RTCDataChannel_send_Callback_RESOLVER_STRING_1_Blob";

Native_RTCDataChannel_sendByteBuffer_Callback(mthis, data) native "RTCDataChannel_send_Callback_RESOLVER_STRING_1_ArrayBuffer";

Native_RTCDataChannel_sendString_Callback(mthis, data) native "RTCDataChannel_send_Callback_RESOLVER_STRING_1_DOMString";

Native_RTCDataChannel_sendTypedData_Callback(mthis, data) native "RTCDataChannel_send_Callback_RESOLVER_STRING_1_ArrayBufferView";

Native_RTCDataChannelEvent_channel_Getter(mthis) native "RTCDataChannelEvent_channel_Getter";

  // Generated overload resolver
Native_RTCIceCandidate_RtcIceCandidate(dictionary) {
    return Native_RTCIceCandidate__create_1constructorCallback(dictionary);
  }

Native_RTCIceCandidate__create_1constructorCallback(dictionary) native "RTCIceCandidate_constructorCallback_RESOLVER_STRING_1_Dictionary";

Native_RTCIceCandidate_candidate_Getter(mthis) native "RTCIceCandidate_candidate_Getter";

Native_RTCIceCandidate_sdpMLineIndex_Getter(mthis) native "RTCIceCandidate_sdpMLineIndex_Getter";

Native_RTCIceCandidate_sdpMid_Getter(mthis) native "RTCIceCandidate_sdpMid_Getter";

Native_RTCIceCandidateEvent_candidate_Getter(mthis) native "RTCIceCandidateEvent_candidate_Getter";

  // Generated overload resolver
Native_RTCPeerConnection_RtcPeerConnection(rtcIceServers, mediaConstraints) {
    return Native_RTCPeerConnection__create_1constructorCallback(rtcIceServers, mediaConstraints);
  }

Native_RTCPeerConnection__create_1constructorCallback(rtcIceServers, mediaConstraints) native "RTCPeerConnection_constructorCallback_RESOLVER_STRING_2_Dictionary_Dictionary";

Native_RTCPeerConnection_iceConnectionState_Getter(mthis) native "RTCPeerConnection_iceConnectionState_Getter";

Native_RTCPeerConnection_iceGatheringState_Getter(mthis) native "RTCPeerConnection_iceGatheringState_Getter";

Native_RTCPeerConnection_localDescription_Getter(mthis) native "RTCPeerConnection_localDescription_Getter";

Native_RTCPeerConnection_remoteDescription_Getter(mthis) native "RTCPeerConnection_remoteDescription_Getter";

Native_RTCPeerConnection_signalingState_Getter(mthis) native "RTCPeerConnection_signalingState_Getter";

Native_RTCPeerConnection_addIceCandidate_Callback(mthis, candidate, successCallback, failureCallback) native "RTCPeerConnection_addIceCandidate_Callback_RESOLVER_STRING_3_RTCIceCandidate_VoidCallback_RTCErrorCallback";

Native_RTCPeerConnection_addStream_Callback(mthis, stream, mediaConstraints) native "RTCPeerConnection_addStream_Callback_RESOLVER_STRING_2_MediaStream_Dictionary";

Native_RTCPeerConnection_close_Callback(mthis) native "RTCPeerConnection_close_Callback_RESOLVER_STRING_0_";

Native_RTCPeerConnection_createAnswer_Callback(mthis, successCallback, failureCallback, mediaConstraints) native "RTCPeerConnection_createAnswer_Callback_RESOLVER_STRING_3_RTCSessionDescriptionCallback_RTCErrorCallback_Dictionary";

Native_RTCPeerConnection_createDTMFSender_Callback(mthis, track) native "RTCPeerConnection_createDTMFSender_Callback_RESOLVER_STRING_1_MediaStreamTrack";

Native_RTCPeerConnection_createDataChannel_Callback(mthis, label, options) native "RTCPeerConnection_createDataChannel_Callback_RESOLVER_STRING_2_DOMString_Dictionary";

Native_RTCPeerConnection_createOffer_Callback(mthis, successCallback, failureCallback, mediaConstraints) native "RTCPeerConnection_createOffer_Callback_RESOLVER_STRING_3_RTCSessionDescriptionCallback_RTCErrorCallback_Dictionary";

Native_RTCPeerConnection_getLocalStreams_Callback(mthis) native "RTCPeerConnection_getLocalStreams_Callback_RESOLVER_STRING_0_";

Native_RTCPeerConnection_getRemoteStreams_Callback(mthis) native "RTCPeerConnection_getRemoteStreams_Callback_RESOLVER_STRING_0_";

Native_RTCPeerConnection_getStats_Callback(mthis, successCallback, selector) native "RTCPeerConnection_getStats_Callback_RESOLVER_STRING_2_RTCStatsCallback_MediaStreamTrack";

Native_RTCPeerConnection_getStreamById_Callback(mthis, streamId) native "RTCPeerConnection_getStreamById_Callback_RESOLVER_STRING_1_DOMString";

Native_RTCPeerConnection_removeStream_Callback(mthis, stream) native "RTCPeerConnection_removeStream_Callback_RESOLVER_STRING_1_MediaStream";

Native_RTCPeerConnection_setLocalDescription_Callback(mthis, description, successCallback, failureCallback) native "RTCPeerConnection_setLocalDescription_Callback_RESOLVER_STRING_3_RTCSessionDescription_VoidCallback_RTCErrorCallback";

Native_RTCPeerConnection_setRemoteDescription_Callback(mthis, description, successCallback, failureCallback) native "RTCPeerConnection_setRemoteDescription_Callback_RESOLVER_STRING_3_RTCSessionDescription_VoidCallback_RTCErrorCallback";

Native_RTCPeerConnection_updateIce_Callback(mthis, configuration, mediaConstraints) native "RTCPeerConnection_updateIce_Callback_RESOLVER_STRING_2_Dictionary_Dictionary";

  // Generated overload resolver
Native_RTCSessionDescription_RtcSessionDescription(descriptionInitDict) {
    return Native_RTCSessionDescription__create_1constructorCallback(descriptionInitDict);
  }

Native_RTCSessionDescription__create_1constructorCallback(descriptionInitDict) native "RTCSessionDescription_constructorCallback_RESOLVER_STRING_1_Dictionary";

Native_RTCSessionDescription_sdp_Getter(mthis) native "RTCSessionDescription_sdp_Getter";

Native_RTCSessionDescription_sdp_Setter(mthis, value) native "RTCSessionDescription_sdp_Setter";

Native_RTCSessionDescription_type_Getter(mthis) native "RTCSessionDescription_type_Getter";

Native_RTCSessionDescription_type_Setter(mthis, value) native "RTCSessionDescription_type_Setter";

Native_RTCStatsReport_id_Getter(mthis) native "RTCStatsReport_id_Getter";

Native_RTCStatsReport_local_Getter(mthis) native "RTCStatsReport_local_Getter";

Native_RTCStatsReport_remote_Getter(mthis) native "RTCStatsReport_remote_Getter";

Native_RTCStatsReport_timestamp_Getter(mthis) native "RTCStatsReport_timestamp_Getter";

Native_RTCStatsReport_type_Getter(mthis) native "RTCStatsReport_type_Getter";

Native_RTCStatsReport_names_Callback(mthis) native "RTCStatsReport_names_Callback_RESOLVER_STRING_0_";

Native_RTCStatsReport_stat_Callback(mthis, name) native "RTCStatsReport_stat_Callback_RESOLVER_STRING_1_DOMString";

Native_RTCStatsResponse___getter___Callback(mthis, name) native "RTCStatsResponse___getter___Callback_RESOLVER_STRING_1_DOMString";

Native_RTCStatsResponse_namedItem_Callback(mthis, name) native "RTCStatsResponse_namedItem_Callback_RESOLVER_STRING_1_DOMString";

Native_RTCStatsResponse_result_Callback(mthis) native "RTCStatsResponse_result_Callback_RESOLVER_STRING_0_";

Native_Range_collapsed_Getter(mthis) native "Range_collapsed_Getter";

Native_Range_commonAncestorContainer_Getter(mthis) native "Range_commonAncestorContainer_Getter";

Native_Range_endContainer_Getter(mthis) native "Range_endContainer_Getter";

Native_Range_endOffset_Getter(mthis) native "Range_endOffset_Getter";

Native_Range_startContainer_Getter(mthis) native "Range_startContainer_Getter";

Native_Range_startOffset_Getter(mthis) native "Range_startOffset_Getter";

Native_Range_cloneContents_Callback(mthis) native "Range_cloneContents_Callback_RESOLVER_STRING_0_";

Native_Range_cloneRange_Callback(mthis) native "Range_cloneRange_Callback_RESOLVER_STRING_0_";

Native_Range_collapse_Callback(mthis, toStart) native "Range_collapse_Callback_RESOLVER_STRING_1_boolean";

Native_Range_comparePoint_Callback(mthis, refNode, offset) native "Range_comparePoint_Callback_RESOLVER_STRING_2_Node_long";

Native_Range_createContextualFragment_Callback(mthis, html) native "Range_createContextualFragment_Callback_RESOLVER_STRING_1_DOMString";

Native_Range_deleteContents_Callback(mthis) native "Range_deleteContents_Callback_RESOLVER_STRING_0_";

Native_Range_detach_Callback(mthis) native "Range_detach_Callback_RESOLVER_STRING_0_";

Native_Range_expand_Callback(mthis, unit) native "Range_expand_Callback_RESOLVER_STRING_1_DOMString";

Native_Range_extractContents_Callback(mthis) native "Range_extractContents_Callback_RESOLVER_STRING_0_";

Native_Range_getBoundingClientRect_Callback(mthis) native "Range_getBoundingClientRect_Callback_RESOLVER_STRING_0_";

Native_Range_getClientRects_Callback(mthis) native "Range_getClientRects_Callback_RESOLVER_STRING_0_";

Native_Range_insertNode_Callback(mthis, newNode) native "Range_insertNode_Callback_RESOLVER_STRING_1_Node";

Native_Range_isPointInRange_Callback(mthis, refNode, offset) native "Range_isPointInRange_Callback_RESOLVER_STRING_2_Node_long";

Native_Range_selectNode_Callback(mthis, refNode) native "Range_selectNode_Callback_RESOLVER_STRING_1_Node";

Native_Range_selectNodeContents_Callback(mthis, refNode) native "Range_selectNodeContents_Callback_RESOLVER_STRING_1_Node";

Native_Range_setEnd_Callback(mthis, refNode, offset) native "Range_setEnd_Callback_RESOLVER_STRING_2_Node_long";

Native_Range_setEndAfter_Callback(mthis, refNode) native "Range_setEndAfter_Callback_RESOLVER_STRING_1_Node";

Native_Range_setEndBefore_Callback(mthis, refNode) native "Range_setEndBefore_Callback_RESOLVER_STRING_1_Node";

Native_Range_setStart_Callback(mthis, refNode, offset) native "Range_setStart_Callback_RESOLVER_STRING_2_Node_long";

Native_Range_setStartAfter_Callback(mthis, refNode) native "Range_setStartAfter_Callback_RESOLVER_STRING_1_Node";

Native_Range_setStartBefore_Callback(mthis, refNode) native "Range_setStartBefore_Callback_RESOLVER_STRING_1_Node";

Native_Range_surroundContents_Callback(mthis, newParent) native "Range_surroundContents_Callback_RESOLVER_STRING_1_Node";

Native_Range_toString_Callback(mthis) native "Range_toString_Callback_RESOLVER_STRING_0_";

Native_ResourceProgressEvent_url_Getter(mthis) native "ResourceProgressEvent_url_Getter";

Native_SQLError_code_Getter(mthis) native "SQLError_code_Getter";

Native_SQLError_message_Getter(mthis) native "SQLError_message_Getter";

Native_SQLResultSet_insertId_Getter(mthis) native "SQLResultSet_insertId_Getter";

Native_SQLResultSet_rows_Getter(mthis) native "SQLResultSet_rows_Getter";

Native_SQLResultSet_rowsAffected_Getter(mthis) native "SQLResultSet_rowsAffected_Getter";

Native_SQLResultSetRowList_length_Getter(mthis) native "SQLResultSetRowList_length_Getter";

Native_SQLResultSetRowList_NativeIndexed_Getter(mthis, index) native "SQLResultSetRowList_item_Callback";

Native_SQLResultSetRowList_item_Callback(mthis, index) native "SQLResultSetRowList_item_Callback";

Native_SQLTransaction_executeSql_Callback(mthis, sqlStatement, arguments, callback, errorCallback) native "SQLTransaction_executeSql_Callback";

Native_SVGElement_className_Getter(mthis) native "SVGElement_className_Getter";

Native_SVGElement_ownerSVGElement_Getter(mthis) native "SVGElement_ownerSVGElement_Getter";

Native_SVGElement_style_Getter(mthis) native "SVGElement_style_Getter";

Native_SVGElement_viewportElement_Getter(mthis) native "SVGElement_viewportElement_Getter";

Native_SVGElement_xmlbase_Getter(mthis) native "SVGElement_xmlbase_Getter";

Native_SVGElement_xmlbase_Setter(mthis, value) native "SVGElement_xmlbase_Setter";

Native_SVGElement_xmllang_Getter(mthis) native "SVGElement_xmllang_Getter";

Native_SVGElement_xmllang_Setter(mthis, value) native "SVGElement_xmllang_Setter";

Native_SVGElement_xmlspace_Getter(mthis) native "SVGElement_xmlspace_Getter";

Native_SVGElement_xmlspace_Setter(mthis, value) native "SVGElement_xmlspace_Setter";

Native_SVGTests_requiredExtensions_Getter(mthis) native "SVGTests_requiredExtensions_Getter";

Native_SVGTests_requiredFeatures_Getter(mthis) native "SVGTests_requiredFeatures_Getter";

Native_SVGTests_systemLanguage_Getter(mthis) native "SVGTests_systemLanguage_Getter";

Native_SVGTests_hasExtension_Callback(mthis, extension) native "SVGTests_hasExtension_Callback_RESOLVER_STRING_1_DOMString";

Native_SVGGraphicsElement_farthestViewportElement_Getter(mthis) native "SVGGraphicsElement_farthestViewportElement_Getter";

Native_SVGGraphicsElement_nearestViewportElement_Getter(mthis) native "SVGGraphicsElement_nearestViewportElement_Getter";

Native_SVGGraphicsElement_transform_Getter(mthis) native "SVGGraphicsElement_transform_Getter";

Native_SVGGraphicsElement_getBBox_Callback(mthis) native "SVGGraphicsElement_getBBox_Callback_RESOLVER_STRING_0_";

Native_SVGGraphicsElement_getCTM_Callback(mthis) native "SVGGraphicsElement_getCTM_Callback_RESOLVER_STRING_0_";

Native_SVGGraphicsElement_getScreenCTM_Callback(mthis) native "SVGGraphicsElement_getScreenCTM_Callback_RESOLVER_STRING_0_";

Native_SVGGraphicsElement_getTransformToElement_Callback(mthis, element) native "SVGGraphicsElement_getTransformToElement_Callback_RESOLVER_STRING_1_SVGElement";

Native_SVGGraphicsElement_requiredExtensions_Getter(mthis) native "SVGGraphicsElement_requiredExtensions_Getter";

Native_SVGGraphicsElement_requiredFeatures_Getter(mthis) native "SVGGraphicsElement_requiredFeatures_Getter";

Native_SVGGraphicsElement_systemLanguage_Getter(mthis) native "SVGGraphicsElement_systemLanguage_Getter";

Native_SVGGraphicsElement_hasExtension_Callback(mthis, extension) native "SVGGraphicsElement_hasExtension_Callback_RESOLVER_STRING_1_DOMString";

Native_SVGURIReference_href_Getter(mthis) native "SVGURIReference_href_Getter";

Native_SVGAElement_target_Getter(mthis) native "SVGAElement_target_Getter";

Native_SVGAElement_href_Getter(mthis) native "SVGAElement_href_Getter";

Native_SVGTextContentElement_lengthAdjust_Getter(mthis) native "SVGTextContentElement_lengthAdjust_Getter";

Native_SVGTextContentElement_textLength_Getter(mthis) native "SVGTextContentElement_textLength_Getter";

Native_SVGTextContentElement_getCharNumAtPosition_Callback(mthis, point) native "SVGTextContentElement_getCharNumAtPosition_Callback_RESOLVER_STRING_1_SVGPoint";

Native_SVGTextContentElement_getComputedTextLength_Callback(mthis) native "SVGTextContentElement_getComputedTextLength_Callback_RESOLVER_STRING_0_";

Native_SVGTextContentElement_getEndPositionOfChar_Callback(mthis, offset) native "SVGTextContentElement_getEndPositionOfChar_Callback_RESOLVER_STRING_1_unsigned long";

Native_SVGTextContentElement_getExtentOfChar_Callback(mthis, offset) native "SVGTextContentElement_getExtentOfChar_Callback_RESOLVER_STRING_1_unsigned long";

Native_SVGTextContentElement_getNumberOfChars_Callback(mthis) native "SVGTextContentElement_getNumberOfChars_Callback_RESOLVER_STRING_0_";

Native_SVGTextContentElement_getRotationOfChar_Callback(mthis, offset) native "SVGTextContentElement_getRotationOfChar_Callback_RESOLVER_STRING_1_unsigned long";

Native_SVGTextContentElement_getStartPositionOfChar_Callback(mthis, offset) native "SVGTextContentElement_getStartPositionOfChar_Callback_RESOLVER_STRING_1_unsigned long";

Native_SVGTextContentElement_getSubStringLength_Callback(mthis, offset, length) native "SVGTextContentElement_getSubStringLength_Callback_RESOLVER_STRING_2_unsigned long_unsigned long";

Native_SVGTextContentElement_selectSubString_Callback(mthis, offset, length) native "SVGTextContentElement_selectSubString_Callback_RESOLVER_STRING_2_unsigned long_unsigned long";

Native_SVGTextPositioningElement_dx_Getter(mthis) native "SVGTextPositioningElement_dx_Getter";

Native_SVGTextPositioningElement_dy_Getter(mthis) native "SVGTextPositioningElement_dy_Getter";

Native_SVGTextPositioningElement_rotate_Getter(mthis) native "SVGTextPositioningElement_rotate_Getter";

Native_SVGTextPositioningElement_x_Getter(mthis) native "SVGTextPositioningElement_x_Getter";

Native_SVGTextPositioningElement_y_Getter(mthis) native "SVGTextPositioningElement_y_Getter";

Native_SVGAltGlyphElement_format_Getter(mthis) native "SVGAltGlyphElement_format_Getter";

Native_SVGAltGlyphElement_format_Setter(mthis, value) native "SVGAltGlyphElement_format_Setter";

Native_SVGAltGlyphElement_glyphRef_Getter(mthis) native "SVGAltGlyphElement_glyphRef_Getter";

Native_SVGAltGlyphElement_glyphRef_Setter(mthis, value) native "SVGAltGlyphElement_glyphRef_Setter";

Native_SVGAltGlyphElement_href_Getter(mthis) native "SVGAltGlyphElement_href_Getter";

Native_SVGAngle_unitType_Getter(mthis) native "SVGAngle_unitType_Getter";

Native_SVGAngle_value_Getter(mthis) native "SVGAngle_value_Getter";

Native_SVGAngle_value_Setter(mthis, value) native "SVGAngle_value_Setter";

Native_SVGAngle_valueAsString_Getter(mthis) native "SVGAngle_valueAsString_Getter";

Native_SVGAngle_valueAsString_Setter(mthis, value) native "SVGAngle_valueAsString_Setter";

Native_SVGAngle_valueInSpecifiedUnits_Getter(mthis) native "SVGAngle_valueInSpecifiedUnits_Getter";

Native_SVGAngle_valueInSpecifiedUnits_Setter(mthis, value) native "SVGAngle_valueInSpecifiedUnits_Setter";

Native_SVGAngle_convertToSpecifiedUnits_Callback(mthis, unitType) native "SVGAngle_convertToSpecifiedUnits_Callback_RESOLVER_STRING_1_unsigned short";

Native_SVGAngle_newValueSpecifiedUnits_Callback(mthis, unitType, valueInSpecifiedUnits) native "SVGAngle_newValueSpecifiedUnits_Callback_RESOLVER_STRING_2_unsigned short_float";

Native_SVGAnimationElement_targetElement_Getter(mthis) native "SVGAnimationElement_targetElement_Getter";

Native_SVGAnimationElement_beginElement_Callback(mthis) native "SVGAnimationElement_beginElement_Callback_RESOLVER_STRING_0_";

Native_SVGAnimationElement_beginElementAt_Callback(mthis, offset) native "SVGAnimationElement_beginElementAt_Callback_RESOLVER_STRING_1_float";

Native_SVGAnimationElement_endElement_Callback(mthis) native "SVGAnimationElement_endElement_Callback_RESOLVER_STRING_0_";

Native_SVGAnimationElement_endElementAt_Callback(mthis, offset) native "SVGAnimationElement_endElementAt_Callback_RESOLVER_STRING_1_float";

Native_SVGAnimationElement_getCurrentTime_Callback(mthis) native "SVGAnimationElement_getCurrentTime_Callback_RESOLVER_STRING_0_";

Native_SVGAnimationElement_getSimpleDuration_Callback(mthis) native "SVGAnimationElement_getSimpleDuration_Callback_RESOLVER_STRING_0_";

Native_SVGAnimationElement_getStartTime_Callback(mthis) native "SVGAnimationElement_getStartTime_Callback_RESOLVER_STRING_0_";

Native_SVGAnimationElement_requiredExtensions_Getter(mthis) native "SVGAnimationElement_requiredExtensions_Getter";

Native_SVGAnimationElement_requiredFeatures_Getter(mthis) native "SVGAnimationElement_requiredFeatures_Getter";

Native_SVGAnimationElement_systemLanguage_Getter(mthis) native "SVGAnimationElement_systemLanguage_Getter";

Native_SVGAnimationElement_hasExtension_Callback(mthis, extension) native "SVGAnimationElement_hasExtension_Callback_RESOLVER_STRING_1_DOMString";

Native_SVGAnimatedAngle_animVal_Getter(mthis) native "SVGAnimatedAngle_animVal_Getter";

Native_SVGAnimatedAngle_baseVal_Getter(mthis) native "SVGAnimatedAngle_baseVal_Getter";

Native_SVGAnimatedBoolean_animVal_Getter(mthis) native "SVGAnimatedBoolean_animVal_Getter";

Native_SVGAnimatedBoolean_baseVal_Getter(mthis) native "SVGAnimatedBoolean_baseVal_Getter";

Native_SVGAnimatedBoolean_baseVal_Setter(mthis, value) native "SVGAnimatedBoolean_baseVal_Setter";

Native_SVGAnimatedEnumeration_animVal_Getter(mthis) native "SVGAnimatedEnumeration_animVal_Getter";

Native_SVGAnimatedEnumeration_baseVal_Getter(mthis) native "SVGAnimatedEnumeration_baseVal_Getter";

Native_SVGAnimatedEnumeration_baseVal_Setter(mthis, value) native "SVGAnimatedEnumeration_baseVal_Setter";

Native_SVGAnimatedInteger_animVal_Getter(mthis) native "SVGAnimatedInteger_animVal_Getter";

Native_SVGAnimatedInteger_baseVal_Getter(mthis) native "SVGAnimatedInteger_baseVal_Getter";

Native_SVGAnimatedInteger_baseVal_Setter(mthis, value) native "SVGAnimatedInteger_baseVal_Setter";

Native_SVGAnimatedLength_animVal_Getter(mthis) native "SVGAnimatedLength_animVal_Getter";

Native_SVGAnimatedLength_baseVal_Getter(mthis) native "SVGAnimatedLength_baseVal_Getter";

Native_SVGAnimatedLengthList_animVal_Getter(mthis) native "SVGAnimatedLengthList_animVal_Getter";

Native_SVGAnimatedLengthList_baseVal_Getter(mthis) native "SVGAnimatedLengthList_baseVal_Getter";

Native_SVGAnimatedNumber_animVal_Getter(mthis) native "SVGAnimatedNumber_animVal_Getter";

Native_SVGAnimatedNumber_baseVal_Getter(mthis) native "SVGAnimatedNumber_baseVal_Getter";

Native_SVGAnimatedNumber_baseVal_Setter(mthis, value) native "SVGAnimatedNumber_baseVal_Setter";

Native_SVGAnimatedNumberList_animVal_Getter(mthis) native "SVGAnimatedNumberList_animVal_Getter";

Native_SVGAnimatedNumberList_baseVal_Getter(mthis) native "SVGAnimatedNumberList_baseVal_Getter";

Native_SVGAnimatedPreserveAspectRatio_animVal_Getter(mthis) native "SVGAnimatedPreserveAspectRatio_animVal_Getter";

Native_SVGAnimatedPreserveAspectRatio_baseVal_Getter(mthis) native "SVGAnimatedPreserveAspectRatio_baseVal_Getter";

Native_SVGAnimatedRect_animVal_Getter(mthis) native "SVGAnimatedRect_animVal_Getter";

Native_SVGAnimatedRect_baseVal_Getter(mthis) native "SVGAnimatedRect_baseVal_Getter";

Native_SVGAnimatedString_animVal_Getter(mthis) native "SVGAnimatedString_animVal_Getter";

Native_SVGAnimatedString_baseVal_Getter(mthis) native "SVGAnimatedString_baseVal_Getter";

Native_SVGAnimatedString_baseVal_Setter(mthis, value) native "SVGAnimatedString_baseVal_Setter";

Native_SVGAnimatedTransformList_animVal_Getter(mthis) native "SVGAnimatedTransformList_animVal_Getter";

Native_SVGAnimatedTransformList_baseVal_Getter(mthis) native "SVGAnimatedTransformList_baseVal_Getter";

Native_SVGGeometryElement_isPointInFill_Callback(mthis, point) native "SVGGeometryElement_isPointInFill_Callback_RESOLVER_STRING_1_SVGPoint";

Native_SVGGeometryElement_isPointInStroke_Callback(mthis, point) native "SVGGeometryElement_isPointInStroke_Callback_RESOLVER_STRING_1_SVGPoint";

Native_SVGCircleElement_cx_Getter(mthis) native "SVGCircleElement_cx_Getter";

Native_SVGCircleElement_cy_Getter(mthis) native "SVGCircleElement_cy_Getter";

Native_SVGCircleElement_r_Getter(mthis) native "SVGCircleElement_r_Getter";

Native_SVGClipPathElement_clipPathUnits_Getter(mthis) native "SVGClipPathElement_clipPathUnits_Getter";

Native_SVGElementInstance_childNodes_Getter(mthis) native "SVGElementInstance_childNodes_Getter";

Native_SVGElementInstance_correspondingElement_Getter(mthis) native "SVGElementInstance_correspondingElement_Getter";

Native_SVGElementInstance_correspondingUseElement_Getter(mthis) native "SVGElementInstance_correspondingUseElement_Getter";

Native_SVGElementInstance_firstChild_Getter(mthis) native "SVGElementInstance_firstChild_Getter";

Native_SVGElementInstance_lastChild_Getter(mthis) native "SVGElementInstance_lastChild_Getter";

Native_SVGElementInstance_nextSibling_Getter(mthis) native "SVGElementInstance_nextSibling_Getter";

Native_SVGElementInstance_parentNode_Getter(mthis) native "SVGElementInstance_parentNode_Getter";

Native_SVGElementInstance_previousSibling_Getter(mthis) native "SVGElementInstance_previousSibling_Getter";

Native_SVGElementInstanceList_length_Getter(mthis) native "SVGElementInstanceList_length_Getter";

Native_SVGElementInstanceList_NativeIndexed_Getter(mthis, index) native "SVGElementInstanceList_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_SVGElementInstanceList_item_Callback(mthis, index) native "SVGElementInstanceList_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_SVGEllipseElement_cx_Getter(mthis) native "SVGEllipseElement_cx_Getter";

Native_SVGEllipseElement_cy_Getter(mthis) native "SVGEllipseElement_cy_Getter";

Native_SVGEllipseElement_rx_Getter(mthis) native "SVGEllipseElement_rx_Getter";

Native_SVGEllipseElement_ry_Getter(mthis) native "SVGEllipseElement_ry_Getter";

Native_SVGFilterPrimitiveStandardAttributes_height_Getter(mthis) native "SVGFilterPrimitiveStandardAttributes_height_Getter";

Native_SVGFilterPrimitiveStandardAttributes_result_Getter(mthis) native "SVGFilterPrimitiveStandardAttributes_result_Getter";

Native_SVGFilterPrimitiveStandardAttributes_width_Getter(mthis) native "SVGFilterPrimitiveStandardAttributes_width_Getter";

Native_SVGFilterPrimitiveStandardAttributes_x_Getter(mthis) native "SVGFilterPrimitiveStandardAttributes_x_Getter";

Native_SVGFilterPrimitiveStandardAttributes_y_Getter(mthis) native "SVGFilterPrimitiveStandardAttributes_y_Getter";

Native_SVGFEBlendElement_in1_Getter(mthis) native "SVGFEBlendElement_in1_Getter";

Native_SVGFEBlendElement_in2_Getter(mthis) native "SVGFEBlendElement_in2_Getter";

Native_SVGFEBlendElement_mode_Getter(mthis) native "SVGFEBlendElement_mode_Getter";

Native_SVGFEBlendElement_height_Getter(mthis) native "SVGFEBlendElement_height_Getter";

Native_SVGFEBlendElement_result_Getter(mthis) native "SVGFEBlendElement_result_Getter";

Native_SVGFEBlendElement_width_Getter(mthis) native "SVGFEBlendElement_width_Getter";

Native_SVGFEBlendElement_x_Getter(mthis) native "SVGFEBlendElement_x_Getter";

Native_SVGFEBlendElement_y_Getter(mthis) native "SVGFEBlendElement_y_Getter";

Native_SVGFEColorMatrixElement_in1_Getter(mthis) native "SVGFEColorMatrixElement_in1_Getter";

Native_SVGFEColorMatrixElement_type_Getter(mthis) native "SVGFEColorMatrixElement_type_Getter";

Native_SVGFEColorMatrixElement_values_Getter(mthis) native "SVGFEColorMatrixElement_values_Getter";

Native_SVGFEColorMatrixElement_height_Getter(mthis) native "SVGFEColorMatrixElement_height_Getter";

Native_SVGFEColorMatrixElement_result_Getter(mthis) native "SVGFEColorMatrixElement_result_Getter";

Native_SVGFEColorMatrixElement_width_Getter(mthis) native "SVGFEColorMatrixElement_width_Getter";

Native_SVGFEColorMatrixElement_x_Getter(mthis) native "SVGFEColorMatrixElement_x_Getter";

Native_SVGFEColorMatrixElement_y_Getter(mthis) native "SVGFEColorMatrixElement_y_Getter";

Native_SVGFEComponentTransferElement_in1_Getter(mthis) native "SVGFEComponentTransferElement_in1_Getter";

Native_SVGFEComponentTransferElement_height_Getter(mthis) native "SVGFEComponentTransferElement_height_Getter";

Native_SVGFEComponentTransferElement_result_Getter(mthis) native "SVGFEComponentTransferElement_result_Getter";

Native_SVGFEComponentTransferElement_width_Getter(mthis) native "SVGFEComponentTransferElement_width_Getter";

Native_SVGFEComponentTransferElement_x_Getter(mthis) native "SVGFEComponentTransferElement_x_Getter";

Native_SVGFEComponentTransferElement_y_Getter(mthis) native "SVGFEComponentTransferElement_y_Getter";

Native_SVGFECompositeElement_in1_Getter(mthis) native "SVGFECompositeElement_in1_Getter";

Native_SVGFECompositeElement_in2_Getter(mthis) native "SVGFECompositeElement_in2_Getter";

Native_SVGFECompositeElement_k1_Getter(mthis) native "SVGFECompositeElement_k1_Getter";

Native_SVGFECompositeElement_k2_Getter(mthis) native "SVGFECompositeElement_k2_Getter";

Native_SVGFECompositeElement_k3_Getter(mthis) native "SVGFECompositeElement_k3_Getter";

Native_SVGFECompositeElement_k4_Getter(mthis) native "SVGFECompositeElement_k4_Getter";

Native_SVGFECompositeElement_operator_Getter(mthis) native "SVGFECompositeElement_operator_Getter";

Native_SVGFECompositeElement_height_Getter(mthis) native "SVGFECompositeElement_height_Getter";

Native_SVGFECompositeElement_result_Getter(mthis) native "SVGFECompositeElement_result_Getter";

Native_SVGFECompositeElement_width_Getter(mthis) native "SVGFECompositeElement_width_Getter";

Native_SVGFECompositeElement_x_Getter(mthis) native "SVGFECompositeElement_x_Getter";

Native_SVGFECompositeElement_y_Getter(mthis) native "SVGFECompositeElement_y_Getter";

Native_SVGFEConvolveMatrixElement_bias_Getter(mthis) native "SVGFEConvolveMatrixElement_bias_Getter";

Native_SVGFEConvolveMatrixElement_divisor_Getter(mthis) native "SVGFEConvolveMatrixElement_divisor_Getter";

Native_SVGFEConvolveMatrixElement_edgeMode_Getter(mthis) native "SVGFEConvolveMatrixElement_edgeMode_Getter";

Native_SVGFEConvolveMatrixElement_in1_Getter(mthis) native "SVGFEConvolveMatrixElement_in1_Getter";

Native_SVGFEConvolveMatrixElement_kernelMatrix_Getter(mthis) native "SVGFEConvolveMatrixElement_kernelMatrix_Getter";

Native_SVGFEConvolveMatrixElement_kernelUnitLengthX_Getter(mthis) native "SVGFEConvolveMatrixElement_kernelUnitLengthX_Getter";

Native_SVGFEConvolveMatrixElement_kernelUnitLengthY_Getter(mthis) native "SVGFEConvolveMatrixElement_kernelUnitLengthY_Getter";

Native_SVGFEConvolveMatrixElement_orderX_Getter(mthis) native "SVGFEConvolveMatrixElement_orderX_Getter";

Native_SVGFEConvolveMatrixElement_orderY_Getter(mthis) native "SVGFEConvolveMatrixElement_orderY_Getter";

Native_SVGFEConvolveMatrixElement_preserveAlpha_Getter(mthis) native "SVGFEConvolveMatrixElement_preserveAlpha_Getter";

Native_SVGFEConvolveMatrixElement_targetX_Getter(mthis) native "SVGFEConvolveMatrixElement_targetX_Getter";

Native_SVGFEConvolveMatrixElement_targetY_Getter(mthis) native "SVGFEConvolveMatrixElement_targetY_Getter";

Native_SVGFEConvolveMatrixElement_height_Getter(mthis) native "SVGFEConvolveMatrixElement_height_Getter";

Native_SVGFEConvolveMatrixElement_result_Getter(mthis) native "SVGFEConvolveMatrixElement_result_Getter";

Native_SVGFEConvolveMatrixElement_width_Getter(mthis) native "SVGFEConvolveMatrixElement_width_Getter";

Native_SVGFEConvolveMatrixElement_x_Getter(mthis) native "SVGFEConvolveMatrixElement_x_Getter";

Native_SVGFEConvolveMatrixElement_y_Getter(mthis) native "SVGFEConvolveMatrixElement_y_Getter";

Native_SVGFEDiffuseLightingElement_diffuseConstant_Getter(mthis) native "SVGFEDiffuseLightingElement_diffuseConstant_Getter";

Native_SVGFEDiffuseLightingElement_in1_Getter(mthis) native "SVGFEDiffuseLightingElement_in1_Getter";

Native_SVGFEDiffuseLightingElement_kernelUnitLengthX_Getter(mthis) native "SVGFEDiffuseLightingElement_kernelUnitLengthX_Getter";

Native_SVGFEDiffuseLightingElement_kernelUnitLengthY_Getter(mthis) native "SVGFEDiffuseLightingElement_kernelUnitLengthY_Getter";

Native_SVGFEDiffuseLightingElement_surfaceScale_Getter(mthis) native "SVGFEDiffuseLightingElement_surfaceScale_Getter";

Native_SVGFEDiffuseLightingElement_height_Getter(mthis) native "SVGFEDiffuseLightingElement_height_Getter";

Native_SVGFEDiffuseLightingElement_result_Getter(mthis) native "SVGFEDiffuseLightingElement_result_Getter";

Native_SVGFEDiffuseLightingElement_width_Getter(mthis) native "SVGFEDiffuseLightingElement_width_Getter";

Native_SVGFEDiffuseLightingElement_x_Getter(mthis) native "SVGFEDiffuseLightingElement_x_Getter";

Native_SVGFEDiffuseLightingElement_y_Getter(mthis) native "SVGFEDiffuseLightingElement_y_Getter";

Native_SVGFEDisplacementMapElement_in1_Getter(mthis) native "SVGFEDisplacementMapElement_in1_Getter";

Native_SVGFEDisplacementMapElement_in2_Getter(mthis) native "SVGFEDisplacementMapElement_in2_Getter";

Native_SVGFEDisplacementMapElement_scale_Getter(mthis) native "SVGFEDisplacementMapElement_scale_Getter";

Native_SVGFEDisplacementMapElement_xChannelSelector_Getter(mthis) native "SVGFEDisplacementMapElement_xChannelSelector_Getter";

Native_SVGFEDisplacementMapElement_yChannelSelector_Getter(mthis) native "SVGFEDisplacementMapElement_yChannelSelector_Getter";

Native_SVGFEDisplacementMapElement_height_Getter(mthis) native "SVGFEDisplacementMapElement_height_Getter";

Native_SVGFEDisplacementMapElement_result_Getter(mthis) native "SVGFEDisplacementMapElement_result_Getter";

Native_SVGFEDisplacementMapElement_width_Getter(mthis) native "SVGFEDisplacementMapElement_width_Getter";

Native_SVGFEDisplacementMapElement_x_Getter(mthis) native "SVGFEDisplacementMapElement_x_Getter";

Native_SVGFEDisplacementMapElement_y_Getter(mthis) native "SVGFEDisplacementMapElement_y_Getter";

Native_SVGFEDistantLightElement_azimuth_Getter(mthis) native "SVGFEDistantLightElement_azimuth_Getter";

Native_SVGFEDistantLightElement_elevation_Getter(mthis) native "SVGFEDistantLightElement_elevation_Getter";

Native_SVGFEFloodElement_height_Getter(mthis) native "SVGFEFloodElement_height_Getter";

Native_SVGFEFloodElement_result_Getter(mthis) native "SVGFEFloodElement_result_Getter";

Native_SVGFEFloodElement_width_Getter(mthis) native "SVGFEFloodElement_width_Getter";

Native_SVGFEFloodElement_x_Getter(mthis) native "SVGFEFloodElement_x_Getter";

Native_SVGFEFloodElement_y_Getter(mthis) native "SVGFEFloodElement_y_Getter";

Native_SVGFEGaussianBlurElement_in1_Getter(mthis) native "SVGFEGaussianBlurElement_in1_Getter";

Native_SVGFEGaussianBlurElement_stdDeviationX_Getter(mthis) native "SVGFEGaussianBlurElement_stdDeviationX_Getter";

Native_SVGFEGaussianBlurElement_stdDeviationY_Getter(mthis) native "SVGFEGaussianBlurElement_stdDeviationY_Getter";

Native_SVGFEGaussianBlurElement_setStdDeviation_Callback(mthis, stdDeviationX, stdDeviationY) native "SVGFEGaussianBlurElement_setStdDeviation_Callback_RESOLVER_STRING_2_float_float";

Native_SVGFEGaussianBlurElement_height_Getter(mthis) native "SVGFEGaussianBlurElement_height_Getter";

Native_SVGFEGaussianBlurElement_result_Getter(mthis) native "SVGFEGaussianBlurElement_result_Getter";

Native_SVGFEGaussianBlurElement_width_Getter(mthis) native "SVGFEGaussianBlurElement_width_Getter";

Native_SVGFEGaussianBlurElement_x_Getter(mthis) native "SVGFEGaussianBlurElement_x_Getter";

Native_SVGFEGaussianBlurElement_y_Getter(mthis) native "SVGFEGaussianBlurElement_y_Getter";

Native_SVGFEImageElement_preserveAspectRatio_Getter(mthis) native "SVGFEImageElement_preserveAspectRatio_Getter";

Native_SVGFEImageElement_height_Getter(mthis) native "SVGFEImageElement_height_Getter";

Native_SVGFEImageElement_result_Getter(mthis) native "SVGFEImageElement_result_Getter";

Native_SVGFEImageElement_width_Getter(mthis) native "SVGFEImageElement_width_Getter";

Native_SVGFEImageElement_x_Getter(mthis) native "SVGFEImageElement_x_Getter";

Native_SVGFEImageElement_y_Getter(mthis) native "SVGFEImageElement_y_Getter";

Native_SVGFEImageElement_href_Getter(mthis) native "SVGFEImageElement_href_Getter";

Native_SVGFEMergeElement_height_Getter(mthis) native "SVGFEMergeElement_height_Getter";

Native_SVGFEMergeElement_result_Getter(mthis) native "SVGFEMergeElement_result_Getter";

Native_SVGFEMergeElement_width_Getter(mthis) native "SVGFEMergeElement_width_Getter";

Native_SVGFEMergeElement_x_Getter(mthis) native "SVGFEMergeElement_x_Getter";

Native_SVGFEMergeElement_y_Getter(mthis) native "SVGFEMergeElement_y_Getter";

Native_SVGFEMergeNodeElement_in1_Getter(mthis) native "SVGFEMergeNodeElement_in1_Getter";

Native_SVGFEMorphologyElement_in1_Getter(mthis) native "SVGFEMorphologyElement_in1_Getter";

Native_SVGFEMorphologyElement_operator_Getter(mthis) native "SVGFEMorphologyElement_operator_Getter";

Native_SVGFEMorphologyElement_radiusX_Getter(mthis) native "SVGFEMorphologyElement_radiusX_Getter";

Native_SVGFEMorphologyElement_radiusY_Getter(mthis) native "SVGFEMorphologyElement_radiusY_Getter";

Native_SVGFEMorphologyElement_setRadius_Callback(mthis, radiusX, radiusY) native "SVGFEMorphologyElement_setRadius_Callback_RESOLVER_STRING_2_float_float";

Native_SVGFEMorphologyElement_height_Getter(mthis) native "SVGFEMorphologyElement_height_Getter";

Native_SVGFEMorphologyElement_result_Getter(mthis) native "SVGFEMorphologyElement_result_Getter";

Native_SVGFEMorphologyElement_width_Getter(mthis) native "SVGFEMorphologyElement_width_Getter";

Native_SVGFEMorphologyElement_x_Getter(mthis) native "SVGFEMorphologyElement_x_Getter";

Native_SVGFEMorphologyElement_y_Getter(mthis) native "SVGFEMorphologyElement_y_Getter";

Native_SVGFEOffsetElement_dx_Getter(mthis) native "SVGFEOffsetElement_dx_Getter";

Native_SVGFEOffsetElement_dy_Getter(mthis) native "SVGFEOffsetElement_dy_Getter";

Native_SVGFEOffsetElement_in1_Getter(mthis) native "SVGFEOffsetElement_in1_Getter";

Native_SVGFEOffsetElement_height_Getter(mthis) native "SVGFEOffsetElement_height_Getter";

Native_SVGFEOffsetElement_result_Getter(mthis) native "SVGFEOffsetElement_result_Getter";

Native_SVGFEOffsetElement_width_Getter(mthis) native "SVGFEOffsetElement_width_Getter";

Native_SVGFEOffsetElement_x_Getter(mthis) native "SVGFEOffsetElement_x_Getter";

Native_SVGFEOffsetElement_y_Getter(mthis) native "SVGFEOffsetElement_y_Getter";

Native_SVGFEPointLightElement_x_Getter(mthis) native "SVGFEPointLightElement_x_Getter";

Native_SVGFEPointLightElement_y_Getter(mthis) native "SVGFEPointLightElement_y_Getter";

Native_SVGFEPointLightElement_z_Getter(mthis) native "SVGFEPointLightElement_z_Getter";

Native_SVGFESpecularLightingElement_in1_Getter(mthis) native "SVGFESpecularLightingElement_in1_Getter";

Native_SVGFESpecularLightingElement_specularConstant_Getter(mthis) native "SVGFESpecularLightingElement_specularConstant_Getter";

Native_SVGFESpecularLightingElement_specularExponent_Getter(mthis) native "SVGFESpecularLightingElement_specularExponent_Getter";

Native_SVGFESpecularLightingElement_surfaceScale_Getter(mthis) native "SVGFESpecularLightingElement_surfaceScale_Getter";

Native_SVGFESpecularLightingElement_height_Getter(mthis) native "SVGFESpecularLightingElement_height_Getter";

Native_SVGFESpecularLightingElement_result_Getter(mthis) native "SVGFESpecularLightingElement_result_Getter";

Native_SVGFESpecularLightingElement_width_Getter(mthis) native "SVGFESpecularLightingElement_width_Getter";

Native_SVGFESpecularLightingElement_x_Getter(mthis) native "SVGFESpecularLightingElement_x_Getter";

Native_SVGFESpecularLightingElement_y_Getter(mthis) native "SVGFESpecularLightingElement_y_Getter";

Native_SVGFESpotLightElement_limitingConeAngle_Getter(mthis) native "SVGFESpotLightElement_limitingConeAngle_Getter";

Native_SVGFESpotLightElement_pointsAtX_Getter(mthis) native "SVGFESpotLightElement_pointsAtX_Getter";

Native_SVGFESpotLightElement_pointsAtY_Getter(mthis) native "SVGFESpotLightElement_pointsAtY_Getter";

Native_SVGFESpotLightElement_pointsAtZ_Getter(mthis) native "SVGFESpotLightElement_pointsAtZ_Getter";

Native_SVGFESpotLightElement_specularExponent_Getter(mthis) native "SVGFESpotLightElement_specularExponent_Getter";

Native_SVGFESpotLightElement_x_Getter(mthis) native "SVGFESpotLightElement_x_Getter";

Native_SVGFESpotLightElement_y_Getter(mthis) native "SVGFESpotLightElement_y_Getter";

Native_SVGFESpotLightElement_z_Getter(mthis) native "SVGFESpotLightElement_z_Getter";

Native_SVGFETileElement_in1_Getter(mthis) native "SVGFETileElement_in1_Getter";

Native_SVGFETileElement_height_Getter(mthis) native "SVGFETileElement_height_Getter";

Native_SVGFETileElement_result_Getter(mthis) native "SVGFETileElement_result_Getter";

Native_SVGFETileElement_width_Getter(mthis) native "SVGFETileElement_width_Getter";

Native_SVGFETileElement_x_Getter(mthis) native "SVGFETileElement_x_Getter";

Native_SVGFETileElement_y_Getter(mthis) native "SVGFETileElement_y_Getter";

Native_SVGFETurbulenceElement_baseFrequencyX_Getter(mthis) native "SVGFETurbulenceElement_baseFrequencyX_Getter";

Native_SVGFETurbulenceElement_baseFrequencyY_Getter(mthis) native "SVGFETurbulenceElement_baseFrequencyY_Getter";

Native_SVGFETurbulenceElement_numOctaves_Getter(mthis) native "SVGFETurbulenceElement_numOctaves_Getter";

Native_SVGFETurbulenceElement_seed_Getter(mthis) native "SVGFETurbulenceElement_seed_Getter";

Native_SVGFETurbulenceElement_stitchTiles_Getter(mthis) native "SVGFETurbulenceElement_stitchTiles_Getter";

Native_SVGFETurbulenceElement_type_Getter(mthis) native "SVGFETurbulenceElement_type_Getter";

Native_SVGFETurbulenceElement_height_Getter(mthis) native "SVGFETurbulenceElement_height_Getter";

Native_SVGFETurbulenceElement_result_Getter(mthis) native "SVGFETurbulenceElement_result_Getter";

Native_SVGFETurbulenceElement_width_Getter(mthis) native "SVGFETurbulenceElement_width_Getter";

Native_SVGFETurbulenceElement_x_Getter(mthis) native "SVGFETurbulenceElement_x_Getter";

Native_SVGFETurbulenceElement_y_Getter(mthis) native "SVGFETurbulenceElement_y_Getter";

Native_SVGFilterElement_filterResX_Getter(mthis) native "SVGFilterElement_filterResX_Getter";

Native_SVGFilterElement_filterResY_Getter(mthis) native "SVGFilterElement_filterResY_Getter";

Native_SVGFilterElement_filterUnits_Getter(mthis) native "SVGFilterElement_filterUnits_Getter";

Native_SVGFilterElement_height_Getter(mthis) native "SVGFilterElement_height_Getter";

Native_SVGFilterElement_primitiveUnits_Getter(mthis) native "SVGFilterElement_primitiveUnits_Getter";

Native_SVGFilterElement_width_Getter(mthis) native "SVGFilterElement_width_Getter";

Native_SVGFilterElement_x_Getter(mthis) native "SVGFilterElement_x_Getter";

Native_SVGFilterElement_y_Getter(mthis) native "SVGFilterElement_y_Getter";

Native_SVGFilterElement_setFilterRes_Callback(mthis, filterResX, filterResY) native "SVGFilterElement_setFilterRes_Callback_RESOLVER_STRING_2_unsigned long_unsigned long";

Native_SVGFilterElement_href_Getter(mthis) native "SVGFilterElement_href_Getter";

Native_SVGFitToViewBox_preserveAspectRatio_Getter(mthis) native "SVGFitToViewBox_preserveAspectRatio_Getter";

Native_SVGFitToViewBox_viewBox_Getter(mthis) native "SVGFitToViewBox_viewBox_Getter";

Native_SVGForeignObjectElement_height_Getter(mthis) native "SVGForeignObjectElement_height_Getter";

Native_SVGForeignObjectElement_width_Getter(mthis) native "SVGForeignObjectElement_width_Getter";

Native_SVGForeignObjectElement_x_Getter(mthis) native "SVGForeignObjectElement_x_Getter";

Native_SVGForeignObjectElement_y_Getter(mthis) native "SVGForeignObjectElement_y_Getter";

Native_SVGGradientElement_gradientTransform_Getter(mthis) native "SVGGradientElement_gradientTransform_Getter";

Native_SVGGradientElement_gradientUnits_Getter(mthis) native "SVGGradientElement_gradientUnits_Getter";

Native_SVGGradientElement_spreadMethod_Getter(mthis) native "SVGGradientElement_spreadMethod_Getter";

Native_SVGGradientElement_href_Getter(mthis) native "SVGGradientElement_href_Getter";

Native_SVGImageElement_height_Getter(mthis) native "SVGImageElement_height_Getter";

Native_SVGImageElement_preserveAspectRatio_Getter(mthis) native "SVGImageElement_preserveAspectRatio_Getter";

Native_SVGImageElement_width_Getter(mthis) native "SVGImageElement_width_Getter";

Native_SVGImageElement_x_Getter(mthis) native "SVGImageElement_x_Getter";

Native_SVGImageElement_y_Getter(mthis) native "SVGImageElement_y_Getter";

Native_SVGImageElement_href_Getter(mthis) native "SVGImageElement_href_Getter";

Native_SVGLength_unitType_Getter(mthis) native "SVGLength_unitType_Getter";

Native_SVGLength_value_Getter(mthis) native "SVGLength_value_Getter";

Native_SVGLength_value_Setter(mthis, value) native "SVGLength_value_Setter";

Native_SVGLength_valueAsString_Getter(mthis) native "SVGLength_valueAsString_Getter";

Native_SVGLength_valueAsString_Setter(mthis, value) native "SVGLength_valueAsString_Setter";

Native_SVGLength_valueInSpecifiedUnits_Getter(mthis) native "SVGLength_valueInSpecifiedUnits_Getter";

Native_SVGLength_valueInSpecifiedUnits_Setter(mthis, value) native "SVGLength_valueInSpecifiedUnits_Setter";

Native_SVGLength_convertToSpecifiedUnits_Callback(mthis, unitType) native "SVGLength_convertToSpecifiedUnits_Callback_RESOLVER_STRING_1_unsigned short";

Native_SVGLength_newValueSpecifiedUnits_Callback(mthis, unitType, valueInSpecifiedUnits) native "SVGLength_newValueSpecifiedUnits_Callback_RESOLVER_STRING_2_unsigned short_float";

Native_SVGLengthList_numberOfItems_Getter(mthis) native "SVGLengthList_numberOfItems_Getter";

Native_SVGLengthList_appendItem_Callback(mthis, item) native "SVGLengthList_appendItem_Callback_RESOLVER_STRING_1_SVGLength";

Native_SVGLengthList_clear_Callback(mthis) native "SVGLengthList_clear_Callback_RESOLVER_STRING_0_";

Native_SVGLengthList_getItem_Callback(mthis, index) native "SVGLengthList_getItem_Callback_RESOLVER_STRING_1_unsigned long";

Native_SVGLengthList_initialize_Callback(mthis, item) native "SVGLengthList_initialize_Callback_RESOLVER_STRING_1_SVGLength";

Native_SVGLengthList_insertItemBefore_Callback(mthis, item, index) native "SVGLengthList_insertItemBefore_Callback_RESOLVER_STRING_2_SVGLength_unsigned long";

Native_SVGLengthList_removeItem_Callback(mthis, index) native "SVGLengthList_removeItem_Callback_RESOLVER_STRING_1_unsigned long";

Native_SVGLengthList_replaceItem_Callback(mthis, item, index) native "SVGLengthList_replaceItem_Callback_RESOLVER_STRING_2_SVGLength_unsigned long";

Native_SVGLineElement_x1_Getter(mthis) native "SVGLineElement_x1_Getter";

Native_SVGLineElement_x2_Getter(mthis) native "SVGLineElement_x2_Getter";

Native_SVGLineElement_y1_Getter(mthis) native "SVGLineElement_y1_Getter";

Native_SVGLineElement_y2_Getter(mthis) native "SVGLineElement_y2_Getter";

Native_SVGLinearGradientElement_x1_Getter(mthis) native "SVGLinearGradientElement_x1_Getter";

Native_SVGLinearGradientElement_x2_Getter(mthis) native "SVGLinearGradientElement_x2_Getter";

Native_SVGLinearGradientElement_y1_Getter(mthis) native "SVGLinearGradientElement_y1_Getter";

Native_SVGLinearGradientElement_y2_Getter(mthis) native "SVGLinearGradientElement_y2_Getter";

Native_SVGMarkerElement_markerHeight_Getter(mthis) native "SVGMarkerElement_markerHeight_Getter";

Native_SVGMarkerElement_markerUnits_Getter(mthis) native "SVGMarkerElement_markerUnits_Getter";

Native_SVGMarkerElement_markerWidth_Getter(mthis) native "SVGMarkerElement_markerWidth_Getter";

Native_SVGMarkerElement_orientAngle_Getter(mthis) native "SVGMarkerElement_orientAngle_Getter";

Native_SVGMarkerElement_orientType_Getter(mthis) native "SVGMarkerElement_orientType_Getter";

Native_SVGMarkerElement_refX_Getter(mthis) native "SVGMarkerElement_refX_Getter";

Native_SVGMarkerElement_refY_Getter(mthis) native "SVGMarkerElement_refY_Getter";

Native_SVGMarkerElement_setOrientToAngle_Callback(mthis, angle) native "SVGMarkerElement_setOrientToAngle_Callback_RESOLVER_STRING_1_SVGAngle";

Native_SVGMarkerElement_setOrientToAuto_Callback(mthis) native "SVGMarkerElement_setOrientToAuto_Callback_RESOLVER_STRING_0_";

Native_SVGMarkerElement_preserveAspectRatio_Getter(mthis) native "SVGMarkerElement_preserveAspectRatio_Getter";

Native_SVGMarkerElement_viewBox_Getter(mthis) native "SVGMarkerElement_viewBox_Getter";

Native_SVGMaskElement_height_Getter(mthis) native "SVGMaskElement_height_Getter";

Native_SVGMaskElement_maskContentUnits_Getter(mthis) native "SVGMaskElement_maskContentUnits_Getter";

Native_SVGMaskElement_maskUnits_Getter(mthis) native "SVGMaskElement_maskUnits_Getter";

Native_SVGMaskElement_width_Getter(mthis) native "SVGMaskElement_width_Getter";

Native_SVGMaskElement_x_Getter(mthis) native "SVGMaskElement_x_Getter";

Native_SVGMaskElement_y_Getter(mthis) native "SVGMaskElement_y_Getter";

Native_SVGMaskElement_requiredExtensions_Getter(mthis) native "SVGMaskElement_requiredExtensions_Getter";

Native_SVGMaskElement_requiredFeatures_Getter(mthis) native "SVGMaskElement_requiredFeatures_Getter";

Native_SVGMaskElement_systemLanguage_Getter(mthis) native "SVGMaskElement_systemLanguage_Getter";

Native_SVGMaskElement_hasExtension_Callback(mthis, extension) native "SVGMaskElement_hasExtension_Callback_RESOLVER_STRING_1_DOMString";

Native_SVGMatrix_a_Getter(mthis) native "SVGMatrix_a_Getter";

Native_SVGMatrix_a_Setter(mthis, value) native "SVGMatrix_a_Setter";

Native_SVGMatrix_b_Getter(mthis) native "SVGMatrix_b_Getter";

Native_SVGMatrix_b_Setter(mthis, value) native "SVGMatrix_b_Setter";

Native_SVGMatrix_c_Getter(mthis) native "SVGMatrix_c_Getter";

Native_SVGMatrix_c_Setter(mthis, value) native "SVGMatrix_c_Setter";

Native_SVGMatrix_d_Getter(mthis) native "SVGMatrix_d_Getter";

Native_SVGMatrix_d_Setter(mthis, value) native "SVGMatrix_d_Setter";

Native_SVGMatrix_e_Getter(mthis) native "SVGMatrix_e_Getter";

Native_SVGMatrix_e_Setter(mthis, value) native "SVGMatrix_e_Setter";

Native_SVGMatrix_f_Getter(mthis) native "SVGMatrix_f_Getter";

Native_SVGMatrix_f_Setter(mthis, value) native "SVGMatrix_f_Setter";

Native_SVGMatrix_flipX_Callback(mthis) native "SVGMatrix_flipX_Callback_RESOLVER_STRING_0_";

Native_SVGMatrix_flipY_Callback(mthis) native "SVGMatrix_flipY_Callback_RESOLVER_STRING_0_";

Native_SVGMatrix_inverse_Callback(mthis) native "SVGMatrix_inverse_Callback_RESOLVER_STRING_0_";

Native_SVGMatrix_multiply_Callback(mthis, secondMatrix) native "SVGMatrix_multiply_Callback_RESOLVER_STRING_1_SVGMatrix";

Native_SVGMatrix_rotate_Callback(mthis, angle) native "SVGMatrix_rotate_Callback_RESOLVER_STRING_1_float";

Native_SVGMatrix_rotateFromVector_Callback(mthis, x, y) native "SVGMatrix_rotateFromVector_Callback_RESOLVER_STRING_2_float_float";

Native_SVGMatrix_scale_Callback(mthis, scaleFactor) native "SVGMatrix_scale_Callback_RESOLVER_STRING_1_float";

Native_SVGMatrix_scaleNonUniform_Callback(mthis, scaleFactorX, scaleFactorY) native "SVGMatrix_scaleNonUniform_Callback_RESOLVER_STRING_2_float_float";

Native_SVGMatrix_skewX_Callback(mthis, angle) native "SVGMatrix_skewX_Callback_RESOLVER_STRING_1_float";

Native_SVGMatrix_skewY_Callback(mthis, angle) native "SVGMatrix_skewY_Callback_RESOLVER_STRING_1_float";

Native_SVGMatrix_translate_Callback(mthis, x, y) native "SVGMatrix_translate_Callback_RESOLVER_STRING_2_float_float";

Native_SVGNumber_value_Getter(mthis) native "SVGNumber_value_Getter";

Native_SVGNumber_value_Setter(mthis, value) native "SVGNumber_value_Setter";

Native_SVGNumberList_numberOfItems_Getter(mthis) native "SVGNumberList_numberOfItems_Getter";

Native_SVGNumberList_appendItem_Callback(mthis, item) native "SVGNumberList_appendItem_Callback_RESOLVER_STRING_1_SVGNumber";

Native_SVGNumberList_clear_Callback(mthis) native "SVGNumberList_clear_Callback_RESOLVER_STRING_0_";

Native_SVGNumberList_getItem_Callback(mthis, index) native "SVGNumberList_getItem_Callback_RESOLVER_STRING_1_unsigned long";

Native_SVGNumberList_initialize_Callback(mthis, item) native "SVGNumberList_initialize_Callback_RESOLVER_STRING_1_SVGNumber";

Native_SVGNumberList_insertItemBefore_Callback(mthis, item, index) native "SVGNumberList_insertItemBefore_Callback_RESOLVER_STRING_2_SVGNumber_unsigned long";

Native_SVGNumberList_removeItem_Callback(mthis, index) native "SVGNumberList_removeItem_Callback_RESOLVER_STRING_1_unsigned long";

Native_SVGNumberList_replaceItem_Callback(mthis, item, index) native "SVGNumberList_replaceItem_Callback_RESOLVER_STRING_2_SVGNumber_unsigned long";

Native_SVGPathElement_animatedNormalizedPathSegList_Getter(mthis) native "SVGPathElement_animatedNormalizedPathSegList_Getter";

Native_SVGPathElement_animatedPathSegList_Getter(mthis) native "SVGPathElement_animatedPathSegList_Getter";

Native_SVGPathElement_normalizedPathSegList_Getter(mthis) native "SVGPathElement_normalizedPathSegList_Getter";

Native_SVGPathElement_pathLength_Getter(mthis) native "SVGPathElement_pathLength_Getter";

Native_SVGPathElement_pathSegList_Getter(mthis) native "SVGPathElement_pathSegList_Getter";

Native_SVGPathElement_createSVGPathSegArcAbs_Callback(mthis, x, y, r1, r2, angle, largeArcFlag, sweepFlag) native "SVGPathElement_createSVGPathSegArcAbs_Callback_RESOLVER_STRING_7_float_float_float_float_float_boolean_boolean";

Native_SVGPathElement_createSVGPathSegArcRel_Callback(mthis, x, y, r1, r2, angle, largeArcFlag, sweepFlag) native "SVGPathElement_createSVGPathSegArcRel_Callback_RESOLVER_STRING_7_float_float_float_float_float_boolean_boolean";

Native_SVGPathElement_createSVGPathSegClosePath_Callback(mthis) native "SVGPathElement_createSVGPathSegClosePath_Callback_RESOLVER_STRING_0_";

Native_SVGPathElement_createSVGPathSegCurvetoCubicAbs_Callback(mthis, x, y, x1, y1, x2, y2) native "SVGPathElement_createSVGPathSegCurvetoCubicAbs_Callback_RESOLVER_STRING_6_float_float_float_float_float_float";

Native_SVGPathElement_createSVGPathSegCurvetoCubicRel_Callback(mthis, x, y, x1, y1, x2, y2) native "SVGPathElement_createSVGPathSegCurvetoCubicRel_Callback_RESOLVER_STRING_6_float_float_float_float_float_float";

Native_SVGPathElement_createSVGPathSegCurvetoCubicSmoothAbs_Callback(mthis, x, y, x2, y2) native "SVGPathElement_createSVGPathSegCurvetoCubicSmoothAbs_Callback_RESOLVER_STRING_4_float_float_float_float";

Native_SVGPathElement_createSVGPathSegCurvetoCubicSmoothRel_Callback(mthis, x, y, x2, y2) native "SVGPathElement_createSVGPathSegCurvetoCubicSmoothRel_Callback_RESOLVER_STRING_4_float_float_float_float";

Native_SVGPathElement_createSVGPathSegCurvetoQuadraticAbs_Callback(mthis, x, y, x1, y1) native "SVGPathElement_createSVGPathSegCurvetoQuadraticAbs_Callback_RESOLVER_STRING_4_float_float_float_float";

Native_SVGPathElement_createSVGPathSegCurvetoQuadraticRel_Callback(mthis, x, y, x1, y1) native "SVGPathElement_createSVGPathSegCurvetoQuadraticRel_Callback_RESOLVER_STRING_4_float_float_float_float";

Native_SVGPathElement_createSVGPathSegCurvetoQuadraticSmoothAbs_Callback(mthis, x, y) native "SVGPathElement_createSVGPathSegCurvetoQuadraticSmoothAbs_Callback_RESOLVER_STRING_2_float_float";

Native_SVGPathElement_createSVGPathSegCurvetoQuadraticSmoothRel_Callback(mthis, x, y) native "SVGPathElement_createSVGPathSegCurvetoQuadraticSmoothRel_Callback_RESOLVER_STRING_2_float_float";

Native_SVGPathElement_createSVGPathSegLinetoAbs_Callback(mthis, x, y) native "SVGPathElement_createSVGPathSegLinetoAbs_Callback_RESOLVER_STRING_2_float_float";

Native_SVGPathElement_createSVGPathSegLinetoHorizontalAbs_Callback(mthis, x) native "SVGPathElement_createSVGPathSegLinetoHorizontalAbs_Callback_RESOLVER_STRING_1_float";

Native_SVGPathElement_createSVGPathSegLinetoHorizontalRel_Callback(mthis, x) native "SVGPathElement_createSVGPathSegLinetoHorizontalRel_Callback_RESOLVER_STRING_1_float";

Native_SVGPathElement_createSVGPathSegLinetoRel_Callback(mthis, x, y) native "SVGPathElement_createSVGPathSegLinetoRel_Callback_RESOLVER_STRING_2_float_float";

Native_SVGPathElement_createSVGPathSegLinetoVerticalAbs_Callback(mthis, y) native "SVGPathElement_createSVGPathSegLinetoVerticalAbs_Callback_RESOLVER_STRING_1_float";

Native_SVGPathElement_createSVGPathSegLinetoVerticalRel_Callback(mthis, y) native "SVGPathElement_createSVGPathSegLinetoVerticalRel_Callback_RESOLVER_STRING_1_float";

Native_SVGPathElement_createSVGPathSegMovetoAbs_Callback(mthis, x, y) native "SVGPathElement_createSVGPathSegMovetoAbs_Callback_RESOLVER_STRING_2_float_float";

Native_SVGPathElement_createSVGPathSegMovetoRel_Callback(mthis, x, y) native "SVGPathElement_createSVGPathSegMovetoRel_Callback_RESOLVER_STRING_2_float_float";

Native_SVGPathElement_getPathSegAtLength_Callback(mthis, distance) native "SVGPathElement_getPathSegAtLength_Callback_RESOLVER_STRING_1_float";

Native_SVGPathElement_getPointAtLength_Callback(mthis, distance) native "SVGPathElement_getPointAtLength_Callback_RESOLVER_STRING_1_float";

Native_SVGPathElement_getTotalLength_Callback(mthis) native "SVGPathElement_getTotalLength_Callback_RESOLVER_STRING_0_";

Native_SVGPathSeg_pathSegType_Getter(mthis) native "SVGPathSeg_pathSegType_Getter";

Native_SVGPathSeg_pathSegTypeAsLetter_Getter(mthis) native "SVGPathSeg_pathSegTypeAsLetter_Getter";

Native_SVGPathSegArcAbs_angle_Getter(mthis) native "SVGPathSegArcAbs_angle_Getter";

Native_SVGPathSegArcAbs_angle_Setter(mthis, value) native "SVGPathSegArcAbs_angle_Setter";

Native_SVGPathSegArcAbs_largeArcFlag_Getter(mthis) native "SVGPathSegArcAbs_largeArcFlag_Getter";

Native_SVGPathSegArcAbs_largeArcFlag_Setter(mthis, value) native "SVGPathSegArcAbs_largeArcFlag_Setter";

Native_SVGPathSegArcAbs_r1_Getter(mthis) native "SVGPathSegArcAbs_r1_Getter";

Native_SVGPathSegArcAbs_r1_Setter(mthis, value) native "SVGPathSegArcAbs_r1_Setter";

Native_SVGPathSegArcAbs_r2_Getter(mthis) native "SVGPathSegArcAbs_r2_Getter";

Native_SVGPathSegArcAbs_r2_Setter(mthis, value) native "SVGPathSegArcAbs_r2_Setter";

Native_SVGPathSegArcAbs_sweepFlag_Getter(mthis) native "SVGPathSegArcAbs_sweepFlag_Getter";

Native_SVGPathSegArcAbs_sweepFlag_Setter(mthis, value) native "SVGPathSegArcAbs_sweepFlag_Setter";

Native_SVGPathSegArcAbs_x_Getter(mthis) native "SVGPathSegArcAbs_x_Getter";

Native_SVGPathSegArcAbs_x_Setter(mthis, value) native "SVGPathSegArcAbs_x_Setter";

Native_SVGPathSegArcAbs_y_Getter(mthis) native "SVGPathSegArcAbs_y_Getter";

Native_SVGPathSegArcAbs_y_Setter(mthis, value) native "SVGPathSegArcAbs_y_Setter";

Native_SVGPathSegArcRel_angle_Getter(mthis) native "SVGPathSegArcRel_angle_Getter";

Native_SVGPathSegArcRel_angle_Setter(mthis, value) native "SVGPathSegArcRel_angle_Setter";

Native_SVGPathSegArcRel_largeArcFlag_Getter(mthis) native "SVGPathSegArcRel_largeArcFlag_Getter";

Native_SVGPathSegArcRel_largeArcFlag_Setter(mthis, value) native "SVGPathSegArcRel_largeArcFlag_Setter";

Native_SVGPathSegArcRel_r1_Getter(mthis) native "SVGPathSegArcRel_r1_Getter";

Native_SVGPathSegArcRel_r1_Setter(mthis, value) native "SVGPathSegArcRel_r1_Setter";

Native_SVGPathSegArcRel_r2_Getter(mthis) native "SVGPathSegArcRel_r2_Getter";

Native_SVGPathSegArcRel_r2_Setter(mthis, value) native "SVGPathSegArcRel_r2_Setter";

Native_SVGPathSegArcRel_sweepFlag_Getter(mthis) native "SVGPathSegArcRel_sweepFlag_Getter";

Native_SVGPathSegArcRel_sweepFlag_Setter(mthis, value) native "SVGPathSegArcRel_sweepFlag_Setter";

Native_SVGPathSegArcRel_x_Getter(mthis) native "SVGPathSegArcRel_x_Getter";

Native_SVGPathSegArcRel_x_Setter(mthis, value) native "SVGPathSegArcRel_x_Setter";

Native_SVGPathSegArcRel_y_Getter(mthis) native "SVGPathSegArcRel_y_Getter";

Native_SVGPathSegArcRel_y_Setter(mthis, value) native "SVGPathSegArcRel_y_Setter";

Native_SVGPathSegCurvetoCubicAbs_x_Getter(mthis) native "SVGPathSegCurvetoCubicAbs_x_Getter";

Native_SVGPathSegCurvetoCubicAbs_x_Setter(mthis, value) native "SVGPathSegCurvetoCubicAbs_x_Setter";

Native_SVGPathSegCurvetoCubicAbs_x1_Getter(mthis) native "SVGPathSegCurvetoCubicAbs_x1_Getter";

Native_SVGPathSegCurvetoCubicAbs_x1_Setter(mthis, value) native "SVGPathSegCurvetoCubicAbs_x1_Setter";

Native_SVGPathSegCurvetoCubicAbs_x2_Getter(mthis) native "SVGPathSegCurvetoCubicAbs_x2_Getter";

Native_SVGPathSegCurvetoCubicAbs_x2_Setter(mthis, value) native "SVGPathSegCurvetoCubicAbs_x2_Setter";

Native_SVGPathSegCurvetoCubicAbs_y_Getter(mthis) native "SVGPathSegCurvetoCubicAbs_y_Getter";

Native_SVGPathSegCurvetoCubicAbs_y_Setter(mthis, value) native "SVGPathSegCurvetoCubicAbs_y_Setter";

Native_SVGPathSegCurvetoCubicAbs_y1_Getter(mthis) native "SVGPathSegCurvetoCubicAbs_y1_Getter";

Native_SVGPathSegCurvetoCubicAbs_y1_Setter(mthis, value) native "SVGPathSegCurvetoCubicAbs_y1_Setter";

Native_SVGPathSegCurvetoCubicAbs_y2_Getter(mthis) native "SVGPathSegCurvetoCubicAbs_y2_Getter";

Native_SVGPathSegCurvetoCubicAbs_y2_Setter(mthis, value) native "SVGPathSegCurvetoCubicAbs_y2_Setter";

Native_SVGPathSegCurvetoCubicRel_x_Getter(mthis) native "SVGPathSegCurvetoCubicRel_x_Getter";

Native_SVGPathSegCurvetoCubicRel_x_Setter(mthis, value) native "SVGPathSegCurvetoCubicRel_x_Setter";

Native_SVGPathSegCurvetoCubicRel_x1_Getter(mthis) native "SVGPathSegCurvetoCubicRel_x1_Getter";

Native_SVGPathSegCurvetoCubicRel_x1_Setter(mthis, value) native "SVGPathSegCurvetoCubicRel_x1_Setter";

Native_SVGPathSegCurvetoCubicRel_x2_Getter(mthis) native "SVGPathSegCurvetoCubicRel_x2_Getter";

Native_SVGPathSegCurvetoCubicRel_x2_Setter(mthis, value) native "SVGPathSegCurvetoCubicRel_x2_Setter";

Native_SVGPathSegCurvetoCubicRel_y_Getter(mthis) native "SVGPathSegCurvetoCubicRel_y_Getter";

Native_SVGPathSegCurvetoCubicRel_y_Setter(mthis, value) native "SVGPathSegCurvetoCubicRel_y_Setter";

Native_SVGPathSegCurvetoCubicRel_y1_Getter(mthis) native "SVGPathSegCurvetoCubicRel_y1_Getter";

Native_SVGPathSegCurvetoCubicRel_y1_Setter(mthis, value) native "SVGPathSegCurvetoCubicRel_y1_Setter";

Native_SVGPathSegCurvetoCubicRel_y2_Getter(mthis) native "SVGPathSegCurvetoCubicRel_y2_Getter";

Native_SVGPathSegCurvetoCubicRel_y2_Setter(mthis, value) native "SVGPathSegCurvetoCubicRel_y2_Setter";

Native_SVGPathSegCurvetoCubicSmoothAbs_x_Getter(mthis) native "SVGPathSegCurvetoCubicSmoothAbs_x_Getter";

Native_SVGPathSegCurvetoCubicSmoothAbs_x_Setter(mthis, value) native "SVGPathSegCurvetoCubicSmoothAbs_x_Setter";

Native_SVGPathSegCurvetoCubicSmoothAbs_x2_Getter(mthis) native "SVGPathSegCurvetoCubicSmoothAbs_x2_Getter";

Native_SVGPathSegCurvetoCubicSmoothAbs_x2_Setter(mthis, value) native "SVGPathSegCurvetoCubicSmoothAbs_x2_Setter";

Native_SVGPathSegCurvetoCubicSmoothAbs_y_Getter(mthis) native "SVGPathSegCurvetoCubicSmoothAbs_y_Getter";

Native_SVGPathSegCurvetoCubicSmoothAbs_y_Setter(mthis, value) native "SVGPathSegCurvetoCubicSmoothAbs_y_Setter";

Native_SVGPathSegCurvetoCubicSmoothAbs_y2_Getter(mthis) native "SVGPathSegCurvetoCubicSmoothAbs_y2_Getter";

Native_SVGPathSegCurvetoCubicSmoothAbs_y2_Setter(mthis, value) native "SVGPathSegCurvetoCubicSmoothAbs_y2_Setter";

Native_SVGPathSegCurvetoCubicSmoothRel_x_Getter(mthis) native "SVGPathSegCurvetoCubicSmoothRel_x_Getter";

Native_SVGPathSegCurvetoCubicSmoothRel_x_Setter(mthis, value) native "SVGPathSegCurvetoCubicSmoothRel_x_Setter";

Native_SVGPathSegCurvetoCubicSmoothRel_x2_Getter(mthis) native "SVGPathSegCurvetoCubicSmoothRel_x2_Getter";

Native_SVGPathSegCurvetoCubicSmoothRel_x2_Setter(mthis, value) native "SVGPathSegCurvetoCubicSmoothRel_x2_Setter";

Native_SVGPathSegCurvetoCubicSmoothRel_y_Getter(mthis) native "SVGPathSegCurvetoCubicSmoothRel_y_Getter";

Native_SVGPathSegCurvetoCubicSmoothRel_y_Setter(mthis, value) native "SVGPathSegCurvetoCubicSmoothRel_y_Setter";

Native_SVGPathSegCurvetoCubicSmoothRel_y2_Getter(mthis) native "SVGPathSegCurvetoCubicSmoothRel_y2_Getter";

Native_SVGPathSegCurvetoCubicSmoothRel_y2_Setter(mthis, value) native "SVGPathSegCurvetoCubicSmoothRel_y2_Setter";

Native_SVGPathSegCurvetoQuadraticAbs_x_Getter(mthis) native "SVGPathSegCurvetoQuadraticAbs_x_Getter";

Native_SVGPathSegCurvetoQuadraticAbs_x_Setter(mthis, value) native "SVGPathSegCurvetoQuadraticAbs_x_Setter";

Native_SVGPathSegCurvetoQuadraticAbs_x1_Getter(mthis) native "SVGPathSegCurvetoQuadraticAbs_x1_Getter";

Native_SVGPathSegCurvetoQuadraticAbs_x1_Setter(mthis, value) native "SVGPathSegCurvetoQuadraticAbs_x1_Setter";

Native_SVGPathSegCurvetoQuadraticAbs_y_Getter(mthis) native "SVGPathSegCurvetoQuadraticAbs_y_Getter";

Native_SVGPathSegCurvetoQuadraticAbs_y_Setter(mthis, value) native "SVGPathSegCurvetoQuadraticAbs_y_Setter";

Native_SVGPathSegCurvetoQuadraticAbs_y1_Getter(mthis) native "SVGPathSegCurvetoQuadraticAbs_y1_Getter";

Native_SVGPathSegCurvetoQuadraticAbs_y1_Setter(mthis, value) native "SVGPathSegCurvetoQuadraticAbs_y1_Setter";

Native_SVGPathSegCurvetoQuadraticRel_x_Getter(mthis) native "SVGPathSegCurvetoQuadraticRel_x_Getter";

Native_SVGPathSegCurvetoQuadraticRel_x_Setter(mthis, value) native "SVGPathSegCurvetoQuadraticRel_x_Setter";

Native_SVGPathSegCurvetoQuadraticRel_x1_Getter(mthis) native "SVGPathSegCurvetoQuadraticRel_x1_Getter";

Native_SVGPathSegCurvetoQuadraticRel_x1_Setter(mthis, value) native "SVGPathSegCurvetoQuadraticRel_x1_Setter";

Native_SVGPathSegCurvetoQuadraticRel_y_Getter(mthis) native "SVGPathSegCurvetoQuadraticRel_y_Getter";

Native_SVGPathSegCurvetoQuadraticRel_y_Setter(mthis, value) native "SVGPathSegCurvetoQuadraticRel_y_Setter";

Native_SVGPathSegCurvetoQuadraticRel_y1_Getter(mthis) native "SVGPathSegCurvetoQuadraticRel_y1_Getter";

Native_SVGPathSegCurvetoQuadraticRel_y1_Setter(mthis, value) native "SVGPathSegCurvetoQuadraticRel_y1_Setter";

Native_SVGPathSegCurvetoQuadraticSmoothAbs_x_Getter(mthis) native "SVGPathSegCurvetoQuadraticSmoothAbs_x_Getter";

Native_SVGPathSegCurvetoQuadraticSmoothAbs_x_Setter(mthis, value) native "SVGPathSegCurvetoQuadraticSmoothAbs_x_Setter";

Native_SVGPathSegCurvetoQuadraticSmoothAbs_y_Getter(mthis) native "SVGPathSegCurvetoQuadraticSmoothAbs_y_Getter";

Native_SVGPathSegCurvetoQuadraticSmoothAbs_y_Setter(mthis, value) native "SVGPathSegCurvetoQuadraticSmoothAbs_y_Setter";

Native_SVGPathSegCurvetoQuadraticSmoothRel_x_Getter(mthis) native "SVGPathSegCurvetoQuadraticSmoothRel_x_Getter";

Native_SVGPathSegCurvetoQuadraticSmoothRel_x_Setter(mthis, value) native "SVGPathSegCurvetoQuadraticSmoothRel_x_Setter";

Native_SVGPathSegCurvetoQuadraticSmoothRel_y_Getter(mthis) native "SVGPathSegCurvetoQuadraticSmoothRel_y_Getter";

Native_SVGPathSegCurvetoQuadraticSmoothRel_y_Setter(mthis, value) native "SVGPathSegCurvetoQuadraticSmoothRel_y_Setter";

Native_SVGPathSegLinetoAbs_x_Getter(mthis) native "SVGPathSegLinetoAbs_x_Getter";

Native_SVGPathSegLinetoAbs_x_Setter(mthis, value) native "SVGPathSegLinetoAbs_x_Setter";

Native_SVGPathSegLinetoAbs_y_Getter(mthis) native "SVGPathSegLinetoAbs_y_Getter";

Native_SVGPathSegLinetoAbs_y_Setter(mthis, value) native "SVGPathSegLinetoAbs_y_Setter";

Native_SVGPathSegLinetoHorizontalAbs_x_Getter(mthis) native "SVGPathSegLinetoHorizontalAbs_x_Getter";

Native_SVGPathSegLinetoHorizontalAbs_x_Setter(mthis, value) native "SVGPathSegLinetoHorizontalAbs_x_Setter";

Native_SVGPathSegLinetoHorizontalRel_x_Getter(mthis) native "SVGPathSegLinetoHorizontalRel_x_Getter";

Native_SVGPathSegLinetoHorizontalRel_x_Setter(mthis, value) native "SVGPathSegLinetoHorizontalRel_x_Setter";

Native_SVGPathSegLinetoRel_x_Getter(mthis) native "SVGPathSegLinetoRel_x_Getter";

Native_SVGPathSegLinetoRel_x_Setter(mthis, value) native "SVGPathSegLinetoRel_x_Setter";

Native_SVGPathSegLinetoRel_y_Getter(mthis) native "SVGPathSegLinetoRel_y_Getter";

Native_SVGPathSegLinetoRel_y_Setter(mthis, value) native "SVGPathSegLinetoRel_y_Setter";

Native_SVGPathSegLinetoVerticalAbs_y_Getter(mthis) native "SVGPathSegLinetoVerticalAbs_y_Getter";

Native_SVGPathSegLinetoVerticalAbs_y_Setter(mthis, value) native "SVGPathSegLinetoVerticalAbs_y_Setter";

Native_SVGPathSegLinetoVerticalRel_y_Getter(mthis) native "SVGPathSegLinetoVerticalRel_y_Getter";

Native_SVGPathSegLinetoVerticalRel_y_Setter(mthis, value) native "SVGPathSegLinetoVerticalRel_y_Setter";

Native_SVGPathSegList_numberOfItems_Getter(mthis) native "SVGPathSegList_numberOfItems_Getter";

Native_SVGPathSegList_appendItem_Callback(mthis, newItem) native "SVGPathSegList_appendItem_Callback_RESOLVER_STRING_1_SVGPathSeg";

Native_SVGPathSegList_clear_Callback(mthis) native "SVGPathSegList_clear_Callback_RESOLVER_STRING_0_";

Native_SVGPathSegList_getItem_Callback(mthis, index) native "SVGPathSegList_getItem_Callback_RESOLVER_STRING_1_unsigned long";

Native_SVGPathSegList_initialize_Callback(mthis, newItem) native "SVGPathSegList_initialize_Callback_RESOLVER_STRING_1_SVGPathSeg";

Native_SVGPathSegList_insertItemBefore_Callback(mthis, newItem, index) native "SVGPathSegList_insertItemBefore_Callback_RESOLVER_STRING_2_SVGPathSeg_unsigned long";

Native_SVGPathSegList_removeItem_Callback(mthis, index) native "SVGPathSegList_removeItem_Callback_RESOLVER_STRING_1_unsigned long";

Native_SVGPathSegList_replaceItem_Callback(mthis, newItem, index) native "SVGPathSegList_replaceItem_Callback_RESOLVER_STRING_2_SVGPathSeg_unsigned long";

Native_SVGPathSegMovetoAbs_x_Getter(mthis) native "SVGPathSegMovetoAbs_x_Getter";

Native_SVGPathSegMovetoAbs_x_Setter(mthis, value) native "SVGPathSegMovetoAbs_x_Setter";

Native_SVGPathSegMovetoAbs_y_Getter(mthis) native "SVGPathSegMovetoAbs_y_Getter";

Native_SVGPathSegMovetoAbs_y_Setter(mthis, value) native "SVGPathSegMovetoAbs_y_Setter";

Native_SVGPathSegMovetoRel_x_Getter(mthis) native "SVGPathSegMovetoRel_x_Getter";

Native_SVGPathSegMovetoRel_x_Setter(mthis, value) native "SVGPathSegMovetoRel_x_Setter";

Native_SVGPathSegMovetoRel_y_Getter(mthis) native "SVGPathSegMovetoRel_y_Getter";

Native_SVGPathSegMovetoRel_y_Setter(mthis, value) native "SVGPathSegMovetoRel_y_Setter";

Native_SVGPatternElement_height_Getter(mthis) native "SVGPatternElement_height_Getter";

Native_SVGPatternElement_patternContentUnits_Getter(mthis) native "SVGPatternElement_patternContentUnits_Getter";

Native_SVGPatternElement_patternTransform_Getter(mthis) native "SVGPatternElement_patternTransform_Getter";

Native_SVGPatternElement_patternUnits_Getter(mthis) native "SVGPatternElement_patternUnits_Getter";

Native_SVGPatternElement_width_Getter(mthis) native "SVGPatternElement_width_Getter";

Native_SVGPatternElement_x_Getter(mthis) native "SVGPatternElement_x_Getter";

Native_SVGPatternElement_y_Getter(mthis) native "SVGPatternElement_y_Getter";

Native_SVGPatternElement_preserveAspectRatio_Getter(mthis) native "SVGPatternElement_preserveAspectRatio_Getter";

Native_SVGPatternElement_viewBox_Getter(mthis) native "SVGPatternElement_viewBox_Getter";

Native_SVGPatternElement_requiredExtensions_Getter(mthis) native "SVGPatternElement_requiredExtensions_Getter";

Native_SVGPatternElement_requiredFeatures_Getter(mthis) native "SVGPatternElement_requiredFeatures_Getter";

Native_SVGPatternElement_systemLanguage_Getter(mthis) native "SVGPatternElement_systemLanguage_Getter";

Native_SVGPatternElement_hasExtension_Callback(mthis, extension) native "SVGPatternElement_hasExtension_Callback_RESOLVER_STRING_1_DOMString";

Native_SVGPatternElement_href_Getter(mthis) native "SVGPatternElement_href_Getter";

Native_SVGPoint_x_Getter(mthis) native "SVGPoint_x_Getter";

Native_SVGPoint_x_Setter(mthis, value) native "SVGPoint_x_Setter";

Native_SVGPoint_y_Getter(mthis) native "SVGPoint_y_Getter";

Native_SVGPoint_y_Setter(mthis, value) native "SVGPoint_y_Setter";

Native_SVGPoint_matrixTransform_Callback(mthis, matrix) native "SVGPoint_matrixTransform_Callback_RESOLVER_STRING_1_SVGMatrix";

Native_SVGPointList_numberOfItems_Getter(mthis) native "SVGPointList_numberOfItems_Getter";

Native_SVGPointList_appendItem_Callback(mthis, item) native "SVGPointList_appendItem_Callback_RESOLVER_STRING_1_SVGPoint";

Native_SVGPointList_clear_Callback(mthis) native "SVGPointList_clear_Callback_RESOLVER_STRING_0_";

Native_SVGPointList_getItem_Callback(mthis, index) native "SVGPointList_getItem_Callback_RESOLVER_STRING_1_unsigned long";

Native_SVGPointList_initialize_Callback(mthis, item) native "SVGPointList_initialize_Callback_RESOLVER_STRING_1_SVGPoint";

Native_SVGPointList_insertItemBefore_Callback(mthis, item, index) native "SVGPointList_insertItemBefore_Callback_RESOLVER_STRING_2_SVGPoint_unsigned long";

Native_SVGPointList_removeItem_Callback(mthis, index) native "SVGPointList_removeItem_Callback_RESOLVER_STRING_1_unsigned long";

Native_SVGPointList_replaceItem_Callback(mthis, item, index) native "SVGPointList_replaceItem_Callback_RESOLVER_STRING_2_SVGPoint_unsigned long";

Native_SVGPolygonElement_animatedPoints_Getter(mthis) native "SVGPolygonElement_animatedPoints_Getter";

Native_SVGPolygonElement_points_Getter(mthis) native "SVGPolygonElement_points_Getter";

Native_SVGPolylineElement_animatedPoints_Getter(mthis) native "SVGPolylineElement_animatedPoints_Getter";

Native_SVGPolylineElement_points_Getter(mthis) native "SVGPolylineElement_points_Getter";

Native_SVGPreserveAspectRatio_align_Getter(mthis) native "SVGPreserveAspectRatio_align_Getter";

Native_SVGPreserveAspectRatio_align_Setter(mthis, value) native "SVGPreserveAspectRatio_align_Setter";

Native_SVGPreserveAspectRatio_meetOrSlice_Getter(mthis) native "SVGPreserveAspectRatio_meetOrSlice_Getter";

Native_SVGPreserveAspectRatio_meetOrSlice_Setter(mthis, value) native "SVGPreserveAspectRatio_meetOrSlice_Setter";

Native_SVGRadialGradientElement_cx_Getter(mthis) native "SVGRadialGradientElement_cx_Getter";

Native_SVGRadialGradientElement_cy_Getter(mthis) native "SVGRadialGradientElement_cy_Getter";

Native_SVGRadialGradientElement_fr_Getter(mthis) native "SVGRadialGradientElement_fr_Getter";

Native_SVGRadialGradientElement_fx_Getter(mthis) native "SVGRadialGradientElement_fx_Getter";

Native_SVGRadialGradientElement_fy_Getter(mthis) native "SVGRadialGradientElement_fy_Getter";

Native_SVGRadialGradientElement_r_Getter(mthis) native "SVGRadialGradientElement_r_Getter";

Native_SVGRect_height_Getter(mthis) native "SVGRect_height_Getter";

Native_SVGRect_height_Setter(mthis, value) native "SVGRect_height_Setter";

Native_SVGRect_width_Getter(mthis) native "SVGRect_width_Getter";

Native_SVGRect_width_Setter(mthis, value) native "SVGRect_width_Setter";

Native_SVGRect_x_Getter(mthis) native "SVGRect_x_Getter";

Native_SVGRect_x_Setter(mthis, value) native "SVGRect_x_Setter";

Native_SVGRect_y_Getter(mthis) native "SVGRect_y_Getter";

Native_SVGRect_y_Setter(mthis, value) native "SVGRect_y_Setter";

Native_SVGRectElement_height_Getter(mthis) native "SVGRectElement_height_Getter";

Native_SVGRectElement_rx_Getter(mthis) native "SVGRectElement_rx_Getter";

Native_SVGRectElement_ry_Getter(mthis) native "SVGRectElement_ry_Getter";

Native_SVGRectElement_width_Getter(mthis) native "SVGRectElement_width_Getter";

Native_SVGRectElement_x_Getter(mthis) native "SVGRectElement_x_Getter";

Native_SVGRectElement_y_Getter(mthis) native "SVGRectElement_y_Getter";

Native_SVGZoomAndPan_zoomAndPan_Getter(mthis) native "SVGZoomAndPan_zoomAndPan_Getter";

Native_SVGZoomAndPan_zoomAndPan_Setter(mthis, value) native "SVGZoomAndPan_zoomAndPan_Setter";

Native_SVGSVGElement_contentScriptType_Getter(mthis) native "SVGSVGElement_contentScriptType_Getter";

Native_SVGSVGElement_contentScriptType_Setter(mthis, value) native "SVGSVGElement_contentScriptType_Setter";

Native_SVGSVGElement_contentStyleType_Getter(mthis) native "SVGSVGElement_contentStyleType_Getter";

Native_SVGSVGElement_contentStyleType_Setter(mthis, value) native "SVGSVGElement_contentStyleType_Setter";

Native_SVGSVGElement_currentScale_Getter(mthis) native "SVGSVGElement_currentScale_Getter";

Native_SVGSVGElement_currentScale_Setter(mthis, value) native "SVGSVGElement_currentScale_Setter";

Native_SVGSVGElement_currentTranslate_Getter(mthis) native "SVGSVGElement_currentTranslate_Getter";

Native_SVGSVGElement_currentView_Getter(mthis) native "SVGSVGElement_currentView_Getter";

Native_SVGSVGElement_height_Getter(mthis) native "SVGSVGElement_height_Getter";

Native_SVGSVGElement_pixelUnitToMillimeterX_Getter(mthis) native "SVGSVGElement_pixelUnitToMillimeterX_Getter";

Native_SVGSVGElement_pixelUnitToMillimeterY_Getter(mthis) native "SVGSVGElement_pixelUnitToMillimeterY_Getter";

Native_SVGSVGElement_screenPixelToMillimeterX_Getter(mthis) native "SVGSVGElement_screenPixelToMillimeterX_Getter";

Native_SVGSVGElement_screenPixelToMillimeterY_Getter(mthis) native "SVGSVGElement_screenPixelToMillimeterY_Getter";

Native_SVGSVGElement_useCurrentView_Getter(mthis) native "SVGSVGElement_useCurrentView_Getter";

Native_SVGSVGElement_viewport_Getter(mthis) native "SVGSVGElement_viewport_Getter";

Native_SVGSVGElement_width_Getter(mthis) native "SVGSVGElement_width_Getter";

Native_SVGSVGElement_x_Getter(mthis) native "SVGSVGElement_x_Getter";

Native_SVGSVGElement_y_Getter(mthis) native "SVGSVGElement_y_Getter";

Native_SVGSVGElement_animationsPaused_Callback(mthis) native "SVGSVGElement_animationsPaused_Callback_RESOLVER_STRING_0_";

Native_SVGSVGElement_checkEnclosure_Callback(mthis, element, rect) native "SVGSVGElement_checkEnclosure_Callback_RESOLVER_STRING_2_SVGElement_SVGRect";

Native_SVGSVGElement_checkIntersection_Callback(mthis, element, rect) native "SVGSVGElement_checkIntersection_Callback_RESOLVER_STRING_2_SVGElement_SVGRect";

Native_SVGSVGElement_createSVGAngle_Callback(mthis) native "SVGSVGElement_createSVGAngle_Callback_RESOLVER_STRING_0_";

Native_SVGSVGElement_createSVGLength_Callback(mthis) native "SVGSVGElement_createSVGLength_Callback_RESOLVER_STRING_0_";

Native_SVGSVGElement_createSVGMatrix_Callback(mthis) native "SVGSVGElement_createSVGMatrix_Callback_RESOLVER_STRING_0_";

Native_SVGSVGElement_createSVGNumber_Callback(mthis) native "SVGSVGElement_createSVGNumber_Callback_RESOLVER_STRING_0_";

Native_SVGSVGElement_createSVGPoint_Callback(mthis) native "SVGSVGElement_createSVGPoint_Callback_RESOLVER_STRING_0_";

Native_SVGSVGElement_createSVGRect_Callback(mthis) native "SVGSVGElement_createSVGRect_Callback_RESOLVER_STRING_0_";

Native_SVGSVGElement_createSVGTransform_Callback(mthis) native "SVGSVGElement_createSVGTransform_Callback_RESOLVER_STRING_0_";

Native_SVGSVGElement_createSVGTransformFromMatrix_Callback(mthis, matrix) native "SVGSVGElement_createSVGTransformFromMatrix_Callback_RESOLVER_STRING_1_SVGMatrix";

Native_SVGSVGElement_deselectAll_Callback(mthis) native "SVGSVGElement_deselectAll_Callback_RESOLVER_STRING_0_";

Native_SVGSVGElement_forceRedraw_Callback(mthis) native "SVGSVGElement_forceRedraw_Callback_RESOLVER_STRING_0_";

Native_SVGSVGElement_getCurrentTime_Callback(mthis) native "SVGSVGElement_getCurrentTime_Callback_RESOLVER_STRING_0_";

Native_SVGSVGElement_getElementById_Callback(mthis, elementId) native "SVGSVGElement_getElementById_Callback_RESOLVER_STRING_1_DOMString";

Native_SVGSVGElement_getEnclosureList_Callback(mthis, rect, referenceElement) native "SVGSVGElement_getEnclosureList_Callback_RESOLVER_STRING_2_SVGRect_SVGElement";

Native_SVGSVGElement_getIntersectionList_Callback(mthis, rect, referenceElement) native "SVGSVGElement_getIntersectionList_Callback_RESOLVER_STRING_2_SVGRect_SVGElement";

Native_SVGSVGElement_pauseAnimations_Callback(mthis) native "SVGSVGElement_pauseAnimations_Callback_RESOLVER_STRING_0_";

Native_SVGSVGElement_setCurrentTime_Callback(mthis, seconds) native "SVGSVGElement_setCurrentTime_Callback_RESOLVER_STRING_1_float";

Native_SVGSVGElement_suspendRedraw_Callback(mthis, maxWaitMilliseconds) native "SVGSVGElement_suspendRedraw_Callback_RESOLVER_STRING_1_unsigned long";

Native_SVGSVGElement_unpauseAnimations_Callback(mthis) native "SVGSVGElement_unpauseAnimations_Callback_RESOLVER_STRING_0_";

Native_SVGSVGElement_unsuspendRedraw_Callback(mthis, suspendHandleId) native "SVGSVGElement_unsuspendRedraw_Callback_RESOLVER_STRING_1_unsigned long";

Native_SVGSVGElement_unsuspendRedrawAll_Callback(mthis) native "SVGSVGElement_unsuspendRedrawAll_Callback_RESOLVER_STRING_0_";

Native_SVGSVGElement_preserveAspectRatio_Getter(mthis) native "SVGSVGElement_preserveAspectRatio_Getter";

Native_SVGSVGElement_viewBox_Getter(mthis) native "SVGSVGElement_viewBox_Getter";

Native_SVGSVGElement_zoomAndPan_Getter(mthis) native "SVGSVGElement_zoomAndPan_Getter";

Native_SVGSVGElement_zoomAndPan_Setter(mthis, value) native "SVGSVGElement_zoomAndPan_Setter";

Native_SVGScriptElement_type_Getter(mthis) native "SVGScriptElement_type_Getter";

Native_SVGScriptElement_type_Setter(mthis, value) native "SVGScriptElement_type_Setter";

Native_SVGScriptElement_href_Getter(mthis) native "SVGScriptElement_href_Getter";

Native_SVGStopElement_offset_Getter(mthis) native "SVGStopElement_offset_Getter";

Native_SVGStringList_numberOfItems_Getter(mthis) native "SVGStringList_numberOfItems_Getter";

Native_SVGStringList_appendItem_Callback(mthis, item) native "SVGStringList_appendItem_Callback_RESOLVER_STRING_1_DOMString";

Native_SVGStringList_clear_Callback(mthis) native "SVGStringList_clear_Callback_RESOLVER_STRING_0_";

Native_SVGStringList_getItem_Callback(mthis, index) native "SVGStringList_getItem_Callback_RESOLVER_STRING_1_unsigned long";

Native_SVGStringList_initialize_Callback(mthis, item) native "SVGStringList_initialize_Callback_RESOLVER_STRING_1_DOMString";

Native_SVGStringList_insertItemBefore_Callback(mthis, item, index) native "SVGStringList_insertItemBefore_Callback_RESOLVER_STRING_2_DOMString_unsigned long";

Native_SVGStringList_removeItem_Callback(mthis, index) native "SVGStringList_removeItem_Callback_RESOLVER_STRING_1_unsigned long";

Native_SVGStringList_replaceItem_Callback(mthis, item, index) native "SVGStringList_replaceItem_Callback_RESOLVER_STRING_2_DOMString_unsigned long";

Native_SVGStyleElement_disabled_Getter(mthis) native "SVGStyleElement_disabled_Getter";

Native_SVGStyleElement_disabled_Setter(mthis, value) native "SVGStyleElement_disabled_Setter";

Native_SVGStyleElement_media_Getter(mthis) native "SVGStyleElement_media_Getter";

Native_SVGStyleElement_media_Setter(mthis, value) native "SVGStyleElement_media_Setter";

Native_SVGStyleElement_title_Getter(mthis) native "SVGStyleElement_title_Getter";

Native_SVGStyleElement_title_Setter(mthis, value) native "SVGStyleElement_title_Setter";

Native_SVGStyleElement_type_Getter(mthis) native "SVGStyleElement_type_Getter";

Native_SVGStyleElement_type_Setter(mthis, value) native "SVGStyleElement_type_Setter";

Native_SVGSymbolElement_preserveAspectRatio_Getter(mthis) native "SVGSymbolElement_preserveAspectRatio_Getter";

Native_SVGSymbolElement_viewBox_Getter(mthis) native "SVGSymbolElement_viewBox_Getter";

Native_SVGTextPathElement_method_Getter(mthis) native "SVGTextPathElement_method_Getter";

Native_SVGTextPathElement_spacing_Getter(mthis) native "SVGTextPathElement_spacing_Getter";

Native_SVGTextPathElement_startOffset_Getter(mthis) native "SVGTextPathElement_startOffset_Getter";

Native_SVGTextPathElement_href_Getter(mthis) native "SVGTextPathElement_href_Getter";

Native_SVGTransform_angle_Getter(mthis) native "SVGTransform_angle_Getter";

Native_SVGTransform_matrix_Getter(mthis) native "SVGTransform_matrix_Getter";

Native_SVGTransform_type_Getter(mthis) native "SVGTransform_type_Getter";

Native_SVGTransform_setMatrix_Callback(mthis, matrix) native "SVGTransform_setMatrix_Callback_RESOLVER_STRING_1_SVGMatrix";

Native_SVGTransform_setRotate_Callback(mthis, angle, cx, cy) native "SVGTransform_setRotate_Callback_RESOLVER_STRING_3_float_float_float";

Native_SVGTransform_setScale_Callback(mthis, sx, sy) native "SVGTransform_setScale_Callback_RESOLVER_STRING_2_float_float";

Native_SVGTransform_setSkewX_Callback(mthis, angle) native "SVGTransform_setSkewX_Callback_RESOLVER_STRING_1_float";

Native_SVGTransform_setSkewY_Callback(mthis, angle) native "SVGTransform_setSkewY_Callback_RESOLVER_STRING_1_float";

Native_SVGTransform_setTranslate_Callback(mthis, tx, ty) native "SVGTransform_setTranslate_Callback_RESOLVER_STRING_2_float_float";

Native_SVGTransformList_numberOfItems_Getter(mthis) native "SVGTransformList_numberOfItems_Getter";

Native_SVGTransformList_appendItem_Callback(mthis, item) native "SVGTransformList_appendItem_Callback_RESOLVER_STRING_1_SVGTransform";

Native_SVGTransformList_clear_Callback(mthis) native "SVGTransformList_clear_Callback_RESOLVER_STRING_0_";

Native_SVGTransformList_consolidate_Callback(mthis) native "SVGTransformList_consolidate_Callback_RESOLVER_STRING_0_";

Native_SVGTransformList_createSVGTransformFromMatrix_Callback(mthis, matrix) native "SVGTransformList_createSVGTransformFromMatrix_Callback_RESOLVER_STRING_1_SVGMatrix";

Native_SVGTransformList_getItem_Callback(mthis, index) native "SVGTransformList_getItem_Callback_RESOLVER_STRING_1_unsigned long";

Native_SVGTransformList_initialize_Callback(mthis, item) native "SVGTransformList_initialize_Callback_RESOLVER_STRING_1_SVGTransform";

Native_SVGTransformList_insertItemBefore_Callback(mthis, item, index) native "SVGTransformList_insertItemBefore_Callback_RESOLVER_STRING_2_SVGTransform_unsigned long";

Native_SVGTransformList_removeItem_Callback(mthis, index) native "SVGTransformList_removeItem_Callback_RESOLVER_STRING_1_unsigned long";

Native_SVGTransformList_replaceItem_Callback(mthis, item, index) native "SVGTransformList_replaceItem_Callback_RESOLVER_STRING_2_SVGTransform_unsigned long";

Native_SVGUseElement_animatedInstanceRoot_Getter(mthis) native "SVGUseElement_animatedInstanceRoot_Getter";

Native_SVGUseElement_height_Getter(mthis) native "SVGUseElement_height_Getter";

Native_SVGUseElement_instanceRoot_Getter(mthis) native "SVGUseElement_instanceRoot_Getter";

Native_SVGUseElement_width_Getter(mthis) native "SVGUseElement_width_Getter";

Native_SVGUseElement_x_Getter(mthis) native "SVGUseElement_x_Getter";

Native_SVGUseElement_y_Getter(mthis) native "SVGUseElement_y_Getter";

Native_SVGUseElement_requiredExtensions_Getter(mthis) native "SVGUseElement_requiredExtensions_Getter";

Native_SVGUseElement_requiredFeatures_Getter(mthis) native "SVGUseElement_requiredFeatures_Getter";

Native_SVGUseElement_systemLanguage_Getter(mthis) native "SVGUseElement_systemLanguage_Getter";

Native_SVGUseElement_hasExtension_Callback(mthis, extension) native "SVGUseElement_hasExtension_Callback_RESOLVER_STRING_1_DOMString";

Native_SVGUseElement_href_Getter(mthis) native "SVGUseElement_href_Getter";

Native_SVGViewElement_viewTarget_Getter(mthis) native "SVGViewElement_viewTarget_Getter";

Native_SVGViewElement_preserveAspectRatio_Getter(mthis) native "SVGViewElement_preserveAspectRatio_Getter";

Native_SVGViewElement_viewBox_Getter(mthis) native "SVGViewElement_viewBox_Getter";

Native_SVGViewElement_zoomAndPan_Getter(mthis) native "SVGViewElement_zoomAndPan_Getter";

Native_SVGViewElement_zoomAndPan_Setter(mthis, value) native "SVGViewElement_zoomAndPan_Setter";

Native_SVGViewSpec_preserveAspectRatioString_Getter(mthis) native "SVGViewSpec_preserveAspectRatioString_Getter";

Native_SVGViewSpec_transform_Getter(mthis) native "SVGViewSpec_transform_Getter";

Native_SVGViewSpec_transformString_Getter(mthis) native "SVGViewSpec_transformString_Getter";

Native_SVGViewSpec_viewBoxString_Getter(mthis) native "SVGViewSpec_viewBoxString_Getter";

Native_SVGViewSpec_viewTarget_Getter(mthis) native "SVGViewSpec_viewTarget_Getter";

Native_SVGViewSpec_viewTargetString_Getter(mthis) native "SVGViewSpec_viewTargetString_Getter";

Native_SVGViewSpec_preserveAspectRatio_Getter(mthis) native "SVGViewSpec_preserveAspectRatio_Getter";

Native_SVGViewSpec_viewBox_Getter(mthis) native "SVGViewSpec_viewBox_Getter";

Native_SVGViewSpec_zoomAndPan_Getter(mthis) native "SVGViewSpec_zoomAndPan_Getter";

Native_SVGViewSpec_zoomAndPan_Setter(mthis, value) native "SVGViewSpec_zoomAndPan_Setter";

Native_SVGZoomEvent_newScale_Getter(mthis) native "SVGZoomEvent_newScale_Getter";

Native_SVGZoomEvent_newTranslate_Getter(mthis) native "SVGZoomEvent_newTranslate_Getter";

Native_SVGZoomEvent_previousScale_Getter(mthis) native "SVGZoomEvent_previousScale_Getter";

Native_SVGZoomEvent_previousTranslate_Getter(mthis) native "SVGZoomEvent_previousTranslate_Getter";

Native_SVGZoomEvent_zoomRectScreen_Getter(mthis) native "SVGZoomEvent_zoomRectScreen_Getter";

Native_Screen_availHeight_Getter(mthis) native "Screen_availHeight_Getter";

Native_Screen_availLeft_Getter(mthis) native "Screen_availLeft_Getter";

Native_Screen_availTop_Getter(mthis) native "Screen_availTop_Getter";

Native_Screen_availWidth_Getter(mthis) native "Screen_availWidth_Getter";

Native_Screen_colorDepth_Getter(mthis) native "Screen_colorDepth_Getter";

Native_Screen_height_Getter(mthis) native "Screen_height_Getter";

Native_Screen_orientation_Getter(mthis) native "Screen_orientation_Getter";

Native_Screen_pixelDepth_Getter(mthis) native "Screen_pixelDepth_Getter";

Native_Screen_width_Getter(mthis) native "Screen_width_Getter";

Native_Screen_lockOrientation_Callback(mthis, orientation) native "Screen_lockOrientation_Callback_RESOLVER_STRING_1_DOMString";

Native_Screen_unlockOrientation_Callback(mthis) native "Screen_unlockOrientation_Callback_RESOLVER_STRING_0_";

Native_ScriptProcessorNode_bufferSize_Getter(mthis) native "ScriptProcessorNode_bufferSize_Getter";

Native_ScriptProcessorNode__setEventListener_Callback(mthis, eventListener) native "ScriptProcessorNode_setEventListener_Callback";

Native_SecurityPolicyViolationEvent_blockedURI_Getter(mthis) native "SecurityPolicyViolationEvent_blockedURI_Getter";

Native_SecurityPolicyViolationEvent_columnNumber_Getter(mthis) native "SecurityPolicyViolationEvent_columnNumber_Getter";

Native_SecurityPolicyViolationEvent_documentURI_Getter(mthis) native "SecurityPolicyViolationEvent_documentURI_Getter";

Native_SecurityPolicyViolationEvent_effectiveDirective_Getter(mthis) native "SecurityPolicyViolationEvent_effectiveDirective_Getter";

Native_SecurityPolicyViolationEvent_lineNumber_Getter(mthis) native "SecurityPolicyViolationEvent_lineNumber_Getter";

Native_SecurityPolicyViolationEvent_originalPolicy_Getter(mthis) native "SecurityPolicyViolationEvent_originalPolicy_Getter";

Native_SecurityPolicyViolationEvent_referrer_Getter(mthis) native "SecurityPolicyViolationEvent_referrer_Getter";

Native_SecurityPolicyViolationEvent_sourceFile_Getter(mthis) native "SecurityPolicyViolationEvent_sourceFile_Getter";

Native_SecurityPolicyViolationEvent_statusCode_Getter(mthis) native "SecurityPolicyViolationEvent_statusCode_Getter";

Native_SecurityPolicyViolationEvent_violatedDirective_Getter(mthis) native "SecurityPolicyViolationEvent_violatedDirective_Getter";

Native_Selection_anchorNode_Getter(mthis) native "Selection_anchorNode_Getter";

Native_Selection_anchorOffset_Getter(mthis) native "Selection_anchorOffset_Getter";

Native_Selection_baseNode_Getter(mthis) native "Selection_baseNode_Getter";

Native_Selection_baseOffset_Getter(mthis) native "Selection_baseOffset_Getter";

Native_Selection_extentNode_Getter(mthis) native "Selection_extentNode_Getter";

Native_Selection_extentOffset_Getter(mthis) native "Selection_extentOffset_Getter";

Native_Selection_focusNode_Getter(mthis) native "Selection_focusNode_Getter";

Native_Selection_focusOffset_Getter(mthis) native "Selection_focusOffset_Getter";

Native_Selection_isCollapsed_Getter(mthis) native "Selection_isCollapsed_Getter";

Native_Selection_rangeCount_Getter(mthis) native "Selection_rangeCount_Getter";

Native_Selection_type_Getter(mthis) native "Selection_type_Getter";

Native_Selection_addRange_Callback(mthis, range) native "Selection_addRange_Callback_RESOLVER_STRING_1_Range";

Native_Selection_collapse_Callback(mthis, node, index) native "Selection_collapse_Callback_RESOLVER_STRING_2_Node_long";

Native_Selection_collapseToEnd_Callback(mthis) native "Selection_collapseToEnd_Callback_RESOLVER_STRING_0_";

Native_Selection_collapseToStart_Callback(mthis) native "Selection_collapseToStart_Callback_RESOLVER_STRING_0_";

Native_Selection_containsNode_Callback(mthis, node, allowPartial) native "Selection_containsNode_Callback_RESOLVER_STRING_2_Node_boolean";

Native_Selection_deleteFromDocument_Callback(mthis) native "Selection_deleteFromDocument_Callback_RESOLVER_STRING_0_";

Native_Selection_empty_Callback(mthis) native "Selection_empty_Callback_RESOLVER_STRING_0_";

Native_Selection_extend_Callback(mthis, node, offset) native "Selection_extend_Callback_RESOLVER_STRING_2_Node_long";

Native_Selection_getRangeAt_Callback(mthis, index) native "Selection_getRangeAt_Callback_RESOLVER_STRING_1_long";

Native_Selection_modify_Callback(mthis, alter, direction, granularity) native "Selection_modify_Callback_RESOLVER_STRING_3_DOMString_DOMString_DOMString";

Native_Selection_removeAllRanges_Callback(mthis) native "Selection_removeAllRanges_Callback_RESOLVER_STRING_0_";

Native_Selection_selectAllChildren_Callback(mthis, node) native "Selection_selectAllChildren_Callback_RESOLVER_STRING_1_Node";

Native_Selection_setBaseAndExtent_Callback(mthis, baseNode, baseOffset, extentNode, extentOffset) native "Selection_setBaseAndExtent_Callback_RESOLVER_STRING_4_Node_long_Node_long";

Native_Selection_setPosition_Callback(mthis, node, offset) native "Selection_setPosition_Callback_RESOLVER_STRING_2_Node_long";

Native_Selection_toString_Callback(mthis) native "Selection_toString_Callback_RESOLVER_STRING_0_";

Native_ShadowRoot_activeElement_Getter(mthis) native "ShadowRoot_activeElement_Getter";

Native_ShadowRoot_applyAuthorStyles_Getter(mthis) native "ShadowRoot_applyAuthorStyles_Getter";

Native_ShadowRoot_applyAuthorStyles_Setter(mthis, value) native "ShadowRoot_applyAuthorStyles_Setter";

Native_ShadowRoot_host_Getter(mthis) native "ShadowRoot_host_Getter";

Native_ShadowRoot_innerHTML_Getter(mthis) native "ShadowRoot_innerHTML_Getter";

Native_ShadowRoot_innerHTML_Setter(mthis, value) native "ShadowRoot_innerHTML_Setter";

Native_ShadowRoot_olderShadowRoot_Getter(mthis) native "ShadowRoot_olderShadowRoot_Getter";

Native_ShadowRoot_resetStyleInheritance_Getter(mthis) native "ShadowRoot_resetStyleInheritance_Getter";

Native_ShadowRoot_resetStyleInheritance_Setter(mthis, value) native "ShadowRoot_resetStyleInheritance_Setter";

Native_ShadowRoot_styleSheets_Getter(mthis) native "ShadowRoot_styleSheets_Getter";

Native_ShadowRoot_cloneNode_Callback(mthis, deep) native "ShadowRoot_cloneNode_Callback_RESOLVER_STRING_1_boolean";

Native_ShadowRoot_elementFromPoint_Callback(mthis, x, y) native "ShadowRoot_elementFromPoint_Callback_RESOLVER_STRING_2_long_long";

Native_ShadowRoot_getElementById_Callback(mthis, elementId) native "ShadowRoot_getElementById_Callback_RESOLVER_STRING_1_DOMString";

Native_ShadowRoot_getElementsByClassName_Callback(mthis, className) native "ShadowRoot_getElementsByClassName_Callback_RESOLVER_STRING_1_DOMString";

Native_ShadowRoot_getElementsByTagName_Callback(mthis, tagName) native "ShadowRoot_getElementsByTagName_Callback_RESOLVER_STRING_1_DOMString";

Native_ShadowRoot_getSelection_Callback(mthis) native "ShadowRoot_getSelection_Callback_RESOLVER_STRING_0_";

  // Generated overload resolver
Native_SharedWorker_SharedWorker(scriptURL, name) {
    return Native_SharedWorker__create_1constructorCallback(scriptURL, name);
  }

Native_SharedWorker__create_1constructorCallback(scriptURL, name) native "SharedWorker_constructorCallback_RESOLVER_STRING_2_DOMString_DOMString";

Native_SharedWorker_port_Getter(mthis) native "SharedWorker_port_Getter";

Native_SharedWorker_workerStart_Getter(mthis) native "SharedWorker_workerStart_Getter";

Native_SharedWorkerGlobalScope_name_Getter(mthis) native "SharedWorkerGlobalScope_name_Getter";

Native_SourceBuffer_appendWindowEnd_Getter(mthis) native "SourceBuffer_appendWindowEnd_Getter";

Native_SourceBuffer_appendWindowEnd_Setter(mthis, value) native "SourceBuffer_appendWindowEnd_Setter";

Native_SourceBuffer_appendWindowStart_Getter(mthis) native "SourceBuffer_appendWindowStart_Getter";

Native_SourceBuffer_appendWindowStart_Setter(mthis, value) native "SourceBuffer_appendWindowStart_Setter";

Native_SourceBuffer_buffered_Getter(mthis) native "SourceBuffer_buffered_Getter";

Native_SourceBuffer_mode_Getter(mthis) native "SourceBuffer_mode_Getter";

Native_SourceBuffer_mode_Setter(mthis, value) native "SourceBuffer_mode_Setter";

Native_SourceBuffer_timestampOffset_Getter(mthis) native "SourceBuffer_timestampOffset_Getter";

Native_SourceBuffer_timestampOffset_Setter(mthis, value) native "SourceBuffer_timestampOffset_Setter";

Native_SourceBuffer_updating_Getter(mthis) native "SourceBuffer_updating_Getter";

Native_SourceBuffer_abort_Callback(mthis) native "SourceBuffer_abort_Callback_RESOLVER_STRING_0_";

Native_SourceBuffer_appendBuffer_Callback(mthis, data) native "SourceBuffer_appendBuffer_Callback_RESOLVER_STRING_1_ArrayBuffer";

  // Generated overload resolver
Native_SourceBuffer_appendStream(mthis, stream, maxSize) {
    if (maxSize != null) {
      Native_SourceBuffer__appendStream_1_Callback(mthis, stream, maxSize);
      return;
    }
    Native_SourceBuffer__appendStream_2_Callback(mthis, stream);
    return;
  }

Native_SourceBuffer__appendStream_1_Callback(mthis, stream, maxSize) native "SourceBuffer_appendStream_Callback_RESOLVER_STRING_2_Stream_unsigned long long";

Native_SourceBuffer__appendStream_2_Callback(mthis, stream) native "SourceBuffer_appendStream_Callback_RESOLVER_STRING_1_Stream";

Native_SourceBuffer_appendTypedData_Callback(mthis, data) native "SourceBuffer_appendBuffer_Callback_RESOLVER_STRING_1_ArrayBufferView";

Native_SourceBuffer_remove_Callback(mthis, start, end) native "SourceBuffer_remove_Callback_RESOLVER_STRING_2_double_double";

Native_SourceBufferList_length_Getter(mthis) native "SourceBufferList_length_Getter";

Native_SourceBufferList_NativeIndexed_Getter(mthis, index) native "SourceBufferList_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_SourceBufferList_item_Callback(mthis, index) native "SourceBufferList_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_SourceInfo_facing_Getter(mthis) native "SourceInfo_facing_Getter";

Native_SourceInfo_id_Getter(mthis) native "SourceInfo_id_Getter";

Native_SourceInfo_kind_Getter(mthis) native "SourceInfo_kind_Getter";

Native_SourceInfo_label_Getter(mthis) native "SourceInfo_label_Getter";

  // Generated overload resolver
Native_SpeechGrammar_SpeechGrammar() {
    return Native_SpeechGrammar__create_1constructorCallback();
  }

Native_SpeechGrammar__create_1constructorCallback() native "SpeechGrammar_constructorCallback_RESOLVER_STRING_0_";

Native_SpeechGrammar_src_Getter(mthis) native "SpeechGrammar_src_Getter";

Native_SpeechGrammar_src_Setter(mthis, value) native "SpeechGrammar_src_Setter";

Native_SpeechGrammar_weight_Getter(mthis) native "SpeechGrammar_weight_Getter";

Native_SpeechGrammar_weight_Setter(mthis, value) native "SpeechGrammar_weight_Setter";

  // Generated overload resolver
Native_SpeechGrammarList_SpeechGrammarList() {
    return Native_SpeechGrammarList__create_1constructorCallback();
  }

Native_SpeechGrammarList__create_1constructorCallback() native "SpeechGrammarList_constructorCallback_RESOLVER_STRING_0_";

Native_SpeechGrammarList_length_Getter(mthis) native "SpeechGrammarList_length_Getter";

Native_SpeechGrammarList_NativeIndexed_Getter(mthis, index) native "SpeechGrammarList_item_Callback_RESOLVER_STRING_1_unsigned long";

  // Generated overload resolver
Native_SpeechGrammarList_addFromString(mthis, string, weight) {
    if (weight != null) {
      Native_SpeechGrammarList__addFromString_1_Callback(mthis, string, weight);
      return;
    }
    Native_SpeechGrammarList__addFromString_2_Callback(mthis, string);
    return;
  }

Native_SpeechGrammarList__addFromString_1_Callback(mthis, string, weight) native "SpeechGrammarList_addFromString_Callback_RESOLVER_STRING_2_DOMString_float";

Native_SpeechGrammarList__addFromString_2_Callback(mthis, string) native "SpeechGrammarList_addFromString_Callback_RESOLVER_STRING_1_DOMString";

  // Generated overload resolver
Native_SpeechGrammarList_addFromUri(mthis, src, weight) {
    if (weight != null) {
      Native_SpeechGrammarList__addFromUri_1_Callback(mthis, src, weight);
      return;
    }
    Native_SpeechGrammarList__addFromUri_2_Callback(mthis, src);
    return;
  }

Native_SpeechGrammarList__addFromUri_1_Callback(mthis, src, weight) native "SpeechGrammarList_addFromUri_Callback_RESOLVER_STRING_2_DOMString_float";

Native_SpeechGrammarList__addFromUri_2_Callback(mthis, src) native "SpeechGrammarList_addFromUri_Callback_RESOLVER_STRING_1_DOMString";

Native_SpeechGrammarList_item_Callback(mthis, index) native "SpeechGrammarList_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_SpeechInputEvent_results_Getter(mthis) native "SpeechInputEvent_results_Getter";

Native_SpeechInputResult_confidence_Getter(mthis) native "SpeechInputResult_confidence_Getter";

Native_SpeechInputResult_utterance_Getter(mthis) native "SpeechInputResult_utterance_Getter";

Native_SpeechInputResultList_length_Getter(mthis) native "SpeechInputResultList_length_Getter";

Native_SpeechInputResultList_NativeIndexed_Getter(mthis, index) native "SpeechInputResultList_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_SpeechInputResultList_item_Callback(mthis, index) native "SpeechInputResultList_item_Callback_RESOLVER_STRING_1_unsigned long";

  // Generated overload resolver
Native_SpeechRecognition_SpeechRecognition() {
    return Native_SpeechRecognition__create_1constructorCallback();
  }

Native_SpeechRecognition__create_1constructorCallback() native "SpeechRecognition_constructorCallback_RESOLVER_STRING_0_";

Native_SpeechRecognition_continuous_Getter(mthis) native "SpeechRecognition_continuous_Getter";

Native_SpeechRecognition_continuous_Setter(mthis, value) native "SpeechRecognition_continuous_Setter";

Native_SpeechRecognition_grammars_Getter(mthis) native "SpeechRecognition_grammars_Getter";

Native_SpeechRecognition_grammars_Setter(mthis, value) native "SpeechRecognition_grammars_Setter";

Native_SpeechRecognition_interimResults_Getter(mthis) native "SpeechRecognition_interimResults_Getter";

Native_SpeechRecognition_interimResults_Setter(mthis, value) native "SpeechRecognition_interimResults_Setter";

Native_SpeechRecognition_lang_Getter(mthis) native "SpeechRecognition_lang_Getter";

Native_SpeechRecognition_lang_Setter(mthis, value) native "SpeechRecognition_lang_Setter";

Native_SpeechRecognition_maxAlternatives_Getter(mthis) native "SpeechRecognition_maxAlternatives_Getter";

Native_SpeechRecognition_maxAlternatives_Setter(mthis, value) native "SpeechRecognition_maxAlternatives_Setter";

Native_SpeechRecognition_abort_Callback(mthis) native "SpeechRecognition_abort_Callback_RESOLVER_STRING_0_";

Native_SpeechRecognition_start_Callback(mthis) native "SpeechRecognition_start_Callback_RESOLVER_STRING_0_";

Native_SpeechRecognition_stop_Callback(mthis) native "SpeechRecognition_stop_Callback_RESOLVER_STRING_0_";

Native_SpeechRecognitionAlternative_confidence_Getter(mthis) native "SpeechRecognitionAlternative_confidence_Getter";

Native_SpeechRecognitionAlternative_transcript_Getter(mthis) native "SpeechRecognitionAlternative_transcript_Getter";

Native_SpeechRecognitionError_error_Getter(mthis) native "SpeechRecognitionError_error_Getter";

Native_SpeechRecognitionError_message_Getter(mthis) native "SpeechRecognitionError_message_Getter";

Native_SpeechRecognitionEvent_emma_Getter(mthis) native "SpeechRecognitionEvent_emma_Getter";

Native_SpeechRecognitionEvent_interpretation_Getter(mthis) native "SpeechRecognitionEvent_interpretation_Getter";

Native_SpeechRecognitionEvent_resultIndex_Getter(mthis) native "SpeechRecognitionEvent_resultIndex_Getter";

Native_SpeechRecognitionEvent_results_Getter(mthis) native "SpeechRecognitionEvent_results_Getter";

Native_SpeechRecognitionResult_isFinal_Getter(mthis) native "SpeechRecognitionResult_isFinal_Getter";

Native_SpeechRecognitionResult_length_Getter(mthis) native "SpeechRecognitionResult_length_Getter";

Native_SpeechRecognitionResult_item_Callback(mthis, index) native "SpeechRecognitionResult_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_SpeechRecognitionResultList_length_Getter(mthis) native "SpeechRecognitionResultList_length_Getter";

Native_SpeechRecognitionResultList_NativeIndexed_Getter(mthis, index) native "SpeechRecognitionResultList_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_SpeechRecognitionResultList_item_Callback(mthis, index) native "SpeechRecognitionResultList_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_SpeechSynthesis_paused_Getter(mthis) native "SpeechSynthesis_paused_Getter";

Native_SpeechSynthesis_pending_Getter(mthis) native "SpeechSynthesis_pending_Getter";

Native_SpeechSynthesis_speaking_Getter(mthis) native "SpeechSynthesis_speaking_Getter";

Native_SpeechSynthesis_cancel_Callback(mthis) native "SpeechSynthesis_cancel_Callback_RESOLVER_STRING_0_";

Native_SpeechSynthesis_getVoices_Callback(mthis) native "SpeechSynthesis_getVoices_Callback_RESOLVER_STRING_0_";

Native_SpeechSynthesis_pause_Callback(mthis) native "SpeechSynthesis_pause_Callback_RESOLVER_STRING_0_";

Native_SpeechSynthesis_resume_Callback(mthis) native "SpeechSynthesis_resume_Callback_RESOLVER_STRING_0_";

Native_SpeechSynthesis_speak_Callback(mthis, utterance) native "SpeechSynthesis_speak_Callback_RESOLVER_STRING_1_SpeechSynthesisUtterance";

Native_SpeechSynthesisEvent_charIndex_Getter(mthis) native "SpeechSynthesisEvent_charIndex_Getter";

Native_SpeechSynthesisEvent_elapsedTime_Getter(mthis) native "SpeechSynthesisEvent_elapsedTime_Getter";

Native_SpeechSynthesisEvent_name_Getter(mthis) native "SpeechSynthesisEvent_name_Getter";

  // Generated overload resolver
Native_SpeechSynthesisUtterance_SpeechSynthesisUtterance(text) {
    return Native_SpeechSynthesisUtterance__create_1constructorCallback(text);
  }

Native_SpeechSynthesisUtterance__create_1constructorCallback(text) native "SpeechSynthesisUtterance_constructorCallback_RESOLVER_STRING_1_DOMString";

Native_SpeechSynthesisUtterance_lang_Getter(mthis) native "SpeechSynthesisUtterance_lang_Getter";

Native_SpeechSynthesisUtterance_lang_Setter(mthis, value) native "SpeechSynthesisUtterance_lang_Setter";

Native_SpeechSynthesisUtterance_pitch_Getter(mthis) native "SpeechSynthesisUtterance_pitch_Getter";

Native_SpeechSynthesisUtterance_pitch_Setter(mthis, value) native "SpeechSynthesisUtterance_pitch_Setter";

Native_SpeechSynthesisUtterance_rate_Getter(mthis) native "SpeechSynthesisUtterance_rate_Getter";

Native_SpeechSynthesisUtterance_rate_Setter(mthis, value) native "SpeechSynthesisUtterance_rate_Setter";

Native_SpeechSynthesisUtterance_text_Getter(mthis) native "SpeechSynthesisUtterance_text_Getter";

Native_SpeechSynthesisUtterance_text_Setter(mthis, value) native "SpeechSynthesisUtterance_text_Setter";

Native_SpeechSynthesisUtterance_voice_Getter(mthis) native "SpeechSynthesisUtterance_voice_Getter";

Native_SpeechSynthesisUtterance_voice_Setter(mthis, value) native "SpeechSynthesisUtterance_voice_Setter";

Native_SpeechSynthesisUtterance_volume_Getter(mthis) native "SpeechSynthesisUtterance_volume_Getter";

Native_SpeechSynthesisUtterance_volume_Setter(mthis, value) native "SpeechSynthesisUtterance_volume_Setter";

Native_SpeechSynthesisVoice_default_Getter(mthis) native "SpeechSynthesisVoice_default_Getter";

Native_SpeechSynthesisVoice_lang_Getter(mthis) native "SpeechSynthesisVoice_lang_Getter";

Native_SpeechSynthesisVoice_localService_Getter(mthis) native "SpeechSynthesisVoice_localService_Getter";

Native_SpeechSynthesisVoice_name_Getter(mthis) native "SpeechSynthesisVoice_name_Getter";

Native_SpeechSynthesisVoice_voiceURI_Getter(mthis) native "SpeechSynthesisVoice_voiceURI_Getter";

Native_Storage_length_Getter(mthis) native "Storage_length_Getter";

  // Generated overload resolver
Native_Storage___delete__(mthis, index_OR_name) {
    if ((index_OR_name is int || index_OR_name == null)) {
      return Native_Storage____delete___1_Callback(mthis, index_OR_name);
    }
    if ((index_OR_name is String || index_OR_name == null)) {
      return Native_Storage____delete___2_Callback(mthis, index_OR_name);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

Native_Storage____delete___1_Callback(mthis, index_OR_name) native "Storage___delete___Callback_RESOLVER_STRING_1_unsigned long";

Native_Storage____delete___2_Callback(mthis, index_OR_name) native "Storage___delete___Callback_RESOLVER_STRING_1_DOMString";

  // Generated overload resolver
Native_Storage___getter__(mthis, index_OR_name) {
    if ((index_OR_name is int || index_OR_name == null)) {
      return Native_Storage____getter___1_Callback(mthis, index_OR_name);
    }
    if ((index_OR_name is String || index_OR_name == null)) {
      return Native_Storage____getter___2_Callback(mthis, index_OR_name);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

Native_Storage____getter___1_Callback(mthis, index_OR_name) native "Storage___getter___Callback_RESOLVER_STRING_1_unsigned long";

Native_Storage____getter___2_Callback(mthis, index_OR_name) native "Storage___getter___Callback_RESOLVER_STRING_1_DOMString";

  // Generated overload resolver
Native_Storage___setter__(mthis, index_OR_name, value) {
    if ((value is String || value == null) && (index_OR_name is int || index_OR_name == null)) {
      Native_Storage____setter___1_Callback(mthis, index_OR_name, value);
      return;
    }
    if ((value is String || value == null) && (index_OR_name is String || index_OR_name == null)) {
      Native_Storage____setter___2_Callback(mthis, index_OR_name, value);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

Native_Storage____setter___1_Callback(mthis, index_OR_name, value) native "Storage___setter___Callback_RESOLVER_STRING_2_unsigned long_DOMString";

Native_Storage____setter___2_Callback(mthis, index_OR_name, value) native "Storage___setter___Callback_RESOLVER_STRING_2_DOMString_DOMString";

Native_Storage_clear_Callback(mthis) native "Storage_clear_Callback_RESOLVER_STRING_0_";

Native_Storage_getItem_Callback(mthis, key) native "Storage_getItem_Callback_RESOLVER_STRING_1_DOMString";

Native_Storage_key_Callback(mthis, index) native "Storage_key_Callback_RESOLVER_STRING_1_unsigned long";

Native_Storage_removeItem_Callback(mthis, key) native "Storage_removeItem_Callback_RESOLVER_STRING_1_DOMString";

Native_Storage_setItem_Callback(mthis, key, data) native "Storage_setItem_Callback_RESOLVER_STRING_2_DOMString_DOMString";

Native_StorageEvent_key_Getter(mthis) native "StorageEvent_key_Getter";

Native_StorageEvent_newValue_Getter(mthis) native "StorageEvent_newValue_Getter";

Native_StorageEvent_oldValue_Getter(mthis) native "StorageEvent_oldValue_Getter";

Native_StorageEvent_storageArea_Getter(mthis) native "StorageEvent_storageArea_Getter";

Native_StorageEvent_url_Getter(mthis) native "StorageEvent_url_Getter";

Native_StorageEvent_initStorageEvent_Callback(mthis, typeArg, canBubbleArg, cancelableArg, keyArg, oldValueArg, newValueArg, urlArg, storageAreaArg) native "StorageEvent_initStorageEvent_Callback_RESOLVER_STRING_8_DOMString_boolean_boolean_DOMString_DOMString_DOMString_DOMString_Storage";

Native_StorageInfo_quota_Getter(mthis) native "StorageInfo_quota_Getter";

Native_StorageInfo_usage_Getter(mthis) native "StorageInfo_usage_Getter";

Native_StorageQuota_supportedTypes_Getter(mthis) native "StorageQuota_supportedTypes_Getter";

Native_Stream_type_Getter(mthis) native "Stream_type_Getter";

Native_StyleMedia_type_Getter(mthis) native "StyleMedia_type_Getter";

Native_StyleMedia_matchMedium_Callback(mthis, mediaquery) native "StyleMedia_matchMedium_Callback_RESOLVER_STRING_1_DOMString";

Native_StyleSheetList_length_Getter(mthis) native "StyleSheetList_length_Getter";

Native_StyleSheetList_NativeIndexed_Getter(mthis, index) native "StyleSheetList_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_StyleSheetList___getter___Callback(mthis, name) native "StyleSheetList___getter___Callback_RESOLVER_STRING_1_DOMString";

Native_StyleSheetList_item_Callback(mthis, index) native "StyleSheetList_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_TextEvent_data_Getter(mthis) native "TextEvent_data_Getter";

Native_TextEvent_initTextEvent_Callback(mthis, typeArg, canBubbleArg, cancelableArg, viewArg, dataArg) native "TextEvent_initTextEvent_Callback_RESOLVER_STRING_5_DOMString_boolean_boolean_Window_DOMString";

Native_TextMetrics_width_Getter(mthis) native "TextMetrics_width_Getter";

Native_TextTrack_activeCues_Getter(mthis) native "TextTrack_activeCues_Getter";

Native_TextTrack_cues_Getter(mthis) native "TextTrack_cues_Getter";

Native_TextTrack_id_Getter(mthis) native "TextTrack_id_Getter";

Native_TextTrack_kind_Getter(mthis) native "TextTrack_kind_Getter";

Native_TextTrack_label_Getter(mthis) native "TextTrack_label_Getter";

Native_TextTrack_language_Getter(mthis) native "TextTrack_language_Getter";

Native_TextTrack_mode_Getter(mthis) native "TextTrack_mode_Getter";

Native_TextTrack_mode_Setter(mthis, value) native "TextTrack_mode_Setter";

Native_TextTrack_regions_Getter(mthis) native "TextTrack_regions_Getter";

Native_TextTrack_addCue_Callback(mthis, cue) native "TextTrack_addCue_Callback_RESOLVER_STRING_1_TextTrackCue";

Native_TextTrack_addRegion_Callback(mthis, region) native "TextTrack_addRegion_Callback_RESOLVER_STRING_1_VTTRegion";

Native_TextTrack_removeCue_Callback(mthis, cue) native "TextTrack_removeCue_Callback_RESOLVER_STRING_1_TextTrackCue";

Native_TextTrack_removeRegion_Callback(mthis, region) native "TextTrack_removeRegion_Callback_RESOLVER_STRING_1_VTTRegion";

Native_TextTrackCue_endTime_Getter(mthis) native "TextTrackCue_endTime_Getter";

Native_TextTrackCue_endTime_Setter(mthis, value) native "TextTrackCue_endTime_Setter";

Native_TextTrackCue_id_Getter(mthis) native "TextTrackCue_id_Getter";

Native_TextTrackCue_id_Setter(mthis, value) native "TextTrackCue_id_Setter";

Native_TextTrackCue_pauseOnExit_Getter(mthis) native "TextTrackCue_pauseOnExit_Getter";

Native_TextTrackCue_pauseOnExit_Setter(mthis, value) native "TextTrackCue_pauseOnExit_Setter";

Native_TextTrackCue_startTime_Getter(mthis) native "TextTrackCue_startTime_Getter";

Native_TextTrackCue_startTime_Setter(mthis, value) native "TextTrackCue_startTime_Setter";

Native_TextTrackCue_track_Getter(mthis) native "TextTrackCue_track_Getter";

Native_TextTrackCueList_length_Getter(mthis) native "TextTrackCueList_length_Getter";

Native_TextTrackCueList_NativeIndexed_Getter(mthis, index) native "TextTrackCueList_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_TextTrackCueList_getCueById_Callback(mthis, id) native "TextTrackCueList_getCueById_Callback_RESOLVER_STRING_1_DOMString";

Native_TextTrackCueList_item_Callback(mthis, index) native "TextTrackCueList_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_TextTrackList_length_Getter(mthis) native "TextTrackList_length_Getter";

Native_TextTrackList_NativeIndexed_Getter(mthis, index) native "TextTrackList_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_TextTrackList_getTrackById_Callback(mthis, id) native "TextTrackList_getTrackById_Callback_RESOLVER_STRING_1_DOMString";

Native_TextTrackList_item_Callback(mthis, index) native "TextTrackList_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_TimeRanges_length_Getter(mthis) native "TimeRanges_length_Getter";

Native_TimeRanges_end_Callback(mthis, index) native "TimeRanges_end_Callback_RESOLVER_STRING_1_unsigned long";

Native_TimeRanges_start_Callback(mthis, index) native "TimeRanges_start_Callback_RESOLVER_STRING_1_unsigned long";

Native_Timeline_play_Callback(mthis, source) native "Timeline_play_Callback_RESOLVER_STRING_1_TimedItem";

Native_Timing_delay_Getter(mthis) native "Timing_delay_Getter";

Native_Timing_delay_Setter(mthis, value) native "Timing_delay_Setter";

Native_Timing_direction_Getter(mthis) native "Timing_direction_Getter";

Native_Timing_direction_Setter(mthis, value) native "Timing_direction_Setter";

Native_Timing_easing_Getter(mthis) native "Timing_easing_Getter";

Native_Timing_easing_Setter(mthis, value) native "Timing_easing_Setter";

Native_Timing_endDelay_Getter(mthis) native "Timing_endDelay_Getter";

Native_Timing_endDelay_Setter(mthis, value) native "Timing_endDelay_Setter";

Native_Timing_fill_Getter(mthis) native "Timing_fill_Getter";

Native_Timing_fill_Setter(mthis, value) native "Timing_fill_Setter";

Native_Timing_iterationStart_Getter(mthis) native "Timing_iterationStart_Getter";

Native_Timing_iterationStart_Setter(mthis, value) native "Timing_iterationStart_Setter";

Native_Timing_iterations_Getter(mthis) native "Timing_iterations_Getter";

Native_Timing_iterations_Setter(mthis, value) native "Timing_iterations_Setter";

Native_Timing_playbackRate_Getter(mthis) native "Timing_playbackRate_Getter";

Native_Timing_playbackRate_Setter(mthis, value) native "Timing_playbackRate_Setter";

Native_Timing___setter___Callback(mthis, name, duration) native "Timing___setter___Callback_RESOLVER_STRING_2_DOMString_double";

Native_Touch_clientX_Getter(mthis) native "Touch_clientX_Getter";

Native_Touch_clientY_Getter(mthis) native "Touch_clientY_Getter";

Native_Touch_identifier_Getter(mthis) native "Touch_identifier_Getter";

Native_Touch_pageX_Getter(mthis) native "Touch_pageX_Getter";

Native_Touch_pageY_Getter(mthis) native "Touch_pageY_Getter";

Native_Touch_screenX_Getter(mthis) native "Touch_screenX_Getter";

Native_Touch_screenY_Getter(mthis) native "Touch_screenY_Getter";

Native_Touch_target_Getter(mthis) native "Touch_target_Getter";

Native_Touch_webkitForce_Getter(mthis) native "Touch_webkitForce_Getter";

Native_Touch_webkitRadiusX_Getter(mthis) native "Touch_webkitRadiusX_Getter";

Native_Touch_webkitRadiusY_Getter(mthis) native "Touch_webkitRadiusY_Getter";

Native_Touch_webkitRotationAngle_Getter(mthis) native "Touch_webkitRotationAngle_Getter";

Native_TouchEvent_altKey_Getter(mthis) native "TouchEvent_altKey_Getter";

Native_TouchEvent_changedTouches_Getter(mthis) native "TouchEvent_changedTouches_Getter";

Native_TouchEvent_ctrlKey_Getter(mthis) native "TouchEvent_ctrlKey_Getter";

Native_TouchEvent_metaKey_Getter(mthis) native "TouchEvent_metaKey_Getter";

Native_TouchEvent_shiftKey_Getter(mthis) native "TouchEvent_shiftKey_Getter";

Native_TouchEvent_targetTouches_Getter(mthis) native "TouchEvent_targetTouches_Getter";

Native_TouchEvent_touches_Getter(mthis) native "TouchEvent_touches_Getter";

Native_TouchEvent_initTouchEvent_Callback(mthis, touches, targetTouches, changedTouches, type, view, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey) native "TouchEvent_initTouchEvent_Callback_RESOLVER_STRING_13_TouchList_TouchList_TouchList_DOMString_Window_long_long_long_long_boolean_boolean_boolean_boolean";

Native_TouchList_length_Getter(mthis) native "TouchList_length_Getter";

Native_TouchList_NativeIndexed_Getter(mthis, index) native "TouchList_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_TouchList_item_Callback(mthis, index) native "TouchList_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_TrackEvent_track_Getter(mthis) native "TrackEvent_track_Getter";

Native_TransitionEvent_elapsedTime_Getter(mthis) native "TransitionEvent_elapsedTime_Getter";

Native_TransitionEvent_propertyName_Getter(mthis) native "TransitionEvent_propertyName_Getter";

Native_TransitionEvent_pseudoElement_Getter(mthis) native "TransitionEvent_pseudoElement_Getter";

Native_TreeWalker_currentNode_Getter(mthis) native "TreeWalker_currentNode_Getter";

Native_TreeWalker_currentNode_Setter(mthis, value) native "TreeWalker_currentNode_Setter";

Native_TreeWalker_filter_Getter(mthis) native "TreeWalker_filter_Getter";

Native_TreeWalker_root_Getter(mthis) native "TreeWalker_root_Getter";

Native_TreeWalker_whatToShow_Getter(mthis) native "TreeWalker_whatToShow_Getter";

Native_TreeWalker_firstChild_Callback(mthis) native "TreeWalker_firstChild_Callback_RESOLVER_STRING_0_";

Native_TreeWalker_lastChild_Callback(mthis) native "TreeWalker_lastChild_Callback_RESOLVER_STRING_0_";

Native_TreeWalker_nextNode_Callback(mthis) native "TreeWalker_nextNode_Callback_RESOLVER_STRING_0_";

Native_TreeWalker_nextSibling_Callback(mthis) native "TreeWalker_nextSibling_Callback_RESOLVER_STRING_0_";

Native_TreeWalker_parentNode_Callback(mthis) native "TreeWalker_parentNode_Callback_RESOLVER_STRING_0_";

Native_TreeWalker_previousNode_Callback(mthis) native "TreeWalker_previousNode_Callback_RESOLVER_STRING_0_";

Native_TreeWalker_previousSibling_Callback(mthis) native "TreeWalker_previousSibling_Callback_RESOLVER_STRING_0_";

  // Generated overload resolver
Native_URL_createObjectUrl(blob_OR_source_OR_stream) {
    if ((blob_OR_source_OR_stream is Blob || blob_OR_source_OR_stream == null)) {
      return Native_URL__createObjectURL_1_Callback(blob_OR_source_OR_stream);
    }
    if ((blob_OR_source_OR_stream is MediaStream || blob_OR_source_OR_stream == null)) {
      return Native_URL__createObjectURL_2_Callback(blob_OR_source_OR_stream);
    }
    if ((blob_OR_source_OR_stream is MediaSource || blob_OR_source_OR_stream == null)) {
      return Native_URL__createObjectURL_3_Callback(blob_OR_source_OR_stream);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

Native_URL__createObjectURL_1_Callback(blob_OR_source_OR_stream) native "URL_createObjectURL_Callback_RESOLVER_STRING_1_Blob";

Native_URL__createObjectURL_2_Callback(blob_OR_source_OR_stream) native "URL_createObjectURL_Callback_RESOLVER_STRING_1_MediaStream";

Native_URL__createObjectURL_3_Callback(blob_OR_source_OR_stream) native "URL_createObjectURL_Callback_RESOLVER_STRING_1_MediaSource";

Native_URL_createObjectUrlFromBlob_Callback(blob) native "URL_createObjectURL_Callback_RESOLVER_STRING_1_Blob";

Native_URL_createObjectUrlFromSource_Callback(source) native "URL_createObjectURL_Callback_RESOLVER_STRING_1_MediaSource";

Native_URL_createObjectUrlFromStream_Callback(stream) native "URL_createObjectURL_Callback_RESOLVER_STRING_1_MediaStream";

Native_URL_revokeObjectURL_Callback(url) native "URL_revokeObjectURL_Callback_RESOLVER_STRING_1_DOMString";

Native_URL_hash_Getter(mthis) native "URL_hash_Getter";

Native_URL_hash_Setter(mthis, value) native "URL_hash_Setter";

Native_URL_host_Getter(mthis) native "URL_host_Getter";

Native_URL_host_Setter(mthis, value) native "URL_host_Setter";

Native_URL_hostname_Getter(mthis) native "URL_hostname_Getter";

Native_URL_hostname_Setter(mthis, value) native "URL_hostname_Setter";

Native_URL_href_Getter(mthis) native "URL_href_Getter";

Native_URL_href_Setter(mthis, value) native "URL_href_Setter";

Native_URL_origin_Getter(mthis) native "URL_origin_Getter";

Native_URL_password_Getter(mthis) native "URL_password_Getter";

Native_URL_password_Setter(mthis, value) native "URL_password_Setter";

Native_URL_pathname_Getter(mthis) native "URL_pathname_Getter";

Native_URL_pathname_Setter(mthis, value) native "URL_pathname_Setter";

Native_URL_port_Getter(mthis) native "URL_port_Getter";

Native_URL_port_Setter(mthis, value) native "URL_port_Setter";

Native_URL_protocol_Getter(mthis) native "URL_protocol_Getter";

Native_URL_protocol_Setter(mthis, value) native "URL_protocol_Setter";

Native_URL_search_Getter(mthis) native "URL_search_Getter";

Native_URL_search_Setter(mthis, value) native "URL_search_Setter";

Native_URL_username_Getter(mthis) native "URL_username_Getter";

Native_URL_username_Setter(mthis, value) native "URL_username_Setter";

Native_URL_toString_Callback(mthis) native "URL_toString_Callback_RESOLVER_STRING_0_";

Native_URLUtilsReadOnly_hash_Getter(mthis) native "WorkerLocation_hash_Getter";

Native_URLUtilsReadOnly_host_Getter(mthis) native "WorkerLocation_host_Getter";

Native_URLUtilsReadOnly_hostname_Getter(mthis) native "WorkerLocation_hostname_Getter";

Native_URLUtilsReadOnly_href_Getter(mthis) native "WorkerLocation_href_Getter";

Native_URLUtilsReadOnly_pathname_Getter(mthis) native "WorkerLocation_pathname_Getter";

Native_URLUtilsReadOnly_port_Getter(mthis) native "WorkerLocation_port_Getter";

Native_URLUtilsReadOnly_protocol_Getter(mthis) native "WorkerLocation_protocol_Getter";

Native_URLUtilsReadOnly_search_Getter(mthis) native "WorkerLocation_search_Getter";

Native_URLUtilsReadOnly_toString_Callback(mthis) native "WorkerLocation_toString_Callback_RESOLVER_STRING_0_";

  // Generated overload resolver
Native_VTTCue_VttCue(startTime, endTime, text) {
    return Native_VTTCue__create_1constructorCallback(startTime, endTime, text);
  }

Native_VTTCue__create_1constructorCallback(startTime, endTime, text) native "VTTCue_constructorCallback_RESOLVER_STRING_3_double_double_DOMString";

Native_VTTCue_align_Getter(mthis) native "VTTCue_align_Getter";

Native_VTTCue_align_Setter(mthis, value) native "VTTCue_align_Setter";

Native_VTTCue_line_Getter(mthis) native "VTTCue_line_Getter";

Native_VTTCue_line_Setter(mthis, value) native "VTTCue_line_Setter";

Native_VTTCue_position_Getter(mthis) native "VTTCue_position_Getter";

Native_VTTCue_position_Setter(mthis, value) native "VTTCue_position_Setter";

Native_VTTCue_regionId_Getter(mthis) native "VTTCue_regionId_Getter";

Native_VTTCue_regionId_Setter(mthis, value) native "VTTCue_regionId_Setter";

Native_VTTCue_size_Getter(mthis) native "VTTCue_size_Getter";

Native_VTTCue_size_Setter(mthis, value) native "VTTCue_size_Setter";

Native_VTTCue_snapToLines_Getter(mthis) native "VTTCue_snapToLines_Getter";

Native_VTTCue_snapToLines_Setter(mthis, value) native "VTTCue_snapToLines_Setter";

Native_VTTCue_text_Getter(mthis) native "VTTCue_text_Getter";

Native_VTTCue_text_Setter(mthis, value) native "VTTCue_text_Setter";

Native_VTTCue_vertical_Getter(mthis) native "VTTCue_vertical_Getter";

Native_VTTCue_vertical_Setter(mthis, value) native "VTTCue_vertical_Setter";

Native_VTTCue_getCueAsHTML_Callback(mthis) native "VTTCue_getCueAsHTML_Callback_RESOLVER_STRING_0_";

  // Generated overload resolver
Native_VTTRegion_VttRegion() {
    return Native_VTTRegion__create_1constructorCallback();
  }

Native_VTTRegion__create_1constructorCallback() native "VTTRegion_constructorCallback_RESOLVER_STRING_0_";

Native_VTTRegion_height_Getter(mthis) native "VTTRegion_height_Getter";

Native_VTTRegion_height_Setter(mthis, value) native "VTTRegion_height_Setter";

Native_VTTRegion_id_Getter(mthis) native "VTTRegion_id_Getter";

Native_VTTRegion_id_Setter(mthis, value) native "VTTRegion_id_Setter";

Native_VTTRegion_regionAnchorX_Getter(mthis) native "VTTRegion_regionAnchorX_Getter";

Native_VTTRegion_regionAnchorX_Setter(mthis, value) native "VTTRegion_regionAnchorX_Setter";

Native_VTTRegion_regionAnchorY_Getter(mthis) native "VTTRegion_regionAnchorY_Getter";

Native_VTTRegion_regionAnchorY_Setter(mthis, value) native "VTTRegion_regionAnchorY_Setter";

Native_VTTRegion_scroll_Getter(mthis) native "VTTRegion_scroll_Getter";

Native_VTTRegion_scroll_Setter(mthis, value) native "VTTRegion_scroll_Setter";

Native_VTTRegion_track_Getter(mthis) native "VTTRegion_track_Getter";

Native_VTTRegion_viewportAnchorX_Getter(mthis) native "VTTRegion_viewportAnchorX_Getter";

Native_VTTRegion_viewportAnchorX_Setter(mthis, value) native "VTTRegion_viewportAnchorX_Setter";

Native_VTTRegion_viewportAnchorY_Getter(mthis) native "VTTRegion_viewportAnchorY_Getter";

Native_VTTRegion_viewportAnchorY_Setter(mthis, value) native "VTTRegion_viewportAnchorY_Setter";

Native_VTTRegion_width_Getter(mthis) native "VTTRegion_width_Getter";

Native_VTTRegion_width_Setter(mthis, value) native "VTTRegion_width_Setter";

Native_VTTRegionList_length_Getter(mthis) native "VTTRegionList_length_Getter";

Native_VTTRegionList_getRegionById_Callback(mthis, id) native "VTTRegionList_getRegionById_Callback_RESOLVER_STRING_1_DOMString";

Native_VTTRegionList_item_Callback(mthis, index) native "VTTRegionList_item_Callback_RESOLVER_STRING_1_unsigned long";

Native_ValidityState_badInput_Getter(mthis) native "ValidityState_badInput_Getter";

Native_ValidityState_customError_Getter(mthis) native "ValidityState_customError_Getter";

Native_ValidityState_patternMismatch_Getter(mthis) native "ValidityState_patternMismatch_Getter";

Native_ValidityState_rangeOverflow_Getter(mthis) native "ValidityState_rangeOverflow_Getter";

Native_ValidityState_rangeUnderflow_Getter(mthis) native "ValidityState_rangeUnderflow_Getter";

Native_ValidityState_stepMismatch_Getter(mthis) native "ValidityState_stepMismatch_Getter";

Native_ValidityState_tooLong_Getter(mthis) native "ValidityState_tooLong_Getter";

Native_ValidityState_typeMismatch_Getter(mthis) native "ValidityState_typeMismatch_Getter";

Native_ValidityState_valid_Getter(mthis) native "ValidityState_valid_Getter";

Native_ValidityState_valueMissing_Getter(mthis) native "ValidityState_valueMissing_Getter";

Native_VideoPlaybackQuality_corruptedVideoFrames_Getter(mthis) native "VideoPlaybackQuality_corruptedVideoFrames_Getter";

Native_VideoPlaybackQuality_creationTime_Getter(mthis) native "VideoPlaybackQuality_creationTime_Getter";

Native_VideoPlaybackQuality_droppedVideoFrames_Getter(mthis) native "VideoPlaybackQuality_droppedVideoFrames_Getter";

Native_VideoPlaybackQuality_totalVideoFrames_Getter(mthis) native "VideoPlaybackQuality_totalVideoFrames_Getter";

Native_WaveShaperNode_curve_Getter(mthis) native "WaveShaperNode_curve_Getter";

Native_WaveShaperNode_curve_Setter(mthis, value) native "WaveShaperNode_curve_Setter";

Native_WaveShaperNode_oversample_Getter(mthis) native "WaveShaperNode_oversample_Getter";

Native_WaveShaperNode_oversample_Setter(mthis, value) native "WaveShaperNode_oversample_Setter";

Native_WebGLActiveInfo_name_Getter(mthis) native "WebGLActiveInfo_name_Getter";

Native_WebGLActiveInfo_size_Getter(mthis) native "WebGLActiveInfo_size_Getter";

Native_WebGLActiveInfo_type_Getter(mthis) native "WebGLActiveInfo_type_Getter";

Native_WebGLContextAttributes_alpha_Getter(mthis) native "WebGLContextAttributes_alpha_Getter";

Native_WebGLContextAttributes_alpha_Setter(mthis, value) native "WebGLContextAttributes_alpha_Setter";

Native_WebGLContextAttributes_antialias_Getter(mthis) native "WebGLContextAttributes_antialias_Getter";

Native_WebGLContextAttributes_antialias_Setter(mthis, value) native "WebGLContextAttributes_antialias_Setter";

Native_WebGLContextAttributes_depth_Getter(mthis) native "WebGLContextAttributes_depth_Getter";

Native_WebGLContextAttributes_depth_Setter(mthis, value) native "WebGLContextAttributes_depth_Setter";

Native_WebGLContextAttributes_failIfMajorPerformanceCaveat_Getter(mthis) native "WebGLContextAttributes_failIfMajorPerformanceCaveat_Getter";

Native_WebGLContextAttributes_failIfMajorPerformanceCaveat_Setter(mthis, value) native "WebGLContextAttributes_failIfMajorPerformanceCaveat_Setter";

Native_WebGLContextAttributes_premultipliedAlpha_Getter(mthis) native "WebGLContextAttributes_premultipliedAlpha_Getter";

Native_WebGLContextAttributes_premultipliedAlpha_Setter(mthis, value) native "WebGLContextAttributes_premultipliedAlpha_Setter";

Native_WebGLContextAttributes_preserveDrawingBuffer_Getter(mthis) native "WebGLContextAttributes_preserveDrawingBuffer_Getter";

Native_WebGLContextAttributes_preserveDrawingBuffer_Setter(mthis, value) native "WebGLContextAttributes_preserveDrawingBuffer_Setter";

Native_WebGLContextAttributes_stencil_Getter(mthis) native "WebGLContextAttributes_stencil_Getter";

Native_WebGLContextAttributes_stencil_Setter(mthis, value) native "WebGLContextAttributes_stencil_Setter";

Native_WebGLContextEvent_statusMessage_Getter(mthis) native "WebGLContextEvent_statusMessage_Getter";

Native_WebGLDebugShaders_getTranslatedShaderSource_Callback(mthis, shader) native "WebGLDebugShaders_getTranslatedShaderSource_Callback_RESOLVER_STRING_1_WebGLShader";

Native_WebGLDrawBuffers_drawBuffersWEBGL_Callback(mthis, buffers) native "WebGLDrawBuffers_drawBuffersWEBGL_Callback_RESOLVER_STRING_1_sequence<unsigned long>";

Native_WebGLLoseContext_loseContext_Callback(mthis) native "WebGLLoseContext_loseContext_Callback_RESOLVER_STRING_0_";

Native_WebGLLoseContext_restoreContext_Callback(mthis) native "WebGLLoseContext_restoreContext_Callback_RESOLVER_STRING_0_";

Native_WebGLRenderingContext_drawingBufferHeight_Getter(mthis) native "WebGLRenderingContext_drawingBufferHeight_Getter";

Native_WebGLRenderingContext_drawingBufferWidth_Getter(mthis) native "WebGLRenderingContext_drawingBufferWidth_Getter";

Native_WebGLRenderingContext_activeTexture_Callback(mthis, texture) native "WebGLRenderingContext_activeTexture_Callback_RESOLVER_STRING_1_unsigned long";

Native_WebGLRenderingContext_attachShader_Callback(mthis, program, shader) native "WebGLRenderingContext_attachShader_Callback_RESOLVER_STRING_2_WebGLProgram_WebGLShader";

Native_WebGLRenderingContext_bindAttribLocation_Callback(mthis, program, index, name) native "WebGLRenderingContext_bindAttribLocation_Callback_RESOLVER_STRING_3_WebGLProgram_unsigned long_DOMString";

Native_WebGLRenderingContext_bindBuffer_Callback(mthis, target, buffer) native "WebGLRenderingContext_bindBuffer_Callback_RESOLVER_STRING_2_unsigned long_WebGLBuffer";

Native_WebGLRenderingContext_bindFramebuffer_Callback(mthis, target, framebuffer) native "WebGLRenderingContext_bindFramebuffer_Callback_RESOLVER_STRING_2_unsigned long_WebGLFramebuffer";

Native_WebGLRenderingContext_bindRenderbuffer_Callback(mthis, target, renderbuffer) native "WebGLRenderingContext_bindRenderbuffer_Callback_RESOLVER_STRING_2_unsigned long_WebGLRenderbuffer";

Native_WebGLRenderingContext_bindTexture_Callback(mthis, target, texture) native "WebGLRenderingContext_bindTexture_Callback_RESOLVER_STRING_2_unsigned long_WebGLTexture";

Native_WebGLRenderingContext_blendColor_Callback(mthis, red, green, blue, alpha) native "WebGLRenderingContext_blendColor_Callback_RESOLVER_STRING_4_float_float_float_float";

Native_WebGLRenderingContext_blendEquation_Callback(mthis, mode) native "WebGLRenderingContext_blendEquation_Callback_RESOLVER_STRING_1_unsigned long";

Native_WebGLRenderingContext_blendEquationSeparate_Callback(mthis, modeRGB, modeAlpha) native "WebGLRenderingContext_blendEquationSeparate_Callback_RESOLVER_STRING_2_unsigned long_unsigned long";

Native_WebGLRenderingContext_blendFunc_Callback(mthis, sfactor, dfactor) native "WebGLRenderingContext_blendFunc_Callback_RESOLVER_STRING_2_unsigned long_unsigned long";

Native_WebGLRenderingContext_blendFuncSeparate_Callback(mthis, srcRGB, dstRGB, srcAlpha, dstAlpha) native "WebGLRenderingContext_blendFuncSeparate_Callback_RESOLVER_STRING_4_unsigned long_unsigned long_unsigned long_unsigned long";

Native_WebGLRenderingContext_bufferByteData_Callback(mthis, target, data, usage) native "WebGLRenderingContext_bufferData_Callback_RESOLVER_STRING_3_unsigned long_ArrayBuffer_unsigned long";

  // Generated overload resolver
Native_WebGLRenderingContext_bufferData(mthis, target, data_OR_size, usage) {
    if ((usage is int || usage == null) && (data_OR_size is TypedData || data_OR_size == null) && (target is int || target == null)) {
      Native_WebGLRenderingContext__bufferData_1_Callback(mthis, target, data_OR_size, usage);
      return;
    }
    if ((usage is int || usage == null) && (data_OR_size is ByteBuffer || data_OR_size == null) && (target is int || target == null)) {
      Native_WebGLRenderingContext__bufferData_2_Callback(mthis, target, data_OR_size, usage);
      return;
    }
    if ((usage is int || usage == null) && (data_OR_size is int || data_OR_size == null) && (target is int || target == null)) {
      Native_WebGLRenderingContext__bufferData_3_Callback(mthis, target, data_OR_size, usage);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

Native_WebGLRenderingContext__bufferData_1_Callback(mthis, target, data_OR_size, usage) native "WebGLRenderingContext_bufferData_Callback_RESOLVER_STRING_3_unsigned long_ArrayBufferView_unsigned long";

Native_WebGLRenderingContext__bufferData_2_Callback(mthis, target, data_OR_size, usage) native "WebGLRenderingContext_bufferData_Callback_RESOLVER_STRING_3_unsigned long_ArrayBuffer_unsigned long";

Native_WebGLRenderingContext__bufferData_3_Callback(mthis, target, data_OR_size, usage) native "WebGLRenderingContext_bufferData_Callback_RESOLVER_STRING_3_unsigned long_long long_unsigned long";

Native_WebGLRenderingContext_bufferDataTyped_Callback(mthis, target, data, usage) native "WebGLRenderingContext_bufferData_Callback_RESOLVER_STRING_3_unsigned long_ArrayBufferView_unsigned long";

Native_WebGLRenderingContext_bufferSubByteData_Callback(mthis, target, offset, data) native "WebGLRenderingContext_bufferSubData_Callback_RESOLVER_STRING_3_unsigned long_long long_ArrayBuffer";

  // Generated overload resolver
Native_WebGLRenderingContext_bufferSubData(mthis, target, offset, data) {
    if ((data is TypedData || data == null) && (offset is int || offset == null) && (target is int || target == null)) {
      Native_WebGLRenderingContext__bufferSubData_1_Callback(mthis, target, offset, data);
      return;
    }
    if ((data is ByteBuffer || data == null) && (offset is int || offset == null) && (target is int || target == null)) {
      Native_WebGLRenderingContext__bufferSubData_2_Callback(mthis, target, offset, data);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

Native_WebGLRenderingContext__bufferSubData_1_Callback(mthis, target, offset, data) native "WebGLRenderingContext_bufferSubData_Callback_RESOLVER_STRING_3_unsigned long_long long_ArrayBufferView";

Native_WebGLRenderingContext__bufferSubData_2_Callback(mthis, target, offset, data) native "WebGLRenderingContext_bufferSubData_Callback_RESOLVER_STRING_3_unsigned long_long long_ArrayBuffer";

Native_WebGLRenderingContext_bufferSubDataTyped_Callback(mthis, target, offset, data) native "WebGLRenderingContext_bufferSubData_Callback_RESOLVER_STRING_3_unsigned long_long long_ArrayBufferView";

Native_WebGLRenderingContext_checkFramebufferStatus_Callback(mthis, target) native "WebGLRenderingContext_checkFramebufferStatus_Callback_RESOLVER_STRING_1_unsigned long";

Native_WebGLRenderingContext_clear_Callback(mthis, mask) native "WebGLRenderingContext_clear_Callback_RESOLVER_STRING_1_unsigned long";

Native_WebGLRenderingContext_clearColor_Callback(mthis, red, green, blue, alpha) native "WebGLRenderingContext_clearColor_Callback_RESOLVER_STRING_4_float_float_float_float";

Native_WebGLRenderingContext_clearDepth_Callback(mthis, depth) native "WebGLRenderingContext_clearDepth_Callback_RESOLVER_STRING_1_float";

Native_WebGLRenderingContext_clearStencil_Callback(mthis, s) native "WebGLRenderingContext_clearStencil_Callback_RESOLVER_STRING_1_long";

Native_WebGLRenderingContext_colorMask_Callback(mthis, red, green, blue, alpha) native "WebGLRenderingContext_colorMask_Callback_RESOLVER_STRING_4_boolean_boolean_boolean_boolean";

Native_WebGLRenderingContext_compileShader_Callback(mthis, shader) native "WebGLRenderingContext_compileShader_Callback_RESOLVER_STRING_1_WebGLShader";

Native_WebGLRenderingContext_compressedTexImage2D_Callback(mthis, target, level, internalformat, width, height, border, data) native "WebGLRenderingContext_compressedTexImage2D_Callback_RESOLVER_STRING_7_unsigned long_long_unsigned long_long_long_long_ArrayBufferView";

Native_WebGLRenderingContext_compressedTexSubImage2D_Callback(mthis, target, level, xoffset, yoffset, width, height, format, data) native "WebGLRenderingContext_compressedTexSubImage2D_Callback_RESOLVER_STRING_8_unsigned long_long_long_long_long_long_unsigned long_ArrayBufferView";

Native_WebGLRenderingContext_copyTexImage2D_Callback(mthis, target, level, internalformat, x, y, width, height, border) native "WebGLRenderingContext_copyTexImage2D_Callback_RESOLVER_STRING_8_unsigned long_long_unsigned long_long_long_long_long_long";

Native_WebGLRenderingContext_copyTexSubImage2D_Callback(mthis, target, level, xoffset, yoffset, x, y, width, height) native "WebGLRenderingContext_copyTexSubImage2D_Callback_RESOLVER_STRING_8_unsigned long_long_long_long_long_long_long_long";

Native_WebGLRenderingContext_createBuffer_Callback(mthis) native "WebGLRenderingContext_createBuffer_Callback_RESOLVER_STRING_0_";

Native_WebGLRenderingContext_createFramebuffer_Callback(mthis) native "WebGLRenderingContext_createFramebuffer_Callback_RESOLVER_STRING_0_";

Native_WebGLRenderingContext_createProgram_Callback(mthis) native "WebGLRenderingContext_createProgram_Callback_RESOLVER_STRING_0_";

Native_WebGLRenderingContext_createRenderbuffer_Callback(mthis) native "WebGLRenderingContext_createRenderbuffer_Callback_RESOLVER_STRING_0_";

Native_WebGLRenderingContext_createShader_Callback(mthis, type) native "WebGLRenderingContext_createShader_Callback_RESOLVER_STRING_1_unsigned long";

Native_WebGLRenderingContext_createTexture_Callback(mthis) native "WebGLRenderingContext_createTexture_Callback_RESOLVER_STRING_0_";

Native_WebGLRenderingContext_cullFace_Callback(mthis, mode) native "WebGLRenderingContext_cullFace_Callback_RESOLVER_STRING_1_unsigned long";

Native_WebGLRenderingContext_deleteBuffer_Callback(mthis, buffer) native "WebGLRenderingContext_deleteBuffer_Callback_RESOLVER_STRING_1_WebGLBuffer";

Native_WebGLRenderingContext_deleteFramebuffer_Callback(mthis, framebuffer) native "WebGLRenderingContext_deleteFramebuffer_Callback_RESOLVER_STRING_1_WebGLFramebuffer";

Native_WebGLRenderingContext_deleteProgram_Callback(mthis, program) native "WebGLRenderingContext_deleteProgram_Callback_RESOLVER_STRING_1_WebGLProgram";

Native_WebGLRenderingContext_deleteRenderbuffer_Callback(mthis, renderbuffer) native "WebGLRenderingContext_deleteRenderbuffer_Callback_RESOLVER_STRING_1_WebGLRenderbuffer";

Native_WebGLRenderingContext_deleteShader_Callback(mthis, shader) native "WebGLRenderingContext_deleteShader_Callback_RESOLVER_STRING_1_WebGLShader";

Native_WebGLRenderingContext_deleteTexture_Callback(mthis, texture) native "WebGLRenderingContext_deleteTexture_Callback_RESOLVER_STRING_1_WebGLTexture";

Native_WebGLRenderingContext_depthFunc_Callback(mthis, func) native "WebGLRenderingContext_depthFunc_Callback_RESOLVER_STRING_1_unsigned long";

Native_WebGLRenderingContext_depthMask_Callback(mthis, flag) native "WebGLRenderingContext_depthMask_Callback_RESOLVER_STRING_1_boolean";

Native_WebGLRenderingContext_depthRange_Callback(mthis, zNear, zFar) native "WebGLRenderingContext_depthRange_Callback_RESOLVER_STRING_2_float_float";

Native_WebGLRenderingContext_detachShader_Callback(mthis, program, shader) native "WebGLRenderingContext_detachShader_Callback_RESOLVER_STRING_2_WebGLProgram_WebGLShader";

Native_WebGLRenderingContext_disable_Callback(mthis, cap) native "WebGLRenderingContext_disable_Callback_RESOLVER_STRING_1_unsigned long";

Native_WebGLRenderingContext_disableVertexAttribArray_Callback(mthis, index) native "WebGLRenderingContext_disableVertexAttribArray_Callback_RESOLVER_STRING_1_unsigned long";

Native_WebGLRenderingContext_drawArrays_Callback(mthis, mode, first, count) native "WebGLRenderingContext_drawArrays_Callback_RESOLVER_STRING_3_unsigned long_long_long";

Native_WebGLRenderingContext_drawElements_Callback(mthis, mode, count, type, offset) native "WebGLRenderingContext_drawElements_Callback_RESOLVER_STRING_4_unsigned long_long_unsigned long_long long";

Native_WebGLRenderingContext_enable_Callback(mthis, cap) native "WebGLRenderingContext_enable_Callback_RESOLVER_STRING_1_unsigned long";

Native_WebGLRenderingContext_enableVertexAttribArray_Callback(mthis, index) native "WebGLRenderingContext_enableVertexAttribArray_Callback_RESOLVER_STRING_1_unsigned long";

Native_WebGLRenderingContext_finish_Callback(mthis) native "WebGLRenderingContext_finish_Callback_RESOLVER_STRING_0_";

Native_WebGLRenderingContext_flush_Callback(mthis) native "WebGLRenderingContext_flush_Callback_RESOLVER_STRING_0_";

Native_WebGLRenderingContext_framebufferRenderbuffer_Callback(mthis, target, attachment, renderbuffertarget, renderbuffer) native "WebGLRenderingContext_framebufferRenderbuffer_Callback_RESOLVER_STRING_4_unsigned long_unsigned long_unsigned long_WebGLRenderbuffer";

Native_WebGLRenderingContext_framebufferTexture2D_Callback(mthis, target, attachment, textarget, texture, level) native "WebGLRenderingContext_framebufferTexture2D_Callback_RESOLVER_STRING_5_unsigned long_unsigned long_unsigned long_WebGLTexture_long";

Native_WebGLRenderingContext_frontFace_Callback(mthis, mode) native "WebGLRenderingContext_frontFace_Callback_RESOLVER_STRING_1_unsigned long";

Native_WebGLRenderingContext_generateMipmap_Callback(mthis, target) native "WebGLRenderingContext_generateMipmap_Callback_RESOLVER_STRING_1_unsigned long";

Native_WebGLRenderingContext_getActiveAttrib_Callback(mthis, program, index) native "WebGLRenderingContext_getActiveAttrib_Callback_RESOLVER_STRING_2_WebGLProgram_unsigned long";

Native_WebGLRenderingContext_getActiveUniform_Callback(mthis, program, index) native "WebGLRenderingContext_getActiveUniform_Callback_RESOLVER_STRING_2_WebGLProgram_unsigned long";

Native_WebGLRenderingContext_getAttachedShaders_Callback(mthis, program) native "WebGLRenderingContext_getAttachedShaders_Callback";

Native_WebGLRenderingContext_getAttribLocation_Callback(mthis, program, name) native "WebGLRenderingContext_getAttribLocation_Callback_RESOLVER_STRING_2_WebGLProgram_DOMString";

Native_WebGLRenderingContext_getBufferParameter_Callback(mthis, target, pname) native "WebGLRenderingContext_getBufferParameter_Callback";

Native_WebGLRenderingContext_getContextAttributes_Callback(mthis) native "WebGLRenderingContext_getContextAttributes_Callback_RESOLVER_STRING_0_";

Native_WebGLRenderingContext_getError_Callback(mthis) native "WebGLRenderingContext_getError_Callback_RESOLVER_STRING_0_";

Native_WebGLRenderingContext_getExtension_Callback(mthis, name) native "WebGLRenderingContext_getExtension_Callback";

Native_WebGLRenderingContext_getFramebufferAttachmentParameter_Callback(mthis, target, attachment, pname) native "WebGLRenderingContext_getFramebufferAttachmentParameter_Callback";

Native_WebGLRenderingContext_getParameter_Callback(mthis, pname) native "WebGLRenderingContext_getParameter_Callback";

Native_WebGLRenderingContext_getProgramInfoLog_Callback(mthis, program) native "WebGLRenderingContext_getProgramInfoLog_Callback_RESOLVER_STRING_1_WebGLProgram";

Native_WebGLRenderingContext_getProgramParameter_Callback(mthis, program, pname) native "WebGLRenderingContext_getProgramParameter_Callback";

Native_WebGLRenderingContext_getRenderbufferParameter_Callback(mthis, target, pname) native "WebGLRenderingContext_getRenderbufferParameter_Callback";

Native_WebGLRenderingContext_getShaderInfoLog_Callback(mthis, shader) native "WebGLRenderingContext_getShaderInfoLog_Callback_RESOLVER_STRING_1_WebGLShader";

Native_WebGLRenderingContext_getShaderParameter_Callback(mthis, shader, pname) native "WebGLRenderingContext_getShaderParameter_Callback";

Native_WebGLRenderingContext_getShaderPrecisionFormat_Callback(mthis, shadertype, precisiontype) native "WebGLRenderingContext_getShaderPrecisionFormat_Callback_RESOLVER_STRING_2_unsigned long_unsigned long";

Native_WebGLRenderingContext_getShaderSource_Callback(mthis, shader) native "WebGLRenderingContext_getShaderSource_Callback_RESOLVER_STRING_1_WebGLShader";

Native_WebGLRenderingContext_getSupportedExtensions_Callback(mthis) native "WebGLRenderingContext_getSupportedExtensions_Callback";

Native_WebGLRenderingContext_getTexParameter_Callback(mthis, target, pname) native "WebGLRenderingContext_getTexParameter_Callback";

Native_WebGLRenderingContext_getUniform_Callback(mthis, program, location) native "WebGLRenderingContext_getUniform_Callback";

Native_WebGLRenderingContext_getUniformLocation_Callback(mthis, program, name) native "WebGLRenderingContext_getUniformLocation_Callback_RESOLVER_STRING_2_WebGLProgram_DOMString";

Native_WebGLRenderingContext_getVertexAttrib_Callback(mthis, index, pname) native "WebGLRenderingContext_getVertexAttrib_Callback";

Native_WebGLRenderingContext_getVertexAttribOffset_Callback(mthis, index, pname) native "WebGLRenderingContext_getVertexAttribOffset_Callback_RESOLVER_STRING_2_unsigned long_unsigned long";

Native_WebGLRenderingContext_hint_Callback(mthis, target, mode) native "WebGLRenderingContext_hint_Callback_RESOLVER_STRING_2_unsigned long_unsigned long";

Native_WebGLRenderingContext_isBuffer_Callback(mthis, buffer) native "WebGLRenderingContext_isBuffer_Callback_RESOLVER_STRING_1_WebGLBuffer";

Native_WebGLRenderingContext_isContextLost_Callback(mthis) native "WebGLRenderingContext_isContextLost_Callback_RESOLVER_STRING_0_";

Native_WebGLRenderingContext_isEnabled_Callback(mthis, cap) native "WebGLRenderingContext_isEnabled_Callback_RESOLVER_STRING_1_unsigned long";

Native_WebGLRenderingContext_isFramebuffer_Callback(mthis, framebuffer) native "WebGLRenderingContext_isFramebuffer_Callback_RESOLVER_STRING_1_WebGLFramebuffer";

Native_WebGLRenderingContext_isProgram_Callback(mthis, program) native "WebGLRenderingContext_isProgram_Callback_RESOLVER_STRING_1_WebGLProgram";

Native_WebGLRenderingContext_isRenderbuffer_Callback(mthis, renderbuffer) native "WebGLRenderingContext_isRenderbuffer_Callback_RESOLVER_STRING_1_WebGLRenderbuffer";

Native_WebGLRenderingContext_isShader_Callback(mthis, shader) native "WebGLRenderingContext_isShader_Callback_RESOLVER_STRING_1_WebGLShader";

Native_WebGLRenderingContext_isTexture_Callback(mthis, texture) native "WebGLRenderingContext_isTexture_Callback_RESOLVER_STRING_1_WebGLTexture";

Native_WebGLRenderingContext_lineWidth_Callback(mthis, width) native "WebGLRenderingContext_lineWidth_Callback_RESOLVER_STRING_1_float";

Native_WebGLRenderingContext_linkProgram_Callback(mthis, program) native "WebGLRenderingContext_linkProgram_Callback_RESOLVER_STRING_1_WebGLProgram";

Native_WebGLRenderingContext_pixelStorei_Callback(mthis, pname, param) native "WebGLRenderingContext_pixelStorei_Callback_RESOLVER_STRING_2_unsigned long_long";

Native_WebGLRenderingContext_polygonOffset_Callback(mthis, factor, units) native "WebGLRenderingContext_polygonOffset_Callback_RESOLVER_STRING_2_float_float";

Native_WebGLRenderingContext_readPixels_Callback(mthis, x, y, width, height, format, type, pixels) native "WebGLRenderingContext_readPixels_Callback_RESOLVER_STRING_7_long_long_long_long_unsigned long_unsigned long_ArrayBufferView";

Native_WebGLRenderingContext_renderbufferStorage_Callback(mthis, target, internalformat, width, height) native "WebGLRenderingContext_renderbufferStorage_Callback_RESOLVER_STRING_4_unsigned long_unsigned long_long_long";

Native_WebGLRenderingContext_sampleCoverage_Callback(mthis, value, invert) native "WebGLRenderingContext_sampleCoverage_Callback_RESOLVER_STRING_2_float_boolean";

Native_WebGLRenderingContext_scissor_Callback(mthis, x, y, width, height) native "WebGLRenderingContext_scissor_Callback_RESOLVER_STRING_4_long_long_long_long";

Native_WebGLRenderingContext_shaderSource_Callback(mthis, shader, string) native "WebGLRenderingContext_shaderSource_Callback_RESOLVER_STRING_2_WebGLShader_DOMString";

Native_WebGLRenderingContext_stencilFunc_Callback(mthis, func, ref, mask) native "WebGLRenderingContext_stencilFunc_Callback_RESOLVER_STRING_3_unsigned long_long_unsigned long";

Native_WebGLRenderingContext_stencilFuncSeparate_Callback(mthis, face, func, ref, mask) native "WebGLRenderingContext_stencilFuncSeparate_Callback_RESOLVER_STRING_4_unsigned long_unsigned long_long_unsigned long";

Native_WebGLRenderingContext_stencilMask_Callback(mthis, mask) native "WebGLRenderingContext_stencilMask_Callback_RESOLVER_STRING_1_unsigned long";

Native_WebGLRenderingContext_stencilMaskSeparate_Callback(mthis, face, mask) native "WebGLRenderingContext_stencilMaskSeparate_Callback_RESOLVER_STRING_2_unsigned long_unsigned long";

Native_WebGLRenderingContext_stencilOp_Callback(mthis, fail, zfail, zpass) native "WebGLRenderingContext_stencilOp_Callback_RESOLVER_STRING_3_unsigned long_unsigned long_unsigned long";

Native_WebGLRenderingContext_stencilOpSeparate_Callback(mthis, face, fail, zfail, zpass) native "WebGLRenderingContext_stencilOpSeparate_Callback_RESOLVER_STRING_4_unsigned long_unsigned long_unsigned long_unsigned long";

  // Generated overload resolver
Native_WebGLRenderingContext_texImage2D(mthis, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video, format, type, pixels) {
    if ((pixels is TypedData || pixels == null) && (type is int || type == null) && (format is int || format == null) && (border_OR_canvas_OR_image_OR_pixels_OR_video is int || border_OR_canvas_OR_image_OR_pixels_OR_video == null) && (height_OR_type is int || height_OR_type == null) && (format_OR_width is int || format_OR_width == null) && (internalformat is int || internalformat == null) && (level is int || level == null) && (target is int || target == null)) {
      Native_WebGLRenderingContext__texImage2D_1_Callback(mthis, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video, format, type, pixels);
      return;
    }
    if ((border_OR_canvas_OR_image_OR_pixels_OR_video is ImageData || border_OR_canvas_OR_image_OR_pixels_OR_video == null) && (height_OR_type is int || height_OR_type == null) && (format_OR_width is int || format_OR_width == null) && (internalformat is int || internalformat == null) && (level is int || level == null) && (target is int || target == null) && format == null && type == null && pixels == null) {
      Native_WebGLRenderingContext__texImage2D_2_Callback(mthis, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((border_OR_canvas_OR_image_OR_pixels_OR_video is ImageElement || border_OR_canvas_OR_image_OR_pixels_OR_video == null) && (height_OR_type is int || height_OR_type == null) && (format_OR_width is int || format_OR_width == null) && (internalformat is int || internalformat == null) && (level is int || level == null) && (target is int || target == null) && format == null && type == null && pixels == null) {
      Native_WebGLRenderingContext__texImage2D_3_Callback(mthis, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((border_OR_canvas_OR_image_OR_pixels_OR_video is CanvasElement || border_OR_canvas_OR_image_OR_pixels_OR_video == null) && (height_OR_type is int || height_OR_type == null) && (format_OR_width is int || format_OR_width == null) && (internalformat is int || internalformat == null) && (level is int || level == null) && (target is int || target == null) && format == null && type == null && pixels == null) {
      Native_WebGLRenderingContext__texImage2D_4_Callback(mthis, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((border_OR_canvas_OR_image_OR_pixels_OR_video is VideoElement || border_OR_canvas_OR_image_OR_pixels_OR_video == null) && (height_OR_type is int || height_OR_type == null) && (format_OR_width is int || format_OR_width == null) && (internalformat is int || internalformat == null) && (level is int || level == null) && (target is int || target == null) && format == null && type == null && pixels == null) {
      Native_WebGLRenderingContext__texImage2D_5_Callback(mthis, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

Native_WebGLRenderingContext__texImage2D_1_Callback(mthis, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video, format, type, pixels) native "WebGLRenderingContext_texImage2D_Callback_RESOLVER_STRING_9_unsigned long_long_unsigned long_long_long_long_unsigned long_unsigned long_ArrayBufferView";

Native_WebGLRenderingContext__texImage2D_2_Callback(mthis, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext_texImage2D_Callback_RESOLVER_STRING_6_unsigned long_long_unsigned long_unsigned long_unsigned long_ImageData";

Native_WebGLRenderingContext__texImage2D_3_Callback(mthis, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext_texImage2D_Callback_RESOLVER_STRING_6_unsigned long_long_unsigned long_unsigned long_unsigned long_HTMLImageElement";

Native_WebGLRenderingContext__texImage2D_4_Callback(mthis, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext_texImage2D_Callback_RESOLVER_STRING_6_unsigned long_long_unsigned long_unsigned long_unsigned long_HTMLCanvasElement";

Native_WebGLRenderingContext__texImage2D_5_Callback(mthis, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext_texImage2D_Callback_RESOLVER_STRING_6_unsigned long_long_unsigned long_unsigned long_unsigned long_HTMLVideoElement";

Native_WebGLRenderingContext_texImage2DCanvas_Callback(mthis, target, level, internalformat, format, type, canvas) native "WebGLRenderingContext_texImage2D_Callback_RESOLVER_STRING_6_unsigned long_long_unsigned long_unsigned long_unsigned long_HTMLCanvasElement";

Native_WebGLRenderingContext_texImage2DImage_Callback(mthis, target, level, internalformat, format, type, image) native "WebGLRenderingContext_texImage2D_Callback_RESOLVER_STRING_6_unsigned long_long_unsigned long_unsigned long_unsigned long_HTMLImageElement";

Native_WebGLRenderingContext_texImage2DImageData_Callback(mthis, target, level, internalformat, format, type, pixels) native "WebGLRenderingContext_texImage2D_Callback_RESOLVER_STRING_6_unsigned long_long_unsigned long_unsigned long_unsigned long_ImageData";

Native_WebGLRenderingContext_texImage2DVideo_Callback(mthis, target, level, internalformat, format, type, video) native "WebGLRenderingContext_texImage2D_Callback_RESOLVER_STRING_6_unsigned long_long_unsigned long_unsigned long_unsigned long_HTMLVideoElement";

Native_WebGLRenderingContext_texParameterf_Callback(mthis, target, pname, param) native "WebGLRenderingContext_texParameterf_Callback_RESOLVER_STRING_3_unsigned long_unsigned long_float";

Native_WebGLRenderingContext_texParameteri_Callback(mthis, target, pname, param) native "WebGLRenderingContext_texParameteri_Callback_RESOLVER_STRING_3_unsigned long_unsigned long_long";

  // Generated overload resolver
Native_WebGLRenderingContext_texSubImage2D(mthis, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video, type, pixels) {
    if ((pixels is TypedData || pixels == null) && (type is int || type == null) && (canvas_OR_format_OR_image_OR_pixels_OR_video is int || canvas_OR_format_OR_image_OR_pixels_OR_video == null) && (height_OR_type is int || height_OR_type == null) && (format_OR_width is int || format_OR_width == null) && (yoffset is int || yoffset == null) && (xoffset is int || xoffset == null) && (level is int || level == null) && (target is int || target == null)) {
      Native_WebGLRenderingContext__texSubImage2D_1_Callback(mthis, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video, type, pixels);
      return;
    }
    if ((canvas_OR_format_OR_image_OR_pixels_OR_video is ImageData || canvas_OR_format_OR_image_OR_pixels_OR_video == null) && (height_OR_type is int || height_OR_type == null) && (format_OR_width is int || format_OR_width == null) && (yoffset is int || yoffset == null) && (xoffset is int || xoffset == null) && (level is int || level == null) && (target is int || target == null) && type == null && pixels == null) {
      Native_WebGLRenderingContext__texSubImage2D_2_Callback(mthis, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((canvas_OR_format_OR_image_OR_pixels_OR_video is ImageElement || canvas_OR_format_OR_image_OR_pixels_OR_video == null) && (height_OR_type is int || height_OR_type == null) && (format_OR_width is int || format_OR_width == null) && (yoffset is int || yoffset == null) && (xoffset is int || xoffset == null) && (level is int || level == null) && (target is int || target == null) && type == null && pixels == null) {
      Native_WebGLRenderingContext__texSubImage2D_3_Callback(mthis, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((canvas_OR_format_OR_image_OR_pixels_OR_video is CanvasElement || canvas_OR_format_OR_image_OR_pixels_OR_video == null) && (height_OR_type is int || height_OR_type == null) && (format_OR_width is int || format_OR_width == null) && (yoffset is int || yoffset == null) && (xoffset is int || xoffset == null) && (level is int || level == null) && (target is int || target == null) && type == null && pixels == null) {
      Native_WebGLRenderingContext__texSubImage2D_4_Callback(mthis, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((canvas_OR_format_OR_image_OR_pixels_OR_video is VideoElement || canvas_OR_format_OR_image_OR_pixels_OR_video == null) && (height_OR_type is int || height_OR_type == null) && (format_OR_width is int || format_OR_width == null) && (yoffset is int || yoffset == null) && (xoffset is int || xoffset == null) && (level is int || level == null) && (target is int || target == null) && type == null && pixels == null) {
      Native_WebGLRenderingContext__texSubImage2D_5_Callback(mthis, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

Native_WebGLRenderingContext__texSubImage2D_1_Callback(mthis, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video, type, pixels) native "WebGLRenderingContext_texSubImage2D_Callback_RESOLVER_STRING_9_unsigned long_long_long_long_long_long_unsigned long_unsigned long_ArrayBufferView";

Native_WebGLRenderingContext__texSubImage2D_2_Callback(mthis, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext_texSubImage2D_Callback_RESOLVER_STRING_7_unsigned long_long_long_long_unsigned long_unsigned long_ImageData";

Native_WebGLRenderingContext__texSubImage2D_3_Callback(mthis, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext_texSubImage2D_Callback_RESOLVER_STRING_7_unsigned long_long_long_long_unsigned long_unsigned long_HTMLImageElement";

Native_WebGLRenderingContext__texSubImage2D_4_Callback(mthis, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext_texSubImage2D_Callback_RESOLVER_STRING_7_unsigned long_long_long_long_unsigned long_unsigned long_HTMLCanvasElement";

Native_WebGLRenderingContext__texSubImage2D_5_Callback(mthis, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext_texSubImage2D_Callback_RESOLVER_STRING_7_unsigned long_long_long_long_unsigned long_unsigned long_HTMLVideoElement";

Native_WebGLRenderingContext_texSubImage2DCanvas_Callback(mthis, target, level, xoffset, yoffset, format, type, canvas) native "WebGLRenderingContext_texSubImage2D_Callback_RESOLVER_STRING_7_unsigned long_long_long_long_unsigned long_unsigned long_HTMLCanvasElement";

Native_WebGLRenderingContext_texSubImage2DImage_Callback(mthis, target, level, xoffset, yoffset, format, type, image) native "WebGLRenderingContext_texSubImage2D_Callback_RESOLVER_STRING_7_unsigned long_long_long_long_unsigned long_unsigned long_HTMLImageElement";

Native_WebGLRenderingContext_texSubImage2DImageData_Callback(mthis, target, level, xoffset, yoffset, format, type, pixels) native "WebGLRenderingContext_texSubImage2D_Callback_RESOLVER_STRING_7_unsigned long_long_long_long_unsigned long_unsigned long_ImageData";

Native_WebGLRenderingContext_texSubImage2DVideo_Callback(mthis, target, level, xoffset, yoffset, format, type, video) native "WebGLRenderingContext_texSubImage2D_Callback_RESOLVER_STRING_7_unsigned long_long_long_long_unsigned long_unsigned long_HTMLVideoElement";

Native_WebGLRenderingContext_uniform1f_Callback(mthis, location, x) native "WebGLRenderingContext_uniform1f_Callback_RESOLVER_STRING_2_WebGLUniformLocation_float";

Native_WebGLRenderingContext_uniform1fv_Callback(mthis, location, v) native "WebGLRenderingContext_uniform1fv_Callback";

Native_WebGLRenderingContext_uniform1i_Callback(mthis, location, x) native "WebGLRenderingContext_uniform1i_Callback_RESOLVER_STRING_2_WebGLUniformLocation_long";

Native_WebGLRenderingContext_uniform1iv_Callback(mthis, location, v) native "WebGLRenderingContext_uniform1iv_Callback";

Native_WebGLRenderingContext_uniform2f_Callback(mthis, location, x, y) native "WebGLRenderingContext_uniform2f_Callback_RESOLVER_STRING_3_WebGLUniformLocation_float_float";

Native_WebGLRenderingContext_uniform2fv_Callback(mthis, location, v) native "WebGLRenderingContext_uniform2fv_Callback";

Native_WebGLRenderingContext_uniform2i_Callback(mthis, location, x, y) native "WebGLRenderingContext_uniform2i_Callback_RESOLVER_STRING_3_WebGLUniformLocation_long_long";

Native_WebGLRenderingContext_uniform2iv_Callback(mthis, location, v) native "WebGLRenderingContext_uniform2iv_Callback";

Native_WebGLRenderingContext_uniform3f_Callback(mthis, location, x, y, z) native "WebGLRenderingContext_uniform3f_Callback_RESOLVER_STRING_4_WebGLUniformLocation_float_float_float";

Native_WebGLRenderingContext_uniform3fv_Callback(mthis, location, v) native "WebGLRenderingContext_uniform3fv_Callback";

Native_WebGLRenderingContext_uniform3i_Callback(mthis, location, x, y, z) native "WebGLRenderingContext_uniform3i_Callback_RESOLVER_STRING_4_WebGLUniformLocation_long_long_long";

Native_WebGLRenderingContext_uniform3iv_Callback(mthis, location, v) native "WebGLRenderingContext_uniform3iv_Callback";

Native_WebGLRenderingContext_uniform4f_Callback(mthis, location, x, y, z, w) native "WebGLRenderingContext_uniform4f_Callback_RESOLVER_STRING_5_WebGLUniformLocation_float_float_float_float";

Native_WebGLRenderingContext_uniform4fv_Callback(mthis, location, v) native "WebGLRenderingContext_uniform4fv_Callback";

Native_WebGLRenderingContext_uniform4i_Callback(mthis, location, x, y, z, w) native "WebGLRenderingContext_uniform4i_Callback_RESOLVER_STRING_5_WebGLUniformLocation_long_long_long_long";

Native_WebGLRenderingContext_uniform4iv_Callback(mthis, location, v) native "WebGLRenderingContext_uniform4iv_Callback";

Native_WebGLRenderingContext_uniformMatrix2fv_Callback(mthis, location, transpose, array) native "WebGLRenderingContext_uniformMatrix2fv_Callback";

Native_WebGLRenderingContext_uniformMatrix3fv_Callback(mthis, location, transpose, array) native "WebGLRenderingContext_uniformMatrix3fv_Callback";

Native_WebGLRenderingContext_uniformMatrix4fv_Callback(mthis, location, transpose, array) native "WebGLRenderingContext_uniformMatrix4fv_Callback";

Native_WebGLRenderingContext_useProgram_Callback(mthis, program) native "WebGLRenderingContext_useProgram_Callback_RESOLVER_STRING_1_WebGLProgram";

Native_WebGLRenderingContext_validateProgram_Callback(mthis, program) native "WebGLRenderingContext_validateProgram_Callback_RESOLVER_STRING_1_WebGLProgram";

Native_WebGLRenderingContext_vertexAttrib1f_Callback(mthis, indx, x) native "WebGLRenderingContext_vertexAttrib1f_Callback_RESOLVER_STRING_2_unsigned long_float";

Native_WebGLRenderingContext_vertexAttrib1fv_Callback(mthis, indx, values) native "WebGLRenderingContext_vertexAttrib1fv_Callback";

Native_WebGLRenderingContext_vertexAttrib2f_Callback(mthis, indx, x, y) native "WebGLRenderingContext_vertexAttrib2f_Callback_RESOLVER_STRING_3_unsigned long_float_float";

Native_WebGLRenderingContext_vertexAttrib2fv_Callback(mthis, indx, values) native "WebGLRenderingContext_vertexAttrib2fv_Callback";

Native_WebGLRenderingContext_vertexAttrib3f_Callback(mthis, indx, x, y, z) native "WebGLRenderingContext_vertexAttrib3f_Callback_RESOLVER_STRING_4_unsigned long_float_float_float";

Native_WebGLRenderingContext_vertexAttrib3fv_Callback(mthis, indx, values) native "WebGLRenderingContext_vertexAttrib3fv_Callback";

Native_WebGLRenderingContext_vertexAttrib4f_Callback(mthis, indx, x, y, z, w) native "WebGLRenderingContext_vertexAttrib4f_Callback_RESOLVER_STRING_5_unsigned long_float_float_float_float";

Native_WebGLRenderingContext_vertexAttrib4fv_Callback(mthis, indx, values) native "WebGLRenderingContext_vertexAttrib4fv_Callback";

Native_WebGLRenderingContext_vertexAttribPointer_Callback(mthis, indx, size, type, normalized, stride, offset) native "WebGLRenderingContext_vertexAttribPointer_Callback_RESOLVER_STRING_6_unsigned long_long_unsigned long_boolean_long_long long";

Native_WebGLRenderingContext_viewport_Callback(mthis, x, y, width, height) native "WebGLRenderingContext_viewport_Callback_RESOLVER_STRING_4_long_long_long_long";

Native_WebGLShaderPrecisionFormat_precision_Getter(mthis) native "WebGLShaderPrecisionFormat_precision_Getter";

Native_WebGLShaderPrecisionFormat_rangeMax_Getter(mthis) native "WebGLShaderPrecisionFormat_rangeMax_Getter";

Native_WebGLShaderPrecisionFormat_rangeMin_Getter(mthis) native "WebGLShaderPrecisionFormat_rangeMin_Getter";

Native_WebKitAnimationEvent_animationName_Getter(mthis) native "WebKitAnimationEvent_animationName_Getter";

Native_WebKitAnimationEvent_elapsedTime_Getter(mthis) native "WebKitAnimationEvent_elapsedTime_Getter";

Native_WebKitCSSFilterRule_style_Getter(mthis) native "WebKitCSSFilterRule_style_Getter";

  // Generated overload resolver
Native_WebKitCSSMatrix__WebKitCSSMatrix(cssValue) {
    return Native_WebKitCSSMatrix__create_1constructorCallback(cssValue);
  }

Native_WebKitCSSMatrix__create_1constructorCallback(cssValue) native "WebKitCSSMatrix_constructorCallback_RESOLVER_STRING_1_DOMString";

  // Generated overload resolver
Native_WebKitMediaSource__WebKitMediaSource() {
    return Native_WebKitMediaSource__create_1constructorCallback();
  }

Native_WebKitMediaSource__create_1constructorCallback() native "WebKitMediaSource_constructorCallback_RESOLVER_STRING_0_";

Native_WebKitPoint_constructorCallback(x, y) native "WebKitPoint_constructorCallback";

Native_WebKitPoint_x_Getter(mthis) native "WebKitPoint_x_Getter";

Native_WebKitPoint_x_Setter(mthis, value) native "WebKitPoint_x_Setter";

Native_WebKitPoint_y_Getter(mthis) native "WebKitPoint_y_Getter";

Native_WebKitPoint_y_Setter(mthis, value) native "WebKitPoint_y_Setter";

Native_WebKitSourceBufferList_item_Callback(mthis, index) native "WebKitSourceBufferList_item_Callback_RESOLVER_STRING_1_unsigned long";

  // Generated overload resolver
Native_WebSocket_WebSocket(url, protocol_OR_protocols) {
    if ((url is String || url == null) && protocol_OR_protocols == null) {
      return Native_WebSocket__create_1constructorCallback(url);
    }
    if ((protocol_OR_protocols is List<String> || protocol_OR_protocols == null) && (url is String || url == null)) {
      return Native_WebSocket__create_2constructorCallback(url, protocol_OR_protocols);
    }
    if ((protocol_OR_protocols is String || protocol_OR_protocols == null) && (url is String || url == null)) {
      return Native_WebSocket__create_3constructorCallback(url, protocol_OR_protocols);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

Native_WebSocket__create_1constructorCallback(url) native "WebSocket_constructorCallback_RESOLVER_STRING_1_DOMString";

Native_WebSocket__create_2constructorCallback(url, protocol_OR_protocols) native "WebSocket_constructorCallback_RESOLVER_STRING_2_DOMString_sequence<DOMString>";

Native_WebSocket__create_3constructorCallback(url, protocol_OR_protocols) native "WebSocket_constructorCallback_RESOLVER_STRING_2_DOMString_DOMString";

Native_WebSocket_binaryType_Getter(mthis) native "WebSocket_binaryType_Getter";

Native_WebSocket_binaryType_Setter(mthis, value) native "WebSocket_binaryType_Setter";

Native_WebSocket_bufferedAmount_Getter(mthis) native "WebSocket_bufferedAmount_Getter";

Native_WebSocket_extensions_Getter(mthis) native "WebSocket_extensions_Getter";

Native_WebSocket_protocol_Getter(mthis) native "WebSocket_protocol_Getter";

Native_WebSocket_readyState_Getter(mthis) native "WebSocket_readyState_Getter";

Native_WebSocket_url_Getter(mthis) native "WebSocket_url_Getter";

  // Generated overload resolver
Native_WebSocket_close(mthis, code, reason) {
    if (reason != null) {
      Native_WebSocket__close_1_Callback(mthis, code, reason);
      return;
    }
    if (code != null) {
      Native_WebSocket__close_2_Callback(mthis, code);
      return;
    }
    Native_WebSocket__close_3_Callback(mthis);
    return;
  }

Native_WebSocket__close_1_Callback(mthis, code, reason) native "WebSocket_close_Callback_RESOLVER_STRING_2_unsigned short_DOMString";

Native_WebSocket__close_2_Callback(mthis, code) native "WebSocket_close_Callback_RESOLVER_STRING_1_unsigned short";

Native_WebSocket__close_3_Callback(mthis) native "WebSocket_close_Callback_RESOLVER_STRING_0_";

  // Generated overload resolver
Native_WebSocket_send(mthis, data) {
    if ((data is TypedData || data == null)) {
      Native_WebSocket__send_1_Callback(mthis, data);
      return;
    }
    if ((data is ByteBuffer || data == null)) {
      Native_WebSocket__send_2_Callback(mthis, data);
      return;
    }
    if ((data is Blob || data == null)) {
      Native_WebSocket__send_3_Callback(mthis, data);
      return;
    }
    if ((data is String || data == null)) {
      Native_WebSocket__send_4_Callback(mthis, data);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

Native_WebSocket__send_1_Callback(mthis, data) native "WebSocket_send_Callback_RESOLVER_STRING_1_ArrayBufferView";

Native_WebSocket__send_2_Callback(mthis, data) native "WebSocket_send_Callback_RESOLVER_STRING_1_ArrayBuffer";

Native_WebSocket__send_3_Callback(mthis, data) native "WebSocket_send_Callback_RESOLVER_STRING_1_Blob";

Native_WebSocket__send_4_Callback(mthis, data) native "WebSocket_send_Callback_RESOLVER_STRING_1_DOMString";

Native_WebSocket_sendBlob_Callback(mthis, data) native "WebSocket_send_Callback_RESOLVER_STRING_1_Blob";

Native_WebSocket_sendByteBuffer_Callback(mthis, data) native "WebSocket_send_Callback_RESOLVER_STRING_1_ArrayBuffer";

Native_WebSocket_sendString_Callback(mthis, data) native "WebSocket_send_Callback_RESOLVER_STRING_1_DOMString";

Native_WebSocket_sendTypedData_Callback(mthis, data) native "WebSocket_send_Callback_RESOLVER_STRING_1_ArrayBufferView";

Native_WheelEvent_deltaMode_Getter(mthis) native "WheelEvent_deltaMode_Getter";

Native_WheelEvent_deltaX_Getter(mthis) native "WheelEvent_deltaX_Getter";

Native_WheelEvent_deltaY_Getter(mthis) native "WheelEvent_deltaY_Getter";

Native_WheelEvent_deltaZ_Getter(mthis) native "WheelEvent_deltaZ_Getter";

Native_WheelEvent_webkitDirectionInvertedFromDevice_Getter(mthis) native "WheelEvent_webkitDirectionInvertedFromDevice_Getter";

Native_WheelEvent_wheelDeltaX_Getter(mthis) native "WheelEvent_wheelDeltaX_Getter";

Native_WheelEvent_wheelDeltaY_Getter(mthis) native "WheelEvent_wheelDeltaY_Getter";

Native_WheelEvent_initWebKitWheelEvent_Callback(mthis, wheelDeltaX, wheelDeltaY, view, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey) native "WheelEvent_initWebKitWheelEvent_Callback_RESOLVER_STRING_11_long_long_Window_long_long_long_long_boolean_boolean_boolean_boolean";

Native_Window_CSS_Getter(mthis) native "Window_CSS_Getter";

Native_Window_applicationCache_Getter(mthis) native "Window_applicationCache_Getter";

Native_Window_closed_Getter(mthis) native "Window_closed_Getter";

Native_Window_console_Getter(mthis) native "Window_console_Getter";

Native_Window_crypto_Getter(mthis) native "Window_crypto_Getter";

Native_Window_defaultStatus_Getter(mthis) native "Window_defaultStatus_Getter";

Native_Window_defaultStatus_Setter(mthis, value) native "Window_defaultStatus_Setter";

Native_Window_defaultstatus_Getter(mthis) native "Window_defaultstatus_Getter";

Native_Window_defaultstatus_Setter(mthis, value) native "Window_defaultstatus_Setter";

Native_Window_devicePixelRatio_Getter(mthis) native "Window_devicePixelRatio_Getter";

Native_Window_document_Getter(mthis) native "Window_document_Getter";

Native_Window_history_Getter(mthis) native "Window_history_Getter";

Native_Window_indexedDB_Getter(mthis) native "Window_indexedDB_Getter";

Native_Window_innerHeight_Getter(mthis) native "Window_innerHeight_Getter";

Native_Window_innerWidth_Getter(mthis) native "Window_innerWidth_Getter";

Native_Window_localStorage_Getter(mthis) native "Window_localStorage_Getter";

Native_Window_location_Getter(mthis) native "Window_location_Getter";

Native_Window_locationbar_Getter(mthis) native "Window_locationbar_Getter";

Native_Window_menubar_Getter(mthis) native "Window_menubar_Getter";

Native_Window_name_Getter(mthis) native "Window_name_Getter";

Native_Window_name_Setter(mthis, value) native "Window_name_Setter";

Native_Window_navigator_Getter(mthis) native "Window_navigator_Getter";

Native_Window_offscreenBuffering_Getter(mthis) native "Window_offscreenBuffering_Getter";

Native_Window_opener_Getter(mthis) native "Window_opener_Getter";

Native_Window_opener_Setter(mthis, value) native "Window_opener_Setter";

Native_Window_orientation_Getter(mthis) native "Window_orientation_Getter";

Native_Window_outerHeight_Getter(mthis) native "Window_outerHeight_Getter";

Native_Window_outerWidth_Getter(mthis) native "Window_outerWidth_Getter";

Native_Window_pageXOffset_Getter(mthis) native "Window_pageXOffset_Getter";

Native_Window_pageYOffset_Getter(mthis) native "Window_pageYOffset_Getter";

Native_Window_parent_Getter(mthis) native "Window_parent_Getter";

Native_Window_performance_Getter(mthis) native "Window_performance_Getter";

Native_Window_screen_Getter(mthis) native "Window_screen_Getter";

Native_Window_screenLeft_Getter(mthis) native "Window_screenLeft_Getter";

Native_Window_screenTop_Getter(mthis) native "Window_screenTop_Getter";

Native_Window_screenX_Getter(mthis) native "Window_screenX_Getter";

Native_Window_screenY_Getter(mthis) native "Window_screenY_Getter";

Native_Window_scrollX_Getter(mthis) native "Window_scrollX_Getter";

Native_Window_scrollY_Getter(mthis) native "Window_scrollY_Getter";

Native_Window_scrollbars_Getter(mthis) native "Window_scrollbars_Getter";

Native_Window_self_Getter(mthis) native "Window_self_Getter";

Native_Window_sessionStorage_Getter(mthis) native "Window_sessionStorage_Getter";

Native_Window_speechSynthesis_Getter(mthis) native "Window_speechSynthesis_Getter";

Native_Window_status_Getter(mthis) native "Window_status_Getter";

Native_Window_status_Setter(mthis, value) native "Window_status_Setter";

Native_Window_statusbar_Getter(mthis) native "Window_statusbar_Getter";

Native_Window_styleMedia_Getter(mthis) native "Window_styleMedia_Getter";

Native_Window_toolbar_Getter(mthis) native "Window_toolbar_Getter";

Native_Window_top_Getter(mthis) native "Window_top_Getter";

Native_Window_window_Getter(mthis) native "Window_window_Getter";

  // Generated overload resolver
Native_Window___getter__(mthis, index_OR_name) {
    if ((index_OR_name is int || index_OR_name == null)) {
      return Native_Window____getter___1_Callback(mthis, index_OR_name);
    }
    if ((index_OR_name is String || index_OR_name == null)) {
      return Native_Window____getter___2_Callback(mthis, index_OR_name);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

Native_Window____getter___1_Callback(mthis, index_OR_name) native "Window___getter___Callback_RESOLVER_STRING_1_unsigned long";

Native_Window____getter___2_Callback(mthis, index_OR_name) native "Window___getter___Callback";

Native_Window_alert_Callback(mthis, message) native "Window_alert_Callback_RESOLVER_STRING_1_DOMString";

Native_Window_cancelAnimationFrame_Callback(mthis, id) native "Window_cancelAnimationFrame_Callback_RESOLVER_STRING_1_long";

Native_Window_close_Callback(mthis) native "Window_close_Callback_RESOLVER_STRING_0_";

Native_Window_confirm_Callback(mthis, message) native "Window_confirm_Callback_RESOLVER_STRING_1_DOMString";

Native_Window_find_Callback(mthis, string, caseSensitive, backwards, wrap, wholeWord, searchInFrames, showDialog) native "Window_find_Callback_RESOLVER_STRING_7_DOMString_boolean_boolean_boolean_boolean_boolean_boolean";

Native_Window_getComputedStyle_Callback(mthis, element, pseudoElement) native "Window_getComputedStyle_Callback_RESOLVER_STRING_2_Element_DOMString";

Native_Window_getMatchedCSSRules_Callback(mthis, element, pseudoElement) native "Window_getMatchedCSSRules_Callback_RESOLVER_STRING_2_Element_DOMString";

Native_Window_getSelection_Callback(mthis) native "Window_getSelection_Callback_RESOLVER_STRING_0_";

Native_Window_matchMedia_Callback(mthis, query) native "Window_matchMedia_Callback_RESOLVER_STRING_1_DOMString";

Native_Window_moveBy_Callback(mthis, x, y) native "Window_moveBy_Callback_RESOLVER_STRING_2_float_float";

Native_Window_moveTo_Callback(mthis, x, y) native "Window_moveTo_Callback_RESOLVER_STRING_2_float_float";

Native_Window_open_Callback(mthis, url, name, options) native "Window_open_Callback";

Native_Window_openDatabase_Callback(mthis, name, version, displayName, estimatedSize, creationCallback) native "Window_openDatabase_Callback_RESOLVER_STRING_5_DOMString_DOMString_DOMString_unsigned long_DatabaseCallback";

Native_Window_postMessage_Callback(mthis, message, targetOrigin, messagePorts) native "Window_postMessage_Callback";

Native_Window_print_Callback(mthis) native "Window_print_Callback_RESOLVER_STRING_0_";

Native_Window_requestAnimationFrame_Callback(mthis, callback) native "Window_requestAnimationFrame_Callback_RESOLVER_STRING_1_RequestAnimationFrameCallback";

Native_Window_resizeBy_Callback(mthis, x, y) native "Window_resizeBy_Callback_RESOLVER_STRING_2_float_float";

Native_Window_resizeTo_Callback(mthis, width, height) native "Window_resizeTo_Callback_RESOLVER_STRING_2_float_float";

Native_Window_scroll_Callback(mthis, x, y, scrollOptions) native "Window_scroll_Callback_RESOLVER_STRING_3_long_long_Dictionary";

Native_Window_scrollBy_Callback(mthis, x, y, scrollOptions) native "Window_scrollBy_Callback_RESOLVER_STRING_3_long_long_Dictionary";

Native_Window_scrollTo_Callback(mthis, x, y, scrollOptions) native "Window_scrollTo_Callback_RESOLVER_STRING_3_long_long_Dictionary";

Native_Window_showModalDialog_Callback(mthis, url, dialogArgs, featureArgs) native "Window_showModalDialog_Callback";

Native_Window_stop_Callback(mthis) native "Window_stop_Callback_RESOLVER_STRING_0_";

Native_Window_toString_Callback(mthis) native "Window_toString_Callback";

Native_Window_webkitConvertPointFromNodeToPage_Callback(mthis, node, p) native "Window_webkitConvertPointFromNodeToPage_Callback_RESOLVER_STRING_2_Node_WebKitPoint";

Native_Window_webkitConvertPointFromPageToNode_Callback(mthis, node, p) native "Window_webkitConvertPointFromPageToNode_Callback_RESOLVER_STRING_2_Node_WebKitPoint";

Native_Window_webkitRequestFileSystem_Callback(mthis, type, size, successCallback, errorCallback) native "Window_webkitRequestFileSystem_Callback_RESOLVER_STRING_4_unsigned short_long long_FileSystemCallback_ErrorCallback";

Native_Window_webkitResolveLocalFileSystemURL_Callback(mthis, url, successCallback, errorCallback) native "Window_webkitResolveLocalFileSystemURL_Callback_RESOLVER_STRING_3_DOMString_EntryCallback_ErrorCallback";

Native_Window_atob_Callback(mthis, string) native "Window_atob_Callback_RESOLVER_STRING_1_DOMString";

Native_Window_btoa_Callback(mthis, string) native "Window_btoa_Callback_RESOLVER_STRING_1_DOMString";

Native_Window_clearInterval_Callback(mthis, handle) native "Window_clearInterval_Callback_RESOLVER_STRING_1_long";

Native_Window_clearTimeout_Callback(mthis, handle) native "Window_clearTimeout_Callback_RESOLVER_STRING_1_long";

Native_Window_setInterval_Callback(mthis, handler, timeout) native "Window_setInterval_Callback";

Native_Window_setTimeout_Callback(mthis, handler, timeout) native "Window_setTimeout_Callback";

  // Generated overload resolver
Native_Worker_Worker(scriptUrl) {
    return Native_Worker__create_1constructorCallback(scriptUrl);
  }

Native_Worker__create_1constructorCallback(scriptUrl) native "Worker_constructorCallback_RESOLVER_STRING_1_DOMString";

Native_Worker_postMessage_Callback(mthis, message, messagePorts) native "Worker_postMessage_Callback";

Native_Worker_terminate_Callback(mthis) native "Worker_terminate_Callback_RESOLVER_STRING_0_";

Native_WorkerCrypto_getRandomValues_Callback(mthis, array) native "WorkerCrypto_getRandomValues_Callback";

Native_WorkerPerformance_now_Callback(mthis) native "WorkerPerformance_now_Callback_RESOLVER_STRING_0_";

Native_XMLHttpRequest_constructorCallback() native "XMLHttpRequest_constructorCallback";

Native_XMLHttpRequest_readyState_Getter(mthis) native "XMLHttpRequest_readyState_Getter";

Native_XMLHttpRequest_response_Getter(mthis) native "XMLHttpRequest_response_Getter";

Native_XMLHttpRequest_responseText_Getter(mthis) native "XMLHttpRequest_responseText_Getter";

Native_XMLHttpRequest_responseType_Getter(mthis) native "XMLHttpRequest_responseType_Getter";

Native_XMLHttpRequest_responseType_Setter(mthis, value) native "XMLHttpRequest_responseType_Setter";

Native_XMLHttpRequest_responseXML_Getter(mthis) native "XMLHttpRequest_responseXML_Getter";

Native_XMLHttpRequest_status_Getter(mthis) native "XMLHttpRequest_status_Getter";

Native_XMLHttpRequest_statusText_Getter(mthis) native "XMLHttpRequest_statusText_Getter";

Native_XMLHttpRequest_timeout_Getter(mthis) native "XMLHttpRequest_timeout_Getter";

Native_XMLHttpRequest_timeout_Setter(mthis, value) native "XMLHttpRequest_timeout_Setter";

Native_XMLHttpRequest_upload_Getter(mthis) native "XMLHttpRequest_upload_Getter";

Native_XMLHttpRequest_withCredentials_Getter(mthis) native "XMLHttpRequest_withCredentials_Getter";

Native_XMLHttpRequest_withCredentials_Setter(mthis, value) native "XMLHttpRequest_withCredentials_Setter";

Native_XMLHttpRequest_abort_Callback(mthis) native "XMLHttpRequest_abort_Callback_RESOLVER_STRING_0_";

Native_XMLHttpRequest_getAllResponseHeaders_Callback(mthis) native "XMLHttpRequest_getAllResponseHeaders_Callback_RESOLVER_STRING_0_";

Native_XMLHttpRequest_getResponseHeader_Callback(mthis, header) native "XMLHttpRequest_getResponseHeader_Callback_RESOLVER_STRING_1_DOMString";

Native_XMLHttpRequest_open_Callback(mthis, method, url, async, user, password) native "XMLHttpRequest_open_Callback";

Native_XMLHttpRequest_overrideMimeType_Callback(mthis, override) native "XMLHttpRequest_overrideMimeType_Callback_RESOLVER_STRING_1_DOMString";

Native_XMLHttpRequest_send_Callback(mthis, data) native "XMLHttpRequest_send_Callback";

Native_XMLHttpRequest_setRequestHeader_Callback(mthis, header, value) native "XMLHttpRequest_setRequestHeader_Callback_RESOLVER_STRING_2_DOMString_DOMString";

  // Generated overload resolver
Native_XMLSerializer_XmlSerializer() {
    return Native_XMLSerializer__create_1constructorCallback();
  }

Native_XMLSerializer__create_1constructorCallback() native "XMLSerializer_constructorCallback_RESOLVER_STRING_0_";

Native_XMLSerializer_serializeToString_Callback(mthis, node) native "XMLSerializer_serializeToString_Callback_RESOLVER_STRING_1_Node";

  // Generated overload resolver
Native_XPathEvaluator_XPathEvaluator() {
    return Native_XPathEvaluator__create_1constructorCallback();
  }

Native_XPathEvaluator__create_1constructorCallback() native "XPathEvaluator_constructorCallback_RESOLVER_STRING_0_";

Native_XPathEvaluator_createExpression_Callback(mthis, expression, resolver) native "XPathEvaluator_createExpression_Callback_RESOLVER_STRING_2_DOMString_XPathNSResolver";

Native_XPathEvaluator_createNSResolver_Callback(mthis, nodeResolver) native "XPathEvaluator_createNSResolver_Callback_RESOLVER_STRING_1_Node";

Native_XPathEvaluator_evaluate_Callback(mthis, expression, contextNode, resolver, type, inResult) native "XPathEvaluator_evaluate_Callback_RESOLVER_STRING_5_DOMString_Node_XPathNSResolver_unsigned short_XPathResult";

Native_XPathExpression_evaluate_Callback(mthis, contextNode, type, inResult) native "XPathExpression_evaluate_Callback_RESOLVER_STRING_3_Node_unsigned short_XPathResult";

Native_XPathNSResolver_lookupNamespaceURI_Callback(mthis, prefix) native "XPathNSResolver_lookupNamespaceURI_Callback_RESOLVER_STRING_1_DOMString";

Native_XPathResult_booleanValue_Getter(mthis) native "XPathResult_booleanValue_Getter";

Native_XPathResult_invalidIteratorState_Getter(mthis) native "XPathResult_invalidIteratorState_Getter";

Native_XPathResult_numberValue_Getter(mthis) native "XPathResult_numberValue_Getter";

Native_XPathResult_resultType_Getter(mthis) native "XPathResult_resultType_Getter";

Native_XPathResult_singleNodeValue_Getter(mthis) native "XPathResult_singleNodeValue_Getter";

Native_XPathResult_snapshotLength_Getter(mthis) native "XPathResult_snapshotLength_Getter";

Native_XPathResult_stringValue_Getter(mthis) native "XPathResult_stringValue_Getter";

Native_XPathResult_iterateNext_Callback(mthis) native "XPathResult_iterateNext_Callback_RESOLVER_STRING_0_";

Native_XPathResult_snapshotItem_Callback(mthis, index) native "XPathResult_snapshotItem_Callback_RESOLVER_STRING_1_unsigned long";

  // Generated overload resolver
Native_XSLTProcessor_XsltProcessor() {
    return Native_XSLTProcessor__create_1constructorCallback();
  }

Native_XSLTProcessor__create_1constructorCallback() native "XSLTProcessor_constructorCallback_RESOLVER_STRING_0_";

Native_XSLTProcessor_clearParameters_Callback(mthis) native "XSLTProcessor_clearParameters_Callback_RESOLVER_STRING_0_";

Native_XSLTProcessor_getParameter_Callback(mthis, namespaceURI, localName) native "XSLTProcessor_getParameter_Callback";

Native_XSLTProcessor_importStylesheet_Callback(mthis, stylesheet) native "XSLTProcessor_importStylesheet_Callback_RESOLVER_STRING_1_Node";

Native_XSLTProcessor_removeParameter_Callback(mthis, namespaceURI, localName) native "XSLTProcessor_removeParameter_Callback";

Native_XSLTProcessor_reset_Callback(mthis) native "XSLTProcessor_reset_Callback_RESOLVER_STRING_0_";

Native_XSLTProcessor_setParameter_Callback(mthis, namespaceURI, localName, value) native "XSLTProcessor_setParameter_Callback";

Native_XSLTProcessor_transformToDocument_Callback(mthis, source) native "XSLTProcessor_transformToDocument_Callback_RESOLVER_STRING_1_Node";

Native_XSLTProcessor_transformToFragment_Callback(mthis, source, docVal) native "XSLTProcessor_transformToFragment_Callback_RESOLVER_STRING_2_Node_Document";


// TODO(vsm): This should be moved out of this library.  Into dart:html?
Type _getType(String key) {
  // TODO(vsm): Add Cross Frame and JS types here as well.
  if (htmlBlinkMap.containsKey(key))
    return htmlBlinkMap[key];
  if (indexed_dbBlinkMap.containsKey(key))
    return indexed_dbBlinkMap[key];
  if (web_audioBlinkMap.containsKey(key))
    return web_audioBlinkMap[key];
  if (web_glBlinkMap.containsKey(key))
    return web_glBlinkMap[key];
  if (web_sqlBlinkMap.containsKey(key))
    return web_sqlBlinkMap[key];
  if (svgBlinkMap.containsKey(key))
    return svgBlinkMap[key];
  return null;
}// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// _Utils native entry points
Native_Utils_window() native "Utils_window";

Native_Utils_forwardingPrint(message) native "Utils_forwardingPrint";

Native_Utils_spawnDomUri(uri) native "Utils_spawnDomUri";

Native_Utils_register(document, tag, customType, extendsTagName) native "Utils_register";

Native_Utils_createElement(document, tagName) native "Utils_createElement";

Native_Utils_initializeCustomElement(element) native "Utils_initializeCustomElement";

Native_Utils_changeElementWrapper(element, type) native "Utils_changeElementWrapper";

// FIXME: Return to using explicit cross frame entry points after roll to M35
Native_DOMWindowCrossFrame_get_history(_DOMWindowCrossFrame) native "Window_history_cross_frame_Getter";

Native_DOMWindowCrossFrame_get_location(_DOMWindowCrossFrame) native "Window_location_cross_frame_Getter";

Native_DOMWindowCrossFrame_get_closed(_DOMWindowCrossFrame) native "Window_closed_Getter";

Native_DOMWindowCrossFrame_get_opener(_DOMWindowCrossFrame) native "Window_opener_Getter";

Native_DOMWindowCrossFrame_get_parent(_DOMWindowCrossFrame) native "Window_parent_Getter";

Native_DOMWindowCrossFrame_get_top(_DOMWindowCrossFrame) native "Window_top_Getter";

Native_DOMWindowCrossFrame_close(_DOMWindowCrossFrame) native "Window_close_Callback_RESOLVER_STRING_0_";

Native_DOMWindowCrossFrame_postMessage(_DOMWindowCrossFrame, message, targetOrigin, [messagePorts]) native "Window_postMessage_Callback";

// _HistoryCrossFrame native entry points
Native_HistoryCrossFrame_back(_HistoryCrossFrame) native "History_back_Callback_RESOLVER_STRING_0_";

Native_HistoryCrossFrame_forward(_HistoryCrossFrame) native "History_forward_Callback_RESOLVER_STRING_0_";

Native_HistoryCrossFrame_go(_HistoryCrossFrame, distance) native "History_go_Callback_RESOLVER_STRING_1_long";

// _LocationCrossFrame native entry points
Native_LocationCrossFrame_set_href(_LocationCrossFrame, h) native "Location_href_Setter";

// _DOMStringMap native entry  points
Native_DOMStringMap_containsKey(_DOMStringMap, key) native "DOMStringMap_containsKey_Callback";

Native_DOMStringMap_item(_DOMStringMap, key) native "DOMStringMap_item_Callback";

Native_DOMStringMap_setItem(_DOMStringMap, key, value) native "DOMStringMap_setItem_Callback";

Native_DOMStringMap_remove(_DOMStringMap, key) native "DOMStringMap_remove_Callback";

Native_DOMStringMap_get_keys(_DOMStringMap) native "DOMStringMap_getKeys_Callback";
