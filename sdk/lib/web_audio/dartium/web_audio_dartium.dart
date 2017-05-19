/**
 * High-fidelity audio programming in the browser.
 */
library dart.dom.web_audio;

import 'dart:async';
import 'dart:collection';
import 'dart:_internal';
import 'dart:html';
import 'dart:html_common';
import 'dart:nativewrappers';
import 'dart:typed_data';
import 'dart:_blink' as _blink;
import 'dart:js' as js;
// DO NOT EDIT
// Auto-generated dart:audio library.

// FIXME: Can we make this private?
@Deprecated("Internal Use Only")
final web_audioBlinkMap = {
  'AnalyserNode': () => AnalyserNode.instanceRuntimeType,
  'AudioBuffer': () => AudioBuffer.instanceRuntimeType,
  'AudioBufferSourceNode': () => AudioBufferSourceNode.instanceRuntimeType,
  'AudioContext': () => AudioContext.instanceRuntimeType,
  'AudioDestinationNode': () => AudioDestinationNode.instanceRuntimeType,
  'AudioListener': () => AudioListener.instanceRuntimeType,
  'AudioNode': () => AudioNode.instanceRuntimeType,
  'AudioParam': () => AudioParam.instanceRuntimeType,
  'AudioProcessingEvent': () => AudioProcessingEvent.instanceRuntimeType,
  'AudioSourceNode': () => AudioSourceNode.instanceRuntimeType,
  'BiquadFilterNode': () => BiquadFilterNode.instanceRuntimeType,
  'ChannelMergerNode': () => ChannelMergerNode.instanceRuntimeType,
  'ChannelSplitterNode': () => ChannelSplitterNode.instanceRuntimeType,
  'ConvolverNode': () => ConvolverNode.instanceRuntimeType,
  'DelayNode': () => DelayNode.instanceRuntimeType,
  'DynamicsCompressorNode': () => DynamicsCompressorNode.instanceRuntimeType,
  'GainNode': () => GainNode.instanceRuntimeType,
  'IIRFilterNode': () => IirFilterNode.instanceRuntimeType,
  'MediaElementAudioSourceNode': () =>
      MediaElementAudioSourceNode.instanceRuntimeType,
  'MediaStreamAudioDestinationNode': () =>
      MediaStreamAudioDestinationNode.instanceRuntimeType,
  'MediaStreamAudioSourceNode': () =>
      MediaStreamAudioSourceNode.instanceRuntimeType,
  'OfflineAudioCompletionEvent': () =>
      OfflineAudioCompletionEvent.instanceRuntimeType,
  'OfflineAudioContext': () => OfflineAudioContext.instanceRuntimeType,
  'OscillatorNode': () => OscillatorNode.instanceRuntimeType,
  'PannerNode': () => PannerNode.instanceRuntimeType,
  'PeriodicWave': () => PeriodicWave.instanceRuntimeType,
  'ScriptProcessorNode': () => ScriptProcessorNode.instanceRuntimeType,
  'StereoPannerNode': () => StereoPannerNode.instanceRuntimeType,
  'WaveShaperNode': () => WaveShaperNode.instanceRuntimeType,
};
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
  factory AnalyserNode._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  AnalyserNode.internal_() : super.internal_();

  @DomName('AnalyserNode.fftSize')
  @DocsEditable()
  int get fftSize => _blink.BlinkAnalyserNode.instance.fftSize_Getter_(this);

  @DomName('AnalyserNode.fftSize')
  @DocsEditable()
  set fftSize(int value) =>
      _blink.BlinkAnalyserNode.instance.fftSize_Setter_(this, value);

  @DomName('AnalyserNode.frequencyBinCount')
  @DocsEditable()
  int get frequencyBinCount =>
      _blink.BlinkAnalyserNode.instance.frequencyBinCount_Getter_(this);

  @DomName('AnalyserNode.maxDecibels')
  @DocsEditable()
  num get maxDecibels =>
      _blink.BlinkAnalyserNode.instance.maxDecibels_Getter_(this);

  @DomName('AnalyserNode.maxDecibels')
  @DocsEditable()
  set maxDecibels(num value) =>
      _blink.BlinkAnalyserNode.instance.maxDecibels_Setter_(this, value);

  @DomName('AnalyserNode.minDecibels')
  @DocsEditable()
  num get minDecibels =>
      _blink.BlinkAnalyserNode.instance.minDecibels_Getter_(this);

  @DomName('AnalyserNode.minDecibels')
  @DocsEditable()
  set minDecibels(num value) =>
      _blink.BlinkAnalyserNode.instance.minDecibels_Setter_(this, value);

  @DomName('AnalyserNode.smoothingTimeConstant')
  @DocsEditable()
  num get smoothingTimeConstant =>
      _blink.BlinkAnalyserNode.instance.smoothingTimeConstant_Getter_(this);

  @DomName('AnalyserNode.smoothingTimeConstant')
  @DocsEditable()
  set smoothingTimeConstant(num value) => _blink.BlinkAnalyserNode.instance
      .smoothingTimeConstant_Setter_(this, value);

  @DomName('AnalyserNode.getByteFrequencyData')
  @DocsEditable()
  void getByteFrequencyData(Uint8List array) =>
      _blink.BlinkAnalyserNode.instance
          .getByteFrequencyData_Callback_1_(this, array);

  @DomName('AnalyserNode.getByteTimeDomainData')
  @DocsEditable()
  void getByteTimeDomainData(Uint8List array) =>
      _blink.BlinkAnalyserNode.instance
          .getByteTimeDomainData_Callback_1_(this, array);

  @DomName('AnalyserNode.getFloatFrequencyData')
  @DocsEditable()
  void getFloatFrequencyData(Float32List array) =>
      _blink.BlinkAnalyserNode.instance
          .getFloatFrequencyData_Callback_1_(this, array);

  @DomName('AnalyserNode.getFloatTimeDomainData')
  @DocsEditable()
  @Experimental() // untriaged
  void getFloatTimeDomainData(Float32List array) =>
      _blink.BlinkAnalyserNode.instance
          .getFloatTimeDomainData_Callback_1_(this, array);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('AudioBuffer')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioBuffer-section
