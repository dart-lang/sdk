library html;

import 'dart:isolate';
import 'dart:json';
import 'dart:svg' as svg;
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// DO NOT EDIT
// Auto-generated dart:html library.







LocalWindow get window => JS('LocalWindow', 'window');

Document get document => JS('Document', 'document');

Element query(String selector) => document.query(selector);
List<Element> queryAll(String selector) => document.queryAll(selector);

// Workaround for tags like <cite> that lack their own Element subclass --
// Dart issue 1990.
class HTMLElement extends Element native "*HTMLElement" {
}

// Support for Send/ReceivePortSync.
int _getNewIsolateId() {
  if (JS('bool', r'!window.$dart$isolate$counter')) {
    JS('void', r'window.$dart$isolate$counter = 1');
  }
  return JS('int', r'window.$dart$isolate$counter++');
}

// Fast path to invoke JS send port.
_callPortSync(int id, message) {
  return JS('var', r'ReceivePortSync.dispatchCall(#, #)', id, message);
}

// TODO(vsm): Plumb this properly.
spawnDomFunction(f) => spawnFunction(f);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName AbstractWorker
class AbstractWorker extends EventTarget native "*AbstractWorker" {

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  AbstractWorkerEvents get on =>
    new AbstractWorkerEvents(this);

  /** @domName AbstractWorker.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "addEventListener";

  /** @domName AbstractWorker.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "dispatchEvent";

  /** @domName AbstractWorker.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "removeEventListener";
}

class AbstractWorkerEvents extends Events {
  AbstractWorkerEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get error => this['error'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName AnalyserNode
class AnalyserNode extends AudioNode native "*AnalyserNode" {

  /** @domName AnalyserNode.fftSize */
  int fftSize;

  /** @domName AnalyserNode.frequencyBinCount */
  final int frequencyBinCount;

  /** @domName AnalyserNode.maxDecibels */
  num maxDecibels;

  /** @domName AnalyserNode.minDecibels */
  num minDecibels;

  /** @domName AnalyserNode.smoothingTimeConstant */
  num smoothingTimeConstant;

  /** @domName AnalyserNode.getByteFrequencyData */
  void getByteFrequencyData(Uint8Array array) native;

  /** @domName AnalyserNode.getByteTimeDomainData */
  void getByteTimeDomainData(Uint8Array array) native;

  /** @domName AnalyserNode.getFloatFrequencyData */
  void getFloatFrequencyData(Float32Array array) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLAnchorElement
class AnchorElement extends Element implements Element native "*HTMLAnchorElement" {

  factory AnchorElement({String href}) {
    if (!?href) {
      return _Elements.createAnchorElement();
    }
    return _Elements.createAnchorElement(href);
  }

  /** @domName HTMLAnchorElement.charset */
  String charset;

  /** @domName HTMLAnchorElement.coords */
  String coords;

  /** @domName HTMLAnchorElement.download */
  String download;

  /** @domName HTMLAnchorElement.hash */
  String hash;

  /** @domName HTMLAnchorElement.host */
  String host;

  /** @domName HTMLAnchorElement.hostname */
  String hostname;

  /** @domName HTMLAnchorElement.href */
  String href;

  /** @domName HTMLAnchorElement.hreflang */
  String hreflang;

  /** @domName HTMLAnchorElement.name */
  String name;

  /** @domName HTMLAnchorElement.origin */
  final String origin;

  /** @domName HTMLAnchorElement.pathname */
  String pathname;

  /** @domName HTMLAnchorElement.ping */
  String ping;

  /** @domName HTMLAnchorElement.port */
  String port;

  /** @domName HTMLAnchorElement.protocol */
  String protocol;

  /** @domName HTMLAnchorElement.rel */
  String rel;

  /** @domName HTMLAnchorElement.rev */
  String rev;

  /** @domName HTMLAnchorElement.search */
  String search;

  /** @domName HTMLAnchorElement.shape */
  String shape;

  /** @domName HTMLAnchorElement.target */
  String target;

  /** @domName HTMLAnchorElement.type */
  String type;

  /** @domName HTMLAnchorElement.toString */
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WebKitAnimation
class Animation native "*WebKitAnimation" {

  static const int DIRECTION_ALTERNATE = 1;

  static const int DIRECTION_NORMAL = 0;

  static const int FILL_BACKWARDS = 1;

  static const int FILL_BOTH = 3;

  static const int FILL_FORWARDS = 2;

  static const int FILL_NONE = 0;

  /** @domName WebKitAnimation.delay */
  final num delay;

  /** @domName WebKitAnimation.direction */
  final int direction;

  /** @domName WebKitAnimation.duration */
  final num duration;

  /** @domName WebKitAnimation.elapsedTime */
  num elapsedTime;

  /** @domName WebKitAnimation.ended */
  final bool ended;

  /** @domName WebKitAnimation.fillMode */
  final int fillMode;

  /** @domName WebKitAnimation.iterationCount */
  final int iterationCount;

  /** @domName WebKitAnimation.name */
  final String name;

  /** @domName WebKitAnimation.paused */
  final bool paused;

  /** @domName WebKitAnimation.pause */
  void pause() native;

  /** @domName WebKitAnimation.play */
  void play() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WebKitAnimationEvent
class AnimationEvent extends Event native "*WebKitAnimationEvent" {

  /** @domName WebKitAnimationEvent.animationName */
  final String animationName;

  /** @domName WebKitAnimationEvent.elapsedTime */
  final num elapsedTime;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLAppletElement
class AppletElement extends Element implements Element native "*HTMLAppletElement" {

  /** @domName HTMLAppletElement.align */
  String align;

  /** @domName HTMLAppletElement.alt */
  String alt;

  /** @domName HTMLAppletElement.archive */
  String archive;

  /** @domName HTMLAppletElement.code */
  String code;

  /** @domName HTMLAppletElement.codeBase */
  String codeBase;

  /** @domName HTMLAppletElement.height */
  String height;

  /** @domName HTMLAppletElement.hspace */
  String hspace;

  /** @domName HTMLAppletElement.name */
  String name;

  /** @domName HTMLAppletElement.object */
  String object;

  /** @domName HTMLAppletElement.vspace */
  String vspace;

  /** @domName HTMLAppletElement.width */
  String width;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLAreaElement
class AreaElement extends Element implements Element native "*HTMLAreaElement" {

  factory AreaElement() => _Elements.createAreaElement();

  /** @domName HTMLAreaElement.alt */
  String alt;

  /** @domName HTMLAreaElement.coords */
  String coords;

  /** @domName HTMLAreaElement.hash */
  final String hash;

  /** @domName HTMLAreaElement.host */
  final String host;

  /** @domName HTMLAreaElement.hostname */
  final String hostname;

  /** @domName HTMLAreaElement.href */
  String href;

  /** @domName HTMLAreaElement.noHref */
  bool noHref;

  /** @domName HTMLAreaElement.pathname */
  final String pathname;

  /** @domName HTMLAreaElement.ping */
  String ping;

  /** @domName HTMLAreaElement.port */
  final String port;

  /** @domName HTMLAreaElement.protocol */
  final String protocol;

  /** @domName HTMLAreaElement.search */
  final String search;

  /** @domName HTMLAreaElement.shape */
  String shape;

  /** @domName HTMLAreaElement.target */
  String target;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName ArrayBuffer
class ArrayBuffer native "*ArrayBuffer" {

  factory ArrayBuffer(int length) => _ArrayBufferFactoryProvider.createArrayBuffer(length);

  /** @domName ArrayBuffer.byteLength */
  final int byteLength;

  /** @domName ArrayBuffer.slice */
  ArrayBuffer slice(int begin, [int end]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName ArrayBufferView
class ArrayBufferView native "*ArrayBufferView" {

  /** @domName ArrayBufferView.buffer */
  final ArrayBuffer buffer;

  /** @domName ArrayBufferView.byteLength */
  final int byteLength;

  /** @domName ArrayBufferView.byteOffset */
  final int byteOffset;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Attr
class Attr extends Node native "*Attr" {

  /** @domName Attr.isId */
  final bool isId;

  /** @domName Attr.name */
  final String name;

  /** @domName Attr.ownerElement */
  final Element ownerElement;

  /** @domName Attr.specified */
  final bool specified;

  /** @domName Attr.value */
  String value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName AudioBuffer
class AudioBuffer native "*AudioBuffer" {

  /** @domName AudioBuffer.duration */
  final num duration;

  /** @domName AudioBuffer.gain */
  num gain;

  /** @domName AudioBuffer.length */
  final int length;

  /** @domName AudioBuffer.numberOfChannels */
  final int numberOfChannels;

  /** @domName AudioBuffer.sampleRate */
  final num sampleRate;

  /** @domName AudioBuffer.getChannelData */
  Float32Array getChannelData(int channelIndex) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void AudioBufferCallback(AudioBuffer audioBuffer);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class AudioBufferSourceNode extends AudioSourceNode native "*AudioBufferSourceNode" {

  // TODO(efortuna): Remove these methods when Chrome stable also uses start
  // instead of noteOn.
  void start(num when, [num grainOffset, num grainDuration]) {
    if (JS('bool', '!!#.start', this)) {
      if (?grainDuration) {
        JS('void', '#.start(#, #, #)', this, when, grainOffset, grainDuration);
      } else if (?grainOffset) {
        JS('void', '#.start(#, #)', this, when, grainOffset);
      } else {
        JS('void', '#.start(#)', this, when);
      }
    } else {
      if (?grainDuration) {
        JS('void', '#.noteOn(#, #, #)', this, when, grainOffset, grainDuration);
      } else if (?grainOffset) {
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

  static const int FINISHED_STATE = 3;

  static const int PLAYING_STATE = 2;

  static const int SCHEDULED_STATE = 1;

  static const int UNSCHEDULED_STATE = 0;

  /** @domName AudioBufferSourceNode.buffer */
  AudioBuffer buffer;

  /** @domName AudioBufferSourceNode.gain */
  final AudioGain gain;

  /** @domName AudioBufferSourceNode.loop */
  bool loop;

  /** @domName AudioBufferSourceNode.loopEnd */
  num loopEnd;

  /** @domName AudioBufferSourceNode.loopStart */
  num loopStart;

  /** @domName AudioBufferSourceNode.playbackRate */
  final AudioParam playbackRate;

  /** @domName AudioBufferSourceNode.playbackState */
  final int playbackState;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class AudioContext extends EventTarget native "*AudioContext" {
  factory AudioContext() => _AudioContextFactoryProvider.createAudioContext();

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  AudioContextEvents get on =>
    new AudioContextEvents(this);

  /** @domName AudioContext.activeSourceCount */
  final int activeSourceCount;

  /** @domName AudioContext.currentTime */
  final num currentTime;

  /** @domName AudioContext.destination */
  final AudioDestinationNode destination;

  /** @domName AudioContext.listener */
  final AudioListener listener;

  /** @domName AudioContext.sampleRate */
  final num sampleRate;

  /** @domName AudioContext.createAnalyser */
  AnalyserNode createAnalyser() native;

  /** @domName AudioContext.createBiquadFilter */
  BiquadFilterNode createBiquadFilter() native;

  /** @domName AudioContext.createBuffer */
  AudioBuffer createBuffer(buffer_OR_numberOfChannels, mixToMono_OR_numberOfFrames, [num sampleRate]) native;

  /** @domName AudioContext.createBufferSource */
  AudioBufferSourceNode createBufferSource() native;

  /** @domName AudioContext.createChannelMerger */
  ChannelMergerNode createChannelMerger([int numberOfInputs]) native;

  /** @domName AudioContext.createChannelSplitter */
  ChannelSplitterNode createChannelSplitter([int numberOfOutputs]) native;

  /** @domName AudioContext.createConvolver */
  ConvolverNode createConvolver() native;

  /** @domName AudioContext.createDelay */
  DelayNode createDelay([num maxDelayTime]) native;

  /** @domName AudioContext.createDynamicsCompressor */
  DynamicsCompressorNode createDynamicsCompressor() native;

  /** @domName AudioContext.createMediaElementSource */
  MediaElementAudioSourceNode createMediaElementSource(MediaElement mediaElement) native;

  /** @domName AudioContext.createMediaStreamSource */
  MediaStreamAudioSourceNode createMediaStreamSource(MediaStream mediaStream) native;

  /** @domName AudioContext.createOscillator */
  OscillatorNode createOscillator() native;

  /** @domName AudioContext.createPanner */
  PannerNode createPanner() native;

  /** @domName AudioContext.createWaveShaper */
  WaveShaperNode createWaveShaper() native;

  /** @domName AudioContext.createWaveTable */
  WaveTable createWaveTable(Float32Array real, Float32Array imag) native;

  /** @domName AudioContext.decodeAudioData */
  void decodeAudioData(ArrayBuffer audioData, AudioBufferCallback successCallback, [AudioBufferCallback errorCallback]) native;

  /** @domName AudioContext.startRendering */
  void startRendering() native;

  GainNode createGain() {
    if (JS('bool', '#.createGain !== undefined', this)) {
      return JS('GainNode', '#.createGain()', this);
    } else {
      return JS('GainNode', '#.createGainNode()', this);
    }
  }

  ScriptProcessorNode createScriptProcessor(int bufferSize,
      [int numberOfInputChannels, int numberOfOutputChannels]) {
    var function = JS('dynamic', '#.createScriptProcessor || '
        '#.createJavaScriptNode', this, this);
    if (?numberOfOutputChannels) {
      return JS('ScriptProcessorNode', '#.call(#, #, #, #)', function, this,
          bufferSize, numberOfInputChannels, numberOfOutputChannels);
    } else if (?numberOfInputChannels) {
      return JS('ScriptProcessorNode', '#.call(#, #, #)', function, this,
          bufferSize, numberOfInputChannels);
    } else {
      return JS('ScriptProcessorNode', '#.call(#, #)', function, this,
          bufferSize);
    }
  }
}

class AudioContextEvents extends Events {
  AudioContextEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get complete => this['complete'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName AudioDestinationNode
class AudioDestinationNode extends AudioNode native "*AudioDestinationNode" {

  /** @domName AudioDestinationNode.numberOfChannels */
  final int numberOfChannels;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLAudioElement
class AudioElement extends MediaElement native "*HTMLAudioElement" {

  factory AudioElement([String src]) {
    if (!?src) {
      return _AudioElementFactoryProvider.createAudioElement();
    }
    return _AudioElementFactoryProvider.createAudioElement(src);
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName AudioGain
class AudioGain extends AudioParam native "*AudioGain" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName AudioListener
class AudioListener native "*AudioListener" {

  /** @domName AudioListener.dopplerFactor */
  num dopplerFactor;

  /** @domName AudioListener.speedOfSound */
  num speedOfSound;

  /** @domName AudioListener.setOrientation */
  void setOrientation(num x, num y, num z, num xUp, num yUp, num zUp) native;

  /** @domName AudioListener.setPosition */
  void setPosition(num x, num y, num z) native;

  /** @domName AudioListener.setVelocity */
  void setVelocity(num x, num y, num z) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName AudioNode
class AudioNode native "*AudioNode" {

  /** @domName AudioNode.context */
  final AudioContext context;

  /** @domName AudioNode.numberOfInputs */
  final int numberOfInputs;

  /** @domName AudioNode.numberOfOutputs */
  final int numberOfOutputs;

  /** @domName AudioNode.connect */
  void connect(destination, int output, [int input]) native;

  /** @domName AudioNode.disconnect */
  void disconnect(int output) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName AudioParam
class AudioParam native "*AudioParam" {

  /** @domName AudioParam.defaultValue */
  final num defaultValue;

  /** @domName AudioParam.maxValue */
  final num maxValue;

  /** @domName AudioParam.minValue */
  final num minValue;

  /** @domName AudioParam.name */
  final String name;

  /** @domName AudioParam.units */
  final int units;

  /** @domName AudioParam.value */
  num value;

  /** @domName AudioParam.cancelScheduledValues */
  void cancelScheduledValues(num startTime) native;

  /** @domName AudioParam.exponentialRampToValueAtTime */
  void exponentialRampToValueAtTime(num value, num time) native;

  /** @domName AudioParam.linearRampToValueAtTime */
  void linearRampToValueAtTime(num value, num time) native;

  /** @domName AudioParam.setTargetAtTime */
  void setTargetAtTime(num target, num time, num timeConstant) native;

  /** @domName AudioParam.setValueAtTime */
  void setValueAtTime(num value, num time) native;

  /** @domName AudioParam.setValueCurveAtTime */
  void setValueCurveAtTime(Float32Array values, num time, num duration) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName AudioProcessingEvent
class AudioProcessingEvent extends Event native "*AudioProcessingEvent" {

  /** @domName AudioProcessingEvent.inputBuffer */
  final AudioBuffer inputBuffer;

  /** @domName AudioProcessingEvent.outputBuffer */
  final AudioBuffer outputBuffer;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName AudioSourceNode
class AudioSourceNode extends AudioNode native "*AudioSourceNode" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLBRElement
class BRElement extends Element implements Element native "*HTMLBRElement" {

  factory BRElement() => _Elements.createBRElement();

  /** @domName HTMLBRElement.clear */
  String clear;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName BarInfo
class BarInfo native "*BarInfo" {

  /** @domName BarInfo.visible */
  final bool visible;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLBaseElement
class BaseElement extends Element implements Element native "*HTMLBaseElement" {

  factory BaseElement() => _Elements.createBaseElement();

  /** @domName HTMLBaseElement.href */
  String href;

  /** @domName HTMLBaseElement.target */
  String target;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLBaseFontElement
class BaseFontElement extends Element implements Element native "*HTMLBaseFontElement" {

  /** @domName HTMLBaseFontElement.color */
  String color;

  /** @domName HTMLBaseFontElement.face */
  String face;

  /** @domName HTMLBaseFontElement.size */
  int size;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName BatteryManager
class BatteryManager extends EventTarget native "*BatteryManager" {

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  BatteryManagerEvents get on =>
    new BatteryManagerEvents(this);

  /** @domName BatteryManager.charging */
  final bool charging;

  /** @domName BatteryManager.chargingTime */
  final num chargingTime;

  /** @domName BatteryManager.dischargingTime */
  final num dischargingTime;

  /** @domName BatteryManager.level */
  final num level;

  /** @domName BatteryManager.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "addEventListener";

  /** @domName BatteryManager.dispatchEvent */
  bool $dom_dispatchEvent(Event event) native "dispatchEvent";

  /** @domName BatteryManager.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "removeEventListener";
}

class BatteryManagerEvents extends Events {
  BatteryManagerEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get chargingChange => this['chargingchange'];

  EventListenerList get chargingTimeChange => this['chargingtimechange'];

  EventListenerList get dischargingTimeChange => this['dischargingtimechange'];

  EventListenerList get levelChange => this['levelchange'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName BeforeLoadEvent
class BeforeLoadEvent extends Event native "*BeforeLoadEvent" {

  /** @domName BeforeLoadEvent.url */
  final String url;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName BiquadFilterNode
class BiquadFilterNode extends AudioNode native "*BiquadFilterNode" {

  static const int ALLPASS = 7;

  static const int BANDPASS = 2;

  static const int HIGHPASS = 1;

  static const int HIGHSHELF = 4;

  static const int LOWPASS = 0;

  static const int LOWSHELF = 3;

  static const int NOTCH = 6;

  static const int PEAKING = 5;

  /** @domName BiquadFilterNode.Q */
  final AudioParam Q;

  /** @domName BiquadFilterNode.frequency */
  final AudioParam frequency;

  /** @domName BiquadFilterNode.gain */
  final AudioParam gain;

  /** @domName BiquadFilterNode.type */
  int type;

  /** @domName BiquadFilterNode.getFrequencyResponse */
  void getFrequencyResponse(Float32Array frequencyHz, Float32Array magResponse, Float32Array phaseResponse) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Blob
class Blob native "*Blob" {

  factory Blob(List blobParts, [String type, String endings]) {
    if (!?type) {
      return _BlobFactoryProvider.createBlob(blobParts);
    }
    if (!?endings) {
      return _BlobFactoryProvider.createBlob(blobParts, type);
    }
    return _BlobFactoryProvider.createBlob(blobParts, type, endings);
  }

  /** @domName Blob.size */
  final int size;

  /** @domName Blob.type */
  final String type;

  /** @domName Blob.slice */
  Blob slice([int start, int end, String contentType]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLBodyElement
class BodyElement extends Element implements Element native "*HTMLBodyElement" {

  factory BodyElement() => _Elements.createBodyElement();

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  BodyElementEvents get on =>
    new BodyElementEvents(this);

  /** @domName HTMLBodyElement.aLink */
  String aLink;

  /** @domName HTMLBodyElement.background */
  String background;

  /** @domName HTMLBodyElement.bgColor */
  String bgColor;

  /** @domName HTMLBodyElement.link */
  String link;

  /** @domName HTMLBodyElement.vLink */
  String vLink;
}

class BodyElementEvents extends ElementEvents {
  BodyElementEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get beforeUnload => this['beforeunload'];

  EventListenerList get blur => this['blur'];

  EventListenerList get error => this['error'];

  EventListenerList get focus => this['focus'];

  EventListenerList get hashChange => this['hashchange'];

  EventListenerList get load => this['load'];

  EventListenerList get message => this['message'];

  EventListenerList get offline => this['offline'];

  EventListenerList get online => this['online'];

  EventListenerList get popState => this['popstate'];

  EventListenerList get resize => this['resize'];

  EventListenerList get storage => this['storage'];

  EventListenerList get unload => this['unload'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLButtonElement
class ButtonElement extends Element implements Element native "*HTMLButtonElement" {

  factory ButtonElement() => _Elements.createButtonElement();

  /** @domName HTMLButtonElement.autofocus */
  bool autofocus;

  /** @domName HTMLButtonElement.disabled */
  bool disabled;

  /** @domName HTMLButtonElement.form */
  final FormElement form;

  /** @domName HTMLButtonElement.formAction */
  String formAction;

  /** @domName HTMLButtonElement.formEnctype */
  String formEnctype;

  /** @domName HTMLButtonElement.formMethod */
  String formMethod;

  /** @domName HTMLButtonElement.formNoValidate */
  bool formNoValidate;

  /** @domName HTMLButtonElement.formTarget */
  String formTarget;

  /** @domName HTMLButtonElement.labels */
  final List<Node> labels;

  /** @domName HTMLButtonElement.name */
  String name;

  /** @domName HTMLButtonElement.type */
  String type;

  /** @domName HTMLButtonElement.validationMessage */
  final String validationMessage;

  /** @domName HTMLButtonElement.validity */
  final ValidityState validity;

  /** @domName HTMLButtonElement.value */
  String value;

  /** @domName HTMLButtonElement.willValidate */
  final bool willValidate;

  /** @domName HTMLButtonElement.checkValidity */
  bool checkValidity() native;

  /** @domName HTMLButtonElement.setCustomValidity */
  void setCustomValidity(String error) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName CDATASection
class CDATASection extends Text native "*CDATASection" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName CSSCharsetRule
class CSSCharsetRule extends CSSRule native "*CSSCharsetRule" {

  /** @domName CSSCharsetRule.encoding */
  String encoding;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName CSSFontFaceRule
class CSSFontFaceRule extends CSSRule native "*CSSFontFaceRule" {

  /** @domName CSSFontFaceRule.style */
  final CSSStyleDeclaration style;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName CSSImportRule
class CSSImportRule extends CSSRule native "*CSSImportRule" {

  /** @domName CSSImportRule.href */
  final String href;

  /** @domName CSSImportRule.media */
  final MediaList media;

  /** @domName CSSImportRule.styleSheet */
  final CSSStyleSheet styleSheet;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WebKitCSSKeyframeRule
class CSSKeyframeRule extends CSSRule native "*WebKitCSSKeyframeRule" {

  /** @domName WebKitCSSKeyframeRule.keyText */
  String keyText;

  /** @domName WebKitCSSKeyframeRule.style */
  final CSSStyleDeclaration style;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WebKitCSSKeyframesRule
class CSSKeyframesRule extends CSSRule native "*WebKitCSSKeyframesRule" {

  /** @domName WebKitCSSKeyframesRule.cssRules */
  final List<CSSRule> cssRules;

  /** @domName WebKitCSSKeyframesRule.name */
  String name;

  /** @domName WebKitCSSKeyframesRule.deleteRule */
  void deleteRule(String key) native;

  /** @domName WebKitCSSKeyframesRule.findRule */
  CSSKeyframeRule findRule(String key) native;

  /** @domName WebKitCSSKeyframesRule.insertRule */
  void insertRule(String rule) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WebKitCSSMatrix
class CSSMatrix native "*WebKitCSSMatrix" {

  factory CSSMatrix([String cssValue]) {
    if (!?cssValue) {
      return _CSSMatrixFactoryProvider.createCSSMatrix();
    }
    return _CSSMatrixFactoryProvider.createCSSMatrix(cssValue);
  }

  /** @domName WebKitCSSMatrix.a */
  num a;

  /** @domName WebKitCSSMatrix.b */
  num b;

  /** @domName WebKitCSSMatrix.c */
  num c;

  /** @domName WebKitCSSMatrix.d */
  num d;

  /** @domName WebKitCSSMatrix.e */
  num e;

  /** @domName WebKitCSSMatrix.f */
  num f;

  /** @domName WebKitCSSMatrix.m11 */
  num m11;

  /** @domName WebKitCSSMatrix.m12 */
  num m12;

  /** @domName WebKitCSSMatrix.m13 */
  num m13;

  /** @domName WebKitCSSMatrix.m14 */
  num m14;

  /** @domName WebKitCSSMatrix.m21 */
  num m21;

  /** @domName WebKitCSSMatrix.m22 */
  num m22;

  /** @domName WebKitCSSMatrix.m23 */
  num m23;

  /** @domName WebKitCSSMatrix.m24 */
  num m24;

  /** @domName WebKitCSSMatrix.m31 */
  num m31;

  /** @domName WebKitCSSMatrix.m32 */
  num m32;

  /** @domName WebKitCSSMatrix.m33 */
  num m33;

  /** @domName WebKitCSSMatrix.m34 */
  num m34;

  /** @domName WebKitCSSMatrix.m41 */
  num m41;

  /** @domName WebKitCSSMatrix.m42 */
  num m42;

  /** @domName WebKitCSSMatrix.m43 */
  num m43;

  /** @domName WebKitCSSMatrix.m44 */
  num m44;

  /** @domName WebKitCSSMatrix.inverse */
  CSSMatrix inverse() native;

  /** @domName WebKitCSSMatrix.multiply */
  CSSMatrix multiply(CSSMatrix secondMatrix) native;

  /** @domName WebKitCSSMatrix.rotate */
  CSSMatrix rotate(num rotX, num rotY, num rotZ) native;

  /** @domName WebKitCSSMatrix.rotateAxisAngle */
  CSSMatrix rotateAxisAngle(num x, num y, num z, num angle) native;

  /** @domName WebKitCSSMatrix.scale */
  CSSMatrix scale(num scaleX, num scaleY, num scaleZ) native;

  /** @domName WebKitCSSMatrix.setMatrixValue */
  void setMatrixValue(String string) native;

  /** @domName WebKitCSSMatrix.skewX */
  CSSMatrix skewX(num angle) native;

  /** @domName WebKitCSSMatrix.skewY */
  CSSMatrix skewY(num angle) native;

  /** @domName WebKitCSSMatrix.toString */
  String toString() native;

  /** @domName WebKitCSSMatrix.translate */
  CSSMatrix translate(num x, num y, num z) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName CSSMediaRule
class CSSMediaRule extends CSSRule native "*CSSMediaRule" {

  /** @domName CSSMediaRule.cssRules */
  final List<CSSRule> cssRules;

  /** @domName CSSMediaRule.media */
  final MediaList media;

  /** @domName CSSMediaRule.deleteRule */
  void deleteRule(int index) native;

  /** @domName CSSMediaRule.insertRule */
  int insertRule(String rule, int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName CSSPageRule
class CSSPageRule extends CSSRule native "*CSSPageRule" {

  /** @domName CSSPageRule.selectorText */
  String selectorText;

  /** @domName CSSPageRule.style */
  final CSSStyleDeclaration style;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName CSSPrimitiveValue
class CSSPrimitiveValue extends CSSValue native "*CSSPrimitiveValue" {

  static const int CSS_ATTR = 22;

  static const int CSS_CM = 6;

  static const int CSS_COUNTER = 23;

  static const int CSS_DEG = 11;

  static const int CSS_DIMENSION = 18;

  static const int CSS_EMS = 3;

  static const int CSS_EXS = 4;

  static const int CSS_GRAD = 13;

  static const int CSS_HZ = 16;

  static const int CSS_IDENT = 21;

  static const int CSS_IN = 8;

  static const int CSS_KHZ = 17;

  static const int CSS_MM = 7;

  static const int CSS_MS = 14;

  static const int CSS_NUMBER = 1;

  static const int CSS_PC = 10;

  static const int CSS_PERCENTAGE = 2;

  static const int CSS_PT = 9;

  static const int CSS_PX = 5;

  static const int CSS_RAD = 12;

  static const int CSS_RECT = 24;

  static const int CSS_RGBCOLOR = 25;

  static const int CSS_S = 15;

  static const int CSS_STRING = 19;

  static const int CSS_UNKNOWN = 0;

  static const int CSS_URI = 20;

  static const int CSS_VH = 27;

  static const int CSS_VMIN = 28;

  static const int CSS_VW = 26;

  /** @domName CSSPrimitiveValue.primitiveType */
  final int primitiveType;

  /** @domName CSSPrimitiveValue.getCounterValue */
  Counter getCounterValue() native;

  /** @domName CSSPrimitiveValue.getFloatValue */
  num getFloatValue(int unitType) native;

  /** @domName CSSPrimitiveValue.getRGBColorValue */
  RGBColor getRGBColorValue() native;

  /** @domName CSSPrimitiveValue.getRectValue */
  Rect getRectValue() native;

  /** @domName CSSPrimitiveValue.getStringValue */
  String getStringValue() native;

  /** @domName CSSPrimitiveValue.setFloatValue */
  void setFloatValue(int unitType, num floatValue) native;

  /** @domName CSSPrimitiveValue.setStringValue */
  void setStringValue(int stringType, String stringValue) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName CSSRule
class CSSRule native "*CSSRule" {

  static const int CHARSET_RULE = 2;

  static const int FONT_FACE_RULE = 5;

  static const int IMPORT_RULE = 3;

  static const int MEDIA_RULE = 4;

  static const int PAGE_RULE = 6;

  static const int STYLE_RULE = 1;

  static const int UNKNOWN_RULE = 0;

  static const int WEBKIT_KEYFRAMES_RULE = 7;

  static const int WEBKIT_KEYFRAME_RULE = 8;

  /** @domName CSSRule.cssText */
  String cssText;

  /** @domName CSSRule.parentRule */
  final CSSRule parentRule;

  /** @domName CSSRule.parentStyleSheet */
  final CSSStyleSheet parentStyleSheet;

  /** @domName CSSRule.type */
  final int type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


String _cachedBrowserPrefix;

String get _browserPrefix {
  if (_cachedBrowserPrefix == null) {
    if (_Device.isFirefox) {
      _cachedBrowserPrefix = '-moz-';
    } else if (_Device.isIE) {
      _cachedBrowserPrefix = '-ms-';
    } else if (_Device.isOpera) {
      _cachedBrowserPrefix = '-o-';
    } else {
      _cachedBrowserPrefix = '-webkit-';
    }
  }
  return _cachedBrowserPrefix;
}

class CSSStyleDeclaration native "*CSSStyleDeclaration" {
  factory CSSStyleDeclaration() => _CSSStyleDeclarationFactoryProvider.createCSSStyleDeclaration();
  factory CSSStyleDeclaration.css(String css) =>
      _CSSStyleDeclarationFactoryProvider.createCSSStyleDeclaration_css(css);


  /** @domName CSSStyleDeclaration.cssText */
  String cssText;

  /** @domName CSSStyleDeclaration.length */
  final int length;

  /** @domName CSSStyleDeclaration.parentRule */
  final CSSRule parentRule;

  /** @domName CSSStyleDeclaration.getPropertyCSSValue */
  CSSValue getPropertyCSSValue(String propertyName) native;

  /** @domName CSSStyleDeclaration.getPropertyPriority */
  String getPropertyPriority(String propertyName) native;

  /** @domName CSSStyleDeclaration.getPropertyShorthand */
  String getPropertyShorthand(String propertyName) native;

  /** @domName CSSStyleDeclaration._getPropertyValue */
  String _getPropertyValue(String propertyName) native "getPropertyValue";

  /** @domName CSSStyleDeclaration.isPropertyImplicit */
  bool isPropertyImplicit(String propertyName) native;

  /** @domName CSSStyleDeclaration.item */
  String item(int index) native;

  /** @domName CSSStyleDeclaration.removeProperty */
  String removeProperty(String propertyName) native;


  String getPropertyValue(String propertyName) {
    var propValue = _getPropertyValue(propertyName);
    return propValue != null ? propValue : '';
  }

  void setProperty(String propertyName, String value, [String priority]) {
    JS('void', '#.setProperty(#, #, #)', this, propertyName, value, priority);
    // Bug #2772, IE9 requires a poke to actually apply the value.
    if (JS('bool', '!!#.setAttribute', this)) {
      JS('void', '#.setAttribute(#, #)', this, propertyName, value);
    }
  }

  // TODO(jacobr): generate this list of properties using the existing script.
    /** Gets the value of "animation" */
  String get animation =>
    getPropertyValue('${_browserPrefix}animation');

  /** Sets the value of "animation" */
  void set animation(var value) {
    setProperty('${_browserPrefix}animation', value, '');
  }

  /** Gets the value of "animation-delay" */
  String get animationDelay =>
    getPropertyValue('${_browserPrefix}animation-delay');

  /** Sets the value of "animation-delay" */
  void set animationDelay(var value) {
    setProperty('${_browserPrefix}animation-delay', value, '');
  }

  /** Gets the value of "animation-direction" */
  String get animationDirection =>
    getPropertyValue('${_browserPrefix}animation-direction');

  /** Sets the value of "animation-direction" */
  void set animationDirection(var value) {
    setProperty('${_browserPrefix}animation-direction', value, '');
  }

  /** Gets the value of "animation-duration" */
  String get animationDuration =>
    getPropertyValue('${_browserPrefix}animation-duration');

  /** Sets the value of "animation-duration" */
  void set animationDuration(var value) {
    setProperty('${_browserPrefix}animation-duration', value, '');
  }

  /** Gets the value of "animation-fill-mode" */
  String get animationFillMode =>
    getPropertyValue('${_browserPrefix}animation-fill-mode');

  /** Sets the value of "animation-fill-mode" */
  void set animationFillMode(var value) {
    setProperty('${_browserPrefix}animation-fill-mode', value, '');
  }

  /** Gets the value of "animation-iteration-count" */
  String get animationIterationCount =>
    getPropertyValue('${_browserPrefix}animation-iteration-count');

  /** Sets the value of "animation-iteration-count" */
  void set animationIterationCount(var value) {
    setProperty('${_browserPrefix}animation-iteration-count', value, '');
  }

  /** Gets the value of "animation-name" */
  String get animationName =>
    getPropertyValue('${_browserPrefix}animation-name');

  /** Sets the value of "animation-name" */
  void set animationName(var value) {
    setProperty('${_browserPrefix}animation-name', value, '');
  }

  /** Gets the value of "animation-play-state" */
  String get animationPlayState =>
    getPropertyValue('${_browserPrefix}animation-play-state');

  /** Sets the value of "animation-play-state" */
  void set animationPlayState(var value) {
    setProperty('${_browserPrefix}animation-play-state', value, '');
  }

  /** Gets the value of "animation-timing-function" */
  String get animationTimingFunction =>
    getPropertyValue('${_browserPrefix}animation-timing-function');

  /** Sets the value of "animation-timing-function" */
  void set animationTimingFunction(var value) {
    setProperty('${_browserPrefix}animation-timing-function', value, '');
  }

  /** Gets the value of "appearance" */
  String get appearance =>
    getPropertyValue('${_browserPrefix}appearance');

  /** Sets the value of "appearance" */
  void set appearance(var value) {
    setProperty('${_browserPrefix}appearance', value, '');
  }

  /** Gets the value of "backface-visibility" */
  String get backfaceVisibility =>
    getPropertyValue('${_browserPrefix}backface-visibility');

  /** Sets the value of "backface-visibility" */
  void set backfaceVisibility(var value) {
    setProperty('${_browserPrefix}backface-visibility', value, '');
  }

  /** Gets the value of "background" */
  String get background =>
    getPropertyValue('background');

  /** Sets the value of "background" */
  void set background(var value) {
    setProperty('background', value, '');
  }

  /** Gets the value of "background-attachment" */
  String get backgroundAttachment =>
    getPropertyValue('background-attachment');

  /** Sets the value of "background-attachment" */
  void set backgroundAttachment(var value) {
    setProperty('background-attachment', value, '');
  }

  /** Gets the value of "background-clip" */
  String get backgroundClip =>
    getPropertyValue('background-clip');

  /** Sets the value of "background-clip" */
  void set backgroundClip(var value) {
    setProperty('background-clip', value, '');
  }

  /** Gets the value of "background-color" */
  String get backgroundColor =>
    getPropertyValue('background-color');

  /** Sets the value of "background-color" */
  void set backgroundColor(var value) {
    setProperty('background-color', value, '');
  }

  /** Gets the value of "background-composite" */
  String get backgroundComposite =>
    getPropertyValue('${_browserPrefix}background-composite');

  /** Sets the value of "background-composite" */
  void set backgroundComposite(var value) {
    setProperty('${_browserPrefix}background-composite', value, '');
  }

  /** Gets the value of "background-image" */
  String get backgroundImage =>
    getPropertyValue('background-image');

  /** Sets the value of "background-image" */
  void set backgroundImage(var value) {
    setProperty('background-image', value, '');
  }

  /** Gets the value of "background-origin" */
  String get backgroundOrigin =>
    getPropertyValue('background-origin');

  /** Sets the value of "background-origin" */
  void set backgroundOrigin(var value) {
    setProperty('background-origin', value, '');
  }

  /** Gets the value of "background-position" */
  String get backgroundPosition =>
    getPropertyValue('background-position');

  /** Sets the value of "background-position" */
  void set backgroundPosition(var value) {
    setProperty('background-position', value, '');
  }

  /** Gets the value of "background-position-x" */
  String get backgroundPositionX =>
    getPropertyValue('background-position-x');

  /** Sets the value of "background-position-x" */
  void set backgroundPositionX(var value) {
    setProperty('background-position-x', value, '');
  }

  /** Gets the value of "background-position-y" */
  String get backgroundPositionY =>
    getPropertyValue('background-position-y');

  /** Sets the value of "background-position-y" */
  void set backgroundPositionY(var value) {
    setProperty('background-position-y', value, '');
  }

  /** Gets the value of "background-repeat" */
  String get backgroundRepeat =>
    getPropertyValue('background-repeat');

  /** Sets the value of "background-repeat" */
  void set backgroundRepeat(var value) {
    setProperty('background-repeat', value, '');
  }

  /** Gets the value of "background-repeat-x" */
  String get backgroundRepeatX =>
    getPropertyValue('background-repeat-x');

  /** Sets the value of "background-repeat-x" */
  void set backgroundRepeatX(var value) {
    setProperty('background-repeat-x', value, '');
  }

  /** Gets the value of "background-repeat-y" */
  String get backgroundRepeatY =>
    getPropertyValue('background-repeat-y');

  /** Sets the value of "background-repeat-y" */
  void set backgroundRepeatY(var value) {
    setProperty('background-repeat-y', value, '');
  }

  /** Gets the value of "background-size" */
  String get backgroundSize =>
    getPropertyValue('background-size');

  /** Sets the value of "background-size" */
  void set backgroundSize(var value) {
    setProperty('background-size', value, '');
  }

  /** Gets the value of "border" */
  String get border =>
    getPropertyValue('border');

  /** Sets the value of "border" */
  void set border(var value) {
    setProperty('border', value, '');
  }

  /** Gets the value of "border-after" */
  String get borderAfter =>
    getPropertyValue('${_browserPrefix}border-after');

  /** Sets the value of "border-after" */
  void set borderAfter(var value) {
    setProperty('${_browserPrefix}border-after', value, '');
  }

  /** Gets the value of "border-after-color" */
  String get borderAfterColor =>
    getPropertyValue('${_browserPrefix}border-after-color');

  /** Sets the value of "border-after-color" */
  void set borderAfterColor(var value) {
    setProperty('${_browserPrefix}border-after-color', value, '');
  }

  /** Gets the value of "border-after-style" */
  String get borderAfterStyle =>
    getPropertyValue('${_browserPrefix}border-after-style');

  /** Sets the value of "border-after-style" */
  void set borderAfterStyle(var value) {
    setProperty('${_browserPrefix}border-after-style', value, '');
  }

  /** Gets the value of "border-after-width" */
  String get borderAfterWidth =>
    getPropertyValue('${_browserPrefix}border-after-width');

  /** Sets the value of "border-after-width" */
  void set borderAfterWidth(var value) {
    setProperty('${_browserPrefix}border-after-width', value, '');
  }

  /** Gets the value of "border-before" */
  String get borderBefore =>
    getPropertyValue('${_browserPrefix}border-before');

  /** Sets the value of "border-before" */
  void set borderBefore(var value) {
    setProperty('${_browserPrefix}border-before', value, '');
  }

  /** Gets the value of "border-before-color" */
  String get borderBeforeColor =>
    getPropertyValue('${_browserPrefix}border-before-color');

  /** Sets the value of "border-before-color" */
  void set borderBeforeColor(var value) {
    setProperty('${_browserPrefix}border-before-color', value, '');
  }

  /** Gets the value of "border-before-style" */
  String get borderBeforeStyle =>
    getPropertyValue('${_browserPrefix}border-before-style');

  /** Sets the value of "border-before-style" */
  void set borderBeforeStyle(var value) {
    setProperty('${_browserPrefix}border-before-style', value, '');
  }

  /** Gets the value of "border-before-width" */
  String get borderBeforeWidth =>
    getPropertyValue('${_browserPrefix}border-before-width');

  /** Sets the value of "border-before-width" */
  void set borderBeforeWidth(var value) {
    setProperty('${_browserPrefix}border-before-width', value, '');
  }

  /** Gets the value of "border-bottom" */
  String get borderBottom =>
    getPropertyValue('border-bottom');

  /** Sets the value of "border-bottom" */
  void set borderBottom(var value) {
    setProperty('border-bottom', value, '');
  }

  /** Gets the value of "border-bottom-color" */
  String get borderBottomColor =>
    getPropertyValue('border-bottom-color');

  /** Sets the value of "border-bottom-color" */
  void set borderBottomColor(var value) {
    setProperty('border-bottom-color', value, '');
  }

  /** Gets the value of "border-bottom-left-radius" */
  String get borderBottomLeftRadius =>
    getPropertyValue('border-bottom-left-radius');

  /** Sets the value of "border-bottom-left-radius" */
  void set borderBottomLeftRadius(var value) {
    setProperty('border-bottom-left-radius', value, '');
  }

  /** Gets the value of "border-bottom-right-radius" */
  String get borderBottomRightRadius =>
    getPropertyValue('border-bottom-right-radius');

  /** Sets the value of "border-bottom-right-radius" */
  void set borderBottomRightRadius(var value) {
    setProperty('border-bottom-right-radius', value, '');
  }

  /** Gets the value of "border-bottom-style" */
  String get borderBottomStyle =>
    getPropertyValue('border-bottom-style');

  /** Sets the value of "border-bottom-style" */
  void set borderBottomStyle(var value) {
    setProperty('border-bottom-style', value, '');
  }

  /** Gets the value of "border-bottom-width" */
  String get borderBottomWidth =>
    getPropertyValue('border-bottom-width');

  /** Sets the value of "border-bottom-width" */
  void set borderBottomWidth(var value) {
    setProperty('border-bottom-width', value, '');
  }

  /** Gets the value of "border-collapse" */
  String get borderCollapse =>
    getPropertyValue('border-collapse');

  /** Sets the value of "border-collapse" */
  void set borderCollapse(var value) {
    setProperty('border-collapse', value, '');
  }

  /** Gets the value of "border-color" */
  String get borderColor =>
    getPropertyValue('border-color');

  /** Sets the value of "border-color" */
  void set borderColor(var value) {
    setProperty('border-color', value, '');
  }

  /** Gets the value of "border-end" */
  String get borderEnd =>
    getPropertyValue('${_browserPrefix}border-end');

  /** Sets the value of "border-end" */
  void set borderEnd(var value) {
    setProperty('${_browserPrefix}border-end', value, '');
  }

  /** Gets the value of "border-end-color" */
  String get borderEndColor =>
    getPropertyValue('${_browserPrefix}border-end-color');

  /** Sets the value of "border-end-color" */
  void set borderEndColor(var value) {
    setProperty('${_browserPrefix}border-end-color', value, '');
  }

  /** Gets the value of "border-end-style" */
  String get borderEndStyle =>
    getPropertyValue('${_browserPrefix}border-end-style');

  /** Sets the value of "border-end-style" */
  void set borderEndStyle(var value) {
    setProperty('${_browserPrefix}border-end-style', value, '');
  }

  /** Gets the value of "border-end-width" */
  String get borderEndWidth =>
    getPropertyValue('${_browserPrefix}border-end-width');

  /** Sets the value of "border-end-width" */
  void set borderEndWidth(var value) {
    setProperty('${_browserPrefix}border-end-width', value, '');
  }

  /** Gets the value of "border-fit" */
  String get borderFit =>
    getPropertyValue('${_browserPrefix}border-fit');

  /** Sets the value of "border-fit" */
  void set borderFit(var value) {
    setProperty('${_browserPrefix}border-fit', value, '');
  }

  /** Gets the value of "border-horizontal-spacing" */
  String get borderHorizontalSpacing =>
    getPropertyValue('${_browserPrefix}border-horizontal-spacing');

  /** Sets the value of "border-horizontal-spacing" */
  void set borderHorizontalSpacing(var value) {
    setProperty('${_browserPrefix}border-horizontal-spacing', value, '');
  }

  /** Gets the value of "border-image" */
  String get borderImage =>
    getPropertyValue('border-image');

  /** Sets the value of "border-image" */
  void set borderImage(var value) {
    setProperty('border-image', value, '');
  }

  /** Gets the value of "border-image-outset" */
  String get borderImageOutset =>
    getPropertyValue('border-image-outset');

  /** Sets the value of "border-image-outset" */
  void set borderImageOutset(var value) {
    setProperty('border-image-outset', value, '');
  }

  /** Gets the value of "border-image-repeat" */
  String get borderImageRepeat =>
    getPropertyValue('border-image-repeat');

  /** Sets the value of "border-image-repeat" */
  void set borderImageRepeat(var value) {
    setProperty('border-image-repeat', value, '');
  }

  /** Gets the value of "border-image-slice" */
  String get borderImageSlice =>
    getPropertyValue('border-image-slice');

  /** Sets the value of "border-image-slice" */
  void set borderImageSlice(var value) {
    setProperty('border-image-slice', value, '');
  }

  /** Gets the value of "border-image-source" */
  String get borderImageSource =>
    getPropertyValue('border-image-source');

  /** Sets the value of "border-image-source" */
  void set borderImageSource(var value) {
    setProperty('border-image-source', value, '');
  }

  /** Gets the value of "border-image-width" */
  String get borderImageWidth =>
    getPropertyValue('border-image-width');

  /** Sets the value of "border-image-width" */
  void set borderImageWidth(var value) {
    setProperty('border-image-width', value, '');
  }

  /** Gets the value of "border-left" */
  String get borderLeft =>
    getPropertyValue('border-left');

  /** Sets the value of "border-left" */
  void set borderLeft(var value) {
    setProperty('border-left', value, '');
  }

  /** Gets the value of "border-left-color" */
  String get borderLeftColor =>
    getPropertyValue('border-left-color');

  /** Sets the value of "border-left-color" */
  void set borderLeftColor(var value) {
    setProperty('border-left-color', value, '');
  }

  /** Gets the value of "border-left-style" */
  String get borderLeftStyle =>
    getPropertyValue('border-left-style');

  /** Sets the value of "border-left-style" */
  void set borderLeftStyle(var value) {
    setProperty('border-left-style', value, '');
  }

  /** Gets the value of "border-left-width" */
  String get borderLeftWidth =>
    getPropertyValue('border-left-width');

  /** Sets the value of "border-left-width" */
  void set borderLeftWidth(var value) {
    setProperty('border-left-width', value, '');
  }

  /** Gets the value of "border-radius" */
  String get borderRadius =>
    getPropertyValue('border-radius');

  /** Sets the value of "border-radius" */
  void set borderRadius(var value) {
    setProperty('border-radius', value, '');
  }

  /** Gets the value of "border-right" */
  String get borderRight =>
    getPropertyValue('border-right');

  /** Sets the value of "border-right" */
  void set borderRight(var value) {
    setProperty('border-right', value, '');
  }

  /** Gets the value of "border-right-color" */
  String get borderRightColor =>
    getPropertyValue('border-right-color');

  /** Sets the value of "border-right-color" */
  void set borderRightColor(var value) {
    setProperty('border-right-color', value, '');
  }

  /** Gets the value of "border-right-style" */
  String get borderRightStyle =>
    getPropertyValue('border-right-style');

  /** Sets the value of "border-right-style" */
  void set borderRightStyle(var value) {
    setProperty('border-right-style', value, '');
  }

  /** Gets the value of "border-right-width" */
  String get borderRightWidth =>
    getPropertyValue('border-right-width');

  /** Sets the value of "border-right-width" */
  void set borderRightWidth(var value) {
    setProperty('border-right-width', value, '');
  }

  /** Gets the value of "border-spacing" */
  String get borderSpacing =>
    getPropertyValue('border-spacing');

  /** Sets the value of "border-spacing" */
  void set borderSpacing(var value) {
    setProperty('border-spacing', value, '');
  }

  /** Gets the value of "border-start" */
  String get borderStart =>
    getPropertyValue('${_browserPrefix}border-start');

  /** Sets the value of "border-start" */
  void set borderStart(var value) {
    setProperty('${_browserPrefix}border-start', value, '');
  }

  /** Gets the value of "border-start-color" */
  String get borderStartColor =>
    getPropertyValue('${_browserPrefix}border-start-color');

  /** Sets the value of "border-start-color" */
  void set borderStartColor(var value) {
    setProperty('${_browserPrefix}border-start-color', value, '');
  }

  /** Gets the value of "border-start-style" */
  String get borderStartStyle =>
    getPropertyValue('${_browserPrefix}border-start-style');

  /** Sets the value of "border-start-style" */
  void set borderStartStyle(var value) {
    setProperty('${_browserPrefix}border-start-style', value, '');
  }

  /** Gets the value of "border-start-width" */
  String get borderStartWidth =>
    getPropertyValue('${_browserPrefix}border-start-width');

  /** Sets the value of "border-start-width" */
  void set borderStartWidth(var value) {
    setProperty('${_browserPrefix}border-start-width', value, '');
  }

  /** Gets the value of "border-style" */
  String get borderStyle =>
    getPropertyValue('border-style');

  /** Sets the value of "border-style" */
  void set borderStyle(var value) {
    setProperty('border-style', value, '');
  }

  /** Gets the value of "border-top" */
  String get borderTop =>
    getPropertyValue('border-top');

  /** Sets the value of "border-top" */
  void set borderTop(var value) {
    setProperty('border-top', value, '');
  }

  /** Gets the value of "border-top-color" */
  String get borderTopColor =>
    getPropertyValue('border-top-color');

  /** Sets the value of "border-top-color" */
  void set borderTopColor(var value) {
    setProperty('border-top-color', value, '');
  }

  /** Gets the value of "border-top-left-radius" */
  String get borderTopLeftRadius =>
    getPropertyValue('border-top-left-radius');

  /** Sets the value of "border-top-left-radius" */
  void set borderTopLeftRadius(var value) {
    setProperty('border-top-left-radius', value, '');
  }

  /** Gets the value of "border-top-right-radius" */
  String get borderTopRightRadius =>
    getPropertyValue('border-top-right-radius');

  /** Sets the value of "border-top-right-radius" */
  void set borderTopRightRadius(var value) {
    setProperty('border-top-right-radius', value, '');
  }

  /** Gets the value of "border-top-style" */
  String get borderTopStyle =>
    getPropertyValue('border-top-style');

  /** Sets the value of "border-top-style" */
  void set borderTopStyle(var value) {
    setProperty('border-top-style', value, '');
  }

  /** Gets the value of "border-top-width" */
  String get borderTopWidth =>
    getPropertyValue('border-top-width');

  /** Sets the value of "border-top-width" */
  void set borderTopWidth(var value) {
    setProperty('border-top-width', value, '');
  }

  /** Gets the value of "border-vertical-spacing" */
  String get borderVerticalSpacing =>
    getPropertyValue('${_browserPrefix}border-vertical-spacing');

  /** Sets the value of "border-vertical-spacing" */
  void set borderVerticalSpacing(var value) {
    setProperty('${_browserPrefix}border-vertical-spacing', value, '');
  }

  /** Gets the value of "border-width" */
  String get borderWidth =>
    getPropertyValue('border-width');

  /** Sets the value of "border-width" */
  void set borderWidth(var value) {
    setProperty('border-width', value, '');
  }

  /** Gets the value of "bottom" */
  String get bottom =>
    getPropertyValue('bottom');

  /** Sets the value of "bottom" */
  void set bottom(var value) {
    setProperty('bottom', value, '');
  }

  /** Gets the value of "box-align" */
  String get boxAlign =>
    getPropertyValue('${_browserPrefix}box-align');

  /** Sets the value of "box-align" */
  void set boxAlign(var value) {
    setProperty('${_browserPrefix}box-align', value, '');
  }

  /** Gets the value of "box-direction" */
  String get boxDirection =>
    getPropertyValue('${_browserPrefix}box-direction');

  /** Sets the value of "box-direction" */
  void set boxDirection(var value) {
    setProperty('${_browserPrefix}box-direction', value, '');
  }

  /** Gets the value of "box-flex" */
  String get boxFlex =>
    getPropertyValue('${_browserPrefix}box-flex');

  /** Sets the value of "box-flex" */
  void set boxFlex(var value) {
    setProperty('${_browserPrefix}box-flex', value, '');
  }

  /** Gets the value of "box-flex-group" */
  String get boxFlexGroup =>
    getPropertyValue('${_browserPrefix}box-flex-group');

  /** Sets the value of "box-flex-group" */
  void set boxFlexGroup(var value) {
    setProperty('${_browserPrefix}box-flex-group', value, '');
  }

  /** Gets the value of "box-lines" */
  String get boxLines =>
    getPropertyValue('${_browserPrefix}box-lines');

  /** Sets the value of "box-lines" */
  void set boxLines(var value) {
    setProperty('${_browserPrefix}box-lines', value, '');
  }

  /** Gets the value of "box-ordinal-group" */
  String get boxOrdinalGroup =>
    getPropertyValue('${_browserPrefix}box-ordinal-group');

  /** Sets the value of "box-ordinal-group" */
  void set boxOrdinalGroup(var value) {
    setProperty('${_browserPrefix}box-ordinal-group', value, '');
  }

  /** Gets the value of "box-orient" */
  String get boxOrient =>
    getPropertyValue('${_browserPrefix}box-orient');

  /** Sets the value of "box-orient" */
  void set boxOrient(var value) {
    setProperty('${_browserPrefix}box-orient', value, '');
  }

  /** Gets the value of "box-pack" */
  String get boxPack =>
    getPropertyValue('${_browserPrefix}box-pack');

  /** Sets the value of "box-pack" */
  void set boxPack(var value) {
    setProperty('${_browserPrefix}box-pack', value, '');
  }

  /** Gets the value of "box-reflect" */
  String get boxReflect =>
    getPropertyValue('${_browserPrefix}box-reflect');

  /** Sets the value of "box-reflect" */
  void set boxReflect(var value) {
    setProperty('${_browserPrefix}box-reflect', value, '');
  }

  /** Gets the value of "box-shadow" */
  String get boxShadow =>
    getPropertyValue('box-shadow');

  /** Sets the value of "box-shadow" */
  void set boxShadow(var value) {
    setProperty('box-shadow', value, '');
  }

  /** Gets the value of "box-sizing" */
  String get boxSizing =>
    getPropertyValue('box-sizing');

  /** Sets the value of "box-sizing" */
  void set boxSizing(var value) {
    setProperty('box-sizing', value, '');
  }

  /** Gets the value of "caption-side" */
  String get captionSide =>
    getPropertyValue('caption-side');

  /** Sets the value of "caption-side" */
  void set captionSide(var value) {
    setProperty('caption-side', value, '');
  }

  /** Gets the value of "clear" */
  String get clear =>
    getPropertyValue('clear');

  /** Sets the value of "clear" */
  void set clear(var value) {
    setProperty('clear', value, '');
  }

  /** Gets the value of "clip" */
  String get clip =>
    getPropertyValue('clip');

  /** Sets the value of "clip" */
  void set clip(var value) {
    setProperty('clip', value, '');
  }

  /** Gets the value of "color" */
  String get color =>
    getPropertyValue('color');

  /** Sets the value of "color" */
  void set color(var value) {
    setProperty('color', value, '');
  }

  /** Gets the value of "color-correction" */
  String get colorCorrection =>
    getPropertyValue('${_browserPrefix}color-correction');

  /** Sets the value of "color-correction" */
  void set colorCorrection(var value) {
    setProperty('${_browserPrefix}color-correction', value, '');
  }

  /** Gets the value of "column-break-after" */
  String get columnBreakAfter =>
    getPropertyValue('${_browserPrefix}column-break-after');

  /** Sets the value of "column-break-after" */
  void set columnBreakAfter(var value) {
    setProperty('${_browserPrefix}column-break-after', value, '');
  }

  /** Gets the value of "column-break-before" */
  String get columnBreakBefore =>
    getPropertyValue('${_browserPrefix}column-break-before');

  /** Sets the value of "column-break-before" */
  void set columnBreakBefore(var value) {
    setProperty('${_browserPrefix}column-break-before', value, '');
  }

  /** Gets the value of "column-break-inside" */
  String get columnBreakInside =>
    getPropertyValue('${_browserPrefix}column-break-inside');

  /** Sets the value of "column-break-inside" */
  void set columnBreakInside(var value) {
    setProperty('${_browserPrefix}column-break-inside', value, '');
  }

  /** Gets the value of "column-count" */
  String get columnCount =>
    getPropertyValue('${_browserPrefix}column-count');

  /** Sets the value of "column-count" */
  void set columnCount(var value) {
    setProperty('${_browserPrefix}column-count', value, '');
  }

  /** Gets the value of "column-gap" */
  String get columnGap =>
    getPropertyValue('${_browserPrefix}column-gap');

  /** Sets the value of "column-gap" */
  void set columnGap(var value) {
    setProperty('${_browserPrefix}column-gap', value, '');
  }

  /** Gets the value of "column-rule" */
  String get columnRule =>
    getPropertyValue('${_browserPrefix}column-rule');

  /** Sets the value of "column-rule" */
  void set columnRule(var value) {
    setProperty('${_browserPrefix}column-rule', value, '');
  }

  /** Gets the value of "column-rule-color" */
  String get columnRuleColor =>
    getPropertyValue('${_browserPrefix}column-rule-color');

  /** Sets the value of "column-rule-color" */
  void set columnRuleColor(var value) {
    setProperty('${_browserPrefix}column-rule-color', value, '');
  }

  /** Gets the value of "column-rule-style" */
  String get columnRuleStyle =>
    getPropertyValue('${_browserPrefix}column-rule-style');

  /** Sets the value of "column-rule-style" */
  void set columnRuleStyle(var value) {
    setProperty('${_browserPrefix}column-rule-style', value, '');
  }

  /** Gets the value of "column-rule-width" */
  String get columnRuleWidth =>
    getPropertyValue('${_browserPrefix}column-rule-width');

  /** Sets the value of "column-rule-width" */
  void set columnRuleWidth(var value) {
    setProperty('${_browserPrefix}column-rule-width', value, '');
  }

  /** Gets the value of "column-span" */
  String get columnSpan =>
    getPropertyValue('${_browserPrefix}column-span');

  /** Sets the value of "column-span" */
  void set columnSpan(var value) {
    setProperty('${_browserPrefix}column-span', value, '');
  }

  /** Gets the value of "column-width" */
  String get columnWidth =>
    getPropertyValue('${_browserPrefix}column-width');

  /** Sets the value of "column-width" */
  void set columnWidth(var value) {
    setProperty('${_browserPrefix}column-width', value, '');
  }

  /** Gets the value of "columns" */
  String get columns =>
    getPropertyValue('${_browserPrefix}columns');

  /** Sets the value of "columns" */
  void set columns(var value) {
    setProperty('${_browserPrefix}columns', value, '');
  }

  /** Gets the value of "content" */
  String get content =>
    getPropertyValue('content');

  /** Sets the value of "content" */
  void set content(var value) {
    setProperty('content', value, '');
  }

  /** Gets the value of "counter-increment" */
  String get counterIncrement =>
    getPropertyValue('counter-increment');

  /** Sets the value of "counter-increment" */
  void set counterIncrement(var value) {
    setProperty('counter-increment', value, '');
  }

  /** Gets the value of "counter-reset" */
  String get counterReset =>
    getPropertyValue('counter-reset');

  /** Sets the value of "counter-reset" */
  void set counterReset(var value) {
    setProperty('counter-reset', value, '');
  }

  /** Gets the value of "cursor" */
  String get cursor =>
    getPropertyValue('cursor');

  /** Sets the value of "cursor" */
  void set cursor(var value) {
    setProperty('cursor', value, '');
  }

  /** Gets the value of "direction" */
  String get direction =>
    getPropertyValue('direction');

  /** Sets the value of "direction" */
  void set direction(var value) {
    setProperty('direction', value, '');
  }

  /** Gets the value of "display" */
  String get display =>
    getPropertyValue('display');

  /** Sets the value of "display" */
  void set display(var value) {
    setProperty('display', value, '');
  }

  /** Gets the value of "empty-cells" */
  String get emptyCells =>
    getPropertyValue('empty-cells');

  /** Sets the value of "empty-cells" */
  void set emptyCells(var value) {
    setProperty('empty-cells', value, '');
  }

  /** Gets the value of "filter" */
  String get filter =>
    getPropertyValue('${_browserPrefix}filter');

  /** Sets the value of "filter" */
  void set filter(var value) {
    setProperty('${_browserPrefix}filter', value, '');
  }

  /** Gets the value of "flex-align" */
  String get flexAlign =>
    getPropertyValue('${_browserPrefix}flex-align');

  /** Sets the value of "flex-align" */
  void set flexAlign(var value) {
    setProperty('${_browserPrefix}flex-align', value, '');
  }

  /** Gets the value of "flex-flow" */
  String get flexFlow =>
    getPropertyValue('${_browserPrefix}flex-flow');

  /** Sets the value of "flex-flow" */
  void set flexFlow(var value) {
    setProperty('${_browserPrefix}flex-flow', value, '');
  }

  /** Gets the value of "flex-order" */
  String get flexOrder =>
    getPropertyValue('${_browserPrefix}flex-order');

  /** Sets the value of "flex-order" */
  void set flexOrder(var value) {
    setProperty('${_browserPrefix}flex-order', value, '');
  }

  /** Gets the value of "flex-pack" */
  String get flexPack =>
    getPropertyValue('${_browserPrefix}flex-pack');

  /** Sets the value of "flex-pack" */
  void set flexPack(var value) {
    setProperty('${_browserPrefix}flex-pack', value, '');
  }

  /** Gets the value of "float" */
  String get float =>
    getPropertyValue('float');

  /** Sets the value of "float" */
  void set float(var value) {
    setProperty('float', value, '');
  }

  /** Gets the value of "flow-from" */
  String get flowFrom =>
    getPropertyValue('${_browserPrefix}flow-from');

  /** Sets the value of "flow-from" */
  void set flowFrom(var value) {
    setProperty('${_browserPrefix}flow-from', value, '');
  }

  /** Gets the value of "flow-into" */
  String get flowInto =>
    getPropertyValue('${_browserPrefix}flow-into');

  /** Sets the value of "flow-into" */
  void set flowInto(var value) {
    setProperty('${_browserPrefix}flow-into', value, '');
  }

  /** Gets the value of "font" */
  String get font =>
    getPropertyValue('font');

  /** Sets the value of "font" */
  void set font(var value) {
    setProperty('font', value, '');
  }

  /** Gets the value of "font-family" */
  String get fontFamily =>
    getPropertyValue('font-family');

  /** Sets the value of "font-family" */
  void set fontFamily(var value) {
    setProperty('font-family', value, '');
  }

  /** Gets the value of "font-feature-settings" */
  String get fontFeatureSettings =>
    getPropertyValue('${_browserPrefix}font-feature-settings');

  /** Sets the value of "font-feature-settings" */
  void set fontFeatureSettings(var value) {
    setProperty('${_browserPrefix}font-feature-settings', value, '');
  }

  /** Gets the value of "font-size" */
  String get fontSize =>
    getPropertyValue('font-size');

  /** Sets the value of "font-size" */
  void set fontSize(var value) {
    setProperty('font-size', value, '');
  }

  /** Gets the value of "font-size-delta" */
  String get fontSizeDelta =>
    getPropertyValue('${_browserPrefix}font-size-delta');

  /** Sets the value of "font-size-delta" */
  void set fontSizeDelta(var value) {
    setProperty('${_browserPrefix}font-size-delta', value, '');
  }

  /** Gets the value of "font-smoothing" */
  String get fontSmoothing =>
    getPropertyValue('${_browserPrefix}font-smoothing');

  /** Sets the value of "font-smoothing" */
  void set fontSmoothing(var value) {
    setProperty('${_browserPrefix}font-smoothing', value, '');
  }

  /** Gets the value of "font-stretch" */
  String get fontStretch =>
    getPropertyValue('font-stretch');

  /** Sets the value of "font-stretch" */
  void set fontStretch(var value) {
    setProperty('font-stretch', value, '');
  }

  /** Gets the value of "font-style" */
  String get fontStyle =>
    getPropertyValue('font-style');

  /** Sets the value of "font-style" */
  void set fontStyle(var value) {
    setProperty('font-style', value, '');
  }

  /** Gets the value of "font-variant" */
  String get fontVariant =>
    getPropertyValue('font-variant');

  /** Sets the value of "font-variant" */
  void set fontVariant(var value) {
    setProperty('font-variant', value, '');
  }

  /** Gets the value of "font-weight" */
  String get fontWeight =>
    getPropertyValue('font-weight');

  /** Sets the value of "font-weight" */
  void set fontWeight(var value) {
    setProperty('font-weight', value, '');
  }

  /** Gets the value of "height" */
  String get height =>
    getPropertyValue('height');

  /** Sets the value of "height" */
  void set height(var value) {
    setProperty('height', value, '');
  }

  /** Gets the value of "highlight" */
  String get highlight =>
    getPropertyValue('${_browserPrefix}highlight');

  /** Sets the value of "highlight" */
  void set highlight(var value) {
    setProperty('${_browserPrefix}highlight', value, '');
  }

  /** Gets the value of "hyphenate-character" */
  String get hyphenateCharacter =>
    getPropertyValue('${_browserPrefix}hyphenate-character');

  /** Sets the value of "hyphenate-character" */
  void set hyphenateCharacter(var value) {
    setProperty('${_browserPrefix}hyphenate-character', value, '');
  }

  /** Gets the value of "hyphenate-limit-after" */
  String get hyphenateLimitAfter =>
    getPropertyValue('${_browserPrefix}hyphenate-limit-after');

  /** Sets the value of "hyphenate-limit-after" */
  void set hyphenateLimitAfter(var value) {
    setProperty('${_browserPrefix}hyphenate-limit-after', value, '');
  }

  /** Gets the value of "hyphenate-limit-before" */
  String get hyphenateLimitBefore =>
    getPropertyValue('${_browserPrefix}hyphenate-limit-before');

  /** Sets the value of "hyphenate-limit-before" */
  void set hyphenateLimitBefore(var value) {
    setProperty('${_browserPrefix}hyphenate-limit-before', value, '');
  }

  /** Gets the value of "hyphenate-limit-lines" */
  String get hyphenateLimitLines =>
    getPropertyValue('${_browserPrefix}hyphenate-limit-lines');

  /** Sets the value of "hyphenate-limit-lines" */
  void set hyphenateLimitLines(var value) {
    setProperty('${_browserPrefix}hyphenate-limit-lines', value, '');
  }

  /** Gets the value of "hyphens" */
  String get hyphens =>
    getPropertyValue('${_browserPrefix}hyphens');

  /** Sets the value of "hyphens" */
  void set hyphens(var value) {
    setProperty('${_browserPrefix}hyphens', value, '');
  }

  /** Gets the value of "image-rendering" */
  String get imageRendering =>
    getPropertyValue('image-rendering');

  /** Sets the value of "image-rendering" */
  void set imageRendering(var value) {
    setProperty('image-rendering', value, '');
  }

  /** Gets the value of "left" */
  String get left =>
    getPropertyValue('left');

  /** Sets the value of "left" */
  void set left(var value) {
    setProperty('left', value, '');
  }

  /** Gets the value of "letter-spacing" */
  String get letterSpacing =>
    getPropertyValue('letter-spacing');

  /** Sets the value of "letter-spacing" */
  void set letterSpacing(var value) {
    setProperty('letter-spacing', value, '');
  }

  /** Gets the value of "line-box-contain" */
  String get lineBoxContain =>
    getPropertyValue('${_browserPrefix}line-box-contain');

  /** Sets the value of "line-box-contain" */
  void set lineBoxContain(var value) {
    setProperty('${_browserPrefix}line-box-contain', value, '');
  }

  /** Gets the value of "line-break" */
  String get lineBreak =>
    getPropertyValue('${_browserPrefix}line-break');

  /** Sets the value of "line-break" */
  void set lineBreak(var value) {
    setProperty('${_browserPrefix}line-break', value, '');
  }

  /** Gets the value of "line-clamp" */
  String get lineClamp =>
    getPropertyValue('${_browserPrefix}line-clamp');

  /** Sets the value of "line-clamp" */
  void set lineClamp(var value) {
    setProperty('${_browserPrefix}line-clamp', value, '');
  }

  /** Gets the value of "line-height" */
  String get lineHeight =>
    getPropertyValue('line-height');

  /** Sets the value of "line-height" */
  void set lineHeight(var value) {
    setProperty('line-height', value, '');
  }

  /** Gets the value of "list-style" */
  String get listStyle =>
    getPropertyValue('list-style');

  /** Sets the value of "list-style" */
  void set listStyle(var value) {
    setProperty('list-style', value, '');
  }

  /** Gets the value of "list-style-image" */
  String get listStyleImage =>
    getPropertyValue('list-style-image');

  /** Sets the value of "list-style-image" */
  void set listStyleImage(var value) {
    setProperty('list-style-image', value, '');
  }

  /** Gets the value of "list-style-position" */
  String get listStylePosition =>
    getPropertyValue('list-style-position');

  /** Sets the value of "list-style-position" */
  void set listStylePosition(var value) {
    setProperty('list-style-position', value, '');
  }

  /** Gets the value of "list-style-type" */
  String get listStyleType =>
    getPropertyValue('list-style-type');

  /** Sets the value of "list-style-type" */
  void set listStyleType(var value) {
    setProperty('list-style-type', value, '');
  }

  /** Gets the value of "locale" */
  String get locale =>
    getPropertyValue('${_browserPrefix}locale');

  /** Sets the value of "locale" */
  void set locale(var value) {
    setProperty('${_browserPrefix}locale', value, '');
  }

  /** Gets the value of "logical-height" */
  String get logicalHeight =>
    getPropertyValue('${_browserPrefix}logical-height');

  /** Sets the value of "logical-height" */
  void set logicalHeight(var value) {
    setProperty('${_browserPrefix}logical-height', value, '');
  }

  /** Gets the value of "logical-width" */
  String get logicalWidth =>
    getPropertyValue('${_browserPrefix}logical-width');

  /** Sets the value of "logical-width" */
  void set logicalWidth(var value) {
    setProperty('${_browserPrefix}logical-width', value, '');
  }

  /** Gets the value of "margin" */
  String get margin =>
    getPropertyValue('margin');

  /** Sets the value of "margin" */
  void set margin(var value) {
    setProperty('margin', value, '');
  }

  /** Gets the value of "margin-after" */
  String get marginAfter =>
    getPropertyValue('${_browserPrefix}margin-after');

  /** Sets the value of "margin-after" */
  void set marginAfter(var value) {
    setProperty('${_browserPrefix}margin-after', value, '');
  }

  /** Gets the value of "margin-after-collapse" */
  String get marginAfterCollapse =>
    getPropertyValue('${_browserPrefix}margin-after-collapse');

  /** Sets the value of "margin-after-collapse" */
  void set marginAfterCollapse(var value) {
    setProperty('${_browserPrefix}margin-after-collapse', value, '');
  }

  /** Gets the value of "margin-before" */
  String get marginBefore =>
    getPropertyValue('${_browserPrefix}margin-before');

  /** Sets the value of "margin-before" */
  void set marginBefore(var value) {
    setProperty('${_browserPrefix}margin-before', value, '');
  }

  /** Gets the value of "margin-before-collapse" */
  String get marginBeforeCollapse =>
    getPropertyValue('${_browserPrefix}margin-before-collapse');

  /** Sets the value of "margin-before-collapse" */
  void set marginBeforeCollapse(var value) {
    setProperty('${_browserPrefix}margin-before-collapse', value, '');
  }

  /** Gets the value of "margin-bottom" */
  String get marginBottom =>
    getPropertyValue('margin-bottom');

  /** Sets the value of "margin-bottom" */
  void set marginBottom(var value) {
    setProperty('margin-bottom', value, '');
  }

  /** Gets the value of "margin-bottom-collapse" */
  String get marginBottomCollapse =>
    getPropertyValue('${_browserPrefix}margin-bottom-collapse');

  /** Sets the value of "margin-bottom-collapse" */
  void set marginBottomCollapse(var value) {
    setProperty('${_browserPrefix}margin-bottom-collapse', value, '');
  }

  /** Gets the value of "margin-collapse" */
  String get marginCollapse =>
    getPropertyValue('${_browserPrefix}margin-collapse');

  /** Sets the value of "margin-collapse" */
  void set marginCollapse(var value) {
    setProperty('${_browserPrefix}margin-collapse', value, '');
  }

  /** Gets the value of "margin-end" */
  String get marginEnd =>
    getPropertyValue('${_browserPrefix}margin-end');

  /** Sets the value of "margin-end" */
  void set marginEnd(var value) {
    setProperty('${_browserPrefix}margin-end', value, '');
  }

  /** Gets the value of "margin-left" */
  String get marginLeft =>
    getPropertyValue('margin-left');

  /** Sets the value of "margin-left" */
  void set marginLeft(var value) {
    setProperty('margin-left', value, '');
  }

  /** Gets the value of "margin-right" */
  String get marginRight =>
    getPropertyValue('margin-right');

  /** Sets the value of "margin-right" */
  void set marginRight(var value) {
    setProperty('margin-right', value, '');
  }

  /** Gets the value of "margin-start" */
  String get marginStart =>
    getPropertyValue('${_browserPrefix}margin-start');

  /** Sets the value of "margin-start" */
  void set marginStart(var value) {
    setProperty('${_browserPrefix}margin-start', value, '');
  }

  /** Gets the value of "margin-top" */
  String get marginTop =>
    getPropertyValue('margin-top');

  /** Sets the value of "margin-top" */
  void set marginTop(var value) {
    setProperty('margin-top', value, '');
  }

  /** Gets the value of "margin-top-collapse" */
  String get marginTopCollapse =>
    getPropertyValue('${_browserPrefix}margin-top-collapse');

  /** Sets the value of "margin-top-collapse" */
  void set marginTopCollapse(var value) {
    setProperty('${_browserPrefix}margin-top-collapse', value, '');
  }

  /** Gets the value of "marquee" */
  String get marquee =>
    getPropertyValue('${_browserPrefix}marquee');

  /** Sets the value of "marquee" */
  void set marquee(var value) {
    setProperty('${_browserPrefix}marquee', value, '');
  }

  /** Gets the value of "marquee-direction" */
  String get marqueeDirection =>
    getPropertyValue('${_browserPrefix}marquee-direction');

  /** Sets the value of "marquee-direction" */
  void set marqueeDirection(var value) {
    setProperty('${_browserPrefix}marquee-direction', value, '');
  }

  /** Gets the value of "marquee-increment" */
  String get marqueeIncrement =>
    getPropertyValue('${_browserPrefix}marquee-increment');

  /** Sets the value of "marquee-increment" */
  void set marqueeIncrement(var value) {
    setProperty('${_browserPrefix}marquee-increment', value, '');
  }

  /** Gets the value of "marquee-repetition" */
  String get marqueeRepetition =>
    getPropertyValue('${_browserPrefix}marquee-repetition');

  /** Sets the value of "marquee-repetition" */
  void set marqueeRepetition(var value) {
    setProperty('${_browserPrefix}marquee-repetition', value, '');
  }

  /** Gets the value of "marquee-speed" */
  String get marqueeSpeed =>
    getPropertyValue('${_browserPrefix}marquee-speed');

  /** Sets the value of "marquee-speed" */
  void set marqueeSpeed(var value) {
    setProperty('${_browserPrefix}marquee-speed', value, '');
  }

  /** Gets the value of "marquee-style" */
  String get marqueeStyle =>
    getPropertyValue('${_browserPrefix}marquee-style');

  /** Sets the value of "marquee-style" */
  void set marqueeStyle(var value) {
    setProperty('${_browserPrefix}marquee-style', value, '');
  }

  /** Gets the value of "mask" */
  String get mask =>
    getPropertyValue('${_browserPrefix}mask');

  /** Sets the value of "mask" */
  void set mask(var value) {
    setProperty('${_browserPrefix}mask', value, '');
  }

  /** Gets the value of "mask-attachment" */
  String get maskAttachment =>
    getPropertyValue('${_browserPrefix}mask-attachment');

  /** Sets the value of "mask-attachment" */
  void set maskAttachment(var value) {
    setProperty('${_browserPrefix}mask-attachment', value, '');
  }

  /** Gets the value of "mask-box-image" */
  String get maskBoxImage =>
    getPropertyValue('${_browserPrefix}mask-box-image');

  /** Sets the value of "mask-box-image" */
  void set maskBoxImage(var value) {
    setProperty('${_browserPrefix}mask-box-image', value, '');
  }

  /** Gets the value of "mask-box-image-outset" */
  String get maskBoxImageOutset =>
    getPropertyValue('${_browserPrefix}mask-box-image-outset');

  /** Sets the value of "mask-box-image-outset" */
  void set maskBoxImageOutset(var value) {
    setProperty('${_browserPrefix}mask-box-image-outset', value, '');
  }

  /** Gets the value of "mask-box-image-repeat" */
  String get maskBoxImageRepeat =>
    getPropertyValue('${_browserPrefix}mask-box-image-repeat');

  /** Sets the value of "mask-box-image-repeat" */
  void set maskBoxImageRepeat(var value) {
    setProperty('${_browserPrefix}mask-box-image-repeat', value, '');
  }

  /** Gets the value of "mask-box-image-slice" */
  String get maskBoxImageSlice =>
    getPropertyValue('${_browserPrefix}mask-box-image-slice');

  /** Sets the value of "mask-box-image-slice" */
  void set maskBoxImageSlice(var value) {
    setProperty('${_browserPrefix}mask-box-image-slice', value, '');
  }

  /** Gets the value of "mask-box-image-source" */
  String get maskBoxImageSource =>
    getPropertyValue('${_browserPrefix}mask-box-image-source');

  /** Sets the value of "mask-box-image-source" */
  void set maskBoxImageSource(var value) {
    setProperty('${_browserPrefix}mask-box-image-source', value, '');
  }

  /** Gets the value of "mask-box-image-width" */
  String get maskBoxImageWidth =>
    getPropertyValue('${_browserPrefix}mask-box-image-width');

  /** Sets the value of "mask-box-image-width" */
  void set maskBoxImageWidth(var value) {
    setProperty('${_browserPrefix}mask-box-image-width', value, '');
  }

  /** Gets the value of "mask-clip" */
  String get maskClip =>
    getPropertyValue('${_browserPrefix}mask-clip');

  /** Sets the value of "mask-clip" */
  void set maskClip(var value) {
    setProperty('${_browserPrefix}mask-clip', value, '');
  }

  /** Gets the value of "mask-composite" */
  String get maskComposite =>
    getPropertyValue('${_browserPrefix}mask-composite');

  /** Sets the value of "mask-composite" */
  void set maskComposite(var value) {
    setProperty('${_browserPrefix}mask-composite', value, '');
  }

  /** Gets the value of "mask-image" */
  String get maskImage =>
    getPropertyValue('${_browserPrefix}mask-image');

  /** Sets the value of "mask-image" */
  void set maskImage(var value) {
    setProperty('${_browserPrefix}mask-image', value, '');
  }

  /** Gets the value of "mask-origin" */
  String get maskOrigin =>
    getPropertyValue('${_browserPrefix}mask-origin');

  /** Sets the value of "mask-origin" */
  void set maskOrigin(var value) {
    setProperty('${_browserPrefix}mask-origin', value, '');
  }

  /** Gets the value of "mask-position" */
  String get maskPosition =>
    getPropertyValue('${_browserPrefix}mask-position');

  /** Sets the value of "mask-position" */
  void set maskPosition(var value) {
    setProperty('${_browserPrefix}mask-position', value, '');
  }

  /** Gets the value of "mask-position-x" */
  String get maskPositionX =>
    getPropertyValue('${_browserPrefix}mask-position-x');

  /** Sets the value of "mask-position-x" */
  void set maskPositionX(var value) {
    setProperty('${_browserPrefix}mask-position-x', value, '');
  }

  /** Gets the value of "mask-position-y" */
  String get maskPositionY =>
    getPropertyValue('${_browserPrefix}mask-position-y');

  /** Sets the value of "mask-position-y" */
  void set maskPositionY(var value) {
    setProperty('${_browserPrefix}mask-position-y', value, '');
  }

  /** Gets the value of "mask-repeat" */
  String get maskRepeat =>
    getPropertyValue('${_browserPrefix}mask-repeat');

  /** Sets the value of "mask-repeat" */
  void set maskRepeat(var value) {
    setProperty('${_browserPrefix}mask-repeat', value, '');
  }

  /** Gets the value of "mask-repeat-x" */
  String get maskRepeatX =>
    getPropertyValue('${_browserPrefix}mask-repeat-x');

  /** Sets the value of "mask-repeat-x" */
  void set maskRepeatX(var value) {
    setProperty('${_browserPrefix}mask-repeat-x', value, '');
  }

  /** Gets the value of "mask-repeat-y" */
  String get maskRepeatY =>
    getPropertyValue('${_browserPrefix}mask-repeat-y');

  /** Sets the value of "mask-repeat-y" */
  void set maskRepeatY(var value) {
    setProperty('${_browserPrefix}mask-repeat-y', value, '');
  }

  /** Gets the value of "mask-size" */
  String get maskSize =>
    getPropertyValue('${_browserPrefix}mask-size');

  /** Sets the value of "mask-size" */
  void set maskSize(var value) {
    setProperty('${_browserPrefix}mask-size', value, '');
  }

  /** Gets the value of "match-nearest-mail-blockquote-color" */
  String get matchNearestMailBlockquoteColor =>
    getPropertyValue('${_browserPrefix}match-nearest-mail-blockquote-color');

  /** Sets the value of "match-nearest-mail-blockquote-color" */
  void set matchNearestMailBlockquoteColor(var value) {
    setProperty('${_browserPrefix}match-nearest-mail-blockquote-color', value, '');
  }

  /** Gets the value of "max-height" */
  String get maxHeight =>
    getPropertyValue('max-height');

  /** Sets the value of "max-height" */
  void set maxHeight(var value) {
    setProperty('max-height', value, '');
  }

  /** Gets the value of "max-logical-height" */
  String get maxLogicalHeight =>
    getPropertyValue('${_browserPrefix}max-logical-height');

  /** Sets the value of "max-logical-height" */
  void set maxLogicalHeight(var value) {
    setProperty('${_browserPrefix}max-logical-height', value, '');
  }

  /** Gets the value of "max-logical-width" */
  String get maxLogicalWidth =>
    getPropertyValue('${_browserPrefix}max-logical-width');

  /** Sets the value of "max-logical-width" */
  void set maxLogicalWidth(var value) {
    setProperty('${_browserPrefix}max-logical-width', value, '');
  }

  /** Gets the value of "max-width" */
  String get maxWidth =>
    getPropertyValue('max-width');

  /** Sets the value of "max-width" */
  void set maxWidth(var value) {
    setProperty('max-width', value, '');
  }

  /** Gets the value of "min-height" */
  String get minHeight =>
    getPropertyValue('min-height');

  /** Sets the value of "min-height" */
  void set minHeight(var value) {
    setProperty('min-height', value, '');
  }

  /** Gets the value of "min-logical-height" */
  String get minLogicalHeight =>
    getPropertyValue('${_browserPrefix}min-logical-height');

  /** Sets the value of "min-logical-height" */
  void set minLogicalHeight(var value) {
    setProperty('${_browserPrefix}min-logical-height', value, '');
  }

  /** Gets the value of "min-logical-width" */
  String get minLogicalWidth =>
    getPropertyValue('${_browserPrefix}min-logical-width');

  /** Sets the value of "min-logical-width" */
  void set minLogicalWidth(var value) {
    setProperty('${_browserPrefix}min-logical-width', value, '');
  }

  /** Gets the value of "min-width" */
  String get minWidth =>
    getPropertyValue('min-width');

  /** Sets the value of "min-width" */
  void set minWidth(var value) {
    setProperty('min-width', value, '');
  }

  /** Gets the value of "nbsp-mode" */
  String get nbspMode =>
    getPropertyValue('${_browserPrefix}nbsp-mode');

  /** Sets the value of "nbsp-mode" */
  void set nbspMode(var value) {
    setProperty('${_browserPrefix}nbsp-mode', value, '');
  }

  /** Gets the value of "opacity" */
  String get opacity =>
    getPropertyValue('opacity');

  /** Sets the value of "opacity" */
  void set opacity(var value) {
    setProperty('opacity', value, '');
  }

  /** Gets the value of "orphans" */
  String get orphans =>
    getPropertyValue('orphans');

  /** Sets the value of "orphans" */
  void set orphans(var value) {
    setProperty('orphans', value, '');
  }

  /** Gets the value of "outline" */
  String get outline =>
    getPropertyValue('outline');

  /** Sets the value of "outline" */
  void set outline(var value) {
    setProperty('outline', value, '');
  }

  /** Gets the value of "outline-color" */
  String get outlineColor =>
    getPropertyValue('outline-color');

  /** Sets the value of "outline-color" */
  void set outlineColor(var value) {
    setProperty('outline-color', value, '');
  }

  /** Gets the value of "outline-offset" */
  String get outlineOffset =>
    getPropertyValue('outline-offset');

  /** Sets the value of "outline-offset" */
  void set outlineOffset(var value) {
    setProperty('outline-offset', value, '');
  }

  /** Gets the value of "outline-style" */
  String get outlineStyle =>
    getPropertyValue('outline-style');

  /** Sets the value of "outline-style" */
  void set outlineStyle(var value) {
    setProperty('outline-style', value, '');
  }

  /** Gets the value of "outline-width" */
  String get outlineWidth =>
    getPropertyValue('outline-width');

  /** Sets the value of "outline-width" */
  void set outlineWidth(var value) {
    setProperty('outline-width', value, '');
  }

  /** Gets the value of "overflow" */
  String get overflow =>
    getPropertyValue('overflow');

  /** Sets the value of "overflow" */
  void set overflow(var value) {
    setProperty('overflow', value, '');
  }

  /** Gets the value of "overflow-x" */
  String get overflowX =>
    getPropertyValue('overflow-x');

  /** Sets the value of "overflow-x" */
  void set overflowX(var value) {
    setProperty('overflow-x', value, '');
  }

  /** Gets the value of "overflow-y" */
  String get overflowY =>
    getPropertyValue('overflow-y');

  /** Sets the value of "overflow-y" */
  void set overflowY(var value) {
    setProperty('overflow-y', value, '');
  }

  /** Gets the value of "padding" */
  String get padding =>
    getPropertyValue('padding');

  /** Sets the value of "padding" */
  void set padding(var value) {
    setProperty('padding', value, '');
  }

  /** Gets the value of "padding-after" */
  String get paddingAfter =>
    getPropertyValue('${_browserPrefix}padding-after');

  /** Sets the value of "padding-after" */
  void set paddingAfter(var value) {
    setProperty('${_browserPrefix}padding-after', value, '');
  }

  /** Gets the value of "padding-before" */
  String get paddingBefore =>
    getPropertyValue('${_browserPrefix}padding-before');

  /** Sets the value of "padding-before" */
  void set paddingBefore(var value) {
    setProperty('${_browserPrefix}padding-before', value, '');
  }

  /** Gets the value of "padding-bottom" */
  String get paddingBottom =>
    getPropertyValue('padding-bottom');

  /** Sets the value of "padding-bottom" */
  void set paddingBottom(var value) {
    setProperty('padding-bottom', value, '');
  }

  /** Gets the value of "padding-end" */
  String get paddingEnd =>
    getPropertyValue('${_browserPrefix}padding-end');

  /** Sets the value of "padding-end" */
  void set paddingEnd(var value) {
    setProperty('${_browserPrefix}padding-end', value, '');
  }

  /** Gets the value of "padding-left" */
  String get paddingLeft =>
    getPropertyValue('padding-left');

  /** Sets the value of "padding-left" */
  void set paddingLeft(var value) {
    setProperty('padding-left', value, '');
  }

  /** Gets the value of "padding-right" */
  String get paddingRight =>
    getPropertyValue('padding-right');

  /** Sets the value of "padding-right" */
  void set paddingRight(var value) {
    setProperty('padding-right', value, '');
  }

  /** Gets the value of "padding-start" */
  String get paddingStart =>
    getPropertyValue('${_browserPrefix}padding-start');

  /** Sets the value of "padding-start" */
  void set paddingStart(var value) {
    setProperty('${_browserPrefix}padding-start', value, '');
  }

  /** Gets the value of "padding-top" */
  String get paddingTop =>
    getPropertyValue('padding-top');

  /** Sets the value of "padding-top" */
  void set paddingTop(var value) {
    setProperty('padding-top', value, '');
  }

  /** Gets the value of "page" */
  String get page =>
    getPropertyValue('page');

  /** Sets the value of "page" */
  void set page(var value) {
    setProperty('page', value, '');
  }

  /** Gets the value of "page-break-after" */
  String get pageBreakAfter =>
    getPropertyValue('page-break-after');

  /** Sets the value of "page-break-after" */
  void set pageBreakAfter(var value) {
    setProperty('page-break-after', value, '');
  }

  /** Gets the value of "page-break-before" */
  String get pageBreakBefore =>
    getPropertyValue('page-break-before');

  /** Sets the value of "page-break-before" */
  void set pageBreakBefore(var value) {
    setProperty('page-break-before', value, '');
  }

  /** Gets the value of "page-break-inside" */
  String get pageBreakInside =>
    getPropertyValue('page-break-inside');

  /** Sets the value of "page-break-inside" */
  void set pageBreakInside(var value) {
    setProperty('page-break-inside', value, '');
  }

  /** Gets the value of "perspective" */
  String get perspective =>
    getPropertyValue('${_browserPrefix}perspective');

  /** Sets the value of "perspective" */
  void set perspective(var value) {
    setProperty('${_browserPrefix}perspective', value, '');
  }

  /** Gets the value of "perspective-origin" */
  String get perspectiveOrigin =>
    getPropertyValue('${_browserPrefix}perspective-origin');

  /** Sets the value of "perspective-origin" */
  void set perspectiveOrigin(var value) {
    setProperty('${_browserPrefix}perspective-origin', value, '');
  }

  /** Gets the value of "perspective-origin-x" */
  String get perspectiveOriginX =>
    getPropertyValue('${_browserPrefix}perspective-origin-x');

  /** Sets the value of "perspective-origin-x" */
  void set perspectiveOriginX(var value) {
    setProperty('${_browserPrefix}perspective-origin-x', value, '');
  }

  /** Gets the value of "perspective-origin-y" */
  String get perspectiveOriginY =>
    getPropertyValue('${_browserPrefix}perspective-origin-y');

  /** Sets the value of "perspective-origin-y" */
  void set perspectiveOriginY(var value) {
    setProperty('${_browserPrefix}perspective-origin-y', value, '');
  }

  /** Gets the value of "pointer-events" */
  String get pointerEvents =>
    getPropertyValue('pointer-events');

  /** Sets the value of "pointer-events" */
  void set pointerEvents(var value) {
    setProperty('pointer-events', value, '');
  }

  /** Gets the value of "position" */
  String get position =>
    getPropertyValue('position');

  /** Sets the value of "position" */
  void set position(var value) {
    setProperty('position', value, '');
  }

  /** Gets the value of "quotes" */
  String get quotes =>
    getPropertyValue('quotes');

  /** Sets the value of "quotes" */
  void set quotes(var value) {
    setProperty('quotes', value, '');
  }

  /** Gets the value of "region-break-after" */
  String get regionBreakAfter =>
    getPropertyValue('${_browserPrefix}region-break-after');

  /** Sets the value of "region-break-after" */
  void set regionBreakAfter(var value) {
    setProperty('${_browserPrefix}region-break-after', value, '');
  }

  /** Gets the value of "region-break-before" */
  String get regionBreakBefore =>
    getPropertyValue('${_browserPrefix}region-break-before');

  /** Sets the value of "region-break-before" */
  void set regionBreakBefore(var value) {
    setProperty('${_browserPrefix}region-break-before', value, '');
  }

  /** Gets the value of "region-break-inside" */
  String get regionBreakInside =>
    getPropertyValue('${_browserPrefix}region-break-inside');

  /** Sets the value of "region-break-inside" */
  void set regionBreakInside(var value) {
    setProperty('${_browserPrefix}region-break-inside', value, '');
  }

  /** Gets the value of "region-overflow" */
  String get regionOverflow =>
    getPropertyValue('${_browserPrefix}region-overflow');

  /** Sets the value of "region-overflow" */
  void set regionOverflow(var value) {
    setProperty('${_browserPrefix}region-overflow', value, '');
  }

  /** Gets the value of "resize" */
  String get resize =>
    getPropertyValue('resize');

  /** Sets the value of "resize" */
  void set resize(var value) {
    setProperty('resize', value, '');
  }

  /** Gets the value of "right" */
  String get right =>
    getPropertyValue('right');

  /** Sets the value of "right" */
  void set right(var value) {
    setProperty('right', value, '');
  }

  /** Gets the value of "rtl-ordering" */
  String get rtlOrdering =>
    getPropertyValue('${_browserPrefix}rtl-ordering');

  /** Sets the value of "rtl-ordering" */
  void set rtlOrdering(var value) {
    setProperty('${_browserPrefix}rtl-ordering', value, '');
  }

  /** Gets the value of "size" */
  String get size =>
    getPropertyValue('size');

  /** Sets the value of "size" */
  void set size(var value) {
    setProperty('size', value, '');
  }

  /** Gets the value of "speak" */
  String get speak =>
    getPropertyValue('speak');

  /** Sets the value of "speak" */
  void set speak(var value) {
    setProperty('speak', value, '');
  }

  /** Gets the value of "src" */
  String get src =>
    getPropertyValue('src');

  /** Sets the value of "src" */
  void set src(var value) {
    setProperty('src', value, '');
  }

  /** Gets the value of "table-layout" */
  String get tableLayout =>
    getPropertyValue('table-layout');

  /** Sets the value of "table-layout" */
  void set tableLayout(var value) {
    setProperty('table-layout', value, '');
  }

  /** Gets the value of "tap-highlight-color" */
  String get tapHighlightColor =>
    getPropertyValue('${_browserPrefix}tap-highlight-color');

  /** Sets the value of "tap-highlight-color" */
  void set tapHighlightColor(var value) {
    setProperty('${_browserPrefix}tap-highlight-color', value, '');
  }

  /** Gets the value of "text-align" */
  String get textAlign =>
    getPropertyValue('text-align');

  /** Sets the value of "text-align" */
  void set textAlign(var value) {
    setProperty('text-align', value, '');
  }

  /** Gets the value of "text-combine" */
  String get textCombine =>
    getPropertyValue('${_browserPrefix}text-combine');

  /** Sets the value of "text-combine" */
  void set textCombine(var value) {
    setProperty('${_browserPrefix}text-combine', value, '');
  }

  /** Gets the value of "text-decoration" */
  String get textDecoration =>
    getPropertyValue('text-decoration');

  /** Sets the value of "text-decoration" */
  void set textDecoration(var value) {
    setProperty('text-decoration', value, '');
  }

  /** Gets the value of "text-decorations-in-effect" */
  String get textDecorationsInEffect =>
    getPropertyValue('${_browserPrefix}text-decorations-in-effect');

  /** Sets the value of "text-decorations-in-effect" */
  void set textDecorationsInEffect(var value) {
    setProperty('${_browserPrefix}text-decorations-in-effect', value, '');
  }

  /** Gets the value of "text-emphasis" */
  String get textEmphasis =>
    getPropertyValue('${_browserPrefix}text-emphasis');

  /** Sets the value of "text-emphasis" */
  void set textEmphasis(var value) {
    setProperty('${_browserPrefix}text-emphasis', value, '');
  }

  /** Gets the value of "text-emphasis-color" */
  String get textEmphasisColor =>
    getPropertyValue('${_browserPrefix}text-emphasis-color');

  /** Sets the value of "text-emphasis-color" */
  void set textEmphasisColor(var value) {
    setProperty('${_browserPrefix}text-emphasis-color', value, '');
  }

  /** Gets the value of "text-emphasis-position" */
  String get textEmphasisPosition =>
    getPropertyValue('${_browserPrefix}text-emphasis-position');

  /** Sets the value of "text-emphasis-position" */
  void set textEmphasisPosition(var value) {
    setProperty('${_browserPrefix}text-emphasis-position', value, '');
  }

  /** Gets the value of "text-emphasis-style" */
  String get textEmphasisStyle =>
    getPropertyValue('${_browserPrefix}text-emphasis-style');

  /** Sets the value of "text-emphasis-style" */
  void set textEmphasisStyle(var value) {
    setProperty('${_browserPrefix}text-emphasis-style', value, '');
  }

  /** Gets the value of "text-fill-color" */
  String get textFillColor =>
    getPropertyValue('${_browserPrefix}text-fill-color');

  /** Sets the value of "text-fill-color" */
  void set textFillColor(var value) {
    setProperty('${_browserPrefix}text-fill-color', value, '');
  }

  /** Gets the value of "text-indent" */
  String get textIndent =>
    getPropertyValue('text-indent');

  /** Sets the value of "text-indent" */
  void set textIndent(var value) {
    setProperty('text-indent', value, '');
  }

  /** Gets the value of "text-line-through" */
  String get textLineThrough =>
    getPropertyValue('text-line-through');

  /** Sets the value of "text-line-through" */
  void set textLineThrough(var value) {
    setProperty('text-line-through', value, '');
  }

  /** Gets the value of "text-line-through-color" */
  String get textLineThroughColor =>
    getPropertyValue('text-line-through-color');

  /** Sets the value of "text-line-through-color" */
  void set textLineThroughColor(var value) {
    setProperty('text-line-through-color', value, '');
  }

  /** Gets the value of "text-line-through-mode" */
  String get textLineThroughMode =>
    getPropertyValue('text-line-through-mode');

  /** Sets the value of "text-line-through-mode" */
  void set textLineThroughMode(var value) {
    setProperty('text-line-through-mode', value, '');
  }

  /** Gets the value of "text-line-through-style" */
  String get textLineThroughStyle =>
    getPropertyValue('text-line-through-style');

  /** Sets the value of "text-line-through-style" */
  void set textLineThroughStyle(var value) {
    setProperty('text-line-through-style', value, '');
  }

  /** Gets the value of "text-line-through-width" */
  String get textLineThroughWidth =>
    getPropertyValue('text-line-through-width');

  /** Sets the value of "text-line-through-width" */
  void set textLineThroughWidth(var value) {
    setProperty('text-line-through-width', value, '');
  }

  /** Gets the value of "text-orientation" */
  String get textOrientation =>
    getPropertyValue('${_browserPrefix}text-orientation');

  /** Sets the value of "text-orientation" */
  void set textOrientation(var value) {
    setProperty('${_browserPrefix}text-orientation', value, '');
  }

  /** Gets the value of "text-overflow" */
  String get textOverflow =>
    getPropertyValue('text-overflow');

  /** Sets the value of "text-overflow" */
  void set textOverflow(var value) {
    setProperty('text-overflow', value, '');
  }

  /** Gets the value of "text-overline" */
  String get textOverline =>
    getPropertyValue('text-overline');

  /** Sets the value of "text-overline" */
  void set textOverline(var value) {
    setProperty('text-overline', value, '');
  }

  /** Gets the value of "text-overline-color" */
  String get textOverlineColor =>
    getPropertyValue('text-overline-color');

  /** Sets the value of "text-overline-color" */
  void set textOverlineColor(var value) {
    setProperty('text-overline-color', value, '');
  }

  /** Gets the value of "text-overline-mode" */
  String get textOverlineMode =>
    getPropertyValue('text-overline-mode');

  /** Sets the value of "text-overline-mode" */
  void set textOverlineMode(var value) {
    setProperty('text-overline-mode', value, '');
  }

  /** Gets the value of "text-overline-style" */
  String get textOverlineStyle =>
    getPropertyValue('text-overline-style');

  /** Sets the value of "text-overline-style" */
  void set textOverlineStyle(var value) {
    setProperty('text-overline-style', value, '');
  }

  /** Gets the value of "text-overline-width" */
  String get textOverlineWidth =>
    getPropertyValue('text-overline-width');

  /** Sets the value of "text-overline-width" */
  void set textOverlineWidth(var value) {
    setProperty('text-overline-width', value, '');
  }

  /** Gets the value of "text-rendering" */
  String get textRendering =>
    getPropertyValue('text-rendering');

  /** Sets the value of "text-rendering" */
  void set textRendering(var value) {
    setProperty('text-rendering', value, '');
  }

  /** Gets the value of "text-security" */
  String get textSecurity =>
    getPropertyValue('${_browserPrefix}text-security');

  /** Sets the value of "text-security" */
  void set textSecurity(var value) {
    setProperty('${_browserPrefix}text-security', value, '');
  }

  /** Gets the value of "text-shadow" */
  String get textShadow =>
    getPropertyValue('text-shadow');

  /** Sets the value of "text-shadow" */
  void set textShadow(var value) {
    setProperty('text-shadow', value, '');
  }

  /** Gets the value of "text-size-adjust" */
  String get textSizeAdjust =>
    getPropertyValue('${_browserPrefix}text-size-adjust');

  /** Sets the value of "text-size-adjust" */
  void set textSizeAdjust(var value) {
    setProperty('${_browserPrefix}text-size-adjust', value, '');
  }

  /** Gets the value of "text-stroke" */
  String get textStroke =>
    getPropertyValue('${_browserPrefix}text-stroke');

  /** Sets the value of "text-stroke" */
  void set textStroke(var value) {
    setProperty('${_browserPrefix}text-stroke', value, '');
  }

  /** Gets the value of "text-stroke-color" */
  String get textStrokeColor =>
    getPropertyValue('${_browserPrefix}text-stroke-color');

  /** Sets the value of "text-stroke-color" */
  void set textStrokeColor(var value) {
    setProperty('${_browserPrefix}text-stroke-color', value, '');
  }

  /** Gets the value of "text-stroke-width" */
  String get textStrokeWidth =>
    getPropertyValue('${_browserPrefix}text-stroke-width');

  /** Sets the value of "text-stroke-width" */
  void set textStrokeWidth(var value) {
    setProperty('${_browserPrefix}text-stroke-width', value, '');
  }

  /** Gets the value of "text-transform" */
  String get textTransform =>
    getPropertyValue('text-transform');

  /** Sets the value of "text-transform" */
  void set textTransform(var value) {
    setProperty('text-transform', value, '');
  }

  /** Gets the value of "text-underline" */
  String get textUnderline =>
    getPropertyValue('text-underline');

  /** Sets the value of "text-underline" */
  void set textUnderline(var value) {
    setProperty('text-underline', value, '');
  }

  /** Gets the value of "text-underline-color" */
  String get textUnderlineColor =>
    getPropertyValue('text-underline-color');

  /** Sets the value of "text-underline-color" */
  void set textUnderlineColor(var value) {
    setProperty('text-underline-color', value, '');
  }

  /** Gets the value of "text-underline-mode" */
  String get textUnderlineMode =>
    getPropertyValue('text-underline-mode');

  /** Sets the value of "text-underline-mode" */
  void set textUnderlineMode(var value) {
    setProperty('text-underline-mode', value, '');
  }

  /** Gets the value of "text-underline-style" */
  String get textUnderlineStyle =>
    getPropertyValue('text-underline-style');

  /** Sets the value of "text-underline-style" */
  void set textUnderlineStyle(var value) {
    setProperty('text-underline-style', value, '');
  }

  /** Gets the value of "text-underline-width" */
  String get textUnderlineWidth =>
    getPropertyValue('text-underline-width');

  /** Sets the value of "text-underline-width" */
  void set textUnderlineWidth(var value) {
    setProperty('text-underline-width', value, '');
  }

  /** Gets the value of "top" */
  String get top =>
    getPropertyValue('top');

  /** Sets the value of "top" */
  void set top(var value) {
    setProperty('top', value, '');
  }

  /** Gets the value of "transform" */
  String get transform =>
    getPropertyValue('${_browserPrefix}transform');

  /** Sets the value of "transform" */
  void set transform(var value) {
    setProperty('${_browserPrefix}transform', value, '');
  }

  /** Gets the value of "transform-origin" */
  String get transformOrigin =>
    getPropertyValue('${_browserPrefix}transform-origin');

  /** Sets the value of "transform-origin" */
  void set transformOrigin(var value) {
    setProperty('${_browserPrefix}transform-origin', value, '');
  }

  /** Gets the value of "transform-origin-x" */
  String get transformOriginX =>
    getPropertyValue('${_browserPrefix}transform-origin-x');

  /** Sets the value of "transform-origin-x" */
  void set transformOriginX(var value) {
    setProperty('${_browserPrefix}transform-origin-x', value, '');
  }

  /** Gets the value of "transform-origin-y" */
  String get transformOriginY =>
    getPropertyValue('${_browserPrefix}transform-origin-y');

  /** Sets the value of "transform-origin-y" */
  void set transformOriginY(var value) {
    setProperty('${_browserPrefix}transform-origin-y', value, '');
  }

  /** Gets the value of "transform-origin-z" */
  String get transformOriginZ =>
    getPropertyValue('${_browserPrefix}transform-origin-z');

  /** Sets the value of "transform-origin-z" */
  void set transformOriginZ(var value) {
    setProperty('${_browserPrefix}transform-origin-z', value, '');
  }

  /** Gets the value of "transform-style" */
  String get transformStyle =>
    getPropertyValue('${_browserPrefix}transform-style');

  /** Sets the value of "transform-style" */
  void set transformStyle(var value) {
    setProperty('${_browserPrefix}transform-style', value, '');
  }

  /** Gets the value of "transition" */
  String get transition =>
    getPropertyValue('${_browserPrefix}transition');

  /** Sets the value of "transition" */
  void set transition(var value) {
    setProperty('${_browserPrefix}transition', value, '');
  }

  /** Gets the value of "transition-delay" */
  String get transitionDelay =>
    getPropertyValue('${_browserPrefix}transition-delay');

  /** Sets the value of "transition-delay" */
  void set transitionDelay(var value) {
    setProperty('${_browserPrefix}transition-delay', value, '');
  }

  /** Gets the value of "transition-duration" */
  String get transitionDuration =>
    getPropertyValue('${_browserPrefix}transition-duration');

  /** Sets the value of "transition-duration" */
  void set transitionDuration(var value) {
    setProperty('${_browserPrefix}transition-duration', value, '');
  }

  /** Gets the value of "transition-property" */
  String get transitionProperty =>
    getPropertyValue('${_browserPrefix}transition-property');

  /** Sets the value of "transition-property" */
  void set transitionProperty(var value) {
    setProperty('${_browserPrefix}transition-property', value, '');
  }

  /** Gets the value of "transition-timing-function" */
  String get transitionTimingFunction =>
    getPropertyValue('${_browserPrefix}transition-timing-function');

  /** Sets the value of "transition-timing-function" */
  void set transitionTimingFunction(var value) {
    setProperty('${_browserPrefix}transition-timing-function', value, '');
  }

  /** Gets the value of "unicode-bidi" */
  String get unicodeBidi =>
    getPropertyValue('unicode-bidi');

  /** Sets the value of "unicode-bidi" */
  void set unicodeBidi(var value) {
    setProperty('unicode-bidi', value, '');
  }

  /** Gets the value of "unicode-range" */
  String get unicodeRange =>
    getPropertyValue('unicode-range');

  /** Sets the value of "unicode-range" */
  void set unicodeRange(var value) {
    setProperty('unicode-range', value, '');
  }

  /** Gets the value of "user-drag" */
  String get userDrag =>
    getPropertyValue('${_browserPrefix}user-drag');

  /** Sets the value of "user-drag" */
  void set userDrag(var value) {
    setProperty('${_browserPrefix}user-drag', value, '');
  }

  /** Gets the value of "user-modify" */
  String get userModify =>
    getPropertyValue('${_browserPrefix}user-modify');

  /** Sets the value of "user-modify" */
  void set userModify(var value) {
    setProperty('${_browserPrefix}user-modify', value, '');
  }

  /** Gets the value of "user-select" */
  String get userSelect =>
    getPropertyValue('${_browserPrefix}user-select');

  /** Sets the value of "user-select" */
  void set userSelect(var value) {
    setProperty('${_browserPrefix}user-select', value, '');
  }

  /** Gets the value of "vertical-align" */
  String get verticalAlign =>
    getPropertyValue('vertical-align');

  /** Sets the value of "vertical-align" */
  void set verticalAlign(var value) {
    setProperty('vertical-align', value, '');
  }

  /** Gets the value of "visibility" */
  String get visibility =>
    getPropertyValue('visibility');

  /** Sets the value of "visibility" */
  void set visibility(var value) {
    setProperty('visibility', value, '');
  }

  /** Gets the value of "white-space" */
  String get whiteSpace =>
    getPropertyValue('white-space');

  /** Sets the value of "white-space" */
  void set whiteSpace(var value) {
    setProperty('white-space', value, '');
  }

  /** Gets the value of "widows" */
  String get widows =>
    getPropertyValue('widows');

  /** Sets the value of "widows" */
  void set widows(var value) {
    setProperty('widows', value, '');
  }

  /** Gets the value of "width" */
  String get width =>
    getPropertyValue('width');

  /** Sets the value of "width" */
  void set width(var value) {
    setProperty('width', value, '');
  }

  /** Gets the value of "word-break" */
  String get wordBreak =>
    getPropertyValue('word-break');

  /** Sets the value of "word-break" */
  void set wordBreak(var value) {
    setProperty('word-break', value, '');
  }

  /** Gets the value of "word-spacing" */
  String get wordSpacing =>
    getPropertyValue('word-spacing');

  /** Sets the value of "word-spacing" */
  void set wordSpacing(var value) {
    setProperty('word-spacing', value, '');
  }

  /** Gets the value of "word-wrap" */
  String get wordWrap =>
    getPropertyValue('word-wrap');

  /** Sets the value of "word-wrap" */
  void set wordWrap(var value) {
    setProperty('word-wrap', value, '');
  }

  /** Gets the value of "wrap-shape" */
  String get wrapShape =>
    getPropertyValue('${_browserPrefix}wrap-shape');

  /** Sets the value of "wrap-shape" */
  void set wrapShape(var value) {
    setProperty('${_browserPrefix}wrap-shape', value, '');
  }

  /** Gets the value of "writing-mode" */
  String get writingMode =>
    getPropertyValue('${_browserPrefix}writing-mode');

  /** Sets the value of "writing-mode" */
  void set writingMode(var value) {
    setProperty('${_browserPrefix}writing-mode', value, '');
  }

  /** Gets the value of "z-index" */
  String get zIndex =>
    getPropertyValue('z-index');

  /** Sets the value of "z-index" */
  void set zIndex(var value) {
    setProperty('z-index', value, '');
  }

  /** Gets the value of "zoom" */
  String get zoom =>
    getPropertyValue('zoom');

  /** Sets the value of "zoom" */
  void set zoom(var value) {
    setProperty('zoom', value, '');
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName CSSStyleRule
class CSSStyleRule extends CSSRule native "*CSSStyleRule" {

  /** @domName CSSStyleRule.selectorText */
  String selectorText;

  /** @domName CSSStyleRule.style */
  final CSSStyleDeclaration style;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName CSSStyleSheet
class CSSStyleSheet extends StyleSheet native "*CSSStyleSheet" {

  /** @domName CSSStyleSheet.cssRules */
  final List<CSSRule> cssRules;

  /** @domName CSSStyleSheet.ownerRule */
  final CSSRule ownerRule;

  /** @domName CSSStyleSheet.rules */
  final List<CSSRule> rules;

  /** @domName CSSStyleSheet.addRule */
  int addRule(String selector, String style, [int index]) native;

  /** @domName CSSStyleSheet.deleteRule */
  void deleteRule(int index) native;

  /** @domName CSSStyleSheet.insertRule */
  int insertRule(String rule, int index) native;

  /** @domName CSSStyleSheet.removeRule */
  void removeRule(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WebKitCSSTransformValue
class CSSTransformValue extends _CSSValueList native "*WebKitCSSTransformValue" {

  static const int CSS_MATRIX = 11;

  static const int CSS_MATRIX3D = 21;

  static const int CSS_PERSPECTIVE = 20;

  static const int CSS_ROTATE = 4;

  static const int CSS_ROTATE3D = 17;

  static const int CSS_ROTATEX = 14;

  static const int CSS_ROTATEY = 15;

  static const int CSS_ROTATEZ = 16;

  static const int CSS_SCALE = 5;

  static const int CSS_SCALE3D = 19;

  static const int CSS_SCALEX = 6;

  static const int CSS_SCALEY = 7;

  static const int CSS_SCALEZ = 18;

  static const int CSS_SKEW = 8;

  static const int CSS_SKEWX = 9;

  static const int CSS_SKEWY = 10;

  static const int CSS_TRANSLATE = 1;

  static const int CSS_TRANSLATE3D = 13;

  static const int CSS_TRANSLATEX = 2;

  static const int CSS_TRANSLATEY = 3;

  static const int CSS_TRANSLATEZ = 12;

  /** @domName WebKitCSSTransformValue.operationType */
  final int operationType;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName CSSUnknownRule
class CSSUnknownRule extends CSSRule native "*CSSUnknownRule" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName CSSValue
class CSSValue native "*CSSValue" {

  static const int CSS_CUSTOM = 3;

  static const int CSS_INHERIT = 0;

  static const int CSS_PRIMITIVE_VALUE = 1;

  static const int CSS_VALUE_LIST = 2;

  /** @domName CSSValue.cssText */
  String cssText;

  /** @domName CSSValue.cssValueType */
  final int cssValueType;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class CanvasElement extends Element implements Element native "*HTMLCanvasElement" {

  factory CanvasElement({int width, int height}) {
    if (!?width) {
      return _Elements.createCanvasElement();
    }
    if (!?height) {
      return _Elements.createCanvasElement(width);
    }
    return _Elements.createCanvasElement(width, height);
  }

  /** @domName HTMLCanvasElement.height */
  int height;

  /** @domName HTMLCanvasElement.width */
  int width;

  /** @domName HTMLCanvasElement.toDataURL */
  String toDataURL(String type, [num quality]) native;


  CanvasRenderingContext getContext(String contextId) native;
  CanvasRenderingContext2D get context2d => getContext('2d');
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName CanvasGradient
class CanvasGradient native "*CanvasGradient" {

  /** @domName CanvasGradient.addColorStop */
  void addColorStop(num offset, String color) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName CanvasPattern
class CanvasPattern native "*CanvasPattern" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName CanvasRenderingContext
class CanvasRenderingContext native "*CanvasRenderingContext" {

  /** @domName CanvasRenderingContext.canvas */
  final CanvasElement canvas;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class CanvasRenderingContext2D extends CanvasRenderingContext native "*CanvasRenderingContext2D" {

  /** @domName CanvasRenderingContext2D.fillStyle */
  dynamic fillStyle;

  /** @domName CanvasRenderingContext2D.font */
  String font;

  /** @domName CanvasRenderingContext2D.globalAlpha */
  num globalAlpha;

  /** @domName CanvasRenderingContext2D.globalCompositeOperation */
  String globalCompositeOperation;

  /** @domName CanvasRenderingContext2D.lineCap */
  String lineCap;

  /** @domName CanvasRenderingContext2D.lineDashOffset */
  num lineDashOffset;

  /** @domName CanvasRenderingContext2D.lineJoin */
  String lineJoin;

  /** @domName CanvasRenderingContext2D.lineWidth */
  num lineWidth;

  /** @domName CanvasRenderingContext2D.miterLimit */
  num miterLimit;

  /** @domName CanvasRenderingContext2D.shadowBlur */
  num shadowBlur;

  /** @domName CanvasRenderingContext2D.shadowColor */
  String shadowColor;

  /** @domName CanvasRenderingContext2D.shadowOffsetX */
  num shadowOffsetX;

  /** @domName CanvasRenderingContext2D.shadowOffsetY */
  num shadowOffsetY;

  /** @domName CanvasRenderingContext2D.strokeStyle */
  dynamic strokeStyle;

  /** @domName CanvasRenderingContext2D.textAlign */
  String textAlign;

  /** @domName CanvasRenderingContext2D.textBaseline */
  String textBaseline;

  /** @domName CanvasRenderingContext2D.webkitBackingStorePixelRatio */
  final num webkitBackingStorePixelRatio;

  /** @domName CanvasRenderingContext2D.webkitImageSmoothingEnabled */
  bool webkitImageSmoothingEnabled;

  /** @domName CanvasRenderingContext2D.webkitLineDash */
  List webkitLineDash;

  /** @domName CanvasRenderingContext2D.webkitLineDashOffset */
  num webkitLineDashOffset;

  /** @domName CanvasRenderingContext2D.arc */
  void arc(num x, num y, num radius, num startAngle, num endAngle, bool anticlockwise) native;

  /** @domName CanvasRenderingContext2D.arcTo */
  void arcTo(num x1, num y1, num x2, num y2, num radius) native;

  /** @domName CanvasRenderingContext2D.beginPath */
  void beginPath() native;

  /** @domName CanvasRenderingContext2D.bezierCurveTo */
  void bezierCurveTo(num cp1x, num cp1y, num cp2x, num cp2y, num x, num y) native;

  /** @domName CanvasRenderingContext2D.clearRect */
  void clearRect(num x, num y, num width, num height) native;

  /** @domName CanvasRenderingContext2D.clearShadow */
  void clearShadow() native;

  /** @domName CanvasRenderingContext2D.clip */
  void clip() native;

  /** @domName CanvasRenderingContext2D.closePath */
  void closePath() native;

  /** @domName CanvasRenderingContext2D.createImageData */
  ImageData createImageData(imagedata_OR_sw, [num sh]) {
    if ((?imagedata_OR_sw && (imagedata_OR_sw is ImageData || imagedata_OR_sw == null)) &&
        !?sh) {
      var imagedata_1 = _convertDartToNative_ImageData(imagedata_OR_sw);
      return _convertNativeToDart_ImageData(_createImageData_1(imagedata_1));
    }
    if ((?imagedata_OR_sw && (imagedata_OR_sw is num || imagedata_OR_sw == null))) {
      return _convertNativeToDart_ImageData(_createImageData_2(imagedata_OR_sw, sh));
    }
    throw const Exception("Incorrect number or type of arguments");
  }
  _createImageData_1(imagedata) native "createImageData";
  _createImageData_2(num sw, sh) native "createImageData";

  /** @domName CanvasRenderingContext2D.createLinearGradient */
  CanvasGradient createLinearGradient(num x0, num y0, num x1, num y1) native;

  /** @domName CanvasRenderingContext2D.createPattern */
  CanvasPattern createPattern(canvas_OR_image, String repetitionType) native;

  /** @domName CanvasRenderingContext2D.createRadialGradient */
  CanvasGradient createRadialGradient(num x0, num y0, num r0, num x1, num y1, num r1) native;

  /** @domName CanvasRenderingContext2D.drawImage */
  void drawImage(canvas_OR_image_OR_video, num sx_OR_x, num sy_OR_y, [num sw_OR_width, num height_OR_sh, num dx, num dy, num dw, num dh]) native;

  /** @domName CanvasRenderingContext2D.drawImageFromRect */
  void drawImageFromRect(ImageElement image, [num sx, num sy, num sw, num sh, num dx, num dy, num dw, num dh, String compositeOperation]) native;

  /** @domName CanvasRenderingContext2D.fill */
  void fill() native;

  /** @domName CanvasRenderingContext2D.fillRect */
  void fillRect(num x, num y, num width, num height) native;

  /** @domName CanvasRenderingContext2D.fillText */
  void fillText(String text, num x, num y, [num maxWidth]) native;

  /** @domName CanvasRenderingContext2D.getImageData */
  ImageData getImageData(num sx, num sy, num sw, num sh) {
    return _convertNativeToDart_ImageData(_getImageData_1(sx, sy, sw, sh));
  }
  _getImageData_1(sx, sy, sw, sh) native "getImageData";

  /** @domName CanvasRenderingContext2D.getLineDash */
  List<num> getLineDash() native;

  /** @domName CanvasRenderingContext2D.isPointInPath */
  bool isPointInPath(num x, num y) native;

  /** @domName CanvasRenderingContext2D.lineTo */
  void lineTo(num x, num y) native;

  /** @domName CanvasRenderingContext2D.measureText */
  TextMetrics measureText(String text) native;

  /** @domName CanvasRenderingContext2D.moveTo */
  void moveTo(num x, num y) native;

  /** @domName CanvasRenderingContext2D.putImageData */
  void putImageData(ImageData imagedata, num dx, num dy, [num dirtyX, num dirtyY, num dirtyWidth, num dirtyHeight]) {
    if (!?dirtyX &&
        !?dirtyY &&
        !?dirtyWidth &&
        !?dirtyHeight) {
      var imagedata_1 = _convertDartToNative_ImageData(imagedata);
      _putImageData_1(imagedata_1, dx, dy);
      return;
    }
    var imagedata_2 = _convertDartToNative_ImageData(imagedata);
    _putImageData_2(imagedata_2, dx, dy, dirtyX, dirtyY, dirtyWidth, dirtyHeight);
    return;
    throw const Exception("Incorrect number or type of arguments");
  }
  void _putImageData_1(imagedata, dx, dy) native "putImageData";
  void _putImageData_2(imagedata, dx, dy, dirtyX, dirtyY, dirtyWidth, dirtyHeight) native "putImageData";

  /** @domName CanvasRenderingContext2D.quadraticCurveTo */
  void quadraticCurveTo(num cpx, num cpy, num x, num y) native;

  /** @domName CanvasRenderingContext2D.rect */
  void rect(num x, num y, num width, num height) native;

  /** @domName CanvasRenderingContext2D.restore */
  void restore() native;

  /** @domName CanvasRenderingContext2D.rotate */
  void rotate(num angle) native;

  /** @domName CanvasRenderingContext2D.save */
  void save() native;

  /** @domName CanvasRenderingContext2D.scale */
  void scale(num sx, num sy) native;

  /** @domName CanvasRenderingContext2D.setAlpha */
  void setAlpha(num alpha) native;

  /** @domName CanvasRenderingContext2D.setCompositeOperation */
  void setCompositeOperation(String compositeOperation) native;

  /** @domName CanvasRenderingContext2D.setLineCap */
  void setLineCap(String cap) native;

  /** @domName CanvasRenderingContext2D.setLineDash */
  void setLineDash(List<num> dash) native;

  /** @domName CanvasRenderingContext2D.setLineJoin */
  void setLineJoin(String join) native;

  /** @domName CanvasRenderingContext2D.setLineWidth */
  void setLineWidth(num width) native;

  /** @domName CanvasRenderingContext2D.setMiterLimit */
  void setMiterLimit(num limit) native;

  /** @domName CanvasRenderingContext2D.setShadow */
  void setShadow(num width, num height, num blur, [c_OR_color_OR_grayLevel_OR_r, num alpha_OR_g_OR_m, num b_OR_y, num a_OR_k, num a]) native;

  /** @domName CanvasRenderingContext2D.setTransform */
  void setTransform(num m11, num m12, num m21, num m22, num dx, num dy) native;

  /** @domName CanvasRenderingContext2D.stroke */
  void stroke() native;

  /** @domName CanvasRenderingContext2D.strokeRect */
  void strokeRect(num x, num y, num width, num height, [num lineWidth]) native;

  /** @domName CanvasRenderingContext2D.strokeText */
  void strokeText(String text, num x, num y, [num maxWidth]) native;

  /** @domName CanvasRenderingContext2D.transform */
  void transform(num m11, num m12, num m21, num m22, num dx, num dy) native;

  /** @domName CanvasRenderingContext2D.translate */
  void translate(num tx, num ty) native;

  /** @domName CanvasRenderingContext2D.webkitGetImageDataHD */
  ImageData webkitGetImageDataHD(num sx, num sy, num sw, num sh) {
    return _convertNativeToDart_ImageData(_webkitGetImageDataHD_1(sx, sy, sw, sh));
  }
  _webkitGetImageDataHD_1(sx, sy, sw, sh) native "webkitGetImageDataHD";

  /** @domName CanvasRenderingContext2D.webkitPutImageDataHD */
  void webkitPutImageDataHD(ImageData imagedata, num dx, num dy, [num dirtyX, num dirtyY, num dirtyWidth, num dirtyHeight]) {
    if (!?dirtyX &&
        !?dirtyY &&
        !?dirtyWidth &&
        !?dirtyHeight) {
      var imagedata_1 = _convertDartToNative_ImageData(imagedata);
      _webkitPutImageDataHD_1(imagedata_1, dx, dy);
      return;
    }
    var imagedata_2 = _convertDartToNative_ImageData(imagedata);
    _webkitPutImageDataHD_2(imagedata_2, dx, dy, dirtyX, dirtyY, dirtyWidth, dirtyHeight);
    return;
    throw const Exception("Incorrect number or type of arguments");
  }
  void _webkitPutImageDataHD_1(imagedata, dx, dy) native "webkitPutImageDataHD";
  void _webkitPutImageDataHD_2(imagedata, dx, dy, dirtyX, dirtyY, dirtyWidth, dirtyHeight) native "webkitPutImageDataHD";


  /**
   * Sets the color used inside shapes.
   * [r], [g], [b] are 0-255, [a] is 0-1.
   */
  void setFillColorRgb(int r, int g, int b, [num a = 1]) {
    this.fillStyle = 'rgba($r, $g, $b, $a)';
  }

  /**
   * Sets the color used inside shapes.
   * [h] is in degrees, 0-360.
   * [s], [l] are in percent, 0-100.
   * [a] is 0-1.
   */
  void setFillColorHsl(int h, num s, num l, [num a = 1]) {
    this.fillStyle = 'hsla($h, $s%, $l%, $a)';
  }

  /**
   * Sets the color used for stroking shapes.
   * [r], [g], [b] are 0-255, [a] is 0-1.
   */
  void setStrokeColorRgb(int r, int g, int b, [num a = 1]) {
    this.strokeStyle = 'rgba($r, $g, $b, $a)';
  }

  /**
   * Sets the color used for stroking shapes.
   * [h] is in degrees, 0-360.
   * [s], [l] are in percent, 0-100.
   * [a] is 0-1.
   */
  void setStrokeColorHsl(int h, num s, num l, [num a = 1]) {
    this.strokeStyle = 'hsla($h, $s%, $l%, $a)';
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName ChannelMergerNode
class ChannelMergerNode extends AudioNode native "*ChannelMergerNode" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName ChannelSplitterNode
class ChannelSplitterNode extends AudioNode native "*ChannelSplitterNode" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName CharacterData
class CharacterData extends Node native "*CharacterData" {

  /** @domName CharacterData.data */
  String data;

  /** @domName CharacterData.length */
  final int length;

  /** @domName CharacterData.appendData */
  void appendData(String data) native;

  /** @domName CharacterData.deleteData */
  void deleteData(int offset, int length) native;

  /** @domName CharacterData.insertData */
  void insertData(int offset, String data) native;

  /** @domName CharacterData.remove */
  void remove() native;

  /** @domName CharacterData.replaceData */
  void replaceData(int offset, int length, String data) native;

  /** @domName CharacterData.substringData */
  String substringData(int offset, int length) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName ClientRect
class ClientRect native "*ClientRect" {

  /** @domName ClientRect.bottom */
  final num bottom;

  /** @domName ClientRect.height */
  final num height;

  /** @domName ClientRect.left */
  final num left;

  /** @domName ClientRect.right */
  final num right;

  /** @domName ClientRect.top */
  final num top;

  /** @domName ClientRect.width */
  final num width;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Clipboard
class Clipboard native "*Clipboard" {

  /** @domName Clipboard.dropEffect */
  String dropEffect;

  /** @domName Clipboard.effectAllowed */
  String effectAllowed;

  /** @domName Clipboard.files */
  final List<File> files;

  /** @domName Clipboard.items */
  final DataTransferItemList items;

  /** @domName Clipboard.types */
  final List types;

  /** @domName Clipboard.clearData */
  void clearData([String type]) native;

  /** @domName Clipboard.getData */
  String getData(String type) native;

  /** @domName Clipboard.setData */
  bool setData(String type, String data) native;

  /** @domName Clipboard.setDragImage */
  void setDragImage(ImageElement image, int x, int y) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName CloseEvent
class CloseEvent extends Event native "*CloseEvent" {

  /** @domName CloseEvent.code */
  final int code;

  /** @domName CloseEvent.reason */
  final String reason;

  /** @domName CloseEvent.wasClean */
  final bool wasClean;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Comment
class Comment extends CharacterData native "*Comment" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName CompositionEvent
class CompositionEvent extends UIEvent native "*CompositionEvent" {

  /** @domName CompositionEvent.data */
  final String data;

  /** @domName CompositionEvent.initCompositionEvent */
  void initCompositionEvent(String typeArg, bool canBubbleArg, bool cancelableArg, LocalWindow viewArg, String dataArg) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class Console
    // Console is sometimes a singleton bag-of-properties without a prototype.
    native "=(typeof console == 'undefined' ? {} : console)" {

  /** @domName Console.memory */
  final MemoryInfo memory;

  /** @domName Console.profiles */
  final List<ScriptProfile> profiles;

  /** @domName Console.assertCondition */
  void assertCondition(bool condition, Object arg) native;

  /** @domName Console.count */
  void count(Object arg) native;

  /** @domName Console.debug */
  void debug(Object arg) native;

  /** @domName Console.dir */
  void dir(Object arg) native;

  /** @domName Console.dirxml */
  void dirxml(Object arg) native;

  /** @domName Console.error */
  void error(Object arg) native;

  /** @domName Console.group */
  void group(Object arg) native;

  /** @domName Console.groupCollapsed */
  void groupCollapsed(Object arg) native;

  /** @domName Console.groupEnd */
  void groupEnd() native;

  /** @domName Console.info */
  void info(Object arg) native;

  /** @domName Console.log */
  void log(Object arg) native;

  /** @domName Console.markTimeline */
  void markTimeline(Object arg) native;

  /** @domName Console.profile */
  void profile(String title) native;

  /** @domName Console.profileEnd */
  void profileEnd(String title) native;

  /** @domName Console.time */
  void time(String title) native;

  /** @domName Console.timeEnd */
  void timeEnd(String title, Object arg) native;

  /** @domName Console.timeStamp */
  void timeStamp(Object arg) native;

  /** @domName Console.trace */
  void trace(Object arg) native;

  /** @domName Console.warn */
  void warn(Object arg) native;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLContentElement
class ContentElement extends Element implements Element native "*HTMLContentElement" {

  factory ContentElement() => _Elements.createContentElement();

  /** @domName HTMLContentElement.resetStyleInheritance */
  bool resetStyleInheritance;

  /** @domName HTMLContentElement.select */
  String select;

  /** @domName HTMLContentElement.getDistributedNodes */
  List<Node> getDistributedNodes() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName ConvolverNode
class ConvolverNode extends AudioNode native "*ConvolverNode" {

  /** @domName ConvolverNode.buffer */
  AudioBuffer buffer;

  /** @domName ConvolverNode.normalize */
  bool normalize;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Coordinates
class Coordinates native "*Coordinates" {

  /** @domName Coordinates.accuracy */
  final num accuracy;

  /** @domName Coordinates.altitude */
  final num altitude;

  /** @domName Coordinates.altitudeAccuracy */
  final num altitudeAccuracy;

  /** @domName Coordinates.heading */
  final num heading;

  /** @domName Coordinates.latitude */
  final num latitude;

  /** @domName Coordinates.longitude */
  final num longitude;

  /** @domName Coordinates.speed */
  final num speed;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Counter
class Counter native "*Counter" {

  /** @domName Counter.identifier */
  final String identifier;

  /** @domName Counter.listStyle */
  final String listStyle;

  /** @domName Counter.separator */
  final String separator;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Crypto
class Crypto native "*Crypto" {

  /** @domName Crypto.getRandomValues */
  void getRandomValues(ArrayBufferView array) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


class CustomEvent extends Event native "*CustomEvent" {
  factory CustomEvent(String type, [bool canBubble = true, bool cancelable = true,
      Object detail]) => _CustomEventFactoryProvider.createCustomEvent(
      type, canBubble, cancelable, detail);

  /** @domName CustomEvent.detail */
  final Object detail;

  /** @domName CustomEvent.initCustomEvent */
  void $dom_initCustomEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object detailArg) native "initCustomEvent";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLDListElement
class DListElement extends Element implements Element native "*HTMLDListElement" {

  factory DListElement() => _Elements.createDListElement();

  /** @domName HTMLDListElement.compact */
  bool compact;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName DOMApplicationCache
class DOMApplicationCache extends EventTarget native "*DOMApplicationCache" {

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  DOMApplicationCacheEvents get on =>
    new DOMApplicationCacheEvents(this);

  static const int CHECKING = 2;

  static const int DOWNLOADING = 3;

  static const int IDLE = 1;

  static const int OBSOLETE = 5;

  static const int UNCACHED = 0;

  static const int UPDATEREADY = 4;

  /** @domName DOMApplicationCache.status */
  final int status;

  /** @domName DOMApplicationCache.abort */
  void abort() native;

  /** @domName DOMApplicationCache.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "addEventListener";

  /** @domName DOMApplicationCache.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "dispatchEvent";

  /** @domName DOMApplicationCache.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "removeEventListener";

  /** @domName DOMApplicationCache.swapCache */
  void swapCache() native;

  /** @domName DOMApplicationCache.update */
  void update() native;
}

class DOMApplicationCacheEvents extends Events {
  DOMApplicationCacheEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get cached => this['cached'];

  EventListenerList get checking => this['checking'];

  EventListenerList get downloading => this['downloading'];

  EventListenerList get error => this['error'];

  EventListenerList get noUpdate => this['noupdate'];

  EventListenerList get obsolete => this['obsolete'];

  EventListenerList get progress => this['progress'];

  EventListenerList get updateReady => this['updateready'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName DOMError
class DOMError native "*DOMError" {

  /** @domName DOMError.name */
  final String name;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName DOMException
class DOMException native "*DOMException" {

  static const int ABORT_ERR = 20;

  static const int DATA_CLONE_ERR = 25;

  static const int DOMSTRING_SIZE_ERR = 2;

  static const int HIERARCHY_REQUEST_ERR = 3;

  static const int INDEX_SIZE_ERR = 1;

  static const int INUSE_ATTRIBUTE_ERR = 10;

  static const int INVALID_ACCESS_ERR = 15;

  static const int INVALID_CHARACTER_ERR = 5;

  static const int INVALID_MODIFICATION_ERR = 13;

  static const int INVALID_NODE_TYPE_ERR = 24;

  static const int INVALID_STATE_ERR = 11;

  static const int NAMESPACE_ERR = 14;

  static const int NETWORK_ERR = 19;

  static const int NOT_FOUND_ERR = 8;

  static const int NOT_SUPPORTED_ERR = 9;

  static const int NO_DATA_ALLOWED_ERR = 6;

  static const int NO_MODIFICATION_ALLOWED_ERR = 7;

  static const int QUOTA_EXCEEDED_ERR = 22;

  static const int SECURITY_ERR = 18;

  static const int SYNTAX_ERR = 12;

  static const int TIMEOUT_ERR = 23;

  static const int TYPE_MISMATCH_ERR = 17;

  static const int URL_MISMATCH_ERR = 21;

  static const int VALIDATION_ERR = 16;

  static const int WRONG_DOCUMENT_ERR = 4;

  /** @domName DOMException.code */
  final int code;

  /** @domName DOMException.message */
  final String message;

  /** @domName DOMException.name */
  final String name;

  /** @domName DOMException.toString */
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName DOMFileSystem
class DOMFileSystem native "*DOMFileSystem" {

  /** @domName DOMFileSystem.name */
  final String name;

  /** @domName DOMFileSystem.root */
  final DirectoryEntry root;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName DOMFileSystemSync
class DOMFileSystemSync native "*DOMFileSystemSync" {

  /** @domName DOMFileSystemSync.name */
  final String name;

  /** @domName DOMFileSystemSync.root */
  final DirectoryEntrySync root;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName DOMImplementation
class DOMImplementation native "*DOMImplementation" {

  /** @domName DOMImplementation.createCSSStyleSheet */
  CSSStyleSheet createCSSStyleSheet(String title, String media) native;

  /** @domName DOMImplementation.createDocument */
  Document createDocument(String namespaceURI, String qualifiedName, DocumentType doctype) native;

  /** @domName DOMImplementation.createDocumentType */
  DocumentType createDocumentType(String qualifiedName, String publicId, String systemId) native;

  /** @domName DOMImplementation.createHTMLDocument */
  Document createHTMLDocument(String title) native;

  /** @domName DOMImplementation.hasFeature */
  bool hasFeature(String feature, String version) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName MimeType
class DOMMimeType native "*MimeType" {

  /** @domName MimeType.description */
  final String description;

  /** @domName MimeType.enabledPlugin */
  final DOMPlugin enabledPlugin;

  /** @domName MimeType.suffixes */
  final String suffixes;

  /** @domName MimeType.type */
  final String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName MimeTypeArray
class DOMMimeTypeArray implements JavaScriptIndexingBehavior, List<DOMMimeType> native "*MimeTypeArray" {

  /** @domName MimeTypeArray.length */
  final int length;

  DOMMimeType operator[](int index) => JS("DOMMimeType", "#[#]", this, index);

  void operator[]=(int index, DOMMimeType value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<DOMMimeType> mixins.
  // DOMMimeType is the element type.

  // From Iterable<DOMMimeType>:

  Iterator<DOMMimeType> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<DOMMimeType>(this);
  }

  // From Collection<DOMMimeType>:

  void add(DOMMimeType value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(DOMMimeType value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<DOMMimeType> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(DOMMimeType element) => _Collections.contains(this, element);

  void forEach(void f(DOMMimeType element)) => _Collections.forEach(this, f);

  Collection map(f(DOMMimeType element)) => _Collections.map(this, [], f);

  Collection<DOMMimeType> filter(bool f(DOMMimeType element)) =>
     _Collections.filter(this, <DOMMimeType>[], f);

  bool every(bool f(DOMMimeType element)) => _Collections.every(this, f);

  bool some(bool f(DOMMimeType element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<DOMMimeType>:

  void sort([Comparator<DOMMimeType> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(DOMMimeType element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(DOMMimeType element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  DOMMimeType get last => this[length - 1];

  DOMMimeType removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<DOMMimeType> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [DOMMimeType initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<DOMMimeType> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <DOMMimeType>[]);

  // -- end List<DOMMimeType> mixins.

  /** @domName MimeTypeArray.item */
  DOMMimeType item(int index) native;

  /** @domName MimeTypeArray.namedItem */
  DOMMimeType namedItem(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName DOMParser
class DOMParser native "*DOMParser" {

  factory DOMParser() => _DOMParserFactoryProvider.createDOMParser();

  /** @domName DOMParser.parseFromString */
  Document parseFromString(String str, String contentType) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Plugin
class DOMPlugin native "*Plugin" {

  /** @domName Plugin.description */
  final String description;

  /** @domName Plugin.filename */
  final String filename;

  /** @domName Plugin.length */
  final int length;

  /** @domName Plugin.name */
  final String name;

  /** @domName Plugin.item */
  DOMMimeType item(int index) native;

  /** @domName Plugin.namedItem */
  DOMMimeType namedItem(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName PluginArray
class DOMPluginArray implements JavaScriptIndexingBehavior, List<DOMPlugin> native "*PluginArray" {

  /** @domName PluginArray.length */
  final int length;

  DOMPlugin operator[](int index) => JS("DOMPlugin", "#[#]", this, index);

  void operator[]=(int index, DOMPlugin value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<DOMPlugin> mixins.
  // DOMPlugin is the element type.

  // From Iterable<DOMPlugin>:

  Iterator<DOMPlugin> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<DOMPlugin>(this);
  }

  // From Collection<DOMPlugin>:

  void add(DOMPlugin value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(DOMPlugin value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<DOMPlugin> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(DOMPlugin element) => _Collections.contains(this, element);

  void forEach(void f(DOMPlugin element)) => _Collections.forEach(this, f);

  Collection map(f(DOMPlugin element)) => _Collections.map(this, [], f);

  Collection<DOMPlugin> filter(bool f(DOMPlugin element)) =>
     _Collections.filter(this, <DOMPlugin>[], f);

  bool every(bool f(DOMPlugin element)) => _Collections.every(this, f);

  bool some(bool f(DOMPlugin element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<DOMPlugin>:

  void sort([Comparator<DOMPlugin> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(DOMPlugin element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(DOMPlugin element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  DOMPlugin get last => this[length - 1];

  DOMPlugin removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<DOMPlugin> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [DOMPlugin initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<DOMPlugin> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <DOMPlugin>[]);

  // -- end List<DOMPlugin> mixins.

  /** @domName PluginArray.item */
  DOMPlugin item(int index) native;

  /** @domName PluginArray.namedItem */
  DOMPlugin namedItem(String name) native;

  /** @domName PluginArray.refresh */
  void refresh(bool reload) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Selection
class DOMSelection native "*Selection" {

  /** @domName Selection.anchorNode */
  final Node anchorNode;

  /** @domName Selection.anchorOffset */
  final int anchorOffset;

  /** @domName Selection.baseNode */
  final Node baseNode;

  /** @domName Selection.baseOffset */
  final int baseOffset;

  /** @domName Selection.extentNode */
  final Node extentNode;

  /** @domName Selection.extentOffset */
  final int extentOffset;

  /** @domName Selection.focusNode */
  final Node focusNode;

  /** @domName Selection.focusOffset */
  final int focusOffset;

  /** @domName Selection.isCollapsed */
  final bool isCollapsed;

  /** @domName Selection.rangeCount */
  final int rangeCount;

  /** @domName Selection.type */
  final String type;

  /** @domName Selection.addRange */
  void addRange(Range range) native;

  /** @domName Selection.collapse */
  void collapse(Node node, int index) native;

  /** @domName Selection.collapseToEnd */
  void collapseToEnd() native;

  /** @domName Selection.collapseToStart */
  void collapseToStart() native;

  /** @domName Selection.containsNode */
  bool containsNode(Node node, bool allowPartial) native;

  /** @domName Selection.deleteFromDocument */
  void deleteFromDocument() native;

  /** @domName Selection.empty */
  void empty() native;

  /** @domName Selection.extend */
  void extend(Node node, int offset) native;

  /** @domName Selection.getRangeAt */
  Range getRangeAt(int index) native;

  /** @domName Selection.modify */
  void modify(String alter, String direction, String granularity) native;

  /** @domName Selection.removeAllRanges */
  void removeAllRanges() native;

  /** @domName Selection.selectAllChildren */
  void selectAllChildren(Node node) native;

  /** @domName Selection.setBaseAndExtent */
  void setBaseAndExtent(Node baseNode, int baseOffset, Node extentNode, int extentOffset) native;

  /** @domName Selection.setPosition */
  void setPosition(Node node, int offset) native;

  /** @domName Selection.toString */
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName DOMSettableTokenList
class DOMSettableTokenList extends DOMTokenList native "*DOMSettableTokenList" {

  /** @domName DOMSettableTokenList.value */
  String value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName DOMStringMap
abstract class DOMStringMap {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName DOMTokenList
class DOMTokenList native "*DOMTokenList" {

  /** @domName DOMTokenList.length */
  final int length;

  /** @domName DOMTokenList.contains */
  bool contains(String token) native;

  /** @domName DOMTokenList.item */
  String item(int index) native;

  /** @domName DOMTokenList.toString */
  String toString() native;

  /** @domName DOMTokenList.toggle */
  bool toggle(String token, [bool force]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLDataListElement
class DataListElement extends Element implements Element native "*HTMLDataListElement" {

  factory DataListElement() => _Elements.createDataListElement();

  /** @domName HTMLDataListElement.options */
  final HTMLCollection options;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName DataTransferItem
class DataTransferItem native "*DataTransferItem" {

  /** @domName DataTransferItem.kind */
  final String kind;

  /** @domName DataTransferItem.type */
  final String type;

  /** @domName DataTransferItem.getAsFile */
  Blob getAsFile() native;

  /** @domName DataTransferItem.getAsString */
  void getAsString([StringCallback callback]) native;

  /** @domName DataTransferItem.webkitGetAsEntry */
  Entry webkitGetAsEntry() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName DataTransferItemList
class DataTransferItemList native "*DataTransferItemList" {

  /** @domName DataTransferItemList.length */
  final int length;

  /** @domName DataTransferItemList.add */
  void add(data_OR_file, [String type]) native;

  /** @domName DataTransferItemList.clear */
  void clear() native;

  /** @domName DataTransferItemList.item */
  DataTransferItem item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName DataView
class DataView extends ArrayBufferView native "*DataView" {

  factory DataView(ArrayBuffer buffer, [int byteOffset, int byteLength]) {
    if (!?byteOffset) {
      return _DataViewFactoryProvider.createDataView(buffer);
    }
    if (!?byteLength) {
      return _DataViewFactoryProvider.createDataView(buffer, byteOffset);
    }
    return _DataViewFactoryProvider.createDataView(buffer, byteOffset, byteLength);
  }

  /** @domName DataView.getFloat32 */
  num getFloat32(int byteOffset, {bool littleEndian}) native;

  /** @domName DataView.getFloat64 */
  num getFloat64(int byteOffset, {bool littleEndian}) native;

  /** @domName DataView.getInt16 */
  int getInt16(int byteOffset, {bool littleEndian}) native;

  /** @domName DataView.getInt32 */
  int getInt32(int byteOffset, {bool littleEndian}) native;

  /** @domName DataView.getInt8 */
  int getInt8(int byteOffset) native;

  /** @domName DataView.getUint16 */
  int getUint16(int byteOffset, {bool littleEndian}) native;

  /** @domName DataView.getUint32 */
  int getUint32(int byteOffset, {bool littleEndian}) native;

  /** @domName DataView.getUint8 */
  int getUint8(int byteOffset) native;

  /** @domName DataView.setFloat32 */
  void setFloat32(int byteOffset, num value, {bool littleEndian}) native;

  /** @domName DataView.setFloat64 */
  void setFloat64(int byteOffset, num value, {bool littleEndian}) native;

  /** @domName DataView.setInt16 */
  void setInt16(int byteOffset, int value, {bool littleEndian}) native;

  /** @domName DataView.setInt32 */
  void setInt32(int byteOffset, int value, {bool littleEndian}) native;

  /** @domName DataView.setInt8 */
  void setInt8(int byteOffset, int value) native;

  /** @domName DataView.setUint16 */
  void setUint16(int byteOffset, int value, {bool littleEndian}) native;

  /** @domName DataView.setUint32 */
  void setUint32(int byteOffset, int value, {bool littleEndian}) native;

  /** @domName DataView.setUint8 */
  void setUint8(int byteOffset, int value) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Database
class Database native "*Database" {

  /** @domName Database.version */
  final String version;

  /** @domName Database.changeVersion */
  void changeVersion(String oldVersion, String newVersion, [SQLTransactionCallback callback, SQLTransactionErrorCallback errorCallback, VoidCallback successCallback]) native;

  /** @domName Database.readTransaction */
  void readTransaction(SQLTransactionCallback callback, [SQLTransactionErrorCallback errorCallback, VoidCallback successCallback]) native;

  /** @domName Database.transaction */
  void transaction(SQLTransactionCallback callback, [SQLTransactionErrorCallback errorCallback, VoidCallback successCallback]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void DatabaseCallback(database);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName DatabaseSync
class DatabaseSync native "*DatabaseSync" {

  /** @domName DatabaseSync.lastErrorMessage */
  final String lastErrorMessage;

  /** @domName DatabaseSync.version */
  final String version;

  /** @domName DatabaseSync.changeVersion */
  void changeVersion(String oldVersion, String newVersion, [SQLTransactionSyncCallback callback]) native;

  /** @domName DatabaseSync.readTransaction */
  void readTransaction(SQLTransactionSyncCallback callback) native;

  /** @domName DatabaseSync.transaction */
  void transaction(SQLTransactionSyncCallback callback) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName DedicatedWorkerContext
class DedicatedWorkerContext extends WorkerContext native "*DedicatedWorkerContext" {

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  DedicatedWorkerContextEvents get on =>
    new DedicatedWorkerContextEvents(this);

  /** @domName DedicatedWorkerContext.postMessage */
  void postMessage(/*any*/ message, [List messagePorts]) {
    if (?messagePorts) {
      var message_1 = _convertDartToNative_SerializedScriptValue(message);
      _postMessage_1(message_1, messagePorts);
      return;
    }
    var message_2 = _convertDartToNative_SerializedScriptValue(message);
    _postMessage_2(message_2);
    return;
  }
  void _postMessage_1(message, List messagePorts) native "postMessage";
  void _postMessage_2(message) native "postMessage";
}

class DedicatedWorkerContextEvents extends WorkerContextEvents {
  DedicatedWorkerContextEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get message => this['message'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName DelayNode
class DelayNode extends AudioNode native "*DelayNode" {

  /** @domName DelayNode.delayTime */
  final AudioParam delayTime;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLDetailsElement
class DetailsElement extends Element implements Element native "*HTMLDetailsElement" {

  factory DetailsElement() => _Elements.createDetailsElement();

  /** @domName HTMLDetailsElement.open */
  bool open;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName DeviceMotionEvent
class DeviceMotionEvent extends Event native "*DeviceMotionEvent" {

  /** @domName DeviceMotionEvent.interval */
  final num interval;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName DeviceOrientationEvent
class DeviceOrientationEvent extends Event native "*DeviceOrientationEvent" {

  /** @domName DeviceOrientationEvent.absolute */
  final bool absolute;

  /** @domName DeviceOrientationEvent.alpha */
  final num alpha;

  /** @domName DeviceOrientationEvent.beta */
  final num beta;

  /** @domName DeviceOrientationEvent.gamma */
  final num gamma;

  /** @domName DeviceOrientationEvent.initDeviceOrientationEvent */
  void initDeviceOrientationEvent(String type, bool bubbles, bool cancelable, num alpha, num beta, num gamma, bool absolute) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLDirectoryElement
class DirectoryElement extends Element implements Element native "*HTMLDirectoryElement" {

  /** @domName HTMLDirectoryElement.compact */
  bool compact;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName DirectoryEntry
class DirectoryEntry extends Entry native "*DirectoryEntry" {

  /** @domName DirectoryEntry.createReader */
  DirectoryReader createReader() native;

  /** @domName DirectoryEntry.getDirectory */
  void getDirectory(String path, {Map options, EntryCallback successCallback, ErrorCallback errorCallback}) {
    if (?errorCallback) {
      var options_1 = _convertDartToNative_Dictionary(options);
      _getDirectory_1(path, options_1, successCallback, errorCallback);
      return;
    }
    if (?successCallback) {
      var options_2 = _convertDartToNative_Dictionary(options);
      _getDirectory_2(path, options_2, successCallback);
      return;
    }
    if (?options) {
      var options_3 = _convertDartToNative_Dictionary(options);
      _getDirectory_3(path, options_3);
      return;
    }
    _getDirectory_4(path);
    return;
  }
  void _getDirectory_1(path, options, EntryCallback successCallback, ErrorCallback errorCallback) native "getDirectory";
  void _getDirectory_2(path, options, EntryCallback successCallback) native "getDirectory";
  void _getDirectory_3(path, options) native "getDirectory";
  void _getDirectory_4(path) native "getDirectory";

  /** @domName DirectoryEntry.getFile */
  void getFile(String path, {Map options, EntryCallback successCallback, ErrorCallback errorCallback}) {
    if (?errorCallback) {
      var options_1 = _convertDartToNative_Dictionary(options);
      _getFile_1(path, options_1, successCallback, errorCallback);
      return;
    }
    if (?successCallback) {
      var options_2 = _convertDartToNative_Dictionary(options);
      _getFile_2(path, options_2, successCallback);
      return;
    }
    if (?options) {
      var options_3 = _convertDartToNative_Dictionary(options);
      _getFile_3(path, options_3);
      return;
    }
    _getFile_4(path);
    return;
  }
  void _getFile_1(path, options, EntryCallback successCallback, ErrorCallback errorCallback) native "getFile";
  void _getFile_2(path, options, EntryCallback successCallback) native "getFile";
  void _getFile_3(path, options) native "getFile";
  void _getFile_4(path) native "getFile";

  /** @domName DirectoryEntry.removeRecursively */
  void removeRecursively(VoidCallback successCallback, [ErrorCallback errorCallback]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName DirectoryEntrySync
class DirectoryEntrySync extends EntrySync native "*DirectoryEntrySync" {

  /** @domName DirectoryEntrySync.createReader */
  DirectoryReaderSync createReader() native;

  /** @domName DirectoryEntrySync.getDirectory */
  DirectoryEntrySync getDirectory(String path, Map flags) {
    var flags_1 = _convertDartToNative_Dictionary(flags);
    return _getDirectory_1(path, flags_1);
  }
  DirectoryEntrySync _getDirectory_1(path, flags) native "getDirectory";

  /** @domName DirectoryEntrySync.getFile */
  FileEntrySync getFile(String path, Map flags) {
    var flags_1 = _convertDartToNative_Dictionary(flags);
    return _getFile_1(path, flags_1);
  }
  FileEntrySync _getFile_1(path, flags) native "getFile";

  /** @domName DirectoryEntrySync.removeRecursively */
  void removeRecursively() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName DirectoryReader
class DirectoryReader native "*DirectoryReader" {

  /** @domName DirectoryReader.readEntries */
  void readEntries(EntriesCallback successCallback, [ErrorCallback errorCallback]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName DirectoryReaderSync
class DirectoryReaderSync native "*DirectoryReaderSync" {

  /** @domName DirectoryReaderSync.readEntries */
  List<EntrySync> readEntries() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLDivElement
class DivElement extends Element implements Element native "*HTMLDivElement" {

  factory DivElement() => _Elements.createDivElement();

  /** @domName HTMLDivElement.align */
  String align;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class Document extends Node
    native "*HTMLDocument"
{


  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  DocumentEvents get on =>
    new DocumentEvents(this);

  /** @domName HTMLDocument.activeElement */
  final Element activeElement;

  /** @domName Document.body */
  Element body;

  /** @domName Document.charset */
  String charset;

  /** @domName Document.cookie */
  String cookie;

  /** @domName Document.defaultView */
  Window get window => _convertNativeToDart_Window(this._window);
  dynamic get _window => JS("dynamic", "#.defaultView", this);

  /** @domName Document.documentElement */
  final Element documentElement;

  /** @domName Document.domain */
  final String domain;

  /** @domName Document.head */
  final HeadElement head;

  /** @domName Document.implementation */
  final DOMImplementation implementation;

  /** @domName Document.lastModified */
  final String lastModified;

  /** @domName Document.preferredStylesheetSet */
  final String preferredStylesheetSet;

  /** @domName Document.readyState */
  final String readyState;

  /** @domName Document.referrer */
  final String referrer;

  /** @domName Document.selectedStylesheetSet */
  String selectedStylesheetSet;

  /** @domName Document.styleSheets */
  final List<StyleSheet> styleSheets;

  /** @domName Document.title */
  String title;

  /** @domName Document.webkitCurrentFullScreenElement */
  final Element webkitCurrentFullScreenElement;

  /** @domName Document.webkitFullScreenKeyboardInputAllowed */
  final bool webkitFullScreenKeyboardInputAllowed;

  /** @domName Document.webkitFullscreenElement */
  final Element webkitFullscreenElement;

  /** @domName Document.webkitFullscreenEnabled */
  final bool webkitFullscreenEnabled;

  /** @domName Document.webkitHidden */
  final bool webkitHidden;

  /** @domName Document.webkitIsFullScreen */
  final bool webkitIsFullScreen;

  /** @domName Document.webkitPointerLockElement */
  final Element webkitPointerLockElement;

  /** @domName Document.webkitVisibilityState */
  final String webkitVisibilityState;

  /** @domName Document.caretRangeFromPoint */
  Range caretRangeFromPoint(int x, int y) native;

  /** @domName Document.createCDATASection */
  CDATASection createCDATASection(String data) native;

  /** @domName Document.createDocumentFragment */
  DocumentFragment createDocumentFragment() native;

  /** @domName Document.createElement */
  Element $dom_createElement(String tagName) native "createElement";

  /** @domName Document.createElementNS */
  Element $dom_createElementNS(String namespaceURI, String qualifiedName) native "createElementNS";

  /** @domName Document.createEvent */
  Event $dom_createEvent(String eventType) native "createEvent";

  /** @domName Document.createRange */
  Range createRange() native;

  /** @domName Document.createTextNode */
  Text $dom_createTextNode(String data) native "createTextNode";

  /** @domName Document.createTouch */
  Touch createTouch(LocalWindow window, EventTarget target, int identifier, int pageX, int pageY, int screenX, int screenY, int webkitRadiusX, int webkitRadiusY, num webkitRotationAngle, num webkitForce) {
    var target_1 = _convertDartToNative_EventTarget(target);
    return _createTouch_1(window, target_1, identifier, pageX, pageY, screenX, screenY, webkitRadiusX, webkitRadiusY, webkitRotationAngle, webkitForce);
  }
  Touch _createTouch_1(LocalWindow window, target, identifier, pageX, pageY, screenX, screenY, webkitRadiusX, webkitRadiusY, webkitRotationAngle, webkitForce) native "createTouch";

  /** @domName Document.createTouchList */
  TouchList $dom_createTouchList() native "createTouchList";

  /** @domName Document.elementFromPoint */
  Element elementFromPoint(int x, int y) native;

  /** @domName Document.execCommand */
  bool execCommand(String command, bool userInterface, String value) native;

  /** @domName Document.getCSSCanvasContext */
  CanvasRenderingContext getCSSCanvasContext(String contextId, String name, int width, int height) native;

  /** @domName Document.getElementById */
  Element $dom_getElementById(String elementId) native "getElementById";

  /** @domName Document.getElementsByClassName */
  List<Node> $dom_getElementsByClassName(String tagname) native "getElementsByClassName";

  /** @domName Document.getElementsByName */
  List<Node> $dom_getElementsByName(String elementName) native "getElementsByName";

  /** @domName Document.getElementsByTagName */
  List<Node> $dom_getElementsByTagName(String tagname) native "getElementsByTagName";

  /** @domName Document.queryCommandEnabled */
  bool queryCommandEnabled(String command) native;

  /** @domName Document.queryCommandIndeterm */
  bool queryCommandIndeterm(String command) native;

  /** @domName Document.queryCommandState */
  bool queryCommandState(String command) native;

  /** @domName Document.queryCommandSupported */
  bool queryCommandSupported(String command) native;

  /** @domName Document.queryCommandValue */
  String queryCommandValue(String command) native;

  /** @domName Document.querySelector */
  Element $dom_querySelector(String selectors) native "querySelector";

  /** @domName Document.querySelectorAll */
  List<Node> $dom_querySelectorAll(String selectors) native "querySelectorAll";

  /** @domName Document.webkitCancelFullScreen */
  void webkitCancelFullScreen() native;

  /** @domName Document.webkitExitFullscreen */
  void webkitExitFullscreen() native;

  /** @domName Document.webkitExitPointerLock */
  void webkitExitPointerLock() native;

  // TODO(jacobr): implement all Element methods not on Document.

  Element query(String selectors) {
    // It is fine for our RegExp to detect element id query selectors to have
    // false negatives but not false positives.
    if (const RegExp("^#[_a-zA-Z]\\w*\$").hasMatch(selectors)) {
      return $dom_getElementById(selectors.substring(1));
    }
    return $dom_querySelector(selectors);
  }

  List<Element> queryAll(String selectors) {
    if (const RegExp("""^\\[name=["'][^'"]+['"]\\]\$""").hasMatch(selectors)) {
      final mutableMatches = $dom_getElementsByName(
          selectors.substring(7,selectors.length - 2));
      int len = mutableMatches.length;
      final copyOfMatches = new List<Element>(len);
      for (int i = 0; i < len; ++i) {
        copyOfMatches[i] = mutableMatches[i];
      }
      return new _FrozenElementList._wrap(copyOfMatches);
    } else if (const RegExp("^[*a-zA-Z0-9]+\$").hasMatch(selectors)) {
      final mutableMatches = $dom_getElementsByTagName(selectors);
      int len = mutableMatches.length;
      final copyOfMatches = new List<Element>(len);
      for (int i = 0; i < len; ++i) {
        copyOfMatches[i] = mutableMatches[i];
      }
      return new _FrozenElementList._wrap(copyOfMatches);
    } else {
      return new _FrozenElementList._wrap($dom_querySelectorAll(selectors));
    }
  }
}

class DocumentEvents extends ElementEvents {
  DocumentEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get abort => this['abort'];

  EventListenerList get beforeCopy => this['beforecopy'];

  EventListenerList get beforeCut => this['beforecut'];

  EventListenerList get beforePaste => this['beforepaste'];

  EventListenerList get blur => this['blur'];

  EventListenerList get change => this['change'];

  EventListenerList get click => this['click'];

  EventListenerList get contextMenu => this['contextmenu'];

  EventListenerList get copy => this['copy'];

  EventListenerList get cut => this['cut'];

  EventListenerList get doubleClick => this['dblclick'];

  EventListenerList get drag => this['drag'];

  EventListenerList get dragEnd => this['dragend'];

  EventListenerList get dragEnter => this['dragenter'];

  EventListenerList get dragLeave => this['dragleave'];

  EventListenerList get dragOver => this['dragover'];

  EventListenerList get dragStart => this['dragstart'];

  EventListenerList get drop => this['drop'];

  EventListenerList get error => this['error'];

  EventListenerList get focus => this['focus'];

  EventListenerList get input => this['input'];

  EventListenerList get invalid => this['invalid'];

  EventListenerList get keyDown => this['keydown'];

  EventListenerList get keyPress => this['keypress'];

  EventListenerList get keyUp => this['keyup'];

  EventListenerList get load => this['load'];

  EventListenerList get mouseDown => this['mousedown'];

  EventListenerList get mouseMove => this['mousemove'];

  EventListenerList get mouseOut => this['mouseout'];

  EventListenerList get mouseOver => this['mouseover'];

  EventListenerList get mouseUp => this['mouseup'];

  EventListenerList get mouseWheel => this['mousewheel'];

  EventListenerList get paste => this['paste'];

  EventListenerList get readyStateChange => this['readystatechange'];

  EventListenerList get reset => this['reset'];

  EventListenerList get scroll => this['scroll'];

  EventListenerList get search => this['search'];

  EventListenerList get select => this['select'];

  EventListenerList get selectionChange => this['selectionchange'];

  EventListenerList get selectStart => this['selectstart'];

  EventListenerList get submit => this['submit'];

  EventListenerList get touchCancel => this['touchcancel'];

  EventListenerList get touchEnd => this['touchend'];

  EventListenerList get touchMove => this['touchmove'];

  EventListenerList get touchStart => this['touchstart'];

  EventListenerList get fullscreenChange => this['webkitfullscreenchange'];

  EventListenerList get fullscreenError => this['webkitfullscreenerror'];

  EventListenerList get pointerLockChange => this['webkitpointerlockchange'];

  EventListenerList get pointerLockError => this['webkitpointerlockerror'];
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


Future<CSSStyleDeclaration> _emptyStyleFuture() {
  return _createMeasurementFuture(() => new Element.tag('div').style,
                                  new Completer<CSSStyleDeclaration>());
}

class _FrozenCssClassSet extends CssClassSet {
  void writeClasses(Set s) {
    throw new UnsupportedError(
        'frozen class set cannot be modified');
  }
  Set<String> readClasses() => new Set<String>();

  bool get frozen => true;
}

class DocumentFragment extends Node native "*DocumentFragment" {
  factory DocumentFragment() => _DocumentFragmentFactoryProvider.createDocumentFragment();

  factory DocumentFragment.html(String html) =>
      _DocumentFragmentFactoryProvider.createDocumentFragment_html(html);

  factory DocumentFragment.svg(String svgContent) =>
      new _DocumentFragmentFactoryProvider.createDocumentFragment_svg(svgContent);

  List<Element> _elements;

  List<Element> get elements {
    if (_elements == null) {
      _elements = new FilteredElementList(this);
    }
    return _elements;
  }

  // TODO: The type of value should be Collection<Element>. See http://b/5392897
  void set elements(value) {
    // Copy list first since we don't want liveness during iteration.
    List copy = new List.from(value);
    final elements = this.elements;
    elements.clear();
    elements.addAll(copy);
  }

  Element query(String selectors) => $dom_querySelector(selectors);

  List<Element> queryAll(String selectors) =>
    new _FrozenElementList._wrap($dom_querySelectorAll(selectors));

  String get innerHTML {
    final e = new Element.tag("div");
    e.nodes.add(this.clone(true));
    return e.innerHTML;
  }

  String get outerHTML => innerHTML;

  // TODO(nweiz): Do we want to support some variant of innerHTML for XML and/or
  // SVG strings?
  void set innerHTML(String value) {
    this.nodes.clear();

    final e = new Element.tag("div");
    e.innerHTML = value;

    // Copy list first since we don't want liveness during iteration.
    List nodes = new List.from(e.nodes);
    this.nodes.addAll(nodes);
  }

  Node _insertAdjacentNode(String where, Node node) {
    switch (where.toLowerCase()) {
      case "beforebegin": return null;
      case "afterend": return null;
      case "afterbegin":
        var first = this.nodes.length > 0 ? this.nodes[0] : null;
        this.insertBefore(node, first);
        return node;
      case "beforeend":
        this.nodes.add(node);
        return node;
      default:
        throw new ArgumentError("Invalid position ${where}");
    }
  }

  Element insertAdjacentElement(String where, Element element)
    => this._insertAdjacentNode(where, element);

  void insertAdjacentText(String where, String text) {
    this._insertAdjacentNode(where, new Text(text));
  }

  void insertAdjacentHTML(String where, String text) {
    this._insertAdjacentNode(where, new DocumentFragment.html(text));
  }

  void addText(String text) {
    this.insertAdjacentText('beforeend', text);
  }

  void addHTML(String text) {
    this.insertAdjacentHTML('beforeend', text);
  }

  // If we can come up with a semi-reasonable default value for an Element
  // getter, we'll use it. In general, these return the same values as an
  // element that has no parent.
  String get contentEditable => "false";
  bool get isContentEditable => false;
  bool get draggable => false;
  bool get hidden => false;
  bool get spellcheck => false;
  bool get translate => false;
  int get tabIndex => -1;
  String get id => "";
  String get title => "";
  String get tagName => "";
  String get webkitdropzone => "";
  String get webkitRegionOverflow => "";
  Element get $m_firstElementChild {
    if (elements.length > 0) {
      return elements[0];
    }
    return null;
  }
  Element get $m_lastElementChild() => elements.last;
  Element get nextElementSibling => null;
  Element get previousElementSibling => null;
  Element get offsetParent => null;
  Element get parent => null;
  Map<String, String> get attributes => const {};
  CssClassSet get classes => new _FrozenCssClassSet();
  Map<String, String> get dataAttributes => const {};
  CSSStyleDeclaration get style => new Element.tag('div').style;
  Future<CSSStyleDeclaration> get computedStyle =>
      _emptyStyleFuture();
  Future<CSSStyleDeclaration> getComputedStyle(String pseudoElement) =>
      _emptyStyleFuture();
  bool matchesSelector(String selectors) => false;

  // Imperative Element methods are made into no-ops, as they are on parentless
  // elements.
  void blur() {}
  void focus() {}
  void click() {}
  void scrollByLines(int lines) {}
  void scrollByPages(int pages) {}
  void scrollIntoView([bool centerIfNeeded]) {}
  void webkitRequestFullScreen(int flags) {}
  void webkitRequestFullscreen() {}

  // Setters throw errors rather than being no-ops because we aren't going to
  // retain the values that were set, and erroring out seems clearer.
  void set attributes(Map<String, String> value) {
    throw new UnsupportedError(
      "Attributes can't be set for document fragments.");
  }

  void set classes(Collection<String> value) {
    throw new UnsupportedError(
      "Classes can't be set for document fragments.");
  }

  void set dataAttributes(Map<String, String> value) {
    throw new UnsupportedError(
      "Data attributes can't be set for document fragments.");
  }

  void set contentEditable(String value) {
    throw new UnsupportedError(
      "Content editable can't be set for document fragments.");
  }

  String get dir {
    throw new UnsupportedError(
      "Document fragments don't support text direction.");
  }

  void set dir(String value) {
    throw new UnsupportedError(
      "Document fragments don't support text direction.");
  }

  void set draggable(bool value) {
    throw new UnsupportedError(
      "Draggable can't be set for document fragments.");
  }

  void set hidden(bool value) {
    throw new UnsupportedError(
      "Hidden can't be set for document fragments.");
  }

  void set id(String value) {
    throw new UnsupportedError(
      "ID can't be set for document fragments.");
  }

  String get lang {
    throw new UnsupportedError(
      "Document fragments don't support language.");
  }

  void set lang(String value) {
    throw new UnsupportedError(
      "Document fragments don't support language.");
  }

  void set scrollLeft(int value) {
    throw new UnsupportedError(
      "Document fragments don't support scrolling.");
  }

  void set scrollTop(int value) {
    throw new UnsupportedError(
      "Document fragments don't support scrolling.");
  }

  void set spellcheck(bool value) {
     throw new UnsupportedError(
      "Spellcheck can't be set for document fragments.");
  }

  void set translate(bool value) {
     throw new UnsupportedError(
      "Spellcheck can't be set for document fragments.");
  }

  void set tabIndex(int value) {
    throw new UnsupportedError(
      "Tab index can't be set for document fragments.");
  }

  void set title(String value) {
    throw new UnsupportedError(
      "Title can't be set for document fragments.");
  }

  void set webkitdropzone(String value) {
    throw new UnsupportedError(
      "WebKit drop zone can't be set for document fragments.");
  }

  void set webkitRegionOverflow(String value) {
    throw new UnsupportedError(
      "WebKit region overflow can't be set for document fragments.");
  }


  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  ElementEvents get on =>
    new ElementEvents(this);

  /** @domName DocumentFragment.querySelector */
  Element $dom_querySelector(String selectors) native "querySelector";

  /** @domName DocumentFragment.querySelectorAll */
  List<Node> $dom_querySelectorAll(String selectors) native "querySelectorAll";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName DocumentType
class DocumentType extends Node native "*DocumentType" {

  /** @domName DocumentType.entities */
  final NamedNodeMap entities;

  /** @domName DocumentType.internalSubset */
  final String internalSubset;

  /** @domName DocumentType.name */
  final String name;

  /** @domName DocumentType.notations */
  final NamedNodeMap notations;

  /** @domName DocumentType.publicId */
  final String publicId;

  /** @domName DocumentType.systemId */
  final String systemId;

  /** @domName DocumentType.remove */
  void remove() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName DynamicsCompressorNode
class DynamicsCompressorNode extends AudioNode native "*DynamicsCompressorNode" {

  /** @domName DynamicsCompressorNode.attack */
  final AudioParam attack;

  /** @domName DynamicsCompressorNode.knee */
  final AudioParam knee;

  /** @domName DynamicsCompressorNode.ratio */
  final AudioParam ratio;

  /** @domName DynamicsCompressorNode.reduction */
  final AudioParam reduction;

  /** @domName DynamicsCompressorNode.release */
  final AudioParam release;

  /** @domName DynamicsCompressorNode.threshold */
  final AudioParam threshold;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName EXTTextureFilterAnisotropic
class EXTTextureFilterAnisotropic native "*EXTTextureFilterAnisotropic" {

  static const int MAX_TEXTURE_MAX_ANISOTROPY_EXT = 0x84FF;

  static const int TEXTURE_MAX_ANISOTROPY_EXT = 0x84FE;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// TODO(jacobr): use _Lists.dart to remove some of the duplicated
// functionality.
class _ChildrenElementList implements List {
  // Raw Element.
  final Element _element;
  final HTMLCollection _childElements;

  _ChildrenElementList._wrap(Element element)
    : _childElements = element.$dom_children,
      _element = element;

  List<Element> _toList() {
    final output = new List(_childElements.length);
    for (int i = 0, len = _childElements.length; i < len; i++) {
      output[i] = _childElements[i];
    }
    return output;
  }

  bool contains(Element element) => _childElements.contains(element);

  void forEach(void f(Element element)) {
    for (Element element in _childElements) {
      f(element);
    }
  }

  List<Element> filter(bool f(Element element)) {
    final output = [];
    forEach((Element element) {
      if (f(element)) {
        output.add(element);
      }
    });
    return new _FrozenElementList._wrap(output);
  }

  bool every(bool f(Element element)) {
    for (Element element in this) {
      if (!f(element)) {
        return false;
      }
    };
    return true;
  }

  bool some(bool f(Element element)) {
    for (Element element in this) {
      if (f(element)) {
        return true;
      }
    };
    return false;
  }

  Collection map(f(Element element)) {
    final out = [];
    for (Element el in this) {
      out.add(f(el));
    }
    return out;
  }

  bool get isEmpty {
    return _element.$dom_firstElementChild == null;
  }

  int get length {
    return _childElements.length;
  }

  Element operator [](int index) {
    return _childElements[index];
  }

  void operator []=(int index, Element value) {
    _element.$dom_replaceChild(value, _childElements[index]);
  }

   void set length(int newLength) {
     // TODO(jacobr): remove children when length is reduced.
     throw new UnsupportedError('');
   }

  Element add(Element value) {
    _element.$dom_appendChild(value);
    return value;
  }

  Element addLast(Element value) => add(value);

  Iterator<Element> iterator() => _toList().iterator();

  void addAll(Collection<Element> collection) {
    for (Element element in collection) {
      _element.$dom_appendChild(element);
    }
  }

  void sort([Comparator<Element> compare = Comparable.compare]) {
    throw new UnsupportedError('TODO(jacobr): should we impl?');
  }

  void setRange(int start, int rangeLength, List from, [int startFrom = 0]) {
    throw new UnimplementedError();
  }

  void removeRange(int start, int rangeLength) {
    throw new UnimplementedError();
  }

  void insertRange(int start, int rangeLength, [initialValue = null]) {
    throw new UnimplementedError();
  }

  List getRange(int start, int rangeLength) =>
    new _FrozenElementList._wrap(_Lists.getRange(this, start, rangeLength,
        []));

  int indexOf(Element element, [int start = 0]) {
    return _Lists.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(Element element, [int start = null]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  void clear() {
    // It is unclear if we want to keep non element nodes?
    _element.text = '';
  }

  Element removeLast() {
    final result = this.last;
    if (result != null) {
      _element.$dom_removeChild(result);
    }
    return result;
  }

  Element get last {
    return _element.$dom_lastElementChild;
  }
}

// TODO(jacobr): this is an inefficient implementation but it is hard to see
// a better option given that we cannot quite force NodeList to be an
// ElementList as there are valid cases where a NodeList JavaScript object
// contains Node objects that are not Elements.
class _FrozenElementList implements List {
  final List<Node> _nodeList;

  _FrozenElementList._wrap(this._nodeList);

  Element get first {
    return _nodeList[0];
  }

  bool contains(Element element) {
    for (Element el in this) {
      if (el == element) return true;
    }
    return false;
  }

  void forEach(void f(Element element)) {
    for (Element el in this) {
      f(el);
    }
  }

  Collection map(f(Element element)) {
    final out = [];
    for (Element el in this) {
      out.add(f(el));
    }
    return out;
  }

  List<Element> filter(bool f(Element element)) {
    final out = [];
    for (Element el in this) {
      if (f(el)) out.add(el);
    }
    return out;
  }

  bool every(bool f(Element element)) {
    for(Element element in this) {
      if (!f(element)) {
        return false;
      }
    };
    return true;
  }

  bool some(bool f(Element element)) {
    for(Element element in this) {
      if (f(element)) {
        return true;
      }
    };
    return false;
  }

  bool get isEmpty => _nodeList.isEmpty;

  int get length => _nodeList.length;

  Element operator [](int index) => _nodeList[index];

  void operator []=(int index, Element value) {
    throw new UnsupportedError('');
  }

  void set length(int newLength) {
    _nodeList.length = newLength;
  }

  void add(Element value) {
    throw new UnsupportedError('');
  }

  void addLast(Element value) {
    throw new UnsupportedError('');
  }

  Iterator<Element> iterator() => new _FrozenElementListIterator(this);

  void addAll(Collection<Element> collection) {
    throw new UnsupportedError('');
  }

  void sort([Comparator<Element> compare = Comparable.compare]) {
    throw new UnsupportedError('');
  }

  void setRange(int start, int rangeLength, List from, [int startFrom = 0]) {
    throw new UnsupportedError('');
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError('');
  }

  void insertRange(int start, int rangeLength, [initialValue = null]) {
    throw new UnsupportedError('');
  }

  List<Element> getRange(int start, int rangeLength) =>
    new _FrozenElementList._wrap(_nodeList.getRange(start, rangeLength));

  int indexOf(Element element, [int start = 0]) =>
    _nodeList.indexOf(element, start);

  int lastIndexOf(Element element, [int start = null]) =>
    _nodeList.lastIndexOf(element, start);

  void clear() {
    throw new UnsupportedError('');
  }

  Element removeLast() {
    throw new UnsupportedError('');
  }

  Element get last => _nodeList.last;
}

class _FrozenElementListIterator implements Iterator<Element> {
  final _FrozenElementList _list;
  int _index = 0;

  _FrozenElementListIterator(this._list);

  /**
   * Gets the next element in the iteration. Throws a
   * [StateError("No more elements")] if no element is left.
   */
  Element next() {
    if (!hasNext) {
      throw new StateError("No more elements");
    }

    return _list[_index++];
  }

  /**
   * Returns whether the [Iterator] has elements left.
   */
  bool get hasNext => _index < _list.length;
}

/**
 * All your attribute manipulation needs in one place.
 * Extends the regular Map interface by automatically coercing non-string
 * values to strings.
 */
abstract class AttributeMap implements Map<String, String> {
  void operator []=(String key, value);
}

class _ElementAttributeMap extends AttributeMap {

  final Element _element;

  _ElementAttributeMap(this._element);

  bool containsValue(String value) {
    final attributes = _element.$dom_attributes;
    for (int i = 0, len = attributes.length; i < len; i++) {
      if(value == attributes[i].value) {
        return true;
      }
    }
    return false;
  }

  bool containsKey(String key) {
    return _element.$dom_hasAttribute(key);
  }

  String operator [](String key) {
    return _element.$dom_getAttribute(key);
  }

  void operator []=(String key, value) {
    _element.$dom_setAttribute(key, '$value');
  }

  String putIfAbsent(String key, String ifAbsent()) {
    if (!containsKey(key)) {
      this[key] = ifAbsent();
    }
    return this[key];
  }

  String remove(String key) {
    String value = _element.$dom_getAttribute(key);
    _element.$dom_removeAttribute(key);
    return value;
  }

  void clear() {
    final attributes = _element.$dom_attributes;
    for (int i = attributes.length - 1; i >= 0; i--) {
      remove(attributes[i].name);
    }
  }

  void forEach(void f(String key, String value)) {
    final attributes = _element.$dom_attributes;
    for (int i = 0, len = attributes.length; i < len; i++) {
      final item = attributes[i];
      f(item.name, item.value);
    }
  }

  Collection<String> get keys {
    // TODO(jacobr): generate a lazy collection instead.
    final attributes = _element.$dom_attributes;
    final keys = new List<String>(attributes.length);
    for (int i = 0, len = attributes.length; i < len; i++) {
      keys[i] = attributes[i].name;
    }
    return keys;
  }

  Collection<String> get values {
    // TODO(jacobr): generate a lazy collection instead.
    final attributes = _element.$dom_attributes;
    final values = new List<String>(attributes.length);
    for (int i = 0, len = attributes.length; i < len; i++) {
      values[i] = attributes[i].value;
    }
    return values;
  }

  /**
   * The number of {key, value} pairs in the map.
   */
  int get length {
    return _element.$dom_attributes.length;
  }

  /**
   * Returns true if there is no {key, value} pair in the map.
   */
  bool get isEmpty {
    return length == 0;
  }
}

/**
 * Provides a Map abstraction on top of data-* attributes, similar to the
 * dataSet in the old DOM.
 */
class _DataAttributeMap extends AttributeMap {

  final Map<String, String> $dom_attributes;

  _DataAttributeMap(this.$dom_attributes);

  // interface Map

  // TODO: Use lazy iterator when it is available on Map.
  bool containsValue(String value) => values.some((v) => v == value);

  bool containsKey(String key) => $dom_attributes.containsKey(_attr(key));

  String operator [](String key) => $dom_attributes[_attr(key)];

  void operator []=(String key, value) {
    $dom_attributes[_attr(key)] = '$value';
  }

  String putIfAbsent(String key, String ifAbsent()) =>
    $dom_attributes.putIfAbsent(_attr(key), ifAbsent);

  String remove(String key) => $dom_attributes.remove(_attr(key));

  void clear() {
    // Needs to operate on a snapshot since we are mutating the collection.
    for (String key in keys) {
      remove(key);
    }
  }

  void forEach(void f(String key, String value)) {
    $dom_attributes.forEach((String key, String value) {
      if (_matches(key)) {
        f(_strip(key), value);
      }
    });
  }

  Collection<String> get keys {
    final keys = new List<String>();
    $dom_attributes.forEach((String key, String value) {
      if (_matches(key)) {
        keys.add(_strip(key));
      }
    });
    return keys;
  }

  Collection<String> get values {
    final values = new List<String>();
    $dom_attributes.forEach((String key, String value) {
      if (_matches(key)) {
        values.add(value);
      }
    });
    return values;
  }

  int get length => keys.length;

  // TODO: Use lazy iterator when it is available on Map.
  bool get isEmpty => length == 0;

  // Helpers.
  String _attr(String key) => 'data-$key';
  bool _matches(String key) => key.startsWith('data-');
  String _strip(String key) => key.substring(5);
}

class _ElementCssClassSet extends CssClassSet {

  final Element _element;

  _ElementCssClassSet(this._element);

  Set<String> readClasses() {
    var s = new Set<String>();
    var classname = _element.$dom_className;

    for (String name in classname.split(' ')) {
      String trimmed = name.trim();
      if (!trimmed.isEmpty) {
        s.add(trimmed);
      }
    }
    return s;
  }

  void writeClasses(Set<String> s) {
    List list = new List.from(s);
    _element.$dom_className = Strings.join(list, ' ');
  }
}

class _SimpleClientRect implements ClientRect {
  final num left;
  final num top;
  final num width;
  final num height;
  num get right => left + width;
  num get bottom => top + height;

  const _SimpleClientRect(this.left, this.top, this.width, this.height);

  bool operator ==(ClientRect other) {
    return other != null && left == other.left && top == other.top
        && width == other.width && height == other.height;
  }

  String toString() => "($left, $top, $width, $height)";
}

class Element extends Node implements ElementTraversal native "*Element" {

  factory Element.html(String html) =>
      _ElementFactoryProvider.createElement_html(html);
  factory Element.tag(String tag) =>
      _ElementFactoryProvider.createElement_tag(tag);

  /**
   * @domName Element.hasAttribute, Element.getAttribute, Element.setAttribute,
   *   Element.removeAttribute
   */
  _ElementAttributeMap get attributes => new _ElementAttributeMap(this);

  void set attributes(Map<String, String> value) {
    Map<String, String> attributes = this.attributes;
    attributes.clear();
    for (String key in value.keys) {
      attributes[key] = value[key];
    }
  }

  void set elements(Collection<Element> value) {
    final elements = this.elements;
    elements.clear();
    elements.addAll(value);
  }

  /**
   * @domName childElementCount, firstElementChild, lastElementChild,
   *   children, Node.nodes.add
   */
  List<Element> get elements => new _ChildrenElementList._wrap(this);

  Element query(String selectors) => $dom_querySelector(selectors);

  List<Element> queryAll(String selectors) =>
    new _FrozenElementList._wrap($dom_querySelectorAll(selectors));

  /** @domName className, classList */
  CssClassSet get classes => new _ElementCssClassSet(this);

  void set classes(Collection<String> value) {
    CssClassSet classSet = classes;
    classSet.clear();
    classSet.addAll(value);
  }

  Map<String, String> get dataAttributes =>
    new _DataAttributeMap(attributes);

  void set dataAttributes(Map<String, String> value) {
    final dataAttributes = this.dataAttributes;
    dataAttributes.clear();
    for (String key in value.keys) {
      dataAttributes[key] = value[key];
    }
  }

  /** @domName Window.getComputedStyle */
  Future<CSSStyleDeclaration> get computedStyle {
     // TODO(jacobr): last param should be null, see b/5045788
     return getComputedStyle('');
  }

  /** @domName Window.getComputedStyle */
  Future<CSSStyleDeclaration> getComputedStyle(String pseudoElement) {
    return _createMeasurementFuture(
        () => window.$dom_getComputedStyle(this, pseudoElement),
        new Completer<CSSStyleDeclaration>());
  }

  /**
   * Adds the specified text as a text node after the last child of this.
   */
  void addText(String text) {
    this.insertAdjacentText('beforeend', text);
  }

  /**
   * Parses the specified text as HTML and adds the resulting node after the
   * last child of this.
   */
  void addHTML(String text) {
    this.insertAdjacentHTML('beforeend', text);
  }

  // Hooks to support custom WebComponents.
  /**
   * Experimental support for [web components][wc]. This field stores a
   * reference to the component implementation. It was inspired by Mozilla's
   * [x-tags][] project. Please note: in the future it may be possible to
   * `extend Element` from your class, in which case this field will be
   * deprecated and will simply return this [Element] object.
   *
   * [wc]: http://dvcs.w3.org/hg/webcomponents/raw-file/tip/explainer/index.html
   * [x-tags]: http://x-tags.org/
   */
  var xtag;

  // TODO(vsm): Implement noSuchMethod or similar for dart2js.

  /** @domName Element.insertAdjacentText */
  void insertAdjacentText(String where, String text) {
    if (JS('bool', '!!#.insertAdjacentText', this)) {
      _insertAdjacentText(where, text);
    } else {
      _insertAdjacentNode(where, new Text(text));
    }
  }

  void _insertAdjacentText(String where, String text)
      native 'insertAdjacentText';

  /** @domName Element.insertAdjacentHTML */
  void insertAdjacentHTML(String where, String text) {
    if (JS('bool', '!!#.insertAdjacentHTML', this)) {
      _insertAdjacentHTML(where, text);
    } else {
      _insertAdjacentNode(where, new DocumentFragment.html(text));
    }
  }

  void _insertAdjacentHTML(String where, String text)
      native 'insertAdjacentHTML';

  /** @domName Element.insertAdjacentHTML */
  Element insertAdjacentElement(String where, Element element) {
    if (JS('bool', '!!#.insertAdjacentElement', this)) {
      _insertAdjacentElement(where, element);
    } else {
      _insertAdjacentNode(where, element);
    }
    return element;
  }

  void _insertAdjacentElement(String where, Element element)
      native 'insertAdjacentElement';

  void _insertAdjacentNode(String where, Node node) {
    switch (where.toLowerCase()) {
      case 'beforebegin':
        this.parent.insertBefore(node, this);
        break;
      case 'afterbegin':
        var first = this.nodes.length > 0 ? this.nodes[0] : null;
        this.insertBefore(node, first);
        break;
      case 'beforeend':
        this.nodes.add(node);
        break;
      case 'afterend':
        this.parent.insertBefore(node, this.nextNode);
        break;
      default:
        throw new ArgumentError("Invalid position ${where}");
    }
  }


  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  ElementEvents get on =>
    new ElementEvents(this);

  /** @domName HTMLElement.children */
  HTMLCollection get $dom_children => JS("HTMLCollection", "#.children", this);

  /** @domName HTMLElement.contentEditable */
  String contentEditable;

  /** @domName HTMLElement.dir */
  String dir;

  /** @domName HTMLElement.draggable */
  bool draggable;

  /** @domName HTMLElement.hidden */
  bool hidden;

  /** @domName HTMLElement.id */
  String id;

  /** @domName HTMLElement.innerHTML */
  String innerHTML;

  /** @domName HTMLElement.isContentEditable */
  final bool isContentEditable;

  /** @domName HTMLElement.lang */
  String lang;

  /** @domName HTMLElement.outerHTML */
  final String outerHTML;

  /** @domName HTMLElement.spellcheck */
  bool spellcheck;

  /** @domName HTMLElement.tabIndex */
  int tabIndex;

  /** @domName HTMLElement.title */
  String title;

  /** @domName HTMLElement.translate */
  bool translate;

  /** @domName HTMLElement.webkitdropzone */
  String webkitdropzone;

  /** @domName HTMLElement.click */
  void click() native;

  static const int ALLOW_KEYBOARD_INPUT = 1;

  /** @domName Element.childElementCount */
  int get $dom_childElementCount => JS("int", "#.childElementCount", this);

  /** @domName Element.className */
  String get $dom_className => JS("String", "#.className", this);

  /** @domName Element.className */
  void set $dom_className(String value) {
    JS("void", "#.className = #", this, value);
  }

  /** @domName Element.clientHeight */
  final int clientHeight;

  /** @domName Element.clientLeft */
  final int clientLeft;

  /** @domName Element.clientTop */
  final int clientTop;

  /** @domName Element.clientWidth */
  final int clientWidth;

  /** @domName Element.dataset */
  final Map<String, String> dataset;

  /** @domName Element.firstElementChild */
  Element get $dom_firstElementChild => JS("Element", "#.firstElementChild", this);

  /** @domName Element.lastElementChild */
  Element get $dom_lastElementChild => JS("Element", "#.lastElementChild", this);

  /** @domName Element.nextElementSibling */
  final Element nextElementSibling;

  /** @domName Element.offsetHeight */
  final int offsetHeight;

  /** @domName Element.offsetLeft */
  final int offsetLeft;

  /** @domName Element.offsetParent */
  final Element offsetParent;

  /** @domName Element.offsetTop */
  final int offsetTop;

  /** @domName Element.offsetWidth */
  final int offsetWidth;

  /** @domName Element.previousElementSibling */
  final Element previousElementSibling;

  /** @domName Element.scrollHeight */
  final int scrollHeight;

  /** @domName Element.scrollLeft */
  int scrollLeft;

  /** @domName Element.scrollTop */
  int scrollTop;

  /** @domName Element.scrollWidth */
  final int scrollWidth;

  /** @domName Element.style */
  final CSSStyleDeclaration style;

  /** @domName Element.tagName */
  final String tagName;

  /** @domName Element.blur */
  void blur() native;

  /** @domName Element.focus */
  void focus() native;

  /** @domName Element.getAttribute */
  String $dom_getAttribute(String name) native "getAttribute";

  /** @domName Element.getBoundingClientRect */
  ClientRect getBoundingClientRect() native;

  /** @domName Element.getClientRects */
  List<ClientRect> getClientRects() native;

  /** @domName Element.getElementsByClassName */
  List<Node> $dom_getElementsByClassName(String name) native "getElementsByClassName";

  /** @domName Element.getElementsByTagName */
  List<Node> $dom_getElementsByTagName(String name) native "getElementsByTagName";

  /** @domName Element.hasAttribute */
  bool $dom_hasAttribute(String name) native "hasAttribute";

  /** @domName Element.querySelector */
  Element $dom_querySelector(String selectors) native "querySelector";

  /** @domName Element.querySelectorAll */
  List<Node> $dom_querySelectorAll(String selectors) native "querySelectorAll";

  /** @domName Element.removeAttribute */
  void $dom_removeAttribute(String name) native "removeAttribute";

  /** @domName Element.scrollByLines */
  void scrollByLines(int lines) native;

  /** @domName Element.scrollByPages */
  void scrollByPages(int pages) native;

  /** @domName Element.scrollIntoViewIfNeeded */
  void scrollIntoView([bool centerIfNeeded]) native "scrollIntoViewIfNeeded";

  /** @domName Element.setAttribute */
  void $dom_setAttribute(String name, String value) native "setAttribute";

  /** @domName Element.webkitMatchesSelector */
  bool matchesSelector(String selectors) native "webkitMatchesSelector";

  /** @domName Element.webkitRequestFullScreen */
  void webkitRequestFullScreen(int flags) native;

  /** @domName Element.webkitRequestFullscreen */
  void webkitRequestFullscreen() native;

  /** @domName Element.webkitRequestPointerLock */
  void webkitRequestPointerLock() native;

}

// Temporary dispatch hook to support WebComponents.
Function dynamicUnknownElementDispatcher;

final _START_TAG_REGEXP = const RegExp('<(\\w+)');
class _ElementFactoryProvider {
  static final _CUSTOM_PARENT_TAG_MAP = const {
    'body' : 'html',
    'head' : 'html',
    'caption' : 'table',
    'td': 'tr',
    'colgroup': 'table',
    'col' : 'colgroup',
    'tr' : 'tbody',
    'tbody' : 'table',
    'tfoot' : 'table',
    'thead' : 'table',
    'track' : 'audio',
  };

  /** @domName Document.createElement */
  static Element createElement_html(String html) {
    // TODO(jacobr): this method can be made more robust and performant.
    // 1) Cache the dummy parent elements required to use innerHTML rather than
    //    creating them every call.
    // 2) Verify that the html does not contain leading or trailing text nodes.
    // 3) Verify that the html does not contain both <head> and <body> tags.
    // 4) Detatch the created element from its dummy parent.
    String parentTag = 'div';
    String tag;
    final match = _START_TAG_REGEXP.firstMatch(html);
    if (match != null) {
      tag = match.group(1).toLowerCase();
      if (_CUSTOM_PARENT_TAG_MAP.containsKey(tag)) {
        parentTag = _CUSTOM_PARENT_TAG_MAP[tag];
      }
    }
    final Element temp = new Element.tag(parentTag);
    temp.innerHTML = html;

    Element element;
    if (temp.elements.length == 1) {
      element = temp.elements[0];
    } else if (parentTag == 'html' && temp.elements.length == 2) {
      // Work around for edge case in WebKit and possibly other browsers where
      // both body and head elements are created even though the inner html
      // only contains a head or body element.
      element = temp.elements[tag == 'head' ? 0 : 1];
    } else {
      throw new ArgumentError('HTML had ${temp.elements.length} '
          'top level elements but 1 expected');
    }
    element.remove();
    return element;
  }

  /** @domName Document.createElement */
  // Optimization to improve performance until the dart2js compiler inlines this
  // method.
  static Element createElement_tag(String tag) =>
      JS('Element', 'document.createElement(#)', tag);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class ElementEvents extends Events {
  ElementEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get abort => this['abort'];

  EventListenerList get beforeCopy => this['beforecopy'];

  EventListenerList get beforeCut => this['beforecut'];

  EventListenerList get beforePaste => this['beforepaste'];

  EventListenerList get blur => this['blur'];

  EventListenerList get change => this['change'];

  EventListenerList get click => this['click'];

  EventListenerList get contextMenu => this['contextmenu'];

  EventListenerList get copy => this['copy'];

  EventListenerList get cut => this['cut'];

  EventListenerList get doubleClick => this['dblclick'];

  EventListenerList get drag => this['drag'];

  EventListenerList get dragEnd => this['dragend'];

  EventListenerList get dragEnter => this['dragenter'];

  EventListenerList get dragLeave => this['dragleave'];

  EventListenerList get dragOver => this['dragover'];

  EventListenerList get dragStart => this['dragstart'];

  EventListenerList get drop => this['drop'];

  EventListenerList get error => this['error'];

  EventListenerList get focus => this['focus'];

  EventListenerList get input => this['input'];

  EventListenerList get invalid => this['invalid'];

  EventListenerList get keyDown => this['keydown'];

  EventListenerList get keyPress => this['keypress'];

  EventListenerList get keyUp => this['keyup'];

  EventListenerList get load => this['load'];

  EventListenerList get mouseDown => this['mousedown'];

  EventListenerList get mouseMove => this['mousemove'];

  EventListenerList get mouseOut => this['mouseout'];

  EventListenerList get mouseOver => this['mouseover'];

  EventListenerList get mouseUp => this['mouseup'];

  EventListenerList get paste => this['paste'];

  EventListenerList get reset => this['reset'];

  EventListenerList get scroll => this['scroll'];

  EventListenerList get search => this['search'];

  EventListenerList get select => this['select'];

  EventListenerList get selectStart => this['selectstart'];

  EventListenerList get submit => this['submit'];

  EventListenerList get touchCancel => this['touchcancel'];

  EventListenerList get touchEnd => this['touchend'];

  EventListenerList get touchEnter => this['touchenter'];

  EventListenerList get touchLeave => this['touchleave'];

  EventListenerList get touchMove => this['touchmove'];

  EventListenerList get touchStart => this['touchstart'];

  EventListenerList get transitionEnd => this['webkitTransitionEnd'];

  EventListenerList get fullscreenChange => this['webkitfullscreenchange'];

  EventListenerList get fullscreenError => this['webkitfullscreenerror'];

  EventListenerList get mouseWheel {
    if (JS('bool', '#.onwheel !== undefined', _ptr)) {
      // W3C spec, and should be IE9+, but IE has a bug exposing onwheel.
      return this['wheel'];
    } else if (JS('bool', '#.onmousewheel !== undefined', _ptr)) {
      // Chrome & IE
      return this['mousewheel'];
    } else {
      // Firefox
      return this['DOMMouseScroll'];
    }
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName ElementTimeControl
abstract class ElementTimeControl {

  /** @domName ElementTimeControl.beginElement */
  void beginElement();

  /** @domName ElementTimeControl.beginElementAt */
  void beginElementAt(num offset);

  /** @domName ElementTimeControl.endElement */
  void endElement();

  /** @domName ElementTimeControl.endElementAt */
  void endElementAt(num offset);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName ElementTraversal
abstract class ElementTraversal {

  int childElementCount;

  Element firstElementChild;

  Element lastElementChild;

  Element nextElementSibling;

  Element previousElementSibling;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLEmbedElement
class EmbedElement extends Element implements Element native "*HTMLEmbedElement" {

  factory EmbedElement() => _Elements.createEmbedElement();

  /** @domName HTMLEmbedElement.align */
  String align;

  /** @domName HTMLEmbedElement.height */
  String height;

  /** @domName HTMLEmbedElement.name */
  String name;

  /** @domName HTMLEmbedElement.src */
  String src;

  /** @domName HTMLEmbedElement.type */
  String type;

  /** @domName HTMLEmbedElement.width */
  String width;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName EntityReference
class EntityReference extends Node native "*EntityReference" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void EntriesCallback(List<Entry> entries);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Entry
class Entry native "*Entry" {

  /** @domName Entry.filesystem */
  final DOMFileSystem filesystem;

  /** @domName Entry.fullPath */
  final String fullPath;

  /** @domName Entry.isDirectory */
  final bool isDirectory;

  /** @domName Entry.isFile */
  final bool isFile;

  /** @domName Entry.name */
  final String name;

  /** @domName Entry.copyTo */
  void copyTo(DirectoryEntry parent, [String name, EntryCallback successCallback, ErrorCallback errorCallback]) native;

  /** @domName Entry.getMetadata */
  void getMetadata(MetadataCallback successCallback, [ErrorCallback errorCallback]) native;

  /** @domName Entry.getParent */
  void getParent([EntryCallback successCallback, ErrorCallback errorCallback]) native;

  /** @domName Entry.moveTo */
  void moveTo(DirectoryEntry parent, [String name, EntryCallback successCallback, ErrorCallback errorCallback]) native;

  /** @domName Entry.remove */
  void remove(VoidCallback successCallback, [ErrorCallback errorCallback]) native;

  /** @domName Entry.toURL */
  String toURL() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void EntryCallback(Entry entry);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName EntrySync
class EntrySync native "*EntrySync" {

  /** @domName EntrySync.filesystem */
  final DOMFileSystemSync filesystem;

  /** @domName EntrySync.fullPath */
  final String fullPath;

  /** @domName EntrySync.isDirectory */
  final bool isDirectory;

  /** @domName EntrySync.isFile */
  final bool isFile;

  /** @domName EntrySync.name */
  final String name;

  /** @domName EntrySync.copyTo */
  EntrySync copyTo(DirectoryEntrySync parent, String name) native;

  /** @domName EntrySync.getMetadata */
  Metadata getMetadata() native;

  /** @domName EntrySync.getParent */
  EntrySync getParent() native;

  /** @domName EntrySync.moveTo */
  EntrySync moveTo(DirectoryEntrySync parent, String name) native;

  /** @domName EntrySync.remove */
  void remove() native;

  /** @domName EntrySync.toURL */
  String toURL() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void ErrorCallback(FileError error);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName ErrorEvent
class ErrorEvent extends Event native "*ErrorEvent" {

  /** @domName ErrorEvent.filename */
  final String filename;

  /** @domName ErrorEvent.lineno */
  final int lineno;

  /** @domName ErrorEvent.message */
  final String message;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


class Event native "*Event" {
  // In JS, canBubble and cancelable are technically required parameters to
  // init*Event. In practice, though, if they aren't provided they simply
  // default to false (since that's Boolean(undefined)).
  //
  // Contrary to JS, we default canBubble and cancelable to true, since that's
  // what people want most of the time anyway.
  factory Event(String type, [bool canBubble = true, bool cancelable = true]) =>
      _EventFactoryProvider.createEvent(type, canBubble, cancelable);

  static const int AT_TARGET = 2;

  static const int BLUR = 8192;

  static const int BUBBLING_PHASE = 3;

  static const int CAPTURING_PHASE = 1;

  static const int CHANGE = 32768;

  static const int CLICK = 64;

  static const int DBLCLICK = 128;

  static const int DRAGDROP = 2048;

  static const int FOCUS = 4096;

  static const int KEYDOWN = 256;

  static const int KEYPRESS = 1024;

  static const int KEYUP = 512;

  static const int MOUSEDOWN = 1;

  static const int MOUSEDRAG = 32;

  static const int MOUSEMOVE = 16;

  static const int MOUSEOUT = 8;

  static const int MOUSEOVER = 4;

  static const int MOUSEUP = 2;

  static const int NONE = 0;

  static const int SELECT = 16384;

  /** @domName Event.bubbles */
  final bool bubbles;

  /** @domName Event.cancelBubble */
  bool cancelBubble;

  /** @domName Event.cancelable */
  final bool cancelable;

  /** @domName Event.clipboardData */
  final Clipboard clipboardData;

  /** @domName Event.currentTarget */
  EventTarget get currentTarget => _convertNativeToDart_EventTarget(this._currentTarget);
  dynamic get _currentTarget => JS("dynamic", "#.currentTarget", this);

  /** @domName Event.defaultPrevented */
  final bool defaultPrevented;

  /** @domName Event.eventPhase */
  final int eventPhase;

  /** @domName Event.returnValue */
  bool returnValue;

  /** @domName Event.srcElement */
  EventTarget get srcElement => _convertNativeToDart_EventTarget(this._srcElement);
  dynamic get _srcElement => JS("dynamic", "#.srcElement", this);

  /** @domName Event.target */
  EventTarget get target => _convertNativeToDart_EventTarget(this._target);
  dynamic get _target => JS("dynamic", "#.target", this);

  /** @domName Event.timeStamp */
  final int timeStamp;

  /** @domName Event.type */
  final String type;

  /** @domName Event.initEvent */
  void $dom_initEvent(String eventTypeArg, bool canBubbleArg, bool cancelableArg) native "initEvent";

  /** @domName Event.preventDefault */
  void preventDefault() native;

  /** @domName Event.stopImmediatePropagation */
  void stopImmediatePropagation() native;

  /** @domName Event.stopPropagation */
  void stopPropagation() native;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName EventException
class EventException native "*EventException" {

  static const int DISPATCH_REQUEST_ERR = 1;

  static const int UNSPECIFIED_EVENT_TYPE_ERR = 0;

  /** @domName EventException.code */
  final int code;

  /** @domName EventException.message */
  final String message;

  /** @domName EventException.name */
  final String name;

  /** @domName EventException.toString */
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName EventSource
class EventSource extends EventTarget native "*EventSource" {

  factory EventSource(String scriptUrl) => _EventSourceFactoryProvider.createEventSource(scriptUrl);

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  EventSourceEvents get on =>
    new EventSourceEvents(this);

  static const int CLOSED = 2;

  static const int CONNECTING = 0;

  static const int OPEN = 1;

  /** @domName EventSource.URL */
  final String URL;

  /** @domName EventSource.readyState */
  final int readyState;

  /** @domName EventSource.url */
  final String url;

  /** @domName EventSource.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "addEventListener";

  /** @domName EventSource.close */
  void close() native;

  /** @domName EventSource.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "dispatchEvent";

  /** @domName EventSource.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "removeEventListener";
}

class EventSourceEvents extends Events {
  EventSourceEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get error => this['error'];

  EventListenerList get message => this['message'];

  EventListenerList get open => this['open'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class Events {
  /* Raw event target. */
  final EventTarget _ptr;

  Events(this._ptr);

  EventListenerList operator [](String type) {
    return new EventListenerList(_ptr, type);
  }
}

class EventListenerList {

  final EventTarget _ptr;
  final String _type;

  EventListenerList(this._ptr, this._type);

  // TODO(jacobr): implement equals.

  EventListenerList add(EventListener listener,
      [bool useCapture = false]) {
    _add(listener, useCapture);
    return this;
  }

  EventListenerList remove(EventListener listener,
      [bool useCapture = false]) {
    _remove(listener, useCapture);
    return this;
  }

  bool dispatch(Event evt) {
    return _ptr.$dom_dispatchEvent(evt);
  }

  void _add(EventListener listener, bool useCapture) {
    _ptr.$dom_addEventListener(_type, listener, useCapture);
  }

  void _remove(EventListener listener, bool useCapture) {
    _ptr.$dom_removeEventListener(_type, listener, useCapture);
  }
}


class EventTarget native "*EventTarget" {

  /** @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent */
  Events get on => new Events(this);

  /** @domName EventTarget.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "addEventListener";

  /** @domName EventTarget.dispatchEvent */
  bool $dom_dispatchEvent(Event event) native "dispatchEvent";

  /** @domName EventTarget.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "removeEventListener";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLFieldSetElement
class FieldSetElement extends Element implements Element native "*HTMLFieldSetElement" {

  factory FieldSetElement() => _Elements.createFieldSetElement();

  /** @domName HTMLFieldSetElement.disabled */
  bool disabled;

  /** @domName HTMLFieldSetElement.elements */
  final HTMLCollection elements;

  /** @domName HTMLFieldSetElement.form */
  final FormElement form;

  /** @domName HTMLFieldSetElement.name */
  String name;

  /** @domName HTMLFieldSetElement.type */
  final String type;

  /** @domName HTMLFieldSetElement.validationMessage */
  final String validationMessage;

  /** @domName HTMLFieldSetElement.validity */
  final ValidityState validity;

  /** @domName HTMLFieldSetElement.willValidate */
  final bool willValidate;

  /** @domName HTMLFieldSetElement.checkValidity */
  bool checkValidity() native;

  /** @domName HTMLFieldSetElement.setCustomValidity */
  void setCustomValidity(String error) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName File
class File extends Blob native "*File" {

  /** @domName File.lastModifiedDate */
  final Date lastModifiedDate;

  /** @domName File.name */
  final String name;

  /** @domName File.webkitRelativePath */
  final String webkitRelativePath;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void FileCallback(File file);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName FileEntry
class FileEntry extends Entry native "*FileEntry" {

  /** @domName FileEntry.createWriter */
  void createWriter(FileWriterCallback successCallback, [ErrorCallback errorCallback]) native;

  /** @domName FileEntry.file */
  void file(FileCallback successCallback, [ErrorCallback errorCallback]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName FileEntrySync
class FileEntrySync extends EntrySync native "*FileEntrySync" {

  /** @domName FileEntrySync.createWriter */
  FileWriterSync createWriter() native;

  /** @domName FileEntrySync.file */
  File file() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName FileError
class FileError native "*FileError" {

  static const int ABORT_ERR = 3;

  static const int ENCODING_ERR = 5;

  static const int INVALID_MODIFICATION_ERR = 9;

  static const int INVALID_STATE_ERR = 7;

  static const int NOT_FOUND_ERR = 1;

  static const int NOT_READABLE_ERR = 4;

  static const int NO_MODIFICATION_ALLOWED_ERR = 6;

  static const int PATH_EXISTS_ERR = 12;

  static const int QUOTA_EXCEEDED_ERR = 10;

  static const int SECURITY_ERR = 2;

  static const int SYNTAX_ERR = 8;

  static const int TYPE_MISMATCH_ERR = 11;

  /** @domName FileError.code */
  final int code;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName FileException
class FileException native "*FileException" {

  static const int ABORT_ERR = 3;

  static const int ENCODING_ERR = 5;

  static const int INVALID_MODIFICATION_ERR = 9;

  static const int INVALID_STATE_ERR = 7;

  static const int NOT_FOUND_ERR = 1;

  static const int NOT_READABLE_ERR = 4;

  static const int NO_MODIFICATION_ALLOWED_ERR = 6;

  static const int PATH_EXISTS_ERR = 12;

  static const int QUOTA_EXCEEDED_ERR = 10;

  static const int SECURITY_ERR = 2;

  static const int SYNTAX_ERR = 8;

  static const int TYPE_MISMATCH_ERR = 11;

  /** @domName FileException.code */
  final int code;

  /** @domName FileException.message */
  final String message;

  /** @domName FileException.name */
  final String name;

  /** @domName FileException.toString */
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName FileReader
class FileReader extends EventTarget native "*FileReader" {

  factory FileReader() => _FileReaderFactoryProvider.createFileReader();

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  FileReaderEvents get on =>
    new FileReaderEvents(this);

  static const int DONE = 2;

  static const int EMPTY = 0;

  static const int LOADING = 1;

  /** @domName FileReader.error */
  final FileError error;

  /** @domName FileReader.readyState */
  final int readyState;

  /** @domName FileReader.result */
  final Object result;

  /** @domName FileReader.abort */
  void abort() native;

  /** @domName FileReader.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "addEventListener";

  /** @domName FileReader.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "dispatchEvent";

  /** @domName FileReader.readAsArrayBuffer */
  void readAsArrayBuffer(Blob blob) native;

  /** @domName FileReader.readAsBinaryString */
  void readAsBinaryString(Blob blob) native;

  /** @domName FileReader.readAsDataURL */
  void readAsDataURL(Blob blob) native;

  /** @domName FileReader.readAsText */
  void readAsText(Blob blob, [String encoding]) native;

  /** @domName FileReader.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "removeEventListener";
}

class FileReaderEvents extends Events {
  FileReaderEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get abort => this['abort'];

  EventListenerList get error => this['error'];

  EventListenerList get load => this['load'];

  EventListenerList get loadEnd => this['loadend'];

  EventListenerList get loadStart => this['loadstart'];

  EventListenerList get progress => this['progress'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName FileReaderSync
class FileReaderSync native "*FileReaderSync" {

  factory FileReaderSync() => _FileReaderSyncFactoryProvider.createFileReaderSync();

  /** @domName FileReaderSync.readAsArrayBuffer */
  ArrayBuffer readAsArrayBuffer(Blob blob) native;

  /** @domName FileReaderSync.readAsBinaryString */
  String readAsBinaryString(Blob blob) native;

  /** @domName FileReaderSync.readAsDataURL */
  String readAsDataURL(Blob blob) native;

  /** @domName FileReaderSync.readAsText */
  String readAsText(Blob blob, [String encoding]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void FileSystemCallback(DOMFileSystem fileSystem);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName FileWriter
class FileWriter extends EventTarget native "*FileWriter" {

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  FileWriterEvents get on =>
    new FileWriterEvents(this);

  static const int DONE = 2;

  static const int INIT = 0;

  static const int WRITING = 1;

  /** @domName FileWriter.error */
  final FileError error;

  /** @domName FileWriter.length */
  final int length;

  /** @domName FileWriter.position */
  final int position;

  /** @domName FileWriter.readyState */
  final int readyState;

  /** @domName FileWriter.abort */
  void abort() native;

  /** @domName FileWriter.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "addEventListener";

  /** @domName FileWriter.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "dispatchEvent";

  /** @domName FileWriter.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "removeEventListener";

  /** @domName FileWriter.seek */
  void seek(int position) native;

  /** @domName FileWriter.truncate */
  void truncate(int size) native;

  /** @domName FileWriter.write */
  void write(Blob data) native;
}

class FileWriterEvents extends Events {
  FileWriterEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get abort => this['abort'];

  EventListenerList get error => this['error'];

  EventListenerList get progress => this['progress'];

  EventListenerList get write => this['write'];

  EventListenerList get writeEnd => this['writeend'];

  EventListenerList get writeStart => this['writestart'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void FileWriterCallback(FileWriter fileWriter);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName FileWriterSync
class FileWriterSync native "*FileWriterSync" {

  /** @domName FileWriterSync.length */
  final int length;

  /** @domName FileWriterSync.position */
  final int position;

  /** @domName FileWriterSync.seek */
  void seek(int position) native;

  /** @domName FileWriterSync.truncate */
  void truncate(int size) native;

  /** @domName FileWriterSync.write */
  void write(Blob data) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Float32Array
class Float32Array extends ArrayBufferView implements JavaScriptIndexingBehavior, List<num> native "*Float32Array" {

  factory Float32Array(int length) =>
    _TypedArrayFactoryProvider.createFloat32Array(length);

  factory Float32Array.fromList(List<num> list) =>
    _TypedArrayFactoryProvider.createFloat32Array_fromList(list);

  factory Float32Array.fromBuffer(ArrayBuffer buffer, [int byteOffset, int length]) => 
    _TypedArrayFactoryProvider.createFloat32Array_fromBuffer(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 4;

  /** @domName Float32Array.length */
  final int length;

  num operator[](int index) => JS("num", "#[#]", this, index);

  void operator[]=(int index, num value) => JS("void", "#[#] = #", this, index, value);
  // -- start List<num> mixins.
  // num is the element type.

  // From Iterable<num>:

  Iterator<num> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<num>(this);
  }

  // From Collection<num>:

  void add(num value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(num value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<num> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(num element) => _Collections.contains(this, element);

  void forEach(void f(num element)) => _Collections.forEach(this, f);

  Collection map(f(num element)) => _Collections.map(this, [], f);

  Collection<num> filter(bool f(num element)) =>
     _Collections.filter(this, <num>[], f);

  bool every(bool f(num element)) => _Collections.every(this, f);

  bool some(bool f(num element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<num>:

  void sort([Comparator<num> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(num element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(num element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  num get last => this[length - 1];

  num removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<num> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [num initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<num> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <num>[]);

  // -- end List<num> mixins.

  /** @domName Float32Array.setElements */
  void setElements(Object array, [int offset]) native "set";

  /** @domName Float32Array.subarray */
  Float32Array subarray(int start, [int end]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Float64Array
class Float64Array extends ArrayBufferView implements JavaScriptIndexingBehavior, List<num> native "*Float64Array" {

  factory Float64Array(int length) =>
    _TypedArrayFactoryProvider.createFloat64Array(length);

  factory Float64Array.fromList(List<num> list) =>
    _TypedArrayFactoryProvider.createFloat64Array_fromList(list);

  factory Float64Array.fromBuffer(ArrayBuffer buffer, [int byteOffset, int length]) => 
    _TypedArrayFactoryProvider.createFloat64Array_fromBuffer(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 8;

  /** @domName Float64Array.length */
  final int length;

  num operator[](int index) => JS("num", "#[#]", this, index);

  void operator[]=(int index, num value) => JS("void", "#[#] = #", this, index, value);
  // -- start List<num> mixins.
  // num is the element type.

  // From Iterable<num>:

  Iterator<num> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<num>(this);
  }

  // From Collection<num>:

  void add(num value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(num value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<num> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(num element) => _Collections.contains(this, element);

  void forEach(void f(num element)) => _Collections.forEach(this, f);

  Collection map(f(num element)) => _Collections.map(this, [], f);

  Collection<num> filter(bool f(num element)) =>
     _Collections.filter(this, <num>[], f);

  bool every(bool f(num element)) => _Collections.every(this, f);

  bool some(bool f(num element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<num>:

  void sort([Comparator<num> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(num element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(num element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  num get last => this[length - 1];

  num removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<num> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [num initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<num> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <num>[]);

  // -- end List<num> mixins.

  /** @domName Float64Array.setElements */
  void setElements(Object array, [int offset]) native "set";

  /** @domName Float64Array.subarray */
  Float64Array subarray(int start, [int end]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLFontElement
class FontElement extends Element implements Element native "*HTMLFontElement" {

  /** @domName HTMLFontElement.color */
  String color;

  /** @domName HTMLFontElement.face */
  String face;

  /** @domName HTMLFontElement.size */
  String size;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName FormData
class FormData native "*FormData" {

  factory FormData([FormElement form]) {
    if (!?form) {
      return _FormDataFactoryProvider.createFormData();
    }
    return _FormDataFactoryProvider.createFormData(form);
  }

  /** @domName FormData.append */
  void append(String name, String value, String filename) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLFormElement
class FormElement extends Element implements Element native "*HTMLFormElement" {

  factory FormElement() => _Elements.createFormElement();

  /** @domName HTMLFormElement.acceptCharset */
  String acceptCharset;

  /** @domName HTMLFormElement.action */
  String action;

  /** @domName HTMLFormElement.autocomplete */
  String autocomplete;

  /** @domName HTMLFormElement.encoding */
  String encoding;

  /** @domName HTMLFormElement.enctype */
  String enctype;

  /** @domName HTMLFormElement.length */
  final int length;

  /** @domName HTMLFormElement.method */
  String method;

  /** @domName HTMLFormElement.name */
  String name;

  /** @domName HTMLFormElement.noValidate */
  bool noValidate;

  /** @domName HTMLFormElement.target */
  String target;

  /** @domName HTMLFormElement.checkValidity */
  bool checkValidity() native;

  /** @domName HTMLFormElement.reset */
  void reset() native;

  /** @domName HTMLFormElement.submit */
  void submit() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLFrameElement
class FrameElement extends Element implements Element native "*HTMLFrameElement" {

  /** @domName HTMLFrameElement.contentWindow */
  Window get contentWindow => _convertNativeToDart_Window(this._contentWindow);
  dynamic get _contentWindow => JS("dynamic", "#.contentWindow", this);

  /** @domName HTMLFrameElement.frameBorder */
  String frameBorder;

  /** @domName HTMLFrameElement.height */
  final int height;

  /** @domName HTMLFrameElement.location */
  String location;

  /** @domName HTMLFrameElement.longDesc */
  String longDesc;

  /** @domName HTMLFrameElement.marginHeight */
  String marginHeight;

  /** @domName HTMLFrameElement.marginWidth */
  String marginWidth;

  /** @domName HTMLFrameElement.name */
  String name;

  /** @domName HTMLFrameElement.noResize */
  bool noResize;

  /** @domName HTMLFrameElement.scrolling */
  String scrolling;

  /** @domName HTMLFrameElement.src */
  String src;

  /** @domName HTMLFrameElement.width */
  final int width;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLFrameSetElement
class FrameSetElement extends Element implements Element native "*HTMLFrameSetElement" {

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  FrameSetElementEvents get on =>
    new FrameSetElementEvents(this);

  /** @domName HTMLFrameSetElement.cols */
  String cols;

  /** @domName HTMLFrameSetElement.rows */
  String rows;
}

class FrameSetElementEvents extends ElementEvents {
  FrameSetElementEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get beforeUnload => this['beforeunload'];

  EventListenerList get blur => this['blur'];

  EventListenerList get error => this['error'];

  EventListenerList get focus => this['focus'];

  EventListenerList get hashChange => this['hashchange'];

  EventListenerList get load => this['load'];

  EventListenerList get message => this['message'];

  EventListenerList get offline => this['offline'];

  EventListenerList get online => this['online'];

  EventListenerList get popState => this['popstate'];

  EventListenerList get resize => this['resize'];

  EventListenerList get storage => this['storage'];

  EventListenerList get unload => this['unload'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName GainNode
class GainNode extends AudioNode native "*GainNode" {

  /** @domName GainNode.gain */
  final AudioGain gain;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Gamepad
class Gamepad native "*Gamepad" {

  /** @domName Gamepad.axes */
  final List<num> axes;

  /** @domName Gamepad.buttons */
  final List<num> buttons;

  /** @domName Gamepad.id */
  final String id;

  /** @domName Gamepad.index */
  final int index;

  /** @domName Gamepad.timestamp */
  final int timestamp;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Geolocation
class Geolocation native "*Geolocation" {

  /** @domName Geolocation.clearWatch */
  void clearWatch(int watchId) native;

  /** @domName Geolocation.getCurrentPosition */
  void getCurrentPosition(PositionCallback successCallback, [PositionErrorCallback errorCallback, Object options]) native;

  /** @domName Geolocation.watchPosition */
  int watchPosition(PositionCallback successCallback, [PositionErrorCallback errorCallback, Object options]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Geoposition
class Geoposition native "*Geoposition" {

  /** @domName Geoposition.coords */
  final Coordinates coords;

  /** @domName Geoposition.timestamp */
  final int timestamp;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLHRElement
class HRElement extends Element implements Element native "*HTMLHRElement" {

  factory HRElement() => _Elements.createHRElement();

  /** @domName HTMLHRElement.align */
  String align;

  /** @domName HTMLHRElement.noShade */
  bool noShade;

  /** @domName HTMLHRElement.size */
  String size;

  /** @domName HTMLHRElement.width */
  String width;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLAllCollection
class HTMLAllCollection implements JavaScriptIndexingBehavior, List<Node> native "*HTMLAllCollection" {

  /** @domName HTMLAllCollection.length */
  final int length;

  Node operator[](int index) => JS("Node", "#[#]", this, index);

  void operator[]=(int index, Node value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Node> mixins.
  // Node is the element type.

  // From Iterable<Node>:

  Iterator<Node> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Node>(this);
  }

  // From Collection<Node>:

  void add(Node value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(Node value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<Node> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(Node element) => _Collections.contains(this, element);

  void forEach(void f(Node element)) => _Collections.forEach(this, f);

  Collection map(f(Node element)) => _Collections.map(this, [], f);

  Collection<Node> filter(bool f(Node element)) =>
     _Collections.filter(this, <Node>[], f);

  bool every(bool f(Node element)) => _Collections.every(this, f);

  bool some(bool f(Node element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<Node>:

  void sort([Comparator<Node> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Node element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Node element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  Node get last => this[length - 1];

  Node removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<Node> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [Node initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<Node> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <Node>[]);

  // -- end List<Node> mixins.

  /** @domName HTMLAllCollection.item */
  Node item(int index) native;

  /** @domName HTMLAllCollection.namedItem */
  Node namedItem(String name) native;

  /** @domName HTMLAllCollection.tags */
  List<Node> tags(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLCollection
class HTMLCollection implements JavaScriptIndexingBehavior, List<Node> native "*HTMLCollection" {

  /** @domName HTMLCollection.length */
  final int length;

  Node operator[](int index) => JS("Node", "#[#]", this, index);

  void operator[]=(int index, Node value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Node> mixins.
  // Node is the element type.

  // From Iterable<Node>:

  Iterator<Node> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Node>(this);
  }

  // From Collection<Node>:

  void add(Node value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(Node value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<Node> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(Node element) => _Collections.contains(this, element);

  void forEach(void f(Node element)) => _Collections.forEach(this, f);

  Collection map(f(Node element)) => _Collections.map(this, [], f);

  Collection<Node> filter(bool f(Node element)) =>
     _Collections.filter(this, <Node>[], f);

  bool every(bool f(Node element)) => _Collections.every(this, f);

  bool some(bool f(Node element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<Node>:

  void sort([Comparator<Node> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Node element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Node element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  Node get last => this[length - 1];

  Node removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<Node> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [Node initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<Node> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <Node>[]);

  // -- end List<Node> mixins.

  /** @domName HTMLCollection.item */
  Node item(int index) native;

  /** @domName HTMLCollection.namedItem */
  Node namedItem(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLOptionsCollection
class HTMLOptionsCollection extends HTMLCollection native "*HTMLOptionsCollection" {

  // Shadowing definition.
  /** @domName HTMLOptionsCollection.length */
  int get length => JS("int", "#.length", this);

  /** @domName HTMLOptionsCollection.length */
  void set length(int value) {
    JS("void", "#.length = #", this, value);
  }

  /** @domName HTMLOptionsCollection.selectedIndex */
  int selectedIndex;

  /** @domName HTMLOptionsCollection.remove */
  void remove(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HashChangeEvent
class HashChangeEvent extends Event native "*HashChangeEvent" {

  /** @domName HashChangeEvent.newURL */
  final String newURL;

  /** @domName HashChangeEvent.oldURL */
  final String oldURL;

  /** @domName HashChangeEvent.initHashChangeEvent */
  void initHashChangeEvent(String type, bool canBubble, bool cancelable, String oldURL, String newURL) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLHeadElement
class HeadElement extends Element implements Element native "*HTMLHeadElement" {

  factory HeadElement() => _Elements.createHeadElement();

  /** @domName HTMLHeadElement.profile */
  String profile;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLHeadingElement
class HeadingElement extends Element implements Element native "*HTMLHeadingElement" {

  factory HeadingElement.h1() => _Elements.createHeadingElement_h1();

  factory HeadingElement.h2() => _Elements.createHeadingElement_h2();

  factory HeadingElement.h3() => _Elements.createHeadingElement_h3();

  factory HeadingElement.h4() => _Elements.createHeadingElement_h4();

  factory HeadingElement.h5() => _Elements.createHeadingElement_h5();

  factory HeadingElement.h6() => _Elements.createHeadingElement_h6();

  /** @domName HTMLHeadingElement.align */
  String align;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLHtmlElement
class HtmlElement extends Element implements Element native "*HTMLHtmlElement" {

  factory HtmlElement() => _Elements.createHtmlElement();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class HttpRequest extends EventTarget native "*XMLHttpRequest" {
  factory HttpRequest.get(String url, onSuccess(HttpRequest request)) =>
      _HttpRequestFactoryProvider.createHttpRequest_get(url, onSuccess);

  factory HttpRequest.getWithCredentials(String url, onSuccess(HttpRequest request)) =>
      _HttpRequestFactoryProvider.createHttpRequestgetWithCredentials(url, onSuccess);


  factory HttpRequest() => _HttpRequestFactoryProvider.createHttpRequest();

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  HttpRequestEvents get on =>
    new HttpRequestEvents(this);

  static const int DONE = 4;

  static const int HEADERS_RECEIVED = 2;

  static const int LOADING = 3;

  static const int OPENED = 1;

  static const int UNSENT = 0;

  /** @domName XMLHttpRequest.readyState */
  final int readyState;

  /** @domName XMLHttpRequest.response */
  final Object response;

  /** @domName XMLHttpRequest.responseText */
  final String responseText;

  /** @domName XMLHttpRequest.responseType */
  String responseType;

  /** @domName XMLHttpRequest.responseXML */
  final Document responseXML;

  /** @domName XMLHttpRequest.status */
  final int status;

  /** @domName XMLHttpRequest.statusText */
  final String statusText;

  /** @domName XMLHttpRequest.upload */
  final HttpRequestUpload upload;

  /** @domName XMLHttpRequest.withCredentials */
  bool withCredentials;

  /** @domName XMLHttpRequest.abort */
  void abort() native;

  /** @domName XMLHttpRequest.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "addEventListener";

  /** @domName XMLHttpRequest.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "dispatchEvent";

  /** @domName XMLHttpRequest.getAllResponseHeaders */
  String getAllResponseHeaders() native;

  /** @domName XMLHttpRequest.getResponseHeader */
  String getResponseHeader(String header) native;

  /** @domName XMLHttpRequest.open */
  void open(String method, String url, [bool async, String user, String password]) native;

  /** @domName XMLHttpRequest.overrideMimeType */
  void overrideMimeType(String override) native;

  /** @domName XMLHttpRequest.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "removeEventListener";

  /** @domName XMLHttpRequest.send */
  void send([data]) native;

  /** @domName XMLHttpRequest.setRequestHeader */
  void setRequestHeader(String header, String value) native;

}

class HttpRequestEvents extends Events {
  HttpRequestEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get abort => this['abort'];

  EventListenerList get error => this['error'];

  EventListenerList get load => this['load'];

  EventListenerList get loadEnd => this['loadend'];

  EventListenerList get loadStart => this['loadstart'];

  EventListenerList get progress => this['progress'];

  EventListenerList get readyStateChange => this['readystatechange'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName XMLHttpRequestException
class HttpRequestException native "*XMLHttpRequestException" {

  static const int ABORT_ERR = 102;

  static const int NETWORK_ERR = 101;

  /** @domName XMLHttpRequestException.code */
  final int code;

  /** @domName XMLHttpRequestException.message */
  final String message;

  /** @domName XMLHttpRequestException.name */
  final String name;

  /** @domName XMLHttpRequestException.toString */
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName XMLHttpRequestProgressEvent
class HttpRequestProgressEvent extends ProgressEvent native "*XMLHttpRequestProgressEvent" {

  /** @domName XMLHttpRequestProgressEvent.position */
  final int position;

  /** @domName XMLHttpRequestProgressEvent.totalSize */
  final int totalSize;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName XMLHttpRequestUpload
class HttpRequestUpload extends EventTarget native "*XMLHttpRequestUpload" {

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  HttpRequestUploadEvents get on =>
    new HttpRequestUploadEvents(this);

  /** @domName XMLHttpRequestUpload.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "addEventListener";

  /** @domName XMLHttpRequestUpload.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "dispatchEvent";

  /** @domName XMLHttpRequestUpload.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "removeEventListener";
}

class HttpRequestUploadEvents extends Events {
  HttpRequestUploadEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get abort => this['abort'];

  EventListenerList get error => this['error'];

  EventListenerList get load => this['load'];

  EventListenerList get loadEnd => this['loadend'];

  EventListenerList get loadStart => this['loadstart'];

  EventListenerList get progress => this['progress'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName IDBAny
class IDBAny native "*IDBAny" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName IDBCursor
class IDBCursor native "*IDBCursor" {

  static const int NEXT = 0;

  static const int NEXT_NO_DUPLICATE = 1;

  static const int PREV = 2;

  static const int PREV_NO_DUPLICATE = 3;

  /** @domName IDBCursor.direction */
  final String direction;

  /** @domName IDBCursor.key */
  final Object key;

  /** @domName IDBCursor.primaryKey */
  final Object primaryKey;

  /** @domName IDBCursor.source */
  final dynamic source;

  /** @domName IDBCursor.advance */
  void advance(int count) native;

  /** @domName IDBCursor.continueFunction */
  void continueFunction([/*IDBKey*/ key]) {
    if (?key) {
      var key_1 = _convertDartToNative_IDBKey(key);
      _continueFunction_1(key_1);
      return;
    }
    _continueFunction_2();
    return;
  }
  void _continueFunction_1(key) native "continue";
  void _continueFunction_2() native "continue";

  /** @domName IDBCursor.delete */
  IDBRequest delete() native;

  /** @domName IDBCursor.update */
  IDBRequest update(/*any*/ value) {
    var value_1 = _convertDartToNative_SerializedScriptValue(value);
    return _update_1(value_1);
  }
  IDBRequest _update_1(value) native "update";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName IDBCursorWithValue
class IDBCursorWithValue extends IDBCursor native "*IDBCursorWithValue" {

  /** @domName IDBCursorWithValue.value */
  final Object value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class IDBDatabase extends EventTarget native "*IDBDatabase" {

  IDBTransaction transaction(storeName_OR_storeNames, String mode) {
    if (mode != 'readonly' && mode != 'readwrite') {
      throw new ArgumentError(mode);
    }

    // TODO(sra): Ensure storeName_OR_storeNames is a string or List<String>,
    // and copy to JavaScript array if necessary.

    if (_transaction_fn != null) {
      return _transaction_fn(this, storeName_OR_storeNames, mode);
    }

    // Try and create a transaction with a string mode.  Browsers that expect a
    // numeric mode tend to convert the string into a number.  This fails
    // silently, resulting in zero ('readonly').
    var txn = _transaction(storeName_OR_storeNames, mode);
    if (_hasNumericMode(txn)) {
      _transaction_fn = _transaction_numeric_mode;
      txn = _transaction_fn(this, storeName_OR_storeNames, mode);
    } else {
      _transaction_fn = _transaction_string_mode;
    }
    return txn;
  }

  static IDBTransaction _transaction_string_mode(IDBDatabase db, stores, mode) {
    return db._transaction(stores, mode);
  }

  static IDBTransaction _transaction_numeric_mode(IDBDatabase db, stores, mode) {
    int intMode;
    if (mode == 'readonly') intMode = IDBTransaction.READ_ONLY;
    if (mode == 'readwrite') intMode = IDBTransaction.READ_WRITE;
    return db._transaction(stores, intMode);
  }

  IDBTransaction _transaction(stores, mode) native 'transaction';

  static bool _hasNumericMode(txn) =>
      JS('bool', 'typeof(#.mode) === "number"', txn);


  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  IDBDatabaseEvents get on =>
    new IDBDatabaseEvents(this);

  /** @domName IDBDatabase.name */
  final String name;

  /** @domName IDBDatabase.objectStoreNames */
  final List<String> objectStoreNames;

  /** @domName IDBDatabase.version */
  final dynamic version;

  /** @domName IDBDatabase.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "addEventListener";

  /** @domName IDBDatabase.close */
  void close() native;

  /** @domName IDBDatabase.createObjectStore */
  IDBObjectStore createObjectStore(String name, [Map options]) {
    if (?options) {
      var options_1 = _convertDartToNative_Dictionary(options);
      return _createObjectStore_1(name, options_1);
    }
    return _createObjectStore_2(name);
  }
  IDBObjectStore _createObjectStore_1(name, options) native "createObjectStore";
  IDBObjectStore _createObjectStore_2(name) native "createObjectStore";

  /** @domName IDBDatabase.deleteObjectStore */
  void deleteObjectStore(String name) native;

  /** @domName IDBDatabase.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "dispatchEvent";

  /** @domName IDBDatabase.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "removeEventListener";

  /** @domName IDBDatabase.setVersion */
  IDBVersionChangeRequest setVersion(String version) native;
}

// TODO(sra): This should be a static member of IDBTransaction but dart2js
// can't handle that.  Move it back after dart2js is completely done.
var _transaction_fn;  // Assigned one of the static methods.

class IDBDatabaseEvents extends Events {
  IDBDatabaseEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get abort => this['abort'];

  EventListenerList get error => this['error'];

  EventListenerList get versionChange => this['versionchange'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName IDBDatabaseException
class IDBDatabaseException native "*IDBDatabaseException" {

  static const int ABORT_ERR = 20;

  static const int CONSTRAINT_ERR = 4;

  static const int DATA_ERR = 5;

  static const int NON_TRANSIENT_ERR = 2;

  static const int NOT_ALLOWED_ERR = 6;

  static const int NOT_FOUND_ERR = 8;

  static const int NO_ERR = 0;

  static const int QUOTA_ERR = 22;

  static const int READ_ONLY_ERR = 9;

  static const int TIMEOUT_ERR = 23;

  static const int TRANSACTION_INACTIVE_ERR = 7;

  static const int UNKNOWN_ERR = 1;

  static const int VER_ERR = 12;

  /** @domName IDBDatabaseException.code */
  final int code;

  /** @domName IDBDatabaseException.message */
  final String message;

  /** @domName IDBDatabaseException.name */
  final String name;

  /** @domName IDBDatabaseException.toString */
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName IDBFactory
class IDBFactory native "*IDBFactory" {

  /** @domName IDBFactory.cmp */
  int cmp(/*IDBKey*/ first, /*IDBKey*/ second) {
    var first_1 = _convertDartToNative_IDBKey(first);
    var second_2 = _convertDartToNative_IDBKey(second);
    return _cmp_1(first_1, second_2);
  }
  int _cmp_1(first, second) native "cmp";

  /** @domName IDBFactory.deleteDatabase */
  IDBVersionChangeRequest deleteDatabase(String name) native;

  /** @domName IDBFactory.open */
  IDBOpenDBRequest open(String name, [int version]) native;

  /** @domName IDBFactory.webkitGetDatabaseNames */
  IDBRequest webkitGetDatabaseNames() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName IDBIndex
class IDBIndex native "*IDBIndex" {

  /** @domName IDBIndex.keyPath */
  final dynamic keyPath;

  /** @domName IDBIndex.multiEntry */
  final bool multiEntry;

  /** @domName IDBIndex.name */
  final String name;

  /** @domName IDBIndex.objectStore */
  final IDBObjectStore objectStore;

  /** @domName IDBIndex.unique */
  final bool unique;

  /** @domName IDBIndex.count */
  IDBRequest count([key_OR_range]) {
    if (!?key_OR_range) {
      return _count_1();
    }
    if ((?key_OR_range && (key_OR_range is IDBKeyRange || key_OR_range == null))) {
      return _count_2(key_OR_range);
    }
    if (?key_OR_range) {
      var key_1 = _convertDartToNative_IDBKey(key_OR_range);
      return _count_3(key_1);
    }
    throw const Exception("Incorrect number or type of arguments");
  }
  IDBRequest _count_1() native "count";
  IDBRequest _count_2(IDBKeyRange range) native "count";
  IDBRequest _count_3(key) native "count";

  /** @domName IDBIndex.get */
  IDBRequest get(key) {
    if ((?key && (key is IDBKeyRange || key == null))) {
      return _get_1(key);
    }
    if (?key) {
      var key_1 = _convertDartToNative_IDBKey(key);
      return _get_2(key_1);
    }
    throw const Exception("Incorrect number or type of arguments");
  }
  IDBRequest _get_1(IDBKeyRange key) native "get";
  IDBRequest _get_2(key) native "get";

  /** @domName IDBIndex.getKey */
  IDBRequest getKey(key) {
    if ((?key && (key is IDBKeyRange || key == null))) {
      return _getKey_1(key);
    }
    if (?key) {
      var key_1 = _convertDartToNative_IDBKey(key);
      return _getKey_2(key_1);
    }
    throw const Exception("Incorrect number or type of arguments");
  }
  IDBRequest _getKey_1(IDBKeyRange key) native "getKey";
  IDBRequest _getKey_2(key) native "getKey";

  /** @domName IDBIndex.openCursor */
  IDBRequest openCursor([key_OR_range, String direction]) {
    if (!?key_OR_range &&
        !?direction) {
      return _openCursor_1();
    }
    if ((?key_OR_range && (key_OR_range is IDBKeyRange || key_OR_range == null)) &&
        !?direction) {
      return _openCursor_2(key_OR_range);
    }
    if ((?key_OR_range && (key_OR_range is IDBKeyRange || key_OR_range == null))) {
      return _openCursor_3(key_OR_range, direction);
    }
    if (?key_OR_range &&
        !?direction) {
      var key_1 = _convertDartToNative_IDBKey(key_OR_range);
      return _openCursor_4(key_1);
    }
    if (?key_OR_range) {
      var key_2 = _convertDartToNative_IDBKey(key_OR_range);
      return _openCursor_5(key_2, direction);
    }
    throw const Exception("Incorrect number or type of arguments");
  }
  IDBRequest _openCursor_1() native "openCursor";
  IDBRequest _openCursor_2(IDBKeyRange range) native "openCursor";
  IDBRequest _openCursor_3(IDBKeyRange range, direction) native "openCursor";
  IDBRequest _openCursor_4(key) native "openCursor";
  IDBRequest _openCursor_5(key, direction) native "openCursor";

  /** @domName IDBIndex.openKeyCursor */
  IDBRequest openKeyCursor([key_OR_range, String direction]) {
    if (!?key_OR_range &&
        !?direction) {
      return _openKeyCursor_1();
    }
    if ((?key_OR_range && (key_OR_range is IDBKeyRange || key_OR_range == null)) &&
        !?direction) {
      return _openKeyCursor_2(key_OR_range);
    }
    if ((?key_OR_range && (key_OR_range is IDBKeyRange || key_OR_range == null))) {
      return _openKeyCursor_3(key_OR_range, direction);
    }
    if (?key_OR_range &&
        !?direction) {
      var key_1 = _convertDartToNative_IDBKey(key_OR_range);
      return _openKeyCursor_4(key_1);
    }
    if (?key_OR_range) {
      var key_2 = _convertDartToNative_IDBKey(key_OR_range);
      return _openKeyCursor_5(key_2, direction);
    }
    throw const Exception("Incorrect number or type of arguments");
  }
  IDBRequest _openKeyCursor_1() native "openKeyCursor";
  IDBRequest _openKeyCursor_2(IDBKeyRange range) native "openKeyCursor";
  IDBRequest _openKeyCursor_3(IDBKeyRange range, direction) native "openKeyCursor";
  IDBRequest _openKeyCursor_4(key) native "openKeyCursor";
  IDBRequest _openKeyCursor_5(key, direction) native "openKeyCursor";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName IDBKey
class IDBKey native "*IDBKey" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class IDBKeyRange native "*IDBKeyRange" {
  /**
   * @domName IDBKeyRange.only
   */
  factory IDBKeyRange.only(/*IDBKey*/ value) =>
      _IDBKeyRangeFactoryProvider.createIDBKeyRange_only(value);

  /**
   * @domName IDBKeyRange.lowerBound
   */
  factory IDBKeyRange.lowerBound(/*IDBKey*/ bound, [bool open = false]) =>
      _IDBKeyRangeFactoryProvider.createIDBKeyRange_lowerBound(bound, open);

  /**
   * @domName IDBKeyRange.upperBound
   */
  factory IDBKeyRange.upperBound(/*IDBKey*/ bound, [bool open = false]) =>
      _IDBKeyRangeFactoryProvider.createIDBKeyRange_upperBound(bound, open);

  /**
   * @domName IDBKeyRange.bound
   */
  factory IDBKeyRange.bound(/*IDBKey*/ lower, /*IDBKey*/ upper,
                            [bool lowerOpen = false, bool upperOpen = false]) =>
      _IDBKeyRangeFactoryProvider.createIDBKeyRange_bound(
          lower, upper, lowerOpen, upperOpen);


  /** @domName IDBKeyRange.lower */
  dynamic get lower => _convertNativeToDart_IDBKey(this._lower);
  dynamic get _lower => JS("dynamic", "#.lower", this);

  /** @domName IDBKeyRange.lowerOpen */
  final bool lowerOpen;

  /** @domName IDBKeyRange.upper */
  dynamic get upper => _convertNativeToDart_IDBKey(this._upper);
  dynamic get _upper => JS("dynamic", "#.upper", this);

  /** @domName IDBKeyRange.upperOpen */
  final bool upperOpen;

  /** @domName IDBKeyRange.bound_ */
  static IDBKeyRange bound_(/*IDBKey*/ lower, /*IDBKey*/ upper, [bool lowerOpen, bool upperOpen]) {
    if (?upperOpen) {
      var lower_1 = _convertDartToNative_IDBKey(lower);
      var upper_2 = _convertDartToNative_IDBKey(upper);
      return _bound__1(lower_1, upper_2, lowerOpen, upperOpen);
    }
    if (?lowerOpen) {
      var lower_3 = _convertDartToNative_IDBKey(lower);
      var upper_4 = _convertDartToNative_IDBKey(upper);
      return _bound__2(lower_3, upper_4, lowerOpen);
    }
    var lower_5 = _convertDartToNative_IDBKey(lower);
    var upper_6 = _convertDartToNative_IDBKey(upper);
    return _bound__3(lower_5, upper_6);
  }
  IDBKeyRange _bound__1(lower, upper, lowerOpen, upperOpen) native "bound";
  IDBKeyRange _bound__2(lower, upper, lowerOpen) native "bound";
  IDBKeyRange _bound__3(lower, upper) native "bound";

  /** @domName IDBKeyRange.lowerBound_ */
  static IDBKeyRange lowerBound_(/*IDBKey*/ bound, [bool open]) {
    if (?open) {
      var bound_1 = _convertDartToNative_IDBKey(bound);
      return _lowerBound__1(bound_1, open);
    }
    var bound_2 = _convertDartToNative_IDBKey(bound);
    return _lowerBound__2(bound_2);
  }
  IDBKeyRange _lowerBound__1(bound, open) native "lowerBound";
  IDBKeyRange _lowerBound__2(bound) native "lowerBound";

  /** @domName IDBKeyRange.only_ */
  static IDBKeyRange only_(/*IDBKey*/ value) {
    var value_1 = _convertDartToNative_IDBKey(value);
    return _only__1(value_1);
  }
  IDBKeyRange _only__1(value) native "only";

  /** @domName IDBKeyRange.upperBound_ */
  static IDBKeyRange upperBound_(/*IDBKey*/ bound, [bool open]) {
    if (?open) {
      var bound_1 = _convertDartToNative_IDBKey(bound);
      return _upperBound__1(bound_1, open);
    }
    var bound_2 = _convertDartToNative_IDBKey(bound);
    return _upperBound__2(bound_2);
  }
  IDBKeyRange _upperBound__1(bound, open) native "upperBound";
  IDBKeyRange _upperBound__2(bound) native "upperBound";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName IDBObjectStore
class IDBObjectStore native "*IDBObjectStore" {

  /** @domName IDBObjectStore.autoIncrement */
  final bool autoIncrement;

  /** @domName IDBObjectStore.indexNames */
  final List<String> indexNames;

  /** @domName IDBObjectStore.keyPath */
  final dynamic keyPath;

  /** @domName IDBObjectStore.name */
  final String name;

  /** @domName IDBObjectStore.transaction */
  final IDBTransaction transaction;

  /** @domName IDBObjectStore.add */
  IDBRequest add(/*any*/ value, [/*IDBKey*/ key]) {
    if (?key) {
      var value_1 = _convertDartToNative_SerializedScriptValue(value);
      var key_2 = _convertDartToNative_IDBKey(key);
      return _add_1(value_1, key_2);
    }
    var value_3 = _convertDartToNative_SerializedScriptValue(value);
    return _add_2(value_3);
  }
  IDBRequest _add_1(value, key) native "add";
  IDBRequest _add_2(value) native "add";

  /** @domName IDBObjectStore.clear */
  IDBRequest clear() native;

  /** @domName IDBObjectStore.count */
  IDBRequest count([key_OR_range]) {
    if (!?key_OR_range) {
      return _count_1();
    }
    if ((?key_OR_range && (key_OR_range is IDBKeyRange || key_OR_range == null))) {
      return _count_2(key_OR_range);
    }
    if (?key_OR_range) {
      var key_1 = _convertDartToNative_IDBKey(key_OR_range);
      return _count_3(key_1);
    }
    throw const Exception("Incorrect number or type of arguments");
  }
  IDBRequest _count_1() native "count";
  IDBRequest _count_2(IDBKeyRange range) native "count";
  IDBRequest _count_3(key) native "count";

  /** @domName IDBObjectStore.createIndex */
  IDBIndex createIndex(String name, keyPath, [Map options]) {
    if ((?keyPath && (keyPath is List<String> || keyPath == null)) &&
        !?options) {
      List keyPath_1 = _convertDartToNative_StringArray(keyPath);
      return _createIndex_1(name, keyPath_1);
    }
    if ((?keyPath && (keyPath is List<String> || keyPath == null))) {
      List keyPath_2 = _convertDartToNative_StringArray(keyPath);
      var options_3 = _convertDartToNative_Dictionary(options);
      return _createIndex_2(name, keyPath_2, options_3);
    }
    if ((?keyPath && (keyPath is String || keyPath == null)) &&
        !?options) {
      return _createIndex_3(name, keyPath);
    }
    if ((?keyPath && (keyPath is String || keyPath == null))) {
      var options_4 = _convertDartToNative_Dictionary(options);
      return _createIndex_4(name, keyPath, options_4);
    }
    throw const Exception("Incorrect number or type of arguments");
  }
  IDBIndex _createIndex_1(name, List keyPath) native "createIndex";
  IDBIndex _createIndex_2(name, List keyPath, options) native "createIndex";
  IDBIndex _createIndex_3(name, String keyPath) native "createIndex";
  IDBIndex _createIndex_4(name, String keyPath, options) native "createIndex";

  /** @domName IDBObjectStore.delete */
  IDBRequest delete(key_OR_keyRange) {
    if ((?key_OR_keyRange && (key_OR_keyRange is IDBKeyRange || key_OR_keyRange == null))) {
      return _delete_1(key_OR_keyRange);
    }
    if (?key_OR_keyRange) {
      var key_1 = _convertDartToNative_IDBKey(key_OR_keyRange);
      return _delete_2(key_1);
    }
    throw const Exception("Incorrect number or type of arguments");
  }
  IDBRequest _delete_1(IDBKeyRange keyRange) native "delete";
  IDBRequest _delete_2(key) native "delete";

  /** @domName IDBObjectStore.deleteIndex */
  void deleteIndex(String name) native;

  /** @domName IDBObjectStore.getObject */
  IDBRequest getObject(key) {
    if ((?key && (key is IDBKeyRange || key == null))) {
      return _getObject_1(key);
    }
    if (?key) {
      var key_1 = _convertDartToNative_IDBKey(key);
      return _getObject_2(key_1);
    }
    throw const Exception("Incorrect number or type of arguments");
  }
  IDBRequest _getObject_1(IDBKeyRange key) native "get";
  IDBRequest _getObject_2(key) native "get";

  /** @domName IDBObjectStore.index */
  IDBIndex index(String name) native;

  /** @domName IDBObjectStore.openCursor */
  IDBRequest openCursor([key_OR_range, String direction]) {
    if (!?key_OR_range &&
        !?direction) {
      return _openCursor_1();
    }
    if ((?key_OR_range && (key_OR_range is IDBKeyRange || key_OR_range == null)) &&
        !?direction) {
      return _openCursor_2(key_OR_range);
    }
    if ((?key_OR_range && (key_OR_range is IDBKeyRange || key_OR_range == null))) {
      return _openCursor_3(key_OR_range, direction);
    }
    if (?key_OR_range &&
        !?direction) {
      var key_1 = _convertDartToNative_IDBKey(key_OR_range);
      return _openCursor_4(key_1);
    }
    if (?key_OR_range) {
      var key_2 = _convertDartToNative_IDBKey(key_OR_range);
      return _openCursor_5(key_2, direction);
    }
    throw const Exception("Incorrect number or type of arguments");
  }
  IDBRequest _openCursor_1() native "openCursor";
  IDBRequest _openCursor_2(IDBKeyRange range) native "openCursor";
  IDBRequest _openCursor_3(IDBKeyRange range, direction) native "openCursor";
  IDBRequest _openCursor_4(key) native "openCursor";
  IDBRequest _openCursor_5(key, direction) native "openCursor";

  /** @domName IDBObjectStore.put */
  IDBRequest put(/*any*/ value, [/*IDBKey*/ key]) {
    if (?key) {
      var value_1 = _convertDartToNative_SerializedScriptValue(value);
      var key_2 = _convertDartToNative_IDBKey(key);
      return _put_1(value_1, key_2);
    }
    var value_3 = _convertDartToNative_SerializedScriptValue(value);
    return _put_2(value_3);
  }
  IDBRequest _put_1(value, key) native "put";
  IDBRequest _put_2(value) native "put";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName IDBOpenDBRequest
class IDBOpenDBRequest extends IDBRequest implements EventTarget native "*IDBOpenDBRequest" {

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  IDBOpenDBRequestEvents get on =>
    new IDBOpenDBRequestEvents(this);
}

class IDBOpenDBRequestEvents extends IDBRequestEvents {
  IDBOpenDBRequestEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get blocked => this['blocked'];

  EventListenerList get upgradeNeeded => this['upgradeneeded'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName IDBRequest
class IDBRequest extends EventTarget native "*IDBRequest" {

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  IDBRequestEvents get on =>
    new IDBRequestEvents(this);

  /** @domName IDBRequest.error */
  final DOMError error;

  /** @domName IDBRequest.errorCode */
  final int errorCode;

  /** @domName IDBRequest.readyState */
  final String readyState;

  /** @domName IDBRequest.result */
  dynamic get result => _convertNativeToDart_IDBAny(this._result);
  dynamic get _result => JS("dynamic", "#.result", this);

  /** @domName IDBRequest.source */
  final dynamic source;

  /** @domName IDBRequest.transaction */
  final IDBTransaction transaction;

  /** @domName IDBRequest.webkitErrorMessage */
  final String webkitErrorMessage;

  /** @domName IDBRequest.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "addEventListener";

  /** @domName IDBRequest.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "dispatchEvent";

  /** @domName IDBRequest.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "removeEventListener";
}

class IDBRequestEvents extends Events {
  IDBRequestEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get error => this['error'];

  EventListenerList get success => this['success'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName IDBTransaction
class IDBTransaction extends EventTarget native "*IDBTransaction" {

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  IDBTransactionEvents get on =>
    new IDBTransactionEvents(this);

  static const int READ_ONLY = 0;

  static const int READ_WRITE = 1;

  static const int VERSION_CHANGE = 2;

  /** @domName IDBTransaction.db */
  final IDBDatabase db;

  /** @domName IDBTransaction.error */
  final DOMError error;

  /** @domName IDBTransaction.mode */
  final String mode;

  /** @domName IDBTransaction.abort */
  void abort() native;

  /** @domName IDBTransaction.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "addEventListener";

  /** @domName IDBTransaction.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "dispatchEvent";

  /** @domName IDBTransaction.objectStore */
  IDBObjectStore objectStore(String name) native;

  /** @domName IDBTransaction.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "removeEventListener";
}

class IDBTransactionEvents extends Events {
  IDBTransactionEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get abort => this['abort'];

  EventListenerList get complete => this['complete'];

  EventListenerList get error => this['error'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName IDBVersionChangeEvent
class IDBUpgradeNeededEvent extends Event native "*IDBVersionChangeEvent" {

  /** @domName IDBVersionChangeEvent.newVersion */
  final int newVersion;

  /** @domName IDBVersionChangeEvent.oldVersion */
  final int oldVersion;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName IDBVersionChangeEvent
class IDBVersionChangeEvent extends Event native "*IDBVersionChangeEvent" {

  /** @domName IDBVersionChangeEvent.version */
  final String version;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName IDBVersionChangeRequest
class IDBVersionChangeRequest extends IDBRequest implements EventTarget native "*IDBVersionChangeRequest" {

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  IDBVersionChangeRequestEvents get on =>
    new IDBVersionChangeRequestEvents(this);
}

class IDBVersionChangeRequestEvents extends IDBRequestEvents {
  IDBVersionChangeRequestEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get blocked => this['blocked'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLIFrameElement
class IFrameElement extends Element implements Element native "*HTMLIFrameElement" {

  factory IFrameElement() => _Elements.createIFrameElement();

  /** @domName HTMLIFrameElement.align */
  String align;

  /** @domName HTMLIFrameElement.contentWindow */
  Window get contentWindow => _convertNativeToDart_Window(this._contentWindow);
  dynamic get _contentWindow => JS("dynamic", "#.contentWindow", this);

  /** @domName HTMLIFrameElement.frameBorder */
  String frameBorder;

  /** @domName HTMLIFrameElement.height */
  String height;

  /** @domName HTMLIFrameElement.longDesc */
  String longDesc;

  /** @domName HTMLIFrameElement.marginHeight */
  String marginHeight;

  /** @domName HTMLIFrameElement.marginWidth */
  String marginWidth;

  /** @domName HTMLIFrameElement.name */
  String name;

  /** @domName HTMLIFrameElement.sandbox */
  String sandbox;

  /** @domName HTMLIFrameElement.scrolling */
  String scrolling;

  /** @domName HTMLIFrameElement.src */
  String src;

  /** @domName HTMLIFrameElement.srcdoc */
  String srcdoc;

  /** @domName HTMLIFrameElement.width */
  String width;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void IceCallback(IceCandidate candidate, bool moreToFollow, PeerConnection00 source);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName IceCandidate
class IceCandidate native "*IceCandidate" {

  factory IceCandidate(String label, String candidateLine) => _IceCandidateFactoryProvider.createIceCandidate(label, candidateLine);

  /** @domName IceCandidate.label */
  final String label;

  /** @domName IceCandidate.toSdp */
  String toSdp() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName ImageData
class ImageData native "*ImageData" {

  /** @domName ImageData.data */
  final Uint8ClampedArray data;

  /** @domName ImageData.height */
  final int height;

  /** @domName ImageData.width */
  final int width;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLImageElement
class ImageElement extends Element implements Element native "*HTMLImageElement" {

  factory ImageElement({String src, int width, int height}) {
    if (!?src) {
      return _Elements.createImageElement();
    }
    if (!?width) {
      return _Elements.createImageElement(src);
    }
    if (!?height) {
      return _Elements.createImageElement(src, width);
    }
    return _Elements.createImageElement(src, width, height);
  }

  /** @domName HTMLImageElement.align */
  String align;

  /** @domName HTMLImageElement.alt */
  String alt;

  /** @domName HTMLImageElement.border */
  String border;

  /** @domName HTMLImageElement.complete */
  final bool complete;

  /** @domName HTMLImageElement.crossOrigin */
  String crossOrigin;

  /** @domName HTMLImageElement.height */
  int height;

  /** @domName HTMLImageElement.hspace */
  int hspace;

  /** @domName HTMLImageElement.isMap */
  bool isMap;

  /** @domName HTMLImageElement.longDesc */
  String longDesc;

  /** @domName HTMLImageElement.lowsrc */
  String lowsrc;

  /** @domName HTMLImageElement.name */
  String name;

  /** @domName HTMLImageElement.naturalHeight */
  final int naturalHeight;

  /** @domName HTMLImageElement.naturalWidth */
  final int naturalWidth;

  /** @domName HTMLImageElement.src */
  String src;

  /** @domName HTMLImageElement.useMap */
  String useMap;

  /** @domName HTMLImageElement.vspace */
  int vspace;

  /** @domName HTMLImageElement.width */
  int width;

  /** @domName HTMLImageElement.x */
  final int x;

  /** @domName HTMLImageElement.y */
  final int y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLInputElement
class InputElement extends Element implements Element native "*HTMLInputElement" {

  factory InputElement({String type}) {
    if (!?type) {
      return _Elements.createInputElement();
    }
    return _Elements.createInputElement(type);
  }

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  InputElementEvents get on =>
    new InputElementEvents(this);

  /** @domName HTMLInputElement.accept */
  String accept;

  /** @domName HTMLInputElement.align */
  String align;

  /** @domName HTMLInputElement.alt */
  String alt;

  /** @domName HTMLInputElement.autocomplete */
  String autocomplete;

  /** @domName HTMLInputElement.autofocus */
  bool autofocus;

  /** @domName HTMLInputElement.checked */
  bool checked;

  /** @domName HTMLInputElement.defaultChecked */
  bool defaultChecked;

  /** @domName HTMLInputElement.defaultValue */
  String defaultValue;

  /** @domName HTMLInputElement.dirName */
  String dirName;

  /** @domName HTMLInputElement.disabled */
  bool disabled;

  /** @domName HTMLInputElement.files */
  List<File> files;

  /** @domName HTMLInputElement.form */
  final FormElement form;

  /** @domName HTMLInputElement.formAction */
  String formAction;

  /** @domName HTMLInputElement.formEnctype */
  String formEnctype;

  /** @domName HTMLInputElement.formMethod */
  String formMethod;

  /** @domName HTMLInputElement.formNoValidate */
  bool formNoValidate;

  /** @domName HTMLInputElement.formTarget */
  String formTarget;

  /** @domName HTMLInputElement.height */
  int height;

  /** @domName HTMLInputElement.incremental */
  bool incremental;

  /** @domName HTMLInputElement.indeterminate */
  bool indeterminate;

  /** @domName HTMLInputElement.labels */
  final List<Node> labels;

  /** @domName HTMLInputElement.list */
  final Element list;

  /** @domName HTMLInputElement.max */
  String max;

  /** @domName HTMLInputElement.maxLength */
  int maxLength;

  /** @domName HTMLInputElement.min */
  String min;

  /** @domName HTMLInputElement.multiple */
  bool multiple;

  /** @domName HTMLInputElement.name */
  String name;

  /** @domName HTMLInputElement.pattern */
  String pattern;

  /** @domName HTMLInputElement.placeholder */
  String placeholder;

  /** @domName HTMLInputElement.readOnly */
  bool readOnly;

  /** @domName HTMLInputElement.required */
  bool required;

  /** @domName HTMLInputElement.selectionDirection */
  String selectionDirection;

  /** @domName HTMLInputElement.selectionEnd */
  int selectionEnd;

  /** @domName HTMLInputElement.selectionStart */
  int selectionStart;

  /** @domName HTMLInputElement.size */
  int size;

  /** @domName HTMLInputElement.src */
  String src;

  /** @domName HTMLInputElement.step */
  String step;

  /** @domName HTMLInputElement.type */
  String type;

  /** @domName HTMLInputElement.useMap */
  String useMap;

  /** @domName HTMLInputElement.validationMessage */
  final String validationMessage;

  /** @domName HTMLInputElement.validity */
  final ValidityState validity;

  /** @domName HTMLInputElement.value */
  String value;

  /** @domName HTMLInputElement.valueAsDate */
  Date valueAsDate;

  /** @domName HTMLInputElement.valueAsNumber */
  num valueAsNumber;

  /** @domName HTMLInputElement.webkitEntries */
  final List<Entry> webkitEntries;

  /** @domName HTMLInputElement.webkitGrammar */
  bool webkitGrammar;

  /** @domName HTMLInputElement.webkitSpeech */
  bool webkitSpeech;

  /** @domName HTMLInputElement.webkitdirectory */
  bool webkitdirectory;

  /** @domName HTMLInputElement.width */
  int width;

  /** @domName HTMLInputElement.willValidate */
  final bool willValidate;

  /** @domName HTMLInputElement.checkValidity */
  bool checkValidity() native;

  /** @domName HTMLInputElement.select */
  void select() native;

  /** @domName HTMLInputElement.setCustomValidity */
  void setCustomValidity(String error) native;

  /** @domName HTMLInputElement.setRangeText */
  void setRangeText(String replacement, [int start, int end, String selectionMode]) native;

  /** @domName HTMLInputElement.setSelectionRange */
  void setSelectionRange(int start, int end, [String direction]) native;

  /** @domName HTMLInputElement.stepDown */
  void stepDown([int n]) native;

  /** @domName HTMLInputElement.stepUp */
  void stepUp([int n]) native;
}

class InputElementEvents extends ElementEvents {
  InputElementEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get speechChange => this['webkitSpeechChange'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Int16Array
class Int16Array extends ArrayBufferView implements JavaScriptIndexingBehavior, List<int> native "*Int16Array" {

  factory Int16Array(int length) =>
    _TypedArrayFactoryProvider.createInt16Array(length);

  factory Int16Array.fromList(List<int> list) =>
    _TypedArrayFactoryProvider.createInt16Array_fromList(list);

  factory Int16Array.fromBuffer(ArrayBuffer buffer, [int byteOffset, int length]) => 
    _TypedArrayFactoryProvider.createInt16Array_fromBuffer(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 2;

  /** @domName Int16Array.length */
  final int length;

  int operator[](int index) => JS("int", "#[#]", this, index);

  void operator[]=(int index, int value) => JS("void", "#[#] = #", this, index, value);
  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<int>(this);
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<int> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(int element) => _Collections.contains(this, element);

  void forEach(void f(int element)) => _Collections.forEach(this, f);

  Collection map(f(int element)) => _Collections.map(this, [], f);

  Collection<int> filter(bool f(int element)) =>
     _Collections.filter(this, <int>[], f);

  bool every(bool f(int element)) => _Collections.every(this, f);

  bool some(bool f(int element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<int>:

  void sort([Comparator<int> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int get last => this[length - 1];

  int removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<int> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [int initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<int> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <int>[]);

  // -- end List<int> mixins.

  /** @domName Int16Array.setElements */
  void setElements(Object array, [int offset]) native "set";

  /** @domName Int16Array.subarray */
  Int16Array subarray(int start, [int end]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Int32Array
class Int32Array extends ArrayBufferView implements JavaScriptIndexingBehavior, List<int> native "*Int32Array" {

  factory Int32Array(int length) =>
    _TypedArrayFactoryProvider.createInt32Array(length);

  factory Int32Array.fromList(List<int> list) =>
    _TypedArrayFactoryProvider.createInt32Array_fromList(list);

  factory Int32Array.fromBuffer(ArrayBuffer buffer, [int byteOffset, int length]) => 
    _TypedArrayFactoryProvider.createInt32Array_fromBuffer(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 4;

  /** @domName Int32Array.length */
  final int length;

  int operator[](int index) => JS("int", "#[#]", this, index);

  void operator[]=(int index, int value) => JS("void", "#[#] = #", this, index, value);
  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<int>(this);
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<int> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(int element) => _Collections.contains(this, element);

  void forEach(void f(int element)) => _Collections.forEach(this, f);

  Collection map(f(int element)) => _Collections.map(this, [], f);

  Collection<int> filter(bool f(int element)) =>
     _Collections.filter(this, <int>[], f);

  bool every(bool f(int element)) => _Collections.every(this, f);

  bool some(bool f(int element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<int>:

  void sort([Comparator<int> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int get last => this[length - 1];

  int removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<int> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [int initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<int> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <int>[]);

  // -- end List<int> mixins.

  /** @domName Int32Array.setElements */
  void setElements(Object array, [int offset]) native "set";

  /** @domName Int32Array.subarray */
  Int32Array subarray(int start, [int end]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Int8Array
class Int8Array extends ArrayBufferView implements JavaScriptIndexingBehavior, List<int> native "*Int8Array" {

  factory Int8Array(int length) =>
    _TypedArrayFactoryProvider.createInt8Array(length);

  factory Int8Array.fromList(List<int> list) =>
    _TypedArrayFactoryProvider.createInt8Array_fromList(list);

  factory Int8Array.fromBuffer(ArrayBuffer buffer, [int byteOffset, int length]) => 
    _TypedArrayFactoryProvider.createInt8Array_fromBuffer(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 1;

  /** @domName Int8Array.length */
  final int length;

  int operator[](int index) => JS("int", "#[#]", this, index);

  void operator[]=(int index, int value) => JS("void", "#[#] = #", this, index, value);
  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<int>(this);
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<int> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(int element) => _Collections.contains(this, element);

  void forEach(void f(int element)) => _Collections.forEach(this, f);

  Collection map(f(int element)) => _Collections.map(this, [], f);

  Collection<int> filter(bool f(int element)) =>
     _Collections.filter(this, <int>[], f);

  bool every(bool f(int element)) => _Collections.every(this, f);

  bool some(bool f(int element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<int>:

  void sort([Comparator<int> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int get last => this[length - 1];

  int removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<int> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [int initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<int> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <int>[]);

  // -- end List<int> mixins.

  /** @domName Int8Array.setElements */
  void setElements(Object array, [int offset]) native "set";

  /** @domName Int8Array.subarray */
  Int8Array subarray(int start, [int end]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName JavaScriptCallFrame
class JavaScriptCallFrame native "*JavaScriptCallFrame" {

  static const int CATCH_SCOPE = 4;

  static const int CLOSURE_SCOPE = 3;

  static const int GLOBAL_SCOPE = 0;

  static const int LOCAL_SCOPE = 1;

  static const int WITH_SCOPE = 2;

  /** @domName JavaScriptCallFrame.caller */
  final JavaScriptCallFrame caller;

  /** @domName JavaScriptCallFrame.column */
  final int column;

  /** @domName JavaScriptCallFrame.functionName */
  final String functionName;

  /** @domName JavaScriptCallFrame.line */
  final int line;

  /** @domName JavaScriptCallFrame.scopeChain */
  final List scopeChain;

  /** @domName JavaScriptCallFrame.sourceID */
  final int sourceID;

  /** @domName JavaScriptCallFrame.thisObject */
  final Object thisObject;

  /** @domName JavaScriptCallFrame.type */
  final String type;

  /** @domName JavaScriptCallFrame.evaluate */
  void evaluate(String script) native;

  /** @domName JavaScriptCallFrame.restart */
  Object restart() native;

  /** @domName JavaScriptCallFrame.scopeType */
  int scopeType(int scopeIndex) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName KeyboardEvent
class KeyboardEvent extends UIEvent native "*KeyboardEvent" {

  /** @domName KeyboardEvent.altGraphKey */
  final bool altGraphKey;

  /** @domName KeyboardEvent.altKey */
  final bool altKey;

  /** @domName KeyboardEvent.ctrlKey */
  final bool ctrlKey;

  /** @domName KeyboardEvent.keyIdentifier */
  final String keyIdentifier;

  /** @domName KeyboardEvent.keyLocation */
  final int keyLocation;

  /** @domName KeyboardEvent.metaKey */
  final bool metaKey;

  /** @domName KeyboardEvent.shiftKey */
  final bool shiftKey;

  /** @domName KeyboardEvent.initKeyboardEvent */
  void initKeyboardEvent(String type, bool canBubble, bool cancelable, LocalWindow view, String keyIdentifier, int keyLocation, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, bool altGraphKey) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLKeygenElement
class KeygenElement extends Element implements Element native "*HTMLKeygenElement" {

  factory KeygenElement() => _Elements.createKeygenElement();

  /** @domName HTMLKeygenElement.autofocus */
  bool autofocus;

  /** @domName HTMLKeygenElement.challenge */
  String challenge;

  /** @domName HTMLKeygenElement.disabled */
  bool disabled;

  /** @domName HTMLKeygenElement.form */
  final FormElement form;

  /** @domName HTMLKeygenElement.keytype */
  String keytype;

  /** @domName HTMLKeygenElement.labels */
  final List<Node> labels;

  /** @domName HTMLKeygenElement.name */
  String name;

  /** @domName HTMLKeygenElement.type */
  final String type;

  /** @domName HTMLKeygenElement.validationMessage */
  final String validationMessage;

  /** @domName HTMLKeygenElement.validity */
  final ValidityState validity;

  /** @domName HTMLKeygenElement.willValidate */
  final bool willValidate;

  /** @domName HTMLKeygenElement.checkValidity */
  bool checkValidity() native;

  /** @domName HTMLKeygenElement.setCustomValidity */
  void setCustomValidity(String error) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLLIElement
class LIElement extends Element implements Element native "*HTMLLIElement" {

  factory LIElement() => _Elements.createLIElement();

  /** @domName HTMLLIElement.type */
  String type;

  /** @domName HTMLLIElement.value */
  int value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLLabelElement
class LabelElement extends Element implements Element native "*HTMLLabelElement" {

  factory LabelElement() => _Elements.createLabelElement();

  /** @domName HTMLLabelElement.control */
  final Element control;

  /** @domName HTMLLabelElement.form */
  final FormElement form;

  /** @domName HTMLLabelElement.htmlFor */
  String htmlFor;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLLegendElement
class LegendElement extends Element implements Element native "*HTMLLegendElement" {

  factory LegendElement() => _Elements.createLegendElement();

  /** @domName HTMLLegendElement.align */
  String align;

  /** @domName HTMLLegendElement.form */
  final FormElement form;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLLinkElement
class LinkElement extends Element implements Element native "*HTMLLinkElement" {

  factory LinkElement() => _Elements.createLinkElement();

  /** @domName HTMLLinkElement.charset */
  String charset;

  /** @domName HTMLLinkElement.disabled */
  bool disabled;

  /** @domName HTMLLinkElement.href */
  String href;

  /** @domName HTMLLinkElement.hreflang */
  String hreflang;

  /** @domName HTMLLinkElement.media */
  String media;

  /** @domName HTMLLinkElement.rel */
  String rel;

  /** @domName HTMLLinkElement.rev */
  String rev;

  /** @domName HTMLLinkElement.sheet */
  final StyleSheet sheet;

  /** @domName HTMLLinkElement.sizes */
  DOMSettableTokenList sizes;

  /** @domName HTMLLinkElement.target */
  String target;

  /** @domName HTMLLinkElement.type */
  String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName History
class LocalHistory implements History native "*History" {

  /** @domName History.length */
  final int length;

  /** @domName History.state */
  final dynamic state;

  /** @domName History.back */
  void back() native;

  /** @domName History.forward */
  void forward() native;

  /** @domName History.go */
  void go(int distance) native;

  /** @domName History.pushState */
  void pushState(Object data, String title, [String url]) native;

  /** @domName History.replaceState */
  void replaceState(Object data, String title, [String url]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Location
class LocalLocation implements Location native "*Location" {

  /** @domName Location.ancestorOrigins */
  final List<String> ancestorOrigins;

  /** @domName Location.hash */
  String hash;

  /** @domName Location.host */
  String host;

  /** @domName Location.hostname */
  String hostname;

  /** @domName Location.href */
  String href;

  /** @domName Location.origin */
  final String origin;

  /** @domName Location.pathname */
  String pathname;

  /** @domName Location.port */
  String port;

  /** @domName Location.protocol */
  String protocol;

  /** @domName Location.search */
  String search;

  /** @domName Location.assign */
  void assign(String url) native;

  /** @domName Location.reload */
  void reload() native;

  /** @domName Location.replace */
  void replace(String url) native;

  /** @domName Location.toString */
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName LocalMediaStream
class LocalMediaStream extends MediaStream implements EventTarget native "*LocalMediaStream" {

  /** @domName LocalMediaStream.stop */
  void stop() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class LocalWindow extends EventTarget implements Window native "@*DOMWindow" {

  Document get document => JS('Document', '#.document', this);

  Window _open2(url, name) => JS('Window', '#.open(#,#)', this, url, name);

  Window _open3(url, name, options) =>
      JS('Window', '#.open(#,#,#)', this, url, name, options);

  Window open(String url, String name, [String options]) {
    if (options == null) {
      return _DOMWindowCrossFrame._createSafe(_open2(url, name));
    } else {
      return _DOMWindowCrossFrame._createSafe(_open3(url, name, options));
    }
  }

  // API level getter and setter for Location.
  // TODO: The cross domain safe wrapper can be inserted here or folded into
  // _LocationWrapper.
  LocalLocation get location() {
    // Firefox work-around for Location.  The Firefox location object cannot be
    // made to behave like a Dart object so must be wrapped.
    var result = _location;
    if (_isDartLocation(result)) return result;  // e.g. on Chrome.
    if (null == _location_wrapper) {
      _location_wrapper = new _LocationWrapper(result);
    }
    return _location_wrapper;
  }

  // TODO: consider forcing users to do: window.location.assign('string').
  /**
   * Sets the window's location, which causes the browser to navigate to the new
   * location. [value] may be a Location object or a string.
   */
  void set location(value) {
    if (value is _LocationWrapper) {
      _location = value._ptr;
    } else {
      _location = value;
    }
  }

  _LocationWrapper _location_wrapper;  // Cached wrapped Location object.

  // Native getter and setter to access raw Location object.
  Location get _location => JS('Location', '#.location', this);
  void set _location(Location value) {
    JS('void', '#.location = #', this, value);
  }
  // Prevent compiled from thinking 'location' property is available for a Dart
  // member.
  _protect_location() native 'location';

  static _isDartLocation(thing) {
    // On Firefox the code that implements 'is Location' fails to find the patch
    // stub on Object.prototype and throws an exception.
    try {
      return thing is Location;
    } catch (e) {
      return false;
    }
  }

  /**
   * Executes a [callback] after the next batch of browser layout measurements
   * has completed or would have completed if any browser layout measurements
   * had been scheduled.
   */
  void requestLayoutFrame(TimeoutHandler callback) {
    _addMeasurementFrameCallback(callback);
  }

  /** @domName DOMWindow.requestAnimationFrame */
  int requestAnimationFrame(RequestAnimationFrameCallback callback) {
    _ensureRequestAnimationFrame();
    return _requestAnimationFrame(callback);
  }

  void cancelAnimationFrame(id) {
    _ensureRequestAnimationFrame();
    _cancelAnimationFrame(id);
  }

  int _requestAnimationFrame(RequestAnimationFrameCallback callback)
      native 'requestAnimationFrame';

  void _cancelAnimationFrame(int id)
      native 'cancelAnimationFrame';

  _ensureRequestAnimationFrame() {
    if (JS('bool',
           '!!(#.requestAnimationFrame && #.cancelAnimationFrame)', this, this))
      return;

    JS('void',
       r"""
  (function($this) {
   var vendors = ['ms', 'moz', 'webkit', 'o'];
   for (var i = 0; i < vendors.length && !$this.requestAnimationFrame; ++i) {
     $this.requestAnimationFrame = $this[vendors[i] + 'RequestAnimationFrame'];
     $this.cancelAnimationFrame =
         $this[vendors[i]+'CancelAnimationFrame'] ||
         $this[vendors[i]+'CancelRequestAnimationFrame'];
   }
   if ($this.requestAnimationFrame && $this.cancelAnimationFrame) return;
   $this.requestAnimationFrame = function(callback) {
      return window.setTimeout(function() {
        callback(Date.now());
      }, 16 /* 16ms ~= 60fps */);
   };
   $this.cancelAnimationFrame = function(id) { clearTimeout(id); }
  })(#)""",
       this);
  }

  IDBFactory get indexedDB() =>
      JS('IDBFactory',
         '#.indexedDB || #.webkitIndexedDB || #.mozIndexedDB',
         this, this, this);

  /**
   * Lookup a port by its [name].  Return null if no port is
   * registered under [name].
   */
  SendPortSync lookupPort(String name) {
    var port = JSON.parse(localStorage['dart-port:$name']);
    return _deserialize(port);
  }

  /**
   * Register a [port] on this window under the given [name].  This
   * port may be retrieved by any isolate (or JavaScript script)
   * running in this window.
   */
  void registerPort(String name, var port) {
    var serialized = _serialize(port);
    localStorage['dart-port:$name'] = JSON.stringify(serialized);
  }


  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  LocalWindowEvents get on =>
    new LocalWindowEvents(this);

  static const int PERSISTENT = 1;

  static const int TEMPORARY = 0;

  /** @domName Window.applicationCache */
  final DOMApplicationCache applicationCache;

  /** @domName Window.clientInformation */
  final Navigator clientInformation;

  /** @domName Window.closed */
  final bool closed;

  /** @domName Window.console */
  final Console console;

  /** @domName Window.crypto */
  final Crypto crypto;

  /** @domName Window.defaultStatus */
  String defaultStatus;

  /** @domName Window.defaultstatus */
  String defaultstatus;

  /** @domName Window.devicePixelRatio */
  final num devicePixelRatio;

  /** @domName Window.event */
  final Event event;

  /** @domName Window.history */
  final LocalHistory history;

  /** @domName Window.innerHeight */
  final int innerHeight;

  /** @domName Window.innerWidth */
  final int innerWidth;

  /** @domName Window.localStorage */
  final Storage localStorage;

  /** @domName Window.locationbar */
  final BarInfo locationbar;

  /** @domName Window.menubar */
  final BarInfo menubar;

  /** @domName Window.name */
  String name;

  /** @domName Window.navigator */
  final Navigator navigator;

  /** @domName Window.offscreenBuffering */
  final bool offscreenBuffering;

  /** @domName Window.opener */
  Window get opener => _convertNativeToDart_Window(this._opener);
  dynamic get _opener => JS("dynamic", "#.opener", this);

  /** @domName Window.outerHeight */
  final int outerHeight;

  /** @domName Window.outerWidth */
  final int outerWidth;

  /** @domName DOMWindow.pagePopupController */
  final PagePopupController pagePopupController;

  /** @domName Window.pageXOffset */
  final int pageXOffset;

  /** @domName Window.pageYOffset */
  final int pageYOffset;

  /** @domName Window.parent */
  Window get parent => _convertNativeToDart_Window(this._parent);
  dynamic get _parent => JS("dynamic", "#.parent", this);

  /** @domName Window.performance */
  final Performance performance;

  /** @domName Window.personalbar */
  final BarInfo personalbar;

  /** @domName Window.screen */
  final Screen screen;

  /** @domName Window.screenLeft */
  final int screenLeft;

  /** @domName Window.screenTop */
  final int screenTop;

  /** @domName Window.screenX */
  final int screenX;

  /** @domName Window.screenY */
  final int screenY;

  /** @domName Window.scrollX */
  final int scrollX;

  /** @domName Window.scrollY */
  final int scrollY;

  /** @domName Window.scrollbars */
  final BarInfo scrollbars;

  /** @domName Window.self */
  Window get self => _convertNativeToDart_Window(this._self);
  dynamic get _self => JS("dynamic", "#.self", this);

  /** @domName Window.sessionStorage */
  final Storage sessionStorage;

  /** @domName Window.status */
  String status;

  /** @domName Window.statusbar */
  final BarInfo statusbar;

  /** @domName Window.styleMedia */
  final StyleMedia styleMedia;

  /** @domName Window.toolbar */
  final BarInfo toolbar;

  /** @domName Window.top */
  Window get top => _convertNativeToDart_Window(this._top);
  dynamic get _top => JS("dynamic", "#.top", this);

  /** @domName DOMWindow.webkitIndexedDB */
  final IDBFactory webkitIndexedDB;

  /** @domName DOMWindow.webkitNotifications */
  final NotificationCenter webkitNotifications;

  /** @domName DOMWindow.webkitStorageInfo */
  final StorageInfo webkitStorageInfo;

  /** @domName Window.window */
  Window get window => _convertNativeToDart_Window(this._window);
  dynamic get _window => JS("dynamic", "#.window", this);

  /** @domName Window.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "addEventListener";

  /** @domName Window.alert */
  void alert(String message) native;

  /** @domName Window.atob */
  String atob(String string) native;

  /** @domName Window.blur */
  void blur() native;

  /** @domName Window.btoa */
  String btoa(String string) native;

  /** @domName Window.captureEvents */
  void captureEvents() native;

  /** @domName Window.clearInterval */
  void clearInterval(int handle) native;

  /** @domName Window.clearTimeout */
  void clearTimeout(int handle) native;

  /** @domName Window.close */
  void close() native;

  /** @domName Window.confirm */
  bool confirm(String message) native;

  /** @domName Window.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "dispatchEvent";

  /** @domName Window.find */
  bool find(String string, bool caseSensitive, bool backwards, bool wrap, bool wholeWord, bool searchInFrames, bool showDialog) native;

  /** @domName Window.focus */
  void focus() native;

  /** @domName Window.getComputedStyle */
  CSSStyleDeclaration $dom_getComputedStyle(Element element, String pseudoElement) native "getComputedStyle";

  /** @domName Window.getMatchedCSSRules */
  List<CSSRule> getMatchedCSSRules(Element element, String pseudoElement) native;

  /** @domName Window.getSelection */
  DOMSelection getSelection() native;

  /** @domName Window.matchMedia */
  MediaQueryList matchMedia(String query) native;

  /** @domName Window.moveBy */
  void moveBy(num x, num y) native;

  /** @domName Window.moveTo */
  void moveTo(num x, num y) native;

  /** @domName DOMWindow.openDatabase */
  Database openDatabase(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback]) native;

  /** @domName Window.postMessage */
  void postMessage(/*SerializedScriptValue*/ message, String targetOrigin, [List messagePorts]) {
    if (?message &&
        !?messagePorts) {
      var message_1 = _convertDartToNative_SerializedScriptValue(message);
      _postMessage_1(message_1, targetOrigin);
      return;
    }
    if (?message) {
      var message_2 = _convertDartToNative_SerializedScriptValue(message);
      _postMessage_2(message_2, targetOrigin, messagePorts);
      return;
    }
    throw const Exception("Incorrect number or type of arguments");
  }
  void _postMessage_1(message, targetOrigin) native "postMessage";
  void _postMessage_2(message, targetOrigin, List messagePorts) native "postMessage";

  /** @domName Window.print */
  void print() native;

  /** @domName Window.prompt */
  String prompt(String message, String defaultValue) native;

  /** @domName Window.releaseEvents */
  void releaseEvents() native;

  /** @domName Window.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "removeEventListener";

  /** @domName Window.resizeBy */
  void resizeBy(num x, num y) native;

  /** @domName Window.resizeTo */
  void resizeTo(num width, num height) native;

  /** @domName Window.scroll */
  void scroll(int x, int y) native;

  /** @domName Window.scrollBy */
  void scrollBy(int x, int y) native;

  /** @domName Window.scrollTo */
  void scrollTo(int x, int y) native;

  /** @domName Window.setInterval */
  int setInterval(TimeoutHandler handler, int timeout) native;

  /** @domName Window.setTimeout */
  int setTimeout(TimeoutHandler handler, int timeout) native;

  /** @domName Window.showModalDialog */
  Object showModalDialog(String url, [Object dialogArgs, String featureArgs]) native;

  /** @domName Window.stop */
  void stop() native;

  /** @domName Window.webkitConvertPointFromNodeToPage */
  Point webkitConvertPointFromNodeToPage(Node node, Point p) native;

  /** @domName Window.webkitConvertPointFromPageToNode */
  Point webkitConvertPointFromPageToNode(Node node, Point p) native;

  /** @domName DOMWindow.webkitRequestFileSystem */
  void webkitRequestFileSystem(int type, int size, FileSystemCallback successCallback, [ErrorCallback errorCallback]) native;

  /** @domName DOMWindow.webkitResolveLocalFileSystemURL */
  void webkitResolveLocalFileSystemURL(String url, EntryCallback successCallback, [ErrorCallback errorCallback]) native;

}

class LocalWindowEvents extends Events {
  LocalWindowEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get abort => this['abort'];

  EventListenerList get beforeUnload => this['beforeunload'];

  EventListenerList get blur => this['blur'];

  EventListenerList get canPlay => this['canplay'];

  EventListenerList get canPlayThrough => this['canplaythrough'];

  EventListenerList get change => this['change'];

  EventListenerList get click => this['click'];

  EventListenerList get contextMenu => this['contextmenu'];

  EventListenerList get doubleClick => this['dblclick'];

  EventListenerList get deviceMotion => this['devicemotion'];

  EventListenerList get deviceOrientation => this['deviceorientation'];

  EventListenerList get drag => this['drag'];

  EventListenerList get dragEnd => this['dragend'];

  EventListenerList get dragEnter => this['dragenter'];

  EventListenerList get dragLeave => this['dragleave'];

  EventListenerList get dragOver => this['dragover'];

  EventListenerList get dragStart => this['dragstart'];

  EventListenerList get drop => this['drop'];

  EventListenerList get durationChange => this['durationchange'];

  EventListenerList get emptied => this['emptied'];

  EventListenerList get ended => this['ended'];

  EventListenerList get error => this['error'];

  EventListenerList get focus => this['focus'];

  EventListenerList get hashChange => this['hashchange'];

  EventListenerList get input => this['input'];

  EventListenerList get invalid => this['invalid'];

  EventListenerList get keyDown => this['keydown'];

  EventListenerList get keyPress => this['keypress'];

  EventListenerList get keyUp => this['keyup'];

  EventListenerList get load => this['load'];

  EventListenerList get loadedData => this['loadeddata'];

  EventListenerList get loadedMetadata => this['loadedmetadata'];

  EventListenerList get loadStart => this['loadstart'];

  EventListenerList get message => this['message'];

  EventListenerList get mouseDown => this['mousedown'];

  EventListenerList get mouseMove => this['mousemove'];

  EventListenerList get mouseOut => this['mouseout'];

  EventListenerList get mouseOver => this['mouseover'];

  EventListenerList get mouseUp => this['mouseup'];

  EventListenerList get mouseWheel => this['mousewheel'];

  EventListenerList get offline => this['offline'];

  EventListenerList get online => this['online'];

  EventListenerList get pageHide => this['pagehide'];

  EventListenerList get pageShow => this['pageshow'];

  EventListenerList get pause => this['pause'];

  EventListenerList get play => this['play'];

  EventListenerList get playing => this['playing'];

  EventListenerList get popState => this['popstate'];

  EventListenerList get progress => this['progress'];

  EventListenerList get rateChange => this['ratechange'];

  EventListenerList get reset => this['reset'];

  EventListenerList get resize => this['resize'];

  EventListenerList get scroll => this['scroll'];

  EventListenerList get search => this['search'];

  EventListenerList get seeked => this['seeked'];

  EventListenerList get seeking => this['seeking'];

  EventListenerList get select => this['select'];

  EventListenerList get stalled => this['stalled'];

  EventListenerList get storage => this['storage'];

  EventListenerList get submit => this['submit'];

  EventListenerList get suspend => this['suspend'];

  EventListenerList get timeUpdate => this['timeupdate'];

  EventListenerList get touchCancel => this['touchcancel'];

  EventListenerList get touchEnd => this['touchend'];

  EventListenerList get touchMove => this['touchmove'];

  EventListenerList get touchStart => this['touchstart'];

  EventListenerList get unload => this['unload'];

  EventListenerList get volumeChange => this['volumechange'];

  EventListenerList get waiting => this['waiting'];

  EventListenerList get animationEnd => this['webkitAnimationEnd'];

  EventListenerList get animationIteration => this['webkitAnimationIteration'];

  EventListenerList get animationStart => this['webkitAnimationStart'];

  EventListenerList get transitionEnd => this['webkitTransitionEnd'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLMapElement
class MapElement extends Element implements Element native "*HTMLMapElement" {

  factory MapElement() => _Elements.createMapElement();

  /** @domName HTMLMapElement.areas */
  final HTMLCollection areas;

  /** @domName HTMLMapElement.name */
  String name;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLMarqueeElement
class MarqueeElement extends Element implements Element native "*HTMLMarqueeElement" {

  /** @domName HTMLMarqueeElement.behavior */
  String behavior;

  /** @domName HTMLMarqueeElement.bgColor */
  String bgColor;

  /** @domName HTMLMarqueeElement.direction */
  String direction;

  /** @domName HTMLMarqueeElement.height */
  String height;

  /** @domName HTMLMarqueeElement.hspace */
  int hspace;

  /** @domName HTMLMarqueeElement.loop */
  int loop;

  /** @domName HTMLMarqueeElement.scrollAmount */
  int scrollAmount;

  /** @domName HTMLMarqueeElement.scrollDelay */
  int scrollDelay;

  /** @domName HTMLMarqueeElement.trueSpeed */
  bool trueSpeed;

  /** @domName HTMLMarqueeElement.vspace */
  int vspace;

  /** @domName HTMLMarqueeElement.width */
  String width;

  /** @domName HTMLMarqueeElement.start */
  void start() native;

  /** @domName HTMLMarqueeElement.stop */
  void stop() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName MediaController
class MediaController extends EventTarget native "*MediaController" {

  factory MediaController() => _MediaControllerFactoryProvider.createMediaController();

  /** @domName MediaController.buffered */
  final TimeRanges buffered;

  /** @domName MediaController.currentTime */
  num currentTime;

  /** @domName MediaController.defaultPlaybackRate */
  num defaultPlaybackRate;

  /** @domName MediaController.duration */
  final num duration;

  /** @domName MediaController.muted */
  bool muted;

  /** @domName MediaController.paused */
  final bool paused;

  /** @domName MediaController.playbackRate */
  num playbackRate;

  /** @domName MediaController.played */
  final TimeRanges played;

  /** @domName MediaController.seekable */
  final TimeRanges seekable;

  /** @domName MediaController.volume */
  num volume;

  /** @domName MediaController.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "addEventListener";

  /** @domName MediaController.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "dispatchEvent";

  /** @domName MediaController.pause */
  void pause() native;

  /** @domName MediaController.play */
  void play() native;

  /** @domName MediaController.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "removeEventListener";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLMediaElement
class MediaElement extends Element implements Element native "*HTMLMediaElement" {

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  MediaElementEvents get on =>
    new MediaElementEvents(this);

  static const int HAVE_CURRENT_DATA = 2;

  static const int HAVE_ENOUGH_DATA = 4;

  static const int HAVE_FUTURE_DATA = 3;

  static const int HAVE_METADATA = 1;

  static const int HAVE_NOTHING = 0;

  static const int NETWORK_EMPTY = 0;

  static const int NETWORK_IDLE = 1;

  static const int NETWORK_LOADING = 2;

  static const int NETWORK_NO_SOURCE = 3;

  /** @domName HTMLMediaElement.autoplay */
  bool autoplay;

  /** @domName HTMLMediaElement.buffered */
  final TimeRanges buffered;

  /** @domName HTMLMediaElement.controller */
  MediaController controller;

  /** @domName HTMLMediaElement.controls */
  bool controls;

  /** @domName HTMLMediaElement.currentSrc */
  final String currentSrc;

  /** @domName HTMLMediaElement.currentTime */
  num currentTime;

  /** @domName HTMLMediaElement.defaultMuted */
  bool defaultMuted;

  /** @domName HTMLMediaElement.defaultPlaybackRate */
  num defaultPlaybackRate;

  /** @domName HTMLMediaElement.duration */
  final num duration;

  /** @domName HTMLMediaElement.ended */
  final bool ended;

  /** @domName HTMLMediaElement.error */
  final MediaError error;

  /** @domName HTMLMediaElement.initialTime */
  final num initialTime;

  /** @domName HTMLMediaElement.loop */
  bool loop;

  /** @domName HTMLMediaElement.mediaGroup */
  String mediaGroup;

  /** @domName HTMLMediaElement.muted */
  bool muted;

  /** @domName HTMLMediaElement.networkState */
  final int networkState;

  /** @domName HTMLMediaElement.paused */
  final bool paused;

  /** @domName HTMLMediaElement.playbackRate */
  num playbackRate;

  /** @domName HTMLMediaElement.played */
  final TimeRanges played;

  /** @domName HTMLMediaElement.preload */
  String preload;

  /** @domName HTMLMediaElement.readyState */
  final int readyState;

  /** @domName HTMLMediaElement.seekable */
  final TimeRanges seekable;

  /** @domName HTMLMediaElement.seeking */
  final bool seeking;

  /** @domName HTMLMediaElement.src */
  String src;

  /** @domName HTMLMediaElement.startTime */
  final num startTime;

  /** @domName HTMLMediaElement.textTracks */
  final TextTrackList textTracks;

  /** @domName HTMLMediaElement.volume */
  num volume;

  /** @domName HTMLMediaElement.webkitAudioDecodedByteCount */
  final int webkitAudioDecodedByteCount;

  /** @domName HTMLMediaElement.webkitClosedCaptionsVisible */
  bool webkitClosedCaptionsVisible;

  /** @domName HTMLMediaElement.webkitHasClosedCaptions */
  final bool webkitHasClosedCaptions;

  /** @domName HTMLMediaElement.webkitPreservesPitch */
  bool webkitPreservesPitch;

  /** @domName HTMLMediaElement.webkitVideoDecodedByteCount */
  final int webkitVideoDecodedByteCount;

  /** @domName HTMLMediaElement.addTextTrack */
  TextTrack addTextTrack(String kind, [String label, String language]) native;

  /** @domName HTMLMediaElement.canPlayType */
  String canPlayType(String type, String keySystem) native;

  /** @domName HTMLMediaElement.load */
  void load() native;

  /** @domName HTMLMediaElement.pause */
  void pause() native;

  /** @domName HTMLMediaElement.play */
  void play() native;

  /** @domName HTMLMediaElement.webkitAddKey */
  void webkitAddKey(String keySystem, Uint8Array key, [Uint8Array initData, String sessionId]) native;

  /** @domName HTMLMediaElement.webkitCancelKeyRequest */
  void webkitCancelKeyRequest(String keySystem, String sessionId) native;

  /** @domName HTMLMediaElement.webkitGenerateKeyRequest */
  void webkitGenerateKeyRequest(String keySystem, [Uint8Array initData]) native;
}

class MediaElementEvents extends ElementEvents {
  MediaElementEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get canPlay => this['canplay'];

  EventListenerList get canPlayThrough => this['canplaythrough'];

  EventListenerList get durationChange => this['durationchange'];

  EventListenerList get emptied => this['emptied'];

  EventListenerList get ended => this['ended'];

  EventListenerList get loadedData => this['loadeddata'];

  EventListenerList get loadedMetadata => this['loadedmetadata'];

  EventListenerList get loadStart => this['loadstart'];

  EventListenerList get pause => this['pause'];

  EventListenerList get play => this['play'];

  EventListenerList get playing => this['playing'];

  EventListenerList get progress => this['progress'];

  EventListenerList get rateChange => this['ratechange'];

  EventListenerList get seeked => this['seeked'];

  EventListenerList get seeking => this['seeking'];

  EventListenerList get show => this['show'];

  EventListenerList get stalled => this['stalled'];

  EventListenerList get suspend => this['suspend'];

  EventListenerList get timeUpdate => this['timeupdate'];

  EventListenerList get volumeChange => this['volumechange'];

  EventListenerList get waiting => this['waiting'];

  EventListenerList get keyAdded => this['webkitkeyadded'];

  EventListenerList get keyError => this['webkitkeyerror'];

  EventListenerList get keyMessage => this['webkitkeymessage'];

  EventListenerList get needKey => this['webkitneedkey'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName MediaElementAudioSourceNode
class MediaElementAudioSourceNode extends AudioSourceNode native "*MediaElementAudioSourceNode" {

  /** @domName MediaElementAudioSourceNode.mediaElement */
  final MediaElement mediaElement;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName MediaError
class MediaError native "*MediaError" {

  static const int MEDIA_ERR_ABORTED = 1;

  static const int MEDIA_ERR_DECODE = 3;

  static const int MEDIA_ERR_ENCRYPTED = 5;

  static const int MEDIA_ERR_NETWORK = 2;

  static const int MEDIA_ERR_SRC_NOT_SUPPORTED = 4;

  /** @domName MediaError.code */
  final int code;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName MediaKeyError
class MediaKeyError native "*MediaKeyError" {

  static const int MEDIA_KEYERR_CLIENT = 2;

  static const int MEDIA_KEYERR_DOMAIN = 6;

  static const int MEDIA_KEYERR_HARDWARECHANGE = 5;

  static const int MEDIA_KEYERR_OUTPUT = 4;

  static const int MEDIA_KEYERR_SERVICE = 3;

  static const int MEDIA_KEYERR_UNKNOWN = 1;

  /** @domName MediaKeyError.code */
  final int code;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName MediaKeyEvent
class MediaKeyEvent extends Event native "*MediaKeyEvent" {

  /** @domName MediaKeyEvent.defaultURL */
  final String defaultURL;

  /** @domName MediaKeyEvent.errorCode */
  final MediaKeyError errorCode;

  /** @domName MediaKeyEvent.initData */
  final Uint8Array initData;

  /** @domName MediaKeyEvent.keySystem */
  final String keySystem;

  /** @domName MediaKeyEvent.message */
  final Uint8Array message;

  /** @domName MediaKeyEvent.sessionId */
  final String sessionId;

  /** @domName MediaKeyEvent.systemCode */
  final int systemCode;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName MediaList
class MediaList native "*MediaList" {

  /** @domName MediaList.length */
  final int length;

  /** @domName MediaList.mediaText */
  String mediaText;

  /** @domName MediaList.appendMedium */
  void appendMedium(String newMedium) native;

  /** @domName MediaList.deleteMedium */
  void deleteMedium(String oldMedium) native;

  /** @domName MediaList.item */
  String item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName MediaQueryList
class MediaQueryList native "*MediaQueryList" {

  /** @domName MediaQueryList.matches */
  final bool matches;

  /** @domName MediaQueryList.media */
  final String media;

  /** @domName MediaQueryList.addListener */
  void addListener(MediaQueryListListener listener) native;

  /** @domName MediaQueryList.removeListener */
  void removeListener(MediaQueryListListener listener) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName MediaQueryListListener
abstract class MediaQueryListListener {

  /** @domName MediaQueryListListener.queryChanged */
  void queryChanged(MediaQueryList list);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName MediaSource
class MediaSource extends EventTarget native "*MediaSource" {

  factory MediaSource() => _MediaSourceFactoryProvider.createMediaSource();

  /** @domName MediaSource.activeSourceBuffers */
  final SourceBufferList activeSourceBuffers;

  /** @domName MediaSource.duration */
  num duration;

  /** @domName MediaSource.readyState */
  final String readyState;

  /** @domName MediaSource.sourceBuffers */
  final SourceBufferList sourceBuffers;

  /** @domName MediaSource.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "addEventListener";

  /** @domName MediaSource.addSourceBuffer */
  SourceBuffer addSourceBuffer(String type) native;

  /** @domName MediaSource.dispatchEvent */
  bool $dom_dispatchEvent(Event event) native "dispatchEvent";

  /** @domName MediaSource.endOfStream */
  void endOfStream(String error) native;

  /** @domName MediaSource.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "removeEventListener";

  /** @domName MediaSource.removeSourceBuffer */
  void removeSourceBuffer(SourceBuffer buffer) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName MediaStream
class MediaStream extends EventTarget native "*MediaStream" {

  factory MediaStream(MediaStreamTrackList audioTracks, MediaStreamTrackList videoTracks) => _MediaStreamFactoryProvider.createMediaStream(audioTracks, videoTracks);

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  MediaStreamEvents get on =>
    new MediaStreamEvents(this);

  static const int ENDED = 2;

  static const int LIVE = 1;

  /** @domName MediaStream.audioTracks */
  final MediaStreamTrackList audioTracks;

  /** @domName MediaStream.label */
  final String label;

  /** @domName MediaStream.readyState */
  final int readyState;

  /** @domName MediaStream.videoTracks */
  final MediaStreamTrackList videoTracks;

  /** @domName MediaStream.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "addEventListener";

  /** @domName MediaStream.dispatchEvent */
  bool $dom_dispatchEvent(Event event) native "dispatchEvent";

  /** @domName MediaStream.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "removeEventListener";
}

class MediaStreamEvents extends Events {
  MediaStreamEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get ended => this['ended'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName MediaStreamAudioSourceNode
class MediaStreamAudioSourceNode extends AudioSourceNode native "*MediaStreamAudioSourceNode" {

  /** @domName MediaStreamAudioSourceNode.mediaStream */
  final MediaStream mediaStream;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName MediaStreamEvent
class MediaStreamEvent extends Event native "*MediaStreamEvent" {

  /** @domName MediaStreamEvent.stream */
  final MediaStream stream;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName MediaStreamTrack
class MediaStreamTrack extends EventTarget native "*MediaStreamTrack" {

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  MediaStreamTrackEvents get on =>
    new MediaStreamTrackEvents(this);

  static const int ENDED = 2;

  static const int LIVE = 0;

  static const int MUTED = 1;

  /** @domName MediaStreamTrack.enabled */
  bool enabled;

  /** @domName MediaStreamTrack.kind */
  final String kind;

  /** @domName MediaStreamTrack.label */
  final String label;

  /** @domName MediaStreamTrack.readyState */
  final int readyState;

  /** @domName MediaStreamTrack.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "addEventListener";

  /** @domName MediaStreamTrack.dispatchEvent */
  bool $dom_dispatchEvent(Event event) native "dispatchEvent";

  /** @domName MediaStreamTrack.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "removeEventListener";
}

class MediaStreamTrackEvents extends Events {
  MediaStreamTrackEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get ended => this['ended'];

  EventListenerList get mute => this['mute'];

  EventListenerList get unmute => this['unmute'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName MediaStreamTrackEvent
class MediaStreamTrackEvent extends Event native "*MediaStreamTrackEvent" {

  /** @domName MediaStreamTrackEvent.track */
  final MediaStreamTrack track;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName MediaStreamTrackList
class MediaStreamTrackList extends EventTarget native "*MediaStreamTrackList" {

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  MediaStreamTrackListEvents get on =>
    new MediaStreamTrackListEvents(this);

  /** @domName MediaStreamTrackList.length */
  final int length;

  /** @domName MediaStreamTrackList.add */
  void add(MediaStreamTrack track) native;

  /** @domName MediaStreamTrackList.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "addEventListener";

  /** @domName MediaStreamTrackList.dispatchEvent */
  bool $dom_dispatchEvent(Event event) native "dispatchEvent";

  /** @domName MediaStreamTrackList.item */
  MediaStreamTrack item(int index) native;

  /** @domName MediaStreamTrackList.remove */
  void remove(MediaStreamTrack track) native;

  /** @domName MediaStreamTrackList.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "removeEventListener";
}

class MediaStreamTrackListEvents extends Events {
  MediaStreamTrackListEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get addTrack => this['addtrack'];

  EventListenerList get removeTrack => this['removetrack'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName MemoryInfo
class MemoryInfo native "*MemoryInfo" {

  /** @domName MemoryInfo.jsHeapSizeLimit */
  final int jsHeapSizeLimit;

  /** @domName MemoryInfo.totalJSHeapSize */
  final int totalJSHeapSize;

  /** @domName MemoryInfo.usedJSHeapSize */
  final int usedJSHeapSize;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLMenuElement
class MenuElement extends Element implements Element native "*HTMLMenuElement" {

  factory MenuElement() => _Elements.createMenuElement();

  /** @domName HTMLMenuElement.compact */
  bool compact;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName MessageChannel
class MessageChannel native "*MessageChannel" {

  factory MessageChannel() => _MessageChannelFactoryProvider.createMessageChannel();

  /** @domName MessageChannel.port1 */
  final MessagePort port1;

  /** @domName MessageChannel.port2 */
  final MessagePort port2;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName MessageEvent
class MessageEvent extends Event native "*MessageEvent" {

  /** @domName MessageEvent.data */
  dynamic get data => _convertNativeToDart_SerializedScriptValue(this._data);
  dynamic get _data => JS("dynamic", "#.data", this);

  /** @domName MessageEvent.lastEventId */
  final String lastEventId;

  /** @domName MessageEvent.origin */
  final String origin;

  /** @domName MessageEvent.ports */
  final List ports;

  /** @domName MessageEvent.source */
  Window get source => _convertNativeToDart_Window(this._source);
  dynamic get _source => JS("dynamic", "#.source", this);

  /** @domName MessageEvent.initMessageEvent */
  void initMessageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object dataArg, String originArg, String lastEventIdArg, LocalWindow sourceArg, List messagePorts) native;

  /** @domName MessageEvent.webkitInitMessageEvent */
  void webkitInitMessageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object dataArg, String originArg, String lastEventIdArg, LocalWindow sourceArg, List transferables) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName MessagePort
class MessagePort extends EventTarget native "*MessagePort" {

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  MessagePortEvents get on =>
    new MessagePortEvents(this);

  /** @domName MessagePort.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "addEventListener";

  /** @domName MessagePort.close */
  void close() native;

  /** @domName MessagePort.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "dispatchEvent";

  /** @domName MessagePort.postMessage */
  void postMessage(/*any*/ message, [List messagePorts]) {
    if (?messagePorts) {
      var message_1 = _convertDartToNative_SerializedScriptValue(message);
      _postMessage_1(message_1, messagePorts);
      return;
    }
    var message_2 = _convertDartToNative_SerializedScriptValue(message);
    _postMessage_2(message_2);
    return;
  }
  void _postMessage_1(message, List messagePorts) native "postMessage";
  void _postMessage_2(message) native "postMessage";

  /** @domName MessagePort.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "removeEventListener";

  /** @domName MessagePort.start */
  void start() native;
}

class MessagePortEvents extends Events {
  MessagePortEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get message => this['message'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLMetaElement
class MetaElement extends Element implements Element native "*HTMLMetaElement" {

  /** @domName HTMLMetaElement.content */
  String content;

  /** @domName HTMLMetaElement.httpEquiv */
  String httpEquiv;

  /** @domName HTMLMetaElement.name */
  String name;

  /** @domName HTMLMetaElement.scheme */
  String scheme;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Metadata
class Metadata native "*Metadata" {

  /** @domName Metadata.modificationTime */
  final Date modificationTime;

  /** @domName Metadata.size */
  final int size;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void MetadataCallback(Metadata metadata);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLMeterElement
class MeterElement extends Element implements Element native "*HTMLMeterElement" {

  factory MeterElement() => _Elements.createMeterElement();

  /** @domName HTMLMeterElement.high */
  num high;

  /** @domName HTMLMeterElement.labels */
  final List<Node> labels;

  /** @domName HTMLMeterElement.low */
  num low;

  /** @domName HTMLMeterElement.max */
  num max;

  /** @domName HTMLMeterElement.min */
  num min;

  /** @domName HTMLMeterElement.optimum */
  num optimum;

  /** @domName HTMLMeterElement.value */
  num value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLModElement
class ModElement extends Element implements Element native "*HTMLModElement" {

  /** @domName HTMLModElement.cite */
  String cite;

  /** @domName HTMLModElement.dateTime */
  String dateTime;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class MouseEvent extends UIEvent native "*MouseEvent" {
  factory MouseEvent(String type, Window view, int detail, int screenX,
      int screenY, int clientX, int clientY, int button, [bool canBubble = true,
      bool cancelable = true, bool ctrlKey = false, bool altKey = false,
      bool shiftKey = false, bool metaKey = false,
      EventTarget relatedTarget = null]) =>
      _MouseEventFactoryProvider.createMouseEvent(
          type, view, detail, screenX, screenY,
          clientX, clientY, button, canBubble, cancelable,
          ctrlKey, altKey, shiftKey, metaKey,
          relatedTarget);

  /** @domName MouseEvent.altKey */
  final bool altKey;

  /** @domName MouseEvent.button */
  final int button;

  /** @domName MouseEvent.clientX */
  final int clientX;

  /** @domName MouseEvent.clientY */
  final int clientY;

  /** @domName MouseEvent.ctrlKey */
  final bool ctrlKey;

  /** @domName MouseEvent.dataTransfer */
  final Clipboard dataTransfer;

  /** @domName MouseEvent.fromElement */
  final Node fromElement;

  /** @domName MouseEvent.metaKey */
  final bool metaKey;

  /** @domName MouseEvent.relatedTarget */
  EventTarget get relatedTarget => _convertNativeToDart_EventTarget(this._relatedTarget);
  dynamic get _relatedTarget => JS("dynamic", "#.relatedTarget", this);

  /** @domName MouseEvent.screenX */
  final int screenX;

  /** @domName MouseEvent.screenY */
  final int screenY;

  /** @domName MouseEvent.shiftKey */
  final bool shiftKey;

  /** @domName MouseEvent.toElement */
  final Node toElement;

  /** @domName MouseEvent.webkitMovementX */
  final int webkitMovementX;

  /** @domName MouseEvent.webkitMovementY */
  final int webkitMovementY;

  /** @domName MouseEvent.x */
  final int x;

  /** @domName MouseEvent.y */
  final int y;

  /** @domName MouseEvent.initMouseEvent */
  void $dom_initMouseEvent(String type, bool canBubble, bool cancelable, LocalWindow view, int detail, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, int button, EventTarget relatedTarget) {
    var relatedTarget_1 = _convertDartToNative_EventTarget(relatedTarget);
    _$dom_initMouseEvent_1(type, canBubble, cancelable, view, detail, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey, button, relatedTarget_1);
    return;
  }
  void _$dom_initMouseEvent_1(type, canBubble, cancelable, LocalWindow view, detail, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey, button, relatedTarget) native "initMouseEvent";


  int get offsetX {
  if (JS('bool', '!!#.offsetX', this)) {
      return JS('int', '#.offsetX', this);
    } else {
      // Firefox does not support offsetX.
      var target = this.target;
      if (!(target is Element)) {
        throw new UnsupportedError(
            'offsetX is only supported on elements');
      }
      return this.clientX - this.target.getBoundingClientRect().left;
    }
  }

  int get offsetY {
    if (JS('bool', '!!#.offsetY', this)) {
      return JS('int', '#.offsetY', this);
    } else {
      // Firefox does not support offsetY.
      var target = this.target;
      if (!(target is Element)) {
        throw new UnsupportedError(
            'offsetY is only supported on elements');
      }
      return this.clientY - this.target.getBoundingClientRect().top;
    }
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void MutationCallback(List<MutationRecord> mutations, MutationObserver observer);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName MutationEvent
class MutationEvent extends Event native "*MutationEvent" {

  static const int ADDITION = 2;

  static const int MODIFICATION = 1;

  static const int REMOVAL = 3;

  /** @domName MutationEvent.attrChange */
  final int attrChange;

  /** @domName MutationEvent.attrName */
  final String attrName;

  /** @domName MutationEvent.newValue */
  final String newValue;

  /** @domName MutationEvent.prevValue */
  final String prevValue;

  /** @domName MutationEvent.relatedNode */
  final Node relatedNode;

  /** @domName MutationEvent.initMutationEvent */
  void initMutationEvent(String type, bool canBubble, bool cancelable, Node relatedNode, String prevValue, String newValue, String attrName, int attrChange) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class MutationObserver native "*MutationObserver" {

  factory MutationObserver(MutationCallback callback) => _MutationObserverFactoryProvider.createMutationObserver(callback);

  /** @domName MutationObserver.disconnect */
  void disconnect() native;

  /** @domName MutationObserver._observe */
  void _observe(Node target, Map options) {
    var options_1 = _convertDartToNative_Dictionary(options);
    __observe_1(target, options_1);
    return;
  }
  void __observe_1(Node target, options) native "observe";

  /** @domName MutationObserver.takeRecords */
  List<MutationRecord> takeRecords() native;

  void observe(Node target,
               {Map options,
                bool childList,
                bool attributes,
                bool characterData,
                bool subtree,
                bool attributeOldValue,
                bool characterDataOldValue,
                List<String> attributeFilter}) {

    // Parse options into map of known type.
    var parsedOptions = _createDict();

    if (options != null) {
      options.forEach((k, v) {
          if (_boolKeys.containsKey(k)) {
            _add(parsedOptions, k, true == v);
          } else if (k == 'attributeFilter') {
            _add(parsedOptions, k, _fixupList(v));
          } else {
            throw new ArgumentError(
                "Illegal MutationObserver.observe option '$k'");
          }
        });
    }

    // Override options passed in the map with named optional arguments.
    override(key, value) {
      if (value != null) _add(parsedOptions, key, value);
    }

    override('childList', childList);
    override('attributes', attributes);
    override('characterData', characterData);
    override('subtree', subtree);
    override('attributeOldValue', attributeOldValue);
    override('characterDataOldValue', characterDataOldValue);
    if (attributeFilter != null) {
      override('attributeFilter', _fixupList(attributeFilter));
    }

    _call(target, parsedOptions);
  }

   // TODO: Change to a set when const Sets are available.
  static final _boolKeys =
    const {'childList': true,
           'attributes': true,
           'characterData': true,
           'subtree': true,
           'attributeOldValue': true,
           'characterDataOldValue': true };


  static _createDict() => JS('var', '{}');
  static _add(m, String key, value) { JS('void', '#[#] = #', m, key, value); }
  static _fixupList(list) => list;  // TODO: Ensure is a JavaScript Array.

  // Call native function with no conversions.
  void _call(target, options) native 'observe';
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName MutationRecord
class MutationRecord native "*MutationRecord" {

  /** @domName MutationRecord.addedNodes */
  final List<Node> addedNodes;

  /** @domName MutationRecord.attributeName */
  final String attributeName;

  /** @domName MutationRecord.attributeNamespace */
  final String attributeNamespace;

  /** @domName MutationRecord.nextSibling */
  final Node nextSibling;

  /** @domName MutationRecord.oldValue */
  final String oldValue;

  /** @domName MutationRecord.previousSibling */
  final Node previousSibling;

  /** @domName MutationRecord.removedNodes */
  final List<Node> removedNodes;

  /** @domName MutationRecord.target */
  final Node target;

  /** @domName MutationRecord.type */
  final String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName NamedNodeMap
class NamedNodeMap implements JavaScriptIndexingBehavior, List<Node> native "*NamedNodeMap" {

  /** @domName NamedNodeMap.length */
  final int length;

  Node operator[](int index) => JS("Node", "#[#]", this, index);

  void operator[]=(int index, Node value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Node> mixins.
  // Node is the element type.

  // From Iterable<Node>:

  Iterator<Node> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Node>(this);
  }

  // From Collection<Node>:

  void add(Node value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(Node value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<Node> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(Node element) => _Collections.contains(this, element);

  void forEach(void f(Node element)) => _Collections.forEach(this, f);

  Collection map(f(Node element)) => _Collections.map(this, [], f);

  Collection<Node> filter(bool f(Node element)) =>
     _Collections.filter(this, <Node>[], f);

  bool every(bool f(Node element)) => _Collections.every(this, f);

  bool some(bool f(Node element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<Node>:

  void sort([Comparator<Node> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Node element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Node element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  Node get last => this[length - 1];

  Node removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<Node> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [Node initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<Node> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <Node>[]);

  // -- end List<Node> mixins.

  /** @domName NamedNodeMap.getNamedItem */
  Node getNamedItem(String name) native;

  /** @domName NamedNodeMap.getNamedItemNS */
  Node getNamedItemNS(String namespaceURI, String localName) native;

  /** @domName NamedNodeMap.item */
  Node item(int index) native;

  /** @domName NamedNodeMap.removeNamedItem */
  Node removeNamedItem(String name) native;

  /** @domName NamedNodeMap.removeNamedItemNS */
  Node removeNamedItemNS(String namespaceURI, String localName) native;

  /** @domName NamedNodeMap.setNamedItem */
  Node setNamedItem(Node node) native;

  /** @domName NamedNodeMap.setNamedItemNS */
  Node setNamedItemNS(Node node) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Navigator
class Navigator native "*Navigator" {

  /** @domName Navigator.appCodeName */
  final String appCodeName;

  /** @domName Navigator.appName */
  final String appName;

  /** @domName Navigator.appVersion */
  final String appVersion;

  /** @domName Navigator.cookieEnabled */
  final bool cookieEnabled;

  /** @domName Navigator.geolocation */
  final Geolocation geolocation;

  /** @domName Navigator.language */
  final String language;

  /** @domName Navigator.mimeTypes */
  final DOMMimeTypeArray mimeTypes;

  /** @domName Navigator.onLine */
  final bool onLine;

  /** @domName Navigator.platform */
  final String platform;

  /** @domName Navigator.plugins */
  final DOMPluginArray plugins;

  /** @domName Navigator.product */
  final String product;

  /** @domName Navigator.productSub */
  final String productSub;

  /** @domName Navigator.userAgent */
  final String userAgent;

  /** @domName Navigator.vendor */
  final String vendor;

  /** @domName Navigator.vendorSub */
  final String vendorSub;

  /** @domName Navigator.webkitBattery */
  final BatteryManager webkitBattery;

  /** @domName Navigator.getStorageUpdates */
  void getStorageUpdates() native;

  /** @domName Navigator.javaEnabled */
  bool javaEnabled() native;

  /** @domName Navigator.webkitGetGamepads */
  List<Gamepad> webkitGetGamepads() native;

  /** @domName Navigator.webkitGetUserMedia */
  void webkitGetUserMedia(Map options, NavigatorUserMediaSuccessCallback successCallback, [NavigatorUserMediaErrorCallback errorCallback]) {
    if (?errorCallback) {
      var options_1 = _convertDartToNative_Dictionary(options);
      _webkitGetUserMedia_1(options_1, successCallback, errorCallback);
      return;
    }
    var options_2 = _convertDartToNative_Dictionary(options);
    _webkitGetUserMedia_2(options_2, successCallback);
    return;
  }
  void _webkitGetUserMedia_1(options, NavigatorUserMediaSuccessCallback successCallback, NavigatorUserMediaErrorCallback errorCallback) native "webkitGetUserMedia";
  void _webkitGetUserMedia_2(options, NavigatorUserMediaSuccessCallback successCallback) native "webkitGetUserMedia";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName NavigatorUserMediaError
class NavigatorUserMediaError native "*NavigatorUserMediaError" {

  static const int PERMISSION_DENIED = 1;

  /** @domName NavigatorUserMediaError.code */
  final int code;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void NavigatorUserMediaErrorCallback(NavigatorUserMediaError error);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void NavigatorUserMediaSuccessCallback(LocalMediaStream stream);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * Lazy implementation of the child nodes of an element that does not request
 * the actual child nodes of an element until strictly necessary greatly
 * improving performance for the typical cases where it is not required.
 */
class _ChildNodeListLazy implements List {
  final Node _this;

  _ChildNodeListLazy(this._this);


  Node get first => JS('Node', '#.firstChild', _this);
  Node get last => JS('Node', '#.lastChild', _this);

  void add(Node value) {
    _this.$dom_appendChild(value);
  }

  void addLast(Node value) {
    _this.$dom_appendChild(value);
  }


  void addAll(Collection<Node> collection) {
    for (Node node in collection) {
      _this.$dom_appendChild(node);
    }
  }

  Node removeLast() {
    final result = last;
    if (result != null) {
      _this.$dom_removeChild(result);
    }
    return result;
  }

  void clear() {
    _this.text = '';
  }

  void operator []=(int index, Node value) {
    _this.$dom_replaceChild(value, this[index]);
  }

  Iterator<Node> iterator() => _this.$dom_childNodes.iterator();

  // TODO(jacobr): We can implement these methods much more efficiently by
  // looking up the nodeList only once instead of once per iteration.
  bool contains(Node element) => _Collections.contains(this, element);

  void forEach(void f(Node element)) => _Collections.forEach(this, f);

  Collection map(f(Node element)) => _Collections.map(this, [], f);

  Collection<Node> filter(bool f(Node element)) =>
     new _NodeListWrapper(_Collections.filter(this, <Node>[], f));

  bool every(bool f(Node element)) => _Collections.every(this, f);

  bool some(bool f(Node element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<Node>:

  // TODO(jacobr): this could be implemented for child node lists.
  // The exception we throw here is misleading.
  void sort([Comparator<Node> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Node element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Node element, [int start = 0]) =>
      _Lists.lastIndexOf(this, element, start);

  // FIXME: implement these.
  void setRange(int start, int rangeLength, List<Node> from, [int startFrom]) {
    throw new UnsupportedError(
        "Cannot setRange on immutable List.");
  }
  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError(
        "Cannot removeRange on immutable List.");
  }
  void insertRange(int start, int rangeLength, [Node initialValue]) {
    throw new UnsupportedError(
        "Cannot insertRange on immutable List.");
  }
  List<Node> getRange(int start, int rangeLength) =>
    new _NodeListWrapper(_Lists.getRange(this, start, rangeLength, <Node>[]));

  // -- end List<Node> mixins.

  // TODO(jacobr): benchmark whether this is more efficient or whether caching
  // a local copy of $dom_childNodes is more efficient.
  int get length => _this.$dom_childNodes.length;

  Node operator[](int index) => _this.$dom_childNodes[index];
}

class Node extends EventTarget native "*Node" {
  _ChildNodeListLazy get nodes {
    return new _ChildNodeListLazy(this);
  }

  void set nodes(Collection<Node> value) {
    // Copy list first since we don't want liveness during iteration.
    // TODO(jacobr): there is a better way to do this.
    List copy = new List.from(value);
    text = '';
    for (Node node in copy) {
      $dom_appendChild(node);
    }
  }

  /**
   * Removes this node from the DOM.
   * @domName Node.removeChild
   */
  void remove() {
    // TODO(jacobr): should we throw an exception if parent is already null?
    // TODO(vsm): Use the native remove when available.
    if (this.parent != null) {
      final Node parent = this.parent;
      parent.$dom_removeChild(this);
    }
  }

  /**
   * Replaces this node with another node.
   * @domName Node.replaceChild
   */
  Node replaceWith(Node otherNode) {
    try {
      final Node parent = this.parent;
      parent.$dom_replaceChild(otherNode, this);
    } catch (e) {

    };
    return this;
  }


  static const int ATTRIBUTE_NODE = 2;

  static const int CDATA_SECTION_NODE = 4;

  static const int COMMENT_NODE = 8;

  static const int DOCUMENT_FRAGMENT_NODE = 11;

  static const int DOCUMENT_NODE = 9;

  static const int DOCUMENT_POSITION_CONTAINED_BY = 0x10;

  static const int DOCUMENT_POSITION_CONTAINS = 0x08;

  static const int DOCUMENT_POSITION_DISCONNECTED = 0x01;

  static const int DOCUMENT_POSITION_FOLLOWING = 0x04;

  static const int DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC = 0x20;

  static const int DOCUMENT_POSITION_PRECEDING = 0x02;

  static const int DOCUMENT_TYPE_NODE = 10;

  static const int ELEMENT_NODE = 1;

  static const int ENTITY_NODE = 6;

  static const int ENTITY_REFERENCE_NODE = 5;

  static const int NOTATION_NODE = 12;

  static const int PROCESSING_INSTRUCTION_NODE = 7;

  static const int TEXT_NODE = 3;

  /** @domName Node.attributes */
  NamedNodeMap get $dom_attributes => JS("NamedNodeMap", "#.attributes", this);

  /** @domName Node.childNodes */
  List<Node> get $dom_childNodes => JS("List<Node>", "#.childNodes", this);

  /** @domName Node.firstChild */
  Node get $dom_firstChild => JS("Node", "#.firstChild", this);

  /** @domName Node.lastChild */
  Node get $dom_lastChild => JS("Node", "#.lastChild", this);

  /** @domName Node.nextSibling */
  Node get nextNode => JS("Node", "#.nextSibling", this);

  /** @domName Node.nodeType */
  int get $dom_nodeType => JS("int", "#.nodeType", this);

  /** @domName Node.ownerDocument */
  Document get document => JS("Document", "#.ownerDocument", this);

  /** @domName Node.parentNode */
  Node get parent => JS("Node", "#.parentNode", this);

  /** @domName Node.previousSibling */
  Node get previousNode => JS("Node", "#.previousSibling", this);

  /** @domName Node.textContent */
  String get text => JS("String", "#.textContent", this);

  /** @domName Node.textContent */
  void set text(String value) {
    JS("void", "#.textContent = #", this, value);
  }

  /** @domName Node.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "addEventListener";

  /** @domName Node.appendChild */
  Node $dom_appendChild(Node newChild) native "appendChild";

  /** @domName Node.cloneNode */
  Node clone(bool deep) native "cloneNode";

  /** @domName Node.contains */
  bool contains(Node other) native;

  /** @domName Node.dispatchEvent */
  bool $dom_dispatchEvent(Event event) native "dispatchEvent";

  /** @domName Node.hasChildNodes */
  bool hasChildNodes() native;

  /** @domName Node.insertBefore */
  Node insertBefore(Node newChild, Node refChild) native;

  /** @domName Node.removeChild */
  Node $dom_removeChild(Node oldChild) native "removeChild";

  /** @domName Node.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "removeEventListener";

  /** @domName Node.replaceChild */
  Node $dom_replaceChild(Node newChild, Node oldChild) native "replaceChild";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName NodeFilter
class NodeFilter native "*NodeFilter" {

  static const int FILTER_ACCEPT = 1;

  static const int FILTER_REJECT = 2;

  static const int FILTER_SKIP = 3;

  static const int SHOW_ALL = 0xFFFFFFFF;

  static const int SHOW_ATTRIBUTE = 0x00000002;

  static const int SHOW_CDATA_SECTION = 0x00000008;

  static const int SHOW_COMMENT = 0x00000080;

  static const int SHOW_DOCUMENT = 0x00000100;

  static const int SHOW_DOCUMENT_FRAGMENT = 0x00000400;

  static const int SHOW_DOCUMENT_TYPE = 0x00000200;

  static const int SHOW_ELEMENT = 0x00000001;

  static const int SHOW_ENTITY = 0x00000020;

  static const int SHOW_ENTITY_REFERENCE = 0x00000010;

  static const int SHOW_NOTATION = 0x00000800;

  static const int SHOW_PROCESSING_INSTRUCTION = 0x00000040;

  static const int SHOW_TEXT = 0x00000004;

  /** @domName NodeFilter.acceptNode */
  int acceptNode(Node n) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName NodeIterator
class NodeIterator native "*NodeIterator" {

  /** @domName NodeIterator.expandEntityReferences */
  final bool expandEntityReferences;

  /** @domName NodeIterator.filter */
  final NodeFilter filter;

  /** @domName NodeIterator.pointerBeforeReferenceNode */
  final bool pointerBeforeReferenceNode;

  /** @domName NodeIterator.referenceNode */
  final Node referenceNode;

  /** @domName NodeIterator.root */
  final Node root;

  /** @domName NodeIterator.whatToShow */
  final int whatToShow;

  /** @domName NodeIterator.detach */
  void detach() native;

  /** @domName NodeIterator.nextNode */
  Node nextNode() native;

  /** @domName NodeIterator.previousNode */
  Node previousNode() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// TODO(nweiz): when all implementations we target have the same name for the
// coreimpl implementation of List<E>, extend that rather than wrapping.
class _ListWrapper<E> implements List<E> {
  List _list;

  _ListWrapper(List this._list);

  Iterator<E> iterator() => _list.iterator();

  bool contains(E element) => _list.contains(element);

  void forEach(void f(E element)) => _list.forEach(f);

  Collection map(f(E element)) => _list.map(f);

  List<E> filter(bool f(E element)) => _list.filter(f);

  bool every(bool f(E element)) => _list.every(f);

  bool some(bool f(E element)) => _list.some(f);

  bool get isEmpty => _list.isEmpty;

  int get length => _list.length;

  E operator [](int index) => _list[index];

  void operator []=(int index, E value) { _list[index] = value; }

  void set length(int newLength) { _list.length = newLength; }

  void add(E value) => _list.add(value);

  void addLast(E value) => _list.addLast(value);

  void addAll(Collection<E> collection) => _list.addAll(collection);

  void sort([Comparator<E> compare = Comparable.compare]) => _list.sort(compare);

  int indexOf(E element, [int start = 0]) => _list.indexOf(element, start);

  int lastIndexOf(E element, [int start = 0]) =>
    _list.lastIndexOf(element, start);

  void clear() => _list.clear();

  E removeLast() => _list.removeLast();

  E get last => _list.last;

  List<E> getRange(int start, int rangeLength) =>
    _list.getRange(start, rangeLength);

  void setRange(int start, int rangeLength, List<E> from, [int startFrom = 0])
      => _list.setRange(start, rangeLength, from, startFrom);

  void removeRange(int start, int rangeLength) =>
    _list.removeRange(start, rangeLength);

  void insertRange(int start, int rangeLength, [E initialValue = null]) =>
    _list.insertRange(start, rangeLength, initialValue);

  E get first => _list[0];
}

/**
 * This class is used to insure the results of list operations are NodeLists
 * instead of lists.
 */
class _NodeListWrapper extends _ListWrapper<Node> implements List {
  _NodeListWrapper(List list) : super(list);

  List<Node> filter(bool f(Node element)) =>
    new _NodeListWrapper(_list.filter(f));

  List<Node> getRange(int start, int rangeLength) =>
    new _NodeListWrapper(_list.getRange(start, rangeLength));
}

class NodeList implements JavaScriptIndexingBehavior, List<Node> native "*NodeList" {
  Node _parent;

  // -- start List<Node> mixins.
  // Node is the element type.

  // From Iterable<Node>:

  Iterator<Node> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Node>(this);
  }

  // From Collection<Node>:

  void add(Node value) {
    _parent.$dom_appendChild(value);
  }

  void addLast(Node value) {
    _parent.$dom_appendChild(value);
  }

  void addAll(Collection<Node> collection) {
    for (Node node in collection) {
      _parent.$dom_appendChild(node);
    }
  }

  Node removeLast() {
    final result = this.last;
    if (result != null) {
      _parent.$dom_removeChild(result);
    }
    return result;
  }

  void clear() {
    _parent.text = '';
  }

  void operator []=(int index, Node value) {
    _parent.$dom_replaceChild(value, this[index]);
  }

  bool contains(Node element) => _Collections.contains(this, element);

  void forEach(void f(Node element)) => _Collections.forEach(this, f);

  Collection map(f(Node element)) => _Collections.map(this, [], f);

  Collection<Node> filter(bool f(Node element)) =>
     new _NodeListWrapper(_Collections.filter(this, <Node>[], f));

  bool every(bool f(Node element)) => _Collections.every(this, f);

  bool some(bool f(Node element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<Node>:

  void sort([Comparator<Node> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Node element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Node element, [int start = 0]) =>
      _Lists.lastIndexOf(this, element, start);

  Node get last => this[length - 1];
  Node get first => this[0];

  // FIXME: implement thesee.
  void setRange(int start, int rangeLength, List<Node> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }
  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }
  void insertRange(int start, int rangeLength, [Node initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }
  List<Node> getRange(int start, int rangeLength) =>
    new _NodeListWrapper(_Lists.getRange(this, start, rangeLength, <Node>[]));

  // -- end List<Node> mixins.


  /** @domName NodeList.length */
  final int length;

  Node operator[](int index) => JS("Node", "#[#]", this, index);

  /** @domName NodeList.item */
  Node _item(int index) native "item";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Notation
class Notation extends Node native "*Notation" {

  /** @domName Notation.publicId */
  final String publicId;

  /** @domName Notation.systemId */
  final String systemId;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Notification
class Notification extends EventTarget native "*Notification" {

  factory Notification(String title, [Map options]) {
    if (!?options) {
      return _NotificationFactoryProvider.createNotification(title);
    }
    return _NotificationFactoryProvider.createNotification(title, options);
  }

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  NotificationEvents get on =>
    new NotificationEvents(this);

  /** @domName Notification.dir */
  String dir;

  /** @domName Notification.permission */
  final String permission;

  /** @domName Notification.replaceId */
  String replaceId;

  /** @domName Notification.tag */
  String tag;

  /** @domName Notification.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "addEventListener";

  /** @domName Notification.cancel */
  void cancel() native;

  /** @domName Notification.close */
  void close() native;

  /** @domName Notification.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "dispatchEvent";

  /** @domName Notification.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "removeEventListener";

  /** @domName Notification.requestPermission */
  static void requestPermission(NotificationPermissionCallback callback) native;

  /** @domName Notification.show */
  void show() native;
}

class NotificationEvents extends Events {
  NotificationEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get click => this['click'];

  EventListenerList get close => this['close'];

  EventListenerList get display => this['display'];

  EventListenerList get error => this['error'];

  EventListenerList get show => this['show'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName NotificationCenter
class NotificationCenter native "*NotificationCenter" {

  /** @domName NotificationCenter.checkPermission */
  int checkPermission() native;

  /** @domName NotificationCenter.createHTMLNotification */
  Notification createHTMLNotification(String url) native;

  /** @domName NotificationCenter.createNotification */
  Notification createNotification(String iconUrl, String title, String body) native;

  /** @domName NotificationCenter.requestPermission */
  void requestPermission(VoidCallback callback) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void NotificationPermissionCallback(String permission);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName OESElementIndexUint
class OESElementIndexUint native "*OESElementIndexUint" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName OESStandardDerivatives
class OESStandardDerivatives native "*OESStandardDerivatives" {

  static const int FRAGMENT_SHADER_DERIVATIVE_HINT_OES = 0x8B8B;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName OESTextureFloat
class OESTextureFloat native "*OESTextureFloat" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName OESVertexArrayObject
class OESVertexArrayObject native "*OESVertexArrayObject" {

  static const int VERTEX_ARRAY_BINDING_OES = 0x85B5;

  /** @domName OESVertexArrayObject.bindVertexArrayOES */
  void bindVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) native;

  /** @domName OESVertexArrayObject.createVertexArrayOES */
  WebGLVertexArrayObjectOES createVertexArrayOES() native;

  /** @domName OESVertexArrayObject.deleteVertexArrayOES */
  void deleteVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) native;

  /** @domName OESVertexArrayObject.isVertexArrayOES */
  bool isVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLOListElement
class OListElement extends Element implements Element native "*HTMLOListElement" {

  factory OListElement() => _Elements.createOListElement();

  /** @domName HTMLOListElement.compact */
  bool compact;

  /** @domName HTMLOListElement.reversed */
  bool reversed;

  /** @domName HTMLOListElement.start */
  int start;

  /** @domName HTMLOListElement.type */
  String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLObjectElement
class ObjectElement extends Element implements Element native "*HTMLObjectElement" {

  factory ObjectElement() => _Elements.createObjectElement();

  /** @domName HTMLObjectElement.align */
  String align;

  /** @domName HTMLObjectElement.archive */
  String archive;

  /** @domName HTMLObjectElement.border */
  String border;

  /** @domName HTMLObjectElement.code */
  String code;

  /** @domName HTMLObjectElement.codeBase */
  String codeBase;

  /** @domName HTMLObjectElement.codeType */
  String codeType;

  /** @domName HTMLObjectElement.data */
  String data;

  /** @domName HTMLObjectElement.declare */
  bool declare;

  /** @domName HTMLObjectElement.form */
  final FormElement form;

  /** @domName HTMLObjectElement.height */
  String height;

  /** @domName HTMLObjectElement.hspace */
  int hspace;

  /** @domName HTMLObjectElement.name */
  String name;

  /** @domName HTMLObjectElement.standby */
  String standby;

  /** @domName HTMLObjectElement.type */
  String type;

  /** @domName HTMLObjectElement.useMap */
  String useMap;

  /** @domName HTMLObjectElement.validationMessage */
  final String validationMessage;

  /** @domName HTMLObjectElement.validity */
  final ValidityState validity;

  /** @domName HTMLObjectElement.vspace */
  int vspace;

  /** @domName HTMLObjectElement.width */
  String width;

  /** @domName HTMLObjectElement.willValidate */
  final bool willValidate;

  /** @domName HTMLObjectElement.checkValidity */
  bool checkValidity() native;

  /** @domName HTMLObjectElement.setCustomValidity */
  void setCustomValidity(String error) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName OfflineAudioCompletionEvent
class OfflineAudioCompletionEvent extends Event native "*OfflineAudioCompletionEvent" {

  /** @domName OfflineAudioCompletionEvent.renderedBuffer */
  final AudioBuffer renderedBuffer;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLOptGroupElement
class OptGroupElement extends Element implements Element native "*HTMLOptGroupElement" {

  factory OptGroupElement() => _Elements.createOptGroupElement();

  /** @domName HTMLOptGroupElement.disabled */
  bool disabled;

  /** @domName HTMLOptGroupElement.label */
  String label;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLOptionElement
class OptionElement extends Element implements Element native "*HTMLOptionElement" {

  factory OptionElement([String data, String value, bool defaultSelected, bool selected]) {
    if (!?data) {
      return _OptionElementFactoryProvider.createOptionElement();
    }
    if (!?value) {
      return _OptionElementFactoryProvider.createOptionElement(data);
    }
    if (!?defaultSelected) {
      return _OptionElementFactoryProvider.createOptionElement(data, value);
    }
    if (!?selected) {
      return _OptionElementFactoryProvider.createOptionElement(data, value, defaultSelected);
    }
    return _OptionElementFactoryProvider.createOptionElement(data, value, defaultSelected, selected);
  }

  /** @domName HTMLOptionElement.defaultSelected */
  bool defaultSelected;

  /** @domName HTMLOptionElement.disabled */
  bool disabled;

  /** @domName HTMLOptionElement.form */
  final FormElement form;

  /** @domName HTMLOptionElement.index */
  final int index;

  /** @domName HTMLOptionElement.label */
  String label;

  /** @domName HTMLOptionElement.selected */
  bool selected;

  /** @domName HTMLOptionElement.value */
  String value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName OscillatorNode
class OscillatorNode extends AudioSourceNode native "*OscillatorNode" {

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
  final AudioParam detune;

  /** @domName OscillatorNode.frequency */
  final AudioParam frequency;

  /** @domName OscillatorNode.playbackState */
  final int playbackState;

  /** @domName OscillatorNode.type */
  int type;

  /** @domName OscillatorNode.setWaveTable */
  void setWaveTable(WaveTable waveTable) native;

  /** @domName OscillatorNode.start */
  void start(num when) native;

  /** @domName OscillatorNode.stop */
  void stop(num when) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLOutputElement
class OutputElement extends Element implements Element native "*HTMLOutputElement" {

  factory OutputElement() => _Elements.createOutputElement();

  /** @domName HTMLOutputElement.defaultValue */
  String defaultValue;

  /** @domName HTMLOutputElement.form */
  final FormElement form;

  /** @domName HTMLOutputElement.htmlFor */
  DOMSettableTokenList htmlFor;

  /** @domName HTMLOutputElement.labels */
  final List<Node> labels;

  /** @domName HTMLOutputElement.name */
  String name;

  /** @domName HTMLOutputElement.type */
  final String type;

  /** @domName HTMLOutputElement.validationMessage */
  final String validationMessage;

  /** @domName HTMLOutputElement.validity */
  final ValidityState validity;

  /** @domName HTMLOutputElement.value */
  String value;

  /** @domName HTMLOutputElement.willValidate */
  final bool willValidate;

  /** @domName HTMLOutputElement.checkValidity */
  bool checkValidity() native;

  /** @domName HTMLOutputElement.setCustomValidity */
  void setCustomValidity(String error) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName OverflowEvent
class OverflowEvent extends Event native "*OverflowEvent" {

  static const int BOTH = 2;

  static const int HORIZONTAL = 0;

  static const int VERTICAL = 1;

  /** @domName OverflowEvent.horizontalOverflow */
  final bool horizontalOverflow;

  /** @domName OverflowEvent.orient */
  final int orient;

  /** @domName OverflowEvent.verticalOverflow */
  final bool verticalOverflow;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName PagePopupController
class PagePopupController native "*PagePopupController" {

  /** @domName PagePopupController.localizeNumberString */
  String localizeNumberString(String numberString) native;

  /** @domName PagePopupController.setValueAndClosePopup */
  void setValueAndClosePopup(int numberValue, String stringValue) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName PageTransitionEvent
class PageTransitionEvent extends Event native "*PageTransitionEvent" {

  /** @domName PageTransitionEvent.persisted */
  final bool persisted;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName PannerNode
class PannerNode extends AudioNode native "*PannerNode" {

  static const int EQUALPOWER = 0;

  static const int EXPONENTIAL_DISTANCE = 2;

  static const int HRTF = 1;

  static const int INVERSE_DISTANCE = 1;

  static const int LINEAR_DISTANCE = 0;

  static const int SOUNDFIELD = 2;

  /** @domName PannerNode.coneGain */
  final AudioGain coneGain;

  /** @domName PannerNode.coneInnerAngle */
  num coneInnerAngle;

  /** @domName PannerNode.coneOuterAngle */
  num coneOuterAngle;

  /** @domName PannerNode.coneOuterGain */
  num coneOuterGain;

  /** @domName PannerNode.distanceGain */
  final AudioGain distanceGain;

  /** @domName PannerNode.distanceModel */
  int distanceModel;

  /** @domName PannerNode.maxDistance */
  num maxDistance;

  /** @domName PannerNode.panningModel */
  int panningModel;

  /** @domName PannerNode.refDistance */
  num refDistance;

  /** @domName PannerNode.rolloffFactor */
  num rolloffFactor;

  /** @domName PannerNode.setOrientation */
  void setOrientation(num x, num y, num z) native;

  /** @domName PannerNode.setPosition */
  void setPosition(num x, num y, num z) native;

  /** @domName PannerNode.setVelocity */
  void setVelocity(num x, num y, num z) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLParagraphElement
class ParagraphElement extends Element implements Element native "*HTMLParagraphElement" {

  factory ParagraphElement() => _Elements.createParagraphElement();

  /** @domName HTMLParagraphElement.align */
  String align;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLParamElement
class ParamElement extends Element implements Element native "*HTMLParamElement" {

  factory ParamElement() => _Elements.createParamElement();

  /** @domName HTMLParamElement.name */
  String name;

  /** @domName HTMLParamElement.type */
  String type;

  /** @domName HTMLParamElement.value */
  String value;

  /** @domName HTMLParamElement.valueType */
  String valueType;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName PeerConnection00
class PeerConnection00 extends EventTarget native "*PeerConnection00" {

  factory PeerConnection00(String serverConfiguration, IceCallback iceCallback) => _PeerConnection00FactoryProvider.createPeerConnection00(serverConfiguration, iceCallback);

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  PeerConnection00Events get on =>
    new PeerConnection00Events(this);

  static const int ACTIVE = 2;

  static const int CLOSED = 3;

  static const int ICE_CHECKING = 0x300;

  static const int ICE_CLOSED = 0x700;

  static const int ICE_COMPLETED = 0x500;

  static const int ICE_CONNECTED = 0x400;

  static const int ICE_FAILED = 0x600;

  static const int ICE_GATHERING = 0x100;

  static const int ICE_WAITING = 0x200;

  static const int NEW = 0;

  static const int OPENING = 1;

  static const int SDP_ANSWER = 0x300;

  static const int SDP_OFFER = 0x100;

  static const int SDP_PRANSWER = 0x200;

  /** @domName PeerConnection00.iceState */
  final int iceState;

  /** @domName PeerConnection00.localDescription */
  final SessionDescription localDescription;

  /** @domName PeerConnection00.localStreams */
  final List<MediaStream> localStreams;

  /** @domName PeerConnection00.readyState */
  final int readyState;

  /** @domName PeerConnection00.remoteDescription */
  final SessionDescription remoteDescription;

  /** @domName PeerConnection00.remoteStreams */
  final List<MediaStream> remoteStreams;

  /** @domName PeerConnection00.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "addEventListener";

  /** @domName PeerConnection00.addStream */
  void addStream(MediaStream stream, [Map mediaStreamHints]) {
    if (?mediaStreamHints) {
      var mediaStreamHints_1 = _convertDartToNative_Dictionary(mediaStreamHints);
      _addStream_1(stream, mediaStreamHints_1);
      return;
    }
    _addStream_2(stream);
    return;
  }
  void _addStream_1(MediaStream stream, mediaStreamHints) native "addStream";
  void _addStream_2(MediaStream stream) native "addStream";

  /** @domName PeerConnection00.close */
  void close() native;

  /** @domName PeerConnection00.createAnswer */
  SessionDescription createAnswer(String offer, [Map mediaHints]) {
    if (?mediaHints) {
      var mediaHints_1 = _convertDartToNative_Dictionary(mediaHints);
      return _createAnswer_1(offer, mediaHints_1);
    }
    return _createAnswer_2(offer);
  }
  SessionDescription _createAnswer_1(offer, mediaHints) native "createAnswer";
  SessionDescription _createAnswer_2(offer) native "createAnswer";

  /** @domName PeerConnection00.createOffer */
  SessionDescription createOffer([Map mediaHints]) {
    if (?mediaHints) {
      var mediaHints_1 = _convertDartToNative_Dictionary(mediaHints);
      return _createOffer_1(mediaHints_1);
    }
    return _createOffer_2();
  }
  SessionDescription _createOffer_1(mediaHints) native "createOffer";
  SessionDescription _createOffer_2() native "createOffer";

  /** @domName PeerConnection00.dispatchEvent */
  bool $dom_dispatchEvent(Event event) native "dispatchEvent";

  /** @domName PeerConnection00.processIceMessage */
  void processIceMessage(IceCandidate candidate) native;

  /** @domName PeerConnection00.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "removeEventListener";

  /** @domName PeerConnection00.removeStream */
  void removeStream(MediaStream stream) native;

  /** @domName PeerConnection00.setLocalDescription */
  void setLocalDescription(int action, SessionDescription desc) native;

  /** @domName PeerConnection00.setRemoteDescription */
  void setRemoteDescription(int action, SessionDescription desc) native;

  /** @domName PeerConnection00.startIce */
  void startIce([Map iceOptions]) {
    if (?iceOptions) {
      var iceOptions_1 = _convertDartToNative_Dictionary(iceOptions);
      _startIce_1(iceOptions_1);
      return;
    }
    _startIce_2();
    return;
  }
  void _startIce_1(iceOptions) native "startIce";
  void _startIce_2() native "startIce";
}

class PeerConnection00Events extends Events {
  PeerConnection00Events(EventTarget _ptr) : super(_ptr);

  EventListenerList get addStream => this['addstream'];

  EventListenerList get connecting => this['connecting'];

  EventListenerList get open => this['open'];

  EventListenerList get removeStream => this['removestream'];

  EventListenerList get stateChange => this['statechange'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Performance
class Performance extends EventTarget native "*Performance" {

  /** @domName Performance.memory */
  final MemoryInfo memory;

  /** @domName Performance.navigation */
  final PerformanceNavigation navigation;

  /** @domName Performance.timing */
  final PerformanceTiming timing;

  /** @domName Performance.now */
  num now() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName PerformanceNavigation
class PerformanceNavigation native "*PerformanceNavigation" {

  static const int TYPE_BACK_FORWARD = 2;

  static const int TYPE_NAVIGATE = 0;

  static const int TYPE_RELOAD = 1;

  static const int TYPE_RESERVED = 255;

  /** @domName PerformanceNavigation.redirectCount */
  final int redirectCount;

  /** @domName PerformanceNavigation.type */
  final int type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName PerformanceTiming
class PerformanceTiming native "*PerformanceTiming" {

  /** @domName PerformanceTiming.connectEnd */
  final int connectEnd;

  /** @domName PerformanceTiming.connectStart */
  final int connectStart;

  /** @domName PerformanceTiming.domComplete */
  final int domComplete;

  /** @domName PerformanceTiming.domContentLoadedEventEnd */
  final int domContentLoadedEventEnd;

  /** @domName PerformanceTiming.domContentLoadedEventStart */
  final int domContentLoadedEventStart;

  /** @domName PerformanceTiming.domInteractive */
  final int domInteractive;

  /** @domName PerformanceTiming.domLoading */
  final int domLoading;

  /** @domName PerformanceTiming.domainLookupEnd */
  final int domainLookupEnd;

  /** @domName PerformanceTiming.domainLookupStart */
  final int domainLookupStart;

  /** @domName PerformanceTiming.fetchStart */
  final int fetchStart;

  /** @domName PerformanceTiming.loadEventEnd */
  final int loadEventEnd;

  /** @domName PerformanceTiming.loadEventStart */
  final int loadEventStart;

  /** @domName PerformanceTiming.navigationStart */
  final int navigationStart;

  /** @domName PerformanceTiming.redirectEnd */
  final int redirectEnd;

  /** @domName PerformanceTiming.redirectStart */
  final int redirectStart;

  /** @domName PerformanceTiming.requestStart */
  final int requestStart;

  /** @domName PerformanceTiming.responseEnd */
  final int responseEnd;

  /** @domName PerformanceTiming.responseStart */
  final int responseStart;

  /** @domName PerformanceTiming.secureConnectionStart */
  final int secureConnectionStart;

  /** @domName PerformanceTiming.unloadEventEnd */
  final int unloadEventEnd;

  /** @domName PerformanceTiming.unloadEventStart */
  final int unloadEventStart;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


class Point native "*WebKitPoint" {
  factory Point(num x, num y) => _PointFactoryProvider.createPoint(x, y);

  /** @domName WebKitPoint.x */
  num x;

  /** @domName WebKitPoint.y */
  num y;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName PopStateEvent
class PopStateEvent extends Event native "*PopStateEvent" {

  /** @domName PopStateEvent.state */
  dynamic get state => _convertNativeToDart_SerializedScriptValue(this._state);
  dynamic get _state => JS("dynamic", "#.state", this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void PositionCallback(Geoposition position);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName PositionError
class PositionError native "*PositionError" {

  static const int PERMISSION_DENIED = 1;

  static const int POSITION_UNAVAILABLE = 2;

  static const int TIMEOUT = 3;

  /** @domName PositionError.code */
  final int code;

  /** @domName PositionError.message */
  final String message;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void PositionErrorCallback(PositionError error);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLPreElement
class PreElement extends Element implements Element native "*HTMLPreElement" {

  factory PreElement() => _Elements.createPreElement();

  /** @domName HTMLPreElement.width */
  int width;

  /** @domName HTMLPreElement.wrap */
  bool wrap;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName ProcessingInstruction
class ProcessingInstruction extends Node native "*ProcessingInstruction" {

  /** @domName ProcessingInstruction.data */
  String data;

  /** @domName ProcessingInstruction.sheet */
  final StyleSheet sheet;

  /** @domName ProcessingInstruction.target */
  final String target;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLProgressElement
class ProgressElement extends Element implements Element native "*HTMLProgressElement" {

  factory ProgressElement() => _Elements.createProgressElement();

  /** @domName HTMLProgressElement.labels */
  final List<Node> labels;

  /** @domName HTMLProgressElement.max */
  num max;

  /** @domName HTMLProgressElement.position */
  final num position;

  /** @domName HTMLProgressElement.value */
  num value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName ProgressEvent
class ProgressEvent extends Event native "*ProgressEvent" {

  /** @domName ProgressEvent.lengthComputable */
  final bool lengthComputable;

  /** @domName ProgressEvent.loaded */
  final int loaded;

  /** @domName ProgressEvent.total */
  final int total;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLQuoteElement
class QuoteElement extends Element implements Element native "*HTMLQuoteElement" {

  /** @domName HTMLQuoteElement.cite */
  String cite;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName RGBColor
class RGBColor native "*RGBColor" {

  /** @domName RGBColor.blue */
  final CSSPrimitiveValue blue;

  /** @domName RGBColor.green */
  final CSSPrimitiveValue green;

  /** @domName RGBColor.red */
  final CSSPrimitiveValue red;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName RTCDataChannel
class RTCDataChannel extends EventTarget native "*RTCDataChannel" {

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  RTCDataChannelEvents get on =>
    new RTCDataChannelEvents(this);

  /** @domName RTCDataChannel.binaryType */
  String binaryType;

  /** @domName RTCDataChannel.bufferedAmount */
  final int bufferedAmount;

  /** @domName RTCDataChannel.label */
  final String label;

  /** @domName RTCDataChannel.readyState */
  final String readyState;

  /** @domName RTCDataChannel.reliable */
  final bool reliable;

  /** @domName RTCDataChannel.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "addEventListener";

  /** @domName RTCDataChannel.close */
  void close() native;

  /** @domName RTCDataChannel.dispatchEvent */
  bool $dom_dispatchEvent(Event event) native "dispatchEvent";

  /** @domName RTCDataChannel.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "removeEventListener";

  /** @domName RTCDataChannel.send */
  void send(data) native;
}

class RTCDataChannelEvents extends Events {
  RTCDataChannelEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get close => this['close'];

  EventListenerList get error => this['error'];

  EventListenerList get message => this['message'];

  EventListenerList get open => this['open'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName RTCDataChannelEvent
class RTCDataChannelEvent extends Event native "*RTCDataChannelEvent" {

  /** @domName RTCDataChannelEvent.channel */
  final RTCDataChannel channel;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void RTCErrorCallback(String errorInformation);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName RTCIceCandidate
class RTCIceCandidate native "*RTCIceCandidate" {

  factory RTCIceCandidate(Map dictionary) => _RTCIceCandidateFactoryProvider.createRTCIceCandidate(dictionary);

  /** @domName RTCIceCandidate.candidate */
  final String candidate;

  /** @domName RTCIceCandidate.sdpMLineIndex */
  final int sdpMLineIndex;

  /** @domName RTCIceCandidate.sdpMid */
  final String sdpMid;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName RTCIceCandidateEvent
class RTCIceCandidateEvent extends Event native "*RTCIceCandidateEvent" {

  /** @domName RTCIceCandidateEvent.candidate */
  final RTCIceCandidate candidate;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName RTCPeerConnection
class RTCPeerConnection extends EventTarget native "*RTCPeerConnection" {

  factory RTCPeerConnection(Map rtcIceServers, [Map mediaConstraints]) {
    if (!?mediaConstraints) {
      return _RTCPeerConnectionFactoryProvider.createRTCPeerConnection(rtcIceServers);
    }
    return _RTCPeerConnectionFactoryProvider.createRTCPeerConnection(rtcIceServers, mediaConstraints);
  }

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  RTCPeerConnectionEvents get on =>
    new RTCPeerConnectionEvents(this);

  /** @domName RTCPeerConnection.iceState */
  final String iceState;

  /** @domName RTCPeerConnection.localDescription */
  final RTCSessionDescription localDescription;

  /** @domName RTCPeerConnection.localStreams */
  final List<MediaStream> localStreams;

  /** @domName RTCPeerConnection.readyState */
  final String readyState;

  /** @domName RTCPeerConnection.remoteDescription */
  final RTCSessionDescription remoteDescription;

  /** @domName RTCPeerConnection.remoteStreams */
  final List<MediaStream> remoteStreams;

  /** @domName RTCPeerConnection.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "addEventListener";

  /** @domName RTCPeerConnection.addIceCandidate */
  void addIceCandidate(RTCIceCandidate candidate) native;

  /** @domName RTCPeerConnection.addStream */
  void addStream(MediaStream stream, [Map mediaConstraints]) {
    if (?mediaConstraints) {
      var mediaConstraints_1 = _convertDartToNative_Dictionary(mediaConstraints);
      _addStream_1(stream, mediaConstraints_1);
      return;
    }
    _addStream_2(stream);
    return;
  }
  void _addStream_1(MediaStream stream, mediaConstraints) native "addStream";
  void _addStream_2(MediaStream stream) native "addStream";

  /** @domName RTCPeerConnection.close */
  void close() native;

  /** @domName RTCPeerConnection.createAnswer */
  void createAnswer(RTCSessionDescriptionCallback successCallback, [RTCErrorCallback failureCallback, Map mediaConstraints]) {
    if (?mediaConstraints) {
      var mediaConstraints_1 = _convertDartToNative_Dictionary(mediaConstraints);
      _createAnswer_1(successCallback, failureCallback, mediaConstraints_1);
      return;
    }
    _createAnswer_2(successCallback, failureCallback);
    return;
  }
  void _createAnswer_1(RTCSessionDescriptionCallback successCallback, RTCErrorCallback failureCallback, mediaConstraints) native "createAnswer";
  void _createAnswer_2(RTCSessionDescriptionCallback successCallback, RTCErrorCallback failureCallback) native "createAnswer";

  /** @domName RTCPeerConnection.createDataChannel */
  RTCDataChannel createDataChannel(String label, [Map options]) {
    if (?options) {
      var options_1 = _convertDartToNative_Dictionary(options);
      return _createDataChannel_1(label, options_1);
    }
    return _createDataChannel_2(label);
  }
  RTCDataChannel _createDataChannel_1(label, options) native "createDataChannel";
  RTCDataChannel _createDataChannel_2(label) native "createDataChannel";

  /** @domName RTCPeerConnection.createOffer */
  void createOffer(RTCSessionDescriptionCallback successCallback, [RTCErrorCallback failureCallback, Map mediaConstraints]) {
    if (?mediaConstraints) {
      var mediaConstraints_1 = _convertDartToNative_Dictionary(mediaConstraints);
      _createOffer_1(successCallback, failureCallback, mediaConstraints_1);
      return;
    }
    _createOffer_2(successCallback, failureCallback);
    return;
  }
  void _createOffer_1(RTCSessionDescriptionCallback successCallback, RTCErrorCallback failureCallback, mediaConstraints) native "createOffer";
  void _createOffer_2(RTCSessionDescriptionCallback successCallback, RTCErrorCallback failureCallback) native "createOffer";

  /** @domName RTCPeerConnection.dispatchEvent */
  bool $dom_dispatchEvent(Event event) native "dispatchEvent";

  /** @domName RTCPeerConnection.getStats */
  void getStats(RTCStatsCallback successCallback, MediaStreamTrack selector) native;

  /** @domName RTCPeerConnection.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "removeEventListener";

  /** @domName RTCPeerConnection.removeStream */
  void removeStream(MediaStream stream) native;

  /** @domName RTCPeerConnection.setLocalDescription */
  void setLocalDescription(RTCSessionDescription description, [VoidCallback successCallback, RTCErrorCallback failureCallback]) native;

  /** @domName RTCPeerConnection.setRemoteDescription */
  void setRemoteDescription(RTCSessionDescription description, [VoidCallback successCallback, RTCErrorCallback failureCallback]) native;

  /** @domName RTCPeerConnection.updateIce */
  void updateIce([Map configuration, Map mediaConstraints]) {
    if (?mediaConstraints) {
      var configuration_1 = _convertDartToNative_Dictionary(configuration);
      var mediaConstraints_2 = _convertDartToNative_Dictionary(mediaConstraints);
      _updateIce_1(configuration_1, mediaConstraints_2);
      return;
    }
    if (?configuration) {
      var configuration_3 = _convertDartToNative_Dictionary(configuration);
      _updateIce_2(configuration_3);
      return;
    }
    _updateIce_3();
    return;
  }
  void _updateIce_1(configuration, mediaConstraints) native "updateIce";
  void _updateIce_2(configuration) native "updateIce";
  void _updateIce_3() native "updateIce";
}

class RTCPeerConnectionEvents extends Events {
  RTCPeerConnectionEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get addStream => this['addstream'];

  EventListenerList get iceCandidate => this['icecandidate'];

  EventListenerList get iceChange => this['icechange'];

  EventListenerList get negotiationNeeded => this['negotiationneeded'];

  EventListenerList get open => this['open'];

  EventListenerList get removeStream => this['removestream'];

  EventListenerList get stateChange => this['statechange'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName RTCSessionDescription
class RTCSessionDescription native "*RTCSessionDescription" {

  factory RTCSessionDescription(Map dictionary) => _RTCSessionDescriptionFactoryProvider.createRTCSessionDescription(dictionary);

  /** @domName RTCSessionDescription.sdp */
  String sdp;

  /** @domName RTCSessionDescription.type */
  String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void RTCSessionDescriptionCallback(RTCSessionDescription sdp);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void RTCStatsCallback(RTCStatsResponse response);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName RTCStatsElement
class RTCStatsElement native "*RTCStatsElement" {

  /** @domName RTCStatsElement.timestamp */
  final Date timestamp;

  /** @domName RTCStatsElement.stat */
  String stat(String name) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName RTCStatsReport
class RTCStatsReport native "*RTCStatsReport" {

  /** @domName RTCStatsReport.local */
  final RTCStatsElement local;

  /** @domName RTCStatsReport.remote */
  final RTCStatsElement remote;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName RTCStatsResponse
class RTCStatsResponse native "*RTCStatsResponse" {

  /** @domName RTCStatsResponse.result */
  List<RTCStatsReport> result() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName RadioNodeList
class RadioNodeList extends NodeList native "*RadioNodeList" {

  /** @domName RadioNodeList.value */
  String value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Range
class Range native "*Range" {

  static const int END_TO_END = 2;

  static const int END_TO_START = 3;

  static const int NODE_AFTER = 1;

  static const int NODE_BEFORE = 0;

  static const int NODE_BEFORE_AND_AFTER = 2;

  static const int NODE_INSIDE = 3;

  static const int START_TO_END = 1;

  static const int START_TO_START = 0;

  /** @domName Range.collapsed */
  final bool collapsed;

  /** @domName Range.commonAncestorContainer */
  final Node commonAncestorContainer;

  /** @domName Range.endContainer */
  final Node endContainer;

  /** @domName Range.endOffset */
  final int endOffset;

  /** @domName Range.startContainer */
  final Node startContainer;

  /** @domName Range.startOffset */
  final int startOffset;

  /** @domName Range.cloneContents */
  DocumentFragment cloneContents() native;

  /** @domName Range.cloneRange */
  Range cloneRange() native;

  /** @domName Range.collapse */
  void collapse(bool toStart) native;

  /** @domName Range.compareNode */
  int compareNode(Node refNode) native;

  /** @domName Range.comparePoint */
  int comparePoint(Node refNode, int offset) native;

  /** @domName Range.createContextualFragment */
  DocumentFragment createContextualFragment(String html) native;

  /** @domName Range.deleteContents */
  void deleteContents() native;

  /** @domName Range.detach */
  void detach() native;

  /** @domName Range.expand */
  void expand(String unit) native;

  /** @domName Range.extractContents */
  DocumentFragment extractContents() native;

  /** @domName Range.getBoundingClientRect */
  ClientRect getBoundingClientRect() native;

  /** @domName Range.getClientRects */
  List<ClientRect> getClientRects() native;

  /** @domName Range.insertNode */
  void insertNode(Node newNode) native;

  /** @domName Range.intersectsNode */
  bool intersectsNode(Node refNode) native;

  /** @domName Range.isPointInRange */
  bool isPointInRange(Node refNode, int offset) native;

  /** @domName Range.selectNode */
  void selectNode(Node refNode) native;

  /** @domName Range.selectNodeContents */
  void selectNodeContents(Node refNode) native;

  /** @domName Range.setEnd */
  void setEnd(Node refNode, int offset) native;

  /** @domName Range.setEndAfter */
  void setEndAfter(Node refNode) native;

  /** @domName Range.setEndBefore */
  void setEndBefore(Node refNode) native;

  /** @domName Range.setStart */
  void setStart(Node refNode, int offset) native;

  /** @domName Range.setStartAfter */
  void setStartAfter(Node refNode) native;

  /** @domName Range.setStartBefore */
  void setStartBefore(Node refNode) native;

  /** @domName Range.surroundContents */
  void surroundContents(Node newParent) native;

  /** @domName Range.toString */
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName RangeException
class RangeException native "*RangeException" {

  static const int BAD_BOUNDARYPOINTS_ERR = 1;

  static const int INVALID_NODE_TYPE_ERR = 2;

  /** @domName RangeException.code */
  final int code;

  /** @domName RangeException.message */
  final String message;

  /** @domName RangeException.name */
  final String name;

  /** @domName RangeException.toString */
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Rect
class Rect native "*Rect" {

  /** @domName Rect.bottom */
  final CSSPrimitiveValue bottom;

  /** @domName Rect.left */
  final CSSPrimitiveValue left;

  /** @domName Rect.right */
  final CSSPrimitiveValue right;

  /** @domName Rect.top */
  final CSSPrimitiveValue top;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void RequestAnimationFrameCallback(num highResTime);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SQLError
class SQLError native "*SQLError" {

  static const int CONSTRAINT_ERR = 6;

  static const int DATABASE_ERR = 1;

  static const int QUOTA_ERR = 4;

  static const int SYNTAX_ERR = 5;

  static const int TIMEOUT_ERR = 7;

  static const int TOO_LARGE_ERR = 3;

  static const int UNKNOWN_ERR = 0;

  static const int VERSION_ERR = 2;

  /** @domName SQLError.code */
  final int code;

  /** @domName SQLError.message */
  final String message;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SQLException
class SQLException native "*SQLException" {

  static const int CONSTRAINT_ERR = 6;

  static const int DATABASE_ERR = 1;

  static const int QUOTA_ERR = 4;

  static const int SYNTAX_ERR = 5;

  static const int TIMEOUT_ERR = 7;

  static const int TOO_LARGE_ERR = 3;

  static const int UNKNOWN_ERR = 0;

  static const int VERSION_ERR = 2;

  /** @domName SQLException.code */
  final int code;

  /** @domName SQLException.message */
  final String message;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SQLResultSet
class SQLResultSet native "*SQLResultSet" {

  /** @domName SQLResultSet.insertId */
  final int insertId;

  /** @domName SQLResultSet.rows */
  final SQLResultSetRowList rows;

  /** @domName SQLResultSet.rowsAffected */
  final int rowsAffected;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SQLResultSetRowList
class SQLResultSetRowList implements JavaScriptIndexingBehavior, List<Map> native "*SQLResultSetRowList" {

  /** @domName SQLResultSetRowList.length */
  final int length;

  Map operator[](int index) => JS("Map", "#[#]", this, index);

  void operator[]=(int index, Map value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Map> mixins.
  // Map is the element type.

  // From Iterable<Map>:

  Iterator<Map> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Map>(this);
  }

  // From Collection<Map>:

  void add(Map value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(Map value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<Map> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(Map element) => _Collections.contains(this, element);

  void forEach(void f(Map element)) => _Collections.forEach(this, f);

  Collection map(f(Map element)) => _Collections.map(this, [], f);

  Collection<Map> filter(bool f(Map element)) =>
     _Collections.filter(this, <Map>[], f);

  bool every(bool f(Map element)) => _Collections.every(this, f);

  bool some(bool f(Map element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<Map>:

  void sort([Comparator<Map> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Map element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Map element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  Map get last => this[length - 1];

  Map removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<Map> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [Map initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<Map> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <Map>[]);

  // -- end List<Map> mixins.

  /** @domName SQLResultSetRowList.item */
  Map item(int index) {
    return _convertNativeToDart_Dictionary(_item_1(index));
  }
  _item_1(index) native "item";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void SQLStatementCallback(SQLTransaction transaction, SQLResultSet resultSet);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void SQLStatementErrorCallback(SQLTransaction transaction, SQLError error);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SQLTransaction
class SQLTransaction native "*SQLTransaction" {

  /** @domName SQLTransaction.executeSql */
  void executeSql(String sqlStatement, List arguments, [SQLStatementCallback callback, SQLStatementErrorCallback errorCallback]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void SQLTransactionCallback(SQLTransaction transaction);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void SQLTransactionErrorCallback(SQLError error);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SQLTransactionSync
class SQLTransactionSync native "*SQLTransactionSync" {

  /** @domName SQLTransactionSync.executeSql */
  SQLResultSet executeSql(String sqlStatement, List arguments) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void SQLTransactionSyncCallback(SQLTransactionSync transaction);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Screen
class Screen native "*Screen" {

  /** @domName Screen.availHeight */
  final int availHeight;

  /** @domName Screen.availLeft */
  final int availLeft;

  /** @domName Screen.availTop */
  final int availTop;

  /** @domName Screen.availWidth */
  final int availWidth;

  /** @domName Screen.colorDepth */
  final int colorDepth;

  /** @domName Screen.height */
  final int height;

  /** @domName Screen.pixelDepth */
  final int pixelDepth;

  /** @domName Screen.width */
  final int width;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLScriptElement
class ScriptElement extends Element implements Element native "*HTMLScriptElement" {

  factory ScriptElement() => _Elements.createScriptElement();

  /** @domName HTMLScriptElement.async */
  bool async;

  /** @domName HTMLScriptElement.charset */
  String charset;

  /** @domName HTMLScriptElement.crossOrigin */
  String crossOrigin;

  /** @domName HTMLScriptElement.defer */
  bool defer;

  /** @domName HTMLScriptElement.event */
  String event;

  /** @domName HTMLScriptElement.htmlFor */
  String htmlFor;

  /** @domName HTMLScriptElement.src */
  String src;

  /** @domName HTMLScriptElement.type */
  String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName ScriptProcessorNode
class ScriptProcessorNode extends AudioNode implements EventTarget native "*ScriptProcessorNode" {

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  ScriptProcessorNodeEvents get on =>
    new ScriptProcessorNodeEvents(this);

  /** @domName ScriptProcessorNode.bufferSize */
  final int bufferSize;
}

class ScriptProcessorNodeEvents extends Events {
  ScriptProcessorNodeEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get audioProcess => this['audioprocess'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName ScriptProfile
class ScriptProfile native "*ScriptProfile" {

  /** @domName ScriptProfile.head */
  final ScriptProfileNode head;

  /** @domName ScriptProfile.title */
  final String title;

  /** @domName ScriptProfile.uid */
  final int uid;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName ScriptProfileNode
class ScriptProfileNode native "*ScriptProfileNode" {

  /** @domName ScriptProfileNode.callUID */
  final int callUID;

  /** @domName ScriptProfileNode.functionName */
  final String functionName;

  /** @domName ScriptProfileNode.lineNumber */
  final int lineNumber;

  /** @domName ScriptProfileNode.numberOfCalls */
  final int numberOfCalls;

  /** @domName ScriptProfileNode.selfTime */
  final num selfTime;

  /** @domName ScriptProfileNode.totalTime */
  final num totalTime;

  /** @domName ScriptProfileNode.url */
  final String url;

  /** @domName ScriptProfileNode.visible */
  final bool visible;

  /** @domName ScriptProfileNode.children */
  List<ScriptProfileNode> children() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class SelectElement extends Element implements Element native "*HTMLSelectElement" {

  factory SelectElement() => _Elements.createSelectElement();

  /** @domName HTMLSelectElement.autofocus */
  bool autofocus;

  /** @domName HTMLSelectElement.disabled */
  bool disabled;

  /** @domName HTMLSelectElement.form */
  final FormElement form;

  /** @domName HTMLSelectElement.labels */
  final List<Node> labels;

  /** @domName HTMLSelectElement.length */
  int length;

  /** @domName HTMLSelectElement.multiple */
  bool multiple;

  /** @domName HTMLSelectElement.name */
  String name;

  /** @domName HTMLSelectElement.required */
  bool required;

  /** @domName HTMLSelectElement.selectedIndex */
  int selectedIndex;

  /** @domName HTMLSelectElement.size */
  int size;

  /** @domName HTMLSelectElement.type */
  final String type;

  /** @domName HTMLSelectElement.validationMessage */
  final String validationMessage;

  /** @domName HTMLSelectElement.validity */
  final ValidityState validity;

  /** @domName HTMLSelectElement.value */
  String value;

  /** @domName HTMLSelectElement.willValidate */
  final bool willValidate;

  /** @domName HTMLSelectElement.checkValidity */
  bool checkValidity() native;

  /** @domName HTMLSelectElement.item */
  Node item(int index) native;

  /** @domName HTMLSelectElement.namedItem */
  Node namedItem(String name) native;

  /** @domName HTMLSelectElement.setCustomValidity */
  void setCustomValidity(String error) native;


  // Override default options, since IE returns SelectElement itself and it
  // does not operate as a List.
  List<OptionElement> get options {
    return this.elements.filter((e) => e is OptionElement);
  }

  List<OptionElement> get selectedOptions {
    // IE does not change the selected flag for single-selection items.
    if (this.multiple) {
      return this.options.filter((o) => o.selected);
    } else {
      return [this.options[this.selectedIndex]];
    }
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SessionDescription
class SessionDescription native "*SessionDescription" {

  factory SessionDescription(String sdp) => _SessionDescriptionFactoryProvider.createSessionDescription(sdp);

  /** @domName SessionDescription.addCandidate */
  void addCandidate(IceCandidate candidate) native;

  /** @domName SessionDescription.toSdp */
  String toSdp() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLShadowElement
class ShadowElement extends Element implements Element native "*HTMLShadowElement" {

  /** @domName HTMLShadowElement.resetStyleInheritance */
  bool resetStyleInheritance;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


class ShadowRoot extends DocumentFragment native "*ShadowRoot" {

  factory ShadowRoot(Element host) => _ShadowRootFactoryProvider.createShadowRoot(host);

  /** @domName ShadowRoot.activeElement */
  final Element activeElement;

  /** @domName ShadowRoot.applyAuthorStyles */
  bool applyAuthorStyles;

  /** @domName ShadowRoot.innerHTML */
  String innerHTML;

  /** @domName ShadowRoot.resetStyleInheritance */
  bool resetStyleInheritance;

  /** @domName ShadowRoot.cloneNode */
  Node clone(bool deep) native "cloneNode";

  /** @domName ShadowRoot.getElementById */
  Element $dom_getElementById(String elementId) native "getElementById";

  /** @domName ShadowRoot.getElementsByClassName */
  List<Node> $dom_getElementsByClassName(String className) native "getElementsByClassName";

  /** @domName ShadowRoot.getElementsByTagName */
  List<Node> $dom_getElementsByTagName(String tagName) native "getElementsByTagName";

  /** @domName ShadowRoot.getSelection */
  DOMSelection getSelection() native;

  static bool get supported =>
      JS('bool', '!!(window.ShadowRoot || window.WebKitShadowRoot)');
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SharedWorker
class SharedWorker extends AbstractWorker native "*SharedWorker" {

  factory SharedWorker(String scriptURL, [String name]) {
    if (!?name) {
      return _SharedWorkerFactoryProvider.createSharedWorker(scriptURL);
    }
    return _SharedWorkerFactoryProvider.createSharedWorker(scriptURL, name);
  }

  /** @domName SharedWorker.port */
  final MessagePort port;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SharedWorkerContext
class SharedWorkerContext extends WorkerContext native "*SharedWorkerContext" {

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  SharedWorkerContextEvents get on =>
    new SharedWorkerContextEvents(this);

  /** @domName SharedWorkerContext.name */
  final String name;
}

class SharedWorkerContextEvents extends WorkerContextEvents {
  SharedWorkerContextEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get connect => this['connect'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SourceBuffer
class SourceBuffer native "*SourceBuffer" {

  /** @domName SourceBuffer.buffered */
  final TimeRanges buffered;

  /** @domName SourceBuffer.timestampOffset */
  num timestampOffset;

  /** @domName SourceBuffer.abort */
  void abort() native;

  /** @domName SourceBuffer.append */
  void append(Uint8Array data) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SourceBufferList
class SourceBufferList extends EventTarget implements JavaScriptIndexingBehavior, List<SourceBuffer> native "*SourceBufferList" {

  /** @domName SourceBufferList.length */
  final int length;

  SourceBuffer operator[](int index) => JS("SourceBuffer", "#[#]", this, index);

  void operator[]=(int index, SourceBuffer value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<SourceBuffer> mixins.
  // SourceBuffer is the element type.

  // From Iterable<SourceBuffer>:

  Iterator<SourceBuffer> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<SourceBuffer>(this);
  }

  // From Collection<SourceBuffer>:

  void add(SourceBuffer value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(SourceBuffer value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<SourceBuffer> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(SourceBuffer element) => _Collections.contains(this, element);

  void forEach(void f(SourceBuffer element)) => _Collections.forEach(this, f);

  Collection map(f(SourceBuffer element)) => _Collections.map(this, [], f);

  Collection<SourceBuffer> filter(bool f(SourceBuffer element)) =>
     _Collections.filter(this, <SourceBuffer>[], f);

  bool every(bool f(SourceBuffer element)) => _Collections.every(this, f);

  bool some(bool f(SourceBuffer element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<SourceBuffer>:

  void sort([Comparator<SourceBuffer> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(SourceBuffer element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(SourceBuffer element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  SourceBuffer get last => this[length - 1];

  SourceBuffer removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<SourceBuffer> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [SourceBuffer initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<SourceBuffer> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <SourceBuffer>[]);

  // -- end List<SourceBuffer> mixins.

  /** @domName SourceBufferList.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "addEventListener";

  /** @domName SourceBufferList.dispatchEvent */
  bool $dom_dispatchEvent(Event event) native "dispatchEvent";

  /** @domName SourceBufferList.item */
  SourceBuffer item(int index) native;

  /** @domName SourceBufferList.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "removeEventListener";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLSourceElement
class SourceElement extends Element implements Element native "*HTMLSourceElement" {

  factory SourceElement() => _Elements.createSourceElement();

  /** @domName HTMLSourceElement.media */
  String media;

  /** @domName HTMLSourceElement.src */
  String src;

  /** @domName HTMLSourceElement.type */
  String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLSpanElement
class SpanElement extends Element implements Element native "*HTMLSpanElement" {

  factory SpanElement() => _Elements.createSpanElement();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SpeechGrammar
class SpeechGrammar native "*SpeechGrammar" {

  factory SpeechGrammar() => _SpeechGrammarFactoryProvider.createSpeechGrammar();

  /** @domName SpeechGrammar.src */
  String src;

  /** @domName SpeechGrammar.weight */
  num weight;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SpeechGrammarList
class SpeechGrammarList implements JavaScriptIndexingBehavior, List<SpeechGrammar> native "*SpeechGrammarList" {

  factory SpeechGrammarList() => _SpeechGrammarListFactoryProvider.createSpeechGrammarList();

  /** @domName SpeechGrammarList.length */
  final int length;

  SpeechGrammar operator[](int index) => JS("SpeechGrammar", "#[#]", this, index);

  void operator[]=(int index, SpeechGrammar value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<SpeechGrammar> mixins.
  // SpeechGrammar is the element type.

  // From Iterable<SpeechGrammar>:

  Iterator<SpeechGrammar> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<SpeechGrammar>(this);
  }

  // From Collection<SpeechGrammar>:

  void add(SpeechGrammar value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(SpeechGrammar value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<SpeechGrammar> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(SpeechGrammar element) => _Collections.contains(this, element);

  void forEach(void f(SpeechGrammar element)) => _Collections.forEach(this, f);

  Collection map(f(SpeechGrammar element)) => _Collections.map(this, [], f);

  Collection<SpeechGrammar> filter(bool f(SpeechGrammar element)) =>
     _Collections.filter(this, <SpeechGrammar>[], f);

  bool every(bool f(SpeechGrammar element)) => _Collections.every(this, f);

  bool some(bool f(SpeechGrammar element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<SpeechGrammar>:

  void sort([Comparator<SpeechGrammar> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(SpeechGrammar element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(SpeechGrammar element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  SpeechGrammar get last => this[length - 1];

  SpeechGrammar removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<SpeechGrammar> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [SpeechGrammar initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<SpeechGrammar> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <SpeechGrammar>[]);

  // -- end List<SpeechGrammar> mixins.

  /** @domName SpeechGrammarList.addFromString */
  void addFromString(String string, [num weight]) native;

  /** @domName SpeechGrammarList.addFromUri */
  void addFromUri(String src, [num weight]) native;

  /** @domName SpeechGrammarList.item */
  SpeechGrammar item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SpeechInputEvent
class SpeechInputEvent extends Event native "*SpeechInputEvent" {

  /** @domName SpeechInputEvent.results */
  final List<SpeechInputResult> results;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SpeechInputResult
class SpeechInputResult native "*SpeechInputResult" {

  /** @domName SpeechInputResult.confidence */
  final num confidence;

  /** @domName SpeechInputResult.utterance */
  final String utterance;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SpeechRecognition
class SpeechRecognition extends EventTarget native "*SpeechRecognition" {

  factory SpeechRecognition() => _SpeechRecognitionFactoryProvider.createSpeechRecognition();

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  SpeechRecognitionEvents get on =>
    new SpeechRecognitionEvents(this);

  /** @domName SpeechRecognition.continuous */
  bool continuous;

  /** @domName SpeechRecognition.grammars */
  SpeechGrammarList grammars;

  /** @domName SpeechRecognition.interimResults */
  bool interimResults;

  /** @domName SpeechRecognition.lang */
  String lang;

  /** @domName SpeechRecognition.maxAlternatives */
  int maxAlternatives;

  /** @domName SpeechRecognition.abort */
  void abort() native;

  /** @domName SpeechRecognition.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "addEventListener";

  /** @domName SpeechRecognition.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "dispatchEvent";

  /** @domName SpeechRecognition.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "removeEventListener";

  /** @domName SpeechRecognition.start */
  void start() native;

  /** @domName SpeechRecognition.stop */
  void stop() native;
}

class SpeechRecognitionEvents extends Events {
  SpeechRecognitionEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get audioEnd => this['audioend'];

  EventListenerList get audioStart => this['audiostart'];

  EventListenerList get end => this['end'];

  EventListenerList get error => this['error'];

  EventListenerList get noMatch => this['nomatch'];

  EventListenerList get result => this['result'];

  EventListenerList get soundEnd => this['soundend'];

  EventListenerList get soundStart => this['soundstart'];

  EventListenerList get speechEnd => this['speechend'];

  EventListenerList get speechStart => this['speechstart'];

  EventListenerList get start => this['start'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SpeechRecognitionAlternative
class SpeechRecognitionAlternative native "*SpeechRecognitionAlternative" {

  /** @domName SpeechRecognitionAlternative.confidence */
  final num confidence;

  /** @domName SpeechRecognitionAlternative.transcript */
  final String transcript;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SpeechRecognitionError
class SpeechRecognitionError extends Event native "*SpeechRecognitionError" {

  static const int ABORTED = 2;

  static const int AUDIO_CAPTURE = 3;

  static const int BAD_GRAMMAR = 7;

  static const int LANGUAGE_NOT_SUPPORTED = 8;

  static const int NETWORK = 4;

  static const int NOT_ALLOWED = 5;

  static const int NO_SPEECH = 1;

  static const int OTHER = 0;

  static const int SERVICE_NOT_ALLOWED = 6;

  /** @domName SpeechRecognitionError.code */
  final int code;

  /** @domName SpeechRecognitionError.message */
  final String message;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SpeechRecognitionEvent
class SpeechRecognitionEvent extends Event native "*SpeechRecognitionEvent" {

  /** @domName SpeechRecognitionEvent.result */
  final SpeechRecognitionResult result;

  /** @domName SpeechRecognitionEvent.resultHistory */
  final List<SpeechRecognitionResult> resultHistory;

  /** @domName SpeechRecognitionEvent.resultIndex */
  final int resultIndex;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SpeechRecognitionResult
class SpeechRecognitionResult native "*SpeechRecognitionResult" {

  /** @domName SpeechRecognitionResult.emma */
  final Document emma;

  /** @domName SpeechRecognitionResult.finalValue */
  bool get finalValue => JS("bool", "#.final", this);

  /** @domName SpeechRecognitionResult.length */
  final int length;

  /** @domName SpeechRecognitionResult.item */
  SpeechRecognitionAlternative item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class Storage implements Map<String, String>  native "*Storage" {

  // TODO(nweiz): update this when maps support lazy iteration
  bool containsValue(String value) => values.some((e) => e == value);

  bool containsKey(String key) => $dom_getItem(key) != null;

  String operator [](String key) => $dom_getItem(key);

  void operator []=(String key, String value) => $dom_setItem(key, value);

  String putIfAbsent(String key, String ifAbsent()) {
    if (!containsKey(key)) this[key] = ifAbsent();
    return this[key];
  }

  String remove(String key) {
    final value = this[key];
    $dom_removeItem(key);
    return value;
  }

  void clear() => $dom_clear();

  void forEach(void f(String key, String value)) {
    for (var i = 0; true; i++) {
      final key = $dom_key(i);
      if (key == null) return;

      f(key, this[key]);
    }
  }

  Collection<String> get keys {
    final keys = [];
    forEach((k, v) => keys.add(k));
    return keys;
  }

  Collection<String> get values {
    final values = [];
    forEach((k, v) => values.add(v));
    return values;
  }

  int get length => $dom_length;

  bool get isEmpty => $dom_key(0) == null;

  /** @domName Storage.length */
  int get $dom_length => JS("int", "#.length", this);

  /** @domName Storage.clear */
  void $dom_clear() native "clear";

  /** @domName Storage.getItem */
  String $dom_getItem(String key) native "getItem";

  /** @domName Storage.key */
  String $dom_key(int index) native "key";

  /** @domName Storage.removeItem */
  void $dom_removeItem(String key) native "removeItem";

  /** @domName Storage.setItem */
  void $dom_setItem(String key, String data) native "setItem";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName StorageEvent
class StorageEvent extends Event native "*StorageEvent" {

  /** @domName StorageEvent.key */
  final String key;

  /** @domName StorageEvent.newValue */
  final String newValue;

  /** @domName StorageEvent.oldValue */
  final String oldValue;

  /** @domName StorageEvent.storageArea */
  final Storage storageArea;

  /** @domName StorageEvent.url */
  final String url;

  /** @domName StorageEvent.initStorageEvent */
  void initStorageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String keyArg, String oldValueArg, String newValueArg, String urlArg, Storage storageAreaArg) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName StorageInfo
class StorageInfo native "*StorageInfo" {

  static const int PERSISTENT = 1;

  static const int TEMPORARY = 0;

  /** @domName StorageInfo.queryUsageAndQuota */
  void queryUsageAndQuota(int storageType, [StorageInfoUsageCallback usageCallback, StorageInfoErrorCallback errorCallback]) native;

  /** @domName StorageInfo.requestQuota */
  void requestQuota(int storageType, int newQuotaInBytes, [StorageInfoQuotaCallback quotaCallback, StorageInfoErrorCallback errorCallback]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void StorageInfoErrorCallback(DOMException error);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void StorageInfoQuotaCallback(int grantedQuotaInBytes);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void StorageInfoUsageCallback(int currentUsageInBytes, int currentQuotaInBytes);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void StringCallback(String data);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLStyleElement
class StyleElement extends Element implements Element native "*HTMLStyleElement" {

  factory StyleElement() => _Elements.createStyleElement();

  /** @domName HTMLStyleElement.disabled */
  bool disabled;

  /** @domName HTMLStyleElement.media */
  String media;

  /** @domName HTMLStyleElement.scoped */
  bool scoped;

  /** @domName HTMLStyleElement.sheet */
  final StyleSheet sheet;

  /** @domName HTMLStyleElement.type */
  String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName StyleMedia
class StyleMedia native "*StyleMedia" {

  /** @domName StyleMedia.type */
  final String type;

  /** @domName StyleMedia.matchMedium */
  bool matchMedium(String mediaquery) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName StyleSheet
class StyleSheet native "*StyleSheet" {

  /** @domName StyleSheet.disabled */
  bool disabled;

  /** @domName StyleSheet.href */
  final String href;

  /** @domName StyleSheet.media */
  final MediaList media;

  /** @domName StyleSheet.ownerNode */
  final Node ownerNode;

  /** @domName StyleSheet.parentStyleSheet */
  final StyleSheet parentStyleSheet;

  /** @domName StyleSheet.title */
  final String title;

  /** @domName StyleSheet.type */
  final String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLTableCaptionElement
class TableCaptionElement extends Element implements Element native "*HTMLTableCaptionElement" {

  factory TableCaptionElement() => _Elements.createTableCaptionElement();

  /** @domName HTMLTableCaptionElement.align */
  String align;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLTableCellElement
class TableCellElement extends Element implements Element native "*HTMLTableCellElement" {

  factory TableCellElement() => _Elements.createTableCellElement();

  /** @domName HTMLTableCellElement.abbr */
  String abbr;

  /** @domName HTMLTableCellElement.align */
  String align;

  /** @domName HTMLTableCellElement.axis */
  String axis;

  /** @domName HTMLTableCellElement.bgColor */
  String bgColor;

  /** @domName HTMLTableCellElement.cellIndex */
  final int cellIndex;

  /** @domName HTMLTableCellElement.ch */
  String ch;

  /** @domName HTMLTableCellElement.chOff */
  String chOff;

  /** @domName HTMLTableCellElement.colSpan */
  int colSpan;

  /** @domName HTMLTableCellElement.headers */
  String headers;

  /** @domName HTMLTableCellElement.height */
  String height;

  /** @domName HTMLTableCellElement.noWrap */
  bool noWrap;

  /** @domName HTMLTableCellElement.rowSpan */
  int rowSpan;

  /** @domName HTMLTableCellElement.scope */
  String scope;

  /** @domName HTMLTableCellElement.vAlign */
  String vAlign;

  /** @domName HTMLTableCellElement.width */
  String width;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLTableColElement
class TableColElement extends Element implements Element native "*HTMLTableColElement" {

  factory TableColElement() => _Elements.createTableColElement();

  /** @domName HTMLTableColElement.align */
  String align;

  /** @domName HTMLTableColElement.ch */
  String ch;

  /** @domName HTMLTableColElement.chOff */
  String chOff;

  /** @domName HTMLTableColElement.span */
  int span;

  /** @domName HTMLTableColElement.vAlign */
  String vAlign;

  /** @domName HTMLTableColElement.width */
  String width;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class TableElement extends Element implements Element native "*HTMLTableElement" {

  factory TableElement() => _Elements.createTableElement();

  /** @domName HTMLTableElement.align */
  String align;

  /** @domName HTMLTableElement.bgColor */
  String bgColor;

  /** @domName HTMLTableElement.border */
  String border;

  /** @domName HTMLTableElement.caption */
  TableCaptionElement caption;

  /** @domName HTMLTableElement.cellPadding */
  String cellPadding;

  /** @domName HTMLTableElement.cellSpacing */
  String cellSpacing;

  /** @domName HTMLTableElement.frame */
  String frame;

  /** @domName HTMLTableElement.rows */
  final HTMLCollection rows;

  /** @domName HTMLTableElement.rules */
  String rules;

  /** @domName HTMLTableElement.summary */
  String summary;

  /** @domName HTMLTableElement.tBodies */
  final HTMLCollection tBodies;

  /** @domName HTMLTableElement.tFoot */
  TableSectionElement tFoot;

  /** @domName HTMLTableElement.tHead */
  TableSectionElement tHead;

  /** @domName HTMLTableElement.width */
  String width;

  /** @domName HTMLTableElement.createCaption */
  Element createCaption() native;

  /** @domName HTMLTableElement.createTFoot */
  Element createTFoot() native;

  /** @domName HTMLTableElement.createTHead */
  Element createTHead() native;

  /** @domName HTMLTableElement.deleteCaption */
  void deleteCaption() native;

  /** @domName HTMLTableElement.deleteRow */
  void deleteRow(int index) native;

  /** @domName HTMLTableElement.deleteTFoot */
  void deleteTFoot() native;

  /** @domName HTMLTableElement.deleteTHead */
  void deleteTHead() native;

  /** @domName HTMLTableElement.insertRow */
  Element insertRow(int index) native;


  Element createTBody() {
    if (JS('bool', '!!#.createTBody', this)) {
      return this._createTBody();
    }
    var tbody = new Element.tag('tbody');
    this.elements.add(tbody);
    return tbody;
  }

  Element _createTBody() native 'createTBody';
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLTableRowElement
class TableRowElement extends Element implements Element native "*HTMLTableRowElement" {

  factory TableRowElement() => _Elements.createTableRowElement();

  /** @domName HTMLTableRowElement.align */
  String align;

  /** @domName HTMLTableRowElement.bgColor */
  String bgColor;

  /** @domName HTMLTableRowElement.cells */
  final HTMLCollection cells;

  /** @domName HTMLTableRowElement.ch */
  String ch;

  /** @domName HTMLTableRowElement.chOff */
  String chOff;

  /** @domName HTMLTableRowElement.rowIndex */
  final int rowIndex;

  /** @domName HTMLTableRowElement.sectionRowIndex */
  final int sectionRowIndex;

  /** @domName HTMLTableRowElement.vAlign */
  String vAlign;

  /** @domName HTMLTableRowElement.deleteCell */
  void deleteCell(int index) native;

  /** @domName HTMLTableRowElement.insertCell */
  Element insertCell(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLTableSectionElement
class TableSectionElement extends Element implements Element native "*HTMLTableSectionElement" {

  /** @domName HTMLTableSectionElement.align */
  String align;

  /** @domName HTMLTableSectionElement.ch */
  String ch;

  /** @domName HTMLTableSectionElement.chOff */
  String chOff;

  /** @domName HTMLTableSectionElement.rows */
  final HTMLCollection rows;

  /** @domName HTMLTableSectionElement.vAlign */
  String vAlign;

  /** @domName HTMLTableSectionElement.deleteRow */
  void deleteRow(int index) native;

  /** @domName HTMLTableSectionElement.insertRow */
  Element insertRow(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


class Text extends CharacterData native "*Text" {
  factory Text(String data) => _TextFactoryProvider.createText(data);

  /** @domName Text.wholeText */
  final String wholeText;

  /** @domName Text.replaceWholeText */
  Text replaceWholeText(String content) native;

  /** @domName Text.splitText */
  Text splitText(int offset) native;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLTextAreaElement
class TextAreaElement extends Element implements Element native "*HTMLTextAreaElement" {

  factory TextAreaElement() => _Elements.createTextAreaElement();

  /** @domName HTMLTextAreaElement.autofocus */
  bool autofocus;

  /** @domName HTMLTextAreaElement.cols */
  int cols;

  /** @domName HTMLTextAreaElement.defaultValue */
  String defaultValue;

  /** @domName HTMLTextAreaElement.dirName */
  String dirName;

  /** @domName HTMLTextAreaElement.disabled */
  bool disabled;

  /** @domName HTMLTextAreaElement.form */
  final FormElement form;

  /** @domName HTMLTextAreaElement.labels */
  final List<Node> labels;

  /** @domName HTMLTextAreaElement.maxLength */
  int maxLength;

  /** @domName HTMLTextAreaElement.name */
  String name;

  /** @domName HTMLTextAreaElement.placeholder */
  String placeholder;

  /** @domName HTMLTextAreaElement.readOnly */
  bool readOnly;

  /** @domName HTMLTextAreaElement.required */
  bool required;

  /** @domName HTMLTextAreaElement.rows */
  int rows;

  /** @domName HTMLTextAreaElement.selectionDirection */
  String selectionDirection;

  /** @domName HTMLTextAreaElement.selectionEnd */
  int selectionEnd;

  /** @domName HTMLTextAreaElement.selectionStart */
  int selectionStart;

  /** @domName HTMLTextAreaElement.textLength */
  final int textLength;

  /** @domName HTMLTextAreaElement.type */
  final String type;

  /** @domName HTMLTextAreaElement.validationMessage */
  final String validationMessage;

  /** @domName HTMLTextAreaElement.validity */
  final ValidityState validity;

  /** @domName HTMLTextAreaElement.value */
  String value;

  /** @domName HTMLTextAreaElement.willValidate */
  final bool willValidate;

  /** @domName HTMLTextAreaElement.wrap */
  String wrap;

  /** @domName HTMLTextAreaElement.checkValidity */
  bool checkValidity() native;

  /** @domName HTMLTextAreaElement.select */
  void select() native;

  /** @domName HTMLTextAreaElement.setCustomValidity */
  void setCustomValidity(String error) native;

  /** @domName HTMLTextAreaElement.setRangeText */
  void setRangeText(String replacement, [int start, int end, String selectionMode]) native;

  /** @domName HTMLTextAreaElement.setSelectionRange */
  void setSelectionRange(int start, int end, [String direction]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName TextEvent
class TextEvent extends UIEvent native "*TextEvent" {

  /** @domName TextEvent.data */
  final String data;

  /** @domName TextEvent.initTextEvent */
  void initTextEvent(String typeArg, bool canBubbleArg, bool cancelableArg, LocalWindow viewArg, String dataArg) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName TextMetrics
class TextMetrics native "*TextMetrics" {

  /** @domName TextMetrics.width */
  final num width;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName TextTrack
class TextTrack extends EventTarget native "*TextTrack" {

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  TextTrackEvents get on =>
    new TextTrackEvents(this);

  /** @domName TextTrack.activeCues */
  final TextTrackCueList activeCues;

  /** @domName TextTrack.cues */
  final TextTrackCueList cues;

  /** @domName TextTrack.kind */
  final String kind;

  /** @domName TextTrack.label */
  final String label;

  /** @domName TextTrack.language */
  final String language;

  /** @domName TextTrack.mode */
  String mode;

  /** @domName TextTrack.addCue */
  void addCue(TextTrackCue cue) native;

  /** @domName TextTrack.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "addEventListener";

  /** @domName TextTrack.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "dispatchEvent";

  /** @domName TextTrack.removeCue */
  void removeCue(TextTrackCue cue) native;

  /** @domName TextTrack.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "removeEventListener";
}

class TextTrackEvents extends Events {
  TextTrackEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get cueChange => this['cuechange'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName TextTrackCue
class TextTrackCue extends EventTarget native "*TextTrackCue" {

  factory TextTrackCue(num startTime, num endTime, String text) => _TextTrackCueFactoryProvider.createTextTrackCue(startTime, endTime, text);

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  TextTrackCueEvents get on =>
    new TextTrackCueEvents(this);

  /** @domName TextTrackCue.align */
  String align;

  /** @domName TextTrackCue.endTime */
  num endTime;

  /** @domName TextTrackCue.id */
  String id;

  /** @domName TextTrackCue.line */
  int line;

  /** @domName TextTrackCue.pauseOnExit */
  bool pauseOnExit;

  /** @domName TextTrackCue.position */
  int position;

  /** @domName TextTrackCue.size */
  int size;

  /** @domName TextTrackCue.snapToLines */
  bool snapToLines;

  /** @domName TextTrackCue.startTime */
  num startTime;

  /** @domName TextTrackCue.text */
  String text;

  /** @domName TextTrackCue.track */
  final TextTrack track;

  /** @domName TextTrackCue.vertical */
  String vertical;

  /** @domName TextTrackCue.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "addEventListener";

  /** @domName TextTrackCue.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "dispatchEvent";

  /** @domName TextTrackCue.getCueAsHTML */
  DocumentFragment getCueAsHTML() native;

  /** @domName TextTrackCue.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "removeEventListener";
}

class TextTrackCueEvents extends Events {
  TextTrackCueEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get enter => this['enter'];

  EventListenerList get exit => this['exit'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName TextTrackCueList
class TextTrackCueList implements List<TextTrackCue>, JavaScriptIndexingBehavior native "*TextTrackCueList" {

  /** @domName TextTrackCueList.length */
  final int length;

  TextTrackCue operator[](int index) => JS("TextTrackCue", "#[#]", this, index);

  void operator[]=(int index, TextTrackCue value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<TextTrackCue> mixins.
  // TextTrackCue is the element type.

  // From Iterable<TextTrackCue>:

  Iterator<TextTrackCue> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<TextTrackCue>(this);
  }

  // From Collection<TextTrackCue>:

  void add(TextTrackCue value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(TextTrackCue value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<TextTrackCue> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(TextTrackCue element) => _Collections.contains(this, element);

  void forEach(void f(TextTrackCue element)) => _Collections.forEach(this, f);

  Collection map(f(TextTrackCue element)) => _Collections.map(this, [], f);

  Collection<TextTrackCue> filter(bool f(TextTrackCue element)) =>
     _Collections.filter(this, <TextTrackCue>[], f);

  bool every(bool f(TextTrackCue element)) => _Collections.every(this, f);

  bool some(bool f(TextTrackCue element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<TextTrackCue>:

  void sort([Comparator<TextTrackCue> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(TextTrackCue element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(TextTrackCue element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  TextTrackCue get last => this[length - 1];

  TextTrackCue removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<TextTrackCue> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [TextTrackCue initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<TextTrackCue> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <TextTrackCue>[]);

  // -- end List<TextTrackCue> mixins.

  /** @domName TextTrackCueList.getCueById */
  TextTrackCue getCueById(String id) native;

  /** @domName TextTrackCueList.item */
  TextTrackCue item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName TextTrackList
class TextTrackList extends EventTarget implements JavaScriptIndexingBehavior, List<TextTrack> native "*TextTrackList" {

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  TextTrackListEvents get on =>
    new TextTrackListEvents(this);

  /** @domName TextTrackList.length */
  final int length;

  TextTrack operator[](int index) => JS("TextTrack", "#[#]", this, index);

  void operator[]=(int index, TextTrack value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<TextTrack> mixins.
  // TextTrack is the element type.

  // From Iterable<TextTrack>:

  Iterator<TextTrack> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<TextTrack>(this);
  }

  // From Collection<TextTrack>:

  void add(TextTrack value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(TextTrack value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<TextTrack> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(TextTrack element) => _Collections.contains(this, element);

  void forEach(void f(TextTrack element)) => _Collections.forEach(this, f);

  Collection map(f(TextTrack element)) => _Collections.map(this, [], f);

  Collection<TextTrack> filter(bool f(TextTrack element)) =>
     _Collections.filter(this, <TextTrack>[], f);

  bool every(bool f(TextTrack element)) => _Collections.every(this, f);

  bool some(bool f(TextTrack element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<TextTrack>:

  void sort([Comparator<TextTrack> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(TextTrack element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(TextTrack element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  TextTrack get last => this[length - 1];

  TextTrack removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<TextTrack> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [TextTrack initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<TextTrack> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <TextTrack>[]);

  // -- end List<TextTrack> mixins.

  /** @domName TextTrackList.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "addEventListener";

  /** @domName TextTrackList.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "dispatchEvent";

  /** @domName TextTrackList.item */
  TextTrack item(int index) native;

  /** @domName TextTrackList.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "removeEventListener";
}

class TextTrackListEvents extends Events {
  TextTrackListEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get addTrack => this['addtrack'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName TimeRanges
class TimeRanges native "*TimeRanges" {

  /** @domName TimeRanges.length */
  final int length;

  /** @domName TimeRanges.end */
  num end(int index) native;

  /** @domName TimeRanges.start */
  num start(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void TimeoutHandler();
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLTitleElement
class TitleElement extends Element implements Element native "*HTMLTitleElement" {

  factory TitleElement() => _Elements.createTitleElement();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Touch
class Touch native "*Touch" {

  /** @domName Touch.clientX */
  final int clientX;

  /** @domName Touch.clientY */
  final int clientY;

  /** @domName Touch.identifier */
  final int identifier;

  /** @domName Touch.pageX */
  final int pageX;

  /** @domName Touch.pageY */
  final int pageY;

  /** @domName Touch.screenX */
  final int screenX;

  /** @domName Touch.screenY */
  final int screenY;

  /** @domName Touch.target */
  EventTarget get target => _convertNativeToDart_EventTarget(this._target);
  dynamic get _target => JS("dynamic", "#.target", this);

  /** @domName Touch.webkitForce */
  final num webkitForce;

  /** @domName Touch.webkitRadiusX */
  final int webkitRadiusX;

  /** @domName Touch.webkitRadiusY */
  final int webkitRadiusY;

  /** @domName Touch.webkitRotationAngle */
  final num webkitRotationAngle;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName TouchEvent
class TouchEvent extends UIEvent native "*TouchEvent" {

  /** @domName TouchEvent.altKey */
  final bool altKey;

  /** @domName TouchEvent.changedTouches */
  final TouchList changedTouches;

  /** @domName TouchEvent.ctrlKey */
  final bool ctrlKey;

  /** @domName TouchEvent.metaKey */
  final bool metaKey;

  /** @domName TouchEvent.shiftKey */
  final bool shiftKey;

  /** @domName TouchEvent.targetTouches */
  final TouchList targetTouches;

  /** @domName TouchEvent.touches */
  final TouchList touches;

  /** @domName TouchEvent.initTouchEvent */
  void initTouchEvent(TouchList touches, TouchList targetTouches, TouchList changedTouches, String type, LocalWindow view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName TouchList
class TouchList implements JavaScriptIndexingBehavior, List<Touch> native "*TouchList" {

  /** @domName TouchList.length */
  final int length;

  Touch operator[](int index) => JS("Touch", "#[#]", this, index);

  void operator[]=(int index, Touch value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Touch> mixins.
  // Touch is the element type.

  // From Iterable<Touch>:

  Iterator<Touch> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Touch>(this);
  }

  // From Collection<Touch>:

  void add(Touch value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(Touch value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<Touch> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(Touch element) => _Collections.contains(this, element);

  void forEach(void f(Touch element)) => _Collections.forEach(this, f);

  Collection map(f(Touch element)) => _Collections.map(this, [], f);

  Collection<Touch> filter(bool f(Touch element)) =>
     _Collections.filter(this, <Touch>[], f);

  bool every(bool f(Touch element)) => _Collections.every(this, f);

  bool some(bool f(Touch element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<Touch>:

  void sort([Comparator<Touch> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Touch element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Touch element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  Touch get last => this[length - 1];

  Touch removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<Touch> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [Touch initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<Touch> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <Touch>[]);

  // -- end List<Touch> mixins.

  /** @domName TouchList.item */
  Touch item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLTrackElement
class TrackElement extends Element implements Element native "*HTMLTrackElement" {

  factory TrackElement() => _Elements.createTrackElement();

  static const int ERROR = 3;

  static const int LOADED = 2;

  static const int LOADING = 1;

  static const int NONE = 0;

  /** @domName HTMLTrackElement.defaultValue */
  bool get defaultValue => JS("bool", "#.default", this);

  /** @domName HTMLTrackElement.defaultValue */
  void set defaultValue(bool value) {
    JS("void", "#.default = #", this, value);
  }

  /** @domName HTMLTrackElement.kind */
  String kind;

  /** @domName HTMLTrackElement.label */
  String label;

  /** @domName HTMLTrackElement.readyState */
  final int readyState;

  /** @domName HTMLTrackElement.src */
  String src;

  /** @domName HTMLTrackElement.srclang */
  String srclang;

  /** @domName HTMLTrackElement.track */
  final TextTrack track;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName TrackEvent
class TrackEvent extends Event native "*TrackEvent" {

  /** @domName TrackEvent.track */
  final Object track;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WebKitTransitionEvent
class TransitionEvent extends Event native "*WebKitTransitionEvent" {

  /** @domName WebKitTransitionEvent.elapsedTime */
  final num elapsedTime;

  /** @domName WebKitTransitionEvent.propertyName */
  final String propertyName;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName TreeWalker
class TreeWalker native "*TreeWalker" {

  /** @domName TreeWalker.currentNode */
  Node currentNode;

  /** @domName TreeWalker.expandEntityReferences */
  final bool expandEntityReferences;

  /** @domName TreeWalker.filter */
  final NodeFilter filter;

  /** @domName TreeWalker.root */
  final Node root;

  /** @domName TreeWalker.whatToShow */
  final int whatToShow;

  /** @domName TreeWalker.firstChild */
  Node firstChild() native;

  /** @domName TreeWalker.lastChild */
  Node lastChild() native;

  /** @domName TreeWalker.nextNode */
  Node nextNode() native;

  /** @domName TreeWalker.nextSibling */
  Node nextSibling() native;

  /** @domName TreeWalker.parentNode */
  Node parentNode() native;

  /** @domName TreeWalker.previousNode */
  Node previousNode() native;

  /** @domName TreeWalker.previousSibling */
  Node previousSibling() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName UIEvent
class UIEvent extends Event native "*UIEvent" {

  /** @domName UIEvent.charCode */
  final int charCode;

  /** @domName UIEvent.detail */
  final int detail;

  /** @domName UIEvent.keyCode */
  final int keyCode;

  /** @domName UIEvent.layerX */
  final int layerX;

  /** @domName UIEvent.layerY */
  final int layerY;

  /** @domName UIEvent.pageX */
  final int pageX;

  /** @domName UIEvent.pageY */
  final int pageY;

  /** @domName UIEvent.view */
  Window get view => _convertNativeToDart_Window(this._view);
  dynamic get _view => JS("dynamic", "#.view", this);

  /** @domName UIEvent.which */
  final int which;

  /** @domName UIEvent.initUIEvent */
  void initUIEvent(String type, bool canBubble, bool cancelable, LocalWindow view, int detail) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLUListElement
class UListElement extends Element implements Element native "*HTMLUListElement" {

  factory UListElement() => _Elements.createUListElement();

  /** @domName HTMLUListElement.compact */
  bool compact;

  /** @domName HTMLUListElement.type */
  String type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Uint16Array
class Uint16Array extends ArrayBufferView implements JavaScriptIndexingBehavior, List<int> native "*Uint16Array" {

  factory Uint16Array(int length) =>
    _TypedArrayFactoryProvider.createUint16Array(length);

  factory Uint16Array.fromList(List<int> list) =>
    _TypedArrayFactoryProvider.createUint16Array_fromList(list);

  factory Uint16Array.fromBuffer(ArrayBuffer buffer, [int byteOffset, int length]) => 
    _TypedArrayFactoryProvider.createUint16Array_fromBuffer(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 2;

  /** @domName Uint16Array.length */
  final int length;

  int operator[](int index) => JS("int", "#[#]", this, index);

  void operator[]=(int index, int value) => JS("void", "#[#] = #", this, index, value);
  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<int>(this);
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<int> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(int element) => _Collections.contains(this, element);

  void forEach(void f(int element)) => _Collections.forEach(this, f);

  Collection map(f(int element)) => _Collections.map(this, [], f);

  Collection<int> filter(bool f(int element)) =>
     _Collections.filter(this, <int>[], f);

  bool every(bool f(int element)) => _Collections.every(this, f);

  bool some(bool f(int element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<int>:

  void sort([Comparator<int> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int get last => this[length - 1];

  int removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<int> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [int initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<int> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <int>[]);

  // -- end List<int> mixins.

  /** @domName Uint16Array.setElements */
  void setElements(Object array, [int offset]) native "set";

  /** @domName Uint16Array.subarray */
  Uint16Array subarray(int start, [int end]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Uint32Array
class Uint32Array extends ArrayBufferView implements JavaScriptIndexingBehavior, List<int> native "*Uint32Array" {

  factory Uint32Array(int length) =>
    _TypedArrayFactoryProvider.createUint32Array(length);

  factory Uint32Array.fromList(List<int> list) =>
    _TypedArrayFactoryProvider.createUint32Array_fromList(list);

  factory Uint32Array.fromBuffer(ArrayBuffer buffer, [int byteOffset, int length]) => 
    _TypedArrayFactoryProvider.createUint32Array_fromBuffer(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 4;

  /** @domName Uint32Array.length */
  final int length;

  int operator[](int index) => JS("int", "#[#]", this, index);

  void operator[]=(int index, int value) => JS("void", "#[#] = #", this, index, value);
  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<int>(this);
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<int> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(int element) => _Collections.contains(this, element);

  void forEach(void f(int element)) => _Collections.forEach(this, f);

  Collection map(f(int element)) => _Collections.map(this, [], f);

  Collection<int> filter(bool f(int element)) =>
     _Collections.filter(this, <int>[], f);

  bool every(bool f(int element)) => _Collections.every(this, f);

  bool some(bool f(int element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<int>:

  void sort([Comparator<int> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int get last => this[length - 1];

  int removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<int> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [int initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<int> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <int>[]);

  // -- end List<int> mixins.

  /** @domName Uint32Array.setElements */
  void setElements(Object array, [int offset]) native "set";

  /** @domName Uint32Array.subarray */
  Uint32Array subarray(int start, [int end]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Uint8Array
class Uint8Array extends ArrayBufferView implements JavaScriptIndexingBehavior, List<int> native "*Uint8Array" {

  factory Uint8Array(int length) =>
    _TypedArrayFactoryProvider.createUint8Array(length);

  factory Uint8Array.fromList(List<int> list) =>
    _TypedArrayFactoryProvider.createUint8Array_fromList(list);

  factory Uint8Array.fromBuffer(ArrayBuffer buffer, [int byteOffset, int length]) => 
    _TypedArrayFactoryProvider.createUint8Array_fromBuffer(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 1;

  /** @domName Uint8Array.length */
  final int length;

  int operator[](int index) => JS("int", "#[#]", this, index);

  void operator[]=(int index, int value) => JS("void", "#[#] = #", this, index, value);
  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<int>(this);
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<int> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(int element) => _Collections.contains(this, element);

  void forEach(void f(int element)) => _Collections.forEach(this, f);

  Collection map(f(int element)) => _Collections.map(this, [], f);

  Collection<int> filter(bool f(int element)) =>
     _Collections.filter(this, <int>[], f);

  bool every(bool f(int element)) => _Collections.every(this, f);

  bool some(bool f(int element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<int>:

  void sort([Comparator<int> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int get last => this[length - 1];

  int removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<int> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [int initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<int> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <int>[]);

  // -- end List<int> mixins.

  /** @domName Uint8Array.setElements */
  void setElements(Object array, [int offset]) native "set";

  /** @domName Uint8Array.subarray */
  Uint8Array subarray(int start, [int end]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Uint8ClampedArray
class Uint8ClampedArray extends Uint8Array native "*Uint8ClampedArray" {

  factory Uint8ClampedArray(int length) =>
    _TypedArrayFactoryProvider.createUint8ClampedArray(length);

  factory Uint8ClampedArray.fromList(List<int> list) =>
    _TypedArrayFactoryProvider.createUint8ClampedArray_fromList(list);

  factory Uint8ClampedArray.fromBuffer(ArrayBuffer buffer, [int byteOffset, int length]) => 
    _TypedArrayFactoryProvider.createUint8ClampedArray_fromBuffer(buffer, byteOffset, length);

  // Use implementation from Uint8Array.
  // final int length;

  /** @domName Uint8ClampedArray.setElements */
  void setElements(Object array, [int offset]) native "set";

  /** @domName Uint8ClampedArray.subarray */
  Uint8ClampedArray subarray(int start, [int end]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLUnknownElement
class UnknownElement extends Element implements Element native "*HTMLUnknownElement" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class Url native "*URL" {

  static String createObjectUrl(blob_OR_source_OR_stream) =>
      JS('String',
         '(window.URL || window.webkitURL).createObjectURL(#)',
         blob_OR_source_OR_stream);

  static void revokeObjectUrl(String objectUrl) =>
      JS('void',
         '(window.URL || window.webkitURL).revokeObjectURL(#)', objectUrl);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName ValidityState
class ValidityState native "*ValidityState" {

  /** @domName ValidityState.customError */
  final bool customError;

  /** @domName ValidityState.patternMismatch */
  final bool patternMismatch;

  /** @domName ValidityState.rangeOverflow */
  final bool rangeOverflow;

  /** @domName ValidityState.rangeUnderflow */
  final bool rangeUnderflow;

  /** @domName ValidityState.stepMismatch */
  final bool stepMismatch;

  /** @domName ValidityState.tooLong */
  final bool tooLong;

  /** @domName ValidityState.typeMismatch */
  final bool typeMismatch;

  /** @domName ValidityState.valid */
  final bool valid;

  /** @domName ValidityState.valueMissing */
  final bool valueMissing;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName HTMLVideoElement
class VideoElement extends MediaElement native "*HTMLVideoElement" {

  factory VideoElement() => _Elements.createVideoElement();

  /** @domName HTMLVideoElement.height */
  int height;

  /** @domName HTMLVideoElement.poster */
  String poster;

  /** @domName HTMLVideoElement.videoHeight */
  final int videoHeight;

  /** @domName HTMLVideoElement.videoWidth */
  final int videoWidth;

  /** @domName HTMLVideoElement.webkitDecodedFrameCount */
  final int webkitDecodedFrameCount;

  /** @domName HTMLVideoElement.webkitDisplayingFullscreen */
  final bool webkitDisplayingFullscreen;

  /** @domName HTMLVideoElement.webkitDroppedFrameCount */
  final int webkitDroppedFrameCount;

  /** @domName HTMLVideoElement.webkitSupportsFullscreen */
  final bool webkitSupportsFullscreen;

  /** @domName HTMLVideoElement.width */
  int width;

  /** @domName HTMLVideoElement.webkitEnterFullScreen */
  void webkitEnterFullScreen() native;

  /** @domName HTMLVideoElement.webkitEnterFullscreen */
  void webkitEnterFullscreen() native;

  /** @domName HTMLVideoElement.webkitExitFullScreen */
  void webkitExitFullScreen() native;

  /** @domName HTMLVideoElement.webkitExitFullscreen */
  void webkitExitFullscreen() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void VoidCallback();
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WaveShaperNode
class WaveShaperNode extends AudioNode native "*WaveShaperNode" {

  /** @domName WaveShaperNode.curve */
  Float32Array curve;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WaveTable
class WaveTable native "*WaveTable" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WebGLActiveInfo
class WebGLActiveInfo native "*WebGLActiveInfo" {

  /** @domName WebGLActiveInfo.name */
  final String name;

  /** @domName WebGLActiveInfo.size */
  final int size;

  /** @domName WebGLActiveInfo.type */
  final int type;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WebGLBuffer
class WebGLBuffer native "*WebGLBuffer" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WebGLCompressedTextureS3TC
class WebGLCompressedTextureS3TC native "*WebGLCompressedTextureS3TC" {

  static const int COMPRESSED_RGBA_S3TC_DXT1_EXT = 0x83F1;

  static const int COMPRESSED_RGBA_S3TC_DXT3_EXT = 0x83F2;

  static const int COMPRESSED_RGBA_S3TC_DXT5_EXT = 0x83F3;

  static const int COMPRESSED_RGB_S3TC_DXT1_EXT = 0x83F0;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WebGLContextAttributes
class WebGLContextAttributes native "*WebGLContextAttributes" {

  /** @domName WebGLContextAttributes.alpha */
  bool alpha;

  /** @domName WebGLContextAttributes.antialias */
  bool antialias;

  /** @domName WebGLContextAttributes.depth */
  bool depth;

  /** @domName WebGLContextAttributes.premultipliedAlpha */
  bool premultipliedAlpha;

  /** @domName WebGLContextAttributes.preserveDrawingBuffer */
  bool preserveDrawingBuffer;

  /** @domName WebGLContextAttributes.stencil */
  bool stencil;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WebGLContextEvent
class WebGLContextEvent extends Event native "*WebGLContextEvent" {

  /** @domName WebGLContextEvent.statusMessage */
  final String statusMessage;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WebGLDebugRendererInfo
class WebGLDebugRendererInfo native "*WebGLDebugRendererInfo" {

  static const int UNMASKED_RENDERER_WEBGL = 0x9246;

  static const int UNMASKED_VENDOR_WEBGL = 0x9245;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WebGLDebugShaders
class WebGLDebugShaders native "*WebGLDebugShaders" {

  /** @domName WebGLDebugShaders.getTranslatedShaderSource */
  String getTranslatedShaderSource(WebGLShader shader) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WebGLDepthTexture
class WebGLDepthTexture native "*WebGLDepthTexture" {

  static const int UNSIGNED_INT_24_8_WEBGL = 0x84FA;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WebGLFramebuffer
class WebGLFramebuffer native "*WebGLFramebuffer" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WebGLLoseContext
class WebGLLoseContext native "*WebGLLoseContext" {

  /** @domName WebGLLoseContext.loseContext */
  void loseContext() native;

  /** @domName WebGLLoseContext.restoreContext */
  void restoreContext() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WebGLProgram
class WebGLProgram native "*WebGLProgram" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WebGLRenderbuffer
class WebGLRenderbuffer native "*WebGLRenderbuffer" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WebGLRenderingContext
class WebGLRenderingContext extends CanvasRenderingContext native "*WebGLRenderingContext" {

  static const int ACTIVE_ATTRIBUTES = 0x8B89;

  static const int ACTIVE_TEXTURE = 0x84E0;

  static const int ACTIVE_UNIFORMS = 0x8B86;

  static const int ALIASED_LINE_WIDTH_RANGE = 0x846E;

  static const int ALIASED_POINT_SIZE_RANGE = 0x846D;

  static const int ALPHA = 0x1906;

  static const int ALPHA_BITS = 0x0D55;

  static const int ALWAYS = 0x0207;

  static const int ARRAY_BUFFER = 0x8892;

  static const int ARRAY_BUFFER_BINDING = 0x8894;

  static const int ATTACHED_SHADERS = 0x8B85;

  static const int BACK = 0x0405;

  static const int BLEND = 0x0BE2;

  static const int BLEND_COLOR = 0x8005;

  static const int BLEND_DST_ALPHA = 0x80CA;

  static const int BLEND_DST_RGB = 0x80C8;

  static const int BLEND_EQUATION = 0x8009;

  static const int BLEND_EQUATION_ALPHA = 0x883D;

  static const int BLEND_EQUATION_RGB = 0x8009;

  static const int BLEND_SRC_ALPHA = 0x80CB;

  static const int BLEND_SRC_RGB = 0x80C9;

  static const int BLUE_BITS = 0x0D54;

  static const int BOOL = 0x8B56;

  static const int BOOL_VEC2 = 0x8B57;

  static const int BOOL_VEC3 = 0x8B58;

  static const int BOOL_VEC4 = 0x8B59;

  static const int BROWSER_DEFAULT_WEBGL = 0x9244;

  static const int BUFFER_SIZE = 0x8764;

  static const int BUFFER_USAGE = 0x8765;

  static const int BYTE = 0x1400;

  static const int CCW = 0x0901;

  static const int CLAMP_TO_EDGE = 0x812F;

  static const int COLOR_ATTACHMENT0 = 0x8CE0;

  static const int COLOR_BUFFER_BIT = 0x00004000;

  static const int COLOR_CLEAR_VALUE = 0x0C22;

  static const int COLOR_WRITEMASK = 0x0C23;

  static const int COMPILE_STATUS = 0x8B81;

  static const int COMPRESSED_TEXTURE_FORMATS = 0x86A3;

  static const int CONSTANT_ALPHA = 0x8003;

  static const int CONSTANT_COLOR = 0x8001;

  static const int CONTEXT_LOST_WEBGL = 0x9242;

  static const int CULL_FACE = 0x0B44;

  static const int CULL_FACE_MODE = 0x0B45;

  static const int CURRENT_PROGRAM = 0x8B8D;

  static const int CURRENT_VERTEX_ATTRIB = 0x8626;

  static const int CW = 0x0900;

  static const int DECR = 0x1E03;

  static const int DECR_WRAP = 0x8508;

  static const int DELETE_STATUS = 0x8B80;

  static const int DEPTH_ATTACHMENT = 0x8D00;

  static const int DEPTH_BITS = 0x0D56;

  static const int DEPTH_BUFFER_BIT = 0x00000100;

  static const int DEPTH_CLEAR_VALUE = 0x0B73;

  static const int DEPTH_COMPONENT = 0x1902;

  static const int DEPTH_COMPONENT16 = 0x81A5;

  static const int DEPTH_FUNC = 0x0B74;

  static const int DEPTH_RANGE = 0x0B70;

  static const int DEPTH_STENCIL = 0x84F9;

  static const int DEPTH_STENCIL_ATTACHMENT = 0x821A;

  static const int DEPTH_TEST = 0x0B71;

  static const int DEPTH_WRITEMASK = 0x0B72;

  static const int DITHER = 0x0BD0;

  static const int DONT_CARE = 0x1100;

  static const int DST_ALPHA = 0x0304;

  static const int DST_COLOR = 0x0306;

  static const int DYNAMIC_DRAW = 0x88E8;

  static const int ELEMENT_ARRAY_BUFFER = 0x8893;

  static const int ELEMENT_ARRAY_BUFFER_BINDING = 0x8895;

  static const int EQUAL = 0x0202;

  static const int FASTEST = 0x1101;

  static const int FLOAT = 0x1406;

  static const int FLOAT_MAT2 = 0x8B5A;

  static const int FLOAT_MAT3 = 0x8B5B;

  static const int FLOAT_MAT4 = 0x8B5C;

  static const int FLOAT_VEC2 = 0x8B50;

  static const int FLOAT_VEC3 = 0x8B51;

  static const int FLOAT_VEC4 = 0x8B52;

  static const int FRAGMENT_SHADER = 0x8B30;

  static const int FRAMEBUFFER = 0x8D40;

  static const int FRAMEBUFFER_ATTACHMENT_OBJECT_NAME = 0x8CD1;

  static const int FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE = 0x8CD0;

  static const int FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE = 0x8CD3;

  static const int FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL = 0x8CD2;

  static const int FRAMEBUFFER_BINDING = 0x8CA6;

  static const int FRAMEBUFFER_COMPLETE = 0x8CD5;

  static const int FRAMEBUFFER_INCOMPLETE_ATTACHMENT = 0x8CD6;

  static const int FRAMEBUFFER_INCOMPLETE_DIMENSIONS = 0x8CD9;

  static const int FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT = 0x8CD7;

  static const int FRAMEBUFFER_UNSUPPORTED = 0x8CDD;

  static const int FRONT = 0x0404;

  static const int FRONT_AND_BACK = 0x0408;

  static const int FRONT_FACE = 0x0B46;

  static const int FUNC_ADD = 0x8006;

  static const int FUNC_REVERSE_SUBTRACT = 0x800B;

  static const int FUNC_SUBTRACT = 0x800A;

  static const int GENERATE_MIPMAP_HINT = 0x8192;

  static const int GEQUAL = 0x0206;

  static const int GREATER = 0x0204;

  static const int GREEN_BITS = 0x0D53;

  static const int HIGH_FLOAT = 0x8DF2;

  static const int HIGH_INT = 0x8DF5;

  static const int INCR = 0x1E02;

  static const int INCR_WRAP = 0x8507;

  static const int INT = 0x1404;

  static const int INT_VEC2 = 0x8B53;

  static const int INT_VEC3 = 0x8B54;

  static const int INT_VEC4 = 0x8B55;

  static const int INVALID_ENUM = 0x0500;

  static const int INVALID_FRAMEBUFFER_OPERATION = 0x0506;

  static const int INVALID_OPERATION = 0x0502;

  static const int INVALID_VALUE = 0x0501;

  static const int INVERT = 0x150A;

  static const int KEEP = 0x1E00;

  static const int LEQUAL = 0x0203;

  static const int LESS = 0x0201;

  static const int LINEAR = 0x2601;

  static const int LINEAR_MIPMAP_LINEAR = 0x2703;

  static const int LINEAR_MIPMAP_NEAREST = 0x2701;

  static const int LINES = 0x0001;

  static const int LINE_LOOP = 0x0002;

  static const int LINE_STRIP = 0x0003;

  static const int LINE_WIDTH = 0x0B21;

  static const int LINK_STATUS = 0x8B82;

  static const int LOW_FLOAT = 0x8DF0;

  static const int LOW_INT = 0x8DF3;

  static const int LUMINANCE = 0x1909;

  static const int LUMINANCE_ALPHA = 0x190A;

  static const int MAX_COMBINED_TEXTURE_IMAGE_UNITS = 0x8B4D;

  static const int MAX_CUBE_MAP_TEXTURE_SIZE = 0x851C;

  static const int MAX_FRAGMENT_UNIFORM_VECTORS = 0x8DFD;

  static const int MAX_RENDERBUFFER_SIZE = 0x84E8;

  static const int MAX_TEXTURE_IMAGE_UNITS = 0x8872;

  static const int MAX_TEXTURE_SIZE = 0x0D33;

  static const int MAX_VARYING_VECTORS = 0x8DFC;

  static const int MAX_VERTEX_ATTRIBS = 0x8869;

  static const int MAX_VERTEX_TEXTURE_IMAGE_UNITS = 0x8B4C;

  static const int MAX_VERTEX_UNIFORM_VECTORS = 0x8DFB;

  static const int MAX_VIEWPORT_DIMS = 0x0D3A;

  static const int MEDIUM_FLOAT = 0x8DF1;

  static const int MEDIUM_INT = 0x8DF4;

  static const int MIRRORED_REPEAT = 0x8370;

  static const int NEAREST = 0x2600;

  static const int NEAREST_MIPMAP_LINEAR = 0x2702;

  static const int NEAREST_MIPMAP_NEAREST = 0x2700;

  static const int NEVER = 0x0200;

  static const int NICEST = 0x1102;

  static const int NONE = 0;

  static const int NOTEQUAL = 0x0205;

  static const int NO_ERROR = 0;

  static const int ONE = 1;

  static const int ONE_MINUS_CONSTANT_ALPHA = 0x8004;

  static const int ONE_MINUS_CONSTANT_COLOR = 0x8002;

  static const int ONE_MINUS_DST_ALPHA = 0x0305;

  static const int ONE_MINUS_DST_COLOR = 0x0307;

  static const int ONE_MINUS_SRC_ALPHA = 0x0303;

  static const int ONE_MINUS_SRC_COLOR = 0x0301;

  static const int OUT_OF_MEMORY = 0x0505;

  static const int PACK_ALIGNMENT = 0x0D05;

  static const int POINTS = 0x0000;

  static const int POLYGON_OFFSET_FACTOR = 0x8038;

  static const int POLYGON_OFFSET_FILL = 0x8037;

  static const int POLYGON_OFFSET_UNITS = 0x2A00;

  static const int RED_BITS = 0x0D52;

  static const int RENDERBUFFER = 0x8D41;

  static const int RENDERBUFFER_ALPHA_SIZE = 0x8D53;

  static const int RENDERBUFFER_BINDING = 0x8CA7;

  static const int RENDERBUFFER_BLUE_SIZE = 0x8D52;

  static const int RENDERBUFFER_DEPTH_SIZE = 0x8D54;

  static const int RENDERBUFFER_GREEN_SIZE = 0x8D51;

  static const int RENDERBUFFER_HEIGHT = 0x8D43;

  static const int RENDERBUFFER_INTERNAL_FORMAT = 0x8D44;

  static const int RENDERBUFFER_RED_SIZE = 0x8D50;

  static const int RENDERBUFFER_STENCIL_SIZE = 0x8D55;

  static const int RENDERBUFFER_WIDTH = 0x8D42;

  static const int RENDERER = 0x1F01;

  static const int REPEAT = 0x2901;

  static const int REPLACE = 0x1E01;

  static const int RGB = 0x1907;

  static const int RGB565 = 0x8D62;

  static const int RGB5_A1 = 0x8057;

  static const int RGBA = 0x1908;

  static const int RGBA4 = 0x8056;

  static const int SAMPLER_2D = 0x8B5E;

  static const int SAMPLER_CUBE = 0x8B60;

  static const int SAMPLES = 0x80A9;

  static const int SAMPLE_ALPHA_TO_COVERAGE = 0x809E;

  static const int SAMPLE_BUFFERS = 0x80A8;

  static const int SAMPLE_COVERAGE = 0x80A0;

  static const int SAMPLE_COVERAGE_INVERT = 0x80AB;

  static const int SAMPLE_COVERAGE_VALUE = 0x80AA;

  static const int SCISSOR_BOX = 0x0C10;

  static const int SCISSOR_TEST = 0x0C11;

  static const int SHADER_TYPE = 0x8B4F;

  static const int SHADING_LANGUAGE_VERSION = 0x8B8C;

  static const int SHORT = 0x1402;

  static const int SRC_ALPHA = 0x0302;

  static const int SRC_ALPHA_SATURATE = 0x0308;

  static const int SRC_COLOR = 0x0300;

  static const int STATIC_DRAW = 0x88E4;

  static const int STENCIL_ATTACHMENT = 0x8D20;

  static const int STENCIL_BACK_FAIL = 0x8801;

  static const int STENCIL_BACK_FUNC = 0x8800;

  static const int STENCIL_BACK_PASS_DEPTH_FAIL = 0x8802;

  static const int STENCIL_BACK_PASS_DEPTH_PASS = 0x8803;

  static const int STENCIL_BACK_REF = 0x8CA3;

  static const int STENCIL_BACK_VALUE_MASK = 0x8CA4;

  static const int STENCIL_BACK_WRITEMASK = 0x8CA5;

  static const int STENCIL_BITS = 0x0D57;

  static const int STENCIL_BUFFER_BIT = 0x00000400;

  static const int STENCIL_CLEAR_VALUE = 0x0B91;

  static const int STENCIL_FAIL = 0x0B94;

  static const int STENCIL_FUNC = 0x0B92;

  static const int STENCIL_INDEX = 0x1901;

  static const int STENCIL_INDEX8 = 0x8D48;

  static const int STENCIL_PASS_DEPTH_FAIL = 0x0B95;

  static const int STENCIL_PASS_DEPTH_PASS = 0x0B96;

  static const int STENCIL_REF = 0x0B97;

  static const int STENCIL_TEST = 0x0B90;

  static const int STENCIL_VALUE_MASK = 0x0B93;

  static const int STENCIL_WRITEMASK = 0x0B98;

  static const int STREAM_DRAW = 0x88E0;

  static const int SUBPIXEL_BITS = 0x0D50;

  static const int TEXTURE = 0x1702;

  static const int TEXTURE0 = 0x84C0;

  static const int TEXTURE1 = 0x84C1;

  static const int TEXTURE10 = 0x84CA;

  static const int TEXTURE11 = 0x84CB;

  static const int TEXTURE12 = 0x84CC;

  static const int TEXTURE13 = 0x84CD;

  static const int TEXTURE14 = 0x84CE;

  static const int TEXTURE15 = 0x84CF;

  static const int TEXTURE16 = 0x84D0;

  static const int TEXTURE17 = 0x84D1;

  static const int TEXTURE18 = 0x84D2;

  static const int TEXTURE19 = 0x84D3;

  static const int TEXTURE2 = 0x84C2;

  static const int TEXTURE20 = 0x84D4;

  static const int TEXTURE21 = 0x84D5;

  static const int TEXTURE22 = 0x84D6;

  static const int TEXTURE23 = 0x84D7;

  static const int TEXTURE24 = 0x84D8;

  static const int TEXTURE25 = 0x84D9;

  static const int TEXTURE26 = 0x84DA;

  static const int TEXTURE27 = 0x84DB;

  static const int TEXTURE28 = 0x84DC;

  static const int TEXTURE29 = 0x84DD;

  static const int TEXTURE3 = 0x84C3;

  static const int TEXTURE30 = 0x84DE;

  static const int TEXTURE31 = 0x84DF;

  static const int TEXTURE4 = 0x84C4;

  static const int TEXTURE5 = 0x84C5;

  static const int TEXTURE6 = 0x84C6;

  static const int TEXTURE7 = 0x84C7;

  static const int TEXTURE8 = 0x84C8;

  static const int TEXTURE9 = 0x84C9;

  static const int TEXTURE_2D = 0x0DE1;

  static const int TEXTURE_BINDING_2D = 0x8069;

  static const int TEXTURE_BINDING_CUBE_MAP = 0x8514;

  static const int TEXTURE_CUBE_MAP = 0x8513;

  static const int TEXTURE_CUBE_MAP_NEGATIVE_X = 0x8516;

  static const int TEXTURE_CUBE_MAP_NEGATIVE_Y = 0x8518;

  static const int TEXTURE_CUBE_MAP_NEGATIVE_Z = 0x851A;

  static const int TEXTURE_CUBE_MAP_POSITIVE_X = 0x8515;

  static const int TEXTURE_CUBE_MAP_POSITIVE_Y = 0x8517;

  static const int TEXTURE_CUBE_MAP_POSITIVE_Z = 0x8519;

  static const int TEXTURE_MAG_FILTER = 0x2800;

  static const int TEXTURE_MIN_FILTER = 0x2801;

  static const int TEXTURE_WRAP_S = 0x2802;

  static const int TEXTURE_WRAP_T = 0x2803;

  static const int TRIANGLES = 0x0004;

  static const int TRIANGLE_FAN = 0x0006;

  static const int TRIANGLE_STRIP = 0x0005;

  static const int UNPACK_ALIGNMENT = 0x0CF5;

  static const int UNPACK_COLORSPACE_CONVERSION_WEBGL = 0x9243;

  static const int UNPACK_FLIP_Y_WEBGL = 0x9240;

  static const int UNPACK_PREMULTIPLY_ALPHA_WEBGL = 0x9241;

  static const int UNSIGNED_BYTE = 0x1401;

  static const int UNSIGNED_INT = 0x1405;

  static const int UNSIGNED_SHORT = 0x1403;

  static const int UNSIGNED_SHORT_4_4_4_4 = 0x8033;

  static const int UNSIGNED_SHORT_5_5_5_1 = 0x8034;

  static const int UNSIGNED_SHORT_5_6_5 = 0x8363;

  static const int VALIDATE_STATUS = 0x8B83;

  static const int VENDOR = 0x1F00;

  static const int VERSION = 0x1F02;

  static const int VERTEX_ATTRIB_ARRAY_BUFFER_BINDING = 0x889F;

  static const int VERTEX_ATTRIB_ARRAY_ENABLED = 0x8622;

  static const int VERTEX_ATTRIB_ARRAY_NORMALIZED = 0x886A;

  static const int VERTEX_ATTRIB_ARRAY_POINTER = 0x8645;

  static const int VERTEX_ATTRIB_ARRAY_SIZE = 0x8623;

  static const int VERTEX_ATTRIB_ARRAY_STRIDE = 0x8624;

  static const int VERTEX_ATTRIB_ARRAY_TYPE = 0x8625;

  static const int VERTEX_SHADER = 0x8B31;

  static const int VIEWPORT = 0x0BA2;

  static const int ZERO = 0;

  /** @domName WebGLRenderingContext.drawingBufferHeight */
  final int drawingBufferHeight;

  /** @domName WebGLRenderingContext.drawingBufferWidth */
  final int drawingBufferWidth;

  /** @domName WebGLRenderingContext.activeTexture */
  void activeTexture(int texture) native;

  /** @domName WebGLRenderingContext.attachShader */
  void attachShader(WebGLProgram program, WebGLShader shader) native;

  /** @domName WebGLRenderingContext.bindAttribLocation */
  void bindAttribLocation(WebGLProgram program, int index, String name) native;

  /** @domName WebGLRenderingContext.bindBuffer */
  void bindBuffer(int target, WebGLBuffer buffer) native;

  /** @domName WebGLRenderingContext.bindFramebuffer */
  void bindFramebuffer(int target, WebGLFramebuffer framebuffer) native;

  /** @domName WebGLRenderingContext.bindRenderbuffer */
  void bindRenderbuffer(int target, WebGLRenderbuffer renderbuffer) native;

  /** @domName WebGLRenderingContext.bindTexture */
  void bindTexture(int target, WebGLTexture texture) native;

  /** @domName WebGLRenderingContext.blendColor */
  void blendColor(num red, num green, num blue, num alpha) native;

  /** @domName WebGLRenderingContext.blendEquation */
  void blendEquation(int mode) native;

  /** @domName WebGLRenderingContext.blendEquationSeparate */
  void blendEquationSeparate(int modeRGB, int modeAlpha) native;

  /** @domName WebGLRenderingContext.blendFunc */
  void blendFunc(int sfactor, int dfactor) native;

  /** @domName WebGLRenderingContext.blendFuncSeparate */
  void blendFuncSeparate(int srcRGB, int dstRGB, int srcAlpha, int dstAlpha) native;

  /** @domName WebGLRenderingContext.bufferData */
  void bufferData(int target, data_OR_size, int usage) native;

  /** @domName WebGLRenderingContext.bufferSubData */
  void bufferSubData(int target, int offset, data) native;

  /** @domName WebGLRenderingContext.checkFramebufferStatus */
  int checkFramebufferStatus(int target) native;

  /** @domName WebGLRenderingContext.clear */
  void clear(int mask) native;

  /** @domName WebGLRenderingContext.clearColor */
  void clearColor(num red, num green, num blue, num alpha) native;

  /** @domName WebGLRenderingContext.clearDepth */
  void clearDepth(num depth) native;

  /** @domName WebGLRenderingContext.clearStencil */
  void clearStencil(int s) native;

  /** @domName WebGLRenderingContext.colorMask */
  void colorMask(bool red, bool green, bool blue, bool alpha) native;

  /** @domName WebGLRenderingContext.compileShader */
  void compileShader(WebGLShader shader) native;

  /** @domName WebGLRenderingContext.compressedTexImage2D */
  void compressedTexImage2D(int target, int level, int internalformat, int width, int height, int border, ArrayBufferView data) native;

  /** @domName WebGLRenderingContext.compressedTexSubImage2D */
  void compressedTexSubImage2D(int target, int level, int xoffset, int yoffset, int width, int height, int format, ArrayBufferView data) native;

  /** @domName WebGLRenderingContext.copyTexImage2D */
  void copyTexImage2D(int target, int level, int internalformat, int x, int y, int width, int height, int border) native;

  /** @domName WebGLRenderingContext.copyTexSubImage2D */
  void copyTexSubImage2D(int target, int level, int xoffset, int yoffset, int x, int y, int width, int height) native;

  /** @domName WebGLRenderingContext.createBuffer */
  WebGLBuffer createBuffer() native;

  /** @domName WebGLRenderingContext.createFramebuffer */
  WebGLFramebuffer createFramebuffer() native;

  /** @domName WebGLRenderingContext.createProgram */
  WebGLProgram createProgram() native;

  /** @domName WebGLRenderingContext.createRenderbuffer */
  WebGLRenderbuffer createRenderbuffer() native;

  /** @domName WebGLRenderingContext.createShader */
  WebGLShader createShader(int type) native;

  /** @domName WebGLRenderingContext.createTexture */
  WebGLTexture createTexture() native;

  /** @domName WebGLRenderingContext.cullFace */
  void cullFace(int mode) native;

  /** @domName WebGLRenderingContext.deleteBuffer */
  void deleteBuffer(WebGLBuffer buffer) native;

  /** @domName WebGLRenderingContext.deleteFramebuffer */
  void deleteFramebuffer(WebGLFramebuffer framebuffer) native;

  /** @domName WebGLRenderingContext.deleteProgram */
  void deleteProgram(WebGLProgram program) native;

  /** @domName WebGLRenderingContext.deleteRenderbuffer */
  void deleteRenderbuffer(WebGLRenderbuffer renderbuffer) native;

  /** @domName WebGLRenderingContext.deleteShader */
  void deleteShader(WebGLShader shader) native;

  /** @domName WebGLRenderingContext.deleteTexture */
  void deleteTexture(WebGLTexture texture) native;

  /** @domName WebGLRenderingContext.depthFunc */
  void depthFunc(int func) native;

  /** @domName WebGLRenderingContext.depthMask */
  void depthMask(bool flag) native;

  /** @domName WebGLRenderingContext.depthRange */
  void depthRange(num zNear, num zFar) native;

  /** @domName WebGLRenderingContext.detachShader */
  void detachShader(WebGLProgram program, WebGLShader shader) native;

  /** @domName WebGLRenderingContext.disable */
  void disable(int cap) native;

  /** @domName WebGLRenderingContext.disableVertexAttribArray */
  void disableVertexAttribArray(int index) native;

  /** @domName WebGLRenderingContext.drawArrays */
  void drawArrays(int mode, int first, int count) native;

  /** @domName WebGLRenderingContext.drawElements */
  void drawElements(int mode, int count, int type, int offset) native;

  /** @domName WebGLRenderingContext.enable */
  void enable(int cap) native;

  /** @domName WebGLRenderingContext.enableVertexAttribArray */
  void enableVertexAttribArray(int index) native;

  /** @domName WebGLRenderingContext.finish */
  void finish() native;

  /** @domName WebGLRenderingContext.flush */
  void flush() native;

  /** @domName WebGLRenderingContext.framebufferRenderbuffer */
  void framebufferRenderbuffer(int target, int attachment, int renderbuffertarget, WebGLRenderbuffer renderbuffer) native;

  /** @domName WebGLRenderingContext.framebufferTexture2D */
  void framebufferTexture2D(int target, int attachment, int textarget, WebGLTexture texture, int level) native;

  /** @domName WebGLRenderingContext.frontFace */
  void frontFace(int mode) native;

  /** @domName WebGLRenderingContext.generateMipmap */
  void generateMipmap(int target) native;

  /** @domName WebGLRenderingContext.getActiveAttrib */
  WebGLActiveInfo getActiveAttrib(WebGLProgram program, int index) native;

  /** @domName WebGLRenderingContext.getActiveUniform */
  WebGLActiveInfo getActiveUniform(WebGLProgram program, int index) native;

  /** @domName WebGLRenderingContext.getAttachedShaders */
  void getAttachedShaders(WebGLProgram program) native;

  /** @domName WebGLRenderingContext.getAttribLocation */
  int getAttribLocation(WebGLProgram program, String name) native;

  /** @domName WebGLRenderingContext.getBufferParameter */
  Object getBufferParameter(int target, int pname) native;

  /** @domName WebGLRenderingContext.getContextAttributes */
  WebGLContextAttributes getContextAttributes() native;

  /** @domName WebGLRenderingContext.getError */
  int getError() native;

  /** @domName WebGLRenderingContext.getExtension */
  Object getExtension(String name) native;

  /** @domName WebGLRenderingContext.getFramebufferAttachmentParameter */
  Object getFramebufferAttachmentParameter(int target, int attachment, int pname) native;

  /** @domName WebGLRenderingContext.getParameter */
  Object getParameter(int pname) native;

  /** @domName WebGLRenderingContext.getProgramInfoLog */
  String getProgramInfoLog(WebGLProgram program) native;

  /** @domName WebGLRenderingContext.getProgramParameter */
  Object getProgramParameter(WebGLProgram program, int pname) native;

  /** @domName WebGLRenderingContext.getRenderbufferParameter */
  Object getRenderbufferParameter(int target, int pname) native;

  /** @domName WebGLRenderingContext.getShaderInfoLog */
  String getShaderInfoLog(WebGLShader shader) native;

  /** @domName WebGLRenderingContext.getShaderParameter */
  Object getShaderParameter(WebGLShader shader, int pname) native;

  /** @domName WebGLRenderingContext.getShaderPrecisionFormat */
  WebGLShaderPrecisionFormat getShaderPrecisionFormat(int shadertype, int precisiontype) native;

  /** @domName WebGLRenderingContext.getShaderSource */
  String getShaderSource(WebGLShader shader) native;

  /** @domName WebGLRenderingContext.getSupportedExtensions */
  List<String> getSupportedExtensions() native;

  /** @domName WebGLRenderingContext.getTexParameter */
  Object getTexParameter(int target, int pname) native;

  /** @domName WebGLRenderingContext.getUniform */
  Object getUniform(WebGLProgram program, WebGLUniformLocation location) native;

  /** @domName WebGLRenderingContext.getUniformLocation */
  WebGLUniformLocation getUniformLocation(WebGLProgram program, String name) native;

  /** @domName WebGLRenderingContext.getVertexAttrib */
  Object getVertexAttrib(int index, int pname) native;

  /** @domName WebGLRenderingContext.getVertexAttribOffset */
  int getVertexAttribOffset(int index, int pname) native;

  /** @domName WebGLRenderingContext.hint */
  void hint(int target, int mode) native;

  /** @domName WebGLRenderingContext.isBuffer */
  bool isBuffer(WebGLBuffer buffer) native;

  /** @domName WebGLRenderingContext.isContextLost */
  bool isContextLost() native;

  /** @domName WebGLRenderingContext.isEnabled */
  bool isEnabled(int cap) native;

  /** @domName WebGLRenderingContext.isFramebuffer */
  bool isFramebuffer(WebGLFramebuffer framebuffer) native;

  /** @domName WebGLRenderingContext.isProgram */
  bool isProgram(WebGLProgram program) native;

  /** @domName WebGLRenderingContext.isRenderbuffer */
  bool isRenderbuffer(WebGLRenderbuffer renderbuffer) native;

  /** @domName WebGLRenderingContext.isShader */
  bool isShader(WebGLShader shader) native;

  /** @domName WebGLRenderingContext.isTexture */
  bool isTexture(WebGLTexture texture) native;

  /** @domName WebGLRenderingContext.lineWidth */
  void lineWidth(num width) native;

  /** @domName WebGLRenderingContext.linkProgram */
  void linkProgram(WebGLProgram program) native;

  /** @domName WebGLRenderingContext.pixelStorei */
  void pixelStorei(int pname, int param) native;

  /** @domName WebGLRenderingContext.polygonOffset */
  void polygonOffset(num factor, num units) native;

  /** @domName WebGLRenderingContext.readPixels */
  void readPixels(int x, int y, int width, int height, int format, int type, ArrayBufferView pixels) native;

  /** @domName WebGLRenderingContext.releaseShaderCompiler */
  void releaseShaderCompiler() native;

  /** @domName WebGLRenderingContext.renderbufferStorage */
  void renderbufferStorage(int target, int internalformat, int width, int height) native;

  /** @domName WebGLRenderingContext.sampleCoverage */
  void sampleCoverage(num value, bool invert) native;

  /** @domName WebGLRenderingContext.scissor */
  void scissor(int x, int y, int width, int height) native;

  /** @domName WebGLRenderingContext.shaderSource */
  void shaderSource(WebGLShader shader, String string) native;

  /** @domName WebGLRenderingContext.stencilFunc */
  void stencilFunc(int func, int ref, int mask) native;

  /** @domName WebGLRenderingContext.stencilFuncSeparate */
  void stencilFuncSeparate(int face, int func, int ref, int mask) native;

  /** @domName WebGLRenderingContext.stencilMask */
  void stencilMask(int mask) native;

  /** @domName WebGLRenderingContext.stencilMaskSeparate */
  void stencilMaskSeparate(int face, int mask) native;

  /** @domName WebGLRenderingContext.stencilOp */
  void stencilOp(int fail, int zfail, int zpass) native;

  /** @domName WebGLRenderingContext.stencilOpSeparate */
  void stencilOpSeparate(int face, int fail, int zfail, int zpass) native;

  /** @domName WebGLRenderingContext.texImage2D */
  void texImage2D(int target, int level, int internalformat, int format_OR_width, int height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video, [int format, int type, ArrayBufferView pixels]) {
    if ((?border_OR_canvas_OR_image_OR_pixels_OR_video && (border_OR_canvas_OR_image_OR_pixels_OR_video is int || border_OR_canvas_OR_image_OR_pixels_OR_video == null))) {
      _texImage2D_1(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video, format, type, pixels);
      return;
    }
    if ((?border_OR_canvas_OR_image_OR_pixels_OR_video && (border_OR_canvas_OR_image_OR_pixels_OR_video is ImageData || border_OR_canvas_OR_image_OR_pixels_OR_video == null)) &&
        !?format &&
        !?type &&
        !?pixels) {
      var pixels_1 = _convertDartToNative_ImageData(border_OR_canvas_OR_image_OR_pixels_OR_video);
      _texImage2D_2(target, level, internalformat, format_OR_width, height_OR_type, pixels_1);
      return;
    }
    if ((?border_OR_canvas_OR_image_OR_pixels_OR_video && (border_OR_canvas_OR_image_OR_pixels_OR_video is ImageElement || border_OR_canvas_OR_image_OR_pixels_OR_video == null)) &&
        !?format &&
        !?type &&
        !?pixels) {
      _texImage2D_3(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((?border_OR_canvas_OR_image_OR_pixels_OR_video && (border_OR_canvas_OR_image_OR_pixels_OR_video is CanvasElement || border_OR_canvas_OR_image_OR_pixels_OR_video == null)) &&
        !?format &&
        !?type &&
        !?pixels) {
      _texImage2D_4(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((?border_OR_canvas_OR_image_OR_pixels_OR_video && (border_OR_canvas_OR_image_OR_pixels_OR_video is VideoElement || border_OR_canvas_OR_image_OR_pixels_OR_video == null)) &&
        !?format &&
        !?type &&
        !?pixels) {
      _texImage2D_5(target, level, internalformat, format_OR_width, height_OR_type, border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    throw const Exception("Incorrect number or type of arguments");
  }
  void _texImage2D_1(target, level, internalformat, width, height, int border, format, type, ArrayBufferView pixels) native "texImage2D";
  void _texImage2D_2(target, level, internalformat, format, type, pixels) native "texImage2D";
  void _texImage2D_3(target, level, internalformat, format, type, ImageElement image) native "texImage2D";
  void _texImage2D_4(target, level, internalformat, format, type, CanvasElement canvas) native "texImage2D";
  void _texImage2D_5(target, level, internalformat, format, type, VideoElement video) native "texImage2D";

  /** @domName WebGLRenderingContext.texParameterf */
  void texParameterf(int target, int pname, num param) native;

  /** @domName WebGLRenderingContext.texParameteri */
  void texParameteri(int target, int pname, int param) native;

  /** @domName WebGLRenderingContext.texSubImage2D */
  void texSubImage2D(int target, int level, int xoffset, int yoffset, int format_OR_width, int height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video, [int type, ArrayBufferView pixels]) {
    if ((?canvas_OR_format_OR_image_OR_pixels_OR_video && (canvas_OR_format_OR_image_OR_pixels_OR_video is int || canvas_OR_format_OR_image_OR_pixels_OR_video == null))) {
      _texSubImage2D_1(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video, type, pixels);
      return;
    }
    if ((?canvas_OR_format_OR_image_OR_pixels_OR_video && (canvas_OR_format_OR_image_OR_pixels_OR_video is ImageData || canvas_OR_format_OR_image_OR_pixels_OR_video == null)) &&
        !?type &&
        !?pixels) {
      var pixels_1 = _convertDartToNative_ImageData(canvas_OR_format_OR_image_OR_pixels_OR_video);
      _texSubImage2D_2(target, level, xoffset, yoffset, format_OR_width, height_OR_type, pixels_1);
      return;
    }
    if ((?canvas_OR_format_OR_image_OR_pixels_OR_video && (canvas_OR_format_OR_image_OR_pixels_OR_video is ImageElement || canvas_OR_format_OR_image_OR_pixels_OR_video == null)) &&
        !?type &&
        !?pixels) {
      _texSubImage2D_3(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((?canvas_OR_format_OR_image_OR_pixels_OR_video && (canvas_OR_format_OR_image_OR_pixels_OR_video is CanvasElement || canvas_OR_format_OR_image_OR_pixels_OR_video == null)) &&
        !?type &&
        !?pixels) {
      _texSubImage2D_4(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((?canvas_OR_format_OR_image_OR_pixels_OR_video && (canvas_OR_format_OR_image_OR_pixels_OR_video is VideoElement || canvas_OR_format_OR_image_OR_pixels_OR_video == null)) &&
        !?type &&
        !?pixels) {
      _texSubImage2D_5(target, level, xoffset, yoffset, format_OR_width, height_OR_type, canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    throw const Exception("Incorrect number or type of arguments");
  }
  void _texSubImage2D_1(target, level, xoffset, yoffset, width, height, int format, type, ArrayBufferView pixels) native "texSubImage2D";
  void _texSubImage2D_2(target, level, xoffset, yoffset, format, type, pixels) native "texSubImage2D";
  void _texSubImage2D_3(target, level, xoffset, yoffset, format, type, ImageElement image) native "texSubImage2D";
  void _texSubImage2D_4(target, level, xoffset, yoffset, format, type, CanvasElement canvas) native "texSubImage2D";
  void _texSubImage2D_5(target, level, xoffset, yoffset, format, type, VideoElement video) native "texSubImage2D";

  /** @domName WebGLRenderingContext.uniform1f */
  void uniform1f(WebGLUniformLocation location, num x) native;

  /** @domName WebGLRenderingContext.uniform1fv */
  void uniform1fv(WebGLUniformLocation location, Float32Array v) native;

  /** @domName WebGLRenderingContext.uniform1i */
  void uniform1i(WebGLUniformLocation location, int x) native;

  /** @domName WebGLRenderingContext.uniform1iv */
  void uniform1iv(WebGLUniformLocation location, Int32Array v) native;

  /** @domName WebGLRenderingContext.uniform2f */
  void uniform2f(WebGLUniformLocation location, num x, num y) native;

  /** @domName WebGLRenderingContext.uniform2fv */
  void uniform2fv(WebGLUniformLocation location, Float32Array v) native;

  /** @domName WebGLRenderingContext.uniform2i */
  void uniform2i(WebGLUniformLocation location, int x, int y) native;

  /** @domName WebGLRenderingContext.uniform2iv */
  void uniform2iv(WebGLUniformLocation location, Int32Array v) native;

  /** @domName WebGLRenderingContext.uniform3f */
  void uniform3f(WebGLUniformLocation location, num x, num y, num z) native;

  /** @domName WebGLRenderingContext.uniform3fv */
  void uniform3fv(WebGLUniformLocation location, Float32Array v) native;

  /** @domName WebGLRenderingContext.uniform3i */
  void uniform3i(WebGLUniformLocation location, int x, int y, int z) native;

  /** @domName WebGLRenderingContext.uniform3iv */
  void uniform3iv(WebGLUniformLocation location, Int32Array v) native;

  /** @domName WebGLRenderingContext.uniform4f */
  void uniform4f(WebGLUniformLocation location, num x, num y, num z, num w) native;

  /** @domName WebGLRenderingContext.uniform4fv */
  void uniform4fv(WebGLUniformLocation location, Float32Array v) native;

  /** @domName WebGLRenderingContext.uniform4i */
  void uniform4i(WebGLUniformLocation location, int x, int y, int z, int w) native;

  /** @domName WebGLRenderingContext.uniform4iv */
  void uniform4iv(WebGLUniformLocation location, Int32Array v) native;

  /** @domName WebGLRenderingContext.uniformMatrix2fv */
  void uniformMatrix2fv(WebGLUniformLocation location, bool transpose, Float32Array array) native;

  /** @domName WebGLRenderingContext.uniformMatrix3fv */
  void uniformMatrix3fv(WebGLUniformLocation location, bool transpose, Float32Array array) native;

  /** @domName WebGLRenderingContext.uniformMatrix4fv */
  void uniformMatrix4fv(WebGLUniformLocation location, bool transpose, Float32Array array) native;

  /** @domName WebGLRenderingContext.useProgram */
  void useProgram(WebGLProgram program) native;

  /** @domName WebGLRenderingContext.validateProgram */
  void validateProgram(WebGLProgram program) native;

  /** @domName WebGLRenderingContext.vertexAttrib1f */
  void vertexAttrib1f(int indx, num x) native;

  /** @domName WebGLRenderingContext.vertexAttrib1fv */
  void vertexAttrib1fv(int indx, Float32Array values) native;

  /** @domName WebGLRenderingContext.vertexAttrib2f */
  void vertexAttrib2f(int indx, num x, num y) native;

  /** @domName WebGLRenderingContext.vertexAttrib2fv */
  void vertexAttrib2fv(int indx, Float32Array values) native;

  /** @domName WebGLRenderingContext.vertexAttrib3f */
  void vertexAttrib3f(int indx, num x, num y, num z) native;

  /** @domName WebGLRenderingContext.vertexAttrib3fv */
  void vertexAttrib3fv(int indx, Float32Array values) native;

  /** @domName WebGLRenderingContext.vertexAttrib4f */
  void vertexAttrib4f(int indx, num x, num y, num z, num w) native;

  /** @domName WebGLRenderingContext.vertexAttrib4fv */
  void vertexAttrib4fv(int indx, Float32Array values) native;

  /** @domName WebGLRenderingContext.vertexAttribPointer */
  void vertexAttribPointer(int indx, int size, int type, bool normalized, int stride, int offset) native;

  /** @domName WebGLRenderingContext.viewport */
  void viewport(int x, int y, int width, int height) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WebGLShader
class WebGLShader native "*WebGLShader" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WebGLShaderPrecisionFormat
class WebGLShaderPrecisionFormat native "*WebGLShaderPrecisionFormat" {

  /** @domName WebGLShaderPrecisionFormat.precision */
  final int precision;

  /** @domName WebGLShaderPrecisionFormat.rangeMax */
  final int rangeMax;

  /** @domName WebGLShaderPrecisionFormat.rangeMin */
  final int rangeMin;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WebGLTexture
class WebGLTexture native "*WebGLTexture" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WebGLUniformLocation
class WebGLUniformLocation native "*WebGLUniformLocation" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WebGLVertexArrayObjectOES
class WebGLVertexArrayObjectOES native "*WebGLVertexArrayObjectOES" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WebKitCSSFilterValue
class WebKitCSSFilterValue extends _CSSValueList native "*WebKitCSSFilterValue" {

  static const int CSS_FILTER_BLUR = 10;

  static const int CSS_FILTER_BRIGHTNESS = 8;

  static const int CSS_FILTER_CONTRAST = 9;

  static const int CSS_FILTER_CUSTOM = 12;

  static const int CSS_FILTER_DROP_SHADOW = 11;

  static const int CSS_FILTER_GRAYSCALE = 2;

  static const int CSS_FILTER_HUE_ROTATE = 5;

  static const int CSS_FILTER_INVERT = 6;

  static const int CSS_FILTER_OPACITY = 7;

  static const int CSS_FILTER_REFERENCE = 1;

  static const int CSS_FILTER_SATURATE = 4;

  static const int CSS_FILTER_SEPIA = 3;

  /** @domName WebKitCSSFilterValue.operationType */
  final int operationType;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WebKitNamedFlow
class WebKitNamedFlow extends EventTarget native "*WebKitNamedFlow" {

  /** @domName WebKitNamedFlow.firstEmptyRegionIndex */
  final int firstEmptyRegionIndex;

  /** @domName WebKitNamedFlow.name */
  final String name;

  /** @domName WebKitNamedFlow.overset */
  final bool overset;

  /** @domName WebKitNamedFlow.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "addEventListener";

  /** @domName WebKitNamedFlow.dispatchEvent */
  bool $dom_dispatchEvent(Event event) native "dispatchEvent";

  /** @domName WebKitNamedFlow.getContent */
  List<Node> getContent() native;

  /** @domName WebKitNamedFlow.getRegions */
  List<Node> getRegions() native;

  /** @domName WebKitNamedFlow.getRegionsByContent */
  List<Node> getRegionsByContent(Node contentNode) native;

  /** @domName WebKitNamedFlow.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "removeEventListener";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


class WebSocket extends EventTarget native "*WebSocket" {
  factory WebSocket(String url) => _WebSocketFactoryProvider.createWebSocket(url);

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  WebSocketEvents get on =>
    new WebSocketEvents(this);

  static const int CLOSED = 3;

  static const int CLOSING = 2;

  static const int CONNECTING = 0;

  static const int OPEN = 1;

  /** @domName WebSocket.URL */
  final String URL;

  /** @domName WebSocket.binaryType */
  String binaryType;

  /** @domName WebSocket.bufferedAmount */
  final int bufferedAmount;

  /** @domName WebSocket.extensions */
  final String extensions;

  /** @domName WebSocket.protocol */
  final String protocol;

  /** @domName WebSocket.readyState */
  final int readyState;

  /** @domName WebSocket.url */
  final String url;

  /** @domName WebSocket.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "addEventListener";

  /** @domName WebSocket.close */
  void close([int code, String reason]) native;

  /** @domName WebSocket.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "dispatchEvent";

  /** @domName WebSocket.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "removeEventListener";

  /** @domName WebSocket.send */
  void send(data) native;

}

class WebSocketEvents extends Events {
  WebSocketEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get close => this['close'];

  EventListenerList get error => this['error'];

  EventListenerList get message => this['message'];

  EventListenerList get open => this['open'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class WheelEvent extends MouseEvent native "*WheelEvent" {

  /** @domName WheelEvent.webkitDirectionInvertedFromDevice */
  final bool webkitDirectionInvertedFromDevice;

  /** @domName WheelEvent.initWebKitWheelEvent */
  void initWebKitWheelEvent(int wheelDeltaX, int wheelDeltaY, LocalWindow view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) native;


  /** @domName WheelEvent.deltaY */
  num get deltaY {
    if (JS('bool', '#.deltaY !== undefined', this)) {
      // W3C WheelEvent
      return this._deltaY;
    } else if (JS('bool', '#.wheelDelta !== undefined', this)) {
      // Chrome and IE
      return this._wheelDelta;
    } else if (JS('bool', '#.detail !== undefined', this)) {
      // Firefox

      // Handle DOMMouseScroll case where it uses detail and the axis to
      // differentiate.
      if (JS('bool', '#.axis == MouseScrollEvent.VERTICAL_AXIS', this)) {
        var detail = this._detail;
        // Firefox is normally the number of lines to scale (normally 3)
        // so multiply it by 40 to get pixels to move, matching IE & WebKit.
        if (detail < 100) {
          return detail * 40;
        }
        return detail;
      }
      return 0;
    }
    throw new UnsupportedError(
        'deltaY is not supported');
  }

  /** @domName WheelEvent.deltaX */
  num get deltaX {
    if (JS('bool', '#.deltaX !== undefined', this)) {
      // W3C WheelEvent
      return this._deltaX;
    } else if (JS('bool', '#.wheelDeltaX !== undefined', this)) {
      // Chrome
      return this._wheelDeltaX;
    } else if (JS('bool', '#.detail !== undefined', this)) {
      // Firefox and IE.
      // IE will have detail set but will not set axis.

      // Handle DOMMouseScroll case where it uses detail and the axis to
      // differentiate.
      if (JS('bool', '#.axis !== undefined && #.axis == MouseScrollEvent.HORIZONTAL_AXIS', this, this)) {
        var detail = this._detail;
        // Firefox is normally the number of lines to scale (normally 3)
        // so multiply it by 40 to get pixels to move, matching IE & WebKit.
        if (detail < 100) {
          return detail * 40;
        }
        return detail;
      }
      return 0;
    }
    throw new UnsupportedError(
        'deltaX is not supported');
  }

  int get deltaMode {
    if (JS('bool', '!!#.deltaMode', this)) {
      // If not available then we're poly-filling and doing pixel scroll.
      return 0;
    }
    return this._deltaMode;
  }

  num get _deltaY => JS('num', '#.deltaY', this);
  num get _deltaX => JS('num', '#.deltaX', this);
  num get _wheelDelta => JS('num', '#.wheelDelta', this);
  num get _wheelDeltaX => JS('num', '#.wheelDeltaX', this);
  num get _detail => JS('num', '#.detail', this);
  int get _deltaMode => JS('int', '#.deltaMode', this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName Worker
class Worker extends AbstractWorker native "*Worker" {

  factory Worker(String scriptUrl) => _WorkerFactoryProvider.createWorker(scriptUrl);

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  WorkerEvents get on =>
    new WorkerEvents(this);

  /** @domName Worker.postMessage */
  void postMessage(/*SerializedScriptValue*/ message, [List messagePorts]) {
    if (?messagePorts) {
      var message_1 = _convertDartToNative_SerializedScriptValue(message);
      _postMessage_1(message_1, messagePorts);
      return;
    }
    var message_2 = _convertDartToNative_SerializedScriptValue(message);
    _postMessage_2(message_2);
    return;
  }
  void _postMessage_1(message, List messagePorts) native "postMessage";
  void _postMessage_2(message) native "postMessage";

  /** @domName Worker.terminate */
  void terminate() native;
}

class WorkerEvents extends AbstractWorkerEvents {
  WorkerEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get message => this['message'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WorkerContext
class WorkerContext extends EventTarget native "*WorkerContext" {

  /**
   * @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent
   */
  WorkerContextEvents get on =>
    new WorkerContextEvents(this);

  static const int PERSISTENT = 1;

  static const int TEMPORARY = 0;

  /** @domName WorkerContext.indexedDB */
  final IDBFactory indexedDB;

  /** @domName WorkerContext.location */
  final WorkerLocation location;

  /** @domName WorkerContext.navigator */
  final WorkerNavigator navigator;

  /** @domName WorkerContext.self */
  final WorkerContext self;

  /** @domName WorkerContext.webkitIndexedDB */
  final IDBFactory webkitIndexedDB;

  /** @domName WorkerContext.webkitNotifications */
  final NotificationCenter webkitNotifications;

  /** @domName WorkerContext.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "addEventListener";

  /** @domName WorkerContext.clearInterval */
  void clearInterval(int handle) native;

  /** @domName WorkerContext.clearTimeout */
  void clearTimeout(int handle) native;

  /** @domName WorkerContext.close */
  void close() native;

  /** @domName WorkerContext.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "dispatchEvent";

  /** @domName WorkerContext.importScripts */
  void importScripts() native;

  /** @domName WorkerContext.openDatabase */
  Database openDatabase(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback]) native;

  /** @domName WorkerContext.openDatabaseSync */
  DatabaseSync openDatabaseSync(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback]) native;

  /** @domName WorkerContext.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "removeEventListener";

  /** @domName WorkerContext.setInterval */
  int setInterval(TimeoutHandler handler, int timeout) native;

  /** @domName WorkerContext.setTimeout */
  int setTimeout(TimeoutHandler handler, int timeout) native;

  /** @domName WorkerContext.webkitRequestFileSystem */
  void webkitRequestFileSystem(int type, int size, [FileSystemCallback successCallback, ErrorCallback errorCallback]) native;

  /** @domName WorkerContext.webkitRequestFileSystemSync */
  DOMFileSystemSync webkitRequestFileSystemSync(int type, int size) native;

  /** @domName WorkerContext.webkitResolveLocalFileSystemSyncURL */
  EntrySync webkitResolveLocalFileSystemSyncURL(String url) native;

  /** @domName WorkerContext.webkitResolveLocalFileSystemURL */
  void webkitResolveLocalFileSystemURL(String url, EntryCallback successCallback, [ErrorCallback errorCallback]) native;
}

class WorkerContextEvents extends Events {
  WorkerContextEvents(EventTarget _ptr) : super(_ptr);

  EventListenerList get error => this['error'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WorkerLocation
class WorkerLocation native "*WorkerLocation" {

  /** @domName WorkerLocation.hash */
  final String hash;

  /** @domName WorkerLocation.host */
  final String host;

  /** @domName WorkerLocation.hostname */
  final String hostname;

  /** @domName WorkerLocation.href */
  final String href;

  /** @domName WorkerLocation.pathname */
  final String pathname;

  /** @domName WorkerLocation.port */
  final String port;

  /** @domName WorkerLocation.protocol */
  final String protocol;

  /** @domName WorkerLocation.search */
  final String search;

  /** @domName WorkerLocation.toString */
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WorkerNavigator
class WorkerNavigator native "*WorkerNavigator" {

  /** @domName WorkerNavigator.appName */
  final String appName;

  /** @domName WorkerNavigator.appVersion */
  final String appVersion;

  /** @domName WorkerNavigator.onLine */
  final bool onLine;

  /** @domName WorkerNavigator.platform */
  final String platform;

  /** @domName WorkerNavigator.userAgent */
  final String userAgent;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName XMLSerializer
class XMLSerializer native "*XMLSerializer" {

  factory XMLSerializer() => _XMLSerializerFactoryProvider.createXMLSerializer();

  /** @domName XMLSerializer.serializeToString */
  String serializeToString(Node node) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName XPathEvaluator
class XPathEvaluator native "*XPathEvaluator" {

  factory XPathEvaluator() => _XPathEvaluatorFactoryProvider.createXPathEvaluator();

  /** @domName XPathEvaluator.createExpression */
  XPathExpression createExpression(String expression, XPathNSResolver resolver) native;

  /** @domName XPathEvaluator.createNSResolver */
  XPathNSResolver createNSResolver(Node nodeResolver) native;

  /** @domName XPathEvaluator.evaluate */
  XPathResult evaluate(String expression, Node contextNode, XPathNSResolver resolver, int type, XPathResult inResult) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName XPathException
class XPathException native "*XPathException" {

  static const int INVALID_EXPRESSION_ERR = 51;

  static const int TYPE_ERR = 52;

  /** @domName XPathException.code */
  final int code;

  /** @domName XPathException.message */
  final String message;

  /** @domName XPathException.name */
  final String name;

  /** @domName XPathException.toString */
  String toString() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName XPathExpression
class XPathExpression native "*XPathExpression" {

  /** @domName XPathExpression.evaluate */
  XPathResult evaluate(Node contextNode, int type, XPathResult inResult) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName XPathNSResolver
class XPathNSResolver native "*XPathNSResolver" {

  /** @domName XPathNSResolver.lookupNamespaceURI */
  String lookupNamespaceURI(String prefix) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName XPathResult
class XPathResult native "*XPathResult" {

  static const int ANY_TYPE = 0;

  static const int ANY_UNORDERED_NODE_TYPE = 8;

  static const int BOOLEAN_TYPE = 3;

  static const int FIRST_ORDERED_NODE_TYPE = 9;

  static const int NUMBER_TYPE = 1;

  static const int ORDERED_NODE_ITERATOR_TYPE = 5;

  static const int ORDERED_NODE_SNAPSHOT_TYPE = 7;

  static const int STRING_TYPE = 2;

  static const int UNORDERED_NODE_ITERATOR_TYPE = 4;

  static const int UNORDERED_NODE_SNAPSHOT_TYPE = 6;

  /** @domName XPathResult.booleanValue */
  final bool booleanValue;

  /** @domName XPathResult.invalidIteratorState */
  final bool invalidIteratorState;

  /** @domName XPathResult.numberValue */
  final num numberValue;

  /** @domName XPathResult.resultType */
  final int resultType;

  /** @domName XPathResult.singleNodeValue */
  final Node singleNodeValue;

  /** @domName XPathResult.snapshotLength */
  final int snapshotLength;

  /** @domName XPathResult.stringValue */
  final String stringValue;

  /** @domName XPathResult.iterateNext */
  Node iterateNext() native;

  /** @domName XPathResult.snapshotItem */
  Node snapshotItem(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName XSLTProcessor
class XSLTProcessor native "*XSLTProcessor" {

  factory XSLTProcessor() => _XSLTProcessorFactoryProvider.createXSLTProcessor();

  /** @domName XSLTProcessor.clearParameters */
  void clearParameters() native;

  /** @domName XSLTProcessor.getParameter */
  String getParameter(String namespaceURI, String localName) native;

  /** @domName XSLTProcessor.importStylesheet */
  void importStylesheet(Node stylesheet) native;

  /** @domName XSLTProcessor.removeParameter */
  void removeParameter(String namespaceURI, String localName) native;

  /** @domName XSLTProcessor.reset */
  void reset() native;

  /** @domName XSLTProcessor.setParameter */
  void setParameter(String namespaceURI, String localName, String value) native;

  /** @domName XSLTProcessor.transformToDocument */
  Document transformToDocument(Node source) native;

  /** @domName XSLTProcessor.transformToFragment */
  DocumentFragment transformToFragment(Node source, Document docVal) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _ArrayBufferFactoryProvider {
  static ArrayBuffer createArrayBuffer(int length) =>
      JS('ArrayBuffer', 'new ArrayBuffer(#)', length);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _AudioElementFactoryProvider {
  static AudioElement createAudioElement([String src = null]) {
    if (src == null) return JS('AudioElement', 'new Audio()');
    return JS('AudioElement', 'new Audio(#)', src);
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _BlobFactoryProvider {
  static Blob createBlob([List blobParts = null, String type, String endings]) {
    // TODO: validate that blobParts is a JS Array and convert if not.
    // TODO: any coercions on the elements of blobParts, e.g. coerce a typed
    // array to ArrayBuffer if it is a total view.
    if (type == null && endings == null) {
      return _create_1(blobParts);
    }
    var bag = _create_bag();
    if (type != null) _bag_set(bag, 'type', type);
    if (endings != null) _bag_set(bag, 'endings', endings);
    return _create_2(blobParts, bag);
  }

  static _create_1(parts) => JS('Blob', 'new Blob(#)', parts);
  static _create_2(parts, bag) => JS('Blob', 'new Blob(#, #)', parts, bag);

  static _create_bag() => JS('var', '{}');
  static _bag_set(bag, key, value) { JS('void', '#[#] = #', bag, key, value); }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _CSSMatrixFactoryProvider {
  static CSSMatrix createCSSMatrix([String cssValue = '']) =>
      JS('CSSMatrix', 'new WebKitCSSMatrix(#)', cssValue);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName CSSRuleList
class _CSSRuleList implements JavaScriptIndexingBehavior, List<CSSRule> native "*CSSRuleList" {

  /** @domName CSSRuleList.length */
  final int length;

  CSSRule operator[](int index) => JS("CSSRule", "#[#]", this, index);

  void operator[]=(int index, CSSRule value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<CSSRule> mixins.
  // CSSRule is the element type.

  // From Iterable<CSSRule>:

  Iterator<CSSRule> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<CSSRule>(this);
  }

  // From Collection<CSSRule>:

  void add(CSSRule value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(CSSRule value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<CSSRule> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(CSSRule element) => _Collections.contains(this, element);

  void forEach(void f(CSSRule element)) => _Collections.forEach(this, f);

  Collection map(f(CSSRule element)) => _Collections.map(this, [], f);

  Collection<CSSRule> filter(bool f(CSSRule element)) =>
     _Collections.filter(this, <CSSRule>[], f);

  bool every(bool f(CSSRule element)) => _Collections.every(this, f);

  bool some(bool f(CSSRule element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<CSSRule>:

  void sort([Comparator<CSSRule> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(CSSRule element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(CSSRule element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  CSSRule get last => this[length - 1];

  CSSRule removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<CSSRule> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [CSSRule initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<CSSRule> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <CSSRule>[]);

  // -- end List<CSSRule> mixins.

  /** @domName CSSRuleList.item */
  CSSRule item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName CSSValueList
class _CSSValueList extends CSSValue implements List<CSSValue>, JavaScriptIndexingBehavior native "*CSSValueList" {

  /** @domName CSSValueList.length */
  final int length;

  CSSValue operator[](int index) => JS("CSSValue", "#[#]", this, index);

  void operator[]=(int index, CSSValue value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<CSSValue> mixins.
  // CSSValue is the element type.

  // From Iterable<CSSValue>:

  Iterator<CSSValue> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<CSSValue>(this);
  }

  // From Collection<CSSValue>:

  void add(CSSValue value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(CSSValue value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<CSSValue> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(CSSValue element) => _Collections.contains(this, element);

  void forEach(void f(CSSValue element)) => _Collections.forEach(this, f);

  Collection map(f(CSSValue element)) => _Collections.map(this, [], f);

  Collection<CSSValue> filter(bool f(CSSValue element)) =>
     _Collections.filter(this, <CSSValue>[], f);

  bool every(bool f(CSSValue element)) => _Collections.every(this, f);

  bool some(bool f(CSSValue element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<CSSValue>:

  void sort([Comparator<CSSValue> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(CSSValue element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(CSSValue element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  CSSValue get last => this[length - 1];

  CSSValue removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<CSSValue> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [CSSValue initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<CSSValue> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <CSSValue>[]);

  // -- end List<CSSValue> mixins.

  /** @domName CSSValueList.item */
  CSSValue item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName ClientRectList
class _ClientRectList implements JavaScriptIndexingBehavior, List<ClientRect> native "*ClientRectList" {

  /** @domName ClientRectList.length */
  final int length;

  ClientRect operator[](int index) => JS("ClientRect", "#[#]", this, index);

  void operator[]=(int index, ClientRect value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<ClientRect> mixins.
  // ClientRect is the element type.

  // From Iterable<ClientRect>:

  Iterator<ClientRect> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<ClientRect>(this);
  }

  // From Collection<ClientRect>:

  void add(ClientRect value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(ClientRect value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<ClientRect> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(ClientRect element) => _Collections.contains(this, element);

  void forEach(void f(ClientRect element)) => _Collections.forEach(this, f);

  Collection map(f(ClientRect element)) => _Collections.map(this, [], f);

  Collection<ClientRect> filter(bool f(ClientRect element)) =>
     _Collections.filter(this, <ClientRect>[], f);

  bool every(bool f(ClientRect element)) => _Collections.every(this, f);

  bool some(bool f(ClientRect element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<ClientRect>:

  void sort([Comparator<ClientRect> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(ClientRect element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(ClientRect element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  ClientRect get last => this[length - 1];

  ClientRect removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<ClientRect> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [ClientRect initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<ClientRect> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <ClientRect>[]);

  // -- end List<ClientRect> mixins.

  /** @domName ClientRectList.item */
  ClientRect item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _DOMParserFactoryProvider {
  static DOMParser createDOMParser() =>
      JS('DOMParser', 'new DOMParser()' );
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName DOMStringList
class _DOMStringList implements JavaScriptIndexingBehavior, List<String> native "*DOMStringList" {

  /** @domName DOMStringList.length */
  final int length;

  String operator[](int index) => JS("String", "#[#]", this, index);

  void operator[]=(int index, String value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<String> mixins.
  // String is the element type.

  // From Iterable<String>:

  Iterator<String> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<String>(this);
  }

  // From Collection<String>:

  void add(String value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(String value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<String> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // contains() defined by IDL.

  void forEach(void f(String element)) => _Collections.forEach(this, f);

  Collection map(f(String element)) => _Collections.map(this, [], f);

  Collection<String> filter(bool f(String element)) =>
     _Collections.filter(this, <String>[], f);

  bool every(bool f(String element)) => _Collections.every(this, f);

  bool some(bool f(String element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<String>:

  void sort([Comparator<String> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(String element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(String element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  String get last => this[length - 1];

  String removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<String> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [String initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<String> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <String>[]);

  // -- end List<String> mixins.

  /** @domName DOMStringList.contains */
  bool contains(String string) native;

  /** @domName DOMStringList.item */
  String item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _DataViewFactoryProvider {
  static DataView createDataView(
      ArrayBuffer buffer, [int byteOffset = null, int byteLength = null]) {
    if (byteOffset == null) {
      return JS('DataView', 'new DataView(#)', buffer);
    }
    if (byteLength == null) {
      return JS('DataView', 'new DataView(#,#)', buffer, byteOffset);
    }
    return JS('DataView', 'new DataView(#,#,#)', buffer, byteOffset, byteLength);
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _Elements {


  static AnchorElement createAnchorElement([String href]) {
    AnchorElement _e = document.$dom_createElement("a");
    if (href != null) _e.href = href;
    return _e;
  }

  static AreaElement createAreaElement() {
    AreaElement _e = document.$dom_createElement("area");
    return _e;
  }

  static BRElement createBRElement() {
    BRElement _e = document.$dom_createElement("br");
    return _e;
  }

  static BaseElement createBaseElement() {
    BaseElement _e = document.$dom_createElement("base");
    return _e;
  }

  static BodyElement createBodyElement() {
    BodyElement _e = document.$dom_createElement("body");
    return _e;
  }

  static ButtonElement createButtonElement() {
    ButtonElement _e = document.$dom_createElement("button");
    return _e;
  }

  static CanvasElement createCanvasElement([int width, int height]) {
    CanvasElement _e = document.$dom_createElement("canvas");
    if (width != null) _e.width = width;
    if (height != null) _e.height = height;
    return _e;
  }

  static ContentElement createContentElement() {
    ContentElement _e = document.$dom_createElement("content");
    return _e;
  }

  static DListElement createDListElement() {
    DListElement _e = document.$dom_createElement("dl");
    return _e;
  }

  static DataListElement createDataListElement() {
    DataListElement _e = document.$dom_createElement("datalist");
    return _e;
  }

  static DetailsElement createDetailsElement() {
    DetailsElement _e = document.$dom_createElement("details");
    return _e;
  }

  static DivElement createDivElement() {
    DivElement _e = document.$dom_createElement("div");
    return _e;
  }

  static EmbedElement createEmbedElement() {
    EmbedElement _e = document.$dom_createElement("embed");
    return _e;
  }

  static FieldSetElement createFieldSetElement() {
    FieldSetElement _e = document.$dom_createElement("fieldset");
    return _e;
  }

  static FormElement createFormElement() {
    FormElement _e = document.$dom_createElement("form");
    return _e;
  }

  static HRElement createHRElement() {
    HRElement _e = document.$dom_createElement("hr");
    return _e;
  }

  static HeadElement createHeadElement() {
    HeadElement _e = document.$dom_createElement("head");
    return _e;
  }

  static HeadingElement createHeadingElement_h1() {
    HeadingElement _e = document.$dom_createElement("h1");
    return _e;
  }

  static HeadingElement createHeadingElement_h2() {
    HeadingElement _e = document.$dom_createElement("h2");
    return _e;
  }

  static HeadingElement createHeadingElement_h3() {
    HeadingElement _e = document.$dom_createElement("h3");
    return _e;
  }

  static HeadingElement createHeadingElement_h4() {
    HeadingElement _e = document.$dom_createElement("h4");
    return _e;
  }

  static HeadingElement createHeadingElement_h5() {
    HeadingElement _e = document.$dom_createElement("h5");
    return _e;
  }

  static HeadingElement createHeadingElement_h6() {
    HeadingElement _e = document.$dom_createElement("h6");
    return _e;
  }

  static HtmlElement createHtmlElement() {
    HtmlElement _e = document.$dom_createElement("html");
    return _e;
  }

  static IFrameElement createIFrameElement() {
    IFrameElement _e = document.$dom_createElement("iframe");
    return _e;
  }

  static ImageElement createImageElement([String src, int width, int height]) {
    ImageElement _e = document.$dom_createElement("img");
    if (src != null) _e.src = src;
    if (width != null) _e.width = width;
    if (height != null) _e.height = height;
    return _e;
  }

  static InputElement createInputElement([String type]) {
    InputElement _e = document.$dom_createElement("input");
    if (type != null) _e.type = type;
    return _e;
  }

  static KeygenElement createKeygenElement() {
    KeygenElement _e = document.$dom_createElement("keygen");
    return _e;
  }

  static LIElement createLIElement() {
    LIElement _e = document.$dom_createElement("li");
    return _e;
  }

  static LabelElement createLabelElement() {
    LabelElement _e = document.$dom_createElement("label");
    return _e;
  }

  static LegendElement createLegendElement() {
    LegendElement _e = document.$dom_createElement("legend");
    return _e;
  }

  static LinkElement createLinkElement() {
    LinkElement _e = document.$dom_createElement("link");
    return _e;
  }

  static MapElement createMapElement() {
    MapElement _e = document.$dom_createElement("map");
    return _e;
  }

  static MenuElement createMenuElement() {
    MenuElement _e = document.$dom_createElement("menu");
    return _e;
  }

  static MeterElement createMeterElement() {
    MeterElement _e = document.$dom_createElement("meter");
    return _e;
  }

  static OListElement createOListElement() {
    OListElement _e = document.$dom_createElement("ol");
    return _e;
  }

  static ObjectElement createObjectElement() {
    ObjectElement _e = document.$dom_createElement("object");
    return _e;
  }

  static OptGroupElement createOptGroupElement() {
    OptGroupElement _e = document.$dom_createElement("optgroup");
    return _e;
  }

  static OutputElement createOutputElement() {
    OutputElement _e = document.$dom_createElement("output");
    return _e;
  }

  static ParagraphElement createParagraphElement() {
    ParagraphElement _e = document.$dom_createElement("p");
    return _e;
  }

  static ParamElement createParamElement() {
    ParamElement _e = document.$dom_createElement("param");
    return _e;
  }

  static PreElement createPreElement() {
    PreElement _e = document.$dom_createElement("pre");
    return _e;
  }

  static ProgressElement createProgressElement() {
    ProgressElement _e = document.$dom_createElement("progress");
    return _e;
  }

  static ScriptElement createScriptElement() {
    ScriptElement _e = document.$dom_createElement("script");
    return _e;
  }

  static SelectElement createSelectElement() {
    SelectElement _e = document.$dom_createElement("select");
    return _e;
  }

  static SourceElement createSourceElement() {
    SourceElement _e = document.$dom_createElement("source");
    return _e;
  }

  static SpanElement createSpanElement() {
    SpanElement _e = document.$dom_createElement("span");
    return _e;
  }

  static StyleElement createStyleElement() {
    StyleElement _e = document.$dom_createElement("style");
    return _e;
  }

  static TableCaptionElement createTableCaptionElement() {
    TableCaptionElement _e = document.$dom_createElement("caption");
    return _e;
  }

  static TableCellElement createTableCellElement() {
    TableCellElement _e = document.$dom_createElement("td");
    return _e;
  }

  static TableColElement createTableColElement() {
    TableColElement _e = document.$dom_createElement("col");
    return _e;
  }

  static TableElement createTableElement() {
    TableElement _e = document.$dom_createElement("table");
    return _e;
  }

  static TableRowElement createTableRowElement() {
    TableRowElement _e = document.$dom_createElement("tr");
    return _e;
  }

  static TextAreaElement createTextAreaElement() {
    TextAreaElement _e = document.$dom_createElement("textarea");
    return _e;
  }

  static TitleElement createTitleElement() {
    TitleElement _e = document.$dom_createElement("title");
    return _e;
  }

  static TrackElement createTrackElement() {
    TrackElement _e = document.$dom_createElement("track");
    return _e;
  }

  static UListElement createUListElement() {
    UListElement _e = document.$dom_createElement("ul");
    return _e;
  }

  static VideoElement createVideoElement() {
    VideoElement _e = document.$dom_createElement("video");
    return _e;
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName EntryArray
class _EntryArray implements JavaScriptIndexingBehavior, List<Entry> native "*EntryArray" {

  /** @domName EntryArray.length */
  final int length;

  Entry operator[](int index) => JS("Entry", "#[#]", this, index);

  void operator[]=(int index, Entry value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Entry> mixins.
  // Entry is the element type.

  // From Iterable<Entry>:

  Iterator<Entry> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Entry>(this);
  }

  // From Collection<Entry>:

  void add(Entry value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(Entry value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<Entry> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(Entry element) => _Collections.contains(this, element);

  void forEach(void f(Entry element)) => _Collections.forEach(this, f);

  Collection map(f(Entry element)) => _Collections.map(this, [], f);

  Collection<Entry> filter(bool f(Entry element)) =>
     _Collections.filter(this, <Entry>[], f);

  bool every(bool f(Entry element)) => _Collections.every(this, f);

  bool some(bool f(Entry element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<Entry>:

  void sort([Comparator<Entry> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Entry element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Entry element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  Entry get last => this[length - 1];

  Entry removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<Entry> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [Entry initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<Entry> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <Entry>[]);

  // -- end List<Entry> mixins.

  /** @domName EntryArray.item */
  Entry item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName EntryArraySync
class _EntryArraySync implements JavaScriptIndexingBehavior, List<EntrySync> native "*EntryArraySync" {

  /** @domName EntryArraySync.length */
  final int length;

  EntrySync operator[](int index) => JS("EntrySync", "#[#]", this, index);

  void operator[]=(int index, EntrySync value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<EntrySync> mixins.
  // EntrySync is the element type.

  // From Iterable<EntrySync>:

  Iterator<EntrySync> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<EntrySync>(this);
  }

  // From Collection<EntrySync>:

  void add(EntrySync value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(EntrySync value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<EntrySync> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(EntrySync element) => _Collections.contains(this, element);

  void forEach(void f(EntrySync element)) => _Collections.forEach(this, f);

  Collection map(f(EntrySync element)) => _Collections.map(this, [], f);

  Collection<EntrySync> filter(bool f(EntrySync element)) =>
     _Collections.filter(this, <EntrySync>[], f);

  bool every(bool f(EntrySync element)) => _Collections.every(this, f);

  bool some(bool f(EntrySync element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<EntrySync>:

  void sort([Comparator<EntrySync> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(EntrySync element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(EntrySync element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  EntrySync get last => this[length - 1];

  EntrySync removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<EntrySync> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [EntrySync initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<EntrySync> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <EntrySync>[]);

  // -- end List<EntrySync> mixins.

  /** @domName EntryArraySync.item */
  EntrySync item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _EventSourceFactoryProvider {
  static EventSource createEventSource(String scriptUrl) =>
      JS('EventSource', 'new EventSource(#)', scriptUrl);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName FileList
class _FileList implements JavaScriptIndexingBehavior, List<File> native "*FileList" {

  /** @domName FileList.length */
  final int length;

  File operator[](int index) => JS("File", "#[#]", this, index);

  void operator[]=(int index, File value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<File> mixins.
  // File is the element type.

  // From Iterable<File>:

  Iterator<File> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<File>(this);
  }

  // From Collection<File>:

  void add(File value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(File value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<File> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(File element) => _Collections.contains(this, element);

  void forEach(void f(File element)) => _Collections.forEach(this, f);

  Collection map(f(File element)) => _Collections.map(this, [], f);

  Collection<File> filter(bool f(File element)) =>
     _Collections.filter(this, <File>[], f);

  bool every(bool f(File element)) => _Collections.every(this, f);

  bool some(bool f(File element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<File>:

  void sort([Comparator<File> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(File element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(File element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  File get last => this[length - 1];

  File removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<File> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [File initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<File> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <File>[]);

  // -- end List<File> mixins.

  /** @domName FileList.item */
  File item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _FileReaderFactoryProvider {
  static FileReader createFileReader() =>
      JS('FileReader', 'new FileReader()' );
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _FileReaderSyncFactoryProvider {
  static FileReaderSync createFileReaderSync() =>
      JS('FileReaderSync', 'new FileReaderSync()' );
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _FormDataFactoryProvider {
  static FormData createFormData([FormElement form = null]) {
    if (form == null) return JS('FormData', 'new FormData()');
    return JS('FormData', 'new FormData(#)', form);
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName GamepadList
class _GamepadList implements JavaScriptIndexingBehavior, List<Gamepad> native "*GamepadList" {

  /** @domName GamepadList.length */
  final int length;

  Gamepad operator[](int index) => JS("Gamepad", "#[#]", this, index);

  void operator[]=(int index, Gamepad value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Gamepad> mixins.
  // Gamepad is the element type.

  // From Iterable<Gamepad>:

  Iterator<Gamepad> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Gamepad>(this);
  }

  // From Collection<Gamepad>:

  void add(Gamepad value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(Gamepad value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<Gamepad> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(Gamepad element) => _Collections.contains(this, element);

  void forEach(void f(Gamepad element)) => _Collections.forEach(this, f);

  Collection map(f(Gamepad element)) => _Collections.map(this, [], f);

  Collection<Gamepad> filter(bool f(Gamepad element)) =>
     _Collections.filter(this, <Gamepad>[], f);

  bool every(bool f(Gamepad element)) => _Collections.every(this, f);

  bool some(bool f(Gamepad element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<Gamepad>:

  void sort([Comparator<Gamepad> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Gamepad element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Gamepad element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  Gamepad get last => this[length - 1];

  Gamepad removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<Gamepad> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [Gamepad initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<Gamepad> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <Gamepad>[]);

  // -- end List<Gamepad> mixins.

  /** @domName GamepadList.item */
  Gamepad item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _HttpRequestFactoryProvider {
  static HttpRequest createHttpRequest() =>
      JS('HttpRequest', 'new XMLHttpRequest()');

  static HttpRequest createHttpRequest_get(String url,
      onSuccess(HttpRequest request)) =>
      _HttpRequestUtils.get(url, onSuccess, false);

  static HttpRequest createHttpRequest_getWithCredentials(String url,
      onSuccess(HttpRequest request)) =>
      _HttpRequestUtils.get(url, onSuccess, true);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _IceCandidateFactoryProvider {
  static IceCandidate createIceCandidate(String label, String candidateLine) =>
      JS('IceCandidate', 'new IceCandidate(#,#)', label, candidateLine);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _MediaControllerFactoryProvider {
  static MediaController createMediaController() =>
      JS('MediaController', 'new MediaController()' );
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _MediaSourceFactoryProvider {
  static MediaSource createMediaSource() =>
      JS('MediaSource', 'new MediaSource()' );
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _MediaStreamFactoryProvider {
  static MediaStream createMediaStream(MediaStreamTrackList audioTracks, MediaStreamTrackList videoTracks) =>
      JS('MediaStream', 'new MediaStream(#,#)', audioTracks, videoTracks);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName MediaStreamList
class _MediaStreamList implements JavaScriptIndexingBehavior, List<MediaStream> native "*MediaStreamList" {

  /** @domName MediaStreamList.length */
  final int length;

  MediaStream operator[](int index) => JS("MediaStream", "#[#]", this, index);

  void operator[]=(int index, MediaStream value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<MediaStream> mixins.
  // MediaStream is the element type.

  // From Iterable<MediaStream>:

  Iterator<MediaStream> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<MediaStream>(this);
  }

  // From Collection<MediaStream>:

  void add(MediaStream value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(MediaStream value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<MediaStream> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(MediaStream element) => _Collections.contains(this, element);

  void forEach(void f(MediaStream element)) => _Collections.forEach(this, f);

  Collection map(f(MediaStream element)) => _Collections.map(this, [], f);

  Collection<MediaStream> filter(bool f(MediaStream element)) =>
     _Collections.filter(this, <MediaStream>[], f);

  bool every(bool f(MediaStream element)) => _Collections.every(this, f);

  bool some(bool f(MediaStream element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<MediaStream>:

  void sort([Comparator<MediaStream> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(MediaStream element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(MediaStream element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  MediaStream get last => this[length - 1];

  MediaStream removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<MediaStream> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [MediaStream initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<MediaStream> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <MediaStream>[]);

  // -- end List<MediaStream> mixins.

  /** @domName MediaStreamList.item */
  MediaStream item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _MessageChannelFactoryProvider {
  static MessageChannel createMessageChannel() =>
      JS('MessageChannel', 'new MessageChannel()' );
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _MutationObserverFactoryProvider {
  static MutationObserver createMutationObserver(MutationCallback callback) {

    // This is a hack to cause MutationRecord to appear to be instantiated.
    //
    // MutationCallback has a parameter type List<MutationRecord>.  From this we
    // infer a list is created in the browser, but not the element type, because
    // other native fields and methods return plain List which is too general
    // and would imply creating anything.  This statement is a work-around.
    JS('MutationRecord','0');

    return _createMutationObserver(callback);
  }

  static MutationObserver _createMutationObserver(MutationCallback callback) native '''
    var constructor =
        window.MutationObserver || window.WebKitMutationObserver ||
        window.MozMutationObserver;
    return new constructor(callback);
  ''';

  // TODO(sra): Dart2js inserts a conversion when a Dart function (i.e. an
  // object with a call method) is passed to a native method.  This is so the
  // native code sees a JavaScript function.
  //
  // This does not happen when a function is 'passed' to a JS-form so it is not
  // possible to rewrite the above code to, e.g. (simplified):
  //
  // static createMutationObserver(MutationCallback callback) =>
  //    JS('var', 'new (window.MutationObserver)(#)', callback);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _NotificationFactoryProvider {
  static Notification createNotification(String title, [Map options]) =>
      JS('Notification', 'new Notification(#,#)', title, options);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _OptionElementFactoryProvider {
  static OptionElement createOptionElement(
      [String data, String value, bool defaultSelected, bool selected]) {
    if (data == null) {
      return JS('OptionElement', 'new Option()');
    }
    if (value == null) {
      return JS('OptionElement', 'new Option(#)', data);
    }
    if (defaultSelected == null) {
      return JS('OptionElement', 'new Option(#,#)', data, value);
    }
    if (selected == null) {
      return JS('OptionElement', 'new Option(#,#,#)',
                data, value, defaultSelected);
    }
    return JS('OptionElement', 'new Option(#,#,#,#)',
              data, value, defaultSelected, selected);
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _PeerConnection00FactoryProvider {
  static PeerConnection00 createPeerConnection00(String serverConfiguration, IceCallback iceCallback) =>
      JS('PeerConnection00', 'new PeerConnection00(#,#)', serverConfiguration, iceCallback);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _RTCIceCandidateFactoryProvider {
  static RTCIceCandidate createRTCIceCandidate(Map dictionary) =>
      JS('RTCIceCandidate', 'new RTCIceCandidate(#)', dictionary);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _RTCPeerConnectionFactoryProvider {
  static RTCPeerConnection createRTCPeerConnection(Map rtcIceServers, [Map mediaConstraints]) =>
      JS('RTCPeerConnection', 'new RTCPeerConnection(#,#)', rtcIceServers, mediaConstraints);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _RTCSessionDescriptionFactoryProvider {
  static RTCSessionDescription createRTCSessionDescription(Map dictionary) =>
      JS('RTCSessionDescription', 'new RTCSessionDescription(#)', dictionary);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _SessionDescriptionFactoryProvider {
  static SessionDescription createSessionDescription(String sdp) =>
      JS('SessionDescription', 'new SessionDescription(#)', sdp);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _ShadowRootFactoryProvider {
  static ShadowRoot createShadowRoot(Element host) =>
      JS('ShadowRoot',
         'new (window.ShadowRoot || window.WebKitShadowRoot)(#)', host);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _SharedWorkerFactoryProvider {
  static SharedWorker createSharedWorker(String scriptURL, [String name]) {
    if (name == null) return JS('SharedWorker', 'new SharedWorker(#)', scriptURL);
    return JS('SharedWorker', 'new SharedWorker(#,#)', scriptURL, name);
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _SpeechGrammarFactoryProvider {
  static SpeechGrammar createSpeechGrammar() =>
      JS('SpeechGrammar', 'new SpeechGrammar()' );
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _SpeechGrammarListFactoryProvider {
  static SpeechGrammarList createSpeechGrammarList() =>
      JS('SpeechGrammarList', 'new SpeechGrammarList()' );
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SpeechInputResultList
class _SpeechInputResultList implements JavaScriptIndexingBehavior, List<SpeechInputResult> native "*SpeechInputResultList" {

  /** @domName SpeechInputResultList.length */
  final int length;

  SpeechInputResult operator[](int index) => JS("SpeechInputResult", "#[#]", this, index);

  void operator[]=(int index, SpeechInputResult value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<SpeechInputResult> mixins.
  // SpeechInputResult is the element type.

  // From Iterable<SpeechInputResult>:

  Iterator<SpeechInputResult> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<SpeechInputResult>(this);
  }

  // From Collection<SpeechInputResult>:

  void add(SpeechInputResult value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(SpeechInputResult value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<SpeechInputResult> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(SpeechInputResult element) => _Collections.contains(this, element);

  void forEach(void f(SpeechInputResult element)) => _Collections.forEach(this, f);

  Collection map(f(SpeechInputResult element)) => _Collections.map(this, [], f);

  Collection<SpeechInputResult> filter(bool f(SpeechInputResult element)) =>
     _Collections.filter(this, <SpeechInputResult>[], f);

  bool every(bool f(SpeechInputResult element)) => _Collections.every(this, f);

  bool some(bool f(SpeechInputResult element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<SpeechInputResult>:

  void sort([Comparator<SpeechInputResult> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(SpeechInputResult element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(SpeechInputResult element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  SpeechInputResult get last => this[length - 1];

  SpeechInputResult removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<SpeechInputResult> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [SpeechInputResult initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<SpeechInputResult> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <SpeechInputResult>[]);

  // -- end List<SpeechInputResult> mixins.

  /** @domName SpeechInputResultList.item */
  SpeechInputResult item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _SpeechRecognitionFactoryProvider {
  static SpeechRecognition createSpeechRecognition() =>
      JS('SpeechRecognition', 'new SpeechRecognition()' );
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName SpeechRecognitionResultList
class _SpeechRecognitionResultList implements JavaScriptIndexingBehavior, List<SpeechRecognitionResult> native "*SpeechRecognitionResultList" {

  /** @domName SpeechRecognitionResultList.length */
  final int length;

  SpeechRecognitionResult operator[](int index) => JS("SpeechRecognitionResult", "#[#]", this, index);

  void operator[]=(int index, SpeechRecognitionResult value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<SpeechRecognitionResult> mixins.
  // SpeechRecognitionResult is the element type.

  // From Iterable<SpeechRecognitionResult>:

  Iterator<SpeechRecognitionResult> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<SpeechRecognitionResult>(this);
  }

  // From Collection<SpeechRecognitionResult>:

  void add(SpeechRecognitionResult value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(SpeechRecognitionResult value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<SpeechRecognitionResult> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(SpeechRecognitionResult element) => _Collections.contains(this, element);

  void forEach(void f(SpeechRecognitionResult element)) => _Collections.forEach(this, f);

  Collection map(f(SpeechRecognitionResult element)) => _Collections.map(this, [], f);

  Collection<SpeechRecognitionResult> filter(bool f(SpeechRecognitionResult element)) =>
     _Collections.filter(this, <SpeechRecognitionResult>[], f);

  bool every(bool f(SpeechRecognitionResult element)) => _Collections.every(this, f);

  bool some(bool f(SpeechRecognitionResult element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<SpeechRecognitionResult>:

  void sort([Comparator<SpeechRecognitionResult> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(SpeechRecognitionResult element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(SpeechRecognitionResult element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  SpeechRecognitionResult get last => this[length - 1];

  SpeechRecognitionResult removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<SpeechRecognitionResult> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [SpeechRecognitionResult initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<SpeechRecognitionResult> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <SpeechRecognitionResult>[]);

  // -- end List<SpeechRecognitionResult> mixins.

  /** @domName SpeechRecognitionResultList.item */
  SpeechRecognitionResult item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName StyleSheetList
class _StyleSheetList implements JavaScriptIndexingBehavior, List<StyleSheet> native "*StyleSheetList" {

  /** @domName StyleSheetList.length */
  final int length;

  StyleSheet operator[](int index) => JS("StyleSheet", "#[#]", this, index);

  void operator[]=(int index, StyleSheet value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<StyleSheet> mixins.
  // StyleSheet is the element type.

  // From Iterable<StyleSheet>:

  Iterator<StyleSheet> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<StyleSheet>(this);
  }

  // From Collection<StyleSheet>:

  void add(StyleSheet value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(StyleSheet value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<StyleSheet> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(StyleSheet element) => _Collections.contains(this, element);

  void forEach(void f(StyleSheet element)) => _Collections.forEach(this, f);

  Collection map(f(StyleSheet element)) => _Collections.map(this, [], f);

  Collection<StyleSheet> filter(bool f(StyleSheet element)) =>
     _Collections.filter(this, <StyleSheet>[], f);

  bool every(bool f(StyleSheet element)) => _Collections.every(this, f);

  bool some(bool f(StyleSheet element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<StyleSheet>:

  void sort([Comparator<StyleSheet> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(StyleSheet element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(StyleSheet element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  StyleSheet get last => this[length - 1];

  StyleSheet removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<StyleSheet> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [StyleSheet initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<StyleSheet> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <StyleSheet>[]);

  // -- end List<StyleSheet> mixins.

  /** @domName StyleSheetList.item */
  StyleSheet item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _TextTrackCueFactoryProvider {
  static TextTrackCue createTextTrackCue(
      String id, num startTime, num endTime, String text,
      [String settings, bool pauseOnExit]) {
        if (settings == null) {
          return JS('TextTrackCue',
                    'new TextTrackCue(#,#,#,#)',
                    id, startTime, endTime, text);
        }
        if (pauseOnExit == null) {
          return JS('TextTrackCue',
                    'new TextTrackCue(#,#,#,#,#)',
                    id, startTime, endTime, text, settings);
        }
        return JS('TextTrackCue',
                  'new TextTrackCue(#,#,#,#,#,#)',
                  id, startTime, endTime, text, settings, pauseOnExit);
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName WebKitAnimationList
class _WebKitAnimationList implements JavaScriptIndexingBehavior, List<Animation> native "*WebKitAnimationList" {

  /** @domName WebKitAnimationList.length */
  final int length;

  Animation operator[](int index) => JS("Animation", "#[#]", this, index);

  void operator[]=(int index, Animation value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Animation> mixins.
  // Animation is the element type.

  // From Iterable<Animation>:

  Iterator<Animation> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Animation>(this);
  }

  // From Collection<Animation>:

  void add(Animation value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(Animation value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Collection<Animation> collection) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  bool contains(Animation element) => _Collections.contains(this, element);

  void forEach(void f(Animation element)) => _Collections.forEach(this, f);

  Collection map(f(Animation element)) => _Collections.map(this, [], f);

  Collection<Animation> filter(bool f(Animation element)) =>
     _Collections.filter(this, <Animation>[], f);

  bool every(bool f(Animation element)) => _Collections.every(this, f);

  bool some(bool f(Animation element)) => _Collections.some(this, f);

  bool get isEmpty => this.length == 0;

  // From List<Animation>:

  void sort([Comparator<Animation> compare = Comparable.compare]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Animation element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Animation element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  Animation get last => this[length - 1];

  Animation removeLast() {
    throw new UnsupportedError("Cannot removeLast on immutable List.");
  }

  void setRange(int start, int rangeLength, List<Animation> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [Animation initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<Animation> getRange(int start, int rangeLength) =>
      _Lists.getRange(this, start, rangeLength, <Animation>[]);

  // -- end List<Animation> mixins.

  /** @domName WebKitAnimationList.item */
  Animation item(int index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _WorkerFactoryProvider {
  static Worker createWorker(String scriptUrl) =>
      JS('Worker', 'new Worker(#)', scriptUrl);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _XMLSerializerFactoryProvider {
  static XMLSerializer createXMLSerializer() =>
      JS('XMLSerializer', 'new XMLSerializer()' );
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _XPathEvaluatorFactoryProvider {
  static XPathEvaluator createXPathEvaluator() =>
      JS('XPathEvaluator', 'new XPathEvaluator()' );
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _XSLTProcessorFactoryProvider {
  static XSLTProcessor createXSLTProcessor() =>
      JS('XSLTProcessor', 'new XSLTProcessor()' );
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


abstract class Window {
  // Fields.
  Location get location;
  History get history;

  bool get closed;
  Window get opener;
  Window get parent;
  Window get top;

  // Methods.
  void focus();
  void blur();
  void close();
  void postMessage(var message, String targetOrigin, [List messagePorts = null]);
}

abstract class Location {
  void set href(String val);
}

abstract class History {
  void back();
  void forward();
  void go(int distance);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class CssClassSet implements Set<String> {

  String toString() {
    return Strings.join(new List.from(readClasses()), ' ');
  }

  /**
   * Adds the class [token] to the element if it is not on it, removes it if it
   * is.
   */
  bool toggle(String value) {
    Set<String> s = readClasses();
    bool result = false;
    if (s.contains(value)) {
      s.remove(value);
    } else {
      s.add(value);
      result = true;
    }
    writeClasses(s);
    return result;
  }

  /**
   * Returns [:true:] if classes cannot be added or removed from this
   * [:CssClassSet:].
   */
  bool get frozen => false;

  // interface Iterable - BEGIN
  Iterator<String> iterator() => readClasses().iterator();
  // interface Iterable - END

  // interface Collection - BEGIN
  void forEach(void f(String element)) {
    readClasses().forEach(f);
  }

  Collection map(f(String element)) => readClasses().map(f);

  Collection<String> filter(bool f(String element)) => readClasses().filter(f);

  bool every(bool f(String element)) => readClasses().every(f);

  bool some(bool f(String element)) => readClasses().some(f);

  bool get isEmpty => readClasses().isEmpty;

  int get length =>readClasses().length;
  // interface Collection - END

  // interface Set - BEGIN
  bool contains(String value) => readClasses().contains(value);

  void add(String value) {
    // TODO - figure out if we need to do any validation here
    // or if the browser natively does enough
    _modify((s) => s.add(value));
  }

  bool remove(String value) {
    Set<String> s = readClasses();
    bool result = s.remove(value);
    writeClasses(s);
    return result;
  }

  void addAll(Collection<String> collection) {
    // TODO - see comment above about validation
    _modify((s) => s.addAll(collection));
  }

  void removeAll(Collection<String> collection) {
    _modify((s) => s.removeAll(collection));
  }

  bool isSubsetOf(Collection<String> collection) =>
    readClasses().isSubsetOf(collection);

  bool containsAll(Collection<String> collection) =>
    readClasses().containsAll(collection);

  Set<String> intersection(Collection<String> other) =>
    readClasses().intersection(other);

  void clear() {
    _modify((s) => s.clear());
  }
  // interface Set - END

  /**
   * Helper method used to modify the set of css classes on this element.
   *
   *   f - callback with:
   *      s - a Set of all the css class name currently on this element.
   *
   *   After f returns, the modified set is written to the
   *       className property of this element.
   */
  void _modify( f(Set<String> s)) {
    Set<String> s = readClasses();
    f(s);
    writeClasses(s);
  }

  /**
   * Read the class names from the Element class property,
   * and put them into a set (duplicates are discarded).
   * This is intended to be overridden by specific implementations.
   */
  Set<String> readClasses();

  /**
   * Join all the elements of a set into one string and write
   * back to the element.
   * This is intended to be overridden by specific implementations.
   */
  void writeClasses(Set<String> s);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * Utils for device detection.
 */
class _Device {
  /**
   * Gets the browser's user agent. Using this function allows tests to inject
   * the user agent.
   * Returns the user agent.
   */
  static String get userAgent => window.navigator.userAgent;

  /**
   * Determines if the current device is running Opera.
   */
  static bool get isOpera => userAgent.contains("Opera", 0);

  /**
   * Determines if the current device is running Internet Explorer.
   */
  static bool get isIE => !isOpera && userAgent.contains("MSIE", 0);

  /**
   * Determines if the current device is running Firefox.
   */
  static bool get isFirefox => userAgent.contains("Firefox", 0);

  /**
   * Determines if the current device is running WebKit.
   */
  static bool get isWebKit => !isOpera && userAgent.contains("WebKit", 0);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


typedef void EventListener(Event event);
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class FilteredElementList implements List {
  final Node _node;
  final List<Node> _childNodes;

  FilteredElementList(Node node): _childNodes = node.nodes, _node = node;

  // We can't memoize this, since it's possible that children will be messed
  // with externally to this class.
  //
  // TODO(nweiz): Do we really need to copy the list to make the types work out?
  List<Element> get _filtered =>
    new List.from(_childNodes.filter((n) => n is Element));

  void forEach(void f(Element element)) {
    _filtered.forEach(f);
  }

  void operator []=(int index, Element value) {
    this[index].replaceWith(value);
  }

  void set length(int newLength) {
    final len = this.length;
    if (newLength >= len) {
      return;
    } else if (newLength < 0) {
      throw new ArgumentError("Invalid list length");
    }

    removeRange(newLength - 1, len - newLength);
  }

  void add(Element value) {
    _childNodes.add(value);
  }

  void addAll(Collection<Element> collection) {
    collection.forEach(add);
  }

  void addLast(Element value) {
    add(value);
  }

  bool contains(Element element) {
    return element is Element && _childNodes.contains(element);
  }

  void sort([Comparator<Element> compare = Comparable.compare]) {
    throw new UnsupportedError('TODO(jacobr): should we impl?');
  }

  void setRange(int start, int rangeLength, List from, [int startFrom = 0]) {
    throw new UnimplementedError();
  }

  void removeRange(int start, int rangeLength) {
    _filtered.getRange(start, rangeLength).forEach((el) => el.remove());
  }

  void insertRange(int start, int rangeLength, [initialValue = null]) {
    throw new UnimplementedError();
  }

  void clear() {
    // Currently, ElementList#clear clears even non-element nodes, so we follow
    // that behavior.
    _childNodes.clear();
  }

  Element removeLast() {
    final result = this.last;
    if (result != null) {
      result.remove();
    }
    return result;
  }

  Collection map(f(Element element)) => _filtered.map(f);
  Collection<Element> filter(bool f(Element element)) => _filtered.filter(f);
  bool every(bool f(Element element)) => _filtered.every(f);
  bool some(bool f(Element element)) => _filtered.some(f);
  bool get isEmpty => _filtered.isEmpty;
  int get length => _filtered.length;
  Element operator [](int index) => _filtered[index];
  Iterator<Element> iterator() => _filtered.iterator();
  List<Element> getRange(int start, int rangeLength) =>
    _filtered.getRange(start, rangeLength);
  int indexOf(Element element, [int start = 0]) =>
    _filtered.indexOf(element, start);

  int lastIndexOf(Element element, [int start = null]) {
    if (start == null) start = length - 1;
    return _filtered.lastIndexOf(element, start);
  }

  Element get last => _filtered.last;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * Defines the keycode values for keys that are returned by 
 * KeyboardEvent.keyCode.
 * 
 * Important note: There is substantial divergence in how different browsers
 * handle keycodes and their variants in different locales/keyboard layouts. We
 * provide these constants to help make code processing keys more readable.
 */
abstract class KeyCode {
  // These constant names were borrowed from Closure's Keycode enumeration
  // class.
  // http://closure-library.googlecode.com/svn/docs/closure_goog_events_keycodes.js.source.html  
  static const int WIN_KEY_FF_LINUX = 0;
  static const int MAC_ENTER = 3;
  static const int BACKSPACE = 8;
  static const int TAB = 9;
  /** NUM_CENTER is also NUMLOCK for FF and Safari on Mac. */
  static const int NUM_CENTER = 12;
  static const int ENTER = 13;
  static const int SHIFT = 16;
  static const int CTRL = 17;
  static const int ALT = 18;
  static const int PAUSE = 19;
  static const int CAPS_LOCK = 20;
  static const int ESC = 27;
  static const int SPACE = 32;
  static const int PAGE_UP = 33;
  static const int PAGE_DOWN = 34;
  static const int END = 35;
  static const int HOME = 36;
  static const int LEFT = 37;
  static const int UP = 38;
  static const int RIGHT = 39;
  static const int DOWN = 40;
  static const int NUM_NORTH_EAST = 33;
  static const int NUM_SOUTH_EAST = 34;
  static const int NUM_SOUTH_WEST = 35;
  static const int NUM_NORTH_WEST = 36;
  static const int NUM_WEST = 37;
  static const int NUM_NORTH = 38;
  static const int NUM_EAST = 39;
  static const int NUM_SOUTH = 40;
  static const int PRINT_SCREEN = 44;
  static const int INSERT = 45;
  static const int NUM_INSERT = 45;
  static const int DELETE = 46;
  static const int NUM_DELETE = 46;
  static const int ZERO = 48;
  static const int ONE = 49;
  static const int TWO = 50;
  static const int THREE = 51;
  static const int FOUR = 52;
  static const int FIVE = 53;
  static const int SIX = 54;
  static const int SEVEN = 55;
  static const int EIGHT = 56;
  static const int NINE = 57;
  static const int FF_SEMICOLON = 59;
  static const int FF_EQUALS = 61;
  /**
   * CAUTION: The question mark is for US-keyboard layouts. It varies
   * for other locales and keyboard layouts.
   */
  static const int QUESTION_MARK = 63;
  static const int A = 65;
  static const int B = 66;
  static const int C = 67;
  static const int D = 68;
  static const int E = 69;
  static const int F = 70;
  static const int G = 71;
  static const int H = 72;
  static const int I = 73;
  static const int J = 74;
  static const int K = 75;
  static const int L = 76;
  static const int M = 77;
  static const int N = 78;
  static const int O = 79;
  static const int P = 80;
  static const int Q = 81;
  static const int R = 82;
  static const int S = 83;
  static const int T = 84;
  static const int U = 85;
  static const int V = 86;
  static const int W = 87;
  static const int X = 88;
  static const int Y = 89;
  static const int Z = 90;
  static const int META = 91;
  static const int WIN_KEY_LEFT = 91;
  static const int WIN_KEY_RIGHT = 92;
  static const int CONTEXT_MENU = 93;
  static const int NUM_ZERO = 96;
  static const int NUM_ONE = 97;
  static const int NUM_TWO = 98;
  static const int NUM_THREE = 99;
  static const int NUM_FOUR = 100;
  static const int NUM_FIVE = 101;
  static const int NUM_SIX = 102;
  static const int NUM_SEVEN = 103;
  static const int NUM_EIGHT = 104;
  static const int NUM_NINE = 105;
  static const int NUM_MULTIPLY = 106;
  static const int NUM_PLUS = 107;
  static const int NUM_MINUS = 109;
  static const int NUM_PERIOD = 110;
  static const int NUM_DIVISION = 111;
  static const int F1 = 112;
  static const int F2 = 113;
  static const int F3 = 114;
  static const int F4 = 115;
  static const int F5 = 116;
  static const int F6 = 117;
  static const int F7 = 118;
  static const int F8 = 119;
  static const int F9 = 120;
  static const int F10 = 121;
  static const int F11 = 122;
  static const int F12 = 123;
  static const int NUMLOCK = 144;
  static const int SCROLL_LOCK = 145;

  // OS-specific media keys like volume controls and browser controls.
  static const int FIRST_MEDIA_KEY = 166;
  static const int LAST_MEDIA_KEY = 183;

  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int SEMICOLON = 186;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int DASH = 189;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int EQUALS = 187;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int COMMA = 188;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int PERIOD = 190;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int SLASH = 191;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int APOSTROPHE = 192;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int TILDE = 192;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int SINGLE_QUOTE = 222;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int OPEN_SQUARE_BRACKET = 219;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int BACKSLASH = 220;
  /**
   * CAUTION: This constant requires localization for other locales and keyboard
   * layouts.
   */
  static const int CLOSE_SQUARE_BRACKET = 221;
  static const int WIN_KEY = 224;
  static const int MAC_FF_META = 224;
  static const int WIN_IME = 229;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * Defines the standard key locations returned by
 * KeyboardEvent.getKeyLocation.
 */
abstract class KeyLocation {

  /**
   * The event key is not distinguished as the left or right version
   * of the key, and did not originate from the numeric keypad (or did not
   * originate with a virtual key corresponding to the numeric keypad).
   */
  static const int STANDARD = 0;

  /**
   * The event key is in the left key location.
   */
  static const int LEFT = 1;

  /**
   * The event key is in the right key location.
   */
  static const int RIGHT = 2;

  /**
   * The event key originated on the numeric keypad or with a virtual key
   * corresponding to the numeric keypad.
   */
  static const int NUMPAD = 3;

  /**
   * The event key originated on a mobile device, either on a physical
   * keypad or a virtual keyboard.
   */
  static const int MOBILE = 4;

  /**
   * The event key originated on a game controller or a joystick on a mobile
   * device.
   */
  static const int JOYSTICK = 5;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * Defines the standard keyboard identifier names for keys that are returned
 * by KeyEvent.getKeyboardIdentifier when the key does not have a direct
 * unicode mapping.
 */
abstract class KeyName {

  /** The Accept (Commit, OK) key */
  static const String ACCEPT = "Accept";

  /** The Add key */
  static const String ADD = "Add";

  /** The Again key */
  static const String AGAIN = "Again";

  /** The All Candidates key */
  static const String ALL_CANDIDATES = "AllCandidates";

  /** The Alphanumeric key */
  static const String ALPHANUMERIC = "Alphanumeric";

  /** The Alt (Menu) key */
  static const String ALT = "Alt";

  /** The Alt-Graph key */
  static const String ALT_GRAPH = "AltGraph";

  /** The Application key */
  static const String APPS = "Apps";

  /** The ATTN key */
  static const String ATTN = "Attn";

  /** The Browser Back key */
  static const String BROWSER_BACK = "BrowserBack";

  /** The Browser Favorites key */
  static const String BROWSER_FAVORTIES = "BrowserFavorites";

  /** The Browser Forward key */
  static const String BROWSER_FORWARD = "BrowserForward";

  /** The Browser Home key */
  static const String BROWSER_NAME = "BrowserHome";

  /** The Browser Refresh key */
  static const String BROWSER_REFRESH = "BrowserRefresh";

  /** The Browser Search key */
  static const String BROWSER_SEARCH = "BrowserSearch";

  /** The Browser Stop key */
  static const String BROWSER_STOP = "BrowserStop";

  /** The Camera key */
  static const String CAMERA = "Camera";

  /** The Caps Lock (Capital) key */
  static const String CAPS_LOCK = "CapsLock";

  /** The Clear key */
  static const String CLEAR = "Clear";

  /** The Code Input key */
  static const String CODE_INPUT = "CodeInput";

  /** The Compose key */
  static const String COMPOSE = "Compose";

  /** The Control (Ctrl) key */
  static const String CONTROL = "Control";

  /** The Crsel key */
  static const String CRSEL = "Crsel";

  /** The Convert key */
  static const String CONVERT = "Convert";

  /** The Copy key */
  static const String COPY = "Copy";

  /** The Cut key */
  static const String CUT = "Cut";

  /** The Decimal key */
  static const String DECIMAL = "Decimal";

  /** The Divide key */
  static const String DIVIDE = "Divide";

  /** The Down Arrow key */
  static const String DOWN = "Down";

  /** The diagonal Down-Left Arrow key */
  static const String DOWN_LEFT = "DownLeft";

  /** The diagonal Down-Right Arrow key */
  static const String DOWN_RIGHT = "DownRight";

  /** The Eject key */
  static const String EJECT = "Eject";

  /** The End key */
  static const String END = "End";

  /**
   * The Enter key. Note: This key value must also be used for the Return
   *  (Macintosh numpad) key
   */
  static const String ENTER = "Enter";

  /** The Erase EOF key */
  static const String ERASE_EOF= "EraseEof";

  /** The Execute key */
  static const String EXECUTE = "Execute";

  /** The Exsel key */
  static const String EXSEL = "Exsel";

  /** The Function switch key */
  static const String FN = "Fn";

  /** The F1 key */
  static const String F1 = "F1";

  /** The F2 key */
  static const String F2 = "F2";

  /** The F3 key */
  static const String F3 = "F3";

  /** The F4 key */
  static const String F4 = "F4";

  /** The F5 key */
  static const String F5 = "F5";

  /** The F6 key */
  static const String F6 = "F6";

  /** The F7 key */
  static const String F7 = "F7";

  /** The F8 key */
  static const String F8 = "F8";

  /** The F9 key */
  static const String F9 = "F9";

  /** The F10 key */
  static const String F10 = "F10";

  /** The F11 key */
  static const String F11 = "F11";

  /** The F12 key */
  static const String F12 = "F12";

  /** The F13 key */
  static const String F13 = "F13";

  /** The F14 key */
  static const String F14 = "F14";

  /** The F15 key */
  static const String F15 = "F15";

  /** The F16 key */
  static const String F16 = "F16";

  /** The F17 key */
  static const String F17 = "F17";

  /** The F18 key */
  static const String F18 = "F18";

  /** The F19 key */
  static const String F19 = "F19";

  /** The F20 key */
  static const String F20 = "F20";

  /** The F21 key */
  static const String F21 = "F21";

  /** The F22 key */
  static const String F22 = "F22";

  /** The F23 key */
  static const String F23 = "F23";

  /** The F24 key */
  static const String F24 = "F24";

  /** The Final Mode (Final) key used on some asian keyboards */
  static const String FINAL_MODE = "FinalMode";

  /** The Find key */
  static const String FIND = "Find";

  /** The Full-Width Characters key */
  static const String FULL_WIDTH = "FullWidth";

  /** The Half-Width Characters key */
  static const String HALF_WIDTH = "HalfWidth";

  /** The Hangul (Korean characters) Mode key */
  static const String HANGUL_MODE = "HangulMode";

  /** The Hanja (Korean characters) Mode key */
  static const String HANJA_MODE = "HanjaMode";

  /** The Help key */
  static const String HELP = "Help";

  /** The Hiragana (Japanese Kana characters) key */
  static const String HIRAGANA = "Hiragana";

  /** The Home key */
  static const String HOME = "Home";

  /** The Insert (Ins) key */
  static const String INSERT = "Insert";

  /** The Japanese-Hiragana key */
  static const String JAPANESE_HIRAGANA = "JapaneseHiragana";

  /** The Japanese-Katakana key */
  static const String JAPANESE_KATAKANA = "JapaneseKatakana";

  /** The Japanese-Romaji key */
  static const String JAPANESE_ROMAJI = "JapaneseRomaji";

  /** The Junja Mode key */
  static const String JUNJA_MODE = "JunjaMode";

  /** The Kana Mode (Kana Lock) key */
  static const String KANA_MODE = "KanaMode";

  /**
   * The Kanji (Japanese name for ideographic characters of Chinese origin)
   * Mode key
   */
  static const String KANJI_MODE = "KanjiMode";

  /** The Katakana (Japanese Kana characters) key */
  static const String KATAKANA = "Katakana";

  /** The Start Application One key */
  static const String LAUNCH_APPLICATION_1 = "LaunchApplication1";

  /** The Start Application Two key */
  static const String LAUNCH_APPLICATION_2 = "LaunchApplication2";

  /** The Start Mail key */
  static const String LAUNCH_MAIL = "LaunchMail";

  /** The Left Arrow key */
  static const String LEFT = "Left";

  /** The Menu key */
  static const String MENU = "Menu";

  /**
   * The Meta key. Note: This key value shall be also used for the Apple
   * Command key
   */
  static const String META = "Meta";

  /** The Media Next Track key */
  static const String MEDIA_NEXT_TRACK = "MediaNextTrack";

  /** The Media Play Pause key */
  static const String MEDIA_PAUSE_PLAY = "MediaPlayPause";

  /** The Media Previous Track key */
  static const String MEDIA_PREVIOUS_TRACK = "MediaPreviousTrack";

  /** The Media Stop key */
  static const String MEDIA_STOP = "MediaStop";

  /** The Mode Change key */
  static const String MODE_CHANGE = "ModeChange";

  /** The Next Candidate function key */
  static const String NEXT_CANDIDATE = "NextCandidate";

  /** The Nonconvert (Don't Convert) key */
  static const String NON_CONVERT = "Nonconvert";

  /** The Number Lock key */
  static const String NUM_LOCK = "NumLock";

  /** The Page Down (Next) key */
  static const String PAGE_DOWN = "PageDown";

  /** The Page Up key */
  static const String PAGE_UP = "PageUp";

  /** The Paste key */
  static const String PASTE = "Paste";

  /** The Pause key */
  static const String PAUSE = "Pause";

  /** The Play key */
  static const String PLAY = "Play";

  /**
   * The Power key. Note: Some devices may not expose this key to the
   * operating environment
   */
  static const String POWER = "Power";

  /** The Previous Candidate function key */
  static const String PREVIOUS_CANDIDATE = "PreviousCandidate";

  /** The Print Screen (PrintScrn, SnapShot) key */
  static const String PRINT_SCREEN = "PrintScreen";

  /** The Process key */
  static const String PROCESS = "Process";

  /** The Props key */
  static const String PROPS = "Props";

  /** The Right Arrow key */
  static const String RIGHT = "Right";

  /** The Roman Characters function key */
  static const String ROMAN_CHARACTERS = "RomanCharacters";

  /** The Scroll Lock key */
  static const String SCROLL = "Scroll";

  /** The Select key */
  static const String SELECT = "Select";

  /** The Select Media key */
  static const String SELECT_MEDIA = "SelectMedia";

  /** The Separator key */
  static const String SEPARATOR = "Separator";

  /** The Shift key */
  static const String SHIFT = "Shift";

  /** The Soft1 key */
  static const String SOFT_1 = "Soft1";

  /** The Soft2 key */
  static const String SOFT_2 = "Soft2";

  /** The Soft3 key */
  static const String SOFT_3 = "Soft3";

  /** The Soft4 key */
  static const String SOFT_4 = "Soft4";

  /** The Stop key */
  static const String STOP = "Stop";

  /** The Subtract key */
  static const String SUBTRACT = "Subtract";

  /** The Symbol Lock key */
  static const String SYMBOL_LOCK = "SymbolLock";

  /** The Up Arrow key */
  static const String UP = "Up";

  /** The diagonal Up-Left Arrow key */
  static const String UP_LEFT = "UpLeft";

  /** The diagonal Up-Right Arrow key */
  static const String UP_RIGHT = "UpRight";

  /** The Undo key */
  static const String UNDO = "Undo";

  /** The Volume Down key */
  static const String VOLUME_DOWN = "VolumeDown";

  /** The Volume Mute key */
  static const String VOLUMN_MUTE = "VolumeMute";

  /** The Volume Up key */
  static const String VOLUMN_UP = "VolumeUp";

  /** The Windows Logo key */
  static const String WIN = "Win";

  /** The Zoom key */
  static const String ZOOM = "Zoom";

  /**
   * The Backspace (Back) key. Note: This key value shall be also used for the
   * key labeled 'delete' MacOS keyboards when not modified by the 'Fn' key
   */
  static const String BACKSPACE = "Backspace";

  /** The Horizontal Tabulation (Tab) key */
  static const String TAB = "Tab";

  /** The Cancel key */
  static const String CANCEL = "Cancel";

  /** The Escape (Esc) key */
  static const String ESC = "Esc";

  /** The Space (Spacebar) key:   */
  static const String SPACEBAR = "Spacebar";

  /**
   * The Delete (Del) Key. Note: This key value shall be also used for the key
   * labeled 'delete' MacOS keyboards when modified by the 'Fn' key
   */
  static const String DEL = "Del";

  /** The Combining Grave Accent (Greek Varia, Dead Grave) key */
  static const String DEAD_GRAVE = "DeadGrave";

  /**
   * The Combining Acute Accent (Stress Mark, Greek Oxia, Tonos, Dead Eacute)
   * key
   */
  static const String DEAD_EACUTE = "DeadEacute";

  /** The Combining Circumflex Accent (Hat, Dead Circumflex) key */
  static const String DEAD_CIRCUMFLEX = "DeadCircumflex";

  /** The Combining Tilde (Dead Tilde) key */
  static const String DEAD_TILDE = "DeadTilde";

  /** The Combining Macron (Long, Dead Macron) key */
  static const String DEAD_MACRON = "DeadMacron";

  /** The Combining Breve (Short, Dead Breve) key */
  static const String DEAD_BREVE = "DeadBreve";

  /** The Combining Dot Above (Derivative, Dead Above Dot) key */
  static const String DEAD_ABOVE_DOT = "DeadAboveDot";

  /**
   * The Combining Diaeresis (Double Dot Abode, Umlaut, Greek Dialytika,
   * Double Derivative, Dead Diaeresis) key
   */
  static const String DEAD_UMLAUT = "DeadUmlaut";

  /** The Combining Ring Above (Dead Above Ring) key */
  static const String DEAD_ABOVE_RING = "DeadAboveRing";

  /** The Combining Double Acute Accent (Dead Doubleacute) key */
  static const String DEAD_DOUBLEACUTE = "DeadDoubleacute";

  /** The Combining Caron (Hacek, V Above, Dead Caron) key */
  static const String DEAD_CARON = "DeadCaron";

  /** The Combining Cedilla (Dead Cedilla) key */
  static const String DEAD_CEDILLA = "DeadCedilla";

  /** The Combining Ogonek (Nasal Hook, Dead Ogonek) key */
  static const String DEAD_OGONEK = "DeadOgonek";

  /**
   * The Combining Greek Ypogegrammeni (Greek Non-Spacing Iota Below, Iota
   * Subscript, Dead Iota) key
   */
  static const String DEAD_IOTA = "DeadIota";

  /**
   * The Combining Katakana-Hiragana Voiced Sound Mark (Dead Voiced Sound) key
   */
  static const String DEAD_VOICED_SOUND = "DeadVoicedSound";

  /**
   * The Combining Katakana-Hiragana Semi-Voiced Sound Mark (Dead Semivoiced
   * Sound) key
   */
  static const String DEC_SEMIVOICED_SOUND= "DeadSemivoicedSound";

  /**
   * Key value used when an implementation is unable to identify another key
   * value, due to either hardware, platform, or software constraints
   */
  static const String UNIDENTIFIED = "Unidentified";
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * Contains the set of standard values returned by HTMLDocument.getReadyState.
 */
abstract class ReadyState {
  /**
   * Indicates the document is still loading and parsing.
   */
  static const String LOADING = "loading";

  /**
   * Indicates the document is finished parsing but is still loading
   * subresources.
   */
  static const String INTERACTIVE = "interactive";

  /**
   * Indicates the document and all subresources have been loaded.
   */
  static const String COMPLETE = "complete";
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// TODO(antonm): support not DOM isolates too.
class _Timer implements Timer {
  final canceller;

  _Timer(this.canceller);

  void cancel() { canceller(); }
}

get _timerFactoryClosure => (int milliSeconds, void callback(Timer timer), bool repeating) {
  var maker;
  var canceller;
  if (repeating) {
    maker = window.setInterval;
    canceller = window.clearInterval;
  } else {
    maker = window.setTimeout;
    canceller = window.clearTimeout;
  }
  Timer timer;
  final int id = maker(() { callback(timer); }, milliSeconds);
  timer = new _Timer(() { canceller(id); });
  return timer;
};
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * The [Collections] class implements static methods useful when
 * writing a class that implements [Collection] and the [iterator]
 * method.
 */
class _Collections {
  static bool contains(Iterable<Object> iterable, Object element) {
    for (final e in iterable) {
      if (e == element) return true;
    }
    return false;
  }

  static void forEach(Iterable<Object> iterable, void f(Object o)) {
    for (final e in iterable) {
      f(e);
    }
  }

  static List map(Iterable<Object> source,
                  List<Object> destination,
                  f(o)) {
    for (final e in source) {
      destination.add(f(e));
    }
    return destination;
  }

  static bool some(Iterable<Object> iterable, bool f(Object o)) {
    for (final e in iterable) {
      if (f(e)) return true;
    }
    return false;
  }

  static bool every(Iterable<Object> iterable, bool f(Object o)) {
    for (final e in iterable) {
      if (!f(e)) return false;
    }
    return true;
  }

  static List filter(Iterable<Object> source,
                     List<Object> destination,
                     bool f(o)) {
    for (final e in source) {
      if (f(e)) destination.add(e);
    }
    return destination;
  }

  static bool isEmpty(Iterable<Object> iterable) {
    return !iterable.iterator().hasNext;
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _HttpRequestUtils {

  // Helper for factory HttpRequest.get
  static HttpRequest get(String url,
                            onSuccess(HttpRequest request),
                            bool withCredentials) {
    final request = new HttpRequest();
    request.open('GET', url, true);

    request.withCredentials = withCredentials;

    // Status 0 is for local XHR request.
    request.on.readyStateChange.add((e) {
      if (request.readyState == HttpRequest.DONE &&
          (request.status == 200 || request.status == 0)) {
        onSuccess(request);
      }
    });

    request.send();

    return request;
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


_serialize(var message) {
  return new _JsSerializer().traverse(message);
}

class _JsSerializer extends _Serializer {

  visitSendPortSync(SendPortSync x) {
    if (x is _JsSendPortSync) return visitJsSendPortSync(x);
    if (x is _LocalSendPortSync) return visitLocalSendPortSync(x);
    if (x is _RemoteSendPortSync) return visitRemoteSendPortSync(x);
    throw "Unknown port type $x";
  }

  visitJsSendPortSync(_JsSendPortSync x) {
    return [ 'sendport', 'nativejs', x._id ];
  }

  visitLocalSendPortSync(_LocalSendPortSync x) {
    return [ 'sendport', 'dart',
             ReceivePortSync._isolateId, x._receivePort._portId ];
  }

  visitRemoteSendPortSync(_RemoteSendPortSync x) {
    return [ 'sendport', 'dart',
             x._receivePort._isolateId, x._receivePort._portId ];
  }
}

_deserialize(var message) {
  return new _JsDeserializer().deserialize(message);
}


class _JsDeserializer extends _Deserializer {

  static const _UNSPECIFIED = const Object();

  deserializeSendPort(List x) {
    String tag = x[1];
    switch (tag) {
      case 'nativejs':
        num id = x[2];
        return new _JsSendPortSync(id);
      case 'dart':
        num isolateId = x[2];
        num portId = x[3];
        return ReceivePortSync._lookup(isolateId, portId);
      default:
        throw 'Illegal SendPortSync type: $tag';
    }
  }
}

// The receiver is JS.
class _JsSendPortSync implements SendPortSync {

  num _id;
  _JsSendPortSync(this._id);

  callSync(var message) {
    var serialized = _serialize(message);
    var result = _callPortSync(_id, serialized);
    return _deserialize(result);
  }

}

// TODO(vsm): Differentiate between Dart2Js and Dartium isolates.
// The receiver is a different Dart isolate, compiled to JS.
class _RemoteSendPortSync implements SendPortSync {

  int _isolateId;
  int _portId;
  _RemoteSendPortSync(this._isolateId, this._portId);

  callSync(var message) {
    var serialized = _serialize(message);
    var result = _call(_isolateId, _portId, serialized);
    return _deserialize(result);
  }

  static _call(int isolateId, int portId, var message) {
    var target = 'dart-port-$isolateId-$portId'; 
    // TODO(vsm): Make this re-entrant.
    // TODO(vsm): Set this up set once, on the first call.
    var source = '$target-result';
    var result = null;
    var listener = (Event e) {
      result = JSON.parse(_getPortSyncEventData(e));
    };
    window.on[source].add(listener);
    _dispatchEvent(target, [source, message]);
    window.on[source].remove(listener);
    return result;
  }
}

// The receiver is in the same Dart isolate, compiled to JS.
class _LocalSendPortSync implements SendPortSync {

  ReceivePortSync _receivePort;

  _LocalSendPortSync._internal(this._receivePort);

  callSync(var message) {
    // TODO(vsm): Do a more efficient deep copy.
    var copy = _deserialize(_serialize(message));
    var result = _receivePort._callback(copy);
    return _deserialize(_serialize(result));
  }
}

// TODO(vsm): Move this to dart:isolate.  This will take some
// refactoring as there are dependences here on the DOM.  Users
// interact with this class (or interface if we change it) directly -
// new ReceivePortSync.  I think most of the DOM logic could be
// delayed until the corresponding SendPort is registered on the
// window.

// A Dart ReceivePortSync (tagged 'dart' when serialized) is
// identifiable / resolvable by the combination of its isolateid and
// portid.  When a corresponding SendPort is used within the same
// isolate, the _portMap below can be used to obtain the
// ReceivePortSync directly.  Across isolates (or from JS), an
// EventListener can be used to communicate with the port indirectly.
class ReceivePortSync {

  static Map<int, ReceivePortSync> _portMap;
  static int _portIdCount;
  static int _cachedIsolateId;

  num _portId;
  Function _callback;
  EventListener _listener;

  ReceivePortSync() {
    if (_portIdCount == null) {
      _portIdCount = 0;
      _portMap = new Map<int, ReceivePortSync>();
    }
    _portId = _portIdCount++;
    _portMap[_portId] = this;
  }

  static int get _isolateId {
    // TODO(vsm): Make this coherent with existing isolate code.
    if (_cachedIsolateId == null) {
      _cachedIsolateId = _getNewIsolateId();      
    }
    return _cachedIsolateId;
  }

  static String _getListenerName(isolateId, portId) =>
      'dart-port-$isolateId-$portId'; 
  String get _listenerName => _getListenerName(_isolateId, _portId);

  void receive(callback(var message)) {
    _callback = callback;
    if (_listener == null) {
      _listener = (Event e) {
        var data = JSON.parse(_getPortSyncEventData(e));
        var replyTo = data[0];
        var message = _deserialize(data[1]);
        var result = _callback(message);
        _dispatchEvent(replyTo, _serialize(result));
      };
      window.on[_listenerName].add(_listener);
    }
  }

  void close() {
    _portMap.remove(_portId);
    if (_listener != null) window.on[_listenerName].remove(_listener);
  }

  SendPortSync toSendPort() {
    return new _LocalSendPortSync._internal(this);
  }

  static SendPortSync _lookup(int isolateId, int portId) {
    if (isolateId == _isolateId) {
      return _portMap[portId].toSendPort();
    } else {
      return new _RemoteSendPortSync(isolateId, portId);
    }
  }
}

get _isolateId => ReceivePortSync._isolateId;

void _dispatchEvent(String receiver, var message) {
  var event = new CustomEvent(receiver, false, false, JSON.stringify(message));
  window.$dom_dispatchEvent(event);
}

String _getPortSyncEventData(CustomEvent event) => event.detail;
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


typedef Object ComputeValue();

class _MeasurementRequest<T> {
  final ComputeValue computeValue;
  final Completer<T> completer;
  Object value;
  bool exception = false;
  _MeasurementRequest(this.computeValue, this.completer);
}

typedef void _MeasurementCallback();


/**
 * This class attempts to invoke a callback as soon as the current event stack
 * unwinds, but before the browser repaints.
 */
abstract class _MeasurementScheduler {
  bool _nextMeasurementFrameScheduled = false;
  _MeasurementCallback _callback;

  _MeasurementScheduler(this._callback);

  /**
   * Creates the best possible measurement scheduler for the current platform.
   */
  factory _MeasurementScheduler.best(_MeasurementCallback callback) {
    if (_isMutationObserverSupported()) {
      return new _MutationObserverScheduler(callback);
    }
    return new _PostMessageScheduler(callback);
  }

  /**
   * Schedules a measurement callback if one has not been scheduled already.
   */
  void maybeSchedule() {
    if (this._nextMeasurementFrameScheduled) {
      return;
    }
    this._nextMeasurementFrameScheduled = true;
    this._schedule();
  }

  /**
   * Does the actual scheduling of the callback.
   */
  void _schedule();

  /**
   * Handles the measurement callback and forwards it if necessary.
   */
  void _onCallback() {
    // Ignore spurious messages.
    if (!_nextMeasurementFrameScheduled) {
      return;
    }
    _nextMeasurementFrameScheduled = false;
    this._callback();
  }
}

/**
 * Scheduler which uses window.postMessage to schedule events.
 */
class _PostMessageScheduler extends _MeasurementScheduler {
  const _MEASUREMENT_MESSAGE = "DART-MEASURE";

  _PostMessageScheduler(_MeasurementCallback callback): super(callback) {
      // Messages from other windows do not cause a security risk as
      // all we care about is that _handleMessage is called
      // after the current event loop is unwound and calling the function is
      // a noop when zero requests are pending.
      window.on.message.add(this._handleMessage);
  }

  void _schedule() {
    window.postMessage(_MEASUREMENT_MESSAGE, "*");
  }

  _handleMessage(e) {
    this._onCallback();
  }
}

/**
 * Scheduler which uses a MutationObserver to schedule events.
 */
class _MutationObserverScheduler extends _MeasurementScheduler {
  MutationObserver _observer;
  Element _dummy;

  _MutationObserverScheduler(_MeasurementCallback callback): super(callback) {
    // Mutation events get fired as soon as the current event stack is unwound
    // so we just make a dummy event and listen for that.
    _observer = new MutationObserver(this._handleMutation);
    _dummy = new DivElement();
    _observer.observe(_dummy, attributes: true);
  }

  void _schedule() {
    // Toggle it to trigger the mutation event.
    _dummy.hidden = !_dummy.hidden;
  }

  _handleMutation(List<MutationRecord> mutations, MutationObserver observer) {
    this._onCallback();
  }
}


List<_MeasurementRequest> _pendingRequests;
List<TimeoutHandler> _pendingMeasurementFrameCallbacks;
_MeasurementScheduler _measurementScheduler = null;

void _maybeScheduleMeasurementFrame() {
  if (_measurementScheduler == null) {
    _measurementScheduler =
      new _MeasurementScheduler.best(_completeMeasurementFutures);
  }
  _measurementScheduler.maybeSchedule();
}

/**
 * Registers a [callback] which is called after the next batch of measurements
 * completes. Even if no measurements completed, the callback is triggered
 * when they would have completed to avoid confusing bugs if it happened that
 * no measurements were actually requested.
 */
void _addMeasurementFrameCallback(TimeoutHandler callback) {
  if (_pendingMeasurementFrameCallbacks == null) {
    _pendingMeasurementFrameCallbacks = <TimeoutHandler>[];
    _maybeScheduleMeasurementFrame();
  }
  _pendingMeasurementFrameCallbacks.add(callback);
}

/**
 * Returns a [Future] whose value will be the result of evaluating
 * [computeValue] during the next safe measurement interval.
 * The next safe measurement interval is after the current event loop has
 * unwound but before the browser has rendered the page.
 * It is important that the [computeValue] function only queries the html
 * layout and html in any way.
 */
Future _createMeasurementFuture(ComputeValue computeValue,
                                Completer completer) {
  if (_pendingRequests == null) {
    _pendingRequests = <_MeasurementRequest>[];
    _maybeScheduleMeasurementFrame();
  }
  _pendingRequests.add(new _MeasurementRequest(computeValue, completer));
  return completer.future;
}

/**
 * Complete all pending measurement futures evaluating them in a single batch
 * so that the the browser is guaranteed to avoid multiple layouts.
 */
void _completeMeasurementFutures() {
  // We must compute all new values before fulfilling the futures as
  // the onComplete callbacks for the futures could modify the DOM making
  // subsequent measurement calculations expensive to compute.
  if (_pendingRequests != null) {
    for (_MeasurementRequest request in _pendingRequests) {
      try {
        request.value = request.computeValue();
      } catch (e) {
        request.value = e;
        request.exception = true;
      }
    }
  }

  final completedRequests = _pendingRequests;
  final readyMeasurementFrameCallbacks = _pendingMeasurementFrameCallbacks;
  _pendingRequests = null;
  _pendingMeasurementFrameCallbacks = null;
  if (completedRequests != null) {
    for (_MeasurementRequest request in completedRequests) {
      if (request.exception) {
        request.completer.completeException(request.value);
      } else {
        request.completer.complete(request.value);
      }
    }
  }

  if (readyMeasurementFrameCallbacks != null) {
    for (TimeoutHandler handler in readyMeasurementFrameCallbacks) {
      // TODO(jacobr): wrap each call to a handler in a try-catch block.
      handler();
    }
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for the dart:isolate library.


/********************************************************
  Inserted from lib/isolate/serialization.dart
 ********************************************************/

class _MessageTraverserVisitedMap {

  operator[](var object) => null;
  void operator[]=(var object, var info) { }

  void reset() { }
  void cleanup() { }

}

/** Abstract visitor for dart objects that can be sent as isolate messages. */
class _MessageTraverser {

  _MessageTraverserVisitedMap _visited;
  _MessageTraverser() : _visited = new _MessageTraverserVisitedMap();

  /** Visitor's entry point. */
  traverse(var x) {
    if (isPrimitive(x)) return visitPrimitive(x);
    _visited.reset();
    var result;
    try {
      result = _dispatch(x);
    } finally {
      _visited.cleanup();
    }
    return result;
  }

  _dispatch(var x) {
    if (isPrimitive(x)) return visitPrimitive(x);
    if (x is List) return visitList(x);
    if (x is Map) return visitMap(x);
    if (x is SendPort) return visitSendPort(x);
    if (x is SendPortSync) return visitSendPortSync(x);

    // Overridable fallback.
    return visitObject(x);
  }

  abstract visitPrimitive(x);
  abstract visitList(List x);
  abstract visitMap(Map x);
  abstract visitSendPort(SendPort x);
  abstract visitSendPortSync(SendPortSync x);

  visitObject(Object x) {
    // TODO(floitsch): make this a real exception. (which one)?
    throw "Message serialization: Illegal value $x passed";
  }

  static bool isPrimitive(x) {
    return (x == null) || (x is String) || (x is num) || (x is bool);
  }
}


/** A visitor that recursively copies a message. */
class _Copier extends _MessageTraverser {

  visitPrimitive(x) => x;

  List visitList(List list) {
    List copy = _visited[list];
    if (copy != null) return copy;

    int len = list.length;

    // TODO(floitsch): we loose the generic type of the List.
    copy = new List(len);
    _visited[list] = copy;
    for (int i = 0; i < len; i++) {
      copy[i] = _dispatch(list[i]);
    }
    return copy;
  }

  Map visitMap(Map map) {
    Map copy = _visited[map];
    if (copy != null) return copy;

    // TODO(floitsch): we loose the generic type of the map.
    copy = new Map();
    _visited[map] = copy;
    map.forEach((key, val) {
      copy[_dispatch(key)] = _dispatch(val);
    });
    return copy;
  }

}

/** Visitor that serializes a message as a JSON array. */
class _Serializer extends _MessageTraverser {
  int _nextFreeRefId = 0;

  visitPrimitive(x) => x;

  visitList(List list) {
    int copyId = _visited[list];
    if (copyId != null) return ['ref', copyId];

    int id = _nextFreeRefId++;
    _visited[list] = id;
    var jsArray = _serializeList(list);
    // TODO(floitsch): we are losing the generic type.
    return ['list', id, jsArray];
  }

  visitMap(Map map) {
    int copyId = _visited[map];
    if (copyId != null) return ['ref', copyId];

    int id = _nextFreeRefId++;
    _visited[map] = id;
    var keys = _serializeList(map.keys);
    var values = _serializeList(map.values);
    // TODO(floitsch): we are losing the generic type.
    return ['map', id, keys, values];
  }

  _serializeList(List list) {
    int len = list.length;
    var result = new List(len);
    for (int i = 0; i < len; i++) {
      result[i] = _dispatch(list[i]);
    }
    return result;
  }
}

/** Deserializes arrays created with [_Serializer]. */
class _Deserializer {
  Map<int, dynamic> _deserialized;

  _Deserializer();

  static bool isPrimitive(x) {
    return (x == null) || (x is String) || (x is num) || (x is bool);
  }

  deserialize(x) {
    if (isPrimitive(x)) return x;
    // TODO(floitsch): this should be new HashMap<int, dynamic>()
    _deserialized = new HashMap();
    return _deserializeHelper(x);
  }

  _deserializeHelper(x) {
    if (isPrimitive(x)) return x;
    assert(x is List);
    switch (x[0]) {
      case 'ref': return _deserializeRef(x);
      case 'list': return _deserializeList(x);
      case 'map': return _deserializeMap(x);
      case 'sendport': return deserializeSendPort(x);
      default: return deserializeObject(x);
    }
  }

  _deserializeRef(List x) {
    int id = x[1];
    var result = _deserialized[id];
    assert(result != null);
    return result;
  }

  List _deserializeList(List x) {
    int id = x[1];
    // We rely on the fact that Dart-lists are directly mapped to Js-arrays.
    List dartList = x[2];
    _deserialized[id] = dartList;
    int len = dartList.length;
    for (int i = 0; i < len; i++) {
      dartList[i] = _deserializeHelper(dartList[i]);
    }
    return dartList;
  }

  Map _deserializeMap(List x) {
    Map result = new Map();
    int id = x[1];
    _deserialized[id] = result;
    List keys = x[2];
    List values = x[3];
    int len = keys.length;
    assert(len == values.length);
    for (int i = 0; i < len; i++) {
      var key = _deserializeHelper(keys[i]);
      var value = _deserializeHelper(values[i]);
      result[key] = value;
    }
    return result;
  }

  abstract deserializeSendPort(List x);

  deserializeObject(List x) {
    // TODO(floitsch): Use real exception (which one?).
    throw "Unexpected serialized object";
  }
}

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _CustomEventFactoryProvider {
  static CustomEvent createCustomEvent(String type, [bool canBubble = true,
      bool cancelable = true, Object detail = null]) {
    final CustomEvent e = document.$dom_createEvent("CustomEvent");
    e.$dom_initCustomEvent(type, canBubble, cancelable, detail);
    return e;
  }
}

class _EventFactoryProvider {
  static Event createEvent(String type, [bool canBubble = true,
      bool cancelable = true]) {
    final Event e = document.$dom_createEvent("Event");
    e.$dom_initEvent(type, canBubble, cancelable);
    return e;
  }
}

class _MouseEventFactoryProvider {
  static MouseEvent createMouseEvent(String type, Window view, int detail,
      int screenX, int screenY, int clientX, int clientY, int button,
      [bool canBubble = true, bool cancelable = true, bool ctrlKey = false,
      bool altKey = false, bool shiftKey = false, bool metaKey = false,
      EventTarget relatedTarget = null]) {
    final e = document.$dom_createEvent("MouseEvent");
    e.$dom_initMouseEvent(type, canBubble, cancelable, view, detail,
        screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey,
        button, relatedTarget);
    return e;
  }
}

class _CSSStyleDeclarationFactoryProvider {
  static CSSStyleDeclaration createCSSStyleDeclaration_css(String css) {
    final style = new Element.tag('div').style;
    style.cssText = css;
    return style;
  }

  static CSSStyleDeclaration createCSSStyleDeclaration() {
    return new CSSStyleDeclaration.css('');
  }
}

class _DocumentFragmentFactoryProvider {
  /** @domName Document.createDocumentFragment */
  static DocumentFragment createDocumentFragment() =>
      document.createDocumentFragment();

  static DocumentFragment createDocumentFragment_html(String html) {
    final fragment = new DocumentFragment();
    fragment.innerHTML = html;
    return fragment;
  }

  // TODO(nweiz): enable this when XML is ported.
  // factory DocumentFragment.xml(String xml) {
  //   final fragment = new DocumentFragment();
  //   final e = new XMLElement.tag("xml");
  //   e.innerHTML = xml;
  //
  //   // Copy list first since we don't want liveness during iteration.
  //   final List nodes = new List.from(e.nodes);
  //   fragment.nodes.addAll(nodes);
  //   return fragment;
  // }

  static DocumentFragment createDocumentFragment_svg(String svgContent) {
    final fragment = new DocumentFragment();
    final e = new svg.SVGSVGElement();
    e.innerHTML = svgContent;

    // Copy list first since we don't want liveness during iteration.
    final List nodes = new List.from(e.nodes);
    fragment.nodes.addAll(nodes);
    return fragment;
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Conversions for IDBKey.
//
// Per http://www.w3.org/TR/IndexedDB/#key-construct
//
// "A value is said to be a valid key if it is one of the following types: Array
// JavaScript objects [ECMA-262], DOMString [WEBIDL], Date [ECMA-262] or float
// [WEBIDL]. However Arrays are only valid keys if every item in the array is
// defined and is a valid key (i.e. sparse arrays can not be valid keys) and if
// the Array doesn't directly or indirectly contain itself. Any non-numeric
// properties are ignored, and thus does not affect whether the Array is a valid
// key. Additionally, if the value is of type float, it is only a valid key if
// it is not NaN, and if the value is of type Date it is only a valid key if its
// [[PrimitiveValue]] internal property, as defined by [ECMA-262], is not NaN."

// What is required is to ensure that an Lists in the key are actually
// JavaScript arrays, and any Dates are JavaScript Dates.

// Conversions for Window.  These check if the window is the local
// window, and if it's not, wraps or unwraps it with a secure wrapper.
// We need to test for EventTarget here as well as it's a base type.
// We omit an unwrapper for Window as no methods take a non-local
// window as a parameter.

Window _convertNativeToDart_Window(win) {
  return _DOMWindowCrossFrame._createSafe(win);
}

EventTarget _convertNativeToDart_EventTarget(e) {
  // Assume it's a Window if it contains the setInterval property.  It may be
  // from a different frame - without a patched prototype - so we cannot
  // rely on Dart type checking.
  if (JS('bool', r'"setInterval" in #', e))
    return _DOMWindowCrossFrame._createSafe(e);
  else
    return e;
}

EventTarget _convertDartToNative_EventTarget(e) {
  if (e is _DOMWindowCrossFrame) {
    return e._window;
  } else {
    return e;
  }
}

// Conversions for ImageData
//
// On Firefox, the returned ImageData is a plain object.

class _TypedImageData implements ImageData {
  final Uint8ClampedArray data;
  final int height;
  final int width;

  _TypedImageData(this.data, this.height, this.width);
}

ImageData _convertNativeToDart_ImageData(nativeImageData) {

  // None of the native getters that return ImageData have the type ImageData
  // since that is incorrect for FireFox (which returns a plain Object).  So we
  // need something that tells the compiler that the ImageData class has been
  // instantiated.
  // TODO(sra): Remove this when all the ImageData returning APIs have been
  // annotated as returning the union ImageData + Object.
  JS('ImageData', '0');

  if (nativeImageData is ImageData) return nativeImageData;

  // On Firefox the above test fails because imagedata is a plain object.
  // So we create a _TypedImageData.

  return new _TypedImageData(
      JS('var', '#.data', nativeImageData),
      JS('var', '#.height', nativeImageData),
      JS('var', '#.width', nativeImageData));
}

// We can get rid of this conversion if _TypedImageData implements the fields
// with native names.
_convertDartToNative_ImageData(ImageData imageData) {
  if (imageData is _TypedImageData) {
    return JS('', '{data: #, height: #, width: #}',
        imageData.data, imageData.height, imageData.width);
  }
  return imageData;
}


/// Converts a JavaScript object with properties into a Dart Map.
/// Not suitable for nested objects.
Map _convertNativeToDart_Dictionary(object) {
  if (object == null) return null;
  var dict = {};
  for (final key in JS('List', 'Object.getOwnPropertyNames(#)', object)) {
    dict[key] = JS('var', '#[#]', object, key);
  }
  return dict;
}

/// Converts a flat Dart map into a JavaScript object with properties.
_convertDartToNative_Dictionary(Map dict) {
  if (dict == null) return null;
  var object = JS('var', '{}');
  dict.forEach((String key, value) {
      JS('void', '#[#] = #', object, key, value);
    });
  return object;
}


/**
 * Ensures that the input is a JavaScript Array.
 *
 * Creates a new JavaScript array if necessary, otherwise returns the original.
 */
List _convertDartToNative_StringArray(List<String> input) {
  // TODO(sra).  Implement this.
  return input;
}


// -----------------------------------------------------------------------------

/**
 * Converts a native IDBKey into a Dart object.
 *
 * May return the original input.  May mutate the original input (but will be
 * idempotent if mutation occurs).  It is assumed that this conversion happens
 * on native IDBKeys on all paths that return IDBKeys from native DOM calls.
 *
 * If necessary, JavaScript Dates are converted into Dart Dates.
 */
_convertNativeToDart_IDBKey(nativeKey) {
  containsDate(object) {
    if (_isJavaScriptDate(object)) return true;
    if (object is List) {
      for (int i = 0; i < object.length; i++) {
        if (containsDate(object[i])) return true;
      }
    }
    return false;  // number, string.
  }
  if (containsDate(nativeKey)) {
    throw new UnimplementedError('IDBKey containing Date');
  }
  // TODO: Cache conversion somewhere?
  return nativeKey;
}

/**
 * Converts a Dart object into a valid IDBKey.
 *
 * May return the original input.  Does not mutate input.
 *
 * If necessary, [dartKey] may be copied to ensure all lists are converted into
 * JavaScript Arrays and Dart Dates into JavaScript Dates.
 */
_convertDartToNative_IDBKey(dartKey) {
  // TODO: Implement.
  return dartKey;
}



/// May modify original.  If so, action is idempotent.
_convertNativeToDart_IDBAny(object) {
  return _convertNativeToDart_AcceptStructuredClone(object, mustCopy: false);
}

/// Converts a Dart value into a JavaScript SerializedScriptValue.
_convertDartToNative_SerializedScriptValue(value) {
  return _convertDartToNative_PrepareForStructuredClone(value);
}

/// Since the source object may be viewed via a JavaScript event listener the
/// original may not be modified.
_convertNativeToDart_SerializedScriptValue(object) {
  return _convertNativeToDart_AcceptStructuredClone(object, mustCopy: true);
}


/**
 * Converts a Dart value into a JavaScript SerializedScriptValue.  Returns the
 * original input or a functional 'copy'.  Does not mutate the original.
 *
 * The main transformation is the translation of Dart Maps are converted to
 * JavaScript Objects.
 *
 * The algorithm is essentially a dry-run of the structured clone algorithm
 * described at
 * http://www.whatwg.org/specs/web-apps/current-work/multipage/common-dom-interfaces.html#structured-clone
 * https://www.khronos.org/registry/typedarray/specs/latest/#9
 *
 * Since the result of this function is expected to be passed only to JavaScript
 * operations that perform the structured clone algorithm which does not mutate
 * its output, the result may share structure with the input [value].
 */
_convertDartToNative_PrepareForStructuredClone(value) {

  // TODO(sra): Replace slots with identity hash table.
  var values = [];
  var copies = [];  // initially 'null', 'true' during initial DFS, then a copy.

  int findSlot(value) {
    int length = values.length;
    for (int i = 0; i < length; i++) {
      if (identical(values[i], value)) return i;
    }
    values.add(value);
    copies.add(null);
    return length;
  }
  readSlot(int i) => copies[i];
  writeSlot(int i, x) { copies[i] = x; }
  cleanupSlots() {}  // Will be needed if we mark objects with a property.

  // Returns the input, or a clone of the input.
  walk(e) {
    if (e == null) return e;
    if (e is bool) return e;
    if (e is num) return e;
    if (e is String) return e;
    if (e is Date) {
      // TODO(sra).
      throw new UnimplementedError('structured clone of Date');
    }
    if (e is RegExp) {
      // TODO(sra).
      throw new UnimplementedError('structured clone of RegExp');
    }

    // The browser's internal structured cloning algorithm will copy certain
    // types of object, but it will copy only its own implementations and not
    // just any Dart implementations of the interface.

    // TODO(sra): The JavaScript objects suitable for direct cloning by the
    // structured clone algorithm could be tagged with an private interface.

    if (e is File) return e;
    if (e is Blob) return e;
    if (e is _FileList) return e;

    // TODO(sra): Firefox: How to convert _TypedImageData on the other end?
    if (e is ImageData) return e;
    if (e is ArrayBuffer) return e;

    if (e is ArrayBufferView) return e;

    if (e is Map) {
      var slot = findSlot(e);
      var copy = readSlot(slot);
      if (copy != null) return copy;
      copy = JS('var', '{}');
      writeSlot(slot, copy);
      e.forEach((key, value) {
          JS('void', '#[#] = #', copy, key, walk(value));
        });
      return copy;
    }

    if (e is List) {
      // Since a JavaScript Array is an instance of Dart List it is possible to
      // avoid making a copy of the list if there is no need to copy anything
      // reachable from the array.  We defer creating a new array until a cycle
      // is detected or a subgraph was copied.
      int length = e.length;
      var slot = findSlot(e);
      var copy = readSlot(slot);
      if (copy != null) {
        if (true == copy) {  // Cycle, so commit to making a copy.
          copy = JS('List', 'new Array(#)', length);
          writeSlot(slot, copy);
        }
        return copy;
      }

      int i = 0;

      if (_isJavaScriptArray(e) &&
          // We have to copy immutable lists, otherwise the structured clone
          // algorithm will copy the .immutable$list marker property, making the
          // list immutable when received!
          !_isImmutableJavaScriptArray(e)) {
        writeSlot(slot, true);  // Deferred copy.
        for ( ; i < length; i++) {
          var element = e[i];
          var elementCopy = walk(element);
          if (!identical(elementCopy, element)) {
            copy = readSlot(slot);   // Cyclic reference may have created it.
            if (true == copy) {
              copy = JS('List', 'new Array(#)', length);
              writeSlot(slot, copy);
            }
            for (int j = 0; j < i; j++) {
              copy[j] = e[j];
            }
            copy[i] = elementCopy;
            i++;
            break;
          }
        }
        if (copy == null) {
          copy = e;
          writeSlot(slot, copy);
        }
      } else {
        // Not a JavaScript Array.  We are forced to make a copy.
        copy = JS('List', 'new Array(#)', length);
        writeSlot(slot, copy);
      }

      for ( ; i < length; i++) {
        copy[i] = walk(e[i]);
      }
      return copy;
    }

    throw new UnimplementedError('structured clone of other type');
  }

  var copy = walk(value);
  cleanupSlots();
  return copy;
}

/**
 * Converts a native value into a Dart object.
 *
 * If [mustCopy] is [:false:], may return the original input.  May mutate the
 * original input (but will be idempotent if mutation occurs).  It is assumed
 * that this conversion happens on native serializable script values such values
 * from native DOM calls.
 *
 * [object] is the result of a structured clone operation.
 *
 * If necessary, JavaScript Dates are converted into Dart Dates.
 *
 * If [mustCopy] is [:true:], the entire object is copied and the original input
 * is not mutated.  This should be the case where Dart and JavaScript code can
 * access the value, for example, via multiple event listeners for
 * MessageEvents.  Mutating the object to make it more 'Dart-like' would corrupt
 * the value as seen from the JavaScript listeners.
 */
_convertNativeToDart_AcceptStructuredClone(object, {mustCopy = false}) {

  // TODO(sra): Replace slots with identity hash table that works on non-dart
  // objects.
  var values = [];
  var copies = [];

  int findSlot(value) {
    int length = values.length;
    for (int i = 0; i < length; i++) {
      if (identical(values[i], value)) return i;
    }
    values.add(value);
    copies.add(null);
    return length;
  }
  readSlot(int i) => copies[i];
  writeSlot(int i, x) { copies[i] = x; }

  walk(e) {
    if (e == null) return e;
    if (e is bool) return e;
    if (e is num) return e;
    if (e is String) return e;

    if (_isJavaScriptDate(e)) {
      // TODO(sra).
      throw new UnimplementedError('structured clone of Date');
    }

    if (_isJavaScriptRegExp(e)) {
      // TODO(sra).
      throw new UnimplementedError('structured clone of RegExp');
    }

    if (_isJavaScriptSimpleObject(e)) {
      // TODO(sra): If mustCopy is false, swizzle the prototype for one of a Map
      // implementation that uses the properies as storage.
      var slot = findSlot(e);
      var copy = readSlot(slot);
      if (copy != null) return copy;
      copy = {};

      writeSlot(slot, copy);
      for (final key in JS('List', 'Object.keys(#)', e)) {
        copy[key] = walk(JS('var', '#[#]', e, key));
      }
      return copy;
    }

    if (_isJavaScriptArray(e)) {
      var slot = findSlot(e);
      var copy = readSlot(slot);
      if (copy != null) return copy;

      int length = e.length;
      // Since a JavaScript Array is an instance of Dart List, we can modify it
      // in-place unless we must copy.
      copy = mustCopy ? JS('List', 'new Array(#)', length) : e;
      writeSlot(slot, copy);

      for (int i = 0; i < length; i++) {
        copy[i] = walk(e[i]);
      }
      return copy;
    }

    // Assume anything else is already a valid Dart object, either by having
    // already been processed, or e.g. a clonable native class.
    return e;
  }

  var copy = walk(object);
  return copy;
}


bool _isJavaScriptDate(value) => JS('bool', '# instanceof Date', value);
bool _isJavaScriptRegExp(value) => JS('bool', '# instanceof RegExp', value);
bool _isJavaScriptArray(value) => JS('bool', '# instanceof Array', value);
bool _isJavaScriptSimpleObject(value) =>
    JS('bool', 'Object.getPrototypeOf(#) === Object.prototype', value);
bool _isImmutableJavaScriptArray(value) =>
    JS('bool', r'!!(#.immutable$list)', value);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(vsm): Unify with Dartium version.
class _DOMWindowCrossFrame implements Window {
  // Private window.  Note, this is a window in another frame, so it
  // cannot be typed as "Window" as its prototype is not patched
  // properly.  Its fields and methods can only be accessed via JavaScript.
  var _window;

  // Fields.
  History get history =>
    _HistoryCrossFrame._createSafe(JS('History', '#.history', _window));
  Location get location =>
    _LocationCrossFrame._createSafe(JS('Location', '#.location', _window));

  // TODO(vsm): Add frames to navigate subframes.  See 2312.

  bool get closed => JS('bool', '#.closed', _window);

  Window get opener => _createSafe(JS('Window', '#.opener', _window));

  Window get parent => _createSafe(JS('Window', '#.parent', _window));

  Window get top => _createSafe(JS('Window', '#.top', _window));

  // Methods.
  void focus() => JS('void', '#.focus()', _window);

  void blur() => JS('void', '#.blur()', _window);

  void close() => JS('void', '#.close()', _window);

  void postMessage(var message, String targetOrigin, [List messagePorts = null]) {
    if (messagePorts == null) {
      JS('void', '#.postMessage(#,#)', _window, message, targetOrigin);
    } else {
      JS('void', '#.postMessage(#,#,#)', _window, message, targetOrigin, messagePorts);
    }
  }

  // Implementation support.
  _DOMWindowCrossFrame(this._window);

  static Window _createSafe(w) {
    if (identical(w, window)) {
      return w;
    } else {
      // TODO(vsm): Cache or implement equality.
      return new _DOMWindowCrossFrame(w);
    }
  }
}

class _LocationCrossFrame implements Location {
  // Private location.  Note, this is a location object in another frame, so it
  // cannot be typed as "Location" as its prototype is not patched
  // properly.  Its fields and methods can only be accessed via JavaScript.
  var _location;

  void set href(String val) => _setHref(_location, val);
  static void _setHref(location, val) {
    JS('void', '#.href = #', location, val);
  }

  // Implementation support.
  _LocationCrossFrame(this._location);

  static Location _createSafe(location) {
    if (identical(location, window.location)) {
      return location;
    } else {
      // TODO(vsm): Cache or implement equality.
      return new _LocationCrossFrame(location);
    }
  }
}

class _HistoryCrossFrame implements History {
  // Private history.  Note, this is a history object in another frame, so it
  // cannot be typed as "History" as its prototype is not patched
  // properly.  Its fields and methods can only be accessed via JavaScript.
  var _history;

  void back() => JS('void', '#.back()', _history);

  void forward() => JS('void', '#.forward()', _history);

  void go(int distance) => JS('void', '#.go(#)', _history, distance);

  // Implementation support.
  _HistoryCrossFrame(this._history);

  static History _createSafe(h) {
    if (identical(h, window.history)) {
      return h;
    } else {
      // TODO(vsm): Cache or implement equality.
      return new _HistoryCrossFrame(h);
    }
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _AudioContextFactoryProvider {

  static AudioContext createAudioContext() {
    return JS('AudioContext',
              'new (window.AudioContext || window.webkitAudioContext)()');
  }
}

class _PointFactoryProvider {
  static Point createPoint(num x, num y) =>
      JS('Point', 'new WebKitPoint(#, #)', x, y);
}

class _WebSocketFactoryProvider {
  static WebSocket createWebSocket(String url) =>
      JS('WebSocket', 'new WebSocket(#)', url);
}

class _TextFactoryProvider {
  static Text createText(String data) =>
      JS('Text', 'document.createTextNode(#)', data);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _IDBKeyRangeFactoryProvider {

  static IDBKeyRange createIDBKeyRange_only(/*IDBKey*/ value) =>
      _only(_class(), _translateKey(value));

  static IDBKeyRange createIDBKeyRange_lowerBound(
      /*IDBKey*/ bound, [bool open = false]) =>
      _lowerBound(_class(), _translateKey(bound), open);

  static IDBKeyRange createIDBKeyRange_upperBound(
      /*IDBKey*/ bound, [bool open = false]) =>
      _upperBound(_class(), _translateKey(bound), open);

  static IDBKeyRange createIDBKeyRange_bound(/*IDBKey*/ lower, /*IDBKey*/ upper,
      [bool lowerOpen = false, bool upperOpen = false]) =>
      _bound(_class(), _translateKey(lower), _translateKey(upper),
             lowerOpen, upperOpen);

  static var _cachedClass;

  static _class() {
    if (_cachedClass != null) return _cachedClass;
    return _cachedClass = _uncachedClass();
  }

  static _uncachedClass() =>
    JS('var',
       '''window.webkitIDBKeyRange || window.mozIDBKeyRange ||
          window.msIDBKeyRange || window.IDBKeyRange''');

  static _translateKey(idbkey) => idbkey;  // TODO: fixme.

  static IDBKeyRange _only(cls, value) =>
       JS('IDBKeyRange', '#.only(#)', cls, value);

  static IDBKeyRange _lowerBound(cls, bound, open) =>
       JS('IDBKeyRange', '#.lowerBound(#, #)', cls, bound, open);

  static IDBKeyRange _upperBound(cls, bound, open) =>
       JS('IDBKeyRange', '#.upperBound(#, #)', cls, bound, open);

  static IDBKeyRange _bound(cls, lower, upper, lowerOpen, upperOpen) =>
       JS('IDBKeyRange', '#.bound(#, #, #, #)',
          cls, lower, upper, lowerOpen, upperOpen);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// On Firefox 11, the object obtained from 'window.location' is very strange.
// It can't be monkey-patched and seems immune to putting methods on
// Object.prototype.  We are forced to wrap the object.

class _LocationWrapper implements LocalLocation {

  final _ptr;  // Opaque reference to real location.

  _LocationWrapper(this._ptr);

  // TODO(sra): Replace all the _set and _get calls with 'JS' forms.

  // final List<String> ancestorOrigins;
  List<String> get ancestorOrigins => _get(_ptr, 'ancestorOrigins');

  // String hash;
  String get hash => _get(_ptr, 'hash');
  void set hash(String value) => _set(_ptr, 'hash', value);

  // String host;
  String get host => _get(_ptr, 'host');
  void set host(String value) => _set(_ptr, 'host', value);

  // String hostname;
  String get hostname => _get(_ptr, 'hostname');
  void set hostname(String value) => _set(_ptr, 'hostname', value);

  // String href;
  String get href => _get(_ptr, 'href');
  void set href(String value) => _set(_ptr, 'href', value);

  // final String origin;
  String get origin => _get(_ptr, 'origin');

  // String pathname;
  String get pathname => _get(_ptr, 'pathname');
  void set pathname(String value) => _set(_ptr, 'pathname', value);

  // String port;
  String get port => _get(_ptr, 'port');
  void set port(String value) => _set(_ptr, 'port', value);

  // String protocol;
  String get protocol => _get(_ptr, 'protocol');
  void set protocol(String value) => _set(_ptr, 'protocol', value);

  // String search;
  String get search => _get(_ptr, 'search');
  void set search(String value) => _set(_ptr, 'search', value);


  void assign(String url) => JS('void', '#.assign(#)', _ptr, url);

  void reload() => JS('void', '#.reload()', _ptr);

  void replace(String url) => JS('void', '#.replace(#)', _ptr, url);

  String toString() => JS('String', '#.toString()', _ptr);


  static _get(p, m) => JS('var', '#[#]', p, m);
  static _set(p, m, v) => JS('void', '#[#] = #', p, m, v);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Checks to see if the mutation observer API is supported on the current
 * platform.
 */
bool _isMutationObserverSupported() =>
  JS('bool', '!!(window.MutationObserver || window.WebKitMutationObserver)');
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _TypedArrayFactoryProvider {

  static Float32Array createFloat32Array(int length) => _F32(length);
  static Float32Array createFloat32Array_fromList(List<num> list) =>
      _F32(ensureNative(list));
  static Float32Array createFloat32Array_fromBuffer(ArrayBuffer buffer,
                                  [int byteOffset = 0, int length]) {
    if (length == null) return _F32_2(buffer, byteOffset);
    return _F32_3(buffer, byteOffset, length);
  }

  static Float64Array createFloat64Array(int length) => _F64(length);
  static Float64Array createFloat64Array_fromList(List<num> list) =>
      _F64(ensureNative(list));
  static Float64Array createFloat64Array_fromBuffer(ArrayBuffer buffer,
      [int byteOffset = 0, int length]) {
    if (length == null) return _F64_2(buffer, byteOffset);
    return _F64_3(buffer, byteOffset, length);
  }

  static Int8Array createInt8Array(int length) => _I8(length);
  static Int8Array createInt8Array_fromList(List<num> list) =>
      _I8(ensureNative(list));
  static Int8Array createInt8Array_fromBuffer(ArrayBuffer buffer,
      [int byteOffset = 0, int length]) {
    if (length == null) return _I8_2(buffer, byteOffset);
    return _I8_3(buffer, byteOffset, length);
  }

  static Int16Array createInt16Array(int length) => _I16(length);
  static Int16Array createInt16Array_fromList(List<num> list) =>
      _I16(ensureNative(list));
  static Int16Array createInt16Array_fromBuffer(ArrayBuffer buffer,
      [int byteOffset = 0, int length]) {
    if (length == null) return _I16_2(buffer, byteOffset);
    return _I16_3(buffer, byteOffset, length);
  }

  static Int32Array createInt32Array(int length) => _I32(length);
  static Int32Array createInt32Array_fromList(List<num> list) =>
      _I32(ensureNative(list));
  static Int32Array createInt32Array_fromBuffer(ArrayBuffer buffer,
      [int byteOffset = 0, int length]) {
    if (length == null) return _I32_2(buffer, byteOffset);
    return _I32_3(buffer, byteOffset, length);
  }

  static Uint8Array createUint8Array(int length) => _U8(length);
  static Uint8Array createUint8Array_fromList(List<num> list) =>
      _U8(ensureNative(list));
  static Uint8Array createUint8Array_fromBuffer(ArrayBuffer buffer,
      [int byteOffset = 0, int length]) {
    if (length == null) return _U8_2(buffer, byteOffset);
    return _U8_3(buffer, byteOffset, length);
  }

  static Uint16Array createUint16Array(int length) => _U16(length);
  static Uint16Array createUint16Array_fromList(List<num> list) =>
      _U16(ensureNative(list));
  static Uint16Array createUint16Array_fromBuffer(ArrayBuffer buffer,
      [int byteOffset = 0, int length]) {
    if (length == null) return _U16_2(buffer, byteOffset);
    return _U16_3(buffer, byteOffset, length);
  }

  static Uint32Array createUint32Array(int length) => _U32(length);
  static Uint32Array createUint32Array_fromList(List<num> list) =>
      _U32(ensureNative(list));
  static Uint32Array createUint32Array_fromBuffer(ArrayBuffer buffer,
      [int byteOffset = 0, int length]) {
    if (length == null) return _U32_2(buffer, byteOffset);
    return _U32_3(buffer, byteOffset, length);
  }

  static Uint8ClampedArray createUint8ClampedArray(int length) => _U8C(length);
  static Uint8ClampedArray createUint8ClampedArray_fromList(List<num> list) =>
      _U8C(ensureNative(list));
  static Uint8ClampedArray createUint8ClampedArray_fromBuffer(
        ArrayBuffer buffer, [int byteOffset = 0, int length]) {
    if (length == null) return _U8C_2(buffer, byteOffset);
    return _U8C_3(buffer, byteOffset, length);
  }

  static Float32Array _F32(arg) =>
      JS('Float32Array', 'new Float32Array(#)', arg);
  static Float64Array _F64(arg) =>
      JS('Float64Array', 'new Float64Array(#)', arg);
  static Int8Array _I8(arg) =>
      JS('Int8Array', 'new Int8Array(#)', arg);
  static Int16Array _I16(arg) =>
      JS('Int16Array', 'new Int16Array(#)', arg);
  static Int32Array _I32(arg) =>
      JS('Int32Array', 'new Int32Array(#)', arg);
  static Uint8Array _U8(arg) =>
      JS('Uint8Array', 'new Uint8Array(#)', arg);
  static Uint16Array _U16(arg) =>
      JS('Uint16Array', 'new Uint16Array(#)', arg);
  static Uint32Array _U32(arg) =>
      JS('Uint32Array', 'new Uint32Array(#)', arg);
  static Uint8ClampedArray _U8C(arg) =>
      JS('Uint8ClampedArray', 'new Uint8ClampedArray(#)', arg);

  static Float32Array _F32_2(arg1, arg2) =>
      JS('Float32Array', 'new Float32Array(#, #)', arg1, arg2);
  static Float64Array _F64_2(arg1, arg2) =>
      JS('Float64Array', 'new Float64Array(#, #)', arg1, arg2);
  static Int8Array _I8_2(arg1, arg2) =>
      JS('Int8Array', 'new Int8Array(#, #)', arg1, arg2);
  static Int16Array _I16_2(arg1, arg2) =>
      JS('Int16Array', 'new Int16Array(#, #)', arg1, arg2);
  static Int32Array _I32_2(arg1, arg2) =>
      JS('Int32Array', 'new Int32Array(#, #)', arg1, arg2);
  static Uint8Array _U8_2(arg1, arg2) =>
      JS('Uint8Array', 'new Uint8Array(#, #)', arg1, arg2);
  static Uint16Array _U16_2(arg1, arg2) =>
      JS('Uint16Array', 'new Uint16Array(#, #)', arg1, arg2);
  static Uint32Array _U32_2(arg1, arg2) =>
      JS('Uint32Array', 'new Uint32Array(#, #)', arg1, arg2);
  static Uint8ClampedArray _U8C_2(arg1, arg2) =>
      JS('Uint8ClampedArray', 'new Uint8ClampedArray(#, #)', arg1, arg2);

  static Float32Array _F32_3(arg1, arg2, arg3) =>
      JS('Float32Array', 'new Float32Array(#, #, #)', arg1, arg2, arg3);
  static Float64Array _F64_3(arg1, arg2, arg3) =>
      JS('Float64Array', 'new Float64Array(#, #, #)', arg1, arg2, arg3);
  static Int8Array _I8_3(arg1, arg2, arg3) =>
      JS('Int8Array', 'new Int8Array(#, #, #)', arg1, arg2, arg3);
  static Int16Array _I16_3(arg1, arg2, arg3) =>
      JS('Int16Array', 'new Int16Array(#, #, #)', arg1, arg2, arg3);
  static Int32Array _I32_3(arg1, arg2, arg3) =>
      JS('Int32Array', 'new Int32Array(#, #, #)', arg1, arg2, arg3);
  static Uint8Array _U8_3(arg1, arg2, arg3) =>
      JS('Uint8Array', 'new Uint8Array(#, #, #)', arg1, arg2, arg3);
  static Uint16Array _U16_3(arg1, arg2, arg3) =>
      JS('Uint16Array', 'new Uint16Array(#, #, #)', arg1, arg2, arg3);
  static Uint32Array _U32_3(arg1, arg2, arg3) =>
      JS('Uint32Array', 'new Uint32Array(#, #, #)', arg1, arg2, arg3);
  static Uint8ClampedArray _U8C_3(arg1, arg2, arg3) =>
      JS('Uint8ClampedArray', 'new Uint8ClampedArray(#, #, #)', arg1, arg2, arg3);


  // Ensures that [list] is a JavaScript Array or a typed array.  If necessary,
  // copies the list.
  static ensureNative(List list) => list;  // TODO: make sure.
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// TODO(rnystrom): add a way to supress public classes from DartDoc output.
// TODO(jacobr): we can remove this class now that we are using the $dom_
// convention for deprecated methods rather than truly private methods.
/**
 * This class is intended for testing purposes only.
 */
class Testing {
  static void addEventListener(EventTarget target, String type, EventListener listener, bool useCapture) {
    target.$dom_addEventListener(type, listener, useCapture);
  }
  static void removeEventListener(EventTarget target, String type, EventListener listener, bool useCapture) {
    target.$dom_removeEventListener(type, listener, useCapture);
  }

}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Iterator for arrays with fixed size.
class FixedSizeListIterator<T> extends _VariableSizeListIterator<T> {
  FixedSizeListIterator(List<T> array)
      : super(array),
        _length = array.length;

  bool get hasNext => _length > _pos;

  final int _length;  // Cache array length for faster access.
}

// Iterator for arrays with variable size.
class _VariableSizeListIterator<T> implements Iterator<T> {
  _VariableSizeListIterator(List<T> array)
      : _array = array,
        _pos = 0;

  bool get hasNext => _array.length > _pos;

  T next() {
    if (!hasNext) {
      throw new StateError("No more elements");
    }
    return _array[_pos++];
  }

  final List<T> _array;
  int _pos;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _Lists {

  /**
   * Returns the index in the array [a] of the given [element], starting
   * the search at index [startIndex] to [endIndex] (exclusive).
   * Returns -1 if [element] is not found.
   */
  static int indexOf(List a,
                     Object element,
                     int startIndex,
                     int endIndex) {
    if (startIndex >= a.length) {
      return -1;
    }
    if (startIndex < 0) {
      startIndex = 0;
    }
    for (int i = startIndex; i < endIndex; i++) {
      if (a[i] == element) {
        return i;
      }
    }
    return -1;
  }

  /**
   * Returns the last index in the array [a] of the given [element], starting
   * the search at index [startIndex] to 0.
   * Returns -1 if [element] is not found.
   */
  static int lastIndexOf(List a, Object element, int startIndex) {
    if (startIndex < 0) {
      return -1;
    }
    if (startIndex >= a.length) {
      startIndex = a.length - 1;
    }
    for (int i = startIndex; i >= 0; i--) {
      if (a[i] == element) {
        return i;
      }
    }
    return -1;
  }

  /**
   * Returns a sub list copy of this list, from [start] to
   * [:start + length:].
   * Returns an empty list if [length] is 0.
   * Throws an [ArgumentError] if [length] is negative.
   * Throws a [RangeError] if [start] or [:start + length:] are out of range.
   */
  static List getRange(List a, int start, int length, List accumulator) {
    if (length < 0) throw new ArgumentError('length');
    if (start < 0) throw new RangeError.value(start);
    int end = start + length;
    if (end > a.length) throw new RangeError.value(end);
    for (int i = start; i < end; i++) {
      accumulator.add(a[i]);
    }
    return accumulator;
  }
}
