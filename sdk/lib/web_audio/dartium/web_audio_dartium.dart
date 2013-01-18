library web_audio;

import 'dart:async';
import 'dart:html';
import 'dart:nativewrappers';
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

  @DocsEditable
  @DomName('AnalyserNode.fftSize')
  int get fftSize native "AnalyserNode_fftSize_Getter";

  @DocsEditable
  @DomName('AnalyserNode.fftSize')
  void set fftSize(int value) native "AnalyserNode_fftSize_Setter";

  @DocsEditable
  @DomName('AnalyserNode.frequencyBinCount')
  int get frequencyBinCount native "AnalyserNode_frequencyBinCount_Getter";

  @DocsEditable
  @DomName('AnalyserNode.maxDecibels')
  num get maxDecibels native "AnalyserNode_maxDecibels_Getter";

  @DocsEditable
  @DomName('AnalyserNode.maxDecibels')
  void set maxDecibels(num value) native "AnalyserNode_maxDecibels_Setter";

  @DocsEditable
  @DomName('AnalyserNode.minDecibels')
  num get minDecibels native "AnalyserNode_minDecibels_Getter";

  @DocsEditable
  @DomName('AnalyserNode.minDecibels')
  void set minDecibels(num value) native "AnalyserNode_minDecibels_Setter";

  @DocsEditable
  @DomName('AnalyserNode.smoothingTimeConstant')
  num get smoothingTimeConstant native "AnalyserNode_smoothingTimeConstant_Getter";

  @DocsEditable
  @DomName('AnalyserNode.smoothingTimeConstant')
  void set smoothingTimeConstant(num value) native "AnalyserNode_smoothingTimeConstant_Setter";

  @DocsEditable
  @DomName('AnalyserNode.getByteFrequencyData')
  void getByteFrequencyData(Uint8Array array) native "AnalyserNode_getByteFrequencyData_Callback";

  @DocsEditable
  @DomName('AnalyserNode.getByteTimeDomainData')
  void getByteTimeDomainData(Uint8Array array) native "AnalyserNode_getByteTimeDomainData_Callback";

  @DocsEditable
  @DomName('AnalyserNode.getFloatFrequencyData')
  void getFloatFrequencyData(Float32Array array) native "AnalyserNode_getFloatFrequencyData_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('AudioBuffer')
class AudioBuffer extends NativeFieldWrapperClass1 {
  AudioBuffer.internal();

  @DocsEditable
  @DomName('AudioBuffer.duration')
  num get duration native "AudioBuffer_duration_Getter";

  @DocsEditable
  @DomName('AudioBuffer.gain')
  num get gain native "AudioBuffer_gain_Getter";

  @DocsEditable
  @DomName('AudioBuffer.gain')
  void set gain(num value) native "AudioBuffer_gain_Setter";

  @DocsEditable
  @DomName('AudioBuffer.length')
  int get length native "AudioBuffer_length_Getter";

  @DocsEditable
  @DomName('AudioBuffer.numberOfChannels')
  int get numberOfChannels native "AudioBuffer_numberOfChannels_Getter";

  @DocsEditable
  @DomName('AudioBuffer.sampleRate')
  num get sampleRate native "AudioBuffer_sampleRate_Getter";

  @DocsEditable
  @DomName('AudioBuffer.getChannelData')
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


@DocsEditable
@DomName('AudioBufferSourceNode')
class AudioBufferSourceNode extends AudioSourceNode {
  AudioBufferSourceNode.internal() : super.internal();

  static const int FINISHED_STATE = 3;

  static const int PLAYING_STATE = 2;

  static const int SCHEDULED_STATE = 1;

  static const int UNSCHEDULED_STATE = 0;

  @DocsEditable
  @DomName('AudioBufferSourceNode.buffer')
  AudioBuffer get buffer native "AudioBufferSourceNode_buffer_Getter";

  @DocsEditable
  @DomName('AudioBufferSourceNode.buffer')
  void set buffer(AudioBuffer value) native "AudioBufferSourceNode_buffer_Setter";

  @DocsEditable
  @DomName('AudioBufferSourceNode.gain')
  AudioGain get gain native "AudioBufferSourceNode_gain_Getter";

  @DocsEditable
  @DomName('AudioBufferSourceNode.loop')
  bool get loop native "AudioBufferSourceNode_loop_Getter";

  @DocsEditable
  @DomName('AudioBufferSourceNode.loop')
  void set loop(bool value) native "AudioBufferSourceNode_loop_Setter";

