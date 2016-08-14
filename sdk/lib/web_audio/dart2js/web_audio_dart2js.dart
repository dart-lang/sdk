/**
 * High-fidelity audio programming in the browser.
 */
library dart.dom.web_audio;

import 'dart:async';
import 'dart:collection';
import 'dart:_internal';
import 'dart:html';
import 'dart:html_common';
import 'dart:_native_typed_data';
import 'dart:typed_data';
import 'dart:_js_helper' show Creates, JSName, Native, Returns, convertDartClosureToJS;
import 'dart:_foreign_helper' show JS;
import 'dart:_interceptors' show Interceptor;
// DO NOT EDIT - unless you are editing documentation as per:
// https://code.google.com/p/dart/wiki/ContributingHTMLDocumentation
// Auto-generated dart:audio library.




// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('AnalyserNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AnalyserNode
@Experimental()
@Native("AnalyserNode,RealtimeAnalyserNode")
class AnalyserNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory AnalyserNode._() { throw new UnsupportedError("Not supported"); }

  @DomName('AnalyserNode.fftSize')
  @DocsEditable()
  int fftSize;

  @DomName('AnalyserNode.frequencyBinCount')
  @DocsEditable()
  final int frequencyBinCount;

  @DomName('AnalyserNode.maxDecibels')
  @DocsEditable()
  num maxDecibels;

  @DomName('AnalyserNode.minDecibels')
  @DocsEditable()
  num minDecibels;

  @DomName('AnalyserNode.smoothingTimeConstant')
  @DocsEditable()
  num smoothingTimeConstant;

  @DomName('AnalyserNode.getByteFrequencyData')
  @DocsEditable()
  void getByteFrequencyData(Uint8List array) native;

  @DomName('AnalyserNode.getByteTimeDomainData')
  @DocsEditable()
  void getByteTimeDomainData(Uint8List array) native;

  @DomName('AnalyserNode.getFloatFrequencyData')
  @DocsEditable()
  void getFloatFrequencyData(Float32List array) native;

  @DomName('AnalyserNode.getFloatTimeDomainData')
  @DocsEditable()
  @Experimental() // untriaged
  void getFloatTimeDomainData(Float32List array) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('AudioBuffer')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioBuffer-section
@Experimental()
@Native("AudioBuffer")
class AudioBuffer extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory AudioBuffer._() { throw new UnsupportedError("Not supported"); }

  @DomName('AudioBuffer.duration')
  @DocsEditable()
  final double duration;

  @DomName('AudioBuffer.length')
  @DocsEditable()
  final int length;

  @DomName('AudioBuffer.numberOfChannels')
  @DocsEditable()
  final int numberOfChannels;

  @DomName('AudioBuffer.sampleRate')
  @DocsEditable()
  final double sampleRate;

  @DomName('AudioBuffer.copyFromChannel')
  @DocsEditable()
  @Experimental() // untriaged
  void copyFromChannel(Float32List destination, int channelNumber, [int startInChannel]) native;

  @DomName('AudioBuffer.copyToChannel')
  @DocsEditable()
  @Experimental() // untriaged
  void copyToChannel(Float32List source, int channelNumber, [int startInChannel]) native;

  @DomName('AudioBuffer.getChannelData')
  @DocsEditable()
  Float32List getChannelData(int channelIndex) native;
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


@DomName('AudioBufferSourceNode')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@Experimental()
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioBufferSourceNode-section
@Native("AudioBufferSourceNode")
class AudioBufferSourceNode extends AudioSourceNode {

  // TODO(efortuna): Remove these methods when Chrome stable also uses start
  // instead of noteOn.
  void start(num when, [num grainOffset, num grainDuration]) {
    if (JS('bool', '!!#.start', this)) {
      if (grainDuration != null) {
        JS('void', '#.start(#, #, #)', this, when, grainOffset, grainDuration);
      } else if (grainOffset != null) {
        JS('void', '#.start(#, #)', this, when, grainOffset);
      } else {
        JS('void', '#.start(#)', this, when);
      }
    } else {
      if (grainDuration != null) {
        JS('void', '#.noteOn(#, #, #)', this, when, grainOffset, grainDuration);
      } else if (grainOffset != null) {
        JS('void', '#.noteOn(#, #)', this, when, grainOffset);
      } else {
        JS('void', '#.noteOn(#)', this, when);
      }
    }
  }