@Experimental()
class AudioBuffer extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory AudioBuffer._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  AudioBuffer.internal_() {}

  @DomName('AudioBuffer.duration')
  @DocsEditable()
  num get duration => _blink.BlinkAudioBuffer.instance.duration_Getter_(this);

  @DomName('AudioBuffer.length')
  @DocsEditable()
  int get length => _blink.BlinkAudioBuffer.instance.length_Getter_(this);

  @DomName('AudioBuffer.numberOfChannels')
  @DocsEditable()
  int get numberOfChannels =>
      _blink.BlinkAudioBuffer.instance.numberOfChannels_Getter_(this);

  @DomName('AudioBuffer.sampleRate')
  @DocsEditable()
  num get sampleRate =>
      _blink.BlinkAudioBuffer.instance.sampleRate_Getter_(this);

  void copyFromChannel(Float32List destination, int channelNumber,
      [int startInChannel]) {
    if (startInChannel != null) {
      _blink.BlinkAudioBuffer.instance.copyFromChannel_Callback_3_(
          this, destination, channelNumber, startInChannel);
      return;
    }
    _blink.BlinkAudioBuffer.instance
        .copyFromChannel_Callback_2_(this, destination, channelNumber);
    return;
  }

  void copyToChannel(Float32List source, int channelNumber,
      [int startInChannel]) {
    if (startInChannel != null) {
      _blink.BlinkAudioBuffer.instance.copyToChannel_Callback_3_(
          this, source, channelNumber, startInChannel);
      return;
    }
    _blink.BlinkAudioBuffer.instance
        .copyToChannel_Callback_2_(this, source, channelNumber);
    return;
  }

  @DomName('AudioBuffer.getChannelData')
  @DocsEditable()
  Float32List getChannelData(int channelIndex) =>
      _blink.BlinkAudioBuffer.instance
          .getChannelData_Callback_1_(this, channelIndex);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DomName('AudioBufferCallback')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioBuffer-section
@Experimental()
typedef void AudioBufferCallback(audioBuffer_OR_exception);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('AudioBufferSourceNode')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@Experimental()
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioBufferSourceNode-section
class AudioBufferSourceNode extends AudioSourceNode {
  // To suppress missing implicit constructor warnings.
  factory AudioBufferSourceNode._() {
    throw new UnsupportedError("Not supported");
  }

