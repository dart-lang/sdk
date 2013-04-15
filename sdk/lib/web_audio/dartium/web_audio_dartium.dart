library dart.dom.web_audio;

import 'dart:async';
import 'dart:collection';
import 'dart:_collection-dev';
import 'dart:html';
import 'dart:html_common';
import 'dart:nativewrappers';
import 'dart:typeddata' as _typeddata;
// DO NOT EDIT
// Auto-generated dart:audio library.




// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('AnalyserNode')
class AnalyserNode extends AudioNode {
  AnalyserNode.internal() : super.internal();

  @DomName('AnalyserNode.fftSize')
  @DocsEditable
  int get fftSize native "AnalyserNode_fftSize_Getter";

  @DomName('AnalyserNode.fftSize')
  @DocsEditable
  void set fftSize(int value) native "AnalyserNode_fftSize_Setter";

  @DomName('AnalyserNode.frequencyBinCount')
  @DocsEditable
  int get frequencyBinCount native "AnalyserNode_frequencyBinCount_Getter";

  @DomName('AnalyserNode.maxDecibels')
  @DocsEditable
  num get maxDecibels native "AnalyserNode_maxDecibels_Getter";

  @DomName('AnalyserNode.maxDecibels')
  @DocsEditable
  void set maxDecibels(num value) native "AnalyserNode_maxDecibels_Setter";

  @DomName('AnalyserNode.minDecibels')
  @DocsEditable
  num get minDecibels native "AnalyserNode_minDecibels_Getter";

  @DomName('AnalyserNode.minDecibels')
  @DocsEditable
  void set minDecibels(num value) native "AnalyserNode_minDecibels_Setter";

  @DomName('AnalyserNode.smoothingTimeConstant')
  @DocsEditable
  num get smoothingTimeConstant native "AnalyserNode_smoothingTimeConstant_Getter";

  @DomName('AnalyserNode.smoothingTimeConstant')
  @DocsEditable
  void set smoothingTimeConstant(num value) native "AnalyserNode_smoothingTimeConstant_Setter";

  @DomName('AnalyserNode.getByteFrequencyData')
  @DocsEditable
  void getByteFrequencyData(List<int> array) native "AnalyserNode_getByteFrequencyData_Callback";

  @DomName('AnalyserNode.getByteTimeDomainData')
  @DocsEditable
  void getByteTimeDomainData(List<int> array) native "AnalyserNode_getByteTimeDomainData_Callback";

  @DomName('AnalyserNode.getFloatFrequencyData')
  @DocsEditable
  void getFloatFrequencyData(List<double> array) native "AnalyserNode_getFloatFrequencyData_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('AudioBuffer')
class AudioBuffer extends NativeFieldWrapperClass1 {
  AudioBuffer.internal();

  @DomName('AudioBuffer.duration')
  @DocsEditable
  num get duration native "AudioBuffer_duration_Getter";

  @DomName('AudioBuffer.gain')
  @DocsEditable
  num get gain native "AudioBuffer_gain_Getter";

  @DomName('AudioBuffer.gain')
  @DocsEditable
  void set gain(num value) native "AudioBuffer_gain_Setter";

  @DomName('AudioBuffer.length')
  @DocsEditable
  int get length native "AudioBuffer_length_Getter";

  @DomName('AudioBuffer.numberOfChannels')
  @DocsEditable
  int get numberOfChannels native "AudioBuffer_numberOfChannels_Getter";

  @DomName('AudioBuffer.sampleRate')
  @DocsEditable
  num get sampleRate native "AudioBuffer_sampleRate_Getter";

  @DomName('AudioBuffer.getChannelData')
  @DocsEditable
  List<double> getChannelData(int channelIndex) native "AudioBuffer_getChannelData_Callback";

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


@DocsEditable
@DomName('AudioBufferSourceNode')
class AudioBufferSourceNode extends AudioSourceNode {
  AudioBufferSourceNode.internal() : super.internal();

  static const int FINISHED_STATE = 3;

  static const int PLAYING_STATE = 2;

  static const int SCHEDULED_STATE = 1;

  static const int UNSCHEDULED_STATE = 0;

  @DomName('AudioBufferSourceNode.buffer')
  @DocsEditable
  AudioBuffer get buffer native "AudioBufferSourceNode_buffer_Getter";