  void stop(num when) {
    if (JS('bool', '!!#.stop', this)) {
      JS('void', '#.stop(#)', this, when);
    } else {
      JS('void', '#.noteOff(#)', this, when);
    }
  }
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

  @DomName('AudioBufferSourceNode.buffer')
  @DocsEditable()
  AudioBuffer buffer;

  @DomName('AudioBufferSourceNode.detune')
  @DocsEditable()
  @Experimental() // untriaged
  final AudioParam detune;

  @DomName('AudioBufferSourceNode.loop')
  @DocsEditable()
  bool loop;

  @DomName('AudioBufferSourceNode.loopEnd')
  @DocsEditable()
  num loopEnd;

  @DomName('AudioBufferSourceNode.loopStart')
  @DocsEditable()
  num loopStart;

  @DomName('AudioBufferSourceNode.playbackRate')
  @DocsEditable()
  final AudioParam playbackRate;

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
@Native("AudioContext,webkitAudioContext")
class AudioContext extends EventTarget {
  // To suppress missing implicit constructor warnings.
  factory AudioContext._() { throw new UnsupportedError("Not supported"); }

  /// Checks if this type is supported on the current platform.
  static bool get supported => JS('bool', '!!(window.AudioContext || window.webkitAudioContext)');

  @DomName('AudioContext.currentTime')
  @DocsEditable()
  final double currentTime;

  @DomName('AudioContext.destination')
  @DocsEditable()
  final AudioDestinationNode destination;

  @DomName('AudioContext.listener')
  @DocsEditable()
  final AudioListener listener;

  @DomName('AudioContext.sampleRate')
  @DocsEditable()
  final double sampleRate;

  @DomName('AudioContext.state')
  @DocsEditable()
  @Experimental() // untriaged
  final String state;

  @DomName('AudioContext.close')
  @DocsEditable()
  @Experimental() // untriaged
  Future close() native;

  @DomName('AudioContext.createAnalyser')
  @DocsEditable()
  AnalyserNode createAnalyser() native;

  @DomName('AudioContext.createBiquadFilter')
  @DocsEditable()
  BiquadFilterNode createBiquadFilter() native;

  @DomName('AudioContext.createBuffer')
  @DocsEditable()
  AudioBuffer createBuffer(int numberOfChannels, int numberOfFrames, num sampleRate) native;

  @DomName('AudioContext.createBufferSource')
  @DocsEditable()
  AudioBufferSourceNode createBufferSource() native;

  @DomName('AudioContext.createChannelMerger')
  @DocsEditable()
  ChannelMergerNode createChannelMerger([int numberOfInputs]) native;

  @DomName('AudioContext.createChannelSplitter')
  @DocsEditable()
  ChannelSplitterNode createChannelSplitter([int numberOfOutputs]) native;

  @DomName('AudioContext.createConvolver')
  @DocsEditable()
  ConvolverNode createConvolver() native;

  @DomName('AudioContext.createDelay')
  @DocsEditable()
  DelayNode createDelay([num maxDelayTime]) native;

  @DomName('AudioContext.createDynamicsCompressor')
  @DocsEditable()
  DynamicsCompressorNode createDynamicsCompressor() native;

  @DomName('AudioContext.createMediaElementSource')
  @DocsEditable()
  MediaElementAudioSourceNode createMediaElementSource(MediaElement mediaElement) native;

  @DomName('AudioContext.createMediaStreamDestination')
  @DocsEditable()
  MediaStreamAudioDestinationNode createMediaStreamDestination() native;

  @DomName('AudioContext.createMediaStreamSource')
  @DocsEditable()
  MediaStreamAudioSourceNode createMediaStreamSource(MediaStream mediaStream) native;

  @DomName('AudioContext.createOscillator')
  @DocsEditable()
  OscillatorNode createOscillator() native;

  @DomName('AudioContext.createPanner')
  @DocsEditable()
  PannerNode createPanner() native;