  /**
   * Static factory designed to expose `ended` events to event
   * handlers that are not necessarily instances of [AudioBufferSourceNode].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('AudioBufferSourceNode.endedEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> endedEvent =
      const EventStreamProvider<Event>('ended');

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  AudioBufferSourceNode.internal_() : super.internal_();

  @DomName('AudioBufferSourceNode.buffer')
  @DocsEditable()
  AudioBuffer get buffer =>
      _blink.BlinkAudioBufferSourceNode.instance.buffer_Getter_(this);

  @DomName('AudioBufferSourceNode.buffer')
  @DocsEditable()
  set buffer(AudioBuffer value) =>
      _blink.BlinkAudioBufferSourceNode.instance.buffer_Setter_(this, value);

  @DomName('AudioBufferSourceNode.detune')
  @DocsEditable()
  @Experimental() // untriaged
  AudioParam get detune =>
      _blink.BlinkAudioBufferSourceNode.instance.detune_Getter_(this);

  @DomName('AudioBufferSourceNode.loop')
  @DocsEditable()
  bool get loop =>
      _blink.BlinkAudioBufferSourceNode.instance.loop_Getter_(this);

  @DomName('AudioBufferSourceNode.loop')
  @DocsEditable()
  set loop(bool value) =>
      _blink.BlinkAudioBufferSourceNode.instance.loop_Setter_(this, value);

  @DomName('AudioBufferSourceNode.loopEnd')
  @DocsEditable()
  num get loopEnd =>
      _blink.BlinkAudioBufferSourceNode.instance.loopEnd_Getter_(this);

  @DomName('AudioBufferSourceNode.loopEnd')
  @DocsEditable()
  set loopEnd(num value) =>
      _blink.BlinkAudioBufferSourceNode.instance.loopEnd_Setter_(this, value);

  @DomName('AudioBufferSourceNode.loopStart')
  @DocsEditable()
  num get loopStart =>
      _blink.BlinkAudioBufferSourceNode.instance.loopStart_Getter_(this);

  @DomName('AudioBufferSourceNode.loopStart')
  @DocsEditable()
  set loopStart(num value) =>
      _blink.BlinkAudioBufferSourceNode.instance.loopStart_Setter_(this, value);

  @DomName('AudioBufferSourceNode.playbackRate')
  @DocsEditable()
  AudioParam get playbackRate =>
      _blink.BlinkAudioBufferSourceNode.instance.playbackRate_Getter_(this);

  void start([num when, num grainOffset, num grainDuration]) {
    if (grainDuration != null) {
      _blink.BlinkAudioBufferSourceNode.instance
          .start_Callback_3_(this, when, grainOffset, grainDuration);
      return;
    }
    if (grainOffset != null) {
      _blink.BlinkAudioBufferSourceNode.instance
          .start_Callback_2_(this, when, grainOffset);
      return;
    }
    if (when != null) {
      _blink.BlinkAudioBufferSourceNode.instance.start_Callback_1_(this, when);
      return;
    }
    _blink.BlinkAudioBufferSourceNode.instance.start_Callback_0_(this);
    return;
  }

  void stop([num when]) {
    if (when != null) {
      _blink.BlinkAudioBufferSourceNode.instance.stop_Callback_1_(this, when);
      return;
    }
    _blink.BlinkAudioBufferSourceNode.instance.stop_Callback_0_(this);
    return;
  }

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
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@Experimental()
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioContext-section
class AudioContext extends EventTarget {
  // To suppress missing implicit constructor warnings.
  factory AudioContext._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('AudioContext.AudioContext')
  @DocsEditable()
  factory AudioContext() {
    return _blink.BlinkAudioContext.instance.constructorCallback_0_();
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  AudioContext.internal_() : super.internal_();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('AudioContext.currentTime')
  @DocsEditable()
  num get currentTime =>
      _blink.BlinkAudioContext.instance.currentTime_Getter_(this);

  @DomName('AudioContext.destination')
  @DocsEditable()
  AudioDestinationNode get destination =>
      _blink.BlinkAudioContext.instance.destination_Getter_(this);

  @DomName('AudioContext.listener')
  @DocsEditable()
  AudioListener get listener =>
      _blink.BlinkAudioContext.instance.listener_Getter_(this);

  @DomName('AudioContext.sampleRate')
  @DocsEditable()
  num get sampleRate =>
      _blink.BlinkAudioContext.instance.sampleRate_Getter_(this);

  @DomName('AudioContext.state')
  @DocsEditable()
  @Experimental() // untriaged
  String get state => _blink.BlinkAudioContext.instance.state_Getter_(this);

  @DomName('AudioContext.close')
  @DocsEditable()
  @Experimental() // untriaged
  Future close() => convertNativePromiseToDartFuture(
      _blink.BlinkAudioContext.instance.close_Callback_0_(this));

  @DomName('AudioContext.createAnalyser')
  @DocsEditable()
  AnalyserNode createAnalyser() =>
      _blink.BlinkAudioContext.instance.createAnalyser_Callback_0_(this);

  @DomName('AudioContext.createBiquadFilter')
  @DocsEditable()
  BiquadFilterNode createBiquadFilter() =>
      _blink.BlinkAudioContext.instance.createBiquadFilter_Callback_0_(this);

  @DomName('AudioContext.createBuffer')
  @DocsEditable()
  AudioBuffer createBuffer(
          int numberOfChannels, int numberOfFrames, num sampleRate) =>
      _blink.BlinkAudioContext.instance.createBuffer_Callback_3_(
          this, numberOfChannels, numberOfFrames, sampleRate);

  @DomName('AudioContext.createBufferSource')
  @DocsEditable()
  AudioBufferSourceNode createBufferSource() =>
      _blink.BlinkAudioContext.instance.createBufferSource_Callback_0_(this);

  ChannelMergerNode createChannelMerger([int numberOfInputs]) {
    if (numberOfInputs != null) {
      return _blink.BlinkAudioContext.instance
          .createChannelMerger_Callback_1_(this, numberOfInputs);
    }
    return _blink.BlinkAudioContext.instance
        .createChannelMerger_Callback_0_(this);
  }

  ChannelSplitterNode createChannelSplitter([int numberOfOutputs]) {
    if (numberOfOutputs != null) {
      return _blink.BlinkAudioContext.instance
          .createChannelSplitter_Callback_1_(this, numberOfOutputs);
    }
    return _blink.BlinkAudioContext.instance
        .createChannelSplitter_Callback_0_(this);
  }

  @DomName('AudioContext.createConvolver')
  @DocsEditable()
  ConvolverNode createConvolver() =>
      _blink.BlinkAudioContext.instance.createConvolver_Callback_0_(this);

  DelayNode createDelay([num maxDelayTime]) {
    if (maxDelayTime != null) {
      return _blink.BlinkAudioContext.instance
          .createDelay_Callback_1_(this, maxDelayTime);
    }
    return _blink.BlinkAudioContext.instance.createDelay_Callback_0_(this);
  }

  @DomName('AudioContext.createDynamicsCompressor')
  @DocsEditable()
  DynamicsCompressorNode createDynamicsCompressor() =>
      _blink.BlinkAudioContext.instance
          .createDynamicsCompressor_Callback_0_(this);

  @DomName('AudioContext.createGain')
  @DocsEditable()
  GainNode createGain() =>
      _blink.BlinkAudioContext.instance.createGain_Callback_0_(this);

  @DomName('AudioContext.createIIRFilter')
  @DocsEditable()
  @Experimental() // untriaged
  IirFilterNode createIirFilter(List<num> feedForward, List<num> feedBack) =>
      _blink.BlinkAudioContext.instance
          .createIIRFilter_Callback_2_(this, feedForward, feedBack);

  @DomName('AudioContext.createMediaElementSource')
  @DocsEditable()
  MediaElementAudioSourceNode createMediaElementSource(
          MediaElement mediaElement) =>
      _blink.BlinkAudioContext.instance
          .createMediaElementSource_Callback_1_(this, mediaElement);

  @DomName('AudioContext.createMediaStreamDestination')
  @DocsEditable()
  MediaStreamAudioDestinationNode createMediaStreamDestination() =>
      _blink.BlinkAudioContext.instance
          .createMediaStreamDestination_Callback_0_(this);

  @DomName('AudioContext.createMediaStreamSource')
  @DocsEditable()
  MediaStreamAudioSourceNode createMediaStreamSource(MediaStream mediaStream) =>
      _blink.BlinkAudioContext.instance
          .createMediaStreamSource_Callback_1_(this, mediaStream);

  @DomName('AudioContext.createOscillator')
  @DocsEditable()
  OscillatorNode createOscillator() =>
      _blink.BlinkAudioContext.instance.createOscillator_Callback_0_(this);

  @DomName('AudioContext.createPanner')
  @DocsEditable()
  PannerNode createPanner() =>
      _blink.BlinkAudioContext.instance.createPanner_Callback_0_(this);

  PeriodicWave createPeriodicWave(Float32List real, Float32List imag,
      [Map options]) {
    if (options != null) {
      return _blink.BlinkAudioContext.instance.createPeriodicWave_Callback_3_(
          this, real, imag, convertDartToNative_Dictionary(options));
    }
    return _blink.BlinkAudioContext.instance
        .createPeriodicWave_Callback_2_(this, real, imag);
  }

  ScriptProcessorNode createScriptProcessor(
      [int bufferSize, int numberOfInputChannels, int numberOfOutputChannels]) {
    if (numberOfOutputChannels != null) {
      return _blink.BlinkAudioContext.instance
          .createScriptProcessor_Callback_3_(
              this, bufferSize, numberOfInputChannels, numberOfOutputChannels);
    }
    if (numberOfInputChannels != null) {
      return _blink.BlinkAudioContext.instance
          .createScriptProcessor_Callback_2_(
              this, bufferSize, numberOfInputChannels);
    }
    if (bufferSize != null) {
      return _blink.BlinkAudioContext.instance
          .createScriptProcessor_Callback_1_(this, bufferSize);
    }
    return _blink.BlinkAudioContext.instance
        .createScriptProcessor_Callback_0_(this);
  }

  @DomName('AudioContext.createStereoPanner')
  @DocsEditable()
  @Experimental() // untriaged
  StereoPannerNode createStereoPanner() =>
      _blink.BlinkAudioContext.instance.createStereoPanner_Callback_0_(this);

  @DomName('AudioContext.createWaveShaper')
  @DocsEditable()
  WaveShaperNode createWaveShaper() =>
      _blink.BlinkAudioContext.instance.createWaveShaper_Callback_0_(this);

  Future _decodeAudioData(ByteBuffer audioData,
      [AudioBufferCallback successCallback,
      AudioBufferCallback errorCallback]) {
    if (errorCallback != null) {
      return _blink.BlinkAudioContext.instance.decodeAudioData_Callback_3_(
          this, audioData, successCallback, errorCallback);
    }
    if (successCallback != null) {
      return _blink.BlinkAudioContext.instance
          .decodeAudioData_Callback_2_(this, audioData, successCallback);
    }
    return _blink.BlinkAudioContext.instance
        .decodeAudioData_Callback_1_(this, audioData);
  }

  @DomName('AudioContext.resume')
  @DocsEditable()
  @Experimental() // untriaged
  Future resume() => convertNativePromiseToDartFuture(
      _blink.BlinkAudioContext.instance.resume_Callback_0_(this));

  @DomName('AudioContext.suspend')
  @DocsEditable()
  @Experimental() // untriaged
  Future suspend() => convertNativePromiseToDartFuture(
      _blink.BlinkAudioContext.instance.suspend_Callback_0_(this));

  @DomName('AudioContext.decodeAudioData')
  Future<AudioBuffer> decodeAudioData(ByteBuffer audioData) {
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

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('AudioDestinationNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioDestinationNode-section
@Experimental()
class AudioDestinationNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory AudioDestinationNode._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  AudioDestinationNode.internal_() : super.internal_();

  @DomName('AudioDestinationNode.maxChannelCount')
  @DocsEditable()
  int get maxChannelCount =>
      _blink.BlinkAudioDestinationNode.instance.maxChannelCount_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('AudioListener')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioListener-section
@Experimental()
class AudioListener extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory AudioListener._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  AudioListener.internal_() {}

  @DomName('AudioListener.dopplerFactor')
  @DocsEditable()
  num get dopplerFactor =>
      _blink.BlinkAudioListener.instance.dopplerFactor_Getter_(this);

  @DomName('AudioListener.dopplerFactor')
  @DocsEditable()
  set dopplerFactor(num value) =>
      _blink.BlinkAudioListener.instance.dopplerFactor_Setter_(this, value);

  @DomName('AudioListener.speedOfSound')
  @DocsEditable()
  num get speedOfSound =>
      _blink.BlinkAudioListener.instance.speedOfSound_Getter_(this);

  @DomName('AudioListener.speedOfSound')
  @DocsEditable()
  set speedOfSound(num value) =>
      _blink.BlinkAudioListener.instance.speedOfSound_Setter_(this, value);

  @DomName('AudioListener.setOrientation')
  @DocsEditable()
  void setOrientation(num x, num y, num z, num xUp, num yUp, num zUp) =>
      _blink.BlinkAudioListener.instance
          .setOrientation_Callback_6_(this, x, y, z, xUp, yUp, zUp);

  @DomName('AudioListener.setPosition')
  @DocsEditable()
  void setPosition(num x, num y, num z) =>
      _blink.BlinkAudioListener.instance.setPosition_Callback_3_(this, x, y, z);

  @DomName('AudioListener.setVelocity')
  @DocsEditable()
  void setVelocity(num x, num y, num z) =>
      _blink.BlinkAudioListener.instance.setVelocity_Callback_3_(this, x, y, z);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DomName('AudioNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioNode-section
@Experimental()
class AudioNode extends EventTarget {
  // To suppress missing implicit constructor warnings.
  factory AudioNode._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  AudioNode.internal_() : super.internal_();

  @DomName('AudioNode.channelCount')
  @DocsEditable()
  int get channelCount =>
      _blink.BlinkAudioNode.instance.channelCount_Getter_(this);

  @DomName('AudioNode.channelCount')
  @DocsEditable()
  set channelCount(int value) =>
      _blink.BlinkAudioNode.instance.channelCount_Setter_(this, value);

  @DomName('AudioNode.channelCountMode')
  @DocsEditable()
  String get channelCountMode =>
      _blink.BlinkAudioNode.instance.channelCountMode_Getter_(this);

  @DomName('AudioNode.channelCountMode')
  @DocsEditable()
  set channelCountMode(String value) =>
      _blink.BlinkAudioNode.instance.channelCountMode_Setter_(this, value);

  @DomName('AudioNode.channelInterpretation')
  @DocsEditable()
  String get channelInterpretation =>
      _blink.BlinkAudioNode.instance.channelInterpretation_Getter_(this);

  @DomName('AudioNode.channelInterpretation')
  @DocsEditable()
  set channelInterpretation(String value) =>
      _blink.BlinkAudioNode.instance.channelInterpretation_Setter_(this, value);

  @DomName('AudioNode.context')
  @DocsEditable()
  AudioContext get context =>
      _blink.BlinkAudioNode.instance.context_Getter_(this);

  @DomName('AudioNode.numberOfInputs')
  @DocsEditable()
  int get numberOfInputs =>
      _blink.BlinkAudioNode.instance.numberOfInputs_Getter_(this);

  @DomName('AudioNode.numberOfOutputs')
  @DocsEditable()
  int get numberOfOutputs =>
      _blink.BlinkAudioNode.instance.numberOfOutputs_Getter_(this);

  AudioNode _connect(destination, [int output, int input]) {
    if ((destination is AudioNode) && output == null && input == null) {
      return _blink.BlinkAudioNode.instance
          .connect_Callback_1_(this, destination);
    }
    if ((output is int || output == null) &&
        (destination is AudioNode) &&
        input == null) {
      return _blink.BlinkAudioNode.instance
          .connect_Callback_2_(this, destination, output);
    }
    if ((input is int || input == null) &&
        (output is int || output == null) &&
        (destination is AudioNode)) {
      return _blink.BlinkAudioNode.instance
          .connect_Callback_3_(this, destination, output, input);
    }
    if ((destination is AudioParam) && output == null && input == null) {
      return _blink.BlinkAudioNode.instance
          .connect_Callback_1_(this, destination);
    }
    if ((output is int || output == null) &&
        (destination is AudioParam) &&
        input == null) {
      return _blink.BlinkAudioNode.instance
          .connect_Callback_2_(this, destination, output);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  void disconnect([destination_OR_output, int output, int input]) {
    if (destination_OR_output == null && output == null && input == null) {
      _blink.BlinkAudioNode.instance.disconnect_Callback_0_(this);
      return;
    }
    if ((destination_OR_output is int) && output == null && input == null) {
      _blink.BlinkAudioNode.instance
          .disconnect_Callback_1_(this, destination_OR_output);
      return;
    }
    if ((destination_OR_output is AudioNode) &&
        output == null &&
        input == null) {
      _blink.BlinkAudioNode.instance
          .disconnect_Callback_1_(this, destination_OR_output);
      return;
    }
    if ((output is int) &&
        (destination_OR_output is AudioNode) &&
        input == null) {
      _blink.BlinkAudioNode.instance
          .disconnect_Callback_2_(this, destination_OR_output, output);
      return;
    }
    if ((input is int) &&
        (output is int) &&
        (destination_OR_output is AudioNode)) {
      _blink.BlinkAudioNode.instance
          .disconnect_Callback_3_(this, destination_OR_output, output, input);
      return;
    }
    if ((destination_OR_output is AudioParam) &&
        output == null &&
        input == null) {
      _blink.BlinkAudioNode.instance
          .disconnect_Callback_1_(this, destination_OR_output);
      return;
    }
    if ((output is int) &&
        (destination_OR_output is AudioParam) &&
        input == null) {
      _blink.BlinkAudioNode.instance
          .disconnect_Callback_2_(this, destination_OR_output, output);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @DomName('AudioNode.connect')
  void connectNode(AudioNode destination, [int output = 0, int input = 0]) {
    _connect(destination, output, input);
  }

  @DomName('AudioNode.connect')
  void connectParam(AudioParam destination, [int output = 0]) {
    _connect(destination, output);
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('AudioParam')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioParam
@Experimental()
class AudioParam extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory AudioParam._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  AudioParam.internal_() {}

  @DomName('AudioParam.defaultValue')
  @DocsEditable()
  num get defaultValue =>
      _blink.BlinkAudioParam.instance.defaultValue_Getter_(this);

  @DomName('AudioParam.value')
  @DocsEditable()
  num get value => _blink.BlinkAudioParam.instance.value_Getter_(this);

  @DomName('AudioParam.value')
  @DocsEditable()
  set value(num value) =>
      _blink.BlinkAudioParam.instance.value_Setter_(this, value);

  @DomName('AudioParam.cancelScheduledValues')
  @DocsEditable()
  AudioParam cancelScheduledValues(num startTime) =>
      _blink.BlinkAudioParam.instance
          .cancelScheduledValues_Callback_1_(this, startTime);

  @DomName('AudioParam.exponentialRampToValueAtTime')
  @DocsEditable()
  AudioParam exponentialRampToValueAtTime(num value, num time) =>
      _blink.BlinkAudioParam.instance
          .exponentialRampToValueAtTime_Callback_2_(this, value, time);

  @DomName('AudioParam.linearRampToValueAtTime')
  @DocsEditable()
  AudioParam linearRampToValueAtTime(num value, num time) =>
      _blink.BlinkAudioParam.instance
          .linearRampToValueAtTime_Callback_2_(this, value, time);

  AudioParam setTargetAtTime(num target, num time, num timeConstant) {
    if ((timeConstant is num) && (time is num) && (target is num)) {
      return _blink.BlinkAudioParam.instance
          .setTargetAtTime_Callback_3_(this, target, time, timeConstant);
    }
    if ((timeConstant is num) && (time is num) && (target is num)) {
      return _blink.BlinkAudioParam.instance
          .setTargetAtTime_Callback_3_(this, target, time, timeConstant);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @DomName('AudioParam.setValueAtTime')
  @DocsEditable()
  AudioParam setValueAtTime(num value, num time) =>
      _blink.BlinkAudioParam.instance
          .setValueAtTime_Callback_2_(this, value, time);

  @DomName('AudioParam.setValueCurveAtTime')
  @DocsEditable()
  AudioParam setValueCurveAtTime(Float32List values, num time, num duration) =>
      _blink.BlinkAudioParam.instance
          .setValueCurveAtTime_Callback_3_(this, values, time, duration);
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
  factory AudioProcessingEvent._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  AudioProcessingEvent.internal_() : super.internal_();

  @DomName('AudioProcessingEvent.inputBuffer')
  @DocsEditable()
  AudioBuffer get inputBuffer =>
      _blink.BlinkAudioProcessingEvent.instance.inputBuffer_Getter_(this);

  @DomName('AudioProcessingEvent.outputBuffer')
  @DocsEditable()
  AudioBuffer get outputBuffer =>
      _blink.BlinkAudioProcessingEvent.instance.outputBuffer_Getter_(this);

  @DomName('AudioProcessingEvent.playbackTime')
  @DocsEditable()
  @Experimental() // untriaged
  num get playbackTime =>
      _blink.BlinkAudioProcessingEvent.instance.playbackTime_Getter_(this);
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
  factory AudioSourceNode._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  AudioSourceNode.internal_() : super.internal_();
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
  factory BiquadFilterNode._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  BiquadFilterNode.internal_() : super.internal_();

  @DomName('BiquadFilterNode.Q')
  @DocsEditable()
  AudioParam get Q => _blink.BlinkBiquadFilterNode.instance.Q_Getter_(this);

  @DomName('BiquadFilterNode.detune')
  @DocsEditable()
  AudioParam get detune =>
      _blink.BlinkBiquadFilterNode.instance.detune_Getter_(this);

  @DomName('BiquadFilterNode.frequency')
  @DocsEditable()
  AudioParam get frequency =>
      _blink.BlinkBiquadFilterNode.instance.frequency_Getter_(this);

  @DomName('BiquadFilterNode.gain')
  @DocsEditable()
  AudioParam get gain =>
      _blink.BlinkBiquadFilterNode.instance.gain_Getter_(this);

  @DomName('BiquadFilterNode.type')
  @DocsEditable()
  String get type => _blink.BlinkBiquadFilterNode.instance.type_Getter_(this);

  @DomName('BiquadFilterNode.type')
  @DocsEditable()
  set type(String value) =>
      _blink.BlinkBiquadFilterNode.instance.type_Setter_(this, value);

  @DomName('BiquadFilterNode.getFrequencyResponse')
  @DocsEditable()
  void getFrequencyResponse(Float32List frequencyHz, Float32List magResponse,
          Float32List phaseResponse) =>
      _blink.BlinkBiquadFilterNode.instance.getFrequencyResponse_Callback_3_(
          this, frequencyHz, magResponse, phaseResponse);
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
  factory ChannelMergerNode._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  ChannelMergerNode.internal_() : super.internal_();
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
  factory ChannelSplitterNode._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  ChannelSplitterNode.internal_() : super.internal_();
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
  factory ConvolverNode._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  ConvolverNode.internal_() : super.internal_();

  @DomName('ConvolverNode.buffer')
  @DocsEditable()
  AudioBuffer get buffer =>
      _blink.BlinkConvolverNode.instance.buffer_Getter_(this);

  @DomName('ConvolverNode.buffer')
  @DocsEditable()
  set buffer(AudioBuffer value) =>
      _blink.BlinkConvolverNode.instance.buffer_Setter_(this, value);

  @DomName('ConvolverNode.normalize')
  @DocsEditable()
  bool get normalize =>
      _blink.BlinkConvolverNode.instance.normalize_Getter_(this);

  @DomName('ConvolverNode.normalize')
  @DocsEditable()
  set normalize(bool value) =>
      _blink.BlinkConvolverNode.instance.normalize_Setter_(this, value);
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
  factory DelayNode._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  DelayNode.internal_() : super.internal_();

  @DomName('DelayNode.delayTime')
  @DocsEditable()
  AudioParam get delayTime =>
      _blink.BlinkDelayNode.instance.delayTime_Getter_(this);
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
  factory DynamicsCompressorNode._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  DynamicsCompressorNode.internal_() : super.internal_();

  @DomName('DynamicsCompressorNode.attack')
  @DocsEditable()
  AudioParam get attack =>
      _blink.BlinkDynamicsCompressorNode.instance.attack_Getter_(this);

  @DomName('DynamicsCompressorNode.knee')
  @DocsEditable()
  AudioParam get knee =>
      _blink.BlinkDynamicsCompressorNode.instance.knee_Getter_(this);

  @DomName('DynamicsCompressorNode.ratio')
  @DocsEditable()
  AudioParam get ratio =>
      _blink.BlinkDynamicsCompressorNode.instance.ratio_Getter_(this);

  @DomName('DynamicsCompressorNode.reduction')
  @DocsEditable()
  AudioParam get reduction =>
      _blink.BlinkDynamicsCompressorNode.instance.reduction_Getter_(this);

  @DomName('DynamicsCompressorNode.release')
  @DocsEditable()
  AudioParam get release =>
      _blink.BlinkDynamicsCompressorNode.instance.release_Getter_(this);

  @DomName('DynamicsCompressorNode.threshold')
  @DocsEditable()
  AudioParam get threshold =>
      _blink.BlinkDynamicsCompressorNode.instance.threshold_Getter_(this);
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
  factory GainNode._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  GainNode.internal_() : super.internal_();

  @DomName('GainNode.gain')
  @DocsEditable()
  AudioParam get gain => _blink.BlinkGainNode.instance.gain_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('IIRFilterNode')
@Experimental() // untriaged
class IirFilterNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory IirFilterNode._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  IirFilterNode.internal_() : super.internal_();

  @DomName('IIRFilterNode.getFrequencyResponse')
  @DocsEditable()
  @Experimental() // untriaged
  void getFrequencyResponse(Float32List frequencyHz, Float32List magResponse,
          Float32List phaseResponse) =>
      _blink.BlinkIIRFilterNode.instance.getFrequencyResponse_Callback_3_(
          this, frequencyHz, magResponse, phaseResponse);
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
  factory MediaElementAudioSourceNode._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  MediaElementAudioSourceNode.internal_() : super.internal_();

  @DomName('MediaElementAudioSourceNode.mediaElement')
  @DocsEditable()
  @Experimental() // non-standard
  MediaElement get mediaElement =>
      _blink.BlinkMediaElementAudioSourceNode.instance
          .mediaElement_Getter_(this);
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
  factory MediaStreamAudioDestinationNode._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  MediaStreamAudioDestinationNode.internal_() : super.internal_();

  @DomName('MediaStreamAudioDestinationNode.stream')
  @DocsEditable()
  MediaStream get stream =>
      _blink.BlinkMediaStreamAudioDestinationNode.instance.stream_Getter_(this);
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
  factory MediaStreamAudioSourceNode._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  MediaStreamAudioSourceNode.internal_() : super.internal_();

  @DomName('MediaStreamAudioSourceNode.mediaStream')
  @DocsEditable()
  MediaStream get mediaStream =>
      _blink.BlinkMediaStreamAudioSourceNode.instance.mediaStream_Getter_(this);
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
  factory OfflineAudioCompletionEvent._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  OfflineAudioCompletionEvent.internal_() : super.internal_();

  @DomName('OfflineAudioCompletionEvent.renderedBuffer')
  @DocsEditable()
  AudioBuffer get renderedBuffer =>
      _blink.BlinkOfflineAudioCompletionEvent.instance
          .renderedBuffer_Getter_(this);
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
  factory OfflineAudioContext._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('OfflineAudioContext.OfflineAudioContext')
  @DocsEditable()
  factory OfflineAudioContext(
      int numberOfChannels, int numberOfFrames, num sampleRate) {
    return _blink.BlinkOfflineAudioContext.instance
        .constructorCallback_3_(numberOfChannels, numberOfFrames, sampleRate);
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  OfflineAudioContext.internal_() : super.internal_();

  @DomName('OfflineAudioContext.resume')
  @DocsEditable()
  @Experimental() // untriaged
  Future resume() => convertNativePromiseToDartFuture(
      _blink.BlinkOfflineAudioContext.instance.resume_Callback_0_(this));

  @DomName('OfflineAudioContext.startRendering')
  @DocsEditable()
  @Experimental() // untriaged
  Future startRendering() =>
      convertNativePromiseToDartFuture(_blink.BlinkOfflineAudioContext.instance
          .startRendering_Callback_0_(this));

  @DomName('OfflineAudioContext.suspend')
  @DocsEditable()
  @Experimental() // untriaged
  Future suspendFor(num suspendTime) =>
      convertNativePromiseToDartFuture(_blink.BlinkOfflineAudioContext.instance
          .suspend_Callback_1_(this, suspendTime));
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
  factory OscillatorNode._() {
    throw new UnsupportedError("Not supported");
  }

  /**
   * Static factory designed to expose `ended` events to event
   * handlers that are not necessarily instances of [OscillatorNode].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('OscillatorNode.endedEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> endedEvent =
      const EventStreamProvider<Event>('ended');

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  OscillatorNode.internal_() : super.internal_();

  @DomName('OscillatorNode.detune')
  @DocsEditable()
  AudioParam get detune =>
      _blink.BlinkOscillatorNode.instance.detune_Getter_(this);

  @DomName('OscillatorNode.frequency')
  @DocsEditable()
  AudioParam get frequency =>
      _blink.BlinkOscillatorNode.instance.frequency_Getter_(this);

  @DomName('OscillatorNode.type')
  @DocsEditable()
  String get type => _blink.BlinkOscillatorNode.instance.type_Getter_(this);

  @DomName('OscillatorNode.type')
  @DocsEditable()
  set type(String value) =>
      _blink.BlinkOscillatorNode.instance.type_Setter_(this, value);

  @DomName('OscillatorNode.setPeriodicWave')
  @DocsEditable()
  @Experimental() // untriaged
  void setPeriodicWave(PeriodicWave periodicWave) =>
      _blink.BlinkOscillatorNode.instance
          .setPeriodicWave_Callback_1_(this, periodicWave);

  void start([num when]) {
    if (when != null) {
      _blink.BlinkOscillatorNode.instance.start_Callback_1_(this, when);
      return;
    }
    _blink.BlinkOscillatorNode.instance.start_Callback_0_(this);
    return;
  }

  void stop([num when]) {
    if (when != null) {
      _blink.BlinkOscillatorNode.instance.stop_Callback_1_(this, when);
      return;
    }
    _blink.BlinkOscillatorNode.instance.stop_Callback_0_(this);
    return;
  }

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
  factory PannerNode._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  PannerNode.internal_() : super.internal_();

  @DomName('PannerNode.coneInnerAngle')
  @DocsEditable()
  num get coneInnerAngle =>
      _blink.BlinkPannerNode.instance.coneInnerAngle_Getter_(this);

  @DomName('PannerNode.coneInnerAngle')
  @DocsEditable()
  set coneInnerAngle(num value) =>
      _blink.BlinkPannerNode.instance.coneInnerAngle_Setter_(this, value);

  @DomName('PannerNode.coneOuterAngle')
  @DocsEditable()
  num get coneOuterAngle =>
      _blink.BlinkPannerNode.instance.coneOuterAngle_Getter_(this);

  @DomName('PannerNode.coneOuterAngle')
  @DocsEditable()
  set coneOuterAngle(num value) =>
      _blink.BlinkPannerNode.instance.coneOuterAngle_Setter_(this, value);

  @DomName('PannerNode.coneOuterGain')
  @DocsEditable()
  num get coneOuterGain =>
      _blink.BlinkPannerNode.instance.coneOuterGain_Getter_(this);

  @DomName('PannerNode.coneOuterGain')
  @DocsEditable()
  set coneOuterGain(num value) =>
      _blink.BlinkPannerNode.instance.coneOuterGain_Setter_(this, value);

  @DomName('PannerNode.distanceModel')
  @DocsEditable()
  String get distanceModel =>
      _blink.BlinkPannerNode.instance.distanceModel_Getter_(this);

  @DomName('PannerNode.distanceModel')
  @DocsEditable()
  set distanceModel(String value) =>
      _blink.BlinkPannerNode.instance.distanceModel_Setter_(this, value);

  @DomName('PannerNode.maxDistance')
  @DocsEditable()
  num get maxDistance =>
      _blink.BlinkPannerNode.instance.maxDistance_Getter_(this);

  @DomName('PannerNode.maxDistance')
  @DocsEditable()
  set maxDistance(num value) =>
      _blink.BlinkPannerNode.instance.maxDistance_Setter_(this, value);

  @DomName('PannerNode.panningModel')
  @DocsEditable()
  String get panningModel =>
      _blink.BlinkPannerNode.instance.panningModel_Getter_(this);

  @DomName('PannerNode.panningModel')
  @DocsEditable()
  set panningModel(String value) =>
      _blink.BlinkPannerNode.instance.panningModel_Setter_(this, value);

  @DomName('PannerNode.refDistance')
  @DocsEditable()
  num get refDistance =>
      _blink.BlinkPannerNode.instance.refDistance_Getter_(this);

  @DomName('PannerNode.refDistance')
  @DocsEditable()
  set refDistance(num value) =>
      _blink.BlinkPannerNode.instance.refDistance_Setter_(this, value);

  @DomName('PannerNode.rolloffFactor')
  @DocsEditable()
  num get rolloffFactor =>
      _blink.BlinkPannerNode.instance.rolloffFactor_Getter_(this);

  @DomName('PannerNode.rolloffFactor')
  @DocsEditable()
  set rolloffFactor(num value) =>
      _blink.BlinkPannerNode.instance.rolloffFactor_Setter_(this, value);

  @DomName('PannerNode.setOrientation')
  @DocsEditable()
  void setOrientation(num x, num y, num z) =>
      _blink.BlinkPannerNode.instance.setOrientation_Callback_3_(this, x, y, z);

  @DomName('PannerNode.setPosition')
  @DocsEditable()
  void setPosition(num x, num y, num z) =>
      _blink.BlinkPannerNode.instance.setPosition_Callback_3_(this, x, y, z);

  @DomName('PannerNode.setVelocity')
  @DocsEditable()
  void setVelocity(num x, num y, num z) =>
      _blink.BlinkPannerNode.instance.setVelocity_Callback_3_(this, x, y, z);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('PeriodicWave')
@Experimental() // untriaged
class PeriodicWave extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory PeriodicWave._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  PeriodicWave.internal_() {}
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
  factory ScriptProcessorNode._() {
    throw new UnsupportedError("Not supported");
  }

  /**
   * Static factory designed to expose `audioprocess` events to event
   * handlers that are not necessarily instances of [ScriptProcessorNode].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('ScriptProcessorNode.audioprocessEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<AudioProcessingEvent> audioProcessEvent =
      const EventStreamProvider<AudioProcessingEvent>('audioprocess');

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  ScriptProcessorNode.internal_() : super.internal_();

  @DomName('ScriptProcessorNode.bufferSize')
  @DocsEditable()
  int get bufferSize =>
      _blink.BlinkScriptProcessorNode.instance.bufferSize_Getter_(this);

  @DomName('ScriptProcessorNode.setEventListener')
  @DocsEditable()
  @Experimental() // untriaged
  void setEventListener(EventListener eventListener) =>
      _blink.BlinkScriptProcessorNode.instance
          .setEventListener_Callback_1_(this, eventListener);

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
  Stream<AudioProcessingEvent> get onAudioProcess =>
      audioProcessEvent.forTarget(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('StereoPannerNode')
@Experimental() // untriaged
class StereoPannerNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory StereoPannerNode._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  StereoPannerNode.internal_() : super.internal_();

  @DomName('StereoPannerNode.pan')
  @DocsEditable()
  @Experimental() // untriaged
  AudioParam get pan => _blink.BlinkStereoPannerNode.instance.pan_Getter_(this);
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
  factory WaveShaperNode._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  WaveShaperNode.internal_() : super.internal_();

  @DomName('WaveShaperNode.curve')
  @DocsEditable()
  Float32List get curve =>
      _blink.BlinkWaveShaperNode.instance.curve_Getter_(this);

  @DomName('WaveShaperNode.curve')
  @DocsEditable()
  set curve(Float32List value) =>
      _blink.BlinkWaveShaperNode.instance.curve_Setter_(this, value);

  @DomName('WaveShaperNode.oversample')
  @DocsEditable()
  String get oversample =>
      _blink.BlinkWaveShaperNode.instance.oversample_Getter_(this);

  @DomName('WaveShaperNode.oversample')
  @DocsEditable()
  set oversample(String value) =>
      _blink.BlinkWaveShaperNode.instance.oversample_Setter_(this, value);
}
