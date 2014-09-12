/**
 * This library provides entry points to the native Blink code which backs
 * up the dart:html library.
 */
library dart.dom._blink;

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// DO NOT EDIT
// Auto-generated dart:_blink library.




class BlinkANGLEInstancedArrays {
  static drawArraysInstancedANGLE_Callback_ul_long_long_long(mthis, mode, first, count, primcount) native "ANGLEInstancedArrays_drawArraysInstancedANGLE_Callback_unsigned long_long_long_long";

  static drawElementsInstancedANGLE_Callback_ul_long_ul_ll_long(mthis, mode, count, type, offset, primcount) native "ANGLEInstancedArrays_drawElementsInstancedANGLE_Callback_unsigned long_long_unsigned long_long long_long";

  static vertexAttribDivisorANGLE_Callback_ul_long(mthis, index, divisor) native "ANGLEInstancedArrays_vertexAttribDivisorANGLE_Callback_unsigned long_long";
}

class BlinkAbstractWorker {}

class BlinkKeyAlgorithm {
  static name_Getter(mthis) native "KeyAlgorithm_name_Getter";
}

class BlinkAesKeyAlgorithm {
  static length_Getter(mthis) native "AesKeyAlgorithm_length_Getter";
}

class BlinkEventTarget {
  static addEventListener_Callback_DOMString_EventListener_boolean(mthis, type, listener, useCapture) native "EventTarget_addEventListener_Callback_DOMString_EventListener_boolean";

  static addEventListener_Callback_DOMString(mthis, type) native "EventTarget_addEventListener_Callback_DOMString";

  static addEventListener_Callback(mthis) native "EventTarget_addEventListener_Callback";

  static dispatchEvent_Callback_Event(mthis, event) native "EventTarget_dispatchEvent_Callback_Event";

  static removeEventListener_Callback_DOMString_EventListener_boolean(mthis, type, listener, useCapture) native "EventTarget_removeEventListener_Callback_DOMString_EventListener_boolean";

  static removeEventListener_Callback_DOMString(mthis, type) native "EventTarget_removeEventListener_Callback_DOMString";

  static removeEventListener_Callback(mthis) native "EventTarget_removeEventListener_Callback";
}

class BlinkAudioNode {
  static channelCount_Getter(mthis) native "AudioNode_channelCount_Getter";

  static channelCount_Setter_ul(mthis, value) native "AudioNode_channelCount_Setter";

  static channelCountMode_Getter(mthis) native "AudioNode_channelCountMode_Getter";

  static channelCountMode_Setter_DOMString(mthis, value) native "AudioNode_channelCountMode_Setter";

  static channelInterpretation_Getter(mthis) native "AudioNode_channelInterpretation_Getter";

  static channelInterpretation_Setter_DOMString(mthis, value) native "AudioNode_channelInterpretation_Setter";

  static context_Getter(mthis) native "AudioNode_context_Getter";

  static numberOfInputs_Getter(mthis) native "AudioNode_numberOfInputs_Getter";

  static numberOfOutputs_Getter(mthis) native "AudioNode_numberOfOutputs_Getter";

  static connect_Callback_AudioNode_ul_ul(mthis, destination, output, input) native "AudioNode_connect_Callback_AudioNode_unsigned long_unsigned long";

  static connect_Callback_AudioParam_ul(mthis, destination, output) native "AudioNode_connect_Callback_AudioParam_unsigned long";

  static disconnect_Callback_ul(mthis, output) native "AudioNode_disconnect_Callback_unsigned long";
}

class BlinkAnalyserNode {
  static fftSize_Getter(mthis) native "AnalyserNode_fftSize_Getter";

  static fftSize_Setter_ul(mthis, value) native "AnalyserNode_fftSize_Setter";

  static frequencyBinCount_Getter(mthis) native "AnalyserNode_frequencyBinCount_Getter";

  static maxDecibels_Getter(mthis) native "AnalyserNode_maxDecibels_Getter";

  static maxDecibels_Setter_double(mthis, value) native "AnalyserNode_maxDecibels_Setter";

  static minDecibels_Getter(mthis) native "AnalyserNode_minDecibels_Getter";

  static minDecibels_Setter_double(mthis, value) native "AnalyserNode_minDecibels_Setter";

  static smoothingTimeConstant_Getter(mthis) native "AnalyserNode_smoothingTimeConstant_Getter";

  static smoothingTimeConstant_Setter_double(mthis, value) native "AnalyserNode_smoothingTimeConstant_Setter";

  static getByteFrequencyData_Callback_Uint8Array(mthis, array) native "AnalyserNode_getByteFrequencyData_Callback_Uint8Array";

  static getByteTimeDomainData_Callback_Uint8Array(mthis, array) native "AnalyserNode_getByteTimeDomainData_Callback_Uint8Array";

  static getFloatFrequencyData_Callback_Float32Array(mthis, array) native "AnalyserNode_getFloatFrequencyData_Callback_Float32Array";

  static getFloatTimeDomainData_Callback_Float32Array(mthis, array) native "AnalyserNode_getFloatTimeDomainData_Callback_Float32Array";
}

class BlinkAnimationNode {
  static activeDuration_Getter(mthis) native "AnimationNode_activeDuration_Getter";

  static currentIteration_Getter(mthis) native "AnimationNode_currentIteration_Getter";

  static duration_Getter(mthis) native "AnimationNode_duration_Getter";

  static endTime_Getter(mthis) native "AnimationNode_endTime_Getter";

  static localTime_Getter(mthis) native "AnimationNode_localTime_Getter";

  static player_Getter(mthis) native "AnimationNode_player_Getter";

  static startTime_Getter(mthis) native "AnimationNode_startTime_Getter";

  static timing_Getter(mthis) native "AnimationNode_timing_Getter";
}

class BlinkAnimation {
  static constructorCallback_Element_SEQ_Dictionary_SEQ(target, keyframes) native "Animation_constructorCallback_Element_sequence<Dictionary>";

  static constructorCallback_Element_SEQ_Dictionary_SEQ_double(target, keyframes, timingInput) native "Animation_constructorCallback_Element_sequence<Dictionary>_double";

  static constructorCallback_Element_SEQ_Dictionary_SEQ_Dictionary(target, keyframes, timingInput) native "Animation_constructorCallback_Element_sequence<Dictionary>_Dictionary";
}

class BlinkAnimationEffect {}

class BlinkAnimationPlayer {
  static currentTime_Getter(mthis) native "AnimationPlayer_currentTime_Getter";

  static currentTime_Setter_double(mthis, value) native "AnimationPlayer_currentTime_Setter";

  static finished_Getter(mthis) native "AnimationPlayer_finished_Getter";

  static paused_Getter(mthis) native "AnimationPlayer_paused_Getter";

  static playbackRate_Getter(mthis) native "AnimationPlayer_playbackRate_Getter";

  static playbackRate_Setter_double(mthis, value) native "AnimationPlayer_playbackRate_Setter";

  static source_Getter(mthis) native "AnimationPlayer_source_Getter";

  static source_Setter_AnimationNode(mthis, value) native "AnimationPlayer_source_Setter";

  static startTime_Getter(mthis) native "AnimationPlayer_startTime_Getter";

  static startTime_Setter_double(mthis, value) native "AnimationPlayer_startTime_Setter";

  static timeLag_Getter(mthis) native "AnimationPlayer_timeLag_Getter";

  static cancel_Callback(mthis) native "AnimationPlayer_cancel_Callback";

  static finish_Callback(mthis) native "AnimationPlayer_finish_Callback";

  static pause_Callback(mthis) native "AnimationPlayer_pause_Callback";

  static play_Callback(mthis) native "AnimationPlayer_play_Callback";

  static reverse_Callback(mthis) native "AnimationPlayer_reverse_Callback";
}

class BlinkEvent {
  static bubbles_Getter(mthis) native "Event_bubbles_Getter";

  static cancelable_Getter(mthis) native "Event_cancelable_Getter";

  static clipboardData_Getter(mthis) native "Event_clipboardData_Getter";

  static currentTarget_Getter(mthis) native "Event_currentTarget_Getter";

  static defaultPrevented_Getter(mthis) native "Event_defaultPrevented_Getter";

  static eventPhase_Getter(mthis) native "Event_eventPhase_Getter";

  static path_Getter(mthis) native "Event_path_Getter";

  static target_Getter(mthis) native "Event_target_Getter";

  static timeStamp_Getter(mthis) native "Event_timeStamp_Getter";

  static type_Getter(mthis) native "Event_type_Getter";

  static initEvent_Callback_DOMString_boolean_boolean(mthis, eventTypeArg, canBubbleArg, cancelableArg) native "Event_initEvent_Callback_DOMString_boolean_boolean";

  static preventDefault_Callback(mthis) native "Event_preventDefault_Callback";

  static stopImmediatePropagation_Callback(mthis) native "Event_stopImmediatePropagation_Callback";

  static stopPropagation_Callback(mthis) native "Event_stopPropagation_Callback";
}

class BlinkAnimationPlayerEvent {
  static currentTime_Getter(mthis) native "AnimationPlayerEvent_currentTime_Getter";

  static timelineTime_Getter(mthis) native "AnimationPlayerEvent_timelineTime_Getter";
}

class BlinkAnimationTimeline {
  static currentTime_Getter(mthis) native "AnimationTimeline_currentTime_Getter";

  static play_Callback_AnimationNode(mthis, source) native "AnimationTimeline_play_Callback_AnimationNode";
}

class BlinkApplicationCache {
  static status_Getter(mthis) native "ApplicationCache_status_Getter";

  static abort_Callback(mthis) native "ApplicationCache_abort_Callback";

  static swapCache_Callback(mthis) native "ApplicationCache_swapCache_Callback";

  static update_Callback(mthis) native "ApplicationCache_update_Callback";
}

class BlinkApplicationCacheErrorEvent {
  static message_Getter(mthis) native "ApplicationCacheErrorEvent_message_Getter";

  static reason_Getter(mthis) native "ApplicationCacheErrorEvent_reason_Getter";

  static status_Getter(mthis) native "ApplicationCacheErrorEvent_status_Getter";

  static url_Getter(mthis) native "ApplicationCacheErrorEvent_url_Getter";
}

class BlinkNode {
  static baseURI_Getter(mthis) native "Node_baseURI_Getter";

  static childNodes_Getter(mthis) native "Node_childNodes_Getter";

  static firstChild_Getter(mthis) native "Node_firstChild_Getter";

  static lastChild_Getter(mthis) native "Node_lastChild_Getter";

  static localName_Getter(mthis) native "Node_localName_Getter";

  static namespaceURI_Getter(mthis) native "Node_namespaceURI_Getter";

  static nextSibling_Getter(mthis) native "Node_nextSibling_Getter";

  static nodeName_Getter(mthis) native "Node_nodeName_Getter";

  static nodeType_Getter(mthis) native "Node_nodeType_Getter";

  static nodeValue_Getter(mthis) native "Node_nodeValue_Getter";

  static ownerDocument_Getter(mthis) native "Node_ownerDocument_Getter";

  static parentElement_Getter(mthis) native "Node_parentElement_Getter";

  static parentNode_Getter(mthis) native "Node_parentNode_Getter";

  static previousSibling_Getter(mthis) native "Node_previousSibling_Getter";

  static textContent_Getter(mthis) native "Node_textContent_Getter";

  static textContent_Setter_DOMString(mthis, value) native "Node_textContent_Setter";

  static appendChild_Callback_Node(mthis, newChild) native "Node_appendChild_Callback";

  static cloneNode_Callback_boolean(mthis, deep) native "Node_cloneNode_Callback";

  static contains_Callback_Node(mthis, other) native "Node_contains_Callback_Node";

  static hasChildNodes_Callback(mthis) native "Node_hasChildNodes_Callback";

  static insertBefore_Callback_Node_Node(mthis, newChild, refChild) native "Node_insertBefore_Callback";

  static removeChild_Callback_Node(mthis, oldChild) native "Node_removeChild_Callback";

  static replaceChild_Callback_Node_Node(mthis, newChild, oldChild) native "Node_replaceChild_Callback";
}

class BlinkAttr {
  static localName_Getter(mthis) native "Attr_localName_Getter";

  static name_Getter(mthis) native "Attr_name_Getter";

  static namespaceURI_Getter(mthis) native "Attr_namespaceURI_Getter";

  static nodeValue_Getter(mthis) native "Attr_nodeValue_Getter";

  static textContent_Getter(mthis) native "Attr_textContent_Getter";

  static textContent_Setter_DOMString(mthis, value) native "Attr_textContent_Setter";

  static value_Getter(mthis) native "Attr_value_Getter";

  static value_Setter_DOMString(mthis, value) native "Attr_value_Setter";
}

class BlinkAudioBuffer {
  static duration_Getter(mthis) native "AudioBuffer_duration_Getter";

  static length_Getter(mthis) native "AudioBuffer_length_Getter";

  static numberOfChannels_Getter(mthis) native "AudioBuffer_numberOfChannels_Getter";

  static sampleRate_Getter(mthis) native "AudioBuffer_sampleRate_Getter";

  static getChannelData_Callback_ul(mthis, channelIndex) native "AudioBuffer_getChannelData_Callback_unsigned long";
}

class BlinkAudioSourceNode {}

class BlinkAudioBufferSourceNode {
  static buffer_Getter(mthis) native "AudioBufferSourceNode_buffer_Getter";

  static buffer_Setter_AudioBuffer(mthis, value) native "AudioBufferSourceNode_buffer_Setter";

  static loop_Getter(mthis) native "AudioBufferSourceNode_loop_Getter";

  static loop_Setter_boolean(mthis, value) native "AudioBufferSourceNode_loop_Setter";

  static loopEnd_Getter(mthis) native "AudioBufferSourceNode_loopEnd_Getter";

  static loopEnd_Setter_double(mthis, value) native "AudioBufferSourceNode_loopEnd_Setter";

  static loopStart_Getter(mthis) native "AudioBufferSourceNode_loopStart_Getter";

  static loopStart_Setter_double(mthis, value) native "AudioBufferSourceNode_loopStart_Setter";

  static playbackRate_Getter(mthis) native "AudioBufferSourceNode_playbackRate_Getter";

  static start_Callback_double_double_double(mthis, when, grainOffset, grainDuration) native "AudioBufferSourceNode_start_Callback_double_double_double";

  static start_Callback_double_double(mthis, when, grainOffset) native "AudioBufferSourceNode_start_Callback_double_double";

  static start_Callback_double(mthis, when) native "AudioBufferSourceNode_start_Callback_double";

  static start_Callback(mthis) native "AudioBufferSourceNode_start_Callback";

  static stop_Callback_double(mthis, when) native "AudioBufferSourceNode_stop_Callback_double";

  static stop_Callback(mthis) native "AudioBufferSourceNode_stop_Callback";
}

class BlinkAudioContext {
  static constructorCallback() native "AudioContext_constructorCallback";

  static currentTime_Getter(mthis) native "AudioContext_currentTime_Getter";

  static destination_Getter(mthis) native "AudioContext_destination_Getter";

  static listener_Getter(mthis) native "AudioContext_listener_Getter";

  static sampleRate_Getter(mthis) native "AudioContext_sampleRate_Getter";

  static createAnalyser_Callback(mthis) native "AudioContext_createAnalyser_Callback";

  static createBiquadFilter_Callback(mthis) native "AudioContext_createBiquadFilter_Callback";

  static createBuffer_Callback_ul_ul_float(mthis, numberOfChannels, numberOfFrames, sampleRate) native "AudioContext_createBuffer_Callback_unsigned long_unsigned long_float";

  static createBufferSource_Callback(mthis) native "AudioContext_createBufferSource_Callback";

  static createChannelMerger_Callback_ul(mthis, numberOfInputs) native "AudioContext_createChannelMerger_Callback_unsigned long";

  static createChannelMerger_Callback(mthis) native "AudioContext_createChannelMerger_Callback";

  static createChannelSplitter_Callback_ul(mthis, numberOfOutputs) native "AudioContext_createChannelSplitter_Callback_unsigned long";

  static createChannelSplitter_Callback(mthis) native "AudioContext_createChannelSplitter_Callback";

  static createConvolver_Callback(mthis) native "AudioContext_createConvolver_Callback";

  static createDelay_Callback_double(mthis, maxDelayTime) native "AudioContext_createDelay_Callback_double";

  static createDelay_Callback(mthis) native "AudioContext_createDelay_Callback";

  static createDynamicsCompressor_Callback(mthis) native "AudioContext_createDynamicsCompressor_Callback";

  static createGain_Callback(mthis) native "AudioContext_createGain_Callback";

  static createMediaElementSource_Callback_HTMLMediaElement(mthis, mediaElement) native "AudioContext_createMediaElementSource_Callback_HTMLMediaElement";

  static createMediaStreamDestination_Callback(mthis) native "AudioContext_createMediaStreamDestination_Callback";

  static createMediaStreamSource_Callback_MediaStream(mthis, mediaStream) native "AudioContext_createMediaStreamSource_Callback_MediaStream";

  static createOscillator_Callback(mthis) native "AudioContext_createOscillator_Callback";

  static createPanner_Callback(mthis) native "AudioContext_createPanner_Callback";

  static createPeriodicWave_Callback_Float32Array_Float32Array(mthis, real, imag) native "AudioContext_createPeriodicWave_Callback_Float32Array_Float32Array";

  static createScriptProcessor_Callback_ul_ul_ul(mthis, bufferSize, numberOfInputChannels, numberOfOutputChannels) native "AudioContext_createScriptProcessor_Callback_unsigned long_unsigned long_unsigned long";

  static createScriptProcessor_Callback_ul_ul(mthis, bufferSize, numberOfInputChannels) native "AudioContext_createScriptProcessor_Callback_unsigned long_unsigned long";

  static createScriptProcessor_Callback_ul(mthis, bufferSize) native "AudioContext_createScriptProcessor_Callback_unsigned long";

  static createScriptProcessor_Callback(mthis) native "AudioContext_createScriptProcessor_Callback";

  static createWaveShaper_Callback(mthis) native "AudioContext_createWaveShaper_Callback";

  static decodeAudioData_Callback_ArrayBuffer_AudioBufferCallback_AudioBufferCallback(mthis, audioData, successCallback, errorCallback) native "AudioContext_decodeAudioData_Callback";

  static startRendering_Callback(mthis) native "AudioContext_startRendering_Callback";
}

class BlinkAudioDestinationNode {
  static maxChannelCount_Getter(mthis) native "AudioDestinationNode_maxChannelCount_Getter";
}

class BlinkAudioListener {
  static dopplerFactor_Getter(mthis) native "AudioListener_dopplerFactor_Getter";

  static dopplerFactor_Setter_float(mthis, value) native "AudioListener_dopplerFactor_Setter";

  static speedOfSound_Getter(mthis) native "AudioListener_speedOfSound_Getter";

  static speedOfSound_Setter_float(mthis, value) native "AudioListener_speedOfSound_Setter";

  static setOrientation_Callback_float_float_float_float_float_float(mthis, x, y, z, xUp, yUp, zUp) native "AudioListener_setOrientation_Callback_float_float_float_float_float_float";

  static setPosition_Callback_float_float_float(mthis, x, y, z) native "AudioListener_setPosition_Callback_float_float_float";

  static setVelocity_Callback_float_float_float(mthis, x, y, z) native "AudioListener_setVelocity_Callback_float_float_float";
}

class BlinkAudioParam {
  static defaultValue_Getter(mthis) native "AudioParam_defaultValue_Getter";

  static maxValue_Getter(mthis) native "AudioParam_maxValue_Getter";

  static minValue_Getter(mthis) native "AudioParam_minValue_Getter";

  static name_Getter(mthis) native "AudioParam_name_Getter";

  static units_Getter(mthis) native "AudioParam_units_Getter";

  static value_Getter(mthis) native "AudioParam_value_Getter";

  static value_Setter_float(mthis, value) native "AudioParam_value_Setter";

  static cancelScheduledValues_Callback_double(mthis, startTime) native "AudioParam_cancelScheduledValues_Callback_double";

  static exponentialRampToValueAtTime_Callback_float_double(mthis, value, time) native "AudioParam_exponentialRampToValueAtTime_Callback_float_double";

  static linearRampToValueAtTime_Callback_float_double(mthis, value, time) native "AudioParam_linearRampToValueAtTime_Callback_float_double";

  static setTargetAtTime_Callback_float_double_double(mthis, target, time, timeConstant) native "AudioParam_setTargetAtTime_Callback_float_double_double";

  static setValueAtTime_Callback_float_double(mthis, value, time) native "AudioParam_setValueAtTime_Callback_float_double";

  static setValueCurveAtTime_Callback_Float32Array_double_double(mthis, values, time, duration) native "AudioParam_setValueCurveAtTime_Callback";
}

class BlinkAudioProcessingEvent {
  static inputBuffer_Getter(mthis) native "AudioProcessingEvent_inputBuffer_Getter";

  static outputBuffer_Getter(mthis) native "AudioProcessingEvent_outputBuffer_Getter";

  static playbackTime_Getter(mthis) native "AudioProcessingEvent_playbackTime_Getter";
}

class BlinkAudioTrack {
  static enabled_Getter(mthis) native "AudioTrack_enabled_Getter";

  static enabled_Setter_boolean(mthis, value) native "AudioTrack_enabled_Setter";

  static id_Getter(mthis) native "AudioTrack_id_Getter";

  static kind_Getter(mthis) native "AudioTrack_kind_Getter";

  static label_Getter(mthis) native "AudioTrack_label_Getter";

  static language_Getter(mthis) native "AudioTrack_language_Getter";
}

class BlinkAudioTrackList {
  static length_Getter(mthis) native "AudioTrackList_length_Getter";

  static $__getter___Callback_ul(mthis, index) native "AudioTrackList___getter___Callback_unsigned long";

  static getTrackById_Callback_DOMString(mthis, id) native "AudioTrackList_getTrackById_Callback_DOMString";
}

class BlinkAutocompleteErrorEvent {
  static reason_Getter(mthis) native "AutocompleteErrorEvent_reason_Getter";
}

class BlinkBarProp {
  static visible_Getter(mthis) native "BarProp_visible_Getter";
}

class BlinkBatteryManager {
  static charging_Getter(mthis) native "BatteryManager_charging_Getter";

  static chargingTime_Getter(mthis) native "BatteryManager_chargingTime_Getter";

  static dischargingTime_Getter(mthis) native "BatteryManager_dischargingTime_Getter";

  static level_Getter(mthis) native "BatteryManager_level_Getter";
}

class BlinkBeforeUnloadEvent {
  static returnValue_Getter(mthis) native "BeforeUnloadEvent_returnValue_Getter";

  static returnValue_Setter_DOMString(mthis, value) native "BeforeUnloadEvent_returnValue_Setter";
}

class BlinkBiquadFilterNode {
  static Q_Getter(mthis) native "BiquadFilterNode_Q_Getter";

  static detune_Getter(mthis) native "BiquadFilterNode_detune_Getter";

  static frequency_Getter(mthis) native "BiquadFilterNode_frequency_Getter";

  static gain_Getter(mthis) native "BiquadFilterNode_gain_Getter";

  static type_Getter(mthis) native "BiquadFilterNode_type_Getter";

  static type_Setter_DOMString(mthis, value) native "BiquadFilterNode_type_Setter";

  static getFrequencyResponse_Callback_Float32Array_Float32Array_Float32Array(mthis, frequencyHz, magResponse, phaseResponse) native "BiquadFilterNode_getFrequencyResponse_Callback_Float32Array_Float32Array_Float32Array";
}

class BlinkBlob {
  static constructorCallback_Array_DOMString_DOMString(blobParts, type, endings) native "Blob_constructorCallback";

  static size_Getter(mthis) native "Blob_size_Getter";

  static type_Getter(mthis) native "Blob_type_Getter";

  static close_Callback(mthis) native "Blob_close_Callback";

  static slice_Callback_ll_ll_DOMString(mthis, start, end, contentType) native "Blob_slice_Callback_long long_long long_DOMString";

  static slice_Callback_ll_ll(mthis, start, end) native "Blob_slice_Callback_long long_long long";

  static slice_Callback_ll(mthis, start) native "Blob_slice_Callback_long long";

  static slice_Callback(mthis) native "Blob_slice_Callback";
}

class BlinkChildNode {
  static nextElementSibling_Getter(mthis) native "ChildNode_nextElementSibling_Getter";

  static previousElementSibling_Getter(mthis) native "ChildNode_previousElementSibling_Getter";

  static remove_Callback(mthis) native "ChildNode_remove_Callback";
}

class BlinkCharacterData {
  static data_Getter(mthis) native "CharacterData_data_Getter";

  static data_Setter_DOMString(mthis, value) native "CharacterData_data_Setter";

  static length_Getter(mthis) native "CharacterData_length_Getter";

  static appendData_Callback_DOMString(mthis, data) native "CharacterData_appendData_Callback_DOMString";

  static deleteData_Callback_ul_ul(mthis, offset, length) native "CharacterData_deleteData_Callback_unsigned long_unsigned long";

  static insertData_Callback_ul_DOMString(mthis, offset, data) native "CharacterData_insertData_Callback_unsigned long_DOMString";

  static replaceData_Callback_ul_ul_DOMString(mthis, offset, length, data) native "CharacterData_replaceData_Callback_unsigned long_unsigned long_DOMString";

  static substringData_Callback_ul_ul(mthis, offset, length) native "CharacterData_substringData_Callback_unsigned long_unsigned long";

  static nextElementSibling_Getter(mthis) native "CharacterData_nextElementSibling_Getter";

  static previousElementSibling_Getter(mthis) native "CharacterData_previousElementSibling_Getter";
}

class BlinkText {
  static wholeText_Getter(mthis) native "Text_wholeText_Getter";

  static getDestinationInsertionPoints_Callback(mthis) native "Text_getDestinationInsertionPoints_Callback";

  static splitText_Callback_ul(mthis, offset) native "Text_splitText_Callback_unsigned long";
}

class BlinkCDATASection {}

class BlinkCSS {
  static supports_Callback_DOMString_DOMString(mthis, property, value) native "CSS_supports_Callback_DOMString_DOMString";

  static supports_Callback_DOMString(mthis, conditionText) native "CSS_supports_Callback_DOMString";
}

class BlinkCSSRule {
  static cssText_Getter(mthis) native "CSSRule_cssText_Getter";

  static cssText_Setter_DOMString(mthis, value) native "CSSRule_cssText_Setter";

  static parentRule_Getter(mthis) native "CSSRule_parentRule_Getter";

  static parentStyleSheet_Getter(mthis) native "CSSRule_parentStyleSheet_Getter";

  static type_Getter(mthis) native "CSSRule_type_Getter";
}

class BlinkCSSCharsetRule {
  static encoding_Getter(mthis) native "CSSCharsetRule_encoding_Getter";

  static encoding_Setter_DOMString(mthis, value) native "CSSCharsetRule_encoding_Setter";
}

class BlinkCSSFontFaceLoadEvent {
  static fontfaces_Getter(mthis) native "CSSFontFaceLoadEvent_fontfaces_Getter";
}

class BlinkCSSFontFaceRule {
  static style_Getter(mthis) native "CSSFontFaceRule_style_Getter";
}

class BlinkCSSImportRule {
  static href_Getter(mthis) native "CSSImportRule_href_Getter";

  static media_Getter(mthis) native "CSSImportRule_media_Getter";

  static styleSheet_Getter(mthis) native "CSSImportRule_styleSheet_Getter";
}

class BlinkCSSKeyframeRule {
  static keyText_Getter(mthis) native "CSSKeyframeRule_keyText_Getter";

  static keyText_Setter_DOMString(mthis, value) native "CSSKeyframeRule_keyText_Setter";

  static style_Getter(mthis) native "CSSKeyframeRule_style_Getter";
}

class BlinkCSSKeyframesRule {
  static cssRules_Getter(mthis) native "CSSKeyframesRule_cssRules_Getter";

  static name_Getter(mthis) native "CSSKeyframesRule_name_Getter";

  static name_Setter_DOMString(mthis, value) native "CSSKeyframesRule_name_Setter";

  static $__getter___Callback_ul(mthis, index) native "CSSKeyframesRule___getter___Callback_unsigned long";

  static deleteRule_Callback_DOMString(mthis, key) native "CSSKeyframesRule_deleteRule_Callback_DOMString";

  static findRule_Callback_DOMString(mthis, key) native "CSSKeyframesRule_findRule_Callback_DOMString";

  static insertRule_Callback_DOMString(mthis, rule) native "CSSKeyframesRule_insertRule_Callback_DOMString";
}

class BlinkCSSMediaRule {
  static cssRules_Getter(mthis) native "CSSMediaRule_cssRules_Getter";

  static media_Getter(mthis) native "CSSMediaRule_media_Getter";

  static deleteRule_Callback_ul(mthis, index) native "CSSMediaRule_deleteRule_Callback_unsigned long";

  static insertRule_Callback_DOMString_ul(mthis, rule, index) native "CSSMediaRule_insertRule_Callback_DOMString_unsigned long";
}

class BlinkCSSPageRule {
  static selectorText_Getter(mthis) native "CSSPageRule_selectorText_Getter";

  static selectorText_Setter_DOMString(mthis, value) native "CSSPageRule_selectorText_Setter";

  static style_Getter(mthis) native "CSSPageRule_style_Getter";
}

class BlinkCSSValue {}

class BlinkCSSPrimitiveValue {}

class BlinkCSSRuleList {
  static length_Getter(mthis) native "CSSRuleList_length_Getter";

  static item_Callback_ul(mthis, index) native "CSSRuleList_item_Callback_unsigned long";
}

class BlinkCSSStyleDeclaration {
  static cssText_Getter(mthis) native "CSSStyleDeclaration_cssText_Getter";

  static cssText_Setter_DOMString(mthis, value) native "CSSStyleDeclaration_cssText_Setter";

  static length_Getter(mthis) native "CSSStyleDeclaration_length_Getter";

  static parentRule_Getter(mthis) native "CSSStyleDeclaration_parentRule_Getter";

  static $__getter___Callback_DOMString(mthis, name) native "CSSStyleDeclaration___getter___Callback";

  static $__propertyQuery___Callback_DOMString(mthis, name) native "CSSStyleDeclaration___propertyQuery___Callback";

  static $__setter___Callback_DOMString_DOMString(mthis, propertyName, propertyValue) native "CSSStyleDeclaration___setter___Callback";

  static getPropertyPriority_Callback_DOMString(mthis, propertyName) native "CSSStyleDeclaration_getPropertyPriority_Callback_DOMString";

  static getPropertyValue_Callback_DOMString(mthis, propertyName) native "CSSStyleDeclaration_getPropertyValue_Callback_DOMString";

  static item_Callback_ul(mthis, index) native "CSSStyleDeclaration_item_Callback_unsigned long";

  static removeProperty_Callback_DOMString(mthis, propertyName) native "CSSStyleDeclaration_removeProperty_Callback_DOMString";

  static setProperty_Callback_DOMString_DOMString_DOMString(mthis, propertyName, value, priority) native "CSSStyleDeclaration_setProperty_Callback_DOMString_DOMString_DOMString";
}

class BlinkCSSStyleRule {
  static selectorText_Getter(mthis) native "CSSStyleRule_selectorText_Getter";

  static selectorText_Setter_DOMString(mthis, value) native "CSSStyleRule_selectorText_Setter";

  static style_Getter(mthis) native "CSSStyleRule_style_Getter";
}

class BlinkStyleSheet {
  static disabled_Getter(mthis) native "StyleSheet_disabled_Getter";

  static disabled_Setter_boolean(mthis, value) native "StyleSheet_disabled_Setter";

  static href_Getter(mthis) native "StyleSheet_href_Getter";

  static media_Getter(mthis) native "StyleSheet_media_Getter";

  static ownerNode_Getter(mthis) native "StyleSheet_ownerNode_Getter";

  static parentStyleSheet_Getter(mthis) native "StyleSheet_parentStyleSheet_Getter";

  static title_Getter(mthis) native "StyleSheet_title_Getter";

  static type_Getter(mthis) native "StyleSheet_type_Getter";
}

class BlinkCSSStyleSheet {
  static cssRules_Getter(mthis) native "CSSStyleSheet_cssRules_Getter";

  static ownerRule_Getter(mthis) native "CSSStyleSheet_ownerRule_Getter";

  static rules_Getter(mthis) native "CSSStyleSheet_rules_Getter";

  static addRule_Callback_DOMString_DOMString_ul(mthis, selector, style, index) native "CSSStyleSheet_addRule_Callback_DOMString_DOMString_unsigned long";

  static addRule_Callback_DOMString_DOMString(mthis, selector, style) native "CSSStyleSheet_addRule_Callback_DOMString_DOMString";

  static deleteRule_Callback_ul(mthis, index) native "CSSStyleSheet_deleteRule_Callback_unsigned long";

  static insertRule_Callback_DOMString_ul(mthis, rule, index) native "CSSStyleSheet_insertRule_Callback_DOMString_unsigned long";

  static insertRule_Callback_DOMString(mthis, rule) native "CSSStyleSheet_insertRule_Callback_DOMString";

  static removeRule_Callback_ul(mthis, index) native "CSSStyleSheet_removeRule_Callback_unsigned long";
}

class BlinkCSSSupportsRule {
  static conditionText_Getter(mthis) native "CSSSupportsRule_conditionText_Getter";

  static cssRules_Getter(mthis) native "CSSSupportsRule_cssRules_Getter";

  static deleteRule_Callback_ul(mthis, index) native "CSSSupportsRule_deleteRule_Callback_unsigned long";

  static insertRule_Callback_DOMString_ul(mthis, rule, index) native "CSSSupportsRule_insertRule_Callback_DOMString_unsigned long";
}

class BlinkCSSUnknownRule {}

class BlinkCSSValueList {
  static length_Getter(mthis) native "CSSValueList_length_Getter";

  static item_Callback_ul(mthis, index) native "CSSValueList_item_Callback_unsigned long";
}

class BlinkCSSViewportRule {
  static style_Getter(mthis) native "CSSViewportRule_style_Getter";
}

class BlinkCanvas2DContextAttributes {
  static alpha_Getter(mthis) native "Canvas2DContextAttributes_alpha_Getter";

  static alpha_Setter_boolean(mthis, value) native "Canvas2DContextAttributes_alpha_Setter";

  static storage_Getter(mthis) native "Canvas2DContextAttributes_storage_Getter";

  static storage_Setter_DOMString(mthis, value) native "Canvas2DContextAttributes_storage_Setter";
}

class BlinkCanvasGradient {
  static addColorStop_Callback_float_DOMString(mthis, offset, color) native "CanvasGradient_addColorStop_Callback_float_DOMString";
}

class BlinkCanvasPathMethods {}

class BlinkCanvasPattern {}

class BlinkCanvasRenderingContext2D {
  static canvas_Getter(mthis) native "CanvasRenderingContext2D_canvas_Getter";

  static currentTransform_Getter(mthis) native "CanvasRenderingContext2D_currentTransform_Getter";

  static currentTransform_Setter_SVGMatrix(mthis, value) native "CanvasRenderingContext2D_currentTransform_Setter";

  static fillStyle_Getter(mthis) native "CanvasRenderingContext2D_fillStyle_Getter";

  static fillStyle_Setter_object(mthis, value) native "CanvasRenderingContext2D_fillStyle_Setter";

  static font_Getter(mthis) native "CanvasRenderingContext2D_font_Getter";

  static font_Setter_DOMString(mthis, value) native "CanvasRenderingContext2D_font_Setter";

  static globalAlpha_Getter(mthis) native "CanvasRenderingContext2D_globalAlpha_Getter";

  static globalAlpha_Setter_float(mthis, value) native "CanvasRenderingContext2D_globalAlpha_Setter";

  static globalCompositeOperation_Getter(mthis) native "CanvasRenderingContext2D_globalCompositeOperation_Getter";

  static globalCompositeOperation_Setter_DOMString(mthis, value) native "CanvasRenderingContext2D_globalCompositeOperation_Setter";

  static imageSmoothingEnabled_Getter(mthis) native "CanvasRenderingContext2D_imageSmoothingEnabled_Getter";

  static imageSmoothingEnabled_Setter_boolean(mthis, value) native "CanvasRenderingContext2D_imageSmoothingEnabled_Setter";

  static lineCap_Getter(mthis) native "CanvasRenderingContext2D_lineCap_Getter";

  static lineCap_Setter_DOMString(mthis, value) native "CanvasRenderingContext2D_lineCap_Setter";

  static lineDashOffset_Getter(mthis) native "CanvasRenderingContext2D_lineDashOffset_Getter";

  static lineDashOffset_Setter_float(mthis, value) native "CanvasRenderingContext2D_lineDashOffset_Setter";

  static lineJoin_Getter(mthis) native "CanvasRenderingContext2D_lineJoin_Getter";

  static lineJoin_Setter_DOMString(mthis, value) native "CanvasRenderingContext2D_lineJoin_Setter";

  static lineWidth_Getter(mthis) native "CanvasRenderingContext2D_lineWidth_Getter";

  static lineWidth_Setter_float(mthis, value) native "CanvasRenderingContext2D_lineWidth_Setter";

  static miterLimit_Getter(mthis) native "CanvasRenderingContext2D_miterLimit_Getter";

  static miterLimit_Setter_float(mthis, value) native "CanvasRenderingContext2D_miterLimit_Setter";

  static shadowBlur_Getter(mthis) native "CanvasRenderingContext2D_shadowBlur_Getter";

  static shadowBlur_Setter_float(mthis, value) native "CanvasRenderingContext2D_shadowBlur_Setter";

  static shadowColor_Getter(mthis) native "CanvasRenderingContext2D_shadowColor_Getter";

  static shadowColor_Setter_DOMString(mthis, value) native "CanvasRenderingContext2D_shadowColor_Setter";

  static shadowOffsetX_Getter(mthis) native "CanvasRenderingContext2D_shadowOffsetX_Getter";

  static shadowOffsetX_Setter_float(mthis, value) native "CanvasRenderingContext2D_shadowOffsetX_Setter";

  static shadowOffsetY_Getter(mthis) native "CanvasRenderingContext2D_shadowOffsetY_Getter";

  static shadowOffsetY_Setter_float(mthis, value) native "CanvasRenderingContext2D_shadowOffsetY_Setter";

  static strokeStyle_Getter(mthis) native "CanvasRenderingContext2D_strokeStyle_Getter";

  static strokeStyle_Setter_object(mthis, value) native "CanvasRenderingContext2D_strokeStyle_Setter";

  static textAlign_Getter(mthis) native "CanvasRenderingContext2D_textAlign_Getter";

  static textAlign_Setter_DOMString(mthis, value) native "CanvasRenderingContext2D_textAlign_Setter";

  static textBaseline_Getter(mthis) native "CanvasRenderingContext2D_textBaseline_Getter";

  static textBaseline_Setter_DOMString(mthis, value) native "CanvasRenderingContext2D_textBaseline_Setter";

  static beginPath_Callback(mthis) native "CanvasRenderingContext2D_beginPath_Callback";

  static clearRect_Callback_float_float_float_float(mthis, x, y, width, height) native "CanvasRenderingContext2D_clearRect_Callback_float_float_float_float";

  static clip_Callback(mthis) native "CanvasRenderingContext2D_clip_Callback";

  static clip_Callback_DOMString(mthis, path_OR_winding) native "CanvasRenderingContext2D_clip_Callback_DOMString";

  static clip_Callback_Path2D(mthis, path_OR_winding) native "CanvasRenderingContext2D_clip_Callback_Path2D";

  static clip_Callback_Path2D_DOMString(mthis, path_OR_winding, winding) native "CanvasRenderingContext2D_clip_Callback_Path2D_DOMString";

  static createImageData_Callback_float_float(mthis, sw, sh) native "CanvasRenderingContext2D_createImageData_Callback_float_float";

  static createImageData_Callback_ImageData(mthis, imagedata) native "CanvasRenderingContext2D_createImageData_Callback_ImageData";

  static createLinearGradient_Callback_float_float_float_float(mthis, x0, y0, x1, y1) native "CanvasRenderingContext2D_createLinearGradient_Callback_float_float_float_float";

  static createPattern_Callback_HTMLCanvasElement_DOMString(mthis, canvas_OR_image, repetitionType) native "CanvasRenderingContext2D_createPattern_Callback_HTMLCanvasElement_DOMString";

  static createPattern_Callback_HTMLVideoElement_DOMString(mthis, canvas_OR_image, repetitionType) native "CanvasRenderingContext2D_createPattern_Callback_HTMLVideoElement_DOMString";

  static createPattern_Callback_HTMLImageElement_DOMString(mthis, image, repetitionType) native "CanvasRenderingContext2D_createPattern_Callback_HTMLImageElement_DOMString";

  static createRadialGradient_Callback_float_float_float_float_float_float(mthis, x0, y0, r0, x1, y1, r1) native "CanvasRenderingContext2D_createRadialGradient_Callback_float_float_float_float_float_float";

  static drawFocusIfNeeded_Callback_Element(mthis, element_OR_path) native "CanvasRenderingContext2D_drawFocusIfNeeded_Callback_Element";

  static drawFocusIfNeeded_Callback_Path2D_Element(mthis, element_OR_path, element) native "CanvasRenderingContext2D_drawFocusIfNeeded_Callback_Path2D_Element";

  static drawImage_Callback_HTMLImageElement_float_float(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y) native "CanvasRenderingContext2D_drawImage_Callback_HTMLImageElement_float_float";

  static drawImage_Callback_HTMLImageElement_float_float_float_float(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh) native "CanvasRenderingContext2D_drawImage_Callback_HTMLImageElement_float_float_float_float";

  static drawImage_Callback_HTMLImageElement_float_float_float_float_float_float_float_float(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh) native "CanvasRenderingContext2D_drawImage_Callback_HTMLImageElement_float_float_float_float_float_float_float_float";

  static drawImage_Callback_HTMLCanvasElement_float_float(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y) native "CanvasRenderingContext2D_drawImage_Callback_HTMLCanvasElement_float_float";

  static drawImage_Callback_HTMLCanvasElement_float_float_float_float(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh) native "CanvasRenderingContext2D_drawImage_Callback_HTMLCanvasElement_float_float_float_float";

  static drawImage_Callback_HTMLCanvasElement_float_float_float_float_float_float_float_float(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh) native "CanvasRenderingContext2D_drawImage_Callback_HTMLCanvasElement_float_float_float_float_float_float_float_float";

  static drawImage_Callback_HTMLVideoElement_float_float(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y) native "CanvasRenderingContext2D_drawImage_Callback_HTMLVideoElement_float_float";

  static drawImage_Callback_HTMLVideoElement_float_float_float_float(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh) native "CanvasRenderingContext2D_drawImage_Callback_HTMLVideoElement_float_float_float_float";

  static drawImage_Callback_HTMLVideoElement_float_float_float_float_float_float_float_float(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh) native "CanvasRenderingContext2D_drawImage_Callback_HTMLVideoElement_float_float_float_float_float_float_float_float";

  static drawImage_Callback_ImageBitmap_float_float(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y) native "CanvasRenderingContext2D_drawImage_Callback_ImageBitmap_float_float";

  static drawImage_Callback_ImageBitmap_float_float_float_float(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh) native "CanvasRenderingContext2D_drawImage_Callback_ImageBitmap_float_float_float_float";

  static drawImage_Callback_ImageBitmap_float_float_float_float_float_float_float_float(mthis, canvas_OR_image_OR_imageBitmap_OR_video, sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh) native "CanvasRenderingContext2D_drawImage_Callback_ImageBitmap_float_float_float_float_float_float_float_float";

  static fill_Callback(mthis) native "CanvasRenderingContext2D_fill_Callback";

  static fill_Callback_DOMString(mthis, path_OR_winding) native "CanvasRenderingContext2D_fill_Callback_DOMString";

  static fill_Callback_Path2D(mthis, path_OR_winding) native "CanvasRenderingContext2D_fill_Callback_Path2D";

  static fill_Callback_Path2D_DOMString(mthis, path_OR_winding, winding) native "CanvasRenderingContext2D_fill_Callback_Path2D_DOMString";

  static fillRect_Callback_float_float_float_float(mthis, x, y, width, height) native "CanvasRenderingContext2D_fillRect_Callback_float_float_float_float";

  static fillText_Callback_DOMString_float_float_float(mthis, text, x, y, maxWidth) native "CanvasRenderingContext2D_fillText_Callback_DOMString_float_float_float";

  static fillText_Callback_DOMString_float_float(mthis, text, x, y) native "CanvasRenderingContext2D_fillText_Callback_DOMString_float_float";

  static getContextAttributes_Callback(mthis) native "CanvasRenderingContext2D_getContextAttributes_Callback";

  static getImageData_Callback_float_float_float_float(mthis, sx, sy, sw, sh) native "CanvasRenderingContext2D_getImageData_Callback_float_float_float_float";

  static getLineDash_Callback(mthis) native "CanvasRenderingContext2D_getLineDash_Callback";

  static isContextLost_Callback(mthis) native "CanvasRenderingContext2D_isContextLost_Callback";

  static isPointInPath_Callback_float_float(mthis, path_OR_x, x_OR_y) native "CanvasRenderingContext2D_isPointInPath_Callback_float_float";

  static isPointInPath_Callback_float_float_DOMString(mthis, path_OR_x, x_OR_y, winding_OR_y) native "CanvasRenderingContext2D_isPointInPath_Callback_float_float_DOMString";

  static isPointInPath_Callback_Path2D_float_float(mthis, path_OR_x, x_OR_y, winding_OR_y) native "CanvasRenderingContext2D_isPointInPath_Callback_Path2D_float_float";

  static isPointInPath_Callback_Path2D_float_float_DOMString(mthis, path_OR_x, x_OR_y, winding_OR_y, winding) native "CanvasRenderingContext2D_isPointInPath_Callback_Path2D_float_float_DOMString";

  static isPointInStroke_Callback_float_float(mthis, path_OR_x, x_OR_y) native "CanvasRenderingContext2D_isPointInStroke_Callback_float_float";

  static isPointInStroke_Callback_Path2D_float_float(mthis, path_OR_x, x_OR_y, y) native "CanvasRenderingContext2D_isPointInStroke_Callback_Path2D_float_float";

  static measureText_Callback_DOMString(mthis, text) native "CanvasRenderingContext2D_measureText_Callback_DOMString";

  static putImageData_Callback_ImageData_float_float(mthis, imagedata, dx, dy) native "CanvasRenderingContext2D_putImageData_Callback_ImageData_float_float";

  static putImageData_Callback_ImageData_float_float_float_float_float_float(mthis, imagedata, dx, dy, dirtyX, dirtyY, dirtyWidth, dirtyHeight) native "CanvasRenderingContext2D_putImageData_Callback_ImageData_float_float_float_float_float_float";

  static resetTransform_Callback(mthis) native "CanvasRenderingContext2D_resetTransform_Callback";

  static restore_Callback(mthis) native "CanvasRenderingContext2D_restore_Callback";

  static rotate_Callback_float(mthis, angle) native "CanvasRenderingContext2D_rotate_Callback_float";

  static save_Callback(mthis) native "CanvasRenderingContext2D_save_Callback";

  static scale_Callback_float_float(mthis, x, y) native "CanvasRenderingContext2D_scale_Callback_float_float";

  static scrollPathIntoView_Callback_Path2D(mthis, path) native "CanvasRenderingContext2D_scrollPathIntoView_Callback_Path2D";

  static scrollPathIntoView_Callback(mthis) native "CanvasRenderingContext2D_scrollPathIntoView_Callback";

  static setLineDash_Callback_SEQ_float_SEQ(mthis, dash) native "CanvasRenderingContext2D_setLineDash_Callback_sequence<unrestricted float>";

  static setTransform_Callback_float_float_float_float_float_float(mthis, a, b, c, d, e, f) native "CanvasRenderingContext2D_setTransform_Callback_float_float_float_float_float_float";

  static stroke_Callback(mthis) native "CanvasRenderingContext2D_stroke_Callback";

  static stroke_Callback_Path2D(mthis, path) native "CanvasRenderingContext2D_stroke_Callback_Path2D";

  static strokeRect_Callback_float_float_float_float(mthis, x, y, width, height) native "CanvasRenderingContext2D_strokeRect_Callback_float_float_float_float";

  static strokeText_Callback_DOMString_float_float_float(mthis, text, x, y, maxWidth) native "CanvasRenderingContext2D_strokeText_Callback_DOMString_float_float_float";

  static strokeText_Callback_DOMString_float_float(mthis, text, x, y) native "CanvasRenderingContext2D_strokeText_Callback_DOMString_float_float";

  static transform_Callback_float_float_float_float_float_float(mthis, a, b, c, d, e, f) native "CanvasRenderingContext2D_transform_Callback_float_float_float_float_float_float";

  static translate_Callback_float_float(mthis, x, y) native "CanvasRenderingContext2D_translate_Callback_float_float";

  static arc_Callback_float_float_float_float_float_boolean(mthis, x, y, radius, startAngle, endAngle, anticlockwise) native "CanvasRenderingContext2D_arc_Callback_float_float_float_float_float_boolean";

  static arcTo_Callback_float_float_float_float_float(mthis, x1, y1, x2, y2, radius) native "CanvasRenderingContext2D_arcTo_Callback_float_float_float_float_float";

  static bezierCurveTo_Callback_float_float_float_float_float_float(mthis, cp1x, cp1y, cp2x, cp2y, x, y) native "CanvasRenderingContext2D_bezierCurveTo_Callback_float_float_float_float_float_float";

  static closePath_Callback(mthis) native "CanvasRenderingContext2D_closePath_Callback";

  static ellipse_Callback_float_float_float_float_float_float_float_boolean(mthis, x, y, radiusX, radiusY, rotation, startAngle, endAngle, anticlockwise) native "CanvasRenderingContext2D_ellipse_Callback_float_float_float_float_float_float_float_boolean";

  static lineTo_Callback_float_float(mthis, x, y) native "CanvasRenderingContext2D_lineTo_Callback_float_float";

  static moveTo_Callback_float_float(mthis, x, y) native "CanvasRenderingContext2D_moveTo_Callback_float_float";

  static quadraticCurveTo_Callback_float_float_float_float(mthis, cpx, cpy, x, y) native "CanvasRenderingContext2D_quadraticCurveTo_Callback_float_float_float_float";

  static rect_Callback_float_float_float_float(mthis, x, y, width, height) native "CanvasRenderingContext2D_rect_Callback_float_float_float_float";
}

class BlinkChannelMergerNode {}

class BlinkChannelSplitterNode {}

class BlinkClient {
  static id_Getter(mthis) native "Client_id_Getter";

  static postMessage_Callback_SerializedScriptValue_A_MessagePort_A(mthis, message, messagePorts) native "Client_postMessage_Callback";
}

class BlinkClientRect {
  static bottom_Getter(mthis) native "ClientRect_bottom_Getter";

  static height_Getter(mthis) native "ClientRect_height_Getter";

  static left_Getter(mthis) native "ClientRect_left_Getter";

  static right_Getter(mthis) native "ClientRect_right_Getter";

  static top_Getter(mthis) native "ClientRect_top_Getter";

  static width_Getter(mthis) native "ClientRect_width_Getter";
}

class BlinkClientRectList {
  static length_Getter(mthis) native "ClientRectList_length_Getter";

  static item_Callback_ul(mthis, index) native "ClientRectList_item_Callback_unsigned long";
}

class BlinkCloseEvent {
  static code_Getter(mthis) native "CloseEvent_code_Getter";

  static reason_Getter(mthis) native "CloseEvent_reason_Getter";

  static wasClean_Getter(mthis) native "CloseEvent_wasClean_Getter";
}

class BlinkComment {
  static constructorCallback_DOMString(data) native "Comment_constructorCallback_DOMString";
}

class BlinkUIEvent {
  static charCode_Getter(mthis) native "UIEvent_charCode_Getter";

  static detail_Getter(mthis) native "UIEvent_detail_Getter";

  static keyCode_Getter(mthis) native "UIEvent_keyCode_Getter";

  static layerX_Getter(mthis) native "UIEvent_layerX_Getter";

  static layerY_Getter(mthis) native "UIEvent_layerY_Getter";

  static pageX_Getter(mthis) native "UIEvent_pageX_Getter";

  static pageY_Getter(mthis) native "UIEvent_pageY_Getter";

  static view_Getter(mthis) native "UIEvent_view_Getter";

  static which_Getter(mthis) native "UIEvent_which_Getter";

  static initUIEvent_Callback_DOMString_boolean_boolean_Window_long(mthis, type, canBubble, cancelable, view, detail) native "UIEvent_initUIEvent_Callback_DOMString_boolean_boolean_Window_long";
}

class BlinkCompositionEvent {
  static activeSegmentEnd_Getter(mthis) native "CompositionEvent_activeSegmentEnd_Getter";

  static activeSegmentStart_Getter(mthis) native "CompositionEvent_activeSegmentStart_Getter";

  static data_Getter(mthis) native "CompositionEvent_data_Getter";

  static initCompositionEvent_Callback_DOMString_boolean_boolean_Window_DOMString(mthis, typeArg, canBubbleArg, cancelableArg, viewArg, dataArg) native "CompositionEvent_initCompositionEvent_Callback_DOMString_boolean_boolean_Window_DOMString";
}

class BlinkConsoleBase {
  static assert_Callback_boolean_object(mthis, condition, arg) native "ConsoleBase_assert_Callback_boolean_object";

  static clear_Callback_object(mthis, arg) native "ConsoleBase_clear_Callback_object";

  static count_Callback_object(mthis, arg) native "ConsoleBase_count_Callback_object";

  static debug_Callback_object(mthis, arg) native "ConsoleBase_debug_Callback_object";

  static dir_Callback_object(mthis, arg) native "ConsoleBase_dir_Callback_object";

  static dirxml_Callback_object(mthis, arg) native "ConsoleBase_dirxml_Callback_object";

  static error_Callback_object(mthis, arg) native "ConsoleBase_error_Callback_object";

  static group_Callback_object(mthis, arg) native "ConsoleBase_group_Callback_object";

  static groupCollapsed_Callback_object(mthis, arg) native "ConsoleBase_groupCollapsed_Callback_object";

  static groupEnd_Callback(mthis) native "ConsoleBase_groupEnd_Callback";

  static info_Callback_object(mthis, arg) native "ConsoleBase_info_Callback_object";

  static log_Callback_object(mthis, arg) native "ConsoleBase_log_Callback_object";

  static markTimeline_Callback_DOMString(mthis, title) native "ConsoleBase_markTimeline_Callback_DOMString";

  static profile_Callback_DOMString(mthis, title) native "ConsoleBase_profile_Callback_DOMString";

  static profileEnd_Callback_DOMString(mthis, title) native "ConsoleBase_profileEnd_Callback_DOMString";

  static table_Callback_object(mthis, arg) native "ConsoleBase_table_Callback_object";

  static time_Callback_DOMString(mthis, title) native "ConsoleBase_time_Callback_DOMString";

  static timeEnd_Callback_DOMString(mthis, title) native "ConsoleBase_timeEnd_Callback_DOMString";

  static timeStamp_Callback_DOMString(mthis, title) native "ConsoleBase_timeStamp_Callback_DOMString";

  static timeline_Callback_DOMString(mthis, title) native "ConsoleBase_timeline_Callback_DOMString";

  static timelineEnd_Callback_DOMString(mthis, title) native "ConsoleBase_timelineEnd_Callback_DOMString";

  static trace_Callback_object(mthis, arg) native "ConsoleBase_trace_Callback_object";

  static warn_Callback_object(mthis, arg) native "ConsoleBase_warn_Callback_object";
}

class BlinkConsole {
  static memory_Getter(mthis) native "Console_memory_Getter";
}

class BlinkConvolverNode {
  static buffer_Getter(mthis) native "ConvolverNode_buffer_Getter";

  static buffer_Setter_AudioBuffer(mthis, value) native "ConvolverNode_buffer_Setter";

  static normalize_Getter(mthis) native "ConvolverNode_normalize_Getter";

  static normalize_Setter_boolean(mthis, value) native "ConvolverNode_normalize_Setter";
}

class BlinkCoordinates {
  static accuracy_Getter(mthis) native "Coordinates_accuracy_Getter";

  static altitude_Getter(mthis) native "Coordinates_altitude_Getter";

  static altitudeAccuracy_Getter(mthis) native "Coordinates_altitudeAccuracy_Getter";

  static heading_Getter(mthis) native "Coordinates_heading_Getter";

  static latitude_Getter(mthis) native "Coordinates_latitude_Getter";

  static longitude_Getter(mthis) native "Coordinates_longitude_Getter";

  static speed_Getter(mthis) native "Coordinates_speed_Getter";
}

class BlinkCounter {}

class BlinkCrypto {
  static subtle_Getter(mthis) native "Crypto_subtle_Getter";

  static getRandomValues_Callback_ArrayBufferView(mthis, array) native "Crypto_getRandomValues_Callback";
}

class BlinkCustomEvent {
  static detail_Getter(mthis) native "CustomEvent_detail_Getter";

  static initCustomEvent_Callback_DOMString_boolean_boolean_ScriptValue(mthis, typeArg, canBubbleArg, cancelableArg, detailArg) native "CustomEvent_initCustomEvent_Callback";
}

class BlinkDOMError {
  static constructorCallback_DOMString_DOMString(name, message) native "DOMError_constructorCallback_DOMString_DOMString";

  static message_Getter(mthis) native "DOMError_message_Getter";

  static name_Getter(mthis) native "DOMError_name_Getter";
}

class BlinkDOMException {
  static message_Getter(mthis) native "DOMException_message_Getter";

  static name_Getter(mthis) native "DOMException_name_Getter";

  static toString_Callback(mthis) native "DOMException_toString_Callback";
}

class BlinkDOMFileSystem {
  static name_Getter(mthis) native "DOMFileSystem_name_Getter";

  static root_Getter(mthis) native "DOMFileSystem_root_Getter";
}

class BlinkDOMFileSystemSync {}

class BlinkDOMImplementation {
  static createDocument_Callback_DOMString_DOMString_DocumentType(mthis, namespaceURI, qualifiedName, doctype) native "DOMImplementation_createDocument_Callback_DOMString_DOMString_DocumentType";

  static createDocumentType_Callback_DOMString_DOMString_DOMString(mthis, qualifiedName, publicId, systemId) native "DOMImplementation_createDocumentType_Callback_DOMString_DOMString_DOMString";

  static createHTMLDocument_Callback_DOMString(mthis, title) native "DOMImplementation_createHTMLDocument_Callback_DOMString";

  static hasFeature_Callback_DOMString_DOMString(mthis, feature, version) native "DOMImplementation_hasFeature_Callback_DOMString_DOMString";
}

class BlinkDOMParser {
  static constructorCallback() native "DOMParser_constructorCallback";

  static parseFromString_Callback_DOMString_DOMString(mthis, str, contentType) native "DOMParser_parseFromString_Callback_DOMString_DOMString";
}

class BlinkDOMTokenList {
  static length_Getter(mthis) native "DOMTokenList_length_Getter";

  static add_Callback_DOMString(mthis, tokens) native "DOMTokenList_add_Callback_DOMString";

  static contains_Callback_DOMString(mthis, token) native "DOMTokenList_contains_Callback_DOMString";

  static item_Callback_ul(mthis, index) native "DOMTokenList_item_Callback_unsigned long";

  static remove_Callback_DOMString(mthis, tokens) native "DOMTokenList_remove_Callback_DOMString";

  static toString_Callback(mthis) native "DOMTokenList_toString_Callback";

  static toggle_Callback_DOMString_boolean(mthis, token, force) native "DOMTokenList_toggle_Callback_DOMString_boolean";

  static toggle_Callback_DOMString(mthis, token) native "DOMTokenList_toggle_Callback_DOMString";
}

class BlinkDOMSettableTokenList {
  static value_Getter(mthis) native "DOMSettableTokenList_value_Getter";

  static value_Setter_DOMString(mthis, value) native "DOMSettableTokenList_value_Setter";

  static $__getter___Callback_ul(mthis, index) native "DOMSettableTokenList___getter___Callback_unsigned long";
}

class BlinkDOMStringList {
  static length_Getter(mthis) native "DOMStringList_length_Getter";

  static contains_Callback_DOMString(mthis, string) native "DOMStringList_contains_Callback_DOMString";

  static item_Callback_ul(mthis, index) native "DOMStringList_item_Callback_unsigned long";
}

class BlinkDOMStringMap {
  static $__delete___Callback_ul(mthis, index_OR_name) native "DOMStringMap___delete___Callback_unsigned long";

  static $__delete___Callback_DOMString(mthis, index_OR_name) native "DOMStringMap___delete___Callback_DOMString";

  static $__getter___Callback_ul(mthis, index_OR_name) native "DOMStringMap___getter___Callback_unsigned long";

  static $__getter___Callback_DOMString(mthis, index_OR_name) native "DOMStringMap___getter___Callback_DOMString";

  static $__setter___Callback_ul_DOMString(mthis, index_OR_name, value) native "DOMStringMap___setter___Callback_unsigned long_DOMString";

  static $__setter___Callback_DOMString_DOMString(mthis, index_OR_name, value) native "DOMStringMap___setter___Callback_DOMString_DOMString";
}

class BlinkDataTransfer {
  static dropEffect_Getter(mthis) native "DataTransfer_dropEffect_Getter";

  static dropEffect_Setter_DOMString(mthis, value) native "DataTransfer_dropEffect_Setter";

  static effectAllowed_Getter(mthis) native "DataTransfer_effectAllowed_Getter";

  static effectAllowed_Setter_DOMString(mthis, value) native "DataTransfer_effectAllowed_Setter";

  static files_Getter(mthis) native "DataTransfer_files_Getter";

  static items_Getter(mthis) native "DataTransfer_items_Getter";

  static types_Getter(mthis) native "DataTransfer_types_Getter";

  static clearData_Callback_DOMString(mthis, type) native "DataTransfer_clearData_Callback_DOMString";

  static clearData_Callback(mthis) native "DataTransfer_clearData_Callback";

  static getData_Callback_DOMString(mthis, type) native "DataTransfer_getData_Callback_DOMString";

  static setData_Callback_DOMString_DOMString(mthis, type, data) native "DataTransfer_setData_Callback_DOMString_DOMString";

  static setDragImage_Callback_Element_long_long(mthis, image, x, y) native "DataTransfer_setDragImage_Callback_Element_long_long";
}

class BlinkDataTransferItem {
  static kind_Getter(mthis) native "DataTransferItem_kind_Getter";

  static type_Getter(mthis) native "DataTransferItem_type_Getter";

  static getAsFile_Callback(mthis) native "DataTransferItem_getAsFile_Callback";

  static getAsString_Callback_StringCallback(mthis, callback) native "DataTransferItem_getAsString_Callback_StringCallback";

  static webkitGetAsEntry_Callback(mthis) native "DataTransferItem_webkitGetAsEntry_Callback";
}

class BlinkDataTransferItemList {
  static length_Getter(mthis) native "DataTransferItemList_length_Getter";

  static $__getter___Callback_ul(mthis, index) native "DataTransferItemList___getter___Callback_unsigned long";

  static add_Callback_DOMString_DOMString(mthis, data_OR_file, type) native "DataTransferItemList_add_Callback_DOMString_DOMString";

  static add_Callback_File(mthis, data_OR_file) native "DataTransferItemList_add_Callback_File";

  static clear_Callback(mthis) native "DataTransferItemList_clear_Callback";

  static remove_Callback_ul(mthis, index) native "DataTransferItemList_remove_Callback_unsigned long";
}

class BlinkDatabase {
  static version_Getter(mthis) native "Database_version_Getter";

  static changeVersion_Callback_DOMString_DOMString_SQLTransactionCallback_SQLTransactionErrorCallback_VoidCallback(mthis, oldVersion, newVersion, callback, errorCallback, successCallback) native "Database_changeVersion_Callback_DOMString_DOMString_SQLTransactionCallback_SQLTransactionErrorCallback_VoidCallback";

  static readTransaction_Callback_SQLTransactionCallback_SQLTransactionErrorCallback_VoidCallback(mthis, callback, errorCallback, successCallback) native "Database_readTransaction_Callback_SQLTransactionCallback_SQLTransactionErrorCallback_VoidCallback";

  static transaction_Callback_SQLTransactionCallback_SQLTransactionErrorCallback_VoidCallback(mthis, callback, errorCallback, successCallback) native "Database_transaction_Callback_SQLTransactionCallback_SQLTransactionErrorCallback_VoidCallback";
}

class BlinkDatabaseSync {}

class BlinkWindowBase64 {
  static atob_Callback_DOMString(mthis, string) native "WindowBase64_atob_Callback_DOMString";

  static btoa_Callback_DOMString(mthis, string) native "WindowBase64_btoa_Callback_DOMString";
}

class BlinkWindowTimers {
  static clearInterval_Callback_long(mthis, handle) native "WindowTimers_clearInterval_Callback_long";

  static clearTimeout_Callback_long(mthis, handle) native "WindowTimers_clearTimeout_Callback_long";

  static setInterval_Callback_ScriptValue_long(mthis, handler, timeout) native "WindowTimers_setInterval_Callback";

  static setTimeout_Callback_ScriptValue_long(mthis, handler, timeout) native "WindowTimers_setTimeout_Callback";
}

class BlinkWorkerGlobalScope {
  static console_Getter(mthis) native "WorkerGlobalScope_console_Getter";

  static crypto_Getter(mthis) native "WorkerGlobalScope_crypto_Getter";

  static indexedDB_Getter(mthis) native "WorkerGlobalScope_indexedDB_Getter";

  static location_Getter(mthis) native "WorkerGlobalScope_location_Getter";

  static navigator_Getter(mthis) native "WorkerGlobalScope_navigator_Getter";

  static performance_Getter(mthis) native "WorkerGlobalScope_performance_Getter";

  static self_Getter(mthis) native "WorkerGlobalScope_self_Getter";

  static close_Callback(mthis) native "WorkerGlobalScope_close_Callback";

  static importScripts_Callback_DOMString(mthis, urls) native "WorkerGlobalScope_importScripts_Callback_DOMString";

  static openDatabase_Callback_DOMString_DOMString_DOMString_ul_DatabaseCallback(mthis, name, version, displayName, estimatedSize, creationCallback) native "WorkerGlobalScope_openDatabase_Callback_DOMString_DOMString_DOMString_unsigned long_DatabaseCallback";

  static openDatabaseSync_Callback_DOMString_DOMString_DOMString_ul_DatabaseCallback(mthis, name, version, displayName, estimatedSize, creationCallback) native "WorkerGlobalScope_openDatabaseSync_Callback_DOMString_DOMString_DOMString_unsigned long_DatabaseCallback";

  static webkitRequestFileSystem_Callback_us_ll_FileSystemCallback_ErrorCallback(mthis, type, size, successCallback, errorCallback) native "WorkerGlobalScope_webkitRequestFileSystem_Callback_unsigned short_long long_FileSystemCallback_ErrorCallback";

  static webkitRequestFileSystemSync_Callback_us_ll(mthis, type, size) native "WorkerGlobalScope_webkitRequestFileSystemSync_Callback_unsigned short_long long";

  static webkitResolveLocalFileSystemSyncURL_Callback_DOMString(mthis, url) native "WorkerGlobalScope_webkitResolveLocalFileSystemSyncURL_Callback_DOMString";

  static webkitResolveLocalFileSystemURL_Callback_DOMString_EntryCallback_ErrorCallback(mthis, url, successCallback, errorCallback) native "WorkerGlobalScope_webkitResolveLocalFileSystemURL_Callback_DOMString_EntryCallback_ErrorCallback";

  static atob_Callback_DOMString(mthis, string) native "WorkerGlobalScope_atob_Callback_DOMString";

  static btoa_Callback_DOMString(mthis, string) native "WorkerGlobalScope_btoa_Callback_DOMString";

  static clearInterval_Callback_long(mthis, handle) native "WorkerGlobalScope_clearInterval_Callback_long";

  static clearTimeout_Callback_long(mthis, handle) native "WorkerGlobalScope_clearTimeout_Callback_long";

  static setInterval_Callback_ScriptValue_long(mthis, handler, timeout) native "WorkerGlobalScope_setInterval_Callback";

  static setTimeout_Callback_ScriptValue_long(mthis, handler, timeout) native "WorkerGlobalScope_setTimeout_Callback";
}

class BlinkDedicatedWorkerGlobalScope {
  static postMessage_Callback_ScriptValue_A_MessagePort_A(mthis, message, messagePorts) native "DedicatedWorkerGlobalScope_postMessage_Callback";
}

class BlinkDelayNode {
  static delayTime_Getter(mthis) native "DelayNode_delayTime_Getter";
}

class BlinkDeprecatedStorageInfo {
  static queryUsageAndQuota_Callback_us_StorageUsageCallback_StorageErrorCallback(mthis, storageType, usageCallback, errorCallback) native "DeprecatedStorageInfo_queryUsageAndQuota_Callback_unsigned short_StorageUsageCallback_StorageErrorCallback";

  static requestQuota_Callback_us_ull_StorageQuotaCallback_StorageErrorCallback(mthis, storageType, newQuotaInBytes, quotaCallback, errorCallback) native "DeprecatedStorageInfo_requestQuota_Callback_unsigned short_unsigned long long_StorageQuotaCallback_StorageErrorCallback";
}

class BlinkDeprecatedStorageQuota {
  static queryUsageAndQuota_Callback_StorageUsageCallback_StorageErrorCallback(mthis, usageCallback, errorCallback) native "DeprecatedStorageQuota_queryUsageAndQuota_Callback_StorageUsageCallback_StorageErrorCallback";

  static requestQuota_Callback_ull_StorageQuotaCallback_StorageErrorCallback(mthis, newQuotaInBytes, quotaCallback, errorCallback) native "DeprecatedStorageQuota_requestQuota_Callback_unsigned long long_StorageQuotaCallback_StorageErrorCallback";
}

class BlinkDeviceAcceleration {
  static x_Getter(mthis) native "DeviceAcceleration_x_Getter";

  static y_Getter(mthis) native "DeviceAcceleration_y_Getter";

  static z_Getter(mthis) native "DeviceAcceleration_z_Getter";
}

class BlinkDeviceLightEvent {
  static value_Getter(mthis) native "DeviceLightEvent_value_Getter";
}

class BlinkDeviceMotionEvent {
  static acceleration_Getter(mthis) native "DeviceMotionEvent_acceleration_Getter";

  static accelerationIncludingGravity_Getter(mthis) native "DeviceMotionEvent_accelerationIncludingGravity_Getter";

  static interval_Getter(mthis) native "DeviceMotionEvent_interval_Getter";

  static rotationRate_Getter(mthis) native "DeviceMotionEvent_rotationRate_Getter";

  static initDeviceMotionEvent_Callback_DOMString_boolean_boolean_DeviceAcceleration_DeviceAcceleration_DeviceRotationRate_double(mthis, type, bubbles, cancelable, acceleration, accelerationIncludingGravity, rotationRate, interval) native "DeviceMotionEvent_initDeviceMotionEvent_Callback";
}

class BlinkDeviceOrientationEvent {
  static absolute_Getter(mthis) native "DeviceOrientationEvent_absolute_Getter";

  static alpha_Getter(mthis) native "DeviceOrientationEvent_alpha_Getter";

  static beta_Getter(mthis) native "DeviceOrientationEvent_beta_Getter";

  static gamma_Getter(mthis) native "DeviceOrientationEvent_gamma_Getter";

  static initDeviceOrientationEvent_Callback_DOMString_boolean_boolean_double_double_double_boolean(mthis, type, bubbles, cancelable, alpha, beta, gamma, absolute) native "DeviceOrientationEvent_initDeviceOrientationEvent_Callback";
}

class BlinkDeviceRotationRate {
  static alpha_Getter(mthis) native "DeviceRotationRate_alpha_Getter";

  static beta_Getter(mthis) native "DeviceRotationRate_beta_Getter";

  static gamma_Getter(mthis) native "DeviceRotationRate_gamma_Getter";
}

class BlinkEntry {
  static filesystem_Getter(mthis) native "Entry_filesystem_Getter";

  static fullPath_Getter(mthis) native "Entry_fullPath_Getter";

  static isDirectory_Getter(mthis) native "Entry_isDirectory_Getter";

  static isFile_Getter(mthis) native "Entry_isFile_Getter";

  static name_Getter(mthis) native "Entry_name_Getter";

  static copyTo_Callback_DirectoryEntry_DOMString_EntryCallback_ErrorCallback(mthis, parent, name, successCallback, errorCallback) native "Entry_copyTo_Callback_DirectoryEntry_DOMString_EntryCallback_ErrorCallback";

  static copyTo_Callback_DirectoryEntry(mthis, parent) native "Entry_copyTo_Callback_DirectoryEntry";

  static getMetadata_Callback_MetadataCallback_ErrorCallback(mthis, successCallback, errorCallback) native "Entry_getMetadata_Callback_MetadataCallback_ErrorCallback";

  static getParent_Callback_EntryCallback_ErrorCallback(mthis, successCallback, errorCallback) native "Entry_getParent_Callback_EntryCallback_ErrorCallback";

  static moveTo_Callback_DirectoryEntry_DOMString_EntryCallback_ErrorCallback(mthis, parent, name, successCallback, errorCallback) native "Entry_moveTo_Callback_DirectoryEntry_DOMString_EntryCallback_ErrorCallback";

  static moveTo_Callback_DirectoryEntry(mthis, parent) native "Entry_moveTo_Callback_DirectoryEntry";

  static remove_Callback_VoidCallback_ErrorCallback(mthis, successCallback, errorCallback) native "Entry_remove_Callback_VoidCallback_ErrorCallback";

  static toURL_Callback(mthis) native "Entry_toURL_Callback";
}

class BlinkDirectoryEntry {
  static createReader_Callback(mthis) native "DirectoryEntry_createReader_Callback";

  static getDirectory_Callback_DOMString_Dictionary_EntryCallback_ErrorCallback(mthis, path, options, successCallback, errorCallback) native "DirectoryEntry_getDirectory_Callback_DOMString_Dictionary_EntryCallback_ErrorCallback";

  static getFile_Callback_DOMString_Dictionary_EntryCallback_ErrorCallback(mthis, path, options, successCallback, errorCallback) native "DirectoryEntry_getFile_Callback_DOMString_Dictionary_EntryCallback_ErrorCallback";

  static removeRecursively_Callback_VoidCallback_ErrorCallback(mthis, successCallback, errorCallback) native "DirectoryEntry_removeRecursively_Callback_VoidCallback_ErrorCallback";
}

class BlinkEntrySync {}

class BlinkDirectoryEntrySync {}

class BlinkDirectoryReader {
  static readEntries_Callback_EntriesCallback_ErrorCallback(mthis, successCallback, errorCallback) native "DirectoryReader_readEntries_Callback_EntriesCallback_ErrorCallback";
}

class BlinkDirectoryReaderSync {}

class BlinkGlobalEventHandlers {}

class BlinkParentNode {
  static childElementCount_Getter(mthis) native "ParentNode_childElementCount_Getter";

  static children_Getter(mthis) native "ParentNode_children_Getter";

  static firstElementChild_Getter(mthis) native "ParentNode_firstElementChild_Getter";

  static lastElementChild_Getter(mthis) native "ParentNode_lastElementChild_Getter";

  static querySelector_Callback_DOMString(mthis, selectors) native "ParentNode_querySelector_Callback_DOMString";

  static querySelectorAll_Callback_DOMString(mthis, selectors) native "ParentNode_querySelectorAll_Callback_DOMString";
}

class BlinkDocument {
  static activeElement_Getter(mthis) native "Document_activeElement_Getter";

  static body_Getter(mthis) native "Document_body_Getter";

  static body_Setter_HTMLElement(mthis, value) native "Document_body_Setter";

  static contentType_Getter(mthis) native "Document_contentType_Getter";

  static cookie_Getter(mthis) native "Document_cookie_Getter";

  static cookie_Setter_DOMString(mthis, value) native "Document_cookie_Setter";

  static currentScript_Getter(mthis) native "Document_currentScript_Getter";

  static defaultView_Getter(mthis) native "Document_defaultView_Getter";

  static documentElement_Getter(mthis) native "Document_documentElement_Getter";

  static domain_Getter(mthis) native "Document_domain_Getter";

  static fonts_Getter(mthis) native "Document_fonts_Getter";

  static head_Getter(mthis) native "Document_head_Getter";

  static hidden_Getter(mthis) native "Document_hidden_Getter";

  static implementation_Getter(mthis) native "Document_implementation_Getter";

  static lastModified_Getter(mthis) native "Document_lastModified_Getter";

  static pointerLockElement_Getter(mthis) native "Document_pointerLockElement_Getter";

  static preferredStylesheetSet_Getter(mthis) native "Document_preferredStylesheetSet_Getter";

  static readyState_Getter(mthis) native "Document_readyState_Getter";

  static referrer_Getter(mthis) native "Document_referrer_Getter";

  static rootElement_Getter(mthis) native "Document_rootElement_Getter";

  static selectedStylesheetSet_Getter(mthis) native "Document_selectedStylesheetSet_Getter";

  static selectedStylesheetSet_Setter_DOMString(mthis, value) native "Document_selectedStylesheetSet_Setter";

  static styleSheets_Getter(mthis) native "Document_styleSheets_Getter";

  static timeline_Getter(mthis) native "Document_timeline_Getter";

  static title_Getter(mthis) native "Document_title_Getter";

  static title_Setter_DOMString(mthis, value) native "Document_title_Setter";

  static visibilityState_Getter(mthis) native "Document_visibilityState_Getter";

  static webkitFullscreenElement_Getter(mthis) native "Document_webkitFullscreenElement_Getter";

  static webkitFullscreenEnabled_Getter(mthis) native "Document_webkitFullscreenEnabled_Getter";

  static webkitHidden_Getter(mthis) native "Document_webkitHidden_Getter";

  static webkitPointerLockElement_Getter(mthis) native "Document_webkitPointerLockElement_Getter";

  static webkitVisibilityState_Getter(mthis) native "Document_webkitVisibilityState_Getter";

  static adoptNode_Callback_Node(mthis, node) native "Document_adoptNode_Callback_Node";

  static caretRangeFromPoint_Callback_long_long(mthis, x, y) native "Document_caretRangeFromPoint_Callback_long_long";

  static createDocumentFragment_Callback(mthis) native "Document_createDocumentFragment_Callback";

  static createElement_Callback_DOMString(mthis, localName_OR_tagName, typeExtension) native "Document_createElement_Callback";

  static createElementNS_Callback_DOMString_DOMString(mthis, namespaceURI, qualifiedName, typeExtension) native "Document_createElementNS_Callback";

  static createEvent_Callback_DOMString(mthis, eventType) native "Document_createEvent_Callback_DOMString";

  static createNodeIterator_Callback_Node_ul_NodeFilter(mthis, root, whatToShow, filter) native "Document_createNodeIterator_Callback_Node_unsigned long_NodeFilter";

  static createNodeIterator_Callback_Node_ul(mthis, root, whatToShow) native "Document_createNodeIterator_Callback_Node_unsigned long";

  static createNodeIterator_Callback_Node(mthis, root) native "Document_createNodeIterator_Callback_Node";

  static createRange_Callback(mthis) native "Document_createRange_Callback";

  static createTextNode_Callback_DOMString(mthis, data) native "Document_createTextNode_Callback_DOMString";

  static createTouch_Callback_Window_EventTarget_long_double_double_double_double_double_double_float_float(mthis, window, target, identifier, pageX, pageY, screenX, screenY, webkitRadiusX, webkitRadiusY, webkitRotationAngle, webkitForce) native "Document_createTouch_Callback_Window_EventTarget_long_double_double_double_double_double_double_float_float";

  static createTouchList_Callback_Touch(mthis, touches) native "Document_createTouchList_Callback_Touch";

  static createTreeWalker_Callback_Node_ul_NodeFilter(mthis, root, whatToShow, filter) native "Document_createTreeWalker_Callback_Node_unsigned long_NodeFilter";

  static createTreeWalker_Callback_Node_ul(mthis, root, whatToShow) native "Document_createTreeWalker_Callback_Node_unsigned long";

  static createTreeWalker_Callback_Node(mthis, root) native "Document_createTreeWalker_Callback_Node";

  static elementFromPoint_Callback_long_long(mthis, x, y) native "Document_elementFromPoint_Callback_long_long";

  static execCommand_Callback_DOMString_boolean_DOMString(mthis, command, userInterface, value) native "Document_execCommand_Callback_DOMString_boolean_DOMString";

  static exitPointerLock_Callback(mthis) native "Document_exitPointerLock_Callback";

  static getCSSCanvasContext_Callback_DOMString_DOMString_long_long(mthis, contextId, name, width, height) native "Document_getCSSCanvasContext_Callback_DOMString_DOMString_long_long";

  static getElementById_Callback_DOMString(mthis, elementId) native "Document_getElementById_Callback_DOMString";

  static getElementsByClassName_Callback_DOMString(mthis, classNames) native "Document_getElementsByClassName_Callback_DOMString";

  static getElementsByName_Callback_DOMString(mthis, elementName) native "Document_getElementsByName_Callback_DOMString";

  static getElementsByTagName_Callback_DOMString(mthis, localName) native "Document_getElementsByTagName_Callback_DOMString";

  static importNode_Callback_Node_boolean(mthis, node, deep) native "Document_importNode_Callback_Node_boolean";

  static importNode_Callback_Node(mthis, node) native "Document_importNode_Callback_Node";

  static queryCommandEnabled_Callback_DOMString(mthis, command) native "Document_queryCommandEnabled_Callback_DOMString";

  static queryCommandIndeterm_Callback_DOMString(mthis, command) native "Document_queryCommandIndeterm_Callback_DOMString";

  static queryCommandState_Callback_DOMString(mthis, command) native "Document_queryCommandState_Callback_DOMString";

  static queryCommandSupported_Callback_DOMString(mthis, command) native "Document_queryCommandSupported_Callback_DOMString";

  static queryCommandValue_Callback_DOMString(mthis, command) native "Document_queryCommandValue_Callback_DOMString";

  static webkitExitFullscreen_Callback(mthis) native "Document_webkitExitFullscreen_Callback";

  static webkitExitPointerLock_Callback(mthis) native "Document_webkitExitPointerLock_Callback";

  static childElementCount_Getter(mthis) native "Document_childElementCount_Getter";

  static children_Getter(mthis) native "Document_children_Getter";

  static firstElementChild_Getter(mthis) native "Document_firstElementChild_Getter";

  static lastElementChild_Getter(mthis) native "Document_lastElementChild_Getter";

  static querySelector_Callback_DOMString(mthis, selectors) native "Document_querySelector_Callback_DOMString";

  static querySelectorAll_Callback_DOMString(mthis, selectors) native "Document_querySelectorAll_Callback_DOMString";
}

class BlinkDocumentFragment {
  static getElementById_Callback_DOMString(mthis, elementId) native "DocumentFragment_getElementById_Callback_DOMString";

  static childElementCount_Getter(mthis) native "DocumentFragment_childElementCount_Getter";

  static firstElementChild_Getter(mthis) native "DocumentFragment_firstElementChild_Getter";

  static lastElementChild_Getter(mthis) native "DocumentFragment_lastElementChild_Getter";

  static querySelector_Callback_DOMString(mthis, selectors) native "DocumentFragment_querySelector_Callback_DOMString";

  static querySelectorAll_Callback_DOMString(mthis, selectors) native "DocumentFragment_querySelectorAll_Callback_DOMString";
}

class BlinkDocumentType {}

class BlinkDynamicsCompressorNode {
  static attack_Getter(mthis) native "DynamicsCompressorNode_attack_Getter";

  static knee_Getter(mthis) native "DynamicsCompressorNode_knee_Getter";

  static ratio_Getter(mthis) native "DynamicsCompressorNode_ratio_Getter";

  static reduction_Getter(mthis) native "DynamicsCompressorNode_reduction_Getter";

  static release_Getter(mthis) native "DynamicsCompressorNode_release_Getter";

  static threshold_Getter(mthis) native "DynamicsCompressorNode_threshold_Getter";
}

class BlinkEXTBlendMinMax {}

class BlinkEXTFragDepth {}

class BlinkEXTShaderTextureLOD {}

class BlinkEXTTextureFilterAnisotropic {}

class BlinkElement {
  static attributes_Getter(mthis) native "Element_attributes_Getter";

  static className_Getter(mthis) native "Element_className_Getter";

  static className_Setter_DOMString(mthis, value) native "Element_className_Setter";

  static clientHeight_Getter(mthis) native "Element_clientHeight_Getter";

  static clientLeft_Getter(mthis) native "Element_clientLeft_Getter";

  static clientTop_Getter(mthis) native "Element_clientTop_Getter";

  static clientWidth_Getter(mthis) native "Element_clientWidth_Getter";

  static id_Getter(mthis) native "Element_id_Getter";

  static id_Setter_DOMString(mthis, value) native "Element_id_Setter";

  static innerHTML_Getter(mthis) native "Element_innerHTML_Getter";

  static innerHTML_Setter_DOMString(mthis, value) native "Element_innerHTML_Setter";

  static localName_Getter(mthis) native "Element_localName_Getter";

  static namespaceURI_Getter(mthis) native "Element_namespaceURI_Getter";

  static offsetHeight_Getter(mthis) native "Element_offsetHeight_Getter";

  static offsetLeft_Getter(mthis) native "Element_offsetLeft_Getter";

  static offsetParent_Getter(mthis) native "Element_offsetParent_Getter";

  static offsetTop_Getter(mthis) native "Element_offsetTop_Getter";

  static offsetWidth_Getter(mthis) native "Element_offsetWidth_Getter";

  static outerHTML_Getter(mthis) native "Element_outerHTML_Getter";

  static scrollHeight_Getter(mthis) native "Element_scrollHeight_Getter";

  static scrollLeft_Getter(mthis) native "Element_scrollLeft_Getter";

  static scrollLeft_Setter_long(mthis, value) native "Element_scrollLeft_Setter";

  static scrollTop_Getter(mthis) native "Element_scrollTop_Getter";

  static scrollTop_Setter_long(mthis, value) native "Element_scrollTop_Setter";

  static scrollWidth_Getter(mthis) native "Element_scrollWidth_Getter";

  static shadowRoot_Getter(mthis) native "Element_shadowRoot_Getter";

  static style_Getter(mthis) native "Element_style_Getter";

  static tagName_Getter(mthis) native "Element_tagName_Getter";

  static animate_Callback_object_object(mthis, effect, timing) native "Element_animate_Callback";

  static blur_Callback(mthis) native "Element_blur_Callback";

  static createShadowRoot_Callback(mthis) native "Element_createShadowRoot_Callback";

  static focus_Callback(mthis) native "Element_focus_Callback";

  static getAttribute_Callback_DOMString(mthis, name) native "Element_getAttribute_Callback_DOMString";

  static getAttributeNS_Callback_DOMString_DOMString(mthis, namespaceURI, localName) native "Element_getAttributeNS_Callback_DOMString_DOMString";

  static getBoundingClientRect_Callback(mthis) native "Element_getBoundingClientRect_Callback";

  static getClientRects_Callback(mthis) native "Element_getClientRects_Callback";

  static getDestinationInsertionPoints_Callback(mthis) native "Element_getDestinationInsertionPoints_Callback";

  static getElementsByClassName_Callback_DOMString(mthis, classNames) native "Element_getElementsByClassName_Callback_DOMString";

  static getElementsByTagName_Callback_DOMString(mthis, name) native "Element_getElementsByTagName_Callback_DOMString";

  static hasAttribute_Callback_DOMString(mthis, name) native "Element_hasAttribute_Callback_DOMString";

  static hasAttributeNS_Callback_DOMString_DOMString(mthis, namespaceURI, localName) native "Element_hasAttributeNS_Callback_DOMString_DOMString";

  static insertAdjacentElement_Callback_DOMString_Element(mthis, where, element) native "Element_insertAdjacentElement_Callback_DOMString_Element";

  static insertAdjacentHTML_Callback_DOMString_DOMString(mthis, where, html) native "Element_insertAdjacentHTML_Callback_DOMString_DOMString";

  static insertAdjacentText_Callback_DOMString_DOMString(mthis, where, text) native "Element_insertAdjacentText_Callback_DOMString_DOMString";

  static matches_Callback_DOMString(mthis, selectors) native "Element_matches_Callback_DOMString";

  static removeAttribute_Callback_DOMString(mthis, name) native "Element_removeAttribute_Callback_DOMString";

  static removeAttributeNS_Callback_DOMString_DOMString(mthis, namespaceURI, localName) native "Element_removeAttributeNS_Callback_DOMString_DOMString";

  static requestPointerLock_Callback(mthis) native "Element_requestPointerLock_Callback";

  static scrollByLines_Callback_long(mthis, lines) native "Element_scrollByLines_Callback_long";

  static scrollByPages_Callback_long(mthis, pages) native "Element_scrollByPages_Callback_long";

  static scrollIntoView_Callback_boolean(mthis, alignWithTop) native "Element_scrollIntoView_Callback_boolean";

  static scrollIntoView_Callback(mthis) native "Element_scrollIntoView_Callback";

  static scrollIntoViewIfNeeded_Callback_boolean(mthis, centerIfNeeded) native "Element_scrollIntoViewIfNeeded_Callback_boolean";

  static scrollIntoViewIfNeeded_Callback(mthis) native "Element_scrollIntoViewIfNeeded_Callback";

  static setAttribute_Callback_DOMString_DOMString(mthis, name, value) native "Element_setAttribute_Callback_DOMString_DOMString";

  static setAttributeNS_Callback_DOMString_DOMString_DOMString(mthis, namespaceURI, qualifiedName, value) native "Element_setAttributeNS_Callback_DOMString_DOMString_DOMString";

  static webkitRequestFullscreen_Callback(mthis) native "Element_webkitRequestFullscreen_Callback";

  static nextElementSibling_Getter(mthis) native "Element_nextElementSibling_Getter";

  static previousElementSibling_Getter(mthis) native "Element_previousElementSibling_Getter";

  static remove_Callback(mthis) native "Element_remove_Callback";

  static childElementCount_Getter(mthis) native "Element_childElementCount_Getter";

  static children_Getter(mthis) native "Element_children_Getter";

  static firstElementChild_Getter(mthis) native "Element_firstElementChild_Getter";

  static lastElementChild_Getter(mthis) native "Element_lastElementChild_Getter";

  static querySelector_Callback_DOMString(mthis, selectors) native "Element_querySelector_Callback_DOMString";

  static querySelectorAll_Callback_DOMString(mthis, selectors) native "Element_querySelectorAll_Callback_DOMString";
}

class BlinkErrorEvent {
  static colno_Getter(mthis) native "ErrorEvent_colno_Getter";

  static error_Getter(mthis) native "ErrorEvent_error_Getter";

  static filename_Getter(mthis) native "ErrorEvent_filename_Getter";

  static lineno_Getter(mthis) native "ErrorEvent_lineno_Getter";

  static message_Getter(mthis) native "ErrorEvent_message_Getter";
}

class BlinkEventSource {
  static constructorCallback_DOMString_Dictionary(url, eventSourceInit) native "EventSource_constructorCallback_DOMString_Dictionary";

  static readyState_Getter(mthis) native "EventSource_readyState_Getter";

  static url_Getter(mthis) native "EventSource_url_Getter";

  static withCredentials_Getter(mthis) native "EventSource_withCredentials_Getter";

  static close_Callback(mthis) native "EventSource_close_Callback";
}

class BlinkFetchEvent {
  static request_Getter(mthis) native "FetchEvent_request_Getter";

  static respondWith_Callback_ScriptValue(mthis, value) native "FetchEvent_respondWith_Callback_ScriptValue";
}

class BlinkFile {
  static lastModified_Getter(mthis) native "File_lastModified_Getter";

  static lastModifiedDate_Getter(mthis) native "File_lastModifiedDate_Getter";

  static name_Getter(mthis) native "File_name_Getter";

  static webkitRelativePath_Getter(mthis) native "File_webkitRelativePath_Getter";
}

class BlinkFileEntry {
  static createWriter_Callback_FileWriterCallback_ErrorCallback(mthis, successCallback, errorCallback) native "FileEntry_createWriter_Callback_FileWriterCallback_ErrorCallback";

  static file_Callback_FileCallback_ErrorCallback(mthis, successCallback, errorCallback) native "FileEntry_file_Callback_FileCallback_ErrorCallback";
}

class BlinkFileEntrySync {}

class BlinkFileError {
  static code_Getter(mthis) native "FileError_code_Getter";
}

class BlinkFileList {
  static length_Getter(mthis) native "FileList_length_Getter";

  static item_Callback_ul(mthis, index) native "FileList_item_Callback_unsigned long";
}

class BlinkFileReader {
  static constructorCallback() native "FileReader_constructorCallback";

  static error_Getter(mthis) native "FileReader_error_Getter";

  static readyState_Getter(mthis) native "FileReader_readyState_Getter";

  static result_Getter(mthis) native "FileReader_result_Getter";

  static abort_Callback(mthis) native "FileReader_abort_Callback";

  static readAsArrayBuffer_Callback_Blob(mthis, blob) native "FileReader_readAsArrayBuffer_Callback_Blob";

  static readAsDataURL_Callback_Blob(mthis, blob) native "FileReader_readAsDataURL_Callback_Blob";

  static readAsText_Callback_Blob_DOMString(mthis, blob, encoding) native "FileReader_readAsText_Callback_Blob_DOMString";

  static readAsText_Callback_Blob(mthis, blob) native "FileReader_readAsText_Callback_Blob";
}

class BlinkFileReaderSync {
  static constructorCallback() native "FileReaderSync_constructorCallback";
}

class BlinkFileWriter {
  static error_Getter(mthis) native "FileWriter_error_Getter";

  static length_Getter(mthis) native "FileWriter_length_Getter";

  static position_Getter(mthis) native "FileWriter_position_Getter";

  static readyState_Getter(mthis) native "FileWriter_readyState_Getter";

  static abort_Callback(mthis) native "FileWriter_abort_Callback";

  static seek_Callback_ll(mthis, position) native "FileWriter_seek_Callback_long long";

  static truncate_Callback_ll(mthis, size) native "FileWriter_truncate_Callback_long long";

  static write_Callback_Blob(mthis, data) native "FileWriter_write_Callback_Blob";
}

class BlinkFileWriterSync {}

class BlinkFocusEvent {
  static relatedTarget_Getter(mthis) native "FocusEvent_relatedTarget_Getter";
}

class BlinkFontFace {
  static constructorCallback_DOMString_DOMString_Dictionary(family, source, descriptors) native "FontFace_constructorCallback_DOMString_DOMString_Dictionary";

  static constructorCallback_DOMString_ArrayBufferView_Dictionary(family, source, descriptors) native "FontFace_constructorCallback_DOMString_ArrayBufferView_Dictionary";

  static constructorCallback_DOMString_ArrayBuffer_Dictionary(family, source, descriptors) native "FontFace_constructorCallback_DOMString_ArrayBuffer_Dictionary";

  static family_Getter(mthis) native "FontFace_family_Getter";

  static family_Setter_DOMString(mthis, value) native "FontFace_family_Setter";

  static featureSettings_Getter(mthis) native "FontFace_featureSettings_Getter";

  static featureSettings_Setter_DOMString(mthis, value) native "FontFace_featureSettings_Setter";

  static status_Getter(mthis) native "FontFace_status_Getter";

  static stretch_Getter(mthis) native "FontFace_stretch_Getter";

  static stretch_Setter_DOMString(mthis, value) native "FontFace_stretch_Setter";

  static style_Getter(mthis) native "FontFace_style_Getter";

  static style_Setter_DOMString(mthis, value) native "FontFace_style_Setter";

  static unicodeRange_Getter(mthis) native "FontFace_unicodeRange_Getter";

  static unicodeRange_Setter_DOMString(mthis, value) native "FontFace_unicodeRange_Setter";

  static variant_Getter(mthis) native "FontFace_variant_Getter";

  static variant_Setter_DOMString(mthis, value) native "FontFace_variant_Setter";

  static weight_Getter(mthis) native "FontFace_weight_Getter";

  static weight_Setter_DOMString(mthis, value) native "FontFace_weight_Setter";
}

class BlinkFontFaceSet {
  static size_Getter(mthis) native "FontFaceSet_size_Getter";

  static status_Getter(mthis) native "FontFaceSet_status_Getter";

  static add_Callback_FontFace(mthis, fontFace) native "FontFaceSet_add_Callback_FontFace";

  static check_Callback_DOMString_DOMString(mthis, font, text) native "FontFaceSet_check_Callback_DOMString_DOMString";

  static clear_Callback(mthis) native "FontFaceSet_clear_Callback";

  static delete_Callback_FontFace(mthis, fontFace) native "FontFaceSet_delete_Callback_FontFace";

  static forEach_Callback_FontFaceSetForEachCallback_ScriptValue(mthis, callback, thisArg) native "FontFaceSet_forEach_Callback_FontFaceSetForEachCallback_ScriptValue";

  static forEach_Callback_FontFaceSetForEachCallback(mthis, callback) native "FontFaceSet_forEach_Callback_FontFaceSetForEachCallback";

  static has_Callback_FontFace(mthis, fontFace) native "FontFaceSet_has_Callback_FontFace";
}

class BlinkFormData {
  static constructorCallback_HTMLFormElement(form) native "FormData_constructorCallback_HTMLFormElement";

  static append_Callback_DOMString_DOMString(mthis, name, value) native "FormData_append_Callback";

  static append_Callback_DOMString_Blob_DOMString(mthis, name, value, filename) native "FormData_append_Callback";
}

class BlinkGainNode {
  static gain_Getter(mthis) native "GainNode_gain_Getter";
}

class BlinkGamepad {
  static axes_Getter(mthis) native "Gamepad_axes_Getter";

  static connected_Getter(mthis) native "Gamepad_connected_Getter";

  static id_Getter(mthis) native "Gamepad_id_Getter";

  static index_Getter(mthis) native "Gamepad_index_Getter";

  static mapping_Getter(mthis) native "Gamepad_mapping_Getter";

  static timestamp_Getter(mthis) native "Gamepad_timestamp_Getter";
}

class BlinkGamepadButton {
  static pressed_Getter(mthis) native "GamepadButton_pressed_Getter";

  static value_Getter(mthis) native "GamepadButton_value_Getter";
}

class BlinkGamepadEvent {
  static gamepad_Getter(mthis) native "GamepadEvent_gamepad_Getter";
}

class BlinkGamepadList {
  static length_Getter(mthis) native "GamepadList_length_Getter";

  static item_Callback_ul(mthis, index) native "GamepadList_item_Callback_unsigned long";
}

class BlinkGeolocation {
  static clearWatch_Callback_long(mthis, watchID) native "Geolocation_clearWatch_Callback_long";

  static getCurrentPosition_Callback_PositionCallback_PositionErrorCallback_object(mthis, successCallback, errorCallback, options) native "Geolocation_getCurrentPosition_Callback";

  static watchPosition_Callback_PositionCallback_PositionErrorCallback_object(mthis, successCallback, errorCallback, options) native "Geolocation_watchPosition_Callback";
}

class BlinkGeoposition {
  static coords_Getter(mthis) native "Geoposition_coords_Getter";

  static timestamp_Getter(mthis) native "Geoposition_timestamp_Getter";
}

class BlinkHTMLAllCollection {
  static item_Callback_ul(mthis, index) native "HTMLAllCollection_item_Callback";
}

class BlinkHTMLElement {
  static contentEditable_Getter(mthis) native "HTMLElement_contentEditable_Getter";

  static contentEditable_Setter_DOMString(mthis, value) native "HTMLElement_contentEditable_Setter";

  static dir_Getter(mthis) native "HTMLElement_dir_Getter";

  static dir_Setter_DOMString(mthis, value) native "HTMLElement_dir_Setter";

  static draggable_Getter(mthis) native "HTMLElement_draggable_Getter";

  static draggable_Setter_boolean(mthis, value) native "HTMLElement_draggable_Setter";

  static hidden_Getter(mthis) native "HTMLElement_hidden_Getter";

  static hidden_Setter_boolean(mthis, value) native "HTMLElement_hidden_Setter";

  static inputMethodContext_Getter(mthis) native "HTMLElement_inputMethodContext_Getter";

  static isContentEditable_Getter(mthis) native "HTMLElement_isContentEditable_Getter";

  static lang_Getter(mthis) native "HTMLElement_lang_Getter";

  static lang_Setter_DOMString(mthis, value) native "HTMLElement_lang_Setter";

  static spellcheck_Getter(mthis) native "HTMLElement_spellcheck_Getter";

  static spellcheck_Setter_boolean(mthis, value) native "HTMLElement_spellcheck_Setter";

  static tabIndex_Getter(mthis) native "HTMLElement_tabIndex_Getter";

  static tabIndex_Setter_long(mthis, value) native "HTMLElement_tabIndex_Setter";

  static title_Getter(mthis) native "HTMLElement_title_Getter";

  static title_Setter_DOMString(mthis, value) native "HTMLElement_title_Setter";

  static translate_Getter(mthis) native "HTMLElement_translate_Getter";

  static translate_Setter_boolean(mthis, value) native "HTMLElement_translate_Setter";

  static webkitdropzone_Getter(mthis) native "HTMLElement_webkitdropzone_Getter";

  static webkitdropzone_Setter_DOMString(mthis, value) native "HTMLElement_webkitdropzone_Setter";

  static click_Callback(mthis) native "HTMLElement_click_Callback";
}

class BlinkURLUtils {
  static hash_Getter(mthis) native "URL_hash_Getter";

  static hash_Setter_DOMString(mthis, value) native "URL_hash_Setter";

  static host_Getter(mthis) native "URL_host_Getter";

  static host_Setter_DOMString(mthis, value) native "URL_host_Setter";

  static hostname_Getter(mthis) native "URL_hostname_Getter";

  static hostname_Setter_DOMString(mthis, value) native "URL_hostname_Setter";

  static href_Getter(mthis) native "URL_href_Getter";

  static href_Setter_DOMString(mthis, value) native "URL_href_Setter";

  static origin_Getter(mthis) native "URL_origin_Getter";

  static password_Getter(mthis) native "URL_password_Getter";

  static password_Setter_DOMString(mthis, value) native "URL_password_Setter";

  static pathname_Getter(mthis) native "URL_pathname_Getter";

  static pathname_Setter_DOMString(mthis, value) native "URL_pathname_Setter";

  static port_Getter(mthis) native "URL_port_Getter";

  static port_Setter_DOMString(mthis, value) native "URL_port_Setter";

  static protocol_Getter(mthis) native "URL_protocol_Getter";

  static protocol_Setter_DOMString(mthis, value) native "URL_protocol_Setter";

  static search_Getter(mthis) native "URL_search_Getter";

  static search_Setter_DOMString(mthis, value) native "URL_search_Setter";

  static username_Getter(mthis) native "URL_username_Getter";

  static username_Setter_DOMString(mthis, value) native "URL_username_Setter";

  static toString_Callback(mthis) native "URL_toString_Callback";
}

class BlinkHTMLAnchorElement {
  static download_Getter(mthis) native "HTMLAnchorElement_download_Getter";

  static download_Setter_DOMString(mthis, value) native "HTMLAnchorElement_download_Setter";

  static hreflang_Getter(mthis) native "HTMLAnchorElement_hreflang_Getter";

  static hreflang_Setter_DOMString(mthis, value) native "HTMLAnchorElement_hreflang_Setter";

  static integrity_Getter(mthis) native "HTMLAnchorElement_integrity_Getter";

  static integrity_Setter_DOMString(mthis, value) native "HTMLAnchorElement_integrity_Setter";

  static rel_Getter(mthis) native "HTMLAnchorElement_rel_Getter";

  static rel_Setter_DOMString(mthis, value) native "HTMLAnchorElement_rel_Setter";

  static target_Getter(mthis) native "HTMLAnchorElement_target_Getter";

  static target_Setter_DOMString(mthis, value) native "HTMLAnchorElement_target_Setter";

  static type_Getter(mthis) native "HTMLAnchorElement_type_Getter";

  static type_Setter_DOMString(mthis, value) native "HTMLAnchorElement_type_Setter";

  static hash_Getter(mthis) native "HTMLAnchorElement_hash_Getter";

  static hash_Setter_DOMString(mthis, value) native "HTMLAnchorElement_hash_Setter";

  static host_Getter(mthis) native "HTMLAnchorElement_host_Getter";

  static host_Setter_DOMString(mthis, value) native "HTMLAnchorElement_host_Setter";

  static hostname_Getter(mthis) native "HTMLAnchorElement_hostname_Getter";

  static hostname_Setter_DOMString(mthis, value) native "HTMLAnchorElement_hostname_Setter";

  static href_Getter(mthis) native "HTMLAnchorElement_href_Getter";

  static href_Setter_DOMString(mthis, value) native "HTMLAnchorElement_href_Setter";

  static origin_Getter(mthis) native "HTMLAnchorElement_origin_Getter";

  static password_Getter(mthis) native "HTMLAnchorElement_password_Getter";

  static password_Setter_DOMString(mthis, value) native "HTMLAnchorElement_password_Setter";

  static pathname_Getter(mthis) native "HTMLAnchorElement_pathname_Getter";

  static pathname_Setter_DOMString(mthis, value) native "HTMLAnchorElement_pathname_Setter";

  static port_Getter(mthis) native "HTMLAnchorElement_port_Getter";

  static port_Setter_DOMString(mthis, value) native "HTMLAnchorElement_port_Setter";

  static protocol_Getter(mthis) native "HTMLAnchorElement_protocol_Getter";

  static protocol_Setter_DOMString(mthis, value) native "HTMLAnchorElement_protocol_Setter";

  static search_Getter(mthis) native "HTMLAnchorElement_search_Getter";

  static search_Setter_DOMString(mthis, value) native "HTMLAnchorElement_search_Setter";

  static username_Getter(mthis) native "HTMLAnchorElement_username_Getter";

  static username_Setter_DOMString(mthis, value) native "HTMLAnchorElement_username_Setter";

  static toString_Callback(mthis) native "HTMLAnchorElement_toString_Callback";
}

class BlinkHTMLAppletElement {}

class BlinkHTMLAreaElement {
  static alt_Getter(mthis) native "HTMLAreaElement_alt_Getter";

  static alt_Setter_DOMString(mthis, value) native "HTMLAreaElement_alt_Setter";

  static coords_Getter(mthis) native "HTMLAreaElement_coords_Getter";

  static coords_Setter_DOMString(mthis, value) native "HTMLAreaElement_coords_Setter";

  static shape_Getter(mthis) native "HTMLAreaElement_shape_Getter";

  static shape_Setter_DOMString(mthis, value) native "HTMLAreaElement_shape_Setter";

  static target_Getter(mthis) native "HTMLAreaElement_target_Getter";

  static target_Setter_DOMString(mthis, value) native "HTMLAreaElement_target_Setter";

  static hash_Getter(mthis) native "HTMLAreaElement_hash_Getter";

  static hash_Setter_DOMString(mthis, value) native "HTMLAreaElement_hash_Setter";

  static host_Getter(mthis) native "HTMLAreaElement_host_Getter";

  static host_Setter_DOMString(mthis, value) native "HTMLAreaElement_host_Setter";

  static hostname_Getter(mthis) native "HTMLAreaElement_hostname_Getter";

  static hostname_Setter_DOMString(mthis, value) native "HTMLAreaElement_hostname_Setter";

  static href_Getter(mthis) native "HTMLAreaElement_href_Getter";

  static href_Setter_DOMString(mthis, value) native "HTMLAreaElement_href_Setter";

  static origin_Getter(mthis) native "HTMLAreaElement_origin_Getter";

  static password_Getter(mthis) native "HTMLAreaElement_password_Getter";

  static password_Setter_DOMString(mthis, value) native "HTMLAreaElement_password_Setter";

  static pathname_Getter(mthis) native "HTMLAreaElement_pathname_Getter";

  static pathname_Setter_DOMString(mthis, value) native "HTMLAreaElement_pathname_Setter";

  static port_Getter(mthis) native "HTMLAreaElement_port_Getter";

  static port_Setter_DOMString(mthis, value) native "HTMLAreaElement_port_Setter";

  static protocol_Getter(mthis) native "HTMLAreaElement_protocol_Getter";

  static protocol_Setter_DOMString(mthis, value) native "HTMLAreaElement_protocol_Setter";

  static search_Getter(mthis) native "HTMLAreaElement_search_Getter";

  static search_Setter_DOMString(mthis, value) native "HTMLAreaElement_search_Setter";

  static username_Getter(mthis) native "HTMLAreaElement_username_Getter";

  static username_Setter_DOMString(mthis, value) native "HTMLAreaElement_username_Setter";

  static toString_Callback(mthis) native "HTMLAreaElement_toString_Callback";
}

class BlinkHTMLMediaElement {
  static audioTracks_Getter(mthis) native "HTMLMediaElement_audioTracks_Getter";

  static autoplay_Getter(mthis) native "HTMLMediaElement_autoplay_Getter";

  static autoplay_Setter_boolean(mthis, value) native "HTMLMediaElement_autoplay_Setter";

  static buffered_Getter(mthis) native "HTMLMediaElement_buffered_Getter";

  static controller_Getter(mthis) native "HTMLMediaElement_controller_Getter";

  static controller_Setter_MediaController(mthis, value) native "HTMLMediaElement_controller_Setter";

  static controls_Getter(mthis) native "HTMLMediaElement_controls_Getter";

  static controls_Setter_boolean(mthis, value) native "HTMLMediaElement_controls_Setter";

  static crossOrigin_Getter(mthis) native "HTMLMediaElement_crossOrigin_Getter";

  static crossOrigin_Setter_DOMString(mthis, value) native "HTMLMediaElement_crossOrigin_Setter";

  static currentSrc_Getter(mthis) native "HTMLMediaElement_currentSrc_Getter";

  static currentTime_Getter(mthis) native "HTMLMediaElement_currentTime_Getter";

  static currentTime_Setter_double(mthis, value) native "HTMLMediaElement_currentTime_Setter";

  static defaultMuted_Getter(mthis) native "HTMLMediaElement_defaultMuted_Getter";

  static defaultMuted_Setter_boolean(mthis, value) native "HTMLMediaElement_defaultMuted_Setter";

  static defaultPlaybackRate_Getter(mthis) native "HTMLMediaElement_defaultPlaybackRate_Getter";

  static defaultPlaybackRate_Setter_double(mthis, value) native "HTMLMediaElement_defaultPlaybackRate_Setter";

  static duration_Getter(mthis) native "HTMLMediaElement_duration_Getter";

  static ended_Getter(mthis) native "HTMLMediaElement_ended_Getter";

  static error_Getter(mthis) native "HTMLMediaElement_error_Getter";

  static integrity_Getter(mthis) native "HTMLMediaElement_integrity_Getter";

  static integrity_Setter_DOMString(mthis, value) native "HTMLMediaElement_integrity_Setter";

  static loop_Getter(mthis) native "HTMLMediaElement_loop_Getter";

  static loop_Setter_boolean(mthis, value) native "HTMLMediaElement_loop_Setter";

  static mediaGroup_Getter(mthis) native "HTMLMediaElement_mediaGroup_Getter";

  static mediaGroup_Setter_DOMString(mthis, value) native "HTMLMediaElement_mediaGroup_Setter";

  static mediaKeys_Getter(mthis) native "HTMLMediaElement_mediaKeys_Getter";

  static muted_Getter(mthis) native "HTMLMediaElement_muted_Getter";

  static muted_Setter_boolean(mthis, value) native "HTMLMediaElement_muted_Setter";

  static networkState_Getter(mthis) native "HTMLMediaElement_networkState_Getter";

  static paused_Getter(mthis) native "HTMLMediaElement_paused_Getter";

  static playbackRate_Getter(mthis) native "HTMLMediaElement_playbackRate_Getter";

  static playbackRate_Setter_double(mthis, value) native "HTMLMediaElement_playbackRate_Setter";

  static played_Getter(mthis) native "HTMLMediaElement_played_Getter";

  static preload_Getter(mthis) native "HTMLMediaElement_preload_Getter";

  static preload_Setter_DOMString(mthis, value) native "HTMLMediaElement_preload_Setter";

  static readyState_Getter(mthis) native "HTMLMediaElement_readyState_Getter";

  static seekable_Getter(mthis) native "HTMLMediaElement_seekable_Getter";

  static seeking_Getter(mthis) native "HTMLMediaElement_seeking_Getter";

  static src_Getter(mthis) native "HTMLMediaElement_src_Getter";

  static src_Setter_DOMString(mthis, value) native "HTMLMediaElement_src_Setter";

  static textTracks_Getter(mthis) native "HTMLMediaElement_textTracks_Getter";

  static videoTracks_Getter(mthis) native "HTMLMediaElement_videoTracks_Getter";

  static volume_Getter(mthis) native "HTMLMediaElement_volume_Getter";

  static volume_Setter_double(mthis, value) native "HTMLMediaElement_volume_Setter";

  static webkitAudioDecodedByteCount_Getter(mthis) native "HTMLMediaElement_webkitAudioDecodedByteCount_Getter";

  static webkitVideoDecodedByteCount_Getter(mthis) native "HTMLMediaElement_webkitVideoDecodedByteCount_Getter";

  static addTextTrack_Callback_DOMString_DOMString_DOMString(mthis, kind, label, language) native "HTMLMediaElement_addTextTrack_Callback_DOMString_DOMString_DOMString";

  static addTextTrack_Callback_DOMString_DOMString(mthis, kind, label) native "HTMLMediaElement_addTextTrack_Callback_DOMString_DOMString";

  static addTextTrack_Callback_DOMString(mthis, kind) native "HTMLMediaElement_addTextTrack_Callback_DOMString";

  static canPlayType_Callback_DOMString_DOMString(mthis, type, keySystem) native "HTMLMediaElement_canPlayType_Callback_DOMString_DOMString";

  static load_Callback(mthis) native "HTMLMediaElement_load_Callback";

  static pause_Callback(mthis) native "HTMLMediaElement_pause_Callback";

  static play_Callback(mthis) native "HTMLMediaElement_play_Callback";

  static setMediaKeys_Callback_MediaKeys(mthis, mediaKeys) native "HTMLMediaElement_setMediaKeys_Callback_MediaKeys";

  static webkitAddKey_Callback_DOMString_Uint8Array_Uint8Array_DOMString(mthis, keySystem, key, initData, sessionId) native "HTMLMediaElement_webkitAddKey_Callback_DOMString_Uint8Array_Uint8Array_DOMString";

  static webkitAddKey_Callback_DOMString_Uint8Array(mthis, keySystem, key) native "HTMLMediaElement_webkitAddKey_Callback_DOMString_Uint8Array";

  static webkitCancelKeyRequest_Callback_DOMString_DOMString(mthis, keySystem, sessionId) native "HTMLMediaElement_webkitCancelKeyRequest_Callback_DOMString_DOMString";

  static webkitGenerateKeyRequest_Callback_DOMString_Uint8Array(mthis, keySystem, initData) native "HTMLMediaElement_webkitGenerateKeyRequest_Callback_DOMString_Uint8Array";

  static webkitGenerateKeyRequest_Callback_DOMString(mthis, keySystem) native "HTMLMediaElement_webkitGenerateKeyRequest_Callback_DOMString";
}

class BlinkHTMLAudioElement {
  static constructorCallback_DOMString(src) native "HTMLAudioElement_constructorCallback_DOMString";
}

class BlinkHTMLBRElement {}

class BlinkHTMLBaseElement {
  static href_Getter(mthis) native "HTMLBaseElement_href_Getter";

  static href_Setter_DOMString(mthis, value) native "HTMLBaseElement_href_Setter";

  static target_Getter(mthis) native "HTMLBaseElement_target_Getter";

  static target_Setter_DOMString(mthis, value) native "HTMLBaseElement_target_Setter";
}

class BlinkWindowEventHandlers {}

class BlinkHTMLBodyElement {}

class BlinkHTMLButtonElement {
  static autofocus_Getter(mthis) native "HTMLButtonElement_autofocus_Getter";

  static autofocus_Setter_boolean(mthis, value) native "HTMLButtonElement_autofocus_Setter";

  static disabled_Getter(mthis) native "HTMLButtonElement_disabled_Getter";

  static disabled_Setter_boolean(mthis, value) native "HTMLButtonElement_disabled_Setter";

  static form_Getter(mthis) native "HTMLButtonElement_form_Getter";

  static formAction_Getter(mthis) native "HTMLButtonElement_formAction_Getter";

  static formAction_Setter_DOMString(mthis, value) native "HTMLButtonElement_formAction_Setter";

  static formEnctype_Getter(mthis) native "HTMLButtonElement_formEnctype_Getter";

  static formEnctype_Setter_DOMString(mthis, value) native "HTMLButtonElement_formEnctype_Setter";

  static formMethod_Getter(mthis) native "HTMLButtonElement_formMethod_Getter";

  static formMethod_Setter_DOMString(mthis, value) native "HTMLButtonElement_formMethod_Setter";

  static formNoValidate_Getter(mthis) native "HTMLButtonElement_formNoValidate_Getter";

  static formNoValidate_Setter_boolean(mthis, value) native "HTMLButtonElement_formNoValidate_Setter";

  static formTarget_Getter(mthis) native "HTMLButtonElement_formTarget_Getter";

  static formTarget_Setter_DOMString(mthis, value) native "HTMLButtonElement_formTarget_Setter";

  static labels_Getter(mthis) native "HTMLButtonElement_labels_Getter";

  static name_Getter(mthis) native "HTMLButtonElement_name_Getter";

  static name_Setter_DOMString(mthis, value) native "HTMLButtonElement_name_Setter";

  static type_Getter(mthis) native "HTMLButtonElement_type_Getter";

  static type_Setter_DOMString(mthis, value) native "HTMLButtonElement_type_Setter";

  static validationMessage_Getter(mthis) native "HTMLButtonElement_validationMessage_Getter";

  static validity_Getter(mthis) native "HTMLButtonElement_validity_Getter";

  static value_Getter(mthis) native "HTMLButtonElement_value_Getter";

  static value_Setter_DOMString(mthis, value) native "HTMLButtonElement_value_Setter";

  static willValidate_Getter(mthis) native "HTMLButtonElement_willValidate_Getter";

  static checkValidity_Callback(mthis) native "HTMLButtonElement_checkValidity_Callback";

  static setCustomValidity_Callback_DOMString(mthis, error) native "HTMLButtonElement_setCustomValidity_Callback_DOMString";
}

class BlinkHTMLCanvasElement {
  static height_Getter(mthis) native "HTMLCanvasElement_height_Getter";

  static height_Setter_long(mthis, value) native "HTMLCanvasElement_height_Setter";

  static width_Getter(mthis) native "HTMLCanvasElement_width_Getter";

  static width_Setter_long(mthis, value) native "HTMLCanvasElement_width_Setter";

  static getContext_Callback_DOMString_Dictionary(mthis, contextId, attrs) native "HTMLCanvasElement_getContext_Callback";

  static toDataURL_Callback_DOMString_float(mthis, type, quality) native "HTMLCanvasElement_toDataURL_Callback";
}

class BlinkHTMLCollection {
  static length_Getter(mthis) native "HTMLCollection_length_Getter";

  static item_Callback_ul(mthis, index) native "HTMLCollection_item_Callback_unsigned long";

  static namedItem_Callback_DOMString(mthis, name) native "HTMLCollection_namedItem_Callback_DOMString";
}

class BlinkHTMLContentElement {
  static select_Getter(mthis) native "HTMLContentElement_select_Getter";

  static select_Setter_DOMString(mthis, value) native "HTMLContentElement_select_Setter";

  static getDistributedNodes_Callback(mthis) native "HTMLContentElement_getDistributedNodes_Callback";
}

class BlinkHTMLDListElement {}

class BlinkHTMLDataListElement {
  static options_Getter(mthis) native "HTMLDataListElement_options_Getter";
}

class BlinkHTMLDetailsElement {
  static open_Getter(mthis) native "HTMLDetailsElement_open_Getter";

  static open_Setter_boolean(mthis, value) native "HTMLDetailsElement_open_Setter";
}

class BlinkHTMLDialogElement {
  static open_Getter(mthis) native "HTMLDialogElement_open_Getter";

  static open_Setter_boolean(mthis, value) native "HTMLDialogElement_open_Setter";

  static returnValue_Getter(mthis) native "HTMLDialogElement_returnValue_Getter";

  static returnValue_Setter_DOMString(mthis, value) native "HTMLDialogElement_returnValue_Setter";

  static close_Callback_DOMString(mthis, returnValue) native "HTMLDialogElement_close_Callback_DOMString";

  static show_Callback(mthis) native "HTMLDialogElement_show_Callback";

  static showModal_Callback(mthis) native "HTMLDialogElement_showModal_Callback";
}

class BlinkHTMLDirectoryElement {}

class BlinkHTMLDivElement {}

class BlinkHTMLDocument {}

class BlinkHTMLEmbedElement {
  static height_Getter(mthis) native "HTMLEmbedElement_height_Getter";

  static height_Setter_DOMString(mthis, value) native "HTMLEmbedElement_height_Setter";

  static integrity_Getter(mthis) native "HTMLEmbedElement_integrity_Getter";

  static integrity_Setter_DOMString(mthis, value) native "HTMLEmbedElement_integrity_Setter";

  static name_Getter(mthis) native "HTMLEmbedElement_name_Getter";

  static name_Setter_DOMString(mthis, value) native "HTMLEmbedElement_name_Setter";

  static src_Getter(mthis) native "HTMLEmbedElement_src_Getter";

  static src_Setter_DOMString(mthis, value) native "HTMLEmbedElement_src_Setter";

  static type_Getter(mthis) native "HTMLEmbedElement_type_Getter";

  static type_Setter_DOMString(mthis, value) native "HTMLEmbedElement_type_Setter";

  static width_Getter(mthis) native "HTMLEmbedElement_width_Getter";

  static width_Setter_DOMString(mthis, value) native "HTMLEmbedElement_width_Setter";

  static $__getter___Callback_ul(mthis, index_OR_name) native "HTMLEmbedElement___getter___Callback";

  static $__setter___Callback_ul_Node(mthis, index_OR_name, value) native "HTMLEmbedElement___setter___Callback";
}

class BlinkHTMLFieldSetElement {
  static disabled_Getter(mthis) native "HTMLFieldSetElement_disabled_Getter";

  static disabled_Setter_boolean(mthis, value) native "HTMLFieldSetElement_disabled_Setter";

  static elements_Getter(mthis) native "HTMLFieldSetElement_elements_Getter";

  static form_Getter(mthis) native "HTMLFieldSetElement_form_Getter";

  static name_Getter(mthis) native "HTMLFieldSetElement_name_Getter";

  static name_Setter_DOMString(mthis, value) native "HTMLFieldSetElement_name_Setter";

  static type_Getter(mthis) native "HTMLFieldSetElement_type_Getter";

  static validationMessage_Getter(mthis) native "HTMLFieldSetElement_validationMessage_Getter";

  static validity_Getter(mthis) native "HTMLFieldSetElement_validity_Getter";

  static willValidate_Getter(mthis) native "HTMLFieldSetElement_willValidate_Getter";

  static checkValidity_Callback(mthis) native "HTMLFieldSetElement_checkValidity_Callback";

  static setCustomValidity_Callback_DOMString(mthis, error) native "HTMLFieldSetElement_setCustomValidity_Callback_DOMString";
}

class BlinkHTMLFontElement {}

class BlinkHTMLFormControlsCollection {
  static namedItem_Callback_DOMString(mthis, name) native "HTMLFormControlsCollection_namedItem_Callback_DOMString";
}

class BlinkHTMLFormElement {
  static acceptCharset_Getter(mthis) native "HTMLFormElement_acceptCharset_Getter";

  static acceptCharset_Setter_DOMString(mthis, value) native "HTMLFormElement_acceptCharset_Setter";

  static action_Getter(mthis) native "HTMLFormElement_action_Getter";

  static action_Setter_DOMString(mthis, value) native "HTMLFormElement_action_Setter";

  static autocomplete_Getter(mthis) native "HTMLFormElement_autocomplete_Getter";

  static autocomplete_Setter_DOMString(mthis, value) native "HTMLFormElement_autocomplete_Setter";

  static encoding_Getter(mthis) native "HTMLFormElement_encoding_Getter";

  static encoding_Setter_DOMString(mthis, value) native "HTMLFormElement_encoding_Setter";

  static enctype_Getter(mthis) native "HTMLFormElement_enctype_Getter";

  static enctype_Setter_DOMString(mthis, value) native "HTMLFormElement_enctype_Setter";

  static length_Getter(mthis) native "HTMLFormElement_length_Getter";

  static method_Getter(mthis) native "HTMLFormElement_method_Getter";

  static method_Setter_DOMString(mthis, value) native "HTMLFormElement_method_Setter";

  static name_Getter(mthis) native "HTMLFormElement_name_Getter";

  static name_Setter_DOMString(mthis, value) native "HTMLFormElement_name_Setter";

  static noValidate_Getter(mthis) native "HTMLFormElement_noValidate_Getter";

  static noValidate_Setter_boolean(mthis, value) native "HTMLFormElement_noValidate_Setter";

  static target_Getter(mthis) native "HTMLFormElement_target_Getter";

  static target_Setter_DOMString(mthis, value) native "HTMLFormElement_target_Setter";

  static $__getter___Callback_ul(mthis, index_OR_name) native "HTMLFormElement___getter___Callback_unsigned long";

  static $__getter___Callback_DOMString(mthis, index_OR_name) native "HTMLFormElement___getter___Callback_DOMString";

  static checkValidity_Callback(mthis) native "HTMLFormElement_checkValidity_Callback";

  static requestAutocomplete_Callback_Dictionary(mthis, details) native "HTMLFormElement_requestAutocomplete_Callback_Dictionary";

  static reset_Callback(mthis) native "HTMLFormElement_reset_Callback";

  static submit_Callback(mthis) native "HTMLFormElement_submit_Callback";
}

class BlinkHTMLFrameElement {}

class BlinkHTMLFrameSetElement {}

class BlinkHTMLHRElement {
  static color_Getter(mthis) native "HTMLHRElement_color_Getter";

  static color_Setter_DOMString(mthis, value) native "HTMLHRElement_color_Setter";
}

class BlinkHTMLHeadElement {}

class BlinkHTMLHeadingElement {}

class BlinkHTMLHtmlElement {}

class BlinkHTMLIFrameElement {
  static contentWindow_Getter(mthis) native "HTMLIFrameElement_contentWindow_Getter";

  static height_Getter(mthis) native "HTMLIFrameElement_height_Getter";

  static height_Setter_DOMString(mthis, value) native "HTMLIFrameElement_height_Setter";

  static integrity_Getter(mthis) native "HTMLIFrameElement_integrity_Getter";

  static integrity_Setter_DOMString(mthis, value) native "HTMLIFrameElement_integrity_Setter";

  static name_Getter(mthis) native "HTMLIFrameElement_name_Getter";

  static name_Setter_DOMString(mthis, value) native "HTMLIFrameElement_name_Setter";

  static sandbox_Getter(mthis) native "HTMLIFrameElement_sandbox_Getter";

  static sandbox_Setter_DOMString(mthis, value) native "HTMLIFrameElement_sandbox_Setter";

  static src_Getter(mthis) native "HTMLIFrameElement_src_Getter";

  static src_Setter_DOMString(mthis, value) native "HTMLIFrameElement_src_Setter";

  static srcdoc_Getter(mthis) native "HTMLIFrameElement_srcdoc_Getter";

  static srcdoc_Setter_DOMString(mthis, value) native "HTMLIFrameElement_srcdoc_Setter";

  static width_Getter(mthis) native "HTMLIFrameElement_width_Getter";

  static width_Setter_DOMString(mthis, value) native "HTMLIFrameElement_width_Setter";
}

class BlinkHTMLImageElement {
  static alt_Getter(mthis) native "HTMLImageElement_alt_Getter";

  static alt_Setter_DOMString(mthis, value) native "HTMLImageElement_alt_Setter";

  static complete_Getter(mthis) native "HTMLImageElement_complete_Getter";

  static crossOrigin_Getter(mthis) native "HTMLImageElement_crossOrigin_Getter";

  static crossOrigin_Setter_DOMString(mthis, value) native "HTMLImageElement_crossOrigin_Setter";

  static currentSrc_Getter(mthis) native "HTMLImageElement_currentSrc_Getter";

  static height_Getter(mthis) native "HTMLImageElement_height_Getter";

  static height_Setter_long(mthis, value) native "HTMLImageElement_height_Setter";

  static integrity_Getter(mthis) native "HTMLImageElement_integrity_Getter";

  static integrity_Setter_DOMString(mthis, value) native "HTMLImageElement_integrity_Setter";

  static isMap_Getter(mthis) native "HTMLImageElement_isMap_Getter";

  static isMap_Setter_boolean(mthis, value) native "HTMLImageElement_isMap_Setter";

  static naturalHeight_Getter(mthis) native "HTMLImageElement_naturalHeight_Getter";

  static naturalWidth_Getter(mthis) native "HTMLImageElement_naturalWidth_Getter";

  static sizes_Getter(mthis) native "HTMLImageElement_sizes_Getter";

  static sizes_Setter_DOMString(mthis, value) native "HTMLImageElement_sizes_Setter";

  static src_Getter(mthis) native "HTMLImageElement_src_Getter";

  static src_Setter_DOMString(mthis, value) native "HTMLImageElement_src_Setter";

  static srcset_Getter(mthis) native "HTMLImageElement_srcset_Getter";

  static srcset_Setter_DOMString(mthis, value) native "HTMLImageElement_srcset_Setter";

  static useMap_Getter(mthis) native "HTMLImageElement_useMap_Getter";

  static useMap_Setter_DOMString(mthis, value) native "HTMLImageElement_useMap_Setter";

  static width_Getter(mthis) native "HTMLImageElement_width_Getter";

  static width_Setter_long(mthis, value) native "HTMLImageElement_width_Setter";
}

class BlinkHTMLInputElement {
  static accept_Getter(mthis) native "HTMLInputElement_accept_Getter";

  static accept_Setter_DOMString(mthis, value) native "HTMLInputElement_accept_Setter";

  static alt_Getter(mthis) native "HTMLInputElement_alt_Getter";

  static alt_Setter_DOMString(mthis, value) native "HTMLInputElement_alt_Setter";

  static autocomplete_Getter(mthis) native "HTMLInputElement_autocomplete_Getter";

  static autocomplete_Setter_DOMString(mthis, value) native "HTMLInputElement_autocomplete_Setter";

  static autofocus_Getter(mthis) native "HTMLInputElement_autofocus_Getter";

  static autofocus_Setter_boolean(mthis, value) native "HTMLInputElement_autofocus_Setter";

  static checked_Getter(mthis) native "HTMLInputElement_checked_Getter";

  static checked_Setter_boolean(mthis, value) native "HTMLInputElement_checked_Setter";

  static defaultChecked_Getter(mthis) native "HTMLInputElement_defaultChecked_Getter";

  static defaultChecked_Setter_boolean(mthis, value) native "HTMLInputElement_defaultChecked_Setter";

  static defaultValue_Getter(mthis) native "HTMLInputElement_defaultValue_Getter";

  static defaultValue_Setter_DOMString(mthis, value) native "HTMLInputElement_defaultValue_Setter";

  static dirName_Getter(mthis) native "HTMLInputElement_dirName_Getter";

  static dirName_Setter_DOMString(mthis, value) native "HTMLInputElement_dirName_Setter";

  static disabled_Getter(mthis) native "HTMLInputElement_disabled_Getter";

  static disabled_Setter_boolean(mthis, value) native "HTMLInputElement_disabled_Setter";

  static files_Getter(mthis) native "HTMLInputElement_files_Getter";

  static files_Setter_FileList(mthis, value) native "HTMLInputElement_files_Setter";

  static form_Getter(mthis) native "HTMLInputElement_form_Getter";

  static formAction_Getter(mthis) native "HTMLInputElement_formAction_Getter";

  static formAction_Setter_DOMString(mthis, value) native "HTMLInputElement_formAction_Setter";

  static formEnctype_Getter(mthis) native "HTMLInputElement_formEnctype_Getter";

  static formEnctype_Setter_DOMString(mthis, value) native "HTMLInputElement_formEnctype_Setter";

  static formMethod_Getter(mthis) native "HTMLInputElement_formMethod_Getter";

  static formMethod_Setter_DOMString(mthis, value) native "HTMLInputElement_formMethod_Setter";

  static formNoValidate_Getter(mthis) native "HTMLInputElement_formNoValidate_Getter";

  static formNoValidate_Setter_boolean(mthis, value) native "HTMLInputElement_formNoValidate_Setter";

  static formTarget_Getter(mthis) native "HTMLInputElement_formTarget_Getter";

  static formTarget_Setter_DOMString(mthis, value) native "HTMLInputElement_formTarget_Setter";

  static height_Getter(mthis) native "HTMLInputElement_height_Getter";

  static height_Setter_ul(mthis, value) native "HTMLInputElement_height_Setter";

  static incremental_Getter(mthis) native "HTMLInputElement_incremental_Getter";

  static incremental_Setter_boolean(mthis, value) native "HTMLInputElement_incremental_Setter";

  static indeterminate_Getter(mthis) native "HTMLInputElement_indeterminate_Getter";

  static indeterminate_Setter_boolean(mthis, value) native "HTMLInputElement_indeterminate_Setter";

  static inputMode_Getter(mthis) native "HTMLInputElement_inputMode_Getter";

  static inputMode_Setter_DOMString(mthis, value) native "HTMLInputElement_inputMode_Setter";

  static labels_Getter(mthis) native "HTMLInputElement_labels_Getter";

  static list_Getter(mthis) native "HTMLInputElement_list_Getter";

  static max_Getter(mthis) native "HTMLInputElement_max_Getter";

  static max_Setter_DOMString(mthis, value) native "HTMLInputElement_max_Setter";

  static maxLength_Getter(mthis) native "HTMLInputElement_maxLength_Getter";

  static maxLength_Setter_long(mthis, value) native "HTMLInputElement_maxLength_Setter";

  static min_Getter(mthis) native "HTMLInputElement_min_Getter";

  static min_Setter_DOMString(mthis, value) native "HTMLInputElement_min_Setter";

  static multiple_Getter(mthis) native "HTMLInputElement_multiple_Getter";

  static multiple_Setter_boolean(mthis, value) native "HTMLInputElement_multiple_Setter";

  static name_Getter(mthis) native "HTMLInputElement_name_Getter";

  static name_Setter_DOMString(mthis, value) native "HTMLInputElement_name_Setter";

  static pattern_Getter(mthis) native "HTMLInputElement_pattern_Getter";

  static pattern_Setter_DOMString(mthis, value) native "HTMLInputElement_pattern_Setter";

  static placeholder_Getter(mthis) native "HTMLInputElement_placeholder_Getter";

  static placeholder_Setter_DOMString(mthis, value) native "HTMLInputElement_placeholder_Setter";

  static readOnly_Getter(mthis) native "HTMLInputElement_readOnly_Getter";

  static readOnly_Setter_boolean(mthis, value) native "HTMLInputElement_readOnly_Setter";

  static required_Getter(mthis) native "HTMLInputElement_required_Getter";

  static required_Setter_boolean(mthis, value) native "HTMLInputElement_required_Setter";

  static selectionDirection_Getter(mthis) native "HTMLInputElement_selectionDirection_Getter";

  static selectionDirection_Setter_DOMString(mthis, value) native "HTMLInputElement_selectionDirection_Setter";

  static selectionEnd_Getter(mthis) native "HTMLInputElement_selectionEnd_Getter";

  static selectionEnd_Setter_long(mthis, value) native "HTMLInputElement_selectionEnd_Setter";

  static selectionStart_Getter(mthis) native "HTMLInputElement_selectionStart_Getter";

  static selectionStart_Setter_long(mthis, value) native "HTMLInputElement_selectionStart_Setter";

  static size_Getter(mthis) native "HTMLInputElement_size_Getter";

  static size_Setter_ul(mthis, value) native "HTMLInputElement_size_Setter";

  static src_Getter(mthis) native "HTMLInputElement_src_Getter";

  static src_Setter_DOMString(mthis, value) native "HTMLInputElement_src_Setter";

  static step_Getter(mthis) native "HTMLInputElement_step_Getter";

  static step_Setter_DOMString(mthis, value) native "HTMLInputElement_step_Setter";

  static type_Getter(mthis) native "HTMLInputElement_type_Getter";

  static type_Setter_DOMString(mthis, value) native "HTMLInputElement_type_Setter";

  static validationMessage_Getter(mthis) native "HTMLInputElement_validationMessage_Getter";

  static validity_Getter(mthis) native "HTMLInputElement_validity_Getter";

  static value_Getter(mthis) native "HTMLInputElement_value_Getter";

  static value_Setter_DOMString(mthis, value) native "HTMLInputElement_value_Setter";

  static valueAsDate_Getter(mthis) native "HTMLInputElement_valueAsDate_Getter";

  static valueAsDate_Setter_Date(mthis, value) native "HTMLInputElement_valueAsDate_Setter";

  static valueAsNumber_Getter(mthis) native "HTMLInputElement_valueAsNumber_Getter";

  static valueAsNumber_Setter_double(mthis, value) native "HTMLInputElement_valueAsNumber_Setter";

  static webkitEntries_Getter(mthis) native "HTMLInputElement_webkitEntries_Getter";

  static webkitdirectory_Getter(mthis) native "HTMLInputElement_webkitdirectory_Getter";

  static webkitdirectory_Setter_boolean(mthis, value) native "HTMLInputElement_webkitdirectory_Setter";

  static width_Getter(mthis) native "HTMLInputElement_width_Getter";

  static width_Setter_ul(mthis, value) native "HTMLInputElement_width_Setter";

  static willValidate_Getter(mthis) native "HTMLInputElement_willValidate_Getter";

  static checkValidity_Callback(mthis) native "HTMLInputElement_checkValidity_Callback";

  static select_Callback(mthis) native "HTMLInputElement_select_Callback";

  static setCustomValidity_Callback_DOMString(mthis, error) native "HTMLInputElement_setCustomValidity_Callback_DOMString";

  static setRangeText_Callback_DOMString(mthis, replacement) native "HTMLInputElement_setRangeText_Callback_DOMString";

  static setRangeText_Callback_DOMString_ul_ul_DOMString(mthis, replacement, start, end, selectionMode) native "HTMLInputElement_setRangeText_Callback_DOMString_unsigned long_unsigned long_DOMString";

  static setSelectionRange_Callback_long_long_DOMString(mthis, start, end, direction) native "HTMLInputElement_setSelectionRange_Callback_long_long_DOMString";

  static setSelectionRange_Callback_long_long(mthis, start, end) native "HTMLInputElement_setSelectionRange_Callback_long_long";

  static stepDown_Callback_long(mthis, n) native "HTMLInputElement_stepDown_Callback_long";

  static stepDown_Callback(mthis) native "HTMLInputElement_stepDown_Callback";

  static stepUp_Callback_long(mthis, n) native "HTMLInputElement_stepUp_Callback_long";

  static stepUp_Callback(mthis) native "HTMLInputElement_stepUp_Callback";
}

class BlinkHTMLKeygenElement {
  static autofocus_Getter(mthis) native "HTMLKeygenElement_autofocus_Getter";

  static autofocus_Setter_boolean(mthis, value) native "HTMLKeygenElement_autofocus_Setter";

  static challenge_Getter(mthis) native "HTMLKeygenElement_challenge_Getter";

  static challenge_Setter_DOMString(mthis, value) native "HTMLKeygenElement_challenge_Setter";

  static disabled_Getter(mthis) native "HTMLKeygenElement_disabled_Getter";

  static disabled_Setter_boolean(mthis, value) native "HTMLKeygenElement_disabled_Setter";

  static form_Getter(mthis) native "HTMLKeygenElement_form_Getter";

  static keytype_Getter(mthis) native "HTMLKeygenElement_keytype_Getter";

  static keytype_Setter_DOMString(mthis, value) native "HTMLKeygenElement_keytype_Setter";

  static labels_Getter(mthis) native "HTMLKeygenElement_labels_Getter";

  static name_Getter(mthis) native "HTMLKeygenElement_name_Getter";

  static name_Setter_DOMString(mthis, value) native "HTMLKeygenElement_name_Setter";

  static type_Getter(mthis) native "HTMLKeygenElement_type_Getter";

  static validationMessage_Getter(mthis) native "HTMLKeygenElement_validationMessage_Getter";

  static validity_Getter(mthis) native "HTMLKeygenElement_validity_Getter";

  static willValidate_Getter(mthis) native "HTMLKeygenElement_willValidate_Getter";

  static checkValidity_Callback(mthis) native "HTMLKeygenElement_checkValidity_Callback";

  static setCustomValidity_Callback_DOMString(mthis, error) native "HTMLKeygenElement_setCustomValidity_Callback_DOMString";
}

class BlinkHTMLLIElement {
  static value_Getter(mthis) native "HTMLLIElement_value_Getter";

  static value_Setter_long(mthis, value) native "HTMLLIElement_value_Setter";
}

class BlinkHTMLLabelElement {
  static control_Getter(mthis) native "HTMLLabelElement_control_Getter";

  static form_Getter(mthis) native "HTMLLabelElement_form_Getter";

  static htmlFor_Getter(mthis) native "HTMLLabelElement_htmlFor_Getter";

  static htmlFor_Setter_DOMString(mthis, value) native "HTMLLabelElement_htmlFor_Setter";
}

class BlinkHTMLLegendElement {
  static form_Getter(mthis) native "HTMLLegendElement_form_Getter";
}

class BlinkHTMLLinkElement {
  static crossOrigin_Getter(mthis) native "HTMLLinkElement_crossOrigin_Getter";

  static crossOrigin_Setter_DOMString(mthis, value) native "HTMLLinkElement_crossOrigin_Setter";

  static disabled_Getter(mthis) native "HTMLLinkElement_disabled_Getter";

  static disabled_Setter_boolean(mthis, value) native "HTMLLinkElement_disabled_Setter";

  static href_Getter(mthis) native "HTMLLinkElement_href_Getter";

  static href_Setter_DOMString(mthis, value) native "HTMLLinkElement_href_Setter";

  static hreflang_Getter(mthis) native "HTMLLinkElement_hreflang_Getter";

  static hreflang_Setter_DOMString(mthis, value) native "HTMLLinkElement_hreflang_Setter";

  static import_Getter(mthis) native "HTMLLinkElement_import_Getter";

  static integrity_Getter(mthis) native "HTMLLinkElement_integrity_Getter";

  static integrity_Setter_DOMString(mthis, value) native "HTMLLinkElement_integrity_Setter";

  static media_Getter(mthis) native "HTMLLinkElement_media_Getter";

  static media_Setter_DOMString(mthis, value) native "HTMLLinkElement_media_Setter";

  static rel_Getter(mthis) native "HTMLLinkElement_rel_Getter";

  static rel_Setter_DOMString(mthis, value) native "HTMLLinkElement_rel_Setter";

  static sheet_Getter(mthis) native "HTMLLinkElement_sheet_Getter";

  static sizes_Getter(mthis) native "HTMLLinkElement_sizes_Getter";

  static type_Getter(mthis) native "HTMLLinkElement_type_Getter";

  static type_Setter_DOMString(mthis, value) native "HTMLLinkElement_type_Setter";
}

class BlinkHTMLMapElement {
  static areas_Getter(mthis) native "HTMLMapElement_areas_Getter";

  static name_Getter(mthis) native "HTMLMapElement_name_Getter";

  static name_Setter_DOMString(mthis, value) native "HTMLMapElement_name_Setter";
}

class BlinkHTMLMarqueeElement {}

class BlinkHTMLMenuElement {}

class BlinkHTMLMetaElement {
  static content_Getter(mthis) native "HTMLMetaElement_content_Getter";

  static content_Setter_DOMString(mthis, value) native "HTMLMetaElement_content_Setter";

  static httpEquiv_Getter(mthis) native "HTMLMetaElement_httpEquiv_Getter";

  static httpEquiv_Setter_DOMString(mthis, value) native "HTMLMetaElement_httpEquiv_Setter";

  static name_Getter(mthis) native "HTMLMetaElement_name_Getter";

  static name_Setter_DOMString(mthis, value) native "HTMLMetaElement_name_Setter";
}

class BlinkHTMLMeterElement {
  static high_Getter(mthis) native "HTMLMeterElement_high_Getter";

  static high_Setter_double(mthis, value) native "HTMLMeterElement_high_Setter";

  static labels_Getter(mthis) native "HTMLMeterElement_labels_Getter";

  static low_Getter(mthis) native "HTMLMeterElement_low_Getter";

  static low_Setter_double(mthis, value) native "HTMLMeterElement_low_Setter";

  static max_Getter(mthis) native "HTMLMeterElement_max_Getter";

  static max_Setter_double(mthis, value) native "HTMLMeterElement_max_Setter";

  static min_Getter(mthis) native "HTMLMeterElement_min_Getter";

  static min_Setter_double(mthis, value) native "HTMLMeterElement_min_Setter";

  static optimum_Getter(mthis) native "HTMLMeterElement_optimum_Getter";

  static optimum_Setter_double(mthis, value) native "HTMLMeterElement_optimum_Setter";

  static value_Getter(mthis) native "HTMLMeterElement_value_Getter";

  static value_Setter_double(mthis, value) native "HTMLMeterElement_value_Setter";
}

class BlinkHTMLModElement {
  static cite_Getter(mthis) native "HTMLModElement_cite_Getter";

  static cite_Setter_DOMString(mthis, value) native "HTMLModElement_cite_Setter";

  static dateTime_Getter(mthis) native "HTMLModElement_dateTime_Getter";

  static dateTime_Setter_DOMString(mthis, value) native "HTMLModElement_dateTime_Setter";
}

class BlinkHTMLOListElement {
  static reversed_Getter(mthis) native "HTMLOListElement_reversed_Getter";

  static reversed_Setter_boolean(mthis, value) native "HTMLOListElement_reversed_Setter";

  static start_Getter(mthis) native "HTMLOListElement_start_Getter";

  static start_Setter_long(mthis, value) native "HTMLOListElement_start_Setter";

  static type_Getter(mthis) native "HTMLOListElement_type_Getter";

  static type_Setter_DOMString(mthis, value) native "HTMLOListElement_type_Setter";
}

class BlinkHTMLObjectElement {
  static data_Getter(mthis) native "HTMLObjectElement_data_Getter";

  static data_Setter_DOMString(mthis, value) native "HTMLObjectElement_data_Setter";

  static form_Getter(mthis) native "HTMLObjectElement_form_Getter";

  static height_Getter(mthis) native "HTMLObjectElement_height_Getter";

  static height_Setter_DOMString(mthis, value) native "HTMLObjectElement_height_Setter";

  static integrity_Getter(mthis) native "HTMLObjectElement_integrity_Getter";

  static integrity_Setter_DOMString(mthis, value) native "HTMLObjectElement_integrity_Setter";

  static name_Getter(mthis) native "HTMLObjectElement_name_Getter";

  static name_Setter_DOMString(mthis, value) native "HTMLObjectElement_name_Setter";

  static type_Getter(mthis) native "HTMLObjectElement_type_Getter";

  static type_Setter_DOMString(mthis, value) native "HTMLObjectElement_type_Setter";

  static useMap_Getter(mthis) native "HTMLObjectElement_useMap_Getter";

  static useMap_Setter_DOMString(mthis, value) native "HTMLObjectElement_useMap_Setter";

  static validationMessage_Getter(mthis) native "HTMLObjectElement_validationMessage_Getter";

  static validity_Getter(mthis) native "HTMLObjectElement_validity_Getter";

  static width_Getter(mthis) native "HTMLObjectElement_width_Getter";

  static width_Setter_DOMString(mthis, value) native "HTMLObjectElement_width_Setter";

  static willValidate_Getter(mthis) native "HTMLObjectElement_willValidate_Getter";

  static $__getter___Callback_ul(mthis, index_OR_name) native "HTMLObjectElement___getter___Callback";

  static $__setter___Callback_ul_Node(mthis, index_OR_name, value) native "HTMLObjectElement___setter___Callback";

  static checkValidity_Callback(mthis) native "HTMLObjectElement_checkValidity_Callback";

  static setCustomValidity_Callback_DOMString(mthis, error) native "HTMLObjectElement_setCustomValidity_Callback_DOMString";
}

class BlinkHTMLOptGroupElement {
  static disabled_Getter(mthis) native "HTMLOptGroupElement_disabled_Getter";

  static disabled_Setter_boolean(mthis, value) native "HTMLOptGroupElement_disabled_Setter";

  static label_Getter(mthis) native "HTMLOptGroupElement_label_Getter";

  static label_Setter_DOMString(mthis, value) native "HTMLOptGroupElement_label_Setter";
}

class BlinkHTMLOptionElement {
  static constructorCallback_DOMString_DOMString_boolean_boolean(data, value, defaultSelected, selected) native "HTMLOptionElement_constructorCallback_DOMString_DOMString_boolean_boolean";

  static defaultSelected_Getter(mthis) native "HTMLOptionElement_defaultSelected_Getter";

  static defaultSelected_Setter_boolean(mthis, value) native "HTMLOptionElement_defaultSelected_Setter";

  static disabled_Getter(mthis) native "HTMLOptionElement_disabled_Getter";

  static disabled_Setter_boolean(mthis, value) native "HTMLOptionElement_disabled_Setter";

  static form_Getter(mthis) native "HTMLOptionElement_form_Getter";

  static index_Getter(mthis) native "HTMLOptionElement_index_Getter";

  static label_Getter(mthis) native "HTMLOptionElement_label_Getter";

  static label_Setter_DOMString(mthis, value) native "HTMLOptionElement_label_Setter";

  static selected_Getter(mthis) native "HTMLOptionElement_selected_Getter";

  static selected_Setter_boolean(mthis, value) native "HTMLOptionElement_selected_Setter";

  static value_Getter(mthis) native "HTMLOptionElement_value_Getter";

  static value_Setter_DOMString(mthis, value) native "HTMLOptionElement_value_Setter";
}

class BlinkHTMLOptionsCollection {}

class BlinkHTMLOutputElement {
  static defaultValue_Getter(mthis) native "HTMLOutputElement_defaultValue_Getter";

  static defaultValue_Setter_DOMString(mthis, value) native "HTMLOutputElement_defaultValue_Setter";

  static form_Getter(mthis) native "HTMLOutputElement_form_Getter";

  static htmlFor_Getter(mthis) native "HTMLOutputElement_htmlFor_Getter";

  static labels_Getter(mthis) native "HTMLOutputElement_labels_Getter";

  static name_Getter(mthis) native "HTMLOutputElement_name_Getter";

  static name_Setter_DOMString(mthis, value) native "HTMLOutputElement_name_Setter";

  static type_Getter(mthis) native "HTMLOutputElement_type_Getter";

  static validationMessage_Getter(mthis) native "HTMLOutputElement_validationMessage_Getter";

  static validity_Getter(mthis) native "HTMLOutputElement_validity_Getter";

  static value_Getter(mthis) native "HTMLOutputElement_value_Getter";

  static value_Setter_DOMString(mthis, value) native "HTMLOutputElement_value_Setter";

  static willValidate_Getter(mthis) native "HTMLOutputElement_willValidate_Getter";

  static checkValidity_Callback(mthis) native "HTMLOutputElement_checkValidity_Callback";

  static setCustomValidity_Callback_DOMString(mthis, error) native "HTMLOutputElement_setCustomValidity_Callback_DOMString";
}

class BlinkHTMLParagraphElement {}

class BlinkHTMLParamElement {
  static name_Getter(mthis) native "HTMLParamElement_name_Getter";

  static name_Setter_DOMString(mthis, value) native "HTMLParamElement_name_Setter";

  static value_Getter(mthis) native "HTMLParamElement_value_Getter";

  static value_Setter_DOMString(mthis, value) native "HTMLParamElement_value_Setter";
}

class BlinkHTMLPictureElement {}

class BlinkHTMLPreElement {}

class BlinkHTMLProgressElement {
  static labels_Getter(mthis) native "HTMLProgressElement_labels_Getter";

  static max_Getter(mthis) native "HTMLProgressElement_max_Getter";

  static max_Setter_double(mthis, value) native "HTMLProgressElement_max_Setter";

  static position_Getter(mthis) native "HTMLProgressElement_position_Getter";

  static value_Getter(mthis) native "HTMLProgressElement_value_Getter";

  static value_Setter_double(mthis, value) native "HTMLProgressElement_value_Setter";
}

class BlinkHTMLQuoteElement {
  static cite_Getter(mthis) native "HTMLQuoteElement_cite_Getter";

  static cite_Setter_DOMString(mthis, value) native "HTMLQuoteElement_cite_Setter";
}

class BlinkHTMLScriptElement {
  static async_Getter(mthis) native "HTMLScriptElement_async_Getter";

  static async_Setter_boolean(mthis, value) native "HTMLScriptElement_async_Setter";

  static charset_Getter(mthis) native "HTMLScriptElement_charset_Getter";

  static charset_Setter_DOMString(mthis, value) native "HTMLScriptElement_charset_Setter";

  static crossOrigin_Getter(mthis) native "HTMLScriptElement_crossOrigin_Getter";

  static crossOrigin_Setter_DOMString(mthis, value) native "HTMLScriptElement_crossOrigin_Setter";

  static defer_Getter(mthis) native "HTMLScriptElement_defer_Getter";

  static defer_Setter_boolean(mthis, value) native "HTMLScriptElement_defer_Setter";

  static integrity_Getter(mthis) native "HTMLScriptElement_integrity_Getter";

  static integrity_Setter_DOMString(mthis, value) native "HTMLScriptElement_integrity_Setter";

  static nonce_Getter(mthis) native "HTMLScriptElement_nonce_Getter";

  static nonce_Setter_DOMString(mthis, value) native "HTMLScriptElement_nonce_Setter";

  static src_Getter(mthis) native "HTMLScriptElement_src_Getter";

  static src_Setter_DOMString(mthis, value) native "HTMLScriptElement_src_Setter";

  static type_Getter(mthis) native "HTMLScriptElement_type_Getter";

  static type_Setter_DOMString(mthis, value) native "HTMLScriptElement_type_Setter";
}

class BlinkHTMLSelectElement {
  static autofocus_Getter(mthis) native "HTMLSelectElement_autofocus_Getter";

  static autofocus_Setter_boolean(mthis, value) native "HTMLSelectElement_autofocus_Setter";

  static disabled_Getter(mthis) native "HTMLSelectElement_disabled_Getter";

  static disabled_Setter_boolean(mthis, value) native "HTMLSelectElement_disabled_Setter";

  static form_Getter(mthis) native "HTMLSelectElement_form_Getter";

  static labels_Getter(mthis) native "HTMLSelectElement_labels_Getter";

  static length_Getter(mthis) native "HTMLSelectElement_length_Getter";

  static length_Setter_ul(mthis, value) native "HTMLSelectElement_length_Setter";

  static multiple_Getter(mthis) native "HTMLSelectElement_multiple_Getter";

  static multiple_Setter_boolean(mthis, value) native "HTMLSelectElement_multiple_Setter";

  static name_Getter(mthis) native "HTMLSelectElement_name_Getter";

  static name_Setter_DOMString(mthis, value) native "HTMLSelectElement_name_Setter";

  static required_Getter(mthis) native "HTMLSelectElement_required_Getter";

  static required_Setter_boolean(mthis, value) native "HTMLSelectElement_required_Setter";

  static selectedIndex_Getter(mthis) native "HTMLSelectElement_selectedIndex_Getter";

  static selectedIndex_Setter_long(mthis, value) native "HTMLSelectElement_selectedIndex_Setter";

  static size_Getter(mthis) native "HTMLSelectElement_size_Getter";

  static size_Setter_long(mthis, value) native "HTMLSelectElement_size_Setter";

  static type_Getter(mthis) native "HTMLSelectElement_type_Getter";

  static validationMessage_Getter(mthis) native "HTMLSelectElement_validationMessage_Getter";

  static validity_Getter(mthis) native "HTMLSelectElement_validity_Getter";

  static value_Getter(mthis) native "HTMLSelectElement_value_Getter";

  static value_Setter_DOMString(mthis, value) native "HTMLSelectElement_value_Setter";

  static willValidate_Getter(mthis) native "HTMLSelectElement_willValidate_Getter";

  static $__setter___Callback_ul_HTMLOptionElement(mthis, index, value) native "HTMLSelectElement___setter___Callback_unsigned long_HTMLOptionElement";

  static add_Callback_HTMLElement_long(mthis, element, before) native "HTMLSelectElement_add_Callback_HTMLElement_long";

  static checkValidity_Callback(mthis) native "HTMLSelectElement_checkValidity_Callback";

  static item_Callback_ul(mthis, index) native "HTMLSelectElement_item_Callback_unsigned long";

  static namedItem_Callback_DOMString(mthis, name) native "HTMLSelectElement_namedItem_Callback_DOMString";

  static setCustomValidity_Callback_DOMString(mthis, error) native "HTMLSelectElement_setCustomValidity_Callback_DOMString";
}

class BlinkHTMLShadowElement {
  static getDistributedNodes_Callback(mthis) native "HTMLShadowElement_getDistributedNodes_Callback";
}

class BlinkHTMLSourceElement {
  static integrity_Getter(mthis) native "HTMLSourceElement_integrity_Getter";

  static integrity_Setter_DOMString(mthis, value) native "HTMLSourceElement_integrity_Setter";

  static media_Getter(mthis) native "HTMLSourceElement_media_Getter";

  static media_Setter_DOMString(mthis, value) native "HTMLSourceElement_media_Setter";

  static sizes_Getter(mthis) native "HTMLSourceElement_sizes_Getter";

  static sizes_Setter_DOMString(mthis, value) native "HTMLSourceElement_sizes_Setter";

  static src_Getter(mthis) native "HTMLSourceElement_src_Getter";

  static src_Setter_DOMString(mthis, value) native "HTMLSourceElement_src_Setter";

  static srcset_Getter(mthis) native "HTMLSourceElement_srcset_Getter";

  static srcset_Setter_DOMString(mthis, value) native "HTMLSourceElement_srcset_Setter";

  static type_Getter(mthis) native "HTMLSourceElement_type_Getter";

  static type_Setter_DOMString(mthis, value) native "HTMLSourceElement_type_Setter";
}

class BlinkHTMLSpanElement {}

class BlinkHTMLStyleElement {
  static disabled_Getter(mthis) native "HTMLStyleElement_disabled_Getter";

  static disabled_Setter_boolean(mthis, value) native "HTMLStyleElement_disabled_Setter";

  static media_Getter(mthis) native "HTMLStyleElement_media_Getter";

  static media_Setter_DOMString(mthis, value) native "HTMLStyleElement_media_Setter";

  static sheet_Getter(mthis) native "HTMLStyleElement_sheet_Getter";

  static type_Getter(mthis) native "HTMLStyleElement_type_Getter";

  static type_Setter_DOMString(mthis, value) native "HTMLStyleElement_type_Setter";
}

class BlinkHTMLTableCaptionElement {}

class BlinkHTMLTableCellElement {
  static cellIndex_Getter(mthis) native "HTMLTableCellElement_cellIndex_Getter";

  static colSpan_Getter(mthis) native "HTMLTableCellElement_colSpan_Getter";

  static colSpan_Setter_long(mthis, value) native "HTMLTableCellElement_colSpan_Setter";

  static headers_Getter(mthis) native "HTMLTableCellElement_headers_Getter";

  static headers_Setter_DOMString(mthis, value) native "HTMLTableCellElement_headers_Setter";

  static rowSpan_Getter(mthis) native "HTMLTableCellElement_rowSpan_Getter";

  static rowSpan_Setter_long(mthis, value) native "HTMLTableCellElement_rowSpan_Setter";
}

class BlinkHTMLTableColElement {
  static span_Getter(mthis) native "HTMLTableColElement_span_Getter";

  static span_Setter_long(mthis, value) native "HTMLTableColElement_span_Setter";
}

class BlinkHTMLTableElement {
  static caption_Getter(mthis) native "HTMLTableElement_caption_Getter";

  static caption_Setter_HTMLTableCaptionElement(mthis, value) native "HTMLTableElement_caption_Setter";

  static rows_Getter(mthis) native "HTMLTableElement_rows_Getter";

  static tBodies_Getter(mthis) native "HTMLTableElement_tBodies_Getter";

  static tFoot_Getter(mthis) native "HTMLTableElement_tFoot_Getter";

  static tFoot_Setter_HTMLTableSectionElement(mthis, value) native "HTMLTableElement_tFoot_Setter";

  static tHead_Getter(mthis) native "HTMLTableElement_tHead_Getter";

  static tHead_Setter_HTMLTableSectionElement(mthis, value) native "HTMLTableElement_tHead_Setter";

  static createCaption_Callback(mthis) native "HTMLTableElement_createCaption_Callback";

  static createTBody_Callback(mthis) native "HTMLTableElement_createTBody_Callback";

  static createTFoot_Callback(mthis) native "HTMLTableElement_createTFoot_Callback";

  static createTHead_Callback(mthis) native "HTMLTableElement_createTHead_Callback";

  static deleteCaption_Callback(mthis) native "HTMLTableElement_deleteCaption_Callback";

  static deleteRow_Callback_long(mthis, index) native "HTMLTableElement_deleteRow_Callback_long";

  static deleteTFoot_Callback(mthis) native "HTMLTableElement_deleteTFoot_Callback";

  static deleteTHead_Callback(mthis) native "HTMLTableElement_deleteTHead_Callback";

  static insertRow_Callback_long(mthis, index) native "HTMLTableElement_insertRow_Callback_long";

  static insertRow_Callback(mthis) native "HTMLTableElement_insertRow_Callback";
}

class BlinkHTMLTableRowElement {
  static cells_Getter(mthis) native "HTMLTableRowElement_cells_Getter";

  static rowIndex_Getter(mthis) native "HTMLTableRowElement_rowIndex_Getter";

  static sectionRowIndex_Getter(mthis) native "HTMLTableRowElement_sectionRowIndex_Getter";

  static deleteCell_Callback_long(mthis, index) native "HTMLTableRowElement_deleteCell_Callback_long";

  static insertCell_Callback_long(mthis, index) native "HTMLTableRowElement_insertCell_Callback_long";

  static insertCell_Callback(mthis) native "HTMLTableRowElement_insertCell_Callback";
}

class BlinkHTMLTableSectionElement {
  static rows_Getter(mthis) native "HTMLTableSectionElement_rows_Getter";

  static deleteRow_Callback_long(mthis, index) native "HTMLTableSectionElement_deleteRow_Callback_long";

  static insertRow_Callback_long(mthis, index) native "HTMLTableSectionElement_insertRow_Callback_long";

  static insertRow_Callback(mthis) native "HTMLTableSectionElement_insertRow_Callback";
}

class BlinkHTMLTemplateElement {
  static content_Getter(mthis) native "HTMLTemplateElement_content_Getter";
}

class BlinkHTMLTextAreaElement {
  static autofocus_Getter(mthis) native "HTMLTextAreaElement_autofocus_Getter";

  static autofocus_Setter_boolean(mthis, value) native "HTMLTextAreaElement_autofocus_Setter";

  static cols_Getter(mthis) native "HTMLTextAreaElement_cols_Getter";

  static cols_Setter_long(mthis, value) native "HTMLTextAreaElement_cols_Setter";

  static defaultValue_Getter(mthis) native "HTMLTextAreaElement_defaultValue_Getter";

  static defaultValue_Setter_DOMString(mthis, value) native "HTMLTextAreaElement_defaultValue_Setter";

  static dirName_Getter(mthis) native "HTMLTextAreaElement_dirName_Getter";

  static dirName_Setter_DOMString(mthis, value) native "HTMLTextAreaElement_dirName_Setter";

  static disabled_Getter(mthis) native "HTMLTextAreaElement_disabled_Getter";

  static disabled_Setter_boolean(mthis, value) native "HTMLTextAreaElement_disabled_Setter";

  static form_Getter(mthis) native "HTMLTextAreaElement_form_Getter";

  static inputMode_Getter(mthis) native "HTMLTextAreaElement_inputMode_Getter";

  static inputMode_Setter_DOMString(mthis, value) native "HTMLTextAreaElement_inputMode_Setter";

  static labels_Getter(mthis) native "HTMLTextAreaElement_labels_Getter";

  static maxLength_Getter(mthis) native "HTMLTextAreaElement_maxLength_Getter";

  static maxLength_Setter_long(mthis, value) native "HTMLTextAreaElement_maxLength_Setter";

  static name_Getter(mthis) native "HTMLTextAreaElement_name_Getter";

  static name_Setter_DOMString(mthis, value) native "HTMLTextAreaElement_name_Setter";

  static placeholder_Getter(mthis) native "HTMLTextAreaElement_placeholder_Getter";

  static placeholder_Setter_DOMString(mthis, value) native "HTMLTextAreaElement_placeholder_Setter";

  static readOnly_Getter(mthis) native "HTMLTextAreaElement_readOnly_Getter";

  static readOnly_Setter_boolean(mthis, value) native "HTMLTextAreaElement_readOnly_Setter";

  static required_Getter(mthis) native "HTMLTextAreaElement_required_Getter";

  static required_Setter_boolean(mthis, value) native "HTMLTextAreaElement_required_Setter";

  static rows_Getter(mthis) native "HTMLTextAreaElement_rows_Getter";

  static rows_Setter_long(mthis, value) native "HTMLTextAreaElement_rows_Setter";

  static selectionDirection_Getter(mthis) native "HTMLTextAreaElement_selectionDirection_Getter";

  static selectionDirection_Setter_DOMString(mthis, value) native "HTMLTextAreaElement_selectionDirection_Setter";

  static selectionEnd_Getter(mthis) native "HTMLTextAreaElement_selectionEnd_Getter";

  static selectionEnd_Setter_long(mthis, value) native "HTMLTextAreaElement_selectionEnd_Setter";

  static selectionStart_Getter(mthis) native "HTMLTextAreaElement_selectionStart_Getter";

  static selectionStart_Setter_long(mthis, value) native "HTMLTextAreaElement_selectionStart_Setter";

  static textLength_Getter(mthis) native "HTMLTextAreaElement_textLength_Getter";

  static type_Getter(mthis) native "HTMLTextAreaElement_type_Getter";

  static validationMessage_Getter(mthis) native "HTMLTextAreaElement_validationMessage_Getter";

  static validity_Getter(mthis) native "HTMLTextAreaElement_validity_Getter";

  static value_Getter(mthis) native "HTMLTextAreaElement_value_Getter";

  static value_Setter_DOMString(mthis, value) native "HTMLTextAreaElement_value_Setter";

  static willValidate_Getter(mthis) native "HTMLTextAreaElement_willValidate_Getter";

  static wrap_Getter(mthis) native "HTMLTextAreaElement_wrap_Getter";

  static wrap_Setter_DOMString(mthis, value) native "HTMLTextAreaElement_wrap_Setter";

  static checkValidity_Callback(mthis) native "HTMLTextAreaElement_checkValidity_Callback";

  static select_Callback(mthis) native "HTMLTextAreaElement_select_Callback";

  static setCustomValidity_Callback_DOMString(mthis, error) native "HTMLTextAreaElement_setCustomValidity_Callback_DOMString";

  static setRangeText_Callback_DOMString(mthis, replacement) native "HTMLTextAreaElement_setRangeText_Callback_DOMString";

  static setRangeText_Callback_DOMString_ul_ul_DOMString(mthis, replacement, start, end, selectionMode) native "HTMLTextAreaElement_setRangeText_Callback_DOMString_unsigned long_unsigned long_DOMString";

  static setSelectionRange_Callback_long_long_DOMString(mthis, start, end, direction) native "HTMLTextAreaElement_setSelectionRange_Callback_long_long_DOMString";

  static setSelectionRange_Callback_long_long(mthis, start, end) native "HTMLTextAreaElement_setSelectionRange_Callback_long_long";
}

class BlinkHTMLTitleElement {}

class BlinkHTMLTrackElement {
  static default_Getter(mthis) native "HTMLTrackElement_default_Getter";

  static default_Setter_boolean(mthis, value) native "HTMLTrackElement_default_Setter";

  static integrity_Getter(mthis) native "HTMLTrackElement_integrity_Getter";

  static integrity_Setter_DOMString(mthis, value) native "HTMLTrackElement_integrity_Setter";

  static kind_Getter(mthis) native "HTMLTrackElement_kind_Getter";

  static kind_Setter_DOMString(mthis, value) native "HTMLTrackElement_kind_Setter";

  static label_Getter(mthis) native "HTMLTrackElement_label_Getter";

  static label_Setter_DOMString(mthis, value) native "HTMLTrackElement_label_Setter";

  static readyState_Getter(mthis) native "HTMLTrackElement_readyState_Getter";

  static src_Getter(mthis) native "HTMLTrackElement_src_Getter";

  static src_Setter_DOMString(mthis, value) native "HTMLTrackElement_src_Setter";

  static srclang_Getter(mthis) native "HTMLTrackElement_srclang_Getter";

  static srclang_Setter_DOMString(mthis, value) native "HTMLTrackElement_srclang_Setter";

  static track_Getter(mthis) native "HTMLTrackElement_track_Getter";
}

class BlinkHTMLUListElement {}

class BlinkHTMLUnknownElement {}

class BlinkHTMLVideoElement {
  static height_Getter(mthis) native "HTMLVideoElement_height_Getter";

  static height_Setter_ul(mthis, value) native "HTMLVideoElement_height_Setter";

  static poster_Getter(mthis) native "HTMLVideoElement_poster_Getter";

  static poster_Setter_DOMString(mthis, value) native "HTMLVideoElement_poster_Setter";

  static videoHeight_Getter(mthis) native "HTMLVideoElement_videoHeight_Getter";

  static videoWidth_Getter(mthis) native "HTMLVideoElement_videoWidth_Getter";

  static webkitDecodedFrameCount_Getter(mthis) native "HTMLVideoElement_webkitDecodedFrameCount_Getter";

  static webkitDroppedFrameCount_Getter(mthis) native "HTMLVideoElement_webkitDroppedFrameCount_Getter";

  static width_Getter(mthis) native "HTMLVideoElement_width_Getter";

  static width_Setter_ul(mthis, value) native "HTMLVideoElement_width_Setter";

  static getVideoPlaybackQuality_Callback(mthis) native "HTMLVideoElement_getVideoPlaybackQuality_Callback";

  static webkitEnterFullscreen_Callback(mthis) native "HTMLVideoElement_webkitEnterFullscreen_Callback";

  static webkitExitFullscreen_Callback(mthis) native "HTMLVideoElement_webkitExitFullscreen_Callback";
}

class BlinkHashChangeEvent {
  static newURL_Getter(mthis) native "HashChangeEvent_newURL_Getter";

  static oldURL_Getter(mthis) native "HashChangeEvent_oldURL_Getter";

  static initHashChangeEvent_Callback_DOMString_boolean_boolean_DOMString_DOMString(mthis, type, canBubble, cancelable, oldURL, newURL) native "HashChangeEvent_initHashChangeEvent_Callback_DOMString_boolean_boolean_DOMString_DOMString";
}

class BlinkHeaderMap {
  static constructorCallback() native "HeaderMap_constructorCallback";

  static size_Getter(mthis) native "HeaderMap_size_Getter";

  static clear_Callback(mthis) native "HeaderMap_clear_Callback";

  static delete_Callback_DOMString(mthis, key) native "HeaderMap_delete_Callback_DOMString";

  static forEach_Callback_HeaderMapForEachCallback_ScriptValue(mthis, callback, thisArg) native "HeaderMap_forEach_Callback_HeaderMapForEachCallback_ScriptValue";

  static forEach_Callback_HeaderMapForEachCallback(mthis, callback) native "HeaderMap_forEach_Callback_HeaderMapForEachCallback";

  static get_Callback_DOMString(mthis, key) native "HeaderMap_get_Callback_DOMString";

  static has_Callback_DOMString(mthis, key) native "HeaderMap_has_Callback_DOMString";

  static set_Callback_DOMString_DOMString(mthis, key, value) native "HeaderMap_set_Callback_DOMString_DOMString";
}

class BlinkHistory {
  static length_Getter(mthis) native "History_length_Getter";

  static state_Getter(mthis) native "History_state_Getter";

  static back_Callback(mthis) native "History_back_Callback";

  static forward_Callback(mthis) native "History_forward_Callback";

  static go_Callback_long(mthis, distance) native "History_go_Callback_long";

  static pushState_Callback_ScriptValue_DOMString_DOMString(mthis, data, title, url) native "History_pushState_Callback";

  static replaceState_Callback_ScriptValue_DOMString_DOMString(mthis, data, title, url) native "History_replaceState_Callback";
}

class BlinkHmacKeyAlgorithm {
  static hash_Getter(mthis) native "HmacKeyAlgorithm_hash_Getter";

  static length_Getter(mthis) native "HmacKeyAlgorithm_length_Getter";
}

class BlinkIDBCursor {
  static direction_Getter(mthis) native "IDBCursor_direction_Getter";

  static key_Getter(mthis) native "IDBCursor_key_Getter";

  static primaryKey_Getter(mthis) native "IDBCursor_primaryKey_Getter";

  static source_Getter(mthis) native "IDBCursor_source_Getter";

  static advance_Callback_ul(mthis, count) native "IDBCursor_advance_Callback_unsigned long";

  static continuePrimaryKey_Callback_ScriptValue_ScriptValue(mthis, key, primaryKey) native "IDBCursor_continuePrimaryKey_Callback_ScriptValue_ScriptValue";

  static delete_Callback(mthis) native "IDBCursor_delete_Callback";

  static continue_Callback_ScriptValue(mthis, key) native "IDBCursor_continue_Callback_ScriptValue";

  static update_Callback_ScriptValue(mthis, value) native "IDBCursor_update_Callback_ScriptValue";
}

class BlinkIDBCursorWithValue {
  static value_Getter(mthis) native "IDBCursorWithValue_value_Getter";
}

class BlinkIDBDatabase {
  static name_Getter(mthis) native "IDBDatabase_name_Getter";

  static objectStoreNames_Getter(mthis) native "IDBDatabase_objectStoreNames_Getter";

  static version_Getter(mthis) native "IDBDatabase_version_Getter";

  static close_Callback(mthis) native "IDBDatabase_close_Callback";

  static createObjectStore_Callback_DOMString_Dictionary(mthis, name, options) native "IDBDatabase_createObjectStore_Callback_DOMString_Dictionary";

  static deleteObjectStore_Callback_DOMString(mthis, name) native "IDBDatabase_deleteObjectStore_Callback_DOMString";

  static transaction_Callback_DOMString_DOMString(mthis, storeName_OR_storeNames, mode) native "IDBDatabase_transaction_Callback_DOMString_DOMString";

  static transaction_Callback_SEQ_DOMString_SEQ_DOMString(mthis, storeName_OR_storeNames, mode) native "IDBDatabase_transaction_Callback_sequence<DOMString>_DOMString";

  static transaction_Callback_DOMStringList_DOMString(mthis, storeName_OR_storeNames, mode) native "IDBDatabase_transaction_Callback_DOMStringList_DOMString";
}

class BlinkIDBFactory {
  static cmp_Callback_ScriptValue_ScriptValue(mthis, first, second) native "IDBFactory_cmp_Callback_ScriptValue_ScriptValue";

  static deleteDatabase_Callback_DOMString(mthis, name) native "IDBFactory_deleteDatabase_Callback_DOMString";

  static open_Callback_DOMString_ull(mthis, name, version) native "IDBFactory_open_Callback_DOMString_unsigned long long";

  static open_Callback_DOMString(mthis, name) native "IDBFactory_open_Callback_DOMString";

  static webkitGetDatabaseNames_Callback(mthis) native "IDBFactory_webkitGetDatabaseNames_Callback";
}

class BlinkIDBIndex {
  static keyPath_Getter(mthis) native "IDBIndex_keyPath_Getter";

  static multiEntry_Getter(mthis) native "IDBIndex_multiEntry_Getter";

  static name_Getter(mthis) native "IDBIndex_name_Getter";

  static objectStore_Getter(mthis) native "IDBIndex_objectStore_Getter";

  static unique_Getter(mthis) native "IDBIndex_unique_Getter";

  static count_Callback_ScriptValue(mthis, key) native "IDBIndex_count_Callback_ScriptValue";

  static get_Callback_ScriptValue(mthis, key) native "IDBIndex_get_Callback_ScriptValue";

  static getKey_Callback_ScriptValue(mthis, key) native "IDBIndex_getKey_Callback_ScriptValue";

  static openCursor_Callback_ScriptValue_DOMString(mthis, key, direction) native "IDBIndex_openCursor_Callback_ScriptValue_DOMString";

  static openKeyCursor_Callback_ScriptValue_DOMString(mthis, key, direction) native "IDBIndex_openKeyCursor_Callback_ScriptValue_DOMString";
}

class BlinkIDBKeyRange {
  static lower_Getter(mthis) native "IDBKeyRange_lower_Getter";

  static lowerOpen_Getter(mthis) native "IDBKeyRange_lowerOpen_Getter";

  static upper_Getter(mthis) native "IDBKeyRange_upper_Getter";

  static upperOpen_Getter(mthis) native "IDBKeyRange_upperOpen_Getter";

  static bound_Callback_ScriptValue_ScriptValue_boolean_boolean(lower, upper, lowerOpen, upperOpen) native "IDBKeyRange_bound_Callback_ScriptValue_ScriptValue_boolean_boolean";

  static lowerBound_Callback_ScriptValue_boolean(bound, open) native "IDBKeyRange_lowerBound_Callback_ScriptValue_boolean";

  static only_Callback_ScriptValue(value) native "IDBKeyRange_only_Callback_ScriptValue";

  static upperBound_Callback_ScriptValue_boolean(bound, open) native "IDBKeyRange_upperBound_Callback_ScriptValue_boolean";
}

class BlinkIDBObjectStore {
  static autoIncrement_Getter(mthis) native "IDBObjectStore_autoIncrement_Getter";

  static indexNames_Getter(mthis) native "IDBObjectStore_indexNames_Getter";

  static keyPath_Getter(mthis) native "IDBObjectStore_keyPath_Getter";

  static name_Getter(mthis) native "IDBObjectStore_name_Getter";

  static transaction_Getter(mthis) native "IDBObjectStore_transaction_Getter";

  static add_Callback_ScriptValue_ScriptValue(mthis, value, key) native "IDBObjectStore_add_Callback_ScriptValue_ScriptValue";

  static clear_Callback(mthis) native "IDBObjectStore_clear_Callback";

  static count_Callback_ScriptValue(mthis, key) native "IDBObjectStore_count_Callback_ScriptValue";

  static createIndex_Callback_DOMString_DOMString_Dictionary(mthis, name, keyPath, options) native "IDBObjectStore_createIndex_Callback_DOMString_DOMString_Dictionary";

  static createIndex_Callback_DOMString_SEQ_DOMString_SEQ_Dictionary(mthis, name, keyPath, options) native "IDBObjectStore_createIndex_Callback_DOMString_sequence<DOMString>_Dictionary";

  static delete_Callback_ScriptValue(mthis, key) native "IDBObjectStore_delete_Callback_ScriptValue";

  static deleteIndex_Callback_DOMString(mthis, name) native "IDBObjectStore_deleteIndex_Callback_DOMString";

  static get_Callback_ScriptValue(mthis, key) native "IDBObjectStore_get_Callback_ScriptValue";

  static index_Callback_DOMString(mthis, name) native "IDBObjectStore_index_Callback_DOMString";

  static openCursor_Callback_ScriptValue_DOMString(mthis, range, direction) native "IDBObjectStore_openCursor_Callback_ScriptValue_DOMString";

  static openKeyCursor_Callback_ScriptValue_DOMString(mthis, range, direction) native "IDBObjectStore_openKeyCursor_Callback_ScriptValue_DOMString";

  static put_Callback_ScriptValue_ScriptValue(mthis, value, key) native "IDBObjectStore_put_Callback_ScriptValue_ScriptValue";
}

class BlinkIDBRequest {
  static error_Getter(mthis) native "IDBRequest_error_Getter";

  static readyState_Getter(mthis) native "IDBRequest_readyState_Getter";

  static result_Getter(mthis) native "IDBRequest_result_Getter";

  static source_Getter(mthis) native "IDBRequest_source_Getter";

  static transaction_Getter(mthis) native "IDBRequest_transaction_Getter";
}

class BlinkIDBOpenDBRequest {}

class BlinkIDBTransaction {
  static db_Getter(mthis) native "IDBTransaction_db_Getter";

  static error_Getter(mthis) native "IDBTransaction_error_Getter";

  static mode_Getter(mthis) native "IDBTransaction_mode_Getter";

  static abort_Callback(mthis) native "IDBTransaction_abort_Callback";

  static objectStore_Callback_DOMString(mthis, name) native "IDBTransaction_objectStore_Callback_DOMString";
}

class BlinkIDBVersionChangeEvent {
  static dataLoss_Getter(mthis) native "IDBVersionChangeEvent_dataLoss_Getter";

  static dataLossMessage_Getter(mthis) native "IDBVersionChangeEvent_dataLossMessage_Getter";

  static newVersion_Getter(mthis) native "IDBVersionChangeEvent_newVersion_Getter";

  static oldVersion_Getter(mthis) native "IDBVersionChangeEvent_oldVersion_Getter";
}

class BlinkImageBitmap {
  static height_Getter(mthis) native "ImageBitmap_height_Getter";

  static width_Getter(mthis) native "ImageBitmap_width_Getter";
}

class BlinkImageData {
  static constructorCallback_ul_ul(data_OR_width, height_OR_width) native "ImageData_constructorCallback_unsigned long_unsigned long";

  static constructorCallback_Uint8ClampedArray_ul_ul(data_OR_width, height_OR_width, height) native "ImageData_constructorCallback_Uint8ClampedArray_unsigned long_unsigned long";

  static data_Getter(mthis) native "ImageData_data_Getter";

  static height_Getter(mthis) native "ImageData_height_Getter";

  static width_Getter(mthis) native "ImageData_width_Getter";
}

class BlinkInjectedScriptHost {
  static inspect_Callback_ScriptValue_ScriptValue(mthis, objectId, hints) native "InjectedScriptHost_inspect_Callback";
}

class BlinkInputMethodContext {
  static compositionEndOffset_Getter(mthis) native "InputMethodContext_compositionEndOffset_Getter";

  static compositionStartOffset_Getter(mthis) native "InputMethodContext_compositionStartOffset_Getter";

  static locale_Getter(mthis) native "InputMethodContext_locale_Getter";

  static target_Getter(mthis) native "InputMethodContext_target_Getter";

  static confirmComposition_Callback(mthis) native "InputMethodContext_confirmComposition_Callback";
}

class BlinkInstallPhaseEvent {
  static waitUntil_Callback_ScriptValue(mthis, value) native "InstallPhaseEvent_waitUntil_Callback_ScriptValue";
}

class BlinkInstallEvent {
  static replace_Callback(mthis) native "InstallEvent_replace_Callback";
}

class BlinkKey {
  static algorithm_Getter(mthis) native "Key_algorithm_Getter";

  static extractable_Getter(mthis) native "Key_extractable_Getter";

  static type_Getter(mthis) native "Key_type_Getter";

  static usages_Getter(mthis) native "Key_usages_Getter";
}

class BlinkKeyboardEvent {
  static altGraphKey_Getter(mthis) native "KeyboardEvent_altGraphKey_Getter";

  static altKey_Getter(mthis) native "KeyboardEvent_altKey_Getter";

  static ctrlKey_Getter(mthis) native "KeyboardEvent_ctrlKey_Getter";

  static keyIdentifier_Getter(mthis) native "KeyboardEvent_keyIdentifier_Getter";

  static keyLocation_Getter(mthis) native "KeyboardEvent_keyLocation_Getter";

  static location_Getter(mthis) native "KeyboardEvent_location_Getter";

  static metaKey_Getter(mthis) native "KeyboardEvent_metaKey_Getter";

  static repeat_Getter(mthis) native "KeyboardEvent_repeat_Getter";

  static shiftKey_Getter(mthis) native "KeyboardEvent_shiftKey_Getter";

  static getModifierState_Callback_DOMString(mthis, keyArgument) native "KeyboardEvent_getModifierState_Callback_DOMString";

  static initKeyboardEvent_Callback_DOMString_boolean_boolean_Window_DOMString_ul_boolean_boolean_boolean_boolean_boolean(mthis, type, canBubble, cancelable, view, keyIdentifier, location, ctrlKey, altKey, shiftKey, metaKey, altGraphKey) native "KeyboardEvent_initKeyboardEvent_Callback_DOMString_boolean_boolean_Window_DOMString_unsigned long_boolean_boolean_boolean_boolean_boolean";
}

class BlinkLocation {
  static ancestorOrigins_Getter(mthis) native "Location_ancestorOrigins_Getter";

  static hash_Getter(mthis) native "Location_hash_Getter";

  static hash_Setter_DOMString(mthis, value) native "Location_hash_Setter";

  static host_Getter(mthis) native "Location_host_Getter";

  static host_Setter_DOMString(mthis, value) native "Location_host_Setter";

  static hostname_Getter(mthis) native "Location_hostname_Getter";

  static hostname_Setter_DOMString(mthis, value) native "Location_hostname_Setter";

  static href_Getter(mthis) native "Location_href_Getter";

  static href_Setter_DOMString(mthis, value) native "Location_href_Setter";

  static origin_Getter(mthis) native "Location_origin_Getter";

  static pathname_Getter(mthis) native "Location_pathname_Getter";

  static pathname_Setter_DOMString(mthis, value) native "Location_pathname_Setter";

  static port_Getter(mthis) native "Location_port_Getter";

  static port_Setter_DOMString(mthis, value) native "Location_port_Setter";

  static protocol_Getter(mthis) native "Location_protocol_Getter";

  static protocol_Setter_DOMString(mthis, value) native "Location_protocol_Setter";

  static search_Getter(mthis) native "Location_search_Getter";

  static search_Setter_DOMString(mthis, value) native "Location_search_Setter";

  static assign_Callback_DOMString(mthis, url) native "Location_assign_Callback";

  static reload_Callback(mthis) native "Location_reload_Callback";

  static replace_Callback_DOMString(mthis, url) native "Location_replace_Callback";

  static toString_Callback(mthis) native "Location_toString_Callback";
}

class BlinkMIDIAccess {
  static sysexEnabled_Getter(mthis) native "MIDIAccess_sysexEnabled_Getter";

  static inputs_Callback(mthis) native "MIDIAccess_inputs_Callback";

  static outputs_Callback(mthis) native "MIDIAccess_outputs_Callback";
}

class BlinkMIDIConnectionEvent {
  static port_Getter(mthis) native "MIDIConnectionEvent_port_Getter";
}

class BlinkMIDIPort {
  static id_Getter(mthis) native "MIDIPort_id_Getter";

  static manufacturer_Getter(mthis) native "MIDIPort_manufacturer_Getter";

  static name_Getter(mthis) native "MIDIPort_name_Getter";

  static type_Getter(mthis) native "MIDIPort_type_Getter";

  static version_Getter(mthis) native "MIDIPort_version_Getter";
}

class BlinkMIDIInput {}

class BlinkMIDIMessageEvent {
  static data_Getter(mthis) native "MIDIMessageEvent_data_Getter";

  static receivedTime_Getter(mthis) native "MIDIMessageEvent_receivedTime_Getter";
}

class BlinkMIDIOutput {
  static send_Callback_Uint8Array_double(mthis, data, timestamp) native "MIDIOutput_send_Callback_Uint8Array_double";

  static send_Callback_Uint8Array(mthis, data) native "MIDIOutput_send_Callback_Uint8Array";
}

class BlinkMediaController {
  static constructorCallback() native "MediaController_constructorCallback";

  static buffered_Getter(mthis) native "MediaController_buffered_Getter";

  static currentTime_Getter(mthis) native "MediaController_currentTime_Getter";

  static currentTime_Setter_double(mthis, value) native "MediaController_currentTime_Setter";

  static defaultPlaybackRate_Getter(mthis) native "MediaController_defaultPlaybackRate_Getter";

  static defaultPlaybackRate_Setter_double(mthis, value) native "MediaController_defaultPlaybackRate_Setter";

  static duration_Getter(mthis) native "MediaController_duration_Getter";

  static muted_Getter(mthis) native "MediaController_muted_Getter";

  static muted_Setter_boolean(mthis, value) native "MediaController_muted_Setter";

  static paused_Getter(mthis) native "MediaController_paused_Getter";

  static playbackRate_Getter(mthis) native "MediaController_playbackRate_Getter";

  static playbackRate_Setter_double(mthis, value) native "MediaController_playbackRate_Setter";

  static playbackState_Getter(mthis) native "MediaController_playbackState_Getter";

  static played_Getter(mthis) native "MediaController_played_Getter";

  static seekable_Getter(mthis) native "MediaController_seekable_Getter";

  static volume_Getter(mthis) native "MediaController_volume_Getter";

  static volume_Setter_double(mthis, value) native "MediaController_volume_Setter";

  static pause_Callback(mthis) native "MediaController_pause_Callback";

  static play_Callback(mthis) native "MediaController_play_Callback";

  static unpause_Callback(mthis) native "MediaController_unpause_Callback";
}

class BlinkMediaDeviceInfo {
  static deviceId_Getter(mthis) native "MediaDeviceInfo_deviceId_Getter";

  static groupId_Getter(mthis) native "MediaDeviceInfo_groupId_Getter";

  static kind_Getter(mthis) native "MediaDeviceInfo_kind_Getter";

  static label_Getter(mthis) native "MediaDeviceInfo_label_Getter";
}

class BlinkMediaElementAudioSourceNode {
  static mediaElement_Getter(mthis) native "MediaElementAudioSourceNode_mediaElement_Getter";
}

class BlinkMediaError {
  static code_Getter(mthis) native "MediaError_code_Getter";
}

class BlinkMediaKeyError {
  static code_Getter(mthis) native "MediaKeyError_code_Getter";

  static systemCode_Getter(mthis) native "MediaKeyError_systemCode_Getter";
}

class BlinkMediaKeyEvent {
  static defaultURL_Getter(mthis) native "MediaKeyEvent_defaultURL_Getter";

  static errorCode_Getter(mthis) native "MediaKeyEvent_errorCode_Getter";

  static initData_Getter(mthis) native "MediaKeyEvent_initData_Getter";

  static keySystem_Getter(mthis) native "MediaKeyEvent_keySystem_Getter";

  static message_Getter(mthis) native "MediaKeyEvent_message_Getter";

  static sessionId_Getter(mthis) native "MediaKeyEvent_sessionId_Getter";

  static systemCode_Getter(mthis) native "MediaKeyEvent_systemCode_Getter";
}

class BlinkMediaKeyMessageEvent {
  static destinationURL_Getter(mthis) native "MediaKeyMessageEvent_destinationURL_Getter";

  static message_Getter(mthis) native "MediaKeyMessageEvent_message_Getter";
}

class BlinkMediaKeyNeededEvent {
  static contentType_Getter(mthis) native "MediaKeyNeededEvent_contentType_Getter";

  static initData_Getter(mthis) native "MediaKeyNeededEvent_initData_Getter";
}

class BlinkMediaKeySession {
  static error_Getter(mthis) native "MediaKeySession_error_Getter";

  static keySystem_Getter(mthis) native "MediaKeySession_keySystem_Getter";

  static sessionId_Getter(mthis) native "MediaKeySession_sessionId_Getter";

  static release_Callback(mthis) native "MediaKeySession_release_Callback";

  static update_Callback_Uint8Array(mthis, response) native "MediaKeySession_update_Callback_Uint8Array";
}

class BlinkMediaKeys {
  static constructorCallback_DOMString(keySystem) native "MediaKeys_constructorCallback_DOMString";

  static keySystem_Getter(mthis) native "MediaKeys_keySystem_Getter";

  static createSession_Callback_DOMString_Uint8Array(mthis, type, initData) native "MediaKeys_createSession_Callback_DOMString_Uint8Array";

  static isTypeSupported_Callback_DOMString_DOMString(keySystem, contentType) native "MediaKeys_isTypeSupported_Callback_DOMString_DOMString";
}

class BlinkMediaList {
  static length_Getter(mthis) native "MediaList_length_Getter";

  static mediaText_Getter(mthis) native "MediaList_mediaText_Getter";

  static mediaText_Setter_DOMString(mthis, value) native "MediaList_mediaText_Setter";

  static appendMedium_Callback_DOMString(mthis, newMedium) native "MediaList_appendMedium_Callback_DOMString";

  static deleteMedium_Callback_DOMString(mthis, oldMedium) native "MediaList_deleteMedium_Callback_DOMString";

  static item_Callback_ul(mthis, index) native "MediaList_item_Callback_unsigned long";
}

class BlinkMediaQueryList {
  static matches_Getter(mthis) native "MediaQueryList_matches_Getter";

  static media_Getter(mthis) native "MediaQueryList_media_Getter";
}

class BlinkMediaSource {
  static constructorCallback() native "MediaSource_constructorCallback";

  static activeSourceBuffers_Getter(mthis) native "MediaSource_activeSourceBuffers_Getter";

  static duration_Getter(mthis) native "MediaSource_duration_Getter";

  static duration_Setter_double(mthis, value) native "MediaSource_duration_Setter";

  static readyState_Getter(mthis) native "MediaSource_readyState_Getter";

  static sourceBuffers_Getter(mthis) native "MediaSource_sourceBuffers_Getter";

  static addSourceBuffer_Callback_DOMString(mthis, type) native "MediaSource_addSourceBuffer_Callback_DOMString";

  static endOfStream_Callback_DOMString(mthis, error) native "MediaSource_endOfStream_Callback_DOMString";

  static endOfStream_Callback(mthis) native "MediaSource_endOfStream_Callback";

  static isTypeSupported_Callback_DOMString(type) native "MediaSource_isTypeSupported_Callback_DOMString";

  static removeSourceBuffer_Callback_SourceBuffer(mthis, buffer) native "MediaSource_removeSourceBuffer_Callback_SourceBuffer";
}

class BlinkMediaStream {
  static constructorCallback() native "MediaStream_constructorCallback";

  static constructorCallback_MediaStream(stream_OR_tracks) native "MediaStream_constructorCallback_MediaStream";

  static constructorCallback_A_MediaStreamTrack_A(stream_OR_tracks) native "MediaStream_constructorCallback_MediaStreamTrack[]";

  static ended_Getter(mthis) native "MediaStream_ended_Getter";

  static id_Getter(mthis) native "MediaStream_id_Getter";

  static label_Getter(mthis) native "MediaStream_label_Getter";

  static addTrack_Callback_MediaStreamTrack(mthis, track) native "MediaStream_addTrack_Callback_MediaStreamTrack";

  static clone_Callback(mthis) native "MediaStream_clone_Callback";

  static getAudioTracks_Callback(mthis) native "MediaStream_getAudioTracks_Callback";

  static getTrackById_Callback_DOMString(mthis, trackId) native "MediaStream_getTrackById_Callback_DOMString";

  static getVideoTracks_Callback(mthis) native "MediaStream_getVideoTracks_Callback";

  static removeTrack_Callback_MediaStreamTrack(mthis, track) native "MediaStream_removeTrack_Callback_MediaStreamTrack";

  static stop_Callback(mthis) native "MediaStream_stop_Callback";
}

class BlinkMediaStreamAudioDestinationNode {
  static stream_Getter(mthis) native "MediaStreamAudioDestinationNode_stream_Getter";
}

class BlinkMediaStreamAudioSourceNode {
  static mediaStream_Getter(mthis) native "MediaStreamAudioSourceNode_mediaStream_Getter";
}

class BlinkMediaStreamEvent {
  static stream_Getter(mthis) native "MediaStreamEvent_stream_Getter";
}

class BlinkMediaStreamTrack {
  static enabled_Getter(mthis) native "MediaStreamTrack_enabled_Getter";

  static enabled_Setter_boolean(mthis, value) native "MediaStreamTrack_enabled_Setter";

  static id_Getter(mthis) native "MediaStreamTrack_id_Getter";

  static kind_Getter(mthis) native "MediaStreamTrack_kind_Getter";

  static label_Getter(mthis) native "MediaStreamTrack_label_Getter";

  static readyState_Getter(mthis) native "MediaStreamTrack_readyState_Getter";

  static clone_Callback(mthis) native "MediaStreamTrack_clone_Callback";

  static getSources_Callback_MediaStreamTrackSourcesCallback(callback) native "MediaStreamTrack_getSources_Callback_MediaStreamTrackSourcesCallback";

  static stop_Callback(mthis) native "MediaStreamTrack_stop_Callback";
}

class BlinkMediaStreamTrackEvent {
  static track_Getter(mthis) native "MediaStreamTrackEvent_track_Getter";
}

class BlinkMemoryInfo {
  static jsHeapSizeLimit_Getter(mthis) native "MemoryInfo_jsHeapSizeLimit_Getter";

  static totalJSHeapSize_Getter(mthis) native "MemoryInfo_totalJSHeapSize_Getter";

  static usedJSHeapSize_Getter(mthis) native "MemoryInfo_usedJSHeapSize_Getter";
}

class BlinkMessageChannel {
  static port1_Getter(mthis) native "MessageChannel_port1_Getter";

  static port2_Getter(mthis) native "MessageChannel_port2_Getter";
}

class BlinkMessageEvent {
  static data_Getter(mthis) native "MessageEvent_data_Getter";

  static lastEventId_Getter(mthis) native "MessageEvent_lastEventId_Getter";

  static origin_Getter(mthis) native "MessageEvent_origin_Getter";

  static source_Getter(mthis) native "MessageEvent_source_Getter";

  static initMessageEvent_Callback_DOMString_boolean_boolean_ScriptValue_DOMString_DOMString_Window_A_MessagePort_A(mthis, typeArg, canBubbleArg, cancelableArg, dataArg, originArg, lastEventIdArg, sourceArg, messagePorts) native "MessageEvent_initMessageEvent_Callback";
}

class BlinkMessagePort {
  static close_Callback(mthis) native "MessagePort_close_Callback";

  static postMessage_Callback_ScriptValue_A_MessagePort_A(mthis, message, messagePorts) native "MessagePort_postMessage_Callback";

  static start_Callback(mthis) native "MessagePort_start_Callback";
}

class BlinkMetadata {
  static modificationTime_Getter(mthis) native "Metadata_modificationTime_Getter";

  static size_Getter(mthis) native "Metadata_size_Getter";
}

class BlinkMimeType {
  static description_Getter(mthis) native "MimeType_description_Getter";

  static enabledPlugin_Getter(mthis) native "MimeType_enabledPlugin_Getter";

  static suffixes_Getter(mthis) native "MimeType_suffixes_Getter";

  static type_Getter(mthis) native "MimeType_type_Getter";
}

class BlinkMimeTypeArray {
  static length_Getter(mthis) native "MimeTypeArray_length_Getter";

  static $__getter___Callback_DOMString(mthis, name) native "MimeTypeArray___getter___Callback_DOMString";

  static item_Callback_ul(mthis, index) native "MimeTypeArray_item_Callback_unsigned long";

  static namedItem_Callback_DOMString(mthis, name) native "MimeTypeArray_namedItem_Callback_DOMString";
}

class BlinkMouseEvent {
  static altKey_Getter(mthis) native "MouseEvent_altKey_Getter";

  static button_Getter(mthis) native "MouseEvent_button_Getter";

  static clientX_Getter(mthis) native "MouseEvent_clientX_Getter";

  static clientY_Getter(mthis) native "MouseEvent_clientY_Getter";

  static ctrlKey_Getter(mthis) native "MouseEvent_ctrlKey_Getter";

  static dataTransfer_Getter(mthis) native "MouseEvent_dataTransfer_Getter";

  static fromElement_Getter(mthis) native "MouseEvent_fromElement_Getter";

  static metaKey_Getter(mthis) native "MouseEvent_metaKey_Getter";

  static movementX_Getter(mthis) native "MouseEvent_movementX_Getter";

  static movementY_Getter(mthis) native "MouseEvent_movementY_Getter";

  static offsetX_Getter(mthis) native "MouseEvent_offsetX_Getter";

  static offsetY_Getter(mthis) native "MouseEvent_offsetY_Getter";

  static relatedTarget_Getter(mthis) native "MouseEvent_relatedTarget_Getter";

  static screenX_Getter(mthis) native "MouseEvent_screenX_Getter";

  static screenY_Getter(mthis) native "MouseEvent_screenY_Getter";

  static shiftKey_Getter(mthis) native "MouseEvent_shiftKey_Getter";

  static toElement_Getter(mthis) native "MouseEvent_toElement_Getter";

  static webkitMovementX_Getter(mthis) native "MouseEvent_webkitMovementX_Getter";

  static webkitMovementY_Getter(mthis) native "MouseEvent_webkitMovementY_Getter";

  static initMouseEvent_Callback_DOMString_boolean_boolean_Window_long_long_long_long_long_boolean_boolean_boolean_boolean_us_EventTarget(mthis, type, canBubble, cancelable, view, detail, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey, button, relatedTarget) native "MouseEvent_initMouseEvent_Callback_DOMString_boolean_boolean_Window_long_long_long_long_long_boolean_boolean_boolean_boolean_unsigned short_EventTarget";
}

class BlinkMutationEvent {}

class BlinkMutationObserver {
  static constructorCallback_MutationCallback(callback) native "MutationObserver_constructorCallback";

  static disconnect_Callback(mthis) native "MutationObserver_disconnect_Callback";

  static observe_Callback_Node_Dictionary(mthis, target, options) native "MutationObserver_observe_Callback_Node_Dictionary";

  static takeRecords_Callback(mthis) native "MutationObserver_takeRecords_Callback";
}

class BlinkMutationRecord {
  static addedNodes_Getter(mthis) native "MutationRecord_addedNodes_Getter";

  static attributeName_Getter(mthis) native "MutationRecord_attributeName_Getter";

  static attributeNamespace_Getter(mthis) native "MutationRecord_attributeNamespace_Getter";

  static nextSibling_Getter(mthis) native "MutationRecord_nextSibling_Getter";

  static oldValue_Getter(mthis) native "MutationRecord_oldValue_Getter";

  static previousSibling_Getter(mthis) native "MutationRecord_previousSibling_Getter";

  static removedNodes_Getter(mthis) native "MutationRecord_removedNodes_Getter";

  static target_Getter(mthis) native "MutationRecord_target_Getter";

  static type_Getter(mthis) native "MutationRecord_type_Getter";
}

class BlinkNamedNodeMap {
  static length_Getter(mthis) native "NamedNodeMap_length_Getter";

  static $__getter___Callback_DOMString(mthis, name) native "NamedNodeMap___getter___Callback_DOMString";

  static getNamedItem_Callback_DOMString(mthis, name) native "NamedNodeMap_getNamedItem_Callback_DOMString";

  static getNamedItemNS_Callback_DOMString_DOMString(mthis, namespaceURI, localName) native "NamedNodeMap_getNamedItemNS_Callback_DOMString_DOMString";

  static item_Callback_ul(mthis, index) native "NamedNodeMap_item_Callback_unsigned long";

  static removeNamedItem_Callback_DOMString(mthis, name) native "NamedNodeMap_removeNamedItem_Callback_DOMString";

  static removeNamedItemNS_Callback_DOMString_DOMString(mthis, namespaceURI, localName) native "NamedNodeMap_removeNamedItemNS_Callback_DOMString_DOMString";

  static setNamedItem_Callback_Node(mthis, node) native "NamedNodeMap_setNamedItem_Callback_Node";

  static setNamedItemNS_Callback_Node(mthis, node) native "NamedNodeMap_setNamedItemNS_Callback_Node";
}

class BlinkNavigatorCPU {
  static hardwareConcurrency_Getter(mthis) native "NavigatorCPU_hardwareConcurrency_Getter";
}

class BlinkNavigatorID {
  static appCodeName_Getter(mthis) native "Navigator_appCodeName_Getter";

  static appName_Getter(mthis) native "Navigator_appName_Getter";

  static appVersion_Getter(mthis) native "Navigator_appVersion_Getter";

  static dartEnabled_Getter(mthis) native "Navigator_dartEnabled_Getter";

  static platform_Getter(mthis) native "Navigator_platform_Getter";

  static product_Getter(mthis) native "Navigator_product_Getter";

  static userAgent_Getter(mthis) native "Navigator_userAgent_Getter";
}

class BlinkNavigatorLanguage {
  static language_Getter(mthis) native "NavigatorLanguage_language_Getter";

  static languages_Getter(mthis) native "NavigatorLanguage_languages_Getter";
}

class BlinkNavigatorOnLine {
  static onLine_Getter(mthis) native "NavigatorOnLine_onLine_Getter";
}

class BlinkNavigator {
  static connection_Getter(mthis) native "Navigator_connection_Getter";

  static cookieEnabled_Getter(mthis) native "Navigator_cookieEnabled_Getter";

  static doNotTrack_Getter(mthis) native "Navigator_doNotTrack_Getter";

  static geolocation_Getter(mthis) native "Navigator_geolocation_Getter";

  static maxTouchPoints_Getter(mthis) native "Navigator_maxTouchPoints_Getter";

  static mimeTypes_Getter(mthis) native "Navigator_mimeTypes_Getter";

  static productSub_Getter(mthis) native "Navigator_productSub_Getter";

  static push_Getter(mthis) native "Navigator_push_Getter";

  static serviceWorker_Getter(mthis) native "Navigator_serviceWorker_Getter";

  static storageQuota_Getter(mthis) native "Navigator_storageQuota_Getter";

  static vendor_Getter(mthis) native "Navigator_vendor_Getter";

  static vendorSub_Getter(mthis) native "Navigator_vendorSub_Getter";

  static webkitPersistentStorage_Getter(mthis) native "Navigator_webkitPersistentStorage_Getter";

  static webkitTemporaryStorage_Getter(mthis) native "Navigator_webkitTemporaryStorage_Getter";

  static getGamepads_Callback(mthis) native "Navigator_getGamepads_Callback";

  static getMediaDevices_Callback_MediaDeviceInfoCallback(mthis, resultCallback) native "Navigator_getMediaDevices_Callback_MediaDeviceInfoCallback";

  static getStorageUpdates_Callback(mthis) native "Navigator_getStorageUpdates_Callback";

  static isProtocolHandlerRegistered_Callback_DOMString_DOMString(mthis, scheme, url) native "Navigator_isProtocolHandlerRegistered_Callback_DOMString_DOMString";

  static registerProtocolHandler_Callback_DOMString_DOMString_DOMString(mthis, scheme, url, title) native "Navigator_registerProtocolHandler_Callback_DOMString_DOMString_DOMString";

  static sendBeacon_Callback_DOMString_DOMString(mthis, url, data) native "Navigator_sendBeacon_Callback_DOMString_DOMString";

  static sendBeacon_Callback_DOMString_ArrayBufferView(mthis, url, data) native "Navigator_sendBeacon_Callback_DOMString_ArrayBufferView";

  static sendBeacon_Callback_DOMString_FormData(mthis, url, data) native "Navigator_sendBeacon_Callback_DOMString_FormData";

  static sendBeacon_Callback_DOMString_Blob(mthis, url, data) native "Navigator_sendBeacon_Callback_DOMString_Blob";

  static unregisterProtocolHandler_Callback_DOMString_DOMString(mthis, scheme, url) native "Navigator_unregisterProtocolHandler_Callback_DOMString_DOMString";

  static webkitGetUserMedia_Callback_Dictionary_NavigatorUserMediaSuccessCallback_NavigatorUserMediaErrorCallback(mthis, options, successCallback, errorCallback) native "Navigator_webkitGetUserMedia_Callback_Dictionary_NavigatorUserMediaSuccessCallback_NavigatorUserMediaErrorCallback";

  static appCodeName_Getter(mthis) native "Navigator_appCodeName_Getter";

  static appName_Getter(mthis) native "Navigator_appName_Getter";

  static appVersion_Getter(mthis) native "Navigator_appVersion_Getter";

  static dartEnabled_Getter(mthis) native "Navigator_dartEnabled_Getter";

  static platform_Getter(mthis) native "Navigator_platform_Getter";

  static product_Getter(mthis) native "Navigator_product_Getter";

  static userAgent_Getter(mthis) native "Navigator_userAgent_Getter";

  static language_Getter(mthis) native "Navigator_language_Getter";

  static languages_Getter(mthis) native "Navigator_languages_Getter";

  static onLine_Getter(mthis) native "Navigator_onLine_Getter";
}

class BlinkNavigatorUserMediaError {
  static constraintName_Getter(mthis) native "NavigatorUserMediaError_constraintName_Getter";

  static message_Getter(mthis) native "NavigatorUserMediaError_message_Getter";

  static name_Getter(mthis) native "NavigatorUserMediaError_name_Getter";
}

class BlinkNetworkInformation {
  static type_Getter(mthis) native "NetworkInformation_type_Getter";
}

class BlinkNodeFilter {}

class BlinkNodeIterator {
  static pointerBeforeReferenceNode_Getter(mthis) native "NodeIterator_pointerBeforeReferenceNode_Getter";

  static referenceNode_Getter(mthis) native "NodeIterator_referenceNode_Getter";

  static root_Getter(mthis) native "NodeIterator_root_Getter";

  static whatToShow_Getter(mthis) native "NodeIterator_whatToShow_Getter";

  static detach_Callback(mthis) native "NodeIterator_detach_Callback";

  static nextNode_Callback(mthis) native "NodeIterator_nextNode_Callback";

  static previousNode_Callback(mthis) native "NodeIterator_previousNode_Callback";
}

class BlinkNodeList {
  static length_Getter(mthis) native "NodeList_length_Getter";

  static item_Callback_ul(mthis, index) native "NodeList_item_Callback_unsigned long";
}

class BlinkNotation {}

class BlinkNotification {
  static constructorCallback_DOMString_Dictionary(title, options) native "Notification_constructorCallback_DOMString_Dictionary";

  static body_Getter(mthis) native "Notification_body_Getter";

  static dir_Getter(mthis) native "Notification_dir_Getter";

  static icon_Getter(mthis) native "Notification_icon_Getter";

  static lang_Getter(mthis) native "Notification_lang_Getter";

  static permission_Getter(mthis) native "Notification_permission_Getter";

  static tag_Getter(mthis) native "Notification_tag_Getter";

  static title_Getter(mthis) native "Notification_title_Getter";

  static close_Callback(mthis) native "Notification_close_Callback";

  static requestPermission_Callback_NotificationPermissionCallback(callback) native "Notification_requestPermission_Callback_NotificationPermissionCallback";
}

class BlinkOESElementIndexUint {}

class BlinkOESStandardDerivatives {}

class BlinkOESTextureFloat {}

class BlinkOESTextureFloatLinear {}

class BlinkOESTextureHalfFloat {}

class BlinkOESTextureHalfFloatLinear {}

class BlinkOESVertexArrayObject {
  static bindVertexArrayOES_Callback_WebGLVertexArrayObjectOES(mthis, arrayObject) native "OESVertexArrayObject_bindVertexArrayOES_Callback_WebGLVertexArrayObjectOES";

  static createVertexArrayOES_Callback(mthis) native "OESVertexArrayObject_createVertexArrayOES_Callback";

  static deleteVertexArrayOES_Callback_WebGLVertexArrayObjectOES(mthis, arrayObject) native "OESVertexArrayObject_deleteVertexArrayOES_Callback_WebGLVertexArrayObjectOES";

  static isVertexArrayOES_Callback_WebGLVertexArrayObjectOES(mthis, arrayObject) native "OESVertexArrayObject_isVertexArrayOES_Callback_WebGLVertexArrayObjectOES";
}

class BlinkOfflineAudioCompletionEvent {
  static renderedBuffer_Getter(mthis) native "OfflineAudioCompletionEvent_renderedBuffer_Getter";
}

class BlinkOfflineAudioContext {
  static constructorCallback_ul_ul_float(numberOfChannels, numberOfFrames, sampleRate) native "OfflineAudioContext_constructorCallback_unsigned long_unsigned long_float";
}

class BlinkOscillatorNode {
  static detune_Getter(mthis) native "OscillatorNode_detune_Getter";

  static frequency_Getter(mthis) native "OscillatorNode_frequency_Getter";

  static type_Getter(mthis) native "OscillatorNode_type_Getter";

  static type_Setter_DOMString(mthis, value) native "OscillatorNode_type_Setter";

  static noteOff_Callback_double(mthis, when) native "OscillatorNode_noteOff_Callback_double";

  static noteOn_Callback_double(mthis, when) native "OscillatorNode_noteOn_Callback_double";

  static setPeriodicWave_Callback_PeriodicWave(mthis, periodicWave) native "OscillatorNode_setPeriodicWave_Callback_PeriodicWave";

  static start_Callback_double(mthis, when) native "OscillatorNode_start_Callback_double";

  static start_Callback(mthis) native "OscillatorNode_start_Callback";

  static stop_Callback_double(mthis, when) native "OscillatorNode_stop_Callback_double";

  static stop_Callback(mthis) native "OscillatorNode_stop_Callback";
}

class BlinkOverflowEvent {
  static horizontalOverflow_Getter(mthis) native "OverflowEvent_horizontalOverflow_Getter";

  static orient_Getter(mthis) native "OverflowEvent_orient_Getter";

  static verticalOverflow_Getter(mthis) native "OverflowEvent_verticalOverflow_Getter";
}

class BlinkPagePopupController {}

class BlinkPageTransitionEvent {
  static persisted_Getter(mthis) native "PageTransitionEvent_persisted_Getter";
}

class BlinkPannerNode {
  static coneInnerAngle_Getter(mthis) native "PannerNode_coneInnerAngle_Getter";

  static coneInnerAngle_Setter_double(mthis, value) native "PannerNode_coneInnerAngle_Setter";

  static coneOuterAngle_Getter(mthis) native "PannerNode_coneOuterAngle_Getter";

  static coneOuterAngle_Setter_double(mthis, value) native "PannerNode_coneOuterAngle_Setter";

  static coneOuterGain_Getter(mthis) native "PannerNode_coneOuterGain_Getter";

  static coneOuterGain_Setter_double(mthis, value) native "PannerNode_coneOuterGain_Setter";

  static distanceModel_Getter(mthis) native "PannerNode_distanceModel_Getter";

  static distanceModel_Setter_DOMString(mthis, value) native "PannerNode_distanceModel_Setter";

  static maxDistance_Getter(mthis) native "PannerNode_maxDistance_Getter";

  static maxDistance_Setter_double(mthis, value) native "PannerNode_maxDistance_Setter";

  static panningModel_Getter(mthis) native "PannerNode_panningModel_Getter";

  static panningModel_Setter_DOMString(mthis, value) native "PannerNode_panningModel_Setter";

  static refDistance_Getter(mthis) native "PannerNode_refDistance_Getter";

  static refDistance_Setter_double(mthis, value) native "PannerNode_refDistance_Setter";

  static rolloffFactor_Getter(mthis) native "PannerNode_rolloffFactor_Getter";

  static rolloffFactor_Setter_double(mthis, value) native "PannerNode_rolloffFactor_Setter";

  static setOrientation_Callback_float_float_float(mthis, x, y, z) native "PannerNode_setOrientation_Callback_float_float_float";

  static setPosition_Callback_float_float_float(mthis, x, y, z) native "PannerNode_setPosition_Callback_float_float_float";

  static setVelocity_Callback_float_float_float(mthis, x, y, z) native "PannerNode_setVelocity_Callback_float_float_float";
}

class BlinkPath2D {
  static constructorCallback() native "Path2D_constructorCallback";

  static constructorCallback_Path2D(path_OR_text) native "Path2D_constructorCallback_Path2D";

  static constructorCallback_DOMString(path_OR_text) native "Path2D_constructorCallback_DOMString";

  static addPath_Callback_Path2D_SVGMatrix(mthis, path, transform) native "Path2D_addPath_Callback_Path2D_SVGMatrix";

  static addPath_Callback_Path2D(mthis, path) native "Path2D_addPath_Callback_Path2D";

  static arc_Callback_float_float_float_float_float_boolean(mthis, x, y, radius, startAngle, endAngle, anticlockwise) native "Path2D_arc_Callback_float_float_float_float_float_boolean";

  static arcTo_Callback_float_float_float_float_float(mthis, x1, y1, x2, y2, radius) native "Path2D_arcTo_Callback_float_float_float_float_float";

  static bezierCurveTo_Callback_float_float_float_float_float_float(mthis, cp1x, cp1y, cp2x, cp2y, x, y) native "Path2D_bezierCurveTo_Callback_float_float_float_float_float_float";

  static closePath_Callback(mthis) native "Path2D_closePath_Callback";

  static ellipse_Callback_float_float_float_float_float_float_float_boolean(mthis, x, y, radiusX, radiusY, rotation, startAngle, endAngle, anticlockwise) native "Path2D_ellipse_Callback_float_float_float_float_float_float_float_boolean";

  static lineTo_Callback_float_float(mthis, x, y) native "Path2D_lineTo_Callback_float_float";

  static moveTo_Callback_float_float(mthis, x, y) native "Path2D_moveTo_Callback_float_float";

  static quadraticCurveTo_Callback_float_float_float_float(mthis, cpx, cpy, x, y) native "Path2D_quadraticCurveTo_Callback_float_float_float_float";

  static rect_Callback_float_float_float_float(mthis, x, y, width, height) native "Path2D_rect_Callback_float_float_float_float";
}

class BlinkPerformance {
  static memory_Getter(mthis) native "Performance_memory_Getter";

  static navigation_Getter(mthis) native "Performance_navigation_Getter";

  static timing_Getter(mthis) native "Performance_timing_Getter";

  static clearMarks_Callback_DOMString(mthis, markName) native "Performance_clearMarks_Callback_DOMString";

  static clearMeasures_Callback_DOMString(mthis, measureName) native "Performance_clearMeasures_Callback_DOMString";

  static getEntries_Callback(mthis) native "Performance_getEntries_Callback";

  static getEntriesByName_Callback_DOMString_DOMString(mthis, name, entryType) native "Performance_getEntriesByName_Callback_DOMString_DOMString";

  static getEntriesByType_Callback_DOMString(mthis, entryType) native "Performance_getEntriesByType_Callback_DOMString";

  static mark_Callback_DOMString(mthis, markName) native "Performance_mark_Callback_DOMString";

  static measure_Callback_DOMString_DOMString_DOMString(mthis, measureName, startMark, endMark) native "Performance_measure_Callback_DOMString_DOMString_DOMString";

  static now_Callback(mthis) native "Performance_now_Callback";

  static webkitClearResourceTimings_Callback(mthis) native "Performance_webkitClearResourceTimings_Callback";

  static webkitSetResourceTimingBufferSize_Callback_ul(mthis, maxSize) native "Performance_webkitSetResourceTimingBufferSize_Callback_unsigned long";
}

class BlinkPerformanceEntry {
  static duration_Getter(mthis) native "PerformanceEntry_duration_Getter";

  static entryType_Getter(mthis) native "PerformanceEntry_entryType_Getter";

  static name_Getter(mthis) native "PerformanceEntry_name_Getter";

  static startTime_Getter(mthis) native "PerformanceEntry_startTime_Getter";
}

class BlinkPerformanceMark {}

class BlinkPerformanceMeasure {}

class BlinkPerformanceNavigation {
  static redirectCount_Getter(mthis) native "PerformanceNavigation_redirectCount_Getter";

  static type_Getter(mthis) native "PerformanceNavigation_type_Getter";
}

class BlinkPerformanceResourceTiming {
  static connectEnd_Getter(mthis) native "PerformanceResourceTiming_connectEnd_Getter";

  static connectStart_Getter(mthis) native "PerformanceResourceTiming_connectStart_Getter";

  static domainLookupEnd_Getter(mthis) native "PerformanceResourceTiming_domainLookupEnd_Getter";

  static domainLookupStart_Getter(mthis) native "PerformanceResourceTiming_domainLookupStart_Getter";

  static fetchStart_Getter(mthis) native "PerformanceResourceTiming_fetchStart_Getter";

  static initiatorType_Getter(mthis) native "PerformanceResourceTiming_initiatorType_Getter";

  static redirectEnd_Getter(mthis) native "PerformanceResourceTiming_redirectEnd_Getter";

  static redirectStart_Getter(mthis) native "PerformanceResourceTiming_redirectStart_Getter";

  static requestStart_Getter(mthis) native "PerformanceResourceTiming_requestStart_Getter";

  static responseEnd_Getter(mthis) native "PerformanceResourceTiming_responseEnd_Getter";

  static responseStart_Getter(mthis) native "PerformanceResourceTiming_responseStart_Getter";

  static secureConnectionStart_Getter(mthis) native "PerformanceResourceTiming_secureConnectionStart_Getter";
}

class BlinkPerformanceTiming {
  static connectEnd_Getter(mthis) native "PerformanceTiming_connectEnd_Getter";

  static connectStart_Getter(mthis) native "PerformanceTiming_connectStart_Getter";

  static domComplete_Getter(mthis) native "PerformanceTiming_domComplete_Getter";

  static domContentLoadedEventEnd_Getter(mthis) native "PerformanceTiming_domContentLoadedEventEnd_Getter";

  static domContentLoadedEventStart_Getter(mthis) native "PerformanceTiming_domContentLoadedEventStart_Getter";

  static domInteractive_Getter(mthis) native "PerformanceTiming_domInteractive_Getter";

  static domLoading_Getter(mthis) native "PerformanceTiming_domLoading_Getter";

  static domainLookupEnd_Getter(mthis) native "PerformanceTiming_domainLookupEnd_Getter";

  static domainLookupStart_Getter(mthis) native "PerformanceTiming_domainLookupStart_Getter";

  static fetchStart_Getter(mthis) native "PerformanceTiming_fetchStart_Getter";

  static loadEventEnd_Getter(mthis) native "PerformanceTiming_loadEventEnd_Getter";

  static loadEventStart_Getter(mthis) native "PerformanceTiming_loadEventStart_Getter";

  static navigationStart_Getter(mthis) native "PerformanceTiming_navigationStart_Getter";

  static redirectEnd_Getter(mthis) native "PerformanceTiming_redirectEnd_Getter";

  static redirectStart_Getter(mthis) native "PerformanceTiming_redirectStart_Getter";

  static requestStart_Getter(mthis) native "PerformanceTiming_requestStart_Getter";

  static responseEnd_Getter(mthis) native "PerformanceTiming_responseEnd_Getter";

  static responseStart_Getter(mthis) native "PerformanceTiming_responseStart_Getter";

  static secureConnectionStart_Getter(mthis) native "PerformanceTiming_secureConnectionStart_Getter";

  static unloadEventEnd_Getter(mthis) native "PerformanceTiming_unloadEventEnd_Getter";

  static unloadEventStart_Getter(mthis) native "PerformanceTiming_unloadEventStart_Getter";
}

class BlinkPeriodicWave {}

class BlinkPlugin {
  static description_Getter(mthis) native "Plugin_description_Getter";

  static filename_Getter(mthis) native "Plugin_filename_Getter";

  static length_Getter(mthis) native "Plugin_length_Getter";

  static name_Getter(mthis) native "Plugin_name_Getter";

  static $__getter___Callback_DOMString(mthis, name) native "Plugin___getter___Callback_DOMString";

  static item_Callback_ul(mthis, index) native "Plugin_item_Callback_unsigned long";

  static namedItem_Callback_DOMString(mthis, name) native "Plugin_namedItem_Callback_DOMString";
}

class BlinkPluginArray {
  static length_Getter(mthis) native "PluginArray_length_Getter";

  static $__getter___Callback_DOMString(mthis, name) native "PluginArray___getter___Callback_DOMString";

  static item_Callback_ul(mthis, index) native "PluginArray_item_Callback_unsigned long";

  static namedItem_Callback_DOMString(mthis, name) native "PluginArray_namedItem_Callback_DOMString";

  static refresh_Callback_boolean(mthis, reload) native "PluginArray_refresh_Callback_boolean";
}

class BlinkPopStateEvent {
  static state_Getter(mthis) native "PopStateEvent_state_Getter";
}

class BlinkPositionError {
  static code_Getter(mthis) native "PositionError_code_Getter";

  static message_Getter(mthis) native "PositionError_message_Getter";
}

class BlinkProcessingInstruction {
  static sheet_Getter(mthis) native "ProcessingInstruction_sheet_Getter";

  static target_Getter(mthis) native "ProcessingInstruction_target_Getter";
}

class BlinkProgressEvent {
  static lengthComputable_Getter(mthis) native "ProgressEvent_lengthComputable_Getter";

  static loaded_Getter(mthis) native "ProgressEvent_loaded_Getter";

  static total_Getter(mthis) native "ProgressEvent_total_Getter";
}

class BlinkPushEvent {
  static data_Getter(mthis) native "PushEvent_data_Getter";
}

class BlinkPushManager {}

class BlinkPushRegistration {
  static pushEndpoint_Getter(mthis) native "PushRegistration_pushEndpoint_Getter";

  static pushRegistrationId_Getter(mthis) native "PushRegistration_pushRegistrationId_Getter";
}

class BlinkRGBColor {}

class BlinkRTCDTMFSender {
  static canInsertDTMF_Getter(mthis) native "RTCDTMFSender_canInsertDTMF_Getter";

  static duration_Getter(mthis) native "RTCDTMFSender_duration_Getter";

  static interToneGap_Getter(mthis) native "RTCDTMFSender_interToneGap_Getter";

  static toneBuffer_Getter(mthis) native "RTCDTMFSender_toneBuffer_Getter";

  static track_Getter(mthis) native "RTCDTMFSender_track_Getter";

  static insertDTMF_Callback_DOMString_long_long(mthis, tones, duration, interToneGap) native "RTCDTMFSender_insertDTMF_Callback_DOMString_long_long";

  static insertDTMF_Callback_DOMString_long(mthis, tones, duration) native "RTCDTMFSender_insertDTMF_Callback_DOMString_long";

  static insertDTMF_Callback_DOMString(mthis, tones) native "RTCDTMFSender_insertDTMF_Callback_DOMString";
}

class BlinkRTCDTMFToneChangeEvent {
  static tone_Getter(mthis) native "RTCDTMFToneChangeEvent_tone_Getter";
}

class BlinkRTCDataChannel {
  static binaryType_Getter(mthis) native "RTCDataChannel_binaryType_Getter";

  static binaryType_Setter_DOMString(mthis, value) native "RTCDataChannel_binaryType_Setter";

  static bufferedAmount_Getter(mthis) native "RTCDataChannel_bufferedAmount_Getter";

  static id_Getter(mthis) native "RTCDataChannel_id_Getter";

  static label_Getter(mthis) native "RTCDataChannel_label_Getter";

  static maxRetransmitTime_Getter(mthis) native "RTCDataChannel_maxRetransmitTime_Getter";

  static maxRetransmits_Getter(mthis) native "RTCDataChannel_maxRetransmits_Getter";

  static negotiated_Getter(mthis) native "RTCDataChannel_negotiated_Getter";

  static ordered_Getter(mthis) native "RTCDataChannel_ordered_Getter";

  static protocol_Getter(mthis) native "RTCDataChannel_protocol_Getter";

  static readyState_Getter(mthis) native "RTCDataChannel_readyState_Getter";

  static reliable_Getter(mthis) native "RTCDataChannel_reliable_Getter";

  static close_Callback(mthis) native "RTCDataChannel_close_Callback";

  static send_Callback_DOMString(mthis, data) native "RTCDataChannel_send_Callback_DOMString";

  static send_Callback_Blob(mthis, data) native "RTCDataChannel_send_Callback_Blob";

  static send_Callback_ArrayBufferView(mthis, data) native "RTCDataChannel_send_Callback_ArrayBufferView";

  static send_Callback_ArrayBuffer(mthis, data) native "RTCDataChannel_send_Callback_ArrayBuffer";
}

class BlinkRTCDataChannelEvent {
  static channel_Getter(mthis) native "RTCDataChannelEvent_channel_Getter";
}

class BlinkRTCIceCandidate {
  static constructorCallback_Dictionary(dictionary) native "RTCIceCandidate_constructorCallback_Dictionary";

  static candidate_Getter(mthis) native "RTCIceCandidate_candidate_Getter";

  static candidate_Setter_DOMString(mthis, value) native "RTCIceCandidate_candidate_Setter";

  static sdpMLineIndex_Getter(mthis) native "RTCIceCandidate_sdpMLineIndex_Getter";

  static sdpMLineIndex_Setter_us(mthis, value) native "RTCIceCandidate_sdpMLineIndex_Setter";

  static sdpMid_Getter(mthis) native "RTCIceCandidate_sdpMid_Getter";

  static sdpMid_Setter_DOMString(mthis, value) native "RTCIceCandidate_sdpMid_Setter";
}

class BlinkRTCIceCandidateEvent {
  static candidate_Getter(mthis) native "RTCIceCandidateEvent_candidate_Getter";
}

class BlinkRTCPeerConnection {
  static constructorCallback_Dictionary_Dictionary(rtcIceServers, mediaConstraints) native "RTCPeerConnection_constructorCallback_Dictionary_Dictionary";

  static iceConnectionState_Getter(mthis) native "RTCPeerConnection_iceConnectionState_Getter";

  static iceGatheringState_Getter(mthis) native "RTCPeerConnection_iceGatheringState_Getter";

  static localDescription_Getter(mthis) native "RTCPeerConnection_localDescription_Getter";

  static remoteDescription_Getter(mthis) native "RTCPeerConnection_remoteDescription_Getter";

  static signalingState_Getter(mthis) native "RTCPeerConnection_signalingState_Getter";

  static addIceCandidate_Callback_RTCIceCandidate_VoidCallback_RTCErrorCallback(mthis, candidate, successCallback, failureCallback) native "RTCPeerConnection_addIceCandidate_Callback_RTCIceCandidate_VoidCallback_RTCErrorCallback";

  static addStream_Callback_MediaStream_Dictionary(mthis, stream, mediaConstraints) native "RTCPeerConnection_addStream_Callback_MediaStream_Dictionary";

  static close_Callback(mthis) native "RTCPeerConnection_close_Callback";

  static createAnswer_Callback_RTCSessionDescriptionCallback_RTCErrorCallback_Dictionary(mthis, successCallback, failureCallback, mediaConstraints) native "RTCPeerConnection_createAnswer_Callback_RTCSessionDescriptionCallback_RTCErrorCallback_Dictionary";

  static createDTMFSender_Callback_MediaStreamTrack(mthis, track) native "RTCPeerConnection_createDTMFSender_Callback_MediaStreamTrack";

  static createDataChannel_Callback_DOMString_Dictionary(mthis, label, options) native "RTCPeerConnection_createDataChannel_Callback_DOMString_Dictionary";

  static createOffer_Callback_RTCSessionDescriptionCallback_RTCErrorCallback_Dictionary(mthis, successCallback, failureCallback, mediaConstraints) native "RTCPeerConnection_createOffer_Callback_RTCSessionDescriptionCallback_RTCErrorCallback_Dictionary";

  static getLocalStreams_Callback(mthis) native "RTCPeerConnection_getLocalStreams_Callback";

  static getRemoteStreams_Callback(mthis) native "RTCPeerConnection_getRemoteStreams_Callback";

  static getStats_Callback_RTCStatsCallback_MediaStreamTrack(mthis, successCallback, selector) native "RTCPeerConnection_getStats_Callback_RTCStatsCallback_MediaStreamTrack";

  static getStreamById_Callback_DOMString(mthis, streamId) native "RTCPeerConnection_getStreamById_Callback_DOMString";

  static removeStream_Callback_MediaStream(mthis, stream) native "RTCPeerConnection_removeStream_Callback_MediaStream";

  static setLocalDescription_Callback_RTCSessionDescription_VoidCallback_RTCErrorCallback(mthis, description, successCallback, failureCallback) native "RTCPeerConnection_setLocalDescription_Callback_RTCSessionDescription_VoidCallback_RTCErrorCallback";

  static setRemoteDescription_Callback_RTCSessionDescription_VoidCallback_RTCErrorCallback(mthis, description, successCallback, failureCallback) native "RTCPeerConnection_setRemoteDescription_Callback_RTCSessionDescription_VoidCallback_RTCErrorCallback";

  static updateIce_Callback_Dictionary_Dictionary(mthis, configuration, mediaConstraints) native "RTCPeerConnection_updateIce_Callback_Dictionary_Dictionary";
}

class BlinkRTCSessionDescription {
  static constructorCallback_Dictionary(descriptionInitDict) native "RTCSessionDescription_constructorCallback_Dictionary";

  static sdp_Getter(mthis) native "RTCSessionDescription_sdp_Getter";

  static sdp_Setter_DOMString(mthis, value) native "RTCSessionDescription_sdp_Setter";

  static type_Getter(mthis) native "RTCSessionDescription_type_Getter";

  static type_Setter_DOMString(mthis, value) native "RTCSessionDescription_type_Setter";
}

class BlinkRTCStatsReport {
  static id_Getter(mthis) native "RTCStatsReport_id_Getter";

  static local_Getter(mthis) native "RTCStatsReport_local_Getter";

  static remote_Getter(mthis) native "RTCStatsReport_remote_Getter";

  static timestamp_Getter(mthis) native "RTCStatsReport_timestamp_Getter";

  static type_Getter(mthis) native "RTCStatsReport_type_Getter";

  static names_Callback(mthis) native "RTCStatsReport_names_Callback";

  static stat_Callback_DOMString(mthis, name) native "RTCStatsReport_stat_Callback_DOMString";
}

class BlinkRTCStatsResponse {
  static $__getter___Callback_DOMString(mthis, name) native "RTCStatsResponse___getter___Callback_DOMString";

  static namedItem_Callback_DOMString(mthis, name) native "RTCStatsResponse_namedItem_Callback_DOMString";

  static result_Callback(mthis) native "RTCStatsResponse_result_Callback";
}

class BlinkRadioNodeList {}

class BlinkRange {
  static collapsed_Getter(mthis) native "Range_collapsed_Getter";

  static commonAncestorContainer_Getter(mthis) native "Range_commonAncestorContainer_Getter";

  static endContainer_Getter(mthis) native "Range_endContainer_Getter";

  static endOffset_Getter(mthis) native "Range_endOffset_Getter";

  static startContainer_Getter(mthis) native "Range_startContainer_Getter";

  static startOffset_Getter(mthis) native "Range_startOffset_Getter";

  static cloneContents_Callback(mthis) native "Range_cloneContents_Callback";

  static cloneRange_Callback(mthis) native "Range_cloneRange_Callback";

  static collapse_Callback_boolean(mthis, toStart) native "Range_collapse_Callback_boolean";

  static comparePoint_Callback_Node_long(mthis, refNode, offset) native "Range_comparePoint_Callback_Node_long";

  static createContextualFragment_Callback_DOMString(mthis, html) native "Range_createContextualFragment_Callback_DOMString";

  static deleteContents_Callback(mthis) native "Range_deleteContents_Callback";

  static detach_Callback(mthis) native "Range_detach_Callback";

  static expand_Callback_DOMString(mthis, unit) native "Range_expand_Callback_DOMString";

  static extractContents_Callback(mthis) native "Range_extractContents_Callback";

  static getBoundingClientRect_Callback(mthis) native "Range_getBoundingClientRect_Callback";

  static getClientRects_Callback(mthis) native "Range_getClientRects_Callback";

  static insertNode_Callback_Node(mthis, newNode) native "Range_insertNode_Callback_Node";

  static isPointInRange_Callback_Node_long(mthis, refNode, offset) native "Range_isPointInRange_Callback_Node_long";

  static selectNode_Callback_Node(mthis, refNode) native "Range_selectNode_Callback_Node";

  static selectNodeContents_Callback_Node(mthis, refNode) native "Range_selectNodeContents_Callback_Node";

  static setEnd_Callback_Node_long(mthis, refNode, offset) native "Range_setEnd_Callback_Node_long";

  static setEndAfter_Callback_Node(mthis, refNode) native "Range_setEndAfter_Callback_Node";

  static setEndBefore_Callback_Node(mthis, refNode) native "Range_setEndBefore_Callback_Node";

  static setStart_Callback_Node_long(mthis, refNode, offset) native "Range_setStart_Callback_Node_long";

  static setStartAfter_Callback_Node(mthis, refNode) native "Range_setStartAfter_Callback_Node";

  static setStartBefore_Callback_Node(mthis, refNode) native "Range_setStartBefore_Callback_Node";

  static surroundContents_Callback_Node(mthis, newParent) native "Range_surroundContents_Callback_Node";

  static toString_Callback(mthis) native "Range_toString_Callback";
}

class BlinkRect {}

class BlinkRequest {
  static constructorCallback_Dictionary(requestInitDict) native "Request_constructorCallback_Dictionary";

  static headers_Getter(mthis) native "Request_headers_Getter";

  static origin_Getter(mthis) native "Request_origin_Getter";

  static url_Getter(mthis) native "Request_url_Getter";

  static url_Setter_DOMString(mthis, value) native "Request_url_Setter";
}

class BlinkResourceProgressEvent {
  static url_Getter(mthis) native "ResourceProgressEvent_url_Getter";
}

class BlinkResponse {
  static constructorCallback_Blob_Dictionary(body, responseInitDict) native "Response_constructorCallback_Blob_Dictionary";
}

class BlinkRsaKeyAlgorithm {
  static modulusLength_Getter(mthis) native "RsaKeyAlgorithm_modulusLength_Getter";

  static publicExponent_Getter(mthis) native "RsaKeyAlgorithm_publicExponent_Getter";
}

class BlinkRsaHashedKeyAlgorithm {
  static hash_Getter(mthis) native "RsaHashedKeyAlgorithm_hash_Getter";
}

class BlinkSQLError {
  static code_Getter(mthis) native "SQLError_code_Getter";

  static message_Getter(mthis) native "SQLError_message_Getter";
}

class BlinkSQLResultSet {
  static insertId_Getter(mthis) native "SQLResultSet_insertId_Getter";

  static rows_Getter(mthis) native "SQLResultSet_rows_Getter";

  static rowsAffected_Getter(mthis) native "SQLResultSet_rowsAffected_Getter";
}

class BlinkSQLResultSetRowList {
  static length_Getter(mthis) native "SQLResultSetRowList_length_Getter";

  static item_Callback_ul(mthis, index) native "SQLResultSetRowList_item_Callback";
}

class BlinkSQLTransaction {
  static executeSql_Callback_DOMString_A_object_A_SQLStatementCallback_SQLStatementErrorCallback(mthis, sqlStatement, arguments, callback, errorCallback) native "SQLTransaction_executeSql_Callback";
}

class BlinkSQLTransactionSync {}

class BlinkSVGElement {
  static className_Getter(mthis) native "SVGElement_className_Getter";

  static ownerSVGElement_Getter(mthis) native "SVGElement_ownerSVGElement_Getter";

  static style_Getter(mthis) native "SVGElement_style_Getter";

  static tabIndex_Getter(mthis) native "SVGElement_tabIndex_Getter";

  static tabIndex_Setter_long(mthis, value) native "SVGElement_tabIndex_Setter";

  static viewportElement_Getter(mthis) native "SVGElement_viewportElement_Getter";

  static xmlbase_Getter(mthis) native "SVGElement_xmlbase_Getter";

  static xmlbase_Setter_DOMString(mthis, value) native "SVGElement_xmlbase_Setter";

  static xmllang_Getter(mthis) native "SVGElement_xmllang_Getter";

  static xmllang_Setter_DOMString(mthis, value) native "SVGElement_xmllang_Setter";

  static xmlspace_Getter(mthis) native "SVGElement_xmlspace_Getter";

  static xmlspace_Setter_DOMString(mthis, value) native "SVGElement_xmlspace_Setter";
}

class BlinkSVGTests {
  static requiredExtensions_Getter(mthis) native "SVGTests_requiredExtensions_Getter";

  static requiredFeatures_Getter(mthis) native "SVGTests_requiredFeatures_Getter";

  static systemLanguage_Getter(mthis) native "SVGTests_systemLanguage_Getter";

  static hasExtension_Callback_DOMString(mthis, extension) native "SVGTests_hasExtension_Callback_DOMString";
}

class BlinkSVGGraphicsElement {
  static farthestViewportElement_Getter(mthis) native "SVGGraphicsElement_farthestViewportElement_Getter";

  static nearestViewportElement_Getter(mthis) native "SVGGraphicsElement_nearestViewportElement_Getter";

  static transform_Getter(mthis) native "SVGGraphicsElement_transform_Getter";

  static getBBox_Callback(mthis) native "SVGGraphicsElement_getBBox_Callback";

  static getCTM_Callback(mthis) native "SVGGraphicsElement_getCTM_Callback";

  static getScreenCTM_Callback(mthis) native "SVGGraphicsElement_getScreenCTM_Callback";

  static getTransformToElement_Callback_SVGElement(mthis, element) native "SVGGraphicsElement_getTransformToElement_Callback_SVGElement";

  static requiredExtensions_Getter(mthis) native "SVGGraphicsElement_requiredExtensions_Getter";

  static requiredFeatures_Getter(mthis) native "SVGGraphicsElement_requiredFeatures_Getter";

  static systemLanguage_Getter(mthis) native "SVGGraphicsElement_systemLanguage_Getter";

  static hasExtension_Callback_DOMString(mthis, extension) native "SVGGraphicsElement_hasExtension_Callback_DOMString";
}

class BlinkSVGURIReference {
  static href_Getter(mthis) native "SVGURIReference_href_Getter";
}

class BlinkSVGAElement {
  static target_Getter(mthis) native "SVGAElement_target_Getter";

  static href_Getter(mthis) native "SVGAElement_href_Getter";
}

class BlinkSVGAltGlyphDefElement {}

class BlinkSVGTextContentElement {
  static lengthAdjust_Getter(mthis) native "SVGTextContentElement_lengthAdjust_Getter";

  static textLength_Getter(mthis) native "SVGTextContentElement_textLength_Getter";

  static getCharNumAtPosition_Callback_SVGPoint(mthis, point) native "SVGTextContentElement_getCharNumAtPosition_Callback_SVGPoint";

  static getComputedTextLength_Callback(mthis) native "SVGTextContentElement_getComputedTextLength_Callback";

  static getEndPositionOfChar_Callback_ul(mthis, offset) native "SVGTextContentElement_getEndPositionOfChar_Callback_unsigned long";

  static getExtentOfChar_Callback_ul(mthis, offset) native "SVGTextContentElement_getExtentOfChar_Callback_unsigned long";

  static getNumberOfChars_Callback(mthis) native "SVGTextContentElement_getNumberOfChars_Callback";

  static getRotationOfChar_Callback_ul(mthis, offset) native "SVGTextContentElement_getRotationOfChar_Callback_unsigned long";

  static getStartPositionOfChar_Callback_ul(mthis, offset) native "SVGTextContentElement_getStartPositionOfChar_Callback_unsigned long";

  static getSubStringLength_Callback_ul_ul(mthis, offset, length) native "SVGTextContentElement_getSubStringLength_Callback_unsigned long_unsigned long";

  static selectSubString_Callback_ul_ul(mthis, offset, length) native "SVGTextContentElement_selectSubString_Callback_unsigned long_unsigned long";
}

class BlinkSVGTextPositioningElement {
  static dx_Getter(mthis) native "SVGTextPositioningElement_dx_Getter";

  static dy_Getter(mthis) native "SVGTextPositioningElement_dy_Getter";

  static rotate_Getter(mthis) native "SVGTextPositioningElement_rotate_Getter";

  static x_Getter(mthis) native "SVGTextPositioningElement_x_Getter";

  static y_Getter(mthis) native "SVGTextPositioningElement_y_Getter";
}

class BlinkSVGAltGlyphElement {
  static format_Getter(mthis) native "SVGAltGlyphElement_format_Getter";

  static format_Setter_DOMString(mthis, value) native "SVGAltGlyphElement_format_Setter";

  static glyphRef_Getter(mthis) native "SVGAltGlyphElement_glyphRef_Getter";

  static glyphRef_Setter_DOMString(mthis, value) native "SVGAltGlyphElement_glyphRef_Setter";

  static href_Getter(mthis) native "SVGAltGlyphElement_href_Getter";
}

class BlinkSVGAltGlyphItemElement {}

class BlinkSVGAngle {
  static unitType_Getter(mthis) native "SVGAngle_unitType_Getter";

  static value_Getter(mthis) native "SVGAngle_value_Getter";

  static value_Setter_float(mthis, value) native "SVGAngle_value_Setter";

  static valueAsString_Getter(mthis) native "SVGAngle_valueAsString_Getter";

  static valueAsString_Setter_DOMString(mthis, value) native "SVGAngle_valueAsString_Setter";

  static valueInSpecifiedUnits_Getter(mthis) native "SVGAngle_valueInSpecifiedUnits_Getter";

  static valueInSpecifiedUnits_Setter_float(mthis, value) native "SVGAngle_valueInSpecifiedUnits_Setter";

  static convertToSpecifiedUnits_Callback_us(mthis, unitType) native "SVGAngle_convertToSpecifiedUnits_Callback_unsigned short";

  static newValueSpecifiedUnits_Callback_us_float(mthis, unitType, valueInSpecifiedUnits) native "SVGAngle_newValueSpecifiedUnits_Callback_unsigned short_float";
}

class BlinkSVGAnimationElement {
  static targetElement_Getter(mthis) native "SVGAnimationElement_targetElement_Getter";

  static beginElement_Callback(mthis) native "SVGAnimationElement_beginElement_Callback";

  static beginElementAt_Callback_float(mthis, offset) native "SVGAnimationElement_beginElementAt_Callback_float";

  static endElement_Callback(mthis) native "SVGAnimationElement_endElement_Callback";

  static endElementAt_Callback_float(mthis, offset) native "SVGAnimationElement_endElementAt_Callback_float";

  static getCurrentTime_Callback(mthis) native "SVGAnimationElement_getCurrentTime_Callback";

  static getSimpleDuration_Callback(mthis) native "SVGAnimationElement_getSimpleDuration_Callback";

  static getStartTime_Callback(mthis) native "SVGAnimationElement_getStartTime_Callback";

  static requiredExtensions_Getter(mthis) native "SVGAnimationElement_requiredExtensions_Getter";

  static requiredFeatures_Getter(mthis) native "SVGAnimationElement_requiredFeatures_Getter";

  static systemLanguage_Getter(mthis) native "SVGAnimationElement_systemLanguage_Getter";

  static hasExtension_Callback_DOMString(mthis, extension) native "SVGAnimationElement_hasExtension_Callback_DOMString";
}

class BlinkSVGAnimateElement {}

class BlinkSVGAnimateMotionElement {}

class BlinkSVGAnimateTransformElement {}

class BlinkSVGAnimatedAngle {
  static animVal_Getter(mthis) native "SVGAnimatedAngle_animVal_Getter";

  static baseVal_Getter(mthis) native "SVGAnimatedAngle_baseVal_Getter";
}

class BlinkSVGAnimatedBoolean {
  static animVal_Getter(mthis) native "SVGAnimatedBoolean_animVal_Getter";

  static baseVal_Getter(mthis) native "SVGAnimatedBoolean_baseVal_Getter";

  static baseVal_Setter_boolean(mthis, value) native "SVGAnimatedBoolean_baseVal_Setter";
}

class BlinkSVGAnimatedEnumeration {
  static animVal_Getter(mthis) native "SVGAnimatedEnumeration_animVal_Getter";

  static baseVal_Getter(mthis) native "SVGAnimatedEnumeration_baseVal_Getter";

  static baseVal_Setter_us(mthis, value) native "SVGAnimatedEnumeration_baseVal_Setter";
}

class BlinkSVGAnimatedInteger {
  static animVal_Getter(mthis) native "SVGAnimatedInteger_animVal_Getter";

  static baseVal_Getter(mthis) native "SVGAnimatedInteger_baseVal_Getter";

  static baseVal_Setter_long(mthis, value) native "SVGAnimatedInteger_baseVal_Setter";
}

class BlinkSVGAnimatedLength {
  static animVal_Getter(mthis) native "SVGAnimatedLength_animVal_Getter";

  static baseVal_Getter(mthis) native "SVGAnimatedLength_baseVal_Getter";
}

class BlinkSVGAnimatedLengthList {
  static animVal_Getter(mthis) native "SVGAnimatedLengthList_animVal_Getter";

  static baseVal_Getter(mthis) native "SVGAnimatedLengthList_baseVal_Getter";
}

class BlinkSVGAnimatedNumber {
  static animVal_Getter(mthis) native "SVGAnimatedNumber_animVal_Getter";

  static baseVal_Getter(mthis) native "SVGAnimatedNumber_baseVal_Getter";

  static baseVal_Setter_float(mthis, value) native "SVGAnimatedNumber_baseVal_Setter";
}

class BlinkSVGAnimatedNumberList {
  static animVal_Getter(mthis) native "SVGAnimatedNumberList_animVal_Getter";

  static baseVal_Getter(mthis) native "SVGAnimatedNumberList_baseVal_Getter";
}

class BlinkSVGAnimatedPreserveAspectRatio {
  static animVal_Getter(mthis) native "SVGAnimatedPreserveAspectRatio_animVal_Getter";

  static baseVal_Getter(mthis) native "SVGAnimatedPreserveAspectRatio_baseVal_Getter";
}

class BlinkSVGAnimatedRect {
  static animVal_Getter(mthis) native "SVGAnimatedRect_animVal_Getter";

  static baseVal_Getter(mthis) native "SVGAnimatedRect_baseVal_Getter";
}

class BlinkSVGAnimatedString {
  static animVal_Getter(mthis) native "SVGAnimatedString_animVal_Getter";

  static baseVal_Getter(mthis) native "SVGAnimatedString_baseVal_Getter";

  static baseVal_Setter_DOMString(mthis, value) native "SVGAnimatedString_baseVal_Setter";
}

class BlinkSVGAnimatedTransformList {
  static animVal_Getter(mthis) native "SVGAnimatedTransformList_animVal_Getter";

  static baseVal_Getter(mthis) native "SVGAnimatedTransformList_baseVal_Getter";
}

class BlinkSVGGeometryElement {
  static isPointInFill_Callback_SVGPoint(mthis, point) native "SVGGeometryElement_isPointInFill_Callback_SVGPoint";

  static isPointInStroke_Callback_SVGPoint(mthis, point) native "SVGGeometryElement_isPointInStroke_Callback_SVGPoint";
}

class BlinkSVGCircleElement {
  static cx_Getter(mthis) native "SVGCircleElement_cx_Getter";

  static cy_Getter(mthis) native "SVGCircleElement_cy_Getter";

  static r_Getter(mthis) native "SVGCircleElement_r_Getter";
}

class BlinkSVGClipPathElement {
  static clipPathUnits_Getter(mthis) native "SVGClipPathElement_clipPathUnits_Getter";
}

class BlinkSVGComponentTransferFunctionElement {}

class BlinkSVGCursorElement {}

class BlinkSVGDefsElement {}

class BlinkSVGDescElement {}

class BlinkSVGDiscardElement {}

class BlinkSVGEllipseElement {
  static cx_Getter(mthis) native "SVGEllipseElement_cx_Getter";

  static cy_Getter(mthis) native "SVGEllipseElement_cy_Getter";

  static rx_Getter(mthis) native "SVGEllipseElement_rx_Getter";

  static ry_Getter(mthis) native "SVGEllipseElement_ry_Getter";
}

class BlinkSVGFilterPrimitiveStandardAttributes {
  static height_Getter(mthis) native "SVGFilterPrimitiveStandardAttributes_height_Getter";

  static result_Getter(mthis) native "SVGFilterPrimitiveStandardAttributes_result_Getter";

  static width_Getter(mthis) native "SVGFilterPrimitiveStandardAttributes_width_Getter";

  static x_Getter(mthis) native "SVGFilterPrimitiveStandardAttributes_x_Getter";

  static y_Getter(mthis) native "SVGFilterPrimitiveStandardAttributes_y_Getter";
}

class BlinkSVGFEBlendElement {
  static in1_Getter(mthis) native "SVGFEBlendElement_in1_Getter";

  static in2_Getter(mthis) native "SVGFEBlendElement_in2_Getter";

  static mode_Getter(mthis) native "SVGFEBlendElement_mode_Getter";

  static height_Getter(mthis) native "SVGFEBlendElement_height_Getter";

  static result_Getter(mthis) native "SVGFEBlendElement_result_Getter";

  static width_Getter(mthis) native "SVGFEBlendElement_width_Getter";

  static x_Getter(mthis) native "SVGFEBlendElement_x_Getter";

  static y_Getter(mthis) native "SVGFEBlendElement_y_Getter";
}

class BlinkSVGFEColorMatrixElement {
  static in1_Getter(mthis) native "SVGFEColorMatrixElement_in1_Getter";

  static type_Getter(mthis) native "SVGFEColorMatrixElement_type_Getter";

  static values_Getter(mthis) native "SVGFEColorMatrixElement_values_Getter";

  static height_Getter(mthis) native "SVGFEColorMatrixElement_height_Getter";

  static result_Getter(mthis) native "SVGFEColorMatrixElement_result_Getter";

  static width_Getter(mthis) native "SVGFEColorMatrixElement_width_Getter";

  static x_Getter(mthis) native "SVGFEColorMatrixElement_x_Getter";

  static y_Getter(mthis) native "SVGFEColorMatrixElement_y_Getter";
}

class BlinkSVGFEComponentTransferElement {
  static in1_Getter(mthis) native "SVGFEComponentTransferElement_in1_Getter";

  static height_Getter(mthis) native "SVGFEComponentTransferElement_height_Getter";

  static result_Getter(mthis) native "SVGFEComponentTransferElement_result_Getter";

  static width_Getter(mthis) native "SVGFEComponentTransferElement_width_Getter";

  static x_Getter(mthis) native "SVGFEComponentTransferElement_x_Getter";

  static y_Getter(mthis) native "SVGFEComponentTransferElement_y_Getter";
}

class BlinkSVGFECompositeElement {
  static in1_Getter(mthis) native "SVGFECompositeElement_in1_Getter";

  static in2_Getter(mthis) native "SVGFECompositeElement_in2_Getter";

  static k1_Getter(mthis) native "SVGFECompositeElement_k1_Getter";

  static k2_Getter(mthis) native "SVGFECompositeElement_k2_Getter";

  static k3_Getter(mthis) native "SVGFECompositeElement_k3_Getter";

  static k4_Getter(mthis) native "SVGFECompositeElement_k4_Getter";

  static operator_Getter(mthis) native "SVGFECompositeElement_operator_Getter";

  static height_Getter(mthis) native "SVGFECompositeElement_height_Getter";

  static result_Getter(mthis) native "SVGFECompositeElement_result_Getter";

  static width_Getter(mthis) native "SVGFECompositeElement_width_Getter";

  static x_Getter(mthis) native "SVGFECompositeElement_x_Getter";

  static y_Getter(mthis) native "SVGFECompositeElement_y_Getter";
}

class BlinkSVGFEConvolveMatrixElement {
  static bias_Getter(mthis) native "SVGFEConvolveMatrixElement_bias_Getter";

  static divisor_Getter(mthis) native "SVGFEConvolveMatrixElement_divisor_Getter";

  static edgeMode_Getter(mthis) native "SVGFEConvolveMatrixElement_edgeMode_Getter";

  static in1_Getter(mthis) native "SVGFEConvolveMatrixElement_in1_Getter";

  static kernelMatrix_Getter(mthis) native "SVGFEConvolveMatrixElement_kernelMatrix_Getter";

  static kernelUnitLengthX_Getter(mthis) native "SVGFEConvolveMatrixElement_kernelUnitLengthX_Getter";

  static kernelUnitLengthY_Getter(mthis) native "SVGFEConvolveMatrixElement_kernelUnitLengthY_Getter";

  static orderX_Getter(mthis) native "SVGFEConvolveMatrixElement_orderX_Getter";

  static orderY_Getter(mthis) native "SVGFEConvolveMatrixElement_orderY_Getter";

  static preserveAlpha_Getter(mthis) native "SVGFEConvolveMatrixElement_preserveAlpha_Getter";

  static targetX_Getter(mthis) native "SVGFEConvolveMatrixElement_targetX_Getter";

  static targetY_Getter(mthis) native "SVGFEConvolveMatrixElement_targetY_Getter";

  static height_Getter(mthis) native "SVGFEConvolveMatrixElement_height_Getter";

  static result_Getter(mthis) native "SVGFEConvolveMatrixElement_result_Getter";

  static width_Getter(mthis) native "SVGFEConvolveMatrixElement_width_Getter";

  static x_Getter(mthis) native "SVGFEConvolveMatrixElement_x_Getter";

  static y_Getter(mthis) native "SVGFEConvolveMatrixElement_y_Getter";
}

class BlinkSVGFEDiffuseLightingElement {
  static diffuseConstant_Getter(mthis) native "SVGFEDiffuseLightingElement_diffuseConstant_Getter";

  static in1_Getter(mthis) native "SVGFEDiffuseLightingElement_in1_Getter";

  static kernelUnitLengthX_Getter(mthis) native "SVGFEDiffuseLightingElement_kernelUnitLengthX_Getter";

  static kernelUnitLengthY_Getter(mthis) native "SVGFEDiffuseLightingElement_kernelUnitLengthY_Getter";

  static surfaceScale_Getter(mthis) native "SVGFEDiffuseLightingElement_surfaceScale_Getter";

  static height_Getter(mthis) native "SVGFEDiffuseLightingElement_height_Getter";

  static result_Getter(mthis) native "SVGFEDiffuseLightingElement_result_Getter";

  static width_Getter(mthis) native "SVGFEDiffuseLightingElement_width_Getter";

  static x_Getter(mthis) native "SVGFEDiffuseLightingElement_x_Getter";

  static y_Getter(mthis) native "SVGFEDiffuseLightingElement_y_Getter";
}

class BlinkSVGFEDisplacementMapElement {
  static in1_Getter(mthis) native "SVGFEDisplacementMapElement_in1_Getter";

  static in2_Getter(mthis) native "SVGFEDisplacementMapElement_in2_Getter";

  static scale_Getter(mthis) native "SVGFEDisplacementMapElement_scale_Getter";

  static xChannelSelector_Getter(mthis) native "SVGFEDisplacementMapElement_xChannelSelector_Getter";

  static yChannelSelector_Getter(mthis) native "SVGFEDisplacementMapElement_yChannelSelector_Getter";

  static height_Getter(mthis) native "SVGFEDisplacementMapElement_height_Getter";

  static result_Getter(mthis) native "SVGFEDisplacementMapElement_result_Getter";

  static width_Getter(mthis) native "SVGFEDisplacementMapElement_width_Getter";

  static x_Getter(mthis) native "SVGFEDisplacementMapElement_x_Getter";

  static y_Getter(mthis) native "SVGFEDisplacementMapElement_y_Getter";
}

class BlinkSVGFEDistantLightElement {
  static azimuth_Getter(mthis) native "SVGFEDistantLightElement_azimuth_Getter";

  static elevation_Getter(mthis) native "SVGFEDistantLightElement_elevation_Getter";
}

class BlinkSVGFEDropShadowElement {}

class BlinkSVGFEFloodElement {
  static height_Getter(mthis) native "SVGFEFloodElement_height_Getter";

  static result_Getter(mthis) native "SVGFEFloodElement_result_Getter";

  static width_Getter(mthis) native "SVGFEFloodElement_width_Getter";

  static x_Getter(mthis) native "SVGFEFloodElement_x_Getter";

  static y_Getter(mthis) native "SVGFEFloodElement_y_Getter";
}

class BlinkSVGFEFuncAElement {}

class BlinkSVGFEFuncBElement {}

class BlinkSVGFEFuncGElement {}

class BlinkSVGFEFuncRElement {}

class BlinkSVGFEGaussianBlurElement {
  static in1_Getter(mthis) native "SVGFEGaussianBlurElement_in1_Getter";

  static stdDeviationX_Getter(mthis) native "SVGFEGaussianBlurElement_stdDeviationX_Getter";

  static stdDeviationY_Getter(mthis) native "SVGFEGaussianBlurElement_stdDeviationY_Getter";

  static setStdDeviation_Callback_float_float(mthis, stdDeviationX, stdDeviationY) native "SVGFEGaussianBlurElement_setStdDeviation_Callback_float_float";

  static height_Getter(mthis) native "SVGFEGaussianBlurElement_height_Getter";

  static result_Getter(mthis) native "SVGFEGaussianBlurElement_result_Getter";

  static width_Getter(mthis) native "SVGFEGaussianBlurElement_width_Getter";

  static x_Getter(mthis) native "SVGFEGaussianBlurElement_x_Getter";

  static y_Getter(mthis) native "SVGFEGaussianBlurElement_y_Getter";
}

class BlinkSVGFEImageElement {
  static preserveAspectRatio_Getter(mthis) native "SVGFEImageElement_preserveAspectRatio_Getter";

  static height_Getter(mthis) native "SVGFEImageElement_height_Getter";

  static result_Getter(mthis) native "SVGFEImageElement_result_Getter";

  static width_Getter(mthis) native "SVGFEImageElement_width_Getter";

  static x_Getter(mthis) native "SVGFEImageElement_x_Getter";

  static y_Getter(mthis) native "SVGFEImageElement_y_Getter";

  static href_Getter(mthis) native "SVGFEImageElement_href_Getter";
}

class BlinkSVGFEMergeElement {
  static height_Getter(mthis) native "SVGFEMergeElement_height_Getter";

  static result_Getter(mthis) native "SVGFEMergeElement_result_Getter";

  static width_Getter(mthis) native "SVGFEMergeElement_width_Getter";

  static x_Getter(mthis) native "SVGFEMergeElement_x_Getter";

  static y_Getter(mthis) native "SVGFEMergeElement_y_Getter";
}

class BlinkSVGFEMergeNodeElement {
  static in1_Getter(mthis) native "SVGFEMergeNodeElement_in1_Getter";
}

class BlinkSVGFEMorphologyElement {
  static in1_Getter(mthis) native "SVGFEMorphologyElement_in1_Getter";

  static operator_Getter(mthis) native "SVGFEMorphologyElement_operator_Getter";

  static radiusX_Getter(mthis) native "SVGFEMorphologyElement_radiusX_Getter";

  static radiusY_Getter(mthis) native "SVGFEMorphologyElement_radiusY_Getter";

  static setRadius_Callback_float_float(mthis, radiusX, radiusY) native "SVGFEMorphologyElement_setRadius_Callback_float_float";

  static height_Getter(mthis) native "SVGFEMorphologyElement_height_Getter";

  static result_Getter(mthis) native "SVGFEMorphologyElement_result_Getter";

  static width_Getter(mthis) native "SVGFEMorphologyElement_width_Getter";

  static x_Getter(mthis) native "SVGFEMorphologyElement_x_Getter";

  static y_Getter(mthis) native "SVGFEMorphologyElement_y_Getter";
}

class BlinkSVGFEOffsetElement {
  static dx_Getter(mthis) native "SVGFEOffsetElement_dx_Getter";

  static dy_Getter(mthis) native "SVGFEOffsetElement_dy_Getter";

  static in1_Getter(mthis) native "SVGFEOffsetElement_in1_Getter";

  static height_Getter(mthis) native "SVGFEOffsetElement_height_Getter";

  static result_Getter(mthis) native "SVGFEOffsetElement_result_Getter";

  static width_Getter(mthis) native "SVGFEOffsetElement_width_Getter";

  static x_Getter(mthis) native "SVGFEOffsetElement_x_Getter";

  static y_Getter(mthis) native "SVGFEOffsetElement_y_Getter";
}

class BlinkSVGFEPointLightElement {
  static x_Getter(mthis) native "SVGFEPointLightElement_x_Getter";

  static y_Getter(mthis) native "SVGFEPointLightElement_y_Getter";

  static z_Getter(mthis) native "SVGFEPointLightElement_z_Getter";
}

class BlinkSVGFESpecularLightingElement {
  static in1_Getter(mthis) native "SVGFESpecularLightingElement_in1_Getter";

  static specularConstant_Getter(mthis) native "SVGFESpecularLightingElement_specularConstant_Getter";

  static specularExponent_Getter(mthis) native "SVGFESpecularLightingElement_specularExponent_Getter";

  static surfaceScale_Getter(mthis) native "SVGFESpecularLightingElement_surfaceScale_Getter";

  static height_Getter(mthis) native "SVGFESpecularLightingElement_height_Getter";

  static result_Getter(mthis) native "SVGFESpecularLightingElement_result_Getter";

  static width_Getter(mthis) native "SVGFESpecularLightingElement_width_Getter";

  static x_Getter(mthis) native "SVGFESpecularLightingElement_x_Getter";

  static y_Getter(mthis) native "SVGFESpecularLightingElement_y_Getter";
}

class BlinkSVGFESpotLightElement {
  static limitingConeAngle_Getter(mthis) native "SVGFESpotLightElement_limitingConeAngle_Getter";

  static pointsAtX_Getter(mthis) native "SVGFESpotLightElement_pointsAtX_Getter";

  static pointsAtY_Getter(mthis) native "SVGFESpotLightElement_pointsAtY_Getter";

  static pointsAtZ_Getter(mthis) native "SVGFESpotLightElement_pointsAtZ_Getter";

  static specularExponent_Getter(mthis) native "SVGFESpotLightElement_specularExponent_Getter";

  static x_Getter(mthis) native "SVGFESpotLightElement_x_Getter";

  static y_Getter(mthis) native "SVGFESpotLightElement_y_Getter";

  static z_Getter(mthis) native "SVGFESpotLightElement_z_Getter";
}

class BlinkSVGFETileElement {
  static in1_Getter(mthis) native "SVGFETileElement_in1_Getter";

  static height_Getter(mthis) native "SVGFETileElement_height_Getter";

  static result_Getter(mthis) native "SVGFETileElement_result_Getter";

  static width_Getter(mthis) native "SVGFETileElement_width_Getter";

  static x_Getter(mthis) native "SVGFETileElement_x_Getter";

  static y_Getter(mthis) native "SVGFETileElement_y_Getter";
}

class BlinkSVGFETurbulenceElement {
  static baseFrequencyX_Getter(mthis) native "SVGFETurbulenceElement_baseFrequencyX_Getter";

  static baseFrequencyY_Getter(mthis) native "SVGFETurbulenceElement_baseFrequencyY_Getter";

  static numOctaves_Getter(mthis) native "SVGFETurbulenceElement_numOctaves_Getter";

  static seed_Getter(mthis) native "SVGFETurbulenceElement_seed_Getter";

  static stitchTiles_Getter(mthis) native "SVGFETurbulenceElement_stitchTiles_Getter";

  static type_Getter(mthis) native "SVGFETurbulenceElement_type_Getter";

  static height_Getter(mthis) native "SVGFETurbulenceElement_height_Getter";

  static result_Getter(mthis) native "SVGFETurbulenceElement_result_Getter";

  static width_Getter(mthis) native "SVGFETurbulenceElement_width_Getter";

  static x_Getter(mthis) native "SVGFETurbulenceElement_x_Getter";

  static y_Getter(mthis) native "SVGFETurbulenceElement_y_Getter";
}

class BlinkSVGFilterElement {
  static filterResX_Getter(mthis) native "SVGFilterElement_filterResX_Getter";

  static filterResY_Getter(mthis) native "SVGFilterElement_filterResY_Getter";

  static filterUnits_Getter(mthis) native "SVGFilterElement_filterUnits_Getter";

  static height_Getter(mthis) native "SVGFilterElement_height_Getter";

  static primitiveUnits_Getter(mthis) native "SVGFilterElement_primitiveUnits_Getter";

  static width_Getter(mthis) native "SVGFilterElement_width_Getter";

  static x_Getter(mthis) native "SVGFilterElement_x_Getter";

  static y_Getter(mthis) native "SVGFilterElement_y_Getter";

  static setFilterRes_Callback_ul_ul(mthis, filterResX, filterResY) native "SVGFilterElement_setFilterRes_Callback_unsigned long_unsigned long";

  static href_Getter(mthis) native "SVGFilterElement_href_Getter";
}

class BlinkSVGFitToViewBox {
  static preserveAspectRatio_Getter(mthis) native "SVGFitToViewBox_preserveAspectRatio_Getter";

  static viewBox_Getter(mthis) native "SVGFitToViewBox_viewBox_Getter";
}

class BlinkSVGFontElement {}

class BlinkSVGFontFaceElement {}

class BlinkSVGFontFaceFormatElement {}

class BlinkSVGFontFaceNameElement {}

class BlinkSVGFontFaceSrcElement {}

class BlinkSVGFontFaceUriElement {}

class BlinkSVGForeignObjectElement {
  static height_Getter(mthis) native "SVGForeignObjectElement_height_Getter";

  static width_Getter(mthis) native "SVGForeignObjectElement_width_Getter";

  static x_Getter(mthis) native "SVGForeignObjectElement_x_Getter";

  static y_Getter(mthis) native "SVGForeignObjectElement_y_Getter";
}

class BlinkSVGGElement {}

class BlinkSVGGlyphElement {}

class BlinkSVGGlyphRefElement {}

class BlinkSVGGradientElement {
  static gradientTransform_Getter(mthis) native "SVGGradientElement_gradientTransform_Getter";

  static gradientUnits_Getter(mthis) native "SVGGradientElement_gradientUnits_Getter";

  static spreadMethod_Getter(mthis) native "SVGGradientElement_spreadMethod_Getter";

  static href_Getter(mthis) native "SVGGradientElement_href_Getter";
}

class BlinkSVGHKernElement {}

class BlinkSVGImageElement {
  static height_Getter(mthis) native "SVGImageElement_height_Getter";

  static preserveAspectRatio_Getter(mthis) native "SVGImageElement_preserveAspectRatio_Getter";

  static width_Getter(mthis) native "SVGImageElement_width_Getter";

  static x_Getter(mthis) native "SVGImageElement_x_Getter";

  static y_Getter(mthis) native "SVGImageElement_y_Getter";

  static href_Getter(mthis) native "SVGImageElement_href_Getter";
}

class BlinkSVGLength {
  static unitType_Getter(mthis) native "SVGLength_unitType_Getter";

  static value_Getter(mthis) native "SVGLength_value_Getter";

  static value_Setter_float(mthis, value) native "SVGLength_value_Setter";

  static valueAsString_Getter(mthis) native "SVGLength_valueAsString_Getter";

  static valueAsString_Setter_DOMString(mthis, value) native "SVGLength_valueAsString_Setter";

  static valueInSpecifiedUnits_Getter(mthis) native "SVGLength_valueInSpecifiedUnits_Getter";

  static valueInSpecifiedUnits_Setter_float(mthis, value) native "SVGLength_valueInSpecifiedUnits_Setter";

  static convertToSpecifiedUnits_Callback_us(mthis, unitType) native "SVGLength_convertToSpecifiedUnits_Callback_unsigned short";

  static newValueSpecifiedUnits_Callback_us_float(mthis, unitType, valueInSpecifiedUnits) native "SVGLength_newValueSpecifiedUnits_Callback_unsigned short_float";
}

class BlinkSVGLengthList {
  static length_Getter(mthis) native "SVGLengthList_length_Getter";

  static numberOfItems_Getter(mthis) native "SVGLengthList_numberOfItems_Getter";

  static $__setter___Callback_ul_SVGLength(mthis, index, value) native "SVGLengthList___setter___Callback_unsigned long_SVGLength";

  static appendItem_Callback_SVGLength(mthis, item) native "SVGLengthList_appendItem_Callback_SVGLength";

  static clear_Callback(mthis) native "SVGLengthList_clear_Callback";

  static getItem_Callback_ul(mthis, index) native "SVGLengthList_getItem_Callback_unsigned long";

  static initialize_Callback_SVGLength(mthis, item) native "SVGLengthList_initialize_Callback_SVGLength";

  static insertItemBefore_Callback_SVGLength_ul(mthis, item, index) native "SVGLengthList_insertItemBefore_Callback_SVGLength_unsigned long";

  static removeItem_Callback_ul(mthis, index) native "SVGLengthList_removeItem_Callback_unsigned long";

  static replaceItem_Callback_SVGLength_ul(mthis, item, index) native "SVGLengthList_replaceItem_Callback_SVGLength_unsigned long";
}

class BlinkSVGLineElement {
  static x1_Getter(mthis) native "SVGLineElement_x1_Getter";

  static x2_Getter(mthis) native "SVGLineElement_x2_Getter";

  static y1_Getter(mthis) native "SVGLineElement_y1_Getter";

  static y2_Getter(mthis) native "SVGLineElement_y2_Getter";
}

class BlinkSVGLinearGradientElement {
  static x1_Getter(mthis) native "SVGLinearGradientElement_x1_Getter";

  static x2_Getter(mthis) native "SVGLinearGradientElement_x2_Getter";

  static y1_Getter(mthis) native "SVGLinearGradientElement_y1_Getter";

  static y2_Getter(mthis) native "SVGLinearGradientElement_y2_Getter";
}

class BlinkSVGMPathElement {}

class BlinkSVGMarkerElement {
  static markerHeight_Getter(mthis) native "SVGMarkerElement_markerHeight_Getter";

  static markerUnits_Getter(mthis) native "SVGMarkerElement_markerUnits_Getter";

  static markerWidth_Getter(mthis) native "SVGMarkerElement_markerWidth_Getter";

  static orientAngle_Getter(mthis) native "SVGMarkerElement_orientAngle_Getter";

  static orientType_Getter(mthis) native "SVGMarkerElement_orientType_Getter";

  static refX_Getter(mthis) native "SVGMarkerElement_refX_Getter";

  static refY_Getter(mthis) native "SVGMarkerElement_refY_Getter";

  static setOrientToAngle_Callback_SVGAngle(mthis, angle) native "SVGMarkerElement_setOrientToAngle_Callback_SVGAngle";

  static setOrientToAuto_Callback(mthis) native "SVGMarkerElement_setOrientToAuto_Callback";

  static preserveAspectRatio_Getter(mthis) native "SVGMarkerElement_preserveAspectRatio_Getter";

  static viewBox_Getter(mthis) native "SVGMarkerElement_viewBox_Getter";
}

class BlinkSVGMaskElement {
  static height_Getter(mthis) native "SVGMaskElement_height_Getter";

  static maskContentUnits_Getter(mthis) native "SVGMaskElement_maskContentUnits_Getter";

  static maskUnits_Getter(mthis) native "SVGMaskElement_maskUnits_Getter";

  static width_Getter(mthis) native "SVGMaskElement_width_Getter";

  static x_Getter(mthis) native "SVGMaskElement_x_Getter";

  static y_Getter(mthis) native "SVGMaskElement_y_Getter";

  static requiredExtensions_Getter(mthis) native "SVGMaskElement_requiredExtensions_Getter";

  static requiredFeatures_Getter(mthis) native "SVGMaskElement_requiredFeatures_Getter";

  static systemLanguage_Getter(mthis) native "SVGMaskElement_systemLanguage_Getter";

  static hasExtension_Callback_DOMString(mthis, extension) native "SVGMaskElement_hasExtension_Callback_DOMString";
}

class BlinkSVGMatrix {
  static a_Getter(mthis) native "SVGMatrix_a_Getter";

  static a_Setter_double(mthis, value) native "SVGMatrix_a_Setter";

  static b_Getter(mthis) native "SVGMatrix_b_Getter";

  static b_Setter_double(mthis, value) native "SVGMatrix_b_Setter";

  static c_Getter(mthis) native "SVGMatrix_c_Getter";

  static c_Setter_double(mthis, value) native "SVGMatrix_c_Setter";

  static d_Getter(mthis) native "SVGMatrix_d_Getter";

  static d_Setter_double(mthis, value) native "SVGMatrix_d_Setter";

  static e_Getter(mthis) native "SVGMatrix_e_Getter";

  static e_Setter_double(mthis, value) native "SVGMatrix_e_Setter";

  static f_Getter(mthis) native "SVGMatrix_f_Getter";

  static f_Setter_double(mthis, value) native "SVGMatrix_f_Setter";

  static flipX_Callback(mthis) native "SVGMatrix_flipX_Callback";

  static flipY_Callback(mthis) native "SVGMatrix_flipY_Callback";

  static inverse_Callback(mthis) native "SVGMatrix_inverse_Callback";

  static multiply_Callback_SVGMatrix(mthis, secondMatrix) native "SVGMatrix_multiply_Callback_SVGMatrix";

  static rotate_Callback_float(mthis, angle) native "SVGMatrix_rotate_Callback_float";

  static rotateFromVector_Callback_float_float(mthis, x, y) native "SVGMatrix_rotateFromVector_Callback_float_float";

  static scale_Callback_float(mthis, scaleFactor) native "SVGMatrix_scale_Callback_float";

  static scaleNonUniform_Callback_float_float(mthis, scaleFactorX, scaleFactorY) native "SVGMatrix_scaleNonUniform_Callback_float_float";

  static skewX_Callback_float(mthis, angle) native "SVGMatrix_skewX_Callback_float";

  static skewY_Callback_float(mthis, angle) native "SVGMatrix_skewY_Callback_float";

  static translate_Callback_float_float(mthis, x, y) native "SVGMatrix_translate_Callback_float_float";
}

class BlinkSVGMetadataElement {}

class BlinkSVGMissingGlyphElement {}

class BlinkSVGNumber {
  static value_Getter(mthis) native "SVGNumber_value_Getter";

  static value_Setter_float(mthis, value) native "SVGNumber_value_Setter";
}

class BlinkSVGNumberList {
  static length_Getter(mthis) native "SVGNumberList_length_Getter";

  static numberOfItems_Getter(mthis) native "SVGNumberList_numberOfItems_Getter";

  static $__setter___Callback_ul_SVGNumber(mthis, index, value) native "SVGNumberList___setter___Callback_unsigned long_SVGNumber";

  static appendItem_Callback_SVGNumber(mthis, item) native "SVGNumberList_appendItem_Callback_SVGNumber";

  static clear_Callback(mthis) native "SVGNumberList_clear_Callback";

  static getItem_Callback_ul(mthis, index) native "SVGNumberList_getItem_Callback_unsigned long";

  static initialize_Callback_SVGNumber(mthis, item) native "SVGNumberList_initialize_Callback_SVGNumber";

  static insertItemBefore_Callback_SVGNumber_ul(mthis, item, index) native "SVGNumberList_insertItemBefore_Callback_SVGNumber_unsigned long";

  static removeItem_Callback_ul(mthis, index) native "SVGNumberList_removeItem_Callback_unsigned long";

  static replaceItem_Callback_SVGNumber_ul(mthis, item, index) native "SVGNumberList_replaceItem_Callback_SVGNumber_unsigned long";
}

class BlinkSVGPathElement {
  static animatedNormalizedPathSegList_Getter(mthis) native "SVGPathElement_animatedNormalizedPathSegList_Getter";

  static animatedPathSegList_Getter(mthis) native "SVGPathElement_animatedPathSegList_Getter";

  static normalizedPathSegList_Getter(mthis) native "SVGPathElement_normalizedPathSegList_Getter";

  static pathLength_Getter(mthis) native "SVGPathElement_pathLength_Getter";

  static pathSegList_Getter(mthis) native "SVGPathElement_pathSegList_Getter";

  static createSVGPathSegArcAbs_Callback_float_float_float_float_float_boolean_boolean(mthis, x, y, r1, r2, angle, largeArcFlag, sweepFlag) native "SVGPathElement_createSVGPathSegArcAbs_Callback_float_float_float_float_float_boolean_boolean";

  static createSVGPathSegArcRel_Callback_float_float_float_float_float_boolean_boolean(mthis, x, y, r1, r2, angle, largeArcFlag, sweepFlag) native "SVGPathElement_createSVGPathSegArcRel_Callback_float_float_float_float_float_boolean_boolean";

  static createSVGPathSegClosePath_Callback(mthis) native "SVGPathElement_createSVGPathSegClosePath_Callback";

  static createSVGPathSegCurvetoCubicAbs_Callback_float_float_float_float_float_float(mthis, x, y, x1, y1, x2, y2) native "SVGPathElement_createSVGPathSegCurvetoCubicAbs_Callback_float_float_float_float_float_float";

  static createSVGPathSegCurvetoCubicRel_Callback_float_float_float_float_float_float(mthis, x, y, x1, y1, x2, y2) native "SVGPathElement_createSVGPathSegCurvetoCubicRel_Callback_float_float_float_float_float_float";

  static createSVGPathSegCurvetoCubicSmoothAbs_Callback_float_float_float_float(mthis, x, y, x2, y2) native "SVGPathElement_createSVGPathSegCurvetoCubicSmoothAbs_Callback_float_float_float_float";

  static createSVGPathSegCurvetoCubicSmoothRel_Callback_float_float_float_float(mthis, x, y, x2, y2) native "SVGPathElement_createSVGPathSegCurvetoCubicSmoothRel_Callback_float_float_float_float";

  static createSVGPathSegCurvetoQuadraticAbs_Callback_float_float_float_float(mthis, x, y, x1, y1) native "SVGPathElement_createSVGPathSegCurvetoQuadraticAbs_Callback_float_float_float_float";

  static createSVGPathSegCurvetoQuadraticRel_Callback_float_float_float_float(mthis, x, y, x1, y1) native "SVGPathElement_createSVGPathSegCurvetoQuadraticRel_Callback_float_float_float_float";

  static createSVGPathSegCurvetoQuadraticSmoothAbs_Callback_float_float(mthis, x, y) native "SVGPathElement_createSVGPathSegCurvetoQuadraticSmoothAbs_Callback_float_float";

  static createSVGPathSegCurvetoQuadraticSmoothRel_Callback_float_float(mthis, x, y) native "SVGPathElement_createSVGPathSegCurvetoQuadraticSmoothRel_Callback_float_float";

  static createSVGPathSegLinetoAbs_Callback_float_float(mthis, x, y) native "SVGPathElement_createSVGPathSegLinetoAbs_Callback_float_float";

  static createSVGPathSegLinetoHorizontalAbs_Callback_float(mthis, x) native "SVGPathElement_createSVGPathSegLinetoHorizontalAbs_Callback_float";

  static createSVGPathSegLinetoHorizontalRel_Callback_float(mthis, x) native "SVGPathElement_createSVGPathSegLinetoHorizontalRel_Callback_float";

  static createSVGPathSegLinetoRel_Callback_float_float(mthis, x, y) native "SVGPathElement_createSVGPathSegLinetoRel_Callback_float_float";

  static createSVGPathSegLinetoVerticalAbs_Callback_float(mthis, y) native "SVGPathElement_createSVGPathSegLinetoVerticalAbs_Callback_float";

  static createSVGPathSegLinetoVerticalRel_Callback_float(mthis, y) native "SVGPathElement_createSVGPathSegLinetoVerticalRel_Callback_float";

  static createSVGPathSegMovetoAbs_Callback_float_float(mthis, x, y) native "SVGPathElement_createSVGPathSegMovetoAbs_Callback_float_float";

  static createSVGPathSegMovetoRel_Callback_float_float(mthis, x, y) native "SVGPathElement_createSVGPathSegMovetoRel_Callback_float_float";

  static getPathSegAtLength_Callback_float(mthis, distance) native "SVGPathElement_getPathSegAtLength_Callback_float";

  static getPointAtLength_Callback_float(mthis, distance) native "SVGPathElement_getPointAtLength_Callback_float";

  static getTotalLength_Callback(mthis) native "SVGPathElement_getTotalLength_Callback";
}

class BlinkSVGPathSeg {
  static pathSegType_Getter(mthis) native "SVGPathSeg_pathSegType_Getter";

  static pathSegTypeAsLetter_Getter(mthis) native "SVGPathSeg_pathSegTypeAsLetter_Getter";
}

class BlinkSVGPathSegArcAbs {
  static angle_Getter(mthis) native "SVGPathSegArcAbs_angle_Getter";

  static angle_Setter_float(mthis, value) native "SVGPathSegArcAbs_angle_Setter";

  static largeArcFlag_Getter(mthis) native "SVGPathSegArcAbs_largeArcFlag_Getter";

  static largeArcFlag_Setter_boolean(mthis, value) native "SVGPathSegArcAbs_largeArcFlag_Setter";

  static r1_Getter(mthis) native "SVGPathSegArcAbs_r1_Getter";

  static r1_Setter_float(mthis, value) native "SVGPathSegArcAbs_r1_Setter";

  static r2_Getter(mthis) native "SVGPathSegArcAbs_r2_Getter";

  static r2_Setter_float(mthis, value) native "SVGPathSegArcAbs_r2_Setter";

  static sweepFlag_Getter(mthis) native "SVGPathSegArcAbs_sweepFlag_Getter";

  static sweepFlag_Setter_boolean(mthis, value) native "SVGPathSegArcAbs_sweepFlag_Setter";

  static x_Getter(mthis) native "SVGPathSegArcAbs_x_Getter";

  static x_Setter_float(mthis, value) native "SVGPathSegArcAbs_x_Setter";

  static y_Getter(mthis) native "SVGPathSegArcAbs_y_Getter";

  static y_Setter_float(mthis, value) native "SVGPathSegArcAbs_y_Setter";
}

class BlinkSVGPathSegArcRel {
  static angle_Getter(mthis) native "SVGPathSegArcRel_angle_Getter";

  static angle_Setter_float(mthis, value) native "SVGPathSegArcRel_angle_Setter";

  static largeArcFlag_Getter(mthis) native "SVGPathSegArcRel_largeArcFlag_Getter";

  static largeArcFlag_Setter_boolean(mthis, value) native "SVGPathSegArcRel_largeArcFlag_Setter";

  static r1_Getter(mthis) native "SVGPathSegArcRel_r1_Getter";

  static r1_Setter_float(mthis, value) native "SVGPathSegArcRel_r1_Setter";

  static r2_Getter(mthis) native "SVGPathSegArcRel_r2_Getter";

  static r2_Setter_float(mthis, value) native "SVGPathSegArcRel_r2_Setter";

  static sweepFlag_Getter(mthis) native "SVGPathSegArcRel_sweepFlag_Getter";

  static sweepFlag_Setter_boolean(mthis, value) native "SVGPathSegArcRel_sweepFlag_Setter";

  static x_Getter(mthis) native "SVGPathSegArcRel_x_Getter";

  static x_Setter_float(mthis, value) native "SVGPathSegArcRel_x_Setter";

  static y_Getter(mthis) native "SVGPathSegArcRel_y_Getter";

  static y_Setter_float(mthis, value) native "SVGPathSegArcRel_y_Setter";
}

class BlinkSVGPathSegClosePath {}

class BlinkSVGPathSegCurvetoCubicAbs {
  static x_Getter(mthis) native "SVGPathSegCurvetoCubicAbs_x_Getter";

  static x_Setter_float(mthis, value) native "SVGPathSegCurvetoCubicAbs_x_Setter";

  static x1_Getter(mthis) native "SVGPathSegCurvetoCubicAbs_x1_Getter";

  static x1_Setter_float(mthis, value) native "SVGPathSegCurvetoCubicAbs_x1_Setter";

  static x2_Getter(mthis) native "SVGPathSegCurvetoCubicAbs_x2_Getter";

  static x2_Setter_float(mthis, value) native "SVGPathSegCurvetoCubicAbs_x2_Setter";

  static y_Getter(mthis) native "SVGPathSegCurvetoCubicAbs_y_Getter";

  static y_Setter_float(mthis, value) native "SVGPathSegCurvetoCubicAbs_y_Setter";

  static y1_Getter(mthis) native "SVGPathSegCurvetoCubicAbs_y1_Getter";

  static y1_Setter_float(mthis, value) native "SVGPathSegCurvetoCubicAbs_y1_Setter";

  static y2_Getter(mthis) native "SVGPathSegCurvetoCubicAbs_y2_Getter";

  static y2_Setter_float(mthis, value) native "SVGPathSegCurvetoCubicAbs_y2_Setter";
}

class BlinkSVGPathSegCurvetoCubicRel {
  static x_Getter(mthis) native "SVGPathSegCurvetoCubicRel_x_Getter";

  static x_Setter_float(mthis, value) native "SVGPathSegCurvetoCubicRel_x_Setter";

  static x1_Getter(mthis) native "SVGPathSegCurvetoCubicRel_x1_Getter";

  static x1_Setter_float(mthis, value) native "SVGPathSegCurvetoCubicRel_x1_Setter";

  static x2_Getter(mthis) native "SVGPathSegCurvetoCubicRel_x2_Getter";

  static x2_Setter_float(mthis, value) native "SVGPathSegCurvetoCubicRel_x2_Setter";

  static y_Getter(mthis) native "SVGPathSegCurvetoCubicRel_y_Getter";

  static y_Setter_float(mthis, value) native "SVGPathSegCurvetoCubicRel_y_Setter";

  static y1_Getter(mthis) native "SVGPathSegCurvetoCubicRel_y1_Getter";

  static y1_Setter_float(mthis, value) native "SVGPathSegCurvetoCubicRel_y1_Setter";

  static y2_Getter(mthis) native "SVGPathSegCurvetoCubicRel_y2_Getter";

  static y2_Setter_float(mthis, value) native "SVGPathSegCurvetoCubicRel_y2_Setter";
}

class BlinkSVGPathSegCurvetoCubicSmoothAbs {
  static x_Getter(mthis) native "SVGPathSegCurvetoCubicSmoothAbs_x_Getter";

  static x_Setter_float(mthis, value) native "SVGPathSegCurvetoCubicSmoothAbs_x_Setter";

  static x2_Getter(mthis) native "SVGPathSegCurvetoCubicSmoothAbs_x2_Getter";

  static x2_Setter_float(mthis, value) native "SVGPathSegCurvetoCubicSmoothAbs_x2_Setter";

  static y_Getter(mthis) native "SVGPathSegCurvetoCubicSmoothAbs_y_Getter";

  static y_Setter_float(mthis, value) native "SVGPathSegCurvetoCubicSmoothAbs_y_Setter";

  static y2_Getter(mthis) native "SVGPathSegCurvetoCubicSmoothAbs_y2_Getter";

  static y2_Setter_float(mthis, value) native "SVGPathSegCurvetoCubicSmoothAbs_y2_Setter";
}

class BlinkSVGPathSegCurvetoCubicSmoothRel {
  static x_Getter(mthis) native "SVGPathSegCurvetoCubicSmoothRel_x_Getter";

  static x_Setter_float(mthis, value) native "SVGPathSegCurvetoCubicSmoothRel_x_Setter";

  static x2_Getter(mthis) native "SVGPathSegCurvetoCubicSmoothRel_x2_Getter";

  static x2_Setter_float(mthis, value) native "SVGPathSegCurvetoCubicSmoothRel_x2_Setter";

  static y_Getter(mthis) native "SVGPathSegCurvetoCubicSmoothRel_y_Getter";

  static y_Setter_float(mthis, value) native "SVGPathSegCurvetoCubicSmoothRel_y_Setter";

  static y2_Getter(mthis) native "SVGPathSegCurvetoCubicSmoothRel_y2_Getter";

  static y2_Setter_float(mthis, value) native "SVGPathSegCurvetoCubicSmoothRel_y2_Setter";
}

class BlinkSVGPathSegCurvetoQuadraticAbs {
  static x_Getter(mthis) native "SVGPathSegCurvetoQuadraticAbs_x_Getter";

  static x_Setter_float(mthis, value) native "SVGPathSegCurvetoQuadraticAbs_x_Setter";

  static x1_Getter(mthis) native "SVGPathSegCurvetoQuadraticAbs_x1_Getter";

  static x1_Setter_float(mthis, value) native "SVGPathSegCurvetoQuadraticAbs_x1_Setter";

  static y_Getter(mthis) native "SVGPathSegCurvetoQuadraticAbs_y_Getter";

  static y_Setter_float(mthis, value) native "SVGPathSegCurvetoQuadraticAbs_y_Setter";

  static y1_Getter(mthis) native "SVGPathSegCurvetoQuadraticAbs_y1_Getter";

  static y1_Setter_float(mthis, value) native "SVGPathSegCurvetoQuadraticAbs_y1_Setter";
}

class BlinkSVGPathSegCurvetoQuadraticRel {
  static x_Getter(mthis) native "SVGPathSegCurvetoQuadraticRel_x_Getter";

  static x_Setter_float(mthis, value) native "SVGPathSegCurvetoQuadraticRel_x_Setter";

  static x1_Getter(mthis) native "SVGPathSegCurvetoQuadraticRel_x1_Getter";

  static x1_Setter_float(mthis, value) native "SVGPathSegCurvetoQuadraticRel_x1_Setter";

  static y_Getter(mthis) native "SVGPathSegCurvetoQuadraticRel_y_Getter";

  static y_Setter_float(mthis, value) native "SVGPathSegCurvetoQuadraticRel_y_Setter";

  static y1_Getter(mthis) native "SVGPathSegCurvetoQuadraticRel_y1_Getter";

  static y1_Setter_float(mthis, value) native "SVGPathSegCurvetoQuadraticRel_y1_Setter";
}

class BlinkSVGPathSegCurvetoQuadraticSmoothAbs {
  static x_Getter(mthis) native "SVGPathSegCurvetoQuadraticSmoothAbs_x_Getter";

  static x_Setter_float(mthis, value) native "SVGPathSegCurvetoQuadraticSmoothAbs_x_Setter";

  static y_Getter(mthis) native "SVGPathSegCurvetoQuadraticSmoothAbs_y_Getter";

  static y_Setter_float(mthis, value) native "SVGPathSegCurvetoQuadraticSmoothAbs_y_Setter";
}

class BlinkSVGPathSegCurvetoQuadraticSmoothRel {
  static x_Getter(mthis) native "SVGPathSegCurvetoQuadraticSmoothRel_x_Getter";

  static x_Setter_float(mthis, value) native "SVGPathSegCurvetoQuadraticSmoothRel_x_Setter";

  static y_Getter(mthis) native "SVGPathSegCurvetoQuadraticSmoothRel_y_Getter";

  static y_Setter_float(mthis, value) native "SVGPathSegCurvetoQuadraticSmoothRel_y_Setter";
}

class BlinkSVGPathSegLinetoAbs {
  static x_Getter(mthis) native "SVGPathSegLinetoAbs_x_Getter";

  static x_Setter_float(mthis, value) native "SVGPathSegLinetoAbs_x_Setter";

  static y_Getter(mthis) native "SVGPathSegLinetoAbs_y_Getter";

  static y_Setter_float(mthis, value) native "SVGPathSegLinetoAbs_y_Setter";
}

class BlinkSVGPathSegLinetoHorizontalAbs {
  static x_Getter(mthis) native "SVGPathSegLinetoHorizontalAbs_x_Getter";

  static x_Setter_float(mthis, value) native "SVGPathSegLinetoHorizontalAbs_x_Setter";
}

class BlinkSVGPathSegLinetoHorizontalRel {
  static x_Getter(mthis) native "SVGPathSegLinetoHorizontalRel_x_Getter";

  static x_Setter_float(mthis, value) native "SVGPathSegLinetoHorizontalRel_x_Setter";
}

class BlinkSVGPathSegLinetoRel {
  static x_Getter(mthis) native "SVGPathSegLinetoRel_x_Getter";

  static x_Setter_float(mthis, value) native "SVGPathSegLinetoRel_x_Setter";

  static y_Getter(mthis) native "SVGPathSegLinetoRel_y_Getter";

  static y_Setter_float(mthis, value) native "SVGPathSegLinetoRel_y_Setter";
}

class BlinkSVGPathSegLinetoVerticalAbs {
  static y_Getter(mthis) native "SVGPathSegLinetoVerticalAbs_y_Getter";

  static y_Setter_float(mthis, value) native "SVGPathSegLinetoVerticalAbs_y_Setter";
}

class BlinkSVGPathSegLinetoVerticalRel {
  static y_Getter(mthis) native "SVGPathSegLinetoVerticalRel_y_Getter";

  static y_Setter_float(mthis, value) native "SVGPathSegLinetoVerticalRel_y_Setter";
}

class BlinkSVGPathSegList {
  static length_Getter(mthis) native "SVGPathSegList_length_Getter";

  static numberOfItems_Getter(mthis) native "SVGPathSegList_numberOfItems_Getter";

  static $__setter___Callback_ul_SVGPathSeg(mthis, index, value) native "SVGPathSegList___setter___Callback_unsigned long_SVGPathSeg";

  static appendItem_Callback_SVGPathSeg(mthis, newItem) native "SVGPathSegList_appendItem_Callback_SVGPathSeg";

  static clear_Callback(mthis) native "SVGPathSegList_clear_Callback";

  static getItem_Callback_ul(mthis, index) native "SVGPathSegList_getItem_Callback_unsigned long";

  static initialize_Callback_SVGPathSeg(mthis, newItem) native "SVGPathSegList_initialize_Callback_SVGPathSeg";

  static insertItemBefore_Callback_SVGPathSeg_ul(mthis, newItem, index) native "SVGPathSegList_insertItemBefore_Callback_SVGPathSeg_unsigned long";

  static removeItem_Callback_ul(mthis, index) native "SVGPathSegList_removeItem_Callback_unsigned long";

  static replaceItem_Callback_SVGPathSeg_ul(mthis, newItem, index) native "SVGPathSegList_replaceItem_Callback_SVGPathSeg_unsigned long";
}

class BlinkSVGPathSegMovetoAbs {
  static x_Getter(mthis) native "SVGPathSegMovetoAbs_x_Getter";

  static x_Setter_float(mthis, value) native "SVGPathSegMovetoAbs_x_Setter";

  static y_Getter(mthis) native "SVGPathSegMovetoAbs_y_Getter";

  static y_Setter_float(mthis, value) native "SVGPathSegMovetoAbs_y_Setter";
}

class BlinkSVGPathSegMovetoRel {
  static x_Getter(mthis) native "SVGPathSegMovetoRel_x_Getter";

  static x_Setter_float(mthis, value) native "SVGPathSegMovetoRel_x_Setter";

  static y_Getter(mthis) native "SVGPathSegMovetoRel_y_Getter";

  static y_Setter_float(mthis, value) native "SVGPathSegMovetoRel_y_Setter";
}

class BlinkSVGPatternElement {
  static height_Getter(mthis) native "SVGPatternElement_height_Getter";

  static patternContentUnits_Getter(mthis) native "SVGPatternElement_patternContentUnits_Getter";

  static patternTransform_Getter(mthis) native "SVGPatternElement_patternTransform_Getter";

  static patternUnits_Getter(mthis) native "SVGPatternElement_patternUnits_Getter";

  static width_Getter(mthis) native "SVGPatternElement_width_Getter";

  static x_Getter(mthis) native "SVGPatternElement_x_Getter";

  static y_Getter(mthis) native "SVGPatternElement_y_Getter";

  static preserveAspectRatio_Getter(mthis) native "SVGPatternElement_preserveAspectRatio_Getter";

  static viewBox_Getter(mthis) native "SVGPatternElement_viewBox_Getter";

  static requiredExtensions_Getter(mthis) native "SVGPatternElement_requiredExtensions_Getter";

  static requiredFeatures_Getter(mthis) native "SVGPatternElement_requiredFeatures_Getter";

  static systemLanguage_Getter(mthis) native "SVGPatternElement_systemLanguage_Getter";

  static hasExtension_Callback_DOMString(mthis, extension) native "SVGPatternElement_hasExtension_Callback_DOMString";

  static href_Getter(mthis) native "SVGPatternElement_href_Getter";
}

class BlinkSVGPoint {
  static x_Getter(mthis) native "SVGPoint_x_Getter";

  static x_Setter_float(mthis, value) native "SVGPoint_x_Setter";

  static y_Getter(mthis) native "SVGPoint_y_Getter";

  static y_Setter_float(mthis, value) native "SVGPoint_y_Setter";

  static matrixTransform_Callback_SVGMatrix(mthis, matrix) native "SVGPoint_matrixTransform_Callback_SVGMatrix";
}

class BlinkSVGPointList {
  static length_Getter(mthis) native "SVGPointList_length_Getter";

  static numberOfItems_Getter(mthis) native "SVGPointList_numberOfItems_Getter";

  static $__setter___Callback_ul_SVGPoint(mthis, index, value) native "SVGPointList___setter___Callback_unsigned long_SVGPoint";

  static appendItem_Callback_SVGPoint(mthis, item) native "SVGPointList_appendItem_Callback_SVGPoint";

  static clear_Callback(mthis) native "SVGPointList_clear_Callback";

  static getItem_Callback_ul(mthis, index) native "SVGPointList_getItem_Callback_unsigned long";

  static initialize_Callback_SVGPoint(mthis, item) native "SVGPointList_initialize_Callback_SVGPoint";

  static insertItemBefore_Callback_SVGPoint_ul(mthis, item, index) native "SVGPointList_insertItemBefore_Callback_SVGPoint_unsigned long";

  static removeItem_Callback_ul(mthis, index) native "SVGPointList_removeItem_Callback_unsigned long";

  static replaceItem_Callback_SVGPoint_ul(mthis, item, index) native "SVGPointList_replaceItem_Callback_SVGPoint_unsigned long";
}

class BlinkSVGPolygonElement {
  static animatedPoints_Getter(mthis) native "SVGPolygonElement_animatedPoints_Getter";

  static points_Getter(mthis) native "SVGPolygonElement_points_Getter";
}

class BlinkSVGPolylineElement {
  static animatedPoints_Getter(mthis) native "SVGPolylineElement_animatedPoints_Getter";

  static points_Getter(mthis) native "SVGPolylineElement_points_Getter";
}

class BlinkSVGPreserveAspectRatio {
  static align_Getter(mthis) native "SVGPreserveAspectRatio_align_Getter";

  static align_Setter_us(mthis, value) native "SVGPreserveAspectRatio_align_Setter";

  static meetOrSlice_Getter(mthis) native "SVGPreserveAspectRatio_meetOrSlice_Getter";

  static meetOrSlice_Setter_us(mthis, value) native "SVGPreserveAspectRatio_meetOrSlice_Setter";
}

class BlinkSVGRadialGradientElement {
  static cx_Getter(mthis) native "SVGRadialGradientElement_cx_Getter";

  static cy_Getter(mthis) native "SVGRadialGradientElement_cy_Getter";

  static fr_Getter(mthis) native "SVGRadialGradientElement_fr_Getter";

  static fx_Getter(mthis) native "SVGRadialGradientElement_fx_Getter";

  static fy_Getter(mthis) native "SVGRadialGradientElement_fy_Getter";

  static r_Getter(mthis) native "SVGRadialGradientElement_r_Getter";
}

class BlinkSVGRect {
  static height_Getter(mthis) native "SVGRect_height_Getter";

  static height_Setter_float(mthis, value) native "SVGRect_height_Setter";

  static width_Getter(mthis) native "SVGRect_width_Getter";

  static width_Setter_float(mthis, value) native "SVGRect_width_Setter";

  static x_Getter(mthis) native "SVGRect_x_Getter";

  static x_Setter_float(mthis, value) native "SVGRect_x_Setter";

  static y_Getter(mthis) native "SVGRect_y_Getter";

  static y_Setter_float(mthis, value) native "SVGRect_y_Setter";
}

class BlinkSVGRectElement {
  static height_Getter(mthis) native "SVGRectElement_height_Getter";

  static rx_Getter(mthis) native "SVGRectElement_rx_Getter";

  static ry_Getter(mthis) native "SVGRectElement_ry_Getter";

  static width_Getter(mthis) native "SVGRectElement_width_Getter";

  static x_Getter(mthis) native "SVGRectElement_x_Getter";

  static y_Getter(mthis) native "SVGRectElement_y_Getter";
}

class BlinkSVGRenderingIntent {}

class BlinkSVGZoomAndPan {
  static zoomAndPan_Getter(mthis) native "SVGZoomAndPan_zoomAndPan_Getter";

  static zoomAndPan_Setter_us(mthis, value) native "SVGZoomAndPan_zoomAndPan_Setter";
}

class BlinkSVGSVGElement {
  static currentScale_Getter(mthis) native "SVGSVGElement_currentScale_Getter";

  static currentScale_Setter_float(mthis, value) native "SVGSVGElement_currentScale_Setter";

  static currentTranslate_Getter(mthis) native "SVGSVGElement_currentTranslate_Getter";

  static currentView_Getter(mthis) native "SVGSVGElement_currentView_Getter";

  static height_Getter(mthis) native "SVGSVGElement_height_Getter";

  static pixelUnitToMillimeterX_Getter(mthis) native "SVGSVGElement_pixelUnitToMillimeterX_Getter";

  static pixelUnitToMillimeterY_Getter(mthis) native "SVGSVGElement_pixelUnitToMillimeterY_Getter";

  static screenPixelToMillimeterX_Getter(mthis) native "SVGSVGElement_screenPixelToMillimeterX_Getter";

  static screenPixelToMillimeterY_Getter(mthis) native "SVGSVGElement_screenPixelToMillimeterY_Getter";

  static useCurrentView_Getter(mthis) native "SVGSVGElement_useCurrentView_Getter";

  static viewport_Getter(mthis) native "SVGSVGElement_viewport_Getter";

  static width_Getter(mthis) native "SVGSVGElement_width_Getter";

  static x_Getter(mthis) native "SVGSVGElement_x_Getter";

  static y_Getter(mthis) native "SVGSVGElement_y_Getter";

  static animationsPaused_Callback(mthis) native "SVGSVGElement_animationsPaused_Callback";

  static checkEnclosure_Callback_SVGElement_SVGRect(mthis, element, rect) native "SVGSVGElement_checkEnclosure_Callback_SVGElement_SVGRect";

  static checkIntersection_Callback_SVGElement_SVGRect(mthis, element, rect) native "SVGSVGElement_checkIntersection_Callback_SVGElement_SVGRect";

  static createSVGAngle_Callback(mthis) native "SVGSVGElement_createSVGAngle_Callback";

  static createSVGLength_Callback(mthis) native "SVGSVGElement_createSVGLength_Callback";

  static createSVGMatrix_Callback(mthis) native "SVGSVGElement_createSVGMatrix_Callback";

  static createSVGNumber_Callback(mthis) native "SVGSVGElement_createSVGNumber_Callback";

  static createSVGPoint_Callback(mthis) native "SVGSVGElement_createSVGPoint_Callback";

  static createSVGRect_Callback(mthis) native "SVGSVGElement_createSVGRect_Callback";

  static createSVGTransform_Callback(mthis) native "SVGSVGElement_createSVGTransform_Callback";

  static createSVGTransformFromMatrix_Callback_SVGMatrix(mthis, matrix) native "SVGSVGElement_createSVGTransformFromMatrix_Callback_SVGMatrix";

  static deselectAll_Callback(mthis) native "SVGSVGElement_deselectAll_Callback";

  static forceRedraw_Callback(mthis) native "SVGSVGElement_forceRedraw_Callback";

  static getCurrentTime_Callback(mthis) native "SVGSVGElement_getCurrentTime_Callback";

  static getElementById_Callback_DOMString(mthis, elementId) native "SVGSVGElement_getElementById_Callback_DOMString";

  static getEnclosureList_Callback_SVGRect_SVGElement(mthis, rect, referenceElement) native "SVGSVGElement_getEnclosureList_Callback_SVGRect_SVGElement";

  static getIntersectionList_Callback_SVGRect_SVGElement(mthis, rect, referenceElement) native "SVGSVGElement_getIntersectionList_Callback_SVGRect_SVGElement";

  static pauseAnimations_Callback(mthis) native "SVGSVGElement_pauseAnimations_Callback";

  static setCurrentTime_Callback_float(mthis, seconds) native "SVGSVGElement_setCurrentTime_Callback_float";

  static suspendRedraw_Callback_ul(mthis, maxWaitMilliseconds) native "SVGSVGElement_suspendRedraw_Callback_unsigned long";

  static unpauseAnimations_Callback(mthis) native "SVGSVGElement_unpauseAnimations_Callback";

  static unsuspendRedraw_Callback_ul(mthis, suspendHandleId) native "SVGSVGElement_unsuspendRedraw_Callback_unsigned long";

  static unsuspendRedrawAll_Callback(mthis) native "SVGSVGElement_unsuspendRedrawAll_Callback";

  static preserveAspectRatio_Getter(mthis) native "SVGSVGElement_preserveAspectRatio_Getter";

  static viewBox_Getter(mthis) native "SVGSVGElement_viewBox_Getter";

  static zoomAndPan_Getter(mthis) native "SVGSVGElement_zoomAndPan_Getter";

  static zoomAndPan_Setter_us(mthis, value) native "SVGSVGElement_zoomAndPan_Setter";
}

class BlinkSVGScriptElement {
  static type_Getter(mthis) native "SVGScriptElement_type_Getter";

  static type_Setter_DOMString(mthis, value) native "SVGScriptElement_type_Setter";

  static href_Getter(mthis) native "SVGScriptElement_href_Getter";
}

class BlinkSVGSetElement {}

class BlinkSVGStopElement {
  static offset_Getter(mthis) native "SVGStopElement_offset_Getter";
}

class BlinkSVGStringList {
  static length_Getter(mthis) native "SVGStringList_length_Getter";

  static numberOfItems_Getter(mthis) native "SVGStringList_numberOfItems_Getter";

  static $__setter___Callback_ul_DOMString(mthis, index, value) native "SVGStringList___setter___Callback_unsigned long_DOMString";

  static appendItem_Callback_DOMString(mthis, item) native "SVGStringList_appendItem_Callback_DOMString";

  static clear_Callback(mthis) native "SVGStringList_clear_Callback";

  static getItem_Callback_ul(mthis, index) native "SVGStringList_getItem_Callback_unsigned long";

  static initialize_Callback_DOMString(mthis, item) native "SVGStringList_initialize_Callback_DOMString";

  static insertItemBefore_Callback_DOMString_ul(mthis, item, index) native "SVGStringList_insertItemBefore_Callback_DOMString_unsigned long";

  static removeItem_Callback_ul(mthis, index) native "SVGStringList_removeItem_Callback_unsigned long";

  static replaceItem_Callback_DOMString_ul(mthis, item, index) native "SVGStringList_replaceItem_Callback_DOMString_unsigned long";
}

class BlinkSVGStyleElement {
  static disabled_Getter(mthis) native "SVGStyleElement_disabled_Getter";

  static disabled_Setter_boolean(mthis, value) native "SVGStyleElement_disabled_Setter";

  static media_Getter(mthis) native "SVGStyleElement_media_Getter";

  static media_Setter_DOMString(mthis, value) native "SVGStyleElement_media_Setter";

  static title_Getter(mthis) native "SVGStyleElement_title_Getter";

  static title_Setter_DOMString(mthis, value) native "SVGStyleElement_title_Setter";

  static type_Getter(mthis) native "SVGStyleElement_type_Getter";

  static type_Setter_DOMString(mthis, value) native "SVGStyleElement_type_Setter";
}

class BlinkSVGSwitchElement {}

class BlinkSVGSymbolElement {
  static preserveAspectRatio_Getter(mthis) native "SVGSymbolElement_preserveAspectRatio_Getter";

  static viewBox_Getter(mthis) native "SVGSymbolElement_viewBox_Getter";
}

class BlinkSVGTSpanElement {}

class BlinkSVGTextElement {}

class BlinkSVGTextPathElement {
  static method_Getter(mthis) native "SVGTextPathElement_method_Getter";

  static spacing_Getter(mthis) native "SVGTextPathElement_spacing_Getter";

  static startOffset_Getter(mthis) native "SVGTextPathElement_startOffset_Getter";

  static href_Getter(mthis) native "SVGTextPathElement_href_Getter";
}

class BlinkSVGTitleElement {}

class BlinkSVGTransform {
  static angle_Getter(mthis) native "SVGTransform_angle_Getter";

  static matrix_Getter(mthis) native "SVGTransform_matrix_Getter";

  static type_Getter(mthis) native "SVGTransform_type_Getter";

  static setMatrix_Callback_SVGMatrix(mthis, matrix) native "SVGTransform_setMatrix_Callback_SVGMatrix";

  static setRotate_Callback_float_float_float(mthis, angle, cx, cy) native "SVGTransform_setRotate_Callback_float_float_float";

  static setScale_Callback_float_float(mthis, sx, sy) native "SVGTransform_setScale_Callback_float_float";

  static setSkewX_Callback_float(mthis, angle) native "SVGTransform_setSkewX_Callback_float";

  static setSkewY_Callback_float(mthis, angle) native "SVGTransform_setSkewY_Callback_float";

  static setTranslate_Callback_float_float(mthis, tx, ty) native "SVGTransform_setTranslate_Callback_float_float";
}

class BlinkSVGTransformList {
  static length_Getter(mthis) native "SVGTransformList_length_Getter";

  static numberOfItems_Getter(mthis) native "SVGTransformList_numberOfItems_Getter";

  static $__setter___Callback_ul_SVGTransform(mthis, index, value) native "SVGTransformList___setter___Callback_unsigned long_SVGTransform";

  static appendItem_Callback_SVGTransform(mthis, item) native "SVGTransformList_appendItem_Callback_SVGTransform";

  static clear_Callback(mthis) native "SVGTransformList_clear_Callback";

  static consolidate_Callback(mthis) native "SVGTransformList_consolidate_Callback";

  static createSVGTransformFromMatrix_Callback_SVGMatrix(mthis, matrix) native "SVGTransformList_createSVGTransformFromMatrix_Callback_SVGMatrix";

  static getItem_Callback_ul(mthis, index) native "SVGTransformList_getItem_Callback_unsigned long";

  static initialize_Callback_SVGTransform(mthis, item) native "SVGTransformList_initialize_Callback_SVGTransform";

  static insertItemBefore_Callback_SVGTransform_ul(mthis, item, index) native "SVGTransformList_insertItemBefore_Callback_SVGTransform_unsigned long";

  static removeItem_Callback_ul(mthis, index) native "SVGTransformList_removeItem_Callback_unsigned long";

  static replaceItem_Callback_SVGTransform_ul(mthis, item, index) native "SVGTransformList_replaceItem_Callback_SVGTransform_unsigned long";
}

class BlinkSVGUnitTypes {}

class BlinkSVGUseElement {
  static height_Getter(mthis) native "SVGUseElement_height_Getter";

  static width_Getter(mthis) native "SVGUseElement_width_Getter";

  static x_Getter(mthis) native "SVGUseElement_x_Getter";

  static y_Getter(mthis) native "SVGUseElement_y_Getter";

  static href_Getter(mthis) native "SVGUseElement_href_Getter";
}

class BlinkSVGVKernElement {}

class BlinkSVGViewElement {
  static viewTarget_Getter(mthis) native "SVGViewElement_viewTarget_Getter";

  static preserveAspectRatio_Getter(mthis) native "SVGViewElement_preserveAspectRatio_Getter";

  static viewBox_Getter(mthis) native "SVGViewElement_viewBox_Getter";

  static zoomAndPan_Getter(mthis) native "SVGViewElement_zoomAndPan_Getter";

  static zoomAndPan_Setter_us(mthis, value) native "SVGViewElement_zoomAndPan_Setter";
}

class BlinkSVGViewSpec {
  static preserveAspectRatioString_Getter(mthis) native "SVGViewSpec_preserveAspectRatioString_Getter";

  static transform_Getter(mthis) native "SVGViewSpec_transform_Getter";

  static transformString_Getter(mthis) native "SVGViewSpec_transformString_Getter";

  static viewBoxString_Getter(mthis) native "SVGViewSpec_viewBoxString_Getter";

  static viewTarget_Getter(mthis) native "SVGViewSpec_viewTarget_Getter";

  static viewTargetString_Getter(mthis) native "SVGViewSpec_viewTargetString_Getter";

  static preserveAspectRatio_Getter(mthis) native "SVGViewSpec_preserveAspectRatio_Getter";

  static viewBox_Getter(mthis) native "SVGViewSpec_viewBox_Getter";

  static zoomAndPan_Getter(mthis) native "SVGViewSpec_zoomAndPan_Getter";

  static zoomAndPan_Setter_us(mthis, value) native "SVGViewSpec_zoomAndPan_Setter";
}

class BlinkSVGZoomEvent {
  static newScale_Getter(mthis) native "SVGZoomEvent_newScale_Getter";

  static newTranslate_Getter(mthis) native "SVGZoomEvent_newTranslate_Getter";

  static previousScale_Getter(mthis) native "SVGZoomEvent_previousScale_Getter";

  static previousTranslate_Getter(mthis) native "SVGZoomEvent_previousTranslate_Getter";

  static zoomRectScreen_Getter(mthis) native "SVGZoomEvent_zoomRectScreen_Getter";
}

class BlinkScreen {
  static availHeight_Getter(mthis) native "Screen_availHeight_Getter";

  static availLeft_Getter(mthis) native "Screen_availLeft_Getter";

  static availTop_Getter(mthis) native "Screen_availTop_Getter";

  static availWidth_Getter(mthis) native "Screen_availWidth_Getter";

  static colorDepth_Getter(mthis) native "Screen_colorDepth_Getter";

  static height_Getter(mthis) native "Screen_height_Getter";

  static orientation_Getter(mthis) native "Screen_orientation_Getter";

  static pixelDepth_Getter(mthis) native "Screen_pixelDepth_Getter";

  static width_Getter(mthis) native "Screen_width_Getter";

  static unlockOrientation_Callback(mthis) native "Screen_unlockOrientation_Callback";
}

class BlinkScriptProcessorNode {
  static bufferSize_Getter(mthis) native "ScriptProcessorNode_bufferSize_Getter";

  static setEventListener_Callback_EventListener(mthis, eventListener) native "ScriptProcessorNode_setEventListener_Callback";
}

class BlinkSecurityPolicyViolationEvent {
  static blockedURI_Getter(mthis) native "SecurityPolicyViolationEvent_blockedURI_Getter";

  static columnNumber_Getter(mthis) native "SecurityPolicyViolationEvent_columnNumber_Getter";

  static documentURI_Getter(mthis) native "SecurityPolicyViolationEvent_documentURI_Getter";

  static effectiveDirective_Getter(mthis) native "SecurityPolicyViolationEvent_effectiveDirective_Getter";

  static lineNumber_Getter(mthis) native "SecurityPolicyViolationEvent_lineNumber_Getter";

  static originalPolicy_Getter(mthis) native "SecurityPolicyViolationEvent_originalPolicy_Getter";

  static referrer_Getter(mthis) native "SecurityPolicyViolationEvent_referrer_Getter";

  static sourceFile_Getter(mthis) native "SecurityPolicyViolationEvent_sourceFile_Getter";

  static statusCode_Getter(mthis) native "SecurityPolicyViolationEvent_statusCode_Getter";

  static violatedDirective_Getter(mthis) native "SecurityPolicyViolationEvent_violatedDirective_Getter";
}

class BlinkSelection {
  static anchorNode_Getter(mthis) native "Selection_anchorNode_Getter";

  static anchorOffset_Getter(mthis) native "Selection_anchorOffset_Getter";

  static baseNode_Getter(mthis) native "Selection_baseNode_Getter";

  static baseOffset_Getter(mthis) native "Selection_baseOffset_Getter";

  static extentNode_Getter(mthis) native "Selection_extentNode_Getter";

  static extentOffset_Getter(mthis) native "Selection_extentOffset_Getter";

  static focusNode_Getter(mthis) native "Selection_focusNode_Getter";

  static focusOffset_Getter(mthis) native "Selection_focusOffset_Getter";

  static isCollapsed_Getter(mthis) native "Selection_isCollapsed_Getter";

  static rangeCount_Getter(mthis) native "Selection_rangeCount_Getter";

  static type_Getter(mthis) native "Selection_type_Getter";

  static addRange_Callback_Range(mthis, range) native "Selection_addRange_Callback_Range";

  static collapse_Callback_Node_long(mthis, node, offset) native "Selection_collapse_Callback_Node_long";

  static collapse_Callback_Node(mthis, node) native "Selection_collapse_Callback_Node";

  static collapseToEnd_Callback(mthis) native "Selection_collapseToEnd_Callback";

  static collapseToStart_Callback(mthis) native "Selection_collapseToStart_Callback";

  static containsNode_Callback_Node_boolean(mthis, node, allowPartial) native "Selection_containsNode_Callback_Node_boolean";

  static deleteFromDocument_Callback(mthis) native "Selection_deleteFromDocument_Callback";

  static empty_Callback(mthis) native "Selection_empty_Callback";

  static extend_Callback_Node_long(mthis, node, offset) native "Selection_extend_Callback_Node_long";

  static getRangeAt_Callback_long(mthis, index) native "Selection_getRangeAt_Callback_long";

  static modify_Callback_DOMString_DOMString_DOMString(mthis, alter, direction, granularity) native "Selection_modify_Callback_DOMString_DOMString_DOMString";

  static removeAllRanges_Callback(mthis) native "Selection_removeAllRanges_Callback";

  static selectAllChildren_Callback_Node(mthis, node) native "Selection_selectAllChildren_Callback_Node";

  static setBaseAndExtent_Callback_Node_long_Node_long(mthis, baseNode, baseOffset, extentNode, extentOffset) native "Selection_setBaseAndExtent_Callback_Node_long_Node_long";

  static setPosition_Callback_Node_long(mthis, node, offset) native "Selection_setPosition_Callback_Node_long";

  static setPosition_Callback_Node(mthis, node) native "Selection_setPosition_Callback_Node";

  static toString_Callback(mthis) native "Selection_toString_Callback";
}

class BlinkServiceWorker {}

class BlinkServiceWorkerClients {}

class BlinkServiceWorkerContainer {
  static active_Getter(mthis) native "ServiceWorkerContainer_active_Getter";

  static controller_Getter(mthis) native "ServiceWorkerContainer_controller_Getter";

  static installing_Getter(mthis) native "ServiceWorkerContainer_installing_Getter";

  static waiting_Getter(mthis) native "ServiceWorkerContainer_waiting_Getter";
}

class BlinkServiceWorkerGlobalScope {
  static clients_Getter(mthis) native "ServiceWorkerGlobalScope_clients_Getter";

  static scope_Getter(mthis) native "ServiceWorkerGlobalScope_scope_Getter";
}

class BlinkShadowRoot {
  static activeElement_Getter(mthis) native "ShadowRoot_activeElement_Getter";

  static host_Getter(mthis) native "ShadowRoot_host_Getter";

  static innerHTML_Getter(mthis) native "ShadowRoot_innerHTML_Getter";

  static innerHTML_Setter_DOMString(mthis, value) native "ShadowRoot_innerHTML_Setter";

  static olderShadowRoot_Getter(mthis) native "ShadowRoot_olderShadowRoot_Getter";

  static styleSheets_Getter(mthis) native "ShadowRoot_styleSheets_Getter";

  static cloneNode_Callback_boolean(mthis, deep) native "ShadowRoot_cloneNode_Callback_boolean";

  static elementFromPoint_Callback_long_long(mthis, x, y) native "ShadowRoot_elementFromPoint_Callback_long_long";

  static getElementById_Callback_DOMString(mthis, elementId) native "ShadowRoot_getElementById_Callback_DOMString";

  static getElementsByClassName_Callback_DOMString(mthis, className) native "ShadowRoot_getElementsByClassName_Callback_DOMString";

  static getElementsByTagName_Callback_DOMString(mthis, tagName) native "ShadowRoot_getElementsByTagName_Callback_DOMString";

  static getSelection_Callback(mthis) native "ShadowRoot_getSelection_Callback";
}

class BlinkSharedWorker {
  static constructorCallback_DOMString_DOMString(scriptURL, name) native "SharedWorker_constructorCallback_DOMString_DOMString";

  static port_Getter(mthis) native "SharedWorker_port_Getter";

  static workerStart_Getter(mthis) native "SharedWorker_workerStart_Getter";
}

class BlinkSharedWorkerGlobalScope {
  static name_Getter(mthis) native "SharedWorkerGlobalScope_name_Getter";
}

class BlinkSourceBuffer {
  static appendWindowEnd_Getter(mthis) native "SourceBuffer_appendWindowEnd_Getter";

  static appendWindowEnd_Setter_double(mthis, value) native "SourceBuffer_appendWindowEnd_Setter";

  static appendWindowStart_Getter(mthis) native "SourceBuffer_appendWindowStart_Getter";

  static appendWindowStart_Setter_double(mthis, value) native "SourceBuffer_appendWindowStart_Setter";

  static buffered_Getter(mthis) native "SourceBuffer_buffered_Getter";

  static mode_Getter(mthis) native "SourceBuffer_mode_Getter";

  static mode_Setter_DOMString(mthis, value) native "SourceBuffer_mode_Setter";

  static timestampOffset_Getter(mthis) native "SourceBuffer_timestampOffset_Getter";

  static timestampOffset_Setter_double(mthis, value) native "SourceBuffer_timestampOffset_Setter";

  static updating_Getter(mthis) native "SourceBuffer_updating_Getter";

  static abort_Callback(mthis) native "SourceBuffer_abort_Callback";

  static appendBuffer_Callback_ArrayBuffer(mthis, data) native "SourceBuffer_appendBuffer_Callback_ArrayBuffer";

  static appendStream_Callback_Stream_ull(mthis, stream, maxSize) native "SourceBuffer_appendStream_Callback_Stream_unsigned long long";

  static appendStream_Callback_Stream(mthis, stream) native "SourceBuffer_appendStream_Callback_Stream";

  static appendBuffer_Callback_ArrayBufferView(mthis, data) native "SourceBuffer_appendBuffer_Callback_ArrayBufferView";

  static remove_Callback_double_double(mthis, start, end) native "SourceBuffer_remove_Callback_double_double";
}

class BlinkSourceBufferList {
  static length_Getter(mthis) native "SourceBufferList_length_Getter";

  static item_Callback_ul(mthis, index) native "SourceBufferList_item_Callback_unsigned long";
}

class BlinkSourceInfo {
  static facing_Getter(mthis) native "SourceInfo_facing_Getter";

  static id_Getter(mthis) native "SourceInfo_id_Getter";

  static kind_Getter(mthis) native "SourceInfo_kind_Getter";

  static label_Getter(mthis) native "SourceInfo_label_Getter";
}

class BlinkSpeechGrammar {
  static constructorCallback() native "SpeechGrammar_constructorCallback";

  static src_Getter(mthis) native "SpeechGrammar_src_Getter";

  static src_Setter_DOMString(mthis, value) native "SpeechGrammar_src_Setter";

  static weight_Getter(mthis) native "SpeechGrammar_weight_Getter";

  static weight_Setter_float(mthis, value) native "SpeechGrammar_weight_Setter";
}

class BlinkSpeechGrammarList {
  static constructorCallback() native "SpeechGrammarList_constructorCallback";

  static length_Getter(mthis) native "SpeechGrammarList_length_Getter";

  static addFromString_Callback_DOMString_float(mthis, string, weight) native "SpeechGrammarList_addFromString_Callback_DOMString_float";

  static addFromString_Callback_DOMString(mthis, string) native "SpeechGrammarList_addFromString_Callback_DOMString";

  static addFromUri_Callback_DOMString_float(mthis, src, weight) native "SpeechGrammarList_addFromUri_Callback_DOMString_float";

  static addFromUri_Callback_DOMString(mthis, src) native "SpeechGrammarList_addFromUri_Callback_DOMString";

  static item_Callback_ul(mthis, index) native "SpeechGrammarList_item_Callback_unsigned long";
}

class BlinkSpeechRecognition {
  static constructorCallback() native "SpeechRecognition_constructorCallback";

  static continuous_Getter(mthis) native "SpeechRecognition_continuous_Getter";

  static continuous_Setter_boolean(mthis, value) native "SpeechRecognition_continuous_Setter";

  static grammars_Getter(mthis) native "SpeechRecognition_grammars_Getter";

  static grammars_Setter_SpeechGrammarList(mthis, value) native "SpeechRecognition_grammars_Setter";

  static interimResults_Getter(mthis) native "SpeechRecognition_interimResults_Getter";

  static interimResults_Setter_boolean(mthis, value) native "SpeechRecognition_interimResults_Setter";

  static lang_Getter(mthis) native "SpeechRecognition_lang_Getter";

  static lang_Setter_DOMString(mthis, value) native "SpeechRecognition_lang_Setter";

  static maxAlternatives_Getter(mthis) native "SpeechRecognition_maxAlternatives_Getter";

  static maxAlternatives_Setter_ul(mthis, value) native "SpeechRecognition_maxAlternatives_Setter";

  static abort_Callback(mthis) native "SpeechRecognition_abort_Callback";

  static start_Callback(mthis) native "SpeechRecognition_start_Callback";

  static stop_Callback(mthis) native "SpeechRecognition_stop_Callback";
}

class BlinkSpeechRecognitionAlternative {
  static confidence_Getter(mthis) native "SpeechRecognitionAlternative_confidence_Getter";

  static transcript_Getter(mthis) native "SpeechRecognitionAlternative_transcript_Getter";
}

class BlinkSpeechRecognitionError {
  static error_Getter(mthis) native "SpeechRecognitionError_error_Getter";

  static message_Getter(mthis) native "SpeechRecognitionError_message_Getter";
}

class BlinkSpeechRecognitionEvent {
  static emma_Getter(mthis) native "SpeechRecognitionEvent_emma_Getter";

  static interpretation_Getter(mthis) native "SpeechRecognitionEvent_interpretation_Getter";

  static resultIndex_Getter(mthis) native "SpeechRecognitionEvent_resultIndex_Getter";

  static results_Getter(mthis) native "SpeechRecognitionEvent_results_Getter";
}

class BlinkSpeechRecognitionResult {
  static isFinal_Getter(mthis) native "SpeechRecognitionResult_isFinal_Getter";

  static length_Getter(mthis) native "SpeechRecognitionResult_length_Getter";

  static item_Callback_ul(mthis, index) native "SpeechRecognitionResult_item_Callback_unsigned long";
}

class BlinkSpeechRecognitionResultList {
  static length_Getter(mthis) native "SpeechRecognitionResultList_length_Getter";

  static item_Callback_ul(mthis, index) native "SpeechRecognitionResultList_item_Callback_unsigned long";
}

class BlinkSpeechSynthesis {
  static paused_Getter(mthis) native "SpeechSynthesis_paused_Getter";

  static pending_Getter(mthis) native "SpeechSynthesis_pending_Getter";

  static speaking_Getter(mthis) native "SpeechSynthesis_speaking_Getter";

  static cancel_Callback(mthis) native "SpeechSynthesis_cancel_Callback";

  static getVoices_Callback(mthis) native "SpeechSynthesis_getVoices_Callback";

  static pause_Callback(mthis) native "SpeechSynthesis_pause_Callback";

  static resume_Callback(mthis) native "SpeechSynthesis_resume_Callback";

  static speak_Callback_SpeechSynthesisUtterance(mthis, utterance) native "SpeechSynthesis_speak_Callback_SpeechSynthesisUtterance";
}

class BlinkSpeechSynthesisEvent {
  static charIndex_Getter(mthis) native "SpeechSynthesisEvent_charIndex_Getter";

  static elapsedTime_Getter(mthis) native "SpeechSynthesisEvent_elapsedTime_Getter";

  static name_Getter(mthis) native "SpeechSynthesisEvent_name_Getter";
}

class BlinkSpeechSynthesisUtterance {
  static constructorCallback_DOMString(text) native "SpeechSynthesisUtterance_constructorCallback_DOMString";

  static lang_Getter(mthis) native "SpeechSynthesisUtterance_lang_Getter";

  static lang_Setter_DOMString(mthis, value) native "SpeechSynthesisUtterance_lang_Setter";

  static pitch_Getter(mthis) native "SpeechSynthesisUtterance_pitch_Getter";

  static pitch_Setter_float(mthis, value) native "SpeechSynthesisUtterance_pitch_Setter";

  static rate_Getter(mthis) native "SpeechSynthesisUtterance_rate_Getter";

  static rate_Setter_float(mthis, value) native "SpeechSynthesisUtterance_rate_Setter";

  static text_Getter(mthis) native "SpeechSynthesisUtterance_text_Getter";

  static text_Setter_DOMString(mthis, value) native "SpeechSynthesisUtterance_text_Setter";

  static voice_Getter(mthis) native "SpeechSynthesisUtterance_voice_Getter";

  static voice_Setter_SpeechSynthesisVoice(mthis, value) native "SpeechSynthesisUtterance_voice_Setter";

  static volume_Getter(mthis) native "SpeechSynthesisUtterance_volume_Getter";

  static volume_Setter_float(mthis, value) native "SpeechSynthesisUtterance_volume_Setter";
}

class BlinkSpeechSynthesisVoice {
  static default_Getter(mthis) native "SpeechSynthesisVoice_default_Getter";

  static lang_Getter(mthis) native "SpeechSynthesisVoice_lang_Getter";

  static localService_Getter(mthis) native "SpeechSynthesisVoice_localService_Getter";

  static name_Getter(mthis) native "SpeechSynthesisVoice_name_Getter";

  static voiceURI_Getter(mthis) native "SpeechSynthesisVoice_voiceURI_Getter";
}

class BlinkStorage {
  static length_Getter(mthis) native "Storage_length_Getter";

  static $__delete___Callback_ul(mthis, index_OR_name) native "Storage___delete___Callback_unsigned long";

  static $__delete___Callback_DOMString(mthis, index_OR_name) native "Storage___delete___Callback_DOMString";

  static $__getter___Callback_ul(mthis, index_OR_name) native "Storage___getter___Callback_unsigned long";

  static $__getter___Callback_DOMString(mthis, index_OR_name) native "Storage___getter___Callback_DOMString";

  static $__setter___Callback_ul_DOMString(mthis, index_OR_name, value) native "Storage___setter___Callback_unsigned long_DOMString";

  static $__setter___Callback_DOMString_DOMString(mthis, index_OR_name, value) native "Storage___setter___Callback_DOMString_DOMString";

  static clear_Callback(mthis) native "Storage_clear_Callback";

  static getItem_Callback_DOMString(mthis, key) native "Storage_getItem_Callback_DOMString";

  static key_Callback_ul(mthis, index) native "Storage_key_Callback_unsigned long";

  static removeItem_Callback_DOMString(mthis, key) native "Storage_removeItem_Callback_DOMString";

  static setItem_Callback_DOMString_DOMString(mthis, key, data) native "Storage_setItem_Callback_DOMString_DOMString";
}

class BlinkStorageEvent {
  static key_Getter(mthis) native "StorageEvent_key_Getter";

  static newValue_Getter(mthis) native "StorageEvent_newValue_Getter";

  static oldValue_Getter(mthis) native "StorageEvent_oldValue_Getter";

  static storageArea_Getter(mthis) native "StorageEvent_storageArea_Getter";

  static url_Getter(mthis) native "StorageEvent_url_Getter";

  static initStorageEvent_Callback_DOMString_boolean_boolean_DOMString_DOMString_DOMString_DOMString_Storage(mthis, typeArg, canBubbleArg, cancelableArg, keyArg, oldValueArg, newValueArg, urlArg, storageAreaArg) native "StorageEvent_initStorageEvent_Callback_DOMString_boolean_boolean_DOMString_DOMString_DOMString_DOMString_Storage";
}

class BlinkStorageInfo {
  static quota_Getter(mthis) native "StorageInfo_quota_Getter";

  static usage_Getter(mthis) native "StorageInfo_usage_Getter";
}

class BlinkStorageQuota {
  static supportedTypes_Getter(mthis) native "StorageQuota_supportedTypes_Getter";
}

class BlinkStream {
  static type_Getter(mthis) native "Stream_type_Getter";
}

class BlinkStyleMedia {
  static type_Getter(mthis) native "StyleMedia_type_Getter";

  static matchMedium_Callback_DOMString(mthis, mediaquery) native "StyleMedia_matchMedium_Callback_DOMString";
}

class BlinkStyleSheetList {
  static length_Getter(mthis) native "StyleSheetList_length_Getter";

  static $__getter___Callback_DOMString(mthis, name) native "StyleSheetList___getter___Callback_DOMString";

  static item_Callback_ul(mthis, index) native "StyleSheetList_item_Callback_unsigned long";
}

class BlinkSubtleCrypto {}

class BlinkTextEvent {
  static data_Getter(mthis) native "TextEvent_data_Getter";

  static initTextEvent_Callback_DOMString_boolean_boolean_Window_DOMString(mthis, typeArg, canBubbleArg, cancelableArg, viewArg, dataArg) native "TextEvent_initTextEvent_Callback_DOMString_boolean_boolean_Window_DOMString";
}

class BlinkTextMetrics {
  static actualBoundingBoxAscent_Getter(mthis) native "TextMetrics_actualBoundingBoxAscent_Getter";

  static actualBoundingBoxDescent_Getter(mthis) native "TextMetrics_actualBoundingBoxDescent_Getter";

  static actualBoundingBoxLeft_Getter(mthis) native "TextMetrics_actualBoundingBoxLeft_Getter";

  static actualBoundingBoxRight_Getter(mthis) native "TextMetrics_actualBoundingBoxRight_Getter";

  static alphabeticBaseline_Getter(mthis) native "TextMetrics_alphabeticBaseline_Getter";

  static emHeightAscent_Getter(mthis) native "TextMetrics_emHeightAscent_Getter";

  static emHeightDescent_Getter(mthis) native "TextMetrics_emHeightDescent_Getter";

  static fontBoundingBoxAscent_Getter(mthis) native "TextMetrics_fontBoundingBoxAscent_Getter";

  static fontBoundingBoxDescent_Getter(mthis) native "TextMetrics_fontBoundingBoxDescent_Getter";

  static hangingBaseline_Getter(mthis) native "TextMetrics_hangingBaseline_Getter";

  static ideographicBaseline_Getter(mthis) native "TextMetrics_ideographicBaseline_Getter";

  static width_Getter(mthis) native "TextMetrics_width_Getter";
}

class BlinkTextTrack {
  static activeCues_Getter(mthis) native "TextTrack_activeCues_Getter";

  static cues_Getter(mthis) native "TextTrack_cues_Getter";

  static id_Getter(mthis) native "TextTrack_id_Getter";

  static kind_Getter(mthis) native "TextTrack_kind_Getter";

  static label_Getter(mthis) native "TextTrack_label_Getter";

  static language_Getter(mthis) native "TextTrack_language_Getter";

  static mode_Getter(mthis) native "TextTrack_mode_Getter";

  static mode_Setter_DOMString(mthis, value) native "TextTrack_mode_Setter";

  static regions_Getter(mthis) native "TextTrack_regions_Getter";

  static addCue_Callback_TextTrackCue(mthis, cue) native "TextTrack_addCue_Callback_TextTrackCue";

  static addRegion_Callback_VTTRegion(mthis, region) native "TextTrack_addRegion_Callback_VTTRegion";

  static removeCue_Callback_TextTrackCue(mthis, cue) native "TextTrack_removeCue_Callback_TextTrackCue";

  static removeRegion_Callback_VTTRegion(mthis, region) native "TextTrack_removeRegion_Callback_VTTRegion";
}

class BlinkTextTrackCue {
  static endTime_Getter(mthis) native "TextTrackCue_endTime_Getter";

  static endTime_Setter_double(mthis, value) native "TextTrackCue_endTime_Setter";

  static id_Getter(mthis) native "TextTrackCue_id_Getter";

  static id_Setter_DOMString(mthis, value) native "TextTrackCue_id_Setter";

  static pauseOnExit_Getter(mthis) native "TextTrackCue_pauseOnExit_Getter";

  static pauseOnExit_Setter_boolean(mthis, value) native "TextTrackCue_pauseOnExit_Setter";

  static startTime_Getter(mthis) native "TextTrackCue_startTime_Getter";

  static startTime_Setter_double(mthis, value) native "TextTrackCue_startTime_Setter";

  static track_Getter(mthis) native "TextTrackCue_track_Getter";
}

class BlinkTextTrackCueList {
  static length_Getter(mthis) native "TextTrackCueList_length_Getter";

  static getCueById_Callback_DOMString(mthis, id) native "TextTrackCueList_getCueById_Callback_DOMString";

  static item_Callback_ul(mthis, index) native "TextTrackCueList_item_Callback_unsigned long";
}

class BlinkTextTrackList {
  static length_Getter(mthis) native "TextTrackList_length_Getter";

  static getTrackById_Callback_DOMString(mthis, id) native "TextTrackList_getTrackById_Callback_DOMString";

  static item_Callback_ul(mthis, index) native "TextTrackList_item_Callback_unsigned long";
}

class BlinkTimeRanges {
  static length_Getter(mthis) native "TimeRanges_length_Getter";

  static end_Callback_ul(mthis, index) native "TimeRanges_end_Callback_unsigned long";

  static start_Callback_ul(mthis, index) native "TimeRanges_start_Callback_unsigned long";
}

class BlinkTiming {
  static delay_Getter(mthis) native "Timing_delay_Getter";

  static delay_Setter_double(mthis, value) native "Timing_delay_Setter";

  static direction_Getter(mthis) native "Timing_direction_Getter";

  static direction_Setter_DOMString(mthis, value) native "Timing_direction_Setter";

  static easing_Getter(mthis) native "Timing_easing_Getter";

  static easing_Setter_DOMString(mthis, value) native "Timing_easing_Setter";

  static endDelay_Getter(mthis) native "Timing_endDelay_Getter";

  static endDelay_Setter_double(mthis, value) native "Timing_endDelay_Setter";

  static fill_Getter(mthis) native "Timing_fill_Getter";

  static fill_Setter_DOMString(mthis, value) native "Timing_fill_Setter";

  static iterationStart_Getter(mthis) native "Timing_iterationStart_Getter";

  static iterationStart_Setter_double(mthis, value) native "Timing_iterationStart_Setter";

  static iterations_Getter(mthis) native "Timing_iterations_Getter";

  static iterations_Setter_double(mthis, value) native "Timing_iterations_Setter";

  static playbackRate_Getter(mthis) native "Timing_playbackRate_Getter";

  static playbackRate_Setter_double(mthis, value) native "Timing_playbackRate_Setter";

  static $__getter___Callback_DOMString(mthis, name) native "Timing___getter___Callback_DOMString";

  static $__setter___Callback_DOMString_double(mthis, name, duration) native "Timing___setter___Callback_DOMString_double";
}

class BlinkTouch {
  static clientX_Getter(mthis) native "Touch_clientX_Getter";

  static clientY_Getter(mthis) native "Touch_clientY_Getter";

  static identifier_Getter(mthis) native "Touch_identifier_Getter";

  static pageX_Getter(mthis) native "Touch_pageX_Getter";

  static pageY_Getter(mthis) native "Touch_pageY_Getter";

  static screenX_Getter(mthis) native "Touch_screenX_Getter";

  static screenY_Getter(mthis) native "Touch_screenY_Getter";

  static target_Getter(mthis) native "Touch_target_Getter";

  static webkitForce_Getter(mthis) native "Touch_webkitForce_Getter";

  static webkitRadiusX_Getter(mthis) native "Touch_webkitRadiusX_Getter";

  static webkitRadiusY_Getter(mthis) native "Touch_webkitRadiusY_Getter";

  static webkitRotationAngle_Getter(mthis) native "Touch_webkitRotationAngle_Getter";
}

class BlinkTouchEvent {
  static altKey_Getter(mthis) native "TouchEvent_altKey_Getter";

  static changedTouches_Getter(mthis) native "TouchEvent_changedTouches_Getter";

  static ctrlKey_Getter(mthis) native "TouchEvent_ctrlKey_Getter";

  static metaKey_Getter(mthis) native "TouchEvent_metaKey_Getter";

  static shiftKey_Getter(mthis) native "TouchEvent_shiftKey_Getter";

  static targetTouches_Getter(mthis) native "TouchEvent_targetTouches_Getter";

  static touches_Getter(mthis) native "TouchEvent_touches_Getter";

  static initTouchEvent_Callback_TouchList_TouchList_TouchList_DOMString_Window_long_long_long_long_boolean_boolean_boolean_boolean(mthis, touches, targetTouches, changedTouches, type, view, unused1, unused2, unused3, unused4, ctrlKey, altKey, shiftKey, metaKey) native "TouchEvent_initTouchEvent_Callback_TouchList_TouchList_TouchList_DOMString_Window_long_long_long_long_boolean_boolean_boolean_boolean";
}

class BlinkTouchList {
  static length_Getter(mthis) native "TouchList_length_Getter";

  static item_Callback_ul(mthis, index) native "TouchList_item_Callback_unsigned long";
}

class BlinkTrackEvent {
  static track_Getter(mthis) native "TrackEvent_track_Getter";
}

class BlinkTransitionEvent {
  static elapsedTime_Getter(mthis) native "TransitionEvent_elapsedTime_Getter";

  static propertyName_Getter(mthis) native "TransitionEvent_propertyName_Getter";

  static pseudoElement_Getter(mthis) native "TransitionEvent_pseudoElement_Getter";
}

class BlinkTreeWalker {
  static currentNode_Getter(mthis) native "TreeWalker_currentNode_Getter";

  static currentNode_Setter_Node(mthis, value) native "TreeWalker_currentNode_Setter";

  static filter_Getter(mthis) native "TreeWalker_filter_Getter";

  static root_Getter(mthis) native "TreeWalker_root_Getter";

  static whatToShow_Getter(mthis) native "TreeWalker_whatToShow_Getter";

  static firstChild_Callback(mthis) native "TreeWalker_firstChild_Callback";

  static lastChild_Callback(mthis) native "TreeWalker_lastChild_Callback";

  static nextNode_Callback(mthis) native "TreeWalker_nextNode_Callback";

  static nextSibling_Callback(mthis) native "TreeWalker_nextSibling_Callback";

  static parentNode_Callback(mthis) native "TreeWalker_parentNode_Callback";

  static previousNode_Callback(mthis) native "TreeWalker_previousNode_Callback";

  static previousSibling_Callback(mthis) native "TreeWalker_previousSibling_Callback";
}

class BlinkURL {
  static createObjectURL_Callback_Blob(blob_OR_source_OR_stream) native "URL_createObjectURL_Callback_Blob";

  static createObjectURL_Callback_MediaStream(blob_OR_source_OR_stream) native "URL_createObjectURL_Callback_MediaStream";

  static createObjectURL_Callback_MediaSource(blob_OR_source_OR_stream) native "URL_createObjectURL_Callback_MediaSource";

  static revokeObjectURL_Callback_DOMString(url) native "URL_revokeObjectURL_Callback_DOMString";

  static hash_Getter(mthis) native "URL_hash_Getter";

  static hash_Setter_DOMString(mthis, value) native "URL_hash_Setter";

  static host_Getter(mthis) native "URL_host_Getter";

  static host_Setter_DOMString(mthis, value) native "URL_host_Setter";

  static hostname_Getter(mthis) native "URL_hostname_Getter";

  static hostname_Setter_DOMString(mthis, value) native "URL_hostname_Setter";

  static href_Getter(mthis) native "URL_href_Getter";

  static href_Setter_DOMString(mthis, value) native "URL_href_Setter";

  static origin_Getter(mthis) native "URL_origin_Getter";

  static password_Getter(mthis) native "URL_password_Getter";

  static password_Setter_DOMString(mthis, value) native "URL_password_Setter";

  static pathname_Getter(mthis) native "URL_pathname_Getter";

  static pathname_Setter_DOMString(mthis, value) native "URL_pathname_Setter";

  static port_Getter(mthis) native "URL_port_Getter";

  static port_Setter_DOMString(mthis, value) native "URL_port_Setter";

  static protocol_Getter(mthis) native "URL_protocol_Getter";

  static protocol_Setter_DOMString(mthis, value) native "URL_protocol_Setter";

  static search_Getter(mthis) native "URL_search_Getter";

  static search_Setter_DOMString(mthis, value) native "URL_search_Setter";

  static username_Getter(mthis) native "URL_username_Getter";

  static username_Setter_DOMString(mthis, value) native "URL_username_Setter";

  static toString_Callback(mthis) native "URL_toString_Callback";
}

class BlinkURLUtilsReadOnly {
  static hash_Getter(mthis) native "WorkerLocation_hash_Getter";

  static host_Getter(mthis) native "WorkerLocation_host_Getter";

  static hostname_Getter(mthis) native "WorkerLocation_hostname_Getter";

  static href_Getter(mthis) native "WorkerLocation_href_Getter";

  static pathname_Getter(mthis) native "WorkerLocation_pathname_Getter";

  static port_Getter(mthis) native "WorkerLocation_port_Getter";

  static protocol_Getter(mthis) native "WorkerLocation_protocol_Getter";

  static search_Getter(mthis) native "WorkerLocation_search_Getter";

  static toString_Callback(mthis) native "WorkerLocation_toString_Callback";
}

class BlinkVTTCue {
  static constructorCallback_double_double_DOMString(startTime, endTime, text) native "VTTCue_constructorCallback_double_double_DOMString";

  static align_Getter(mthis) native "VTTCue_align_Getter";

  static align_Setter_DOMString(mthis, value) native "VTTCue_align_Setter";

  static line_Getter(mthis) native "VTTCue_line_Getter";

  static line_Setter_long(mthis, value) native "VTTCue_line_Setter";

  static position_Getter(mthis) native "VTTCue_position_Getter";

  static position_Setter_long(mthis, value) native "VTTCue_position_Setter";

  static regionId_Getter(mthis) native "VTTCue_regionId_Getter";

  static regionId_Setter_DOMString(mthis, value) native "VTTCue_regionId_Setter";

  static size_Getter(mthis) native "VTTCue_size_Getter";

  static size_Setter_long(mthis, value) native "VTTCue_size_Setter";

  static snapToLines_Getter(mthis) native "VTTCue_snapToLines_Getter";

  static snapToLines_Setter_boolean(mthis, value) native "VTTCue_snapToLines_Setter";

  static text_Getter(mthis) native "VTTCue_text_Getter";

  static text_Setter_DOMString(mthis, value) native "VTTCue_text_Setter";

  static vertical_Getter(mthis) native "VTTCue_vertical_Getter";

  static vertical_Setter_DOMString(mthis, value) native "VTTCue_vertical_Setter";

  static getCueAsHTML_Callback(mthis) native "VTTCue_getCueAsHTML_Callback";
}

class BlinkVTTRegion {
  static constructorCallback() native "VTTRegion_constructorCallback";

  static height_Getter(mthis) native "VTTRegion_height_Getter";

  static height_Setter_long(mthis, value) native "VTTRegion_height_Setter";

  static id_Getter(mthis) native "VTTRegion_id_Getter";

  static id_Setter_DOMString(mthis, value) native "VTTRegion_id_Setter";

  static regionAnchorX_Getter(mthis) native "VTTRegion_regionAnchorX_Getter";

  static regionAnchorX_Setter_double(mthis, value) native "VTTRegion_regionAnchorX_Setter";

  static regionAnchorY_Getter(mthis) native "VTTRegion_regionAnchorY_Getter";

  static regionAnchorY_Setter_double(mthis, value) native "VTTRegion_regionAnchorY_Setter";

  static scroll_Getter(mthis) native "VTTRegion_scroll_Getter";

  static scroll_Setter_DOMString(mthis, value) native "VTTRegion_scroll_Setter";

  static track_Getter(mthis) native "VTTRegion_track_Getter";

  static viewportAnchorX_Getter(mthis) native "VTTRegion_viewportAnchorX_Getter";

  static viewportAnchorX_Setter_double(mthis, value) native "VTTRegion_viewportAnchorX_Setter";

  static viewportAnchorY_Getter(mthis) native "VTTRegion_viewportAnchorY_Getter";

  static viewportAnchorY_Setter_double(mthis, value) native "VTTRegion_viewportAnchorY_Setter";

  static width_Getter(mthis) native "VTTRegion_width_Getter";

  static width_Setter_double(mthis, value) native "VTTRegion_width_Setter";
}

class BlinkVTTRegionList {
  static length_Getter(mthis) native "VTTRegionList_length_Getter";

  static getRegionById_Callback_DOMString(mthis, id) native "VTTRegionList_getRegionById_Callback_DOMString";

  static item_Callback_ul(mthis, index) native "VTTRegionList_item_Callback_unsigned long";
}

class BlinkValidityState {
  static badInput_Getter(mthis) native "ValidityState_badInput_Getter";

  static customError_Getter(mthis) native "ValidityState_customError_Getter";

  static patternMismatch_Getter(mthis) native "ValidityState_patternMismatch_Getter";

  static rangeOverflow_Getter(mthis) native "ValidityState_rangeOverflow_Getter";

  static rangeUnderflow_Getter(mthis) native "ValidityState_rangeUnderflow_Getter";

  static stepMismatch_Getter(mthis) native "ValidityState_stepMismatch_Getter";

  static tooLong_Getter(mthis) native "ValidityState_tooLong_Getter";

  static typeMismatch_Getter(mthis) native "ValidityState_typeMismatch_Getter";

  static valid_Getter(mthis) native "ValidityState_valid_Getter";

  static valueMissing_Getter(mthis) native "ValidityState_valueMissing_Getter";
}

class BlinkVideoPlaybackQuality {
  static corruptedVideoFrames_Getter(mthis) native "VideoPlaybackQuality_corruptedVideoFrames_Getter";

  static creationTime_Getter(mthis) native "VideoPlaybackQuality_creationTime_Getter";

  static droppedVideoFrames_Getter(mthis) native "VideoPlaybackQuality_droppedVideoFrames_Getter";

  static totalVideoFrames_Getter(mthis) native "VideoPlaybackQuality_totalVideoFrames_Getter";
}

class BlinkVideoTrack {
  static id_Getter(mthis) native "VideoTrack_id_Getter";

  static kind_Getter(mthis) native "VideoTrack_kind_Getter";

  static label_Getter(mthis) native "VideoTrack_label_Getter";

  static language_Getter(mthis) native "VideoTrack_language_Getter";

  static selected_Getter(mthis) native "VideoTrack_selected_Getter";

  static selected_Setter_boolean(mthis, value) native "VideoTrack_selected_Setter";
}

class BlinkVideoTrackList {
  static length_Getter(mthis) native "VideoTrackList_length_Getter";

  static selectedIndex_Getter(mthis) native "VideoTrackList_selectedIndex_Getter";

  static $__getter___Callback_ul(mthis, index) native "VideoTrackList___getter___Callback_unsigned long";

  static getTrackById_Callback_DOMString(mthis, id) native "VideoTrackList_getTrackById_Callback_DOMString";
}

class BlinkWaveShaperNode {
  static curve_Getter(mthis) native "WaveShaperNode_curve_Getter";

  static curve_Setter_Float32Array(mthis, value) native "WaveShaperNode_curve_Setter";

  static oversample_Getter(mthis) native "WaveShaperNode_oversample_Getter";

  static oversample_Setter_DOMString(mthis, value) native "WaveShaperNode_oversample_Setter";
}

class BlinkWebGLActiveInfo {
  static name_Getter(mthis) native "WebGLActiveInfo_name_Getter";

  static size_Getter(mthis) native "WebGLActiveInfo_size_Getter";

  static type_Getter(mthis) native "WebGLActiveInfo_type_Getter";
}

class BlinkWebGLBuffer {}

class BlinkWebGLCompressedTextureATC {}

class BlinkWebGLCompressedTextureETC1 {}

class BlinkWebGLCompressedTexturePVRTC {}

class BlinkWebGLCompressedTextureS3TC {}

class BlinkWebGLContextAttributes {
  static alpha_Getter(mthis) native "WebGLContextAttributes_alpha_Getter";

  static alpha_Setter_boolean(mthis, value) native "WebGLContextAttributes_alpha_Setter";

  static antialias_Getter(mthis) native "WebGLContextAttributes_antialias_Getter";

  static antialias_Setter_boolean(mthis, value) native "WebGLContextAttributes_antialias_Setter";

  static depth_Getter(mthis) native "WebGLContextAttributes_depth_Getter";

  static depth_Setter_boolean(mthis, value) native "WebGLContextAttributes_depth_Setter";

  static failIfMajorPerformanceCaveat_Getter(mthis) native "WebGLContextAttributes_failIfMajorPerformanceCaveat_Getter";

  static failIfMajorPerformanceCaveat_Setter_boolean(mthis, value) native "WebGLContextAttributes_failIfMajorPerformanceCaveat_Setter";

  static premultipliedAlpha_Getter(mthis) native "WebGLContextAttributes_premultipliedAlpha_Getter";

  static premultipliedAlpha_Setter_boolean(mthis, value) native "WebGLContextAttributes_premultipliedAlpha_Setter";

  static preserveDrawingBuffer_Getter(mthis) native "WebGLContextAttributes_preserveDrawingBuffer_Getter";

  static preserveDrawingBuffer_Setter_boolean(mthis, value) native "WebGLContextAttributes_preserveDrawingBuffer_Setter";

  static stencil_Getter(mthis) native "WebGLContextAttributes_stencil_Getter";

  static stencil_Setter_boolean(mthis, value) native "WebGLContextAttributes_stencil_Setter";
}

class BlinkWebGLContextEvent {
  static statusMessage_Getter(mthis) native "WebGLContextEvent_statusMessage_Getter";
}

class BlinkWebGLDebugRendererInfo {}

class BlinkWebGLDebugShaders {
  static getTranslatedShaderSource_Callback_WebGLShader(mthis, shader) native "WebGLDebugShaders_getTranslatedShaderSource_Callback_WebGLShader";
}

class BlinkWebGLDepthTexture {}

class BlinkWebGLDrawBuffers {}

class BlinkWebGLFramebuffer {}

class BlinkWebGLLoseContext {
  static loseContext_Callback(mthis) native "WebGLLoseContext_loseContext_Callback";

  static restoreContext_Callback(mthis) native "WebGLLoseContext_restoreContext_Callback";
}

class BlinkWebGLProgram {}

class BlinkWebGLRenderbuffer {}

class BlinkWebGLRenderingContextBase {
  static canvas_Getter(mthis) native "WebGLRenderingContextBase_canvas_Getter";

  static drawingBufferHeight_Getter(mthis) native "WebGLRenderingContextBase_drawingBufferHeight_Getter";

  static drawingBufferWidth_Getter(mthis) native "WebGLRenderingContextBase_drawingBufferWidth_Getter";

  static activeTexture_Callback_ul(mthis, texture) native "WebGLRenderingContextBase_activeTexture_Callback_unsigned long";

  static attachShader_Callback_WebGLProgram_WebGLShader(mthis, program, shader) native "WebGLRenderingContextBase_attachShader_Callback_WebGLProgram_WebGLShader";

  static bindAttribLocation_Callback_WebGLProgram_ul_DOMString(mthis, program, index, name) native "WebGLRenderingContextBase_bindAttribLocation_Callback_WebGLProgram_unsigned long_DOMString";

  static bindBuffer_Callback_ul_WebGLBuffer(mthis, target, buffer) native "WebGLRenderingContextBase_bindBuffer_Callback_unsigned long_WebGLBuffer";

  static bindFramebuffer_Callback_ul_WebGLFramebuffer(mthis, target, framebuffer) native "WebGLRenderingContextBase_bindFramebuffer_Callback_unsigned long_WebGLFramebuffer";

  static bindRenderbuffer_Callback_ul_WebGLRenderbuffer(mthis, target, renderbuffer) native "WebGLRenderingContextBase_bindRenderbuffer_Callback_unsigned long_WebGLRenderbuffer";

  static bindTexture_Callback_ul_WebGLTexture(mthis, target, texture) native "WebGLRenderingContextBase_bindTexture_Callback_unsigned long_WebGLTexture";

  static blendColor_Callback_float_float_float_float(mthis, red, green, blue, alpha) native "WebGLRenderingContextBase_blendColor_Callback_float_float_float_float";

  static blendEquation_Callback_ul(mthis, mode) native "WebGLRenderingContextBase_blendEquation_Callback_unsigned long";

  static blendEquationSeparate_Callback_ul_ul(mthis, modeRGB, modeAlpha) native "WebGLRenderingContextBase_blendEquationSeparate_Callback_unsigned long_unsigned long";

  static blendFunc_Callback_ul_ul(mthis, sfactor, dfactor) native "WebGLRenderingContextBase_blendFunc_Callback_unsigned long_unsigned long";

  static blendFuncSeparate_Callback_ul_ul_ul_ul(mthis, srcRGB, dstRGB, srcAlpha, dstAlpha) native "WebGLRenderingContextBase_blendFuncSeparate_Callback_unsigned long_unsigned long_unsigned long_unsigned long";

  static bufferData_Callback_ul_ArrayBuffer_ul(mthis, target, data, usage) native "WebGLRenderingContextBase_bufferData_Callback_unsigned long_ArrayBuffer_unsigned long";

  static bufferData_Callback_ul_ll_ul(mthis, target, data_OR_size, usage) native "WebGLRenderingContextBase_bufferData_Callback_unsigned long_long long_unsigned long";

  static bufferData_Callback_ul_ArrayBufferView_ul(mthis, target, data_OR_size, usage) native "WebGLRenderingContextBase_bufferData_Callback_unsigned long_ArrayBufferView_unsigned long";

  static bufferSubData_Callback_ul_ll_ArrayBuffer(mthis, target, offset, data) native "WebGLRenderingContextBase_bufferSubData_Callback_unsigned long_long long_ArrayBuffer";

  static bufferSubData_Callback_ul_ll_ArrayBufferView(mthis, target, offset, data) native "WebGLRenderingContextBase_bufferSubData_Callback_unsigned long_long long_ArrayBufferView";

  static checkFramebufferStatus_Callback_ul(mthis, target) native "WebGLRenderingContextBase_checkFramebufferStatus_Callback_unsigned long";

  static clear_Callback_ul(mthis, mask) native "WebGLRenderingContextBase_clear_Callback_unsigned long";

  static clearColor_Callback_float_float_float_float(mthis, red, green, blue, alpha) native "WebGLRenderingContextBase_clearColor_Callback_float_float_float_float";

  static clearDepth_Callback_float(mthis, depth) native "WebGLRenderingContextBase_clearDepth_Callback_float";

  static clearStencil_Callback_long(mthis, s) native "WebGLRenderingContextBase_clearStencil_Callback_long";

  static colorMask_Callback_boolean_boolean_boolean_boolean(mthis, red, green, blue, alpha) native "WebGLRenderingContextBase_colorMask_Callback_boolean_boolean_boolean_boolean";

  static compileShader_Callback_WebGLShader(mthis, shader) native "WebGLRenderingContextBase_compileShader_Callback_WebGLShader";

  static compressedTexImage2D_Callback_ul_long_ul_long_long_long_ArrayBufferView(mthis, target, level, internalformat, width, height, border, data) native "WebGLRenderingContextBase_compressedTexImage2D_Callback_unsigned long_long_unsigned long_long_long_long_ArrayBufferView";

  static compressedTexSubImage2D_Callback_ul_long_long_long_long_long_ul_ArrayBufferView(mthis, target, level, xoffset, yoffset, width, height, format, data) native "WebGLRenderingContextBase_compressedTexSubImage2D_Callback_unsigned long_long_long_long_long_long_unsigned long_ArrayBufferView";

  static copyTexImage2D_Callback_ul_long_ul_long_long_long_long_long(mthis, target, level, internalformat, x, y, width, height, border) native "WebGLRenderingContextBase_copyTexImage2D_Callback_unsigned long_long_unsigned long_long_long_long_long_long";

  static copyTexSubImage2D_Callback_ul_long_long_long_long_long_long_long(mthis, target, level, xoffset, yoffset, x, y, width, height) native "WebGLRenderingContextBase_copyTexSubImage2D_Callback_unsigned long_long_long_long_long_long_long_long";

  static createBuffer_Callback(mthis) native "WebGLRenderingContextBase_createBuffer_Callback";

  static createFramebuffer_Callback(mthis) native "WebGLRenderingContextBase_createFramebuffer_Callback";

  static createProgram_Callback(mthis) native "WebGLRenderingContextBase_createProgram_Callback";

  static createRenderbuffer_Callback(mthis) native "WebGLRenderingContextBase_createRenderbuffer_Callback";

  static createShader_Callback_ul(mthis, type) native "WebGLRenderingContextBase_createShader_Callback_unsigned long";

  static createTexture_Callback(mthis) native "WebGLRenderingContextBase_createTexture_Callback";

  static cullFace_Callback_ul(mthis, mode) native "WebGLRenderingContextBase_cullFace_Callback_unsigned long";

  static deleteBuffer_Callback_WebGLBuffer(mthis, buffer) native "WebGLRenderingContextBase_deleteBuffer_Callback_WebGLBuffer";

  static deleteFramebuffer_Callback_WebGLFramebuffer(mthis, framebuffer) native "WebGLRenderingContextBase_deleteFramebuffer_Callback_WebGLFramebuffer";

  static deleteProgram_Callback_WebGLProgram(mthis, program) native "WebGLRenderingContextBase_deleteProgram_Callback_WebGLProgram";

  static deleteRenderbuffer_Callback_WebGLRenderbuffer(mthis, renderbuffer) native "WebGLRenderingContextBase_deleteRenderbuffer_Callback_WebGLRenderbuffer";

  static deleteShader_Callback_WebGLShader(mthis, shader) native "WebGLRenderingContextBase_deleteShader_Callback_WebGLShader";

  static deleteTexture_Callback_WebGLTexture(mthis, texture) native "WebGLRenderingContextBase_deleteTexture_Callback_WebGLTexture";

  static depthFunc_Callback_ul(mthis, func) native "WebGLRenderingContextBase_depthFunc_Callback_unsigned long";

  static depthMask_Callback_boolean(mthis, flag) native "WebGLRenderingContextBase_depthMask_Callback_boolean";

  static depthRange_Callback_float_float(mthis, zNear, zFar) native "WebGLRenderingContextBase_depthRange_Callback_float_float";

  static detachShader_Callback_WebGLProgram_WebGLShader(mthis, program, shader) native "WebGLRenderingContextBase_detachShader_Callback_WebGLProgram_WebGLShader";

  static disable_Callback_ul(mthis, cap) native "WebGLRenderingContextBase_disable_Callback_unsigned long";

  static disableVertexAttribArray_Callback_ul(mthis, index) native "WebGLRenderingContextBase_disableVertexAttribArray_Callback_unsigned long";

  static drawArrays_Callback_ul_long_long(mthis, mode, first, count) native "WebGLRenderingContextBase_drawArrays_Callback_unsigned long_long_long";

  static drawElements_Callback_ul_long_ul_ll(mthis, mode, count, type, offset) native "WebGLRenderingContextBase_drawElements_Callback_unsigned long_long_unsigned long_long long";

  static enable_Callback_ul(mthis, cap) native "WebGLRenderingContextBase_enable_Callback_unsigned long";

  static enableVertexAttribArray_Callback_ul(mthis, index) native "WebGLRenderingContextBase_enableVertexAttribArray_Callback_unsigned long";

  static finish_Callback(mthis) native "WebGLRenderingContextBase_finish_Callback";

  static flush_Callback(mthis) native "WebGLRenderingContextBase_flush_Callback";

  static framebufferRenderbuffer_Callback_ul_ul_ul_WebGLRenderbuffer(mthis, target, attachment, renderbuffertarget, renderbuffer) native "WebGLRenderingContextBase_framebufferRenderbuffer_Callback_unsigned long_unsigned long_unsigned long_WebGLRenderbuffer";

  static framebufferTexture2D_Callback_ul_ul_ul_WebGLTexture_long(mthis, target, attachment, textarget, texture, level) native "WebGLRenderingContextBase_framebufferTexture2D_Callback_unsigned long_unsigned long_unsigned long_WebGLTexture_long";

  static frontFace_Callback_ul(mthis, mode) native "WebGLRenderingContextBase_frontFace_Callback_unsigned long";

  static generateMipmap_Callback_ul(mthis, target) native "WebGLRenderingContextBase_generateMipmap_Callback_unsigned long";

  static getActiveAttrib_Callback_WebGLProgram_ul(mthis, program, index) native "WebGLRenderingContextBase_getActiveAttrib_Callback_WebGLProgram_unsigned long";

  static getActiveUniform_Callback_WebGLProgram_ul(mthis, program, index) native "WebGLRenderingContextBase_getActiveUniform_Callback_WebGLProgram_unsigned long";

  static getAttachedShaders_Callback_WebGLProgram(mthis, program) native "WebGLRenderingContextBase_getAttachedShaders_Callback";

  static getAttribLocation_Callback_WebGLProgram_DOMString(mthis, program, name) native "WebGLRenderingContextBase_getAttribLocation_Callback_WebGLProgram_DOMString";

  static getBufferParameter_Callback_ul_ul(mthis, target, pname) native "WebGLRenderingContextBase_getBufferParameter_Callback";

  static getContextAttributes_Callback(mthis) native "WebGLRenderingContextBase_getContextAttributes_Callback";

  static getError_Callback(mthis) native "WebGLRenderingContextBase_getError_Callback";

  static getExtension_Callback_DOMString(mthis, name) native "WebGLRenderingContextBase_getExtension_Callback";

  static getFramebufferAttachmentParameter_Callback_ul_ul_ul(mthis, target, attachment, pname) native "WebGLRenderingContextBase_getFramebufferAttachmentParameter_Callback";

  static getParameter_Callback_ul(mthis, pname) native "WebGLRenderingContextBase_getParameter_Callback";

  static getProgramInfoLog_Callback_WebGLProgram(mthis, program) native "WebGLRenderingContextBase_getProgramInfoLog_Callback_WebGLProgram";

  static getProgramParameter_Callback_WebGLProgram_ul(mthis, program, pname) native "WebGLRenderingContextBase_getProgramParameter_Callback";

  static getRenderbufferParameter_Callback_ul_ul(mthis, target, pname) native "WebGLRenderingContextBase_getRenderbufferParameter_Callback";

  static getShaderInfoLog_Callback_WebGLShader(mthis, shader) native "WebGLRenderingContextBase_getShaderInfoLog_Callback_WebGLShader";

  static getShaderParameter_Callback_WebGLShader_ul(mthis, shader, pname) native "WebGLRenderingContextBase_getShaderParameter_Callback";

  static getShaderPrecisionFormat_Callback_ul_ul(mthis, shadertype, precisiontype) native "WebGLRenderingContextBase_getShaderPrecisionFormat_Callback_unsigned long_unsigned long";

  static getShaderSource_Callback_WebGLShader(mthis, shader) native "WebGLRenderingContextBase_getShaderSource_Callback_WebGLShader";

  static getSupportedExtensions_Callback(mthis) native "WebGLRenderingContextBase_getSupportedExtensions_Callback";

  static getTexParameter_Callback_ul_ul(mthis, target, pname) native "WebGLRenderingContextBase_getTexParameter_Callback";

  static getUniform_Callback_WebGLProgram_WebGLUniformLocation(mthis, program, location) native "WebGLRenderingContextBase_getUniform_Callback";

  static getUniformLocation_Callback_WebGLProgram_DOMString(mthis, program, name) native "WebGLRenderingContextBase_getUniformLocation_Callback_WebGLProgram_DOMString";

  static getVertexAttrib_Callback_ul_ul(mthis, index, pname) native "WebGLRenderingContextBase_getVertexAttrib_Callback";

  static getVertexAttribOffset_Callback_ul_ul(mthis, index, pname) native "WebGLRenderingContextBase_getVertexAttribOffset_Callback_unsigned long_unsigned long";

  static hint_Callback_ul_ul(mthis, target, mode) native "WebGLRenderingContextBase_hint_Callback_unsigned long_unsigned long";

  static isBuffer_Callback_WebGLBuffer(mthis, buffer) native "WebGLRenderingContextBase_isBuffer_Callback_WebGLBuffer";

  static isContextLost_Callback(mthis) native "WebGLRenderingContextBase_isContextLost_Callback";

  static isEnabled_Callback_ul(mthis, cap) native "WebGLRenderingContextBase_isEnabled_Callback_unsigned long";

  static isFramebuffer_Callback_WebGLFramebuffer(mthis, framebuffer) native "WebGLRenderingContextBase_isFramebuffer_Callback_WebGLFramebuffer";

  static isProgram_Callback_WebGLProgram(mthis, program) native "WebGLRenderingContextBase_isProgram_Callback_WebGLProgram";

  static isRenderbuffer_Callback_WebGLRenderbuffer(mthis, renderbuffer) native "WebGLRenderingContextBase_isRenderbuffer_Callback_WebGLRenderbuffer";

  static isShader_Callback_WebGLShader(mthis, shader) native "WebGLRenderingContextBase_isShader_Callback_WebGLShader";

  static isTexture_Callback_WebGLTexture(mthis, texture) native "WebGLRenderingContextBase_isTexture_Callback_WebGLTexture";

  static lineWidth_Callback_float(mthis, width) native "WebGLRenderingContextBase_lineWidth_Callback_float";

  static linkProgram_Callback_WebGLProgram(mthis, program) native "WebGLRenderingContextBase_linkProgram_Callback_WebGLProgram";

  static pixelStorei_Callback_ul_long(mthis, pname, param) native "WebGLRenderingContextBase_pixelStorei_Callback_unsigned long_long";

  static polygonOffset_Callback_float_float(mthis, factor, units) native "WebGLRenderingContextBase_polygonOffset_Callback_float_float";

  static readPixels_Callback_long_long_long_long_ul_ul_ArrayBufferView(mthis, x, y, width, height, format, type, pixels) native "WebGLRenderingContextBase_readPixels_Callback_long_long_long_long_unsigned long_unsigned long_ArrayBufferView";

  static renderbufferStorage_Callback_ul_ul_long_long(mthis, target, internalformat, width, height) native "WebGLRenderingContextBase_renderbufferStorage_Callback_unsigned long_unsigned long_long_long";

  static sampleCoverage_Callback_float_boolean(mthis, value, invert) native "WebGLRenderingContextBase_sampleCoverage_Callback_float_boolean";

  static scissor_Callback_long_long_long_long(mthis, x, y, width, height) native "WebGLRenderingContextBase_scissor_Callback_long_long_long_long";

  static shaderSource_Callback_WebGLShader_DOMString(mthis, shader, string) native "WebGLRenderingContextBase_shaderSource_Callback_WebGLShader_DOMString";

  static stencilFunc_Callback_ul_long_ul(mthis, func, ref, mask) native "WebGLRenderingContextBase_stencilFunc_Callback_unsigned long_long_unsigned long";

  static stencilFuncSeparate_Callback_ul_ul_long_ul(mthis, face, func, ref, mask) native "WebGLRenderingContextBase_stencilFuncSeparate_Callback_unsigned long_unsigned long_long_unsigned long";

  static stencilMask_Callback_ul(mthis, mask) native "WebGLRenderingContextBase_stencilMask_Callback_unsigned long";

  static stencilMaskSeparate_Callback_ul_ul(mthis, face, mask) native "WebGLRenderingContextBase_stencilMaskSeparate_Callback_unsigned long_unsigned long";

  static stencilOp_Callback_ul_ul_ul(mthis, fail, zfail, zpass) native "WebGLRenderingContextBase_stencilOp_Callback_unsigned long_unsigned long_unsigned long";

  static stencilOpSeparate_Callback_ul_ul_ul_ul(mthis, face, fail, zfail, zpass) native "WebGLRenderingContextBase_stencilOpSeparate_Callback_unsigned long_unsigned long_unsigned long_unsigned long";

  static texImage2D_Callback_ul_long_ul_long_long_long_ul_ul_ArrayBufferView(mthis, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video, format, type, pixels) native "WebGLRenderingContextBase_texImage2D_Callback_unsigned long_long_unsigned long_long_long_long_unsigned long_unsigned long_ArrayBufferView";

  static texImage2D_Callback_ul_long_ul_ul_ul_ImageData(mthis, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video) native "WebGLRenderingContextBase_texImage2D_Callback_unsigned long_long_unsigned long_unsigned long_unsigned long_ImageData";

  static texImage2D_Callback_ul_long_ul_ul_ul_HTMLImageElement(mthis, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video) native "WebGLRenderingContextBase_texImage2D_Callback_unsigned long_long_unsigned long_unsigned long_unsigned long_HTMLImageElement";

  static texImage2D_Callback_ul_long_ul_ul_ul_HTMLCanvasElement(mthis, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video) native "WebGLRenderingContextBase_texImage2D_Callback_unsigned long_long_unsigned long_unsigned long_unsigned long_HTMLCanvasElement";

  static texImage2D_Callback_ul_long_ul_ul_ul_HTMLVideoElement(mthis, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video) native "WebGLRenderingContextBase_texImage2D_Callback_unsigned long_long_unsigned long_unsigned long_unsigned long_HTMLVideoElement";

  static texParameterf_Callback_ul_ul_float(mthis, target, pname, param) native "WebGLRenderingContextBase_texParameterf_Callback_unsigned long_unsigned long_float";

  static texParameteri_Callback_ul_ul_long(mthis, target, pname, param) native "WebGLRenderingContextBase_texParameteri_Callback_unsigned long_unsigned long_long";

  static texSubImage2D_Callback_ul_long_long_long_long_long_ul_ul_ArrayBufferView(mthis, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video, type, pixels) native "WebGLRenderingContextBase_texSubImage2D_Callback_unsigned long_long_long_long_long_long_unsigned long_unsigned long_ArrayBufferView";

  static texSubImage2D_Callback_ul_long_long_long_ul_ul_ImageData(mthis, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video) native "WebGLRenderingContextBase_texSubImage2D_Callback_unsigned long_long_long_long_unsigned long_unsigned long_ImageData";

  static texSubImage2D_Callback_ul_long_long_long_ul_ul_HTMLImageElement(mthis, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video) native "WebGLRenderingContextBase_texSubImage2D_Callback_unsigned long_long_long_long_unsigned long_unsigned long_HTMLImageElement";

  static texSubImage2D_Callback_ul_long_long_long_ul_ul_HTMLCanvasElement(mthis, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video) native "WebGLRenderingContextBase_texSubImage2D_Callback_unsigned long_long_long_long_unsigned long_unsigned long_HTMLCanvasElement";

  static texSubImage2D_Callback_ul_long_long_long_ul_ul_HTMLVideoElement(mthis, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video) native "WebGLRenderingContextBase_texSubImage2D_Callback_unsigned long_long_long_long_unsigned long_unsigned long_HTMLVideoElement";

  static uniform1f_Callback_WebGLUniformLocation_float(mthis, location, x) native "WebGLRenderingContextBase_uniform1f_Callback_WebGLUniformLocation_float";

  static uniform1fv_Callback_WebGLUniformLocation_Float32Array(mthis, location, v) native "WebGLRenderingContextBase_uniform1fv_Callback";

  static uniform1i_Callback_WebGLUniformLocation_long(mthis, location, x) native "WebGLRenderingContextBase_uniform1i_Callback_WebGLUniformLocation_long";

  static uniform1iv_Callback_WebGLUniformLocation_Int32Array(mthis, location, v) native "WebGLRenderingContextBase_uniform1iv_Callback";

  static uniform2f_Callback_WebGLUniformLocation_float_float(mthis, location, x, y) native "WebGLRenderingContextBase_uniform2f_Callback_WebGLUniformLocation_float_float";

  static uniform2fv_Callback_WebGLUniformLocation_Float32Array(mthis, location, v) native "WebGLRenderingContextBase_uniform2fv_Callback";

  static uniform2i_Callback_WebGLUniformLocation_long_long(mthis, location, x, y) native "WebGLRenderingContextBase_uniform2i_Callback_WebGLUniformLocation_long_long";

  static uniform2iv_Callback_WebGLUniformLocation_Int32Array(mthis, location, v) native "WebGLRenderingContextBase_uniform2iv_Callback";

  static uniform3f_Callback_WebGLUniformLocation_float_float_float(mthis, location, x, y, z) native "WebGLRenderingContextBase_uniform3f_Callback_WebGLUniformLocation_float_float_float";

  static uniform3fv_Callback_WebGLUniformLocation_Float32Array(mthis, location, v) native "WebGLRenderingContextBase_uniform3fv_Callback";

  static uniform3i_Callback_WebGLUniformLocation_long_long_long(mthis, location, x, y, z) native "WebGLRenderingContextBase_uniform3i_Callback_WebGLUniformLocation_long_long_long";

  static uniform3iv_Callback_WebGLUniformLocation_Int32Array(mthis, location, v) native "WebGLRenderingContextBase_uniform3iv_Callback";

  static uniform4f_Callback_WebGLUniformLocation_float_float_float_float(mthis, location, x, y, z, w) native "WebGLRenderingContextBase_uniform4f_Callback_WebGLUniformLocation_float_float_float_float";

  static uniform4fv_Callback_WebGLUniformLocation_Float32Array(mthis, location, v) native "WebGLRenderingContextBase_uniform4fv_Callback";

  static uniform4i_Callback_WebGLUniformLocation_long_long_long_long(mthis, location, x, y, z, w) native "WebGLRenderingContextBase_uniform4i_Callback_WebGLUniformLocation_long_long_long_long";

  static uniform4iv_Callback_WebGLUniformLocation_Int32Array(mthis, location, v) native "WebGLRenderingContextBase_uniform4iv_Callback";

  static uniformMatrix2fv_Callback_WebGLUniformLocation_boolean_Float32Array(mthis, location, transpose, array) native "WebGLRenderingContextBase_uniformMatrix2fv_Callback";

  static uniformMatrix3fv_Callback_WebGLUniformLocation_boolean_Float32Array(mthis, location, transpose, array) native "WebGLRenderingContextBase_uniformMatrix3fv_Callback";

  static uniformMatrix4fv_Callback_WebGLUniformLocation_boolean_Float32Array(mthis, location, transpose, array) native "WebGLRenderingContextBase_uniformMatrix4fv_Callback";

  static useProgram_Callback_WebGLProgram(mthis, program) native "WebGLRenderingContextBase_useProgram_Callback_WebGLProgram";

  static validateProgram_Callback_WebGLProgram(mthis, program) native "WebGLRenderingContextBase_validateProgram_Callback_WebGLProgram";

  static vertexAttrib1f_Callback_ul_float(mthis, indx, x) native "WebGLRenderingContextBase_vertexAttrib1f_Callback_unsigned long_float";

  static vertexAttrib1fv_Callback_ul_Float32Array(mthis, indx, values) native "WebGLRenderingContextBase_vertexAttrib1fv_Callback";

  static vertexAttrib2f_Callback_ul_float_float(mthis, indx, x, y) native "WebGLRenderingContextBase_vertexAttrib2f_Callback_unsigned long_float_float";

  static vertexAttrib2fv_Callback_ul_Float32Array(mthis, indx, values) native "WebGLRenderingContextBase_vertexAttrib2fv_Callback";

  static vertexAttrib3f_Callback_ul_float_float_float(mthis, indx, x, y, z) native "WebGLRenderingContextBase_vertexAttrib3f_Callback_unsigned long_float_float_float";

  static vertexAttrib3fv_Callback_ul_Float32Array(mthis, indx, values) native "WebGLRenderingContextBase_vertexAttrib3fv_Callback";

  static vertexAttrib4f_Callback_ul_float_float_float_float(mthis, indx, x, y, z, w) native "WebGLRenderingContextBase_vertexAttrib4f_Callback_unsigned long_float_float_float_float";

  static vertexAttrib4fv_Callback_ul_Float32Array(mthis, indx, values) native "WebGLRenderingContextBase_vertexAttrib4fv_Callback";

  static vertexAttribPointer_Callback_ul_long_ul_boolean_long_ll(mthis, indx, size, type, normalized, stride, offset) native "WebGLRenderingContextBase_vertexAttribPointer_Callback_unsigned long_long_unsigned long_boolean_long_long long";

  static viewport_Callback_long_long_long_long(mthis, x, y, width, height) native "WebGLRenderingContextBase_viewport_Callback_long_long_long_long";
}

class BlinkWebGLRenderingContext {
  static canvas_Getter(mthis) native "WebGLRenderingContext_canvas_Getter";

  static drawingBufferHeight_Getter(mthis) native "WebGLRenderingContext_drawingBufferHeight_Getter";

  static drawingBufferWidth_Getter(mthis) native "WebGLRenderingContext_drawingBufferWidth_Getter";

  static activeTexture_Callback_ul(mthis, texture) native "WebGLRenderingContext_activeTexture_Callback_unsigned long";

  static attachShader_Callback_WebGLProgram_WebGLShader(mthis, program, shader) native "WebGLRenderingContext_attachShader_Callback_WebGLProgram_WebGLShader";

  static bindAttribLocation_Callback_WebGLProgram_ul_DOMString(mthis, program, index, name) native "WebGLRenderingContext_bindAttribLocation_Callback_WebGLProgram_unsigned long_DOMString";

  static bindBuffer_Callback_ul_WebGLBuffer(mthis, target, buffer) native "WebGLRenderingContext_bindBuffer_Callback_unsigned long_WebGLBuffer";

  static bindFramebuffer_Callback_ul_WebGLFramebuffer(mthis, target, framebuffer) native "WebGLRenderingContext_bindFramebuffer_Callback_unsigned long_WebGLFramebuffer";

  static bindRenderbuffer_Callback_ul_WebGLRenderbuffer(mthis, target, renderbuffer) native "WebGLRenderingContext_bindRenderbuffer_Callback_unsigned long_WebGLRenderbuffer";

  static bindTexture_Callback_ul_WebGLTexture(mthis, target, texture) native "WebGLRenderingContext_bindTexture_Callback_unsigned long_WebGLTexture";

  static blendColor_Callback_float_float_float_float(mthis, red, green, blue, alpha) native "WebGLRenderingContext_blendColor_Callback_float_float_float_float";

  static blendEquation_Callback_ul(mthis, mode) native "WebGLRenderingContext_blendEquation_Callback_unsigned long";

  static blendEquationSeparate_Callback_ul_ul(mthis, modeRGB, modeAlpha) native "WebGLRenderingContext_blendEquationSeparate_Callback_unsigned long_unsigned long";

  static blendFunc_Callback_ul_ul(mthis, sfactor, dfactor) native "WebGLRenderingContext_blendFunc_Callback_unsigned long_unsigned long";

  static blendFuncSeparate_Callback_ul_ul_ul_ul(mthis, srcRGB, dstRGB, srcAlpha, dstAlpha) native "WebGLRenderingContext_blendFuncSeparate_Callback_unsigned long_unsigned long_unsigned long_unsigned long";

  static bufferData_Callback_ul_ArrayBuffer_ul(mthis, target, data, usage) native "WebGLRenderingContext_bufferData_Callback_unsigned long_ArrayBuffer_unsigned long";

  static bufferData_Callback_ul_ll_ul(mthis, target, data_OR_size, usage) native "WebGLRenderingContext_bufferData_Callback_unsigned long_long long_unsigned long";

  static bufferData_Callback_ul_ArrayBufferView_ul(mthis, target, data_OR_size, usage) native "WebGLRenderingContext_bufferData_Callback_unsigned long_ArrayBufferView_unsigned long";

  static bufferSubData_Callback_ul_ll_ArrayBuffer(mthis, target, offset, data) native "WebGLRenderingContext_bufferSubData_Callback_unsigned long_long long_ArrayBuffer";

  static bufferSubData_Callback_ul_ll_ArrayBufferView(mthis, target, offset, data) native "WebGLRenderingContext_bufferSubData_Callback_unsigned long_long long_ArrayBufferView";

  static checkFramebufferStatus_Callback_ul(mthis, target) native "WebGLRenderingContext_checkFramebufferStatus_Callback_unsigned long";

  static clear_Callback_ul(mthis, mask) native "WebGLRenderingContext_clear_Callback_unsigned long";

  static clearColor_Callback_float_float_float_float(mthis, red, green, blue, alpha) native "WebGLRenderingContext_clearColor_Callback_float_float_float_float";

  static clearDepth_Callback_float(mthis, depth) native "WebGLRenderingContext_clearDepth_Callback_float";

  static clearStencil_Callback_long(mthis, s) native "WebGLRenderingContext_clearStencil_Callback_long";

  static colorMask_Callback_boolean_boolean_boolean_boolean(mthis, red, green, blue, alpha) native "WebGLRenderingContext_colorMask_Callback_boolean_boolean_boolean_boolean";

  static compileShader_Callback_WebGLShader(mthis, shader) native "WebGLRenderingContext_compileShader_Callback_WebGLShader";

  static compressedTexImage2D_Callback_ul_long_ul_long_long_long_ArrayBufferView(mthis, target, level, internalformat, width, height, border, data) native "WebGLRenderingContext_compressedTexImage2D_Callback_unsigned long_long_unsigned long_long_long_long_ArrayBufferView";

  static compressedTexSubImage2D_Callback_ul_long_long_long_long_long_ul_ArrayBufferView(mthis, target, level, xoffset, yoffset, width, height, format, data) native "WebGLRenderingContext_compressedTexSubImage2D_Callback_unsigned long_long_long_long_long_long_unsigned long_ArrayBufferView";

  static copyTexImage2D_Callback_ul_long_ul_long_long_long_long_long(mthis, target, level, internalformat, x, y, width, height, border) native "WebGLRenderingContext_copyTexImage2D_Callback_unsigned long_long_unsigned long_long_long_long_long_long";

  static copyTexSubImage2D_Callback_ul_long_long_long_long_long_long_long(mthis, target, level, xoffset, yoffset, x, y, width, height) native "WebGLRenderingContext_copyTexSubImage2D_Callback_unsigned long_long_long_long_long_long_long_long";

  static createBuffer_Callback(mthis) native "WebGLRenderingContext_createBuffer_Callback";

  static createFramebuffer_Callback(mthis) native "WebGLRenderingContext_createFramebuffer_Callback";

  static createProgram_Callback(mthis) native "WebGLRenderingContext_createProgram_Callback";

  static createRenderbuffer_Callback(mthis) native "WebGLRenderingContext_createRenderbuffer_Callback";

  static createShader_Callback_ul(mthis, type) native "WebGLRenderingContext_createShader_Callback_unsigned long";

  static createTexture_Callback(mthis) native "WebGLRenderingContext_createTexture_Callback";

  static cullFace_Callback_ul(mthis, mode) native "WebGLRenderingContext_cullFace_Callback_unsigned long";

  static deleteBuffer_Callback_WebGLBuffer(mthis, buffer) native "WebGLRenderingContext_deleteBuffer_Callback_WebGLBuffer";

  static deleteFramebuffer_Callback_WebGLFramebuffer(mthis, framebuffer) native "WebGLRenderingContext_deleteFramebuffer_Callback_WebGLFramebuffer";

  static deleteProgram_Callback_WebGLProgram(mthis, program) native "WebGLRenderingContext_deleteProgram_Callback_WebGLProgram";

  static deleteRenderbuffer_Callback_WebGLRenderbuffer(mthis, renderbuffer) native "WebGLRenderingContext_deleteRenderbuffer_Callback_WebGLRenderbuffer";

  static deleteShader_Callback_WebGLShader(mthis, shader) native "WebGLRenderingContext_deleteShader_Callback_WebGLShader";

  static deleteTexture_Callback_WebGLTexture(mthis, texture) native "WebGLRenderingContext_deleteTexture_Callback_WebGLTexture";

  static depthFunc_Callback_ul(mthis, func) native "WebGLRenderingContext_depthFunc_Callback_unsigned long";

  static depthMask_Callback_boolean(mthis, flag) native "WebGLRenderingContext_depthMask_Callback_boolean";

  static depthRange_Callback_float_float(mthis, zNear, zFar) native "WebGLRenderingContext_depthRange_Callback_float_float";

  static detachShader_Callback_WebGLProgram_WebGLShader(mthis, program, shader) native "WebGLRenderingContext_detachShader_Callback_WebGLProgram_WebGLShader";

  static disable_Callback_ul(mthis, cap) native "WebGLRenderingContext_disable_Callback_unsigned long";

  static disableVertexAttribArray_Callback_ul(mthis, index) native "WebGLRenderingContext_disableVertexAttribArray_Callback_unsigned long";

  static drawArrays_Callback_ul_long_long(mthis, mode, first, count) native "WebGLRenderingContext_drawArrays_Callback_unsigned long_long_long";

  static drawElements_Callback_ul_long_ul_ll(mthis, mode, count, type, offset) native "WebGLRenderingContext_drawElements_Callback_unsigned long_long_unsigned long_long long";

  static enable_Callback_ul(mthis, cap) native "WebGLRenderingContext_enable_Callback_unsigned long";

  static enableVertexAttribArray_Callback_ul(mthis, index) native "WebGLRenderingContext_enableVertexAttribArray_Callback_unsigned long";

  static finish_Callback(mthis) native "WebGLRenderingContext_finish_Callback";

  static flush_Callback(mthis) native "WebGLRenderingContext_flush_Callback";

  static framebufferRenderbuffer_Callback_ul_ul_ul_WebGLRenderbuffer(mthis, target, attachment, renderbuffertarget, renderbuffer) native "WebGLRenderingContext_framebufferRenderbuffer_Callback_unsigned long_unsigned long_unsigned long_WebGLRenderbuffer";

  static framebufferTexture2D_Callback_ul_ul_ul_WebGLTexture_long(mthis, target, attachment, textarget, texture, level) native "WebGLRenderingContext_framebufferTexture2D_Callback_unsigned long_unsigned long_unsigned long_WebGLTexture_long";

  static frontFace_Callback_ul(mthis, mode) native "WebGLRenderingContext_frontFace_Callback_unsigned long";

  static generateMipmap_Callback_ul(mthis, target) native "WebGLRenderingContext_generateMipmap_Callback_unsigned long";

  static getActiveAttrib_Callback_WebGLProgram_ul(mthis, program, index) native "WebGLRenderingContext_getActiveAttrib_Callback_WebGLProgram_unsigned long";

  static getActiveUniform_Callback_WebGLProgram_ul(mthis, program, index) native "WebGLRenderingContext_getActiveUniform_Callback_WebGLProgram_unsigned long";

  static getAttachedShaders_Callback_WebGLProgram(mthis, program) native "WebGLRenderingContext_getAttachedShaders_Callback";

  static getAttribLocation_Callback_WebGLProgram_DOMString(mthis, program, name) native "WebGLRenderingContext_getAttribLocation_Callback_WebGLProgram_DOMString";

  static getBufferParameter_Callback_ul_ul(mthis, target, pname) native "WebGLRenderingContext_getBufferParameter_Callback";

  static getContextAttributes_Callback(mthis) native "WebGLRenderingContext_getContextAttributes_Callback";

  static getError_Callback(mthis) native "WebGLRenderingContext_getError_Callback";

  static getExtension_Callback_DOMString(mthis, name) native "WebGLRenderingContext_getExtension_Callback";

  static getFramebufferAttachmentParameter_Callback_ul_ul_ul(mthis, target, attachment, pname) native "WebGLRenderingContext_getFramebufferAttachmentParameter_Callback";

  static getParameter_Callback_ul(mthis, pname) native "WebGLRenderingContext_getParameter_Callback";

  static getProgramInfoLog_Callback_WebGLProgram(mthis, program) native "WebGLRenderingContext_getProgramInfoLog_Callback_WebGLProgram";

  static getProgramParameter_Callback_WebGLProgram_ul(mthis, program, pname) native "WebGLRenderingContext_getProgramParameter_Callback";

  static getRenderbufferParameter_Callback_ul_ul(mthis, target, pname) native "WebGLRenderingContext_getRenderbufferParameter_Callback";

  static getShaderInfoLog_Callback_WebGLShader(mthis, shader) native "WebGLRenderingContext_getShaderInfoLog_Callback_WebGLShader";

  static getShaderParameter_Callback_WebGLShader_ul(mthis, shader, pname) native "WebGLRenderingContext_getShaderParameter_Callback";

  static getShaderPrecisionFormat_Callback_ul_ul(mthis, shadertype, precisiontype) native "WebGLRenderingContext_getShaderPrecisionFormat_Callback_unsigned long_unsigned long";

  static getShaderSource_Callback_WebGLShader(mthis, shader) native "WebGLRenderingContext_getShaderSource_Callback_WebGLShader";

  static getSupportedExtensions_Callback(mthis) native "WebGLRenderingContext_getSupportedExtensions_Callback";

  static getTexParameter_Callback_ul_ul(mthis, target, pname) native "WebGLRenderingContext_getTexParameter_Callback";

  static getUniform_Callback_WebGLProgram_WebGLUniformLocation(mthis, program, location) native "WebGLRenderingContext_getUniform_Callback";

  static getUniformLocation_Callback_WebGLProgram_DOMString(mthis, program, name) native "WebGLRenderingContext_getUniformLocation_Callback_WebGLProgram_DOMString";

  static getVertexAttrib_Callback_ul_ul(mthis, index, pname) native "WebGLRenderingContext_getVertexAttrib_Callback";

  static getVertexAttribOffset_Callback_ul_ul(mthis, index, pname) native "WebGLRenderingContext_getVertexAttribOffset_Callback_unsigned long_unsigned long";

  static hint_Callback_ul_ul(mthis, target, mode) native "WebGLRenderingContext_hint_Callback_unsigned long_unsigned long";

  static isBuffer_Callback_WebGLBuffer(mthis, buffer) native "WebGLRenderingContext_isBuffer_Callback_WebGLBuffer";

  static isContextLost_Callback(mthis) native "WebGLRenderingContext_isContextLost_Callback";

  static isEnabled_Callback_ul(mthis, cap) native "WebGLRenderingContext_isEnabled_Callback_unsigned long";

  static isFramebuffer_Callback_WebGLFramebuffer(mthis, framebuffer) native "WebGLRenderingContext_isFramebuffer_Callback_WebGLFramebuffer";

  static isProgram_Callback_WebGLProgram(mthis, program) native "WebGLRenderingContext_isProgram_Callback_WebGLProgram";

  static isRenderbuffer_Callback_WebGLRenderbuffer(mthis, renderbuffer) native "WebGLRenderingContext_isRenderbuffer_Callback_WebGLRenderbuffer";

  static isShader_Callback_WebGLShader(mthis, shader) native "WebGLRenderingContext_isShader_Callback_WebGLShader";

  static isTexture_Callback_WebGLTexture(mthis, texture) native "WebGLRenderingContext_isTexture_Callback_WebGLTexture";

  static lineWidth_Callback_float(mthis, width) native "WebGLRenderingContext_lineWidth_Callback_float";

  static linkProgram_Callback_WebGLProgram(mthis, program) native "WebGLRenderingContext_linkProgram_Callback_WebGLProgram";

  static pixelStorei_Callback_ul_long(mthis, pname, param) native "WebGLRenderingContext_pixelStorei_Callback_unsigned long_long";

  static polygonOffset_Callback_float_float(mthis, factor, units) native "WebGLRenderingContext_polygonOffset_Callback_float_float";

  static readPixels_Callback_long_long_long_long_ul_ul_ArrayBufferView(mthis, x, y, width, height, format, type, pixels) native "WebGLRenderingContext_readPixels_Callback_long_long_long_long_unsigned long_unsigned long_ArrayBufferView";

  static renderbufferStorage_Callback_ul_ul_long_long(mthis, target, internalformat, width, height) native "WebGLRenderingContext_renderbufferStorage_Callback_unsigned long_unsigned long_long_long";

  static sampleCoverage_Callback_float_boolean(mthis, value, invert) native "WebGLRenderingContext_sampleCoverage_Callback_float_boolean";

  static scissor_Callback_long_long_long_long(mthis, x, y, width, height) native "WebGLRenderingContext_scissor_Callback_long_long_long_long";

  static shaderSource_Callback_WebGLShader_DOMString(mthis, shader, string) native "WebGLRenderingContext_shaderSource_Callback_WebGLShader_DOMString";

  static stencilFunc_Callback_ul_long_ul(mthis, func, ref, mask) native "WebGLRenderingContext_stencilFunc_Callback_unsigned long_long_unsigned long";

  static stencilFuncSeparate_Callback_ul_ul_long_ul(mthis, face, func, ref, mask) native "WebGLRenderingContext_stencilFuncSeparate_Callback_unsigned long_unsigned long_long_unsigned long";

  static stencilMask_Callback_ul(mthis, mask) native "WebGLRenderingContext_stencilMask_Callback_unsigned long";

  static stencilMaskSeparate_Callback_ul_ul(mthis, face, mask) native "WebGLRenderingContext_stencilMaskSeparate_Callback_unsigned long_unsigned long";

  static stencilOp_Callback_ul_ul_ul(mthis, fail, zfail, zpass) native "WebGLRenderingContext_stencilOp_Callback_unsigned long_unsigned long_unsigned long";

  static stencilOpSeparate_Callback_ul_ul_ul_ul(mthis, face, fail, zfail, zpass) native "WebGLRenderingContext_stencilOpSeparate_Callback_unsigned long_unsigned long_unsigned long_unsigned long";

  static texImage2D_Callback_ul_long_ul_long_long_long_ul_ul_ArrayBufferView(mthis, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video, format, type, pixels) native "WebGLRenderingContext_texImage2D_Callback_unsigned long_long_unsigned long_long_long_long_unsigned long_unsigned long_ArrayBufferView";

  static texImage2D_Callback_ul_long_ul_ul_ul_ImageData(mthis, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext_texImage2D_Callback_unsigned long_long_unsigned long_unsigned long_unsigned long_ImageData";

  static texImage2D_Callback_ul_long_ul_ul_ul_HTMLImageElement(mthis, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext_texImage2D_Callback_unsigned long_long_unsigned long_unsigned long_unsigned long_HTMLImageElement";

  static texImage2D_Callback_ul_long_ul_ul_ul_HTMLCanvasElement(mthis, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext_texImage2D_Callback_unsigned long_long_unsigned long_unsigned long_unsigned long_HTMLCanvasElement";

  static texImage2D_Callback_ul_long_ul_ul_ul_HTMLVideoElement(mthis, target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext_texImage2D_Callback_unsigned long_long_unsigned long_unsigned long_unsigned long_HTMLVideoElement";

  static texParameterf_Callback_ul_ul_float(mthis, target, pname, param) native "WebGLRenderingContext_texParameterf_Callback_unsigned long_unsigned long_float";

  static texParameteri_Callback_ul_ul_long(mthis, target, pname, param) native "WebGLRenderingContext_texParameteri_Callback_unsigned long_unsigned long_long";

  static texSubImage2D_Callback_ul_long_long_long_long_long_ul_ul_ArrayBufferView(mthis, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video, type, pixels) native "WebGLRenderingContext_texSubImage2D_Callback_unsigned long_long_long_long_long_long_unsigned long_unsigned long_ArrayBufferView";

  static texSubImage2D_Callback_ul_long_long_long_ul_ul_ImageData(mthis, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext_texSubImage2D_Callback_unsigned long_long_long_long_unsigned long_unsigned long_ImageData";

  static texSubImage2D_Callback_ul_long_long_long_ul_ul_HTMLImageElement(mthis, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext_texSubImage2D_Callback_unsigned long_long_long_long_unsigned long_unsigned long_HTMLImageElement";

  static texSubImage2D_Callback_ul_long_long_long_ul_ul_HTMLCanvasElement(mthis, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext_texSubImage2D_Callback_unsigned long_long_long_long_unsigned long_unsigned long_HTMLCanvasElement";

  static texSubImage2D_Callback_ul_long_long_long_ul_ul_HTMLVideoElement(mthis, target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video) native "WebGLRenderingContext_texSubImage2D_Callback_unsigned long_long_long_long_unsigned long_unsigned long_HTMLVideoElement";

  static uniform1f_Callback_WebGLUniformLocation_float(mthis, location, x) native "WebGLRenderingContext_uniform1f_Callback_WebGLUniformLocation_float";

  static uniform1fv_Callback_WebGLUniformLocation_Float32Array(mthis, location, v) native "WebGLRenderingContext_uniform1fv_Callback";

  static uniform1i_Callback_WebGLUniformLocation_long(mthis, location, x) native "WebGLRenderingContext_uniform1i_Callback_WebGLUniformLocation_long";

  static uniform1iv_Callback_WebGLUniformLocation_Int32Array(mthis, location, v) native "WebGLRenderingContext_uniform1iv_Callback";

  static uniform2f_Callback_WebGLUniformLocation_float_float(mthis, location, x, y) native "WebGLRenderingContext_uniform2f_Callback_WebGLUniformLocation_float_float";

  static uniform2fv_Callback_WebGLUniformLocation_Float32Array(mthis, location, v) native "WebGLRenderingContext_uniform2fv_Callback";

  static uniform2i_Callback_WebGLUniformLocation_long_long(mthis, location, x, y) native "WebGLRenderingContext_uniform2i_Callback_WebGLUniformLocation_long_long";

  static uniform2iv_Callback_WebGLUniformLocation_Int32Array(mthis, location, v) native "WebGLRenderingContext_uniform2iv_Callback";

  static uniform3f_Callback_WebGLUniformLocation_float_float_float(mthis, location, x, y, z) native "WebGLRenderingContext_uniform3f_Callback_WebGLUniformLocation_float_float_float";

  static uniform3fv_Callback_WebGLUniformLocation_Float32Array(mthis, location, v) native "WebGLRenderingContext_uniform3fv_Callback";

  static uniform3i_Callback_WebGLUniformLocation_long_long_long(mthis, location, x, y, z) native "WebGLRenderingContext_uniform3i_Callback_WebGLUniformLocation_long_long_long";

  static uniform3iv_Callback_WebGLUniformLocation_Int32Array(mthis, location, v) native "WebGLRenderingContext_uniform3iv_Callback";

  static uniform4f_Callback_WebGLUniformLocation_float_float_float_float(mthis, location, x, y, z, w) native "WebGLRenderingContext_uniform4f_Callback_WebGLUniformLocation_float_float_float_float";

  static uniform4fv_Callback_WebGLUniformLocation_Float32Array(mthis, location, v) native "WebGLRenderingContext_uniform4fv_Callback";

  static uniform4i_Callback_WebGLUniformLocation_long_long_long_long(mthis, location, x, y, z, w) native "WebGLRenderingContext_uniform4i_Callback_WebGLUniformLocation_long_long_long_long";

  static uniform4iv_Callback_WebGLUniformLocation_Int32Array(mthis, location, v) native "WebGLRenderingContext_uniform4iv_Callback";

  static uniformMatrix2fv_Callback_WebGLUniformLocation_boolean_Float32Array(mthis, location, transpose, array) native "WebGLRenderingContext_uniformMatrix2fv_Callback";

  static uniformMatrix3fv_Callback_WebGLUniformLocation_boolean_Float32Array(mthis, location, transpose, array) native "WebGLRenderingContext_uniformMatrix3fv_Callback";

  static uniformMatrix4fv_Callback_WebGLUniformLocation_boolean_Float32Array(mthis, location, transpose, array) native "WebGLRenderingContext_uniformMatrix4fv_Callback";

  static useProgram_Callback_WebGLProgram(mthis, program) native "WebGLRenderingContext_useProgram_Callback_WebGLProgram";

  static validateProgram_Callback_WebGLProgram(mthis, program) native "WebGLRenderingContext_validateProgram_Callback_WebGLProgram";

  static vertexAttrib1f_Callback_ul_float(mthis, indx, x) native "WebGLRenderingContext_vertexAttrib1f_Callback_unsigned long_float";

  static vertexAttrib1fv_Callback_ul_Float32Array(mthis, indx, values) native "WebGLRenderingContext_vertexAttrib1fv_Callback";

  static vertexAttrib2f_Callback_ul_float_float(mthis, indx, x, y) native "WebGLRenderingContext_vertexAttrib2f_Callback_unsigned long_float_float";

  static vertexAttrib2fv_Callback_ul_Float32Array(mthis, indx, values) native "WebGLRenderingContext_vertexAttrib2fv_Callback";

  static vertexAttrib3f_Callback_ul_float_float_float(mthis, indx, x, y, z) native "WebGLRenderingContext_vertexAttrib3f_Callback_unsigned long_float_float_float";

  static vertexAttrib3fv_Callback_ul_Float32Array(mthis, indx, values) native "WebGLRenderingContext_vertexAttrib3fv_Callback";

  static vertexAttrib4f_Callback_ul_float_float_float_float(mthis, indx, x, y, z, w) native "WebGLRenderingContext_vertexAttrib4f_Callback_unsigned long_float_float_float_float";

  static vertexAttrib4fv_Callback_ul_Float32Array(mthis, indx, values) native "WebGLRenderingContext_vertexAttrib4fv_Callback";

  static vertexAttribPointer_Callback_ul_long_ul_boolean_long_ll(mthis, indx, size, type, normalized, stride, offset) native "WebGLRenderingContext_vertexAttribPointer_Callback_unsigned long_long_unsigned long_boolean_long_long long";

  static viewport_Callback_long_long_long_long(mthis, x, y, width, height) native "WebGLRenderingContext_viewport_Callback_long_long_long_long";
}

class BlinkWebGLShader {}

class BlinkWebGLShaderPrecisionFormat {
  static precision_Getter(mthis) native "WebGLShaderPrecisionFormat_precision_Getter";

  static rangeMax_Getter(mthis) native "WebGLShaderPrecisionFormat_rangeMax_Getter";

  static rangeMin_Getter(mthis) native "WebGLShaderPrecisionFormat_rangeMin_Getter";
}

class BlinkWebGLTexture {}

class BlinkWebGLUniformLocation {}

class BlinkWebGLVertexArrayObjectOES {}

class BlinkWebKitAnimationEvent {
  static animationName_Getter(mthis) native "WebKitAnimationEvent_animationName_Getter";

  static elapsedTime_Getter(mthis) native "WebKitAnimationEvent_elapsedTime_Getter";
}

class BlinkWebKitCSSFilterRule {
  static style_Getter(mthis) native "WebKitCSSFilterRule_style_Getter";
}

class BlinkWebKitCSSFilterValue {}

class BlinkWebKitCSSMatrix {
  static constructorCallback_DOMString(cssValue) native "WebKitCSSMatrix_constructorCallback_DOMString";
}

class BlinkWebKitCSSTransformValue {}

class BlinkWebKitPoint {
  static constructorCallback_float_float(x, y) native "WebKitPoint_constructorCallback";

  static x_Getter(mthis) native "WebKitPoint_x_Getter";

  static x_Setter_float(mthis, value) native "WebKitPoint_x_Setter";

  static y_Getter(mthis) native "WebKitPoint_y_Getter";

  static y_Setter_float(mthis, value) native "WebKitPoint_y_Setter";
}

class BlinkWebSocket {
  static constructorCallback_DOMString(url) native "WebSocket_constructorCallback_DOMString";

  static constructorCallback_DOMString_DOMString(url, protocol_OR_protocols) native "WebSocket_constructorCallback_DOMString_DOMString";

  static constructorCallback_DOMString_SEQ_DOMString_SEQ(url, protocol_OR_protocols) native "WebSocket_constructorCallback_DOMString_sequence<DOMString>";

  static binaryType_Getter(mthis) native "WebSocket_binaryType_Getter";

  static binaryType_Setter_DOMString(mthis, value) native "WebSocket_binaryType_Setter";

  static bufferedAmount_Getter(mthis) native "WebSocket_bufferedAmount_Getter";

  static extensions_Getter(mthis) native "WebSocket_extensions_Getter";

  static protocol_Getter(mthis) native "WebSocket_protocol_Getter";

  static readyState_Getter(mthis) native "WebSocket_readyState_Getter";

  static url_Getter(mthis) native "WebSocket_url_Getter";

  static close_Callback_us_DOMString(mthis, code, reason) native "WebSocket_close_Callback_unsigned short_DOMString";

  static close_Callback_us(mthis, code) native "WebSocket_close_Callback_unsigned short";

  static close_Callback(mthis) native "WebSocket_close_Callback";

  static send_Callback_DOMString(mthis, data) native "WebSocket_send_Callback_DOMString";

  static send_Callback_Blob(mthis, data) native "WebSocket_send_Callback_Blob";

  static send_Callback_ArrayBufferView(mthis, data) native "WebSocket_send_Callback_ArrayBufferView";

  static send_Callback_ArrayBuffer(mthis, data) native "WebSocket_send_Callback_ArrayBuffer";
}

class BlinkWheelEvent {
  static deltaMode_Getter(mthis) native "WheelEvent_deltaMode_Getter";

  static deltaX_Getter(mthis) native "WheelEvent_deltaX_Getter";

  static deltaY_Getter(mthis) native "WheelEvent_deltaY_Getter";

  static deltaZ_Getter(mthis) native "WheelEvent_deltaZ_Getter";

  static webkitDirectionInvertedFromDevice_Getter(mthis) native "WheelEvent_webkitDirectionInvertedFromDevice_Getter";

  static wheelDeltaX_Getter(mthis) native "WheelEvent_wheelDeltaX_Getter";

  static wheelDeltaY_Getter(mthis) native "WheelEvent_wheelDeltaY_Getter";

  static initWebKitWheelEvent_Callback_long_long_Window_long_long_long_long_boolean_boolean_boolean_boolean(mthis, wheelDeltaX, wheelDeltaY, view, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey) native "WheelEvent_initWebKitWheelEvent_Callback_long_long_Window_long_long_long_long_boolean_boolean_boolean_boolean";
}

class BlinkWindow {
  static CSS_Getter(mthis) native "Window_CSS_Getter";

  static applicationCache_Getter(mthis) native "Window_applicationCache_Getter";

  static closed_Getter(mthis) native "Window_closed_Getter";

  static console_Getter(mthis) native "Window_console_Getter";

  static crypto_Getter(mthis) native "Window_crypto_Getter";

  static defaultStatus_Getter(mthis) native "Window_defaultStatus_Getter";

  static defaultStatus_Setter_DOMString(mthis, value) native "Window_defaultStatus_Setter";

  static defaultstatus_Getter(mthis) native "Window_defaultstatus_Getter";

  static defaultstatus_Setter_DOMString(mthis, value) native "Window_defaultstatus_Setter";

  static devicePixelRatio_Getter(mthis) native "Window_devicePixelRatio_Getter";

  static document_Getter(mthis) native "Window_document_Getter";

  static history_Getter(mthis) native "Window_history_Getter";

  static indexedDB_Getter(mthis) native "Window_indexedDB_Getter";

  static innerHeight_Getter(mthis) native "Window_innerHeight_Getter";

  static innerWidth_Getter(mthis) native "Window_innerWidth_Getter";

  static localStorage_Getter(mthis) native "Window_localStorage_Getter";

  static location_Getter(mthis) native "Window_location_Getter";

  static locationbar_Getter(mthis) native "Window_locationbar_Getter";

  static menubar_Getter(mthis) native "Window_menubar_Getter";

  static name_Getter(mthis) native "Window_name_Getter";

  static name_Setter_DOMString(mthis, value) native "Window_name_Setter";

  static navigator_Getter(mthis) native "Window_navigator_Getter";

  static offscreenBuffering_Getter(mthis) native "Window_offscreenBuffering_Getter";

  static opener_Getter(mthis) native "Window_opener_Getter";

  static opener_Setter_Window(mthis, value) native "Window_opener_Setter";

  static orientation_Getter(mthis) native "Window_orientation_Getter";

  static outerHeight_Getter(mthis) native "Window_outerHeight_Getter";

  static outerWidth_Getter(mthis) native "Window_outerWidth_Getter";

  static pageXOffset_Getter(mthis) native "Window_pageXOffset_Getter";

  static pageYOffset_Getter(mthis) native "Window_pageYOffset_Getter";

  static parent_Getter(mthis) native "Window_parent_Getter";

  static performance_Getter(mthis) native "Window_performance_Getter";

  static screen_Getter(mthis) native "Window_screen_Getter";

  static screenLeft_Getter(mthis) native "Window_screenLeft_Getter";

  static screenTop_Getter(mthis) native "Window_screenTop_Getter";

  static screenX_Getter(mthis) native "Window_screenX_Getter";

  static screenY_Getter(mthis) native "Window_screenY_Getter";

  static scrollX_Getter(mthis) native "Window_scrollX_Getter";

  static scrollY_Getter(mthis) native "Window_scrollY_Getter";

  static scrollbars_Getter(mthis) native "Window_scrollbars_Getter";

  static self_Getter(mthis) native "Window_self_Getter";

  static sessionStorage_Getter(mthis) native "Window_sessionStorage_Getter";

  static speechSynthesis_Getter(mthis) native "Window_speechSynthesis_Getter";

  static status_Getter(mthis) native "Window_status_Getter";

  static status_Setter_DOMString(mthis, value) native "Window_status_Setter";

  static statusbar_Getter(mthis) native "Window_statusbar_Getter";

  static styleMedia_Getter(mthis) native "Window_styleMedia_Getter";

  static toolbar_Getter(mthis) native "Window_toolbar_Getter";

  static top_Getter(mthis) native "Window_top_Getter";

  static window_Getter(mthis) native "Window_window_Getter";

  static $__getter___Callback_ul(mthis, index_OR_name) native "Window___getter___Callback_unsigned long";

  static $__getter___Callback_DOMString(mthis, index_OR_name) native "Window___getter___Callback";

  static alert_Callback_DOMString(mthis, message) native "Window_alert_Callback_DOMString";

  static alert_Callback(mthis) native "Window_alert_Callback";

  static cancelAnimationFrame_Callback_long(mthis, id) native "Window_cancelAnimationFrame_Callback_long";

  static close_Callback(mthis) native "Window_close_Callback";

  static confirm_Callback_DOMString(mthis, message) native "Window_confirm_Callback_DOMString";

  static find_Callback_DOMString_boolean_boolean_boolean_boolean_boolean_boolean(mthis, string, caseSensitive, backwards, wrap, wholeWord, searchInFrames, showDialog) native "Window_find_Callback_DOMString_boolean_boolean_boolean_boolean_boolean_boolean";

  static getComputedStyle_Callback_Element_DOMString(mthis, element, pseudoElement) native "Window_getComputedStyle_Callback_Element_DOMString";

  static getMatchedCSSRules_Callback_Element_DOMString(mthis, element, pseudoElement) native "Window_getMatchedCSSRules_Callback_Element_DOMString";

  static getSelection_Callback(mthis) native "Window_getSelection_Callback";

  static matchMedia_Callback_DOMString(mthis, query) native "Window_matchMedia_Callback_DOMString";

  static moveBy_Callback_float_float(mthis, x, y) native "Window_moveBy_Callback_float_float";

  static moveTo_Callback_float_float(mthis, x, y) native "Window_moveTo_Callback_float_float";

  static open_Callback_DOMString_DOMString_DOMString(mthis, url, name, options) native "Window_open_Callback";

  static openDatabase_Callback_DOMString_DOMString_DOMString_ul_DatabaseCallback(mthis, name, version, displayName, estimatedSize, creationCallback) native "Window_openDatabase_Callback_DOMString_DOMString_DOMString_unsigned long_DatabaseCallback";

  static postMessage_Callback_SerializedScriptValue_DOMString_A_MessagePort_A(mthis, message, targetOrigin, messagePorts) native "Window_postMessage_Callback";

  static print_Callback(mthis) native "Window_print_Callback";

  static requestAnimationFrame_Callback_RequestAnimationFrameCallback(mthis, callback) native "Window_requestAnimationFrame_Callback_RequestAnimationFrameCallback";

  static resizeBy_Callback_float_float(mthis, x, y) native "Window_resizeBy_Callback_float_float";

  static resizeTo_Callback_float_float(mthis, width, height) native "Window_resizeTo_Callback_float_float";

  static scroll_Callback_long_long_Dictionary(mthis, x, y, scrollOptions) native "Window_scroll_Callback_long_long_Dictionary";

  static scrollBy_Callback_long_long_Dictionary(mthis, x, y, scrollOptions) native "Window_scrollBy_Callback_long_long_Dictionary";

  static scrollTo_Callback_long_long_Dictionary(mthis, x, y, scrollOptions) native "Window_scrollTo_Callback_long_long_Dictionary";

  static showModalDialog_Callback_DOMString_ScriptValue_DOMString(mthis, url, dialogArgs, featureArgs) native "Window_showModalDialog_Callback";

  static stop_Callback(mthis) native "Window_stop_Callback";

  static toString_Callback(mthis) native "Window_toString_Callback";

  static webkitConvertPointFromNodeToPage_Callback_Node_WebKitPoint(mthis, node, p) native "Window_webkitConvertPointFromNodeToPage_Callback_Node_WebKitPoint";

  static webkitConvertPointFromPageToNode_Callback_Node_WebKitPoint(mthis, node, p) native "Window_webkitConvertPointFromPageToNode_Callback_Node_WebKitPoint";

  static webkitRequestFileSystem_Callback_us_ll_FileSystemCallback_ErrorCallback(mthis, type, size, successCallback, errorCallback) native "Window_webkitRequestFileSystem_Callback_unsigned short_long long_FileSystemCallback_ErrorCallback";

  static webkitResolveLocalFileSystemURL_Callback_DOMString_EntryCallback_ErrorCallback(mthis, url, successCallback, errorCallback) native "Window_webkitResolveLocalFileSystemURL_Callback_DOMString_EntryCallback_ErrorCallback";

  static atob_Callback_DOMString(mthis, string) native "Window_atob_Callback_DOMString";

  static btoa_Callback_DOMString(mthis, string) native "Window_btoa_Callback_DOMString";

  static clearInterval_Callback_long(mthis, handle) native "Window_clearInterval_Callback_long";

  static clearTimeout_Callback_long(mthis, handle) native "Window_clearTimeout_Callback_long";

  static setInterval_Callback_ScriptValue_long(mthis, handler, timeout) native "Window_setInterval_Callback";

  static setTimeout_Callback_ScriptValue_long(mthis, handler, timeout) native "Window_setTimeout_Callback";
}

class BlinkWorker {
  static constructorCallback_DOMString(scriptUrl) native "Worker_constructorCallback_DOMString";

  static postMessage_Callback_SerializedScriptValue_A_MessagePort_A(mthis, message, messagePorts) native "Worker_postMessage_Callback";

  static terminate_Callback(mthis) native "Worker_terminate_Callback";
}

class BlinkWorkerConsole {}

class BlinkWorkerLocation {}

class BlinkWorkerNavigator {}

class BlinkWorkerPerformance {
  static memory_Getter(mthis) native "WorkerPerformance_memory_Getter";

  static now_Callback(mthis) native "WorkerPerformance_now_Callback";
}

class BlinkXMLDocument {}

class BlinkXMLHttpRequestEventTarget {}

class BlinkXMLHttpRequest {
  static constructorCallback() native "XMLHttpRequest_constructorCallback";

  static readyState_Getter(mthis) native "XMLHttpRequest_readyState_Getter";

  static response_Getter(mthis) native "XMLHttpRequest_response_Getter";

  static responseText_Getter(mthis) native "XMLHttpRequest_responseText_Getter";

  static responseType_Getter(mthis) native "XMLHttpRequest_responseType_Getter";

  static responseType_Setter_DOMString(mthis, value) native "XMLHttpRequest_responseType_Setter";

  static responseURL_Getter(mthis) native "XMLHttpRequest_responseURL_Getter";

  static responseXML_Getter(mthis) native "XMLHttpRequest_responseXML_Getter";

  static status_Getter(mthis) native "XMLHttpRequest_status_Getter";

  static statusText_Getter(mthis) native "XMLHttpRequest_statusText_Getter";

  static timeout_Getter(mthis) native "XMLHttpRequest_timeout_Getter";

  static timeout_Setter_ul(mthis, value) native "XMLHttpRequest_timeout_Setter";

  static upload_Getter(mthis) native "XMLHttpRequest_upload_Getter";

  static withCredentials_Getter(mthis) native "XMLHttpRequest_withCredentials_Getter";

  static withCredentials_Setter_boolean(mthis, value) native "XMLHttpRequest_withCredentials_Setter";

  static abort_Callback(mthis) native "XMLHttpRequest_abort_Callback";

  static getAllResponseHeaders_Callback(mthis) native "XMLHttpRequest_getAllResponseHeaders_Callback";

  static getResponseHeader_Callback_DOMString(mthis, header) native "XMLHttpRequest_getResponseHeader_Callback_DOMString";

  static open_Callback_DOMString_DOMString_boolean_DOMString_DOMString(mthis, method, url, async, user, password) native "XMLHttpRequest_open_Callback";

  static overrideMimeType_Callback_DOMString(mthis, override) native "XMLHttpRequest_overrideMimeType_Callback_DOMString";

  static send_Callback(mthis, data) native "XMLHttpRequest_send_Callback";

  static setRequestHeader_Callback_DOMString_DOMString(mthis, header, value) native "XMLHttpRequest_setRequestHeader_Callback_DOMString_DOMString";
}

class BlinkXMLHttpRequestProgressEvent {}

class BlinkXMLHttpRequestUpload {}

class BlinkXMLSerializer {
  static constructorCallback() native "XMLSerializer_constructorCallback";

  static serializeToString_Callback_Node(mthis, node) native "XMLSerializer_serializeToString_Callback_Node";
}

class BlinkXPathEvaluator {
  static constructorCallback() native "XPathEvaluator_constructorCallback";

  static createExpression_Callback_DOMString_XPathNSResolver(mthis, expression, resolver) native "XPathEvaluator_createExpression_Callback_DOMString_XPathNSResolver";

  static createNSResolver_Callback_Node(mthis, nodeResolver) native "XPathEvaluator_createNSResolver_Callback_Node";

  static evaluate_Callback_DOMString_Node_XPathNSResolver_us_XPathResult(mthis, expression, contextNode, resolver, type, inResult) native "XPathEvaluator_evaluate_Callback_DOMString_Node_XPathNSResolver_unsigned short_XPathResult";
}

class BlinkXPathExpression {
  static evaluate_Callback_Node_us_XPathResult(mthis, contextNode, type, inResult) native "XPathExpression_evaluate_Callback_Node_unsigned short_XPathResult";
}

class BlinkXPathNSResolver {
  static lookupNamespaceURI_Callback_DOMString(mthis, prefix) native "XPathNSResolver_lookupNamespaceURI_Callback_DOMString";
}

class BlinkXPathResult {
  static booleanValue_Getter(mthis) native "XPathResult_booleanValue_Getter";

  static invalidIteratorState_Getter(mthis) native "XPathResult_invalidIteratorState_Getter";

  static numberValue_Getter(mthis) native "XPathResult_numberValue_Getter";

  static resultType_Getter(mthis) native "XPathResult_resultType_Getter";

  static singleNodeValue_Getter(mthis) native "XPathResult_singleNodeValue_Getter";

  static snapshotLength_Getter(mthis) native "XPathResult_snapshotLength_Getter";

  static stringValue_Getter(mthis) native "XPathResult_stringValue_Getter";

  static iterateNext_Callback(mthis) native "XPathResult_iterateNext_Callback";

  static snapshotItem_Callback_ul(mthis, index) native "XPathResult_snapshotItem_Callback_unsigned long";
}

class BlinkXSLTProcessor {
  static constructorCallback() native "XSLTProcessor_constructorCallback";

  static clearParameters_Callback(mthis) native "XSLTProcessor_clearParameters_Callback";

  static getParameter_Callback_DOMString_DOMString(mthis, namespaceURI, localName) native "XSLTProcessor_getParameter_Callback";

  static importStylesheet_Callback_Node(mthis, stylesheet) native "XSLTProcessor_importStylesheet_Callback_Node";

  static removeParameter_Callback_DOMString_DOMString(mthis, namespaceURI, localName) native "XSLTProcessor_removeParameter_Callback";

  static reset_Callback(mthis) native "XSLTProcessor_reset_Callback";

  static setParameter_Callback_DOMString_DOMString_DOMString(mthis, namespaceURI, localName, value) native "XSLTProcessor_setParameter_Callback";

  static transformToDocument_Callback_Node(mthis, source) native "XSLTProcessor_transformToDocument_Callback_Node";

  static transformToFragment_Callback_Node_Document(mthis, source, docVal) native "XSLTProcessor_transformToFragment_Callback_Node_Document";
}


// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
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

  static close(_DOMWindowCrossFrame) native "Window_close_Callback";

  static postMessage(_DOMWindowCrossFrame, message, targetOrigin, [messagePorts]) native "Window_postMessage_Callback";
}

class Blink_HistoryCrossFrame {
  // _HistoryCrossFrame native entry points
  static back(_HistoryCrossFrame) native "History_back_Callback";

  static forward(_HistoryCrossFrame) native "History_forward_Callback";

  static go(_HistoryCrossFrame, distance) native "History_go_Callback_long";
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