  @DomName('AudioBufferSourceNode.buffer')
  @DocsEditable
  void set buffer(AudioBuffer value) native "AudioBufferSourceNode_buffer_Setter";

  @DomName('AudioBufferSourceNode.gain')
  @DocsEditable
  AudioParam get gain native "AudioBufferSourceNode_gain_Getter";

  @DomName('AudioBufferSourceNode.loop')
  @DocsEditable
  bool get loop native "AudioBufferSourceNode_loop_Getter";

  @DomName('AudioBufferSourceNode.loop')
  @DocsEditable
  void set loop(bool value) native "AudioBufferSourceNode_loop_Setter";

  @DomName('AudioBufferSourceNode.loopEnd')
  @DocsEditable
  num get loopEnd native "AudioBufferSourceNode_loopEnd_Getter";

  @DomName('AudioBufferSourceNode.loopEnd')
  @DocsEditable
  void set loopEnd(num value) native "AudioBufferSourceNode_loopEnd_Setter";

  @DomName('AudioBufferSourceNode.loopStart')
  @DocsEditable
  num get loopStart native "AudioBufferSourceNode_loopStart_Getter";

  @DomName('AudioBufferSourceNode.loopStart')
  @DocsEditable
  void set loopStart(num value) native "AudioBufferSourceNode_loopStart_Setter";

  @DomName('AudioBufferSourceNode.playbackRate')
  @DocsEditable
  AudioParam get playbackRate native "AudioBufferSourceNode_playbackRate_Getter";

  @DomName('AudioBufferSourceNode.playbackState')
  @DocsEditable
  int get playbackState native "AudioBufferSourceNode_playbackState_Getter";

