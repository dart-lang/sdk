library dart.dom.web_audio;

import 'dart:async';
import 'dart:collection';
import 'dart:_internal' hide deprecated;
import 'dart:html';
import 'dart:html_common';
import 'dart:nativewrappers';
import 'dart:typed_data';
// DO NOT EDIT
// Auto-generated dart:audio library.




// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('AnalyserNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AnalyserNode
@Experimental()
class AnalyserNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory AnalyserNode._() { throw new UnsupportedError("Not supported"); }

  @DomName('AnalyserNode.fftSize')
  @DocsEditable()
  int get fftSize native "AnalyserNode_fftSize_Getter";

  @DomName('AnalyserNode.fftSize')
  @DocsEditable()
  void set fftSize(int value) native "AnalyserNode_fftSize_Setter";

  @DomName('AnalyserNode.frequencyBinCount')
  @DocsEditable()
  int get frequencyBinCount native "AnalyserNode_frequencyBinCount_Getter";

  @DomName('AnalyserNode.maxDecibels')
  @DocsEditable()
  num get maxDecibels native "AnalyserNode_maxDecibels_Getter";

  @DomName('AnalyserNode.maxDecibels')
  @DocsEditable()
  void set maxDecibels(num value) native "AnalyserNode_maxDecibels_Setter";

  @DomName('AnalyserNode.minDecibels')
  @DocsEditable()
  num get minDecibels native "AnalyserNode_minDecibels_Getter";

  @DomName('AnalyserNode.minDecibels')
  @DocsEditable()
  void set minDecibels(num value) native "AnalyserNode_minDecibels_Setter";

  @DomName('AnalyserNode.smoothingTimeConstant')
  @DocsEditable()
  num get smoothingTimeConstant native "AnalyserNode_smoothingTimeConstant_Getter";

  @DomName('AnalyserNode.smoothingTimeConstant')
  @DocsEditable()
  void set smoothingTimeConstant(num value) native "AnalyserNode_smoothingTimeConstant_Setter";

  @DomName('AnalyserNode.getByteFrequencyData')
  @DocsEditable()
  void getByteFrequencyData(Uint8List array) native "AnalyserNode_getByteFrequencyData_Callback";

  @DomName('AnalyserNode.getByteTimeDomainData')
  @DocsEditable()
  void getByteTimeDomainData(Uint8List array) native "AnalyserNode_getByteTimeDomainData_Callback";

  @DomName('AnalyserNode.getFloatFrequencyData')
  @DocsEditable()
  void getFloatFrequencyData(Float32List array) native "AnalyserNode_getFloatFrequencyData_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('AudioBuffer')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioBuffer-section
@Experimental()
class AudioBuffer extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory AudioBuffer._() { throw new UnsupportedError("Not supported"); }

  @DomName('AudioBuffer.duration')
  @DocsEditable()
  double get duration native "AudioBuffer_duration_Getter";

  @DomName('AudioBuffer.gain')
  @DocsEditable()
  num get gain native "AudioBuffer_gain_Getter";

  @DomName('AudioBuffer.gain')
  @DocsEditable()
  void set gain(num value) native "AudioBuffer_gain_Setter";

  @DomName('AudioBuffer.length')
  @DocsEditable()
  int get length native "AudioBuffer_length_Getter";

  @DomName('AudioBuffer.numberOfChannels')
  @DocsEditable()
  int get numberOfChannels native "AudioBuffer_numberOfChannels_Getter";

  @DomName('AudioBuffer.sampleRate')
  @DocsEditable()
  double get sampleRate native "AudioBuffer_sampleRate_Getter";

  @DomName('AudioBuffer.getChannelData')
  @DocsEditable()
  Float32List getChannelData(int channelIndex) native "AudioBuffer_getChannelData_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DomName('AudioBufferCallback')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioBuffer-section
