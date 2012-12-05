library web_audio;

import 'dart:html';
import 'dart:nativewrappers';
// DO NOT EDIT
// Auto-generated dart:audio library.




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


/// @domName AudioContext
class AudioContext extends EventTarget {
  factory AudioContext() => _createAudioContext();

  static _createAudioContext([int numberOfChannels,
                              int numberOfFrames,
                              int sampleRate])
      native "AudioContext_constructor_Callback";

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


class _AudioElementFactoryProvider {
  static AudioElement createAudioElement([String src]) native "HTMLAudioElement_constructor_Callback";
}