  @DocsEditable
  @DomName('AudioBufferSourceNode.loopEnd')
  num get loopEnd native "AudioBufferSourceNode_loopEnd_Getter";

  @DocsEditable
  @DomName('AudioBufferSourceNode.loopEnd')
  void set loopEnd(num value) native "AudioBufferSourceNode_loopEnd_Setter";

  @DocsEditable
  @DomName('AudioBufferSourceNode.loopStart')
  num get loopStart native "AudioBufferSourceNode_loopStart_Getter";

  @DocsEditable
  @DomName('AudioBufferSourceNode.loopStart')
  void set loopStart(num value) native "AudioBufferSourceNode_loopStart_Setter";

  @DocsEditable
  @DomName('AudioBufferSourceNode.playbackRate')
  AudioParam get playbackRate native "AudioBufferSourceNode_playbackRate_Getter";

  @DocsEditable
  @DomName('AudioBufferSourceNode.playbackState')
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

  @DocsEditable
  @DomName('AudioBufferSourceNode.start_1')
  void _start_1(when) native "AudioBufferSourceNode_start_1_Callback";

  @DocsEditable
  @DomName('AudioBufferSourceNode.start_2')
  void _start_2(when, grainOffset) native "AudioBufferSourceNode_start_2_Callback";

  @DocsEditable
  @DomName('AudioBufferSourceNode.start_3')
  void _start_3(when, grainOffset, grainDuration) native "AudioBufferSourceNode_start_3_Callback";

  @DocsEditable
  @DomName('AudioBufferSourceNode.stop')
  void stop(num when) native "AudioBufferSourceNode_stop_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('AudioContext')
class AudioContext extends EventTarget {
  AudioContext.internal() : super.internal();

  static const EventStreamProvider<Event> completeEvent = const EventStreamProvider<Event>('complete');

  @DocsEditable
  factory AudioContext() => AudioContext._create();
  static AudioContext _create() native "AudioContext_constructor_Callback";

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  AudioContextEvents get on =>
    new AudioContextEvents(this);

  @DocsEditable
  @DomName('AudioContext.activeSourceCount')
  int get activeSourceCount native "AudioContext_activeSourceCount_Getter";

  @DocsEditable
  @DomName('AudioContext.currentTime')
  num get currentTime native "AudioContext_currentTime_Getter";

  @DocsEditable
  @DomName('AudioContext.destination')
  AudioDestinationNode get destination native "AudioContext_destination_Getter";

  @DocsEditable
  @DomName('AudioContext.listener')
  AudioListener get listener native "AudioContext_listener_Getter";

  @DocsEditable
  @DomName('AudioContext.sampleRate')
  num get sampleRate native "AudioContext_sampleRate_Getter";

  @DocsEditable
  @DomName('AudioContext.createAnalyser')
  AnalyserNode createAnalyser() native "AudioContext_createAnalyser_Callback";

  @DocsEditable
  @DomName('AudioContext.createBiquadFilter')
  BiquadFilterNode createBiquadFilter() native "AudioContext_createBiquadFilter_Callback";

