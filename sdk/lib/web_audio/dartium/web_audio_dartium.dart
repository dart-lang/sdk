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
  'AnalyserNode': () => AnalyserNode,
  'AudioBuffer': () => AudioBuffer,
  'AudioBufferSourceNode': () => AudioBufferSourceNode,
  'AudioContext': () => AudioContext,
  'AudioDestinationNode': () => AudioDestinationNode,
  'AudioListener': () => AudioListener,
  'AudioNode': () => AudioNode,
  'AudioParam': () => AudioParam,
  'AudioProcessingEvent': () => AudioProcessingEvent,
  'AudioSourceNode': () => AudioSourceNode,
  'BiquadFilterNode': () => BiquadFilterNode,
  'ChannelMergerNode': () => ChannelMergerNode,
  'ChannelSplitterNode': () => ChannelSplitterNode,
  'ConvolverNode': () => ConvolverNode,
  'DelayNode': () => DelayNode,
  'DynamicsCompressorNode': () => DynamicsCompressorNode,
  'GainNode': () => GainNode,
  'MediaElementAudioSourceNode': () => MediaElementAudioSourceNode,
  'MediaStreamAudioDestinationNode': () => MediaStreamAudioDestinationNode,
  'MediaStreamAudioSourceNode': () => MediaStreamAudioSourceNode,
  'OfflineAudioCompletionEvent': () => OfflineAudioCompletionEvent,
  'OfflineAudioContext': () => OfflineAudioContext,
  'OscillatorNode': () => OscillatorNode,
  'PannerNode': () => PannerNode,
  'PeriodicWave': () => PeriodicWave,
  'ScriptProcessorNode': () => ScriptProcessorNode,
  'StereoPannerNode': () => StereoPannerNode,
  'WaveShaperNode': () => WaveShaperNode,

};