  @DomName('AudioContext.createPeriodicWave')
  @DocsEditable()
  @Experimental() // untriaged
  PeriodicWave createPeriodicWave(Float32List real, Float32List imag) native;

  @DomName('AudioContext.createStereoPanner')
  @DocsEditable()
  @Experimental() // untriaged
  StereoPannerNode createStereoPanner() native;

  @DomName('AudioContext.createWaveShaper')
  @DocsEditable()
  WaveShaperNode createWaveShaper() native;

  @JSName('decodeAudioData')
  @DomName('AudioContext.decodeAudioData')
  @DocsEditable()
  void _decodeAudioData(ByteBuffer audioData, AudioBufferCallback successCallback, [AudioBufferCallback errorCallback]) native;

  @DomName('AudioContext.resume')
  @DocsEditable()
  @Experimental() // untriaged
  Future resume() native;

  @DomName('AudioContext.suspend')
  @DocsEditable()
  @Experimental() // untriaged
  Future suspend() native;

  factory AudioContext() => JS('AudioContext',
      'new (window.AudioContext || window.webkitAudioContext)()');

  GainNode createGain() {
    if (JS('bool', '#.createGain !== undefined', this)) {
      return JS('GainNode', '#.createGain()', this);
    } else {
      return JS('GainNode', '#.createGainNode()', this);
    }
  }