  AudioBuffer createBuffer(buffer_OR_numberOfChannels, mixToMono_OR_numberOfFrames, [num sampleRate]) {
    if ((buffer_OR_numberOfChannels is int || buffer_OR_numberOfChannels == null) && (mixToMono_OR_numberOfFrames is int || mixToMono_OR_numberOfFrames == null) && (sampleRate is num || sampleRate == null)) {
      return _createBuffer_1(buffer_OR_numberOfChannels, mixToMono_OR_numberOfFrames, sampleRate);
    }
    if ((buffer_OR_numberOfChannels is ArrayBuffer || buffer_OR_numberOfChannels == null) && (mixToMono_OR_numberOfFrames is bool || mixToMono_OR_numberOfFrames == null) && !?sampleRate) {
      return _createBuffer_2(buffer_OR_numberOfChannels, mixToMono_OR_numberOfFrames);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @DocsEditable
  @DomName('AudioContext.createBuffer_1')
  AudioBuffer _createBuffer_1(buffer_OR_numberOfChannels, mixToMono_OR_numberOfFrames, sampleRate) native "AudioContext_createBuffer_1_Callback";

  @DocsEditable
  @DomName('AudioContext.createBuffer_2')
  AudioBuffer _createBuffer_2(buffer_OR_numberOfChannels, mixToMono_OR_numberOfFrames) native "AudioContext_createBuffer_2_Callback";

  @DocsEditable
  @DomName('AudioContext.createBufferSource')
  AudioBufferSourceNode createBufferSource() native "AudioContext_createBufferSource_Callback";

  ChannelMergerNode createChannelMerger([int numberOfInputs]) {
    if (?numberOfInputs) {
      return _createChannelMerger_1(numberOfInputs);
    }
    return _createChannelMerger_2();
  }

  @DocsEditable
  @DomName('AudioContext.createChannelMerger_1')
  ChannelMergerNode _createChannelMerger_1(numberOfInputs) native "AudioContext_createChannelMerger_1_Callback";

  @DocsEditable
  @DomName('AudioContext.createChannelMerger_2')
  ChannelMergerNode _createChannelMerger_2() native "AudioContext_createChannelMerger_2_Callback";

  ChannelSplitterNode createChannelSplitter([int numberOfOutputs]) {
    if (?numberOfOutputs) {
      return _createChannelSplitter_1(numberOfOutputs);
    }
    return _createChannelSplitter_2();
  }

  @DocsEditable
  @DomName('AudioContext.createChannelSplitter_1')
  ChannelSplitterNode _createChannelSplitter_1(numberOfOutputs) native "AudioContext_createChannelSplitter_1_Callback";

  @DocsEditable
  @DomName('AudioContext.createChannelSplitter_2')
  ChannelSplitterNode _createChannelSplitter_2() native "AudioContext_createChannelSplitter_2_Callback";

  @DocsEditable
  @DomName('AudioContext.createConvolver')
  ConvolverNode createConvolver() native "AudioContext_createConvolver_Callback";

  DelayNode createDelay([num maxDelayTime]) {
    if (?maxDelayTime) {
      return _createDelay_1(maxDelayTime);
    }
    return _createDelay_2();
  }

  @DocsEditable
  @DomName('AudioContext.createDelay_1')
  DelayNode _createDelay_1(maxDelayTime) native "AudioContext_createDelay_1_Callback";

  @DocsEditable
  @DomName('AudioContext.createDelay_2')
  DelayNode _createDelay_2() native "AudioContext_createDelay_2_Callback";

  @DocsEditable
  @DomName('AudioContext.createDynamicsCompressor')
  DynamicsCompressorNode createDynamicsCompressor() native "AudioContext_createDynamicsCompressor_Callback";

  @DocsEditable
  @DomName('AudioContext.createGain')
  GainNode createGain() native "AudioContext_createGain_Callback";

  @DocsEditable
  @DomName('AudioContext.createMediaElementSource')
  MediaElementAudioSourceNode createMediaElementSource(MediaElement mediaElement) native "AudioContext_createMediaElementSource_Callback";

  @DocsEditable
  @DomName('AudioContext.createMediaStreamDestination')
  MediaStreamAudioDestinationNode createMediaStreamDestination() native "AudioContext_createMediaStreamDestination_Callback";

  @DocsEditable
  @DomName('AudioContext.createMediaStreamSource')
  MediaStreamAudioSourceNode createMediaStreamSource(MediaStream mediaStream) native "AudioContext_createMediaStreamSource_Callback";

  @DocsEditable
  @DomName('AudioContext.createOscillator')
  OscillatorNode createOscillator() native "AudioContext_createOscillator_Callback";

  @DocsEditable
  @DomName('AudioContext.createPanner')
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

  @DocsEditable
  @DomName('AudioContext.createScriptProcessor_1')
  ScriptProcessorNode _createScriptProcessor_1(bufferSize, numberOfInputChannels, numberOfOutputChannels) native "AudioContext_createScriptProcessor_1_Callback";

  @DocsEditable
  @DomName('AudioContext.createScriptProcessor_2')
  ScriptProcessorNode _createScriptProcessor_2(bufferSize, numberOfInputChannels) native "AudioContext_createScriptProcessor_2_Callback";

  @DocsEditable
  @DomName('AudioContext.createScriptProcessor_3')
  ScriptProcessorNode _createScriptProcessor_3(bufferSize) native "AudioContext_createScriptProcessor_3_Callback";

  @DocsEditable
  @DomName('AudioContext.createWaveShaper')
  WaveShaperNode createWaveShaper() native "AudioContext_createWaveShaper_Callback";

  @DocsEditable
  @DomName('AudioContext.createWaveTable')
  WaveTable createWaveTable(Float32Array real, Float32Array imag) native "AudioContext_createWaveTable_Callback";

  @DocsEditable
  @DomName('AudioContext.decodeAudioData')
  void decodeAudioData(ArrayBuffer audioData, AudioBufferCallback successCallback, [AudioBufferCallback errorCallback]) native "AudioContext_decodeAudioData_Callback";

  @DocsEditable
  @DomName('AudioContext.startRendering')
  void startRendering() native "AudioContext_startRendering_Callback";

  Stream<Event> get onComplete => completeEvent.forTarget(this);

}

@DocsEditable
class AudioContextEvents extends Events {
  @DocsEditable
  AudioContextEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get complete => this['complete'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('AudioDestinationNode')
class AudioDestinationNode extends AudioNode {
  AudioDestinationNode.internal() : super.internal();

  @DocsEditable
  @DomName('AudioDestinationNode.numberOfChannels')
  int get numberOfChannels native "AudioDestinationNode_numberOfChannels_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('AudioGain')
class AudioGain extends AudioParam {
  AudioGain.internal() : super.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('AudioListener')
class AudioListener extends NativeFieldWrapperClass1 {
  AudioListener.internal();

  @DocsEditable
  @DomName('AudioListener.dopplerFactor')
  num get dopplerFactor native "AudioListener_dopplerFactor_Getter";

  @DocsEditable
  @DomName('AudioListener.dopplerFactor')
  void set dopplerFactor(num value) native "AudioListener_dopplerFactor_Setter";

  @DocsEditable
  @DomName('AudioListener.speedOfSound')
  num get speedOfSound native "AudioListener_speedOfSound_Getter";

  @DocsEditable
  @DomName('AudioListener.speedOfSound')
  void set speedOfSound(num value) native "AudioListener_speedOfSound_Setter";

  @DocsEditable
  @DomName('AudioListener.setOrientation')
  void setOrientation(num x, num y, num z, num xUp, num yUp, num zUp) native "AudioListener_setOrientation_Callback";

  @DocsEditable
  @DomName('AudioListener.setPosition')
  void setPosition(num x, num y, num z) native "AudioListener_setPosition_Callback";

  @DocsEditable
  @DomName('AudioListener.setVelocity')
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

  @DocsEditable
  @DomName('AudioNode.context')
  AudioContext get context native "AudioNode_context_Getter";

  @DocsEditable
  @DomName('AudioNode.numberOfInputs')
  int get numberOfInputs native "AudioNode_numberOfInputs_Getter";

  @DocsEditable
  @DomName('AudioNode.numberOfOutputs')
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

  @DocsEditable
  @DomName('AudioNode.connect_1')
  void _connect_1(destination, output, input) native "AudioNode_connect_1_Callback";

  @DocsEditable
  @DomName('AudioNode.connect_2')
  void _connect_2(destination, output) native "AudioNode_connect_2_Callback";

  @DocsEditable
  @DomName('AudioNode.disconnect')
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

  @DocsEditable
  @DomName('AudioParam.defaultValue')
  num get defaultValue native "AudioParam_defaultValue_Getter";

  @DocsEditable
  @DomName('AudioParam.maxValue')
  num get maxValue native "AudioParam_maxValue_Getter";

  @DocsEditable
  @DomName('AudioParam.minValue')
  num get minValue native "AudioParam_minValue_Getter";

  @DocsEditable
  @DomName('AudioParam.name')
  String get name native "AudioParam_name_Getter";

  @DocsEditable
  @DomName('AudioParam.units')
  int get units native "AudioParam_units_Getter";

  @DocsEditable
  @DomName('AudioParam.value')
  num get value native "AudioParam_value_Getter";

  @DocsEditable
  @DomName('AudioParam.value')
  void set value(num value) native "AudioParam_value_Setter";

  @DocsEditable
  @DomName('AudioParam.cancelScheduledValues')
  void cancelScheduledValues(num startTime) native "AudioParam_cancelScheduledValues_Callback";

  @DocsEditable
  @DomName('AudioParam.exponentialRampToValueAtTime')
  void exponentialRampToValueAtTime(num value, num time) native "AudioParam_exponentialRampToValueAtTime_Callback";

  @DocsEditable
  @DomName('AudioParam.linearRampToValueAtTime')
  void linearRampToValueAtTime(num value, num time) native "AudioParam_linearRampToValueAtTime_Callback";

  @DocsEditable
  @DomName('AudioParam.setTargetAtTime')
  void setTargetAtTime(num target, num time, num timeConstant) native "AudioParam_setTargetAtTime_Callback";

  @DocsEditable
  @DomName('AudioParam.setValueAtTime')
  void setValueAtTime(num value, num time) native "AudioParam_setValueAtTime_Callback";

  @DocsEditable
  @DomName('AudioParam.setValueCurveAtTime')
  void setValueCurveAtTime(Float32Array values, num time, num duration) native "AudioParam_setValueCurveAtTime_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('AudioProcessingEvent')
class AudioProcessingEvent extends Event {
  AudioProcessingEvent.internal() : super.internal();

  @DocsEditable
  @DomName('AudioProcessingEvent.inputBuffer')
  AudioBuffer get inputBuffer native "AudioProcessingEvent_inputBuffer_Getter";

  @DocsEditable
  @DomName('AudioProcessingEvent.outputBuffer')
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

  @DocsEditable
  @DomName('BiquadFilterNode.Q')
  AudioParam get Q native "BiquadFilterNode_Q_Getter";

  @DocsEditable
  @DomName('BiquadFilterNode.detune')
  AudioParam get detune native "BiquadFilterNode_detune_Getter";

  @DocsEditable
  @DomName('BiquadFilterNode.frequency')
  AudioParam get frequency native "BiquadFilterNode_frequency_Getter";

  @DocsEditable
  @DomName('BiquadFilterNode.gain')
  AudioParam get gain native "BiquadFilterNode_gain_Getter";

  @DocsEditable
  @DomName('BiquadFilterNode.type')
  String get type native "BiquadFilterNode_type_Getter";

  @DocsEditable
  @DomName('BiquadFilterNode.type')
  void set type(String value) native "BiquadFilterNode_type_Setter";

  @DocsEditable
  @DomName('BiquadFilterNode.getFrequencyResponse')
  void getFrequencyResponse(Float32Array frequencyHz, Float32Array magResponse, Float32Array phaseResponse) native "BiquadFilterNode_getFrequencyResponse_Callback";

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

  @DocsEditable
  @DomName('ConvolverNode.buffer')
  AudioBuffer get buffer native "ConvolverNode_buffer_Getter";

  @DocsEditable
  @DomName('ConvolverNode.buffer')
  void set buffer(AudioBuffer value) native "ConvolverNode_buffer_Setter";

  @DocsEditable
  @DomName('ConvolverNode.normalize')
  bool get normalize native "ConvolverNode_normalize_Getter";

  @DocsEditable
  @DomName('ConvolverNode.normalize')
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

  @DocsEditable
  @DomName('DelayNode.delayTime')
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

  @DocsEditable
  @DomName('DynamicsCompressorNode.attack')
  AudioParam get attack native "DynamicsCompressorNode_attack_Getter";

  @DocsEditable
  @DomName('DynamicsCompressorNode.knee')
  AudioParam get knee native "DynamicsCompressorNode_knee_Getter";

  @DocsEditable
  @DomName('DynamicsCompressorNode.ratio')
  AudioParam get ratio native "DynamicsCompressorNode_ratio_Getter";

  @DocsEditable
  @DomName('DynamicsCompressorNode.reduction')
  AudioParam get reduction native "DynamicsCompressorNode_reduction_Getter";

  @DocsEditable
  @DomName('DynamicsCompressorNode.release')
  AudioParam get release native "DynamicsCompressorNode_release_Getter";

  @DocsEditable
  @DomName('DynamicsCompressorNode.threshold')
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

  @DocsEditable
  @DomName('GainNode.gain')
  AudioGain get gain native "GainNode_gain_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('MediaElementAudioSourceNode')
class MediaElementAudioSourceNode extends AudioSourceNode {
  MediaElementAudioSourceNode.internal() : super.internal();

  @DocsEditable
  @DomName('MediaElementAudioSourceNode.mediaElement')
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

  @DocsEditable
  @DomName('MediaStreamAudioDestinationNode.stream')
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

  @DocsEditable
  @DomName('MediaStreamAudioSourceNode.mediaStream')
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

  @DocsEditable
  @DomName('OfflineAudioCompletionEvent.renderedBuffer')
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

  @DocsEditable
  factory OfflineAudioContext(int numberOfChannels, int numberOfFrames, num sampleRate) => OfflineAudioContext._create(numberOfChannels, numberOfFrames, sampleRate);
  static OfflineAudioContext _create(int numberOfChannels, int numberOfFrames, num sampleRate) native "OfflineAudioContext_constructor_Callback";

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

  @DocsEditable
  @DomName('OscillatorNode.detune')
  AudioParam get detune native "OscillatorNode_detune_Getter";

  @DocsEditable
  @DomName('OscillatorNode.frequency')
  AudioParam get frequency native "OscillatorNode_frequency_Getter";

  @DocsEditable
  @DomName('OscillatorNode.playbackState')
  int get playbackState native "OscillatorNode_playbackState_Getter";

  @DocsEditable
  @DomName('OscillatorNode.type')
  String get type native "OscillatorNode_type_Getter";

  @DocsEditable
  @DomName('OscillatorNode.type')
  void set type(String value) native "OscillatorNode_type_Setter";

  @DocsEditable
  @DomName('OscillatorNode.setWaveTable')
  void setWaveTable(WaveTable waveTable) native "OscillatorNode_setWaveTable_Callback";

  @DocsEditable
  @DomName('OscillatorNode.start')
  void start(num when) native "OscillatorNode_start_Callback";

  @DocsEditable
  @DomName('OscillatorNode.stop')
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

  @DocsEditable
  @DomName('PannerNode.coneInnerAngle')
  num get coneInnerAngle native "PannerNode_coneInnerAngle_Getter";

  @DocsEditable
  @DomName('PannerNode.coneInnerAngle')
  void set coneInnerAngle(num value) native "PannerNode_coneInnerAngle_Setter";

  @DocsEditable
  @DomName('PannerNode.coneOuterAngle')
  num get coneOuterAngle native "PannerNode_coneOuterAngle_Getter";

  @DocsEditable
  @DomName('PannerNode.coneOuterAngle')
  void set coneOuterAngle(num value) native "PannerNode_coneOuterAngle_Setter";

  @DocsEditable
  @DomName('PannerNode.coneOuterGain')
  num get coneOuterGain native "PannerNode_coneOuterGain_Getter";

  @DocsEditable
  @DomName('PannerNode.coneOuterGain')
  void set coneOuterGain(num value) native "PannerNode_coneOuterGain_Setter";

  @DocsEditable
  @DomName('PannerNode.distanceModel')
  String get distanceModel native "PannerNode_distanceModel_Getter";

  @DocsEditable
  @DomName('PannerNode.distanceModel')
  void set distanceModel(String value) native "PannerNode_distanceModel_Setter";

  @DocsEditable
  @DomName('PannerNode.maxDistance')
  num get maxDistance native "PannerNode_maxDistance_Getter";

  @DocsEditable
  @DomName('PannerNode.maxDistance')
  void set maxDistance(num value) native "PannerNode_maxDistance_Setter";

  @DocsEditable
  @DomName('PannerNode.panningModel')
  String get panningModel native "PannerNode_panningModel_Getter";

  @DocsEditable
  @DomName('PannerNode.panningModel')
  void set panningModel(String value) native "PannerNode_panningModel_Setter";

  @DocsEditable
  @DomName('PannerNode.refDistance')
  num get refDistance native "PannerNode_refDistance_Getter";

  @DocsEditable
  @DomName('PannerNode.refDistance')
  void set refDistance(num value) native "PannerNode_refDistance_Setter";

  @DocsEditable
  @DomName('PannerNode.rolloffFactor')
  num get rolloffFactor native "PannerNode_rolloffFactor_Getter";

  @DocsEditable
  @DomName('PannerNode.rolloffFactor')
  void set rolloffFactor(num value) native "PannerNode_rolloffFactor_Setter";

  @DocsEditable
  @DomName('PannerNode.setOrientation')
  void setOrientation(num x, num y, num z) native "PannerNode_setOrientation_Callback";

  @DocsEditable
  @DomName('PannerNode.setPosition')
  void setPosition(num x, num y, num z) native "PannerNode_setPosition_Callback";

  @DocsEditable
  @DomName('PannerNode.setVelocity')
  void setVelocity(num x, num y, num z) native "PannerNode_setVelocity_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('ScriptProcessorNode')
class ScriptProcessorNode extends AudioNode implements EventTarget {
  ScriptProcessorNode.internal() : super.internal();

  @DocsEditable
  @DomName('ScriptProcessorNode.bufferSize')
  int get bufferSize native "ScriptProcessorNode_bufferSize_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('WaveShaperNode')
class WaveShaperNode extends AudioNode {
  WaveShaperNode.internal() : super.internal();

  @DocsEditable
  @DomName('WaveShaperNode.curve')
  Float32Array get curve native "WaveShaperNode_curve_Getter";

  @DocsEditable
  @DomName('WaveShaperNode.curve')
  void set curve(Float32Array value) native "WaveShaperNode_curve_Setter";

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