// FIXME: Can we make this private?
@Deprecated("Internal Use Only")
final web_audioBlinkFunctionMap = {
  'AnalyserNode': () => AnalyserNode.internalCreateAnalyserNode,
  'AudioBuffer': () => AudioBuffer.internalCreateAudioBuffer,
  'AudioBufferSourceNode': () => AudioBufferSourceNode.internalCreateAudioBufferSourceNode,
  'AudioContext': () => AudioContext.internalCreateAudioContext,
  'AudioDestinationNode': () => AudioDestinationNode.internalCreateAudioDestinationNode,
  'AudioListener': () => AudioListener.internalCreateAudioListener,
  'AudioNode': () => AudioNode.internalCreateAudioNode,
  'AudioParam': () => AudioParam.internalCreateAudioParam,
  'AudioProcessingEvent': () => AudioProcessingEvent.internalCreateAudioProcessingEvent,
  'AudioSourceNode': () => AudioSourceNode.internalCreateAudioSourceNode,
  'BiquadFilterNode': () => BiquadFilterNode.internalCreateBiquadFilterNode,
  'ChannelMergerNode': () => ChannelMergerNode.internalCreateChannelMergerNode,
  'ChannelSplitterNode': () => ChannelSplitterNode.internalCreateChannelSplitterNode,
  'ConvolverNode': () => ConvolverNode.internalCreateConvolverNode,
  'DelayNode': () => DelayNode.internalCreateDelayNode,
  'DynamicsCompressorNode': () => DynamicsCompressorNode.internalCreateDynamicsCompressorNode,
  'GainNode': () => GainNode.internalCreateGainNode,
  'MediaElementAudioSourceNode': () => MediaElementAudioSourceNode.internalCreateMediaElementAudioSourceNode,
  'MediaStreamAudioDestinationNode': () => MediaStreamAudioDestinationNode.internalCreateMediaStreamAudioDestinationNode,
  'MediaStreamAudioSourceNode': () => MediaStreamAudioSourceNode.internalCreateMediaStreamAudioSourceNode,
  'OfflineAudioCompletionEvent': () => OfflineAudioCompletionEvent.internalCreateOfflineAudioCompletionEvent,
  'OfflineAudioContext': () => OfflineAudioContext.internalCreateOfflineAudioContext,
  'OscillatorNode': () => OscillatorNode.internalCreateOscillatorNode,
  'PannerNode': () => PannerNode.internalCreatePannerNode,
  'PeriodicWave': () => PeriodicWave.internalCreatePeriodicWave,
  'ScriptProcessorNode': () => ScriptProcessorNode.internalCreateScriptProcessorNode,
  'StereoPannerNode': () => StereoPannerNode.internalCreateStereoPannerNode,
  'WaveShaperNode': () => WaveShaperNode.internalCreateWaveShaperNode,

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
  factory AnalyserNode._() { throw new UnsupportedError("Not supported"); }


  @Deprecated("Internal Use Only")
  static AnalyserNode internalCreateAnalyserNode() {
    return new AnalyserNode._internalWrap();
  }

  external factory AnalyserNode._internalWrap();

  @Deprecated("Internal Use Only")
  AnalyserNode.internal_() : super.internal_();


  @DomName('AnalyserNode.fftSize')
  @DocsEditable()
  int get fftSize => _blink.BlinkAnalyserNode.instance.fftSize_Getter_(unwrap_jso(this));
  
  @DomName('AnalyserNode.fftSize')
  @DocsEditable()
  set fftSize(int value) => _blink.BlinkAnalyserNode.instance.fftSize_Setter_(unwrap_jso(this), value);
  
  @DomName('AnalyserNode.frequencyBinCount')
  @DocsEditable()
  int get frequencyBinCount => _blink.BlinkAnalyserNode.instance.frequencyBinCount_Getter_(unwrap_jso(this));
  
  @DomName('AnalyserNode.maxDecibels')
  @DocsEditable()
  num get maxDecibels => _blink.BlinkAnalyserNode.instance.maxDecibels_Getter_(unwrap_jso(this));
  
  @DomName('AnalyserNode.maxDecibels')
  @DocsEditable()
  set maxDecibels(num value) => _blink.BlinkAnalyserNode.instance.maxDecibels_Setter_(unwrap_jso(this), value);
  
  @DomName('AnalyserNode.minDecibels')
  @DocsEditable()
  num get minDecibels => _blink.BlinkAnalyserNode.instance.minDecibels_Getter_(unwrap_jso(this));
  
  @DomName('AnalyserNode.minDecibels')
  @DocsEditable()
  set minDecibels(num value) => _blink.BlinkAnalyserNode.instance.minDecibels_Setter_(unwrap_jso(this), value);
  
  @DomName('AnalyserNode.smoothingTimeConstant')
  @DocsEditable()
  num get smoothingTimeConstant => _blink.BlinkAnalyserNode.instance.smoothingTimeConstant_Getter_(unwrap_jso(this));
  
  @DomName('AnalyserNode.smoothingTimeConstant')
  @DocsEditable()
  set smoothingTimeConstant(num value) => _blink.BlinkAnalyserNode.instance.smoothingTimeConstant_Setter_(unwrap_jso(this), value);
  
  @DomName('AnalyserNode.getByteFrequencyData')
  @DocsEditable()
  void getByteFrequencyData(Uint8List array) => _blink.BlinkAnalyserNode.instance.getByteFrequencyData_Callback_1_(unwrap_jso(this), unwrap_jso(array));
  
  @DomName('AnalyserNode.getByteTimeDomainData')
  @DocsEditable()
  void getByteTimeDomainData(Uint8List array) => _blink.BlinkAnalyserNode.instance.getByteTimeDomainData_Callback_1_(unwrap_jso(this), unwrap_jso(array));
  
  @DomName('AnalyserNode.getFloatFrequencyData')
  @DocsEditable()
  void getFloatFrequencyData(Float32List array) => _blink.BlinkAnalyserNode.instance.getFloatFrequencyData_Callback_1_(unwrap_jso(this), unwrap_jso(array));
  
  @DomName('AnalyserNode.getFloatTimeDomainData')
  @DocsEditable()
  @Experimental() // untriaged
  void getFloatTimeDomainData(Float32List array) => _blink.BlinkAnalyserNode.instance.getFloatTimeDomainData_Callback_1_(unwrap_jso(this), unwrap_jso(array));
  
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
  factory AudioBuffer._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static AudioBuffer internalCreateAudioBuffer() {
    return new AudioBuffer._internalWrap();
  }

  factory AudioBuffer._internalWrap() {
    return new AudioBuffer.internal_();
  }

  @Deprecated("Internal Use Only")
  AudioBuffer.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('AudioBuffer.duration')
  @DocsEditable()
  num get duration => _blink.BlinkAudioBuffer.instance.duration_Getter_(unwrap_jso(this));
  
  @DomName('AudioBuffer.length')
  @DocsEditable()
  int get length => _blink.BlinkAudioBuffer.instance.length_Getter_(unwrap_jso(this));
  
  @DomName('AudioBuffer.numberOfChannels')
  @DocsEditable()
  int get numberOfChannels => _blink.BlinkAudioBuffer.instance.numberOfChannels_Getter_(unwrap_jso(this));
  
  @DomName('AudioBuffer.sampleRate')
  @DocsEditable()
  num get sampleRate => _blink.BlinkAudioBuffer.instance.sampleRate_Getter_(unwrap_jso(this));
  
  void copyFromChannel(Float32List destination, int channelNumber, [int startInChannel]) {
    if (startInChannel != null) {
      _blink.BlinkAudioBuffer.instance.copyFromChannel_Callback_3_(unwrap_jso(this), unwrap_jso(destination), channelNumber, startInChannel);
      return;
    }
    _blink.BlinkAudioBuffer.instance.copyFromChannel_Callback_2_(unwrap_jso(this), unwrap_jso(destination), channelNumber);
    return;
  }

  void copyToChannel(Float32List source, int channelNumber, [int startInChannel]) {
    if (startInChannel != null) {
      _blink.BlinkAudioBuffer.instance.copyToChannel_Callback_3_(unwrap_jso(this), unwrap_jso(source), channelNumber, startInChannel);
      return;
    }
    _blink.BlinkAudioBuffer.instance.copyToChannel_Callback_2_(unwrap_jso(this), unwrap_jso(source), channelNumber);
    return;
  }

  @DomName('AudioBuffer.getChannelData')
  @DocsEditable()
  Float32List getChannelData(int channelIndex) => wrap_jso(_blink.BlinkAudioBuffer.instance.getChannelData_Callback_1_(unwrap_jso(this), channelIndex));
  
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
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@Experimental()
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioBufferSourceNode-section
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


  @Deprecated("Internal Use Only")
  static AudioBufferSourceNode internalCreateAudioBufferSourceNode() {
    return new AudioBufferSourceNode._internalWrap();
  }

  external factory AudioBufferSourceNode._internalWrap();

  @Deprecated("Internal Use Only")
  AudioBufferSourceNode.internal_() : super.internal_();


  @DomName('AudioBufferSourceNode.buffer')
  @DocsEditable()
  AudioBuffer get buffer => wrap_jso(_blink.BlinkAudioBufferSourceNode.instance.buffer_Getter_(unwrap_jso(this)));
  
  @DomName('AudioBufferSourceNode.buffer')
  @DocsEditable()
  set buffer(AudioBuffer value) => _blink.BlinkAudioBufferSourceNode.instance.buffer_Setter_(unwrap_jso(this), unwrap_jso(value));
  
  @DomName('AudioBufferSourceNode.detune')
  @DocsEditable()
  @Experimental() // untriaged
  AudioParam get detune => wrap_jso(_blink.BlinkAudioBufferSourceNode.instance.detune_Getter_(unwrap_jso(this)));
  
  @DomName('AudioBufferSourceNode.loop')
  @DocsEditable()
  bool get loop => _blink.BlinkAudioBufferSourceNode.instance.loop_Getter_(unwrap_jso(this));
  
  @DomName('AudioBufferSourceNode.loop')
  @DocsEditable()
  set loop(bool value) => _blink.BlinkAudioBufferSourceNode.instance.loop_Setter_(unwrap_jso(this), value);
  
  @DomName('AudioBufferSourceNode.loopEnd')
  @DocsEditable()
  num get loopEnd => _blink.BlinkAudioBufferSourceNode.instance.loopEnd_Getter_(unwrap_jso(this));
  
  @DomName('AudioBufferSourceNode.loopEnd')
  @DocsEditable()
  set loopEnd(num value) => _blink.BlinkAudioBufferSourceNode.instance.loopEnd_Setter_(unwrap_jso(this), value);
  
  @DomName('AudioBufferSourceNode.loopStart')
  @DocsEditable()
  num get loopStart => _blink.BlinkAudioBufferSourceNode.instance.loopStart_Getter_(unwrap_jso(this));
  
  @DomName('AudioBufferSourceNode.loopStart')
  @DocsEditable()
  set loopStart(num value) => _blink.BlinkAudioBufferSourceNode.instance.loopStart_Setter_(unwrap_jso(this), value);
  
  @DomName('AudioBufferSourceNode.playbackRate')
  @DocsEditable()
  AudioParam get playbackRate => wrap_jso(_blink.BlinkAudioBufferSourceNode.instance.playbackRate_Getter_(unwrap_jso(this)));
  
  void start([num when, num grainOffset, num grainDuration]) {
    if (grainDuration != null) {
      _blink.BlinkAudioBufferSourceNode.instance.start_Callback_3_(unwrap_jso(this), when, grainOffset, grainDuration);
      return;
    }
    if (grainOffset != null) {
      _blink.BlinkAudioBufferSourceNode.instance.start_Callback_2_(unwrap_jso(this), when, grainOffset);
      return;
    }
    if (when != null) {
      _blink.BlinkAudioBufferSourceNode.instance.start_Callback_1_(unwrap_jso(this), when);
      return;
    }
    _blink.BlinkAudioBufferSourceNode.instance.start_Callback_0_(unwrap_jso(this));
    return;
  }

  void stop([num when]) {
    if (when != null) {
      _blink.BlinkAudioBufferSourceNode.instance.stop_Callback_1_(unwrap_jso(this), when);
      return;
    }
    _blink.BlinkAudioBufferSourceNode.instance.stop_Callback_0_(unwrap_jso(this));
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
  factory AudioContext._() { throw new UnsupportedError("Not supported"); }

  @DomName('AudioContext.AudioContext')
  @DocsEditable()
  factory AudioContext() {
    return wrap_jso(_blink.BlinkAudioContext.instance.constructorCallback_0_());
  }


  @Deprecated("Internal Use Only")
  static AudioContext internalCreateAudioContext() {
    return new AudioContext._internalWrap();
  }

  external factory AudioContext._internalWrap();

  @Deprecated("Internal Use Only")
  AudioContext.internal_() : super.internal_();


  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('AudioContext.currentTime')
  @DocsEditable()
  num get currentTime => _blink.BlinkAudioContext.instance.currentTime_Getter_(unwrap_jso(this));
  
  @DomName('AudioContext.destination')
  @DocsEditable()
  AudioDestinationNode get destination => wrap_jso(_blink.BlinkAudioContext.instance.destination_Getter_(unwrap_jso(this)));
  
  @DomName('AudioContext.listener')
  @DocsEditable()
  AudioListener get listener => wrap_jso(_blink.BlinkAudioContext.instance.listener_Getter_(unwrap_jso(this)));
  
  @DomName('AudioContext.sampleRate')
  @DocsEditable()
  num get sampleRate => _blink.BlinkAudioContext.instance.sampleRate_Getter_(unwrap_jso(this));
  
  @DomName('AudioContext.state')
  @DocsEditable()
  @Experimental() // untriaged
  String get state => _blink.BlinkAudioContext.instance.state_Getter_(unwrap_jso(this));
  
  @DomName('AudioContext.close')
  @DocsEditable()
  @Experimental() // untriaged
  Future close() => wrap_jso(_blink.BlinkAudioContext.instance.close_Callback_0_(unwrap_jso(this)));
  
  @DomName('AudioContext.createAnalyser')
  @DocsEditable()
  AnalyserNode createAnalyser() => wrap_jso(_blink.BlinkAudioContext.instance.createAnalyser_Callback_0_(unwrap_jso(this)));
  
  @DomName('AudioContext.createBiquadFilter')
  @DocsEditable()
  BiquadFilterNode createBiquadFilter() => wrap_jso(_blink.BlinkAudioContext.instance.createBiquadFilter_Callback_0_(unwrap_jso(this)));
  
  @DomName('AudioContext.createBuffer')
  @DocsEditable()
  AudioBuffer createBuffer(int numberOfChannels, int numberOfFrames, num sampleRate) => wrap_jso(_blink.BlinkAudioContext.instance.createBuffer_Callback_3_(unwrap_jso(this), numberOfChannels, numberOfFrames, sampleRate));
  
  @DomName('AudioContext.createBufferSource')
  @DocsEditable()
  AudioBufferSourceNode createBufferSource() => wrap_jso(_blink.BlinkAudioContext.instance.createBufferSource_Callback_0_(unwrap_jso(this)));
  
  ChannelMergerNode createChannelMerger([int numberOfInputs]) {
    if (numberOfInputs != null) {
      return wrap_jso(_blink.BlinkAudioContext.instance.createChannelMerger_Callback_1_(unwrap_jso(this), numberOfInputs));
    }
    return wrap_jso(_blink.BlinkAudioContext.instance.createChannelMerger_Callback_0_(unwrap_jso(this)));
  }

  ChannelSplitterNode createChannelSplitter([int numberOfOutputs]) {
    if (numberOfOutputs != null) {
      return wrap_jso(_blink.BlinkAudioContext.instance.createChannelSplitter_Callback_1_(unwrap_jso(this), numberOfOutputs));
    }
    return wrap_jso(_blink.BlinkAudioContext.instance.createChannelSplitter_Callback_0_(unwrap_jso(this)));
  }

  @DomName('AudioContext.createConvolver')
  @DocsEditable()
  ConvolverNode createConvolver() => wrap_jso(_blink.BlinkAudioContext.instance.createConvolver_Callback_0_(unwrap_jso(this)));
  
  DelayNode createDelay([num maxDelayTime]) {
    if (maxDelayTime != null) {
      return wrap_jso(_blink.BlinkAudioContext.instance.createDelay_Callback_1_(unwrap_jso(this), maxDelayTime));
    }
    return wrap_jso(_blink.BlinkAudioContext.instance.createDelay_Callback_0_(unwrap_jso(this)));
  }

  @DomName('AudioContext.createDynamicsCompressor')
  @DocsEditable()
  DynamicsCompressorNode createDynamicsCompressor() => wrap_jso(_blink.BlinkAudioContext.instance.createDynamicsCompressor_Callback_0_(unwrap_jso(this)));
  
  @DomName('AudioContext.createGain')
  @DocsEditable()
  GainNode createGain() => wrap_jso(_blink.BlinkAudioContext.instance.createGain_Callback_0_(unwrap_jso(this)));
  
  @DomName('AudioContext.createMediaElementSource')
  @DocsEditable()
  MediaElementAudioSourceNode createMediaElementSource(MediaElement mediaElement) => wrap_jso(_blink.BlinkAudioContext.instance.createMediaElementSource_Callback_1_(unwrap_jso(this), unwrap_jso(mediaElement)));
  
  @DomName('AudioContext.createMediaStreamDestination')
  @DocsEditable()
  MediaStreamAudioDestinationNode createMediaStreamDestination() => wrap_jso(_blink.BlinkAudioContext.instance.createMediaStreamDestination_Callback_0_(unwrap_jso(this)));
  
  @DomName('AudioContext.createMediaStreamSource')
  @DocsEditable()
  MediaStreamAudioSourceNode createMediaStreamSource(MediaStream mediaStream) => wrap_jso(_blink.BlinkAudioContext.instance.createMediaStreamSource_Callback_1_(unwrap_jso(this), unwrap_jso(mediaStream)));
  
  @DomName('AudioContext.createOscillator')
  @DocsEditable()
  OscillatorNode createOscillator() => wrap_jso(_blink.BlinkAudioContext.instance.createOscillator_Callback_0_(unwrap_jso(this)));
  
  @DomName('AudioContext.createPanner')
  @DocsEditable()
  PannerNode createPanner() => wrap_jso(_blink.BlinkAudioContext.instance.createPanner_Callback_0_(unwrap_jso(this)));
  
  @DomName('AudioContext.createPeriodicWave')
  @DocsEditable()
  @Experimental() // untriaged
  PeriodicWave createPeriodicWave(Float32List real, Float32List imag) => wrap_jso(_blink.BlinkAudioContext.instance.createPeriodicWave_Callback_2_(unwrap_jso(this), unwrap_jso(real), unwrap_jso(imag)));
  
  ScriptProcessorNode createScriptProcessor([int bufferSize, int numberOfInputChannels, int numberOfOutputChannels]) {
    if (numberOfOutputChannels != null) {
      return wrap_jso(_blink.BlinkAudioContext.instance.createScriptProcessor_Callback_3_(unwrap_jso(this), bufferSize, numberOfInputChannels, numberOfOutputChannels));
    }
    if (numberOfInputChannels != null) {
      return wrap_jso(_blink.BlinkAudioContext.instance.createScriptProcessor_Callback_2_(unwrap_jso(this), bufferSize, numberOfInputChannels));
    }
    if (bufferSize != null) {
      return wrap_jso(_blink.BlinkAudioContext.instance.createScriptProcessor_Callback_1_(unwrap_jso(this), bufferSize));
    }
    return wrap_jso(_blink.BlinkAudioContext.instance.createScriptProcessor_Callback_0_(unwrap_jso(this)));
  }

  @DomName('AudioContext.createStereoPanner')
  @DocsEditable()
  @Experimental() // untriaged
  StereoPannerNode createStereoPanner() => wrap_jso(_blink.BlinkAudioContext.instance.createStereoPanner_Callback_0_(unwrap_jso(this)));
  
  @DomName('AudioContext.createWaveShaper')
  @DocsEditable()
  WaveShaperNode createWaveShaper() => wrap_jso(_blink.BlinkAudioContext.instance.createWaveShaper_Callback_0_(unwrap_jso(this)));
  
  void _decodeAudioData(ByteBuffer audioData, AudioBufferCallback successCallback, [AudioBufferCallback errorCallback]) {
    if (errorCallback != null) {
      _blink.BlinkAudioContext.instance.decodeAudioData_Callback_3_(unwrap_jso(this), unwrap_jso(audioData), unwrap_jso((audioBuffer) => successCallback(wrap_jso(audioBuffer))), unwrap_jso((audioBuffer) => errorCallback(wrap_jso(audioBuffer))));
      return;
    }
    _blink.BlinkAudioContext.instance.decodeAudioData_Callback_2_(unwrap_jso(this), unwrap_jso(audioData), unwrap_jso((audioBuffer) => successCallback(wrap_jso(audioBuffer))));
    return;
  }

  @DomName('AudioContext.resume')
  @DocsEditable()
  @Experimental() // untriaged
  Future resume() => wrap_jso(_blink.BlinkAudioContext.instance.resume_Callback_0_(unwrap_jso(this)));
  
  @DomName('AudioContext.suspend')
  @DocsEditable()
  @Experimental() // untriaged
  Future suspend() => wrap_jso(_blink.BlinkAudioContext.instance.suspend_Callback_0_(unwrap_jso(this)));
  
  @DomName('AudioContext.decodeAudioData')
  Future<AudioBuffer> decodeAudioData(ByteBuffer audioData) {
    var completer = new Completer<AudioBuffer>();
    _decodeAudioData(audioData,
        (value) { completer.complete(value); },
        (error) {
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
  factory AudioDestinationNode._() { throw new UnsupportedError("Not supported"); }


  @Deprecated("Internal Use Only")
  static AudioDestinationNode internalCreateAudioDestinationNode() {
    return new AudioDestinationNode._internalWrap();
  }

  external factory AudioDestinationNode._internalWrap();

  @Deprecated("Internal Use Only")
  AudioDestinationNode.internal_() : super.internal_();


  @DomName('AudioDestinationNode.maxChannelCount')
  @DocsEditable()
  int get maxChannelCount => _blink.BlinkAudioDestinationNode.instance.maxChannelCount_Getter_(unwrap_jso(this));
  
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
  factory AudioListener._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static AudioListener internalCreateAudioListener() {
    return new AudioListener._internalWrap();
  }

  factory AudioListener._internalWrap() {
    return new AudioListener.internal_();
  }

  @Deprecated("Internal Use Only")
  AudioListener.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('AudioListener.dopplerFactor')
  @DocsEditable()
  num get dopplerFactor => _blink.BlinkAudioListener.instance.dopplerFactor_Getter_(unwrap_jso(this));
  
  @DomName('AudioListener.dopplerFactor')
  @DocsEditable()
  set dopplerFactor(num value) => _blink.BlinkAudioListener.instance.dopplerFactor_Setter_(unwrap_jso(this), value);
  
  @DomName('AudioListener.speedOfSound')
  @DocsEditable()
  num get speedOfSound => _blink.BlinkAudioListener.instance.speedOfSound_Getter_(unwrap_jso(this));
  
  @DomName('AudioListener.speedOfSound')
  @DocsEditable()
  set speedOfSound(num value) => _blink.BlinkAudioListener.instance.speedOfSound_Setter_(unwrap_jso(this), value);
  
  @DomName('AudioListener.setOrientation')
  @DocsEditable()
  void setOrientation(num x, num y, num z, num xUp, num yUp, num zUp) => _blink.BlinkAudioListener.instance.setOrientation_Callback_6_(unwrap_jso(this), x, y, z, xUp, yUp, zUp);
  
  @DomName('AudioListener.setPosition')
  @DocsEditable()
  void setPosition(num x, num y, num z) => _blink.BlinkAudioListener.instance.setPosition_Callback_3_(unwrap_jso(this), x, y, z);
  
  @DomName('AudioListener.setVelocity')
  @DocsEditable()
  void setVelocity(num x, num y, num z) => _blink.BlinkAudioListener.instance.setVelocity_Callback_3_(unwrap_jso(this), x, y, z);
  
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


  @Deprecated("Internal Use Only")
  static AudioNode internalCreateAudioNode() {
    return new AudioNode._internalWrap();
  }

  external factory AudioNode._internalWrap();

  @Deprecated("Internal Use Only")
  AudioNode.internal_() : super.internal_();


  @DomName('AudioNode.channelCount')
  @DocsEditable()
  int get channelCount => _blink.BlinkAudioNode.instance.channelCount_Getter_(unwrap_jso(this));
  
  @DomName('AudioNode.channelCount')
  @DocsEditable()
  set channelCount(int value) => _blink.BlinkAudioNode.instance.channelCount_Setter_(unwrap_jso(this), value);
  
  @DomName('AudioNode.channelCountMode')
  @DocsEditable()
  String get channelCountMode => _blink.BlinkAudioNode.instance.channelCountMode_Getter_(unwrap_jso(this));
  
  @DomName('AudioNode.channelCountMode')
  @DocsEditable()
  set channelCountMode(String value) => _blink.BlinkAudioNode.instance.channelCountMode_Setter_(unwrap_jso(this), value);
  
  @DomName('AudioNode.channelInterpretation')
  @DocsEditable()
  String get channelInterpretation => _blink.BlinkAudioNode.instance.channelInterpretation_Getter_(unwrap_jso(this));
  
  @DomName('AudioNode.channelInterpretation')
  @DocsEditable()
  set channelInterpretation(String value) => _blink.BlinkAudioNode.instance.channelInterpretation_Setter_(unwrap_jso(this), value);
  
  @DomName('AudioNode.context')
  @DocsEditable()
  AudioContext get context => wrap_jso(_blink.BlinkAudioNode.instance.context_Getter_(unwrap_jso(this)));
  
  @DomName('AudioNode.numberOfInputs')
  @DocsEditable()
  int get numberOfInputs => _blink.BlinkAudioNode.instance.numberOfInputs_Getter_(unwrap_jso(this));
  
  @DomName('AudioNode.numberOfOutputs')
  @DocsEditable()
  int get numberOfOutputs => _blink.BlinkAudioNode.instance.numberOfOutputs_Getter_(unwrap_jso(this));
  
  void _connect(destination, [int output, int input]) {
    if ((destination is AudioNode) && output == null && input == null) {
      _blink.BlinkAudioNode.instance.connect_Callback_1_(unwrap_jso(this), unwrap_jso(destination));
      return;
    }
    if ((output is int || output == null) && (destination is AudioNode) && input == null) {
      _blink.BlinkAudioNode.instance.connect_Callback_2_(unwrap_jso(this), unwrap_jso(destination), output);
      return;
    }
    if ((input is int || input == null) && (output is int || output == null) && (destination is AudioNode)) {
      _blink.BlinkAudioNode.instance.connect_Callback_3_(unwrap_jso(this), unwrap_jso(destination), output, input);
      return;
    }
    if ((destination is AudioParam) && output == null && input == null) {
      _blink.BlinkAudioNode.instance.connect_Callback_1_(unwrap_jso(this), unwrap_jso(destination));
      return;
    }
    if ((output is int || output == null) && (destination is AudioParam) && input == null) {
      _blink.BlinkAudioNode.instance.connect_Callback_2_(unwrap_jso(this), unwrap_jso(destination), output);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  void disconnect([destination_OR_output, int output, int input]) {
    if (destination_OR_output == null && output == null && input == null) {
      _blink.BlinkAudioNode.instance.disconnect_Callback_0_(unwrap_jso(this));
      return;
    }
    if ((destination_OR_output is int) && output == null && input == null) {
      _blink.BlinkAudioNode.instance.disconnect_Callback_1_(unwrap_jso(this), unwrap_jso(destination_OR_output));
      return;
    }
    if ((destination_OR_output is AudioNode) && output == null && input == null) {
      _blink.BlinkAudioNode.instance.disconnect_Callback_1_(unwrap_jso(this), unwrap_jso(destination_OR_output));
      return;
    }
    if ((output is int) && (destination_OR_output is AudioNode) && input == null) {
      _blink.BlinkAudioNode.instance.disconnect_Callback_2_(unwrap_jso(this), unwrap_jso(destination_OR_output), output);
      return;
    }
    if ((input is int) && (output is int) && (destination_OR_output is AudioNode)) {
      _blink.BlinkAudioNode.instance.disconnect_Callback_3_(unwrap_jso(this), unwrap_jso(destination_OR_output), output, input);
      return;
    }
    if ((destination_OR_output is AudioParam) && output == null && input == null) {
      _blink.BlinkAudioNode.instance.disconnect_Callback_1_(unwrap_jso(this), unwrap_jso(destination_OR_output));
      return;
    }
    if ((output is int) && (destination_OR_output is AudioParam) && input == null) {
      _blink.BlinkAudioNode.instance.disconnect_Callback_2_(unwrap_jso(this), unwrap_jso(destination_OR_output), output);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

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
class AudioParam extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory AudioParam._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static AudioParam internalCreateAudioParam() {
    return new AudioParam._internalWrap();
  }

  factory AudioParam._internalWrap() {
    return new AudioParam.internal_();
  }

  @Deprecated("Internal Use Only")
  AudioParam.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('AudioParam.defaultValue')
  @DocsEditable()
  num get defaultValue => _blink.BlinkAudioParam.instance.defaultValue_Getter_(unwrap_jso(this));
  
  @DomName('AudioParam.value')
  @DocsEditable()
  num get value => _blink.BlinkAudioParam.instance.value_Getter_(unwrap_jso(this));
  
  @DomName('AudioParam.value')
  @DocsEditable()
  set value(num value) => _blink.BlinkAudioParam.instance.value_Setter_(unwrap_jso(this), value);
  
  @DomName('AudioParam.cancelScheduledValues')
  @DocsEditable()
  void cancelScheduledValues(num startTime) => _blink.BlinkAudioParam.instance.cancelScheduledValues_Callback_1_(unwrap_jso(this), startTime);
  
  @DomName('AudioParam.exponentialRampToValueAtTime')
  @DocsEditable()
  void exponentialRampToValueAtTime(num value, num time) => _blink.BlinkAudioParam.instance.exponentialRampToValueAtTime_Callback_2_(unwrap_jso(this), value, time);
  
  @DomName('AudioParam.linearRampToValueAtTime')
  @DocsEditable()
  void linearRampToValueAtTime(num value, num time) => _blink.BlinkAudioParam.instance.linearRampToValueAtTime_Callback_2_(unwrap_jso(this), value, time);
  
  @DomName('AudioParam.setTargetAtTime')
  @DocsEditable()
  void setTargetAtTime(num target, num time, num timeConstant) => _blink.BlinkAudioParam.instance.setTargetAtTime_Callback_3_(unwrap_jso(this), target, time, timeConstant);
  
  @DomName('AudioParam.setValueAtTime')
  @DocsEditable()
  void setValueAtTime(num value, num time) => _blink.BlinkAudioParam.instance.setValueAtTime_Callback_2_(unwrap_jso(this), value, time);
  
  @DomName('AudioParam.setValueCurveAtTime')
  @DocsEditable()
  void setValueCurveAtTime(Float32List values, num time, num duration) => _blink.BlinkAudioParam.instance.setValueCurveAtTime_Callback_3_(unwrap_jso(this), unwrap_jso(values), time, duration);
  
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


  @Deprecated("Internal Use Only")
  static AudioProcessingEvent internalCreateAudioProcessingEvent() {
    return new AudioProcessingEvent._internalWrap();
  }

  external factory AudioProcessingEvent._internalWrap();

  @Deprecated("Internal Use Only")
  AudioProcessingEvent.internal_() : super.internal_();


  @DomName('AudioProcessingEvent.inputBuffer')
  @DocsEditable()
  AudioBuffer get inputBuffer => wrap_jso(_blink.BlinkAudioProcessingEvent.instance.inputBuffer_Getter_(unwrap_jso(this)));
  
  @DomName('AudioProcessingEvent.outputBuffer')
  @DocsEditable()
  AudioBuffer get outputBuffer => wrap_jso(_blink.BlinkAudioProcessingEvent.instance.outputBuffer_Getter_(unwrap_jso(this)));
  
  @DomName('AudioProcessingEvent.playbackTime')
  @DocsEditable()
  @Experimental() // untriaged
  num get playbackTime => _blink.BlinkAudioProcessingEvent.instance.playbackTime_Getter_(unwrap_jso(this));
  
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


  @Deprecated("Internal Use Only")
  static AudioSourceNode internalCreateAudioSourceNode() {
    return new AudioSourceNode._internalWrap();
  }

  external factory AudioSourceNode._internalWrap();

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
  factory BiquadFilterNode._() { throw new UnsupportedError("Not supported"); }


  @Deprecated("Internal Use Only")
  static BiquadFilterNode internalCreateBiquadFilterNode() {
    return new BiquadFilterNode._internalWrap();
  }

  external factory BiquadFilterNode._internalWrap();

  @Deprecated("Internal Use Only")
  BiquadFilterNode.internal_() : super.internal_();


  @DomName('BiquadFilterNode.Q')
  @DocsEditable()
  AudioParam get Q => wrap_jso(_blink.BlinkBiquadFilterNode.instance.Q_Getter_(unwrap_jso(this)));
  
  @DomName('BiquadFilterNode.detune')
  @DocsEditable()
  AudioParam get detune => wrap_jso(_blink.BlinkBiquadFilterNode.instance.detune_Getter_(unwrap_jso(this)));
  
  @DomName('BiquadFilterNode.frequency')
  @DocsEditable()
  AudioParam get frequency => wrap_jso(_blink.BlinkBiquadFilterNode.instance.frequency_Getter_(unwrap_jso(this)));
  
  @DomName('BiquadFilterNode.gain')
  @DocsEditable()
  AudioParam get gain => wrap_jso(_blink.BlinkBiquadFilterNode.instance.gain_Getter_(unwrap_jso(this)));
  
  @DomName('BiquadFilterNode.type')
  @DocsEditable()
  String get type => _blink.BlinkBiquadFilterNode.instance.type_Getter_(unwrap_jso(this));
  
  @DomName('BiquadFilterNode.type')
  @DocsEditable()
  set type(String value) => _blink.BlinkBiquadFilterNode.instance.type_Setter_(unwrap_jso(this), value);
  
  @DomName('BiquadFilterNode.getFrequencyResponse')
  @DocsEditable()
  void getFrequencyResponse(Float32List frequencyHz, Float32List magResponse, Float32List phaseResponse) => _blink.BlinkBiquadFilterNode.instance.getFrequencyResponse_Callback_3_(unwrap_jso(this), unwrap_jso(frequencyHz), unwrap_jso(magResponse), unwrap_jso(phaseResponse));
  
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


  @Deprecated("Internal Use Only")
  static ChannelMergerNode internalCreateChannelMergerNode() {
    return new ChannelMergerNode._internalWrap();
  }

  external factory ChannelMergerNode._internalWrap();

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
  factory ChannelSplitterNode._() { throw new UnsupportedError("Not supported"); }


  @Deprecated("Internal Use Only")
  static ChannelSplitterNode internalCreateChannelSplitterNode() {
    return new ChannelSplitterNode._internalWrap();
  }

  external factory ChannelSplitterNode._internalWrap();

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
  factory ConvolverNode._() { throw new UnsupportedError("Not supported"); }


  @Deprecated("Internal Use Only")
  static ConvolverNode internalCreateConvolverNode() {
    return new ConvolverNode._internalWrap();
  }

  external factory ConvolverNode._internalWrap();

  @Deprecated("Internal Use Only")
  ConvolverNode.internal_() : super.internal_();


  @DomName('ConvolverNode.buffer')
  @DocsEditable()
  AudioBuffer get buffer => wrap_jso(_blink.BlinkConvolverNode.instance.buffer_Getter_(unwrap_jso(this)));
  
  @DomName('ConvolverNode.buffer')
  @DocsEditable()
  set buffer(AudioBuffer value) => _blink.BlinkConvolverNode.instance.buffer_Setter_(unwrap_jso(this), unwrap_jso(value));
  
  @DomName('ConvolverNode.normalize')
  @DocsEditable()
  bool get normalize => _blink.BlinkConvolverNode.instance.normalize_Getter_(unwrap_jso(this));
  
  @DomName('ConvolverNode.normalize')
  @DocsEditable()
  set normalize(bool value) => _blink.BlinkConvolverNode.instance.normalize_Setter_(unwrap_jso(this), value);
  
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


  @Deprecated("Internal Use Only")
  static DelayNode internalCreateDelayNode() {
    return new DelayNode._internalWrap();
  }

  external factory DelayNode._internalWrap();

  @Deprecated("Internal Use Only")
  DelayNode.internal_() : super.internal_();


  @DomName('DelayNode.delayTime')
  @DocsEditable()
  AudioParam get delayTime => wrap_jso(_blink.BlinkDelayNode.instance.delayTime_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static DynamicsCompressorNode internalCreateDynamicsCompressorNode() {
    return new DynamicsCompressorNode._internalWrap();
  }

  external factory DynamicsCompressorNode._internalWrap();

  @Deprecated("Internal Use Only")
  DynamicsCompressorNode.internal_() : super.internal_();


  @DomName('DynamicsCompressorNode.attack')
  @DocsEditable()
  AudioParam get attack => wrap_jso(_blink.BlinkDynamicsCompressorNode.instance.attack_Getter_(unwrap_jso(this)));
  
  @DomName('DynamicsCompressorNode.knee')
  @DocsEditable()
  AudioParam get knee => wrap_jso(_blink.BlinkDynamicsCompressorNode.instance.knee_Getter_(unwrap_jso(this)));
  
  @DomName('DynamicsCompressorNode.ratio')
  @DocsEditable()
  AudioParam get ratio => wrap_jso(_blink.BlinkDynamicsCompressorNode.instance.ratio_Getter_(unwrap_jso(this)));
  
  @DomName('DynamicsCompressorNode.reduction')
  @DocsEditable()
  AudioParam get reduction => wrap_jso(_blink.BlinkDynamicsCompressorNode.instance.reduction_Getter_(unwrap_jso(this)));
  
  @DomName('DynamicsCompressorNode.release')
  @DocsEditable()
  AudioParam get release => wrap_jso(_blink.BlinkDynamicsCompressorNode.instance.release_Getter_(unwrap_jso(this)));
  
  @DomName('DynamicsCompressorNode.threshold')
  @DocsEditable()
  AudioParam get threshold => wrap_jso(_blink.BlinkDynamicsCompressorNode.instance.threshold_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static GainNode internalCreateGainNode() {
    return new GainNode._internalWrap();
  }

  external factory GainNode._internalWrap();

  @Deprecated("Internal Use Only")
  GainNode.internal_() : super.internal_();


  @DomName('GainNode.gain')
  @DocsEditable()
  AudioParam get gain => wrap_jso(_blink.BlinkGainNode.instance.gain_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static MediaElementAudioSourceNode internalCreateMediaElementAudioSourceNode() {
    return new MediaElementAudioSourceNode._internalWrap();
  }

  external factory MediaElementAudioSourceNode._internalWrap();

  @Deprecated("Internal Use Only")
  MediaElementAudioSourceNode.internal_() : super.internal_();


  @DomName('MediaElementAudioSourceNode.mediaElement')
  @DocsEditable()
  @Experimental() // non-standard
  MediaElement get mediaElement => wrap_jso(_blink.BlinkMediaElementAudioSourceNode.instance.mediaElement_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static MediaStreamAudioDestinationNode internalCreateMediaStreamAudioDestinationNode() {
    return new MediaStreamAudioDestinationNode._internalWrap();
  }

  external factory MediaStreamAudioDestinationNode._internalWrap();

  @Deprecated("Internal Use Only")
  MediaStreamAudioDestinationNode.internal_() : super.internal_();


  @DomName('MediaStreamAudioDestinationNode.stream')
  @DocsEditable()
  MediaStream get stream => wrap_jso(_blink.BlinkMediaStreamAudioDestinationNode.instance.stream_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static MediaStreamAudioSourceNode internalCreateMediaStreamAudioSourceNode() {
    return new MediaStreamAudioSourceNode._internalWrap();
  }

  external factory MediaStreamAudioSourceNode._internalWrap();

  @Deprecated("Internal Use Only")
  MediaStreamAudioSourceNode.internal_() : super.internal_();


  @DomName('MediaStreamAudioSourceNode.mediaStream')
  @DocsEditable()
  MediaStream get mediaStream => wrap_jso(_blink.BlinkMediaStreamAudioSourceNode.instance.mediaStream_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static OfflineAudioCompletionEvent internalCreateOfflineAudioCompletionEvent() {
    return new OfflineAudioCompletionEvent._internalWrap();
  }

  external factory OfflineAudioCompletionEvent._internalWrap();

  @Deprecated("Internal Use Only")
  OfflineAudioCompletionEvent.internal_() : super.internal_();


  @DomName('OfflineAudioCompletionEvent.renderedBuffer')
  @DocsEditable()
  AudioBuffer get renderedBuffer => wrap_jso(_blink.BlinkOfflineAudioCompletionEvent.instance.renderedBuffer_Getter_(unwrap_jso(this)));
  
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
    return wrap_jso(_blink.BlinkOfflineAudioContext.instance.constructorCallback_3_(numberOfChannels, numberOfFrames, sampleRate));
  }


  @Deprecated("Internal Use Only")
  static OfflineAudioContext internalCreateOfflineAudioContext() {
    return new OfflineAudioContext._internalWrap();
  }

  external factory OfflineAudioContext._internalWrap();

  @Deprecated("Internal Use Only")
  OfflineAudioContext.internal_() : super.internal_();


  @DomName('OfflineAudioContext.startRendering')
  @DocsEditable()
  @Experimental() // untriaged
  Future startRendering() => wrap_jso(_blink.BlinkOfflineAudioContext.instance.startRendering_Callback_0_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static OscillatorNode internalCreateOscillatorNode() {
    return new OscillatorNode._internalWrap();
  }

  external factory OscillatorNode._internalWrap();

  @Deprecated("Internal Use Only")
  OscillatorNode.internal_() : super.internal_();


  @DomName('OscillatorNode.detune')
  @DocsEditable()
  AudioParam get detune => wrap_jso(_blink.BlinkOscillatorNode.instance.detune_Getter_(unwrap_jso(this)));
  
  @DomName('OscillatorNode.frequency')
  @DocsEditable()
  AudioParam get frequency => wrap_jso(_blink.BlinkOscillatorNode.instance.frequency_Getter_(unwrap_jso(this)));
  
  @DomName('OscillatorNode.type')
  @DocsEditable()
  String get type => _blink.BlinkOscillatorNode.instance.type_Getter_(unwrap_jso(this));
  
  @DomName('OscillatorNode.type')
  @DocsEditable()
  set type(String value) => _blink.BlinkOscillatorNode.instance.type_Setter_(unwrap_jso(this), value);
  
  @DomName('OscillatorNode.setPeriodicWave')
  @DocsEditable()
  @Experimental() // untriaged
  void setPeriodicWave(PeriodicWave periodicWave) => _blink.BlinkOscillatorNode.instance.setPeriodicWave_Callback_1_(unwrap_jso(this), unwrap_jso(periodicWave));
  
  void start([num when]) {
    if (when != null) {
      _blink.BlinkOscillatorNode.instance.start_Callback_1_(unwrap_jso(this), when);
      return;
    }
    _blink.BlinkOscillatorNode.instance.start_Callback_0_(unwrap_jso(this));
    return;
  }

  void stop([num when]) {
    if (when != null) {
      _blink.BlinkOscillatorNode.instance.stop_Callback_1_(unwrap_jso(this), when);
      return;
    }
    _blink.BlinkOscillatorNode.instance.stop_Callback_0_(unwrap_jso(this));
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
  factory PannerNode._() { throw new UnsupportedError("Not supported"); }


  @Deprecated("Internal Use Only")
  static PannerNode internalCreatePannerNode() {
    return new PannerNode._internalWrap();
  }

  external factory PannerNode._internalWrap();

  @Deprecated("Internal Use Only")
  PannerNode.internal_() : super.internal_();


  @DomName('PannerNode.coneInnerAngle')
  @DocsEditable()
  num get coneInnerAngle => _blink.BlinkPannerNode.instance.coneInnerAngle_Getter_(unwrap_jso(this));
  
  @DomName('PannerNode.coneInnerAngle')
  @DocsEditable()
  set coneInnerAngle(num value) => _blink.BlinkPannerNode.instance.coneInnerAngle_Setter_(unwrap_jso(this), value);
  
  @DomName('PannerNode.coneOuterAngle')
  @DocsEditable()
  num get coneOuterAngle => _blink.BlinkPannerNode.instance.coneOuterAngle_Getter_(unwrap_jso(this));
  
  @DomName('PannerNode.coneOuterAngle')
  @DocsEditable()
  set coneOuterAngle(num value) => _blink.BlinkPannerNode.instance.coneOuterAngle_Setter_(unwrap_jso(this), value);
  
  @DomName('PannerNode.coneOuterGain')
  @DocsEditable()
  num get coneOuterGain => _blink.BlinkPannerNode.instance.coneOuterGain_Getter_(unwrap_jso(this));
  
  @DomName('PannerNode.coneOuterGain')
  @DocsEditable()
  set coneOuterGain(num value) => _blink.BlinkPannerNode.instance.coneOuterGain_Setter_(unwrap_jso(this), value);
  
  @DomName('PannerNode.distanceModel')
  @DocsEditable()
  String get distanceModel => _blink.BlinkPannerNode.instance.distanceModel_Getter_(unwrap_jso(this));
  
  @DomName('PannerNode.distanceModel')
  @DocsEditable()
  set distanceModel(String value) => _blink.BlinkPannerNode.instance.distanceModel_Setter_(unwrap_jso(this), value);
  
  @DomName('PannerNode.maxDistance')
  @DocsEditable()
  num get maxDistance => _blink.BlinkPannerNode.instance.maxDistance_Getter_(unwrap_jso(this));
  
  @DomName('PannerNode.maxDistance')
  @DocsEditable()
  set maxDistance(num value) => _blink.BlinkPannerNode.instance.maxDistance_Setter_(unwrap_jso(this), value);
  
  @DomName('PannerNode.panningModel')
  @DocsEditable()
  String get panningModel => _blink.BlinkPannerNode.instance.panningModel_Getter_(unwrap_jso(this));
  
  @DomName('PannerNode.panningModel')
  @DocsEditable()
  set panningModel(String value) => _blink.BlinkPannerNode.instance.panningModel_Setter_(unwrap_jso(this), value);
  
  @DomName('PannerNode.refDistance')
  @DocsEditable()
  num get refDistance => _blink.BlinkPannerNode.instance.refDistance_Getter_(unwrap_jso(this));
  
  @DomName('PannerNode.refDistance')
  @DocsEditable()
  set refDistance(num value) => _blink.BlinkPannerNode.instance.refDistance_Setter_(unwrap_jso(this), value);
  
  @DomName('PannerNode.rolloffFactor')
  @DocsEditable()
  num get rolloffFactor => _blink.BlinkPannerNode.instance.rolloffFactor_Getter_(unwrap_jso(this));
  
  @DomName('PannerNode.rolloffFactor')
  @DocsEditable()
  set rolloffFactor(num value) => _blink.BlinkPannerNode.instance.rolloffFactor_Setter_(unwrap_jso(this), value);
  
  @DomName('PannerNode.setOrientation')
  @DocsEditable()
  void setOrientation(num x, num y, num z) => _blink.BlinkPannerNode.instance.setOrientation_Callback_3_(unwrap_jso(this), x, y, z);
  
  @DomName('PannerNode.setPosition')
  @DocsEditable()
  void setPosition(num x, num y, num z) => _blink.BlinkPannerNode.instance.setPosition_Callback_3_(unwrap_jso(this), x, y, z);
  
  @DomName('PannerNode.setVelocity')
  @DocsEditable()
  void setVelocity(num x, num y, num z) => _blink.BlinkPannerNode.instance.setVelocity_Callback_3_(unwrap_jso(this), x, y, z);
  
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
  factory PeriodicWave._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static PeriodicWave internalCreatePeriodicWave() {
    return new PeriodicWave._internalWrap();
  }

  factory PeriodicWave._internalWrap() {
    return new PeriodicWave.internal_();
  }

  @Deprecated("Internal Use Only")
  PeriodicWave.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

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


  @Deprecated("Internal Use Only")
  static ScriptProcessorNode internalCreateScriptProcessorNode() {
    return new ScriptProcessorNode._internalWrap();
  }

  external factory ScriptProcessorNode._internalWrap();

  @Deprecated("Internal Use Only")
  ScriptProcessorNode.internal_() : super.internal_();


  @DomName('ScriptProcessorNode.bufferSize')
  @DocsEditable()
  int get bufferSize => _blink.BlinkScriptProcessorNode.instance.bufferSize_Getter_(unwrap_jso(this));
  
  @DomName('ScriptProcessorNode.setEventListener')
  @DocsEditable()
  @Experimental() // untriaged
  void setEventListener(EventListener eventListener) => _blink.BlinkScriptProcessorNode.instance.setEventListener_Callback_1_(unwrap_jso(this), unwrap_jso((event) => eventListener(wrap_jso(event))));
  
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
@DomName('StereoPannerNode')
@Experimental() // untriaged
class StereoPannerNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory StereoPannerNode._() { throw new UnsupportedError("Not supported"); }


  @Deprecated("Internal Use Only")
  static StereoPannerNode internalCreateStereoPannerNode() {
    return new StereoPannerNode._internalWrap();
  }

  external factory StereoPannerNode._internalWrap();

  @Deprecated("Internal Use Only")
  StereoPannerNode.internal_() : super.internal_();


  @DomName('StereoPannerNode.pan')
  @DocsEditable()
  @Experimental() // untriaged
  AudioParam get pan => wrap_jso(_blink.BlinkStereoPannerNode.instance.pan_Getter_(unwrap_jso(this)));
  
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


  @Deprecated("Internal Use Only")
  static WaveShaperNode internalCreateWaveShaperNode() {
    return new WaveShaperNode._internalWrap();
  }

  external factory WaveShaperNode._internalWrap();

  @Deprecated("Internal Use Only")
  WaveShaperNode.internal_() : super.internal_();


  @DomName('WaveShaperNode.curve')
  @DocsEditable()
  Float32List get curve => wrap_jso(_blink.BlinkWaveShaperNode.instance.curve_Getter_(unwrap_jso(this)));
  
  @DomName('WaveShaperNode.curve')
  @DocsEditable()
  set curve(Float32List value) => _blink.BlinkWaveShaperNode.instance.curve_Setter_(unwrap_jso(this), unwrap_jso(value));
  
  @DomName('WaveShaperNode.oversample')
  @DocsEditable()
  String get oversample => _blink.BlinkWaveShaperNode.instance.oversample_Getter_(unwrap_jso(this));
  
  @DomName('WaveShaperNode.oversample')
  @DocsEditable()
  set oversample(String value) => _blink.BlinkWaveShaperNode.instance.oversample_Setter_(unwrap_jso(this), value);
  
}