@Experimental()
typedef void AudioBufferCallback(AudioBuffer audioBuffer);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('AudioBufferSourceNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioBufferSourceNode-section
@Experimental()
class AudioBufferSourceNode extends AudioSourceNode {
  // To suppress missing implicit constructor warnings.
  factory AudioBufferSourceNode._() { throw new UnsupportedError("Not supported"); }

  /**
   * Static factory designed to expose `ended` events to event
   * handlers that are not necessarily instances of [AudioBufferSourceNode].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('AudioBufferSourceNode.endedEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> endedEvent = const EventStreamProvider<Event>('ended');

  @DomName('AudioBufferSourceNode.FINISHED_STATE')
  @DocsEditable()
  static const int FINISHED_STATE = 3;

  @DomName('AudioBufferSourceNode.PLAYING_STATE')
  @DocsEditable()
  static const int PLAYING_STATE = 2;

  @DomName('AudioBufferSourceNode.SCHEDULED_STATE')
  @DocsEditable()
  static const int SCHEDULED_STATE = 1;

  @DomName('AudioBufferSourceNode.UNSCHEDULED_STATE')
  @DocsEditable()
  static const int UNSCHEDULED_STATE = 0;

  @DomName('AudioBufferSourceNode.buffer')
  @DocsEditable()
  AudioBuffer get buffer native "AudioBufferSourceNode_buffer_Getter";

  @DomName('AudioBufferSourceNode.buffer')
  @DocsEditable()
  void set buffer(AudioBuffer value) native "AudioBufferSourceNode_buffer_Setter";

  @DomName('AudioBufferSourceNode.gain')
  @DocsEditable()
  AudioParam get gain native "AudioBufferSourceNode_gain_Getter";

  @DomName('AudioBufferSourceNode.loop')
  @DocsEditable()
  bool get loop native "AudioBufferSourceNode_loop_Getter";

  @DomName('AudioBufferSourceNode.loop')
  @DocsEditable()
  void set loop(bool value) native "AudioBufferSourceNode_loop_Setter";

  @DomName('AudioBufferSourceNode.loopEnd')
  @DocsEditable()
  num get loopEnd native "AudioBufferSourceNode_loopEnd_Getter";

  @DomName('AudioBufferSourceNode.loopEnd')
  @DocsEditable()
  void set loopEnd(num value) native "AudioBufferSourceNode_loopEnd_Setter";

  @DomName('AudioBufferSourceNode.loopStart')
  @DocsEditable()
  num get loopStart native "AudioBufferSourceNode_loopStart_Getter";

  @DomName('AudioBufferSourceNode.loopStart')
  @DocsEditable()
  void set loopStart(num value) native "AudioBufferSourceNode_loopStart_Setter";

  @DomName('AudioBufferSourceNode.playbackRate')
  @DocsEditable()
  AudioParam get playbackRate native "AudioBufferSourceNode_playbackRate_Getter";

  @DomName('AudioBufferSourceNode.playbackState')
  @DocsEditable()
  int get playbackState native "AudioBufferSourceNode_playbackState_Getter";

  @DomName('AudioBufferSourceNode.noteGrainOn')
  @DocsEditable()
  void noteGrainOn(num when, num grainOffset, num grainDuration) native "AudioBufferSourceNode_noteGrainOn_Callback";

  @DomName('AudioBufferSourceNode.noteOff')
  @DocsEditable()
  void noteOff(num when) native "AudioBufferSourceNode_noteOff_Callback";

  @DomName('AudioBufferSourceNode.noteOn')
  @DocsEditable()
  void noteOn(num when) native "AudioBufferSourceNode_noteOn_Callback";

  void start([num when, num grainOffset, num grainDuration]) {
    if (grainDuration != null) {
      _start_1(when, grainOffset, grainDuration);
      return;
    }
    if (grainOffset != null) {
      _start_2(when, grainOffset);
      return;
    }
    if (when != null) {
      _start_3(when);
      return;
    }
    _start_4();
    return;
  }

  void _start_1(when, grainOffset, grainDuration) native "AudioBufferSourceNode__start_1_Callback";

  void _start_2(when, grainOffset) native "AudioBufferSourceNode__start_2_Callback";

  void _start_3(when) native "AudioBufferSourceNode__start_3_Callback";

  void _start_4() native "AudioBufferSourceNode__start_4_Callback";

  void stop([num when]) {
    if (when != null) {
      _stop_1(when);
      return;
    }
    _stop_2();
    return;
  }

  void _stop_1(when) native "AudioBufferSourceNode__stop_1_Callback";

  void _stop_2() native "AudioBufferSourceNode__stop_2_Callback";

  /// Stream of `ended` events handled by this [AudioBufferSourceNode].
  @DomName('AudioBufferSourceNode.onended')
  @DocsEditable()
  @Experimental() // untriaged
  Stream<Event> get onEnded => endedEvent.forTarget(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('AudioContext')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioContext-section
@Experimental()
class AudioContext extends EventTarget {
  // To suppress missing implicit constructor warnings.
  factory AudioContext._() { throw new UnsupportedError("Not supported"); }

  /**
   * Static factory designed to expose `complete` events to event
   * handlers that are not necessarily instances of [AudioContext].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('AudioContext.completeEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> completeEvent = const EventStreamProvider<Event>('complete');

  @DomName('AudioContext.AudioContext')
  @DocsEditable()
  factory AudioContext() {
    return AudioContext._create_1();
  }

  @DocsEditable()
  static AudioContext _create_1() native "AudioContext__create_1constructorCallback";

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('AudioContext.activeSourceCount')
  @DocsEditable()
  int get activeSourceCount native "AudioContext_activeSourceCount_Getter";

  @DomName('AudioContext.currentTime')
  @DocsEditable()
  double get currentTime native "AudioContext_currentTime_Getter";

  @DomName('AudioContext.destination')
  @DocsEditable()
  AudioDestinationNode get destination native "AudioContext_destination_Getter";

  @DomName('AudioContext.listener')
  @DocsEditable()
  AudioListener get listener native "AudioContext_listener_Getter";

  @DomName('AudioContext.sampleRate')
  @DocsEditable()
  double get sampleRate native "AudioContext_sampleRate_Getter";

  @DomName('AudioContext.createAnalyser')
  @DocsEditable()
  AnalyserNode createAnalyser() native "AudioContext_createAnalyser_Callback";

  @DomName('AudioContext.createBiquadFilter')
  @DocsEditable()
  BiquadFilterNode createBiquadFilter() native "AudioContext_createBiquadFilter_Callback";

  @DomName('AudioContext.createBuffer')
  @DocsEditable()
  AudioBuffer createBuffer(int numberOfChannels, int numberOfFrames, num sampleRate) native "AudioContext_createBuffer_Callback";

  @DomName('AudioContext.createBufferFromBuffer')
  @DocsEditable()
  AudioBuffer createBufferFromBuffer(ByteBuffer buffer, bool mixToMono) native "AudioContext_createBufferFromBuffer_Callback";

  @DomName('AudioContext.createBufferSource')
  @DocsEditable()
  AudioBufferSourceNode createBufferSource() native "AudioContext_createBufferSource_Callback";

  ChannelMergerNode createChannelMerger([int numberOfInputs]) {
    if (numberOfInputs != null) {
      return _createChannelMerger_1(numberOfInputs);
    }
    return _createChannelMerger_2();
  }

  ChannelMergerNode _createChannelMerger_1(numberOfInputs) native "AudioContext__createChannelMerger_1_Callback";

  ChannelMergerNode _createChannelMerger_2() native "AudioContext__createChannelMerger_2_Callback";

  ChannelSplitterNode createChannelSplitter([int numberOfOutputs]) {
    if (numberOfOutputs != null) {
      return _createChannelSplitter_1(numberOfOutputs);
    }
    return _createChannelSplitter_2();
  }

  ChannelSplitterNode _createChannelSplitter_1(numberOfOutputs) native "AudioContext__createChannelSplitter_1_Callback";

  ChannelSplitterNode _createChannelSplitter_2() native "AudioContext__createChannelSplitter_2_Callback";

  @DomName('AudioContext.createConvolver')
  @DocsEditable()
  ConvolverNode createConvolver() native "AudioContext_createConvolver_Callback";

  DelayNode createDelay([num maxDelayTime]) {
    if (maxDelayTime != null) {
      return _createDelay_1(maxDelayTime);
    }
    return _createDelay_2();
  }

  DelayNode _createDelay_1(maxDelayTime) native "AudioContext__createDelay_1_Callback";

  DelayNode _createDelay_2() native "AudioContext__createDelay_2_Callback";

  DelayNode createDelayNode([num maxDelayTime]) {
    if (maxDelayTime != null) {
      return _createDelayNode_1(maxDelayTime);
    }
    return _createDelayNode_2();
  }

  DelayNode _createDelayNode_1(maxDelayTime) native "AudioContext__createDelayNode_1_Callback";

  DelayNode _createDelayNode_2() native "AudioContext__createDelayNode_2_Callback";

  @DomName('AudioContext.createDynamicsCompressor')
  @DocsEditable()
  DynamicsCompressorNode createDynamicsCompressor() native "AudioContext_createDynamicsCompressor_Callback";

  @DomName('AudioContext.createGain')
  @DocsEditable()
  GainNode createGain() native "AudioContext_createGain_Callback";

  @DomName('AudioContext.createGainNode')
  @DocsEditable()
  GainNode createGainNode() native "AudioContext_createGainNode_Callback";

  ScriptProcessorNode createJavaScriptNode(int bufferSize, [int numberOfInputChannels, int numberOfOutputChannels]) {
    if (numberOfOutputChannels != null) {
      return _createJavaScriptNode_1(bufferSize, numberOfInputChannels, numberOfOutputChannels);
    }
    if (numberOfInputChannels != null) {
      return _createJavaScriptNode_2(bufferSize, numberOfInputChannels);
    }
    return _createJavaScriptNode_3(bufferSize);
  }

  ScriptProcessorNode _createJavaScriptNode_1(bufferSize, numberOfInputChannels, numberOfOutputChannels) native "AudioContext__createJavaScriptNode_1_Callback";

  ScriptProcessorNode _createJavaScriptNode_2(bufferSize, numberOfInputChannels) native "AudioContext__createJavaScriptNode_2_Callback";

  ScriptProcessorNode _createJavaScriptNode_3(bufferSize) native "AudioContext__createJavaScriptNode_3_Callback";

  @DomName('AudioContext.createMediaElementSource')
  @DocsEditable()
  MediaElementAudioSourceNode createMediaElementSource(MediaElement mediaElement) native "AudioContext_createMediaElementSource_Callback";

  @DomName('AudioContext.createMediaStreamDestination')
  @DocsEditable()
  MediaStreamAudioDestinationNode createMediaStreamDestination() native "AudioContext_createMediaStreamDestination_Callback";

  @DomName('AudioContext.createMediaStreamSource')
  @DocsEditable()
  MediaStreamAudioSourceNode createMediaStreamSource(MediaStream mediaStream) native "AudioContext_createMediaStreamSource_Callback";

  @DomName('AudioContext.createOscillator')
  @DocsEditable()
  OscillatorNode createOscillator() native "AudioContext_createOscillator_Callback";

  @DomName('AudioContext.createPanner')
  @DocsEditable()
  PannerNode createPanner() native "AudioContext_createPanner_Callback";

  @DomName('AudioContext.createPeriodicWave')
  @DocsEditable()
  @Experimental() // untriaged
  PeriodicWave createPeriodicWave(Float32List real, Float32List imag) native "AudioContext_createPeriodicWave_Callback";

  ScriptProcessorNode createScriptProcessor([int bufferSize, int numberOfInputChannels, int numberOfOutputChannels]) {
    if (numberOfOutputChannels != null) {
      return _createScriptProcessor_1(bufferSize, numberOfInputChannels, numberOfOutputChannels);
    }
    if (numberOfInputChannels != null) {
      return _createScriptProcessor_2(bufferSize, numberOfInputChannels);
    }
    if (bufferSize != null) {
      return _createScriptProcessor_3(bufferSize);
    }
    return _createScriptProcessor_4();
  }

  ScriptProcessorNode _createScriptProcessor_1(bufferSize, numberOfInputChannels, numberOfOutputChannels) native "AudioContext__createScriptProcessor_1_Callback";

  ScriptProcessorNode _createScriptProcessor_2(bufferSize, numberOfInputChannels) native "AudioContext__createScriptProcessor_2_Callback";

  ScriptProcessorNode _createScriptProcessor_3(bufferSize) native "AudioContext__createScriptProcessor_3_Callback";

  ScriptProcessorNode _createScriptProcessor_4() native "AudioContext__createScriptProcessor_4_Callback";

  @DomName('AudioContext.createWaveShaper')
  @DocsEditable()
  WaveShaperNode createWaveShaper() native "AudioContext_createWaveShaper_Callback";

  @DomName('AudioContext.decodeAudioData')
  @DocsEditable()
  void _decodeAudioData(ByteBuffer audioData, AudioBufferCallback successCallback, [AudioBufferCallback errorCallback]) native "AudioContext_decodeAudioData_Callback";

  Future<AudioBuffer> decodeAudioData(ByteBuffer audioData) {
    var completer = new Completer<AudioBuffer>();
    _decodeAudioData(audioData,
        (value) { completer.complete(value); },
        (error) { completer.completeError(error); });
    return completer.future;
  }

  @DomName('AudioContext.startRendering')
  @DocsEditable()
  void startRendering() native "AudioContext_startRendering_Callback";

  @DomName('AudioContext.addEventListener')
  @DocsEditable()
  @Experimental() // untriaged
  void addEventListener(String type, EventListener listener, [bool useCapture]) native "AudioContext_addEventListener_Callback";

  @DomName('AudioContext.dispatchEvent')
  @DocsEditable()
  @Experimental() // untriaged
  bool dispatchEvent(Event event) native "AudioContext_dispatchEvent_Callback";

  @DomName('AudioContext.removeEventListener')
  @DocsEditable()
  @Experimental() // untriaged
  void removeEventListener(String type, EventListener listener, [bool useCapture]) native "AudioContext_removeEventListener_Callback";

  /// Stream of `complete` events handled by this [AudioContext].
  @DomName('AudioContext.oncomplete')
  @DocsEditable()
  Stream<Event> get onComplete => completeEvent.forTarget(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('AudioDestinationNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioDestinationNode-section
@Experimental()
class AudioDestinationNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory AudioDestinationNode._() { throw new UnsupportedError("Not supported"); }

  @DomName('AudioDestinationNode.maxChannelCount')
  @DocsEditable()
  int get maxChannelCount native "AudioDestinationNode_maxChannelCount_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('AudioListener')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioListener-section
@Experimental()
class AudioListener extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory AudioListener._() { throw new UnsupportedError("Not supported"); }

  @DomName('AudioListener.dopplerFactor')
  @DocsEditable()
  num get dopplerFactor native "AudioListener_dopplerFactor_Getter";

  @DomName('AudioListener.dopplerFactor')
  @DocsEditable()
  void set dopplerFactor(num value) native "AudioListener_dopplerFactor_Setter";

  @DomName('AudioListener.speedOfSound')
  @DocsEditable()
  num get speedOfSound native "AudioListener_speedOfSound_Getter";

  @DomName('AudioListener.speedOfSound')
  @DocsEditable()
  void set speedOfSound(num value) native "AudioListener_speedOfSound_Setter";

  @DomName('AudioListener.setOrientation')
  @DocsEditable()
  void setOrientation(num x, num y, num z, num xUp, num yUp, num zUp) native "AudioListener_setOrientation_Callback";

  @DomName('AudioListener.setPosition')
  @DocsEditable()
  void setPosition(num x, num y, num z) native "AudioListener_setPosition_Callback";

  @DomName('AudioListener.setVelocity')
  @DocsEditable()
  void setVelocity(num x, num y, num z) native "AudioListener_setVelocity_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('AudioNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioNode-section
@Experimental()
class AudioNode extends EventTarget {
  // To suppress missing implicit constructor warnings.
  factory AudioNode._() { throw new UnsupportedError("Not supported"); }

  @DomName('AudioNode.channelCount')
  @DocsEditable()
  int get channelCount native "AudioNode_channelCount_Getter";

  @DomName('AudioNode.channelCount')
  @DocsEditable()
  void set channelCount(int value) native "AudioNode_channelCount_Setter";

  @DomName('AudioNode.channelCountMode')
  @DocsEditable()
  String get channelCountMode native "AudioNode_channelCountMode_Getter";

  @DomName('AudioNode.channelCountMode')
  @DocsEditable()
  void set channelCountMode(String value) native "AudioNode_channelCountMode_Setter";

  @DomName('AudioNode.channelInterpretation')
  @DocsEditable()
  String get channelInterpretation native "AudioNode_channelInterpretation_Getter";

  @DomName('AudioNode.channelInterpretation')
  @DocsEditable()
  void set channelInterpretation(String value) native "AudioNode_channelInterpretation_Setter";

  @DomName('AudioNode.context')
  @DocsEditable()
  AudioContext get context native "AudioNode_context_Getter";

  @DomName('AudioNode.numberOfInputs')
  @DocsEditable()
  int get numberOfInputs native "AudioNode_numberOfInputs_Getter";

  @DomName('AudioNode.numberOfOutputs')
  @DocsEditable()
  int get numberOfOutputs native "AudioNode_numberOfOutputs_Getter";

  void _connect(destination, int output, [int input]) {
    if ((input is int || input == null) && (output is int || output == null) && (destination is AudioNode || destination == null)) {
      _connect_1(destination, output, input);
      return;
    }
    if ((output is int || output == null) && (destination is AudioParam || destination == null) && input == null) {
      _connect_2(destination, output);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  void _connect_1(destination, output, input) native "AudioNode__connect_1_Callback";

  void _connect_2(destination, output) native "AudioNode__connect_2_Callback";

  @DomName('AudioNode.disconnect')
  @DocsEditable()
  void disconnect(int output) native "AudioNode_disconnect_Callback";

  @DomName('AudioNode.addEventListener')
  @DocsEditable()
  void addEventListener(String type, EventListener listener, [bool useCapture]) native "AudioNode_addEventListener_Callback";

  @DomName('AudioNode.dispatchEvent')
  @DocsEditable()
  bool dispatchEvent(Event event) native "AudioNode_dispatchEvent_Callback";

  @DomName('AudioNode.removeEventListener')
  @DocsEditable()
  void removeEventListener(String type, EventListener listener, [bool useCapture]) native "AudioNode_removeEventListener_Callback";

  @DomName('AudioNode.connect')
  void connectNode(AudioNode destination, [int output = 0, int input = 0]) =>
      _connect(destination, output, input);

  @DomName('AudioNode.connect')
  void connectParam(AudioParam destination, [int output = 0]) =>
      _connect(destination, output);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('AudioParam')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioParam
@Experimental()
class AudioParam extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory AudioParam._() { throw new UnsupportedError("Not supported"); }

  @DomName('AudioParam.defaultValue')
  @DocsEditable()
  double get defaultValue native "AudioParam_defaultValue_Getter";

  @DomName('AudioParam.maxValue')
  @DocsEditable()
  double get maxValue native "AudioParam_maxValue_Getter";

  @DomName('AudioParam.minValue')
  @DocsEditable()
  double get minValue native "AudioParam_minValue_Getter";

  @DomName('AudioParam.name')
  @DocsEditable()
  String get name native "AudioParam_name_Getter";

  @DomName('AudioParam.units')
  @DocsEditable()
  int get units native "AudioParam_units_Getter";

  @DomName('AudioParam.value')
  @DocsEditable()
  num get value native "AudioParam_value_Getter";

  @DomName('AudioParam.value')
  @DocsEditable()
  void set value(num value) native "AudioParam_value_Setter";

  @DomName('AudioParam.cancelScheduledValues')
  @DocsEditable()
  void cancelScheduledValues(num startTime) native "AudioParam_cancelScheduledValues_Callback";

  @DomName('AudioParam.exponentialRampToValueAtTime')
  @DocsEditable()
  void exponentialRampToValueAtTime(num value, num time) native "AudioParam_exponentialRampToValueAtTime_Callback";

  @DomName('AudioParam.linearRampToValueAtTime')
  @DocsEditable()
  void linearRampToValueAtTime(num value, num time) native "AudioParam_linearRampToValueAtTime_Callback";

  @DomName('AudioParam.setTargetAtTime')
  @DocsEditable()
  void setTargetAtTime(num target, num time, num timeConstant) native "AudioParam_setTargetAtTime_Callback";

  @DomName('AudioParam.setTargetValueAtTime')
  @DocsEditable()
  void setTargetValueAtTime(num targetValue, num time, num timeConstant) native "AudioParam_setTargetValueAtTime_Callback";

  @DomName('AudioParam.setValueAtTime')
  @DocsEditable()
  void setValueAtTime(num value, num time) native "AudioParam_setValueAtTime_Callback";

  @DomName('AudioParam.setValueCurveAtTime')
  @DocsEditable()
  void setValueCurveAtTime(Float32List values, num time, num duration) native "AudioParam_setValueCurveAtTime_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('AudioProcessingEvent')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioProcessingEvent-section
@Experimental()
class AudioProcessingEvent extends Event {
  // To suppress missing implicit constructor warnings.
  factory AudioProcessingEvent._() { throw new UnsupportedError("Not supported"); }

  @DomName('AudioProcessingEvent.inputBuffer')
  @DocsEditable()
  AudioBuffer get inputBuffer native "AudioProcessingEvent_inputBuffer_Getter";

  @DomName('AudioProcessingEvent.outputBuffer')
  @DocsEditable()
  AudioBuffer get outputBuffer native "AudioProcessingEvent_outputBuffer_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('AudioSourceNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html
@Experimental()
class AudioSourceNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory AudioSourceNode._() { throw new UnsupportedError("Not supported"); }

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('BiquadFilterNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#BiquadFilterNode-section
@Experimental()
class BiquadFilterNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory BiquadFilterNode._() { throw new UnsupportedError("Not supported"); }

  @DomName('BiquadFilterNode.ALLPASS')
  @DocsEditable()
  static const int ALLPASS = 7;

  @DomName('BiquadFilterNode.BANDPASS')
  @DocsEditable()
  static const int BANDPASS = 2;

  @DomName('BiquadFilterNode.HIGHPASS')
  @DocsEditable()
  static const int HIGHPASS = 1;

  @DomName('BiquadFilterNode.HIGHSHELF')
  @DocsEditable()
  static const int HIGHSHELF = 4;

  @DomName('BiquadFilterNode.LOWPASS')
  @DocsEditable()
  static const int LOWPASS = 0;

  @DomName('BiquadFilterNode.LOWSHELF')
  @DocsEditable()
  static const int LOWSHELF = 3;

  @DomName('BiquadFilterNode.NOTCH')
  @DocsEditable()
  static const int NOTCH = 6;

  @DomName('BiquadFilterNode.PEAKING')
  @DocsEditable()
  static const int PEAKING = 5;

  @DomName('BiquadFilterNode.Q')
  @DocsEditable()
  AudioParam get Q native "BiquadFilterNode_Q_Getter";

  @DomName('BiquadFilterNode.detune')
  @DocsEditable()
  AudioParam get detune native "BiquadFilterNode_detune_Getter";

  @DomName('BiquadFilterNode.frequency')
  @DocsEditable()
  AudioParam get frequency native "BiquadFilterNode_frequency_Getter";

  @DomName('BiquadFilterNode.gain')
  @DocsEditable()
  AudioParam get gain native "BiquadFilterNode_gain_Getter";

  @DomName('BiquadFilterNode.type')
  @DocsEditable()
  String get type native "BiquadFilterNode_type_Getter";

  @DomName('BiquadFilterNode.type')
  @DocsEditable()
  void set type(String value) native "BiquadFilterNode_type_Setter";

  @DomName('BiquadFilterNode.getFrequencyResponse')
  @DocsEditable()
  void getFrequencyResponse(Float32List frequencyHz, Float32List magResponse, Float32List phaseResponse) native "BiquadFilterNode_getFrequencyResponse_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('ChannelMergerNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#ChannelMergerNode-section
@Experimental()
class ChannelMergerNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory ChannelMergerNode._() { throw new UnsupportedError("Not supported"); }

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('ChannelSplitterNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#ChannelSplitterNode-section
@Experimental()
class ChannelSplitterNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory ChannelSplitterNode._() { throw new UnsupportedError("Not supported"); }

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('ConvolverNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#ConvolverNode
@Experimental()
class ConvolverNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory ConvolverNode._() { throw new UnsupportedError("Not supported"); }

  @DomName('ConvolverNode.buffer')
  @DocsEditable()
  AudioBuffer get buffer native "ConvolverNode_buffer_Getter";

  @DomName('ConvolverNode.buffer')
  @DocsEditable()
  void set buffer(AudioBuffer value) native "ConvolverNode_buffer_Setter";

  @DomName('ConvolverNode.normalize')
  @DocsEditable()
  bool get normalize native "ConvolverNode_normalize_Getter";

  @DomName('ConvolverNode.normalize')
  @DocsEditable()
  void set normalize(bool value) native "ConvolverNode_normalize_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('DelayNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#DelayNode
@Experimental()
class DelayNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory DelayNode._() { throw new UnsupportedError("Not supported"); }

  @DomName('DelayNode.delayTime')
  @DocsEditable()
  AudioParam get delayTime native "DelayNode_delayTime_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('DynamicsCompressorNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#DynamicsCompressorNode
@Experimental()
class DynamicsCompressorNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory DynamicsCompressorNode._() { throw new UnsupportedError("Not supported"); }

  @DomName('DynamicsCompressorNode.attack')
  @DocsEditable()
  AudioParam get attack native "DynamicsCompressorNode_attack_Getter";

  @DomName('DynamicsCompressorNode.knee')
  @DocsEditable()
  AudioParam get knee native "DynamicsCompressorNode_knee_Getter";

  @DomName('DynamicsCompressorNode.ratio')
  @DocsEditable()
  AudioParam get ratio native "DynamicsCompressorNode_ratio_Getter";

  @DomName('DynamicsCompressorNode.reduction')
  @DocsEditable()
  AudioParam get reduction native "DynamicsCompressorNode_reduction_Getter";

  @DomName('DynamicsCompressorNode.release')
  @DocsEditable()
  AudioParam get release native "DynamicsCompressorNode_release_Getter";

  @DomName('DynamicsCompressorNode.threshold')
  @DocsEditable()
  AudioParam get threshold native "DynamicsCompressorNode_threshold_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('GainNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#GainNode
@Experimental()
class GainNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory GainNode._() { throw new UnsupportedError("Not supported"); }

  @DomName('GainNode.gain')
  @DocsEditable()
  AudioParam get gain native "GainNode_gain_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('MediaElementAudioSourceNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#MediaElementAudioSourceNode
@Experimental()
class MediaElementAudioSourceNode extends AudioSourceNode {
  // To suppress missing implicit constructor warnings.
  factory MediaElementAudioSourceNode._() { throw new UnsupportedError("Not supported"); }

  @DomName('MediaElementAudioSourceNode.mediaElement')
  @DocsEditable()
  @Experimental() // non-standard
  MediaElement get mediaElement native "MediaElementAudioSourceNode_mediaElement_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('MediaStreamAudioDestinationNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#MediaStreamAudioDestinationNode
@Experimental()
class MediaStreamAudioDestinationNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory MediaStreamAudioDestinationNode._() { throw new UnsupportedError("Not supported"); }

  @DomName('MediaStreamAudioDestinationNode.stream')
  @DocsEditable()
  MediaStream get stream native "MediaStreamAudioDestinationNode_stream_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('MediaStreamAudioSourceNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#MediaStreamAudioSourceNode
@Experimental()
class MediaStreamAudioSourceNode extends AudioSourceNode {
  // To suppress missing implicit constructor warnings.
  factory MediaStreamAudioSourceNode._() { throw new UnsupportedError("Not supported"); }

  @DomName('MediaStreamAudioSourceNode.mediaStream')
  @DocsEditable()
  MediaStream get mediaStream native "MediaStreamAudioSourceNode_mediaStream_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('OfflineAudioCompletionEvent')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#OfflineAudioCompletionEvent-section
@Experimental()
class OfflineAudioCompletionEvent extends Event {
  // To suppress missing implicit constructor warnings.
  factory OfflineAudioCompletionEvent._() { throw new UnsupportedError("Not supported"); }

  @DomName('OfflineAudioCompletionEvent.renderedBuffer')
  @DocsEditable()
  AudioBuffer get renderedBuffer native "OfflineAudioCompletionEvent_renderedBuffer_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('OfflineAudioContext')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#OfflineAudioContext-section
@Experimental()
class OfflineAudioContext extends AudioContext {
  // To suppress missing implicit constructor warnings.
  factory OfflineAudioContext._() { throw new UnsupportedError("Not supported"); }

  @DomName('OfflineAudioContext.OfflineAudioContext')
  @DocsEditable()
  factory OfflineAudioContext(int numberOfChannels, int numberOfFrames, num sampleRate) {
    return OfflineAudioContext._create_1(numberOfChannels, numberOfFrames, sampleRate);
  }

  @DocsEditable()
  static OfflineAudioContext _create_1(numberOfChannels, numberOfFrames, sampleRate) native "OfflineAudioContext__create_1constructorCallback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('OscillatorNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#dfn-OscillatorNode
@Experimental()
class OscillatorNode extends AudioSourceNode {
  // To suppress missing implicit constructor warnings.
  factory OscillatorNode._() { throw new UnsupportedError("Not supported"); }

  /**
   * Static factory designed to expose `ended` events to event
   * handlers that are not necessarily instances of [OscillatorNode].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('OscillatorNode.endedEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> endedEvent = const EventStreamProvider<Event>('ended');

  @DomName('OscillatorNode.FINISHED_STATE')
  @DocsEditable()
  static const int FINISHED_STATE = 3;

  @DomName('OscillatorNode.PLAYING_STATE')
  @DocsEditable()
  static const int PLAYING_STATE = 2;

  @DomName('OscillatorNode.SCHEDULED_STATE')
  @DocsEditable()
  static const int SCHEDULED_STATE = 1;

  @DomName('OscillatorNode.UNSCHEDULED_STATE')
  @DocsEditable()
  static const int UNSCHEDULED_STATE = 0;

  @DomName('OscillatorNode.detune')
  @DocsEditable()
  AudioParam get detune native "OscillatorNode_detune_Getter";

  @DomName('OscillatorNode.frequency')
  @DocsEditable()
  AudioParam get frequency native "OscillatorNode_frequency_Getter";

  @DomName('OscillatorNode.playbackState')
  @DocsEditable()
  int get playbackState native "OscillatorNode_playbackState_Getter";

  @DomName('OscillatorNode.type')
  @DocsEditable()
  String get type native "OscillatorNode_type_Getter";

  @DomName('OscillatorNode.type')
  @DocsEditable()
  void set type(String value) native "OscillatorNode_type_Setter";

  @DomName('OscillatorNode.noteOff')
  @DocsEditable()
  void noteOff(num when) native "OscillatorNode_noteOff_Callback";

  @DomName('OscillatorNode.noteOn')
  @DocsEditable()
  void noteOn(num when) native "OscillatorNode_noteOn_Callback";

  @DomName('OscillatorNode.setPeriodicWave')
  @DocsEditable()
  @Experimental() // untriaged
  void setPeriodicWave(PeriodicWave periodicWave) native "OscillatorNode_setPeriodicWave_Callback";

  void start([num when]) {
    if (when != null) {
      _start_1(when);
      return;
    }
    _start_2();
    return;
  }

  void _start_1(when) native "OscillatorNode__start_1_Callback";

  void _start_2() native "OscillatorNode__start_2_Callback";

  void stop([num when]) {
    if (when != null) {
      _stop_1(when);
      return;
    }
    _stop_2();
    return;
  }

  void _stop_1(when) native "OscillatorNode__stop_1_Callback";

  void _stop_2() native "OscillatorNode__stop_2_Callback";

  /// Stream of `ended` events handled by this [OscillatorNode].
  @DomName('OscillatorNode.onended')
  @DocsEditable()
  @Experimental() // untriaged
  Stream<Event> get onEnded => endedEvent.forTarget(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('PannerNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#PannerNode
@Experimental()
class PannerNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory PannerNode._() { throw new UnsupportedError("Not supported"); }

  @DomName('PannerNode.coneInnerAngle')
  @DocsEditable()
  num get coneInnerAngle native "PannerNode_coneInnerAngle_Getter";

  @DomName('PannerNode.coneInnerAngle')
  @DocsEditable()
  void set coneInnerAngle(num value) native "PannerNode_coneInnerAngle_Setter";

  @DomName('PannerNode.coneOuterAngle')
  @DocsEditable()
  num get coneOuterAngle native "PannerNode_coneOuterAngle_Getter";

  @DomName('PannerNode.coneOuterAngle')
  @DocsEditable()
  void set coneOuterAngle(num value) native "PannerNode_coneOuterAngle_Setter";

  @DomName('PannerNode.coneOuterGain')
  @DocsEditable()
  num get coneOuterGain native "PannerNode_coneOuterGain_Getter";

  @DomName('PannerNode.coneOuterGain')
  @DocsEditable()
  void set coneOuterGain(num value) native "PannerNode_coneOuterGain_Setter";

  @DomName('PannerNode.distanceModel')
  @DocsEditable()
  String get distanceModel native "PannerNode_distanceModel_Getter";

  @DomName('PannerNode.distanceModel')
  @DocsEditable()
  void set distanceModel(String value) native "PannerNode_distanceModel_Setter";

  @DomName('PannerNode.maxDistance')
  @DocsEditable()
  num get maxDistance native "PannerNode_maxDistance_Getter";

  @DomName('PannerNode.maxDistance')
  @DocsEditable()
  void set maxDistance(num value) native "PannerNode_maxDistance_Setter";

  @DomName('PannerNode.panningModel')
  @DocsEditable()
  String get panningModel native "PannerNode_panningModel_Getter";

  @DomName('PannerNode.panningModel')
  @DocsEditable()
  void set panningModel(String value) native "PannerNode_panningModel_Setter";

  @DomName('PannerNode.refDistance')
  @DocsEditable()
  num get refDistance native "PannerNode_refDistance_Getter";

  @DomName('PannerNode.refDistance')
  @DocsEditable()
  void set refDistance(num value) native "PannerNode_refDistance_Setter";

  @DomName('PannerNode.rolloffFactor')
  @DocsEditable()
  num get rolloffFactor native "PannerNode_rolloffFactor_Getter";

  @DomName('PannerNode.rolloffFactor')
  @DocsEditable()
  void set rolloffFactor(num value) native "PannerNode_rolloffFactor_Setter";

  @DomName('PannerNode.setOrientation')
  @DocsEditable()
  void setOrientation(num x, num y, num z) native "PannerNode_setOrientation_Callback";

  @DomName('PannerNode.setPosition')
  @DocsEditable()
  void setPosition(num x, num y, num z) native "PannerNode_setPosition_Callback";

  @DomName('PannerNode.setVelocity')
  @DocsEditable()
  void setVelocity(num x, num y, num z) native "PannerNode_setVelocity_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('PeriodicWave')
@Experimental() // untriaged
class PeriodicWave extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory PeriodicWave._() { throw new UnsupportedError("Not supported"); }

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('ScriptProcessorNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#ScriptProcessorNode
@Experimental()
class ScriptProcessorNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory ScriptProcessorNode._() { throw new UnsupportedError("Not supported"); }

  /**
   * Static factory designed to expose `audioprocess` events to event
   * handlers that are not necessarily instances of [ScriptProcessorNode].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('ScriptProcessorNode.audioprocessEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<AudioProcessingEvent> audioProcessEvent = const EventStreamProvider<AudioProcessingEvent>('audioprocess');

  @DomName('ScriptProcessorNode.bufferSize')
  @DocsEditable()
  int get bufferSize native "ScriptProcessorNode_bufferSize_Getter";

  @DomName('ScriptProcessorNode._setEventListener')
  @DocsEditable()
  @Experimental() // non-standard
  void _setEventListener(EventListener eventListener) native "ScriptProcessorNode__setEventListener_Callback";

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
  Stream<AudioProcessingEvent> get onAudioProcess => audioProcessEvent.forTarget(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('WaveShaperNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#dfn-WaveShaperNode
@Experimental()
class WaveShaperNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory WaveShaperNode._() { throw new UnsupportedError("Not supported"); }

  @DomName('WaveShaperNode.curve')
  @DocsEditable()
  Float32List get curve native "WaveShaperNode_curve_Getter";

  @DomName('WaveShaperNode.curve')
  @DocsEditable()
  void set curve(Float32List value) native "WaveShaperNode_curve_Setter";

  @DomName('WaveShaperNode.oversample')
  @DocsEditable()
  String get oversample native "WaveShaperNode_oversample_Getter";

  @DomName('WaveShaperNode.oversample')
  @DocsEditable()
  void set oversample(String value) native "WaveShaperNode_oversample_Setter";

}