  void start(num when, [num grainOffset, num grainDuration]) {
    if ((when is num || when == null) && !?grainOffset && !?grainDuration) {
      _start_1(when);
      return;
    }
    if ((when is num || when == null) && (grainOffset is num || grainOffset == null) && !?grainDuration) {
      _start_2(when, grainOffset);
      return;
    }
    if ((when is num || when == null) && (grainOffset is num || grainOffset == null) && (grainDuration is num || grainDuration == null)) {
      _start_3(when, grainOffset, grainDuration);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @DomName('AudioBufferSourceNode._start_1')
  @DocsEditable
  void _start_1(when) native "AudioBufferSourceNode__start_1_Callback";

  @DomName('AudioBufferSourceNode._start_2')
  @DocsEditable
  void _start_2(when, grainOffset) native "AudioBufferSourceNode__start_2_Callback";

  @DomName('AudioBufferSourceNode._start_3')
  @DocsEditable
  void _start_3(when, grainOffset, grainDuration) native "AudioBufferSourceNode__start_3_Callback";

  @DomName('AudioBufferSourceNode.stop')
  @DocsEditable
  void stop(num when) native "AudioBufferSourceNode_stop_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('AudioContext')
class AudioContext extends EventTarget {
  AudioContext.internal() : super.internal();

  @DomName('AudioContext.completeEvent')
  @DocsEditable
  static const EventStreamProvider<Event> completeEvent = const EventStreamProvider<Event>('complete');
  factory AudioContext() => _create();

  @DocsEditable
  static AudioContext _create() native "AudioContext_constructorCallback";

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('AudioContext.activeSourceCount')
  @DocsEditable
  int get activeSourceCount native "AudioContext_activeSourceCount_Getter";

  @DomName('AudioContext.currentTime')
  @DocsEditable
  num get currentTime native "AudioContext_currentTime_Getter";

  @DomName('AudioContext.destination')
  @DocsEditable
  AudioDestinationNode get destination native "AudioContext_destination_Getter";

  @DomName('AudioContext.listener')
  @DocsEditable
  AudioListener get listener native "AudioContext_listener_Getter";

  @DomName('AudioContext.sampleRate')
  @DocsEditable
  num get sampleRate native "AudioContext_sampleRate_Getter";

  @DomName('AudioContext.createAnalyser')
  @DocsEditable
  AnalyserNode createAnalyser() native "AudioContext_createAnalyser_Callback";

  @DomName('AudioContext.createBiquadFilter')
  @DocsEditable
  BiquadFilterNode createBiquadFilter() native "AudioContext_createBiquadFilter_Callback";

  AudioBuffer createBuffer(buffer_OR_numberOfChannels, mixToMono_OR_numberOfFrames, [num sampleRate]) {
    if ((buffer_OR_numberOfChannels is int || buffer_OR_numberOfChannels == null) && (mixToMono_OR_numberOfFrames is int || mixToMono_OR_numberOfFrames == null) && (sampleRate is num || sampleRate == null)) {
      return _createBuffer_1(buffer_OR_numberOfChannels, mixToMono_OR_numberOfFrames, sampleRate);
    }
    if ((buffer_OR_numberOfChannels is ArrayBuffer || buffer_OR_numberOfChannels is _typeddata.ByteBuffer || buffer_OR_numberOfChannels == null) && (mixToMono_OR_numberOfFrames is bool || mixToMono_OR_numberOfFrames == null) && !?sampleRate) {
      return _createBuffer_2(buffer_OR_numberOfChannels, mixToMono_OR_numberOfFrames);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @DomName('AudioContext._createBuffer_1')
  @DocsEditable
  AudioBuffer _createBuffer_1(buffer_OR_numberOfChannels, mixToMono_OR_numberOfFrames, sampleRate) native "AudioContext__createBuffer_1_Callback";

  @DomName('AudioContext._createBuffer_2')
  @DocsEditable
  AudioBuffer _createBuffer_2(buffer_OR_numberOfChannels, mixToMono_OR_numberOfFrames) native "AudioContext__createBuffer_2_Callback";

  @DomName('AudioContext.createBufferSource')
  @DocsEditable
  AudioBufferSourceNode createBufferSource() native "AudioContext_createBufferSource_Callback";

  ChannelMergerNode createChannelMerger([int numberOfInputs]) {
    if (?numberOfInputs) {
      return _createChannelMerger_1(numberOfInputs);
    }
    return _createChannelMerger_2();
  }

  @DomName('AudioContext._createChannelMerger_1')
  @DocsEditable
  ChannelMergerNode _createChannelMerger_1(numberOfInputs) native "AudioContext__createChannelMerger_1_Callback";

  @DomName('AudioContext._createChannelMerger_2')
  @DocsEditable
  ChannelMergerNode _createChannelMerger_2() native "AudioContext__createChannelMerger_2_Callback";

  ChannelSplitterNode createChannelSplitter([int numberOfOutputs]) {
    if (?numberOfOutputs) {
      return _createChannelSplitter_1(numberOfOutputs);
    }
    return _createChannelSplitter_2();
  }

  @DomName('AudioContext._createChannelSplitter_1')
  @DocsEditable
  ChannelSplitterNode _createChannelSplitter_1(numberOfOutputs) native "AudioContext__createChannelSplitter_1_Callback";

  @DomName('AudioContext._createChannelSplitter_2')
  @DocsEditable
  ChannelSplitterNode _createChannelSplitter_2() native "AudioContext__createChannelSplitter_2_Callback";

  @DomName('AudioContext.createConvolver')
  @DocsEditable
  ConvolverNode createConvolver() native "AudioContext_createConvolver_Callback";

  DelayNode createDelay([num maxDelayTime]) {
    if (?maxDelayTime) {
      return _createDelay_1(maxDelayTime);
    }
    return _createDelay_2();
  }

  @DomName('AudioContext._createDelay_1')
  @DocsEditable
  DelayNode _createDelay_1(maxDelayTime) native "AudioContext__createDelay_1_Callback";

  @DomName('AudioContext._createDelay_2')
  @DocsEditable
  DelayNode _createDelay_2() native "AudioContext__createDelay_2_Callback";

  @DomName('AudioContext.createDynamicsCompressor')
  @DocsEditable
  DynamicsCompressorNode createDynamicsCompressor() native "AudioContext_createDynamicsCompressor_Callback";

  @DomName('AudioContext.createGain')
  @DocsEditable
  GainNode createGain() native "AudioContext_createGain_Callback";

  @DomName('AudioContext.createMediaElementSource')
  @DocsEditable
  MediaElementAudioSourceNode createMediaElementSource(MediaElement mediaElement) native "AudioContext_createMediaElementSource_Callback";

  @DomName('AudioContext.createMediaStreamDestination')
  @DocsEditable
  MediaStreamAudioDestinationNode createMediaStreamDestination() native "AudioContext_createMediaStreamDestination_Callback";

  @DomName('AudioContext.createMediaStreamSource')
  @DocsEditable
  MediaStreamAudioSourceNode createMediaStreamSource(MediaStream mediaStream) native "AudioContext_createMediaStreamSource_Callback";

  @DomName('AudioContext.createOscillator')
  @DocsEditable
  OscillatorNode createOscillator() native "AudioContext_createOscillator_Callback";

  @DomName('AudioContext.createPanner')
  @DocsEditable
  PannerNode createPanner() native "AudioContext_createPanner_Callback";

  ScriptProcessorNode createScriptProcessor(int bufferSize, [int numberOfInputChannels, int numberOfOutputChannels]) {
    if (?numberOfOutputChannels) {
      return _createScriptProcessor_1(bufferSize, numberOfInputChannels, numberOfOutputChannels);
    }
    if (?numberOfInputChannels) {
      return _createScriptProcessor_2(bufferSize, numberOfInputChannels);
    }
    return _createScriptProcessor_3(bufferSize);
  }

  @DomName('AudioContext._createScriptProcessor_1')
  @DocsEditable
  ScriptProcessorNode _createScriptProcessor_1(bufferSize, numberOfInputChannels, numberOfOutputChannels) native "AudioContext__createScriptProcessor_1_Callback";

  @DomName('AudioContext._createScriptProcessor_2')
  @DocsEditable
  ScriptProcessorNode _createScriptProcessor_2(bufferSize, numberOfInputChannels) native "AudioContext__createScriptProcessor_2_Callback";

  @DomName('AudioContext._createScriptProcessor_3')
  @DocsEditable
  ScriptProcessorNode _createScriptProcessor_3(bufferSize) native "AudioContext__createScriptProcessor_3_Callback";

  @DomName('AudioContext.createWaveShaper')
  @DocsEditable
  WaveShaperNode createWaveShaper() native "AudioContext_createWaveShaper_Callback";

  @DomName('AudioContext.createWaveTable')
  @DocsEditable
  WaveTable createWaveTable(List<double> real, List<double> imag) native "AudioContext_createWaveTable_Callback";

  @DomName('AudioContext.decodeAudioData')
  @DocsEditable
  void decodeAudioData(/*ArrayBuffer*/ audioData, AudioBufferCallback successCallback, [AudioBufferCallback errorCallback]) native "AudioContext_decodeAudioData_Callback";

  @DomName('AudioContext.startRendering')
  @DocsEditable
  void startRendering() native "AudioContext_startRendering_Callback";

  @DomName('AudioContext.oncomplete')
  @DocsEditable
  Stream<Event> get onComplete => completeEvent.forTarget(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('AudioDestinationNode')
class AudioDestinationNode extends AudioNode {
  AudioDestinationNode.internal() : super.internal();

  @DomName('AudioDestinationNode.maxChannelCount')
  @DocsEditable
  int get maxChannelCount native "AudioDestinationNode_maxChannelCount_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('AudioListener')
class AudioListener extends NativeFieldWrapperClass1 {
  AudioListener.internal();

  @DomName('AudioListener.dopplerFactor')
  @DocsEditable
  num get dopplerFactor native "AudioListener_dopplerFactor_Getter";

  @DomName('AudioListener.dopplerFactor')
  @DocsEditable
  void set dopplerFactor(num value) native "AudioListener_dopplerFactor_Setter";

  @DomName('AudioListener.speedOfSound')
  @DocsEditable
  num get speedOfSound native "AudioListener_speedOfSound_Getter";

  @DomName('AudioListener.speedOfSound')
  @DocsEditable
  void set speedOfSound(num value) native "AudioListener_speedOfSound_Setter";

  @DomName('AudioListener.setOrientation')
  @DocsEditable
  void setOrientation(num x, num y, num z, num xUp, num yUp, num zUp) native "AudioListener_setOrientation_Callback";

  @DomName('AudioListener.setPosition')
  @DocsEditable
  void setPosition(num x, num y, num z) native "AudioListener_setPosition_Callback";

  @DomName('AudioListener.setVelocity')
  @DocsEditable
  void setVelocity(num x, num y, num z) native "AudioListener_setVelocity_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('AudioNode')
class AudioNode extends NativeFieldWrapperClass1 {
  AudioNode.internal();

  @DomName('AudioNode.channelCount')
  @DocsEditable
  int get channelCount native "AudioNode_channelCount_Getter";

  @DomName('AudioNode.channelCount')
  @DocsEditable
  void set channelCount(int value) native "AudioNode_channelCount_Setter";

  @DomName('AudioNode.channelCountMode')
  @DocsEditable
  String get channelCountMode native "AudioNode_channelCountMode_Getter";

  @DomName('AudioNode.channelCountMode')
  @DocsEditable
  void set channelCountMode(String value) native "AudioNode_channelCountMode_Setter";

  @DomName('AudioNode.channelInterpretation')
  @DocsEditable
  String get channelInterpretation native "AudioNode_channelInterpretation_Getter";

  @DomName('AudioNode.channelInterpretation')
  @DocsEditable
  void set channelInterpretation(String value) native "AudioNode_channelInterpretation_Setter";

  @DomName('AudioNode.context')
  @DocsEditable
  AudioContext get context native "AudioNode_context_Getter";

  @DomName('AudioNode.numberOfInputs')
  @DocsEditable
  int get numberOfInputs native "AudioNode_numberOfInputs_Getter";

  @DomName('AudioNode.numberOfOutputs')
  @DocsEditable
  int get numberOfOutputs native "AudioNode_numberOfOutputs_Getter";

  void connect(destination, int output, [int input]) {
    if ((destination is AudioNode || destination == null) && (output is int || output == null) && (input is int || input == null)) {
      _connect_1(destination, output, input);
      return;
    }
    if ((destination is AudioParam || destination == null) && (output is int || output == null) && !?input) {
      _connect_2(destination, output);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @DomName('AudioNode._connect_1')
  @DocsEditable
  void _connect_1(destination, output, input) native "AudioNode__connect_1_Callback";

  @DomName('AudioNode._connect_2')
  @DocsEditable
  void _connect_2(destination, output) native "AudioNode__connect_2_Callback";

  @DomName('AudioNode.disconnect')
  @DocsEditable
  void disconnect(int output) native "AudioNode_disconnect_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('AudioParam')
class AudioParam extends NativeFieldWrapperClass1 {
  AudioParam.internal();

  @DomName('AudioParam.defaultValue')
  @DocsEditable
  num get defaultValue native "AudioParam_defaultValue_Getter";

  @DomName('AudioParam.maxValue')
  @DocsEditable
  num get maxValue native "AudioParam_maxValue_Getter";

  @DomName('AudioParam.minValue')
  @DocsEditable
  num get minValue native "AudioParam_minValue_Getter";

  @DomName('AudioParam.name')
  @DocsEditable
  String get name native "AudioParam_name_Getter";

  @DomName('AudioParam.units')
  @DocsEditable
  int get units native "AudioParam_units_Getter";

  @DomName('AudioParam.value')
  @DocsEditable
  num get value native "AudioParam_value_Getter";

  @DomName('AudioParam.value')
  @DocsEditable
  void set value(num value) native "AudioParam_value_Setter";

  @DomName('AudioParam.cancelScheduledValues')
  @DocsEditable
  void cancelScheduledValues(num startTime) native "AudioParam_cancelScheduledValues_Callback";

  @DomName('AudioParam.exponentialRampToValueAtTime')
  @DocsEditable
  void exponentialRampToValueAtTime(num value, num time) native "AudioParam_exponentialRampToValueAtTime_Callback";

  @DomName('AudioParam.linearRampToValueAtTime')
  @DocsEditable
  void linearRampToValueAtTime(num value, num time) native "AudioParam_linearRampToValueAtTime_Callback";

  @DomName('AudioParam.setTargetAtTime')
  @DocsEditable
  void setTargetAtTime(num target, num time, num timeConstant) native "AudioParam_setTargetAtTime_Callback";

  @DomName('AudioParam.setValueAtTime')
  @DocsEditable
  void setValueAtTime(num value, num time) native "AudioParam_setValueAtTime_Callback";

  @DomName('AudioParam.setValueCurveAtTime')
  @DocsEditable
  void setValueCurveAtTime(List<double> values, num time, num duration) native "AudioParam_setValueCurveAtTime_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('AudioProcessingEvent')
class AudioProcessingEvent extends Event {
  AudioProcessingEvent.internal() : super.internal();

  @DomName('AudioProcessingEvent.inputBuffer')
  @DocsEditable
  AudioBuffer get inputBuffer native "AudioProcessingEvent_inputBuffer_Getter";

  @DomName('AudioProcessingEvent.outputBuffer')
  @DocsEditable
  AudioBuffer get outputBuffer native "AudioProcessingEvent_outputBuffer_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('AudioSourceNode')
class AudioSourceNode extends AudioNode {
  AudioSourceNode.internal() : super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('BiquadFilterNode')
class BiquadFilterNode extends AudioNode {
  BiquadFilterNode.internal() : super.internal();

  static const int ALLPASS = 7;

  static const int BANDPASS = 2;

  static const int HIGHPASS = 1;

  static const int HIGHSHELF = 4;

  static const int LOWPASS = 0;

  static const int LOWSHELF = 3;

  static const int NOTCH = 6;

  static const int PEAKING = 5;

  @DomName('BiquadFilterNode.Q')
  @DocsEditable
  AudioParam get Q native "BiquadFilterNode_Q_Getter";

  @DomName('BiquadFilterNode.detune')
  @DocsEditable
  AudioParam get detune native "BiquadFilterNode_detune_Getter";

  @DomName('BiquadFilterNode.frequency')
  @DocsEditable
  AudioParam get frequency native "BiquadFilterNode_frequency_Getter";

  @DomName('BiquadFilterNode.gain')
  @DocsEditable
  AudioParam get gain native "BiquadFilterNode_gain_Getter";

  @DomName('BiquadFilterNode.type')
  @DocsEditable
  String get type native "BiquadFilterNode_type_Getter";

  @DomName('BiquadFilterNode.type')
  @DocsEditable
  void set type(String value) native "BiquadFilterNode_type_Setter";

  @DomName('BiquadFilterNode.getFrequencyResponse')
  @DocsEditable
  void getFrequencyResponse(List<double> frequencyHz, List<double> magResponse, List<double> phaseResponse) native "BiquadFilterNode_getFrequencyResponse_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('ChannelMergerNode')
class ChannelMergerNode extends AudioNode {
  ChannelMergerNode.internal() : super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('ChannelSplitterNode')
class ChannelSplitterNode extends AudioNode {
  ChannelSplitterNode.internal() : super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('ConvolverNode')
class ConvolverNode extends AudioNode {
  ConvolverNode.internal() : super.internal();

  @DomName('ConvolverNode.buffer')
  @DocsEditable
  AudioBuffer get buffer native "ConvolverNode_buffer_Getter";

  @DomName('ConvolverNode.buffer')
  @DocsEditable
  void set buffer(AudioBuffer value) native "ConvolverNode_buffer_Setter";

  @DomName('ConvolverNode.normalize')
  @DocsEditable
  bool get normalize native "ConvolverNode_normalize_Getter";

  @DomName('ConvolverNode.normalize')
  @DocsEditable
  void set normalize(bool value) native "ConvolverNode_normalize_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('DelayNode')
class DelayNode extends AudioNode {
  DelayNode.internal() : super.internal();

  @DomName('DelayNode.delayTime')
  @DocsEditable
  AudioParam get delayTime native "DelayNode_delayTime_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('DynamicsCompressorNode')
class DynamicsCompressorNode extends AudioNode {
  DynamicsCompressorNode.internal() : super.internal();

  @DomName('DynamicsCompressorNode.attack')
  @DocsEditable
  AudioParam get attack native "DynamicsCompressorNode_attack_Getter";

  @DomName('DynamicsCompressorNode.knee')
  @DocsEditable
  AudioParam get knee native "DynamicsCompressorNode_knee_Getter";

  @DomName('DynamicsCompressorNode.ratio')
  @DocsEditable
  AudioParam get ratio native "DynamicsCompressorNode_ratio_Getter";

  @DomName('DynamicsCompressorNode.reduction')
  @DocsEditable
  AudioParam get reduction native "DynamicsCompressorNode_reduction_Getter";

  @DomName('DynamicsCompressorNode.release')
  @DocsEditable
  AudioParam get release native "DynamicsCompressorNode_release_Getter";

  @DomName('DynamicsCompressorNode.threshold')
  @DocsEditable
  AudioParam get threshold native "DynamicsCompressorNode_threshold_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('GainNode')
class GainNode extends AudioNode {
  GainNode.internal() : super.internal();

  @DomName('GainNode.gain')
  @DocsEditable
  AudioParam get gain native "GainNode_gain_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('MediaElementAudioSourceNode')
class MediaElementAudioSourceNode extends AudioSourceNode {
  MediaElementAudioSourceNode.internal() : super.internal();

  @DomName('MediaElementAudioSourceNode.mediaElement')
  @DocsEditable
  MediaElement get mediaElement native "MediaElementAudioSourceNode_mediaElement_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('MediaStreamAudioDestinationNode')
class MediaStreamAudioDestinationNode extends AudioSourceNode {
  MediaStreamAudioDestinationNode.internal() : super.internal();

  @DomName('MediaStreamAudioDestinationNode.stream')
  @DocsEditable
  MediaStream get stream native "MediaStreamAudioDestinationNode_stream_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('MediaStreamAudioSourceNode')
class MediaStreamAudioSourceNode extends AudioSourceNode {
  MediaStreamAudioSourceNode.internal() : super.internal();

  @DomName('MediaStreamAudioSourceNode.mediaStream')
  @DocsEditable
  MediaStream get mediaStream native "MediaStreamAudioSourceNode_mediaStream_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('OfflineAudioCompletionEvent')
class OfflineAudioCompletionEvent extends Event {
  OfflineAudioCompletionEvent.internal() : super.internal();

  @DomName('OfflineAudioCompletionEvent.renderedBuffer')
  @DocsEditable
  AudioBuffer get renderedBuffer native "OfflineAudioCompletionEvent_renderedBuffer_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('OfflineAudioContext')
class OfflineAudioContext extends AudioContext implements EventTarget {
  OfflineAudioContext.internal() : super.internal();

  @DomName('OfflineAudioContext.OfflineAudioContext')
  @DocsEditable
  factory OfflineAudioContext(int numberOfChannels, int numberOfFrames, num sampleRate) {
    return OfflineAudioContext._create_1(numberOfChannels, numberOfFrames, sampleRate);
  }

  @DocsEditable
  static OfflineAudioContext _create_1(numberOfChannels, numberOfFrames, sampleRate) native "OfflineAudioContext__create_1constructorCallback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('OscillatorNode')
class OscillatorNode extends AudioSourceNode {
  OscillatorNode.internal() : super.internal();

  static const int CUSTOM = 4;

  static const int FINISHED_STATE = 3;

  static const int PLAYING_STATE = 2;

  static const int SAWTOOTH = 2;

  static const int SCHEDULED_STATE = 1;

  static const int SINE = 0;

  static const int SQUARE = 1;

  static const int TRIANGLE = 3;

  static const int UNSCHEDULED_STATE = 0;

  @DomName('OscillatorNode.detune')
  @DocsEditable
  AudioParam get detune native "OscillatorNode_detune_Getter";

  @DomName('OscillatorNode.frequency')
  @DocsEditable
  AudioParam get frequency native "OscillatorNode_frequency_Getter";

  @DomName('OscillatorNode.playbackState')
  @DocsEditable
  int get playbackState native "OscillatorNode_playbackState_Getter";

  @DomName('OscillatorNode.type')
  @DocsEditable
  String get type native "OscillatorNode_type_Getter";

  @DomName('OscillatorNode.type')
  @DocsEditable
  void set type(String value) native "OscillatorNode_type_Setter";

  @DomName('OscillatorNode.setWaveTable')
  @DocsEditable
  void setWaveTable(WaveTable waveTable) native "OscillatorNode_setWaveTable_Callback";

  @DomName('OscillatorNode.start')
  @DocsEditable
  void start(num when) native "OscillatorNode_start_Callback";

  @DomName('OscillatorNode.stop')
  @DocsEditable
  void stop(num when) native "OscillatorNode_stop_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('PannerNode')
class PannerNode extends AudioNode {
  PannerNode.internal() : super.internal();

  static const int EQUALPOWER = 0;

  static const int EXPONENTIAL_DISTANCE = 2;

  static const int HRTF = 1;

  static const int INVERSE_DISTANCE = 1;

  static const int LINEAR_DISTANCE = 0;

  static const int SOUNDFIELD = 2;

  @DomName('PannerNode.coneInnerAngle')
  @DocsEditable
  num get coneInnerAngle native "PannerNode_coneInnerAngle_Getter";

  @DomName('PannerNode.coneInnerAngle')
  @DocsEditable
  void set coneInnerAngle(num value) native "PannerNode_coneInnerAngle_Setter";

  @DomName('PannerNode.coneOuterAngle')
  @DocsEditable
  num get coneOuterAngle native "PannerNode_coneOuterAngle_Getter";

  @DomName('PannerNode.coneOuterAngle')
  @DocsEditable
  void set coneOuterAngle(num value) native "PannerNode_coneOuterAngle_Setter";

  @DomName('PannerNode.coneOuterGain')
  @DocsEditable
  num get coneOuterGain native "PannerNode_coneOuterGain_Getter";

  @DomName('PannerNode.coneOuterGain')
  @DocsEditable
  void set coneOuterGain(num value) native "PannerNode_coneOuterGain_Setter";

  @DomName('PannerNode.distanceModel')
  @DocsEditable
  String get distanceModel native "PannerNode_distanceModel_Getter";

  @DomName('PannerNode.distanceModel')
  @DocsEditable
  void set distanceModel(String value) native "PannerNode_distanceModel_Setter";

  @DomName('PannerNode.maxDistance')
  @DocsEditable
  num get maxDistance native "PannerNode_maxDistance_Getter";

  @DomName('PannerNode.maxDistance')
  @DocsEditable
  void set maxDistance(num value) native "PannerNode_maxDistance_Setter";

  @DomName('PannerNode.panningModel')
  @DocsEditable
  String get panningModel native "PannerNode_panningModel_Getter";

  @DomName('PannerNode.panningModel')
  @DocsEditable
  void set panningModel(String value) native "PannerNode_panningModel_Setter";

  @DomName('PannerNode.refDistance')
  @DocsEditable
  num get refDistance native "PannerNode_refDistance_Getter";

  @DomName('PannerNode.refDistance')
  @DocsEditable
  void set refDistance(num value) native "PannerNode_refDistance_Setter";

  @DomName('PannerNode.rolloffFactor')
  @DocsEditable
  num get rolloffFactor native "PannerNode_rolloffFactor_Getter";

  @DomName('PannerNode.rolloffFactor')
  @DocsEditable
  void set rolloffFactor(num value) native "PannerNode_rolloffFactor_Setter";

  @DomName('PannerNode.setOrientation')
  @DocsEditable
  void setOrientation(num x, num y, num z) native "PannerNode_setOrientation_Callback";

  @DomName('PannerNode.setPosition')
  @DocsEditable
  void setPosition(num x, num y, num z) native "PannerNode_setPosition_Callback";

  @DomName('PannerNode.setVelocity')
  @DocsEditable
  void setVelocity(num x, num y, num z) native "PannerNode_setVelocity_Callback";

}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('ScriptProcessorNode')
class ScriptProcessorNode extends AudioNode {
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
      var controller = new StreamController();
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


  ScriptProcessorNode.internal() : super.internal();

  @DomName('ScriptProcessorNode.bufferSize')
  @DocsEditable
  int get bufferSize native "ScriptProcessorNode_bufferSize_Getter";

  @DomName('ScriptProcessorNode._setEventListener')
  @DocsEditable
  void _setEventListener(EventListener eventListener) native "ScriptProcessorNode__setEventListener_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('WaveShaperNode')
class WaveShaperNode extends AudioNode {
  WaveShaperNode.internal() : super.internal();

  @DomName('WaveShaperNode.curve')
  @DocsEditable
  List<double> get curve native "WaveShaperNode_curve_Getter";

  @DomName('WaveShaperNode.curve')
  @DocsEditable
  void set curve(List<double> value) native "WaveShaperNode_curve_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('WaveTable')
class WaveTable extends NativeFieldWrapperClass1 {
  WaveTable.internal();

}