  ScriptProcessorNode createScriptProcessor(int bufferSize,
      [int numberOfInputChannels, int numberOfOutputChannels]) {
    var function = JS('=Object', '#.createScriptProcessor || '
        '#.createJavaScriptNode', this, this);
    if (numberOfOutputChannels != null) {
      return JS('ScriptProcessorNode', '#.call(#, #, #, #)', function, this,
          bufferSize, numberOfInputChannels, numberOfOutputChannels);
    } else if (numberOfInputChannels != null) {
      return JS('ScriptProcessorNode', '#.call(#, #, #)', function, this,
          bufferSize, numberOfInputChannels);
    } else {
      return JS('ScriptProcessorNode', '#.call(#, #)', function, this,
          bufferSize);
    }
  }
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


@DocsEditable()
@DomName('AudioDestinationNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioDestinationNode-section
@Experimental()
@Native("AudioDestinationNode")
class AudioDestinationNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory AudioDestinationNode._() { throw new UnsupportedError("Not supported"); }

  @DomName('AudioDestinationNode.maxChannelCount')
  @DocsEditable()
  final int maxChannelCount;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('AudioListener')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioListener-section
@Experimental()
@Native("AudioListener")
class AudioListener extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory AudioListener._() { throw new UnsupportedError("Not supported"); }

  @DomName('AudioListener.dopplerFactor')
  @DocsEditable()
  num dopplerFactor;

  @DomName('AudioListener.speedOfSound')
  @DocsEditable()
  num speedOfSound;

  @DomName('AudioListener.setOrientation')
  @DocsEditable()
  void setOrientation(num x, num y, num z, num xUp, num yUp, num zUp) native;

  @DomName('AudioListener.setPosition')
  @DocsEditable()
  void setPosition(num x, num y, num z) native;

  @DomName('AudioListener.setVelocity')
  @DocsEditable()
  void setVelocity(num x, num y, num z) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('AudioNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioNode-section
@Experimental()
@Native("AudioNode")
class AudioNode extends EventTarget {
  // To suppress missing implicit constructor warnings.
  factory AudioNode._() { throw new UnsupportedError("Not supported"); }

  @DomName('AudioNode.channelCount')
  @DocsEditable()
  int channelCount;

  @DomName('AudioNode.channelCountMode')
  @DocsEditable()
  String channelCountMode;

  @DomName('AudioNode.channelInterpretation')
  @DocsEditable()
  String channelInterpretation;

  @DomName('AudioNode.context')
  @DocsEditable()
  final AudioContext context;

  @DomName('AudioNode.numberOfInputs')
  @DocsEditable()
  final int numberOfInputs;

  @DomName('AudioNode.numberOfOutputs')
  @DocsEditable()
  final int numberOfOutputs;

  @JSName('connect')
  @DomName('AudioNode.connect')
  @DocsEditable()
  void _connect(destination, [int output, int input]) native;

  @DomName('AudioNode.disconnect')
  @DocsEditable()
  void disconnect([destination_OR_output, int output, int input]) native;

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


@DocsEditable()
@DomName('AudioParam')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioParam
@Experimental()
@Native("AudioParam")
class AudioParam extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory AudioParam._() { throw new UnsupportedError("Not supported"); }

  @DomName('AudioParam.defaultValue')
  @DocsEditable()
  final double defaultValue;

  @DomName('AudioParam.value')
  @DocsEditable()
  num value;

  @DomName('AudioParam.cancelScheduledValues')
  @DocsEditable()
  void cancelScheduledValues(num startTime) native;

  @DomName('AudioParam.exponentialRampToValueAtTime')
  @DocsEditable()
  void exponentialRampToValueAtTime(num value, num time) native;

  @DomName('AudioParam.linearRampToValueAtTime')
  @DocsEditable()
  void linearRampToValueAtTime(num value, num time) native;

  @DomName('AudioParam.setTargetAtTime')
  @DocsEditable()
  void setTargetAtTime(num target, num time, num timeConstant) native;

  @DomName('AudioParam.setValueAtTime')
  @DocsEditable()
  void setValueAtTime(num value, num time) native;

  @DomName('AudioParam.setValueCurveAtTime')
  @DocsEditable()
  void setValueCurveAtTime(Float32List values, num time, num duration) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('AudioProcessingEvent')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#AudioProcessingEvent-section
@Experimental()
@Native("AudioProcessingEvent")
class AudioProcessingEvent extends Event {
  // To suppress missing implicit constructor warnings.
  factory AudioProcessingEvent._() { throw new UnsupportedError("Not supported"); }

  @DomName('AudioProcessingEvent.inputBuffer')
  @DocsEditable()
  final AudioBuffer inputBuffer;

  @DomName('AudioProcessingEvent.outputBuffer')
  @DocsEditable()
  final AudioBuffer outputBuffer;

  @DomName('AudioProcessingEvent.playbackTime')
  @DocsEditable()
  @Experimental() // untriaged
  final double playbackTime;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('AudioSourceNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html
@Experimental()
@Native("AudioSourceNode")
class AudioSourceNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory AudioSourceNode._() { throw new UnsupportedError("Not supported"); }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('BiquadFilterNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#BiquadFilterNode-section
@Experimental()
@Native("BiquadFilterNode")
class BiquadFilterNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory BiquadFilterNode._() { throw new UnsupportedError("Not supported"); }

  @DomName('BiquadFilterNode.Q')
  @DocsEditable()
  final AudioParam Q;

  @DomName('BiquadFilterNode.detune')
  @DocsEditable()
  final AudioParam detune;

  @DomName('BiquadFilterNode.frequency')
  @DocsEditable()
  final AudioParam frequency;

  @DomName('BiquadFilterNode.gain')
  @DocsEditable()
  final AudioParam gain;

  @DomName('BiquadFilterNode.type')
  @DocsEditable()
  String type;

  @DomName('BiquadFilterNode.getFrequencyResponse')
  @DocsEditable()
  void getFrequencyResponse(Float32List frequencyHz, Float32List magResponse, Float32List phaseResponse) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('ChannelMergerNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#ChannelMergerNode-section
@Experimental()
@Native("ChannelMergerNode,AudioChannelMerger")
class ChannelMergerNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory ChannelMergerNode._() { throw new UnsupportedError("Not supported"); }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('ChannelSplitterNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#ChannelSplitterNode-section
@Experimental()
@Native("ChannelSplitterNode,AudioChannelSplitter")
class ChannelSplitterNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory ChannelSplitterNode._() { throw new UnsupportedError("Not supported"); }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('ConvolverNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#ConvolverNode
@Experimental()
@Native("ConvolverNode")
class ConvolverNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory ConvolverNode._() { throw new UnsupportedError("Not supported"); }

  @DomName('ConvolverNode.buffer')
  @DocsEditable()
  AudioBuffer buffer;

  @DomName('ConvolverNode.normalize')
  @DocsEditable()
  bool normalize;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('DelayNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#DelayNode
@Experimental()
@Native("DelayNode")
class DelayNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory DelayNode._() { throw new UnsupportedError("Not supported"); }

  @DomName('DelayNode.delayTime')
  @DocsEditable()
  final AudioParam delayTime;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('DynamicsCompressorNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#DynamicsCompressorNode
@Experimental()
@Native("DynamicsCompressorNode")
class DynamicsCompressorNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory DynamicsCompressorNode._() { throw new UnsupportedError("Not supported"); }

  @DomName('DynamicsCompressorNode.attack')
  @DocsEditable()
  final AudioParam attack;

  @DomName('DynamicsCompressorNode.knee')
  @DocsEditable()
  final AudioParam knee;

  @DomName('DynamicsCompressorNode.ratio')
  @DocsEditable()
  final AudioParam ratio;

  @DomName('DynamicsCompressorNode.reduction')
  @DocsEditable()
  final AudioParam reduction;

  @DomName('DynamicsCompressorNode.release')
  @DocsEditable()
  final AudioParam release;

  @DomName('DynamicsCompressorNode.threshold')
  @DocsEditable()
  final AudioParam threshold;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('GainNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#GainNode
@Experimental()
@Native("GainNode,AudioGainNode")
class GainNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory GainNode._() { throw new UnsupportedError("Not supported"); }

  @DomName('GainNode.gain')
  @DocsEditable()
  final AudioParam gain;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('MediaElementAudioSourceNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#MediaElementAudioSourceNode
@Experimental()
@Native("MediaElementAudioSourceNode")
class MediaElementAudioSourceNode extends AudioSourceNode {
  // To suppress missing implicit constructor warnings.
  factory MediaElementAudioSourceNode._() { throw new UnsupportedError("Not supported"); }

  @DomName('MediaElementAudioSourceNode.mediaElement')
  @DocsEditable()
  @Experimental() // non-standard
  final MediaElement mediaElement;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('MediaStreamAudioDestinationNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#MediaStreamAudioDestinationNode
@Experimental()
@Native("MediaStreamAudioDestinationNode")
class MediaStreamAudioDestinationNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory MediaStreamAudioDestinationNode._() { throw new UnsupportedError("Not supported"); }

  @DomName('MediaStreamAudioDestinationNode.stream')
  @DocsEditable()
  final MediaStream stream;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('MediaStreamAudioSourceNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#MediaStreamAudioSourceNode
@Experimental()
@Native("MediaStreamAudioSourceNode")
class MediaStreamAudioSourceNode extends AudioSourceNode {
  // To suppress missing implicit constructor warnings.
  factory MediaStreamAudioSourceNode._() { throw new UnsupportedError("Not supported"); }

  @DomName('MediaStreamAudioSourceNode.mediaStream')
  @DocsEditable()
  final MediaStream mediaStream;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('OfflineAudioCompletionEvent')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#OfflineAudioCompletionEvent-section
@Experimental()
@Native("OfflineAudioCompletionEvent")
class OfflineAudioCompletionEvent extends Event {
  // To suppress missing implicit constructor warnings.
  factory OfflineAudioCompletionEvent._() { throw new UnsupportedError("Not supported"); }

  @DomName('OfflineAudioCompletionEvent.renderedBuffer')
  @DocsEditable()
  final AudioBuffer renderedBuffer;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('OfflineAudioContext')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#OfflineAudioContext-section
@Experimental()
@Native("OfflineAudioContext")
class OfflineAudioContext extends AudioContext {
  // To suppress missing implicit constructor warnings.
  factory OfflineAudioContext._() { throw new UnsupportedError("Not supported"); }

  @DomName('OfflineAudioContext.OfflineAudioContext')
  @DocsEditable()
  factory OfflineAudioContext(int numberOfChannels, int numberOfFrames, num sampleRate) {
    return OfflineAudioContext._create_1(numberOfChannels, numberOfFrames, sampleRate);
  }
  static OfflineAudioContext _create_1(numberOfChannels, numberOfFrames, sampleRate) => JS('OfflineAudioContext', 'new OfflineAudioContext(#,#,#)', numberOfChannels, numberOfFrames, sampleRate);

  @DomName('OfflineAudioContext.startRendering')
  @DocsEditable()
  @Experimental() // untriaged
  Future startRendering() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('OscillatorNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#dfn-OscillatorNode
@Experimental()
@Native("OscillatorNode,Oscillator")
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

  @DomName('OscillatorNode.detune')
  @DocsEditable()
  final AudioParam detune;

  @DomName('OscillatorNode.frequency')
  @DocsEditable()
  final AudioParam frequency;

  @DomName('OscillatorNode.type')
  @DocsEditable()
  String type;

  @DomName('OscillatorNode.setPeriodicWave')
  @DocsEditable()
  @Experimental() // untriaged
  void setPeriodicWave(PeriodicWave periodicWave) native;

  @DomName('OscillatorNode.start')
  @DocsEditable()
  void start([num when]) native;

  @DomName('OscillatorNode.stop')
  @DocsEditable()
  void stop([num when]) native;

  /// Stream of `ended` events handled by this [OscillatorNode].
  @DomName('OscillatorNode.onended')
  @DocsEditable()
  @Experimental() // untriaged
  Stream<Event> get onEnded => endedEvent.forTarget(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('PannerNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#PannerNode
@Experimental()
@Native("PannerNode,AudioPannerNode,webkitAudioPannerNode")
class PannerNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory PannerNode._() { throw new UnsupportedError("Not supported"); }

  @DomName('PannerNode.coneInnerAngle')
  @DocsEditable()
  num coneInnerAngle;

  @DomName('PannerNode.coneOuterAngle')
  @DocsEditable()
  num coneOuterAngle;

  @DomName('PannerNode.coneOuterGain')
  @DocsEditable()
  num coneOuterGain;

  @DomName('PannerNode.distanceModel')
  @DocsEditable()
  String distanceModel;

  @DomName('PannerNode.maxDistance')
  @DocsEditable()
  num maxDistance;

  @DomName('PannerNode.panningModel')
  @DocsEditable()
  String panningModel;

  @DomName('PannerNode.refDistance')
  @DocsEditable()
  num refDistance;

  @DomName('PannerNode.rolloffFactor')
  @DocsEditable()
  num rolloffFactor;

  @DomName('PannerNode.setOrientation')
  @DocsEditable()
  void setOrientation(num x, num y, num z) native;

  @DomName('PannerNode.setPosition')
  @DocsEditable()
  void setPosition(num x, num y, num z) native;

  @DomName('PannerNode.setVelocity')
  @DocsEditable()
  void setVelocity(num x, num y, num z) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('PeriodicWave')
@Experimental() // untriaged
@Native("PeriodicWave")
class PeriodicWave extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory PeriodicWave._() { throw new UnsupportedError("Not supported"); }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('ScriptProcessorNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#ScriptProcessorNode
@Experimental()
@Native("ScriptProcessorNode,JavaScriptAudioNode")
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
  final int bufferSize;

  @DomName('ScriptProcessorNode.setEventListener')
  @DocsEditable()
  @Experimental() // untriaged
  void setEventListener(EventListener eventListener) native;

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


@DocsEditable()
@DomName('StereoPannerNode')
@Experimental() // untriaged
@Native("StereoPannerNode")
class StereoPannerNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory StereoPannerNode._() { throw new UnsupportedError("Not supported"); }

  @DomName('StereoPannerNode.pan')
  @DocsEditable()
  @Experimental() // untriaged
  final AudioParam pan;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('WaveShaperNode')
// https://dvcs.w3.org/hg/audio/raw-file/tip/webaudio/specification.html#dfn-WaveShaperNode
@Experimental()
@Native("WaveShaperNode")
class WaveShaperNode extends AudioNode {
  // To suppress missing implicit constructor warnings.
  factory WaveShaperNode._() { throw new UnsupportedError("Not supported"); }

  @DomName('WaveShaperNode.curve')
  @DocsEditable()
  Float32List curve;

  @DomName('WaveShaperNode.oversample')
  @DocsEditable()
  String oversample;
}
