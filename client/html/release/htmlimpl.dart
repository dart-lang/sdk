#library('htmlimpl');

#import('dart:dom', prefix:'dom');
#import('dart:html');
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// DO NOT EDIT
// Auto-generated Dart HTML library.






// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AnchorElementWrappingImplementation extends ElementWrappingImplementation implements AnchorElement {
  AnchorElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get accessKey() { return _ptr.accessKey; }

  void set accessKey(String value) { _ptr.accessKey = value; }

  String get charset() { return _ptr.charset; }

  void set charset(String value) { _ptr.charset = value; }

  String get coords() { return _ptr.coords; }

  void set coords(String value) { _ptr.coords = value; }

  String get download() { return _ptr.download; }

  void set download(String value) { _ptr.download = value; }

  String get hash() { return _ptr.hash; }

  void set hash(String value) { _ptr.hash = value; }

  String get host() { return _ptr.host; }

  void set host(String value) { _ptr.host = value; }

  String get hostname() { return _ptr.hostname; }

  void set hostname(String value) { _ptr.hostname = value; }

  String get href() { return _ptr.href; }

  void set href(String value) { _ptr.href = value; }

  String get hreflang() { return _ptr.hreflang; }

  void set hreflang(String value) { _ptr.hreflang = value; }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  String get origin() { return _ptr.origin; }

  String get pathname() { return _ptr.pathname; }

  void set pathname(String value) { _ptr.pathname = value; }

  String get ping() { return _ptr.ping; }

  void set ping(String value) { _ptr.ping = value; }

  String get port() { return _ptr.port; }

  void set port(String value) { _ptr.port = value; }

  String get protocol() { return _ptr.protocol; }

  void set protocol(String value) { _ptr.protocol = value; }

  String get rel() { return _ptr.rel; }

  void set rel(String value) { _ptr.rel = value; }

  String get rev() { return _ptr.rev; }

  void set rev(String value) { _ptr.rev = value; }

  String get search() { return _ptr.search; }

  void set search(String value) { _ptr.search = value; }

  String get shape() { return _ptr.shape; }

  void set shape(String value) { _ptr.shape = value; }

  String get target() { return _ptr.target; }

  void set target(String value) { _ptr.target = value; }

  String get text() { return _ptr.text; }

  String get type() { return _ptr.type; }

  void set type(String value) { _ptr.type = value; }

  String getParameter(String name) {
    return _ptr.getParameter(name);
  }

  String toString() {
    return _ptr.toString();
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AnimationListWrappingImplementation extends DOMWrapperBase implements AnimationList {
  AnimationListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  Animation item(int index) {
    return LevelDom.wrapAnimation(_ptr.item(index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AnimationWrappingImplementation extends DOMWrapperBase implements Animation {
  AnimationWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get delay() { return _ptr.delay; }

  int get direction() { return _ptr.direction; }

  num get duration() { return _ptr.duration; }

  num get elapsedTime() { return _ptr.elapsedTime; }

  void set elapsedTime(num value) { _ptr.elapsedTime = value; }

  bool get ended() { return _ptr.ended; }

  int get fillMode() { return _ptr.fillMode; }

  int get iterationCount() { return _ptr.iterationCount; }

  String get name() { return _ptr.name; }

  bool get paused() { return _ptr.paused; }

  void pause() {
    _ptr.pause();
    return;
  }

  void play() {
    _ptr.play();
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AreaElementWrappingImplementation extends ElementWrappingImplementation implements AreaElement {
  AreaElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get accessKey() { return _ptr.accessKey; }

  void set accessKey(String value) { _ptr.accessKey = value; }

  String get alt() { return _ptr.alt; }

  void set alt(String value) { _ptr.alt = value; }

  String get coords() { return _ptr.coords; }

  void set coords(String value) { _ptr.coords = value; }

  String get hash() { return _ptr.hash; }

  String get host() { return _ptr.host; }

  String get hostname() { return _ptr.hostname; }

  String get href() { return _ptr.href; }

  void set href(String value) { _ptr.href = value; }

  bool get noHref() { return _ptr.noHref; }

  void set noHref(bool value) { _ptr.noHref = value; }

  String get pathname() { return _ptr.pathname; }

  String get ping() { return _ptr.ping; }

  void set ping(String value) { _ptr.ping = value; }

  String get port() { return _ptr.port; }

  String get protocol() { return _ptr.protocol; }

  String get search() { return _ptr.search; }

  String get shape() { return _ptr.shape; }

  void set shape(String value) { _ptr.shape = value; }

  String get target() { return _ptr.target; }

  void set target(String value) { _ptr.target = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ArrayBufferViewWrappingImplementation extends DOMWrapperBase implements ArrayBufferView {
  ArrayBufferViewWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  ArrayBuffer get buffer() { return LevelDom.wrapArrayBuffer(_ptr.buffer); }

  int get byteLength() { return _ptr.byteLength; }

  int get byteOffset() { return _ptr.byteOffset; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ArrayBufferWrappingImplementation extends DOMWrapperBase implements ArrayBuffer {
  ArrayBufferWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get byteLength() { return _ptr.byteLength; }

  ArrayBuffer slice(int begin, [int end]) {
    if (end === null) {
      return LevelDom.wrapArrayBuffer(_ptr.slice(begin));
    } else {
      return LevelDom.wrapArrayBuffer(_ptr.slice(begin, end));
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AudioBufferSourceNodeWrappingImplementation extends AudioSourceNodeWrappingImplementation implements AudioBufferSourceNode {
  AudioBufferSourceNodeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  AudioBuffer get buffer() { return LevelDom.wrapAudioBuffer(_ptr.buffer); }

  void set buffer(AudioBuffer value) { _ptr.buffer = LevelDom.unwrap(value); }

  AudioGain get gain() { return LevelDom.wrapAudioGain(_ptr.gain); }

  bool get loop() { return _ptr.loop; }

  void set loop(bool value) { _ptr.loop = value; }

  bool get looping() { return _ptr.looping; }

  void set looping(bool value) { _ptr.looping = value; }

  AudioParam get playbackRate() { return LevelDom.wrapAudioParam(_ptr.playbackRate); }

  void noteGrainOn(num when, num grainOffset, num grainDuration) {
    _ptr.noteGrainOn(when, grainOffset, grainDuration);
    return;
  }

  void noteOff(num when) {
    _ptr.noteOff(when);
    return;
  }

  void noteOn(num when) {
    _ptr.noteOn(when);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AudioBufferWrappingImplementation extends DOMWrapperBase implements AudioBuffer {
  AudioBufferWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get duration() { return _ptr.duration; }

  num get gain() { return _ptr.gain; }

  void set gain(num value) { _ptr.gain = value; }

  int get length() { return _ptr.length; }

  int get numberOfChannels() { return _ptr.numberOfChannels; }

  num get sampleRate() { return _ptr.sampleRate; }

  Float32Array getChannelData(int channelIndex) {
    return LevelDom.wrapFloat32Array(_ptr.getChannelData(channelIndex));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AudioChannelMergerWrappingImplementation extends AudioNodeWrappingImplementation implements AudioChannelMerger {
  AudioChannelMergerWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AudioChannelSplitterWrappingImplementation extends AudioNodeWrappingImplementation implements AudioChannelSplitter {
  AudioChannelSplitterWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AudioContextWrappingImplementation extends DOMWrapperBase implements AudioContext {
  AudioContextWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get currentTime() { return _ptr.currentTime; }

  AudioDestinationNode get destination() { return LevelDom.wrapAudioDestinationNode(_ptr.destination); }

  AudioListener get listener() { return LevelDom.wrapAudioListener(_ptr.listener); }

  num get sampleRate() { return _ptr.sampleRate; }

  RealtimeAnalyserNode createAnalyser() {
    return LevelDom.wrapRealtimeAnalyserNode(_ptr.createAnalyser());
  }

  BiquadFilterNode createBiquadFilter() {
    return LevelDom.wrapBiquadFilterNode(_ptr.createBiquadFilter());
  }

  AudioBuffer createBuffer() {
    return LevelDom.wrapAudioBuffer(_ptr.createBuffer());
  }

  AudioBufferSourceNode createBufferSource() {
    return LevelDom.wrapAudioBufferSourceNode(_ptr.createBufferSource());
  }

  AudioChannelMerger createChannelMerger() {
    return LevelDom.wrapAudioChannelMerger(_ptr.createChannelMerger());
  }

  AudioChannelSplitter createChannelSplitter() {
    return LevelDom.wrapAudioChannelSplitter(_ptr.createChannelSplitter());
  }

  ConvolverNode createConvolver() {
    return LevelDom.wrapConvolverNode(_ptr.createConvolver());
  }

  DelayNode createDelayNode() {
    return LevelDom.wrapDelayNode(_ptr.createDelayNode());
  }

  DynamicsCompressorNode createDynamicsCompressor() {
    return LevelDom.wrapDynamicsCompressorNode(_ptr.createDynamicsCompressor());
  }

  AudioGainNode createGainNode() {
    return LevelDom.wrapAudioGainNode(_ptr.createGainNode());
  }

  HighPass2FilterNode createHighPass2Filter() {
    return LevelDom.wrapHighPass2FilterNode(_ptr.createHighPass2Filter());
  }

  JavaScriptAudioNode createJavaScriptNode(int bufferSize) {
    return LevelDom.wrapJavaScriptAudioNode(_ptr.createJavaScriptNode(bufferSize));
  }

  LowPass2FilterNode createLowPass2Filter() {
    return LevelDom.wrapLowPass2FilterNode(_ptr.createLowPass2Filter());
  }

  AudioPannerNode createPanner() {
    return LevelDom.wrapAudioPannerNode(_ptr.createPanner());
  }

  WaveShaperNode createWaveShaper() {
    return LevelDom.wrapWaveShaperNode(_ptr.createWaveShaper());
  }

  void decodeAudioData(ArrayBuffer audioData, AudioBufferCallback successCallback, [AudioBufferCallback errorCallback]) {
    if (errorCallback === null) {
      _ptr.decodeAudioData(LevelDom.unwrap(audioData), successCallback);
      return;
    } else {
      _ptr.decodeAudioData(LevelDom.unwrap(audioData), successCallback, errorCallback);
      return;
    }
  }

  void startRendering() {
    _ptr.startRendering();
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AudioDestinationNodeWrappingImplementation extends AudioNodeWrappingImplementation implements AudioDestinationNode {
  AudioDestinationNodeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get numberOfChannels() { return _ptr.numberOfChannels; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AudioElementWrappingImplementation extends MediaElementWrappingImplementation implements AudioElement {
  AudioElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AudioGainNodeWrappingImplementation extends AudioNodeWrappingImplementation implements AudioGainNode {
  AudioGainNodeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  AudioGain get gain() { return LevelDom.wrapAudioGain(_ptr.gain); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AudioGainWrappingImplementation extends AudioParamWrappingImplementation implements AudioGain {
  AudioGainWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AudioListenerWrappingImplementation extends DOMWrapperBase implements AudioListener {
  AudioListenerWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get dopplerFactor() { return _ptr.dopplerFactor; }

  void set dopplerFactor(num value) { _ptr.dopplerFactor = value; }

  num get speedOfSound() { return _ptr.speedOfSound; }

  void set speedOfSound(num value) { _ptr.speedOfSound = value; }

  void setOrientation(num x, num y, num z, num xUp, num yUp, num zUp) {
    _ptr.setOrientation(x, y, z, xUp, yUp, zUp);
    return;
  }

  void setPosition(num x, num y, num z) {
    _ptr.setPosition(x, y, z);
    return;
  }

  void setVelocity(num x, num y, num z) {
    _ptr.setVelocity(x, y, z);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AudioNodeWrappingImplementation extends DOMWrapperBase implements AudioNode {
  AudioNodeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  AudioContext get context() { return LevelDom.wrapAudioContext(_ptr.context); }

  int get numberOfInputs() { return _ptr.numberOfInputs; }

  int get numberOfOutputs() { return _ptr.numberOfOutputs; }

  void connect(AudioNode destination, [int output, int input]) {
    if (output === null) {
      if (input === null) {
        _ptr.connect(LevelDom.unwrap(destination));
        return;
      }
    } else {
      if (input === null) {
        _ptr.connect(LevelDom.unwrap(destination), output);
        return;
      } else {
        _ptr.connect(LevelDom.unwrap(destination), output, input);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void disconnect([int output]) {
    if (output === null) {
      _ptr.disconnect();
      return;
    } else {
      _ptr.disconnect(output);
      return;
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AudioPannerNodeWrappingImplementation extends AudioNodeWrappingImplementation implements AudioPannerNode {
  AudioPannerNodeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  AudioGain get coneGain() { return LevelDom.wrapAudioGain(_ptr.coneGain); }

  num get coneInnerAngle() { return _ptr.coneInnerAngle; }

  void set coneInnerAngle(num value) { _ptr.coneInnerAngle = value; }

  num get coneOuterAngle() { return _ptr.coneOuterAngle; }

  void set coneOuterAngle(num value) { _ptr.coneOuterAngle = value; }

  num get coneOuterGain() { return _ptr.coneOuterGain; }

  void set coneOuterGain(num value) { _ptr.coneOuterGain = value; }

  AudioGain get distanceGain() { return LevelDom.wrapAudioGain(_ptr.distanceGain); }

  int get distanceModel() { return _ptr.distanceModel; }

  void set distanceModel(int value) { _ptr.distanceModel = value; }

  num get maxDistance() { return _ptr.maxDistance; }

  void set maxDistance(num value) { _ptr.maxDistance = value; }

  int get panningModel() { return _ptr.panningModel; }

  void set panningModel(int value) { _ptr.panningModel = value; }

  num get refDistance() { return _ptr.refDistance; }

  void set refDistance(num value) { _ptr.refDistance = value; }

  num get rolloffFactor() { return _ptr.rolloffFactor; }

  void set rolloffFactor(num value) { _ptr.rolloffFactor = value; }

  void setOrientation(num x, num y, num z) {
    _ptr.setOrientation(x, y, z);
    return;
  }

  void setPosition(num x, num y, num z) {
    _ptr.setPosition(x, y, z);
    return;
  }

  void setVelocity(num x, num y, num z) {
    _ptr.setVelocity(x, y, z);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AudioParamWrappingImplementation extends DOMWrapperBase implements AudioParam {
  AudioParamWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get defaultValue() { return _ptr.defaultValue; }

  num get maxValue() { return _ptr.maxValue; }

  num get minValue() { return _ptr.minValue; }

  String get name() { return _ptr.name; }

  int get units() { return _ptr.units; }

  num get value() { return _ptr.value; }

  void set value(num value) { _ptr.value = value; }

  void cancelScheduledValues(num startTime) {
    _ptr.cancelScheduledValues(startTime);
    return;
  }

  void exponentialRampToValueAtTime(num value, num time) {
    _ptr.exponentialRampToValueAtTime(value, time);
    return;
  }

  void linearRampToValueAtTime(num value, num time) {
    _ptr.linearRampToValueAtTime(value, time);
    return;
  }

  void setTargetValueAtTime(num targetValue, num time, num timeConstant) {
    _ptr.setTargetValueAtTime(targetValue, time, timeConstant);
    return;
  }

  void setValueAtTime(num value, num time) {
    _ptr.setValueAtTime(value, time);
    return;
  }

  void setValueCurveAtTime(Float32Array values, num time, num duration) {
    _ptr.setValueCurveAtTime(LevelDom.unwrap(values), time, duration);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AudioProcessingEventWrappingImplementation extends EventWrappingImplementation implements AudioProcessingEvent {
  AudioProcessingEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  AudioBuffer get inputBuffer() { return LevelDom.wrapAudioBuffer(_ptr.inputBuffer); }

  AudioBuffer get outputBuffer() { return LevelDom.wrapAudioBuffer(_ptr.outputBuffer); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AudioSourceNodeWrappingImplementation extends AudioNodeWrappingImplementation implements AudioSourceNode {
  AudioSourceNodeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class BRElementWrappingImplementation extends ElementWrappingImplementation implements BRElement {
  BRElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get clear() { return _ptr.clear; }

  void set clear(String value) { _ptr.clear = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class BarInfoWrappingImplementation extends DOMWrapperBase implements BarInfo {
  BarInfoWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get visible() { return _ptr.visible; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class BaseElementWrappingImplementation extends ElementWrappingImplementation implements BaseElement {
  BaseElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get href() { return _ptr.href; }

  void set href(String value) { _ptr.href = value; }

  String get target() { return _ptr.target; }

  void set target(String value) { _ptr.target = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class BiquadFilterNodeWrappingImplementation extends AudioNodeWrappingImplementation implements BiquadFilterNode {
  BiquadFilterNodeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  AudioParam get Q() { return LevelDom.wrapAudioParam(_ptr.Q); }

  AudioParam get frequency() { return LevelDom.wrapAudioParam(_ptr.frequency); }

  AudioParam get gain() { return LevelDom.wrapAudioParam(_ptr.gain); }

  int get type() { return _ptr.type; }

  void set type(int value) { _ptr.type = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class BlobBuilderWrappingImplementation extends DOMWrapperBase implements BlobBuilder {
  BlobBuilderWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void append(var blob_OR_value, [String endings]) {
    if (blob_OR_value is Blob) {
      if (endings === null) {
        _ptr.append(LevelDom.unwrapMaybePrimitive(blob_OR_value));
        return;
      }
    } else {
      if (blob_OR_value is String) {
        if (endings === null) {
          _ptr.append(LevelDom.unwrapMaybePrimitive(blob_OR_value));
          return;
        } else {
          _ptr.append(LevelDom.unwrapMaybePrimitive(blob_OR_value), endings);
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  Blob getBlob([String contentType]) {
    if (contentType === null) {
      return LevelDom.wrapBlob(_ptr.getBlob());
    } else {
      return LevelDom.wrapBlob(_ptr.getBlob(contentType));
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class BlobWrappingImplementation extends DOMWrapperBase implements Blob {
  BlobWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get size() { return _ptr.size; }

  String get type() { return _ptr.type; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ButtonElementWrappingImplementation extends ElementWrappingImplementation implements ButtonElement {
  ButtonElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get accessKey() { return _ptr.accessKey; }

  void set accessKey(String value) { _ptr.accessKey = value; }

  bool get autofocus() { return _ptr.autofocus; }

  void set autofocus(bool value) { _ptr.autofocus = value; }

  bool get disabled() { return _ptr.disabled; }

  void set disabled(bool value) { _ptr.disabled = value; }

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  String get formAction() { return _ptr.formAction; }

  void set formAction(String value) { _ptr.formAction = value; }

  String get formEnctype() { return _ptr.formEnctype; }

  void set formEnctype(String value) { _ptr.formEnctype = value; }

  String get formMethod() { return _ptr.formMethod; }

  void set formMethod(String value) { _ptr.formMethod = value; }

  bool get formNoValidate() { return _ptr.formNoValidate; }

  void set formNoValidate(bool value) { _ptr.formNoValidate = value; }

  String get formTarget() { return _ptr.formTarget; }

  void set formTarget(String value) { _ptr.formTarget = value; }

  ElementList get labels() { return LevelDom.wrapElementList(_ptr.labels); }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  String get type() { return _ptr.type; }

  String get validationMessage() { return _ptr.validationMessage; }

  ValidityState get validity() { return LevelDom.wrapValidityState(_ptr.validity); }

  String get value() { return _ptr.value; }

  void set value(String value) { _ptr.value = value; }

  bool get willValidate() { return _ptr.willValidate; }

  bool checkValidity() {
    return _ptr.checkValidity();
  }

  void click() {
    _ptr.click();
    return;
  }

  void setCustomValidity(String error) {
    _ptr.setCustomValidity(error);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CDATASectionWrappingImplementation extends TextWrappingImplementation implements CDATASection {
  CDATASectionWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSCharsetRuleWrappingImplementation extends CSSRuleWrappingImplementation implements CSSCharsetRule {
  CSSCharsetRuleWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get encoding() { return _ptr.encoding; }

  void set encoding(String value) { _ptr.encoding = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSFontFaceRuleWrappingImplementation extends CSSRuleWrappingImplementation implements CSSFontFaceRule {
  CSSFontFaceRuleWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSImportRuleWrappingImplementation extends CSSRuleWrappingImplementation implements CSSImportRule {
  CSSImportRuleWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get href() { return _ptr.href; }

  MediaList get media() { return LevelDom.wrapMediaList(_ptr.media); }

  CSSStyleSheet get styleSheet() { return LevelDom.wrapCSSStyleSheet(_ptr.styleSheet); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSKeyframeRuleWrappingImplementation extends CSSRuleWrappingImplementation implements CSSKeyframeRule {
  CSSKeyframeRuleWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get keyText() { return _ptr.keyText; }

  void set keyText(String value) { _ptr.keyText = value; }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSKeyframesRuleWrappingImplementation extends CSSRuleWrappingImplementation implements CSSKeyframesRule {
  CSSKeyframesRuleWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  CSSRuleList get cssRules() { return LevelDom.wrapCSSRuleList(_ptr.cssRules); }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  void deleteRule(String key) {
    _ptr.deleteRule(key);
    return;
  }

  CSSKeyframeRule findRule(String key) {
    return LevelDom.wrapCSSKeyframeRule(_ptr.findRule(key));
  }

  void insertRule(String rule) {
    _ptr.insertRule(rule);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSMatrixWrappingImplementation extends DOMWrapperBase implements CSSMatrix {
  CSSMatrixWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
  factory CSSMatrixWrappingImplementation([String cssValue = null]) {
    
    if (cssValue === null) {
      return LevelDom.wrapCSSMatrix(new dom.WebKitCSSMatrix());
    } else {
      return LevelDom.wrapCSSMatrix(new dom.WebKitCSSMatrix(cssValue));
    }
  }

  num get a() { return _ptr.a; }

  void set a(num value) { _ptr.a = value; }

  num get b() { return _ptr.b; }

  void set b(num value) { _ptr.b = value; }

  num get c() { return _ptr.c; }

  void set c(num value) { _ptr.c = value; }

  num get d() { return _ptr.d; }

  void set d(num value) { _ptr.d = value; }

  num get e() { return _ptr.e; }

  void set e(num value) { _ptr.e = value; }

  num get f() { return _ptr.f; }

  void set f(num value) { _ptr.f = value; }

  num get m11() { return _ptr.m11; }

  void set m11(num value) { _ptr.m11 = value; }

  num get m12() { return _ptr.m12; }

  void set m12(num value) { _ptr.m12 = value; }

  num get m13() { return _ptr.m13; }

  void set m13(num value) { _ptr.m13 = value; }

  num get m14() { return _ptr.m14; }

  void set m14(num value) { _ptr.m14 = value; }

  num get m21() { return _ptr.m21; }

  void set m21(num value) { _ptr.m21 = value; }

  num get m22() { return _ptr.m22; }

  void set m22(num value) { _ptr.m22 = value; }

  num get m23() { return _ptr.m23; }

  void set m23(num value) { _ptr.m23 = value; }

  num get m24() { return _ptr.m24; }

  void set m24(num value) { _ptr.m24 = value; }

  num get m31() { return _ptr.m31; }

  void set m31(num value) { _ptr.m31 = value; }

  num get m32() { return _ptr.m32; }

  void set m32(num value) { _ptr.m32 = value; }

  num get m33() { return _ptr.m33; }

  void set m33(num value) { _ptr.m33 = value; }

  num get m34() { return _ptr.m34; }

  void set m34(num value) { _ptr.m34 = value; }

  num get m41() { return _ptr.m41; }

  void set m41(num value) { _ptr.m41 = value; }

  num get m42() { return _ptr.m42; }

  void set m42(num value) { _ptr.m42 = value; }

  num get m43() { return _ptr.m43; }

  void set m43(num value) { _ptr.m43 = value; }

  num get m44() { return _ptr.m44; }

  void set m44(num value) { _ptr.m44 = value; }

  CSSMatrix inverse() {
    return LevelDom.wrapCSSMatrix(_ptr.inverse());
  }

  CSSMatrix multiply(CSSMatrix secondMatrix) {
    return LevelDom.wrapCSSMatrix(_ptr.multiply(LevelDom.unwrap(secondMatrix)));
  }

  CSSMatrix rotate(num rotX, num rotY, num rotZ) {
    return LevelDom.wrapCSSMatrix(_ptr.rotate(rotX, rotY, rotZ));
  }

  CSSMatrix rotateAxisAngle(num x, num y, num z, num angle) {
    return LevelDom.wrapCSSMatrix(_ptr.rotateAxisAngle(x, y, z, angle));
  }

  CSSMatrix scale(num scaleX, num scaleY, num scaleZ) {
    return LevelDom.wrapCSSMatrix(_ptr.scale(scaleX, scaleY, scaleZ));
  }

  void setMatrixValue(String string) {
    _ptr.setMatrixValue(string);
    return;
  }

  CSSMatrix skewX(num angle) {
    return LevelDom.wrapCSSMatrix(_ptr.skewX(angle));
  }

  CSSMatrix skewY(num angle) {
    return LevelDom.wrapCSSMatrix(_ptr.skewY(angle));
  }

  String toString() {
    return _ptr.toString();
  }

  CSSMatrix translate(num x, num y, num z) {
    return LevelDom.wrapCSSMatrix(_ptr.translate(x, y, z));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSMediaRuleWrappingImplementation extends CSSRuleWrappingImplementation implements CSSMediaRule {
  CSSMediaRuleWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  CSSRuleList get cssRules() { return LevelDom.wrapCSSRuleList(_ptr.cssRules); }

  MediaList get media() { return LevelDom.wrapMediaList(_ptr.media); }

  void deleteRule(int index) {
    _ptr.deleteRule(index);
    return;
  }

  int insertRule(String rule, int index) {
    return _ptr.insertRule(rule, index);
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSPageRuleWrappingImplementation extends CSSRuleWrappingImplementation implements CSSPageRule {
  CSSPageRuleWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get selectorText() { return _ptr.selectorText; }

  void set selectorText(String value) { _ptr.selectorText = value; }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSPrimitiveValueWrappingImplementation extends CSSValueWrappingImplementation implements CSSPrimitiveValue {
  CSSPrimitiveValueWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get primitiveType() { return _ptr.primitiveType; }

  Counter getCounterValue() {
    return LevelDom.wrapCounter(_ptr.getCounterValue());
  }

  num getFloatValue(int unitType) {
    return _ptr.getFloatValue(unitType);
  }

  RGBColor getRGBColorValue() {
    return LevelDom.wrapRGBColor(_ptr.getRGBColorValue());
  }

  Rect getRectValue() {
    return LevelDom.wrapRect(_ptr.getRectValue());
  }

  String getStringValue() {
    return _ptr.getStringValue();
  }

  void setFloatValue(int unitType, num floatValue) {
    _ptr.setFloatValue(unitType, floatValue);
    return;
  }

  void setStringValue(int stringType, String stringValue) {
    _ptr.setStringValue(stringType, stringValue);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSRuleListWrappingImplementation extends DOMWrapperBase implements CSSRuleList {
  CSSRuleListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  CSSRule item(int index) {
    return LevelDom.wrapCSSRule(_ptr.item(index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSRuleWrappingImplementation extends DOMWrapperBase implements CSSRule {
  CSSRuleWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get cssText() { return _ptr.cssText; }

  void set cssText(String value) { _ptr.cssText = value; }

  CSSRule get parentRule() { return LevelDom.wrapCSSRule(_ptr.parentRule); }

  CSSStyleSheet get parentStyleSheet() { return LevelDom.wrapCSSStyleSheet(_ptr.parentStyleSheet); }

  int get type() { return _ptr.type; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSStyleRuleWrappingImplementation extends CSSRuleWrappingImplementation implements CSSStyleRule {
  CSSStyleRuleWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get selectorText() { return _ptr.selectorText; }

  void set selectorText(String value) { _ptr.selectorText = value; }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSStyleSheetWrappingImplementation extends StyleSheetWrappingImplementation implements CSSStyleSheet {
  CSSStyleSheetWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  CSSRuleList get cssRules() { return LevelDom.wrapCSSRuleList(_ptr.cssRules); }

  CSSRule get ownerRule() { return LevelDom.wrapCSSRule(_ptr.ownerRule); }

  CSSRuleList get rules() { return LevelDom.wrapCSSRuleList(_ptr.rules); }

  int addRule(String selector, String style, [int index]) {
    if (index === null) {
      return _ptr.addRule(selector, style);
    } else {
      return _ptr.addRule(selector, style, index);
    }
  }

  void deleteRule(int index) {
    _ptr.deleteRule(index);
    return;
  }

  int insertRule(String rule, int index) {
    return _ptr.insertRule(rule, index);
  }

  void removeRule(int index) {
    _ptr.removeRule(index);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSTransformValueWrappingImplementation extends CSSValueListWrappingImplementation implements CSSTransformValue {
  CSSTransformValueWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get operationType() { return _ptr.operationType; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSUnknownRuleWrappingImplementation extends CSSRuleWrappingImplementation implements CSSUnknownRule {
  CSSUnknownRuleWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSValueListWrappingImplementation extends CSSValueWrappingImplementation implements CSSValueList {
  CSSValueListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  CSSValue item(int index) {
    return LevelDom.wrapCSSValue(_ptr.item(index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSValueWrappingImplementation extends DOMWrapperBase implements CSSValue {
  CSSValueWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get cssText() { return _ptr.cssText; }

  void set cssText(String value) { _ptr.cssText = value; }

  int get cssValueType() { return _ptr.cssValueType; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CanvasElementWrappingImplementation extends ElementWrappingImplementation implements CanvasElement {
  CanvasElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get height() { return _ptr.height; }

  void set height(int value) { _ptr.height = value; }

  int get width() { return _ptr.width; }

  void set width(int value) { _ptr.width = value; }

  CanvasRenderingContext getContext([String contextId = null]) {
    if (contextId === null) {
      return LevelDom.wrapCanvasRenderingContext(_ptr.getContext());
    } else {
      return LevelDom.wrapCanvasRenderingContext(_ptr.getContext(contextId));
    }
  }

  String toDataURL(String type) {
    return _ptr.toDataURL(type);
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CanvasGradientWrappingImplementation extends DOMWrapperBase implements CanvasGradient {
  CanvasGradientWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void addColorStop(num offset, String color) {
    _ptr.addColorStop(offset, color);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CanvasPatternWrappingImplementation extends DOMWrapperBase implements CanvasPattern {
  CanvasPatternWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CanvasPixelArrayWrappingImplementation extends DOMWrapperBase implements CanvasPixelArray {
  CanvasPixelArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  int operator[](int index) {
    return _ptr[index];
  }

  void operator[]=(int index, int value) {
    _ptr[index] = value;
  }

  void add(int value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addLast(int value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addAll(Collection<int> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void sort(int compare(int a, int b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
  }

  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) {
    throw new UnsupportedOperationException("This object is immutable.");
  }

  int indexOf(int element, [int start = 0]) {
    return _Lists.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(int element, [int start = null]) {
    if (start === null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int clear() {
    throw new UnsupportedOperationException("Cannot clear immutable List.");
  }

  int removeLast() {
    throw new UnsupportedOperationException("Cannot removeLast on immutable List.");
  }

  int last() {
    return this[length - 1];
  }

  void forEach(void f(int element)) {
    _Collections.forEach(this, f);
  }

  Collection<int> filter(bool f(int element)) {
    return _Collections.filter(this, new List<int>(), f);
  }

  bool every(bool f(int element)) {
    return _Collections.every(this, f);
  }

  bool some(bool f(int element)) {
    return _Collections.some(this, f);
  }

  void setRange(int start, int length, List<int> from, [int startFrom]) {
    throw new UnsupportedOperationException("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int length) {
    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int length, [int initialValue]) {
    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");
  }

  List<int> getRange(int start, int length) {
    throw new NotImplementedException();
  }

  bool isEmpty() {
    return length == 0;
  }

  Iterator<int> iterator() {
    return new _FixedSizeListIterator<int>(this);
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CanvasRenderingContext2DWrappingImplementation extends CanvasRenderingContextWrappingImplementation implements CanvasRenderingContext2D {
  CanvasRenderingContext2DWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  Object get fillStyle() { return LevelDom.wrapObject(_ptr.fillStyle); }

  void set fillStyle(Object value) { _ptr.fillStyle = LevelDom.unwrapMaybePrimitive(value); }

  String get font() { return _ptr.font; }

  void set font(String value) { _ptr.font = value; }

  num get globalAlpha() { return _ptr.globalAlpha; }

  void set globalAlpha(num value) { _ptr.globalAlpha = value; }

  String get globalCompositeOperation() { return _ptr.globalCompositeOperation; }

  void set globalCompositeOperation(String value) { _ptr.globalCompositeOperation = value; }

  String get lineCap() { return _ptr.lineCap; }

  void set lineCap(String value) { _ptr.lineCap = value; }

  String get lineJoin() { return _ptr.lineJoin; }

  void set lineJoin(String value) { _ptr.lineJoin = value; }

  num get lineWidth() { return _ptr.lineWidth; }

  void set lineWidth(num value) { _ptr.lineWidth = value; }

  num get miterLimit() { return _ptr.miterLimit; }

  void set miterLimit(num value) { _ptr.miterLimit = value; }

  num get shadowBlur() { return _ptr.shadowBlur; }

  void set shadowBlur(num value) { _ptr.shadowBlur = value; }

  String get shadowColor() { return _ptr.shadowColor; }

  void set shadowColor(String value) { _ptr.shadowColor = value; }

  num get shadowOffsetX() { return _ptr.shadowOffsetX; }

  void set shadowOffsetX(num value) { _ptr.shadowOffsetX = value; }

  num get shadowOffsetY() { return _ptr.shadowOffsetY; }

  void set shadowOffsetY(num value) { _ptr.shadowOffsetY = value; }

  Object get strokeStyle() { return LevelDom.wrapObject(_ptr.strokeStyle); }

  void set strokeStyle(Object value) { _ptr.strokeStyle = LevelDom.unwrapMaybePrimitive(value); }

  String get textAlign() { return _ptr.textAlign; }

  void set textAlign(String value) { _ptr.textAlign = value; }

  String get textBaseline() { return _ptr.textBaseline; }

  void set textBaseline(String value) { _ptr.textBaseline = value; }

  List get webkitLineDash() { return _ptr.webkitLineDash; }

  void set webkitLineDash(List value) { _ptr.webkitLineDash = value; }

  num get webkitLineDashOffset() { return _ptr.webkitLineDashOffset; }

  void set webkitLineDashOffset(num value) { _ptr.webkitLineDashOffset = value; }

  void arc(num x, num y, num radius, num startAngle, num endAngle, bool anticlockwise) {
    _ptr.arc(x, y, radius, startAngle, endAngle, anticlockwise);
    return;
  }

  void arcTo(num x1, num y1, num x2, num y2, num radius) {
    _ptr.arcTo(x1, y1, x2, y2, radius);
    return;
  }

  void beginPath() {
    _ptr.beginPath();
    return;
  }

  void bezierCurveTo(num cp1x, num cp1y, num cp2x, num cp2y, num x, num y) {
    _ptr.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y);
    return;
  }

  void clearRect(num x, num y, num width, num height) {
    _ptr.clearRect(x, y, width, height);
    return;
  }

  void clearShadow() {
    _ptr.clearShadow();
    return;
  }

  void clip() {
    _ptr.clip();
    return;
  }

  void closePath() {
    _ptr.closePath();
    return;
  }

  ImageData createImageData(var imagedata_OR_sw, [num sh = null]) {
    if (imagedata_OR_sw is ImageData) {
      if (sh === null) {
        return LevelDom.wrapImageData(_ptr.createImageData(LevelDom.unwrapMaybePrimitive(imagedata_OR_sw)));
      }
    } else {
      if (imagedata_OR_sw is num) {
        return LevelDom.wrapImageData(_ptr.createImageData(LevelDom.unwrapMaybePrimitive(imagedata_OR_sw), sh));
      }
    }
    throw "Incorrect number or type of arguments";
  }

  CanvasGradient createLinearGradient(num x0, num y0, num x1, num y1) {
    return LevelDom.wrapCanvasGradient(_ptr.createLinearGradient(x0, y0, x1, y1));
  }

  CanvasPattern createPattern(var canvas_OR_image, String repetitionType) {
    if (canvas_OR_image is CanvasElement) {
      return LevelDom.wrapCanvasPattern(_ptr.createPattern(LevelDom.unwrapMaybePrimitive(canvas_OR_image), repetitionType));
    } else {
      if (canvas_OR_image is ImageElement) {
        return LevelDom.wrapCanvasPattern(_ptr.createPattern(LevelDom.unwrapMaybePrimitive(canvas_OR_image), repetitionType));
      }
    }
    throw "Incorrect number or type of arguments";
  }

  CanvasGradient createRadialGradient(num x0, num y0, num r0, num x1, num y1, num r1) {
    return LevelDom.wrapCanvasGradient(_ptr.createRadialGradient(x0, y0, r0, x1, y1, r1));
  }

  void drawImage(var canvas_OR_image, num sx_OR_x, num sy_OR_y, [num sw_OR_width = null, num height_OR_sh = null, num dx = null, num dy = null, num dw = null, num dh = null]) {
    if (canvas_OR_image is ImageElement) {
      if (sw_OR_width === null) {
        if (height_OR_sh === null) {
          if (dx === null) {
            if (dy === null) {
              if (dw === null) {
                if (dh === null) {
                  _ptr.drawImage(LevelDom.unwrapMaybePrimitive(canvas_OR_image), sx_OR_x, sy_OR_y);
                  return;
                }
              }
            }
          }
        }
      } else {
        if (dx === null) {
          if (dy === null) {
            if (dw === null) {
              if (dh === null) {
                _ptr.drawImage(LevelDom.unwrapMaybePrimitive(canvas_OR_image), sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh);
                return;
              }
            }
          }
        } else {
          _ptr.drawImage(LevelDom.unwrapMaybePrimitive(canvas_OR_image), sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh);
          return;
        }
      }
    } else {
      if (canvas_OR_image is CanvasElement) {
        if (sw_OR_width === null) {
          if (height_OR_sh === null) {
            if (dx === null) {
              if (dy === null) {
                if (dw === null) {
                  if (dh === null) {
                    _ptr.drawImage(LevelDom.unwrapMaybePrimitive(canvas_OR_image), sx_OR_x, sy_OR_y);
                    return;
                  }
                }
              }
            }
          }
        } else {
          if (dx === null) {
            if (dy === null) {
              if (dw === null) {
                if (dh === null) {
                  _ptr.drawImage(LevelDom.unwrapMaybePrimitive(canvas_OR_image), sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh);
                  return;
                }
              }
            }
          } else {
            _ptr.drawImage(LevelDom.unwrapMaybePrimitive(canvas_OR_image), sx_OR_x, sy_OR_y, sw_OR_width, height_OR_sh, dx, dy, dw, dh);
            return;
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void drawImageFromRect(ImageElement image, [num sx = null, num sy = null, num sw = null, num sh = null, num dx = null, num dy = null, num dw = null, num dh = null, String compositeOperation = null]) {
    if (sx === null) {
      if (sy === null) {
        if (sw === null) {
          if (sh === null) {
            if (dx === null) {
              if (dy === null) {
                if (dw === null) {
                  if (dh === null) {
                    if (compositeOperation === null) {
                      _ptr.drawImageFromRect(LevelDom.unwrap(image));
                      return;
                    }
                  }
                }
              }
            }
          }
        }
      }
    } else {
      if (sy === null) {
        if (sw === null) {
          if (sh === null) {
            if (dx === null) {
              if (dy === null) {
                if (dw === null) {
                  if (dh === null) {
                    if (compositeOperation === null) {
                      _ptr.drawImageFromRect(LevelDom.unwrap(image), sx);
                      return;
                    }
                  }
                }
              }
            }
          }
        }
      } else {
        if (sw === null) {
          if (sh === null) {
            if (dx === null) {
              if (dy === null) {
                if (dw === null) {
                  if (dh === null) {
                    if (compositeOperation === null) {
                      _ptr.drawImageFromRect(LevelDom.unwrap(image), sx, sy);
                      return;
                    }
                  }
                }
              }
            }
          }
        } else {
          if (sh === null) {
            if (dx === null) {
              if (dy === null) {
                if (dw === null) {
                  if (dh === null) {
                    if (compositeOperation === null) {
                      _ptr.drawImageFromRect(LevelDom.unwrap(image), sx, sy, sw);
                      return;
                    }
                  }
                }
              }
            }
          } else {
            if (dx === null) {
              if (dy === null) {
                if (dw === null) {
                  if (dh === null) {
                    if (compositeOperation === null) {
                      _ptr.drawImageFromRect(LevelDom.unwrap(image), sx, sy, sw, sh);
                      return;
                    }
                  }
                }
              }
            } else {
              if (dy === null) {
                if (dw === null) {
                  if (dh === null) {
                    if (compositeOperation === null) {
                      _ptr.drawImageFromRect(LevelDom.unwrap(image), sx, sy, sw, sh, dx);
                      return;
                    }
                  }
                }
              } else {
                if (dw === null) {
                  if (dh === null) {
                    if (compositeOperation === null) {
                      _ptr.drawImageFromRect(LevelDom.unwrap(image), sx, sy, sw, sh, dx, dy);
                      return;
                    }
                  }
                } else {
                  if (dh === null) {
                    if (compositeOperation === null) {
                      _ptr.drawImageFromRect(LevelDom.unwrap(image), sx, sy, sw, sh, dx, dy, dw);
                      return;
                    }
                  } else {
                    if (compositeOperation === null) {
                      _ptr.drawImageFromRect(LevelDom.unwrap(image), sx, sy, sw, sh, dx, dy, dw, dh);
                      return;
                    } else {
                      _ptr.drawImageFromRect(LevelDom.unwrap(image), sx, sy, sw, sh, dx, dy, dw, dh, compositeOperation);
                      return;
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void fill() {
    _ptr.fill();
    return;
  }

  void fillRect(num x, num y, num width, num height) {
    _ptr.fillRect(x, y, width, height);
    return;
  }

  void fillText(String text, num x, num y, [num maxWidth = null]) {
    if (maxWidth === null) {
      _ptr.fillText(text, x, y);
      return;
    } else {
      _ptr.fillText(text, x, y, maxWidth);
      return;
    }
  }

  ImageData getImageData(num sx, num sy, num sw, num sh) {
    return LevelDom.wrapImageData(_ptr.getImageData(sx, sy, sw, sh));
  }

  bool isPointInPath(num x, num y) {
    return _ptr.isPointInPath(x, y);
  }

  void lineTo(num x, num y) {
    _ptr.lineTo(x, y);
    return;
  }

  TextMetrics measureText(String text) {
    return LevelDom.wrapTextMetrics(_ptr.measureText(text));
  }

  void moveTo(num x, num y) {
    _ptr.moveTo(x, y);
    return;
  }

  void putImageData(ImageData imagedata, num dx, num dy, [num dirtyX = null, num dirtyY = null, num dirtyWidth = null, num dirtyHeight = null]) {
    if (dirtyX === null) {
      if (dirtyY === null) {
        if (dirtyWidth === null) {
          if (dirtyHeight === null) {
            _ptr.putImageData(LevelDom.unwrap(imagedata), dx, dy);
            return;
          }
        }
      }
    } else {
      _ptr.putImageData(LevelDom.unwrap(imagedata), dx, dy, dirtyX, dirtyY, dirtyWidth, dirtyHeight);
      return;
    }
    throw "Incorrect number or type of arguments";
  }

  void quadraticCurveTo(num cpx, num cpy, num x, num y) {
    _ptr.quadraticCurveTo(cpx, cpy, x, y);
    return;
  }

  void rect(num x, num y, num width, num height) {
    _ptr.rect(x, y, width, height);
    return;
  }

  void restore() {
    _ptr.restore();
    return;
  }

  void rotate(num angle) {
    _ptr.rotate(angle);
    return;
  }

  void save() {
    _ptr.save();
    return;
  }

  void scale(num sx, num sy) {
    _ptr.scale(sx, sy);
    return;
  }

  void setAlpha(num alpha) {
    _ptr.setAlpha(alpha);
    return;
  }

  void setCompositeOperation(String compositeOperation) {
    _ptr.setCompositeOperation(compositeOperation);
    return;
  }

  void setFillColor(var c_OR_color_OR_grayLevel_OR_r, [num alpha_OR_g_OR_m = null, num b_OR_y = null, num a_OR_k = null, num a = null]) {
    if (c_OR_color_OR_grayLevel_OR_r is String) {
      if (alpha_OR_g_OR_m === null) {
        if (b_OR_y === null) {
          if (a_OR_k === null) {
            if (a === null) {
              _ptr.setFillColor(LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r));
              return;
            }
          }
        }
      } else {
        if (b_OR_y === null) {
          if (a_OR_k === null) {
            if (a === null) {
              _ptr.setFillColor(LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m);
              return;
            }
          }
        }
      }
    } else {
      if (c_OR_color_OR_grayLevel_OR_r is num) {
        if (alpha_OR_g_OR_m === null) {
          if (b_OR_y === null) {
            if (a_OR_k === null) {
              if (a === null) {
                _ptr.setFillColor(LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r));
                return;
              }
            }
          }
        } else {
          if (b_OR_y === null) {
            if (a_OR_k === null) {
              if (a === null) {
                _ptr.setFillColor(LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m);
                return;
              }
            }
          } else {
            if (a === null) {
              _ptr.setFillColor(LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m, b_OR_y, a_OR_k);
              return;
            } else {
              _ptr.setFillColor(LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m, b_OR_y, a_OR_k, a);
              return;
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void setLineCap(String cap) {
    _ptr.setLineCap(cap);
    return;
  }

  void setLineJoin(String join) {
    _ptr.setLineJoin(join);
    return;
  }

  void setLineWidth(num width) {
    _ptr.setLineWidth(width);
    return;
  }

  void setMiterLimit(num limit) {
    _ptr.setMiterLimit(limit);
    return;
  }

  void setShadow(num width, num height, num blur, [var c_OR_color_OR_grayLevel_OR_r = null, num alpha_OR_g_OR_m = null, num b_OR_y = null, num a_OR_k = null, num a = null]) {
    if (c_OR_color_OR_grayLevel_OR_r === null) {
      if (alpha_OR_g_OR_m === null) {
        if (b_OR_y === null) {
          if (a_OR_k === null) {
            if (a === null) {
              _ptr.setShadow(width, height, blur);
              return;
            }
          }
        }
      }
    } else {
      if (c_OR_color_OR_grayLevel_OR_r is String) {
        if (alpha_OR_g_OR_m === null) {
          if (b_OR_y === null) {
            if (a_OR_k === null) {
              if (a === null) {
                _ptr.setShadow(width, height, blur, LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r));
                return;
              }
            }
          }
        } else {
          if (b_OR_y === null) {
            if (a_OR_k === null) {
              if (a === null) {
                _ptr.setShadow(width, height, blur, LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m);
                return;
              }
            }
          }
        }
      } else {
        if (c_OR_color_OR_grayLevel_OR_r is num) {
          if (alpha_OR_g_OR_m === null) {
            if (b_OR_y === null) {
              if (a_OR_k === null) {
                if (a === null) {
                  _ptr.setShadow(width, height, blur, LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r));
                  return;
                }
              }
            }
          } else {
            if (b_OR_y === null) {
              if (a_OR_k === null) {
                if (a === null) {
                  _ptr.setShadow(width, height, blur, LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m);
                  return;
                }
              }
            } else {
              if (a === null) {
                _ptr.setShadow(width, height, blur, LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m, b_OR_y, a_OR_k);
                return;
              } else {
                _ptr.setShadow(width, height, blur, LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m, b_OR_y, a_OR_k, a);
                return;
              }
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void setStrokeColor(var c_OR_color_OR_grayLevel_OR_r, [num alpha_OR_g_OR_m = null, num b_OR_y = null, num a_OR_k = null, num a = null]) {
    if (c_OR_color_OR_grayLevel_OR_r is String) {
      if (alpha_OR_g_OR_m === null) {
        if (b_OR_y === null) {
          if (a_OR_k === null) {
            if (a === null) {
              _ptr.setStrokeColor(LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r));
              return;
            }
          }
        }
      } else {
        if (b_OR_y === null) {
          if (a_OR_k === null) {
            if (a === null) {
              _ptr.setStrokeColor(LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m);
              return;
            }
          }
        }
      }
    } else {
      if (c_OR_color_OR_grayLevel_OR_r is num) {
        if (alpha_OR_g_OR_m === null) {
          if (b_OR_y === null) {
            if (a_OR_k === null) {
              if (a === null) {
                _ptr.setStrokeColor(LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r));
                return;
              }
            }
          }
        } else {
          if (b_OR_y === null) {
            if (a_OR_k === null) {
              if (a === null) {
                _ptr.setStrokeColor(LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m);
                return;
              }
            }
          } else {
            if (a === null) {
              _ptr.setStrokeColor(LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m, b_OR_y, a_OR_k);
              return;
            } else {
              _ptr.setStrokeColor(LevelDom.unwrapMaybePrimitive(c_OR_color_OR_grayLevel_OR_r), alpha_OR_g_OR_m, b_OR_y, a_OR_k, a);
              return;
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void setTransform(num m11, num m12, num m21, num m22, num dx, num dy) {
    _ptr.setTransform(m11, m12, m21, m22, dx, dy);
    return;
  }

  void stroke() {
    _ptr.stroke();
    return;
  }

  void strokeRect(num x, num y, num width, num height, [num lineWidth = null]) {
    if (lineWidth === null) {
      _ptr.strokeRect(x, y, width, height);
      return;
    } else {
      _ptr.strokeRect(x, y, width, height, lineWidth);
      return;
    }
  }

  void strokeText(String text, num x, num y, [num maxWidth = null]) {
    if (maxWidth === null) {
      _ptr.strokeText(text, x, y);
      return;
    } else {
      _ptr.strokeText(text, x, y, maxWidth);
      return;
    }
  }

  void transform(num m11, num m12, num m21, num m22, num dx, num dy) {
    _ptr.transform(m11, m12, m21, m22, dx, dy);
    return;
  }

  void translate(num tx, num ty) {
    _ptr.translate(tx, ty);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CanvasRenderingContextWrappingImplementation extends DOMWrapperBase implements CanvasRenderingContext {
  CanvasRenderingContextWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  CanvasElement get canvas() { return LevelDom.wrapCanvasElement(_ptr.canvas); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CharacterDataWrappingImplementation extends NodeWrappingImplementation implements CharacterData {
  CharacterDataWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get data() { return _ptr.data; }

  void set data(String value) { _ptr.data = value; }

  int get length() { return _ptr.length; }

  void appendData(String data) {
    _ptr.appendData(data);
    return;
  }

  void deleteData(int offset, int length) {
    _ptr.deleteData(offset, length);
    return;
  }

  void insertData(int offset, String data) {
    _ptr.insertData(offset, data);
    return;
  }

  void replaceData(int offset, int length, String data) {
    _ptr.replaceData(offset, length, data);
    return;
  }

  String substringData(int offset, int length) {
    return _ptr.substringData(offset, length);
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ClientRectListWrappingImplementation extends DOMWrapperBase implements ClientRectList {
  ClientRectListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  ClientRect item(int index) {
    return LevelDom.wrapClientRect(_ptr.item(index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ClientRectWrappingImplementation extends DOMWrapperBase implements ClientRect {
  ClientRectWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get bottom() { return _ptr.bottom; }

  num get height() { return _ptr.height; }

  num get left() { return _ptr.left; }

  num get right() { return _ptr.right; }

  num get top() { return _ptr.top; }

  num get width() { return _ptr.width; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ClipboardWrappingImplementation extends DOMWrapperBase implements Clipboard {
  ClipboardWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get dropEffect() { return _ptr.dropEffect; }

  void set dropEffect(String value) { _ptr.dropEffect = value; }

  String get effectAllowed() { return _ptr.effectAllowed; }

  void set effectAllowed(String value) { _ptr.effectAllowed = value; }

  FileList get files() { return LevelDom.wrapFileList(_ptr.files); }

  DataTransferItemList get items() { return LevelDom.wrapDataTransferItemList(_ptr.items); }

  List get types() { return _ptr.types; }

  void clearData([String type]) {
    if (type === null) {
      _ptr.clearData();
      return;
    } else {
      _ptr.clearData(type);
      return;
    }
  }

  void getData(String type) {
    _ptr.getData(type);
    return;
  }

  bool setData(String type, String data) {
    return _ptr.setData(type, data);
  }

  void setDragImage(ImageElement image, int x, int y) {
    _ptr.setDragImage(LevelDom.unwrap(image), x, y);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CommentWrappingImplementation extends CharacterDataWrappingImplementation implements Comment {
  CommentWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ConsoleWrappingImplementation extends DOMWrapperBase implements Console {
  ConsoleWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void count() {
    _ptr.count();
    return;
  }

  void debug(Object arg) {
    _ptr.debug(LevelDom.unwrapMaybePrimitive(arg));
    return;
  }

  void dir() {
    _ptr.dir();
    return;
  }

  void dirxml() {
    _ptr.dirxml();
    return;
  }

  void error(Object arg) {
    _ptr.error(LevelDom.unwrapMaybePrimitive(arg));
    return;
  }

  void group() {
    _ptr.group();
    return;
  }

  void groupCollapsed() {
    _ptr.groupCollapsed();
    return;
  }

  void groupEnd() {
    _ptr.groupEnd();
    return;
  }

  void info(Object arg) {
    _ptr.info(LevelDom.unwrapMaybePrimitive(arg));
    return;
  }

  void log(Object arg) {
    _ptr.log(LevelDom.unwrapMaybePrimitive(arg));
    return;
  }

  void markTimeline() {
    _ptr.markTimeline();
    return;
  }

  void time(String title) {
    _ptr.time(title);
    return;
  }

  void timeEnd(String title) {
    _ptr.timeEnd(title);
    return;
  }

  void timeStamp() {
    _ptr.timeStamp();
    return;
  }

  void trace(Object arg) {
    _ptr.trace(LevelDom.unwrapMaybePrimitive(arg));
    return;
  }

  void warn(Object arg) {
    _ptr.warn(LevelDom.unwrapMaybePrimitive(arg));
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ConvolverNodeWrappingImplementation extends AudioNodeWrappingImplementation implements ConvolverNode {
  ConvolverNodeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  AudioBuffer get buffer() { return LevelDom.wrapAudioBuffer(_ptr.buffer); }

  void set buffer(AudioBuffer value) { _ptr.buffer = LevelDom.unwrap(value); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CoordinatesWrappingImplementation extends DOMWrapperBase implements Coordinates {
  CoordinatesWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get accuracy() { return _ptr.accuracy; }

  num get altitude() { return _ptr.altitude; }

  num get altitudeAccuracy() { return _ptr.altitudeAccuracy; }

  num get heading() { return _ptr.heading; }

  num get latitude() { return _ptr.latitude; }

  num get longitude() { return _ptr.longitude; }

  num get speed() { return _ptr.speed; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CounterWrappingImplementation extends DOMWrapperBase implements Counter {
  CounterWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get identifier() { return _ptr.identifier; }

  String get listStyle() { return _ptr.listStyle; }

  String get separator() { return _ptr.separator; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CryptoWrappingImplementation extends DOMWrapperBase implements Crypto {
  CryptoWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void getRandomValues(ArrayBufferView array) {
    _ptr.getRandomValues(LevelDom.unwrap(array));
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DListElementWrappingImplementation extends ElementWrappingImplementation implements DListElement {
  DListElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get compact() { return _ptr.compact; }

  void set compact(bool value) { _ptr.compact = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMExceptionWrappingImplementation extends DOMWrapperBase implements DOMException {
  DOMExceptionWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get code() { return _ptr.code; }

  String get message() { return _ptr.message; }

  String get name() { return _ptr.name; }

  String toString() {
    return _ptr.toString();
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMFileSystemSyncWrappingImplementation extends DOMWrapperBase implements DOMFileSystemSync {
  DOMFileSystemSyncWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get name() { return _ptr.name; }

  DirectoryEntrySync get root() { return LevelDom.wrapDirectoryEntrySync(_ptr.root); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMFileSystemWrappingImplementation extends DOMWrapperBase implements DOMFileSystem {
  DOMFileSystemWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get name() { return _ptr.name; }

  DirectoryEntry get root() { return LevelDom.wrapDirectoryEntry(_ptr.root); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMFormDataWrappingImplementation extends DOMWrapperBase implements DOMFormData {
  DOMFormDataWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void append(String name, String value, String filename) {
    _ptr.append(name, value, filename);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMMimeTypeArrayWrappingImplementation extends DOMWrapperBase implements DOMMimeTypeArray {
  DOMMimeTypeArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  DOMMimeType item(int index) {
    return LevelDom.wrapDOMMimeType(_ptr.item(index));
  }

  DOMMimeType namedItem(String name) {
    return LevelDom.wrapDOMMimeType(_ptr.namedItem(name));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMMimeTypeWrappingImplementation extends DOMWrapperBase implements DOMMimeType {
  DOMMimeTypeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get description() { return _ptr.description; }

  DOMPlugin get enabledPlugin() { return LevelDom.wrapDOMPlugin(_ptr.enabledPlugin); }

  String get suffixes() { return _ptr.suffixes; }

  String get type() { return _ptr.type; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMParserWrappingImplementation extends DOMWrapperBase implements DOMParser {
  DOMParserWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  Document parseFromString(String str, String contentType) {
    return LevelDom.wrapDocument(_ptr.parseFromString(str, contentType));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMPluginArrayWrappingImplementation extends DOMWrapperBase implements DOMPluginArray {
  DOMPluginArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  DOMPlugin item(int index) {
    return LevelDom.wrapDOMPlugin(_ptr.item(index));
  }

  DOMPlugin namedItem(String name) {
    return LevelDom.wrapDOMPlugin(_ptr.namedItem(name));
  }

  void refresh(bool reload) {
    _ptr.refresh(reload);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMPluginWrappingImplementation extends DOMWrapperBase implements DOMPlugin {
  DOMPluginWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get description() { return _ptr.description; }

  String get filename() { return _ptr.filename; }

  int get length() { return _ptr.length; }

  String get name() { return _ptr.name; }

  DOMMimeType item(int index) {
    return LevelDom.wrapDOMMimeType(_ptr.item(index));
  }

  DOMMimeType namedItem(String name) {
    return LevelDom.wrapDOMMimeType(_ptr.namedItem(name));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMSelectionWrappingImplementation extends DOMWrapperBase implements DOMSelection {
  DOMSelectionWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  Node get anchorNode() { return LevelDom.wrapNode(_ptr.anchorNode); }

  int get anchorOffset() { return _ptr.anchorOffset; }

  Node get baseNode() { return LevelDom.wrapNode(_ptr.baseNode); }

  int get baseOffset() { return _ptr.baseOffset; }

  Node get extentNode() { return LevelDom.wrapNode(_ptr.extentNode); }

  int get extentOffset() { return _ptr.extentOffset; }

  Node get focusNode() { return LevelDom.wrapNode(_ptr.focusNode); }

  int get focusOffset() { return _ptr.focusOffset; }

  bool get isCollapsed() { return _ptr.isCollapsed; }

  int get rangeCount() { return _ptr.rangeCount; }

  String get type() { return _ptr.type; }

  void addRange(Range range) {
    _ptr.addRange(LevelDom.unwrap(range));
    return;
  }

  void collapse(Node node, int index) {
    _ptr.collapse(LevelDom.unwrap(node), index);
    return;
  }

  void collapseToEnd() {
    _ptr.collapseToEnd();
    return;
  }

  void collapseToStart() {
    _ptr.collapseToStart();
    return;
  }

  bool containsNode(Node node, bool allowPartial) {
    return _ptr.containsNode(LevelDom.unwrap(node), allowPartial);
  }

  void deleteFromDocument() {
    _ptr.deleteFromDocument();
    return;
  }

  void empty() {
    _ptr.empty();
    return;
  }

  void extend(Node node, int offset) {
    _ptr.extend(LevelDom.unwrap(node), offset);
    return;
  }

  Range getRangeAt(int index) {
    return LevelDom.wrapRange(_ptr.getRangeAt(index));
  }

  void modify(String alter, String direction, String granularity) {
    _ptr.modify(alter, direction, granularity);
    return;
  }

  void removeAllRanges() {
    _ptr.removeAllRanges();
    return;
  }

  void selectAllChildren(Node node) {
    _ptr.selectAllChildren(LevelDom.unwrap(node));
    return;
  }

  void setBaseAndExtent(Node baseNode, int baseOffset, Node extentNode, int extentOffset) {
    _ptr.setBaseAndExtent(LevelDom.unwrap(baseNode), baseOffset, LevelDom.unwrap(extentNode), extentOffset);
    return;
  }

  void setPosition(Node node, int offset) {
    _ptr.setPosition(LevelDom.unwrap(node), offset);
    return;
  }

  String toString() {
    return _ptr.toString();
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMSettableTokenListWrappingImplementation extends DOMTokenListWrappingImplementation implements DOMSettableTokenList {
  DOMSettableTokenListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get value() { return _ptr.value; }

  void set value(String value) { _ptr.value = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMTokenListWrappingImplementation extends DOMWrapperBase implements DOMTokenList {
  DOMTokenListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  void add(String token) {
    _ptr.add(token);
    return;
  }

  bool contains(String token) {
    return _ptr.contains(token);
  }

  String item(int index) {
    return _ptr.item(index);
  }

  void remove(String token) {
    _ptr.remove(token);
    return;
  }

  String toString() {
    return _ptr.toString();
  }

  bool toggle(String token) {
    return _ptr.toggle(token);
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DOMURLWrappingImplementation extends DOMWrapperBase implements DOMURL {
  DOMURLWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String createObjectURL(Blob blob) {
    return _ptr.createObjectURL(LevelDom.unwrap(blob));
  }

  void revokeObjectURL(String url) {
    _ptr.revokeObjectURL(url);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DataListElementWrappingImplementation extends ElementWrappingImplementation implements DataListElement {
  DataListElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  ElementList get options() { return LevelDom.wrapElementList(_ptr.options); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DataTransferItemListWrappingImplementation extends DOMWrapperBase implements DataTransferItemList {
  DataTransferItemListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  void add(String data, String type) {
    _ptr.add(data, type);
    return;
  }

  void clear() {
    _ptr.clear();
    return;
  }

  DataTransferItem item(int index) {
    return LevelDom.wrapDataTransferItem(_ptr.item(index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DataTransferItemWrappingImplementation extends DOMWrapperBase implements DataTransferItem {
  DataTransferItemWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get kind() { return _ptr.kind; }

  String get type() { return _ptr.type; }

  Blob getAsFile() {
    return LevelDom.wrapBlob(_ptr.getAsFile());
  }

  void getAsString(StringCallback callback) {
    _ptr.getAsString(callback);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DataViewWrappingImplementation extends ArrayBufferViewWrappingImplementation implements DataView {
  DataViewWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num getFloat32(int byteOffset, [bool littleEndian]) {
    if (littleEndian === null) {
      return _ptr.getFloat32(byteOffset);
    } else {
      return _ptr.getFloat32(byteOffset, littleEndian);
    }
  }

  num getFloat64(int byteOffset, [bool littleEndian]) {
    if (littleEndian === null) {
      return _ptr.getFloat64(byteOffset);
    } else {
      return _ptr.getFloat64(byteOffset, littleEndian);
    }
  }

  int getInt16(int byteOffset, [bool littleEndian]) {
    if (littleEndian === null) {
      return _ptr.getInt16(byteOffset);
    } else {
      return _ptr.getInt16(byteOffset, littleEndian);
    }
  }

  int getInt32(int byteOffset, [bool littleEndian]) {
    if (littleEndian === null) {
      return _ptr.getInt32(byteOffset);
    } else {
      return _ptr.getInt32(byteOffset, littleEndian);
    }
  }

  int getInt8() {
    return _ptr.getInt8();
  }

  int getUint16(int byteOffset, [bool littleEndian]) {
    if (littleEndian === null) {
      return _ptr.getUint16(byteOffset);
    } else {
      return _ptr.getUint16(byteOffset, littleEndian);
    }
  }

  int getUint32(int byteOffset, [bool littleEndian]) {
    if (littleEndian === null) {
      return _ptr.getUint32(byteOffset);
    } else {
      return _ptr.getUint32(byteOffset, littleEndian);
    }
  }

  int getUint8() {
    return _ptr.getUint8();
  }

  void setFloat32(int byteOffset, num value, [bool littleEndian]) {
    if (littleEndian === null) {
      _ptr.setFloat32(byteOffset, value);
      return;
    } else {
      _ptr.setFloat32(byteOffset, value, littleEndian);
      return;
    }
  }

  void setFloat64(int byteOffset, num value, [bool littleEndian]) {
    if (littleEndian === null) {
      _ptr.setFloat64(byteOffset, value);
      return;
    } else {
      _ptr.setFloat64(byteOffset, value, littleEndian);
      return;
    }
  }

  void setInt16(int byteOffset, int value, [bool littleEndian]) {
    if (littleEndian === null) {
      _ptr.setInt16(byteOffset, value);
      return;
    } else {
      _ptr.setInt16(byteOffset, value, littleEndian);
      return;
    }
  }

  void setInt32(int byteOffset, int value, [bool littleEndian]) {
    if (littleEndian === null) {
      _ptr.setInt32(byteOffset, value);
      return;
    } else {
      _ptr.setInt32(byteOffset, value, littleEndian);
      return;
    }
  }

  void setInt8() {
    _ptr.setInt8();
    return;
  }

  void setUint16(int byteOffset, int value, [bool littleEndian]) {
    if (littleEndian === null) {
      _ptr.setUint16(byteOffset, value);
      return;
    } else {
      _ptr.setUint16(byteOffset, value, littleEndian);
      return;
    }
  }

  void setUint32(int byteOffset, int value, [bool littleEndian]) {
    if (littleEndian === null) {
      _ptr.setUint32(byteOffset, value);
      return;
    } else {
      _ptr.setUint32(byteOffset, value, littleEndian);
      return;
    }
  }

  void setUint8() {
    _ptr.setUint8();
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DelayNodeWrappingImplementation extends AudioNodeWrappingImplementation implements DelayNode {
  DelayNodeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  AudioParam get delayTime() { return LevelDom.wrapAudioParam(_ptr.delayTime); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DetailsElementWrappingImplementation extends ElementWrappingImplementation implements DetailsElement {
  DetailsElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get open() { return _ptr.open; }

  void set open(bool value) { _ptr.open = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DirectoryEntrySyncWrappingImplementation extends EntrySyncWrappingImplementation implements DirectoryEntrySync {
  DirectoryEntrySyncWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  DirectoryReaderSync createReader() {
    return LevelDom.wrapDirectoryReaderSync(_ptr.createReader());
  }

  DirectoryEntrySync getDirectory(String path, Flags flags) {
    return LevelDom.wrapDirectoryEntrySync(_ptr.getDirectory(path, LevelDom.unwrap(flags)));
  }

  FileEntrySync getFile(String path, Flags flags) {
    return LevelDom.wrapFileEntrySync(_ptr.getFile(path, LevelDom.unwrap(flags)));
  }

  void removeRecursively() {
    _ptr.removeRecursively();
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DirectoryEntryWrappingImplementation extends EntryWrappingImplementation implements DirectoryEntry {
  DirectoryEntryWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  DirectoryReader createReader() {
    return LevelDom.wrapDirectoryReader(_ptr.createReader());
  }

  void getDirectory(String path, [Flags flags, EntryCallback successCallback, ErrorCallback errorCallback]) {
    if (flags === null) {
      if (successCallback === null) {
        if (errorCallback === null) {
          _ptr.getDirectory(path);
          return;
        }
      }
    } else {
      if (successCallback === null) {
        if (errorCallback === null) {
          _ptr.getDirectory(path, LevelDom.unwrap(flags));
          return;
        }
      } else {
        if (errorCallback === null) {
          _ptr.getDirectory(path, LevelDom.unwrap(flags), successCallback);
          return;
        } else {
          _ptr.getDirectory(path, LevelDom.unwrap(flags), successCallback, LevelDom.unwrap(errorCallback));
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void getFile(String path, [Flags flags, EntryCallback successCallback, ErrorCallback errorCallback]) {
    if (flags === null) {
      if (successCallback === null) {
        if (errorCallback === null) {
          _ptr.getFile(path);
          return;
        }
      }
    } else {
      if (successCallback === null) {
        if (errorCallback === null) {
          _ptr.getFile(path, LevelDom.unwrap(flags));
          return;
        }
      } else {
        if (errorCallback === null) {
          _ptr.getFile(path, LevelDom.unwrap(flags), successCallback);
          return;
        } else {
          _ptr.getFile(path, LevelDom.unwrap(flags), successCallback, LevelDom.unwrap(errorCallback));
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void removeRecursively([VoidCallback successCallback, ErrorCallback errorCallback]) {
    if (successCallback === null) {
      if (errorCallback === null) {
        _ptr.removeRecursively();
        return;
      }
    } else {
      if (errorCallback === null) {
        _ptr.removeRecursively(LevelDom.unwrap(successCallback));
        return;
      } else {
        _ptr.removeRecursively(LevelDom.unwrap(successCallback), LevelDom.unwrap(errorCallback));
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DirectoryReaderSyncWrappingImplementation extends DOMWrapperBase implements DirectoryReaderSync {
  DirectoryReaderSyncWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  EntryArraySync readEntries() {
    return LevelDom.wrapEntryArraySync(_ptr.readEntries());
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DirectoryReaderWrappingImplementation extends DOMWrapperBase implements DirectoryReader {
  DirectoryReaderWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void readEntries(EntriesCallback successCallback, [ErrorCallback errorCallback]) {
    if (errorCallback === null) {
      _ptr.readEntries(successCallback);
      return;
    } else {
      _ptr.readEntries(successCallback, LevelDom.unwrap(errorCallback));
      return;
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DivElementWrappingImplementation extends ElementWrappingImplementation implements DivElement {
  DivElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DynamicsCompressorNodeWrappingImplementation extends AudioNodeWrappingImplementation implements DynamicsCompressorNode {
  DynamicsCompressorNodeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ElementTimeControlWrappingImplementation extends DOMWrapperBase implements ElementTimeControl {
  ElementTimeControlWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void beginElement() {
    _ptr.beginElement();
    return;
  }

  void beginElementAt(num offset) {
    _ptr.beginElementAt(offset);
    return;
  }

  void endElement() {
    _ptr.endElement();
    return;
  }

  void endElementAt(num offset) {
    _ptr.endElementAt(offset);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class EmbedElementWrappingImplementation extends ElementWrappingImplementation implements EmbedElement {
  EmbedElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }

  String get height() { return _ptr.height; }

  void set height(String value) { _ptr.height = value; }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  String get src() { return _ptr.src; }

  void set src(String value) { _ptr.src = value; }

  String get type() { return _ptr.type; }

  void set type(String value) { _ptr.type = value; }

  String get width() { return _ptr.width; }

  void set width(String value) { _ptr.width = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class EntityReferenceWrappingImplementation extends NodeWrappingImplementation implements EntityReference {
  EntityReferenceWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class EntityWrappingImplementation extends NodeWrappingImplementation implements Entity {
  EntityWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get notationName() { return _ptr.notationName; }

  String get publicId() { return _ptr.publicId; }

  String get systemId() { return _ptr.systemId; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class EntryArraySyncWrappingImplementation extends DOMWrapperBase implements EntryArraySync {
  EntryArraySyncWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  EntrySync item(int index) {
    return LevelDom.wrapEntrySync(_ptr.item(index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class EntryArrayWrappingImplementation extends DOMWrapperBase implements EntryArray {
  EntryArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  Entry item(int index) {
    return LevelDom.wrapEntry(_ptr.item(index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class EntrySyncWrappingImplementation extends DOMWrapperBase implements EntrySync {
  EntrySyncWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  DOMFileSystemSync get filesystem() { return LevelDom.wrapDOMFileSystemSync(_ptr.filesystem); }

  String get fullPath() { return _ptr.fullPath; }

  bool get isDirectory() { return _ptr.isDirectory; }

  bool get isFile() { return _ptr.isFile; }

  String get name() { return _ptr.name; }

  EntrySync copyTo(DirectoryEntrySync parent, String name) {
    return LevelDom.wrapEntrySync(_ptr.copyTo(LevelDom.unwrap(parent), name));
  }

  Metadata getMetadata() {
    return LevelDom.wrapMetadata(_ptr.getMetadata());
  }

  DirectoryEntrySync getParent() {
    return LevelDom.wrapDirectoryEntrySync(_ptr.getParent());
  }

  EntrySync moveTo(DirectoryEntrySync parent, String name) {
    return LevelDom.wrapEntrySync(_ptr.moveTo(LevelDom.unwrap(parent), name));
  }

  void remove() {
    _ptr.remove();
    return;
  }

  String toURL() {
    return _ptr.toURL();
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class EntryWrappingImplementation extends DOMWrapperBase implements Entry {
  EntryWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  DOMFileSystem get filesystem() { return LevelDom.wrapDOMFileSystem(_ptr.filesystem); }

  String get fullPath() { return _ptr.fullPath; }

  bool get isDirectory() { return _ptr.isDirectory; }

  bool get isFile() { return _ptr.isFile; }

  String get name() { return _ptr.name; }

  void copyTo(DirectoryEntry parent, [String name, EntryCallback successCallback, ErrorCallback errorCallback]) {
    if (name === null) {
      if (successCallback === null) {
        if (errorCallback === null) {
          _ptr.copyTo(LevelDom.unwrap(parent));
          return;
        }
      }
    } else {
      if (successCallback === null) {
        if (errorCallback === null) {
          _ptr.copyTo(LevelDom.unwrap(parent), name);
          return;
        }
      } else {
        if (errorCallback === null) {
          _ptr.copyTo(LevelDom.unwrap(parent), name, successCallback);
          return;
        } else {
          _ptr.copyTo(LevelDom.unwrap(parent), name, successCallback, LevelDom.unwrap(errorCallback));
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void getMetadata([MetadataCallback successCallback, ErrorCallback errorCallback]) {
    if (successCallback === null) {
      if (errorCallback === null) {
        _ptr.getMetadata();
        return;
      }
    } else {
      if (errorCallback === null) {
        _ptr.getMetadata(successCallback);
        return;
      } else {
        _ptr.getMetadata(successCallback, LevelDom.unwrap(errorCallback));
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void getParent([EntryCallback successCallback, ErrorCallback errorCallback]) {
    if (successCallback === null) {
      if (errorCallback === null) {
        _ptr.getParent();
        return;
      }
    } else {
      if (errorCallback === null) {
        _ptr.getParent(successCallback);
        return;
      } else {
        _ptr.getParent(successCallback, LevelDom.unwrap(errorCallback));
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void moveTo(DirectoryEntry parent, [String name, EntryCallback successCallback, ErrorCallback errorCallback]) {
    if (name === null) {
      if (successCallback === null) {
        if (errorCallback === null) {
          _ptr.moveTo(LevelDom.unwrap(parent));
          return;
        }
      }
    } else {
      if (successCallback === null) {
        if (errorCallback === null) {
          _ptr.moveTo(LevelDom.unwrap(parent), name);
          return;
        }
      } else {
        if (errorCallback === null) {
          _ptr.moveTo(LevelDom.unwrap(parent), name, successCallback);
          return;
        } else {
          _ptr.moveTo(LevelDom.unwrap(parent), name, successCallback, LevelDom.unwrap(errorCallback));
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void remove([VoidCallback successCallback, ErrorCallback errorCallback]) {
    if (successCallback === null) {
      if (errorCallback === null) {
        _ptr.remove();
        return;
      }
    } else {
      if (errorCallback === null) {
        _ptr.remove(LevelDom.unwrap(successCallback));
        return;
      } else {
        _ptr.remove(LevelDom.unwrap(successCallback), LevelDom.unwrap(errorCallback));
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }

  String toURL() {
    return _ptr.toURL();
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class EventExceptionWrappingImplementation extends DOMWrapperBase implements EventException {
  EventExceptionWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get code() { return _ptr.code; }

  String get message() { return _ptr.message; }

  String get name() { return _ptr.name; }

  String toString() {
    return _ptr.toString();
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FieldSetElementWrappingImplementation extends ElementWrappingImplementation implements FieldSetElement {
  FieldSetElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  String get validationMessage() { return _ptr.validationMessage; }

  ValidityState get validity() { return LevelDom.wrapValidityState(_ptr.validity); }

  bool get willValidate() { return _ptr.willValidate; }

  bool checkValidity() {
    return _ptr.checkValidity();
  }

  void setCustomValidity(String error) {
    _ptr.setCustomValidity(error);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FileEntrySyncWrappingImplementation extends EntrySyncWrappingImplementation implements FileEntrySync {
  FileEntrySyncWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  FileWriterSync createWriter() {
    return LevelDom.wrapFileWriterSync(_ptr.createWriter());
  }

  File file() {
    return LevelDom.wrapFile(_ptr.file());
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FileEntryWrappingImplementation extends EntryWrappingImplementation implements FileEntry {
  FileEntryWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void createWriter(FileWriterCallback successCallback, [ErrorCallback errorCallback]) {
    if (errorCallback === null) {
      _ptr.createWriter(successCallback);
      return;
    } else {
      _ptr.createWriter(successCallback, LevelDom.unwrap(errorCallback));
      return;
    }
  }

  void file(FileCallback successCallback, [ErrorCallback errorCallback]) {
    if (errorCallback === null) {
      _ptr.file(successCallback);
      return;
    } else {
      _ptr.file(successCallback, LevelDom.unwrap(errorCallback));
      return;
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FileErrorWrappingImplementation extends DOMWrapperBase implements FileError {
  FileErrorWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get code() { return _ptr.code; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FileExceptionWrappingImplementation extends DOMWrapperBase implements FileException {
  FileExceptionWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get code() { return _ptr.code; }

  String get message() { return _ptr.message; }

  String get name() { return _ptr.name; }

  String toString() {
    return _ptr.toString();
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FileListWrappingImplementation extends DOMWrapperBase implements FileList {
  FileListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  File item(int index) {
    return LevelDom.wrapFile(_ptr.item(index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FileReaderSyncWrappingImplementation extends DOMWrapperBase implements FileReaderSync {
  FileReaderSyncWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  ArrayBuffer readAsArrayBuffer(Blob blob) {
    return LevelDom.wrapArrayBuffer(_ptr.readAsArrayBuffer(LevelDom.unwrap(blob)));
  }

  String readAsBinaryString(Blob blob) {
    return _ptr.readAsBinaryString(LevelDom.unwrap(blob));
  }

  String readAsDataURL(Blob blob) {
    return _ptr.readAsDataURL(LevelDom.unwrap(blob));
  }

  String readAsText(Blob blob, [String encoding]) {
    if (encoding === null) {
      return _ptr.readAsText(LevelDom.unwrap(blob));
    } else {
      return _ptr.readAsText(LevelDom.unwrap(blob), encoding);
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FileReaderWrappingImplementation extends DOMWrapperBase implements FileReader {
  FileReaderWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  FileError get error() { return LevelDom.wrapFileError(_ptr.error); }

  int get readyState() { return _ptr.readyState; }

  String get result() { return _ptr.result; }

  void abort() {
    _ptr.abort();
    return;
  }

  void readAsArrayBuffer(Blob blob) {
    _ptr.readAsArrayBuffer(LevelDom.unwrap(blob));
    return;
  }

  void readAsBinaryString(Blob blob) {
    _ptr.readAsBinaryString(LevelDom.unwrap(blob));
    return;
  }

  void readAsDataURL(Blob blob) {
    _ptr.readAsDataURL(LevelDom.unwrap(blob));
    return;
  }

  void readAsText(Blob blob, [String encoding]) {
    if (encoding === null) {
      _ptr.readAsText(LevelDom.unwrap(blob));
      return;
    } else {
      _ptr.readAsText(LevelDom.unwrap(blob), encoding);
      return;
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FileWrappingImplementation extends BlobWrappingImplementation implements File {
  FileWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get fileName() { return _ptr.fileName; }

  int get fileSize() { return _ptr.fileSize; }

  Date get lastModifiedDate() { return _ptr.lastModifiedDate; }

  String get name() { return _ptr.name; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FileWriterSyncWrappingImplementation extends DOMWrapperBase implements FileWriterSync {
  FileWriterSyncWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  int get position() { return _ptr.position; }

  void seek(int position) {
    _ptr.seek(position);
    return;
  }

  void truncate(int size) {
    _ptr.truncate(size);
    return;
  }

  void write(Blob data) {
    _ptr.write(LevelDom.unwrap(data));
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FileWriterWrappingImplementation extends DOMWrapperBase implements FileWriter {
  FileWriterWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  FileError get error() { return LevelDom.wrapFileError(_ptr.error); }

  int get length() { return _ptr.length; }

  int get position() { return _ptr.position; }

  int get readyState() { return _ptr.readyState; }

  void abort() {
    _ptr.abort();
    return;
  }

  void seek(int position) {
    _ptr.seek(position);
    return;
  }

  void truncate(int size) {
    _ptr.truncate(size);
    return;
  }

  void write(Blob data) {
    _ptr.write(LevelDom.unwrap(data));
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FlagsWrappingImplementation extends DOMWrapperBase implements Flags {
  FlagsWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get create() { return _ptr.create; }

  void set create(bool value) { _ptr.create = value; }

  bool get exclusive() { return _ptr.exclusive; }

  void set exclusive(bool value) { _ptr.exclusive = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class Float32ArrayWrappingImplementation extends ArrayBufferViewWrappingImplementation implements Float32Array {
  Float32ArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  Float32Array subarray(int start, [int end]) {
    if (end === null) {
      return LevelDom.wrapFloat32Array(_ptr.subarray(start));
    } else {
      return LevelDom.wrapFloat32Array(_ptr.subarray(start, end));
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class Float64ArrayWrappingImplementation extends ArrayBufferViewWrappingImplementation implements Float64Array {
  Float64ArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  Float64Array subarray(int start, [int end]) {
    if (end === null) {
      return LevelDom.wrapFloat64Array(_ptr.subarray(start));
    } else {
      return LevelDom.wrapFloat64Array(_ptr.subarray(start, end));
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FontElementWrappingImplementation extends ElementWrappingImplementation implements FontElement {
  FontElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get color() { return _ptr.color; }

  void set color(String value) { _ptr.color = value; }

  String get face() { return _ptr.face; }

  void set face(String value) { _ptr.face = value; }

  String get size() { return _ptr.size; }

  void set size(String value) { _ptr.size = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FormElementWrappingImplementation extends ElementWrappingImplementation implements FormElement {
  FormElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get acceptCharset() { return _ptr.acceptCharset; }

  void set acceptCharset(String value) { _ptr.acceptCharset = value; }

  String get action() { return _ptr.action; }

  void set action(String value) { _ptr.action = value; }

  String get autocomplete() { return _ptr.autocomplete; }

  void set autocomplete(String value) { _ptr.autocomplete = value; }

  String get encoding() { return _ptr.encoding; }

  void set encoding(String value) { _ptr.encoding = value; }

  String get enctype() { return _ptr.enctype; }

  void set enctype(String value) { _ptr.enctype = value; }

  int get length() { return _ptr.length; }

  String get method() { return _ptr.method; }

  void set method(String value) { _ptr.method = value; }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  bool get noValidate() { return _ptr.noValidate; }

  void set noValidate(bool value) { _ptr.noValidate = value; }

  String get target() { return _ptr.target; }

  void set target(String value) { _ptr.target = value; }

  bool checkValidity() {
    return _ptr.checkValidity();
  }

  void reset() {
    _ptr.reset();
    return;
  }

  void submit() {
    _ptr.submit();
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class GeolocationWrappingImplementation extends DOMWrapperBase implements Geolocation {
  GeolocationWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void clearWatch(int watchId) {
    _ptr.clearWatch(watchId);
    return;
  }

  void getCurrentPosition(PositionCallback successCallback, [PositionErrorCallback errorCallback]) {
    if (errorCallback === null) {
      _ptr.getCurrentPosition(successCallback);
      return;
    } else {
      _ptr.getCurrentPosition(successCallback, LevelDom.unwrap(errorCallback));
      return;
    }
  }

  int watchPosition(PositionCallback successCallback, [PositionErrorCallback errorCallback]) {
    if (errorCallback === null) {
      return _ptr.watchPosition(successCallback);
    } else {
      return _ptr.watchPosition(successCallback, LevelDom.unwrap(errorCallback));
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class GeopositionWrappingImplementation extends DOMWrapperBase implements Geoposition {
  GeopositionWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  Coordinates get coords() { return LevelDom.wrapCoordinates(_ptr.coords); }

  int get timestamp() { return _ptr.timestamp; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class HRElementWrappingImplementation extends ElementWrappingImplementation implements HRElement {
  HRElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }

  bool get noShade() { return _ptr.noShade; }

  void set noShade(bool value) { _ptr.noShade = value; }

  String get size() { return _ptr.size; }

  void set size(String value) { _ptr.size = value; }

  String get width() { return _ptr.width; }

  void set width(String value) { _ptr.width = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class HTMLAllCollectionWrappingImplementation extends DOMWrapperBase implements HTMLAllCollection {
  HTMLAllCollectionWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  Node item(int index) {
    return LevelDom.wrapNode(_ptr.item(index));
  }

  Node namedItem(String name) {
    return LevelDom.wrapNode(_ptr.namedItem(name));
  }

  ElementList tags(String name) {
    return LevelDom.wrapElementList(_ptr.tags(name));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class HeadElementWrappingImplementation extends ElementWrappingImplementation implements HeadElement {
  HeadElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get profile() { return _ptr.profile; }

  void set profile(String value) { _ptr.profile = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class HeadingElementWrappingImplementation extends ElementWrappingImplementation implements HeadingElement {
  HeadingElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class HighPass2FilterNodeWrappingImplementation extends AudioNodeWrappingImplementation implements HighPass2FilterNode {
  HighPass2FilterNodeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  AudioParam get cutoff() { return LevelDom.wrapAudioParam(_ptr.cutoff); }

  AudioParam get resonance() { return LevelDom.wrapAudioParam(_ptr.resonance); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class HistoryWrappingImplementation extends DOMWrapperBase implements History {
  HistoryWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  void back() {
    _ptr.back();
    return;
  }

  void forward() {
    _ptr.forward();
    return;
  }

  void go(int distance) {
    _ptr.go(distance);
    return;
  }

  void pushState(Object data, String title, [String url]) {
    if (url === null) {
      _ptr.pushState(LevelDom.unwrapMaybePrimitive(data), title);
      return;
    } else {
      _ptr.pushState(LevelDom.unwrapMaybePrimitive(data), title, url);
      return;
    }
  }

  void replaceState(Object data, String title, [String url]) {
    if (url === null) {
      _ptr.replaceState(LevelDom.unwrapMaybePrimitive(data), title);
      return;
    } else {
      _ptr.replaceState(LevelDom.unwrapMaybePrimitive(data), title, url);
      return;
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBAnyWrappingImplementation extends DOMWrapperBase implements IDBAny {
  IDBAnyWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBCursorWithValueWrappingImplementation extends IDBCursorWrappingImplementation implements IDBCursorWithValue {
  IDBCursorWithValueWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  IDBAny get value() { return LevelDom.wrapIDBAny(_ptr.value); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBCursorWrappingImplementation extends DOMWrapperBase implements IDBCursor {
  IDBCursorWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get direction() { return _ptr.direction; }

  IDBKey get key() { return LevelDom.wrapIDBKey(_ptr.key); }

  IDBKey get primaryKey() { return LevelDom.wrapIDBKey(_ptr.primaryKey); }

  IDBAny get source() { return LevelDom.wrapIDBAny(_ptr.source); }

  void continueFunction([IDBKey key]) {
    if (key === null) {
      _ptr.continueFunction();
      return;
    } else {
      _ptr.continueFunction(LevelDom.unwrap(key));
      return;
    }
  }

  IDBRequest delete() {
    return LevelDom.wrapIDBRequest(_ptr.delete());
  }

  IDBRequest update(String value) {
    return LevelDom.wrapIDBRequest(_ptr.update(value));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBDatabaseErrorWrappingImplementation extends DOMWrapperBase implements IDBDatabaseError {
  IDBDatabaseErrorWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get code() { return _ptr.code; }

  void set code(int value) { _ptr.code = value; }

  String get message() { return _ptr.message; }

  void set message(String value) { _ptr.message = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBDatabaseExceptionWrappingImplementation extends DOMWrapperBase implements IDBDatabaseException {
  IDBDatabaseExceptionWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get code() { return _ptr.code; }

  String get message() { return _ptr.message; }

  String get name() { return _ptr.name; }

  String toString() {
    return _ptr.toString();
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBDatabaseWrappingImplementation extends DOMWrapperBase implements IDBDatabase {
  IDBDatabaseWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get name() { return _ptr.name; }

  String get version() { return _ptr.version; }

  void addEventListener(String type, EventListener listener, [bool useCapture]) {
    if (useCapture === null) {
      _ptr.addEventListener(type, LevelDom.unwrap(listener));
      return;
    } else {
      _ptr.addEventListener(type, LevelDom.unwrap(listener), useCapture);
      return;
    }
  }

  void close() {
    _ptr.close();
    return;
  }

  IDBObjectStore createObjectStore(String name) {
    return LevelDom.wrapIDBObjectStore(_ptr.createObjectStore(name));
  }

  void deleteObjectStore(String name) {
    _ptr.deleteObjectStore(name);
    return;
  }

  bool dispatchEvent(Event evt) {
    return _ptr.dispatchEvent(LevelDom.unwrap(evt));
  }

  void removeEventListener(String type, EventListener listener, [bool useCapture]) {
    if (useCapture === null) {
      _ptr.removeEventListener(type, LevelDom.unwrap(listener));
      return;
    } else {
      _ptr.removeEventListener(type, LevelDom.unwrap(listener), useCapture);
      return;
    }
  }

  IDBVersionChangeRequest setVersion(String version) {
    return LevelDom.wrapIDBVersionChangeRequest(_ptr.setVersion(version));
  }

  IDBTransaction transaction(String storeName, int mode) {
    return LevelDom.wrapIDBTransaction(_ptr.transaction(storeName, mode));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBFactoryWrappingImplementation extends DOMWrapperBase implements IDBFactory {
  IDBFactoryWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int cmp(IDBKey first, IDBKey second) {
    return _ptr.cmp(LevelDom.unwrap(first), LevelDom.unwrap(second));
  }

  IDBVersionChangeRequest deleteDatabase(String name) {
    return LevelDom.wrapIDBVersionChangeRequest(_ptr.deleteDatabase(name));
  }

  IDBRequest getDatabaseNames() {
    return LevelDom.wrapIDBRequest(_ptr.getDatabaseNames());
  }

  IDBRequest open(String name) {
    return LevelDom.wrapIDBRequest(_ptr.open(name));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBIndexWrappingImplementation extends DOMWrapperBase implements IDBIndex {
  IDBIndexWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get keyPath() { return _ptr.keyPath; }

  String get name() { return _ptr.name; }

  IDBObjectStore get objectStore() { return LevelDom.wrapIDBObjectStore(_ptr.objectStore); }

  bool get unique() { return _ptr.unique; }

  IDBRequest getObject(IDBKey key) {
    return LevelDom.wrapIDBRequest(_ptr.getObject(LevelDom.unwrap(key)));
  }

  IDBRequest getKey(IDBKey key) {
    return LevelDom.wrapIDBRequest(_ptr.getKey(LevelDom.unwrap(key)));
  }

  IDBRequest openCursor([IDBKeyRange range, int direction]) {
    if (range === null) {
      if (direction === null) {
        return LevelDom.wrapIDBRequest(_ptr.openCursor());
      }
    } else {
      if (direction === null) {
        return LevelDom.wrapIDBRequest(_ptr.openCursor(LevelDom.unwrap(range)));
      } else {
        return LevelDom.wrapIDBRequest(_ptr.openCursor(LevelDom.unwrap(range), direction));
      }
    }
    throw "Incorrect number or type of arguments";
  }

  IDBRequest openKeyCursor([IDBKeyRange range, int direction]) {
    if (range === null) {
      if (direction === null) {
        return LevelDom.wrapIDBRequest(_ptr.openKeyCursor());
      }
    } else {
      if (direction === null) {
        return LevelDom.wrapIDBRequest(_ptr.openKeyCursor(LevelDom.unwrap(range)));
      } else {
        return LevelDom.wrapIDBRequest(_ptr.openKeyCursor(LevelDom.unwrap(range), direction));
      }
    }
    throw "Incorrect number or type of arguments";
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBKeyRangeWrappingImplementation extends DOMWrapperBase implements IDBKeyRange {
  IDBKeyRangeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  IDBKey get lower() { return LevelDom.wrapIDBKey(_ptr.lower); }

  bool get lowerOpen() { return _ptr.lowerOpen; }

  IDBKey get upper() { return LevelDom.wrapIDBKey(_ptr.upper); }

  bool get upperOpen() { return _ptr.upperOpen; }

  IDBKeyRange bound(IDBKey lower, IDBKey upper, [bool lowerOpen, bool upperOpen]) {
    if (lowerOpen === null) {
      if (upperOpen === null) {
        return LevelDom.wrapIDBKeyRange(_ptr.bound(LevelDom.unwrap(lower), LevelDom.unwrap(upper)));
      }
    } else {
      if (upperOpen === null) {
        return LevelDom.wrapIDBKeyRange(_ptr.bound(LevelDom.unwrap(lower), LevelDom.unwrap(upper), lowerOpen));
      } else {
        return LevelDom.wrapIDBKeyRange(_ptr.bound(LevelDom.unwrap(lower), LevelDom.unwrap(upper), lowerOpen, upperOpen));
      }
    }
    throw "Incorrect number or type of arguments";
  }

  IDBKeyRange lowerBound(IDBKey bound, [bool open]) {
    if (open === null) {
      return LevelDom.wrapIDBKeyRange(_ptr.lowerBound(LevelDom.unwrap(bound)));
    } else {
      return LevelDom.wrapIDBKeyRange(_ptr.lowerBound(LevelDom.unwrap(bound), open));
    }
  }

  IDBKeyRange only(IDBKey value) {
    return LevelDom.wrapIDBKeyRange(_ptr.only(LevelDom.unwrap(value)));
  }

  IDBKeyRange upperBound(IDBKey bound, [bool open]) {
    if (open === null) {
      return LevelDom.wrapIDBKeyRange(_ptr.upperBound(LevelDom.unwrap(bound)));
    } else {
      return LevelDom.wrapIDBKeyRange(_ptr.upperBound(LevelDom.unwrap(bound), open));
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBKeyWrappingImplementation extends DOMWrapperBase implements IDBKey {
  IDBKeyWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBObjectStoreWrappingImplementation extends DOMWrapperBase implements IDBObjectStore {
  IDBObjectStoreWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get keyPath() { return _ptr.keyPath; }

  String get name() { return _ptr.name; }

  IDBTransaction get transaction() { return LevelDom.wrapIDBTransaction(_ptr.transaction); }

  IDBRequest add(String value, [IDBKey key]) {
    if (key === null) {
      return LevelDom.wrapIDBRequest(_ptr.add(value));
    } else {
      return LevelDom.wrapIDBRequest(_ptr.add(value, LevelDom.unwrap(key)));
    }
  }

  IDBRequest clear() {
    return LevelDom.wrapIDBRequest(_ptr.clear());
  }

  IDBIndex createIndex(String name, String keyPath) {
    return LevelDom.wrapIDBIndex(_ptr.createIndex(name, keyPath));
  }

  IDBRequest delete(IDBKey key) {
    return LevelDom.wrapIDBRequest(_ptr.delete(LevelDom.unwrap(key)));
  }

  void deleteIndex(String name) {
    _ptr.deleteIndex(name);
    return;
  }

  IDBRequest getObject(IDBKey key) {
    return LevelDom.wrapIDBRequest(_ptr.getObject(LevelDom.unwrap(key)));
  }

  IDBIndex index(String name) {
    return LevelDom.wrapIDBIndex(_ptr.index(name));
  }

  IDBRequest openCursor([IDBKeyRange range, int direction]) {
    if (range === null) {
      if (direction === null) {
        return LevelDom.wrapIDBRequest(_ptr.openCursor());
      }
    } else {
      if (direction === null) {
        return LevelDom.wrapIDBRequest(_ptr.openCursor(LevelDom.unwrap(range)));
      } else {
        return LevelDom.wrapIDBRequest(_ptr.openCursor(LevelDom.unwrap(range), direction));
      }
    }
    throw "Incorrect number or type of arguments";
  }

  IDBRequest put(String value, [IDBKey key]) {
    if (key === null) {
      return LevelDom.wrapIDBRequest(_ptr.put(value));
    } else {
      return LevelDom.wrapIDBRequest(_ptr.put(value, LevelDom.unwrap(key)));
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBRequestWrappingImplementation extends DOMWrapperBase implements IDBRequest {
  IDBRequestWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get errorCode() { return _ptr.errorCode; }

  int get readyState() { return _ptr.readyState; }

  IDBAny get result() { return LevelDom.wrapIDBAny(_ptr.result); }

  IDBAny get source() { return LevelDom.wrapIDBAny(_ptr.source); }

  IDBTransaction get transaction() { return LevelDom.wrapIDBTransaction(_ptr.transaction); }

  String get webkitErrorMessage() { return _ptr.webkitErrorMessage; }

  void addEventListener(String type, EventListener listener, [bool useCapture]) {
    if (useCapture === null) {
      _ptr.addEventListener(type, LevelDom.unwrap(listener));
      return;
    } else {
      _ptr.addEventListener(type, LevelDom.unwrap(listener), useCapture);
      return;
    }
  }

  bool dispatchEvent(Event evt) {
    return _ptr.dispatchEvent(LevelDom.unwrap(evt));
  }

  void removeEventListener(String type, EventListener listener, [bool useCapture]) {
    if (useCapture === null) {
      _ptr.removeEventListener(type, LevelDom.unwrap(listener));
      return;
    } else {
      _ptr.removeEventListener(type, LevelDom.unwrap(listener), useCapture);
      return;
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBTransactionWrappingImplementation extends DOMWrapperBase implements IDBTransaction {
  IDBTransactionWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  IDBDatabase get db() { return LevelDom.wrapIDBDatabase(_ptr.db); }

  int get mode() { return _ptr.mode; }

  void abort() {
    _ptr.abort();
    return;
  }

  void addEventListener(String type, EventListener listener, [bool useCapture]) {
    if (useCapture === null) {
      _ptr.addEventListener(type, LevelDom.unwrap(listener));
      return;
    } else {
      _ptr.addEventListener(type, LevelDom.unwrap(listener), useCapture);
      return;
    }
  }

  bool dispatchEvent(Event evt) {
    return _ptr.dispatchEvent(LevelDom.unwrap(evt));
  }

  IDBObjectStore objectStore(String name) {
    return LevelDom.wrapIDBObjectStore(_ptr.objectStore(name));
  }

  void removeEventListener(String type, EventListener listener, [bool useCapture]) {
    if (useCapture === null) {
      _ptr.removeEventListener(type, LevelDom.unwrap(listener));
      return;
    } else {
      _ptr.removeEventListener(type, LevelDom.unwrap(listener), useCapture);
      return;
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBVersionChangeEventWrappingImplementation extends EventWrappingImplementation implements IDBVersionChangeEvent {
  IDBVersionChangeEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get version() { return _ptr.version; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IDBVersionChangeRequestWrappingImplementation extends IDBRequestWrappingImplementation implements IDBVersionChangeRequest {
  IDBVersionChangeRequestWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class IFrameElementWrappingImplementation extends ElementWrappingImplementation implements IFrameElement {
  IFrameElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }

  Document get contentDocument() { return LevelDom.wrapDocument(_ptr.contentDocument); }

  Window get contentWindow() { return LevelDom.wrapWindow(_ptr.contentWindow); }

  String get frameBorder() { return _ptr.frameBorder; }

  void set frameBorder(String value) { _ptr.frameBorder = value; }

  String get height() { return _ptr.height; }

  void set height(String value) { _ptr.height = value; }

  String get longDesc() { return _ptr.longDesc; }

  void set longDesc(String value) { _ptr.longDesc = value; }

  String get marginHeight() { return _ptr.marginHeight; }

  void set marginHeight(String value) { _ptr.marginHeight = value; }

  String get marginWidth() { return _ptr.marginWidth; }

  void set marginWidth(String value) { _ptr.marginWidth = value; }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  String get sandbox() { return _ptr.sandbox; }

  void set sandbox(String value) { _ptr.sandbox = value; }

  String get scrolling() { return _ptr.scrolling; }

  void set scrolling(String value) { _ptr.scrolling = value; }

  String get src() { return _ptr.src; }

  void set src(String value) { _ptr.src = value; }

  String get width() { return _ptr.width; }

  void set width(String value) { _ptr.width = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ImageDataWrappingImplementation extends DOMWrapperBase implements ImageData {
  ImageDataWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  CanvasPixelArray get data() { return LevelDom.wrapCanvasPixelArray(_ptr.data); }

  int get height() { return _ptr.height; }

  int get width() { return _ptr.width; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ImageElementWrappingImplementation extends ElementWrappingImplementation implements ImageElement {
  ImageElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }

  String get alt() { return _ptr.alt; }

  void set alt(String value) { _ptr.alt = value; }

  String get border() { return _ptr.border; }

  void set border(String value) { _ptr.border = value; }

  bool get complete() { return _ptr.complete; }

  String get crossOrigin() { return _ptr.crossOrigin; }

  void set crossOrigin(String value) { _ptr.crossOrigin = value; }

  int get height() { return _ptr.height; }

  void set height(int value) { _ptr.height = value; }

  int get hspace() { return _ptr.hspace; }

  void set hspace(int value) { _ptr.hspace = value; }

  bool get isMap() { return _ptr.isMap; }

  void set isMap(bool value) { _ptr.isMap = value; }

  String get longDesc() { return _ptr.longDesc; }

  void set longDesc(String value) { _ptr.longDesc = value; }

  String get lowsrc() { return _ptr.lowsrc; }

  void set lowsrc(String value) { _ptr.lowsrc = value; }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  int get naturalHeight() { return _ptr.naturalHeight; }

  int get naturalWidth() { return _ptr.naturalWidth; }

  String get src() { return _ptr.src; }

  void set src(String value) { _ptr.src = value; }

  String get useMap() { return _ptr.useMap; }

  void set useMap(String value) { _ptr.useMap = value; }

  int get vspace() { return _ptr.vspace; }

  void set vspace(int value) { _ptr.vspace = value; }

  int get width() { return _ptr.width; }

  void set width(int value) { _ptr.width = value; }

  int get x() { return _ptr.x; }

  int get y() { return _ptr.y; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class InputElementWrappingImplementation extends ElementWrappingImplementation implements InputElement {
  InputElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get accept() { return _ptr.accept; }

  void set accept(String value) { _ptr.accept = value; }

  String get accessKey() { return _ptr.accessKey; }

  void set accessKey(String value) { _ptr.accessKey = value; }

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }

  String get alt() { return _ptr.alt; }

  void set alt(String value) { _ptr.alt = value; }

  String get autocomplete() { return _ptr.autocomplete; }

  void set autocomplete(String value) { _ptr.autocomplete = value; }

  bool get autofocus() { return _ptr.autofocus; }

  void set autofocus(bool value) { _ptr.autofocus = value; }

  bool get checked() { return _ptr.checked; }

  void set checked(bool value) { _ptr.checked = value; }

  bool get defaultChecked() { return _ptr.defaultChecked; }

  void set defaultChecked(bool value) { _ptr.defaultChecked = value; }

  String get defaultValue() { return _ptr.defaultValue; }

  void set defaultValue(String value) { _ptr.defaultValue = value; }

  bool get disabled() { return _ptr.disabled; }

  void set disabled(bool value) { _ptr.disabled = value; }

  FileList get files() { return LevelDom.wrapFileList(_ptr.files); }

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  String get formAction() { return _ptr.formAction; }

  void set formAction(String value) { _ptr.formAction = value; }

  String get formEnctype() { return _ptr.formEnctype; }

  void set formEnctype(String value) { _ptr.formEnctype = value; }

  String get formMethod() { return _ptr.formMethod; }

  void set formMethod(String value) { _ptr.formMethod = value; }

  bool get formNoValidate() { return _ptr.formNoValidate; }

  void set formNoValidate(bool value) { _ptr.formNoValidate = value; }

  String get formTarget() { return _ptr.formTarget; }

  void set formTarget(String value) { _ptr.formTarget = value; }

  bool get incremental() { return _ptr.incremental; }

  void set incremental(bool value) { _ptr.incremental = value; }

  bool get indeterminate() { return _ptr.indeterminate; }

  void set indeterminate(bool value) { _ptr.indeterminate = value; }

  ElementList get labels() { return LevelDom.wrapElementList(_ptr.labels); }

  Element get list() { return LevelDom.wrapElement(_ptr.list); }

  String get max() { return _ptr.max; }

  void set max(String value) { _ptr.max = value; }

  int get maxLength() { return _ptr.maxLength; }

  void set maxLength(int value) { _ptr.maxLength = value; }

  String get min() { return _ptr.min; }

  void set min(String value) { _ptr.min = value; }

  bool get multiple() { return _ptr.multiple; }

  void set multiple(bool value) { _ptr.multiple = value; }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  String get pattern() { return _ptr.pattern; }

  void set pattern(String value) { _ptr.pattern = value; }

  String get placeholder() { return _ptr.placeholder; }

  void set placeholder(String value) { _ptr.placeholder = value; }

  bool get readOnly() { return _ptr.readOnly; }

  void set readOnly(bool value) { _ptr.readOnly = value; }

  bool get required() { return _ptr.required; }

  void set required(bool value) { _ptr.required = value; }

  OptionElement get selectedOption() { return LevelDom.wrapOptionElement(_ptr.selectedOption); }

  String get selectionDirection() { return _ptr.selectionDirection; }

  void set selectionDirection(String value) { _ptr.selectionDirection = value; }

  int get selectionEnd() { return _ptr.selectionEnd; }

  void set selectionEnd(int value) { _ptr.selectionEnd = value; }

  int get selectionStart() { return _ptr.selectionStart; }

  void set selectionStart(int value) { _ptr.selectionStart = value; }

  int get size() { return _ptr.size; }

  void set size(int value) { _ptr.size = value; }

  String get src() { return _ptr.src; }

  void set src(String value) { _ptr.src = value; }

  String get step() { return _ptr.step; }

  void set step(String value) { _ptr.step = value; }

  String get type() { return _ptr.type; }

  void set type(String value) { _ptr.type = value; }

  String get useMap() { return _ptr.useMap; }

  void set useMap(String value) { _ptr.useMap = value; }

  String get validationMessage() { return _ptr.validationMessage; }

  ValidityState get validity() { return LevelDom.wrapValidityState(_ptr.validity); }

  String get value() { return _ptr.value; }

  void set value(String value) { _ptr.value = value; }

  Date get valueAsDate() { return _ptr.valueAsDate; }

  void set valueAsDate(Date value) { _ptr.valueAsDate = value; }

  num get valueAsNumber() { return _ptr.valueAsNumber; }

  void set valueAsNumber(num value) { _ptr.valueAsNumber = value; }

  bool get webkitGrammar() { return _ptr.webkitGrammar; }

  void set webkitGrammar(bool value) { _ptr.webkitGrammar = value; }

  bool get webkitSpeech() { return _ptr.webkitSpeech; }

  void set webkitSpeech(bool value) { _ptr.webkitSpeech = value; }

  bool get webkitdirectory() { return _ptr.webkitdirectory; }

  void set webkitdirectory(bool value) { _ptr.webkitdirectory = value; }

  bool get willValidate() { return _ptr.willValidate; }

  bool checkValidity() {
    return _ptr.checkValidity();
  }

  void click() {
    _ptr.click();
    return;
  }

  void select() {
    _ptr.select();
    return;
  }

  void setCustomValidity(String error) {
    _ptr.setCustomValidity(error);
    return;
  }

  void setSelectionRange(int start, int end, [String direction = null]) {
    if (direction === null) {
      _ptr.setSelectionRange(start, end);
      return;
    } else {
      _ptr.setSelectionRange(start, end, direction);
      return;
    }
  }

  void stepDown([int n = null]) {
    if (n === null) {
      _ptr.stepDown();
      return;
    } else {
      _ptr.stepDown(n);
      return;
    }
  }

  void stepUp([int n = null]) {
    if (n === null) {
      _ptr.stepUp();
      return;
    } else {
      _ptr.stepUp(n);
      return;
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class Int16ArrayWrappingImplementation extends ArrayBufferViewWrappingImplementation implements Int16Array {
  Int16ArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  Int16Array subarray(int start, [int end]) {
    if (end === null) {
      return LevelDom.wrapInt16Array(_ptr.subarray(start));
    } else {
      return LevelDom.wrapInt16Array(_ptr.subarray(start, end));
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class Int32ArrayWrappingImplementation extends ArrayBufferViewWrappingImplementation implements Int32Array {
  Int32ArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  Int32Array subarray(int start, [int end]) {
    if (end === null) {
      return LevelDom.wrapInt32Array(_ptr.subarray(start));
    } else {
      return LevelDom.wrapInt32Array(_ptr.subarray(start, end));
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class Int8ArrayWrappingImplementation extends ArrayBufferViewWrappingImplementation implements Int8Array {
  Int8ArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  Int8Array subarray(int start, [int end]) {
    if (end === null) {
      return LevelDom.wrapInt8Array(_ptr.subarray(start));
    } else {
      return LevelDom.wrapInt8Array(_ptr.subarray(start, end));
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class JavaScriptAudioNodeWrappingImplementation extends AudioNodeWrappingImplementation implements JavaScriptAudioNode {
  JavaScriptAudioNodeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get bufferSize() { return _ptr.bufferSize; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class KeygenElementWrappingImplementation extends ElementWrappingImplementation implements KeygenElement {
  KeygenElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get autofocus() { return _ptr.autofocus; }

  void set autofocus(bool value) { _ptr.autofocus = value; }

  String get challenge() { return _ptr.challenge; }

  void set challenge(String value) { _ptr.challenge = value; }

  bool get disabled() { return _ptr.disabled; }

  void set disabled(bool value) { _ptr.disabled = value; }

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  String get keytype() { return _ptr.keytype; }

  void set keytype(String value) { _ptr.keytype = value; }

  ElementList get labels() { return LevelDom.wrapElementList(_ptr.labels); }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  String get type() { return _ptr.type; }

  String get validationMessage() { return _ptr.validationMessage; }

  ValidityState get validity() { return LevelDom.wrapValidityState(_ptr.validity); }

  bool get willValidate() { return _ptr.willValidate; }

  bool checkValidity() {
    return _ptr.checkValidity();
  }

  void setCustomValidity(String error) {
    _ptr.setCustomValidity(error);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class LIElementWrappingImplementation extends ElementWrappingImplementation implements LIElement {
  LIElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get type() { return _ptr.type; }

  void set type(String value) { _ptr.type = value; }

  int get value() { return _ptr.value; }

  void set value(int value) { _ptr.value = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class LabelElementWrappingImplementation extends ElementWrappingImplementation implements LabelElement {
  LabelElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get accessKey() { return _ptr.accessKey; }

  void set accessKey(String value) { _ptr.accessKey = value; }

  Element get control() { return LevelDom.wrapElement(_ptr.control); }

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  String get htmlFor() { return _ptr.htmlFor; }

  void set htmlFor(String value) { _ptr.htmlFor = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class LegendElementWrappingImplementation extends ElementWrappingImplementation implements LegendElement {
  LegendElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get accessKey() { return _ptr.accessKey; }

  void set accessKey(String value) { _ptr.accessKey = value; }

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class LinkElementWrappingImplementation extends ElementWrappingImplementation implements LinkElement {
  LinkElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get charset() { return _ptr.charset; }

  void set charset(String value) { _ptr.charset = value; }

  bool get disabled() { return _ptr.disabled; }

  void set disabled(bool value) { _ptr.disabled = value; }

  String get href() { return _ptr.href; }

  void set href(String value) { _ptr.href = value; }

  String get hreflang() { return _ptr.hreflang; }

  void set hreflang(String value) { _ptr.hreflang = value; }

  String get media() { return _ptr.media; }

  void set media(String value) { _ptr.media = value; }

  String get rel() { return _ptr.rel; }

  void set rel(String value) { _ptr.rel = value; }

  String get rev() { return _ptr.rev; }

  void set rev(String value) { _ptr.rev = value; }

  StyleSheet get sheet() { return LevelDom.wrapStyleSheet(_ptr.sheet); }

  DOMSettableTokenList get sizes() { return LevelDom.wrapDOMSettableTokenList(_ptr.sizes); }

  void set sizes(DOMSettableTokenList value) { _ptr.sizes = LevelDom.unwrap(value); }

  String get target() { return _ptr.target; }

  void set target(String value) { _ptr.target = value; }

  String get type() { return _ptr.type; }

  void set type(String value) { _ptr.type = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class LocationWrappingImplementation extends DOMWrapperBase implements Location {
  LocationWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get hash() { return _ptr.hash; }

  void set hash(String value) { _ptr.hash = value; }

  String get host() { return _ptr.host; }

  void set host(String value) { _ptr.host = value; }

  String get hostname() { return _ptr.hostname; }

  void set hostname(String value) { _ptr.hostname = value; }

  String get href() { return _ptr.href; }

  void set href(String value) { _ptr.href = value; }

  String get origin() { return _ptr.origin; }

  String get pathname() { return _ptr.pathname; }

  void set pathname(String value) { _ptr.pathname = value; }

  String get port() { return _ptr.port; }

  void set port(String value) { _ptr.port = value; }

  String get protocol() { return _ptr.protocol; }

  void set protocol(String value) { _ptr.protocol = value; }

  String get search() { return _ptr.search; }

  void set search(String value) { _ptr.search = value; }

  void assign(String url) {
    _ptr.assign(url);
    return;
  }

  String getParameter(String name) {
    return _ptr.getParameter(name);
  }

  void reload() {
    _ptr.reload();
    return;
  }

  void replace(String url) {
    _ptr.replace(url);
    return;
  }

  String toString() {
    return _ptr.toString();
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class LoseContextWrappingImplementation extends DOMWrapperBase implements LoseContext {
  LoseContextWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void loseContext() {
    _ptr.loseContext();
    return;
  }

  void restoreContext() {
    _ptr.restoreContext();
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class LowPass2FilterNodeWrappingImplementation extends AudioNodeWrappingImplementation implements LowPass2FilterNode {
  LowPass2FilterNodeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  AudioParam get cutoff() { return LevelDom.wrapAudioParam(_ptr.cutoff); }

  AudioParam get resonance() { return LevelDom.wrapAudioParam(_ptr.resonance); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MapElementWrappingImplementation extends ElementWrappingImplementation implements MapElement {
  MapElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  ElementList get areas() { return LevelDom.wrapElementList(_ptr.areas); }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MarqueeElementWrappingImplementation extends ElementWrappingImplementation implements MarqueeElement {
  MarqueeElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get behavior() { return _ptr.behavior; }

  void set behavior(String value) { _ptr.behavior = value; }

  String get bgColor() { return _ptr.bgColor; }

  void set bgColor(String value) { _ptr.bgColor = value; }

  String get direction() { return _ptr.direction; }

  void set direction(String value) { _ptr.direction = value; }

  String get height() { return _ptr.height; }

  void set height(String value) { _ptr.height = value; }

  int get hspace() { return _ptr.hspace; }

  void set hspace(int value) { _ptr.hspace = value; }

  int get loop() { return _ptr.loop; }

  void set loop(int value) { _ptr.loop = value; }

  int get scrollAmount() { return _ptr.scrollAmount; }

  void set scrollAmount(int value) { _ptr.scrollAmount = value; }

  int get scrollDelay() { return _ptr.scrollDelay; }

  void set scrollDelay(int value) { _ptr.scrollDelay = value; }

  bool get trueSpeed() { return _ptr.trueSpeed; }

  void set trueSpeed(bool value) { _ptr.trueSpeed = value; }

  int get vspace() { return _ptr.vspace; }

  void set vspace(int value) { _ptr.vspace = value; }

  String get width() { return _ptr.width; }

  void set width(String value) { _ptr.width = value; }

  void start() {
    _ptr.start();
    return;
  }

  void stop() {
    _ptr.stop();
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MediaElementAudioSourceNodeWrappingImplementation extends AudioSourceNodeWrappingImplementation implements MediaElementAudioSourceNode {
  MediaElementAudioSourceNodeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  MediaElement get mediaElement() { return LevelDom.wrapMediaElement(_ptr.mediaElement); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MediaElementWrappingImplementation extends ElementWrappingImplementation implements MediaElement {
  MediaElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get autoplay() { return _ptr.autoplay; }

  void set autoplay(bool value) { _ptr.autoplay = value; }

  TimeRanges get buffered() { return LevelDom.wrapTimeRanges(_ptr.buffered); }

  bool get controls() { return _ptr.controls; }

  void set controls(bool value) { _ptr.controls = value; }

  String get currentSrc() { return _ptr.currentSrc; }

  num get currentTime() { return _ptr.currentTime; }

  void set currentTime(num value) { _ptr.currentTime = value; }

  bool get defaultMuted() { return _ptr.defaultMuted; }

  void set defaultMuted(bool value) { _ptr.defaultMuted = value; }

  num get defaultPlaybackRate() { return _ptr.defaultPlaybackRate; }

  void set defaultPlaybackRate(num value) { _ptr.defaultPlaybackRate = value; }

  num get duration() { return _ptr.duration; }

  bool get ended() { return _ptr.ended; }

  MediaError get error() { return LevelDom.wrapMediaError(_ptr.error); }

  num get initialTime() { return _ptr.initialTime; }

  bool get loop() { return _ptr.loop; }

  void set loop(bool value) { _ptr.loop = value; }

  bool get muted() { return _ptr.muted; }

  void set muted(bool value) { _ptr.muted = value; }

  int get networkState() { return _ptr.networkState; }

  bool get paused() { return _ptr.paused; }

  num get playbackRate() { return _ptr.playbackRate; }

  void set playbackRate(num value) { _ptr.playbackRate = value; }

  TimeRanges get played() { return LevelDom.wrapTimeRanges(_ptr.played); }

  String get preload() { return _ptr.preload; }

  void set preload(String value) { _ptr.preload = value; }

  int get readyState() { return _ptr.readyState; }

  TimeRanges get seekable() { return LevelDom.wrapTimeRanges(_ptr.seekable); }

  bool get seeking() { return _ptr.seeking; }

  String get src() { return _ptr.src; }

  void set src(String value) { _ptr.src = value; }

  num get startTime() { return _ptr.startTime; }

  num get volume() { return _ptr.volume; }

  void set volume(num value) { _ptr.volume = value; }

  int get webkitAudioDecodedByteCount() { return _ptr.webkitAudioDecodedByteCount; }

  bool get webkitClosedCaptionsVisible() { return _ptr.webkitClosedCaptionsVisible; }

  void set webkitClosedCaptionsVisible(bool value) { _ptr.webkitClosedCaptionsVisible = value; }

  bool get webkitHasClosedCaptions() { return _ptr.webkitHasClosedCaptions; }

  bool get webkitPreservesPitch() { return _ptr.webkitPreservesPitch; }

  void set webkitPreservesPitch(bool value) { _ptr.webkitPreservesPitch = value; }

  int get webkitVideoDecodedByteCount() { return _ptr.webkitVideoDecodedByteCount; }

  String canPlayType(String type) {
    return _ptr.canPlayType(type);
  }

  void load() {
    _ptr.load();
    return;
  }

  void pause() {
    _ptr.pause();
    return;
  }

  void play() {
    _ptr.play();
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MediaErrorWrappingImplementation extends DOMWrapperBase implements MediaError {
  MediaErrorWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get code() { return _ptr.code; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MediaListWrappingImplementation extends DOMWrapperBase implements MediaList {
  MediaListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  String get mediaText() { return _ptr.mediaText; }

  void set mediaText(String value) { _ptr.mediaText = value; }

  String operator[](int index) {
    return _ptr[index];
  }

  void operator[]=(int index, String value) {
    _ptr[index] = value;
  }

  void add(String value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addLast(String value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addAll(Collection<String> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void sort(int compare(String a, String b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
  }

  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) {
    throw new UnsupportedOperationException("This object is immutable.");
  }

  int indexOf(String element, [int start = 0]) {
    return _Lists.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(String element, [int start = null]) {
    if (start === null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int clear() {
    throw new UnsupportedOperationException("Cannot clear immutable List.");
  }

  String removeLast() {
    throw new UnsupportedOperationException("Cannot removeLast on immutable List.");
  }

  String last() {
    return this[length - 1];
  }

  void forEach(void f(String element)) {
    _Collections.forEach(this, f);
  }

  Collection<String> filter(bool f(String element)) {
    return _Collections.filter(this, new List<String>(), f);
  }

  bool every(bool f(String element)) {
    return _Collections.every(this, f);
  }

  bool some(bool f(String element)) {
    return _Collections.some(this, f);
  }

  void setRange(int start, int length, List<String> from, [int startFrom]) {
    throw new UnsupportedOperationException("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int length) {
    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int length, [String initialValue]) {
    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");
  }

  List<String> getRange(int start, int length) {
    throw new NotImplementedException();
  }

  bool isEmpty() {
    return length == 0;
  }

  Iterator<String> iterator() {
    return new _FixedSizeListIterator<String>(this);
  }

  void appendMedium(String newMedium) {
    _ptr.appendMedium(newMedium);
    return;
  }

  void deleteMedium(String oldMedium) {
    _ptr.deleteMedium(oldMedium);
    return;
  }

  String item(int index) {
    return _ptr.item(index);
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MediaQueryListListenerWrappingImplementation extends DOMWrapperBase implements MediaQueryListListener {
  MediaQueryListListenerWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void queryChanged(MediaQueryList list) {
    _ptr.queryChanged(LevelDom.unwrap(list));
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MediaQueryListWrappingImplementation extends DOMWrapperBase implements MediaQueryList {
  MediaQueryListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get matches() { return _ptr.matches; }

  String get media() { return _ptr.media; }

  void addListener(MediaQueryListListener listener) {
    _ptr.addListener(LevelDom.unwrap(listener));
    return;
  }

  void removeListener(MediaQueryListListener listener) {
    _ptr.removeListener(LevelDom.unwrap(listener));
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MenuElementWrappingImplementation extends ElementWrappingImplementation implements MenuElement {
  MenuElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get compact() { return _ptr.compact; }

  void set compact(bool value) { _ptr.compact = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MessageChannelWrappingImplementation extends DOMWrapperBase implements MessageChannel {
  MessageChannelWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  MessagePort get port1() { return LevelDom.wrapMessagePort(_ptr.port1); }

  MessagePort get port2() { return LevelDom.wrapMessagePort(_ptr.port2); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MetaElementWrappingImplementation extends ElementWrappingImplementation implements MetaElement {
  MetaElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get content() { return _ptr.content; }

  void set content(String value) { _ptr.content = value; }

  String get httpEquiv() { return _ptr.httpEquiv; }

  void set httpEquiv(String value) { _ptr.httpEquiv = value; }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  String get scheme() { return _ptr.scheme; }

  void set scheme(String value) { _ptr.scheme = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MetadataWrappingImplementation extends DOMWrapperBase implements Metadata {
  MetadataWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  Date get modificationTime() { return _ptr.modificationTime; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MeterElementWrappingImplementation extends ElementWrappingImplementation implements MeterElement {
  MeterElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  num get high() { return _ptr.high; }

  void set high(num value) { _ptr.high = value; }

  ElementList get labels() { return LevelDom.wrapElementList(_ptr.labels); }

  num get low() { return _ptr.low; }

  void set low(num value) { _ptr.low = value; }

  num get max() { return _ptr.max; }

  void set max(num value) { _ptr.max = value; }

  num get min() { return _ptr.min; }

  void set min(num value) { _ptr.min = value; }

  num get optimum() { return _ptr.optimum; }

  void set optimum(num value) { _ptr.optimum = value; }

  num get value() { return _ptr.value; }

  void set value(num value) { _ptr.value = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ModElementWrappingImplementation extends ElementWrappingImplementation implements ModElement {
  ModElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get cite() { return _ptr.cite; }

  void set cite(String value) { _ptr.cite = value; }

  String get dateTime() { return _ptr.dateTime; }

  void set dateTime(String value) { _ptr.dateTime = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MutationCallbackWrappingImplementation extends DOMWrapperBase implements MutationCallback {
  MutationCallbackWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MutationRecordWrappingImplementation extends DOMWrapperBase implements MutationRecord {
  MutationRecordWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  ElementList get addedNodes() { return LevelDom.wrapElementList(_ptr.addedNodes); }

  String get attributeName() { return _ptr.attributeName; }

  String get attributeNamespace() { return _ptr.attributeNamespace; }

  Node get nextSibling() { return LevelDom.wrapNode(_ptr.nextSibling); }

  String get oldValue() { return _ptr.oldValue; }

  Node get previousSibling() { return LevelDom.wrapNode(_ptr.previousSibling); }

  ElementList get removedNodes() { return LevelDom.wrapElementList(_ptr.removedNodes); }

  Node get target() { return LevelDom.wrapNode(_ptr.target); }

  String get type() { return _ptr.type; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class NavigatorUserMediaErrorWrappingImplementation extends DOMWrapperBase implements NavigatorUserMediaError {
  NavigatorUserMediaErrorWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get code() { return _ptr.code; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class NavigatorUserMediaSuccessCallbackWrappingImplementation extends DOMWrapperBase implements NavigatorUserMediaSuccessCallback {
  NavigatorUserMediaSuccessCallbackWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class NavigatorWrappingImplementation extends DOMWrapperBase implements Navigator {
  NavigatorWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get appCodeName() { return _ptr.appCodeName; }

  String get appName() { return _ptr.appName; }

  String get appVersion() { return _ptr.appVersion; }

  bool get cookieEnabled() { return _ptr.cookieEnabled; }

  String get language() { return _ptr.language; }

  DOMMimeTypeArray get mimeTypes() { return LevelDom.wrapDOMMimeTypeArray(_ptr.mimeTypes); }

  bool get onLine() { return _ptr.onLine; }

  String get platform() { return _ptr.platform; }

  DOMPluginArray get plugins() { return LevelDom.wrapDOMPluginArray(_ptr.plugins); }

  String get product() { return _ptr.product; }

  String get productSub() { return _ptr.productSub; }

  String get userAgent() { return _ptr.userAgent; }

  String get vendor() { return _ptr.vendor; }

  String get vendorSub() { return _ptr.vendorSub; }

  void getStorageUpdates() {
    _ptr.getStorageUpdates();
    return;
  }

  bool javaEnabled() {
    return _ptr.javaEnabled();
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class NotationWrappingImplementation extends NodeWrappingImplementation implements Notation {
  NotationWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get publicId() { return _ptr.publicId; }

  String get systemId() { return _ptr.systemId; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class NotificationCenterWrappingImplementation extends DOMWrapperBase implements NotificationCenter {
  NotificationCenterWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int checkPermission() {
    return _ptr.checkPermission();
  }

  Notification createHTMLNotification(String url) {
    return LevelDom.wrapNotification(_ptr.createHTMLNotification(url));
  }

  Notification createNotification(String iconUrl, String title, String body) {
    return LevelDom.wrapNotification(_ptr.createNotification(iconUrl, title, body));
  }

  void requestPermission(VoidCallback callback) {
    _ptr.requestPermission(LevelDom.unwrap(callback));
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class OESStandardDerivativesWrappingImplementation extends DOMWrapperBase implements OESStandardDerivatives {
  OESStandardDerivativesWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class OESTextureFloatWrappingImplementation extends DOMWrapperBase implements OESTextureFloat {
  OESTextureFloatWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class OESVertexArrayObjectWrappingImplementation extends DOMWrapperBase implements OESVertexArrayObject {
  OESVertexArrayObjectWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void bindVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) {
    _ptr.bindVertexArrayOES(LevelDom.unwrap(arrayObject));
    return;
  }

  WebGLVertexArrayObjectOES createVertexArrayOES() {
    return LevelDom.wrapWebGLVertexArrayObjectOES(_ptr.createVertexArrayOES());
  }

  void deleteVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) {
    _ptr.deleteVertexArrayOES(LevelDom.unwrap(arrayObject));
    return;
  }

  bool isVertexArrayOES(WebGLVertexArrayObjectOES arrayObject) {
    return _ptr.isVertexArrayOES(LevelDom.unwrap(arrayObject));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class OListElementWrappingImplementation extends ElementWrappingImplementation implements OListElement {
  OListElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get compact() { return _ptr.compact; }

  void set compact(bool value) { _ptr.compact = value; }

  int get start() { return _ptr.start; }

  void set start(int value) { _ptr.start = value; }

  String get type() { return _ptr.type; }

  void set type(String value) { _ptr.type = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ObjectElementWrappingImplementation extends ElementWrappingImplementation implements ObjectElement {
  ObjectElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }

  String get archive() { return _ptr.archive; }

  void set archive(String value) { _ptr.archive = value; }

  String get border() { return _ptr.border; }

  void set border(String value) { _ptr.border = value; }

  String get code() { return _ptr.code; }

  void set code(String value) { _ptr.code = value; }

  String get codeBase() { return _ptr.codeBase; }

  void set codeBase(String value) { _ptr.codeBase = value; }

  String get codeType() { return _ptr.codeType; }

  void set codeType(String value) { _ptr.codeType = value; }

  Document get contentDocument() { return LevelDom.wrapDocument(_ptr.contentDocument); }

  String get data() { return _ptr.data; }

  void set data(String value) { _ptr.data = value; }

  bool get declare() { return _ptr.declare; }

  void set declare(bool value) { _ptr.declare = value; }

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  String get height() { return _ptr.height; }

  void set height(String value) { _ptr.height = value; }

  int get hspace() { return _ptr.hspace; }

  void set hspace(int value) { _ptr.hspace = value; }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  String get standby() { return _ptr.standby; }

  void set standby(String value) { _ptr.standby = value; }

  String get type() { return _ptr.type; }

  void set type(String value) { _ptr.type = value; }

  String get useMap() { return _ptr.useMap; }

  void set useMap(String value) { _ptr.useMap = value; }

  String get validationMessage() { return _ptr.validationMessage; }

  ValidityState get validity() { return LevelDom.wrapValidityState(_ptr.validity); }

  int get vspace() { return _ptr.vspace; }

  void set vspace(int value) { _ptr.vspace = value; }

  String get width() { return _ptr.width; }

  void set width(String value) { _ptr.width = value; }

  bool get willValidate() { return _ptr.willValidate; }

  bool checkValidity() {
    return _ptr.checkValidity();
  }

  void setCustomValidity(String error) {
    _ptr.setCustomValidity(error);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class OfflineAudioCompletionEventWrappingImplementation extends EventWrappingImplementation implements OfflineAudioCompletionEvent {
  OfflineAudioCompletionEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  AudioBuffer get renderedBuffer() { return LevelDom.wrapAudioBuffer(_ptr.renderedBuffer); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class OperationNotAllowedExceptionWrappingImplementation extends DOMWrapperBase implements OperationNotAllowedException {
  OperationNotAllowedExceptionWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get code() { return _ptr.code; }

  String get message() { return _ptr.message; }

  String get name() { return _ptr.name; }

  String toString() {
    return _ptr.toString();
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class OptGroupElementWrappingImplementation extends ElementWrappingImplementation implements OptGroupElement {
  OptGroupElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get disabled() { return _ptr.disabled; }

  void set disabled(bool value) { _ptr.disabled = value; }

  String get label() { return _ptr.label; }

  void set label(String value) { _ptr.label = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class OptionElementWrappingImplementation extends ElementWrappingImplementation implements OptionElement {
  OptionElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get defaultSelected() { return _ptr.defaultSelected; }

  void set defaultSelected(bool value) { _ptr.defaultSelected = value; }

  bool get disabled() { return _ptr.disabled; }

  void set disabled(bool value) { _ptr.disabled = value; }

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  int get index() { return _ptr.index; }

  String get label() { return _ptr.label; }

  void set label(String value) { _ptr.label = value; }

  bool get selected() { return _ptr.selected; }

  void set selected(bool value) { _ptr.selected = value; }

  String get text() { return _ptr.text; }

  void set text(String value) { _ptr.text = value; }

  String get value() { return _ptr.value; }

  void set value(String value) { _ptr.value = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class OutputElementWrappingImplementation extends ElementWrappingImplementation implements OutputElement {
  OutputElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get defaultValue() { return _ptr.defaultValue; }

  void set defaultValue(String value) { _ptr.defaultValue = value; }

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  DOMSettableTokenList get htmlFor() { return LevelDom.wrapDOMSettableTokenList(_ptr.htmlFor); }

  void set htmlFor(DOMSettableTokenList value) { _ptr.htmlFor = LevelDom.unwrap(value); }

  ElementList get labels() { return LevelDom.wrapElementList(_ptr.labels); }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  String get type() { return _ptr.type; }

  String get validationMessage() { return _ptr.validationMessage; }

  ValidityState get validity() { return LevelDom.wrapValidityState(_ptr.validity); }

  String get value() { return _ptr.value; }

  void set value(String value) { _ptr.value = value; }

  bool get willValidate() { return _ptr.willValidate; }

  bool checkValidity() {
    return _ptr.checkValidity();
  }

  void setCustomValidity(String error) {
    _ptr.setCustomValidity(error);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ParagraphElementWrappingImplementation extends ElementWrappingImplementation implements ParagraphElement {
  ParagraphElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ParamElementWrappingImplementation extends ElementWrappingImplementation implements ParamElement {
  ParamElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  String get type() { return _ptr.type; }

  void set type(String value) { _ptr.type = value; }

  String get value() { return _ptr.value; }

  void set value(String value) { _ptr.value = value; }

  String get valueType() { return _ptr.valueType; }

  void set valueType(String value) { _ptr.valueType = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class PointWrappingImplementation extends DOMWrapperBase implements Point {
  PointWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
  factory PointWrappingImplementation(num x, num y) {
    return LevelDom.wrapPoint(new dom.WebKitPoint(x, y));
  }

  num get x() { return _ptr.x; }

  void set x(num value) { _ptr.x = value; }

  num get y() { return _ptr.y; }

  void set y(num value) { _ptr.y = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class PositionErrorWrappingImplementation extends DOMWrapperBase implements PositionError {
  PositionErrorWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get code() { return _ptr.code; }

  String get message() { return _ptr.message; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class PreElementWrappingImplementation extends ElementWrappingImplementation implements PreElement {
  PreElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get width() { return _ptr.width; }

  void set width(int value) { _ptr.width = value; }

  bool get wrap() { return _ptr.wrap; }

  void set wrap(bool value) { _ptr.wrap = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ProcessingInstructionWrappingImplementation extends NodeWrappingImplementation implements ProcessingInstruction {
  ProcessingInstructionWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get data() { return _ptr.data; }

  void set data(String value) { _ptr.data = value; }

  StyleSheet get sheet() { return LevelDom.wrapStyleSheet(_ptr.sheet); }

  String get target() { return _ptr.target; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ProgressElementWrappingImplementation extends ElementWrappingImplementation implements ProgressElement {
  ProgressElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  ElementList get labels() { return LevelDom.wrapElementList(_ptr.labels); }

  num get max() { return _ptr.max; }

  void set max(num value) { _ptr.max = value; }

  num get position() { return _ptr.position; }

  num get value() { return _ptr.value; }

  void set value(num value) { _ptr.value = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class QuoteElementWrappingImplementation extends ElementWrappingImplementation implements QuoteElement {
  QuoteElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get cite() { return _ptr.cite; }

  void set cite(String value) { _ptr.cite = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class RGBColorWrappingImplementation extends DOMWrapperBase implements RGBColor {
  RGBColorWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  CSSPrimitiveValue get blue() { return LevelDom.wrapCSSPrimitiveValue(_ptr.blue); }

  CSSPrimitiveValue get green() { return LevelDom.wrapCSSPrimitiveValue(_ptr.green); }

  CSSPrimitiveValue get red() { return LevelDom.wrapCSSPrimitiveValue(_ptr.red); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class RangeExceptionWrappingImplementation extends DOMWrapperBase implements RangeException {
  RangeExceptionWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get code() { return _ptr.code; }

  String get message() { return _ptr.message; }

  String get name() { return _ptr.name; }

  String toString() {
    return _ptr.toString();
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class RangeWrappingImplementation extends DOMWrapperBase implements Range {
  RangeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get collapsed() { return _ptr.collapsed; }

  Node get commonAncestorContainer() { return LevelDom.wrapNode(_ptr.commonAncestorContainer); }

  Node get endContainer() { return LevelDom.wrapNode(_ptr.endContainer); }

  int get endOffset() { return _ptr.endOffset; }

  Node get startContainer() { return LevelDom.wrapNode(_ptr.startContainer); }

  int get startOffset() { return _ptr.startOffset; }

  DocumentFragment cloneContents() {
    return LevelDom.wrapDocumentFragment(_ptr.cloneContents());
  }

  Range cloneRange() {
    return LevelDom.wrapRange(_ptr.cloneRange());
  }

  void collapse(bool toStart) {
    _ptr.collapse(toStart);
    return;
  }

  int compareNode(Node refNode) {
    return _ptr.compareNode(LevelDom.unwrap(refNode));
  }

  int comparePoint(Node refNode, int offset) {
    return _ptr.comparePoint(LevelDom.unwrap(refNode), offset);
  }

  DocumentFragment createContextualFragment(String html) {
    return LevelDom.wrapDocumentFragment(_ptr.createContextualFragment(html));
  }

  void deleteContents() {
    _ptr.deleteContents();
    return;
  }

  void detach() {
    _ptr.detach();
    return;
  }

  void expand(String unit) {
    _ptr.expand(unit);
    return;
  }

  DocumentFragment extractContents() {
    return LevelDom.wrapDocumentFragment(_ptr.extractContents());
  }

  ClientRect getBoundingClientRect() {
    return LevelDom.wrapClientRect(_ptr.getBoundingClientRect());
  }

  ClientRectList getClientRects() {
    return LevelDom.wrapClientRectList(_ptr.getClientRects());
  }

  void insertNode(Node newNode) {
    _ptr.insertNode(LevelDom.unwrap(newNode));
    return;
  }

  bool intersectsNode(Node refNode) {
    return _ptr.intersectsNode(LevelDom.unwrap(refNode));
  }

  bool isPointInRange(Node refNode, int offset) {
    return _ptr.isPointInRange(LevelDom.unwrap(refNode), offset);
  }

  void selectNode(Node refNode) {
    _ptr.selectNode(LevelDom.unwrap(refNode));
    return;
  }

  void selectNodeContents(Node refNode) {
    _ptr.selectNodeContents(LevelDom.unwrap(refNode));
    return;
  }

  void setEnd(Node refNode, int offset) {
    _ptr.setEnd(LevelDom.unwrap(refNode), offset);
    return;
  }

  void setEndAfter(Node refNode) {
    _ptr.setEndAfter(LevelDom.unwrap(refNode));
    return;
  }

  void setEndBefore(Node refNode) {
    _ptr.setEndBefore(LevelDom.unwrap(refNode));
    return;
  }

  void setStart(Node refNode, int offset) {
    _ptr.setStart(LevelDom.unwrap(refNode), offset);
    return;
  }

  void setStartAfter(Node refNode) {
    _ptr.setStartAfter(LevelDom.unwrap(refNode));
    return;
  }

  void setStartBefore(Node refNode) {
    _ptr.setStartBefore(LevelDom.unwrap(refNode));
    return;
  }

  void surroundContents(Node newParent) {
    _ptr.surroundContents(LevelDom.unwrap(newParent));
    return;
  }

  String toString() {
    return _ptr.toString();
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class RealtimeAnalyserNodeWrappingImplementation extends AudioNodeWrappingImplementation implements RealtimeAnalyserNode {
  RealtimeAnalyserNodeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get fftSize() { return _ptr.fftSize; }

  void set fftSize(int value) { _ptr.fftSize = value; }

  int get frequencyBinCount() { return _ptr.frequencyBinCount; }

  num get maxDecibels() { return _ptr.maxDecibels; }

  void set maxDecibels(num value) { _ptr.maxDecibels = value; }

  num get minDecibels() { return _ptr.minDecibels; }

  void set minDecibels(num value) { _ptr.minDecibels = value; }

  num get smoothingTimeConstant() { return _ptr.smoothingTimeConstant; }

  void set smoothingTimeConstant(num value) { _ptr.smoothingTimeConstant = value; }

  void getByteFrequencyData(Uint8Array array) {
    _ptr.getByteFrequencyData(LevelDom.unwrap(array));
    return;
  }

  void getByteTimeDomainData(Uint8Array array) {
    _ptr.getByteTimeDomainData(LevelDom.unwrap(array));
    return;
  }

  void getFloatFrequencyData(Float32Array array) {
    _ptr.getFloatFrequencyData(LevelDom.unwrap(array));
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class RectWrappingImplementation extends DOMWrapperBase implements Rect {
  RectWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  CSSPrimitiveValue get bottom() { return LevelDom.wrapCSSPrimitiveValue(_ptr.bottom); }

  CSSPrimitiveValue get left() { return LevelDom.wrapCSSPrimitiveValue(_ptr.left); }

  CSSPrimitiveValue get right() { return LevelDom.wrapCSSPrimitiveValue(_ptr.right); }

  CSSPrimitiveValue get top() { return LevelDom.wrapCSSPrimitiveValue(_ptr.top); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGAElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGAElement {
  SVGAElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedString get target() { return LevelDom.wrapSVGAnimatedString(_ptr.target); }

  // From SVGURIReference

  SVGAnimatedString get href() { return LevelDom.wrapSVGAnimatedString(_ptr.href); }

  // From SVGTests

  SVGStringList get requiredExtensions() { return LevelDom.wrapSVGStringList(_ptr.requiredExtensions); }

  SVGStringList get requiredFeatures() { return LevelDom.wrapSVGStringList(_ptr.requiredFeatures); }

  SVGStringList get systemLanguage() { return LevelDom.wrapSVGStringList(_ptr.systemLanguage); }

  bool hasExtension(String extension) {
    return _ptr.hasExtension(extension);
  }

  // From SVGLangSpace

  String get xmllang() { return _ptr.xmllang; }

  void set xmllang(String value) { _ptr.xmllang = value; }

  String get xmlspace() { return _ptr.xmlspace; }

  void set xmlspace(String value) { _ptr.xmlspace = value; }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }

  // From SVGTransformable

  SVGAnimatedTransformList get transform() { return LevelDom.wrapSVGAnimatedTransformList(_ptr.transform); }

  // From SVGLocatable

  SVGElement get farthestViewportElement() { return LevelDom.wrapSVGElement(_ptr.farthestViewportElement); }

  SVGElement get nearestViewportElement() { return LevelDom.wrapSVGElement(_ptr.nearestViewportElement); }

  SVGRect getBBox() {
    return LevelDom.wrapSVGRect(_ptr.getBBox());
  }

  SVGMatrix getCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getCTM());
  }

  SVGMatrix getScreenCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getScreenCTM());
  }

  SVGMatrix getTransformToElement(SVGElement element) {
    return LevelDom.wrapSVGMatrix(_ptr.getTransformToElement(LevelDom.unwrap(element)));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGAltGlyphDefElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGAltGlyphDefElement {
  SVGAltGlyphDefElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGAltGlyphElementWrappingImplementation extends SVGTextPositioningElementWrappingImplementation implements SVGAltGlyphElement {
  SVGAltGlyphElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get format() { return _ptr.format; }

  void set format(String value) { _ptr.format = value; }

  String get glyphRef() { return _ptr.glyphRef; }

  void set glyphRef(String value) { _ptr.glyphRef = value; }

  // From SVGURIReference

  SVGAnimatedString get href() { return LevelDom.wrapSVGAnimatedString(_ptr.href); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGAltGlyphItemElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGAltGlyphItemElement {
  SVGAltGlyphItemElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGAngleWrappingImplementation extends DOMWrapperBase implements SVGAngle {
  SVGAngleWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get unitType() { return _ptr.unitType; }

  num get value() { return _ptr.value; }

  void set value(num value) { _ptr.value = value; }

  String get valueAsString() { return _ptr.valueAsString; }

  void set valueAsString(String value) { _ptr.valueAsString = value; }

  num get valueInSpecifiedUnits() { return _ptr.valueInSpecifiedUnits; }

  void set valueInSpecifiedUnits(num value) { _ptr.valueInSpecifiedUnits = value; }

  void convertToSpecifiedUnits(int unitType) {
    _ptr.convertToSpecifiedUnits(unitType);
    return;
  }

  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) {
    _ptr.newValueSpecifiedUnits(unitType, valueInSpecifiedUnits);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGAnimateColorElementWrappingImplementation extends SVGAnimationElementWrappingImplementation implements SVGAnimateColorElement {
  SVGAnimateColorElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGAnimateElementWrappingImplementation extends SVGAnimationElementWrappingImplementation implements SVGAnimateElement {
  SVGAnimateElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGAnimateMotionElementWrappingImplementation extends SVGAnimationElementWrappingImplementation implements SVGAnimateMotionElement {
  SVGAnimateMotionElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGAnimateTransformElementWrappingImplementation extends SVGAnimationElementWrappingImplementation implements SVGAnimateTransformElement {
  SVGAnimateTransformElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGAnimatedAngleWrappingImplementation extends DOMWrapperBase implements SVGAnimatedAngle {
  SVGAnimatedAngleWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAngle get animVal() { return LevelDom.wrapSVGAngle(_ptr.animVal); }

  SVGAngle get baseVal() { return LevelDom.wrapSVGAngle(_ptr.baseVal); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGAnimatedBooleanWrappingImplementation extends DOMWrapperBase implements SVGAnimatedBoolean {
  SVGAnimatedBooleanWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get animVal() { return _ptr.animVal; }

  bool get baseVal() { return _ptr.baseVal; }

  void set baseVal(bool value) { _ptr.baseVal = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGAnimatedEnumerationWrappingImplementation extends DOMWrapperBase implements SVGAnimatedEnumeration {
  SVGAnimatedEnumerationWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get animVal() { return _ptr.animVal; }

  int get baseVal() { return _ptr.baseVal; }

  void set baseVal(int value) { _ptr.baseVal = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGAnimatedIntegerWrappingImplementation extends DOMWrapperBase implements SVGAnimatedInteger {
  SVGAnimatedIntegerWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get animVal() { return _ptr.animVal; }

  int get baseVal() { return _ptr.baseVal; }

  void set baseVal(int value) { _ptr.baseVal = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGAnimatedLengthListWrappingImplementation extends DOMWrapperBase implements SVGAnimatedLengthList {
  SVGAnimatedLengthListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGLengthList get animVal() { return LevelDom.wrapSVGLengthList(_ptr.animVal); }

  SVGLengthList get baseVal() { return LevelDom.wrapSVGLengthList(_ptr.baseVal); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGAnimatedLengthWrappingImplementation extends DOMWrapperBase implements SVGAnimatedLength {
  SVGAnimatedLengthWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGLength get animVal() { return LevelDom.wrapSVGLength(_ptr.animVal); }

  SVGLength get baseVal() { return LevelDom.wrapSVGLength(_ptr.baseVal); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGAnimatedNumberListWrappingImplementation extends DOMWrapperBase implements SVGAnimatedNumberList {
  SVGAnimatedNumberListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGNumberList get animVal() { return LevelDom.wrapSVGNumberList(_ptr.animVal); }

  SVGNumberList get baseVal() { return LevelDom.wrapSVGNumberList(_ptr.baseVal); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGAnimatedNumberWrappingImplementation extends DOMWrapperBase implements SVGAnimatedNumber {
  SVGAnimatedNumberWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get animVal() { return _ptr.animVal; }

  num get baseVal() { return _ptr.baseVal; }

  void set baseVal(num value) { _ptr.baseVal = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGAnimatedPreserveAspectRatioWrappingImplementation extends DOMWrapperBase implements SVGAnimatedPreserveAspectRatio {
  SVGAnimatedPreserveAspectRatioWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGPreserveAspectRatio get animVal() { return LevelDom.wrapSVGPreserveAspectRatio(_ptr.animVal); }

  SVGPreserveAspectRatio get baseVal() { return LevelDom.wrapSVGPreserveAspectRatio(_ptr.baseVal); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGAnimatedRectWrappingImplementation extends DOMWrapperBase implements SVGAnimatedRect {
  SVGAnimatedRectWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGRect get animVal() { return LevelDom.wrapSVGRect(_ptr.animVal); }

  SVGRect get baseVal() { return LevelDom.wrapSVGRect(_ptr.baseVal); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGAnimatedStringWrappingImplementation extends DOMWrapperBase implements SVGAnimatedString {
  SVGAnimatedStringWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get animVal() { return _ptr.animVal; }

  String get baseVal() { return _ptr.baseVal; }

  void set baseVal(String value) { _ptr.baseVal = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGAnimatedTransformListWrappingImplementation extends DOMWrapperBase implements SVGAnimatedTransformList {
  SVGAnimatedTransformListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGTransformList get animVal() { return LevelDom.wrapSVGTransformList(_ptr.animVal); }

  SVGTransformList get baseVal() { return LevelDom.wrapSVGTransformList(_ptr.baseVal); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGAnimationElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGAnimationElement {
  SVGAnimationElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGElement get targetElement() { return LevelDom.wrapSVGElement(_ptr.targetElement); }

  num getCurrentTime() {
    return _ptr.getCurrentTime();
  }

  num getSimpleDuration() {
    return _ptr.getSimpleDuration();
  }

  num getStartTime() {
    return _ptr.getStartTime();
  }

  // From SVGTests

  SVGStringList get requiredExtensions() { return LevelDom.wrapSVGStringList(_ptr.requiredExtensions); }

  SVGStringList get requiredFeatures() { return LevelDom.wrapSVGStringList(_ptr.requiredFeatures); }

  SVGStringList get systemLanguage() { return LevelDom.wrapSVGStringList(_ptr.systemLanguage); }

  bool hasExtension(String extension) {
    return _ptr.hasExtension(extension);
  }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }

  // From ElementTimeControl

  void beginElement() {
    _ptr.beginElement();
    return;
  }

  void beginElementAt(num offset) {
    _ptr.beginElementAt(offset);
    return;
  }

  void endElement() {
    _ptr.endElement();
    return;
  }

  void endElementAt(num offset) {
    _ptr.endElementAt(offset);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGCircleElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGCircleElement {
  SVGCircleElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedLength get cx() { return LevelDom.wrapSVGAnimatedLength(_ptr.cx); }

  SVGAnimatedLength get cy() { return LevelDom.wrapSVGAnimatedLength(_ptr.cy); }

  SVGAnimatedLength get r() { return LevelDom.wrapSVGAnimatedLength(_ptr.r); }

  // From SVGTests

  SVGStringList get requiredExtensions() { return LevelDom.wrapSVGStringList(_ptr.requiredExtensions); }

  SVGStringList get requiredFeatures() { return LevelDom.wrapSVGStringList(_ptr.requiredFeatures); }

  SVGStringList get systemLanguage() { return LevelDom.wrapSVGStringList(_ptr.systemLanguage); }

  bool hasExtension(String extension) {
    return _ptr.hasExtension(extension);
  }

  // From SVGLangSpace

  String get xmllang() { return _ptr.xmllang; }

  void set xmllang(String value) { _ptr.xmllang = value; }

  String get xmlspace() { return _ptr.xmlspace; }

  void set xmlspace(String value) { _ptr.xmlspace = value; }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }

  // From SVGTransformable

  SVGAnimatedTransformList get transform() { return LevelDom.wrapSVGAnimatedTransformList(_ptr.transform); }

  // From SVGLocatable

  SVGElement get farthestViewportElement() { return LevelDom.wrapSVGElement(_ptr.farthestViewportElement); }

  SVGElement get nearestViewportElement() { return LevelDom.wrapSVGElement(_ptr.nearestViewportElement); }

  SVGRect getBBox() {
    return LevelDom.wrapSVGRect(_ptr.getBBox());
  }

  SVGMatrix getCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getCTM());
  }

  SVGMatrix getScreenCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getScreenCTM());
  }

  SVGMatrix getTransformToElement(SVGElement element) {
    return LevelDom.wrapSVGMatrix(_ptr.getTransformToElement(LevelDom.unwrap(element)));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGClipPathElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGClipPathElement {
  SVGClipPathElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedEnumeration get clipPathUnits() { return LevelDom.wrapSVGAnimatedEnumeration(_ptr.clipPathUnits); }

  // From SVGTests

  SVGStringList get requiredExtensions() { return LevelDom.wrapSVGStringList(_ptr.requiredExtensions); }

  SVGStringList get requiredFeatures() { return LevelDom.wrapSVGStringList(_ptr.requiredFeatures); }

  SVGStringList get systemLanguage() { return LevelDom.wrapSVGStringList(_ptr.systemLanguage); }

  bool hasExtension(String extension) {
    return _ptr.hasExtension(extension);
  }

  // From SVGLangSpace

  String get xmllang() { return _ptr.xmllang; }

  void set xmllang(String value) { _ptr.xmllang = value; }

  String get xmlspace() { return _ptr.xmlspace; }

  void set xmlspace(String value) { _ptr.xmlspace = value; }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }

  // From SVGTransformable

  SVGAnimatedTransformList get transform() { return LevelDom.wrapSVGAnimatedTransformList(_ptr.transform); }

  // From SVGLocatable

  SVGElement get farthestViewportElement() { return LevelDom.wrapSVGElement(_ptr.farthestViewportElement); }

  SVGElement get nearestViewportElement() { return LevelDom.wrapSVGElement(_ptr.nearestViewportElement); }

  SVGRect getBBox() {
    return LevelDom.wrapSVGRect(_ptr.getBBox());
  }

  SVGMatrix getCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getCTM());
  }

  SVGMatrix getScreenCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getScreenCTM());
  }

  SVGMatrix getTransformToElement(SVGElement element) {
    return LevelDom.wrapSVGMatrix(_ptr.getTransformToElement(LevelDom.unwrap(element)));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGColorWrappingImplementation extends CSSValueWrappingImplementation implements SVGColor {
  SVGColorWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get colorType() { return _ptr.colorType; }

  RGBColor get rgbColor() { return LevelDom.wrapRGBColor(_ptr.rgbColor); }

  void setColor(int colorType, String rgbColor, String iccColor) {
    _ptr.setColor(colorType, rgbColor, iccColor);
    return;
  }

  void setRGBColor(String rgbColor) {
    _ptr.setRGBColor(rgbColor);
    return;
  }

  void setRGBColorICCColor(String rgbColor, String iccColor) {
    _ptr.setRGBColorICCColor(rgbColor, iccColor);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGComponentTransferFunctionElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGComponentTransferFunctionElement {
  SVGComponentTransferFunctionElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedNumber get amplitude() { return LevelDom.wrapSVGAnimatedNumber(_ptr.amplitude); }

  SVGAnimatedNumber get exponent() { return LevelDom.wrapSVGAnimatedNumber(_ptr.exponent); }

  SVGAnimatedNumber get intercept() { return LevelDom.wrapSVGAnimatedNumber(_ptr.intercept); }

  SVGAnimatedNumber get offset() { return LevelDom.wrapSVGAnimatedNumber(_ptr.offset); }

  SVGAnimatedNumber get slope() { return LevelDom.wrapSVGAnimatedNumber(_ptr.slope); }

  SVGAnimatedNumberList get tableValues() { return LevelDom.wrapSVGAnimatedNumberList(_ptr.tableValues); }

  SVGAnimatedEnumeration get type() { return LevelDom.wrapSVGAnimatedEnumeration(_ptr.type); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGCursorElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGCursorElement {
  SVGCursorElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedLength get x() { return LevelDom.wrapSVGAnimatedLength(_ptr.x); }

  SVGAnimatedLength get y() { return LevelDom.wrapSVGAnimatedLength(_ptr.y); }

  // From SVGURIReference

  SVGAnimatedString get href() { return LevelDom.wrapSVGAnimatedString(_ptr.href); }

  // From SVGTests

  SVGStringList get requiredExtensions() { return LevelDom.wrapSVGStringList(_ptr.requiredExtensions); }

  SVGStringList get requiredFeatures() { return LevelDom.wrapSVGStringList(_ptr.requiredFeatures); }

  SVGStringList get systemLanguage() { return LevelDom.wrapSVGStringList(_ptr.systemLanguage); }

  bool hasExtension(String extension) {
    return _ptr.hasExtension(extension);
  }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGDefsElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGDefsElement {
  SVGDefsElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  // From SVGTests

  SVGStringList get requiredExtensions() { return LevelDom.wrapSVGStringList(_ptr.requiredExtensions); }

  SVGStringList get requiredFeatures() { return LevelDom.wrapSVGStringList(_ptr.requiredFeatures); }

  SVGStringList get systemLanguage() { return LevelDom.wrapSVGStringList(_ptr.systemLanguage); }

  bool hasExtension(String extension) {
    return _ptr.hasExtension(extension);
  }

  // From SVGLangSpace

  String get xmllang() { return _ptr.xmllang; }

  void set xmllang(String value) { _ptr.xmllang = value; }

  String get xmlspace() { return _ptr.xmlspace; }

  void set xmlspace(String value) { _ptr.xmlspace = value; }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }

  // From SVGTransformable

  SVGAnimatedTransformList get transform() { return LevelDom.wrapSVGAnimatedTransformList(_ptr.transform); }

  // From SVGLocatable

  SVGElement get farthestViewportElement() { return LevelDom.wrapSVGElement(_ptr.farthestViewportElement); }

  SVGElement get nearestViewportElement() { return LevelDom.wrapSVGElement(_ptr.nearestViewportElement); }

  SVGRect getBBox() {
    return LevelDom.wrapSVGRect(_ptr.getBBox());
  }

  SVGMatrix getCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getCTM());
  }

  SVGMatrix getScreenCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getScreenCTM());
  }

  SVGMatrix getTransformToElement(SVGElement element) {
    return LevelDom.wrapSVGMatrix(_ptr.getTransformToElement(LevelDom.unwrap(element)));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGDescElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGDescElement {
  SVGDescElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  // From SVGLangSpace

  String get xmllang() { return _ptr.xmllang; }

  void set xmllang(String value) { _ptr.xmllang = value; }

  String get xmlspace() { return _ptr.xmlspace; }

  void set xmlspace(String value) { _ptr.xmlspace = value; }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGElementInstanceListWrappingImplementation extends DOMWrapperBase implements SVGElementInstanceList {
  SVGElementInstanceListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  SVGElementInstance item(int index) {
    return LevelDom.wrapSVGElementInstance(_ptr.item(index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGElementWrappingImplementation extends ElementWrappingImplementation implements SVGElement {
  SVGElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get id() { return _ptr.id; }

  void set id(String value) { _ptr.id = value; }

  SVGSVGElement get ownerSVGElement() { return LevelDom.wrapSVGSVGElement(_ptr.ownerSVGElement); }

  SVGElement get viewportElement() { return LevelDom.wrapSVGElement(_ptr.viewportElement); }

  String get xmlbase() { return _ptr.xmlbase; }

  void set xmlbase(String value) { _ptr.xmlbase = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGEllipseElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGEllipseElement {
  SVGEllipseElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedLength get cx() { return LevelDom.wrapSVGAnimatedLength(_ptr.cx); }

  SVGAnimatedLength get cy() { return LevelDom.wrapSVGAnimatedLength(_ptr.cy); }

  SVGAnimatedLength get rx() { return LevelDom.wrapSVGAnimatedLength(_ptr.rx); }

  SVGAnimatedLength get ry() { return LevelDom.wrapSVGAnimatedLength(_ptr.ry); }

  // From SVGTests

  SVGStringList get requiredExtensions() { return LevelDom.wrapSVGStringList(_ptr.requiredExtensions); }

  SVGStringList get requiredFeatures() { return LevelDom.wrapSVGStringList(_ptr.requiredFeatures); }

  SVGStringList get systemLanguage() { return LevelDom.wrapSVGStringList(_ptr.systemLanguage); }

  bool hasExtension(String extension) {
    return _ptr.hasExtension(extension);
  }

  // From SVGLangSpace

  String get xmllang() { return _ptr.xmllang; }

  void set xmllang(String value) { _ptr.xmllang = value; }

  String get xmlspace() { return _ptr.xmlspace; }

  void set xmlspace(String value) { _ptr.xmlspace = value; }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }

  // From SVGTransformable

  SVGAnimatedTransformList get transform() { return LevelDom.wrapSVGAnimatedTransformList(_ptr.transform); }

  // From SVGLocatable

  SVGElement get farthestViewportElement() { return LevelDom.wrapSVGElement(_ptr.farthestViewportElement); }

  SVGElement get nearestViewportElement() { return LevelDom.wrapSVGElement(_ptr.nearestViewportElement); }

  SVGRect getBBox() {
    return LevelDom.wrapSVGRect(_ptr.getBBox());
  }

  SVGMatrix getCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getCTM());
  }

  SVGMatrix getScreenCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getScreenCTM());
  }

  SVGMatrix getTransformToElement(SVGElement element) {
    return LevelDom.wrapSVGMatrix(_ptr.getTransformToElement(LevelDom.unwrap(element)));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGExceptionWrappingImplementation extends DOMWrapperBase implements SVGException {
  SVGExceptionWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get code() { return _ptr.code; }

  String get message() { return _ptr.message; }

  String get name() { return _ptr.name; }

  String toString() {
    return _ptr.toString();
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGExternalResourcesRequiredWrappingImplementation extends DOMWrapperBase implements SVGExternalResourcesRequired {
  SVGExternalResourcesRequiredWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFEBlendElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGFEBlendElement {
  SVGFEBlendElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedString get in1() { return LevelDom.wrapSVGAnimatedString(_ptr.in1); }

  SVGAnimatedString get in2() { return LevelDom.wrapSVGAnimatedString(_ptr.in2); }

  SVGAnimatedEnumeration get mode() { return LevelDom.wrapSVGAnimatedEnumeration(_ptr.mode); }

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() { return LevelDom.wrapSVGAnimatedLength(_ptr.height); }

  SVGAnimatedString get result() { return LevelDom.wrapSVGAnimatedString(_ptr.result); }

  SVGAnimatedLength get width() { return LevelDom.wrapSVGAnimatedLength(_ptr.width); }

  SVGAnimatedLength get x() { return LevelDom.wrapSVGAnimatedLength(_ptr.x); }

  SVGAnimatedLength get y() { return LevelDom.wrapSVGAnimatedLength(_ptr.y); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFEColorMatrixElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGFEColorMatrixElement {
  SVGFEColorMatrixElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedString get in1() { return LevelDom.wrapSVGAnimatedString(_ptr.in1); }

  SVGAnimatedEnumeration get type() { return LevelDom.wrapSVGAnimatedEnumeration(_ptr.type); }

  SVGAnimatedNumberList get values() { return LevelDom.wrapSVGAnimatedNumberList(_ptr.values); }

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() { return LevelDom.wrapSVGAnimatedLength(_ptr.height); }

  SVGAnimatedString get result() { return LevelDom.wrapSVGAnimatedString(_ptr.result); }

  SVGAnimatedLength get width() { return LevelDom.wrapSVGAnimatedLength(_ptr.width); }

  SVGAnimatedLength get x() { return LevelDom.wrapSVGAnimatedLength(_ptr.x); }

  SVGAnimatedLength get y() { return LevelDom.wrapSVGAnimatedLength(_ptr.y); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFEComponentTransferElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGFEComponentTransferElement {
  SVGFEComponentTransferElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedString get in1() { return LevelDom.wrapSVGAnimatedString(_ptr.in1); }

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() { return LevelDom.wrapSVGAnimatedLength(_ptr.height); }

  SVGAnimatedString get result() { return LevelDom.wrapSVGAnimatedString(_ptr.result); }

  SVGAnimatedLength get width() { return LevelDom.wrapSVGAnimatedLength(_ptr.width); }

  SVGAnimatedLength get x() { return LevelDom.wrapSVGAnimatedLength(_ptr.x); }

  SVGAnimatedLength get y() { return LevelDom.wrapSVGAnimatedLength(_ptr.y); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFEConvolveMatrixElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGFEConvolveMatrixElement {
  SVGFEConvolveMatrixElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedNumber get bias() { return LevelDom.wrapSVGAnimatedNumber(_ptr.bias); }

  SVGAnimatedNumber get divisor() { return LevelDom.wrapSVGAnimatedNumber(_ptr.divisor); }

  SVGAnimatedEnumeration get edgeMode() { return LevelDom.wrapSVGAnimatedEnumeration(_ptr.edgeMode); }

  SVGAnimatedString get in1() { return LevelDom.wrapSVGAnimatedString(_ptr.in1); }

  SVGAnimatedNumberList get kernelMatrix() { return LevelDom.wrapSVGAnimatedNumberList(_ptr.kernelMatrix); }

  SVGAnimatedNumber get kernelUnitLengthX() { return LevelDom.wrapSVGAnimatedNumber(_ptr.kernelUnitLengthX); }

  SVGAnimatedNumber get kernelUnitLengthY() { return LevelDom.wrapSVGAnimatedNumber(_ptr.kernelUnitLengthY); }

  SVGAnimatedInteger get orderX() { return LevelDom.wrapSVGAnimatedInteger(_ptr.orderX); }

  SVGAnimatedInteger get orderY() { return LevelDom.wrapSVGAnimatedInteger(_ptr.orderY); }

  SVGAnimatedBoolean get preserveAlpha() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.preserveAlpha); }

  SVGAnimatedInteger get targetX() { return LevelDom.wrapSVGAnimatedInteger(_ptr.targetX); }

  SVGAnimatedInteger get targetY() { return LevelDom.wrapSVGAnimatedInteger(_ptr.targetY); }

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() { return LevelDom.wrapSVGAnimatedLength(_ptr.height); }

  SVGAnimatedString get result() { return LevelDom.wrapSVGAnimatedString(_ptr.result); }

  SVGAnimatedLength get width() { return LevelDom.wrapSVGAnimatedLength(_ptr.width); }

  SVGAnimatedLength get x() { return LevelDom.wrapSVGAnimatedLength(_ptr.x); }

  SVGAnimatedLength get y() { return LevelDom.wrapSVGAnimatedLength(_ptr.y); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFEDiffuseLightingElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGFEDiffuseLightingElement {
  SVGFEDiffuseLightingElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedNumber get diffuseConstant() { return LevelDom.wrapSVGAnimatedNumber(_ptr.diffuseConstant); }

  SVGAnimatedString get in1() { return LevelDom.wrapSVGAnimatedString(_ptr.in1); }

  SVGAnimatedNumber get kernelUnitLengthX() { return LevelDom.wrapSVGAnimatedNumber(_ptr.kernelUnitLengthX); }

  SVGAnimatedNumber get kernelUnitLengthY() { return LevelDom.wrapSVGAnimatedNumber(_ptr.kernelUnitLengthY); }

  SVGAnimatedNumber get surfaceScale() { return LevelDom.wrapSVGAnimatedNumber(_ptr.surfaceScale); }

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() { return LevelDom.wrapSVGAnimatedLength(_ptr.height); }

  SVGAnimatedString get result() { return LevelDom.wrapSVGAnimatedString(_ptr.result); }

  SVGAnimatedLength get width() { return LevelDom.wrapSVGAnimatedLength(_ptr.width); }

  SVGAnimatedLength get x() { return LevelDom.wrapSVGAnimatedLength(_ptr.x); }

  SVGAnimatedLength get y() { return LevelDom.wrapSVGAnimatedLength(_ptr.y); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFEDisplacementMapElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGFEDisplacementMapElement {
  SVGFEDisplacementMapElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedString get in1() { return LevelDom.wrapSVGAnimatedString(_ptr.in1); }

  SVGAnimatedString get in2() { return LevelDom.wrapSVGAnimatedString(_ptr.in2); }

  SVGAnimatedNumber get scale() { return LevelDom.wrapSVGAnimatedNumber(_ptr.scale); }

  SVGAnimatedEnumeration get xChannelSelector() { return LevelDom.wrapSVGAnimatedEnumeration(_ptr.xChannelSelector); }

  SVGAnimatedEnumeration get yChannelSelector() { return LevelDom.wrapSVGAnimatedEnumeration(_ptr.yChannelSelector); }

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() { return LevelDom.wrapSVGAnimatedLength(_ptr.height); }

  SVGAnimatedString get result() { return LevelDom.wrapSVGAnimatedString(_ptr.result); }

  SVGAnimatedLength get width() { return LevelDom.wrapSVGAnimatedLength(_ptr.width); }

  SVGAnimatedLength get x() { return LevelDom.wrapSVGAnimatedLength(_ptr.x); }

  SVGAnimatedLength get y() { return LevelDom.wrapSVGAnimatedLength(_ptr.y); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFEDistantLightElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGFEDistantLightElement {
  SVGFEDistantLightElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedNumber get azimuth() { return LevelDom.wrapSVGAnimatedNumber(_ptr.azimuth); }

  SVGAnimatedNumber get elevation() { return LevelDom.wrapSVGAnimatedNumber(_ptr.elevation); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFEDropShadowElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGFEDropShadowElement {
  SVGFEDropShadowElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedNumber get dx() { return LevelDom.wrapSVGAnimatedNumber(_ptr.dx); }

  SVGAnimatedNumber get dy() { return LevelDom.wrapSVGAnimatedNumber(_ptr.dy); }

  SVGAnimatedString get in1() { return LevelDom.wrapSVGAnimatedString(_ptr.in1); }

  SVGAnimatedNumber get stdDeviationX() { return LevelDom.wrapSVGAnimatedNumber(_ptr.stdDeviationX); }

  SVGAnimatedNumber get stdDeviationY() { return LevelDom.wrapSVGAnimatedNumber(_ptr.stdDeviationY); }

  void setStdDeviation(num stdDeviationX, num stdDeviationY) {
    _ptr.setStdDeviation(stdDeviationX, stdDeviationY);
    return;
  }

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() { return LevelDom.wrapSVGAnimatedLength(_ptr.height); }

  SVGAnimatedString get result() { return LevelDom.wrapSVGAnimatedString(_ptr.result); }

  SVGAnimatedLength get width() { return LevelDom.wrapSVGAnimatedLength(_ptr.width); }

  SVGAnimatedLength get x() { return LevelDom.wrapSVGAnimatedLength(_ptr.x); }

  SVGAnimatedLength get y() { return LevelDom.wrapSVGAnimatedLength(_ptr.y); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFEFloodElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGFEFloodElement {
  SVGFEFloodElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() { return LevelDom.wrapSVGAnimatedLength(_ptr.height); }

  SVGAnimatedString get result() { return LevelDom.wrapSVGAnimatedString(_ptr.result); }

  SVGAnimatedLength get width() { return LevelDom.wrapSVGAnimatedLength(_ptr.width); }

  SVGAnimatedLength get x() { return LevelDom.wrapSVGAnimatedLength(_ptr.x); }

  SVGAnimatedLength get y() { return LevelDom.wrapSVGAnimatedLength(_ptr.y); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFEFuncAElementWrappingImplementation extends SVGComponentTransferFunctionElementWrappingImplementation implements SVGFEFuncAElement {
  SVGFEFuncAElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFEFuncBElementWrappingImplementation extends SVGComponentTransferFunctionElementWrappingImplementation implements SVGFEFuncBElement {
  SVGFEFuncBElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFEFuncGElementWrappingImplementation extends SVGComponentTransferFunctionElementWrappingImplementation implements SVGFEFuncGElement {
  SVGFEFuncGElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFEFuncRElementWrappingImplementation extends SVGComponentTransferFunctionElementWrappingImplementation implements SVGFEFuncRElement {
  SVGFEFuncRElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFEGaussianBlurElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGFEGaussianBlurElement {
  SVGFEGaussianBlurElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedString get in1() { return LevelDom.wrapSVGAnimatedString(_ptr.in1); }

  SVGAnimatedNumber get stdDeviationX() { return LevelDom.wrapSVGAnimatedNumber(_ptr.stdDeviationX); }

  SVGAnimatedNumber get stdDeviationY() { return LevelDom.wrapSVGAnimatedNumber(_ptr.stdDeviationY); }

  void setStdDeviation(num stdDeviationX, num stdDeviationY) {
    _ptr.setStdDeviation(stdDeviationX, stdDeviationY);
    return;
  }

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() { return LevelDom.wrapSVGAnimatedLength(_ptr.height); }

  SVGAnimatedString get result() { return LevelDom.wrapSVGAnimatedString(_ptr.result); }

  SVGAnimatedLength get width() { return LevelDom.wrapSVGAnimatedLength(_ptr.width); }

  SVGAnimatedLength get x() { return LevelDom.wrapSVGAnimatedLength(_ptr.x); }

  SVGAnimatedLength get y() { return LevelDom.wrapSVGAnimatedLength(_ptr.y); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFEImageElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGFEImageElement {
  SVGFEImageElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() { return LevelDom.wrapSVGAnimatedPreserveAspectRatio(_ptr.preserveAspectRatio); }

  // From SVGURIReference

  SVGAnimatedString get href() { return LevelDom.wrapSVGAnimatedString(_ptr.href); }

  // From SVGLangSpace

  String get xmllang() { return _ptr.xmllang; }

  void set xmllang(String value) { _ptr.xmllang = value; }

  String get xmlspace() { return _ptr.xmlspace; }

  void set xmlspace(String value) { _ptr.xmlspace = value; }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() { return LevelDom.wrapSVGAnimatedLength(_ptr.height); }

  SVGAnimatedString get result() { return LevelDom.wrapSVGAnimatedString(_ptr.result); }

  SVGAnimatedLength get width() { return LevelDom.wrapSVGAnimatedLength(_ptr.width); }

  SVGAnimatedLength get x() { return LevelDom.wrapSVGAnimatedLength(_ptr.x); }

  SVGAnimatedLength get y() { return LevelDom.wrapSVGAnimatedLength(_ptr.y); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFEMergeElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGFEMergeElement {
  SVGFEMergeElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() { return LevelDom.wrapSVGAnimatedLength(_ptr.height); }

  SVGAnimatedString get result() { return LevelDom.wrapSVGAnimatedString(_ptr.result); }

  SVGAnimatedLength get width() { return LevelDom.wrapSVGAnimatedLength(_ptr.width); }

  SVGAnimatedLength get x() { return LevelDom.wrapSVGAnimatedLength(_ptr.x); }

  SVGAnimatedLength get y() { return LevelDom.wrapSVGAnimatedLength(_ptr.y); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFEMergeNodeElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGFEMergeNodeElement {
  SVGFEMergeNodeElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedString get in1() { return LevelDom.wrapSVGAnimatedString(_ptr.in1); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFEOffsetElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGFEOffsetElement {
  SVGFEOffsetElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedNumber get dx() { return LevelDom.wrapSVGAnimatedNumber(_ptr.dx); }

  SVGAnimatedNumber get dy() { return LevelDom.wrapSVGAnimatedNumber(_ptr.dy); }

  SVGAnimatedString get in1() { return LevelDom.wrapSVGAnimatedString(_ptr.in1); }

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() { return LevelDom.wrapSVGAnimatedLength(_ptr.height); }

  SVGAnimatedString get result() { return LevelDom.wrapSVGAnimatedString(_ptr.result); }

  SVGAnimatedLength get width() { return LevelDom.wrapSVGAnimatedLength(_ptr.width); }

  SVGAnimatedLength get x() { return LevelDom.wrapSVGAnimatedLength(_ptr.x); }

  SVGAnimatedLength get y() { return LevelDom.wrapSVGAnimatedLength(_ptr.y); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFEPointLightElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGFEPointLightElement {
  SVGFEPointLightElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedNumber get x() { return LevelDom.wrapSVGAnimatedNumber(_ptr.x); }

  SVGAnimatedNumber get y() { return LevelDom.wrapSVGAnimatedNumber(_ptr.y); }

  SVGAnimatedNumber get z() { return LevelDom.wrapSVGAnimatedNumber(_ptr.z); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFESpecularLightingElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGFESpecularLightingElement {
  SVGFESpecularLightingElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedString get in1() { return LevelDom.wrapSVGAnimatedString(_ptr.in1); }

  SVGAnimatedNumber get specularConstant() { return LevelDom.wrapSVGAnimatedNumber(_ptr.specularConstant); }

  SVGAnimatedNumber get specularExponent() { return LevelDom.wrapSVGAnimatedNumber(_ptr.specularExponent); }

  SVGAnimatedNumber get surfaceScale() { return LevelDom.wrapSVGAnimatedNumber(_ptr.surfaceScale); }

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() { return LevelDom.wrapSVGAnimatedLength(_ptr.height); }

  SVGAnimatedString get result() { return LevelDom.wrapSVGAnimatedString(_ptr.result); }

  SVGAnimatedLength get width() { return LevelDom.wrapSVGAnimatedLength(_ptr.width); }

  SVGAnimatedLength get x() { return LevelDom.wrapSVGAnimatedLength(_ptr.x); }

  SVGAnimatedLength get y() { return LevelDom.wrapSVGAnimatedLength(_ptr.y); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFESpotLightElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGFESpotLightElement {
  SVGFESpotLightElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedNumber get limitingConeAngle() { return LevelDom.wrapSVGAnimatedNumber(_ptr.limitingConeAngle); }

  SVGAnimatedNumber get pointsAtX() { return LevelDom.wrapSVGAnimatedNumber(_ptr.pointsAtX); }

  SVGAnimatedNumber get pointsAtY() { return LevelDom.wrapSVGAnimatedNumber(_ptr.pointsAtY); }

  SVGAnimatedNumber get pointsAtZ() { return LevelDom.wrapSVGAnimatedNumber(_ptr.pointsAtZ); }

  SVGAnimatedNumber get specularExponent() { return LevelDom.wrapSVGAnimatedNumber(_ptr.specularExponent); }

  SVGAnimatedNumber get x() { return LevelDom.wrapSVGAnimatedNumber(_ptr.x); }

  SVGAnimatedNumber get y() { return LevelDom.wrapSVGAnimatedNumber(_ptr.y); }

  SVGAnimatedNumber get z() { return LevelDom.wrapSVGAnimatedNumber(_ptr.z); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFETileElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGFETileElement {
  SVGFETileElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedString get in1() { return LevelDom.wrapSVGAnimatedString(_ptr.in1); }

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() { return LevelDom.wrapSVGAnimatedLength(_ptr.height); }

  SVGAnimatedString get result() { return LevelDom.wrapSVGAnimatedString(_ptr.result); }

  SVGAnimatedLength get width() { return LevelDom.wrapSVGAnimatedLength(_ptr.width); }

  SVGAnimatedLength get x() { return LevelDom.wrapSVGAnimatedLength(_ptr.x); }

  SVGAnimatedLength get y() { return LevelDom.wrapSVGAnimatedLength(_ptr.y); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFETurbulenceElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGFETurbulenceElement {
  SVGFETurbulenceElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedNumber get baseFrequencyX() { return LevelDom.wrapSVGAnimatedNumber(_ptr.baseFrequencyX); }

  SVGAnimatedNumber get baseFrequencyY() { return LevelDom.wrapSVGAnimatedNumber(_ptr.baseFrequencyY); }

  SVGAnimatedInteger get numOctaves() { return LevelDom.wrapSVGAnimatedInteger(_ptr.numOctaves); }

  SVGAnimatedNumber get seed() { return LevelDom.wrapSVGAnimatedNumber(_ptr.seed); }

  SVGAnimatedEnumeration get stitchTiles() { return LevelDom.wrapSVGAnimatedEnumeration(_ptr.stitchTiles); }

  SVGAnimatedEnumeration get type() { return LevelDom.wrapSVGAnimatedEnumeration(_ptr.type); }

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() { return LevelDom.wrapSVGAnimatedLength(_ptr.height); }

  SVGAnimatedString get result() { return LevelDom.wrapSVGAnimatedString(_ptr.result); }

  SVGAnimatedLength get width() { return LevelDom.wrapSVGAnimatedLength(_ptr.width); }

  SVGAnimatedLength get x() { return LevelDom.wrapSVGAnimatedLength(_ptr.x); }

  SVGAnimatedLength get y() { return LevelDom.wrapSVGAnimatedLength(_ptr.y); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFilterElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGFilterElement {
  SVGFilterElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedInteger get filterResX() { return LevelDom.wrapSVGAnimatedInteger(_ptr.filterResX); }

  SVGAnimatedInteger get filterResY() { return LevelDom.wrapSVGAnimatedInteger(_ptr.filterResY); }

  SVGAnimatedEnumeration get filterUnits() { return LevelDom.wrapSVGAnimatedEnumeration(_ptr.filterUnits); }

  SVGAnimatedLength get height() { return LevelDom.wrapSVGAnimatedLength(_ptr.height); }

  SVGAnimatedEnumeration get primitiveUnits() { return LevelDom.wrapSVGAnimatedEnumeration(_ptr.primitiveUnits); }

  SVGAnimatedLength get width() { return LevelDom.wrapSVGAnimatedLength(_ptr.width); }

  SVGAnimatedLength get x() { return LevelDom.wrapSVGAnimatedLength(_ptr.x); }

  SVGAnimatedLength get y() { return LevelDom.wrapSVGAnimatedLength(_ptr.y); }

  void setFilterRes(int filterResX, int filterResY) {
    _ptr.setFilterRes(filterResX, filterResY);
    return;
  }

  // From SVGURIReference

  SVGAnimatedString get href() { return LevelDom.wrapSVGAnimatedString(_ptr.href); }

  // From SVGLangSpace

  String get xmllang() { return _ptr.xmllang; }

  void set xmllang(String value) { _ptr.xmllang = value; }

  String get xmlspace() { return _ptr.xmlspace; }

  void set xmlspace(String value) { _ptr.xmlspace = value; }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFilterPrimitiveStandardAttributesWrappingImplementation extends SVGStylableWrappingImplementation implements SVGFilterPrimitiveStandardAttributes {
  SVGFilterPrimitiveStandardAttributesWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedLength get height() { return LevelDom.wrapSVGAnimatedLength(_ptr.height); }

  SVGAnimatedString get result() { return LevelDom.wrapSVGAnimatedString(_ptr.result); }

  SVGAnimatedLength get width() { return LevelDom.wrapSVGAnimatedLength(_ptr.width); }

  SVGAnimatedLength get x() { return LevelDom.wrapSVGAnimatedLength(_ptr.x); }

  SVGAnimatedLength get y() { return LevelDom.wrapSVGAnimatedLength(_ptr.y); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFitToViewBoxWrappingImplementation extends DOMWrapperBase implements SVGFitToViewBox {
  SVGFitToViewBoxWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() { return LevelDom.wrapSVGAnimatedPreserveAspectRatio(_ptr.preserveAspectRatio); }

  SVGAnimatedRect get viewBox() { return LevelDom.wrapSVGAnimatedRect(_ptr.viewBox); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFontElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGFontElement {
  SVGFontElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFontFaceElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGFontFaceElement {
  SVGFontFaceElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFontFaceFormatElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGFontFaceFormatElement {
  SVGFontFaceFormatElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFontFaceNameElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGFontFaceNameElement {
  SVGFontFaceNameElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFontFaceSrcElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGFontFaceSrcElement {
  SVGFontFaceSrcElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGFontFaceUriElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGFontFaceUriElement {
  SVGFontFaceUriElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGForeignObjectElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGForeignObjectElement {
  SVGForeignObjectElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedLength get height() { return LevelDom.wrapSVGAnimatedLength(_ptr.height); }

  SVGAnimatedLength get width() { return LevelDom.wrapSVGAnimatedLength(_ptr.width); }

  SVGAnimatedLength get x() { return LevelDom.wrapSVGAnimatedLength(_ptr.x); }

  SVGAnimatedLength get y() { return LevelDom.wrapSVGAnimatedLength(_ptr.y); }

  // From SVGTests

  SVGStringList get requiredExtensions() { return LevelDom.wrapSVGStringList(_ptr.requiredExtensions); }

  SVGStringList get requiredFeatures() { return LevelDom.wrapSVGStringList(_ptr.requiredFeatures); }

  SVGStringList get systemLanguage() { return LevelDom.wrapSVGStringList(_ptr.systemLanguage); }

  bool hasExtension(String extension) {
    return _ptr.hasExtension(extension);
  }

  // From SVGLangSpace

  String get xmllang() { return _ptr.xmllang; }

  void set xmllang(String value) { _ptr.xmllang = value; }

  String get xmlspace() { return _ptr.xmlspace; }

  void set xmlspace(String value) { _ptr.xmlspace = value; }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }

  // From SVGTransformable

  SVGAnimatedTransformList get transform() { return LevelDom.wrapSVGAnimatedTransformList(_ptr.transform); }

  // From SVGLocatable

  SVGElement get farthestViewportElement() { return LevelDom.wrapSVGElement(_ptr.farthestViewportElement); }

  SVGElement get nearestViewportElement() { return LevelDom.wrapSVGElement(_ptr.nearestViewportElement); }

  SVGRect getBBox() {
    return LevelDom.wrapSVGRect(_ptr.getBBox());
  }

  SVGMatrix getCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getCTM());
  }

  SVGMatrix getScreenCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getScreenCTM());
  }

  SVGMatrix getTransformToElement(SVGElement element) {
    return LevelDom.wrapSVGMatrix(_ptr.getTransformToElement(LevelDom.unwrap(element)));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGGElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGGElement {
  SVGGElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  // From SVGTests

  SVGStringList get requiredExtensions() { return LevelDom.wrapSVGStringList(_ptr.requiredExtensions); }

  SVGStringList get requiredFeatures() { return LevelDom.wrapSVGStringList(_ptr.requiredFeatures); }

  SVGStringList get systemLanguage() { return LevelDom.wrapSVGStringList(_ptr.systemLanguage); }

  bool hasExtension(String extension) {
    return _ptr.hasExtension(extension);
  }

  // From SVGLangSpace

  String get xmllang() { return _ptr.xmllang; }

  void set xmllang(String value) { _ptr.xmllang = value; }

  String get xmlspace() { return _ptr.xmlspace; }

  void set xmlspace(String value) { _ptr.xmlspace = value; }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }

  // From SVGTransformable

  SVGAnimatedTransformList get transform() { return LevelDom.wrapSVGAnimatedTransformList(_ptr.transform); }

  // From SVGLocatable

  SVGElement get farthestViewportElement() { return LevelDom.wrapSVGElement(_ptr.farthestViewportElement); }

  SVGElement get nearestViewportElement() { return LevelDom.wrapSVGElement(_ptr.nearestViewportElement); }

  SVGRect getBBox() {
    return LevelDom.wrapSVGRect(_ptr.getBBox());
  }

  SVGMatrix getCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getCTM());
  }

  SVGMatrix getScreenCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getScreenCTM());
  }

  SVGMatrix getTransformToElement(SVGElement element) {
    return LevelDom.wrapSVGMatrix(_ptr.getTransformToElement(LevelDom.unwrap(element)));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGGlyphElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGGlyphElement {
  SVGGlyphElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGGlyphRefElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGGlyphRefElement {
  SVGGlyphRefElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get dx() { return _ptr.dx; }

  void set dx(num value) { _ptr.dx = value; }

  num get dy() { return _ptr.dy; }

  void set dy(num value) { _ptr.dy = value; }

  String get format() { return _ptr.format; }

  void set format(String value) { _ptr.format = value; }

  String get glyphRef() { return _ptr.glyphRef; }

  void set glyphRef(String value) { _ptr.glyphRef = value; }

  num get x() { return _ptr.x; }

  void set x(num value) { _ptr.x = value; }

  num get y() { return _ptr.y; }

  void set y(num value) { _ptr.y = value; }

  // From SVGURIReference

  SVGAnimatedString get href() { return LevelDom.wrapSVGAnimatedString(_ptr.href); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGGradientElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGGradientElement {
  SVGGradientElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedTransformList get gradientTransform() { return LevelDom.wrapSVGAnimatedTransformList(_ptr.gradientTransform); }

  SVGAnimatedEnumeration get gradientUnits() { return LevelDom.wrapSVGAnimatedEnumeration(_ptr.gradientUnits); }

  SVGAnimatedEnumeration get spreadMethod() { return LevelDom.wrapSVGAnimatedEnumeration(_ptr.spreadMethod); }

  // From SVGURIReference

  SVGAnimatedString get href() { return LevelDom.wrapSVGAnimatedString(_ptr.href); }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGHKernElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGHKernElement {
  SVGHKernElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGImageElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGImageElement {
  SVGImageElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedLength get height() { return LevelDom.wrapSVGAnimatedLength(_ptr.height); }

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() { return LevelDom.wrapSVGAnimatedPreserveAspectRatio(_ptr.preserveAspectRatio); }

  SVGAnimatedLength get width() { return LevelDom.wrapSVGAnimatedLength(_ptr.width); }

  SVGAnimatedLength get x() { return LevelDom.wrapSVGAnimatedLength(_ptr.x); }

  SVGAnimatedLength get y() { return LevelDom.wrapSVGAnimatedLength(_ptr.y); }

  // From SVGURIReference

  SVGAnimatedString get href() { return LevelDom.wrapSVGAnimatedString(_ptr.href); }

  // From SVGTests

  SVGStringList get requiredExtensions() { return LevelDom.wrapSVGStringList(_ptr.requiredExtensions); }

  SVGStringList get requiredFeatures() { return LevelDom.wrapSVGStringList(_ptr.requiredFeatures); }

  SVGStringList get systemLanguage() { return LevelDom.wrapSVGStringList(_ptr.systemLanguage); }

  bool hasExtension(String extension) {
    return _ptr.hasExtension(extension);
  }

  // From SVGLangSpace

  String get xmllang() { return _ptr.xmllang; }

  void set xmllang(String value) { _ptr.xmllang = value; }

  String get xmlspace() { return _ptr.xmlspace; }

  void set xmlspace(String value) { _ptr.xmlspace = value; }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }

  // From SVGTransformable

  SVGAnimatedTransformList get transform() { return LevelDom.wrapSVGAnimatedTransformList(_ptr.transform); }

  // From SVGLocatable

  SVGElement get farthestViewportElement() { return LevelDom.wrapSVGElement(_ptr.farthestViewportElement); }

  SVGElement get nearestViewportElement() { return LevelDom.wrapSVGElement(_ptr.nearestViewportElement); }

  SVGRect getBBox() {
    return LevelDom.wrapSVGRect(_ptr.getBBox());
  }

  SVGMatrix getCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getCTM());
  }

  SVGMatrix getScreenCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getScreenCTM());
  }

  SVGMatrix getTransformToElement(SVGElement element) {
    return LevelDom.wrapSVGMatrix(_ptr.getTransformToElement(LevelDom.unwrap(element)));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGLangSpaceWrappingImplementation extends DOMWrapperBase implements SVGLangSpace {
  SVGLangSpaceWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get xmllang() { return _ptr.xmllang; }

  void set xmllang(String value) { _ptr.xmllang = value; }

  String get xmlspace() { return _ptr.xmlspace; }

  void set xmlspace(String value) { _ptr.xmlspace = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGLengthListWrappingImplementation extends DOMWrapperBase implements SVGLengthList {
  SVGLengthListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get numberOfItems() { return _ptr.numberOfItems; }

  SVGLength appendItem(SVGLength item) {
    return LevelDom.wrapSVGLength(_ptr.appendItem(LevelDom.unwrap(item)));
  }

  void clear() {
    _ptr.clear();
    return;
  }

  SVGLength getItem(int index) {
    return LevelDom.wrapSVGLength(_ptr.getItem(index));
  }

  SVGLength initialize(SVGLength item) {
    return LevelDom.wrapSVGLength(_ptr.initialize(LevelDom.unwrap(item)));
  }

  SVGLength insertItemBefore(SVGLength item, int index) {
    return LevelDom.wrapSVGLength(_ptr.insertItemBefore(LevelDom.unwrap(item), index));
  }

  SVGLength removeItem(int index) {
    return LevelDom.wrapSVGLength(_ptr.removeItem(index));
  }

  SVGLength replaceItem(SVGLength item, int index) {
    return LevelDom.wrapSVGLength(_ptr.replaceItem(LevelDom.unwrap(item), index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGLengthWrappingImplementation extends DOMWrapperBase implements SVGLength {
  SVGLengthWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get unitType() { return _ptr.unitType; }

  num get value() { return _ptr.value; }

  void set value(num value) { _ptr.value = value; }

  String get valueAsString() { return _ptr.valueAsString; }

  void set valueAsString(String value) { _ptr.valueAsString = value; }

  num get valueInSpecifiedUnits() { return _ptr.valueInSpecifiedUnits; }

  void set valueInSpecifiedUnits(num value) { _ptr.valueInSpecifiedUnits = value; }

  void convertToSpecifiedUnits(int unitType) {
    _ptr.convertToSpecifiedUnits(unitType);
    return;
  }

  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) {
    _ptr.newValueSpecifiedUnits(unitType, valueInSpecifiedUnits);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGLineElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGLineElement {
  SVGLineElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedLength get x1() { return LevelDom.wrapSVGAnimatedLength(_ptr.x1); }

  SVGAnimatedLength get x2() { return LevelDom.wrapSVGAnimatedLength(_ptr.x2); }

  SVGAnimatedLength get y1() { return LevelDom.wrapSVGAnimatedLength(_ptr.y1); }

  SVGAnimatedLength get y2() { return LevelDom.wrapSVGAnimatedLength(_ptr.y2); }

  // From SVGTests

  SVGStringList get requiredExtensions() { return LevelDom.wrapSVGStringList(_ptr.requiredExtensions); }

  SVGStringList get requiredFeatures() { return LevelDom.wrapSVGStringList(_ptr.requiredFeatures); }

  SVGStringList get systemLanguage() { return LevelDom.wrapSVGStringList(_ptr.systemLanguage); }

  bool hasExtension(String extension) {
    return _ptr.hasExtension(extension);
  }

  // From SVGLangSpace

  String get xmllang() { return _ptr.xmllang; }

  void set xmllang(String value) { _ptr.xmllang = value; }

  String get xmlspace() { return _ptr.xmlspace; }

  void set xmlspace(String value) { _ptr.xmlspace = value; }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }

  // From SVGTransformable

  SVGAnimatedTransformList get transform() { return LevelDom.wrapSVGAnimatedTransformList(_ptr.transform); }

  // From SVGLocatable

  SVGElement get farthestViewportElement() { return LevelDom.wrapSVGElement(_ptr.farthestViewportElement); }

  SVGElement get nearestViewportElement() { return LevelDom.wrapSVGElement(_ptr.nearestViewportElement); }

  SVGRect getBBox() {
    return LevelDom.wrapSVGRect(_ptr.getBBox());
  }

  SVGMatrix getCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getCTM());
  }

  SVGMatrix getScreenCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getScreenCTM());
  }

  SVGMatrix getTransformToElement(SVGElement element) {
    return LevelDom.wrapSVGMatrix(_ptr.getTransformToElement(LevelDom.unwrap(element)));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGLinearGradientElementWrappingImplementation extends SVGGradientElementWrappingImplementation implements SVGLinearGradientElement {
  SVGLinearGradientElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedLength get x1() { return LevelDom.wrapSVGAnimatedLength(_ptr.x1); }

  SVGAnimatedLength get x2() { return LevelDom.wrapSVGAnimatedLength(_ptr.x2); }

  SVGAnimatedLength get y1() { return LevelDom.wrapSVGAnimatedLength(_ptr.y1); }

  SVGAnimatedLength get y2() { return LevelDom.wrapSVGAnimatedLength(_ptr.y2); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGLocatableWrappingImplementation extends DOMWrapperBase implements SVGLocatable {
  SVGLocatableWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGElement get farthestViewportElement() { return LevelDom.wrapSVGElement(_ptr.farthestViewportElement); }

  SVGElement get nearestViewportElement() { return LevelDom.wrapSVGElement(_ptr.nearestViewportElement); }

  SVGRect getBBox() {
    return LevelDom.wrapSVGRect(_ptr.getBBox());
  }

  SVGMatrix getCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getCTM());
  }

  SVGMatrix getScreenCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getScreenCTM());
  }

  SVGMatrix getTransformToElement(SVGElement element) {
    return LevelDom.wrapSVGMatrix(_ptr.getTransformToElement(LevelDom.unwrap(element)));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGMPathElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGMPathElement {
  SVGMPathElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  // From SVGURIReference

  SVGAnimatedString get href() { return LevelDom.wrapSVGAnimatedString(_ptr.href); }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGMarkerElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGMarkerElement {
  SVGMarkerElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedLength get markerHeight() { return LevelDom.wrapSVGAnimatedLength(_ptr.markerHeight); }

  SVGAnimatedEnumeration get markerUnits() { return LevelDom.wrapSVGAnimatedEnumeration(_ptr.markerUnits); }

  SVGAnimatedLength get markerWidth() { return LevelDom.wrapSVGAnimatedLength(_ptr.markerWidth); }

  SVGAnimatedAngle get orientAngle() { return LevelDom.wrapSVGAnimatedAngle(_ptr.orientAngle); }

  SVGAnimatedEnumeration get orientType() { return LevelDom.wrapSVGAnimatedEnumeration(_ptr.orientType); }

  SVGAnimatedLength get refX() { return LevelDom.wrapSVGAnimatedLength(_ptr.refX); }

  SVGAnimatedLength get refY() { return LevelDom.wrapSVGAnimatedLength(_ptr.refY); }

  void setOrientToAngle(SVGAngle angle) {
    _ptr.setOrientToAngle(LevelDom.unwrap(angle));
    return;
  }

  void setOrientToAuto() {
    _ptr.setOrientToAuto();
    return;
  }

  // From SVGLangSpace

  String get xmllang() { return _ptr.xmllang; }

  void set xmllang(String value) { _ptr.xmllang = value; }

  String get xmlspace() { return _ptr.xmlspace; }

  void set xmlspace(String value) { _ptr.xmlspace = value; }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() { return LevelDom.wrapSVGAnimatedPreserveAspectRatio(_ptr.preserveAspectRatio); }

  SVGAnimatedRect get viewBox() { return LevelDom.wrapSVGAnimatedRect(_ptr.viewBox); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGMaskElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGMaskElement {
  SVGMaskElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedLength get height() { return LevelDom.wrapSVGAnimatedLength(_ptr.height); }

  SVGAnimatedEnumeration get maskContentUnits() { return LevelDom.wrapSVGAnimatedEnumeration(_ptr.maskContentUnits); }

  SVGAnimatedEnumeration get maskUnits() { return LevelDom.wrapSVGAnimatedEnumeration(_ptr.maskUnits); }

  SVGAnimatedLength get width() { return LevelDom.wrapSVGAnimatedLength(_ptr.width); }

  SVGAnimatedLength get x() { return LevelDom.wrapSVGAnimatedLength(_ptr.x); }

  SVGAnimatedLength get y() { return LevelDom.wrapSVGAnimatedLength(_ptr.y); }

  // From SVGTests

  SVGStringList get requiredExtensions() { return LevelDom.wrapSVGStringList(_ptr.requiredExtensions); }

  SVGStringList get requiredFeatures() { return LevelDom.wrapSVGStringList(_ptr.requiredFeatures); }

  SVGStringList get systemLanguage() { return LevelDom.wrapSVGStringList(_ptr.systemLanguage); }

  bool hasExtension(String extension) {
    return _ptr.hasExtension(extension);
  }

  // From SVGLangSpace

  String get xmllang() { return _ptr.xmllang; }

  void set xmllang(String value) { _ptr.xmllang = value; }

  String get xmlspace() { return _ptr.xmlspace; }

  void set xmlspace(String value) { _ptr.xmlspace = value; }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGMatrixWrappingImplementation extends DOMWrapperBase implements SVGMatrix {
  SVGMatrixWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get a() { return _ptr.a; }

  void set a(num value) { _ptr.a = value; }

  num get b() { return _ptr.b; }

  void set b(num value) { _ptr.b = value; }

  num get c() { return _ptr.c; }

  void set c(num value) { _ptr.c = value; }

  num get d() { return _ptr.d; }

  void set d(num value) { _ptr.d = value; }

  num get e() { return _ptr.e; }

  void set e(num value) { _ptr.e = value; }

  num get f() { return _ptr.f; }

  void set f(num value) { _ptr.f = value; }

  SVGMatrix flipX() {
    return LevelDom.wrapSVGMatrix(_ptr.flipX());
  }

  SVGMatrix flipY() {
    return LevelDom.wrapSVGMatrix(_ptr.flipY());
  }

  SVGMatrix inverse() {
    return LevelDom.wrapSVGMatrix(_ptr.inverse());
  }

  SVGMatrix multiply(SVGMatrix secondMatrix) {
    return LevelDom.wrapSVGMatrix(_ptr.multiply(LevelDom.unwrap(secondMatrix)));
  }

  SVGMatrix rotate(num angle) {
    return LevelDom.wrapSVGMatrix(_ptr.rotate(angle));
  }

  SVGMatrix rotateFromVector(num x, num y) {
    return LevelDom.wrapSVGMatrix(_ptr.rotateFromVector(x, y));
  }

  SVGMatrix scale(num scaleFactor) {
    return LevelDom.wrapSVGMatrix(_ptr.scale(scaleFactor));
  }

  SVGMatrix scaleNonUniform(num scaleFactorX, num scaleFactorY) {
    return LevelDom.wrapSVGMatrix(_ptr.scaleNonUniform(scaleFactorX, scaleFactorY));
  }

  SVGMatrix skewX(num angle) {
    return LevelDom.wrapSVGMatrix(_ptr.skewX(angle));
  }

  SVGMatrix skewY(num angle) {
    return LevelDom.wrapSVGMatrix(_ptr.skewY(angle));
  }

  SVGMatrix translate(num x, num y) {
    return LevelDom.wrapSVGMatrix(_ptr.translate(x, y));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGMetadataElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGMetadataElement {
  SVGMetadataElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGMissingGlyphElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGMissingGlyphElement {
  SVGMissingGlyphElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGNumberListWrappingImplementation extends DOMWrapperBase implements SVGNumberList {
  SVGNumberListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get numberOfItems() { return _ptr.numberOfItems; }

  SVGNumber appendItem(SVGNumber item) {
    return LevelDom.wrapSVGNumber(_ptr.appendItem(LevelDom.unwrap(item)));
  }

  void clear() {
    _ptr.clear();
    return;
  }

  SVGNumber getItem(int index) {
    return LevelDom.wrapSVGNumber(_ptr.getItem(index));
  }

  SVGNumber initialize(SVGNumber item) {
    return LevelDom.wrapSVGNumber(_ptr.initialize(LevelDom.unwrap(item)));
  }

  SVGNumber insertItemBefore(SVGNumber item, int index) {
    return LevelDom.wrapSVGNumber(_ptr.insertItemBefore(LevelDom.unwrap(item), index));
  }

  SVGNumber removeItem(int index) {
    return LevelDom.wrapSVGNumber(_ptr.removeItem(index));
  }

  SVGNumber replaceItem(SVGNumber item, int index) {
    return LevelDom.wrapSVGNumber(_ptr.replaceItem(LevelDom.unwrap(item), index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGNumberWrappingImplementation extends DOMWrapperBase implements SVGNumber {
  SVGNumberWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get value() { return _ptr.value; }

  void set value(num value) { _ptr.value = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPaintWrappingImplementation extends SVGColorWrappingImplementation implements SVGPaint {
  SVGPaintWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get paintType() { return _ptr.paintType; }

  String get uri() { return _ptr.uri; }

  void setPaint(int paintType, String uri, String rgbColor, String iccColor) {
    _ptr.setPaint(paintType, uri, rgbColor, iccColor);
    return;
  }

  void setUri(String uri) {
    _ptr.setUri(uri);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPathElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGPathElement {
  SVGPathElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGPathSegList get animatedNormalizedPathSegList() { return LevelDom.wrapSVGPathSegList(_ptr.animatedNormalizedPathSegList); }

  SVGPathSegList get animatedPathSegList() { return LevelDom.wrapSVGPathSegList(_ptr.animatedPathSegList); }

  SVGPathSegList get normalizedPathSegList() { return LevelDom.wrapSVGPathSegList(_ptr.normalizedPathSegList); }

  SVGAnimatedNumber get pathLength() { return LevelDom.wrapSVGAnimatedNumber(_ptr.pathLength); }

  SVGPathSegList get pathSegList() { return LevelDom.wrapSVGPathSegList(_ptr.pathSegList); }

  SVGPathSegArcAbs createSVGPathSegArcAbs(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) {
    return LevelDom.wrapSVGPathSegArcAbs(_ptr.createSVGPathSegArcAbs(x, y, r1, r2, angle, largeArcFlag, sweepFlag));
  }

  SVGPathSegArcRel createSVGPathSegArcRel(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) {
    return LevelDom.wrapSVGPathSegArcRel(_ptr.createSVGPathSegArcRel(x, y, r1, r2, angle, largeArcFlag, sweepFlag));
  }

  SVGPathSegClosePath createSVGPathSegClosePath() {
    return LevelDom.wrapSVGPathSegClosePath(_ptr.createSVGPathSegClosePath());
  }

  SVGPathSegCurvetoCubicAbs createSVGPathSegCurvetoCubicAbs(num x, num y, num x1, num y1, num x2, num y2) {
    return LevelDom.wrapSVGPathSegCurvetoCubicAbs(_ptr.createSVGPathSegCurvetoCubicAbs(x, y, x1, y1, x2, y2));
  }

  SVGPathSegCurvetoCubicRel createSVGPathSegCurvetoCubicRel(num x, num y, num x1, num y1, num x2, num y2) {
    return LevelDom.wrapSVGPathSegCurvetoCubicRel(_ptr.createSVGPathSegCurvetoCubicRel(x, y, x1, y1, x2, y2));
  }

  SVGPathSegCurvetoCubicSmoothAbs createSVGPathSegCurvetoCubicSmoothAbs(num x, num y, num x2, num y2) {
    return LevelDom.wrapSVGPathSegCurvetoCubicSmoothAbs(_ptr.createSVGPathSegCurvetoCubicSmoothAbs(x, y, x2, y2));
  }

  SVGPathSegCurvetoCubicSmoothRel createSVGPathSegCurvetoCubicSmoothRel(num x, num y, num x2, num y2) {
    return LevelDom.wrapSVGPathSegCurvetoCubicSmoothRel(_ptr.createSVGPathSegCurvetoCubicSmoothRel(x, y, x2, y2));
  }

  SVGPathSegCurvetoQuadraticAbs createSVGPathSegCurvetoQuadraticAbs(num x, num y, num x1, num y1) {
    return LevelDom.wrapSVGPathSegCurvetoQuadraticAbs(_ptr.createSVGPathSegCurvetoQuadraticAbs(x, y, x1, y1));
  }

  SVGPathSegCurvetoQuadraticRel createSVGPathSegCurvetoQuadraticRel(num x, num y, num x1, num y1) {
    return LevelDom.wrapSVGPathSegCurvetoQuadraticRel(_ptr.createSVGPathSegCurvetoQuadraticRel(x, y, x1, y1));
  }

  SVGPathSegCurvetoQuadraticSmoothAbs createSVGPathSegCurvetoQuadraticSmoothAbs(num x, num y) {
    return LevelDom.wrapSVGPathSegCurvetoQuadraticSmoothAbs(_ptr.createSVGPathSegCurvetoQuadraticSmoothAbs(x, y));
  }

  SVGPathSegCurvetoQuadraticSmoothRel createSVGPathSegCurvetoQuadraticSmoothRel(num x, num y) {
    return LevelDom.wrapSVGPathSegCurvetoQuadraticSmoothRel(_ptr.createSVGPathSegCurvetoQuadraticSmoothRel(x, y));
  }

  SVGPathSegLinetoAbs createSVGPathSegLinetoAbs(num x, num y) {
    return LevelDom.wrapSVGPathSegLinetoAbs(_ptr.createSVGPathSegLinetoAbs(x, y));
  }

  SVGPathSegLinetoHorizontalAbs createSVGPathSegLinetoHorizontalAbs(num x) {
    return LevelDom.wrapSVGPathSegLinetoHorizontalAbs(_ptr.createSVGPathSegLinetoHorizontalAbs(x));
  }

  SVGPathSegLinetoHorizontalRel createSVGPathSegLinetoHorizontalRel(num x) {
    return LevelDom.wrapSVGPathSegLinetoHorizontalRel(_ptr.createSVGPathSegLinetoHorizontalRel(x));
  }

  SVGPathSegLinetoRel createSVGPathSegLinetoRel(num x, num y) {
    return LevelDom.wrapSVGPathSegLinetoRel(_ptr.createSVGPathSegLinetoRel(x, y));
  }

  SVGPathSegLinetoVerticalAbs createSVGPathSegLinetoVerticalAbs(num y) {
    return LevelDom.wrapSVGPathSegLinetoVerticalAbs(_ptr.createSVGPathSegLinetoVerticalAbs(y));
  }

  SVGPathSegLinetoVerticalRel createSVGPathSegLinetoVerticalRel(num y) {
    return LevelDom.wrapSVGPathSegLinetoVerticalRel(_ptr.createSVGPathSegLinetoVerticalRel(y));
  }

  SVGPathSegMovetoAbs createSVGPathSegMovetoAbs(num x, num y) {
    return LevelDom.wrapSVGPathSegMovetoAbs(_ptr.createSVGPathSegMovetoAbs(x, y));
  }

  SVGPathSegMovetoRel createSVGPathSegMovetoRel(num x, num y) {
    return LevelDom.wrapSVGPathSegMovetoRel(_ptr.createSVGPathSegMovetoRel(x, y));
  }

  int getPathSegAtLength(num distance) {
    return _ptr.getPathSegAtLength(distance);
  }

  SVGPoint getPointAtLength(num distance) {
    return LevelDom.wrapSVGPoint(_ptr.getPointAtLength(distance));
  }

  num getTotalLength() {
    return _ptr.getTotalLength();
  }

  // From SVGTests

  SVGStringList get requiredExtensions() { return LevelDom.wrapSVGStringList(_ptr.requiredExtensions); }

  SVGStringList get requiredFeatures() { return LevelDom.wrapSVGStringList(_ptr.requiredFeatures); }

  SVGStringList get systemLanguage() { return LevelDom.wrapSVGStringList(_ptr.systemLanguage); }

  bool hasExtension(String extension) {
    return _ptr.hasExtension(extension);
  }

  // From SVGLangSpace

  String get xmllang() { return _ptr.xmllang; }

  void set xmllang(String value) { _ptr.xmllang = value; }

  String get xmlspace() { return _ptr.xmlspace; }

  void set xmlspace(String value) { _ptr.xmlspace = value; }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }

  // From SVGTransformable

  SVGAnimatedTransformList get transform() { return LevelDom.wrapSVGAnimatedTransformList(_ptr.transform); }

  // From SVGLocatable

  SVGElement get farthestViewportElement() { return LevelDom.wrapSVGElement(_ptr.farthestViewportElement); }

  SVGElement get nearestViewportElement() { return LevelDom.wrapSVGElement(_ptr.nearestViewportElement); }

  SVGRect getBBox() {
    return LevelDom.wrapSVGRect(_ptr.getBBox());
  }

  SVGMatrix getCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getCTM());
  }

  SVGMatrix getScreenCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getScreenCTM());
  }

  SVGMatrix getTransformToElement(SVGElement element) {
    return LevelDom.wrapSVGMatrix(_ptr.getTransformToElement(LevelDom.unwrap(element)));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPathSegArcAbsWrappingImplementation extends SVGPathSegWrappingImplementation implements SVGPathSegArcAbs {
  SVGPathSegArcAbsWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get angle() { return _ptr.angle; }

  void set angle(num value) { _ptr.angle = value; }

  bool get largeArcFlag() { return _ptr.largeArcFlag; }

  void set largeArcFlag(bool value) { _ptr.largeArcFlag = value; }

  num get r1() { return _ptr.r1; }

  void set r1(num value) { _ptr.r1 = value; }

  num get r2() { return _ptr.r2; }

  void set r2(num value) { _ptr.r2 = value; }

  bool get sweepFlag() { return _ptr.sweepFlag; }

  void set sweepFlag(bool value) { _ptr.sweepFlag = value; }

  num get x() { return _ptr.x; }

  void set x(num value) { _ptr.x = value; }

  num get y() { return _ptr.y; }

  void set y(num value) { _ptr.y = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPathSegArcRelWrappingImplementation extends SVGPathSegWrappingImplementation implements SVGPathSegArcRel {
  SVGPathSegArcRelWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get angle() { return _ptr.angle; }

  void set angle(num value) { _ptr.angle = value; }

  bool get largeArcFlag() { return _ptr.largeArcFlag; }

  void set largeArcFlag(bool value) { _ptr.largeArcFlag = value; }

  num get r1() { return _ptr.r1; }

  void set r1(num value) { _ptr.r1 = value; }

  num get r2() { return _ptr.r2; }

  void set r2(num value) { _ptr.r2 = value; }

  bool get sweepFlag() { return _ptr.sweepFlag; }

  void set sweepFlag(bool value) { _ptr.sweepFlag = value; }

  num get x() { return _ptr.x; }

  void set x(num value) { _ptr.x = value; }

  num get y() { return _ptr.y; }

  void set y(num value) { _ptr.y = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPathSegClosePathWrappingImplementation extends SVGPathSegWrappingImplementation implements SVGPathSegClosePath {
  SVGPathSegClosePathWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPathSegCurvetoCubicAbsWrappingImplementation extends SVGPathSegWrappingImplementation implements SVGPathSegCurvetoCubicAbs {
  SVGPathSegCurvetoCubicAbsWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get x() { return _ptr.x; }

  void set x(num value) { _ptr.x = value; }

  num get x1() { return _ptr.x1; }

  void set x1(num value) { _ptr.x1 = value; }

  num get x2() { return _ptr.x2; }

  void set x2(num value) { _ptr.x2 = value; }

  num get y() { return _ptr.y; }

  void set y(num value) { _ptr.y = value; }

  num get y1() { return _ptr.y1; }

  void set y1(num value) { _ptr.y1 = value; }

  num get y2() { return _ptr.y2; }

  void set y2(num value) { _ptr.y2 = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPathSegCurvetoCubicRelWrappingImplementation extends SVGPathSegWrappingImplementation implements SVGPathSegCurvetoCubicRel {
  SVGPathSegCurvetoCubicRelWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get x() { return _ptr.x; }

  void set x(num value) { _ptr.x = value; }

  num get x1() { return _ptr.x1; }

  void set x1(num value) { _ptr.x1 = value; }

  num get x2() { return _ptr.x2; }

  void set x2(num value) { _ptr.x2 = value; }

  num get y() { return _ptr.y; }

  void set y(num value) { _ptr.y = value; }

  num get y1() { return _ptr.y1; }

  void set y1(num value) { _ptr.y1 = value; }

  num get y2() { return _ptr.y2; }

  void set y2(num value) { _ptr.y2 = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPathSegCurvetoCubicSmoothAbsWrappingImplementation extends SVGPathSegWrappingImplementation implements SVGPathSegCurvetoCubicSmoothAbs {
  SVGPathSegCurvetoCubicSmoothAbsWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get x() { return _ptr.x; }

  void set x(num value) { _ptr.x = value; }

  num get x2() { return _ptr.x2; }

  void set x2(num value) { _ptr.x2 = value; }

  num get y() { return _ptr.y; }

  void set y(num value) { _ptr.y = value; }

  num get y2() { return _ptr.y2; }

  void set y2(num value) { _ptr.y2 = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPathSegCurvetoCubicSmoothRelWrappingImplementation extends SVGPathSegWrappingImplementation implements SVGPathSegCurvetoCubicSmoothRel {
  SVGPathSegCurvetoCubicSmoothRelWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get x() { return _ptr.x; }

  void set x(num value) { _ptr.x = value; }

  num get x2() { return _ptr.x2; }

  void set x2(num value) { _ptr.x2 = value; }

  num get y() { return _ptr.y; }

  void set y(num value) { _ptr.y = value; }

  num get y2() { return _ptr.y2; }

  void set y2(num value) { _ptr.y2 = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPathSegCurvetoQuadraticAbsWrappingImplementation extends SVGPathSegWrappingImplementation implements SVGPathSegCurvetoQuadraticAbs {
  SVGPathSegCurvetoQuadraticAbsWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get x() { return _ptr.x; }

  void set x(num value) { _ptr.x = value; }

  num get x1() { return _ptr.x1; }

  void set x1(num value) { _ptr.x1 = value; }

  num get y() { return _ptr.y; }

  void set y(num value) { _ptr.y = value; }

  num get y1() { return _ptr.y1; }

  void set y1(num value) { _ptr.y1 = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPathSegCurvetoQuadraticRelWrappingImplementation extends SVGPathSegWrappingImplementation implements SVGPathSegCurvetoQuadraticRel {
  SVGPathSegCurvetoQuadraticRelWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get x() { return _ptr.x; }

  void set x(num value) { _ptr.x = value; }

  num get x1() { return _ptr.x1; }

  void set x1(num value) { _ptr.x1 = value; }

  num get y() { return _ptr.y; }

  void set y(num value) { _ptr.y = value; }

  num get y1() { return _ptr.y1; }

  void set y1(num value) { _ptr.y1 = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPathSegCurvetoQuadraticSmoothAbsWrappingImplementation extends SVGPathSegWrappingImplementation implements SVGPathSegCurvetoQuadraticSmoothAbs {
  SVGPathSegCurvetoQuadraticSmoothAbsWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get x() { return _ptr.x; }

  void set x(num value) { _ptr.x = value; }

  num get y() { return _ptr.y; }

  void set y(num value) { _ptr.y = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPathSegCurvetoQuadraticSmoothRelWrappingImplementation extends SVGPathSegWrappingImplementation implements SVGPathSegCurvetoQuadraticSmoothRel {
  SVGPathSegCurvetoQuadraticSmoothRelWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get x() { return _ptr.x; }

  void set x(num value) { _ptr.x = value; }

  num get y() { return _ptr.y; }

  void set y(num value) { _ptr.y = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPathSegLinetoAbsWrappingImplementation extends SVGPathSegWrappingImplementation implements SVGPathSegLinetoAbs {
  SVGPathSegLinetoAbsWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get x() { return _ptr.x; }

  void set x(num value) { _ptr.x = value; }

  num get y() { return _ptr.y; }

  void set y(num value) { _ptr.y = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPathSegLinetoHorizontalAbsWrappingImplementation extends SVGPathSegWrappingImplementation implements SVGPathSegLinetoHorizontalAbs {
  SVGPathSegLinetoHorizontalAbsWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get x() { return _ptr.x; }

  void set x(num value) { _ptr.x = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPathSegLinetoHorizontalRelWrappingImplementation extends SVGPathSegWrappingImplementation implements SVGPathSegLinetoHorizontalRel {
  SVGPathSegLinetoHorizontalRelWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get x() { return _ptr.x; }

  void set x(num value) { _ptr.x = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPathSegLinetoRelWrappingImplementation extends SVGPathSegWrappingImplementation implements SVGPathSegLinetoRel {
  SVGPathSegLinetoRelWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get x() { return _ptr.x; }

  void set x(num value) { _ptr.x = value; }

  num get y() { return _ptr.y; }

  void set y(num value) { _ptr.y = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPathSegLinetoVerticalAbsWrappingImplementation extends SVGPathSegWrappingImplementation implements SVGPathSegLinetoVerticalAbs {
  SVGPathSegLinetoVerticalAbsWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get y() { return _ptr.y; }

  void set y(num value) { _ptr.y = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPathSegLinetoVerticalRelWrappingImplementation extends SVGPathSegWrappingImplementation implements SVGPathSegLinetoVerticalRel {
  SVGPathSegLinetoVerticalRelWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get y() { return _ptr.y; }

  void set y(num value) { _ptr.y = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPathSegListWrappingImplementation extends DOMWrapperBase implements SVGPathSegList {
  SVGPathSegListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get numberOfItems() { return _ptr.numberOfItems; }

  SVGPathSeg appendItem(SVGPathSeg newItem) {
    return LevelDom.wrapSVGPathSeg(_ptr.appendItem(LevelDom.unwrap(newItem)));
  }

  void clear() {
    _ptr.clear();
    return;
  }

  SVGPathSeg getItem(int index) {
    return LevelDom.wrapSVGPathSeg(_ptr.getItem(index));
  }

  SVGPathSeg initialize(SVGPathSeg newItem) {
    return LevelDom.wrapSVGPathSeg(_ptr.initialize(LevelDom.unwrap(newItem)));
  }

  SVGPathSeg insertItemBefore(SVGPathSeg newItem, int index) {
    return LevelDom.wrapSVGPathSeg(_ptr.insertItemBefore(LevelDom.unwrap(newItem), index));
  }

  SVGPathSeg removeItem(int index) {
    return LevelDom.wrapSVGPathSeg(_ptr.removeItem(index));
  }

  SVGPathSeg replaceItem(SVGPathSeg newItem, int index) {
    return LevelDom.wrapSVGPathSeg(_ptr.replaceItem(LevelDom.unwrap(newItem), index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPathSegMovetoAbsWrappingImplementation extends SVGPathSegWrappingImplementation implements SVGPathSegMovetoAbs {
  SVGPathSegMovetoAbsWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get x() { return _ptr.x; }

  void set x(num value) { _ptr.x = value; }

  num get y() { return _ptr.y; }

  void set y(num value) { _ptr.y = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPathSegMovetoRelWrappingImplementation extends SVGPathSegWrappingImplementation implements SVGPathSegMovetoRel {
  SVGPathSegMovetoRelWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get x() { return _ptr.x; }

  void set x(num value) { _ptr.x = value; }

  num get y() { return _ptr.y; }

  void set y(num value) { _ptr.y = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPathSegWrappingImplementation extends DOMWrapperBase implements SVGPathSeg {
  SVGPathSegWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get pathSegType() { return _ptr.pathSegType; }

  String get pathSegTypeAsLetter() { return _ptr.pathSegTypeAsLetter; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPatternElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGPatternElement {
  SVGPatternElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedLength get height() { return LevelDom.wrapSVGAnimatedLength(_ptr.height); }

  SVGAnimatedEnumeration get patternContentUnits() { return LevelDom.wrapSVGAnimatedEnumeration(_ptr.patternContentUnits); }

  SVGAnimatedTransformList get patternTransform() { return LevelDom.wrapSVGAnimatedTransformList(_ptr.patternTransform); }

  SVGAnimatedEnumeration get patternUnits() { return LevelDom.wrapSVGAnimatedEnumeration(_ptr.patternUnits); }

  SVGAnimatedLength get width() { return LevelDom.wrapSVGAnimatedLength(_ptr.width); }

  SVGAnimatedLength get x() { return LevelDom.wrapSVGAnimatedLength(_ptr.x); }

  SVGAnimatedLength get y() { return LevelDom.wrapSVGAnimatedLength(_ptr.y); }

  // From SVGURIReference

  SVGAnimatedString get href() { return LevelDom.wrapSVGAnimatedString(_ptr.href); }

  // From SVGTests

  SVGStringList get requiredExtensions() { return LevelDom.wrapSVGStringList(_ptr.requiredExtensions); }

  SVGStringList get requiredFeatures() { return LevelDom.wrapSVGStringList(_ptr.requiredFeatures); }

  SVGStringList get systemLanguage() { return LevelDom.wrapSVGStringList(_ptr.systemLanguage); }

  bool hasExtension(String extension) {
    return _ptr.hasExtension(extension);
  }

  // From SVGLangSpace

  String get xmllang() { return _ptr.xmllang; }

  void set xmllang(String value) { _ptr.xmllang = value; }

  String get xmlspace() { return _ptr.xmlspace; }

  void set xmlspace(String value) { _ptr.xmlspace = value; }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() { return LevelDom.wrapSVGAnimatedPreserveAspectRatio(_ptr.preserveAspectRatio); }

  SVGAnimatedRect get viewBox() { return LevelDom.wrapSVGAnimatedRect(_ptr.viewBox); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPointListWrappingImplementation extends DOMWrapperBase implements SVGPointList {
  SVGPointListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get numberOfItems() { return _ptr.numberOfItems; }

  SVGPoint appendItem(SVGPoint item) {
    return LevelDom.wrapSVGPoint(_ptr.appendItem(LevelDom.unwrap(item)));
  }

  void clear() {
    _ptr.clear();
    return;
  }

  SVGPoint getItem(int index) {
    return LevelDom.wrapSVGPoint(_ptr.getItem(index));
  }

  SVGPoint initialize(SVGPoint item) {
    return LevelDom.wrapSVGPoint(_ptr.initialize(LevelDom.unwrap(item)));
  }

  SVGPoint insertItemBefore(SVGPoint item, int index) {
    return LevelDom.wrapSVGPoint(_ptr.insertItemBefore(LevelDom.unwrap(item), index));
  }

  SVGPoint removeItem(int index) {
    return LevelDom.wrapSVGPoint(_ptr.removeItem(index));
  }

  SVGPoint replaceItem(SVGPoint item, int index) {
    return LevelDom.wrapSVGPoint(_ptr.replaceItem(LevelDom.unwrap(item), index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPointWrappingImplementation extends DOMWrapperBase implements SVGPoint {
  SVGPointWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get x() { return _ptr.x; }

  void set x(num value) { _ptr.x = value; }

  num get y() { return _ptr.y; }

  void set y(num value) { _ptr.y = value; }

  SVGPoint matrixTransform(SVGMatrix matrix) {
    return LevelDom.wrapSVGPoint(_ptr.matrixTransform(LevelDom.unwrap(matrix)));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPolygonElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGPolygonElement {
  SVGPolygonElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGPointList get animatedPoints() { return LevelDom.wrapSVGPointList(_ptr.animatedPoints); }

  SVGPointList get points() { return LevelDom.wrapSVGPointList(_ptr.points); }

  // From SVGTests

  SVGStringList get requiredExtensions() { return LevelDom.wrapSVGStringList(_ptr.requiredExtensions); }

  SVGStringList get requiredFeatures() { return LevelDom.wrapSVGStringList(_ptr.requiredFeatures); }

  SVGStringList get systemLanguage() { return LevelDom.wrapSVGStringList(_ptr.systemLanguage); }

  bool hasExtension(String extension) {
    return _ptr.hasExtension(extension);
  }

  // From SVGLangSpace

  String get xmllang() { return _ptr.xmllang; }

  void set xmllang(String value) { _ptr.xmllang = value; }

  String get xmlspace() { return _ptr.xmlspace; }

  void set xmlspace(String value) { _ptr.xmlspace = value; }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }

  // From SVGTransformable

  SVGAnimatedTransformList get transform() { return LevelDom.wrapSVGAnimatedTransformList(_ptr.transform); }

  // From SVGLocatable

  SVGElement get farthestViewportElement() { return LevelDom.wrapSVGElement(_ptr.farthestViewportElement); }

  SVGElement get nearestViewportElement() { return LevelDom.wrapSVGElement(_ptr.nearestViewportElement); }

  SVGRect getBBox() {
    return LevelDom.wrapSVGRect(_ptr.getBBox());
  }

  SVGMatrix getCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getCTM());
  }

  SVGMatrix getScreenCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getScreenCTM());
  }

  SVGMatrix getTransformToElement(SVGElement element) {
    return LevelDom.wrapSVGMatrix(_ptr.getTransformToElement(LevelDom.unwrap(element)));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPolylineElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGPolylineElement {
  SVGPolylineElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGPointList get animatedPoints() { return LevelDom.wrapSVGPointList(_ptr.animatedPoints); }

  SVGPointList get points() { return LevelDom.wrapSVGPointList(_ptr.points); }

  // From SVGTests

  SVGStringList get requiredExtensions() { return LevelDom.wrapSVGStringList(_ptr.requiredExtensions); }

  SVGStringList get requiredFeatures() { return LevelDom.wrapSVGStringList(_ptr.requiredFeatures); }

  SVGStringList get systemLanguage() { return LevelDom.wrapSVGStringList(_ptr.systemLanguage); }

  bool hasExtension(String extension) {
    return _ptr.hasExtension(extension);
  }

  // From SVGLangSpace

  String get xmllang() { return _ptr.xmllang; }

  void set xmllang(String value) { _ptr.xmllang = value; }

  String get xmlspace() { return _ptr.xmlspace; }

  void set xmlspace(String value) { _ptr.xmlspace = value; }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }

  // From SVGTransformable

  SVGAnimatedTransformList get transform() { return LevelDom.wrapSVGAnimatedTransformList(_ptr.transform); }

  // From SVGLocatable

  SVGElement get farthestViewportElement() { return LevelDom.wrapSVGElement(_ptr.farthestViewportElement); }

  SVGElement get nearestViewportElement() { return LevelDom.wrapSVGElement(_ptr.nearestViewportElement); }

  SVGRect getBBox() {
    return LevelDom.wrapSVGRect(_ptr.getBBox());
  }

  SVGMatrix getCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getCTM());
  }

  SVGMatrix getScreenCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getScreenCTM());
  }

  SVGMatrix getTransformToElement(SVGElement element) {
    return LevelDom.wrapSVGMatrix(_ptr.getTransformToElement(LevelDom.unwrap(element)));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGPreserveAspectRatioWrappingImplementation extends DOMWrapperBase implements SVGPreserveAspectRatio {
  SVGPreserveAspectRatioWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get align() { return _ptr.align; }

  void set align(int value) { _ptr.align = value; }

  int get meetOrSlice() { return _ptr.meetOrSlice; }

  void set meetOrSlice(int value) { _ptr.meetOrSlice = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGRadialGradientElementWrappingImplementation extends SVGGradientElementWrappingImplementation implements SVGRadialGradientElement {
  SVGRadialGradientElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedLength get cx() { return LevelDom.wrapSVGAnimatedLength(_ptr.cx); }

  SVGAnimatedLength get cy() { return LevelDom.wrapSVGAnimatedLength(_ptr.cy); }

  SVGAnimatedLength get fx() { return LevelDom.wrapSVGAnimatedLength(_ptr.fx); }

  SVGAnimatedLength get fy() { return LevelDom.wrapSVGAnimatedLength(_ptr.fy); }

  SVGAnimatedLength get r() { return LevelDom.wrapSVGAnimatedLength(_ptr.r); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGRectElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGRectElement {
  SVGRectElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedLength get height() { return LevelDom.wrapSVGAnimatedLength(_ptr.height); }

  SVGAnimatedLength get rx() { return LevelDom.wrapSVGAnimatedLength(_ptr.rx); }

  SVGAnimatedLength get ry() { return LevelDom.wrapSVGAnimatedLength(_ptr.ry); }

  SVGAnimatedLength get width() { return LevelDom.wrapSVGAnimatedLength(_ptr.width); }

  SVGAnimatedLength get x() { return LevelDom.wrapSVGAnimatedLength(_ptr.x); }

  SVGAnimatedLength get y() { return LevelDom.wrapSVGAnimatedLength(_ptr.y); }

  // From SVGTests

  SVGStringList get requiredExtensions() { return LevelDom.wrapSVGStringList(_ptr.requiredExtensions); }

  SVGStringList get requiredFeatures() { return LevelDom.wrapSVGStringList(_ptr.requiredFeatures); }

  SVGStringList get systemLanguage() { return LevelDom.wrapSVGStringList(_ptr.systemLanguage); }

  bool hasExtension(String extension) {
    return _ptr.hasExtension(extension);
  }

  // From SVGLangSpace

  String get xmllang() { return _ptr.xmllang; }

  void set xmllang(String value) { _ptr.xmllang = value; }

  String get xmlspace() { return _ptr.xmlspace; }

  void set xmlspace(String value) { _ptr.xmlspace = value; }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }

  // From SVGTransformable

  SVGAnimatedTransformList get transform() { return LevelDom.wrapSVGAnimatedTransformList(_ptr.transform); }

  // From SVGLocatable

  SVGElement get farthestViewportElement() { return LevelDom.wrapSVGElement(_ptr.farthestViewportElement); }

  SVGElement get nearestViewportElement() { return LevelDom.wrapSVGElement(_ptr.nearestViewportElement); }

  SVGRect getBBox() {
    return LevelDom.wrapSVGRect(_ptr.getBBox());
  }

  SVGMatrix getCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getCTM());
  }

  SVGMatrix getScreenCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getScreenCTM());
  }

  SVGMatrix getTransformToElement(SVGElement element) {
    return LevelDom.wrapSVGMatrix(_ptr.getTransformToElement(LevelDom.unwrap(element)));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGRectWrappingImplementation extends DOMWrapperBase implements SVGRect {
  SVGRectWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get height() { return _ptr.height; }

  void set height(num value) { _ptr.height = value; }

  num get width() { return _ptr.width; }

  void set width(num value) { _ptr.width = value; }

  num get x() { return _ptr.x; }

  void set x(num value) { _ptr.x = value; }

  num get y() { return _ptr.y; }

  void set y(num value) { _ptr.y = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGRenderingIntentWrappingImplementation extends DOMWrapperBase implements SVGRenderingIntent {
  SVGRenderingIntentWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGSVGElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGSVGElement {
  SVGSVGElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get contentScriptType() { return _ptr.contentScriptType; }

  void set contentScriptType(String value) { _ptr.contentScriptType = value; }

  String get contentStyleType() { return _ptr.contentStyleType; }

  void set contentStyleType(String value) { _ptr.contentStyleType = value; }

  num get currentScale() { return _ptr.currentScale; }

  void set currentScale(num value) { _ptr.currentScale = value; }

  SVGPoint get currentTranslate() { return LevelDom.wrapSVGPoint(_ptr.currentTranslate); }

  SVGAnimatedLength get height() { return LevelDom.wrapSVGAnimatedLength(_ptr.height); }

  num get pixelUnitToMillimeterX() { return _ptr.pixelUnitToMillimeterX; }

  num get pixelUnitToMillimeterY() { return _ptr.pixelUnitToMillimeterY; }

  num get screenPixelToMillimeterX() { return _ptr.screenPixelToMillimeterX; }

  num get screenPixelToMillimeterY() { return _ptr.screenPixelToMillimeterY; }

  bool get useCurrentView() { return _ptr.useCurrentView; }

  void set useCurrentView(bool value) { _ptr.useCurrentView = value; }

  SVGRect get viewport() { return LevelDom.wrapSVGRect(_ptr.viewport); }

  SVGAnimatedLength get width() { return LevelDom.wrapSVGAnimatedLength(_ptr.width); }

  SVGAnimatedLength get x() { return LevelDom.wrapSVGAnimatedLength(_ptr.x); }

  SVGAnimatedLength get y() { return LevelDom.wrapSVGAnimatedLength(_ptr.y); }

  bool animationsPaused() {
    return _ptr.animationsPaused();
  }

  bool checkEnclosure(SVGElement element, SVGRect rect) {
    return _ptr.checkEnclosure(LevelDom.unwrap(element), LevelDom.unwrap(rect));
  }

  bool checkIntersection(SVGElement element, SVGRect rect) {
    return _ptr.checkIntersection(LevelDom.unwrap(element), LevelDom.unwrap(rect));
  }

  SVGAngle createSVGAngle() {
    return LevelDom.wrapSVGAngle(_ptr.createSVGAngle());
  }

  SVGLength createSVGLength() {
    return LevelDom.wrapSVGLength(_ptr.createSVGLength());
  }

  SVGMatrix createSVGMatrix() {
    return LevelDom.wrapSVGMatrix(_ptr.createSVGMatrix());
  }

  SVGNumber createSVGNumber() {
    return LevelDom.wrapSVGNumber(_ptr.createSVGNumber());
  }

  SVGPoint createSVGPoint() {
    return LevelDom.wrapSVGPoint(_ptr.createSVGPoint());
  }

  SVGRect createSVGRect() {
    return LevelDom.wrapSVGRect(_ptr.createSVGRect());
  }

  SVGTransform createSVGTransform() {
    return LevelDom.wrapSVGTransform(_ptr.createSVGTransform());
  }

  SVGTransform createSVGTransformFromMatrix(SVGMatrix matrix) {
    return LevelDom.wrapSVGTransform(_ptr.createSVGTransformFromMatrix(LevelDom.unwrap(matrix)));
  }

  void deselectAll() {
    _ptr.deselectAll();
    return;
  }

  void forceRedraw() {
    _ptr.forceRedraw();
    return;
  }

  num getCurrentTime() {
    return _ptr.getCurrentTime();
  }

  Element getElementById(String elementId) {
    return LevelDom.wrapElement(_ptr.getElementById(elementId));
  }

  ElementList getEnclosureList(SVGRect rect, SVGElement referenceElement) {
    return LevelDom.wrapElementList(_ptr.getEnclosureList(LevelDom.unwrap(rect), LevelDom.unwrap(referenceElement)));
  }

  ElementList getIntersectionList(SVGRect rect, SVGElement referenceElement) {
    return LevelDom.wrapElementList(_ptr.getIntersectionList(LevelDom.unwrap(rect), LevelDom.unwrap(referenceElement)));
  }

  void pauseAnimations() {
    _ptr.pauseAnimations();
    return;
  }

  void setCurrentTime(num seconds) {
    _ptr.setCurrentTime(seconds);
    return;
  }

  int suspendRedraw(int maxWaitMilliseconds) {
    return _ptr.suspendRedraw(maxWaitMilliseconds);
  }

  void unpauseAnimations() {
    _ptr.unpauseAnimations();
    return;
  }

  void unsuspendRedraw(int suspendHandleId) {
    _ptr.unsuspendRedraw(suspendHandleId);
    return;
  }

  void unsuspendRedrawAll() {
    _ptr.unsuspendRedrawAll();
    return;
  }

  // From SVGTests

  SVGStringList get requiredExtensions() { return LevelDom.wrapSVGStringList(_ptr.requiredExtensions); }

  SVGStringList get requiredFeatures() { return LevelDom.wrapSVGStringList(_ptr.requiredFeatures); }

  SVGStringList get systemLanguage() { return LevelDom.wrapSVGStringList(_ptr.systemLanguage); }

  bool hasExtension(String extension) {
    return _ptr.hasExtension(extension);
  }

  // From SVGLangSpace

  String get xmllang() { return _ptr.xmllang; }

  void set xmllang(String value) { _ptr.xmllang = value; }

  String get xmlspace() { return _ptr.xmlspace; }

  void set xmlspace(String value) { _ptr.xmlspace = value; }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }

  // From SVGLocatable

  SVGElement get farthestViewportElement() { return LevelDom.wrapSVGElement(_ptr.farthestViewportElement); }

  SVGElement get nearestViewportElement() { return LevelDom.wrapSVGElement(_ptr.nearestViewportElement); }

  SVGRect getBBox() {
    return LevelDom.wrapSVGRect(_ptr.getBBox());
  }

  SVGMatrix getCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getCTM());
  }

  SVGMatrix getScreenCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getScreenCTM());
  }

  SVGMatrix getTransformToElement(SVGElement element) {
    return LevelDom.wrapSVGMatrix(_ptr.getTransformToElement(LevelDom.unwrap(element)));
  }

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() { return LevelDom.wrapSVGAnimatedPreserveAspectRatio(_ptr.preserveAspectRatio); }

  SVGAnimatedRect get viewBox() { return LevelDom.wrapSVGAnimatedRect(_ptr.viewBox); }

  // From SVGZoomAndPan

  int get zoomAndPan() { return _ptr.zoomAndPan; }

  void set zoomAndPan(int value) { _ptr.zoomAndPan = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGScriptElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGScriptElement {
  SVGScriptElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get type() { return _ptr.type; }

  void set type(String value) { _ptr.type = value; }

  // From SVGURIReference

  SVGAnimatedString get href() { return LevelDom.wrapSVGAnimatedString(_ptr.href); }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGSetElementWrappingImplementation extends SVGAnimationElementWrappingImplementation implements SVGSetElement {
  SVGSetElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGStopElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGStopElement {
  SVGStopElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedNumber get offset() { return LevelDom.wrapSVGAnimatedNumber(_ptr.offset); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGStringListWrappingImplementation extends DOMWrapperBase implements SVGStringList {
  SVGStringListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get numberOfItems() { return _ptr.numberOfItems; }

  String appendItem(String item) {
    return _ptr.appendItem(item);
  }

  void clear() {
    _ptr.clear();
    return;
  }

  String getItem(int index) {
    return _ptr.getItem(index);
  }

  String initialize(String item) {
    return _ptr.initialize(item);
  }

  String insertItemBefore(String item, int index) {
    return _ptr.insertItemBefore(item, index);
  }

  String removeItem(int index) {
    return _ptr.removeItem(index);
  }

  String replaceItem(String item, int index) {
    return _ptr.replaceItem(item, index);
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGStylableWrappingImplementation extends DOMWrapperBase implements SVGStylable {
  SVGStylableWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGStyleElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGStyleElement {
  SVGStyleElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get media() { return _ptr.media; }

  void set media(String value) { _ptr.media = value; }

  String get title() { return _ptr.title; }

  void set title(String value) { _ptr.title = value; }

  String get type() { return _ptr.type; }

  void set type(String value) { _ptr.type = value; }

  // From SVGLangSpace

  String get xmllang() { return _ptr.xmllang; }

  void set xmllang(String value) { _ptr.xmllang = value; }

  String get xmlspace() { return _ptr.xmlspace; }

  void set xmlspace(String value) { _ptr.xmlspace = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGSwitchElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGSwitchElement {
  SVGSwitchElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  // From SVGTests

  SVGStringList get requiredExtensions() { return LevelDom.wrapSVGStringList(_ptr.requiredExtensions); }

  SVGStringList get requiredFeatures() { return LevelDom.wrapSVGStringList(_ptr.requiredFeatures); }

  SVGStringList get systemLanguage() { return LevelDom.wrapSVGStringList(_ptr.systemLanguage); }

  bool hasExtension(String extension) {
    return _ptr.hasExtension(extension);
  }

  // From SVGLangSpace

  String get xmllang() { return _ptr.xmllang; }

  void set xmllang(String value) { _ptr.xmllang = value; }

  String get xmlspace() { return _ptr.xmlspace; }

  void set xmlspace(String value) { _ptr.xmlspace = value; }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }

  // From SVGTransformable

  SVGAnimatedTransformList get transform() { return LevelDom.wrapSVGAnimatedTransformList(_ptr.transform); }

  // From SVGLocatable

  SVGElement get farthestViewportElement() { return LevelDom.wrapSVGElement(_ptr.farthestViewportElement); }

  SVGElement get nearestViewportElement() { return LevelDom.wrapSVGElement(_ptr.nearestViewportElement); }

  SVGRect getBBox() {
    return LevelDom.wrapSVGRect(_ptr.getBBox());
  }

  SVGMatrix getCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getCTM());
  }

  SVGMatrix getScreenCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getScreenCTM());
  }

  SVGMatrix getTransformToElement(SVGElement element) {
    return LevelDom.wrapSVGMatrix(_ptr.getTransformToElement(LevelDom.unwrap(element)));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGSymbolElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGSymbolElement {
  SVGSymbolElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  // From SVGLangSpace

  String get xmllang() { return _ptr.xmllang; }

  void set xmllang(String value) { _ptr.xmllang = value; }

  String get xmlspace() { return _ptr.xmlspace; }

  void set xmlspace(String value) { _ptr.xmlspace = value; }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() { return LevelDom.wrapSVGAnimatedPreserveAspectRatio(_ptr.preserveAspectRatio); }

  SVGAnimatedRect get viewBox() { return LevelDom.wrapSVGAnimatedRect(_ptr.viewBox); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGTRefElementWrappingImplementation extends SVGTextPositioningElementWrappingImplementation implements SVGTRefElement {
  SVGTRefElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  // From SVGURIReference

  SVGAnimatedString get href() { return LevelDom.wrapSVGAnimatedString(_ptr.href); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGTSpanElementWrappingImplementation extends SVGTextPositioningElementWrappingImplementation implements SVGTSpanElement {
  SVGTSpanElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGTestsWrappingImplementation extends DOMWrapperBase implements SVGTests {
  SVGTestsWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGStringList get requiredExtensions() { return LevelDom.wrapSVGStringList(_ptr.requiredExtensions); }

  SVGStringList get requiredFeatures() { return LevelDom.wrapSVGStringList(_ptr.requiredFeatures); }

  SVGStringList get systemLanguage() { return LevelDom.wrapSVGStringList(_ptr.systemLanguage); }

  bool hasExtension(String extension) {
    return _ptr.hasExtension(extension);
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGTextContentElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGTextContentElement {
  SVGTextContentElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedEnumeration get lengthAdjust() { return LevelDom.wrapSVGAnimatedEnumeration(_ptr.lengthAdjust); }

  SVGAnimatedLength get textLength() { return LevelDom.wrapSVGAnimatedLength(_ptr.textLength); }

  int getCharNumAtPosition(SVGPoint point) {
    return _ptr.getCharNumAtPosition(LevelDom.unwrap(point));
  }

  num getComputedTextLength() {
    return _ptr.getComputedTextLength();
  }

  SVGPoint getEndPositionOfChar(int offset) {
    return LevelDom.wrapSVGPoint(_ptr.getEndPositionOfChar(offset));
  }

  SVGRect getExtentOfChar(int offset) {
    return LevelDom.wrapSVGRect(_ptr.getExtentOfChar(offset));
  }

  int getNumberOfChars() {
    return _ptr.getNumberOfChars();
  }

  num getRotationOfChar(int offset) {
    return _ptr.getRotationOfChar(offset);
  }

  SVGPoint getStartPositionOfChar(int offset) {
    return LevelDom.wrapSVGPoint(_ptr.getStartPositionOfChar(offset));
  }

  num getSubStringLength(int offset, int length) {
    return _ptr.getSubStringLength(offset, length);
  }

  void selectSubString(int offset, int length) {
    _ptr.selectSubString(offset, length);
    return;
  }

  // From SVGTests

  SVGStringList get requiredExtensions() { return LevelDom.wrapSVGStringList(_ptr.requiredExtensions); }

  SVGStringList get requiredFeatures() { return LevelDom.wrapSVGStringList(_ptr.requiredFeatures); }

  SVGStringList get systemLanguage() { return LevelDom.wrapSVGStringList(_ptr.systemLanguage); }

  bool hasExtension(String extension) {
    return _ptr.hasExtension(extension);
  }

  // From SVGLangSpace

  String get xmllang() { return _ptr.xmllang; }

  void set xmllang(String value) { _ptr.xmllang = value; }

  String get xmlspace() { return _ptr.xmlspace; }

  void set xmlspace(String value) { _ptr.xmlspace = value; }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGTextElementWrappingImplementation extends SVGTextPositioningElementWrappingImplementation implements SVGTextElement {
  SVGTextElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  // From SVGTransformable

  SVGAnimatedTransformList get transform() { return LevelDom.wrapSVGAnimatedTransformList(_ptr.transform); }

  // From SVGLocatable

  SVGElement get farthestViewportElement() { return LevelDom.wrapSVGElement(_ptr.farthestViewportElement); }

  SVGElement get nearestViewportElement() { return LevelDom.wrapSVGElement(_ptr.nearestViewportElement); }

  SVGRect getBBox() {
    return LevelDom.wrapSVGRect(_ptr.getBBox());
  }

  SVGMatrix getCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getCTM());
  }

  SVGMatrix getScreenCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getScreenCTM());
  }

  SVGMatrix getTransformToElement(SVGElement element) {
    return LevelDom.wrapSVGMatrix(_ptr.getTransformToElement(LevelDom.unwrap(element)));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGTextPathElementWrappingImplementation extends SVGTextContentElementWrappingImplementation implements SVGTextPathElement {
  SVGTextPathElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedEnumeration get method() { return LevelDom.wrapSVGAnimatedEnumeration(_ptr.method); }

  SVGAnimatedEnumeration get spacing() { return LevelDom.wrapSVGAnimatedEnumeration(_ptr.spacing); }

  SVGAnimatedLength get startOffset() { return LevelDom.wrapSVGAnimatedLength(_ptr.startOffset); }

  // From SVGURIReference

  SVGAnimatedString get href() { return LevelDom.wrapSVGAnimatedString(_ptr.href); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGTextPositioningElementWrappingImplementation extends SVGTextContentElementWrappingImplementation implements SVGTextPositioningElement {
  SVGTextPositioningElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedLengthList get dx() { return LevelDom.wrapSVGAnimatedLengthList(_ptr.dx); }

  SVGAnimatedLengthList get dy() { return LevelDom.wrapSVGAnimatedLengthList(_ptr.dy); }

  SVGAnimatedNumberList get rotate() { return LevelDom.wrapSVGAnimatedNumberList(_ptr.rotate); }

  SVGAnimatedLengthList get x() { return LevelDom.wrapSVGAnimatedLengthList(_ptr.x); }

  SVGAnimatedLengthList get y() { return LevelDom.wrapSVGAnimatedLengthList(_ptr.y); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGTitleElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGTitleElement {
  SVGTitleElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  // From SVGLangSpace

  String get xmllang() { return _ptr.xmllang; }

  void set xmllang(String value) { _ptr.xmllang = value; }

  String get xmlspace() { return _ptr.xmlspace; }

  void set xmlspace(String value) { _ptr.xmlspace = value; }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGTransformListWrappingImplementation extends DOMWrapperBase implements SVGTransformList {
  SVGTransformListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get numberOfItems() { return _ptr.numberOfItems; }

  SVGTransform appendItem(SVGTransform item) {
    return LevelDom.wrapSVGTransform(_ptr.appendItem(LevelDom.unwrap(item)));
  }

  void clear() {
    _ptr.clear();
    return;
  }

  SVGTransform consolidate() {
    return LevelDom.wrapSVGTransform(_ptr.consolidate());
  }

  SVGTransform createSVGTransformFromMatrix(SVGMatrix matrix) {
    return LevelDom.wrapSVGTransform(_ptr.createSVGTransformFromMatrix(LevelDom.unwrap(matrix)));
  }

  SVGTransform getItem(int index) {
    return LevelDom.wrapSVGTransform(_ptr.getItem(index));
  }

  SVGTransform initialize(SVGTransform item) {
    return LevelDom.wrapSVGTransform(_ptr.initialize(LevelDom.unwrap(item)));
  }

  SVGTransform insertItemBefore(SVGTransform item, int index) {
    return LevelDom.wrapSVGTransform(_ptr.insertItemBefore(LevelDom.unwrap(item), index));
  }

  SVGTransform removeItem(int index) {
    return LevelDom.wrapSVGTransform(_ptr.removeItem(index));
  }

  SVGTransform replaceItem(SVGTransform item, int index) {
    return LevelDom.wrapSVGTransform(_ptr.replaceItem(LevelDom.unwrap(item), index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGTransformWrappingImplementation extends DOMWrapperBase implements SVGTransform {
  SVGTransformWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get angle() { return _ptr.angle; }

  SVGMatrix get matrix() { return LevelDom.wrapSVGMatrix(_ptr.matrix); }

  int get type() { return _ptr.type; }

  void setMatrix(SVGMatrix matrix) {
    _ptr.setMatrix(LevelDom.unwrap(matrix));
    return;
  }

  void setRotate(num angle, num cx, num cy) {
    _ptr.setRotate(angle, cx, cy);
    return;
  }

  void setScale(num sx, num sy) {
    _ptr.setScale(sx, sy);
    return;
  }

  void setSkewX(num angle) {
    _ptr.setSkewX(angle);
    return;
  }

  void setSkewY(num angle) {
    _ptr.setSkewY(angle);
    return;
  }

  void setTranslate(num tx, num ty) {
    _ptr.setTranslate(tx, ty);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGTransformableWrappingImplementation extends SVGLocatableWrappingImplementation implements SVGTransformable {
  SVGTransformableWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedTransformList get transform() { return LevelDom.wrapSVGAnimatedTransformList(_ptr.transform); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGURIReferenceWrappingImplementation extends DOMWrapperBase implements SVGURIReference {
  SVGURIReferenceWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGAnimatedString get href() { return LevelDom.wrapSVGAnimatedString(_ptr.href); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGUnitTypesWrappingImplementation extends DOMWrapperBase implements SVGUnitTypes {
  SVGUnitTypesWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGUseElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGUseElement {
  SVGUseElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGElementInstance get animatedInstanceRoot() { return LevelDom.wrapSVGElementInstance(_ptr.animatedInstanceRoot); }

  SVGAnimatedLength get height() { return LevelDom.wrapSVGAnimatedLength(_ptr.height); }

  SVGElementInstance get instanceRoot() { return LevelDom.wrapSVGElementInstance(_ptr.instanceRoot); }

  SVGAnimatedLength get width() { return LevelDom.wrapSVGAnimatedLength(_ptr.width); }

  SVGAnimatedLength get x() { return LevelDom.wrapSVGAnimatedLength(_ptr.x); }

  SVGAnimatedLength get y() { return LevelDom.wrapSVGAnimatedLength(_ptr.y); }

  // From SVGURIReference

  SVGAnimatedString get href() { return LevelDom.wrapSVGAnimatedString(_ptr.href); }

  // From SVGTests

  SVGStringList get requiredExtensions() { return LevelDom.wrapSVGStringList(_ptr.requiredExtensions); }

  SVGStringList get requiredFeatures() { return LevelDom.wrapSVGStringList(_ptr.requiredFeatures); }

  SVGStringList get systemLanguage() { return LevelDom.wrapSVGStringList(_ptr.systemLanguage); }

  bool hasExtension(String extension) {
    return _ptr.hasExtension(extension);
  }

  // From SVGLangSpace

  String get xmllang() { return _ptr.xmllang; }

  void set xmllang(String value) { _ptr.xmllang = value; }

  String get xmlspace() { return _ptr.xmlspace; }

  void set xmlspace(String value) { _ptr.xmlspace = value; }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }

  // From SVGStylable

  SVGAnimatedString get className() { return LevelDom.wrapSVGAnimatedString(_ptr.className); }

  CSSStyleDeclaration get style() { return LevelDom.wrapCSSStyleDeclaration(_ptr.style); }

  CSSValue getPresentationAttribute(String name) {
    return LevelDom.wrapCSSValue(_ptr.getPresentationAttribute(name));
  }

  // From SVGTransformable

  SVGAnimatedTransformList get transform() { return LevelDom.wrapSVGAnimatedTransformList(_ptr.transform); }

  // From SVGLocatable

  SVGElement get farthestViewportElement() { return LevelDom.wrapSVGElement(_ptr.farthestViewportElement); }

  SVGElement get nearestViewportElement() { return LevelDom.wrapSVGElement(_ptr.nearestViewportElement); }

  SVGRect getBBox() {
    return LevelDom.wrapSVGRect(_ptr.getBBox());
  }

  SVGMatrix getCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getCTM());
  }

  SVGMatrix getScreenCTM() {
    return LevelDom.wrapSVGMatrix(_ptr.getScreenCTM());
  }

  SVGMatrix getTransformToElement(SVGElement element) {
    return LevelDom.wrapSVGMatrix(_ptr.getTransformToElement(LevelDom.unwrap(element)));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGVKernElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGVKernElement {
  SVGVKernElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGViewElementWrappingImplementation extends SVGElementWrappingImplementation implements SVGViewElement {
  SVGViewElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGStringList get viewTarget() { return LevelDom.wrapSVGStringList(_ptr.viewTarget); }

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return LevelDom.wrapSVGAnimatedBoolean(_ptr.externalResourcesRequired); }

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() { return LevelDom.wrapSVGAnimatedPreserveAspectRatio(_ptr.preserveAspectRatio); }

  SVGAnimatedRect get viewBox() { return LevelDom.wrapSVGAnimatedRect(_ptr.viewBox); }

  // From SVGZoomAndPan

  int get zoomAndPan() { return _ptr.zoomAndPan; }

  void set zoomAndPan(int value) { _ptr.zoomAndPan = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGViewSpecWrappingImplementation extends SVGZoomAndPanWrappingImplementation implements SVGViewSpec {
  SVGViewSpecWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get preserveAspectRatioString() { return _ptr.preserveAspectRatioString; }

  SVGTransformList get transform() { return LevelDom.wrapSVGTransformList(_ptr.transform); }

  String get transformString() { return _ptr.transformString; }

  String get viewBoxString() { return _ptr.viewBoxString; }

  SVGElement get viewTarget() { return LevelDom.wrapSVGElement(_ptr.viewTarget); }

  String get viewTargetString() { return _ptr.viewTargetString; }

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() { return LevelDom.wrapSVGAnimatedPreserveAspectRatio(_ptr.preserveAspectRatio); }

  SVGAnimatedRect get viewBox() { return LevelDom.wrapSVGAnimatedRect(_ptr.viewBox); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGZoomAndPanWrappingImplementation extends DOMWrapperBase implements SVGZoomAndPan {
  SVGZoomAndPanWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get zoomAndPan() { return _ptr.zoomAndPan; }

  void set zoomAndPan(int value) { _ptr.zoomAndPan = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGZoomEventWrappingImplementation extends UIEventWrappingImplementation implements SVGZoomEvent {
  SVGZoomEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get newScale() { return _ptr.newScale; }

  SVGPoint get newTranslate() { return LevelDom.wrapSVGPoint(_ptr.newTranslate); }

  num get previousScale() { return _ptr.previousScale; }

  SVGPoint get previousTranslate() { return LevelDom.wrapSVGPoint(_ptr.previousTranslate); }

  SVGRect get zoomRectScreen() { return LevelDom.wrapSVGRect(_ptr.zoomRectScreen); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ScreenWrappingImplementation extends DOMWrapperBase implements Screen {
  ScreenWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get availHeight() { return _ptr.availHeight; }

  int get availLeft() { return _ptr.availLeft; }

  int get availTop() { return _ptr.availTop; }

  int get availWidth() { return _ptr.availWidth; }

  int get colorDepth() { return _ptr.colorDepth; }

  int get height() { return _ptr.height; }

  int get pixelDepth() { return _ptr.pixelDepth; }

  int get width() { return _ptr.width; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ScriptElementWrappingImplementation extends ElementWrappingImplementation implements ScriptElement {
  ScriptElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get async() { return _ptr.async; }

  void set async(bool value) { _ptr.async = value; }

  String get charset() { return _ptr.charset; }

  void set charset(String value) { _ptr.charset = value; }

  bool get defer() { return _ptr.defer; }

  void set defer(bool value) { _ptr.defer = value; }

  String get event() { return _ptr.event; }

  void set event(String value) { _ptr.event = value; }

  String get htmlFor() { return _ptr.htmlFor; }

  void set htmlFor(String value) { _ptr.htmlFor = value; }

  String get src() { return _ptr.src; }

  void set src(String value) { _ptr.src = value; }

  String get text() { return _ptr.text; }

  void set text(String value) { _ptr.text = value; }

  String get type() { return _ptr.type; }

  void set type(String value) { _ptr.type = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SelectElementWrappingImplementation extends ElementWrappingImplementation implements SelectElement {
  SelectElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get autofocus() { return _ptr.autofocus; }

  void set autofocus(bool value) { _ptr.autofocus = value; }

  bool get disabled() { return _ptr.disabled; }

  void set disabled(bool value) { _ptr.disabled = value; }

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  ElementList get labels() { return LevelDom.wrapElementList(_ptr.labels); }

  int get length() { return _ptr.length; }

  void set length(int value) { _ptr.length = value; }

  bool get multiple() { return _ptr.multiple; }

  void set multiple(bool value) { _ptr.multiple = value; }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  ElementList get options() { return LevelDom.wrapElementList(_ptr.options); }

  bool get required() { return _ptr.required; }

  void set required(bool value) { _ptr.required = value; }

  int get selectedIndex() { return _ptr.selectedIndex; }

  void set selectedIndex(int value) { _ptr.selectedIndex = value; }

  int get size() { return _ptr.size; }

  void set size(int value) { _ptr.size = value; }

  String get type() { return _ptr.type; }

  String get validationMessage() { return _ptr.validationMessage; }

  ValidityState get validity() { return LevelDom.wrapValidityState(_ptr.validity); }

  String get value() { return _ptr.value; }

  void set value(String value) { _ptr.value = value; }

  bool get willValidate() { return _ptr.willValidate; }

  void add(Element element, Element before) {
    _ptr.add(LevelDom.unwrap(element), LevelDom.unwrap(before));
    return;
  }

  bool checkValidity() {
    return _ptr.checkValidity();
  }

  Node item(int index) {
    return LevelDom.wrapNode(_ptr.item(index));
  }

  Node namedItem(String name) {
    return LevelDom.wrapNode(_ptr.namedItem(name));
  }

  void setCustomValidity(String error) {
    _ptr.setCustomValidity(error);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SourceElementWrappingImplementation extends ElementWrappingImplementation implements SourceElement {
  SourceElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get media() { return _ptr.media; }

  void set media(String value) { _ptr.media = value; }

  String get src() { return _ptr.src; }

  void set src(String value) { _ptr.src = value; }

  String get type() { return _ptr.type; }

  void set type(String value) { _ptr.type = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SpanElementWrappingImplementation extends ElementWrappingImplementation implements SpanElement {
  SpanElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SpeechInputEventWrappingImplementation extends EventWrappingImplementation implements SpeechInputEvent {
  SpeechInputEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SpeechInputResultList get results() { return LevelDom.wrapSpeechInputResultList(_ptr.results); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SpeechInputResultListWrappingImplementation extends DOMWrapperBase implements SpeechInputResultList {
  SpeechInputResultListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  SpeechInputResult item(int index) {
    return LevelDom.wrapSpeechInputResult(_ptr.item(index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SpeechInputResultWrappingImplementation extends DOMWrapperBase implements SpeechInputResult {
  SpeechInputResultWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get confidence() { return _ptr.confidence; }

  String get utterance() { return _ptr.utterance; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class StorageInfoWrappingImplementation extends DOMWrapperBase implements StorageInfo {
  StorageInfoWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void queryUsageAndQuota(int storageType, [StorageInfoUsageCallback usageCallback, StorageInfoErrorCallback errorCallback]) {
    if (usageCallback === null) {
      if (errorCallback === null) {
        _ptr.queryUsageAndQuota(storageType);
        return;
      }
    } else {
      if (errorCallback === null) {
        _ptr.queryUsageAndQuota(storageType, LevelDom.unwrap(usageCallback));
        return;
      } else {
        _ptr.queryUsageAndQuota(storageType, LevelDom.unwrap(usageCallback), errorCallback);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void requestQuota(int storageType, int newQuotaInBytes, [StorageInfoQuotaCallback quotaCallback, StorageInfoErrorCallback errorCallback]) {
    if (quotaCallback === null) {
      if (errorCallback === null) {
        _ptr.requestQuota(storageType, newQuotaInBytes);
        return;
      }
    } else {
      if (errorCallback === null) {
        _ptr.requestQuota(storageType, newQuotaInBytes, quotaCallback);
        return;
      } else {
        _ptr.requestQuota(storageType, newQuotaInBytes, quotaCallback, errorCallback);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class StorageWrappingImplementation extends DOMWrapperBase implements Storage {
  StorageWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  void clear() {
    _ptr.clear();
    return;
  }

  String getItem(String key) {
    return _ptr.getItem(key);
  }

  String key(int index) {
    return _ptr.key(index);
  }

  void removeItem(String key) {
    _ptr.removeItem(key);
    return;
  }

  void setItem(String key, String data) {
    _ptr.setItem(key, data);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class StyleElementWrappingImplementation extends ElementWrappingImplementation implements StyleElement {
  StyleElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get disabled() { return _ptr.disabled; }

  void set disabled(bool value) { _ptr.disabled = value; }

  String get media() { return _ptr.media; }

  void set media(String value) { _ptr.media = value; }

  StyleSheet get sheet() { return LevelDom.wrapStyleSheet(_ptr.sheet); }

  String get type() { return _ptr.type; }

  void set type(String value) { _ptr.type = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class StyleMediaWrappingImplementation extends DOMWrapperBase implements StyleMedia {
  StyleMediaWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get type() { return _ptr.type; }

  bool matchMedium(String mediaquery) {
    return _ptr.matchMedium(mediaquery);
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class StyleSheetListWrappingImplementation extends DOMWrapperBase implements StyleSheetList {
  StyleSheetListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  StyleSheet operator[](int index) {
    return LevelDom.wrapStyleSheet(_ptr[index]);
  }

  void operator[]=(int index, StyleSheet value) {
    _ptr[index] = LevelDom.unwrap(value);
  }

  void add(StyleSheet value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addLast(StyleSheet value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addAll(Collection<StyleSheet> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void sort(int compare(StyleSheet a, StyleSheet b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
  }

  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) {
    throw new UnsupportedOperationException("This object is immutable.");
  }

  int indexOf(StyleSheet element, [int start = 0]) {
    return _Lists.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(StyleSheet element, [int start = null]) {
    if (start === null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int clear() {
    throw new UnsupportedOperationException("Cannot clear immutable List.");
  }

  StyleSheet removeLast() {
    throw new UnsupportedOperationException("Cannot removeLast on immutable List.");
  }

  StyleSheet last() {
    return this[length - 1];
  }

  void forEach(void f(StyleSheet element)) {
    _Collections.forEach(this, f);
  }

  Collection<StyleSheet> filter(bool f(StyleSheet element)) {
    return _Collections.filter(this, new List<StyleSheet>(), f);
  }

  bool every(bool f(StyleSheet element)) {
    return _Collections.every(this, f);
  }

  bool some(bool f(StyleSheet element)) {
    return _Collections.some(this, f);
  }

  void setRange(int start, int length, List<StyleSheet> from, [int startFrom]) {
    throw new UnsupportedOperationException("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int length) {
    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int length, [StyleSheet initialValue]) {
    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");
  }

  List<StyleSheet> getRange(int start, int length) {
    throw new NotImplementedException();
  }

  bool isEmpty() {
    return length == 0;
  }

  Iterator<StyleSheet> iterator() {
    return new _FixedSizeListIterator<StyleSheet>(this);
  }

  StyleSheet item(int index) {
    return LevelDom.wrapStyleSheet(_ptr.item(index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class StyleSheetWrappingImplementation extends DOMWrapperBase implements StyleSheet {
  StyleSheetWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get disabled() { return _ptr.disabled; }

  void set disabled(bool value) { _ptr.disabled = value; }

  String get href() { return _ptr.href; }

  MediaList get media() { return LevelDom.wrapMediaList(_ptr.media); }

  Node get ownerNode() { return LevelDom.wrapNode(_ptr.ownerNode); }

  StyleSheet get parentStyleSheet() { return LevelDom.wrapStyleSheet(_ptr.parentStyleSheet); }

  String get title() { return _ptr.title; }

  String get type() { return _ptr.type; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TableCaptionElementWrappingImplementation extends ElementWrappingImplementation implements TableCaptionElement {
  TableCaptionElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TableCellElementWrappingImplementation extends ElementWrappingImplementation implements TableCellElement {
  TableCellElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get abbr() { return _ptr.abbr; }

  void set abbr(String value) { _ptr.abbr = value; }

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }

  String get axis() { return _ptr.axis; }

  void set axis(String value) { _ptr.axis = value; }

  String get bgColor() { return _ptr.bgColor; }

  void set bgColor(String value) { _ptr.bgColor = value; }

  int get cellIndex() { return _ptr.cellIndex; }

  String get ch() { return _ptr.ch; }

  void set ch(String value) { _ptr.ch = value; }

  String get chOff() { return _ptr.chOff; }

  void set chOff(String value) { _ptr.chOff = value; }

  int get colSpan() { return _ptr.colSpan; }

  void set colSpan(int value) { _ptr.colSpan = value; }

  String get headers() { return _ptr.headers; }

  void set headers(String value) { _ptr.headers = value; }

  String get height() { return _ptr.height; }

  void set height(String value) { _ptr.height = value; }

  bool get noWrap() { return _ptr.noWrap; }

  void set noWrap(bool value) { _ptr.noWrap = value; }

  int get rowSpan() { return _ptr.rowSpan; }

  void set rowSpan(int value) { _ptr.rowSpan = value; }

  String get scope() { return _ptr.scope; }

  void set scope(String value) { _ptr.scope = value; }

  String get vAlign() { return _ptr.vAlign; }

  void set vAlign(String value) { _ptr.vAlign = value; }

  String get width() { return _ptr.width; }

  void set width(String value) { _ptr.width = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TableColElementWrappingImplementation extends ElementWrappingImplementation implements TableColElement {
  TableColElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }

  String get ch() { return _ptr.ch; }

  void set ch(String value) { _ptr.ch = value; }

  String get chOff() { return _ptr.chOff; }

  void set chOff(String value) { _ptr.chOff = value; }

  int get span() { return _ptr.span; }

  void set span(int value) { _ptr.span = value; }

  String get vAlign() { return _ptr.vAlign; }

  void set vAlign(String value) { _ptr.vAlign = value; }

  String get width() { return _ptr.width; }

  void set width(String value) { _ptr.width = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TableElementWrappingImplementation extends ElementWrappingImplementation implements TableElement {
  TableElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }

  String get bgColor() { return _ptr.bgColor; }

  void set bgColor(String value) { _ptr.bgColor = value; }

  String get border() { return _ptr.border; }

  void set border(String value) { _ptr.border = value; }

  TableCaptionElement get caption() { return LevelDom.wrapTableCaptionElement(_ptr.caption); }

  void set caption(TableCaptionElement value) { _ptr.caption = LevelDom.unwrap(value); }

  String get cellPadding() { return _ptr.cellPadding; }

  void set cellPadding(String value) { _ptr.cellPadding = value; }

  String get cellSpacing() { return _ptr.cellSpacing; }

  void set cellSpacing(String value) { _ptr.cellSpacing = value; }

  String get frame() { return _ptr.frame; }

  void set frame(String value) { _ptr.frame = value; }

  ElementList get rows() { return LevelDom.wrapElementList(_ptr.rows); }

  String get rules() { return _ptr.rules; }

  void set rules(String value) { _ptr.rules = value; }

  String get summary() { return _ptr.summary; }

  void set summary(String value) { _ptr.summary = value; }

  ElementList get tBodies() { return LevelDom.wrapElementList(_ptr.tBodies); }

  TableSectionElement get tFoot() { return LevelDom.wrapTableSectionElement(_ptr.tFoot); }

  void set tFoot(TableSectionElement value) { _ptr.tFoot = LevelDom.unwrap(value); }

  TableSectionElement get tHead() { return LevelDom.wrapTableSectionElement(_ptr.tHead); }

  void set tHead(TableSectionElement value) { _ptr.tHead = LevelDom.unwrap(value); }

  String get width() { return _ptr.width; }

  void set width(String value) { _ptr.width = value; }

  Element createCaption() {
    return LevelDom.wrapElement(_ptr.createCaption());
  }

  Element createTFoot() {
    return LevelDom.wrapElement(_ptr.createTFoot());
  }

  Element createTHead() {
    return LevelDom.wrapElement(_ptr.createTHead());
  }

  void deleteCaption() {
    _ptr.deleteCaption();
    return;
  }

  void deleteRow(int index) {
    _ptr.deleteRow(index);
    return;
  }

  void deleteTFoot() {
    _ptr.deleteTFoot();
    return;
  }

  void deleteTHead() {
    _ptr.deleteTHead();
    return;
  }

  Element insertRow(int index) {
    return LevelDom.wrapElement(_ptr.insertRow(index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TableRowElementWrappingImplementation extends ElementWrappingImplementation implements TableRowElement {
  TableRowElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }

  String get bgColor() { return _ptr.bgColor; }

  void set bgColor(String value) { _ptr.bgColor = value; }

  ElementList get cells() { return LevelDom.wrapElementList(_ptr.cells); }

  String get ch() { return _ptr.ch; }

  void set ch(String value) { _ptr.ch = value; }

  String get chOff() { return _ptr.chOff; }

  void set chOff(String value) { _ptr.chOff = value; }

  int get rowIndex() { return _ptr.rowIndex; }

  int get sectionRowIndex() { return _ptr.sectionRowIndex; }

  String get vAlign() { return _ptr.vAlign; }

  void set vAlign(String value) { _ptr.vAlign = value; }

  void deleteCell(int index) {
    _ptr.deleteCell(index);
    return;
  }

  Element insertCell(int index) {
    return LevelDom.wrapElement(_ptr.insertCell(index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TableSectionElementWrappingImplementation extends ElementWrappingImplementation implements TableSectionElement {
  TableSectionElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }

  String get ch() { return _ptr.ch; }

  void set ch(String value) { _ptr.ch = value; }

  String get chOff() { return _ptr.chOff; }

  void set chOff(String value) { _ptr.chOff = value; }

  ElementList get rows() { return LevelDom.wrapElementList(_ptr.rows); }

  String get vAlign() { return _ptr.vAlign; }

  void set vAlign(String value) { _ptr.vAlign = value; }

  void deleteRow(int index) {
    _ptr.deleteRow(index);
    return;
  }

  Element insertRow(int index) {
    return LevelDom.wrapElement(_ptr.insertRow(index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TextAreaElementWrappingImplementation extends ElementWrappingImplementation implements TextAreaElement {
  TextAreaElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get accessKey() { return _ptr.accessKey; }

  void set accessKey(String value) { _ptr.accessKey = value; }

  bool get autofocus() { return _ptr.autofocus; }

  void set autofocus(bool value) { _ptr.autofocus = value; }

  int get cols() { return _ptr.cols; }

  void set cols(int value) { _ptr.cols = value; }

  String get defaultValue() { return _ptr.defaultValue; }

  void set defaultValue(String value) { _ptr.defaultValue = value; }

  bool get disabled() { return _ptr.disabled; }

  void set disabled(bool value) { _ptr.disabled = value; }

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  ElementList get labels() { return LevelDom.wrapElementList(_ptr.labels); }

  int get maxLength() { return _ptr.maxLength; }

  void set maxLength(int value) { _ptr.maxLength = value; }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  String get placeholder() { return _ptr.placeholder; }

  void set placeholder(String value) { _ptr.placeholder = value; }

  bool get readOnly() { return _ptr.readOnly; }

  void set readOnly(bool value) { _ptr.readOnly = value; }

  bool get required() { return _ptr.required; }

  void set required(bool value) { _ptr.required = value; }

  int get rows() { return _ptr.rows; }

  void set rows(int value) { _ptr.rows = value; }

  String get selectionDirection() { return _ptr.selectionDirection; }

  void set selectionDirection(String value) { _ptr.selectionDirection = value; }

  int get selectionEnd() { return _ptr.selectionEnd; }

  void set selectionEnd(int value) { _ptr.selectionEnd = value; }

  int get selectionStart() { return _ptr.selectionStart; }

  void set selectionStart(int value) { _ptr.selectionStart = value; }

  int get textLength() { return _ptr.textLength; }

  String get type() { return _ptr.type; }

  String get validationMessage() { return _ptr.validationMessage; }

  ValidityState get validity() { return LevelDom.wrapValidityState(_ptr.validity); }

  String get value() { return _ptr.value; }

  void set value(String value) { _ptr.value = value; }

  bool get willValidate() { return _ptr.willValidate; }

  String get wrap() { return _ptr.wrap; }

  void set wrap(String value) { _ptr.wrap = value; }

  bool checkValidity() {
    return _ptr.checkValidity();
  }

  void select() {
    _ptr.select();
    return;
  }

  void setCustomValidity(String error) {
    _ptr.setCustomValidity(error);
    return;
  }

  void setSelectionRange(int start, int end, [String direction]) {
    if (direction === null) {
      _ptr.setSelectionRange(start, end);
      return;
    } else {
      _ptr.setSelectionRange(start, end, direction);
      return;
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TextMetricsWrappingImplementation extends DOMWrapperBase implements TextMetrics {
  TextMetricsWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get width() { return _ptr.width; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TextTrackCueListWrappingImplementation extends DOMWrapperBase implements TextTrackCueList {
  TextTrackCueListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  TextTrackCue getCueById(String id) {
    return LevelDom.wrapTextTrackCue(_ptr.getCueById(id));
  }

  TextTrackCue item(int index) {
    return LevelDom.wrapTextTrackCue(_ptr.item(index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TextTrackCueWrappingImplementation extends DOMWrapperBase implements TextTrackCue {
  TextTrackCueWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get alignment() { return _ptr.alignment; }

  String get direction() { return _ptr.direction; }

  num get endTime() { return _ptr.endTime; }

  String get id() { return _ptr.id; }

  int get linePosition() { return _ptr.linePosition; }

  bool get pauseOnExit() { return _ptr.pauseOnExit; }

  int get size() { return _ptr.size; }

  bool get snapToLines() { return _ptr.snapToLines; }

  num get startTime() { return _ptr.startTime; }

  int get textPosition() { return _ptr.textPosition; }

  TextTrack get track() { return LevelDom.wrapTextTrack(_ptr.track); }

  DocumentFragment getCueAsHTML() {
    return LevelDom.wrapDocumentFragment(_ptr.getCueAsHTML());
  }

  String getCueAsSource() {
    return _ptr.getCueAsSource();
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TextTrackWrappingImplementation extends DOMWrapperBase implements TextTrack {
  TextTrackWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  TextTrackCueList get activeCues() { return LevelDom.wrapTextTrackCueList(_ptr.activeCues); }

  TextTrackCueList get cues() { return LevelDom.wrapTextTrackCueList(_ptr.cues); }

  String get kind() { return _ptr.kind; }

  String get label() { return _ptr.label; }

  String get language() { return _ptr.language; }

  int get mode() { return _ptr.mode; }

  void set mode(int value) { _ptr.mode = value; }

  int get readyState() { return _ptr.readyState; }

  void addCue(TextTrackCue cue) {
    _ptr.addCue(LevelDom.unwrap(cue));
    return;
  }

  void removeCue(TextTrackCue cue) {
    _ptr.removeCue(LevelDom.unwrap(cue));
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TimeRangesWrappingImplementation extends DOMWrapperBase implements TimeRanges {
  TimeRangesWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  num end(int index) {
    return _ptr.end(index);
  }

  num start(int index) {
    return _ptr.start(index);
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TitleElementWrappingImplementation extends ElementWrappingImplementation implements TitleElement {
  TitleElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get text() { return _ptr.text; }

  void set text(String value) { _ptr.text = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TouchListWrappingImplementation extends DOMWrapperBase implements TouchList {
  TouchListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  Touch operator[](int index) {
    return LevelDom.wrapTouch(_ptr[index]);
  }

  void operator[]=(int index, Touch value) {
    _ptr[index] = LevelDom.unwrap(value);
  }

  void add(Touch value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addLast(Touch value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addAll(Collection<Touch> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void sort(int compare(Touch a, Touch b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
  }

  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) {
    throw new UnsupportedOperationException("This object is immutable.");
  }

  int indexOf(Touch element, [int start = 0]) {
    return _Lists.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(Touch element, [int start = null]) {
    if (start === null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int clear() {
    throw new UnsupportedOperationException("Cannot clear immutable List.");
  }

  Touch removeLast() {
    throw new UnsupportedOperationException("Cannot removeLast on immutable List.");
  }

  Touch last() {
    return this[length - 1];
  }

  void forEach(void f(Touch element)) {
    _Collections.forEach(this, f);
  }

  Collection<Touch> filter(bool f(Touch element)) {
    return _Collections.filter(this, new List<Touch>(), f);
  }

  bool every(bool f(Touch element)) {
    return _Collections.every(this, f);
  }

  bool some(bool f(Touch element)) {
    return _Collections.some(this, f);
  }

  void setRange(int start, int length, List<Touch> from, [int startFrom]) {
    throw new UnsupportedOperationException("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int length) {
    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int length, [Touch initialValue]) {
    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");
  }

  List<Touch> getRange(int start, int length) {
    throw new NotImplementedException();
  }

  bool isEmpty() {
    return length == 0;
  }

  Iterator<Touch> iterator() {
    return new _FixedSizeListIterator<Touch>(this);
  }

  Touch item(int index) {
    return LevelDom.wrapTouch(_ptr.item(index));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TouchWrappingImplementation extends DOMWrapperBase implements Touch {
  TouchWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get clientX() { return _ptr.clientX; }

  int get clientY() { return _ptr.clientY; }

  int get identifier() { return _ptr.identifier; }

  int get pageX() { return _ptr.pageX; }

  int get pageY() { return _ptr.pageY; }

  int get screenX() { return _ptr.screenX; }

  int get screenY() { return _ptr.screenY; }

  EventTarget get target() { return LevelDom.wrapEventTarget(_ptr.target); }

  num get webkitForce() { return _ptr.webkitForce; }

  int get webkitRadiusX() { return _ptr.webkitRadiusX; }

  int get webkitRadiusY() { return _ptr.webkitRadiusY; }

  num get webkitRotationAngle() { return _ptr.webkitRotationAngle; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TrackElementWrappingImplementation extends ElementWrappingImplementation implements TrackElement {
  TrackElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get isDefault() { return _ptr.isDefault; }

  void set isDefault(bool value) { _ptr.isDefault = value; }

  String get kind() { return _ptr.kind; }

  void set kind(String value) { _ptr.kind = value; }

  String get label() { return _ptr.label; }

  void set label(String value) { _ptr.label = value; }

  String get src() { return _ptr.src; }

  void set src(String value) { _ptr.src = value; }

  String get srclang() { return _ptr.srclang; }

  void set srclang(String value) { _ptr.srclang = value; }

  TextTrack get track() { return LevelDom.wrapTextTrack(_ptr.track); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class UListElementWrappingImplementation extends ElementWrappingImplementation implements UListElement {
  UListElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get compact() { return _ptr.compact; }

  void set compact(bool value) { _ptr.compact = value; }

  String get type() { return _ptr.type; }

  void set type(String value) { _ptr.type = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class Uint16ArrayWrappingImplementation extends ArrayBufferViewWrappingImplementation implements Uint16Array {
  Uint16ArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  Uint16Array subarray(int start, [int end]) {
    if (end === null) {
      return LevelDom.wrapUint16Array(_ptr.subarray(start));
    } else {
      return LevelDom.wrapUint16Array(_ptr.subarray(start, end));
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class Uint32ArrayWrappingImplementation extends ArrayBufferViewWrappingImplementation implements Uint32Array {
  Uint32ArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  Uint32Array subarray(int start, [int end]) {
    if (end === null) {
      return LevelDom.wrapUint32Array(_ptr.subarray(start));
    } else {
      return LevelDom.wrapUint32Array(_ptr.subarray(start, end));
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class Uint8ArrayWrappingImplementation extends ArrayBufferViewWrappingImplementation implements Uint8Array {
  Uint8ArrayWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  Uint8Array subarray(int start, [int end]) {
    if (end === null) {
      return LevelDom.wrapUint8Array(_ptr.subarray(start));
    } else {
      return LevelDom.wrapUint8Array(_ptr.subarray(start, end));
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class UnknownElementWrappingImplementation extends ElementWrappingImplementation implements UnknownElement {
  UnknownElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ValidityStateWrappingImplementation extends DOMWrapperBase implements ValidityState {
  ValidityStateWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get customError() { return _ptr.customError; }

  bool get patternMismatch() { return _ptr.patternMismatch; }

  bool get rangeOverflow() { return _ptr.rangeOverflow; }

  bool get rangeUnderflow() { return _ptr.rangeUnderflow; }

  bool get stepMismatch() { return _ptr.stepMismatch; }

  bool get tooLong() { return _ptr.tooLong; }

  bool get typeMismatch() { return _ptr.typeMismatch; }

  bool get valid() { return _ptr.valid; }

  bool get valueMissing() { return _ptr.valueMissing; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class VideoElementWrappingImplementation extends MediaElementWrappingImplementation implements VideoElement {
  VideoElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get height() { return _ptr.height; }

  void set height(int value) { _ptr.height = value; }

  String get poster() { return _ptr.poster; }

  void set poster(String value) { _ptr.poster = value; }

  int get videoHeight() { return _ptr.videoHeight; }

  int get videoWidth() { return _ptr.videoWidth; }

  int get webkitDecodedFrameCount() { return _ptr.webkitDecodedFrameCount; }

  bool get webkitDisplayingFullscreen() { return _ptr.webkitDisplayingFullscreen; }

  int get webkitDroppedFrameCount() { return _ptr.webkitDroppedFrameCount; }

  bool get webkitSupportsFullscreen() { return _ptr.webkitSupportsFullscreen; }

  int get width() { return _ptr.width; }

  void set width(int value) { _ptr.width = value; }

  void webkitEnterFullScreen() {
    _ptr.webkitEnterFullScreen();
    return;
  }

  void webkitEnterFullscreen() {
    _ptr.webkitEnterFullscreen();
    return;
  }

  void webkitExitFullScreen() {
    _ptr.webkitExitFullScreen();
    return;
  }

  void webkitExitFullscreen() {
    _ptr.webkitExitFullscreen();
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class VoidCallbackWrappingImplementation extends DOMWrapperBase implements VoidCallback {
  VoidCallbackWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void handleEvent() {
    _ptr.handleEvent();
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class WaveShaperNodeWrappingImplementation extends AudioNodeWrappingImplementation implements WaveShaperNode {
  WaveShaperNodeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  Float32Array get curve() { return LevelDom.wrapFloat32Array(_ptr.curve); }

  void set curve(Float32Array value) { _ptr.curve = LevelDom.unwrap(value); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class WebGLActiveInfoWrappingImplementation extends DOMWrapperBase implements WebGLActiveInfo {
  WebGLActiveInfoWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get name() { return _ptr.name; }

  int get size() { return _ptr.size; }

  int get type() { return _ptr.type; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class WebGLBufferWrappingImplementation extends DOMWrapperBase implements WebGLBuffer {
  WebGLBufferWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class WebGLContextAttributesWrappingImplementation extends DOMWrapperBase implements WebGLContextAttributes {
  WebGLContextAttributesWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get alpha() { return _ptr.alpha; }

  void set alpha(bool value) { _ptr.alpha = value; }

  bool get antialias() { return _ptr.antialias; }

  void set antialias(bool value) { _ptr.antialias = value; }

  bool get depth() { return _ptr.depth; }

  void set depth(bool value) { _ptr.depth = value; }

  bool get premultipliedAlpha() { return _ptr.premultipliedAlpha; }

  void set premultipliedAlpha(bool value) { _ptr.premultipliedAlpha = value; }

  bool get preserveDrawingBuffer() { return _ptr.preserveDrawingBuffer; }

  void set preserveDrawingBuffer(bool value) { _ptr.preserveDrawingBuffer = value; }

  bool get stencil() { return _ptr.stencil; }

  void set stencil(bool value) { _ptr.stencil = value; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class WebGLContextEventWrappingImplementation extends EventWrappingImplementation implements WebGLContextEvent {
  WebGLContextEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get statusMessage() { return _ptr.statusMessage; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class WebGLDebugRendererInfoWrappingImplementation extends DOMWrapperBase implements WebGLDebugRendererInfo {
  WebGLDebugRendererInfoWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class WebGLDebugShadersWrappingImplementation extends DOMWrapperBase implements WebGLDebugShaders {
  WebGLDebugShadersWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String getTranslatedShaderSource(WebGLShader shader) {
    return _ptr.getTranslatedShaderSource(LevelDom.unwrap(shader));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class WebGLFramebufferWrappingImplementation extends DOMWrapperBase implements WebGLFramebuffer {
  WebGLFramebufferWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class WebGLProgramWrappingImplementation extends DOMWrapperBase implements WebGLProgram {
  WebGLProgramWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class WebGLRenderbufferWrappingImplementation extends DOMWrapperBase implements WebGLRenderbuffer {
  WebGLRenderbufferWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class WebGLRenderingContextWrappingImplementation extends CanvasRenderingContextWrappingImplementation implements WebGLRenderingContext {
  WebGLRenderingContextWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get drawingBufferHeight() { return _ptr.drawingBufferHeight; }

  int get drawingBufferWidth() { return _ptr.drawingBufferWidth; }

  void activeTexture(int texture) {
    _ptr.activeTexture(texture);
    return;
  }

  void attachShader(WebGLProgram program, WebGLShader shader) {
    _ptr.attachShader(LevelDom.unwrap(program), LevelDom.unwrap(shader));
    return;
  }

  void bindAttribLocation(WebGLProgram program, int index, String name) {
    _ptr.bindAttribLocation(LevelDom.unwrap(program), index, name);
    return;
  }

  void bindBuffer(int target, WebGLBuffer buffer) {
    _ptr.bindBuffer(target, LevelDom.unwrap(buffer));
    return;
  }

  void bindFramebuffer(int target, WebGLFramebuffer framebuffer) {
    _ptr.bindFramebuffer(target, LevelDom.unwrap(framebuffer));
    return;
  }

  void bindRenderbuffer(int target, WebGLRenderbuffer renderbuffer) {
    _ptr.bindRenderbuffer(target, LevelDom.unwrap(renderbuffer));
    return;
  }

  void bindTexture(int target, WebGLTexture texture) {
    _ptr.bindTexture(target, LevelDom.unwrap(texture));
    return;
  }

  void blendColor(num red, num green, num blue, num alpha) {
    _ptr.blendColor(red, green, blue, alpha);
    return;
  }

  void blendEquation(int mode) {
    _ptr.blendEquation(mode);
    return;
  }

  void blendEquationSeparate(int modeRGB, int modeAlpha) {
    _ptr.blendEquationSeparate(modeRGB, modeAlpha);
    return;
  }

  void blendFunc(int sfactor, int dfactor) {
    _ptr.blendFunc(sfactor, dfactor);
    return;
  }

  void blendFuncSeparate(int srcRGB, int dstRGB, int srcAlpha, int dstAlpha) {
    _ptr.blendFuncSeparate(srcRGB, dstRGB, srcAlpha, dstAlpha);
    return;
  }

  void bufferData(int target, var data_OR_size, int usage) {
    if (data_OR_size is ArrayBuffer) {
      _ptr.bufferData(target, LevelDom.unwrapMaybePrimitive(data_OR_size), usage);
      return;
    } else {
      if (data_OR_size is ArrayBufferView) {
        _ptr.bufferData(target, LevelDom.unwrapMaybePrimitive(data_OR_size), usage);
        return;
      } else {
        if (data_OR_size is int) {
          _ptr.bufferData(target, LevelDom.unwrapMaybePrimitive(data_OR_size), usage);
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void bufferSubData(int target, int offset, var data) {
    if (data is ArrayBuffer) {
      _ptr.bufferSubData(target, offset, LevelDom.unwrapMaybePrimitive(data));
      return;
    } else {
      if (data is ArrayBufferView) {
        _ptr.bufferSubData(target, offset, LevelDom.unwrapMaybePrimitive(data));
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }

  int checkFramebufferStatus(int target) {
    return _ptr.checkFramebufferStatus(target);
  }

  void clear(int mask) {
    _ptr.clear(mask);
    return;
  }

  void clearColor(num red, num green, num blue, num alpha) {
    _ptr.clearColor(red, green, blue, alpha);
    return;
  }

  void clearDepth(num depth) {
    _ptr.clearDepth(depth);
    return;
  }

  void clearStencil(int s) {
    _ptr.clearStencil(s);
    return;
  }

  void colorMask(bool red, bool green, bool blue, bool alpha) {
    _ptr.colorMask(red, green, blue, alpha);
    return;
  }

  void compileShader(WebGLShader shader) {
    _ptr.compileShader(LevelDom.unwrap(shader));
    return;
  }

  void copyTexImage2D(int target, int level, int internalformat, int x, int y, int width, int height, int border) {
    _ptr.copyTexImage2D(target, level, internalformat, x, y, width, height, border);
    return;
  }

  void copyTexSubImage2D(int target, int level, int xoffset, int yoffset, int x, int y, int width, int height) {
    _ptr.copyTexSubImage2D(target, level, xoffset, yoffset, x, y, width, height);
    return;
  }

  WebGLBuffer createBuffer() {
    return LevelDom.wrapWebGLBuffer(_ptr.createBuffer());
  }

  WebGLFramebuffer createFramebuffer() {
    return LevelDom.wrapWebGLFramebuffer(_ptr.createFramebuffer());
  }

  WebGLProgram createProgram() {
    return LevelDom.wrapWebGLProgram(_ptr.createProgram());
  }

  WebGLRenderbuffer createRenderbuffer() {
    return LevelDom.wrapWebGLRenderbuffer(_ptr.createRenderbuffer());
  }

  WebGLShader createShader(int type) {
    return LevelDom.wrapWebGLShader(_ptr.createShader(type));
  }

  WebGLTexture createTexture() {
    return LevelDom.wrapWebGLTexture(_ptr.createTexture());
  }

  void cullFace(int mode) {
    _ptr.cullFace(mode);
    return;
  }

  void deleteBuffer(WebGLBuffer buffer) {
    _ptr.deleteBuffer(LevelDom.unwrap(buffer));
    return;
  }

  void deleteFramebuffer(WebGLFramebuffer framebuffer) {
    _ptr.deleteFramebuffer(LevelDom.unwrap(framebuffer));
    return;
  }

  void deleteProgram(WebGLProgram program) {
    _ptr.deleteProgram(LevelDom.unwrap(program));
    return;
  }

  void deleteRenderbuffer(WebGLRenderbuffer renderbuffer) {
    _ptr.deleteRenderbuffer(LevelDom.unwrap(renderbuffer));
    return;
  }

  void deleteShader(WebGLShader shader) {
    _ptr.deleteShader(LevelDom.unwrap(shader));
    return;
  }

  void deleteTexture(WebGLTexture texture) {
    _ptr.deleteTexture(LevelDom.unwrap(texture));
    return;
  }

  void depthFunc(int func) {
    _ptr.depthFunc(func);
    return;
  }

  void depthMask(bool flag) {
    _ptr.depthMask(flag);
    return;
  }

  void depthRange(num zNear, num zFar) {
    _ptr.depthRange(zNear, zFar);
    return;
  }

  void detachShader(WebGLProgram program, WebGLShader shader) {
    _ptr.detachShader(LevelDom.unwrap(program), LevelDom.unwrap(shader));
    return;
  }

  void disable(int cap) {
    _ptr.disable(cap);
    return;
  }

  void disableVertexAttribArray(int index) {
    _ptr.disableVertexAttribArray(index);
    return;
  }

  void drawArrays(int mode, int first, int count) {
    _ptr.drawArrays(mode, first, count);
    return;
  }

  void drawElements(int mode, int count, int type, int offset) {
    _ptr.drawElements(mode, count, type, offset);
    return;
  }

  void enable(int cap) {
    _ptr.enable(cap);
    return;
  }

  void enableVertexAttribArray(int index) {
    _ptr.enableVertexAttribArray(index);
    return;
  }

  void finish() {
    _ptr.finish();
    return;
  }

  void flush() {
    _ptr.flush();
    return;
  }

  void framebufferRenderbuffer(int target, int attachment, int renderbuffertarget, WebGLRenderbuffer renderbuffer) {
    _ptr.framebufferRenderbuffer(target, attachment, renderbuffertarget, LevelDom.unwrap(renderbuffer));
    return;
  }

  void framebufferTexture2D(int target, int attachment, int textarget, WebGLTexture texture, int level) {
    _ptr.framebufferTexture2D(target, attachment, textarget, LevelDom.unwrap(texture), level);
    return;
  }

  void frontFace(int mode) {
    _ptr.frontFace(mode);
    return;
  }

  void generateMipmap(int target) {
    _ptr.generateMipmap(target);
    return;
  }

  WebGLActiveInfo getActiveAttrib(WebGLProgram program, int index) {
    return LevelDom.wrapWebGLActiveInfo(_ptr.getActiveAttrib(LevelDom.unwrap(program), index));
  }

  WebGLActiveInfo getActiveUniform(WebGLProgram program, int index) {
    return LevelDom.wrapWebGLActiveInfo(_ptr.getActiveUniform(LevelDom.unwrap(program), index));
  }

  void getAttachedShaders(WebGLProgram program) {
    _ptr.getAttachedShaders(LevelDom.unwrap(program));
    return;
  }

  int getAttribLocation(WebGLProgram program, String name) {
    return _ptr.getAttribLocation(LevelDom.unwrap(program), name);
  }

  Object getBufferParameter(int target, int pname) {
    return LevelDom.wrapObject(_ptr.getBufferParameter(target, pname));
  }

  WebGLContextAttributes getContextAttributes() {
    return LevelDom.wrapWebGLContextAttributes(_ptr.getContextAttributes());
  }

  int getError() {
    return _ptr.getError();
  }

  Object getExtension(String name) {
    return LevelDom.wrapObject(_ptr.getExtension(name));
  }

  Object getFramebufferAttachmentParameter(int target, int attachment, int pname) {
    return LevelDom.wrapObject(_ptr.getFramebufferAttachmentParameter(target, attachment, pname));
  }

  Object getParameter(int pname) {
    return LevelDom.wrapObject(_ptr.getParameter(pname));
  }

  String getProgramInfoLog(WebGLProgram program) {
    return _ptr.getProgramInfoLog(LevelDom.unwrap(program));
  }

  Object getProgramParameter(WebGLProgram program, int pname) {
    return LevelDom.wrapObject(_ptr.getProgramParameter(LevelDom.unwrap(program), pname));
  }

  Object getRenderbufferParameter(int target, int pname) {
    return LevelDom.wrapObject(_ptr.getRenderbufferParameter(target, pname));
  }

  String getShaderInfoLog(WebGLShader shader) {
    return _ptr.getShaderInfoLog(LevelDom.unwrap(shader));
  }

  Object getShaderParameter(WebGLShader shader, int pname) {
    return LevelDom.wrapObject(_ptr.getShaderParameter(LevelDom.unwrap(shader), pname));
  }

  String getShaderSource(WebGLShader shader) {
    return _ptr.getShaderSource(LevelDom.unwrap(shader));
  }

  Object getTexParameter(int target, int pname) {
    return LevelDom.wrapObject(_ptr.getTexParameter(target, pname));
  }

  Object getUniform(WebGLProgram program, WebGLUniformLocation location) {
    return LevelDom.wrapObject(_ptr.getUniform(LevelDom.unwrap(program), LevelDom.unwrap(location)));
  }

  WebGLUniformLocation getUniformLocation(WebGLProgram program, String name) {
    return LevelDom.wrapWebGLUniformLocation(_ptr.getUniformLocation(LevelDom.unwrap(program), name));
  }

  Object getVertexAttrib(int index, int pname) {
    return LevelDom.wrapObject(_ptr.getVertexAttrib(index, pname));
  }

  int getVertexAttribOffset(int index, int pname) {
    return _ptr.getVertexAttribOffset(index, pname);
  }

  void hint(int target, int mode) {
    _ptr.hint(target, mode);
    return;
  }

  bool isBuffer(WebGLBuffer buffer) {
    return _ptr.isBuffer(LevelDom.unwrap(buffer));
  }

  bool isContextLost() {
    return _ptr.isContextLost();
  }

  bool isEnabled(int cap) {
    return _ptr.isEnabled(cap);
  }

  bool isFramebuffer(WebGLFramebuffer framebuffer) {
    return _ptr.isFramebuffer(LevelDom.unwrap(framebuffer));
  }

  bool isProgram(WebGLProgram program) {
    return _ptr.isProgram(LevelDom.unwrap(program));
  }

  bool isRenderbuffer(WebGLRenderbuffer renderbuffer) {
    return _ptr.isRenderbuffer(LevelDom.unwrap(renderbuffer));
  }

  bool isShader(WebGLShader shader) {
    return _ptr.isShader(LevelDom.unwrap(shader));
  }

  bool isTexture(WebGLTexture texture) {
    return _ptr.isTexture(LevelDom.unwrap(texture));
  }

  void lineWidth(num width) {
    _ptr.lineWidth(width);
    return;
  }

  void linkProgram(WebGLProgram program) {
    _ptr.linkProgram(LevelDom.unwrap(program));
    return;
  }

  void pixelStorei(int pname, int param) {
    _ptr.pixelStorei(pname, param);
    return;
  }

  void polygonOffset(num factor, num units) {
    _ptr.polygonOffset(factor, units);
    return;
  }

  void readPixels(int x, int y, int width, int height, int format, int type, ArrayBufferView pixels) {
    _ptr.readPixels(x, y, width, height, format, type, LevelDom.unwrap(pixels));
    return;
  }

  void releaseShaderCompiler() {
    _ptr.releaseShaderCompiler();
    return;
  }

  void renderbufferStorage(int target, int internalformat, int width, int height) {
    _ptr.renderbufferStorage(target, internalformat, width, height);
    return;
  }

  void sampleCoverage(num value, bool invert) {
    _ptr.sampleCoverage(value, invert);
    return;
  }

  void scissor(int x, int y, int width, int height) {
    _ptr.scissor(x, y, width, height);
    return;
  }

  void shaderSource(WebGLShader shader, String string) {
    _ptr.shaderSource(LevelDom.unwrap(shader), string);
    return;
  }

  void stencilFunc(int func, int ref, int mask) {
    _ptr.stencilFunc(func, ref, mask);
    return;
  }

  void stencilFuncSeparate(int face, int func, int ref, int mask) {
    _ptr.stencilFuncSeparate(face, func, ref, mask);
    return;
  }

  void stencilMask(int mask) {
    _ptr.stencilMask(mask);
    return;
  }

  void stencilMaskSeparate(int face, int mask) {
    _ptr.stencilMaskSeparate(face, mask);
    return;
  }

  void stencilOp(int fail, int zfail, int zpass) {
    _ptr.stencilOp(fail, zfail, zpass);
    return;
  }

  void stencilOpSeparate(int face, int fail, int zfail, int zpass) {
    _ptr.stencilOpSeparate(face, fail, zfail, zpass);
    return;
  }

  void texImage2D(int target, int level, int internalformat, int format_OR_width, int height_OR_type, var border_OR_canvas_OR_image_OR_pixels, [int format, int type, ArrayBufferView pixels]) {
    if (border_OR_canvas_OR_image_OR_pixels is ImageData) {
      if (format === null) {
        if (type === null) {
          if (pixels === null) {
            _ptr.texImage2D(target, level, internalformat, format_OR_width, height_OR_type, LevelDom.unwrapMaybePrimitive(border_OR_canvas_OR_image_OR_pixels));
            return;
          }
        }
      }
    } else {
      if (border_OR_canvas_OR_image_OR_pixels is ImageElement) {
        if (format === null) {
          if (type === null) {
            if (pixels === null) {
              _ptr.texImage2D(target, level, internalformat, format_OR_width, height_OR_type, LevelDom.unwrapMaybePrimitive(border_OR_canvas_OR_image_OR_pixels));
              return;
            }
          }
        }
      } else {
        if (border_OR_canvas_OR_image_OR_pixels is CanvasElement) {
          if (format === null) {
            if (type === null) {
              if (pixels === null) {
                _ptr.texImage2D(target, level, internalformat, format_OR_width, height_OR_type, LevelDom.unwrapMaybePrimitive(border_OR_canvas_OR_image_OR_pixels));
                return;
              }
            }
          }
        } else {
          if (border_OR_canvas_OR_image_OR_pixels is int) {
            _ptr.texImage2D(target, level, internalformat, format_OR_width, height_OR_type, LevelDom.unwrapMaybePrimitive(border_OR_canvas_OR_image_OR_pixels), format, type, LevelDom.unwrap(pixels));
            return;
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void texParameterf(int target, int pname, num param) {
    _ptr.texParameterf(target, pname, param);
    return;
  }

  void texParameteri(int target, int pname, int param) {
    _ptr.texParameteri(target, pname, param);
    return;
  }

  void texSubImage2D(int target, int level, int xoffset, int yoffset, int format_OR_width, int height_OR_type, var canvas_OR_format_OR_image_OR_pixels, [int type, ArrayBufferView pixels]) {
    if (canvas_OR_format_OR_image_OR_pixels is ImageData) {
      if (type === null) {
        if (pixels === null) {
          _ptr.texSubImage2D(target, level, xoffset, yoffset, format_OR_width, height_OR_type, LevelDom.unwrapMaybePrimitive(canvas_OR_format_OR_image_OR_pixels));
          return;
        }
      }
    } else {
      if (canvas_OR_format_OR_image_OR_pixels is ImageElement) {
        if (type === null) {
          if (pixels === null) {
            _ptr.texSubImage2D(target, level, xoffset, yoffset, format_OR_width, height_OR_type, LevelDom.unwrapMaybePrimitive(canvas_OR_format_OR_image_OR_pixels));
            return;
          }
        }
      } else {
        if (canvas_OR_format_OR_image_OR_pixels is CanvasElement) {
          if (type === null) {
            if (pixels === null) {
              _ptr.texSubImage2D(target, level, xoffset, yoffset, format_OR_width, height_OR_type, LevelDom.unwrapMaybePrimitive(canvas_OR_format_OR_image_OR_pixels));
              return;
            }
          }
        } else {
          if (canvas_OR_format_OR_image_OR_pixels is int) {
            _ptr.texSubImage2D(target, level, xoffset, yoffset, format_OR_width, height_OR_type, LevelDom.unwrapMaybePrimitive(canvas_OR_format_OR_image_OR_pixels), type, LevelDom.unwrap(pixels));
            return;
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void uniform1f(WebGLUniformLocation location, num x) {
    _ptr.uniform1f(LevelDom.unwrap(location), x);
    return;
  }

  void uniform1fv(WebGLUniformLocation location, Float32Array v) {
    _ptr.uniform1fv(LevelDom.unwrap(location), LevelDom.unwrap(v));
    return;
  }

  void uniform1i(WebGLUniformLocation location, int x) {
    _ptr.uniform1i(LevelDom.unwrap(location), x);
    return;
  }

  void uniform1iv(WebGLUniformLocation location, Int32Array v) {
    _ptr.uniform1iv(LevelDom.unwrap(location), LevelDom.unwrap(v));
    return;
  }

  void uniform2f(WebGLUniformLocation location, num x, num y) {
    _ptr.uniform2f(LevelDom.unwrap(location), x, y);
    return;
  }

  void uniform2fv(WebGLUniformLocation location, Float32Array v) {
    _ptr.uniform2fv(LevelDom.unwrap(location), LevelDom.unwrap(v));
    return;
  }

  void uniform2i(WebGLUniformLocation location, int x, int y) {
    _ptr.uniform2i(LevelDom.unwrap(location), x, y);
    return;
  }

  void uniform2iv(WebGLUniformLocation location, Int32Array v) {
    _ptr.uniform2iv(LevelDom.unwrap(location), LevelDom.unwrap(v));
    return;
  }

  void uniform3f(WebGLUniformLocation location, num x, num y, num z) {
    _ptr.uniform3f(LevelDom.unwrap(location), x, y, z);
    return;
  }

  void uniform3fv(WebGLUniformLocation location, Float32Array v) {
    _ptr.uniform3fv(LevelDom.unwrap(location), LevelDom.unwrap(v));
    return;
  }

  void uniform3i(WebGLUniformLocation location, int x, int y, int z) {
    _ptr.uniform3i(LevelDom.unwrap(location), x, y, z);
    return;
  }

  void uniform3iv(WebGLUniformLocation location, Int32Array v) {
    _ptr.uniform3iv(LevelDom.unwrap(location), LevelDom.unwrap(v));
    return;
  }

  void uniform4f(WebGLUniformLocation location, num x, num y, num z, num w) {
    _ptr.uniform4f(LevelDom.unwrap(location), x, y, z, w);
    return;
  }

  void uniform4fv(WebGLUniformLocation location, Float32Array v) {
    _ptr.uniform4fv(LevelDom.unwrap(location), LevelDom.unwrap(v));
    return;
  }

  void uniform4i(WebGLUniformLocation location, int x, int y, int z, int w) {
    _ptr.uniform4i(LevelDom.unwrap(location), x, y, z, w);
    return;
  }

  void uniform4iv(WebGLUniformLocation location, Int32Array v) {
    _ptr.uniform4iv(LevelDom.unwrap(location), LevelDom.unwrap(v));
    return;
  }

  void uniformMatrix2fv(WebGLUniformLocation location, bool transpose, Float32Array array) {
    _ptr.uniformMatrix2fv(LevelDom.unwrap(location), transpose, LevelDom.unwrap(array));
    return;
  }

  void uniformMatrix3fv(WebGLUniformLocation location, bool transpose, Float32Array array) {
    _ptr.uniformMatrix3fv(LevelDom.unwrap(location), transpose, LevelDom.unwrap(array));
    return;
  }

  void uniformMatrix4fv(WebGLUniformLocation location, bool transpose, Float32Array array) {
    _ptr.uniformMatrix4fv(LevelDom.unwrap(location), transpose, LevelDom.unwrap(array));
    return;
  }

  void useProgram(WebGLProgram program) {
    _ptr.useProgram(LevelDom.unwrap(program));
    return;
  }

  void validateProgram(WebGLProgram program) {
    _ptr.validateProgram(LevelDom.unwrap(program));
    return;
  }

  void vertexAttrib1f(int indx, num x) {
    _ptr.vertexAttrib1f(indx, x);
    return;
  }

  void vertexAttrib1fv(int indx, Float32Array values) {
    _ptr.vertexAttrib1fv(indx, LevelDom.unwrap(values));
    return;
  }

  void vertexAttrib2f(int indx, num x, num y) {
    _ptr.vertexAttrib2f(indx, x, y);
    return;
  }

  void vertexAttrib2fv(int indx, Float32Array values) {
    _ptr.vertexAttrib2fv(indx, LevelDom.unwrap(values));
    return;
  }

  void vertexAttrib3f(int indx, num x, num y, num z) {
    _ptr.vertexAttrib3f(indx, x, y, z);
    return;
  }

  void vertexAttrib3fv(int indx, Float32Array values) {
    _ptr.vertexAttrib3fv(indx, LevelDom.unwrap(values));
    return;
  }

  void vertexAttrib4f(int indx, num x, num y, num z, num w) {
    _ptr.vertexAttrib4f(indx, x, y, z, w);
    return;
  }

  void vertexAttrib4fv(int indx, Float32Array values) {
    _ptr.vertexAttrib4fv(indx, LevelDom.unwrap(values));
    return;
  }

  void vertexAttribPointer(int indx, int size, int type, bool normalized, int stride, int offset) {
    _ptr.vertexAttribPointer(indx, size, type, normalized, stride, offset);
    return;
  }

  void viewport(int x, int y, int width, int height) {
    _ptr.viewport(x, y, width, height);
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class WebGLShaderWrappingImplementation extends DOMWrapperBase implements WebGLShader {
  WebGLShaderWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class WebGLTextureWrappingImplementation extends DOMWrapperBase implements WebGLTexture {
  WebGLTextureWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class WebGLUniformLocationWrappingImplementation extends DOMWrapperBase implements WebGLUniformLocation {
  WebGLUniformLocationWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class WebGLVertexArrayObjectOESWrappingImplementation extends DOMWrapperBase implements WebGLVertexArrayObjectOES {
  WebGLVertexArrayObjectOESWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class WebKitCSSFilterValueWrappingImplementation extends CSSValueListWrappingImplementation implements WebKitCSSFilterValue {
  WebKitCSSFilterValueWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get operationType() { return _ptr.operationType; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class WebKitMutationObserverWrappingImplementation extends DOMWrapperBase implements WebKitMutationObserver {
  WebKitMutationObserverWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void disconnect() {
    _ptr.disconnect();
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class XMLHttpRequestExceptionWrappingImplementation extends DOMWrapperBase implements XMLHttpRequestException {
  XMLHttpRequestExceptionWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get code() { return _ptr.code; }

  String get message() { return _ptr.message; }

  String get name() { return _ptr.name; }

  String toString() {
    return _ptr.toString();
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class LevelDom {
  static AnchorElement wrapAnchorElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AnchorElementWrappingImplementation._wrap(raw);
  }

  static Animation wrapAnimation(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AnimationWrappingImplementation._wrap(raw);
  }

  static AnimationEvent wrapAnimationEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AnimationEventWrappingImplementation._wrap(raw);
  }

  static AnimationList wrapAnimationList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AnimationListWrappingImplementation._wrap(raw);
  }

  static AreaElement wrapAreaElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AreaElementWrappingImplementation._wrap(raw);
  }

  static ArrayBuffer wrapArrayBuffer(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ArrayBufferWrappingImplementation._wrap(raw);
  }

  static ArrayBufferView wrapArrayBufferView(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "ArrayBufferView":
        return new ArrayBufferViewWrappingImplementation._wrap(raw);
      case "DataView":
        return new DataViewWrappingImplementation._wrap(raw);
      case "Float32Array":
        return new Float32ArrayWrappingImplementation._wrap(raw);
      case "Float64Array":
        return new Float64ArrayWrappingImplementation._wrap(raw);
      case "Int16Array":
        return new Int16ArrayWrappingImplementation._wrap(raw);
      case "Int32Array":
        return new Int32ArrayWrappingImplementation._wrap(raw);
      case "Int8Array":
        return new Int8ArrayWrappingImplementation._wrap(raw);
      case "Uint16Array":
        return new Uint16ArrayWrappingImplementation._wrap(raw);
      case "Uint32Array":
        return new Uint32ArrayWrappingImplementation._wrap(raw);
      case "Uint8Array":
        return new Uint8ArrayWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static AudioBuffer wrapAudioBuffer(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AudioBufferWrappingImplementation._wrap(raw);
  }

  // Skipped AudioBufferCallback
  static AudioBufferSourceNode wrapAudioBufferSourceNode(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AudioBufferSourceNodeWrappingImplementation._wrap(raw);
  }

  static AudioChannelMerger wrapAudioChannelMerger(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AudioChannelMergerWrappingImplementation._wrap(raw);
  }

  static AudioChannelSplitter wrapAudioChannelSplitter(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AudioChannelSplitterWrappingImplementation._wrap(raw);
  }

  static AudioContext wrapAudioContext(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AudioContextWrappingImplementation._wrap(raw);
  }

  static AudioDestinationNode wrapAudioDestinationNode(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AudioDestinationNodeWrappingImplementation._wrap(raw);
  }

  static AudioElement wrapAudioElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AudioElementWrappingImplementation._wrap(raw);
  }

  static AudioGain wrapAudioGain(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AudioGainWrappingImplementation._wrap(raw);
  }

  static AudioGainNode wrapAudioGainNode(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AudioGainNodeWrappingImplementation._wrap(raw);
  }

  static AudioListener wrapAudioListener(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AudioListenerWrappingImplementation._wrap(raw);
  }

  static AudioNode wrapAudioNode(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "AudioBufferSourceNode":
        return new AudioBufferSourceNodeWrappingImplementation._wrap(raw);
      case "AudioChannelMerger":
        return new AudioChannelMergerWrappingImplementation._wrap(raw);
      case "AudioChannelSplitter":
        return new AudioChannelSplitterWrappingImplementation._wrap(raw);
      case "AudioDestinationNode":
        return new AudioDestinationNodeWrappingImplementation._wrap(raw);
      case "AudioGainNode":
        return new AudioGainNodeWrappingImplementation._wrap(raw);
      case "AudioNode":
        return new AudioNodeWrappingImplementation._wrap(raw);
      case "AudioPannerNode":
        return new AudioPannerNodeWrappingImplementation._wrap(raw);
      case "AudioSourceNode":
        return new AudioSourceNodeWrappingImplementation._wrap(raw);
      case "BiquadFilterNode":
        return new BiquadFilterNodeWrappingImplementation._wrap(raw);
      case "ConvolverNode":
        return new ConvolverNodeWrappingImplementation._wrap(raw);
      case "DelayNode":
        return new DelayNodeWrappingImplementation._wrap(raw);
      case "DynamicsCompressorNode":
        return new DynamicsCompressorNodeWrappingImplementation._wrap(raw);
      case "HighPass2FilterNode":
        return new HighPass2FilterNodeWrappingImplementation._wrap(raw);
      case "JavaScriptAudioNode":
        return new JavaScriptAudioNodeWrappingImplementation._wrap(raw);
      case "LowPass2FilterNode":
        return new LowPass2FilterNodeWrappingImplementation._wrap(raw);
      case "MediaElementAudioSourceNode":
        return new MediaElementAudioSourceNodeWrappingImplementation._wrap(raw);
      case "RealtimeAnalyserNode":
        return new RealtimeAnalyserNodeWrappingImplementation._wrap(raw);
      case "WaveShaperNode":
        return new WaveShaperNodeWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static AudioPannerNode wrapAudioPannerNode(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AudioPannerNodeWrappingImplementation._wrap(raw);
  }

  static AudioParam wrapAudioParam(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "AudioGain":
        return new AudioGainWrappingImplementation._wrap(raw);
      case "AudioParam":
        return new AudioParamWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static AudioProcessingEvent wrapAudioProcessingEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new AudioProcessingEventWrappingImplementation._wrap(raw);
  }

  static AudioSourceNode wrapAudioSourceNode(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "AudioBufferSourceNode":
        return new AudioBufferSourceNodeWrappingImplementation._wrap(raw);
      case "AudioSourceNode":
        return new AudioSourceNodeWrappingImplementation._wrap(raw);
      case "MediaElementAudioSourceNode":
        return new MediaElementAudioSourceNodeWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static BRElement wrapBRElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new BRElementWrappingImplementation._wrap(raw);
  }

  static BarInfo wrapBarInfo(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new BarInfoWrappingImplementation._wrap(raw);
  }

  static BaseElement wrapBaseElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new BaseElementWrappingImplementation._wrap(raw);
  }

  static BeforeLoadEvent wrapBeforeLoadEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new BeforeLoadEventWrappingImplementation._wrap(raw);
  }

  static BiquadFilterNode wrapBiquadFilterNode(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new BiquadFilterNodeWrappingImplementation._wrap(raw);
  }

  static Blob wrapBlob(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "Blob":
        return new BlobWrappingImplementation._wrap(raw);
      case "File":
        return new FileWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static BlobBuilder wrapBlobBuilder(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new BlobBuilderWrappingImplementation._wrap(raw);
  }

  static BodyElement wrapBodyElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new BodyElementWrappingImplementation._wrap(raw);
  }

  static ButtonElement wrapButtonElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ButtonElementWrappingImplementation._wrap(raw);
  }

  static CDATASection wrapCDATASection(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CDATASectionWrappingImplementation._wrap(raw);
  }

  static CSSCharsetRule wrapCSSCharsetRule(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSCharsetRuleWrappingImplementation._wrap(raw);
  }

  static CSSFontFaceRule wrapCSSFontFaceRule(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSFontFaceRuleWrappingImplementation._wrap(raw);
  }

  static CSSImportRule wrapCSSImportRule(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSImportRuleWrappingImplementation._wrap(raw);
  }

  static CSSKeyframeRule wrapCSSKeyframeRule(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSKeyframeRuleWrappingImplementation._wrap(raw);
  }

  static CSSKeyframesRule wrapCSSKeyframesRule(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSKeyframesRuleWrappingImplementation._wrap(raw);
  }

  static CSSMatrix wrapCSSMatrix(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSMatrixWrappingImplementation._wrap(raw);
  }

  static CSSMediaRule wrapCSSMediaRule(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSMediaRuleWrappingImplementation._wrap(raw);
  }

  static CSSPageRule wrapCSSPageRule(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSPageRuleWrappingImplementation._wrap(raw);
  }

  static CSSPrimitiveValue wrapCSSPrimitiveValue(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSPrimitiveValueWrappingImplementation._wrap(raw);
  }

  static CSSRule wrapCSSRule(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "CSSCharsetRule":
        return new CSSCharsetRuleWrappingImplementation._wrap(raw);
      case "CSSFontFaceRule":
        return new CSSFontFaceRuleWrappingImplementation._wrap(raw);
      case "CSSImportRule":
        return new CSSImportRuleWrappingImplementation._wrap(raw);
      case "WebKitCSSKeyframeRule":
        return new CSSKeyframeRuleWrappingImplementation._wrap(raw);
      case "WebKitCSSKeyframesRule":
        return new CSSKeyframesRuleWrappingImplementation._wrap(raw);
      case "CSSMediaRule":
        return new CSSMediaRuleWrappingImplementation._wrap(raw);
      case "CSSPageRule":
        return new CSSPageRuleWrappingImplementation._wrap(raw);
      case "CSSRule":
        return new CSSRuleWrappingImplementation._wrap(raw);
      case "CSSStyleRule":
        return new CSSStyleRuleWrappingImplementation._wrap(raw);
      case "CSSUnknownRule":
        return new CSSUnknownRuleWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static CSSRuleList wrapCSSRuleList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSRuleListWrappingImplementation._wrap(raw);
  }

  static CSSStyleDeclaration wrapCSSStyleDeclaration(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSStyleDeclarationWrappingImplementation._wrap(raw);
  }

  static CSSStyleRule wrapCSSStyleRule(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSStyleRuleWrappingImplementation._wrap(raw);
  }

  static CSSStyleSheet wrapCSSStyleSheet(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSStyleSheetWrappingImplementation._wrap(raw);
  }

  static CSSTransformValue wrapCSSTransformValue(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSTransformValueWrappingImplementation._wrap(raw);
  }

  static CSSUnknownRule wrapCSSUnknownRule(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CSSUnknownRuleWrappingImplementation._wrap(raw);
  }

  static CSSValue wrapCSSValue(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "CSSPrimitiveValue":
        return new CSSPrimitiveValueWrappingImplementation._wrap(raw);
      case "WebKitCSSTransformValue":
        return new CSSTransformValueWrappingImplementation._wrap(raw);
      case "CSSValue":
        return new CSSValueWrappingImplementation._wrap(raw);
      case "CSSValueList":
        return new CSSValueListWrappingImplementation._wrap(raw);
      case "SVGColor":
        return new SVGColorWrappingImplementation._wrap(raw);
      case "SVGPaint":
        return new SVGPaintWrappingImplementation._wrap(raw);
      case "WebKitCSSFilterValue":
        return new WebKitCSSFilterValueWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static CSSValueList wrapCSSValueList(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "WebKitCSSTransformValue":
        return new CSSTransformValueWrappingImplementation._wrap(raw);
      case "CSSValueList":
        return new CSSValueListWrappingImplementation._wrap(raw);
      case "WebKitCSSFilterValue":
        return new WebKitCSSFilterValueWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static CanvasElement wrapCanvasElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CanvasElementWrappingImplementation._wrap(raw);
  }

  static CanvasGradient wrapCanvasGradient(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CanvasGradientWrappingImplementation._wrap(raw);
  }

  static CanvasPattern wrapCanvasPattern(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CanvasPatternWrappingImplementation._wrap(raw);
  }

  static CanvasPixelArray wrapCanvasPixelArray(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CanvasPixelArrayWrappingImplementation._wrap(raw);
  }

  static CanvasRenderingContext wrapCanvasRenderingContext(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "CanvasRenderingContext":
        return new CanvasRenderingContextWrappingImplementation._wrap(raw);
      case "CanvasRenderingContext2D":
        return new CanvasRenderingContext2DWrappingImplementation._wrap(raw);
      case "WebGLRenderingContext":
        return new WebGLRenderingContextWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static CanvasRenderingContext2D wrapCanvasRenderingContext2D(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CanvasRenderingContext2DWrappingImplementation._wrap(raw);
  }

  static CharacterData wrapCharacterData(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "CDATASection":
        return new CDATASectionWrappingImplementation._wrap(raw);
      case "CharacterData":
        return new CharacterDataWrappingImplementation._wrap(raw);
      case "Comment":
        return new CommentWrappingImplementation._wrap(raw);
      case "Text":
        return new TextWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static ClientRect wrapClientRect(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ClientRectWrappingImplementation._wrap(raw);
  }

  static ClientRectList wrapClientRectList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ClientRectListWrappingImplementation._wrap(raw);
  }

  static Clipboard wrapClipboard(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ClipboardWrappingImplementation._wrap(raw);
  }

  static CloseEvent wrapCloseEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CloseEventWrappingImplementation._wrap(raw);
  }

  static Comment wrapComment(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CommentWrappingImplementation._wrap(raw);
  }

  static CompositionEvent wrapCompositionEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CompositionEventWrappingImplementation._wrap(raw);
  }

  static Console wrapConsole(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ConsoleWrappingImplementation._wrap(raw);
  }

  static ConvolverNode wrapConvolverNode(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ConvolverNodeWrappingImplementation._wrap(raw);
  }

  static Coordinates wrapCoordinates(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CoordinatesWrappingImplementation._wrap(raw);
  }

  static Counter wrapCounter(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CounterWrappingImplementation._wrap(raw);
  }

  static Crypto wrapCrypto(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CryptoWrappingImplementation._wrap(raw);
  }

  static CustomEvent wrapCustomEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new CustomEventWrappingImplementation._wrap(raw);
  }

  static DListElement wrapDListElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DListElementWrappingImplementation._wrap(raw);
  }

  static DOMApplicationCache wrapDOMApplicationCache(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMApplicationCacheWrappingImplementation._wrap(raw);
  }

  static DOMException wrapDOMException(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMExceptionWrappingImplementation._wrap(raw);
  }

  static DOMFileSystem wrapDOMFileSystem(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMFileSystemWrappingImplementation._wrap(raw);
  }

  static DOMFileSystemSync wrapDOMFileSystemSync(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMFileSystemSyncWrappingImplementation._wrap(raw);
  }

  static DOMFormData wrapDOMFormData(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMFormDataWrappingImplementation._wrap(raw);
  }

  static DOMMimeType wrapDOMMimeType(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMMimeTypeWrappingImplementation._wrap(raw);
  }

  static DOMMimeTypeArray wrapDOMMimeTypeArray(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMMimeTypeArrayWrappingImplementation._wrap(raw);
  }

  static DOMParser wrapDOMParser(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMParserWrappingImplementation._wrap(raw);
  }

  static DOMPlugin wrapDOMPlugin(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMPluginWrappingImplementation._wrap(raw);
  }

  static DOMPluginArray wrapDOMPluginArray(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMPluginArrayWrappingImplementation._wrap(raw);
  }

  static DOMSelection wrapDOMSelection(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMSelectionWrappingImplementation._wrap(raw);
  }

  static DOMSettableTokenList wrapDOMSettableTokenList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMSettableTokenListWrappingImplementation._wrap(raw);
  }

  static DOMTokenList wrapDOMTokenList(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "DOMSettableTokenList":
        return new DOMSettableTokenListWrappingImplementation._wrap(raw);
      case "DOMTokenList":
        return new DOMTokenListWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static DOMURL wrapDOMURL(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DOMURLWrappingImplementation._wrap(raw);
  }

  static DataListElement wrapDataListElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DataListElementWrappingImplementation._wrap(raw);
  }

  static DataTransferItem wrapDataTransferItem(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DataTransferItemWrappingImplementation._wrap(raw);
  }

  static DataTransferItemList wrapDataTransferItemList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DataTransferItemListWrappingImplementation._wrap(raw);
  }

  static DataView wrapDataView(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DataViewWrappingImplementation._wrap(raw);
  }

  // Skipped DatabaseCallback
  static DelayNode wrapDelayNode(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DelayNodeWrappingImplementation._wrap(raw);
  }

  static DetailsElement wrapDetailsElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DetailsElementWrappingImplementation._wrap(raw);
  }

  static DeviceMotionEvent wrapDeviceMotionEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DeviceMotionEventWrappingImplementation._wrap(raw);
  }

  static DeviceOrientationEvent wrapDeviceOrientationEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DeviceOrientationEventWrappingImplementation._wrap(raw);
  }

  static DirectoryEntry wrapDirectoryEntry(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DirectoryEntryWrappingImplementation._wrap(raw);
  }

  static DirectoryEntrySync wrapDirectoryEntrySync(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DirectoryEntrySyncWrappingImplementation._wrap(raw);
  }

  static DirectoryReader wrapDirectoryReader(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DirectoryReaderWrappingImplementation._wrap(raw);
  }

  static DirectoryReaderSync wrapDirectoryReaderSync(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DirectoryReaderSyncWrappingImplementation._wrap(raw);
  }

  static DivElement wrapDivElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DivElementWrappingImplementation._wrap(raw);
  }

  static Document wrapDocument(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "HTMLDocument":
        return new DocumentWrappingImplementation._wrap(raw, raw.documentElement);
      case "SVGDocument":
        return new SVGDocumentWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static DocumentFragment wrapDocumentFragment(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DocumentFragmentWrappingImplementation._wrap(raw);
  }

  static DynamicsCompressorNode wrapDynamicsCompressorNode(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new DynamicsCompressorNodeWrappingImplementation._wrap(raw);
  }

  static Element wrapElement(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "HTMLAnchorElement":
        return new AnchorElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLAppletElement*/
      case "HTMLAreaElement":
        return new AreaElementWrappingImplementation._wrap(raw);
      case "HTMLAudioElement":
        return new AudioElementWrappingImplementation._wrap(raw);
      case "HTMLBRElement":
        return new BRElementWrappingImplementation._wrap(raw);
      case "HTMLBaseElement":
        return new BaseElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLBaseFontElement*/
      case "HTMLBodyElement":
        return new BodyElementWrappingImplementation._wrap(raw);
      case "HTMLButtonElement":
        return new ButtonElementWrappingImplementation._wrap(raw);
      case "HTMLCanvasElement":
        return new CanvasElementWrappingImplementation._wrap(raw);
      case "HTMLDListElement":
        return new DListElementWrappingImplementation._wrap(raw);
      case "HTMLDataListElement":
        return new DataListElementWrappingImplementation._wrap(raw);
      case "HTMLDetailsElement":
        return new DetailsElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLDirectoryElement*/
      case "HTMLDivElement":
        return new DivElementWrappingImplementation._wrap(raw);
      case "HTMLElement":
        return new ElementWrappingImplementation._wrap(raw);
      case "HTMLEmbedElement":
        return new EmbedElementWrappingImplementation._wrap(raw);
      case "HTMLFieldSetElement":
        return new FieldSetElementWrappingImplementation._wrap(raw);
      case "HTMLFontElement":
        return new FontElementWrappingImplementation._wrap(raw);
      case "HTMLFormElement":
        return new FormElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLFrameElement*/
      /* Skipping HTMLFrameSetElement*/
      case "HTMLHRElement":
        return new HRElementWrappingImplementation._wrap(raw);
      case "HTMLHeadElement":
        return new HeadElementWrappingImplementation._wrap(raw);
      case "HTMLHeadingElement":
        return new HeadingElementWrappingImplementation._wrap(raw);
      case "HTMLHtmlElement":
        return new DocumentWrappingImplementation._wrap(raw.parentNode, raw);
      case "HTMLIFrameElement":
        return new IFrameElementWrappingImplementation._wrap(raw);
      case "HTMLImageElement":
        return new ImageElementWrappingImplementation._wrap(raw);
      case "HTMLInputElement":
        return new InputElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLIsIndexElement*/
      case "HTMLKeygenElement":
        return new KeygenElementWrappingImplementation._wrap(raw);
      case "HTMLLIElement":
        return new LIElementWrappingImplementation._wrap(raw);
      case "HTMLLabelElement":
        return new LabelElementWrappingImplementation._wrap(raw);
      case "HTMLLegendElement":
        return new LegendElementWrappingImplementation._wrap(raw);
      case "HTMLLinkElement":
        return new LinkElementWrappingImplementation._wrap(raw);
      case "HTMLMapElement":
        return new MapElementWrappingImplementation._wrap(raw);
      case "HTMLMarqueeElement":
        return new MarqueeElementWrappingImplementation._wrap(raw);
      case "HTMLMediaElement":
        return new MediaElementWrappingImplementation._wrap(raw);
      case "HTMLMenuElement":
        return new MenuElementWrappingImplementation._wrap(raw);
      case "HTMLMetaElement":
        return new MetaElementWrappingImplementation._wrap(raw);
      case "HTMLMeterElement":
        return new MeterElementWrappingImplementation._wrap(raw);
      case "HTMLModElement":
        return new ModElementWrappingImplementation._wrap(raw);
      case "HTMLOListElement":
        return new OListElementWrappingImplementation._wrap(raw);
      case "HTMLObjectElement":
        return new ObjectElementWrappingImplementation._wrap(raw);
      case "HTMLOptGroupElement":
        return new OptGroupElementWrappingImplementation._wrap(raw);
      case "HTMLOptionElement":
        return new OptionElementWrappingImplementation._wrap(raw);
      case "HTMLOutputElement":
        return new OutputElementWrappingImplementation._wrap(raw);
      case "HTMLParagraphElement":
        return new ParagraphElementWrappingImplementation._wrap(raw);
      case "HTMLParamElement":
        return new ParamElementWrappingImplementation._wrap(raw);
      case "HTMLPreElement":
        return new PreElementWrappingImplementation._wrap(raw);
      case "HTMLProgressElement":
        return new ProgressElementWrappingImplementation._wrap(raw);
      case "HTMLQuoteElement":
        return new QuoteElementWrappingImplementation._wrap(raw);
      case "SVGAElement":
        return new SVGAElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphDefElement":
        return new SVGAltGlyphDefElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphElement":
        return new SVGAltGlyphElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphItemElement":
        return new SVGAltGlyphItemElementWrappingImplementation._wrap(raw);
      case "SVGAnimateColorElement":
        return new SVGAnimateColorElementWrappingImplementation._wrap(raw);
      case "SVGAnimateElement":
        return new SVGAnimateElementWrappingImplementation._wrap(raw);
      case "SVGAnimateMotionElement":
        return new SVGAnimateMotionElementWrappingImplementation._wrap(raw);
      case "SVGAnimateTransformElement":
        return new SVGAnimateTransformElementWrappingImplementation._wrap(raw);
      case "SVGAnimationElement":
        return new SVGAnimationElementWrappingImplementation._wrap(raw);
      case "SVGCircleElement":
        return new SVGCircleElementWrappingImplementation._wrap(raw);
      case "SVGClipPathElement":
        return new SVGClipPathElementWrappingImplementation._wrap(raw);
      case "SVGComponentTransferFunctionElement":
        return new SVGComponentTransferFunctionElementWrappingImplementation._wrap(raw);
      case "SVGCursorElement":
        return new SVGCursorElementWrappingImplementation._wrap(raw);
      case "SVGDefsElement":
        return new SVGDefsElementWrappingImplementation._wrap(raw);
      case "SVGDescElement":
        return new SVGDescElementWrappingImplementation._wrap(raw);
      case "SVGElement":
        return new SVGElementWrappingImplementation._wrap(raw);
      case "SVGEllipseElement":
        return new SVGEllipseElementWrappingImplementation._wrap(raw);
      case "SVGFEBlendElement":
        return new SVGFEBlendElementWrappingImplementation._wrap(raw);
      case "SVGFEColorMatrixElement":
        return new SVGFEColorMatrixElementWrappingImplementation._wrap(raw);
      case "SVGFEComponentTransferElement":
        return new SVGFEComponentTransferElementWrappingImplementation._wrap(raw);
      /* Skipping SVGFECompositeElement*/
      case "SVGFEConvolveMatrixElement":
        return new SVGFEConvolveMatrixElementWrappingImplementation._wrap(raw);
      case "SVGFEDiffuseLightingElement":
        return new SVGFEDiffuseLightingElementWrappingImplementation._wrap(raw);
      case "SVGFEDisplacementMapElement":
        return new SVGFEDisplacementMapElementWrappingImplementation._wrap(raw);
      case "SVGFEDistantLightElement":
        return new SVGFEDistantLightElementWrappingImplementation._wrap(raw);
      case "SVGFEDropShadowElement":
        return new SVGFEDropShadowElementWrappingImplementation._wrap(raw);
      case "SVGFEFloodElement":
        return new SVGFEFloodElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncAElement":
        return new SVGFEFuncAElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncBElement":
        return new SVGFEFuncBElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncGElement":
        return new SVGFEFuncGElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncRElement":
        return new SVGFEFuncRElementWrappingImplementation._wrap(raw);
      case "SVGFEGaussianBlurElement":
        return new SVGFEGaussianBlurElementWrappingImplementation._wrap(raw);
      case "SVGFEImageElement":
        return new SVGFEImageElementWrappingImplementation._wrap(raw);
      case "SVGFEMergeElement":
        return new SVGFEMergeElementWrappingImplementation._wrap(raw);
      case "SVGFEMergeNodeElement":
        return new SVGFEMergeNodeElementWrappingImplementation._wrap(raw);
      /* Skipping SVGFEMorphologyElement*/
      case "SVGFEOffsetElement":
        return new SVGFEOffsetElementWrappingImplementation._wrap(raw);
      case "SVGFEPointLightElement":
        return new SVGFEPointLightElementWrappingImplementation._wrap(raw);
      case "SVGFESpecularLightingElement":
        return new SVGFESpecularLightingElementWrappingImplementation._wrap(raw);
      case "SVGFESpotLightElement":
        return new SVGFESpotLightElementWrappingImplementation._wrap(raw);
      case "SVGFETileElement":
        return new SVGFETileElementWrappingImplementation._wrap(raw);
      case "SVGFETurbulenceElement":
        return new SVGFETurbulenceElementWrappingImplementation._wrap(raw);
      case "SVGFilterElement":
        return new SVGFilterElementWrappingImplementation._wrap(raw);
      case "SVGFontElement":
        return new SVGFontElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceElement":
        return new SVGFontFaceElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceFormatElement":
        return new SVGFontFaceFormatElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceNameElement":
        return new SVGFontFaceNameElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceSrcElement":
        return new SVGFontFaceSrcElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceUriElement":
        return new SVGFontFaceUriElementWrappingImplementation._wrap(raw);
      case "SVGForeignObjectElement":
        return new SVGForeignObjectElementWrappingImplementation._wrap(raw);
      case "SVGGElement":
        return new SVGGElementWrappingImplementation._wrap(raw);
      case "SVGGlyphElement":
        return new SVGGlyphElementWrappingImplementation._wrap(raw);
      case "SVGGlyphRefElement":
        return new SVGGlyphRefElementWrappingImplementation._wrap(raw);
      case "SVGGradientElement":
        return new SVGGradientElementWrappingImplementation._wrap(raw);
      case "SVGHKernElement":
        return new SVGHKernElementWrappingImplementation._wrap(raw);
      case "SVGImageElement":
        return new SVGImageElementWrappingImplementation._wrap(raw);
      case "SVGLineElement":
        return new SVGLineElementWrappingImplementation._wrap(raw);
      case "SVGLinearGradientElement":
        return new SVGLinearGradientElementWrappingImplementation._wrap(raw);
      case "SVGMPathElement":
        return new SVGMPathElementWrappingImplementation._wrap(raw);
      case "SVGMarkerElement":
        return new SVGMarkerElementWrappingImplementation._wrap(raw);
      case "SVGMaskElement":
        return new SVGMaskElementWrappingImplementation._wrap(raw);
      case "SVGMetadataElement":
        return new SVGMetadataElementWrappingImplementation._wrap(raw);
      case "SVGMissingGlyphElement":
        return new SVGMissingGlyphElementWrappingImplementation._wrap(raw);
      case "SVGPathElement":
        return new SVGPathElementWrappingImplementation._wrap(raw);
      case "SVGPatternElement":
        return new SVGPatternElementWrappingImplementation._wrap(raw);
      case "SVGPolygonElement":
        return new SVGPolygonElementWrappingImplementation._wrap(raw);
      case "SVGPolylineElement":
        return new SVGPolylineElementWrappingImplementation._wrap(raw);
      case "SVGRadialGradientElement":
        return new SVGRadialGradientElementWrappingImplementation._wrap(raw);
      case "SVGRectElement":
        return new SVGRectElementWrappingImplementation._wrap(raw);
      case "SVGSVGElement":
        return new SVGSVGElementWrappingImplementation._wrap(raw);
      case "SVGScriptElement":
        return new SVGScriptElementWrappingImplementation._wrap(raw);
      case "SVGSetElement":
        return new SVGSetElementWrappingImplementation._wrap(raw);
      case "SVGStopElement":
        return new SVGStopElementWrappingImplementation._wrap(raw);
      case "SVGStyleElement":
        return new SVGStyleElementWrappingImplementation._wrap(raw);
      case "SVGSwitchElement":
        return new SVGSwitchElementWrappingImplementation._wrap(raw);
      case "SVGSymbolElement":
        return new SVGSymbolElementWrappingImplementation._wrap(raw);
      case "SVGTRefElement":
        return new SVGTRefElementWrappingImplementation._wrap(raw);
      case "SVGTSpanElement":
        return new SVGTSpanElementWrappingImplementation._wrap(raw);
      case "SVGTextContentElement":
        return new SVGTextContentElementWrappingImplementation._wrap(raw);
      case "SVGTextElement":
        return new SVGTextElementWrappingImplementation._wrap(raw);
      case "SVGTextPathElement":
        return new SVGTextPathElementWrappingImplementation._wrap(raw);
      case "SVGTextPositioningElement":
        return new SVGTextPositioningElementWrappingImplementation._wrap(raw);
      case "SVGTitleElement":
        return new SVGTitleElementWrappingImplementation._wrap(raw);
      case "SVGUseElement":
        return new SVGUseElementWrappingImplementation._wrap(raw);
      case "SVGVKernElement":
        return new SVGVKernElementWrappingImplementation._wrap(raw);
      case "SVGViewElement":
        return new SVGViewElementWrappingImplementation._wrap(raw);
      case "HTMLScriptElement":
        return new ScriptElementWrappingImplementation._wrap(raw);
      case "HTMLSelectElement":
        return new SelectElementWrappingImplementation._wrap(raw);
      case "HTMLSourceElement":
        return new SourceElementWrappingImplementation._wrap(raw);
      case "HTMLSpanElement":
        return new SpanElementWrappingImplementation._wrap(raw);
      case "HTMLStyleElement":
        return new StyleElementWrappingImplementation._wrap(raw);
      case "HTMLTableCaptionElement":
        return new TableCaptionElementWrappingImplementation._wrap(raw);
      case "HTMLTableCellElement":
        return new TableCellElementWrappingImplementation._wrap(raw);
      case "HTMLTableColElement":
        return new TableColElementWrappingImplementation._wrap(raw);
      case "HTMLTableElement":
        return new TableElementWrappingImplementation._wrap(raw);
      case "HTMLTableRowElement":
        return new TableRowElementWrappingImplementation._wrap(raw);
      case "HTMLTableSectionElement":
        return new TableSectionElementWrappingImplementation._wrap(raw);
      case "HTMLTextAreaElement":
        return new TextAreaElementWrappingImplementation._wrap(raw);
      case "HTMLTitleElement":
        return new TitleElementWrappingImplementation._wrap(raw);
      case "HTMLTrackElement":
        return new TrackElementWrappingImplementation._wrap(raw);
      case "HTMLUListElement":
        return new UListElementWrappingImplementation._wrap(raw);
      case "HTMLUnknownElement":
        return new UnknownElementWrappingImplementation._wrap(raw);
      case "HTMLVideoElement":
        return new VideoElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static ElementList wrapElementList(raw) {
    return raw === null ? null : new FrozenElementList._wrap(raw);
  }

  static ElementTimeControl wrapElementTimeControl(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "ElementTimeControl":
        return new ElementTimeControlWrappingImplementation._wrap(raw);
      case "SVGAnimateColorElement":
        return new SVGAnimateColorElementWrappingImplementation._wrap(raw);
      case "SVGAnimateElement":
        return new SVGAnimateElementWrappingImplementation._wrap(raw);
      case "SVGAnimateMotionElement":
        return new SVGAnimateMotionElementWrappingImplementation._wrap(raw);
      case "SVGAnimateTransformElement":
        return new SVGAnimateTransformElementWrappingImplementation._wrap(raw);
      case "SVGAnimationElement":
        return new SVGAnimationElementWrappingImplementation._wrap(raw);
      case "SVGSetElement":
        return new SVGSetElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static EmbedElement wrapEmbedElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new EmbedElementWrappingImplementation._wrap(raw);
  }

  static Entity wrapEntity(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new EntityWrappingImplementation._wrap(raw);
  }

  static EntityReference wrapEntityReference(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new EntityReferenceWrappingImplementation._wrap(raw);
  }

  // Skipped EntriesCallback
  static Entry wrapEntry(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "DirectoryEntry":
        return new DirectoryEntryWrappingImplementation._wrap(raw);
      case "Entry":
        return new EntryWrappingImplementation._wrap(raw);
      case "FileEntry":
        return new FileEntryWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static EntryArray wrapEntryArray(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new EntryArrayWrappingImplementation._wrap(raw);
  }

  static EntryArraySync wrapEntryArraySync(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new EntryArraySyncWrappingImplementation._wrap(raw);
  }

  // Skipped EntryCallback
  static EntrySync wrapEntrySync(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "DirectoryEntrySync":
        return new DirectoryEntrySyncWrappingImplementation._wrap(raw);
      case "EntrySync":
        return new EntrySyncWrappingImplementation._wrap(raw);
      case "FileEntrySync":
        return new FileEntrySyncWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  // Skipped ErrorCallback
  static ErrorEvent wrapErrorEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ErrorEventWrappingImplementation._wrap(raw);
  }

  static Event wrapEvent(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "WebKitAnimationEvent":
        return new AnimationEventWrappingImplementation._wrap(raw);
      case "AudioProcessingEvent":
        return new AudioProcessingEventWrappingImplementation._wrap(raw);
      case "BeforeLoadEvent":
        return new BeforeLoadEventWrappingImplementation._wrap(raw);
      case "CloseEvent":
        return new CloseEventWrappingImplementation._wrap(raw);
      case "CompositionEvent":
        return new CompositionEventWrappingImplementation._wrap(raw);
      case "CustomEvent":
        return new CustomEventWrappingImplementation._wrap(raw);
      case "DeviceMotionEvent":
        return new DeviceMotionEventWrappingImplementation._wrap(raw);
      case "DeviceOrientationEvent":
        return new DeviceOrientationEventWrappingImplementation._wrap(raw);
      case "ErrorEvent":
        return new ErrorEventWrappingImplementation._wrap(raw);
      case "Event":
        return new EventWrappingImplementation._wrap(raw);
      case "HashChangeEvent":
        return new HashChangeEventWrappingImplementation._wrap(raw);
      case "IDBVersionChangeEvent":
        return new IDBVersionChangeEventWrappingImplementation._wrap(raw);
      case "KeyboardEvent":
        return new KeyboardEventWrappingImplementation._wrap(raw);
      case "MessageEvent":
        return new MessageEventWrappingImplementation._wrap(raw);
      case "MouseEvent":
        return new MouseEventWrappingImplementation._wrap(raw);
      case "MutationEvent":
        return new MutationEventWrappingImplementation._wrap(raw);
      case "OfflineAudioCompletionEvent":
        return new OfflineAudioCompletionEventWrappingImplementation._wrap(raw);
      case "OverflowEvent":
        return new OverflowEventWrappingImplementation._wrap(raw);
      case "PageTransitionEvent":
        return new PageTransitionEventWrappingImplementation._wrap(raw);
      case "PopStateEvent":
        return new PopStateEventWrappingImplementation._wrap(raw);
      case "ProgressEvent":
        return new ProgressEventWrappingImplementation._wrap(raw);
      case "SVGZoomEvent":
        return new SVGZoomEventWrappingImplementation._wrap(raw);
      case "SpeechInputEvent":
        return new SpeechInputEventWrappingImplementation._wrap(raw);
      case "StorageEvent":
        return new StorageEventWrappingImplementation._wrap(raw);
      case "TextEvent":
        return new TextEventWrappingImplementation._wrap(raw);
      case "TouchEvent":
        return new TouchEventWrappingImplementation._wrap(raw);
      case "WebKitTransitionEvent":
        return new TransitionEventWrappingImplementation._wrap(raw);
      case "UIEvent":
        return new UIEventWrappingImplementation._wrap(raw);
      case "WebGLContextEvent":
        return new WebGLContextEventWrappingImplementation._wrap(raw);
      case "WheelEvent":
        return new WheelEventWrappingImplementation._wrap(raw);
      case "XMLHttpRequestProgressEvent":
        return new XMLHttpRequestProgressEventWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static EventException wrapEventException(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new EventExceptionWrappingImplementation._wrap(raw);
  }

  static Function wrapEventListener(raw) {
    return raw === null ? null : function(evt) { return raw(LevelDom.wrapEvent(evt)); };
  }

  static EventSource wrapEventSource(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new EventSourceWrappingImplementation._wrap(raw);
  }

  static EventTarget wrapEventTarget(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      /* Skipping AbstractWorker*/
      case "HTMLAnchorElement":
        return new AnchorElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLAppletElement*/
      case "HTMLAreaElement":
        return new AreaElementWrappingImplementation._wrap(raw);
      /* Skipping Attr*/
      case "HTMLAudioElement":
        return new AudioElementWrappingImplementation._wrap(raw);
      case "HTMLBRElement":
        return new BRElementWrappingImplementation._wrap(raw);
      case "HTMLBaseElement":
        return new BaseElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLBaseFontElement*/
      case "HTMLBodyElement":
        return new BodyElementWrappingImplementation._wrap(raw);
      case "HTMLButtonElement":
        return new ButtonElementWrappingImplementation._wrap(raw);
      case "CDATASection":
        return new CDATASectionWrappingImplementation._wrap(raw);
      case "HTMLCanvasElement":
        return new CanvasElementWrappingImplementation._wrap(raw);
      case "CharacterData":
        return new CharacterDataWrappingImplementation._wrap(raw);
      case "Comment":
        return new CommentWrappingImplementation._wrap(raw);
      case "HTMLDListElement":
        return new DListElementWrappingImplementation._wrap(raw);
      case "DOMApplicationCache":
        return new DOMApplicationCacheWrappingImplementation._wrap(raw);
      case "HTMLDataListElement":
        return new DataListElementWrappingImplementation._wrap(raw);
      case "HTMLDetailsElement":
        return new DetailsElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLDirectoryElement*/
      case "HTMLDivElement":
        return new DivElementWrappingImplementation._wrap(raw);
      case "HTMLDocument":
        return new DocumentWrappingImplementation._wrap(raw, raw.documentElement);
      case "DocumentFragment":
        return new DocumentFragmentWrappingImplementation._wrap(raw);
      /* Skipping DocumentType*/
      case "HTMLElement":
        return new ElementWrappingImplementation._wrap(raw);
      case "HTMLEmbedElement":
        return new EmbedElementWrappingImplementation._wrap(raw);
      case "Entity":
        return new EntityWrappingImplementation._wrap(raw);
      case "EntityReference":
        return new EntityReferenceWrappingImplementation._wrap(raw);
      case "EventSource":
        return new EventSourceWrappingImplementation._wrap(raw);
      case "EventTarget":
        return new EventTargetWrappingImplementation._wrap(raw);
      case "HTMLFieldSetElement":
        return new FieldSetElementWrappingImplementation._wrap(raw);
      case "HTMLFontElement":
        return new FontElementWrappingImplementation._wrap(raw);
      case "HTMLFormElement":
        return new FormElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLFrameElement*/
      /* Skipping HTMLFrameSetElement*/
      case "HTMLHRElement":
        return new HRElementWrappingImplementation._wrap(raw);
      case "HTMLHeadElement":
        return new HeadElementWrappingImplementation._wrap(raw);
      case "HTMLHeadingElement":
        return new HeadingElementWrappingImplementation._wrap(raw);
      case "HTMLHtmlElement":
        return new DocumentWrappingImplementation._wrap(raw.parentNode, raw);
      case "HTMLIFrameElement":
        return new IFrameElementWrappingImplementation._wrap(raw);
      case "HTMLImageElement":
        return new ImageElementWrappingImplementation._wrap(raw);
      case "HTMLInputElement":
        return new InputElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLIsIndexElement*/
      case "HTMLKeygenElement":
        return new KeygenElementWrappingImplementation._wrap(raw);
      case "HTMLLIElement":
        return new LIElementWrappingImplementation._wrap(raw);
      case "HTMLLabelElement":
        return new LabelElementWrappingImplementation._wrap(raw);
      case "HTMLLegendElement":
        return new LegendElementWrappingImplementation._wrap(raw);
      case "HTMLLinkElement":
        return new LinkElementWrappingImplementation._wrap(raw);
      case "HTMLMapElement":
        return new MapElementWrappingImplementation._wrap(raw);
      case "HTMLMarqueeElement":
        return new MarqueeElementWrappingImplementation._wrap(raw);
      case "HTMLMediaElement":
        return new MediaElementWrappingImplementation._wrap(raw);
      case "HTMLMenuElement":
        return new MenuElementWrappingImplementation._wrap(raw);
      case "MessagePort":
        return new MessagePortWrappingImplementation._wrap(raw);
      case "HTMLMetaElement":
        return new MetaElementWrappingImplementation._wrap(raw);
      case "HTMLMeterElement":
        return new MeterElementWrappingImplementation._wrap(raw);
      case "HTMLModElement":
        return new ModElementWrappingImplementation._wrap(raw);
      case "Node":
        return new NodeWrappingImplementation._wrap(raw);
      case "Notation":
        return new NotationWrappingImplementation._wrap(raw);
      case "Notification":
        return new NotificationWrappingImplementation._wrap(raw);
      case "HTMLOListElement":
        return new OListElementWrappingImplementation._wrap(raw);
      case "HTMLObjectElement":
        return new ObjectElementWrappingImplementation._wrap(raw);
      case "HTMLOptGroupElement":
        return new OptGroupElementWrappingImplementation._wrap(raw);
      case "HTMLOptionElement":
        return new OptionElementWrappingImplementation._wrap(raw);
      case "HTMLOutputElement":
        return new OutputElementWrappingImplementation._wrap(raw);
      case "HTMLParagraphElement":
        return new ParagraphElementWrappingImplementation._wrap(raw);
      case "HTMLParamElement":
        return new ParamElementWrappingImplementation._wrap(raw);
      case "HTMLPreElement":
        return new PreElementWrappingImplementation._wrap(raw);
      case "ProcessingInstruction":
        return new ProcessingInstructionWrappingImplementation._wrap(raw);
      case "HTMLProgressElement":
        return new ProgressElementWrappingImplementation._wrap(raw);
      case "HTMLQuoteElement":
        return new QuoteElementWrappingImplementation._wrap(raw);
      case "SVGAElement":
        return new SVGAElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphDefElement":
        return new SVGAltGlyphDefElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphElement":
        return new SVGAltGlyphElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphItemElement":
        return new SVGAltGlyphItemElementWrappingImplementation._wrap(raw);
      case "SVGAnimateColorElement":
        return new SVGAnimateColorElementWrappingImplementation._wrap(raw);
      case "SVGAnimateElement":
        return new SVGAnimateElementWrappingImplementation._wrap(raw);
      case "SVGAnimateMotionElement":
        return new SVGAnimateMotionElementWrappingImplementation._wrap(raw);
      case "SVGAnimateTransformElement":
        return new SVGAnimateTransformElementWrappingImplementation._wrap(raw);
      case "SVGAnimationElement":
        return new SVGAnimationElementWrappingImplementation._wrap(raw);
      case "SVGCircleElement":
        return new SVGCircleElementWrappingImplementation._wrap(raw);
      case "SVGClipPathElement":
        return new SVGClipPathElementWrappingImplementation._wrap(raw);
      case "SVGComponentTransferFunctionElement":
        return new SVGComponentTransferFunctionElementWrappingImplementation._wrap(raw);
      case "SVGCursorElement":
        return new SVGCursorElementWrappingImplementation._wrap(raw);
      case "SVGDefsElement":
        return new SVGDefsElementWrappingImplementation._wrap(raw);
      case "SVGDescElement":
        return new SVGDescElementWrappingImplementation._wrap(raw);
      case "SVGDocument":
        return new SVGDocumentWrappingImplementation._wrap(raw);
      case "SVGElement":
        return new SVGElementWrappingImplementation._wrap(raw);
      case "SVGElementInstance":
        return new SVGElementInstanceWrappingImplementation._wrap(raw);
      case "SVGEllipseElement":
        return new SVGEllipseElementWrappingImplementation._wrap(raw);
      case "SVGFEBlendElement":
        return new SVGFEBlendElementWrappingImplementation._wrap(raw);
      case "SVGFEColorMatrixElement":
        return new SVGFEColorMatrixElementWrappingImplementation._wrap(raw);
      case "SVGFEComponentTransferElement":
        return new SVGFEComponentTransferElementWrappingImplementation._wrap(raw);
      /* Skipping SVGFECompositeElement*/
      case "SVGFEConvolveMatrixElement":
        return new SVGFEConvolveMatrixElementWrappingImplementation._wrap(raw);
      case "SVGFEDiffuseLightingElement":
        return new SVGFEDiffuseLightingElementWrappingImplementation._wrap(raw);
      case "SVGFEDisplacementMapElement":
        return new SVGFEDisplacementMapElementWrappingImplementation._wrap(raw);
      case "SVGFEDistantLightElement":
        return new SVGFEDistantLightElementWrappingImplementation._wrap(raw);
      case "SVGFEDropShadowElement":
        return new SVGFEDropShadowElementWrappingImplementation._wrap(raw);
      case "SVGFEFloodElement":
        return new SVGFEFloodElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncAElement":
        return new SVGFEFuncAElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncBElement":
        return new SVGFEFuncBElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncGElement":
        return new SVGFEFuncGElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncRElement":
        return new SVGFEFuncRElementWrappingImplementation._wrap(raw);
      case "SVGFEGaussianBlurElement":
        return new SVGFEGaussianBlurElementWrappingImplementation._wrap(raw);
      case "SVGFEImageElement":
        return new SVGFEImageElementWrappingImplementation._wrap(raw);
      case "SVGFEMergeElement":
        return new SVGFEMergeElementWrappingImplementation._wrap(raw);
      case "SVGFEMergeNodeElement":
        return new SVGFEMergeNodeElementWrappingImplementation._wrap(raw);
      /* Skipping SVGFEMorphologyElement*/
      case "SVGFEOffsetElement":
        return new SVGFEOffsetElementWrappingImplementation._wrap(raw);
      case "SVGFEPointLightElement":
        return new SVGFEPointLightElementWrappingImplementation._wrap(raw);
      case "SVGFESpecularLightingElement":
        return new SVGFESpecularLightingElementWrappingImplementation._wrap(raw);
      case "SVGFESpotLightElement":
        return new SVGFESpotLightElementWrappingImplementation._wrap(raw);
      case "SVGFETileElement":
        return new SVGFETileElementWrappingImplementation._wrap(raw);
      case "SVGFETurbulenceElement":
        return new SVGFETurbulenceElementWrappingImplementation._wrap(raw);
      case "SVGFilterElement":
        return new SVGFilterElementWrappingImplementation._wrap(raw);
      case "SVGFontElement":
        return new SVGFontElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceElement":
        return new SVGFontFaceElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceFormatElement":
        return new SVGFontFaceFormatElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceNameElement":
        return new SVGFontFaceNameElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceSrcElement":
        return new SVGFontFaceSrcElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceUriElement":
        return new SVGFontFaceUriElementWrappingImplementation._wrap(raw);
      case "SVGForeignObjectElement":
        return new SVGForeignObjectElementWrappingImplementation._wrap(raw);
      case "SVGGElement":
        return new SVGGElementWrappingImplementation._wrap(raw);
      case "SVGGlyphElement":
        return new SVGGlyphElementWrappingImplementation._wrap(raw);
      case "SVGGlyphRefElement":
        return new SVGGlyphRefElementWrappingImplementation._wrap(raw);
      case "SVGGradientElement":
        return new SVGGradientElementWrappingImplementation._wrap(raw);
      case "SVGHKernElement":
        return new SVGHKernElementWrappingImplementation._wrap(raw);
      case "SVGImageElement":
        return new SVGImageElementWrappingImplementation._wrap(raw);
      case "SVGLineElement":
        return new SVGLineElementWrappingImplementation._wrap(raw);
      case "SVGLinearGradientElement":
        return new SVGLinearGradientElementWrappingImplementation._wrap(raw);
      case "SVGMPathElement":
        return new SVGMPathElementWrappingImplementation._wrap(raw);
      case "SVGMarkerElement":
        return new SVGMarkerElementWrappingImplementation._wrap(raw);
      case "SVGMaskElement":
        return new SVGMaskElementWrappingImplementation._wrap(raw);
      case "SVGMetadataElement":
        return new SVGMetadataElementWrappingImplementation._wrap(raw);
      case "SVGMissingGlyphElement":
        return new SVGMissingGlyphElementWrappingImplementation._wrap(raw);
      case "SVGPathElement":
        return new SVGPathElementWrappingImplementation._wrap(raw);
      case "SVGPatternElement":
        return new SVGPatternElementWrappingImplementation._wrap(raw);
      case "SVGPolygonElement":
        return new SVGPolygonElementWrappingImplementation._wrap(raw);
      case "SVGPolylineElement":
        return new SVGPolylineElementWrappingImplementation._wrap(raw);
      case "SVGRadialGradientElement":
        return new SVGRadialGradientElementWrappingImplementation._wrap(raw);
      case "SVGRectElement":
        return new SVGRectElementWrappingImplementation._wrap(raw);
      case "SVGSVGElement":
        return new SVGSVGElementWrappingImplementation._wrap(raw);
      case "SVGScriptElement":
        return new SVGScriptElementWrappingImplementation._wrap(raw);
      case "SVGSetElement":
        return new SVGSetElementWrappingImplementation._wrap(raw);
      case "SVGStopElement":
        return new SVGStopElementWrappingImplementation._wrap(raw);
      case "SVGStyleElement":
        return new SVGStyleElementWrappingImplementation._wrap(raw);
      case "SVGSwitchElement":
        return new SVGSwitchElementWrappingImplementation._wrap(raw);
      case "SVGSymbolElement":
        return new SVGSymbolElementWrappingImplementation._wrap(raw);
      case "SVGTRefElement":
        return new SVGTRefElementWrappingImplementation._wrap(raw);
      case "SVGTSpanElement":
        return new SVGTSpanElementWrappingImplementation._wrap(raw);
      case "SVGTextContentElement":
        return new SVGTextContentElementWrappingImplementation._wrap(raw);
      case "SVGTextElement":
        return new SVGTextElementWrappingImplementation._wrap(raw);
      case "SVGTextPathElement":
        return new SVGTextPathElementWrappingImplementation._wrap(raw);
      case "SVGTextPositioningElement":
        return new SVGTextPositioningElementWrappingImplementation._wrap(raw);
      case "SVGTitleElement":
        return new SVGTitleElementWrappingImplementation._wrap(raw);
      case "SVGUseElement":
        return new SVGUseElementWrappingImplementation._wrap(raw);
      case "SVGVKernElement":
        return new SVGVKernElementWrappingImplementation._wrap(raw);
      case "SVGViewElement":
        return new SVGViewElementWrappingImplementation._wrap(raw);
      case "HTMLScriptElement":
        return new ScriptElementWrappingImplementation._wrap(raw);
      case "HTMLSelectElement":
        return new SelectElementWrappingImplementation._wrap(raw);
      case "SharedWorker":
        return new SharedWorkerWrappingImplementation._wrap(raw);
      case "HTMLSourceElement":
        return new SourceElementWrappingImplementation._wrap(raw);
      case "HTMLSpanElement":
        return new SpanElementWrappingImplementation._wrap(raw);
      case "HTMLStyleElement":
        return new StyleElementWrappingImplementation._wrap(raw);
      case "HTMLTableCaptionElement":
        return new TableCaptionElementWrappingImplementation._wrap(raw);
      case "HTMLTableCellElement":
        return new TableCellElementWrappingImplementation._wrap(raw);
      case "HTMLTableColElement":
        return new TableColElementWrappingImplementation._wrap(raw);
      case "HTMLTableElement":
        return new TableElementWrappingImplementation._wrap(raw);
      case "HTMLTableRowElement":
        return new TableRowElementWrappingImplementation._wrap(raw);
      case "HTMLTableSectionElement":
        return new TableSectionElementWrappingImplementation._wrap(raw);
      case "Text":
        return new TextWrappingImplementation._wrap(raw);
      case "HTMLTextAreaElement":
        return new TextAreaElementWrappingImplementation._wrap(raw);
      case "HTMLTitleElement":
        return new TitleElementWrappingImplementation._wrap(raw);
      case "HTMLTrackElement":
        return new TrackElementWrappingImplementation._wrap(raw);
      case "HTMLUListElement":
        return new UListElementWrappingImplementation._wrap(raw);
      case "HTMLUnknownElement":
        return new UnknownElementWrappingImplementation._wrap(raw);
      case "HTMLVideoElement":
        return new VideoElementWrappingImplementation._wrap(raw);
      case "WebSocket":
        return new WebSocketWrappingImplementation._wrap(raw);
      case "Window":
        return new WindowWrappingImplementation._wrap(raw);
      case "Worker":
        return new WorkerWrappingImplementation._wrap(raw);
      case "XMLHttpRequest":
        return new XMLHttpRequestWrappingImplementation._wrap(raw);
      case "XMLHttpRequestUpload":
        return new XMLHttpRequestUploadWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static FieldSetElement wrapFieldSetElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FieldSetElementWrappingImplementation._wrap(raw);
  }

  static File wrapFile(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileWrappingImplementation._wrap(raw);
  }

  // Skipped FileCallback
  static FileEntry wrapFileEntry(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileEntryWrappingImplementation._wrap(raw);
  }

  static FileEntrySync wrapFileEntrySync(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileEntrySyncWrappingImplementation._wrap(raw);
  }

  static FileError wrapFileError(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileErrorWrappingImplementation._wrap(raw);
  }

  static FileException wrapFileException(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileExceptionWrappingImplementation._wrap(raw);
  }

  static FileList wrapFileList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileListWrappingImplementation._wrap(raw);
  }

  static FileReader wrapFileReader(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileReaderWrappingImplementation._wrap(raw);
  }

  static FileReaderSync wrapFileReaderSync(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileReaderSyncWrappingImplementation._wrap(raw);
  }

  // Skipped FileSystemCallback
  static FileWriter wrapFileWriter(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileWriterWrappingImplementation._wrap(raw);
  }

  // Skipped FileWriterCallback
  static FileWriterSync wrapFileWriterSync(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FileWriterSyncWrappingImplementation._wrap(raw);
  }

  static Flags wrapFlags(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FlagsWrappingImplementation._wrap(raw);
  }

  static Float32Array wrapFloat32Array(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new Float32ArrayWrappingImplementation._wrap(raw);
  }

  static Float64Array wrapFloat64Array(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new Float64ArrayWrappingImplementation._wrap(raw);
  }

  static FontElement wrapFontElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FontElementWrappingImplementation._wrap(raw);
  }

  static FormElement wrapFormElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new FormElementWrappingImplementation._wrap(raw);
  }

  static Geolocation wrapGeolocation(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new GeolocationWrappingImplementation._wrap(raw);
  }

  static Geoposition wrapGeoposition(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new GeopositionWrappingImplementation._wrap(raw);
  }

  static HRElement wrapHRElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new HRElementWrappingImplementation._wrap(raw);
  }

  static HTMLAllCollection wrapHTMLAllCollection(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new HTMLAllCollectionWrappingImplementation._wrap(raw);
  }

  static HashChangeEvent wrapHashChangeEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new HashChangeEventWrappingImplementation._wrap(raw);
  }

  static HeadElement wrapHeadElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new HeadElementWrappingImplementation._wrap(raw);
  }

  static HeadingElement wrapHeadingElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new HeadingElementWrappingImplementation._wrap(raw);
  }

  static HighPass2FilterNode wrapHighPass2FilterNode(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new HighPass2FilterNodeWrappingImplementation._wrap(raw);
  }

  static History wrapHistory(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new HistoryWrappingImplementation._wrap(raw);
  }

  static IDBAny wrapIDBAny(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBAnyWrappingImplementation._wrap(raw);
  }

  static IDBCursor wrapIDBCursor(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "IDBCursor":
        return new IDBCursorWrappingImplementation._wrap(raw);
      case "IDBCursorWithValue":
        return new IDBCursorWithValueWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static IDBCursorWithValue wrapIDBCursorWithValue(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBCursorWithValueWrappingImplementation._wrap(raw);
  }

  static IDBDatabase wrapIDBDatabase(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBDatabaseWrappingImplementation._wrap(raw);
  }

  static IDBDatabaseError wrapIDBDatabaseError(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBDatabaseErrorWrappingImplementation._wrap(raw);
  }

  static IDBDatabaseException wrapIDBDatabaseException(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBDatabaseExceptionWrappingImplementation._wrap(raw);
  }

  static IDBFactory wrapIDBFactory(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBFactoryWrappingImplementation._wrap(raw);
  }

  static IDBIndex wrapIDBIndex(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBIndexWrappingImplementation._wrap(raw);
  }

  static IDBKey wrapIDBKey(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBKeyWrappingImplementation._wrap(raw);
  }

  static IDBKeyRange wrapIDBKeyRange(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBKeyRangeWrappingImplementation._wrap(raw);
  }

  static IDBObjectStore wrapIDBObjectStore(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBObjectStoreWrappingImplementation._wrap(raw);
  }

  static IDBRequest wrapIDBRequest(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "IDBRequest":
        return new IDBRequestWrappingImplementation._wrap(raw);
      case "IDBVersionChangeRequest":
        return new IDBVersionChangeRequestWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static IDBTransaction wrapIDBTransaction(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBTransactionWrappingImplementation._wrap(raw);
  }

  static IDBVersionChangeEvent wrapIDBVersionChangeEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBVersionChangeEventWrappingImplementation._wrap(raw);
  }

  static IDBVersionChangeRequest wrapIDBVersionChangeRequest(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IDBVersionChangeRequestWrappingImplementation._wrap(raw);
  }

  static IFrameElement wrapIFrameElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new IFrameElementWrappingImplementation._wrap(raw);
  }

  static ImageData wrapImageData(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ImageDataWrappingImplementation._wrap(raw);
  }

  static ImageElement wrapImageElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ImageElementWrappingImplementation._wrap(raw);
  }

  static InputElement wrapInputElement(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "HTMLInputElement":
        return new InputElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLIsIndexElement*/
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static Int16Array wrapInt16Array(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new Int16ArrayWrappingImplementation._wrap(raw);
  }

  static Int32Array wrapInt32Array(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new Int32ArrayWrappingImplementation._wrap(raw);
  }

  static Int8Array wrapInt8Array(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new Int8ArrayWrappingImplementation._wrap(raw);
  }

  static JavaScriptAudioNode wrapJavaScriptAudioNode(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new JavaScriptAudioNodeWrappingImplementation._wrap(raw);
  }

  static KeyboardEvent wrapKeyboardEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new KeyboardEventWrappingImplementation._wrap(raw);
  }

  static KeygenElement wrapKeygenElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new KeygenElementWrappingImplementation._wrap(raw);
  }

  static LIElement wrapLIElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new LIElementWrappingImplementation._wrap(raw);
  }

  static LabelElement wrapLabelElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new LabelElementWrappingImplementation._wrap(raw);
  }

  static LegendElement wrapLegendElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new LegendElementWrappingImplementation._wrap(raw);
  }

  static LinkElement wrapLinkElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new LinkElementWrappingImplementation._wrap(raw);
  }

  static Location wrapLocation(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new LocationWrappingImplementation._wrap(raw);
  }

  static LoseContext wrapLoseContext(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new LoseContextWrappingImplementation._wrap(raw);
  }

  static LowPass2FilterNode wrapLowPass2FilterNode(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new LowPass2FilterNodeWrappingImplementation._wrap(raw);
  }

  static MapElement wrapMapElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MapElementWrappingImplementation._wrap(raw);
  }

  static MarqueeElement wrapMarqueeElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MarqueeElementWrappingImplementation._wrap(raw);
  }

  static MediaElement wrapMediaElement(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "HTMLAudioElement":
        return new AudioElementWrappingImplementation._wrap(raw);
      case "HTMLMediaElement":
        return new MediaElementWrappingImplementation._wrap(raw);
      case "HTMLVideoElement":
        return new VideoElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static MediaElementAudioSourceNode wrapMediaElementAudioSourceNode(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MediaElementAudioSourceNodeWrappingImplementation._wrap(raw);
  }

  static MediaError wrapMediaError(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MediaErrorWrappingImplementation._wrap(raw);
  }

  static MediaList wrapMediaList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MediaListWrappingImplementation._wrap(raw);
  }

  static MediaQueryList wrapMediaQueryList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MediaQueryListWrappingImplementation._wrap(raw);
  }

  static MediaQueryListListener wrapMediaQueryListListener(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MediaQueryListListenerWrappingImplementation._wrap(raw);
  }

  static MenuElement wrapMenuElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MenuElementWrappingImplementation._wrap(raw);
  }

  static MessageChannel wrapMessageChannel(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MessageChannelWrappingImplementation._wrap(raw);
  }

  static MessageEvent wrapMessageEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MessageEventWrappingImplementation._wrap(raw);
  }

  static MessagePort wrapMessagePort(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MessagePortWrappingImplementation._wrap(raw);
  }

  static MetaElement wrapMetaElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MetaElementWrappingImplementation._wrap(raw);
  }

  static Metadata wrapMetadata(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MetadataWrappingImplementation._wrap(raw);
  }

  // Skipped MetadataCallback
  static MeterElement wrapMeterElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MeterElementWrappingImplementation._wrap(raw);
  }

  static ModElement wrapModElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ModElementWrappingImplementation._wrap(raw);
  }

  static MouseEvent wrapMouseEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MouseEventWrappingImplementation._wrap(raw);
  }

  static MutationCallback wrapMutationCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MutationCallbackWrappingImplementation._wrap(raw);
  }

  static MutationEvent wrapMutationEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MutationEventWrappingImplementation._wrap(raw);
  }

  static MutationRecord wrapMutationRecord(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new MutationRecordWrappingImplementation._wrap(raw);
  }

  static Navigator wrapNavigator(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new NavigatorWrappingImplementation._wrap(raw);
  }

  static NavigatorUserMediaError wrapNavigatorUserMediaError(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new NavigatorUserMediaErrorWrappingImplementation._wrap(raw);
  }

  // Skipped NavigatorUserMediaErrorCallback
  static NavigatorUserMediaSuccessCallback wrapNavigatorUserMediaSuccessCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new NavigatorUserMediaSuccessCallbackWrappingImplementation._wrap(raw);
  }

  static Node wrapNode(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "HTMLAnchorElement":
        return new AnchorElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLAppletElement*/
      case "HTMLAreaElement":
        return new AreaElementWrappingImplementation._wrap(raw);
      /* Skipping Attr*/
      case "HTMLAudioElement":
        return new AudioElementWrappingImplementation._wrap(raw);
      case "HTMLBRElement":
        return new BRElementWrappingImplementation._wrap(raw);
      case "HTMLBaseElement":
        return new BaseElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLBaseFontElement*/
      case "HTMLBodyElement":
        return new BodyElementWrappingImplementation._wrap(raw);
      case "HTMLButtonElement":
        return new ButtonElementWrappingImplementation._wrap(raw);
      case "CDATASection":
        return new CDATASectionWrappingImplementation._wrap(raw);
      case "HTMLCanvasElement":
        return new CanvasElementWrappingImplementation._wrap(raw);
      case "CharacterData":
        return new CharacterDataWrappingImplementation._wrap(raw);
      case "Comment":
        return new CommentWrappingImplementation._wrap(raw);
      case "HTMLDListElement":
        return new DListElementWrappingImplementation._wrap(raw);
      case "HTMLDataListElement":
        return new DataListElementWrappingImplementation._wrap(raw);
      case "HTMLDetailsElement":
        return new DetailsElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLDirectoryElement*/
      case "HTMLDivElement":
        return new DivElementWrappingImplementation._wrap(raw);
      case "HTMLDocument":
        return new DocumentWrappingImplementation._wrap(raw, raw.documentElement);
      case "DocumentFragment":
        return new DocumentFragmentWrappingImplementation._wrap(raw);
      /* Skipping DocumentType*/
      case "HTMLElement":
        return new ElementWrappingImplementation._wrap(raw);
      case "HTMLEmbedElement":
        return new EmbedElementWrappingImplementation._wrap(raw);
      case "Entity":
        return new EntityWrappingImplementation._wrap(raw);
      case "EntityReference":
        return new EntityReferenceWrappingImplementation._wrap(raw);
      case "HTMLFieldSetElement":
        return new FieldSetElementWrappingImplementation._wrap(raw);
      case "HTMLFontElement":
        return new FontElementWrappingImplementation._wrap(raw);
      case "HTMLFormElement":
        return new FormElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLFrameElement*/
      /* Skipping HTMLFrameSetElement*/
      case "HTMLHRElement":
        return new HRElementWrappingImplementation._wrap(raw);
      case "HTMLHeadElement":
        return new HeadElementWrappingImplementation._wrap(raw);
      case "HTMLHeadingElement":
        return new HeadingElementWrappingImplementation._wrap(raw);
      case "HTMLHtmlElement":
        return new DocumentWrappingImplementation._wrap(raw.parentNode, raw);
      case "HTMLIFrameElement":
        return new IFrameElementWrappingImplementation._wrap(raw);
      case "HTMLImageElement":
        return new ImageElementWrappingImplementation._wrap(raw);
      case "HTMLInputElement":
        return new InputElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLIsIndexElement*/
      case "HTMLKeygenElement":
        return new KeygenElementWrappingImplementation._wrap(raw);
      case "HTMLLIElement":
        return new LIElementWrappingImplementation._wrap(raw);
      case "HTMLLabelElement":
        return new LabelElementWrappingImplementation._wrap(raw);
      case "HTMLLegendElement":
        return new LegendElementWrappingImplementation._wrap(raw);
      case "HTMLLinkElement":
        return new LinkElementWrappingImplementation._wrap(raw);
      case "HTMLMapElement":
        return new MapElementWrappingImplementation._wrap(raw);
      case "HTMLMarqueeElement":
        return new MarqueeElementWrappingImplementation._wrap(raw);
      case "HTMLMediaElement":
        return new MediaElementWrappingImplementation._wrap(raw);
      case "HTMLMenuElement":
        return new MenuElementWrappingImplementation._wrap(raw);
      case "HTMLMetaElement":
        return new MetaElementWrappingImplementation._wrap(raw);
      case "HTMLMeterElement":
        return new MeterElementWrappingImplementation._wrap(raw);
      case "HTMLModElement":
        return new ModElementWrappingImplementation._wrap(raw);
      case "Node":
        return new NodeWrappingImplementation._wrap(raw);
      case "Notation":
        return new NotationWrappingImplementation._wrap(raw);
      case "HTMLOListElement":
        return new OListElementWrappingImplementation._wrap(raw);
      case "HTMLObjectElement":
        return new ObjectElementWrappingImplementation._wrap(raw);
      case "HTMLOptGroupElement":
        return new OptGroupElementWrappingImplementation._wrap(raw);
      case "HTMLOptionElement":
        return new OptionElementWrappingImplementation._wrap(raw);
      case "HTMLOutputElement":
        return new OutputElementWrappingImplementation._wrap(raw);
      case "HTMLParagraphElement":
        return new ParagraphElementWrappingImplementation._wrap(raw);
      case "HTMLParamElement":
        return new ParamElementWrappingImplementation._wrap(raw);
      case "HTMLPreElement":
        return new PreElementWrappingImplementation._wrap(raw);
      case "ProcessingInstruction":
        return new ProcessingInstructionWrappingImplementation._wrap(raw);
      case "HTMLProgressElement":
        return new ProgressElementWrappingImplementation._wrap(raw);
      case "HTMLQuoteElement":
        return new QuoteElementWrappingImplementation._wrap(raw);
      case "SVGAElement":
        return new SVGAElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphDefElement":
        return new SVGAltGlyphDefElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphElement":
        return new SVGAltGlyphElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphItemElement":
        return new SVGAltGlyphItemElementWrappingImplementation._wrap(raw);
      case "SVGAnimateColorElement":
        return new SVGAnimateColorElementWrappingImplementation._wrap(raw);
      case "SVGAnimateElement":
        return new SVGAnimateElementWrappingImplementation._wrap(raw);
      case "SVGAnimateMotionElement":
        return new SVGAnimateMotionElementWrappingImplementation._wrap(raw);
      case "SVGAnimateTransformElement":
        return new SVGAnimateTransformElementWrappingImplementation._wrap(raw);
      case "SVGAnimationElement":
        return new SVGAnimationElementWrappingImplementation._wrap(raw);
      case "SVGCircleElement":
        return new SVGCircleElementWrappingImplementation._wrap(raw);
      case "SVGClipPathElement":
        return new SVGClipPathElementWrappingImplementation._wrap(raw);
      case "SVGComponentTransferFunctionElement":
        return new SVGComponentTransferFunctionElementWrappingImplementation._wrap(raw);
      case "SVGCursorElement":
        return new SVGCursorElementWrappingImplementation._wrap(raw);
      case "SVGDefsElement":
        return new SVGDefsElementWrappingImplementation._wrap(raw);
      case "SVGDescElement":
        return new SVGDescElementWrappingImplementation._wrap(raw);
      case "SVGDocument":
        return new SVGDocumentWrappingImplementation._wrap(raw);
      case "SVGElement":
        return new SVGElementWrappingImplementation._wrap(raw);
      case "SVGEllipseElement":
        return new SVGEllipseElementWrappingImplementation._wrap(raw);
      case "SVGFEBlendElement":
        return new SVGFEBlendElementWrappingImplementation._wrap(raw);
      case "SVGFEColorMatrixElement":
        return new SVGFEColorMatrixElementWrappingImplementation._wrap(raw);
      case "SVGFEComponentTransferElement":
        return new SVGFEComponentTransferElementWrappingImplementation._wrap(raw);
      /* Skipping SVGFECompositeElement*/
      case "SVGFEConvolveMatrixElement":
        return new SVGFEConvolveMatrixElementWrappingImplementation._wrap(raw);
      case "SVGFEDiffuseLightingElement":
        return new SVGFEDiffuseLightingElementWrappingImplementation._wrap(raw);
      case "SVGFEDisplacementMapElement":
        return new SVGFEDisplacementMapElementWrappingImplementation._wrap(raw);
      case "SVGFEDistantLightElement":
        return new SVGFEDistantLightElementWrappingImplementation._wrap(raw);
      case "SVGFEDropShadowElement":
        return new SVGFEDropShadowElementWrappingImplementation._wrap(raw);
      case "SVGFEFloodElement":
        return new SVGFEFloodElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncAElement":
        return new SVGFEFuncAElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncBElement":
        return new SVGFEFuncBElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncGElement":
        return new SVGFEFuncGElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncRElement":
        return new SVGFEFuncRElementWrappingImplementation._wrap(raw);
      case "SVGFEGaussianBlurElement":
        return new SVGFEGaussianBlurElementWrappingImplementation._wrap(raw);
      case "SVGFEImageElement":
        return new SVGFEImageElementWrappingImplementation._wrap(raw);
      case "SVGFEMergeElement":
        return new SVGFEMergeElementWrappingImplementation._wrap(raw);
      case "SVGFEMergeNodeElement":
        return new SVGFEMergeNodeElementWrappingImplementation._wrap(raw);
      /* Skipping SVGFEMorphologyElement*/
      case "SVGFEOffsetElement":
        return new SVGFEOffsetElementWrappingImplementation._wrap(raw);
      case "SVGFEPointLightElement":
        return new SVGFEPointLightElementWrappingImplementation._wrap(raw);
      case "SVGFESpecularLightingElement":
        return new SVGFESpecularLightingElementWrappingImplementation._wrap(raw);
      case "SVGFESpotLightElement":
        return new SVGFESpotLightElementWrappingImplementation._wrap(raw);
      case "SVGFETileElement":
        return new SVGFETileElementWrappingImplementation._wrap(raw);
      case "SVGFETurbulenceElement":
        return new SVGFETurbulenceElementWrappingImplementation._wrap(raw);
      case "SVGFilterElement":
        return new SVGFilterElementWrappingImplementation._wrap(raw);
      case "SVGFontElement":
        return new SVGFontElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceElement":
        return new SVGFontFaceElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceFormatElement":
        return new SVGFontFaceFormatElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceNameElement":
        return new SVGFontFaceNameElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceSrcElement":
        return new SVGFontFaceSrcElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceUriElement":
        return new SVGFontFaceUriElementWrappingImplementation._wrap(raw);
      case "SVGForeignObjectElement":
        return new SVGForeignObjectElementWrappingImplementation._wrap(raw);
      case "SVGGElement":
        return new SVGGElementWrappingImplementation._wrap(raw);
      case "SVGGlyphElement":
        return new SVGGlyphElementWrappingImplementation._wrap(raw);
      case "SVGGlyphRefElement":
        return new SVGGlyphRefElementWrappingImplementation._wrap(raw);
      case "SVGGradientElement":
        return new SVGGradientElementWrappingImplementation._wrap(raw);
      case "SVGHKernElement":
        return new SVGHKernElementWrappingImplementation._wrap(raw);
      case "SVGImageElement":
        return new SVGImageElementWrappingImplementation._wrap(raw);
      case "SVGLineElement":
        return new SVGLineElementWrappingImplementation._wrap(raw);
      case "SVGLinearGradientElement":
        return new SVGLinearGradientElementWrappingImplementation._wrap(raw);
      case "SVGMPathElement":
        return new SVGMPathElementWrappingImplementation._wrap(raw);
      case "SVGMarkerElement":
        return new SVGMarkerElementWrappingImplementation._wrap(raw);
      case "SVGMaskElement":
        return new SVGMaskElementWrappingImplementation._wrap(raw);
      case "SVGMetadataElement":
        return new SVGMetadataElementWrappingImplementation._wrap(raw);
      case "SVGMissingGlyphElement":
        return new SVGMissingGlyphElementWrappingImplementation._wrap(raw);
      case "SVGPathElement":
        return new SVGPathElementWrappingImplementation._wrap(raw);
      case "SVGPatternElement":
        return new SVGPatternElementWrappingImplementation._wrap(raw);
      case "SVGPolygonElement":
        return new SVGPolygonElementWrappingImplementation._wrap(raw);
      case "SVGPolylineElement":
        return new SVGPolylineElementWrappingImplementation._wrap(raw);
      case "SVGRadialGradientElement":
        return new SVGRadialGradientElementWrappingImplementation._wrap(raw);
      case "SVGRectElement":
        return new SVGRectElementWrappingImplementation._wrap(raw);
      case "SVGSVGElement":
        return new SVGSVGElementWrappingImplementation._wrap(raw);
      case "SVGScriptElement":
        return new SVGScriptElementWrappingImplementation._wrap(raw);
      case "SVGSetElement":
        return new SVGSetElementWrappingImplementation._wrap(raw);
      case "SVGStopElement":
        return new SVGStopElementWrappingImplementation._wrap(raw);
      case "SVGStyleElement":
        return new SVGStyleElementWrappingImplementation._wrap(raw);
      case "SVGSwitchElement":
        return new SVGSwitchElementWrappingImplementation._wrap(raw);
      case "SVGSymbolElement":
        return new SVGSymbolElementWrappingImplementation._wrap(raw);
      case "SVGTRefElement":
        return new SVGTRefElementWrappingImplementation._wrap(raw);
      case "SVGTSpanElement":
        return new SVGTSpanElementWrappingImplementation._wrap(raw);
      case "SVGTextContentElement":
        return new SVGTextContentElementWrappingImplementation._wrap(raw);
      case "SVGTextElement":
        return new SVGTextElementWrappingImplementation._wrap(raw);
      case "SVGTextPathElement":
        return new SVGTextPathElementWrappingImplementation._wrap(raw);
      case "SVGTextPositioningElement":
        return new SVGTextPositioningElementWrappingImplementation._wrap(raw);
      case "SVGTitleElement":
        return new SVGTitleElementWrappingImplementation._wrap(raw);
      case "SVGUseElement":
        return new SVGUseElementWrappingImplementation._wrap(raw);
      case "SVGVKernElement":
        return new SVGVKernElementWrappingImplementation._wrap(raw);
      case "SVGViewElement":
        return new SVGViewElementWrappingImplementation._wrap(raw);
      case "HTMLScriptElement":
        return new ScriptElementWrappingImplementation._wrap(raw);
      case "HTMLSelectElement":
        return new SelectElementWrappingImplementation._wrap(raw);
      case "HTMLSourceElement":
        return new SourceElementWrappingImplementation._wrap(raw);
      case "HTMLSpanElement":
        return new SpanElementWrappingImplementation._wrap(raw);
      case "HTMLStyleElement":
        return new StyleElementWrappingImplementation._wrap(raw);
      case "HTMLTableCaptionElement":
        return new TableCaptionElementWrappingImplementation._wrap(raw);
      case "HTMLTableCellElement":
        return new TableCellElementWrappingImplementation._wrap(raw);
      case "HTMLTableColElement":
        return new TableColElementWrappingImplementation._wrap(raw);
      case "HTMLTableElement":
        return new TableElementWrappingImplementation._wrap(raw);
      case "HTMLTableRowElement":
        return new TableRowElementWrappingImplementation._wrap(raw);
      case "HTMLTableSectionElement":
        return new TableSectionElementWrappingImplementation._wrap(raw);
      case "Text":
        return new TextWrappingImplementation._wrap(raw);
      case "HTMLTextAreaElement":
        return new TextAreaElementWrappingImplementation._wrap(raw);
      case "HTMLTitleElement":
        return new TitleElementWrappingImplementation._wrap(raw);
      case "HTMLTrackElement":
        return new TrackElementWrappingImplementation._wrap(raw);
      case "HTMLUListElement":
        return new UListElementWrappingImplementation._wrap(raw);
      case "HTMLUnknownElement":
        return new UnknownElementWrappingImplementation._wrap(raw);
      case "HTMLVideoElement":
        return new VideoElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static Notation wrapNotation(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new NotationWrappingImplementation._wrap(raw);
  }

  static Notification wrapNotification(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new NotificationWrappingImplementation._wrap(raw);
  }

  static NotificationCenter wrapNotificationCenter(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new NotificationCenterWrappingImplementation._wrap(raw);
  }

  static OESStandardDerivatives wrapOESStandardDerivatives(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new OESStandardDerivativesWrappingImplementation._wrap(raw);
  }

  static OESTextureFloat wrapOESTextureFloat(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new OESTextureFloatWrappingImplementation._wrap(raw);
  }

  static OESVertexArrayObject wrapOESVertexArrayObject(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new OESVertexArrayObjectWrappingImplementation._wrap(raw);
  }

  static OListElement wrapOListElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new OListElementWrappingImplementation._wrap(raw);
  }

  static ObjectElement wrapObjectElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ObjectElementWrappingImplementation._wrap(raw);
  }

  static OfflineAudioCompletionEvent wrapOfflineAudioCompletionEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new OfflineAudioCompletionEventWrappingImplementation._wrap(raw);
  }

  static OperationNotAllowedException wrapOperationNotAllowedException(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new OperationNotAllowedExceptionWrappingImplementation._wrap(raw);
  }

  static OptGroupElement wrapOptGroupElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new OptGroupElementWrappingImplementation._wrap(raw);
  }

  static OptionElement wrapOptionElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new OptionElementWrappingImplementation._wrap(raw);
  }

  static OutputElement wrapOutputElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new OutputElementWrappingImplementation._wrap(raw);
  }

  static OverflowEvent wrapOverflowEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new OverflowEventWrappingImplementation._wrap(raw);
  }

  static PageTransitionEvent wrapPageTransitionEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new PageTransitionEventWrappingImplementation._wrap(raw);
  }

  static ParagraphElement wrapParagraphElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ParagraphElementWrappingImplementation._wrap(raw);
  }

  static ParamElement wrapParamElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ParamElementWrappingImplementation._wrap(raw);
  }

  static Point wrapPoint(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new PointWrappingImplementation._wrap(raw);
  }

  static PopStateEvent wrapPopStateEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new PopStateEventWrappingImplementation._wrap(raw);
  }

  // Skipped PositionCallback
  static PositionError wrapPositionError(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new PositionErrorWrappingImplementation._wrap(raw);
  }

  // Skipped PositionErrorCallback
  static PreElement wrapPreElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new PreElementWrappingImplementation._wrap(raw);
  }

  static ProcessingInstruction wrapProcessingInstruction(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ProcessingInstructionWrappingImplementation._wrap(raw);
  }

  static ProgressElement wrapProgressElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ProgressElementWrappingImplementation._wrap(raw);
  }

  static ProgressEvent wrapProgressEvent(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "ProgressEvent":
        return new ProgressEventWrappingImplementation._wrap(raw);
      case "XMLHttpRequestProgressEvent":
        return new XMLHttpRequestProgressEventWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static QuoteElement wrapQuoteElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new QuoteElementWrappingImplementation._wrap(raw);
  }

  static RGBColor wrapRGBColor(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new RGBColorWrappingImplementation._wrap(raw);
  }

  static Range wrapRange(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new RangeWrappingImplementation._wrap(raw);
  }

  static RangeException wrapRangeException(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new RangeExceptionWrappingImplementation._wrap(raw);
  }

  static RealtimeAnalyserNode wrapRealtimeAnalyserNode(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new RealtimeAnalyserNodeWrappingImplementation._wrap(raw);
  }

  static Rect wrapRect(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new RectWrappingImplementation._wrap(raw);
  }

  // Skipped RequestAnimationFrameCallback
  // Skipped SQLStatementCallback
  // Skipped SQLStatementErrorCallback
  // Skipped SQLTransactionCallback
  // Skipped SQLTransactionErrorCallback
  // Skipped SQLTransactionSyncCallback
  static SVGAElement wrapSVGAElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAElementWrappingImplementation._wrap(raw);
  }

  static SVGAltGlyphDefElement wrapSVGAltGlyphDefElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAltGlyphDefElementWrappingImplementation._wrap(raw);
  }

  static SVGAltGlyphElement wrapSVGAltGlyphElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAltGlyphElementWrappingImplementation._wrap(raw);
  }

  static SVGAltGlyphItemElement wrapSVGAltGlyphItemElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAltGlyphItemElementWrappingImplementation._wrap(raw);
  }

  static SVGAngle wrapSVGAngle(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAngleWrappingImplementation._wrap(raw);
  }

  static SVGAnimateColorElement wrapSVGAnimateColorElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAnimateColorElementWrappingImplementation._wrap(raw);
  }

  static SVGAnimateElement wrapSVGAnimateElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAnimateElementWrappingImplementation._wrap(raw);
  }

  static SVGAnimateMotionElement wrapSVGAnimateMotionElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAnimateMotionElementWrappingImplementation._wrap(raw);
  }

  static SVGAnimateTransformElement wrapSVGAnimateTransformElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAnimateTransformElementWrappingImplementation._wrap(raw);
  }

  static SVGAnimatedAngle wrapSVGAnimatedAngle(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAnimatedAngleWrappingImplementation._wrap(raw);
  }

  static SVGAnimatedBoolean wrapSVGAnimatedBoolean(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAnimatedBooleanWrappingImplementation._wrap(raw);
  }

  static SVGAnimatedEnumeration wrapSVGAnimatedEnumeration(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAnimatedEnumerationWrappingImplementation._wrap(raw);
  }

  static SVGAnimatedInteger wrapSVGAnimatedInteger(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAnimatedIntegerWrappingImplementation._wrap(raw);
  }

  static SVGAnimatedLength wrapSVGAnimatedLength(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAnimatedLengthWrappingImplementation._wrap(raw);
  }

  static SVGAnimatedLengthList wrapSVGAnimatedLengthList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAnimatedLengthListWrappingImplementation._wrap(raw);
  }

  static SVGAnimatedNumber wrapSVGAnimatedNumber(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAnimatedNumberWrappingImplementation._wrap(raw);
  }

  static SVGAnimatedNumberList wrapSVGAnimatedNumberList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAnimatedNumberListWrappingImplementation._wrap(raw);
  }

  static SVGAnimatedPreserveAspectRatio wrapSVGAnimatedPreserveAspectRatio(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAnimatedPreserveAspectRatioWrappingImplementation._wrap(raw);
  }

  static SVGAnimatedRect wrapSVGAnimatedRect(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAnimatedRectWrappingImplementation._wrap(raw);
  }

  static SVGAnimatedString wrapSVGAnimatedString(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAnimatedStringWrappingImplementation._wrap(raw);
  }

  static SVGAnimatedTransformList wrapSVGAnimatedTransformList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGAnimatedTransformListWrappingImplementation._wrap(raw);
  }

  static SVGAnimationElement wrapSVGAnimationElement(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGAnimateColorElement":
        return new SVGAnimateColorElementWrappingImplementation._wrap(raw);
      case "SVGAnimateElement":
        return new SVGAnimateElementWrappingImplementation._wrap(raw);
      case "SVGAnimateMotionElement":
        return new SVGAnimateMotionElementWrappingImplementation._wrap(raw);
      case "SVGAnimateTransformElement":
        return new SVGAnimateTransformElementWrappingImplementation._wrap(raw);
      case "SVGAnimationElement":
        return new SVGAnimationElementWrappingImplementation._wrap(raw);
      case "SVGSetElement":
        return new SVGSetElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGCircleElement wrapSVGCircleElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGCircleElementWrappingImplementation._wrap(raw);
  }

  static SVGClipPathElement wrapSVGClipPathElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGClipPathElementWrappingImplementation._wrap(raw);
  }

  static SVGColor wrapSVGColor(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGColor":
        return new SVGColorWrappingImplementation._wrap(raw);
      case "SVGPaint":
        return new SVGPaintWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGComponentTransferFunctionElement wrapSVGComponentTransferFunctionElement(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGComponentTransferFunctionElement":
        return new SVGComponentTransferFunctionElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncAElement":
        return new SVGFEFuncAElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncBElement":
        return new SVGFEFuncBElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncGElement":
        return new SVGFEFuncGElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncRElement":
        return new SVGFEFuncRElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGCursorElement wrapSVGCursorElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGCursorElementWrappingImplementation._wrap(raw);
  }

  static SVGDefsElement wrapSVGDefsElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGDefsElementWrappingImplementation._wrap(raw);
  }

  static SVGDescElement wrapSVGDescElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGDescElementWrappingImplementation._wrap(raw);
  }

  static SVGDocument wrapSVGDocument(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGDocumentWrappingImplementation._wrap(raw);
  }

  static SVGElement wrapSVGElement(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGAElement":
        return new SVGAElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphDefElement":
        return new SVGAltGlyphDefElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphElement":
        return new SVGAltGlyphElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphItemElement":
        return new SVGAltGlyphItemElementWrappingImplementation._wrap(raw);
      case "SVGAnimateColorElement":
        return new SVGAnimateColorElementWrappingImplementation._wrap(raw);
      case "SVGAnimateElement":
        return new SVGAnimateElementWrappingImplementation._wrap(raw);
      case "SVGAnimateMotionElement":
        return new SVGAnimateMotionElementWrappingImplementation._wrap(raw);
      case "SVGAnimateTransformElement":
        return new SVGAnimateTransformElementWrappingImplementation._wrap(raw);
      case "SVGAnimationElement":
        return new SVGAnimationElementWrappingImplementation._wrap(raw);
      case "SVGCircleElement":
        return new SVGCircleElementWrappingImplementation._wrap(raw);
      case "SVGClipPathElement":
        return new SVGClipPathElementWrappingImplementation._wrap(raw);
      case "SVGComponentTransferFunctionElement":
        return new SVGComponentTransferFunctionElementWrappingImplementation._wrap(raw);
      case "SVGCursorElement":
        return new SVGCursorElementWrappingImplementation._wrap(raw);
      case "SVGDefsElement":
        return new SVGDefsElementWrappingImplementation._wrap(raw);
      case "SVGDescElement":
        return new SVGDescElementWrappingImplementation._wrap(raw);
      case "SVGElement":
        return new SVGElementWrappingImplementation._wrap(raw);
      case "SVGEllipseElement":
        return new SVGEllipseElementWrappingImplementation._wrap(raw);
      case "SVGFEBlendElement":
        return new SVGFEBlendElementWrappingImplementation._wrap(raw);
      case "SVGFEColorMatrixElement":
        return new SVGFEColorMatrixElementWrappingImplementation._wrap(raw);
      case "SVGFEComponentTransferElement":
        return new SVGFEComponentTransferElementWrappingImplementation._wrap(raw);
      /* Skipping SVGFECompositeElement*/
      case "SVGFEConvolveMatrixElement":
        return new SVGFEConvolveMatrixElementWrappingImplementation._wrap(raw);
      case "SVGFEDiffuseLightingElement":
        return new SVGFEDiffuseLightingElementWrappingImplementation._wrap(raw);
      case "SVGFEDisplacementMapElement":
        return new SVGFEDisplacementMapElementWrappingImplementation._wrap(raw);
      case "SVGFEDistantLightElement":
        return new SVGFEDistantLightElementWrappingImplementation._wrap(raw);
      case "SVGFEDropShadowElement":
        return new SVGFEDropShadowElementWrappingImplementation._wrap(raw);
      case "SVGFEFloodElement":
        return new SVGFEFloodElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncAElement":
        return new SVGFEFuncAElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncBElement":
        return new SVGFEFuncBElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncGElement":
        return new SVGFEFuncGElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncRElement":
        return new SVGFEFuncRElementWrappingImplementation._wrap(raw);
      case "SVGFEGaussianBlurElement":
        return new SVGFEGaussianBlurElementWrappingImplementation._wrap(raw);
      case "SVGFEImageElement":
        return new SVGFEImageElementWrappingImplementation._wrap(raw);
      case "SVGFEMergeElement":
        return new SVGFEMergeElementWrappingImplementation._wrap(raw);
      case "SVGFEMergeNodeElement":
        return new SVGFEMergeNodeElementWrappingImplementation._wrap(raw);
      /* Skipping SVGFEMorphologyElement*/
      case "SVGFEOffsetElement":
        return new SVGFEOffsetElementWrappingImplementation._wrap(raw);
      case "SVGFEPointLightElement":
        return new SVGFEPointLightElementWrappingImplementation._wrap(raw);
      case "SVGFESpecularLightingElement":
        return new SVGFESpecularLightingElementWrappingImplementation._wrap(raw);
      case "SVGFESpotLightElement":
        return new SVGFESpotLightElementWrappingImplementation._wrap(raw);
      case "SVGFETileElement":
        return new SVGFETileElementWrappingImplementation._wrap(raw);
      case "SVGFETurbulenceElement":
        return new SVGFETurbulenceElementWrappingImplementation._wrap(raw);
      case "SVGFilterElement":
        return new SVGFilterElementWrappingImplementation._wrap(raw);
      case "SVGFontElement":
        return new SVGFontElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceElement":
        return new SVGFontFaceElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceFormatElement":
        return new SVGFontFaceFormatElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceNameElement":
        return new SVGFontFaceNameElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceSrcElement":
        return new SVGFontFaceSrcElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceUriElement":
        return new SVGFontFaceUriElementWrappingImplementation._wrap(raw);
      case "SVGForeignObjectElement":
        return new SVGForeignObjectElementWrappingImplementation._wrap(raw);
      case "SVGGElement":
        return new SVGGElementWrappingImplementation._wrap(raw);
      case "SVGGlyphElement":
        return new SVGGlyphElementWrappingImplementation._wrap(raw);
      case "SVGGlyphRefElement":
        return new SVGGlyphRefElementWrappingImplementation._wrap(raw);
      case "SVGGradientElement":
        return new SVGGradientElementWrappingImplementation._wrap(raw);
      case "SVGHKernElement":
        return new SVGHKernElementWrappingImplementation._wrap(raw);
      case "SVGImageElement":
        return new SVGImageElementWrappingImplementation._wrap(raw);
      case "SVGLineElement":
        return new SVGLineElementWrappingImplementation._wrap(raw);
      case "SVGLinearGradientElement":
        return new SVGLinearGradientElementWrappingImplementation._wrap(raw);
      case "SVGMPathElement":
        return new SVGMPathElementWrappingImplementation._wrap(raw);
      case "SVGMarkerElement":
        return new SVGMarkerElementWrappingImplementation._wrap(raw);
      case "SVGMaskElement":
        return new SVGMaskElementWrappingImplementation._wrap(raw);
      case "SVGMetadataElement":
        return new SVGMetadataElementWrappingImplementation._wrap(raw);
      case "SVGMissingGlyphElement":
        return new SVGMissingGlyphElementWrappingImplementation._wrap(raw);
      case "SVGPathElement":
        return new SVGPathElementWrappingImplementation._wrap(raw);
      case "SVGPatternElement":
        return new SVGPatternElementWrappingImplementation._wrap(raw);
      case "SVGPolygonElement":
        return new SVGPolygonElementWrappingImplementation._wrap(raw);
      case "SVGPolylineElement":
        return new SVGPolylineElementWrappingImplementation._wrap(raw);
      case "SVGRadialGradientElement":
        return new SVGRadialGradientElementWrappingImplementation._wrap(raw);
      case "SVGRectElement":
        return new SVGRectElementWrappingImplementation._wrap(raw);
      case "SVGSVGElement":
        return new SVGSVGElementWrappingImplementation._wrap(raw);
      case "SVGScriptElement":
        return new SVGScriptElementWrappingImplementation._wrap(raw);
      case "SVGSetElement":
        return new SVGSetElementWrappingImplementation._wrap(raw);
      case "SVGStopElement":
        return new SVGStopElementWrappingImplementation._wrap(raw);
      case "SVGStyleElement":
        return new SVGStyleElementWrappingImplementation._wrap(raw);
      case "SVGSwitchElement":
        return new SVGSwitchElementWrappingImplementation._wrap(raw);
      case "SVGSymbolElement":
        return new SVGSymbolElementWrappingImplementation._wrap(raw);
      case "SVGTRefElement":
        return new SVGTRefElementWrappingImplementation._wrap(raw);
      case "SVGTSpanElement":
        return new SVGTSpanElementWrappingImplementation._wrap(raw);
      case "SVGTextContentElement":
        return new SVGTextContentElementWrappingImplementation._wrap(raw);
      case "SVGTextElement":
        return new SVGTextElementWrappingImplementation._wrap(raw);
      case "SVGTextPathElement":
        return new SVGTextPathElementWrappingImplementation._wrap(raw);
      case "SVGTextPositioningElement":
        return new SVGTextPositioningElementWrappingImplementation._wrap(raw);
      case "SVGTitleElement":
        return new SVGTitleElementWrappingImplementation._wrap(raw);
      case "SVGUseElement":
        return new SVGUseElementWrappingImplementation._wrap(raw);
      case "SVGVKernElement":
        return new SVGVKernElementWrappingImplementation._wrap(raw);
      case "SVGViewElement":
        return new SVGViewElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGElementInstance wrapSVGElementInstance(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGElementInstanceWrappingImplementation._wrap(raw);
  }

  static SVGElementInstanceList wrapSVGElementInstanceList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGElementInstanceListWrappingImplementation._wrap(raw);
  }

  static SVGEllipseElement wrapSVGEllipseElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGEllipseElementWrappingImplementation._wrap(raw);
  }

  static SVGException wrapSVGException(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGExceptionWrappingImplementation._wrap(raw);
  }

  static SVGExternalResourcesRequired wrapSVGExternalResourcesRequired(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGAElement":
        return new SVGAElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphElement":
        return new SVGAltGlyphElementWrappingImplementation._wrap(raw);
      case "SVGAnimateColorElement":
        return new SVGAnimateColorElementWrappingImplementation._wrap(raw);
      case "SVGAnimateElement":
        return new SVGAnimateElementWrappingImplementation._wrap(raw);
      case "SVGAnimateMotionElement":
        return new SVGAnimateMotionElementWrappingImplementation._wrap(raw);
      case "SVGAnimateTransformElement":
        return new SVGAnimateTransformElementWrappingImplementation._wrap(raw);
      case "SVGAnimationElement":
        return new SVGAnimationElementWrappingImplementation._wrap(raw);
      case "SVGCircleElement":
        return new SVGCircleElementWrappingImplementation._wrap(raw);
      case "SVGClipPathElement":
        return new SVGClipPathElementWrappingImplementation._wrap(raw);
      case "SVGCursorElement":
        return new SVGCursorElementWrappingImplementation._wrap(raw);
      case "SVGDefsElement":
        return new SVGDefsElementWrappingImplementation._wrap(raw);
      case "SVGEllipseElement":
        return new SVGEllipseElementWrappingImplementation._wrap(raw);
      case "SVGExternalResourcesRequired":
        return new SVGExternalResourcesRequiredWrappingImplementation._wrap(raw);
      case "SVGFEImageElement":
        return new SVGFEImageElementWrappingImplementation._wrap(raw);
      case "SVGFilterElement":
        return new SVGFilterElementWrappingImplementation._wrap(raw);
      case "SVGForeignObjectElement":
        return new SVGForeignObjectElementWrappingImplementation._wrap(raw);
      case "SVGGElement":
        return new SVGGElementWrappingImplementation._wrap(raw);
      case "SVGGradientElement":
        return new SVGGradientElementWrappingImplementation._wrap(raw);
      case "SVGImageElement":
        return new SVGImageElementWrappingImplementation._wrap(raw);
      case "SVGLineElement":
        return new SVGLineElementWrappingImplementation._wrap(raw);
      case "SVGLinearGradientElement":
        return new SVGLinearGradientElementWrappingImplementation._wrap(raw);
      case "SVGMPathElement":
        return new SVGMPathElementWrappingImplementation._wrap(raw);
      case "SVGMarkerElement":
        return new SVGMarkerElementWrappingImplementation._wrap(raw);
      case "SVGMaskElement":
        return new SVGMaskElementWrappingImplementation._wrap(raw);
      case "SVGPathElement":
        return new SVGPathElementWrappingImplementation._wrap(raw);
      case "SVGPatternElement":
        return new SVGPatternElementWrappingImplementation._wrap(raw);
      case "SVGPolygonElement":
        return new SVGPolygonElementWrappingImplementation._wrap(raw);
      case "SVGPolylineElement":
        return new SVGPolylineElementWrappingImplementation._wrap(raw);
      case "SVGRadialGradientElement":
        return new SVGRadialGradientElementWrappingImplementation._wrap(raw);
      case "SVGRectElement":
        return new SVGRectElementWrappingImplementation._wrap(raw);
      case "SVGSVGElement":
        return new SVGSVGElementWrappingImplementation._wrap(raw);
      case "SVGScriptElement":
        return new SVGScriptElementWrappingImplementation._wrap(raw);
      case "SVGSetElement":
        return new SVGSetElementWrappingImplementation._wrap(raw);
      case "SVGSwitchElement":
        return new SVGSwitchElementWrappingImplementation._wrap(raw);
      case "SVGSymbolElement":
        return new SVGSymbolElementWrappingImplementation._wrap(raw);
      case "SVGTRefElement":
        return new SVGTRefElementWrappingImplementation._wrap(raw);
      case "SVGTSpanElement":
        return new SVGTSpanElementWrappingImplementation._wrap(raw);
      case "SVGTextContentElement":
        return new SVGTextContentElementWrappingImplementation._wrap(raw);
      case "SVGTextElement":
        return new SVGTextElementWrappingImplementation._wrap(raw);
      case "SVGTextPathElement":
        return new SVGTextPathElementWrappingImplementation._wrap(raw);
      case "SVGTextPositioningElement":
        return new SVGTextPositioningElementWrappingImplementation._wrap(raw);
      case "SVGUseElement":
        return new SVGUseElementWrappingImplementation._wrap(raw);
      case "SVGViewElement":
        return new SVGViewElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGFEBlendElement wrapSVGFEBlendElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEBlendElementWrappingImplementation._wrap(raw);
  }

  static SVGFEColorMatrixElement wrapSVGFEColorMatrixElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEColorMatrixElementWrappingImplementation._wrap(raw);
  }

  static SVGFEComponentTransferElement wrapSVGFEComponentTransferElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEComponentTransferElementWrappingImplementation._wrap(raw);
  }

  static SVGFEConvolveMatrixElement wrapSVGFEConvolveMatrixElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEConvolveMatrixElementWrappingImplementation._wrap(raw);
  }

  static SVGFEDiffuseLightingElement wrapSVGFEDiffuseLightingElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEDiffuseLightingElementWrappingImplementation._wrap(raw);
  }

  static SVGFEDisplacementMapElement wrapSVGFEDisplacementMapElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEDisplacementMapElementWrappingImplementation._wrap(raw);
  }

  static SVGFEDistantLightElement wrapSVGFEDistantLightElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEDistantLightElementWrappingImplementation._wrap(raw);
  }

  static SVGFEDropShadowElement wrapSVGFEDropShadowElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEDropShadowElementWrappingImplementation._wrap(raw);
  }

  static SVGFEFloodElement wrapSVGFEFloodElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEFloodElementWrappingImplementation._wrap(raw);
  }

  static SVGFEFuncAElement wrapSVGFEFuncAElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEFuncAElementWrappingImplementation._wrap(raw);
  }

  static SVGFEFuncBElement wrapSVGFEFuncBElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEFuncBElementWrappingImplementation._wrap(raw);
  }

  static SVGFEFuncGElement wrapSVGFEFuncGElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEFuncGElementWrappingImplementation._wrap(raw);
  }

  static SVGFEFuncRElement wrapSVGFEFuncRElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEFuncRElementWrappingImplementation._wrap(raw);
  }

  static SVGFEGaussianBlurElement wrapSVGFEGaussianBlurElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEGaussianBlurElementWrappingImplementation._wrap(raw);
  }

  static SVGFEImageElement wrapSVGFEImageElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEImageElementWrappingImplementation._wrap(raw);
  }

  static SVGFEMergeElement wrapSVGFEMergeElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEMergeElementWrappingImplementation._wrap(raw);
  }

  static SVGFEMergeNodeElement wrapSVGFEMergeNodeElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEMergeNodeElementWrappingImplementation._wrap(raw);
  }

  static SVGFEOffsetElement wrapSVGFEOffsetElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEOffsetElementWrappingImplementation._wrap(raw);
  }

  static SVGFEPointLightElement wrapSVGFEPointLightElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFEPointLightElementWrappingImplementation._wrap(raw);
  }

  static SVGFESpecularLightingElement wrapSVGFESpecularLightingElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFESpecularLightingElementWrappingImplementation._wrap(raw);
  }

  static SVGFESpotLightElement wrapSVGFESpotLightElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFESpotLightElementWrappingImplementation._wrap(raw);
  }

  static SVGFETileElement wrapSVGFETileElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFETileElementWrappingImplementation._wrap(raw);
  }

  static SVGFETurbulenceElement wrapSVGFETurbulenceElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFETurbulenceElementWrappingImplementation._wrap(raw);
  }

  static SVGFilterElement wrapSVGFilterElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFilterElementWrappingImplementation._wrap(raw);
  }

  static SVGFilterPrimitiveStandardAttributes wrapSVGFilterPrimitiveStandardAttributes(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGFEBlendElement":
        return new SVGFEBlendElementWrappingImplementation._wrap(raw);
      case "SVGFEColorMatrixElement":
        return new SVGFEColorMatrixElementWrappingImplementation._wrap(raw);
      case "SVGFEComponentTransferElement":
        return new SVGFEComponentTransferElementWrappingImplementation._wrap(raw);
      /* Skipping SVGFECompositeElement*/
      case "SVGFEConvolveMatrixElement":
        return new SVGFEConvolveMatrixElementWrappingImplementation._wrap(raw);
      case "SVGFEDiffuseLightingElement":
        return new SVGFEDiffuseLightingElementWrappingImplementation._wrap(raw);
      case "SVGFEDisplacementMapElement":
        return new SVGFEDisplacementMapElementWrappingImplementation._wrap(raw);
      case "SVGFEDropShadowElement":
        return new SVGFEDropShadowElementWrappingImplementation._wrap(raw);
      case "SVGFEFloodElement":
        return new SVGFEFloodElementWrappingImplementation._wrap(raw);
      case "SVGFEGaussianBlurElement":
        return new SVGFEGaussianBlurElementWrappingImplementation._wrap(raw);
      case "SVGFEImageElement":
        return new SVGFEImageElementWrappingImplementation._wrap(raw);
      case "SVGFEMergeElement":
        return new SVGFEMergeElementWrappingImplementation._wrap(raw);
      /* Skipping SVGFEMorphologyElement*/
      case "SVGFEOffsetElement":
        return new SVGFEOffsetElementWrappingImplementation._wrap(raw);
      case "SVGFESpecularLightingElement":
        return new SVGFESpecularLightingElementWrappingImplementation._wrap(raw);
      case "SVGFETileElement":
        return new SVGFETileElementWrappingImplementation._wrap(raw);
      case "SVGFETurbulenceElement":
        return new SVGFETurbulenceElementWrappingImplementation._wrap(raw);
      case "SVGFilterPrimitiveStandardAttributes":
        return new SVGFilterPrimitiveStandardAttributesWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGFitToViewBox wrapSVGFitToViewBox(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGFitToViewBox":
        return new SVGFitToViewBoxWrappingImplementation._wrap(raw);
      case "SVGMarkerElement":
        return new SVGMarkerElementWrappingImplementation._wrap(raw);
      case "SVGPatternElement":
        return new SVGPatternElementWrappingImplementation._wrap(raw);
      case "SVGSVGElement":
        return new SVGSVGElementWrappingImplementation._wrap(raw);
      case "SVGSymbolElement":
        return new SVGSymbolElementWrappingImplementation._wrap(raw);
      case "SVGViewElement":
        return new SVGViewElementWrappingImplementation._wrap(raw);
      case "SVGViewSpec":
        return new SVGViewSpecWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGFontElement wrapSVGFontElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFontElementWrappingImplementation._wrap(raw);
  }

  static SVGFontFaceElement wrapSVGFontFaceElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFontFaceElementWrappingImplementation._wrap(raw);
  }

  static SVGFontFaceFormatElement wrapSVGFontFaceFormatElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFontFaceFormatElementWrappingImplementation._wrap(raw);
  }

  static SVGFontFaceNameElement wrapSVGFontFaceNameElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFontFaceNameElementWrappingImplementation._wrap(raw);
  }

  static SVGFontFaceSrcElement wrapSVGFontFaceSrcElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFontFaceSrcElementWrappingImplementation._wrap(raw);
  }

  static SVGFontFaceUriElement wrapSVGFontFaceUriElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGFontFaceUriElementWrappingImplementation._wrap(raw);
  }

  static SVGForeignObjectElement wrapSVGForeignObjectElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGForeignObjectElementWrappingImplementation._wrap(raw);
  }

  static SVGGElement wrapSVGGElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGGElementWrappingImplementation._wrap(raw);
  }

  static SVGGlyphElement wrapSVGGlyphElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGGlyphElementWrappingImplementation._wrap(raw);
  }

  static SVGGlyphRefElement wrapSVGGlyphRefElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGGlyphRefElementWrappingImplementation._wrap(raw);
  }

  static SVGGradientElement wrapSVGGradientElement(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGGradientElement":
        return new SVGGradientElementWrappingImplementation._wrap(raw);
      case "SVGLinearGradientElement":
        return new SVGLinearGradientElementWrappingImplementation._wrap(raw);
      case "SVGRadialGradientElement":
        return new SVGRadialGradientElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGHKernElement wrapSVGHKernElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGHKernElementWrappingImplementation._wrap(raw);
  }

  static SVGImageElement wrapSVGImageElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGImageElementWrappingImplementation._wrap(raw);
  }

  static SVGLangSpace wrapSVGLangSpace(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGAElement":
        return new SVGAElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphElement":
        return new SVGAltGlyphElementWrappingImplementation._wrap(raw);
      case "SVGCircleElement":
        return new SVGCircleElementWrappingImplementation._wrap(raw);
      case "SVGClipPathElement":
        return new SVGClipPathElementWrappingImplementation._wrap(raw);
      case "SVGDefsElement":
        return new SVGDefsElementWrappingImplementation._wrap(raw);
      case "SVGDescElement":
        return new SVGDescElementWrappingImplementation._wrap(raw);
      case "SVGEllipseElement":
        return new SVGEllipseElementWrappingImplementation._wrap(raw);
      case "SVGFEImageElement":
        return new SVGFEImageElementWrappingImplementation._wrap(raw);
      case "SVGFilterElement":
        return new SVGFilterElementWrappingImplementation._wrap(raw);
      case "SVGForeignObjectElement":
        return new SVGForeignObjectElementWrappingImplementation._wrap(raw);
      case "SVGGElement":
        return new SVGGElementWrappingImplementation._wrap(raw);
      case "SVGImageElement":
        return new SVGImageElementWrappingImplementation._wrap(raw);
      case "SVGLangSpace":
        return new SVGLangSpaceWrappingImplementation._wrap(raw);
      case "SVGLineElement":
        return new SVGLineElementWrappingImplementation._wrap(raw);
      case "SVGMarkerElement":
        return new SVGMarkerElementWrappingImplementation._wrap(raw);
      case "SVGMaskElement":
        return new SVGMaskElementWrappingImplementation._wrap(raw);
      case "SVGPathElement":
        return new SVGPathElementWrappingImplementation._wrap(raw);
      case "SVGPatternElement":
        return new SVGPatternElementWrappingImplementation._wrap(raw);
      case "SVGPolygonElement":
        return new SVGPolygonElementWrappingImplementation._wrap(raw);
      case "SVGPolylineElement":
        return new SVGPolylineElementWrappingImplementation._wrap(raw);
      case "SVGRectElement":
        return new SVGRectElementWrappingImplementation._wrap(raw);
      case "SVGSVGElement":
        return new SVGSVGElementWrappingImplementation._wrap(raw);
      case "SVGStyleElement":
        return new SVGStyleElementWrappingImplementation._wrap(raw);
      case "SVGSwitchElement":
        return new SVGSwitchElementWrappingImplementation._wrap(raw);
      case "SVGSymbolElement":
        return new SVGSymbolElementWrappingImplementation._wrap(raw);
      case "SVGTRefElement":
        return new SVGTRefElementWrappingImplementation._wrap(raw);
      case "SVGTSpanElement":
        return new SVGTSpanElementWrappingImplementation._wrap(raw);
      case "SVGTextContentElement":
        return new SVGTextContentElementWrappingImplementation._wrap(raw);
      case "SVGTextElement":
        return new SVGTextElementWrappingImplementation._wrap(raw);
      case "SVGTextPathElement":
        return new SVGTextPathElementWrappingImplementation._wrap(raw);
      case "SVGTextPositioningElement":
        return new SVGTextPositioningElementWrappingImplementation._wrap(raw);
      case "SVGTitleElement":
        return new SVGTitleElementWrappingImplementation._wrap(raw);
      case "SVGUseElement":
        return new SVGUseElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGLength wrapSVGLength(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGLengthWrappingImplementation._wrap(raw);
  }

  static SVGLengthList wrapSVGLengthList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGLengthListWrappingImplementation._wrap(raw);
  }

  static SVGLineElement wrapSVGLineElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGLineElementWrappingImplementation._wrap(raw);
  }

  static SVGLinearGradientElement wrapSVGLinearGradientElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGLinearGradientElementWrappingImplementation._wrap(raw);
  }

  static SVGLocatable wrapSVGLocatable(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGAElement":
        return new SVGAElementWrappingImplementation._wrap(raw);
      case "SVGCircleElement":
        return new SVGCircleElementWrappingImplementation._wrap(raw);
      case "SVGClipPathElement":
        return new SVGClipPathElementWrappingImplementation._wrap(raw);
      case "SVGDefsElement":
        return new SVGDefsElementWrappingImplementation._wrap(raw);
      case "SVGEllipseElement":
        return new SVGEllipseElementWrappingImplementation._wrap(raw);
      case "SVGForeignObjectElement":
        return new SVGForeignObjectElementWrappingImplementation._wrap(raw);
      case "SVGGElement":
        return new SVGGElementWrappingImplementation._wrap(raw);
      case "SVGImageElement":
        return new SVGImageElementWrappingImplementation._wrap(raw);
      case "SVGLineElement":
        return new SVGLineElementWrappingImplementation._wrap(raw);
      case "SVGLocatable":
        return new SVGLocatableWrappingImplementation._wrap(raw);
      case "SVGPathElement":
        return new SVGPathElementWrappingImplementation._wrap(raw);
      case "SVGPolygonElement":
        return new SVGPolygonElementWrappingImplementation._wrap(raw);
      case "SVGPolylineElement":
        return new SVGPolylineElementWrappingImplementation._wrap(raw);
      case "SVGRectElement":
        return new SVGRectElementWrappingImplementation._wrap(raw);
      case "SVGSVGElement":
        return new SVGSVGElementWrappingImplementation._wrap(raw);
      case "SVGSwitchElement":
        return new SVGSwitchElementWrappingImplementation._wrap(raw);
      case "SVGTextElement":
        return new SVGTextElementWrappingImplementation._wrap(raw);
      case "SVGTransformable":
        return new SVGTransformableWrappingImplementation._wrap(raw);
      case "SVGUseElement":
        return new SVGUseElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGMPathElement wrapSVGMPathElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGMPathElementWrappingImplementation._wrap(raw);
  }

  static SVGMarkerElement wrapSVGMarkerElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGMarkerElementWrappingImplementation._wrap(raw);
  }

  static SVGMaskElement wrapSVGMaskElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGMaskElementWrappingImplementation._wrap(raw);
  }

  static SVGMatrix wrapSVGMatrix(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGMatrixWrappingImplementation._wrap(raw);
  }

  static SVGMetadataElement wrapSVGMetadataElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGMetadataElementWrappingImplementation._wrap(raw);
  }

  static SVGMissingGlyphElement wrapSVGMissingGlyphElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGMissingGlyphElementWrappingImplementation._wrap(raw);
  }

  static SVGNumber wrapSVGNumber(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGNumberWrappingImplementation._wrap(raw);
  }

  static SVGNumberList wrapSVGNumberList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGNumberListWrappingImplementation._wrap(raw);
  }

  static SVGPaint wrapSVGPaint(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPaintWrappingImplementation._wrap(raw);
  }

  static SVGPathElement wrapSVGPathElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathElementWrappingImplementation._wrap(raw);
  }

  static SVGPathSeg wrapSVGPathSeg(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGPathSeg":
        return new SVGPathSegWrappingImplementation._wrap(raw);
      case "SVGPathSegArcAbs":
        return new SVGPathSegArcAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegArcRel":
        return new SVGPathSegArcRelWrappingImplementation._wrap(raw);
      case "SVGPathSegClosePath":
        return new SVGPathSegClosePathWrappingImplementation._wrap(raw);
      case "SVGPathSegCurvetoCubicAbs":
        return new SVGPathSegCurvetoCubicAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegCurvetoCubicRel":
        return new SVGPathSegCurvetoCubicRelWrappingImplementation._wrap(raw);
      case "SVGPathSegCurvetoCubicSmoothAbs":
        return new SVGPathSegCurvetoCubicSmoothAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegCurvetoCubicSmoothRel":
        return new SVGPathSegCurvetoCubicSmoothRelWrappingImplementation._wrap(raw);
      case "SVGPathSegCurvetoQuadraticAbs":
        return new SVGPathSegCurvetoQuadraticAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegCurvetoQuadraticRel":
        return new SVGPathSegCurvetoQuadraticRelWrappingImplementation._wrap(raw);
      case "SVGPathSegCurvetoQuadraticSmoothAbs":
        return new SVGPathSegCurvetoQuadraticSmoothAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegCurvetoQuadraticSmoothRel":
        return new SVGPathSegCurvetoQuadraticSmoothRelWrappingImplementation._wrap(raw);
      case "SVGPathSegLinetoAbs":
        return new SVGPathSegLinetoAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegLinetoHorizontalAbs":
        return new SVGPathSegLinetoHorizontalAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegLinetoHorizontalRel":
        return new SVGPathSegLinetoHorizontalRelWrappingImplementation._wrap(raw);
      case "SVGPathSegLinetoRel":
        return new SVGPathSegLinetoRelWrappingImplementation._wrap(raw);
      case "SVGPathSegLinetoVerticalAbs":
        return new SVGPathSegLinetoVerticalAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegLinetoVerticalRel":
        return new SVGPathSegLinetoVerticalRelWrappingImplementation._wrap(raw);
      case "SVGPathSegMovetoAbs":
        return new SVGPathSegMovetoAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegMovetoRel":
        return new SVGPathSegMovetoRelWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGPathSegArcAbs wrapSVGPathSegArcAbs(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegArcAbsWrappingImplementation._wrap(raw);
  }

  static SVGPathSegArcRel wrapSVGPathSegArcRel(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegArcRelWrappingImplementation._wrap(raw);
  }

  static SVGPathSegClosePath wrapSVGPathSegClosePath(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegClosePathWrappingImplementation._wrap(raw);
  }

  static SVGPathSegCurvetoCubicAbs wrapSVGPathSegCurvetoCubicAbs(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegCurvetoCubicAbsWrappingImplementation._wrap(raw);
  }

  static SVGPathSegCurvetoCubicRel wrapSVGPathSegCurvetoCubicRel(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegCurvetoCubicRelWrappingImplementation._wrap(raw);
  }

  static SVGPathSegCurvetoCubicSmoothAbs wrapSVGPathSegCurvetoCubicSmoothAbs(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegCurvetoCubicSmoothAbsWrappingImplementation._wrap(raw);
  }

  static SVGPathSegCurvetoCubicSmoothRel wrapSVGPathSegCurvetoCubicSmoothRel(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegCurvetoCubicSmoothRelWrappingImplementation._wrap(raw);
  }

  static SVGPathSegCurvetoQuadraticAbs wrapSVGPathSegCurvetoQuadraticAbs(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegCurvetoQuadraticAbsWrappingImplementation._wrap(raw);
  }

  static SVGPathSegCurvetoQuadraticRel wrapSVGPathSegCurvetoQuadraticRel(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegCurvetoQuadraticRelWrappingImplementation._wrap(raw);
  }

  static SVGPathSegCurvetoQuadraticSmoothAbs wrapSVGPathSegCurvetoQuadraticSmoothAbs(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegCurvetoQuadraticSmoothAbsWrappingImplementation._wrap(raw);
  }

  static SVGPathSegCurvetoQuadraticSmoothRel wrapSVGPathSegCurvetoQuadraticSmoothRel(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegCurvetoQuadraticSmoothRelWrappingImplementation._wrap(raw);
  }

  static SVGPathSegLinetoAbs wrapSVGPathSegLinetoAbs(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegLinetoAbsWrappingImplementation._wrap(raw);
  }

  static SVGPathSegLinetoHorizontalAbs wrapSVGPathSegLinetoHorizontalAbs(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegLinetoHorizontalAbsWrappingImplementation._wrap(raw);
  }

  static SVGPathSegLinetoHorizontalRel wrapSVGPathSegLinetoHorizontalRel(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegLinetoHorizontalRelWrappingImplementation._wrap(raw);
  }

  static SVGPathSegLinetoRel wrapSVGPathSegLinetoRel(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegLinetoRelWrappingImplementation._wrap(raw);
  }

  static SVGPathSegLinetoVerticalAbs wrapSVGPathSegLinetoVerticalAbs(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegLinetoVerticalAbsWrappingImplementation._wrap(raw);
  }

  static SVGPathSegLinetoVerticalRel wrapSVGPathSegLinetoVerticalRel(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegLinetoVerticalRelWrappingImplementation._wrap(raw);
  }

  static SVGPathSegList wrapSVGPathSegList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegListWrappingImplementation._wrap(raw);
  }

  static SVGPathSegMovetoAbs wrapSVGPathSegMovetoAbs(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegMovetoAbsWrappingImplementation._wrap(raw);
  }

  static SVGPathSegMovetoRel wrapSVGPathSegMovetoRel(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPathSegMovetoRelWrappingImplementation._wrap(raw);
  }

  static SVGPatternElement wrapSVGPatternElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPatternElementWrappingImplementation._wrap(raw);
  }

  static SVGPoint wrapSVGPoint(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPointWrappingImplementation._wrap(raw);
  }

  static SVGPointList wrapSVGPointList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPointListWrappingImplementation._wrap(raw);
  }

  static SVGPolygonElement wrapSVGPolygonElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPolygonElementWrappingImplementation._wrap(raw);
  }

  static SVGPolylineElement wrapSVGPolylineElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPolylineElementWrappingImplementation._wrap(raw);
  }

  static SVGPreserveAspectRatio wrapSVGPreserveAspectRatio(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGPreserveAspectRatioWrappingImplementation._wrap(raw);
  }

  static SVGRadialGradientElement wrapSVGRadialGradientElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGRadialGradientElementWrappingImplementation._wrap(raw);
  }

  static SVGRect wrapSVGRect(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGRectWrappingImplementation._wrap(raw);
  }

  static SVGRectElement wrapSVGRectElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGRectElementWrappingImplementation._wrap(raw);
  }

  static SVGRenderingIntent wrapSVGRenderingIntent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGRenderingIntentWrappingImplementation._wrap(raw);
  }

  static SVGSVGElement wrapSVGSVGElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGSVGElementWrappingImplementation._wrap(raw);
  }

  static SVGScriptElement wrapSVGScriptElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGScriptElementWrappingImplementation._wrap(raw);
  }

  static SVGSetElement wrapSVGSetElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGSetElementWrappingImplementation._wrap(raw);
  }

  static SVGStopElement wrapSVGStopElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGStopElementWrappingImplementation._wrap(raw);
  }

  static SVGStringList wrapSVGStringList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGStringListWrappingImplementation._wrap(raw);
  }

  static SVGStylable wrapSVGStylable(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGAElement":
        return new SVGAElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphElement":
        return new SVGAltGlyphElementWrappingImplementation._wrap(raw);
      case "SVGCircleElement":
        return new SVGCircleElementWrappingImplementation._wrap(raw);
      case "SVGClipPathElement":
        return new SVGClipPathElementWrappingImplementation._wrap(raw);
      case "SVGDefsElement":
        return new SVGDefsElementWrappingImplementation._wrap(raw);
      case "SVGDescElement":
        return new SVGDescElementWrappingImplementation._wrap(raw);
      case "SVGEllipseElement":
        return new SVGEllipseElementWrappingImplementation._wrap(raw);
      case "SVGFEBlendElement":
        return new SVGFEBlendElementWrappingImplementation._wrap(raw);
      case "SVGFEColorMatrixElement":
        return new SVGFEColorMatrixElementWrappingImplementation._wrap(raw);
      case "SVGFEComponentTransferElement":
        return new SVGFEComponentTransferElementWrappingImplementation._wrap(raw);
      /* Skipping SVGFECompositeElement*/
      case "SVGFEConvolveMatrixElement":
        return new SVGFEConvolveMatrixElementWrappingImplementation._wrap(raw);
      case "SVGFEDiffuseLightingElement":
        return new SVGFEDiffuseLightingElementWrappingImplementation._wrap(raw);
      case "SVGFEDisplacementMapElement":
        return new SVGFEDisplacementMapElementWrappingImplementation._wrap(raw);
      case "SVGFEDropShadowElement":
        return new SVGFEDropShadowElementWrappingImplementation._wrap(raw);
      case "SVGFEFloodElement":
        return new SVGFEFloodElementWrappingImplementation._wrap(raw);
      case "SVGFEGaussianBlurElement":
        return new SVGFEGaussianBlurElementWrappingImplementation._wrap(raw);
      case "SVGFEImageElement":
        return new SVGFEImageElementWrappingImplementation._wrap(raw);
      case "SVGFEMergeElement":
        return new SVGFEMergeElementWrappingImplementation._wrap(raw);
      /* Skipping SVGFEMorphologyElement*/
      case "SVGFEOffsetElement":
        return new SVGFEOffsetElementWrappingImplementation._wrap(raw);
      case "SVGFESpecularLightingElement":
        return new SVGFESpecularLightingElementWrappingImplementation._wrap(raw);
      case "SVGFETileElement":
        return new SVGFETileElementWrappingImplementation._wrap(raw);
      case "SVGFETurbulenceElement":
        return new SVGFETurbulenceElementWrappingImplementation._wrap(raw);
      case "SVGFilterElement":
        return new SVGFilterElementWrappingImplementation._wrap(raw);
      case "SVGFilterPrimitiveStandardAttributes":
        return new SVGFilterPrimitiveStandardAttributesWrappingImplementation._wrap(raw);
      case "SVGForeignObjectElement":
        return new SVGForeignObjectElementWrappingImplementation._wrap(raw);
      case "SVGGElement":
        return new SVGGElementWrappingImplementation._wrap(raw);
      case "SVGGlyphRefElement":
        return new SVGGlyphRefElementWrappingImplementation._wrap(raw);
      case "SVGGradientElement":
        return new SVGGradientElementWrappingImplementation._wrap(raw);
      case "SVGImageElement":
        return new SVGImageElementWrappingImplementation._wrap(raw);
      case "SVGLineElement":
        return new SVGLineElementWrappingImplementation._wrap(raw);
      case "SVGLinearGradientElement":
        return new SVGLinearGradientElementWrappingImplementation._wrap(raw);
      case "SVGMarkerElement":
        return new SVGMarkerElementWrappingImplementation._wrap(raw);
      case "SVGMaskElement":
        return new SVGMaskElementWrappingImplementation._wrap(raw);
      case "SVGPathElement":
        return new SVGPathElementWrappingImplementation._wrap(raw);
      case "SVGPatternElement":
        return new SVGPatternElementWrappingImplementation._wrap(raw);
      case "SVGPolygonElement":
        return new SVGPolygonElementWrappingImplementation._wrap(raw);
      case "SVGPolylineElement":
        return new SVGPolylineElementWrappingImplementation._wrap(raw);
      case "SVGRadialGradientElement":
        return new SVGRadialGradientElementWrappingImplementation._wrap(raw);
      case "SVGRectElement":
        return new SVGRectElementWrappingImplementation._wrap(raw);
      case "SVGSVGElement":
        return new SVGSVGElementWrappingImplementation._wrap(raw);
      case "SVGStopElement":
        return new SVGStopElementWrappingImplementation._wrap(raw);
      case "SVGStylable":
        return new SVGStylableWrappingImplementation._wrap(raw);
      case "SVGSwitchElement":
        return new SVGSwitchElementWrappingImplementation._wrap(raw);
      case "SVGSymbolElement":
        return new SVGSymbolElementWrappingImplementation._wrap(raw);
      case "SVGTRefElement":
        return new SVGTRefElementWrappingImplementation._wrap(raw);
      case "SVGTSpanElement":
        return new SVGTSpanElementWrappingImplementation._wrap(raw);
      case "SVGTextContentElement":
        return new SVGTextContentElementWrappingImplementation._wrap(raw);
      case "SVGTextElement":
        return new SVGTextElementWrappingImplementation._wrap(raw);
      case "SVGTextPathElement":
        return new SVGTextPathElementWrappingImplementation._wrap(raw);
      case "SVGTextPositioningElement":
        return new SVGTextPositioningElementWrappingImplementation._wrap(raw);
      case "SVGTitleElement":
        return new SVGTitleElementWrappingImplementation._wrap(raw);
      case "SVGUseElement":
        return new SVGUseElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGStyleElement wrapSVGStyleElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGStyleElementWrappingImplementation._wrap(raw);
  }

  static SVGSwitchElement wrapSVGSwitchElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGSwitchElementWrappingImplementation._wrap(raw);
  }

  static SVGSymbolElement wrapSVGSymbolElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGSymbolElementWrappingImplementation._wrap(raw);
  }

  static SVGTRefElement wrapSVGTRefElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGTRefElementWrappingImplementation._wrap(raw);
  }

  static SVGTSpanElement wrapSVGTSpanElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGTSpanElementWrappingImplementation._wrap(raw);
  }

  static SVGTests wrapSVGTests(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGAElement":
        return new SVGAElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphElement":
        return new SVGAltGlyphElementWrappingImplementation._wrap(raw);
      case "SVGAnimateColorElement":
        return new SVGAnimateColorElementWrappingImplementation._wrap(raw);
      case "SVGAnimateElement":
        return new SVGAnimateElementWrappingImplementation._wrap(raw);
      case "SVGAnimateMotionElement":
        return new SVGAnimateMotionElementWrappingImplementation._wrap(raw);
      case "SVGAnimateTransformElement":
        return new SVGAnimateTransformElementWrappingImplementation._wrap(raw);
      case "SVGAnimationElement":
        return new SVGAnimationElementWrappingImplementation._wrap(raw);
      case "SVGCircleElement":
        return new SVGCircleElementWrappingImplementation._wrap(raw);
      case "SVGClipPathElement":
        return new SVGClipPathElementWrappingImplementation._wrap(raw);
      case "SVGCursorElement":
        return new SVGCursorElementWrappingImplementation._wrap(raw);
      case "SVGDefsElement":
        return new SVGDefsElementWrappingImplementation._wrap(raw);
      case "SVGEllipseElement":
        return new SVGEllipseElementWrappingImplementation._wrap(raw);
      case "SVGForeignObjectElement":
        return new SVGForeignObjectElementWrappingImplementation._wrap(raw);
      case "SVGGElement":
        return new SVGGElementWrappingImplementation._wrap(raw);
      case "SVGImageElement":
        return new SVGImageElementWrappingImplementation._wrap(raw);
      case "SVGLineElement":
        return new SVGLineElementWrappingImplementation._wrap(raw);
      case "SVGMaskElement":
        return new SVGMaskElementWrappingImplementation._wrap(raw);
      case "SVGPathElement":
        return new SVGPathElementWrappingImplementation._wrap(raw);
      case "SVGPatternElement":
        return new SVGPatternElementWrappingImplementation._wrap(raw);
      case "SVGPolygonElement":
        return new SVGPolygonElementWrappingImplementation._wrap(raw);
      case "SVGPolylineElement":
        return new SVGPolylineElementWrappingImplementation._wrap(raw);
      case "SVGRectElement":
        return new SVGRectElementWrappingImplementation._wrap(raw);
      case "SVGSVGElement":
        return new SVGSVGElementWrappingImplementation._wrap(raw);
      case "SVGSetElement":
        return new SVGSetElementWrappingImplementation._wrap(raw);
      case "SVGSwitchElement":
        return new SVGSwitchElementWrappingImplementation._wrap(raw);
      case "SVGTRefElement":
        return new SVGTRefElementWrappingImplementation._wrap(raw);
      case "SVGTSpanElement":
        return new SVGTSpanElementWrappingImplementation._wrap(raw);
      case "SVGTests":
        return new SVGTestsWrappingImplementation._wrap(raw);
      case "SVGTextContentElement":
        return new SVGTextContentElementWrappingImplementation._wrap(raw);
      case "SVGTextElement":
        return new SVGTextElementWrappingImplementation._wrap(raw);
      case "SVGTextPathElement":
        return new SVGTextPathElementWrappingImplementation._wrap(raw);
      case "SVGTextPositioningElement":
        return new SVGTextPositioningElementWrappingImplementation._wrap(raw);
      case "SVGUseElement":
        return new SVGUseElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGTextContentElement wrapSVGTextContentElement(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGAltGlyphElement":
        return new SVGAltGlyphElementWrappingImplementation._wrap(raw);
      case "SVGTRefElement":
        return new SVGTRefElementWrappingImplementation._wrap(raw);
      case "SVGTSpanElement":
        return new SVGTSpanElementWrappingImplementation._wrap(raw);
      case "SVGTextContentElement":
        return new SVGTextContentElementWrappingImplementation._wrap(raw);
      case "SVGTextElement":
        return new SVGTextElementWrappingImplementation._wrap(raw);
      case "SVGTextPathElement":
        return new SVGTextPathElementWrappingImplementation._wrap(raw);
      case "SVGTextPositioningElement":
        return new SVGTextPositioningElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGTextElement wrapSVGTextElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGTextElementWrappingImplementation._wrap(raw);
  }

  static SVGTextPathElement wrapSVGTextPathElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGTextPathElementWrappingImplementation._wrap(raw);
  }

  static SVGTextPositioningElement wrapSVGTextPositioningElement(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGAltGlyphElement":
        return new SVGAltGlyphElementWrappingImplementation._wrap(raw);
      case "SVGTRefElement":
        return new SVGTRefElementWrappingImplementation._wrap(raw);
      case "SVGTSpanElement":
        return new SVGTSpanElementWrappingImplementation._wrap(raw);
      case "SVGTextElement":
        return new SVGTextElementWrappingImplementation._wrap(raw);
      case "SVGTextPositioningElement":
        return new SVGTextPositioningElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGTitleElement wrapSVGTitleElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGTitleElementWrappingImplementation._wrap(raw);
  }

  static SVGTransform wrapSVGTransform(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGTransformWrappingImplementation._wrap(raw);
  }

  static SVGTransformList wrapSVGTransformList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGTransformListWrappingImplementation._wrap(raw);
  }

  static SVGTransformable wrapSVGTransformable(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGAElement":
        return new SVGAElementWrappingImplementation._wrap(raw);
      case "SVGCircleElement":
        return new SVGCircleElementWrappingImplementation._wrap(raw);
      case "SVGClipPathElement":
        return new SVGClipPathElementWrappingImplementation._wrap(raw);
      case "SVGDefsElement":
        return new SVGDefsElementWrappingImplementation._wrap(raw);
      case "SVGEllipseElement":
        return new SVGEllipseElementWrappingImplementation._wrap(raw);
      case "SVGForeignObjectElement":
        return new SVGForeignObjectElementWrappingImplementation._wrap(raw);
      case "SVGGElement":
        return new SVGGElementWrappingImplementation._wrap(raw);
      case "SVGImageElement":
        return new SVGImageElementWrappingImplementation._wrap(raw);
      case "SVGLineElement":
        return new SVGLineElementWrappingImplementation._wrap(raw);
      case "SVGPathElement":
        return new SVGPathElementWrappingImplementation._wrap(raw);
      case "SVGPolygonElement":
        return new SVGPolygonElementWrappingImplementation._wrap(raw);
      case "SVGPolylineElement":
        return new SVGPolylineElementWrappingImplementation._wrap(raw);
      case "SVGRectElement":
        return new SVGRectElementWrappingImplementation._wrap(raw);
      case "SVGSwitchElement":
        return new SVGSwitchElementWrappingImplementation._wrap(raw);
      case "SVGTextElement":
        return new SVGTextElementWrappingImplementation._wrap(raw);
      case "SVGTransformable":
        return new SVGTransformableWrappingImplementation._wrap(raw);
      case "SVGUseElement":
        return new SVGUseElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGURIReference wrapSVGURIReference(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGAElement":
        return new SVGAElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphElement":
        return new SVGAltGlyphElementWrappingImplementation._wrap(raw);
      case "SVGCursorElement":
        return new SVGCursorElementWrappingImplementation._wrap(raw);
      case "SVGFEImageElement":
        return new SVGFEImageElementWrappingImplementation._wrap(raw);
      case "SVGFilterElement":
        return new SVGFilterElementWrappingImplementation._wrap(raw);
      case "SVGGlyphRefElement":
        return new SVGGlyphRefElementWrappingImplementation._wrap(raw);
      case "SVGGradientElement":
        return new SVGGradientElementWrappingImplementation._wrap(raw);
      case "SVGImageElement":
        return new SVGImageElementWrappingImplementation._wrap(raw);
      case "SVGLinearGradientElement":
        return new SVGLinearGradientElementWrappingImplementation._wrap(raw);
      case "SVGMPathElement":
        return new SVGMPathElementWrappingImplementation._wrap(raw);
      case "SVGPatternElement":
        return new SVGPatternElementWrappingImplementation._wrap(raw);
      case "SVGRadialGradientElement":
        return new SVGRadialGradientElementWrappingImplementation._wrap(raw);
      case "SVGScriptElement":
        return new SVGScriptElementWrappingImplementation._wrap(raw);
      case "SVGTRefElement":
        return new SVGTRefElementWrappingImplementation._wrap(raw);
      case "SVGTextPathElement":
        return new SVGTextPathElementWrappingImplementation._wrap(raw);
      case "SVGURIReference":
        return new SVGURIReferenceWrappingImplementation._wrap(raw);
      case "SVGUseElement":
        return new SVGUseElementWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGUnitTypes wrapSVGUnitTypes(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGUnitTypesWrappingImplementation._wrap(raw);
  }

  static SVGUseElement wrapSVGUseElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGUseElementWrappingImplementation._wrap(raw);
  }

  static SVGVKernElement wrapSVGVKernElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGVKernElementWrappingImplementation._wrap(raw);
  }

  static SVGViewElement wrapSVGViewElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGViewElementWrappingImplementation._wrap(raw);
  }

  static SVGViewSpec wrapSVGViewSpec(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGViewSpecWrappingImplementation._wrap(raw);
  }

  static SVGZoomAndPan wrapSVGZoomAndPan(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "SVGSVGElement":
        return new SVGSVGElementWrappingImplementation._wrap(raw);
      case "SVGViewElement":
        return new SVGViewElementWrappingImplementation._wrap(raw);
      case "SVGViewSpec":
        return new SVGViewSpecWrappingImplementation._wrap(raw);
      case "SVGZoomAndPan":
        return new SVGZoomAndPanWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static SVGZoomEvent wrapSVGZoomEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SVGZoomEventWrappingImplementation._wrap(raw);
  }

  static Screen wrapScreen(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ScreenWrappingImplementation._wrap(raw);
  }

  static ScriptElement wrapScriptElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ScriptElementWrappingImplementation._wrap(raw);
  }

  static SelectElement wrapSelectElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SelectElementWrappingImplementation._wrap(raw);
  }

  static SharedWorker wrapSharedWorker(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SharedWorkerWrappingImplementation._wrap(raw);
  }

  static SourceElement wrapSourceElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SourceElementWrappingImplementation._wrap(raw);
  }

  static SpanElement wrapSpanElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SpanElementWrappingImplementation._wrap(raw);
  }

  static SpeechInputEvent wrapSpeechInputEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SpeechInputEventWrappingImplementation._wrap(raw);
  }

  static SpeechInputResult wrapSpeechInputResult(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SpeechInputResultWrappingImplementation._wrap(raw);
  }

  static SpeechInputResultList wrapSpeechInputResultList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new SpeechInputResultListWrappingImplementation._wrap(raw);
  }

  static Storage wrapStorage(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new StorageWrappingImplementation._wrap(raw);
  }

  static StorageEvent wrapStorageEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new StorageEventWrappingImplementation._wrap(raw);
  }

  static StorageInfo wrapStorageInfo(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new StorageInfoWrappingImplementation._wrap(raw);
  }

  // Skipped StorageInfoErrorCallback
  // Skipped StorageInfoQuotaCallback
  // Skipped StorageInfoUsageCallback
  // Skipped StringCallback
  static StyleElement wrapStyleElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new StyleElementWrappingImplementation._wrap(raw);
  }

  static StyleMedia wrapStyleMedia(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new StyleMediaWrappingImplementation._wrap(raw);
  }

  static StyleSheet wrapStyleSheet(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "CSSStyleSheet":
        return new CSSStyleSheetWrappingImplementation._wrap(raw);
      case "StyleSheet":
        return new StyleSheetWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static StyleSheetList wrapStyleSheetList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new StyleSheetListWrappingImplementation._wrap(raw);
  }

  static TableCaptionElement wrapTableCaptionElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TableCaptionElementWrappingImplementation._wrap(raw);
  }

  static TableCellElement wrapTableCellElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TableCellElementWrappingImplementation._wrap(raw);
  }

  static TableColElement wrapTableColElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TableColElementWrappingImplementation._wrap(raw);
  }

  static TableElement wrapTableElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TableElementWrappingImplementation._wrap(raw);
  }

  static TableRowElement wrapTableRowElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TableRowElementWrappingImplementation._wrap(raw);
  }

  static TableSectionElement wrapTableSectionElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TableSectionElementWrappingImplementation._wrap(raw);
  }

  static Text wrapText(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "CDATASection":
        return new CDATASectionWrappingImplementation._wrap(raw);
      case "Text":
        return new TextWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static TextAreaElement wrapTextAreaElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TextAreaElementWrappingImplementation._wrap(raw);
  }

  static TextEvent wrapTextEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TextEventWrappingImplementation._wrap(raw);
  }

  static TextMetrics wrapTextMetrics(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TextMetricsWrappingImplementation._wrap(raw);
  }

  static TextTrack wrapTextTrack(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TextTrackWrappingImplementation._wrap(raw);
  }

  static TextTrackCue wrapTextTrackCue(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TextTrackCueWrappingImplementation._wrap(raw);
  }

  static TextTrackCueList wrapTextTrackCueList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TextTrackCueListWrappingImplementation._wrap(raw);
  }

  static TimeRanges wrapTimeRanges(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TimeRangesWrappingImplementation._wrap(raw);
  }

  static TitleElement wrapTitleElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TitleElementWrappingImplementation._wrap(raw);
  }

  static Touch wrapTouch(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TouchWrappingImplementation._wrap(raw);
  }

  static TouchEvent wrapTouchEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TouchEventWrappingImplementation._wrap(raw);
  }

  static TouchList wrapTouchList(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TouchListWrappingImplementation._wrap(raw);
  }

  static TrackElement wrapTrackElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TrackElementWrappingImplementation._wrap(raw);
  }

  static TransitionEvent wrapTransitionEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new TransitionEventWrappingImplementation._wrap(raw);
  }

  static UIEvent wrapUIEvent(raw) {
    if (raw === null) { return null; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      case "CompositionEvent":
        return new CompositionEventWrappingImplementation._wrap(raw);
      case "KeyboardEvent":
        return new KeyboardEventWrappingImplementation._wrap(raw);
      case "MouseEvent":
        return new MouseEventWrappingImplementation._wrap(raw);
      case "SVGZoomEvent":
        return new SVGZoomEventWrappingImplementation._wrap(raw);
      case "TextEvent":
        return new TextEventWrappingImplementation._wrap(raw);
      case "TouchEvent":
        return new TouchEventWrappingImplementation._wrap(raw);
      case "UIEvent":
        return new UIEventWrappingImplementation._wrap(raw);
      case "WheelEvent":
        return new WheelEventWrappingImplementation._wrap(raw);
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static UListElement wrapUListElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new UListElementWrappingImplementation._wrap(raw);
  }

  static Uint16Array wrapUint16Array(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new Uint16ArrayWrappingImplementation._wrap(raw);
  }

  static Uint32Array wrapUint32Array(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new Uint32ArrayWrappingImplementation._wrap(raw);
  }

  static Uint8Array wrapUint8Array(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new Uint8ArrayWrappingImplementation._wrap(raw);
  }

  static UnknownElement wrapUnknownElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new UnknownElementWrappingImplementation._wrap(raw);
  }

  static ValidityState wrapValidityState(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new ValidityStateWrappingImplementation._wrap(raw);
  }

  static VideoElement wrapVideoElement(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new VideoElementWrappingImplementation._wrap(raw);
  }

  static VoidCallback wrapVoidCallback(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new VoidCallbackWrappingImplementation._wrap(raw);
  }

  static WaveShaperNode wrapWaveShaperNode(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WaveShaperNodeWrappingImplementation._wrap(raw);
  }

  static WebGLActiveInfo wrapWebGLActiveInfo(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLActiveInfoWrappingImplementation._wrap(raw);
  }

  static WebGLBuffer wrapWebGLBuffer(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLBufferWrappingImplementation._wrap(raw);
  }

  static WebGLContextAttributes wrapWebGLContextAttributes(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLContextAttributesWrappingImplementation._wrap(raw);
  }

  static WebGLContextEvent wrapWebGLContextEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLContextEventWrappingImplementation._wrap(raw);
  }

  static WebGLDebugRendererInfo wrapWebGLDebugRendererInfo(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLDebugRendererInfoWrappingImplementation._wrap(raw);
  }

  static WebGLDebugShaders wrapWebGLDebugShaders(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLDebugShadersWrappingImplementation._wrap(raw);
  }

  static WebGLFramebuffer wrapWebGLFramebuffer(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLFramebufferWrappingImplementation._wrap(raw);
  }

  static WebGLProgram wrapWebGLProgram(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLProgramWrappingImplementation._wrap(raw);
  }

  static WebGLRenderbuffer wrapWebGLRenderbuffer(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLRenderbufferWrappingImplementation._wrap(raw);
  }

  static WebGLRenderingContext wrapWebGLRenderingContext(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLRenderingContextWrappingImplementation._wrap(raw);
  }

  static WebGLShader wrapWebGLShader(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLShaderWrappingImplementation._wrap(raw);
  }

  static WebGLTexture wrapWebGLTexture(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLTextureWrappingImplementation._wrap(raw);
  }

  static WebGLUniformLocation wrapWebGLUniformLocation(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLUniformLocationWrappingImplementation._wrap(raw);
  }

  static WebGLVertexArrayObjectOES wrapWebGLVertexArrayObjectOES(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebGLVertexArrayObjectOESWrappingImplementation._wrap(raw);
  }

  static WebKitCSSFilterValue wrapWebKitCSSFilterValue(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebKitCSSFilterValueWrappingImplementation._wrap(raw);
  }

  static WebKitMutationObserver wrapWebKitMutationObserver(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebKitMutationObserverWrappingImplementation._wrap(raw);
  }

  static WebSocket wrapWebSocket(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WebSocketWrappingImplementation._wrap(raw);
  }

  static WheelEvent wrapWheelEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WheelEventWrappingImplementation._wrap(raw);
  }

  static Window wrapWindow(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WindowWrappingImplementation._wrap(raw);
  }

  static Worker wrapWorker(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new WorkerWrappingImplementation._wrap(raw);
  }

  static XMLHttpRequest wrapXMLHttpRequest(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new XMLHttpRequestWrappingImplementation._wrap(raw);
  }

  static XMLHttpRequestException wrapXMLHttpRequestException(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new XMLHttpRequestExceptionWrappingImplementation._wrap(raw);
  }

  static XMLHttpRequestProgressEvent wrapXMLHttpRequestProgressEvent(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new XMLHttpRequestProgressEventWrappingImplementation._wrap(raw);
  }

  static XMLHttpRequestUpload wrapXMLHttpRequestUpload(raw) {
    return raw === null ? null : raw.dartObjectLocalStorage !== null ? raw.dartObjectLocalStorage : new XMLHttpRequestUploadWrappingImplementation._wrap(raw);
  }

  static Object wrapObject(raw) {
    if (raw === null || raw is String || raw is num || raw is Date) { return raw; }
    if (raw.dartObjectLocalStorage !== null) {
      return raw.dartObjectLocalStorage;
    }
    switch (raw.typeName) {
      /* Skipping AbstractWorker*/
      case "HTMLAnchorElement":
        return new AnchorElementWrappingImplementation._wrap(raw);
      case "WebKitAnimation":
        return new AnimationWrappingImplementation._wrap(raw);
      case "WebKitAnimationEvent":
        return new AnimationEventWrappingImplementation._wrap(raw);
      case "WebKitAnimationList":
        return new AnimationListWrappingImplementation._wrap(raw);
      /* Skipping HTMLAppletElement*/
      case "HTMLAreaElement":
        return new AreaElementWrappingImplementation._wrap(raw);
      case "ArrayBuffer":
        return new ArrayBufferWrappingImplementation._wrap(raw);
      case "ArrayBufferView":
        return new ArrayBufferViewWrappingImplementation._wrap(raw);
      /* Skipping Attr*/
      case "AudioBuffer":
        return new AudioBufferWrappingImplementation._wrap(raw);
      /* Skipping AudioBufferCallback*/
      case "AudioBufferSourceNode":
        return new AudioBufferSourceNodeWrappingImplementation._wrap(raw);
      case "AudioChannelMerger":
        return new AudioChannelMergerWrappingImplementation._wrap(raw);
      case "AudioChannelSplitter":
        return new AudioChannelSplitterWrappingImplementation._wrap(raw);
      case "AudioContext":
        return new AudioContextWrappingImplementation._wrap(raw);
      case "AudioDestinationNode":
        return new AudioDestinationNodeWrappingImplementation._wrap(raw);
      case "HTMLAudioElement":
        return new AudioElementWrappingImplementation._wrap(raw);
      case "AudioGain":
        return new AudioGainWrappingImplementation._wrap(raw);
      case "AudioGainNode":
        return new AudioGainNodeWrappingImplementation._wrap(raw);
      case "AudioListener":
        return new AudioListenerWrappingImplementation._wrap(raw);
      case "AudioNode":
        return new AudioNodeWrappingImplementation._wrap(raw);
      case "AudioPannerNode":
        return new AudioPannerNodeWrappingImplementation._wrap(raw);
      case "AudioParam":
        return new AudioParamWrappingImplementation._wrap(raw);
      case "AudioProcessingEvent":
        return new AudioProcessingEventWrappingImplementation._wrap(raw);
      case "AudioSourceNode":
        return new AudioSourceNodeWrappingImplementation._wrap(raw);
      case "HTMLBRElement":
        return new BRElementWrappingImplementation._wrap(raw);
      case "BarInfo":
        return new BarInfoWrappingImplementation._wrap(raw);
      case "HTMLBaseElement":
        return new BaseElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLBaseFontElement*/
      case "BeforeLoadEvent":
        return new BeforeLoadEventWrappingImplementation._wrap(raw);
      case "BiquadFilterNode":
        return new BiquadFilterNodeWrappingImplementation._wrap(raw);
      case "Blob":
        return new BlobWrappingImplementation._wrap(raw);
      case "WebKitBlobBuilder":
        return new BlobBuilderWrappingImplementation._wrap(raw);
      case "HTMLBodyElement":
        return new BodyElementWrappingImplementation._wrap(raw);
      case "HTMLButtonElement":
        return new ButtonElementWrappingImplementation._wrap(raw);
      case "CDATASection":
        return new CDATASectionWrappingImplementation._wrap(raw);
      case "CSSCharsetRule":
        return new CSSCharsetRuleWrappingImplementation._wrap(raw);
      case "CSSFontFaceRule":
        return new CSSFontFaceRuleWrappingImplementation._wrap(raw);
      case "CSSImportRule":
        return new CSSImportRuleWrappingImplementation._wrap(raw);
      case "WebKitCSSKeyframeRule":
        return new CSSKeyframeRuleWrappingImplementation._wrap(raw);
      case "WebKitCSSKeyframesRule":
        return new CSSKeyframesRuleWrappingImplementation._wrap(raw);
      case "WebKitCSSMatrix":
        return new CSSMatrixWrappingImplementation._wrap(raw);
      case "CSSMediaRule":
        return new CSSMediaRuleWrappingImplementation._wrap(raw);
      case "CSSPageRule":
        return new CSSPageRuleWrappingImplementation._wrap(raw);
      case "CSSPrimitiveValue":
        return new CSSPrimitiveValueWrappingImplementation._wrap(raw);
      case "CSSRule":
        return new CSSRuleWrappingImplementation._wrap(raw);
      case "CSSRuleList":
        return new CSSRuleListWrappingImplementation._wrap(raw);
      case "CSSStyleDeclaration":
        return new CSSStyleDeclarationWrappingImplementation._wrap(raw);
      case "CSSStyleRule":
        return new CSSStyleRuleWrappingImplementation._wrap(raw);
      case "CSSStyleSheet":
        return new CSSStyleSheetWrappingImplementation._wrap(raw);
      case "WebKitCSSTransformValue":
        return new CSSTransformValueWrappingImplementation._wrap(raw);
      case "CSSUnknownRule":
        return new CSSUnknownRuleWrappingImplementation._wrap(raw);
      case "CSSValue":
        return new CSSValueWrappingImplementation._wrap(raw);
      case "CSSValueList":
        return new CSSValueListWrappingImplementation._wrap(raw);
      case "HTMLCanvasElement":
        return new CanvasElementWrappingImplementation._wrap(raw);
      case "CanvasGradient":
        return new CanvasGradientWrappingImplementation._wrap(raw);
      case "CanvasPattern":
        return new CanvasPatternWrappingImplementation._wrap(raw);
      case "CanvasPixelArray":
        return new CanvasPixelArrayWrappingImplementation._wrap(raw);
      case "CanvasRenderingContext":
        return new CanvasRenderingContextWrappingImplementation._wrap(raw);
      case "CanvasRenderingContext2D":
        return new CanvasRenderingContext2DWrappingImplementation._wrap(raw);
      case "CharacterData":
        return new CharacterDataWrappingImplementation._wrap(raw);
      case "ClientRect":
        return new ClientRectWrappingImplementation._wrap(raw);
      case "ClientRectList":
        return new ClientRectListWrappingImplementation._wrap(raw);
      case "Clipboard":
        return new ClipboardWrappingImplementation._wrap(raw);
      case "CloseEvent":
        return new CloseEventWrappingImplementation._wrap(raw);
      case "Comment":
        return new CommentWrappingImplementation._wrap(raw);
      case "CompositionEvent":
        return new CompositionEventWrappingImplementation._wrap(raw);
      case "Console":
        return new ConsoleWrappingImplementation._wrap(raw);
      case "ConvolverNode":
        return new ConvolverNodeWrappingImplementation._wrap(raw);
      case "Coordinates":
        return new CoordinatesWrappingImplementation._wrap(raw);
      case "Counter":
        return new CounterWrappingImplementation._wrap(raw);
      case "Crypto":
        return new CryptoWrappingImplementation._wrap(raw);
      case "CustomEvent":
        return new CustomEventWrappingImplementation._wrap(raw);
      case "HTMLDListElement":
        return new DListElementWrappingImplementation._wrap(raw);
      case "DOMApplicationCache":
        return new DOMApplicationCacheWrappingImplementation._wrap(raw);
      case "DOMException":
        return new DOMExceptionWrappingImplementation._wrap(raw);
      case "DOMFileSystem":
        return new DOMFileSystemWrappingImplementation._wrap(raw);
      case "DOMFileSystemSync":
        return new DOMFileSystemSyncWrappingImplementation._wrap(raw);
      case "DOMFormData":
        return new DOMFormDataWrappingImplementation._wrap(raw);
      /* Skipping DOMImplementation*/
      case "DOMMimeType":
        return new DOMMimeTypeWrappingImplementation._wrap(raw);
      case "DOMMimeTypeArray":
        return new DOMMimeTypeArrayWrappingImplementation._wrap(raw);
      case "DOMParser":
        return new DOMParserWrappingImplementation._wrap(raw);
      case "DOMPlugin":
        return new DOMPluginWrappingImplementation._wrap(raw);
      case "DOMPluginArray":
        return new DOMPluginArrayWrappingImplementation._wrap(raw);
      case "DOMSelection":
        return new DOMSelectionWrappingImplementation._wrap(raw);
      case "DOMSettableTokenList":
        return new DOMSettableTokenListWrappingImplementation._wrap(raw);
      case "DOMTokenList":
        return new DOMTokenListWrappingImplementation._wrap(raw);
      case "DOMURL":
        return new DOMURLWrappingImplementation._wrap(raw);
      case "HTMLDataListElement":
        return new DataListElementWrappingImplementation._wrap(raw);
      case "DataTransferItem":
        return new DataTransferItemWrappingImplementation._wrap(raw);
      case "DataTransferItemList":
        return new DataTransferItemListWrappingImplementation._wrap(raw);
      case "DataView":
        return new DataViewWrappingImplementation._wrap(raw);
      /* Skipping Database*/
      /* Skipping DatabaseCallback*/
      /* Skipping DatabaseSync*/
      /* Skipping DedicatedWorkerContext*/
      case "DelayNode":
        return new DelayNodeWrappingImplementation._wrap(raw);
      case "HTMLDetailsElement":
        return new DetailsElementWrappingImplementation._wrap(raw);
      case "DeviceMotionEvent":
        return new DeviceMotionEventWrappingImplementation._wrap(raw);
      case "DeviceOrientationEvent":
        return new DeviceOrientationEventWrappingImplementation._wrap(raw);
      /* Skipping HTMLDirectoryElement*/
      case "DirectoryEntry":
        return new DirectoryEntryWrappingImplementation._wrap(raw);
      case "DirectoryEntrySync":
        return new DirectoryEntrySyncWrappingImplementation._wrap(raw);
      case "DirectoryReader":
        return new DirectoryReaderWrappingImplementation._wrap(raw);
      case "DirectoryReaderSync":
        return new DirectoryReaderSyncWrappingImplementation._wrap(raw);
      case "HTMLDivElement":
        return new DivElementWrappingImplementation._wrap(raw);
      case "HTMLDocument":
        return new DocumentWrappingImplementation._wrap(raw, raw.documentElement);
      case "DocumentFragment":
        return new DocumentFragmentWrappingImplementation._wrap(raw);
      /* Skipping DocumentType*/
      case "DynamicsCompressorNode":
        return new DynamicsCompressorNodeWrappingImplementation._wrap(raw);
      case "HTMLElement":
        return new ElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLOptionsCollection*/
      case "ElementTimeControl":
        return new ElementTimeControlWrappingImplementation._wrap(raw);
      /* Skipping ElementTraversal*/
      case "HTMLEmbedElement":
        return new EmbedElementWrappingImplementation._wrap(raw);
      case "Entity":
        return new EntityWrappingImplementation._wrap(raw);
      case "EntityReference":
        return new EntityReferenceWrappingImplementation._wrap(raw);
      /* Skipping EntriesCallback*/
      case "Entry":
        return new EntryWrappingImplementation._wrap(raw);
      case "EntryArray":
        return new EntryArrayWrappingImplementation._wrap(raw);
      case "EntryArraySync":
        return new EntryArraySyncWrappingImplementation._wrap(raw);
      /* Skipping EntryCallback*/
      case "EntrySync":
        return new EntrySyncWrappingImplementation._wrap(raw);
      /* Skipping ErrorCallback*/
      case "ErrorEvent":
        return new ErrorEventWrappingImplementation._wrap(raw);
      case "Event":
        return new EventWrappingImplementation._wrap(raw);
      case "EventException":
        return new EventExceptionWrappingImplementation._wrap(raw);
      /* Skipping EventListener*/
      case "EventSource":
        return new EventSourceWrappingImplementation._wrap(raw);
      case "EventTarget":
        return new EventTargetWrappingImplementation._wrap(raw);
      case "HTMLFieldSetElement":
        return new FieldSetElementWrappingImplementation._wrap(raw);
      case "File":
        return new FileWrappingImplementation._wrap(raw);
      /* Skipping FileCallback*/
      case "FileEntry":
        return new FileEntryWrappingImplementation._wrap(raw);
      case "FileEntrySync":
        return new FileEntrySyncWrappingImplementation._wrap(raw);
      case "FileError":
        return new FileErrorWrappingImplementation._wrap(raw);
      case "FileException":
        return new FileExceptionWrappingImplementation._wrap(raw);
      case "FileList":
        return new FileListWrappingImplementation._wrap(raw);
      case "FileReader":
        return new FileReaderWrappingImplementation._wrap(raw);
      case "FileReaderSync":
        return new FileReaderSyncWrappingImplementation._wrap(raw);
      /* Skipping FileSystemCallback*/
      case "FileWriter":
        return new FileWriterWrappingImplementation._wrap(raw);
      /* Skipping FileWriterCallback*/
      case "FileWriterSync":
        return new FileWriterSyncWrappingImplementation._wrap(raw);
      case "WebKitFlags":
        return new FlagsWrappingImplementation._wrap(raw);
      case "Float32Array":
        return new Float32ArrayWrappingImplementation._wrap(raw);
      case "Float64Array":
        return new Float64ArrayWrappingImplementation._wrap(raw);
      case "HTMLFontElement":
        return new FontElementWrappingImplementation._wrap(raw);
      case "HTMLFormElement":
        return new FormElementWrappingImplementation._wrap(raw);
      /* Skipping HTMLFrameElement*/
      /* Skipping HTMLFrameSetElement*/
      case "Geolocation":
        return new GeolocationWrappingImplementation._wrap(raw);
      case "Geoposition":
        return new GeopositionWrappingImplementation._wrap(raw);
      case "HTMLHRElement":
        return new HRElementWrappingImplementation._wrap(raw);
      case "HTMLAllCollection":
        return new HTMLAllCollectionWrappingImplementation._wrap(raw);
      case "HashChangeEvent":
        return new HashChangeEventWrappingImplementation._wrap(raw);
      case "HTMLHeadElement":
        return new HeadElementWrappingImplementation._wrap(raw);
      case "HTMLHeadingElement":
        return new HeadingElementWrappingImplementation._wrap(raw);
      case "HighPass2FilterNode":
        return new HighPass2FilterNodeWrappingImplementation._wrap(raw);
      case "History":
        return new HistoryWrappingImplementation._wrap(raw);
      case "HTMLHtmlElement":
        return new DocumentWrappingImplementation._wrap(raw.parentNode, raw);
      case "IDBAny":
        return new IDBAnyWrappingImplementation._wrap(raw);
      case "IDBCursor":
        return new IDBCursorWrappingImplementation._wrap(raw);
      case "IDBCursorWithValue":
        return new IDBCursorWithValueWrappingImplementation._wrap(raw);
      case "IDBDatabase":
        return new IDBDatabaseWrappingImplementation._wrap(raw);
      case "IDBDatabaseError":
        return new IDBDatabaseErrorWrappingImplementation._wrap(raw);
      case "IDBDatabaseException":
        return new IDBDatabaseExceptionWrappingImplementation._wrap(raw);
      case "IDBFactory":
        return new IDBFactoryWrappingImplementation._wrap(raw);
      case "IDBIndex":
        return new IDBIndexWrappingImplementation._wrap(raw);
      case "IDBKey":
        return new IDBKeyWrappingImplementation._wrap(raw);
      case "IDBKeyRange":
        return new IDBKeyRangeWrappingImplementation._wrap(raw);
      case "IDBObjectStore":
        return new IDBObjectStoreWrappingImplementation._wrap(raw);
      case "IDBRequest":
        return new IDBRequestWrappingImplementation._wrap(raw);
      case "IDBTransaction":
        return new IDBTransactionWrappingImplementation._wrap(raw);
      case "IDBVersionChangeEvent":
        return new IDBVersionChangeEventWrappingImplementation._wrap(raw);
      case "IDBVersionChangeRequest":
        return new IDBVersionChangeRequestWrappingImplementation._wrap(raw);
      case "HTMLIFrameElement":
        return new IFrameElementWrappingImplementation._wrap(raw);
      case "ImageData":
        return new ImageDataWrappingImplementation._wrap(raw);
      case "HTMLImageElement":
        return new ImageElementWrappingImplementation._wrap(raw);
      /* Skipping InjectedScriptHost*/
      case "HTMLInputElement":
        return new InputElementWrappingImplementation._wrap(raw);
      /* Skipping InspectorFrontendHost*/
      case "Int16Array":
        return new Int16ArrayWrappingImplementation._wrap(raw);
      case "Int32Array":
        return new Int32ArrayWrappingImplementation._wrap(raw);
      case "Int8Array":
        return new Int8ArrayWrappingImplementation._wrap(raw);
      /* Skipping HTMLIsIndexElement*/
      case "JavaScriptAudioNode":
        return new JavaScriptAudioNodeWrappingImplementation._wrap(raw);
      /* Skipping JavaScriptCallFrame*/
      case "KeyboardEvent":
        return new KeyboardEventWrappingImplementation._wrap(raw);
      case "HTMLKeygenElement":
        return new KeygenElementWrappingImplementation._wrap(raw);
      case "HTMLLIElement":
        return new LIElementWrappingImplementation._wrap(raw);
      case "HTMLLabelElement":
        return new LabelElementWrappingImplementation._wrap(raw);
      case "HTMLLegendElement":
        return new LegendElementWrappingImplementation._wrap(raw);
      case "HTMLLinkElement":
        return new LinkElementWrappingImplementation._wrap(raw);
      case "Location":
        return new LocationWrappingImplementation._wrap(raw);
      case "WebKitLoseContext":
        return new LoseContextWrappingImplementation._wrap(raw);
      case "LowPass2FilterNode":
        return new LowPass2FilterNodeWrappingImplementation._wrap(raw);
      case "HTMLMapElement":
        return new MapElementWrappingImplementation._wrap(raw);
      case "HTMLMarqueeElement":
        return new MarqueeElementWrappingImplementation._wrap(raw);
      case "HTMLMediaElement":
        return new MediaElementWrappingImplementation._wrap(raw);
      case "MediaElementAudioSourceNode":
        return new MediaElementAudioSourceNodeWrappingImplementation._wrap(raw);
      case "MediaError":
        return new MediaErrorWrappingImplementation._wrap(raw);
      case "MediaList":
        return new MediaListWrappingImplementation._wrap(raw);
      case "MediaQueryList":
        return new MediaQueryListWrappingImplementation._wrap(raw);
      case "MediaQueryListListener":
        return new MediaQueryListListenerWrappingImplementation._wrap(raw);
      /* Skipping MemoryInfo*/
      case "HTMLMenuElement":
        return new MenuElementWrappingImplementation._wrap(raw);
      case "MessageChannel":
        return new MessageChannelWrappingImplementation._wrap(raw);
      case "MessageEvent":
        return new MessageEventWrappingImplementation._wrap(raw);
      case "MessagePort":
        return new MessagePortWrappingImplementation._wrap(raw);
      case "HTMLMetaElement":
        return new MetaElementWrappingImplementation._wrap(raw);
      case "Metadata":
        return new MetadataWrappingImplementation._wrap(raw);
      /* Skipping MetadataCallback*/
      case "HTMLMeterElement":
        return new MeterElementWrappingImplementation._wrap(raw);
      case "HTMLModElement":
        return new ModElementWrappingImplementation._wrap(raw);
      case "MouseEvent":
        return new MouseEventWrappingImplementation._wrap(raw);
      case "MutationCallback":
        return new MutationCallbackWrappingImplementation._wrap(raw);
      case "MutationEvent":
        return new MutationEventWrappingImplementation._wrap(raw);
      case "MutationRecord":
        return new MutationRecordWrappingImplementation._wrap(raw);
      /* Skipping NamedNodeMap*/
      case "Navigator":
        return new NavigatorWrappingImplementation._wrap(raw);
      case "NavigatorUserMediaError":
        return new NavigatorUserMediaErrorWrappingImplementation._wrap(raw);
      /* Skipping NavigatorUserMediaErrorCallback*/
      case "NavigatorUserMediaSuccessCallback":
        return new NavigatorUserMediaSuccessCallbackWrappingImplementation._wrap(raw);
      case "Node":
        return new NodeWrappingImplementation._wrap(raw);
      /* Skipping NodeFilter*/
      /* Skipping NodeIterator*/
      /* Skipping NodeSelector*/
      case "Notation":
        return new NotationWrappingImplementation._wrap(raw);
      case "Notification":
        return new NotificationWrappingImplementation._wrap(raw);
      case "NotificationCenter":
        return new NotificationCenterWrappingImplementation._wrap(raw);
      case "OESStandardDerivatives":
        return new OESStandardDerivativesWrappingImplementation._wrap(raw);
      case "OESTextureFloat":
        return new OESTextureFloatWrappingImplementation._wrap(raw);
      case "OESVertexArrayObject":
        return new OESVertexArrayObjectWrappingImplementation._wrap(raw);
      case "HTMLOListElement":
        return new OListElementWrappingImplementation._wrap(raw);
      case "HTMLObjectElement":
        return new ObjectElementWrappingImplementation._wrap(raw);
      case "OfflineAudioCompletionEvent":
        return new OfflineAudioCompletionEventWrappingImplementation._wrap(raw);
      case "OperationNotAllowedException":
        return new OperationNotAllowedExceptionWrappingImplementation._wrap(raw);
      case "HTMLOptGroupElement":
        return new OptGroupElementWrappingImplementation._wrap(raw);
      case "HTMLOptionElement":
        return new OptionElementWrappingImplementation._wrap(raw);
      case "HTMLOutputElement":
        return new OutputElementWrappingImplementation._wrap(raw);
      case "OverflowEvent":
        return new OverflowEventWrappingImplementation._wrap(raw);
      case "PageTransitionEvent":
        return new PageTransitionEventWrappingImplementation._wrap(raw);
      case "HTMLParagraphElement":
        return new ParagraphElementWrappingImplementation._wrap(raw);
      case "HTMLParamElement":
        return new ParamElementWrappingImplementation._wrap(raw);
      /* Skipping Performance*/
      /* Skipping PerformanceNavigation*/
      /* Skipping PerformanceTiming*/
      case "WebKitPoint":
        return new PointWrappingImplementation._wrap(raw);
      case "PopStateEvent":
        return new PopStateEventWrappingImplementation._wrap(raw);
      /* Skipping PositionCallback*/
      case "PositionError":
        return new PositionErrorWrappingImplementation._wrap(raw);
      /* Skipping PositionErrorCallback*/
      case "HTMLPreElement":
        return new PreElementWrappingImplementation._wrap(raw);
      case "ProcessingInstruction":
        return new ProcessingInstructionWrappingImplementation._wrap(raw);
      case "HTMLProgressElement":
        return new ProgressElementWrappingImplementation._wrap(raw);
      case "ProgressEvent":
        return new ProgressEventWrappingImplementation._wrap(raw);
      case "HTMLQuoteElement":
        return new QuoteElementWrappingImplementation._wrap(raw);
      case "RGBColor":
        return new RGBColorWrappingImplementation._wrap(raw);
      case "Range":
        return new RangeWrappingImplementation._wrap(raw);
      case "RangeException":
        return new RangeExceptionWrappingImplementation._wrap(raw);
      case "RealtimeAnalyserNode":
        return new RealtimeAnalyserNodeWrappingImplementation._wrap(raw);
      case "Rect":
        return new RectWrappingImplementation._wrap(raw);
      /* Skipping RequestAnimationFrameCallback*/
      /* Skipping SQLError*/
      /* Skipping SQLException*/
      /* Skipping SQLResultSet*/
      /* Skipping SQLResultSetRowList*/
      /* Skipping SQLStatementCallback*/
      /* Skipping SQLStatementErrorCallback*/
      /* Skipping SQLTransaction*/
      /* Skipping SQLTransactionCallback*/
      /* Skipping SQLTransactionErrorCallback*/
      /* Skipping SQLTransactionSync*/
      /* Skipping SQLTransactionSyncCallback*/
      case "SVGAElement":
        return new SVGAElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphDefElement":
        return new SVGAltGlyphDefElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphElement":
        return new SVGAltGlyphElementWrappingImplementation._wrap(raw);
      case "SVGAltGlyphItemElement":
        return new SVGAltGlyphItemElementWrappingImplementation._wrap(raw);
      case "SVGAngle":
        return new SVGAngleWrappingImplementation._wrap(raw);
      case "SVGAnimateColorElement":
        return new SVGAnimateColorElementWrappingImplementation._wrap(raw);
      case "SVGAnimateElement":
        return new SVGAnimateElementWrappingImplementation._wrap(raw);
      case "SVGAnimateMotionElement":
        return new SVGAnimateMotionElementWrappingImplementation._wrap(raw);
      case "SVGAnimateTransformElement":
        return new SVGAnimateTransformElementWrappingImplementation._wrap(raw);
      case "SVGAnimatedAngle":
        return new SVGAnimatedAngleWrappingImplementation._wrap(raw);
      case "SVGAnimatedBoolean":
        return new SVGAnimatedBooleanWrappingImplementation._wrap(raw);
      case "SVGAnimatedEnumeration":
        return new SVGAnimatedEnumerationWrappingImplementation._wrap(raw);
      case "SVGAnimatedInteger":
        return new SVGAnimatedIntegerWrappingImplementation._wrap(raw);
      case "SVGAnimatedLength":
        return new SVGAnimatedLengthWrappingImplementation._wrap(raw);
      case "SVGAnimatedLengthList":
        return new SVGAnimatedLengthListWrappingImplementation._wrap(raw);
      case "SVGAnimatedNumber":
        return new SVGAnimatedNumberWrappingImplementation._wrap(raw);
      case "SVGAnimatedNumberList":
        return new SVGAnimatedNumberListWrappingImplementation._wrap(raw);
      case "SVGAnimatedPreserveAspectRatio":
        return new SVGAnimatedPreserveAspectRatioWrappingImplementation._wrap(raw);
      case "SVGAnimatedRect":
        return new SVGAnimatedRectWrappingImplementation._wrap(raw);
      case "SVGAnimatedString":
        return new SVGAnimatedStringWrappingImplementation._wrap(raw);
      case "SVGAnimatedTransformList":
        return new SVGAnimatedTransformListWrappingImplementation._wrap(raw);
      case "SVGAnimationElement":
        return new SVGAnimationElementWrappingImplementation._wrap(raw);
      case "SVGCircleElement":
        return new SVGCircleElementWrappingImplementation._wrap(raw);
      case "SVGClipPathElement":
        return new SVGClipPathElementWrappingImplementation._wrap(raw);
      case "SVGColor":
        return new SVGColorWrappingImplementation._wrap(raw);
      case "SVGComponentTransferFunctionElement":
        return new SVGComponentTransferFunctionElementWrappingImplementation._wrap(raw);
      case "SVGCursorElement":
        return new SVGCursorElementWrappingImplementation._wrap(raw);
      case "SVGDefsElement":
        return new SVGDefsElementWrappingImplementation._wrap(raw);
      case "SVGDescElement":
        return new SVGDescElementWrappingImplementation._wrap(raw);
      case "SVGDocument":
        return new SVGDocumentWrappingImplementation._wrap(raw);
      case "SVGElement":
        return new SVGElementWrappingImplementation._wrap(raw);
      case "SVGElementInstance":
        return new SVGElementInstanceWrappingImplementation._wrap(raw);
      case "SVGElementInstanceList":
        return new SVGElementInstanceListWrappingImplementation._wrap(raw);
      case "SVGEllipseElement":
        return new SVGEllipseElementWrappingImplementation._wrap(raw);
      case "SVGException":
        return new SVGExceptionWrappingImplementation._wrap(raw);
      case "SVGExternalResourcesRequired":
        return new SVGExternalResourcesRequiredWrappingImplementation._wrap(raw);
      case "SVGFEBlendElement":
        return new SVGFEBlendElementWrappingImplementation._wrap(raw);
      case "SVGFEColorMatrixElement":
        return new SVGFEColorMatrixElementWrappingImplementation._wrap(raw);
      case "SVGFEComponentTransferElement":
        return new SVGFEComponentTransferElementWrappingImplementation._wrap(raw);
      /* Skipping SVGFECompositeElement*/
      case "SVGFEConvolveMatrixElement":
        return new SVGFEConvolveMatrixElementWrappingImplementation._wrap(raw);
      case "SVGFEDiffuseLightingElement":
        return new SVGFEDiffuseLightingElementWrappingImplementation._wrap(raw);
      case "SVGFEDisplacementMapElement":
        return new SVGFEDisplacementMapElementWrappingImplementation._wrap(raw);
      case "SVGFEDistantLightElement":
        return new SVGFEDistantLightElementWrappingImplementation._wrap(raw);
      case "SVGFEDropShadowElement":
        return new SVGFEDropShadowElementWrappingImplementation._wrap(raw);
      case "SVGFEFloodElement":
        return new SVGFEFloodElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncAElement":
        return new SVGFEFuncAElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncBElement":
        return new SVGFEFuncBElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncGElement":
        return new SVGFEFuncGElementWrappingImplementation._wrap(raw);
      case "SVGFEFuncRElement":
        return new SVGFEFuncRElementWrappingImplementation._wrap(raw);
      case "SVGFEGaussianBlurElement":
        return new SVGFEGaussianBlurElementWrappingImplementation._wrap(raw);
      case "SVGFEImageElement":
        return new SVGFEImageElementWrappingImplementation._wrap(raw);
      case "SVGFEMergeElement":
        return new SVGFEMergeElementWrappingImplementation._wrap(raw);
      case "SVGFEMergeNodeElement":
        return new SVGFEMergeNodeElementWrappingImplementation._wrap(raw);
      /* Skipping SVGFEMorphologyElement*/
      case "SVGFEOffsetElement":
        return new SVGFEOffsetElementWrappingImplementation._wrap(raw);
      case "SVGFEPointLightElement":
        return new SVGFEPointLightElementWrappingImplementation._wrap(raw);
      case "SVGFESpecularLightingElement":
        return new SVGFESpecularLightingElementWrappingImplementation._wrap(raw);
      case "SVGFESpotLightElement":
        return new SVGFESpotLightElementWrappingImplementation._wrap(raw);
      case "SVGFETileElement":
        return new SVGFETileElementWrappingImplementation._wrap(raw);
      case "SVGFETurbulenceElement":
        return new SVGFETurbulenceElementWrappingImplementation._wrap(raw);
      case "SVGFilterElement":
        return new SVGFilterElementWrappingImplementation._wrap(raw);
      case "SVGFilterPrimitiveStandardAttributes":
        return new SVGFilterPrimitiveStandardAttributesWrappingImplementation._wrap(raw);
      case "SVGFitToViewBox":
        return new SVGFitToViewBoxWrappingImplementation._wrap(raw);
      case "SVGFontElement":
        return new SVGFontElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceElement":
        return new SVGFontFaceElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceFormatElement":
        return new SVGFontFaceFormatElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceNameElement":
        return new SVGFontFaceNameElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceSrcElement":
        return new SVGFontFaceSrcElementWrappingImplementation._wrap(raw);
      case "SVGFontFaceUriElement":
        return new SVGFontFaceUriElementWrappingImplementation._wrap(raw);
      case "SVGForeignObjectElement":
        return new SVGForeignObjectElementWrappingImplementation._wrap(raw);
      case "SVGGElement":
        return new SVGGElementWrappingImplementation._wrap(raw);
      case "SVGGlyphElement":
        return new SVGGlyphElementWrappingImplementation._wrap(raw);
      case "SVGGlyphRefElement":
        return new SVGGlyphRefElementWrappingImplementation._wrap(raw);
      case "SVGGradientElement":
        return new SVGGradientElementWrappingImplementation._wrap(raw);
      case "SVGHKernElement":
        return new SVGHKernElementWrappingImplementation._wrap(raw);
      case "SVGImageElement":
        return new SVGImageElementWrappingImplementation._wrap(raw);
      case "SVGLangSpace":
        return new SVGLangSpaceWrappingImplementation._wrap(raw);
      case "SVGLength":
        return new SVGLengthWrappingImplementation._wrap(raw);
      case "SVGLengthList":
        return new SVGLengthListWrappingImplementation._wrap(raw);
      case "SVGLineElement":
        return new SVGLineElementWrappingImplementation._wrap(raw);
      case "SVGLinearGradientElement":
        return new SVGLinearGradientElementWrappingImplementation._wrap(raw);
      case "SVGLocatable":
        return new SVGLocatableWrappingImplementation._wrap(raw);
      case "SVGMPathElement":
        return new SVGMPathElementWrappingImplementation._wrap(raw);
      case "SVGMarkerElement":
        return new SVGMarkerElementWrappingImplementation._wrap(raw);
      case "SVGMaskElement":
        return new SVGMaskElementWrappingImplementation._wrap(raw);
      case "SVGMatrix":
        return new SVGMatrixWrappingImplementation._wrap(raw);
      case "SVGMetadataElement":
        return new SVGMetadataElementWrappingImplementation._wrap(raw);
      case "SVGMissingGlyphElement":
        return new SVGMissingGlyphElementWrappingImplementation._wrap(raw);
      case "SVGNumber":
        return new SVGNumberWrappingImplementation._wrap(raw);
      case "SVGNumberList":
        return new SVGNumberListWrappingImplementation._wrap(raw);
      case "SVGPaint":
        return new SVGPaintWrappingImplementation._wrap(raw);
      case "SVGPathElement":
        return new SVGPathElementWrappingImplementation._wrap(raw);
      case "SVGPathSeg":
        return new SVGPathSegWrappingImplementation._wrap(raw);
      case "SVGPathSegArcAbs":
        return new SVGPathSegArcAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegArcRel":
        return new SVGPathSegArcRelWrappingImplementation._wrap(raw);
      case "SVGPathSegClosePath":
        return new SVGPathSegClosePathWrappingImplementation._wrap(raw);
      case "SVGPathSegCurvetoCubicAbs":
        return new SVGPathSegCurvetoCubicAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegCurvetoCubicRel":
        return new SVGPathSegCurvetoCubicRelWrappingImplementation._wrap(raw);
      case "SVGPathSegCurvetoCubicSmoothAbs":
        return new SVGPathSegCurvetoCubicSmoothAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegCurvetoCubicSmoothRel":
        return new SVGPathSegCurvetoCubicSmoothRelWrappingImplementation._wrap(raw);
      case "SVGPathSegCurvetoQuadraticAbs":
        return new SVGPathSegCurvetoQuadraticAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegCurvetoQuadraticRel":
        return new SVGPathSegCurvetoQuadraticRelWrappingImplementation._wrap(raw);
      case "SVGPathSegCurvetoQuadraticSmoothAbs":
        return new SVGPathSegCurvetoQuadraticSmoothAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegCurvetoQuadraticSmoothRel":
        return new SVGPathSegCurvetoQuadraticSmoothRelWrappingImplementation._wrap(raw);
      case "SVGPathSegLinetoAbs":
        return new SVGPathSegLinetoAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegLinetoHorizontalAbs":
        return new SVGPathSegLinetoHorizontalAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegLinetoHorizontalRel":
        return new SVGPathSegLinetoHorizontalRelWrappingImplementation._wrap(raw);
      case "SVGPathSegLinetoRel":
        return new SVGPathSegLinetoRelWrappingImplementation._wrap(raw);
      case "SVGPathSegLinetoVerticalAbs":
        return new SVGPathSegLinetoVerticalAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegLinetoVerticalRel":
        return new SVGPathSegLinetoVerticalRelWrappingImplementation._wrap(raw);
      case "SVGPathSegList":
        return new SVGPathSegListWrappingImplementation._wrap(raw);
      case "SVGPathSegMovetoAbs":
        return new SVGPathSegMovetoAbsWrappingImplementation._wrap(raw);
      case "SVGPathSegMovetoRel":
        return new SVGPathSegMovetoRelWrappingImplementation._wrap(raw);
      case "SVGPatternElement":
        return new SVGPatternElementWrappingImplementation._wrap(raw);
      case "SVGPoint":
        return new SVGPointWrappingImplementation._wrap(raw);
      case "SVGPointList":
        return new SVGPointListWrappingImplementation._wrap(raw);
      case "SVGPolygonElement":
        return new SVGPolygonElementWrappingImplementation._wrap(raw);
      case "SVGPolylineElement":
        return new SVGPolylineElementWrappingImplementation._wrap(raw);
      case "SVGPreserveAspectRatio":
        return new SVGPreserveAspectRatioWrappingImplementation._wrap(raw);
      case "SVGRadialGradientElement":
        return new SVGRadialGradientElementWrappingImplementation._wrap(raw);
      case "SVGRect":
        return new SVGRectWrappingImplementation._wrap(raw);
      case "SVGRectElement":
        return new SVGRectElementWrappingImplementation._wrap(raw);
      case "SVGRenderingIntent":
        return new SVGRenderingIntentWrappingImplementation._wrap(raw);
      case "SVGSVGElement":
        return new SVGSVGElementWrappingImplementation._wrap(raw);
      case "SVGScriptElement":
        return new SVGScriptElementWrappingImplementation._wrap(raw);
      case "SVGSetElement":
        return new SVGSetElementWrappingImplementation._wrap(raw);
      case "SVGStopElement":
        return new SVGStopElementWrappingImplementation._wrap(raw);
      case "SVGStringList":
        return new SVGStringListWrappingImplementation._wrap(raw);
      case "SVGStylable":
        return new SVGStylableWrappingImplementation._wrap(raw);
      case "SVGStyleElement":
        return new SVGStyleElementWrappingImplementation._wrap(raw);
      case "SVGSwitchElement":
        return new SVGSwitchElementWrappingImplementation._wrap(raw);
      case "SVGSymbolElement":
        return new SVGSymbolElementWrappingImplementation._wrap(raw);
      case "SVGTRefElement":
        return new SVGTRefElementWrappingImplementation._wrap(raw);
      case "SVGTSpanElement":
        return new SVGTSpanElementWrappingImplementation._wrap(raw);
      case "SVGTests":
        return new SVGTestsWrappingImplementation._wrap(raw);
      case "SVGTextContentElement":
        return new SVGTextContentElementWrappingImplementation._wrap(raw);
      case "SVGTextElement":
        return new SVGTextElementWrappingImplementation._wrap(raw);
      case "SVGTextPathElement":
        return new SVGTextPathElementWrappingImplementation._wrap(raw);
      case "SVGTextPositioningElement":
        return new SVGTextPositioningElementWrappingImplementation._wrap(raw);
      case "SVGTitleElement":
        return new SVGTitleElementWrappingImplementation._wrap(raw);
      case "SVGTransform":
        return new SVGTransformWrappingImplementation._wrap(raw);
      case "SVGTransformList":
        return new SVGTransformListWrappingImplementation._wrap(raw);
      case "SVGTransformable":
        return new SVGTransformableWrappingImplementation._wrap(raw);
      case "SVGURIReference":
        return new SVGURIReferenceWrappingImplementation._wrap(raw);
      case "SVGUnitTypes":
        return new SVGUnitTypesWrappingImplementation._wrap(raw);
      case "SVGUseElement":
        return new SVGUseElementWrappingImplementation._wrap(raw);
      case "SVGVKernElement":
        return new SVGVKernElementWrappingImplementation._wrap(raw);
      case "SVGViewElement":
        return new SVGViewElementWrappingImplementation._wrap(raw);
      case "SVGViewSpec":
        return new SVGViewSpecWrappingImplementation._wrap(raw);
      case "SVGZoomAndPan":
        return new SVGZoomAndPanWrappingImplementation._wrap(raw);
      case "SVGZoomEvent":
        return new SVGZoomEventWrappingImplementation._wrap(raw);
      case "Screen":
        return new ScreenWrappingImplementation._wrap(raw);
      case "HTMLScriptElement":
        return new ScriptElementWrappingImplementation._wrap(raw);
      /* Skipping ScriptProfile*/
      /* Skipping ScriptProfileNode*/
      case "HTMLSelectElement":
        return new SelectElementWrappingImplementation._wrap(raw);
      case "SharedWorker":
        return new SharedWorkerWrappingImplementation._wrap(raw);
      /* Skipping SharedWorkercontext*/
      case "HTMLSourceElement":
        return new SourceElementWrappingImplementation._wrap(raw);
      case "HTMLSpanElement":
        return new SpanElementWrappingImplementation._wrap(raw);
      case "SpeechInputEvent":
        return new SpeechInputEventWrappingImplementation._wrap(raw);
      case "SpeechInputResult":
        return new SpeechInputResultWrappingImplementation._wrap(raw);
      case "SpeechInputResultList":
        return new SpeechInputResultListWrappingImplementation._wrap(raw);
      case "Storage":
        return new StorageWrappingImplementation._wrap(raw);
      case "StorageEvent":
        return new StorageEventWrappingImplementation._wrap(raw);
      case "StorageInfo":
        return new StorageInfoWrappingImplementation._wrap(raw);
      /* Skipping StorageInfoErrorCallback*/
      /* Skipping StorageInfoQuotaCallback*/
      /* Skipping StorageInfoUsageCallback*/
      /* Skipping StringCallback*/
      case "HTMLStyleElement":
        return new StyleElementWrappingImplementation._wrap(raw);
      case "StyleMedia":
        return new StyleMediaWrappingImplementation._wrap(raw);
      case "StyleSheet":
        return new StyleSheetWrappingImplementation._wrap(raw);
      case "StyleSheetList":
        return new StyleSheetListWrappingImplementation._wrap(raw);
      case "HTMLTableCaptionElement":
        return new TableCaptionElementWrappingImplementation._wrap(raw);
      case "HTMLTableCellElement":
        return new TableCellElementWrappingImplementation._wrap(raw);
      case "HTMLTableColElement":
        return new TableColElementWrappingImplementation._wrap(raw);
      case "HTMLTableElement":
        return new TableElementWrappingImplementation._wrap(raw);
      case "HTMLTableRowElement":
        return new TableRowElementWrappingImplementation._wrap(raw);
      case "HTMLTableSectionElement":
        return new TableSectionElementWrappingImplementation._wrap(raw);
      case "Text":
        return new TextWrappingImplementation._wrap(raw);
      case "HTMLTextAreaElement":
        return new TextAreaElementWrappingImplementation._wrap(raw);
      case "TextEvent":
        return new TextEventWrappingImplementation._wrap(raw);
      case "TextMetrics":
        return new TextMetricsWrappingImplementation._wrap(raw);
      case "TextTrack":
        return new TextTrackWrappingImplementation._wrap(raw);
      case "TextTrackCue":
        return new TextTrackCueWrappingImplementation._wrap(raw);
      case "TextTrackCueList":
        return new TextTrackCueListWrappingImplementation._wrap(raw);
      case "TimeRanges":
        return new TimeRangesWrappingImplementation._wrap(raw);
      case "HTMLTitleElement":
        return new TitleElementWrappingImplementation._wrap(raw);
      case "Touch":
        return new TouchWrappingImplementation._wrap(raw);
      case "TouchEvent":
        return new TouchEventWrappingImplementation._wrap(raw);
      case "TouchList":
        return new TouchListWrappingImplementation._wrap(raw);
      case "HTMLTrackElement":
        return new TrackElementWrappingImplementation._wrap(raw);
      case "WebKitTransitionEvent":
        return new TransitionEventWrappingImplementation._wrap(raw);
      /* Skipping TreeWalker*/
      case "UIEvent":
        return new UIEventWrappingImplementation._wrap(raw);
      case "HTMLUListElement":
        return new UListElementWrappingImplementation._wrap(raw);
      case "Uint16Array":
        return new Uint16ArrayWrappingImplementation._wrap(raw);
      case "Uint32Array":
        return new Uint32ArrayWrappingImplementation._wrap(raw);
      case "Uint8Array":
        return new Uint8ArrayWrappingImplementation._wrap(raw);
      case "HTMLUnknownElement":
        return new UnknownElementWrappingImplementation._wrap(raw);
      case "ValidityState":
        return new ValidityStateWrappingImplementation._wrap(raw);
      case "HTMLVideoElement":
        return new VideoElementWrappingImplementation._wrap(raw);
      case "VoidCallback":
        return new VoidCallbackWrappingImplementation._wrap(raw);
      case "WaveShaperNode":
        return new WaveShaperNodeWrappingImplementation._wrap(raw);
      case "WebGLActiveInfo":
        return new WebGLActiveInfoWrappingImplementation._wrap(raw);
      case "WebGLBuffer":
        return new WebGLBufferWrappingImplementation._wrap(raw);
      case "WebGLContextAttributes":
        return new WebGLContextAttributesWrappingImplementation._wrap(raw);
      case "WebGLContextEvent":
        return new WebGLContextEventWrappingImplementation._wrap(raw);
      case "WebGLDebugRendererInfo":
        return new WebGLDebugRendererInfoWrappingImplementation._wrap(raw);
      case "WebGLDebugShaders":
        return new WebGLDebugShadersWrappingImplementation._wrap(raw);
      case "WebGLFramebuffer":
        return new WebGLFramebufferWrappingImplementation._wrap(raw);
      case "WebGLProgram":
        return new WebGLProgramWrappingImplementation._wrap(raw);
      case "WebGLRenderbuffer":
        return new WebGLRenderbufferWrappingImplementation._wrap(raw);
      case "WebGLRenderingContext":
        return new WebGLRenderingContextWrappingImplementation._wrap(raw);
      case "WebGLShader":
        return new WebGLShaderWrappingImplementation._wrap(raw);
      case "WebGLTexture":
        return new WebGLTextureWrappingImplementation._wrap(raw);
      case "WebGLUniformLocation":
        return new WebGLUniformLocationWrappingImplementation._wrap(raw);
      case "WebGLVertexArrayObjectOES":
        return new WebGLVertexArrayObjectOESWrappingImplementation._wrap(raw);
      case "WebKitCSSFilterValue":
        return new WebKitCSSFilterValueWrappingImplementation._wrap(raw);
      case "WebKitMutationObserver":
        return new WebKitMutationObserverWrappingImplementation._wrap(raw);
      case "WebSocket":
        return new WebSocketWrappingImplementation._wrap(raw);
      case "WheelEvent":
        return new WheelEventWrappingImplementation._wrap(raw);
      case "Window":
        return new WindowWrappingImplementation._wrap(raw);
      case "Worker":
        return new WorkerWrappingImplementation._wrap(raw);
      /* Skipping WorkerContext*/
      /* Skipping WorkerLocation*/
      /* Skipping WorkerNavigator*/
      case "XMLHttpRequest":
        return new XMLHttpRequestWrappingImplementation._wrap(raw);
      case "XMLHttpRequestException":
        return new XMLHttpRequestExceptionWrappingImplementation._wrap(raw);
      case "XMLHttpRequestProgressEvent":
        return new XMLHttpRequestProgressEventWrappingImplementation._wrap(raw);
      case "XMLHttpRequestUpload":
        return new XMLHttpRequestUploadWrappingImplementation._wrap(raw);
      /* Skipping XMLSerializer*/
      /* Skipping XPathEvaluator*/
      /* Skipping XPathException*/
      /* Skipping XPathExpression*/
      /* Skipping XPathNSResolver*/
      /* Skipping XPathResult*/
      /* Skipping XSLTProcessor*/
      default:
        throw new UnsupportedOperationException("Unknown type:" + raw.toString());
    }
  }

  static unwrapMaybePrimitive(raw) {
    return (raw === null || raw is String || raw is num || raw is bool) ? raw : raw._ptr;
  }

  static unwrap(raw) {
    return raw === null ? null : raw._ptr;
  }


  static void initialize() {
    secretWindow = wrapWindow(dom.window);
    secretDocument = wrapDocument(dom.document);
  }

}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The [Collections] class implements static methods useful when
 * writing a class that implements [Collection] and the [iterator]
 * method.
 */
class _Collections {
  static void forEach(Iterable<Object> iterable, void f(Object o)) {
    for (final e in iterable) {
      f(e);
    }
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
    return !iterable.iterator().hasNext();
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// These factory methods could all live in one factory provider class but dartc
// has a bug (5399939) preventing that.

class FileReaderFactoryProvider {

  factory FileReader() {
    return new dom.FileReader();
  }
}

class CSSMatrixFactoryProvider {

  factory CSSMatrix([String spec = '']) {
    return new CSSMatrixWrappingImplementation._wrap(
        new dom.WebKitCSSMatrix(spec));
  }
}

class PointFactoryProvider {

  factory Point(num x, num y) {
    return new PointWrappingImplementation._wrap(new dom.WebKitPoint(x, y));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Iterator for lists with fixed size.
class _FixedSizeListIterator<T> extends _VariableSizeListIterator<T> {
  _FixedSizeListIterator(List<T> list)
      : super(list),
        _length = list.length;

  bool hasNext() => _length > _pos;

  final int _length;  // Cache list length for faster access.
}

// Iterator for lists with variable size.
class _VariableSizeListIterator<T> implements Iterator<T> {
  _VariableSizeListIterator(List<T> list)
      : _list = list,
        _pos = 0;

  bool hasNext() => _list.length > _pos;

  T next() {
    if (!hasNext()) {
      throw const NoMoreElementsException();
    }
    return _list[_pos++];
  }

  final List<T> _list;
  int _pos;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jacobr): move into a core library or at least merge with the copy
// in client/dom/src
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
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class AbstractWorkerEventsImplementation extends EventsImplementation implements AbstractWorkerEvents {
  AbstractWorkerEventsImplementation._wrap(_ptr) : super._wrap(_ptr);
  
  EventListenerList get error() => _get('error');
}

class AbstractWorkerWrappingImplementation extends EventTargetWrappingImplementation implements AbstractWorker {
  AbstractWorkerWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  AbstractWorkerEvents get on() {
    if (_on === null) {	
      _on = new AbstractWorkerEventsImplementation._wrap(_ptr);
    }
    return _on;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class AnimationEventWrappingImplementation extends EventWrappingImplementation implements AnimationEvent {
  static String _name;

  AnimationEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  static String get _eventName() {
    if (_name != null) return _name;

    try {
      dom.document.createEvent("WebKitAnimationEvent");
      _name = "WebKitAnimationEvent";
    } catch (var e) {
      _name = "AnimationEvent";
    }
    return _name;
  }

  factory AnimationEventWrappingImplementation(String type, String propertyName,
      double elapsedTime, [bool canBubble = true, bool cancelable = true]) {
    final e = dom.document.createEvent(_eventName);
    e.initWebKitAnimationEvent(
        type, canBubble, cancelable, propertyName, elapsedTime);
    return LevelDom.wrapAnimationEvent(e);
  }

  String get animationName() => _ptr.animationName;

  num get elapsedTime() => _ptr.elapsedTime;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class BeforeLoadEventWrappingImplementation extends EventWrappingImplementation implements BeforeLoadEvent {
  BeforeLoadEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory BeforeLoadEventWrappingImplementation(String type, String url,
      [bool canBubble = true, bool cancelable = true]) {
    final e = dom.document.createEvent("BeforeLoadEvent");
    e.initBeforeLoadEvent(type, canBubble, cancelable, url);
    return LevelDom.wrapBeforeLoadEvent(e);
  }

  String get url() => _ptr.url;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class BodyElementEventsImplementation
    extends ElementEventsImplementation implements BodyElementEvents {

  BodyElementEventsImplementation._wrap(_ptr) : super._wrap(_ptr);

  EventListenerList get beforeUnload() => _get('beforeunload');
  EventListenerList get hashChange() => _get('hashchange');
  EventListenerList get message() => _get('message');
  EventListenerList get offline() => _get('offline');
  EventListenerList get online() => _get('online');
  EventListenerList get orientationChange() => _get('orientationchange');
  EventListenerList get popState() => _get('popstate');
  EventListenerList get resize() => _get('resize');
  EventListenerList get storage() => _get('storage');
  EventListenerList get unLoad() => _get('unload');
}

class BodyElementWrappingImplementation
    extends ElementWrappingImplementation implements BodyElement {

  BodyElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  BodyElementEvents get on() {
    if (_on === null) {
      _on = new BodyElementEventsImplementation._wrap(_ptr);
    }
    return _on;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class CloseEventWrappingImplementation extends EventWrappingImplementation implements CloseEvent {
  CloseEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory CloseEventWrappingImplementation(String type, int code, String reason,
      [bool canBubble = true, bool cancelable = true, bool wasClean = true]) {
    final e = dom.document.createEvent("CloseEvent");
    e.initCloseEvent(type, canBubble, cancelable, wasClean, code, reason);
    return LevelDom.wrapCloseEvent(e);
  }

  int get code() => _ptr.code;

  String get reason() => _ptr.reason;

  bool get wasClean() => _ptr.wasClean;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class CompositionEventWrappingImplementation extends UIEventWrappingImplementation implements CompositionEvent {
  CompositionEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory CompositionEventWrappingImplementation(String type, Window view,
      String data, [bool canBubble = true, bool cancelable = true]) {
    final e = dom.document.createEvent("CompositionEvent");
    e.initCompositionEvent(type, canBubble, cancelable, LevelDom.unwrap(view),
        data);
    return LevelDom.wrapCompositionEvent(e);
  }

  String get data() => _ptr.data;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO - figure out whether classList exists, and if so use that
// rather than the className property that is being used here.

class _CssClassSet implements Set<String> {

  final _element;

  _CssClassSet(this._element);

  String toString() {
    return _formatSet(_read());
  }

  // interface Iterable - BEGIN
  Iterator<String> iterator() {
    return _read().iterator();
  }
  // interface Iterable - END

  // interface Collection - BEGIN
  void forEach(void f(String element)) {
    _read().forEach(f);
  }

  Collection<String> filter(bool f(String element)) {
    return _read().filter(f);
  }

  bool every(bool f(String element)) {
    return _read().every(f);
  }

  bool some(bool f(String element)) {
    return _read().some(f);
  }

  bool isEmpty() {
    return _read().isEmpty();
  }

  int get length() {
    return _read().length;
  }
  // interface Collection - END

  // interface Set - BEGIN
  bool contains(String value) {
    return _read().contains(value);
  }

  void add(String value) {
    // TODO - figure out if we need to do any validation here
    // or if the browser natively does enough
    _modify((s) => s.add(value));
  }

  bool remove(String value) {
    Set<String> s = _read();
    bool result = s.remove(value);
    _write(s);
    return result;
  }

  void addAll(Collection<String> collection) {
    // TODO - see comment above about validation
    _modify((s) => s.addAll(collection));
  }

  void removeAll(Collection<String> collection) {
    _modify((s) => s.removeAll(collection));
  }

  bool isSubsetOf(Collection<String> collection) {
    return _read().isSubsetOf(collection);
  }

  bool containsAll(Collection<String> collection) {
    return _read().containsAll(collection);
  }

  Set<String> intersection(Collection<String> other) {
    return _read().intersection(other);
  }

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
    Set<String> s = _read();
    f(s);
    _write(s);
  }

  /**
   * Read the class names from the HTMLElement class property,
   * and put them into a set (duplicates are discarded).
   */
  Set<String> _read() {
    // TODO(mattsh) simplify this once split can take regex.
    Set<String> s = new Set<String>();
    for (String name in _element.className.split(' ')) {
      String trimmed = name.trim();
      if (!trimmed.isEmpty()) {
        s.add(trimmed);
      }
    }
    return s;
  }

  /**
   * Join all the elements of a set into one string and write
   * back to the element.
   */
  void _write(Set s) {
    _element.className = _formatSet(s);
  }

  String _formatSet(Set<String> s) {
    // TODO(mattsh) should be able to pass Set to String.joins http:/b/5398605
    List list = new List.from(s);
    return Strings.join(list, ' ');
  }

}

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit.
// This file was generated by html/scripts/css_code_generator.py

// Source of CSS properties:
//   Source/WebCore/css/CSSPropertyNames.in

// TODO(jacobr): add versions that take numeric values in px, miliseconds, etc.

class CSSStyleDeclarationWrappingImplementation extends DOMWrapperBase implements CSSStyleDeclaration {
  static String _cachedBrowserPrefix;

  CSSStyleDeclarationWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  factory CSSStyleDeclarationWrappingImplementation.css(String css) {
    var style = new Element.tag('div').style;
    style.cssText = css;
    return style;
  }

  factory CSSStyleDeclarationWrappingImplementation() {
    return new CSSStyleDeclarationWrappingImplementation.css('');
  }

  static String get _browserPrefix() {
    if (_cachedBrowserPrefix === null) {
      if (_Device.isFirefox) {
        _cachedBrowserPrefix = '-moz-';
      } else {
        _cachedBrowserPrefix = '-webkit-';
      }
      // TODO(jacobr): support IE 9.0 and Opera as well.
    }
    return _cachedBrowserPrefix;
  }

  String get cssText() { return _ptr.cssText; }

  void set cssText(String value) { _ptr.cssText = value; }

  int get length() { return _ptr.length; }

  CSSRule get parentRule() { return LevelDom.wrapCSSRule(_ptr.parentRule); }

  CSSValue getPropertyCSSValue(String propertyName) {
    return LevelDom.wrapCSSValue(_ptr.getPropertyCSSValue(propertyName));
  }

  String getPropertyPriority(String propertyName) {
    return _ptr.getPropertyPriority(propertyName);
  }

  String getPropertyShorthand(String propertyName) {
    return _ptr.getPropertyShorthand(propertyName);
  }

  String getPropertyValue(String propertyName) {
    return _ptr.getPropertyValue(propertyName);
  }

  bool isPropertyImplicit(String propertyName) {
    return _ptr.isPropertyImplicit(propertyName);
  }

  String item(int index) {
    return _ptr.item(index);
  }

  String removeProperty(String propertyName) {
    return _ptr.removeProperty(propertyName);
  }

  void setProperty(String propertyName, String value, [String priority = '']) {
    _ptr.setProperty(propertyName, value, priority);
  }

  String get typeName() { return "CSSStyleDeclaration"; }


  /** Gets the value of "animation" */
  String get animation() =>
    getPropertyValue('${_browserPrefix}animation');

  /** Sets the value of "animation" */
  void set animation(String value) {
    setProperty('${_browserPrefix}animation', value, '');
  }

  /** Gets the value of "animation-delay" */
  String get animationDelay() =>
    getPropertyValue('${_browserPrefix}animation-delay');

  /** Sets the value of "animation-delay" */
  void set animationDelay(String value) {
    setProperty('${_browserPrefix}animation-delay', value, '');
  }

  /** Gets the value of "animation-direction" */
  String get animationDirection() =>
    getPropertyValue('${_browserPrefix}animation-direction');

  /** Sets the value of "animation-direction" */
  void set animationDirection(String value) {
    setProperty('${_browserPrefix}animation-direction', value, '');
  }

  /** Gets the value of "animation-duration" */
  String get animationDuration() =>
    getPropertyValue('${_browserPrefix}animation-duration');

  /** Sets the value of "animation-duration" */
  void set animationDuration(String value) {
    setProperty('${_browserPrefix}animation-duration', value, '');
  }

  /** Gets the value of "animation-fill-mode" */
  String get animationFillMode() =>
    getPropertyValue('${_browserPrefix}animation-fill-mode');

  /** Sets the value of "animation-fill-mode" */
  void set animationFillMode(String value) {
    setProperty('${_browserPrefix}animation-fill-mode', value, '');
  }

  /** Gets the value of "animation-iteration-count" */
  String get animationIterationCount() =>
    getPropertyValue('${_browserPrefix}animation-iteration-count');

  /** Sets the value of "animation-iteration-count" */
  void set animationIterationCount(String value) {
    setProperty('${_browserPrefix}animation-iteration-count', value, '');
  }

  /** Gets the value of "animation-name" */
  String get animationName() =>
    getPropertyValue('${_browserPrefix}animation-name');

  /** Sets the value of "animation-name" */
  void set animationName(String value) {
    setProperty('${_browserPrefix}animation-name', value, '');
  }

  /** Gets the value of "animation-play-state" */
  String get animationPlayState() =>
    getPropertyValue('${_browserPrefix}animation-play-state');

  /** Sets the value of "animation-play-state" */
  void set animationPlayState(String value) {
    setProperty('${_browserPrefix}animation-play-state', value, '');
  }

  /** Gets the value of "animation-timing-function" */
  String get animationTimingFunction() =>
    getPropertyValue('${_browserPrefix}animation-timing-function');

  /** Sets the value of "animation-timing-function" */
  void set animationTimingFunction(String value) {
    setProperty('${_browserPrefix}animation-timing-function', value, '');
  }

  /** Gets the value of "appearance" */
  String get appearance() =>
    getPropertyValue('${_browserPrefix}appearance');

  /** Sets the value of "appearance" */
  void set appearance(String value) {
    setProperty('${_browserPrefix}appearance', value, '');
  }

  /** Gets the value of "backface-visibility" */
  String get backfaceVisibility() =>
    getPropertyValue('${_browserPrefix}backface-visibility');

  /** Sets the value of "backface-visibility" */
  void set backfaceVisibility(String value) {
    setProperty('${_browserPrefix}backface-visibility', value, '');
  }

  /** Gets the value of "background" */
  String get background() =>
    getPropertyValue('background');

  /** Sets the value of "background" */
  void set background(String value) {
    setProperty('background', value, '');
  }

  /** Gets the value of "background-attachment" */
  String get backgroundAttachment() =>
    getPropertyValue('background-attachment');

  /** Sets the value of "background-attachment" */
  void set backgroundAttachment(String value) {
    setProperty('background-attachment', value, '');
  }

  /** Gets the value of "background-clip" */
  String get backgroundClip() =>
    getPropertyValue('background-clip');

  /** Sets the value of "background-clip" */
  void set backgroundClip(String value) {
    setProperty('background-clip', value, '');
  }

  /** Gets the value of "background-color" */
  String get backgroundColor() =>
    getPropertyValue('background-color');

  /** Sets the value of "background-color" */
  void set backgroundColor(String value) {
    setProperty('background-color', value, '');
  }

  /** Gets the value of "background-composite" */
  String get backgroundComposite() =>
    getPropertyValue('${_browserPrefix}background-composite');

  /** Sets the value of "background-composite" */
  void set backgroundComposite(String value) {
    setProperty('${_browserPrefix}background-composite', value, '');
  }

  /** Gets the value of "background-image" */
  String get backgroundImage() =>
    getPropertyValue('background-image');

  /** Sets the value of "background-image" */
  void set backgroundImage(String value) {
    setProperty('background-image', value, '');
  }

  /** Gets the value of "background-origin" */
  String get backgroundOrigin() =>
    getPropertyValue('background-origin');

  /** Sets the value of "background-origin" */
  void set backgroundOrigin(String value) {
    setProperty('background-origin', value, '');
  }

  /** Gets the value of "background-position" */
  String get backgroundPosition() =>
    getPropertyValue('background-position');

  /** Sets the value of "background-position" */
  void set backgroundPosition(String value) {
    setProperty('background-position', value, '');
  }

  /** Gets the value of "background-position-x" */
  String get backgroundPositionX() =>
    getPropertyValue('background-position-x');

  /** Sets the value of "background-position-x" */
  void set backgroundPositionX(String value) {
    setProperty('background-position-x', value, '');
  }

  /** Gets the value of "background-position-y" */
  String get backgroundPositionY() =>
    getPropertyValue('background-position-y');

  /** Sets the value of "background-position-y" */
  void set backgroundPositionY(String value) {
    setProperty('background-position-y', value, '');
  }

  /** Gets the value of "background-repeat" */
  String get backgroundRepeat() =>
    getPropertyValue('background-repeat');

  /** Sets the value of "background-repeat" */
  void set backgroundRepeat(String value) {
    setProperty('background-repeat', value, '');
  }

  /** Gets the value of "background-repeat-x" */
  String get backgroundRepeatX() =>
    getPropertyValue('background-repeat-x');

  /** Sets the value of "background-repeat-x" */
  void set backgroundRepeatX(String value) {
    setProperty('background-repeat-x', value, '');
  }

  /** Gets the value of "background-repeat-y" */
  String get backgroundRepeatY() =>
    getPropertyValue('background-repeat-y');

  /** Sets the value of "background-repeat-y" */
  void set backgroundRepeatY(String value) {
    setProperty('background-repeat-y', value, '');
  }

  /** Gets the value of "background-size" */
  String get backgroundSize() =>
    getPropertyValue('background-size');

  /** Sets the value of "background-size" */
  void set backgroundSize(String value) {
    setProperty('background-size', value, '');
  }

  /** Gets the value of "border" */
  String get border() =>
    getPropertyValue('border');

  /** Sets the value of "border" */
  void set border(String value) {
    setProperty('border', value, '');
  }

  /** Gets the value of "border-after" */
  String get borderAfter() =>
    getPropertyValue('${_browserPrefix}border-after');

  /** Sets the value of "border-after" */
  void set borderAfter(String value) {
    setProperty('${_browserPrefix}border-after', value, '');
  }

  /** Gets the value of "border-after-color" */
  String get borderAfterColor() =>
    getPropertyValue('${_browserPrefix}border-after-color');

  /** Sets the value of "border-after-color" */
  void set borderAfterColor(String value) {
    setProperty('${_browserPrefix}border-after-color', value, '');
  }

  /** Gets the value of "border-after-style" */
  String get borderAfterStyle() =>
    getPropertyValue('${_browserPrefix}border-after-style');

  /** Sets the value of "border-after-style" */
  void set borderAfterStyle(String value) {
    setProperty('${_browserPrefix}border-after-style', value, '');
  }

  /** Gets the value of "border-after-width" */
  String get borderAfterWidth() =>
    getPropertyValue('${_browserPrefix}border-after-width');

  /** Sets the value of "border-after-width" */
  void set borderAfterWidth(String value) {
    setProperty('${_browserPrefix}border-after-width', value, '');
  }

  /** Gets the value of "border-before" */
  String get borderBefore() =>
    getPropertyValue('${_browserPrefix}border-before');

  /** Sets the value of "border-before" */
  void set borderBefore(String value) {
    setProperty('${_browserPrefix}border-before', value, '');
  }

  /** Gets the value of "border-before-color" */
  String get borderBeforeColor() =>
    getPropertyValue('${_browserPrefix}border-before-color');

  /** Sets the value of "border-before-color" */
  void set borderBeforeColor(String value) {
    setProperty('${_browserPrefix}border-before-color', value, '');
  }

  /** Gets the value of "border-before-style" */
  String get borderBeforeStyle() =>
    getPropertyValue('${_browserPrefix}border-before-style');

  /** Sets the value of "border-before-style" */
  void set borderBeforeStyle(String value) {
    setProperty('${_browserPrefix}border-before-style', value, '');
  }

  /** Gets the value of "border-before-width" */
  String get borderBeforeWidth() =>
    getPropertyValue('${_browserPrefix}border-before-width');

  /** Sets the value of "border-before-width" */
  void set borderBeforeWidth(String value) {
    setProperty('${_browserPrefix}border-before-width', value, '');
  }

  /** Gets the value of "border-bottom" */
  String get borderBottom() =>
    getPropertyValue('border-bottom');

  /** Sets the value of "border-bottom" */
  void set borderBottom(String value) {
    setProperty('border-bottom', value, '');
  }

  /** Gets the value of "border-bottom-color" */
  String get borderBottomColor() =>
    getPropertyValue('border-bottom-color');

  /** Sets the value of "border-bottom-color" */
  void set borderBottomColor(String value) {
    setProperty('border-bottom-color', value, '');
  }

  /** Gets the value of "border-bottom-left-radius" */
  String get borderBottomLeftRadius() =>
    getPropertyValue('border-bottom-left-radius');

  /** Sets the value of "border-bottom-left-radius" */
  void set borderBottomLeftRadius(String value) {
    setProperty('border-bottom-left-radius', value, '');
  }

  /** Gets the value of "border-bottom-right-radius" */
  String get borderBottomRightRadius() =>
    getPropertyValue('border-bottom-right-radius');

  /** Sets the value of "border-bottom-right-radius" */
  void set borderBottomRightRadius(String value) {
    setProperty('border-bottom-right-radius', value, '');
  }

  /** Gets the value of "border-bottom-style" */
  String get borderBottomStyle() =>
    getPropertyValue('border-bottom-style');

  /** Sets the value of "border-bottom-style" */
  void set borderBottomStyle(String value) {
    setProperty('border-bottom-style', value, '');
  }

  /** Gets the value of "border-bottom-width" */
  String get borderBottomWidth() =>
    getPropertyValue('border-bottom-width');

  /** Sets the value of "border-bottom-width" */
  void set borderBottomWidth(String value) {
    setProperty('border-bottom-width', value, '');
  }

  /** Gets the value of "border-collapse" */
  String get borderCollapse() =>
    getPropertyValue('border-collapse');

  /** Sets the value of "border-collapse" */
  void set borderCollapse(String value) {
    setProperty('border-collapse', value, '');
  }

  /** Gets the value of "border-color" */
  String get borderColor() =>
    getPropertyValue('border-color');

  /** Sets the value of "border-color" */
  void set borderColor(String value) {
    setProperty('border-color', value, '');
  }

  /** Gets the value of "border-end" */
  String get borderEnd() =>
    getPropertyValue('${_browserPrefix}border-end');

  /** Sets the value of "border-end" */
  void set borderEnd(String value) {
    setProperty('${_browserPrefix}border-end', value, '');
  }

  /** Gets the value of "border-end-color" */
  String get borderEndColor() =>
    getPropertyValue('${_browserPrefix}border-end-color');

  /** Sets the value of "border-end-color" */
  void set borderEndColor(String value) {
    setProperty('${_browserPrefix}border-end-color', value, '');
  }

  /** Gets the value of "border-end-style" */
  String get borderEndStyle() =>
    getPropertyValue('${_browserPrefix}border-end-style');

  /** Sets the value of "border-end-style" */
  void set borderEndStyle(String value) {
    setProperty('${_browserPrefix}border-end-style', value, '');
  }

  /** Gets the value of "border-end-width" */
  String get borderEndWidth() =>
    getPropertyValue('${_browserPrefix}border-end-width');

  /** Sets the value of "border-end-width" */
  void set borderEndWidth(String value) {
    setProperty('${_browserPrefix}border-end-width', value, '');
  }

  /** Gets the value of "border-fit" */
  String get borderFit() =>
    getPropertyValue('${_browserPrefix}border-fit');

  /** Sets the value of "border-fit" */
  void set borderFit(String value) {
    setProperty('${_browserPrefix}border-fit', value, '');
  }

  /** Gets the value of "border-horizontal-spacing" */
  String get borderHorizontalSpacing() =>
    getPropertyValue('${_browserPrefix}border-horizontal-spacing');

  /** Sets the value of "border-horizontal-spacing" */
  void set borderHorizontalSpacing(String value) {
    setProperty('${_browserPrefix}border-horizontal-spacing', value, '');
  }

  /** Gets the value of "border-image" */
  String get borderImage() =>
    getPropertyValue('border-image');

  /** Sets the value of "border-image" */
  void set borderImage(String value) {
    setProperty('border-image', value, '');
  }

  /** Gets the value of "border-image-outset" */
  String get borderImageOutset() =>
    getPropertyValue('border-image-outset');

  /** Sets the value of "border-image-outset" */
  void set borderImageOutset(String value) {
    setProperty('border-image-outset', value, '');
  }

  /** Gets the value of "border-image-repeat" */
  String get borderImageRepeat() =>
    getPropertyValue('border-image-repeat');

  /** Sets the value of "border-image-repeat" */
  void set borderImageRepeat(String value) {
    setProperty('border-image-repeat', value, '');
  }

  /** Gets the value of "border-image-slice" */
  String get borderImageSlice() =>
    getPropertyValue('border-image-slice');

  /** Sets the value of "border-image-slice" */
  void set borderImageSlice(String value) {
    setProperty('border-image-slice', value, '');
  }

  /** Gets the value of "border-image-source" */
  String get borderImageSource() =>
    getPropertyValue('border-image-source');

  /** Sets the value of "border-image-source" */
  void set borderImageSource(String value) {
    setProperty('border-image-source', value, '');
  }

  /** Gets the value of "border-image-width" */
  String get borderImageWidth() =>
    getPropertyValue('border-image-width');

  /** Sets the value of "border-image-width" */
  void set borderImageWidth(String value) {
    setProperty('border-image-width', value, '');
  }

  /** Gets the value of "border-left" */
  String get borderLeft() =>
    getPropertyValue('border-left');

  /** Sets the value of "border-left" */
  void set borderLeft(String value) {
    setProperty('border-left', value, '');
  }

  /** Gets the value of "border-left-color" */
  String get borderLeftColor() =>
    getPropertyValue('border-left-color');

  /** Sets the value of "border-left-color" */
  void set borderLeftColor(String value) {
    setProperty('border-left-color', value, '');
  }

  /** Gets the value of "border-left-style" */
  String get borderLeftStyle() =>
    getPropertyValue('border-left-style');

  /** Sets the value of "border-left-style" */
  void set borderLeftStyle(String value) {
    setProperty('border-left-style', value, '');
  }

  /** Gets the value of "border-left-width" */
  String get borderLeftWidth() =>
    getPropertyValue('border-left-width');

  /** Sets the value of "border-left-width" */
  void set borderLeftWidth(String value) {
    setProperty('border-left-width', value, '');
  }

  /** Gets the value of "border-radius" */
  String get borderRadius() =>
    getPropertyValue('border-radius');

  /** Sets the value of "border-radius" */
  void set borderRadius(String value) {
    setProperty('border-radius', value, '');
  }

  /** Gets the value of "border-right" */
  String get borderRight() =>
    getPropertyValue('border-right');

  /** Sets the value of "border-right" */
  void set borderRight(String value) {
    setProperty('border-right', value, '');
  }

  /** Gets the value of "border-right-color" */
  String get borderRightColor() =>
    getPropertyValue('border-right-color');

  /** Sets the value of "border-right-color" */
  void set borderRightColor(String value) {
    setProperty('border-right-color', value, '');
  }

  /** Gets the value of "border-right-style" */
  String get borderRightStyle() =>
    getPropertyValue('border-right-style');

  /** Sets the value of "border-right-style" */
  void set borderRightStyle(String value) {
    setProperty('border-right-style', value, '');
  }

  /** Gets the value of "border-right-width" */
  String get borderRightWidth() =>
    getPropertyValue('border-right-width');

  /** Sets the value of "border-right-width" */
  void set borderRightWidth(String value) {
    setProperty('border-right-width', value, '');
  }

  /** Gets the value of "border-spacing" */
  String get borderSpacing() =>
    getPropertyValue('border-spacing');

  /** Sets the value of "border-spacing" */
  void set borderSpacing(String value) {
    setProperty('border-spacing', value, '');
  }

  /** Gets the value of "border-start" */
  String get borderStart() =>
    getPropertyValue('${_browserPrefix}border-start');

  /** Sets the value of "border-start" */
  void set borderStart(String value) {
    setProperty('${_browserPrefix}border-start', value, '');
  }

  /** Gets the value of "border-start-color" */
  String get borderStartColor() =>
    getPropertyValue('${_browserPrefix}border-start-color');

  /** Sets the value of "border-start-color" */
  void set borderStartColor(String value) {
    setProperty('${_browserPrefix}border-start-color', value, '');
  }

  /** Gets the value of "border-start-style" */
  String get borderStartStyle() =>
    getPropertyValue('${_browserPrefix}border-start-style');

  /** Sets the value of "border-start-style" */
  void set borderStartStyle(String value) {
    setProperty('${_browserPrefix}border-start-style', value, '');
  }

  /** Gets the value of "border-start-width" */
  String get borderStartWidth() =>
    getPropertyValue('${_browserPrefix}border-start-width');

  /** Sets the value of "border-start-width" */
  void set borderStartWidth(String value) {
    setProperty('${_browserPrefix}border-start-width', value, '');
  }

  /** Gets the value of "border-style" */
  String get borderStyle() =>
    getPropertyValue('border-style');

  /** Sets the value of "border-style" */
  void set borderStyle(String value) {
    setProperty('border-style', value, '');
  }

  /** Gets the value of "border-top" */
  String get borderTop() =>
    getPropertyValue('border-top');

  /** Sets the value of "border-top" */
  void set borderTop(String value) {
    setProperty('border-top', value, '');
  }

  /** Gets the value of "border-top-color" */
  String get borderTopColor() =>
    getPropertyValue('border-top-color');

  /** Sets the value of "border-top-color" */
  void set borderTopColor(String value) {
    setProperty('border-top-color', value, '');
  }

  /** Gets the value of "border-top-left-radius" */
  String get borderTopLeftRadius() =>
    getPropertyValue('border-top-left-radius');

  /** Sets the value of "border-top-left-radius" */
  void set borderTopLeftRadius(String value) {
    setProperty('border-top-left-radius', value, '');
  }

  /** Gets the value of "border-top-right-radius" */
  String get borderTopRightRadius() =>
    getPropertyValue('border-top-right-radius');

  /** Sets the value of "border-top-right-radius" */
  void set borderTopRightRadius(String value) {
    setProperty('border-top-right-radius', value, '');
  }

  /** Gets the value of "border-top-style" */
  String get borderTopStyle() =>
    getPropertyValue('border-top-style');

  /** Sets the value of "border-top-style" */
  void set borderTopStyle(String value) {
    setProperty('border-top-style', value, '');
  }

  /** Gets the value of "border-top-width" */
  String get borderTopWidth() =>
    getPropertyValue('border-top-width');

  /** Sets the value of "border-top-width" */
  void set borderTopWidth(String value) {
    setProperty('border-top-width', value, '');
  }

  /** Gets the value of "border-vertical-spacing" */
  String get borderVerticalSpacing() =>
    getPropertyValue('${_browserPrefix}border-vertical-spacing');

  /** Sets the value of "border-vertical-spacing" */
  void set borderVerticalSpacing(String value) {
    setProperty('${_browserPrefix}border-vertical-spacing', value, '');
  }

  /** Gets the value of "border-width" */
  String get borderWidth() =>
    getPropertyValue('border-width');

  /** Sets the value of "border-width" */
  void set borderWidth(String value) {
    setProperty('border-width', value, '');
  }

  /** Gets the value of "bottom" */
  String get bottom() =>
    getPropertyValue('bottom');

  /** Sets the value of "bottom" */
  void set bottom(String value) {
    setProperty('bottom', value, '');
  }

  /** Gets the value of "box-align" */
  String get boxAlign() =>
    getPropertyValue('${_browserPrefix}box-align');

  /** Sets the value of "box-align" */
  void set boxAlign(String value) {
    setProperty('${_browserPrefix}box-align', value, '');
  }

  /** Gets the value of "box-direction" */
  String get boxDirection() =>
    getPropertyValue('${_browserPrefix}box-direction');

  /** Sets the value of "box-direction" */
  void set boxDirection(String value) {
    setProperty('${_browserPrefix}box-direction', value, '');
  }

  /** Gets the value of "box-flex" */
  String get boxFlex() =>
    getPropertyValue('${_browserPrefix}box-flex');

  /** Sets the value of "box-flex" */
  void set boxFlex(String value) {
    setProperty('${_browserPrefix}box-flex', value, '');
  }

  /** Gets the value of "box-flex-group" */
  String get boxFlexGroup() =>
    getPropertyValue('${_browserPrefix}box-flex-group');

  /** Sets the value of "box-flex-group" */
  void set boxFlexGroup(String value) {
    setProperty('${_browserPrefix}box-flex-group', value, '');
  }

  /** Gets the value of "box-lines" */
  String get boxLines() =>
    getPropertyValue('${_browserPrefix}box-lines');

  /** Sets the value of "box-lines" */
  void set boxLines(String value) {
    setProperty('${_browserPrefix}box-lines', value, '');
  }

  /** Gets the value of "box-ordinal-group" */
  String get boxOrdinalGroup() =>
    getPropertyValue('${_browserPrefix}box-ordinal-group');

  /** Sets the value of "box-ordinal-group" */
  void set boxOrdinalGroup(String value) {
    setProperty('${_browserPrefix}box-ordinal-group', value, '');
  }

  /** Gets the value of "box-orient" */
  String get boxOrient() =>
    getPropertyValue('${_browserPrefix}box-orient');

  /** Sets the value of "box-orient" */
  void set boxOrient(String value) {
    setProperty('${_browserPrefix}box-orient', value, '');
  }

  /** Gets the value of "box-pack" */
  String get boxPack() =>
    getPropertyValue('${_browserPrefix}box-pack');

  /** Sets the value of "box-pack" */
  void set boxPack(String value) {
    setProperty('${_browserPrefix}box-pack', value, '');
  }

  /** Gets the value of "box-reflect" */
  String get boxReflect() =>
    getPropertyValue('${_browserPrefix}box-reflect');

  /** Sets the value of "box-reflect" */
  void set boxReflect(String value) {
    setProperty('${_browserPrefix}box-reflect', value, '');
  }

  /** Gets the value of "box-shadow" */
  String get boxShadow() =>
    getPropertyValue('box-shadow');

  /** Sets the value of "box-shadow" */
  void set boxShadow(String value) {
    setProperty('box-shadow', value, '');
  }

  /** Gets the value of "box-sizing" */
  String get boxSizing() =>
    getPropertyValue('box-sizing');

  /** Sets the value of "box-sizing" */
  void set boxSizing(String value) {
    setProperty('box-sizing', value, '');
  }

  /** Gets the value of "caption-side" */
  String get captionSide() =>
    getPropertyValue('caption-side');

  /** Sets the value of "caption-side" */
  void set captionSide(String value) {
    setProperty('caption-side', value, '');
  }

  /** Gets the value of "clear" */
  String get clear() =>
    getPropertyValue('clear');

  /** Sets the value of "clear" */
  void set clear(String value) {
    setProperty('clear', value, '');
  }

  /** Gets the value of "clip" */
  String get clip() =>
    getPropertyValue('clip');

  /** Sets the value of "clip" */
  void set clip(String value) {
    setProperty('clip', value, '');
  }

  /** Gets the value of "color" */
  String get color() =>
    getPropertyValue('color');

  /** Sets the value of "color" */
  void set color(String value) {
    setProperty('color', value, '');
  }

  /** Gets the value of "color-correction" */
  String get colorCorrection() =>
    getPropertyValue('${_browserPrefix}color-correction');

  /** Sets the value of "color-correction" */
  void set colorCorrection(String value) {
    setProperty('${_browserPrefix}color-correction', value, '');
  }

  /** Gets the value of "column-break-after" */
  String get columnBreakAfter() =>
    getPropertyValue('${_browserPrefix}column-break-after');

  /** Sets the value of "column-break-after" */
  void set columnBreakAfter(String value) {
    setProperty('${_browserPrefix}column-break-after', value, '');
  }

  /** Gets the value of "column-break-before" */
  String get columnBreakBefore() =>
    getPropertyValue('${_browserPrefix}column-break-before');

  /** Sets the value of "column-break-before" */
  void set columnBreakBefore(String value) {
    setProperty('${_browserPrefix}column-break-before', value, '');
  }

  /** Gets the value of "column-break-inside" */
  String get columnBreakInside() =>
    getPropertyValue('${_browserPrefix}column-break-inside');

  /** Sets the value of "column-break-inside" */
  void set columnBreakInside(String value) {
    setProperty('${_browserPrefix}column-break-inside', value, '');
  }

  /** Gets the value of "column-count" */
  String get columnCount() =>
    getPropertyValue('${_browserPrefix}column-count');

  /** Sets the value of "column-count" */
  void set columnCount(String value) {
    setProperty('${_browserPrefix}column-count', value, '');
  }

  /** Gets the value of "column-gap" */
  String get columnGap() =>
    getPropertyValue('${_browserPrefix}column-gap');

  /** Sets the value of "column-gap" */
  void set columnGap(String value) {
    setProperty('${_browserPrefix}column-gap', value, '');
  }

  /** Gets the value of "column-rule" */
  String get columnRule() =>
    getPropertyValue('${_browserPrefix}column-rule');

  /** Sets the value of "column-rule" */
  void set columnRule(String value) {
    setProperty('${_browserPrefix}column-rule', value, '');
  }

  /** Gets the value of "column-rule-color" */
  String get columnRuleColor() =>
    getPropertyValue('${_browserPrefix}column-rule-color');

  /** Sets the value of "column-rule-color" */
  void set columnRuleColor(String value) {
    setProperty('${_browserPrefix}column-rule-color', value, '');
  }

  /** Gets the value of "column-rule-style" */
  String get columnRuleStyle() =>
    getPropertyValue('${_browserPrefix}column-rule-style');

  /** Sets the value of "column-rule-style" */
  void set columnRuleStyle(String value) {
    setProperty('${_browserPrefix}column-rule-style', value, '');
  }

  /** Gets the value of "column-rule-width" */
  String get columnRuleWidth() =>
    getPropertyValue('${_browserPrefix}column-rule-width');

  /** Sets the value of "column-rule-width" */
  void set columnRuleWidth(String value) {
    setProperty('${_browserPrefix}column-rule-width', value, '');
  }

  /** Gets the value of "column-span" */
  String get columnSpan() =>
    getPropertyValue('${_browserPrefix}column-span');

  /** Sets the value of "column-span" */
  void set columnSpan(String value) {
    setProperty('${_browserPrefix}column-span', value, '');
  }

  /** Gets the value of "column-width" */
  String get columnWidth() =>
    getPropertyValue('${_browserPrefix}column-width');

  /** Sets the value of "column-width" */
  void set columnWidth(String value) {
    setProperty('${_browserPrefix}column-width', value, '');
  }

  /** Gets the value of "columns" */
  String get columns() =>
    getPropertyValue('${_browserPrefix}columns');

  /** Sets the value of "columns" */
  void set columns(String value) {
    setProperty('${_browserPrefix}columns', value, '');
  }

  /** Gets the value of "content" */
  String get content() =>
    getPropertyValue('content');

  /** Sets the value of "content" */
  void set content(String value) {
    setProperty('content', value, '');
  }

  /** Gets the value of "counter-increment" */
  String get counterIncrement() =>
    getPropertyValue('counter-increment');

  /** Sets the value of "counter-increment" */
  void set counterIncrement(String value) {
    setProperty('counter-increment', value, '');
  }

  /** Gets the value of "counter-reset" */
  String get counterReset() =>
    getPropertyValue('counter-reset');

  /** Sets the value of "counter-reset" */
  void set counterReset(String value) {
    setProperty('counter-reset', value, '');
  }

  /** Gets the value of "cursor" */
  String get cursor() =>
    getPropertyValue('cursor');

  /** Sets the value of "cursor" */
  void set cursor(String value) {
    setProperty('cursor', value, '');
  }

  /** Gets the value of "direction" */
  String get direction() =>
    getPropertyValue('direction');

  /** Sets the value of "direction" */
  void set direction(String value) {
    setProperty('direction', value, '');
  }

  /** Gets the value of "display" */
  String get display() =>
    getPropertyValue('display');

  /** Sets the value of "display" */
  void set display(String value) {
    setProperty('display', value, '');
  }

  /** Gets the value of "empty-cells" */
  String get emptyCells() =>
    getPropertyValue('empty-cells');

  /** Sets the value of "empty-cells" */
  void set emptyCells(String value) {
    setProperty('empty-cells', value, '');
  }

  /** Gets the value of "filter" */
  String get filter() =>
    getPropertyValue('${_browserPrefix}filter');

  /** Sets the value of "filter" */
  void set filter(String value) {
    setProperty('${_browserPrefix}filter', value, '');
  }

  /** Gets the value of "flex-align" */
  String get flexAlign() =>
    getPropertyValue('${_browserPrefix}flex-align');

  /** Sets the value of "flex-align" */
  void set flexAlign(String value) {
    setProperty('${_browserPrefix}flex-align', value, '');
  }

  /** Gets the value of "flex-flow" */
  String get flexFlow() =>
    getPropertyValue('${_browserPrefix}flex-flow');

  /** Sets the value of "flex-flow" */
  void set flexFlow(String value) {
    setProperty('${_browserPrefix}flex-flow', value, '');
  }

  /** Gets the value of "flex-order" */
  String get flexOrder() =>
    getPropertyValue('${_browserPrefix}flex-order');

  /** Sets the value of "flex-order" */
  void set flexOrder(String value) {
    setProperty('${_browserPrefix}flex-order', value, '');
  }

  /** Gets the value of "flex-pack" */
  String get flexPack() =>
    getPropertyValue('${_browserPrefix}flex-pack');

  /** Sets the value of "flex-pack" */
  void set flexPack(String value) {
    setProperty('${_browserPrefix}flex-pack', value, '');
  }

  /** Gets the value of "float" */
  String get float() =>
    getPropertyValue('float');

  /** Sets the value of "float" */
  void set float(String value) {
    setProperty('float', value, '');
  }

  /** Gets the value of "flow-from" */
  String get flowFrom() =>
    getPropertyValue('${_browserPrefix}flow-from');

  /** Sets the value of "flow-from" */
  void set flowFrom(String value) {
    setProperty('${_browserPrefix}flow-from', value, '');
  }

  /** Gets the value of "flow-into" */
  String get flowInto() =>
    getPropertyValue('${_browserPrefix}flow-into');

  /** Sets the value of "flow-into" */
  void set flowInto(String value) {
    setProperty('${_browserPrefix}flow-into', value, '');
  }

  /** Gets the value of "font" */
  String get font() =>
    getPropertyValue('font');

  /** Sets the value of "font" */
  void set font(String value) {
    setProperty('font', value, '');
  }

  /** Gets the value of "font-family" */
  String get fontFamily() =>
    getPropertyValue('font-family');

  /** Sets the value of "font-family" */
  void set fontFamily(String value) {
    setProperty('font-family', value, '');
  }

  /** Gets the value of "font-feature-settings" */
  String get fontFeatureSettings() =>
    getPropertyValue('${_browserPrefix}font-feature-settings');

  /** Sets the value of "font-feature-settings" */
  void set fontFeatureSettings(String value) {
    setProperty('${_browserPrefix}font-feature-settings', value, '');
  }

  /** Gets the value of "font-size" */
  String get fontSize() =>
    getPropertyValue('font-size');

  /** Sets the value of "font-size" */
  void set fontSize(String value) {
    setProperty('font-size', value, '');
  }

  /** Gets the value of "font-size-delta" */
  String get fontSizeDelta() =>
    getPropertyValue('${_browserPrefix}font-size-delta');

  /** Sets the value of "font-size-delta" */
  void set fontSizeDelta(String value) {
    setProperty('${_browserPrefix}font-size-delta', value, '');
  }

  /** Gets the value of "font-smoothing" */
  String get fontSmoothing() =>
    getPropertyValue('${_browserPrefix}font-smoothing');

  /** Sets the value of "font-smoothing" */
  void set fontSmoothing(String value) {
    setProperty('${_browserPrefix}font-smoothing', value, '');
  }

  /** Gets the value of "font-stretch" */
  String get fontStretch() =>
    getPropertyValue('font-stretch');

  /** Sets the value of "font-stretch" */
  void set fontStretch(String value) {
    setProperty('font-stretch', value, '');
  }

  /** Gets the value of "font-style" */
  String get fontStyle() =>
    getPropertyValue('font-style');

  /** Sets the value of "font-style" */
  void set fontStyle(String value) {
    setProperty('font-style', value, '');
  }

  /** Gets the value of "font-variant" */
  String get fontVariant() =>
    getPropertyValue('font-variant');

  /** Sets the value of "font-variant" */
  void set fontVariant(String value) {
    setProperty('font-variant', value, '');
  }

  /** Gets the value of "font-weight" */
  String get fontWeight() =>
    getPropertyValue('font-weight');

  /** Sets the value of "font-weight" */
  void set fontWeight(String value) {
    setProperty('font-weight', value, '');
  }

  /** Gets the value of "height" */
  String get height() =>
    getPropertyValue('height');

  /** Sets the value of "height" */
  void set height(String value) {
    setProperty('height', value, '');
  }

  /** Gets the value of "highlight" */
  String get highlight() =>
    getPropertyValue('${_browserPrefix}highlight');

  /** Sets the value of "highlight" */
  void set highlight(String value) {
    setProperty('${_browserPrefix}highlight', value, '');
  }

  /** Gets the value of "hyphenate-character" */
  String get hyphenateCharacter() =>
    getPropertyValue('${_browserPrefix}hyphenate-character');

  /** Sets the value of "hyphenate-character" */
  void set hyphenateCharacter(String value) {
    setProperty('${_browserPrefix}hyphenate-character', value, '');
  }

  /** Gets the value of "hyphenate-limit-after" */
  String get hyphenateLimitAfter() =>
    getPropertyValue('${_browserPrefix}hyphenate-limit-after');

  /** Sets the value of "hyphenate-limit-after" */
  void set hyphenateLimitAfter(String value) {
    setProperty('${_browserPrefix}hyphenate-limit-after', value, '');
  }

  /** Gets the value of "hyphenate-limit-before" */
  String get hyphenateLimitBefore() =>
    getPropertyValue('${_browserPrefix}hyphenate-limit-before');

  /** Sets the value of "hyphenate-limit-before" */
  void set hyphenateLimitBefore(String value) {
    setProperty('${_browserPrefix}hyphenate-limit-before', value, '');
  }

  /** Gets the value of "hyphenate-limit-lines" */
  String get hyphenateLimitLines() =>
    getPropertyValue('${_browserPrefix}hyphenate-limit-lines');

  /** Sets the value of "hyphenate-limit-lines" */
  void set hyphenateLimitLines(String value) {
    setProperty('${_browserPrefix}hyphenate-limit-lines', value, '');
  }

  /** Gets the value of "hyphens" */
  String get hyphens() =>
    getPropertyValue('${_browserPrefix}hyphens');

  /** Sets the value of "hyphens" */
  void set hyphens(String value) {
    setProperty('${_browserPrefix}hyphens', value, '');
  }

  /** Gets the value of "image-rendering" */
  String get imageRendering() =>
    getPropertyValue('image-rendering');

  /** Sets the value of "image-rendering" */
  void set imageRendering(String value) {
    setProperty('image-rendering', value, '');
  }

  /** Gets the value of "left" */
  String get left() =>
    getPropertyValue('left');

  /** Sets the value of "left" */
  void set left(String value) {
    setProperty('left', value, '');
  }

  /** Gets the value of "letter-spacing" */
  String get letterSpacing() =>
    getPropertyValue('letter-spacing');

  /** Sets the value of "letter-spacing" */
  void set letterSpacing(String value) {
    setProperty('letter-spacing', value, '');
  }

  /** Gets the value of "line-box-contain" */
  String get lineBoxContain() =>
    getPropertyValue('${_browserPrefix}line-box-contain');

  /** Sets the value of "line-box-contain" */
  void set lineBoxContain(String value) {
    setProperty('${_browserPrefix}line-box-contain', value, '');
  }

  /** Gets the value of "line-break" */
  String get lineBreak() =>
    getPropertyValue('${_browserPrefix}line-break');

  /** Sets the value of "line-break" */
  void set lineBreak(String value) {
    setProperty('${_browserPrefix}line-break', value, '');
  }

  /** Gets the value of "line-clamp" */
  String get lineClamp() =>
    getPropertyValue('${_browserPrefix}line-clamp');

  /** Sets the value of "line-clamp" */
  void set lineClamp(String value) {
    setProperty('${_browserPrefix}line-clamp', value, '');
  }

  /** Gets the value of "line-height" */
  String get lineHeight() =>
    getPropertyValue('line-height');

  /** Sets the value of "line-height" */
  void set lineHeight(String value) {
    setProperty('line-height', value, '');
  }

  /** Gets the value of "list-style" */
  String get listStyle() =>
    getPropertyValue('list-style');

  /** Sets the value of "list-style" */
  void set listStyle(String value) {
    setProperty('list-style', value, '');
  }

  /** Gets the value of "list-style-image" */
  String get listStyleImage() =>
    getPropertyValue('list-style-image');

  /** Sets the value of "list-style-image" */
  void set listStyleImage(String value) {
    setProperty('list-style-image', value, '');
  }

  /** Gets the value of "list-style-position" */
  String get listStylePosition() =>
    getPropertyValue('list-style-position');

  /** Sets the value of "list-style-position" */
  void set listStylePosition(String value) {
    setProperty('list-style-position', value, '');
  }

  /** Gets the value of "list-style-type" */
  String get listStyleType() =>
    getPropertyValue('list-style-type');

  /** Sets the value of "list-style-type" */
  void set listStyleType(String value) {
    setProperty('list-style-type', value, '');
  }

  /** Gets the value of "locale" */
  String get locale() =>
    getPropertyValue('${_browserPrefix}locale');

  /** Sets the value of "locale" */
  void set locale(String value) {
    setProperty('${_browserPrefix}locale', value, '');
  }

  /** Gets the value of "logical-height" */
  String get logicalHeight() =>
    getPropertyValue('${_browserPrefix}logical-height');

  /** Sets the value of "logical-height" */
  void set logicalHeight(String value) {
    setProperty('${_browserPrefix}logical-height', value, '');
  }

  /** Gets the value of "logical-width" */
  String get logicalWidth() =>
    getPropertyValue('${_browserPrefix}logical-width');

  /** Sets the value of "logical-width" */
  void set logicalWidth(String value) {
    setProperty('${_browserPrefix}logical-width', value, '');
  }

  /** Gets the value of "margin" */
  String get margin() =>
    getPropertyValue('margin');

  /** Sets the value of "margin" */
  void set margin(String value) {
    setProperty('margin', value, '');
  }

  /** Gets the value of "margin-after" */
  String get marginAfter() =>
    getPropertyValue('${_browserPrefix}margin-after');

  /** Sets the value of "margin-after" */
  void set marginAfter(String value) {
    setProperty('${_browserPrefix}margin-after', value, '');
  }

  /** Gets the value of "margin-after-collapse" */
  String get marginAfterCollapse() =>
    getPropertyValue('${_browserPrefix}margin-after-collapse');

  /** Sets the value of "margin-after-collapse" */
  void set marginAfterCollapse(String value) {
    setProperty('${_browserPrefix}margin-after-collapse', value, '');
  }

  /** Gets the value of "margin-before" */
  String get marginBefore() =>
    getPropertyValue('${_browserPrefix}margin-before');

  /** Sets the value of "margin-before" */
  void set marginBefore(String value) {
    setProperty('${_browserPrefix}margin-before', value, '');
  }

  /** Gets the value of "margin-before-collapse" */
  String get marginBeforeCollapse() =>
    getPropertyValue('${_browserPrefix}margin-before-collapse');

  /** Sets the value of "margin-before-collapse" */
  void set marginBeforeCollapse(String value) {
    setProperty('${_browserPrefix}margin-before-collapse', value, '');
  }

  /** Gets the value of "margin-bottom" */
  String get marginBottom() =>
    getPropertyValue('margin-bottom');

  /** Sets the value of "margin-bottom" */
  void set marginBottom(String value) {
    setProperty('margin-bottom', value, '');
  }

  /** Gets the value of "margin-bottom-collapse" */
  String get marginBottomCollapse() =>
    getPropertyValue('${_browserPrefix}margin-bottom-collapse');

  /** Sets the value of "margin-bottom-collapse" */
  void set marginBottomCollapse(String value) {
    setProperty('${_browserPrefix}margin-bottom-collapse', value, '');
  }

  /** Gets the value of "margin-collapse" */
  String get marginCollapse() =>
    getPropertyValue('${_browserPrefix}margin-collapse');

  /** Sets the value of "margin-collapse" */
  void set marginCollapse(String value) {
    setProperty('${_browserPrefix}margin-collapse', value, '');
  }

  /** Gets the value of "margin-end" */
  String get marginEnd() =>
    getPropertyValue('${_browserPrefix}margin-end');

  /** Sets the value of "margin-end" */
  void set marginEnd(String value) {
    setProperty('${_browserPrefix}margin-end', value, '');
  }

  /** Gets the value of "margin-left" */
  String get marginLeft() =>
    getPropertyValue('margin-left');

  /** Sets the value of "margin-left" */
  void set marginLeft(String value) {
    setProperty('margin-left', value, '');
  }

  /** Gets the value of "margin-right" */
  String get marginRight() =>
    getPropertyValue('margin-right');

  /** Sets the value of "margin-right" */
  void set marginRight(String value) {
    setProperty('margin-right', value, '');
  }

  /** Gets the value of "margin-start" */
  String get marginStart() =>
    getPropertyValue('${_browserPrefix}margin-start');

  /** Sets the value of "margin-start" */
  void set marginStart(String value) {
    setProperty('${_browserPrefix}margin-start', value, '');
  }

  /** Gets the value of "margin-top" */
  String get marginTop() =>
    getPropertyValue('margin-top');

  /** Sets the value of "margin-top" */
  void set marginTop(String value) {
    setProperty('margin-top', value, '');
  }

  /** Gets the value of "margin-top-collapse" */
  String get marginTopCollapse() =>
    getPropertyValue('${_browserPrefix}margin-top-collapse');

  /** Sets the value of "margin-top-collapse" */
  void set marginTopCollapse(String value) {
    setProperty('${_browserPrefix}margin-top-collapse', value, '');
  }

  /** Gets the value of "marquee" */
  String get marquee() =>
    getPropertyValue('${_browserPrefix}marquee');

  /** Sets the value of "marquee" */
  void set marquee(String value) {
    setProperty('${_browserPrefix}marquee', value, '');
  }

  /** Gets the value of "marquee-direction" */
  String get marqueeDirection() =>
    getPropertyValue('${_browserPrefix}marquee-direction');

  /** Sets the value of "marquee-direction" */
  void set marqueeDirection(String value) {
    setProperty('${_browserPrefix}marquee-direction', value, '');
  }

  /** Gets the value of "marquee-increment" */
  String get marqueeIncrement() =>
    getPropertyValue('${_browserPrefix}marquee-increment');

  /** Sets the value of "marquee-increment" */
  void set marqueeIncrement(String value) {
    setProperty('${_browserPrefix}marquee-increment', value, '');
  }

  /** Gets the value of "marquee-repetition" */
  String get marqueeRepetition() =>
    getPropertyValue('${_browserPrefix}marquee-repetition');

  /** Sets the value of "marquee-repetition" */
  void set marqueeRepetition(String value) {
    setProperty('${_browserPrefix}marquee-repetition', value, '');
  }

  /** Gets the value of "marquee-speed" */
  String get marqueeSpeed() =>
    getPropertyValue('${_browserPrefix}marquee-speed');

  /** Sets the value of "marquee-speed" */
  void set marqueeSpeed(String value) {
    setProperty('${_browserPrefix}marquee-speed', value, '');
  }

  /** Gets the value of "marquee-style" */
  String get marqueeStyle() =>
    getPropertyValue('${_browserPrefix}marquee-style');

  /** Sets the value of "marquee-style" */
  void set marqueeStyle(String value) {
    setProperty('${_browserPrefix}marquee-style', value, '');
  }

  /** Gets the value of "mask" */
  String get mask() =>
    getPropertyValue('${_browserPrefix}mask');

  /** Sets the value of "mask" */
  void set mask(String value) {
    setProperty('${_browserPrefix}mask', value, '');
  }

  /** Gets the value of "mask-attachment" */
  String get maskAttachment() =>
    getPropertyValue('${_browserPrefix}mask-attachment');

  /** Sets the value of "mask-attachment" */
  void set maskAttachment(String value) {
    setProperty('${_browserPrefix}mask-attachment', value, '');
  }

  /** Gets the value of "mask-box-image" */
  String get maskBoxImage() =>
    getPropertyValue('${_browserPrefix}mask-box-image');

  /** Sets the value of "mask-box-image" */
  void set maskBoxImage(String value) {
    setProperty('${_browserPrefix}mask-box-image', value, '');
  }

  /** Gets the value of "mask-box-image-outset" */
  String get maskBoxImageOutset() =>
    getPropertyValue('${_browserPrefix}mask-box-image-outset');

  /** Sets the value of "mask-box-image-outset" */
  void set maskBoxImageOutset(String value) {
    setProperty('${_browserPrefix}mask-box-image-outset', value, '');
  }

  /** Gets the value of "mask-box-image-repeat" */
  String get maskBoxImageRepeat() =>
    getPropertyValue('${_browserPrefix}mask-box-image-repeat');

  /** Sets the value of "mask-box-image-repeat" */
  void set maskBoxImageRepeat(String value) {
    setProperty('${_browserPrefix}mask-box-image-repeat', value, '');
  }

  /** Gets the value of "mask-box-image-slice" */
  String get maskBoxImageSlice() =>
    getPropertyValue('${_browserPrefix}mask-box-image-slice');

  /** Sets the value of "mask-box-image-slice" */
  void set maskBoxImageSlice(String value) {
    setProperty('${_browserPrefix}mask-box-image-slice', value, '');
  }

  /** Gets the value of "mask-box-image-source" */
  String get maskBoxImageSource() =>
    getPropertyValue('${_browserPrefix}mask-box-image-source');

  /** Sets the value of "mask-box-image-source" */
  void set maskBoxImageSource(String value) {
    setProperty('${_browserPrefix}mask-box-image-source', value, '');
  }

  /** Gets the value of "mask-box-image-width" */
  String get maskBoxImageWidth() =>
    getPropertyValue('${_browserPrefix}mask-box-image-width');

  /** Sets the value of "mask-box-image-width" */
  void set maskBoxImageWidth(String value) {
    setProperty('${_browserPrefix}mask-box-image-width', value, '');
  }

  /** Gets the value of "mask-clip" */
  String get maskClip() =>
    getPropertyValue('${_browserPrefix}mask-clip');

  /** Sets the value of "mask-clip" */
  void set maskClip(String value) {
    setProperty('${_browserPrefix}mask-clip', value, '');
  }

  /** Gets the value of "mask-composite" */
  String get maskComposite() =>
    getPropertyValue('${_browserPrefix}mask-composite');

  /** Sets the value of "mask-composite" */
  void set maskComposite(String value) {
    setProperty('${_browserPrefix}mask-composite', value, '');
  }

  /** Gets the value of "mask-image" */
  String get maskImage() =>
    getPropertyValue('${_browserPrefix}mask-image');

  /** Sets the value of "mask-image" */
  void set maskImage(String value) {
    setProperty('${_browserPrefix}mask-image', value, '');
  }

  /** Gets the value of "mask-origin" */
  String get maskOrigin() =>
    getPropertyValue('${_browserPrefix}mask-origin');

  /** Sets the value of "mask-origin" */
  void set maskOrigin(String value) {
    setProperty('${_browserPrefix}mask-origin', value, '');
  }

  /** Gets the value of "mask-position" */
  String get maskPosition() =>
    getPropertyValue('${_browserPrefix}mask-position');

  /** Sets the value of "mask-position" */
  void set maskPosition(String value) {
    setProperty('${_browserPrefix}mask-position', value, '');
  }

  /** Gets the value of "mask-position-x" */
  String get maskPositionX() =>
    getPropertyValue('${_browserPrefix}mask-position-x');

  /** Sets the value of "mask-position-x" */
  void set maskPositionX(String value) {
    setProperty('${_browserPrefix}mask-position-x', value, '');
  }

  /** Gets the value of "mask-position-y" */
  String get maskPositionY() =>
    getPropertyValue('${_browserPrefix}mask-position-y');

  /** Sets the value of "mask-position-y" */
  void set maskPositionY(String value) {
    setProperty('${_browserPrefix}mask-position-y', value, '');
  }

  /** Gets the value of "mask-repeat" */
  String get maskRepeat() =>
    getPropertyValue('${_browserPrefix}mask-repeat');

  /** Sets the value of "mask-repeat" */
  void set maskRepeat(String value) {
    setProperty('${_browserPrefix}mask-repeat', value, '');
  }

  /** Gets the value of "mask-repeat-x" */
  String get maskRepeatX() =>
    getPropertyValue('${_browserPrefix}mask-repeat-x');

  /** Sets the value of "mask-repeat-x" */
  void set maskRepeatX(String value) {
    setProperty('${_browserPrefix}mask-repeat-x', value, '');
  }

  /** Gets the value of "mask-repeat-y" */
  String get maskRepeatY() =>
    getPropertyValue('${_browserPrefix}mask-repeat-y');

  /** Sets the value of "mask-repeat-y" */
  void set maskRepeatY(String value) {
    setProperty('${_browserPrefix}mask-repeat-y', value, '');
  }

  /** Gets the value of "mask-size" */
  String get maskSize() =>
    getPropertyValue('${_browserPrefix}mask-size');

  /** Sets the value of "mask-size" */
  void set maskSize(String value) {
    setProperty('${_browserPrefix}mask-size', value, '');
  }

  /** Gets the value of "match-nearest-mail-blockquote-color" */
  String get matchNearestMailBlockquoteColor() =>
    getPropertyValue('${_browserPrefix}match-nearest-mail-blockquote-color');

  /** Sets the value of "match-nearest-mail-blockquote-color" */
  void set matchNearestMailBlockquoteColor(String value) {
    setProperty('${_browserPrefix}match-nearest-mail-blockquote-color', value, '');
  }

  /** Gets the value of "max-height" */
  String get maxHeight() =>
    getPropertyValue('max-height');

  /** Sets the value of "max-height" */
  void set maxHeight(String value) {
    setProperty('max-height', value, '');
  }

  /** Gets the value of "max-logical-height" */
  String get maxLogicalHeight() =>
    getPropertyValue('${_browserPrefix}max-logical-height');

  /** Sets the value of "max-logical-height" */
  void set maxLogicalHeight(String value) {
    setProperty('${_browserPrefix}max-logical-height', value, '');
  }

  /** Gets the value of "max-logical-width" */
  String get maxLogicalWidth() =>
    getPropertyValue('${_browserPrefix}max-logical-width');

  /** Sets the value of "max-logical-width" */
  void set maxLogicalWidth(String value) {
    setProperty('${_browserPrefix}max-logical-width', value, '');
  }

  /** Gets the value of "max-width" */
  String get maxWidth() =>
    getPropertyValue('max-width');

  /** Sets the value of "max-width" */
  void set maxWidth(String value) {
    setProperty('max-width', value, '');
  }

  /** Gets the value of "min-height" */
  String get minHeight() =>
    getPropertyValue('min-height');

  /** Sets the value of "min-height" */
  void set minHeight(String value) {
    setProperty('min-height', value, '');
  }

  /** Gets the value of "min-logical-height" */
  String get minLogicalHeight() =>
    getPropertyValue('${_browserPrefix}min-logical-height');

  /** Sets the value of "min-logical-height" */
  void set minLogicalHeight(String value) {
    setProperty('${_browserPrefix}min-logical-height', value, '');
  }

  /** Gets the value of "min-logical-width" */
  String get minLogicalWidth() =>
    getPropertyValue('${_browserPrefix}min-logical-width');

  /** Sets the value of "min-logical-width" */
  void set minLogicalWidth(String value) {
    setProperty('${_browserPrefix}min-logical-width', value, '');
  }

  /** Gets the value of "min-width" */
  String get minWidth() =>
    getPropertyValue('min-width');

  /** Sets the value of "min-width" */
  void set minWidth(String value) {
    setProperty('min-width', value, '');
  }

  /** Gets the value of "nbsp-mode" */
  String get nbspMode() =>
    getPropertyValue('${_browserPrefix}nbsp-mode');

  /** Sets the value of "nbsp-mode" */
  void set nbspMode(String value) {
    setProperty('${_browserPrefix}nbsp-mode', value, '');
  }

  /** Gets the value of "opacity" */
  String get opacity() =>
    getPropertyValue('opacity');

  /** Sets the value of "opacity" */
  void set opacity(String value) {
    setProperty('opacity', value, '');
  }

  /** Gets the value of "orphans" */
  String get orphans() =>
    getPropertyValue('orphans');

  /** Sets the value of "orphans" */
  void set orphans(String value) {
    setProperty('orphans', value, '');
  }

  /** Gets the value of "outline" */
  String get outline() =>
    getPropertyValue('outline');

  /** Sets the value of "outline" */
  void set outline(String value) {
    setProperty('outline', value, '');
  }

  /** Gets the value of "outline-color" */
  String get outlineColor() =>
    getPropertyValue('outline-color');

  /** Sets the value of "outline-color" */
  void set outlineColor(String value) {
    setProperty('outline-color', value, '');
  }

  /** Gets the value of "outline-offset" */
  String get outlineOffset() =>
    getPropertyValue('outline-offset');

  /** Sets the value of "outline-offset" */
  void set outlineOffset(String value) {
    setProperty('outline-offset', value, '');
  }

  /** Gets the value of "outline-style" */
  String get outlineStyle() =>
    getPropertyValue('outline-style');

  /** Sets the value of "outline-style" */
  void set outlineStyle(String value) {
    setProperty('outline-style', value, '');
  }

  /** Gets the value of "outline-width" */
  String get outlineWidth() =>
    getPropertyValue('outline-width');

  /** Sets the value of "outline-width" */
  void set outlineWidth(String value) {
    setProperty('outline-width', value, '');
  }

  /** Gets the value of "overflow" */
  String get overflow() =>
    getPropertyValue('overflow');

  /** Sets the value of "overflow" */
  void set overflow(String value) {
    setProperty('overflow', value, '');
  }

  /** Gets the value of "overflow-x" */
  String get overflowX() =>
    getPropertyValue('overflow-x');

  /** Sets the value of "overflow-x" */
  void set overflowX(String value) {
    setProperty('overflow-x', value, '');
  }

  /** Gets the value of "overflow-y" */
  String get overflowY() =>
    getPropertyValue('overflow-y');

  /** Sets the value of "overflow-y" */
  void set overflowY(String value) {
    setProperty('overflow-y', value, '');
  }

  /** Gets the value of "padding" */
  String get padding() =>
    getPropertyValue('padding');

  /** Sets the value of "padding" */
  void set padding(String value) {
    setProperty('padding', value, '');
  }

  /** Gets the value of "padding-after" */
  String get paddingAfter() =>
    getPropertyValue('${_browserPrefix}padding-after');

  /** Sets the value of "padding-after" */
  void set paddingAfter(String value) {
    setProperty('${_browserPrefix}padding-after', value, '');
  }

  /** Gets the value of "padding-before" */
  String get paddingBefore() =>
    getPropertyValue('${_browserPrefix}padding-before');

  /** Sets the value of "padding-before" */
  void set paddingBefore(String value) {
    setProperty('${_browserPrefix}padding-before', value, '');
  }

  /** Gets the value of "padding-bottom" */
  String get paddingBottom() =>
    getPropertyValue('padding-bottom');

  /** Sets the value of "padding-bottom" */
  void set paddingBottom(String value) {
    setProperty('padding-bottom', value, '');
  }

  /** Gets the value of "padding-end" */
  String get paddingEnd() =>
    getPropertyValue('${_browserPrefix}padding-end');

  /** Sets the value of "padding-end" */
  void set paddingEnd(String value) {
    setProperty('${_browserPrefix}padding-end', value, '');
  }

  /** Gets the value of "padding-left" */
  String get paddingLeft() =>
    getPropertyValue('padding-left');

  /** Sets the value of "padding-left" */
  void set paddingLeft(String value) {
    setProperty('padding-left', value, '');
  }

  /** Gets the value of "padding-right" */
  String get paddingRight() =>
    getPropertyValue('padding-right');

  /** Sets the value of "padding-right" */
  void set paddingRight(String value) {
    setProperty('padding-right', value, '');
  }

  /** Gets the value of "padding-start" */
  String get paddingStart() =>
    getPropertyValue('${_browserPrefix}padding-start');

  /** Sets the value of "padding-start" */
  void set paddingStart(String value) {
    setProperty('${_browserPrefix}padding-start', value, '');
  }

  /** Gets the value of "padding-top" */
  String get paddingTop() =>
    getPropertyValue('padding-top');

  /** Sets the value of "padding-top" */
  void set paddingTop(String value) {
    setProperty('padding-top', value, '');
  }

  /** Gets the value of "page" */
  String get page() =>
    getPropertyValue('page');

  /** Sets the value of "page" */
  void set page(String value) {
    setProperty('page', value, '');
  }

  /** Gets the value of "page-break-after" */
  String get pageBreakAfter() =>
    getPropertyValue('page-break-after');

  /** Sets the value of "page-break-after" */
  void set pageBreakAfter(String value) {
    setProperty('page-break-after', value, '');
  }

  /** Gets the value of "page-break-before" */
  String get pageBreakBefore() =>
    getPropertyValue('page-break-before');

  /** Sets the value of "page-break-before" */
  void set pageBreakBefore(String value) {
    setProperty('page-break-before', value, '');
  }

  /** Gets the value of "page-break-inside" */
  String get pageBreakInside() =>
    getPropertyValue('page-break-inside');

  /** Sets the value of "page-break-inside" */
  void set pageBreakInside(String value) {
    setProperty('page-break-inside', value, '');
  }

  /** Gets the value of "perspective" */
  String get perspective() =>
    getPropertyValue('${_browserPrefix}perspective');

  /** Sets the value of "perspective" */
  void set perspective(String value) {
    setProperty('${_browserPrefix}perspective', value, '');
  }

  /** Gets the value of "perspective-origin" */
  String get perspectiveOrigin() =>
    getPropertyValue('${_browserPrefix}perspective-origin');

  /** Sets the value of "perspective-origin" */
  void set perspectiveOrigin(String value) {
    setProperty('${_browserPrefix}perspective-origin', value, '');
  }

  /** Gets the value of "perspective-origin-x" */
  String get perspectiveOriginX() =>
    getPropertyValue('${_browserPrefix}perspective-origin-x');

  /** Sets the value of "perspective-origin-x" */
  void set perspectiveOriginX(String value) {
    setProperty('${_browserPrefix}perspective-origin-x', value, '');
  }

  /** Gets the value of "perspective-origin-y" */
  String get perspectiveOriginY() =>
    getPropertyValue('${_browserPrefix}perspective-origin-y');

  /** Sets the value of "perspective-origin-y" */
  void set perspectiveOriginY(String value) {
    setProperty('${_browserPrefix}perspective-origin-y', value, '');
  }

  /** Gets the value of "pointer-events" */
  String get pointerEvents() =>
    getPropertyValue('pointer-events');

  /** Sets the value of "pointer-events" */
  void set pointerEvents(String value) {
    setProperty('pointer-events', value, '');
  }

  /** Gets the value of "position" */
  String get position() =>
    getPropertyValue('position');

  /** Sets the value of "position" */
  void set position(String value) {
    setProperty('position', value, '');
  }

  /** Gets the value of "quotes" */
  String get quotes() =>
    getPropertyValue('quotes');

  /** Sets the value of "quotes" */
  void set quotes(String value) {
    setProperty('quotes', value, '');
  }

  /** Gets the value of "region-break-after" */
  String get regionBreakAfter() =>
    getPropertyValue('${_browserPrefix}region-break-after');

  /** Sets the value of "region-break-after" */
  void set regionBreakAfter(String value) {
    setProperty('${_browserPrefix}region-break-after', value, '');
  }

  /** Gets the value of "region-break-before" */
  String get regionBreakBefore() =>
    getPropertyValue('${_browserPrefix}region-break-before');

  /** Sets the value of "region-break-before" */
  void set regionBreakBefore(String value) {
    setProperty('${_browserPrefix}region-break-before', value, '');
  }

  /** Gets the value of "region-break-inside" */
  String get regionBreakInside() =>
    getPropertyValue('${_browserPrefix}region-break-inside');

  /** Sets the value of "region-break-inside" */
  void set regionBreakInside(String value) {
    setProperty('${_browserPrefix}region-break-inside', value, '');
  }

  /** Gets the value of "region-overflow" */
  String get regionOverflow() =>
    getPropertyValue('${_browserPrefix}region-overflow');

  /** Sets the value of "region-overflow" */
  void set regionOverflow(String value) {
    setProperty('${_browserPrefix}region-overflow', value, '');
  }

  /** Gets the value of "resize" */
  String get resize() =>
    getPropertyValue('resize');

  /** Sets the value of "resize" */
  void set resize(String value) {
    setProperty('resize', value, '');
  }

  /** Gets the value of "right" */
  String get right() =>
    getPropertyValue('right');

  /** Sets the value of "right" */
  void set right(String value) {
    setProperty('right', value, '');
  }

  /** Gets the value of "rtl-ordering" */
  String get rtlOrdering() =>
    getPropertyValue('${_browserPrefix}rtl-ordering');

  /** Sets the value of "rtl-ordering" */
  void set rtlOrdering(String value) {
    setProperty('${_browserPrefix}rtl-ordering', value, '');
  }

  /** Gets the value of "size" */
  String get size() =>
    getPropertyValue('size');

  /** Sets the value of "size" */
  void set size(String value) {
    setProperty('size', value, '');
  }

  /** Gets the value of "speak" */
  String get speak() =>
    getPropertyValue('speak');

  /** Sets the value of "speak" */
  void set speak(String value) {
    setProperty('speak', value, '');
  }

  /** Gets the value of "src" */
  String get src() =>
    getPropertyValue('src');

  /** Sets the value of "src" */
  void set src(String value) {
    setProperty('src', value, '');
  }

  /** Gets the value of "table-layout" */
  String get tableLayout() =>
    getPropertyValue('table-layout');

  /** Sets the value of "table-layout" */
  void set tableLayout(String value) {
    setProperty('table-layout', value, '');
  }

  /** Gets the value of "tap-highlight-color" */
  String get tapHighlightColor() =>
    getPropertyValue('${_browserPrefix}tap-highlight-color');

  /** Sets the value of "tap-highlight-color" */
  void set tapHighlightColor(String value) {
    setProperty('${_browserPrefix}tap-highlight-color', value, '');
  }

  /** Gets the value of "text-align" */
  String get textAlign() =>
    getPropertyValue('text-align');

  /** Sets the value of "text-align" */
  void set textAlign(String value) {
    setProperty('text-align', value, '');
  }

  /** Gets the value of "text-combine" */
  String get textCombine() =>
    getPropertyValue('${_browserPrefix}text-combine');

  /** Sets the value of "text-combine" */
  void set textCombine(String value) {
    setProperty('${_browserPrefix}text-combine', value, '');
  }

  /** Gets the value of "text-decoration" */
  String get textDecoration() =>
    getPropertyValue('text-decoration');

  /** Sets the value of "text-decoration" */
  void set textDecoration(String value) {
    setProperty('text-decoration', value, '');
  }

  /** Gets the value of "text-decorations-in-effect" */
  String get textDecorationsInEffect() =>
    getPropertyValue('${_browserPrefix}text-decorations-in-effect');

  /** Sets the value of "text-decorations-in-effect" */
  void set textDecorationsInEffect(String value) {
    setProperty('${_browserPrefix}text-decorations-in-effect', value, '');
  }

  /** Gets the value of "text-emphasis" */
  String get textEmphasis() =>
    getPropertyValue('${_browserPrefix}text-emphasis');

  /** Sets the value of "text-emphasis" */
  void set textEmphasis(String value) {
    setProperty('${_browserPrefix}text-emphasis', value, '');
  }

  /** Gets the value of "text-emphasis-color" */
  String get textEmphasisColor() =>
    getPropertyValue('${_browserPrefix}text-emphasis-color');

  /** Sets the value of "text-emphasis-color" */
  void set textEmphasisColor(String value) {
    setProperty('${_browserPrefix}text-emphasis-color', value, '');
  }

  /** Gets the value of "text-emphasis-position" */
  String get textEmphasisPosition() =>
    getPropertyValue('${_browserPrefix}text-emphasis-position');

  /** Sets the value of "text-emphasis-position" */
  void set textEmphasisPosition(String value) {
    setProperty('${_browserPrefix}text-emphasis-position', value, '');
  }

  /** Gets the value of "text-emphasis-style" */
  String get textEmphasisStyle() =>
    getPropertyValue('${_browserPrefix}text-emphasis-style');

  /** Sets the value of "text-emphasis-style" */
  void set textEmphasisStyle(String value) {
    setProperty('${_browserPrefix}text-emphasis-style', value, '');
  }

  /** Gets the value of "text-fill-color" */
  String get textFillColor() =>
    getPropertyValue('${_browserPrefix}text-fill-color');

  /** Sets the value of "text-fill-color" */
  void set textFillColor(String value) {
    setProperty('${_browserPrefix}text-fill-color', value, '');
  }

  /** Gets the value of "text-indent" */
  String get textIndent() =>
    getPropertyValue('text-indent');

  /** Sets the value of "text-indent" */
  void set textIndent(String value) {
    setProperty('text-indent', value, '');
  }

  /** Gets the value of "text-line-through" */
  String get textLineThrough() =>
    getPropertyValue('text-line-through');

  /** Sets the value of "text-line-through" */
  void set textLineThrough(String value) {
    setProperty('text-line-through', value, '');
  }

  /** Gets the value of "text-line-through-color" */
  String get textLineThroughColor() =>
    getPropertyValue('text-line-through-color');

  /** Sets the value of "text-line-through-color" */
  void set textLineThroughColor(String value) {
    setProperty('text-line-through-color', value, '');
  }

  /** Gets the value of "text-line-through-mode" */
  String get textLineThroughMode() =>
    getPropertyValue('text-line-through-mode');

  /** Sets the value of "text-line-through-mode" */
  void set textLineThroughMode(String value) {
    setProperty('text-line-through-mode', value, '');
  }

  /** Gets the value of "text-line-through-style" */
  String get textLineThroughStyle() =>
    getPropertyValue('text-line-through-style');

  /** Sets the value of "text-line-through-style" */
  void set textLineThroughStyle(String value) {
    setProperty('text-line-through-style', value, '');
  }

  /** Gets the value of "text-line-through-width" */
  String get textLineThroughWidth() =>
    getPropertyValue('text-line-through-width');

  /** Sets the value of "text-line-through-width" */
  void set textLineThroughWidth(String value) {
    setProperty('text-line-through-width', value, '');
  }

  /** Gets the value of "text-orientation" */
  String get textOrientation() =>
    getPropertyValue('${_browserPrefix}text-orientation');

  /** Sets the value of "text-orientation" */
  void set textOrientation(String value) {
    setProperty('${_browserPrefix}text-orientation', value, '');
  }

  /** Gets the value of "text-overflow" */
  String get textOverflow() =>
    getPropertyValue('text-overflow');

  /** Sets the value of "text-overflow" */
  void set textOverflow(String value) {
    setProperty('text-overflow', value, '');
  }

  /** Gets the value of "text-overline" */
  String get textOverline() =>
    getPropertyValue('text-overline');

  /** Sets the value of "text-overline" */
  void set textOverline(String value) {
    setProperty('text-overline', value, '');
  }

  /** Gets the value of "text-overline-color" */
  String get textOverlineColor() =>
    getPropertyValue('text-overline-color');

  /** Sets the value of "text-overline-color" */
  void set textOverlineColor(String value) {
    setProperty('text-overline-color', value, '');
  }

  /** Gets the value of "text-overline-mode" */
  String get textOverlineMode() =>
    getPropertyValue('text-overline-mode');

  /** Sets the value of "text-overline-mode" */
  void set textOverlineMode(String value) {
    setProperty('text-overline-mode', value, '');
  }

  /** Gets the value of "text-overline-style" */
  String get textOverlineStyle() =>
    getPropertyValue('text-overline-style');

  /** Sets the value of "text-overline-style" */
  void set textOverlineStyle(String value) {
    setProperty('text-overline-style', value, '');
  }

  /** Gets the value of "text-overline-width" */
  String get textOverlineWidth() =>
    getPropertyValue('text-overline-width');

  /** Sets the value of "text-overline-width" */
  void set textOverlineWidth(String value) {
    setProperty('text-overline-width', value, '');
  }

  /** Gets the value of "text-rendering" */
  String get textRendering() =>
    getPropertyValue('text-rendering');

  /** Sets the value of "text-rendering" */
  void set textRendering(String value) {
    setProperty('text-rendering', value, '');
  }

  /** Gets the value of "text-security" */
  String get textSecurity() =>
    getPropertyValue('${_browserPrefix}text-security');

  /** Sets the value of "text-security" */
  void set textSecurity(String value) {
    setProperty('${_browserPrefix}text-security', value, '');
  }

  /** Gets the value of "text-shadow" */
  String get textShadow() =>
    getPropertyValue('text-shadow');

  /** Sets the value of "text-shadow" */
  void set textShadow(String value) {
    setProperty('text-shadow', value, '');
  }

  /** Gets the value of "text-size-adjust" */
  String get textSizeAdjust() =>
    getPropertyValue('${_browserPrefix}text-size-adjust');

  /** Sets the value of "text-size-adjust" */
  void set textSizeAdjust(String value) {
    setProperty('${_browserPrefix}text-size-adjust', value, '');
  }

  /** Gets the value of "text-stroke" */
  String get textStroke() =>
    getPropertyValue('${_browserPrefix}text-stroke');

  /** Sets the value of "text-stroke" */
  void set textStroke(String value) {
    setProperty('${_browserPrefix}text-stroke', value, '');
  }

  /** Gets the value of "text-stroke-color" */
  String get textStrokeColor() =>
    getPropertyValue('${_browserPrefix}text-stroke-color');

  /** Sets the value of "text-stroke-color" */
  void set textStrokeColor(String value) {
    setProperty('${_browserPrefix}text-stroke-color', value, '');
  }

  /** Gets the value of "text-stroke-width" */
  String get textStrokeWidth() =>
    getPropertyValue('${_browserPrefix}text-stroke-width');

  /** Sets the value of "text-stroke-width" */
  void set textStrokeWidth(String value) {
    setProperty('${_browserPrefix}text-stroke-width', value, '');
  }

  /** Gets the value of "text-transform" */
  String get textTransform() =>
    getPropertyValue('text-transform');

  /** Sets the value of "text-transform" */
  void set textTransform(String value) {
    setProperty('text-transform', value, '');
  }

  /** Gets the value of "text-underline" */
  String get textUnderline() =>
    getPropertyValue('text-underline');

  /** Sets the value of "text-underline" */
  void set textUnderline(String value) {
    setProperty('text-underline', value, '');
  }

  /** Gets the value of "text-underline-color" */
  String get textUnderlineColor() =>
    getPropertyValue('text-underline-color');

  /** Sets the value of "text-underline-color" */
  void set textUnderlineColor(String value) {
    setProperty('text-underline-color', value, '');
  }

  /** Gets the value of "text-underline-mode" */
  String get textUnderlineMode() =>
    getPropertyValue('text-underline-mode');

  /** Sets the value of "text-underline-mode" */
  void set textUnderlineMode(String value) {
    setProperty('text-underline-mode', value, '');
  }

  /** Gets the value of "text-underline-style" */
  String get textUnderlineStyle() =>
    getPropertyValue('text-underline-style');

  /** Sets the value of "text-underline-style" */
  void set textUnderlineStyle(String value) {
    setProperty('text-underline-style', value, '');
  }

  /** Gets the value of "text-underline-width" */
  String get textUnderlineWidth() =>
    getPropertyValue('text-underline-width');

  /** Sets the value of "text-underline-width" */
  void set textUnderlineWidth(String value) {
    setProperty('text-underline-width', value, '');
  }

  /** Gets the value of "top" */
  String get top() =>
    getPropertyValue('top');

  /** Sets the value of "top" */
  void set top(String value) {
    setProperty('top', value, '');
  }

  /** Gets the value of "transform" */
  String get transform() =>
    getPropertyValue('${_browserPrefix}transform');

  /** Sets the value of "transform" */
  void set transform(String value) {
    setProperty('${_browserPrefix}transform', value, '');
  }

  /** Gets the value of "transform-origin" */
  String get transformOrigin() =>
    getPropertyValue('${_browserPrefix}transform-origin');

  /** Sets the value of "transform-origin" */
  void set transformOrigin(String value) {
    setProperty('${_browserPrefix}transform-origin', value, '');
  }

  /** Gets the value of "transform-origin-x" */
  String get transformOriginX() =>
    getPropertyValue('${_browserPrefix}transform-origin-x');

  /** Sets the value of "transform-origin-x" */
  void set transformOriginX(String value) {
    setProperty('${_browserPrefix}transform-origin-x', value, '');
  }

  /** Gets the value of "transform-origin-y" */
  String get transformOriginY() =>
    getPropertyValue('${_browserPrefix}transform-origin-y');

  /** Sets the value of "transform-origin-y" */
  void set transformOriginY(String value) {
    setProperty('${_browserPrefix}transform-origin-y', value, '');
  }

  /** Gets the value of "transform-origin-z" */
  String get transformOriginZ() =>
    getPropertyValue('${_browserPrefix}transform-origin-z');

  /** Sets the value of "transform-origin-z" */
  void set transformOriginZ(String value) {
    setProperty('${_browserPrefix}transform-origin-z', value, '');
  }

  /** Gets the value of "transform-style" */
  String get transformStyle() =>
    getPropertyValue('${_browserPrefix}transform-style');

  /** Sets the value of "transform-style" */
  void set transformStyle(String value) {
    setProperty('${_browserPrefix}transform-style', value, '');
  }

  /** Gets the value of "transition" */
  String get transition() =>
    getPropertyValue('${_browserPrefix}transition');

  /** Sets the value of "transition" */
  void set transition(String value) {
    setProperty('${_browserPrefix}transition', value, '');
  }

  /** Gets the value of "transition-delay" */
  String get transitionDelay() =>
    getPropertyValue('${_browserPrefix}transition-delay');

  /** Sets the value of "transition-delay" */
  void set transitionDelay(String value) {
    setProperty('${_browserPrefix}transition-delay', value, '');
  }

  /** Gets the value of "transition-duration" */
  String get transitionDuration() =>
    getPropertyValue('${_browserPrefix}transition-duration');

  /** Sets the value of "transition-duration" */
  void set transitionDuration(String value) {
    setProperty('${_browserPrefix}transition-duration', value, '');
  }

  /** Gets the value of "transition-property" */
  String get transitionProperty() =>
    getPropertyValue('${_browserPrefix}transition-property');

  /** Sets the value of "transition-property" */
  void set transitionProperty(String value) {
    setProperty('${_browserPrefix}transition-property', value, '');
  }

  /** Gets the value of "transition-timing-function" */
  String get transitionTimingFunction() =>
    getPropertyValue('${_browserPrefix}transition-timing-function');

  /** Sets the value of "transition-timing-function" */
  void set transitionTimingFunction(String value) {
    setProperty('${_browserPrefix}transition-timing-function', value, '');
  }

  /** Gets the value of "unicode-bidi" */
  String get unicodeBidi() =>
    getPropertyValue('unicode-bidi');

  /** Sets the value of "unicode-bidi" */
  void set unicodeBidi(String value) {
    setProperty('unicode-bidi', value, '');
  }

  /** Gets the value of "unicode-range" */
  String get unicodeRange() =>
    getPropertyValue('unicode-range');

  /** Sets the value of "unicode-range" */
  void set unicodeRange(String value) {
    setProperty('unicode-range', value, '');
  }

  /** Gets the value of "user-drag" */
  String get userDrag() =>
    getPropertyValue('${_browserPrefix}user-drag');

  /** Sets the value of "user-drag" */
  void set userDrag(String value) {
    setProperty('${_browserPrefix}user-drag', value, '');
  }

  /** Gets the value of "user-modify" */
  String get userModify() =>
    getPropertyValue('${_browserPrefix}user-modify');

  /** Sets the value of "user-modify" */
  void set userModify(String value) {
    setProperty('${_browserPrefix}user-modify', value, '');
  }

  /** Gets the value of "user-select" */
  String get userSelect() =>
    getPropertyValue('${_browserPrefix}user-select');

  /** Sets the value of "user-select" */
  void set userSelect(String value) {
    setProperty('${_browserPrefix}user-select', value, '');
  }

  /** Gets the value of "vertical-align" */
  String get verticalAlign() =>
    getPropertyValue('vertical-align');

  /** Sets the value of "vertical-align" */
  void set verticalAlign(String value) {
    setProperty('vertical-align', value, '');
  }

  /** Gets the value of "visibility" */
  String get visibility() =>
    getPropertyValue('visibility');

  /** Sets the value of "visibility" */
  void set visibility(String value) {
    setProperty('visibility', value, '');
  }

  /** Gets the value of "white-space" */
  String get whiteSpace() =>
    getPropertyValue('white-space');

  /** Sets the value of "white-space" */
  void set whiteSpace(String value) {
    setProperty('white-space', value, '');
  }

  /** Gets the value of "widows" */
  String get widows() =>
    getPropertyValue('widows');

  /** Sets the value of "widows" */
  void set widows(String value) {
    setProperty('widows', value, '');
  }

  /** Gets the value of "width" */
  String get width() =>
    getPropertyValue('width');

  /** Sets the value of "width" */
  void set width(String value) {
    setProperty('width', value, '');
  }

  /** Gets the value of "word-break" */
  String get wordBreak() =>
    getPropertyValue('word-break');

  /** Sets the value of "word-break" */
  void set wordBreak(String value) {
    setProperty('word-break', value, '');
  }

  /** Gets the value of "word-spacing" */
  String get wordSpacing() =>
    getPropertyValue('word-spacing');

  /** Sets the value of "word-spacing" */
  void set wordSpacing(String value) {
    setProperty('word-spacing', value, '');
  }

  /** Gets the value of "word-wrap" */
  String get wordWrap() =>
    getPropertyValue('word-wrap');

  /** Sets the value of "word-wrap" */
  void set wordWrap(String value) {
    setProperty('word-wrap', value, '');
  }

  /** Gets the value of "wrap-shape" */
  String get wrapShape() =>
    getPropertyValue('${_browserPrefix}wrap-shape');

  /** Sets the value of "wrap-shape" */
  void set wrapShape(String value) {
    setProperty('${_browserPrefix}wrap-shape', value, '');
  }

  /** Gets the value of "writing-mode" */
  String get writingMode() =>
    getPropertyValue('${_browserPrefix}writing-mode');

  /** Sets the value of "writing-mode" */
  void set writingMode(String value) {
    setProperty('${_browserPrefix}writing-mode', value, '');
  }

  /** Gets the value of "z-index" */
  String get zIndex() =>
    getPropertyValue('z-index');

  /** Sets the value of "z-index" */
  void set zIndex(String value) {
    setProperty('z-index', value, '');
  }

  /** Gets the value of "zoom" */
  String get zoom() =>
    getPropertyValue('zoom');

  /** Sets the value of "zoom" */
  void set zoom(String value) {
    setProperty('zoom', value, '');
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class CustomEventWrappingImplementation extends EventWrappingImplementation implements CustomEvent {
  CustomEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory CustomEventWrappingImplementation(String type,
      [bool canBubble = true, bool cancelable = true, Object detail = null]) {
    final e = dom.document.createEvent("CustomEvent");
    e.initCustomEvent(type, canBubble, cancelable, detail);
    return LevelDom.wrapCustomEvent(e);
  }

  String get detail() => _ptr.detail;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Provides a Map abstraction on top of data-* attributes, similar to the
 * dataSet in the old DOM.
 */
class _DataAttributeMap implements Map<String, String> {

  final Map<String, String> _attributes;

  _DataAttributeMap(this._attributes);

  // interface Map

  // TODO: Use lazy iterator when it is available on Map.
  bool containsValue(String value) => getValues().some((v) => v == value);

  bool containsKey(String key) => _attributes.containsKey(_attr(key));

  String operator [](String key) => _attributes[_attr(key)];

  void operator []=(String key, String value) {
    _attributes[_attr(key)] = value;
  }

  String putIfAbsent(String key, String ifAbsent()) {
    if (!containsKey(key)) {
      return this[key] = ifAbsent();
    }
    return this[key];
  }

  String remove(String key) => _attributes.remove(_attr(key));

  void clear() {
    // Needs to operate on a snapshot since we are mutatiting the collection.
    for (String key in getKeys()) {
      remove(key);
    }
  }

  void forEach(void f(String key, String value)) {
    _attributes.forEach((String key, String value) {
      if (_matches(key)) {
        f(_strip(key), value);
      }
    });
  }

  Collection<String> getKeys() {
    final keys = new List<String>();
    _attributes.forEach((String key, String value) {
      if (_matches(key)) {
        keys.add(_strip(key));
      }
    });
    return keys;
  }

  Collection<String> getValues() {
    final values = new List<String>();
    _attributes.forEach((String key, String value) {
      if (_matches(key)) {
        values.add(value);
      }
    });
    return values;
  }

  int get length() => getKeys().length;

  // TODO: Use lazy iterator when it is available on Map.
  bool isEmpty() => length == 0;

  // Helpers.
  String _attr(String key) => 'data-$key';
  bool _matches(String key) => key.startsWith('data-');
  String _strip(String key) => key.substring(5);
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
  static String get userAgent() => dom.window.navigator.userAgent;

  /**
   * Determines if the current device is running Firefox.
   */
  static bool get isFirefox() => userAgent.contains("Firefox", 0);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class DeviceMotionEventWrappingImplementation extends EventWrappingImplementation implements DeviceMotionEvent {
  DeviceMotionEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory DeviceMotionEventWrappingImplementation(String type,
      [bool canBubble = true, bool cancelable = true]) {
    final e = dom.document.createEvent("DeviceMotionEvent");
    e.initEvent(type, canBubble, cancelable);
    return LevelDom.wrapDeviceMotionEvent(e);
  }

  num get interval() => _ptr.interval;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class DeviceOrientationEventWrappingImplementation extends EventWrappingImplementation implements DeviceOrientationEvent {
  DeviceOrientationEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory DeviceOrientationEventWrappingImplementation(String type,
      double alpha, double beta, double gamma, [bool canBubble = true,
      bool cancelable = true]) {
    final e = dom.document.createEvent("DeviceOrientationEvent");
    e.initDeviceOrientationEvent(
        type, canBubble, cancelable, alpha, beta, gamma);
    return LevelDom.wrapDeviceOrientationEvent(e);
  }

  num get alpha() => _ptr.alpha;

  num get beta() => _ptr.beta;

  num get gamma() => _ptr.gamma;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class FilteredElementList implements ElementList {
  final Node _node;
  final NodeList _childNodes;

  FilteredElementList(Node node): _childNodes = node.nodes, _node = node;

  // We can't memoize this, since it's possible that children will be messed
  // with externally to this class.
  //
  // TODO(nweiz): Do we really need to copy the list to make the types work out?
  List<Element> get _filtered() =>
    new List.from(_childNodes.filter((n) => n is Element));

  // Don't use _filtered.first so we can short-circuit once we find an element.
  Element get first() {
    for (var node in _childNodes) {
      if (node is Element) {
        return node;
      }
    }
    return null;
  }

  void forEach(void f(Element element)) {
    _filtered.forEach(f);
  }

  void operator []=(int index, Element value) {
    this[index].replaceWith(value);
  }

  void set length(int newLength) {
    var len = this.length;
    if (newLength >= len) {
      return;
    } else if (newLength < 0) {
      throw const IllegalArgumentException("Invalid list length");
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

  void sort(int compare(Element a, Element b)) {
    throw const UnsupportedOperationException('TODO(jacobr): should we impl?');
  }

  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) {
    throw const NotImplementedException();
  }

  void setRange(int start, int length, List from, [int startFrom = 0]) {
    throw const NotImplementedException();
  }

  void removeRange(int start, int length) {
    _filtered.getRange(start, length).forEach((el) => el.remove());
  }

  void insertRange(int start, int length, [initialValue = null]) {
    throw const NotImplementedException();
  }

  void clear() {
    // Currently, ElementList#clear clears even non-element nodes, so we follow
    // that behavior.
    _childNodes.clear();
  }

  Element removeLast() {
    var last = this.last();
    if (last != null) {
      last.remove();
    }
    return last;
  }

  Collection<Element> filter(bool f(Element element)) => _filtered.filter(f);
  bool every(bool f(Element element)) => _filtered.every(f);
  bool some(bool f(Element element)) => _filtered.some(f);
  bool isEmpty() => _filtered.isEmpty();
  int get length() => _filtered.length;
  Element operator [](int index) => _filtered[index];
  Iterator<Element> iterator() => _filtered.iterator();
  List<Element> getRange(int start, int length) =>
    _filtered.getRange(start, length);
  int indexOf(Element element, [int start = 0]) =>
    _filtered.indexOf(element, start);

  int lastIndexOf(Element element, [int start = null]) {
    if (start === null) start = length - 1;
    return _filtered.lastIndexOf(element, start);
  }

  Element last() => _filtered.last();
}

class EmptyStyleDeclaration extends CSSStyleDeclarationWrappingImplementation {
  // This can't call super(), since that's a factory constructor
  EmptyStyleDeclaration()
    : super._wrap(dom.document.createElement('div').style);

  void set cssText(String value) {
    throw new UnsupportedOperationException(
        "Can't modify a frozen style declaration.");
  }

  String removeProperty(String propertyName) {
    throw new UnsupportedOperationException(
        "Can't modify a frozen style declaration.");
  }

  void setProperty(String propertyName, String value, [String priority]) {
    throw new UnsupportedOperationException(
        "Can't modify a frozen style declaration.");
  }
}

Future<CSSStyleDeclaration> _emptyStyleFuture() {
  return _createMeasurementFuture(() => new EmptyStyleDeclaration(),
                                  new Completer<CSSStyleDeclaration>());
}

class EmptyElementRect implements ElementRect {
  final ClientRect client = const SimpleClientRect(0, 0, 0, 0);
  final ClientRect offset = const SimpleClientRect(0, 0, 0, 0);
  final ClientRect scroll = const SimpleClientRect(0, 0, 0, 0);
  final ClientRect bounding = const SimpleClientRect(0, 0, 0, 0);
  final List<ClientRect> clientRects = const <ClientRect>[];

  const EmptyElementRect();
}

class DocumentFragmentWrappingImplementation extends NodeWrappingImplementation implements DocumentFragment {
  ElementList _elements;

  DocumentFragmentWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  /** @domName Document.createDocumentFragment */
  factory DocumentFragmentWrappingImplementation() {
    return new DocumentFragmentWrappingImplementation._wrap(
	    dom.document.createDocumentFragment());
  }

  factory DocumentFragmentWrappingImplementation.html(String html) {
    var fragment = new DocumentFragment();
    fragment.innerHTML = html;
    return fragment;
  }

  ElementList get elements() {
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

  String get innerHTML() {
    var e = new Element.tag("div");
    e.nodes.add(this.clone(true));
    return e.innerHTML;
  }

  String get outerHTML() => innerHTML;

  void set innerHTML(String value) {
    this.nodes.clear();

    var e = new Element.tag("div");
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
        this.insertBefore(node, nodes.first);
        return node;
      case "beforeend":
        this.nodes.add(node);
        return node;
      default:
        throw new IllegalArgumentException("Invalid position ${where}");
    }
  }

  Element insertAdjacentElement([String where = null, Element element = null])
    => this._insertAdjacentNode(where, element);

  void insertAdjacentText([String where = null, String text = null]) {
    this._insertAdjacentNode(where, new Text(text));
  }

  void insertAdjacentHTML(
      [String position_OR_where = null, String text = null]) {
    this._insertAdjacentNode(
      position_OR_where, new DocumentFragment.html(text));
  }

  ElementEvents get on() {
    if (_on === null) {
      _on = new ElementEventsImplementation._wrap(_ptr);
    }
    return _on;
  }

  Future<ElementRect> get rect() {
    return _createMeasurementFuture(() => const EmptyElementRect(),
                                    new Completer<ElementRect>());
  }

  Element query(String selectors) =>
    LevelDom.wrapElement(_ptr.querySelector(selectors));

  ElementList queryAll(String selectors) =>
    LevelDom.wrapElementList(_ptr.querySelectorAll(selectors));

  // If we can come up with a semi-reasonable default value for an Element
  // getter, we'll use it. In general, these return the same values as an
  // element that has no parent.
  String get contentEditable() => "false";
  bool get isContentEditable() => false;
  bool get draggable() => false;
  bool get hidden() => false;
  bool get spellcheck() => false;
  int get tabIndex() => -1;
  String get id() => "";
  String get title() => "";
  String get tagName() => "";
  String get webkitdropzone() => "";
  Element get firstElementChild() => elements.first();
  Element get lastElementChild() => elements.last();
  Element get nextElementSibling() => null;
  Element get previousElementSibling() => null;
  Element get offsetParent() => null;
  Element get parent() => null;
  Map<String, String> get attributes() => const {};
  // Issue 174: this should be a const set.
  Set<String> get classes() => new Set<String>();
  Map<String, String> get dataAttributes() => const {};
  CSSStyleDeclaration get style() => new EmptyStyleDeclaration();
  Future<CSSStyleDeclaration> get computedStyle() =>
      _emptyStyleFuture();
  Future<CSSStyleDeclaration> getComputedStyle(String pseudoElement) =>
      _emptyStyleFuture();
  bool matchesSelector([String selectors]) => false;

  // Imperative Element methods are made into no-ops, as they are on parentless
  // elements.
  void blur() {}
  void focus() {}
  void scrollByLines([int lines]) {}
  void scrollByPages([int pages]) {}
  void scrollIntoView([bool centerIfNeeded]) {}

  // Setters throw errors rather than being no-ops because we aren't going to
  // retain the values that were set, and erroring out seems clearer.
  void set attributes(Map<String, String> value) {
    throw new UnsupportedOperationException(
      "Attributes can't be set for document fragments.");
  }

  void set classes(Collection<String> value) {
    throw new UnsupportedOperationException(
      "Classes can't be set for document fragments.");
  }

  void set dataAttributes(Map<String, String> value) {
    throw new UnsupportedOperationException(
      "Data attributes can't be set for document fragments.");
  }

  void set contentEditable(String value) {
    throw new UnsupportedOperationException(
      "Content editable can't be set for document fragments.");
  }

  String get dir() {
    throw new UnsupportedOperationException(
      "Document fragments don't support text direction.");
  }

  void set dir(String value) {
    throw new UnsupportedOperationException(
      "Document fragments don't support text direction.");
  }

  void set draggable(bool value) {
    throw new UnsupportedOperationException(
      "Draggable can't be set for document fragments.");
  }

  void set hidden(bool value) {
    throw new UnsupportedOperationException(
      "Hidden can't be set for document fragments.");
  }

  void set id(String value) {
    throw new UnsupportedOperationException(
      "ID can't be set for document fragments.");
  }

  String get lang() {
    throw new UnsupportedOperationException(
      "Document fragments don't support language.");
  }

  void set lang(String value) {
    throw new UnsupportedOperationException(
      "Document fragments don't support language.");
  }

  void set scrollLeft(int value) {
    throw new UnsupportedOperationException(
      "Document fragments don't support scrolling.");
  }

  void set scrollTop(int value) {
    throw new UnsupportedOperationException(
      "Document fragments don't support scrolling.");
  }

  void set spellcheck(bool value) {
     throw new UnsupportedOperationException(
      "Spellcheck can't be set for document fragments.");
  }

  void set tabIndex(int value) {
    throw new UnsupportedOperationException(
      "Tab index can't be set for document fragments.");
  }

  void set title(String value) {
    throw new UnsupportedOperationException(
      "Title can't be set for document fragments.");
  }

  void set webkitdropzone(String value) {
    throw new UnsupportedOperationException(
      "WebKit drop zone can't be set for document fragments.");
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class DocumentEventsImplementation extends ElementEventsImplementation
      implements DocumentEvents {

  DocumentEventsImplementation._wrap(_ptr) : super._wrap(_ptr);

  EventListenerList get readyStateChange() => _get('readystatechange');

  EventListenerList get selectionChange() => _get('selectionchange');

  EventListenerList get contentLoaded() => _get('DOMContentLoaded');
}

class DocumentWrappingImplementation extends ElementWrappingImplementation implements Document {

  final _documentPtr;

  DocumentWrappingImplementation._wrap(this._documentPtr, ptr) : super._wrap(ptr) {
    // We have to set the back ptr on the document as well as the documentElement
    // so that it is always simple to detect when an existing wrapper exists.
    _documentPtr.dynamic.dartObjectLocalStorage = this;
  }

  /** @domName HTMLDocument.activeElement */
  Element get activeElement() => LevelDom.wrapElement(_documentPtr.dynamic.activeElement);

  Node get parent() => null;

  /** @domName Document.body */
  Element get body() => LevelDom.wrapElement(_documentPtr.body);

  /** @domName Document.body */
  void set body(Element value) { _documentPtr.body = LevelDom.unwrap(value); }

  /** @domName Document.charset */
  String get charset() => _documentPtr.charset;

  /** @domName Document.charset */
  void set charset(String value) { _documentPtr.charset = value; }

  /** @domName Document.cookie */
  String get cookie() => _documentPtr.cookie;

  /** @domName Document.cookie */
  void set cookie(String value) { _documentPtr.cookie = value; }

  /** @domName Document.defaultView */
  Window get window() => LevelDom.wrapWindow(_documentPtr.defaultView);

  /** @domName HTMLDocument.designMode */
  void set designMode(String value) { _documentPtr.dynamic.designMode = value; }

  /** @domName Document.domain */
  String get domain() => _documentPtr.domain;

  /** @domName Document.head */
  HeadElement get head() => LevelDom.wrapHeadElement(_documentPtr.head);

  /** @domName Document.lastModified */
  String get lastModified() => _documentPtr.lastModified;

  /** @domName Document.readyState */
  String get readyState() => _documentPtr.readyState;

  /** @domName Document.referrer */
  String get referrer() => _documentPtr.referrer;

  /** @domName Document.styleSheets */
  StyleSheetList get styleSheets() => LevelDom.wrapStyleSheetList(_documentPtr.styleSheets);

  /** @domName Document.title */
  String get title() => _documentPtr.title;

  /** @domName Document.title */
  void set title(String value) { _documentPtr.title = value; }

  /** @domName Document.webkitHidden */
  bool get webkitHidden() => _documentPtr.webkitHidden;

  /** @domName Document.webkitVisibilityState */
  String get webkitVisibilityState() => _documentPtr.webkitVisibilityState;

  /** @domName Document.caretRangeFromPoint */
  Future<Range> caretRangeFromPoint([int x = null, int y = null]) {
    return _createMeasurementFuture(
        () => LevelDom.wrapRange(_documentPtr.caretRangeFromPoint(x, y)),
        new Completer<Range>());
  }

  /** @domName Document.createEvent */
  Event createEvent(String eventType) {
    return LevelDom.wrapEvent(_documentPtr.createEvent(eventType));
  }

  /** @domName Document.elementFromPoint */
  Future<Element> elementFromPoint([int x = null, int y = null]) {
    return _createMeasurementFuture(
        () => LevelDom.wrapElement(_documentPtr.elementFromPoint(x, y)),
        new Completer<Element>());
  }

  /** @domName Document.execCommand */
  bool execCommand([String command = null, bool userInterface = null, String value = null]) {
    return _documentPtr.execCommand(command, userInterface, value);
  }

  /** @domName Document.getCSSCanvasContext */
  CanvasRenderingContext getCSSCanvasContext(String contextId, String name,
                                             int width, int height) {
    return LevelDom.wrapCanvasRenderingContext(_documentPtr.getCSSCanvasContext(contextId, name, width, height));
  }

  /** @domName Document.queryCommandEnabled */
  bool queryCommandEnabled([String command = null]) {
    return _documentPtr.queryCommandEnabled(command);
  }

  /** @domName Document.queryCommandIndeterm */
  bool queryCommandIndeterm([String command = null]) {
    return _documentPtr.queryCommandIndeterm(command);
  }

  /** @domName Document.queryCommandState */
  bool queryCommandState([String command = null]) {
    return _documentPtr.queryCommandState(command);
  }

  /** @domName Document.queryCommandSupported */
  bool queryCommandSupported([String command = null]) {
    return _documentPtr.queryCommandSupported(command);
  }

  /** @domName Document.queryCommandValue */
  String queryCommandValue([String command = null]) {
    return _documentPtr.queryCommandValue(command);
  }

  String get manifest() => _ptr.manifest;

  void set manifest(String value) { _ptr.manifest = value; }

  DocumentEvents get on() {
    if (_on === null) {
      _on = new DocumentEventsImplementation._wrap(_ptr);
    }
    return _on;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class DOMApplicationCacheEventsImplementation extends EventsImplementation
    implements DOMApplicationCacheEvents {
  DOMApplicationCacheEventsImplementation._wrap(ptr) : super._wrap(ptr);

  EventListenerList get cached() => _get('cached');
  EventListenerList get checking() => _get('checking');
  EventListenerList get downloading() => _get('downloading');
  EventListenerList get error() => _get('error');
  EventListenerList get noUpdate() => _get('noupdate');
  EventListenerList get obsolete() => _get('obsolete');
  EventListenerList get progress() => _get('progress');
  EventListenerList get updateReady() => _get('updateready');
}

class DOMApplicationCacheWrappingImplementation extends EventTargetWrappingImplementation implements DOMApplicationCache {
  DOMApplicationCacheWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  int get status() => _ptr.status;

  void swapCache() {
    _ptr.swapCache();
  }

  void update() {
    _ptr.update();
  }

  DOMApplicationCacheEvents get on() {
    if (_on === null) {
      _on = new DOMApplicationCacheEventsImplementation._wrap(_ptr);
    }
    return _on;  
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class DOMWrapperBase {
  final _ptr;

  DOMWrapperBase._wrap(this._ptr) {
  	// We should never be creating duplicate wrappers.
  	assert(_ptr.dartObjectLocalStorage === null);
	_ptr.dartObjectLocalStorage = this;
  }
}

/** This function is provided for unittest purposes only. */
unwrapDomObject(DOMWrapperBase wrapper) {
  return wrapper._ptr;
}// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jacobr): use Lists.dart to remove some of the duplicated functionality.
class _ChildrenElementList implements ElementList {
  // Raw Element.
  final _element;
  final _childElements;

  _ChildrenElementList._wrap(var element)
    : _childElements = element.children,
      _element = element;

  List<Element> _toList() {
    final output = new List(_childElements.length);
    for (int i = 0, len = _childElements.length; i < len; i++) {
      output[i] = LevelDom.wrapElement(_childElements[i]);
    }
    return output;
  }

  Element get first() {
    return LevelDom.wrapElement(_element.firstElementChild);
  }

  void forEach(void f(Element element)) {
    for (var element in _childElements) {
      f(LevelDom.wrapElement(element));
    }
  }

  Collection<Element> filter(bool f(Element element)) {
    List<Element> output = new List<Element>();
    forEach((Element element) {
      if (f(element)) {
        output.add(element);
      }
    });
    return output;
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

  bool isEmpty() {
    return _element.firstElementChild !== null;
  }

  int get length() {
    return _childElements.length;
  }

  Element operator [](int index) {
    return LevelDom.wrapElement(_childElements[index]);
  }

  void operator []=(int index, Element value) {
    _element.replaceChild(LevelDom.unwrap(value), _childElements.item(index));
  }

   void set length(int newLength) {
     // TODO(jacobr): remove children when length is reduced.
     throw const UnsupportedOperationException('');
   }

  Element add(Element value) {
    _element.appendChild(LevelDom.unwrap(value));
    return value;
  }

  Element addLast(Element value) => add(value);

  Iterator<Element> iterator() => _toList().iterator();

  void addAll(Collection<Element> collection) {
    for (Element element in collection) {
      _element.appendChild(LevelDom.unwrap(element));
    }
  }

  void sort(int compare(Element a, Element b)) {
    throw const UnsupportedOperationException('TODO(jacobr): should we impl?');
  }

  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) {
    throw 'Not impl yet. todo(jacobr)';
  }

  void setRange(int start, int length, List from, [int startFrom = 0]) {
    throw const NotImplementedException();
  }

  void removeRange(int start, int length) {
    throw const NotImplementedException();
  }

  void insertRange(int start, int length, [initialValue = null]) {
    throw const NotImplementedException();
  }

  List getRange(int start, int length) {
    throw const NotImplementedException();
  }

  int indexOf(Element element, [int start = 0]) {
    return _Lists.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(Element element, [int start = null]) {
    if (start === null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  void clear() {
    // It is unclear if we want to keep non element nodes?
    _element.textContent = '';
  }

  Element removeLast() {
    final last = this.last();
    if (last != null) {
      _element.removeChild(LevelDom.unwrap(last));
    }
    return last;
  }

  Element last() {
    return LevelDom.wrapElement(_element.lastElementChild);
  }
}

class FrozenElementList implements ElementList {
  final _ptr;

  FrozenElementList._wrap(this._ptr);

  Element get first() {
    return this[0];
  }

  void forEach(void f(Element element)) {
    for (var element in _ptr) {
      f(LevelDom.wrapElement(element));
    }
  }

  Collection<Element> filter(bool f(Element element)) {
    throw 'Not impl yet. todo(jacobr)';
  }

  bool every(bool f(Element element)) {
    throw 'Not impl yet. todo(jacobr)';
  }

  bool some(bool f(Element element)) {
    throw 'Not impl yet. todo(jacobr)';
  }

  bool isEmpty() {
    return _ptr.length == 0;
  }

  int get length() {
    return _ptr.length;
  }

  Element operator [](int index) {
    return LevelDom.wrapElement(_ptr[index]);
  }

  void operator []=(int index, Element value) {
    throw const UnsupportedOperationException('');
  }

   void set length(int newLength) {
    throw const UnsupportedOperationException('');
   }

  void add(Element value) {
    throw const UnsupportedOperationException('');
  }


  void addLast(Element value) {
    throw const UnsupportedOperationException('');
  }

  Iterator<Element> iterator() => new FrozenElementListIterator(this);

  void addAll(Collection<Element> collection) {
    throw const UnsupportedOperationException('');
  }

  void sort(int compare(Element a, Element b)) {
    throw const UnsupportedOperationException('');
  }

  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) {
    throw 'Not impl yet. todo(jacobr)';
  }

  void setRange(int start, int length, List from, [int startFrom = 0]) {
    throw const NotImplementedException();
  }

  void removeRange(int start, int length) {
    throw const NotImplementedException();
  }

  void insertRange(int start, int length, [initialValue = null]) {
    throw const NotImplementedException();
  }

  List getRange(int start, int length) {
    throw const NotImplementedException();
  }

  int indexOf(Element element, [int start = 0]) {
    throw 'Not impl yet. todo(jacobr)';
  }

  int lastIndexOf(Element element, [int start = null]) {
    throw 'Not impl yet. todo(jacobr)';
  }

  void clear() {
    throw 'Not impl yet. todo(jacobr)';
  }

  Element removeLast() {
    throw 'Not impl yet. todo(jacobr)';
  }

  Element last() {
    return this[length-1];
  }
}

class FrozenElementListIterator implements Iterator<Element> {
  final FrozenElementList _list;
  int _index = 0;

  FrozenElementListIterator(this._list);

  /**
   * Gets the next element in the iteration. Throws a
   * [NoMoreElementsException] if no element is left.
   */
  Element next() {
    if (!hasNext()) {
      throw const NoMoreElementsException();
    }

    return _list[_index++];
  }

  /**
   * Returns whether the [Iterator] has elements left.
   */
  bool hasNext() => _index < _list.length;
}

class ElementAttributeMap implements Map<String, String> {

  final _element;

  ElementAttributeMap._wrap(this._element);

  bool containsValue(String value) {
    final attributes = _element.attributes;
    for (int i = 0, len = attributes.length; i < len; i++) {
      if(value == attributes.item(i).value) {
        return true;
      }
    }
    return false;
  }

  /** @domName Element.hasAttribute */
  bool containsKey(String key) {
    return _element.hasAttribute(key);
  }

  /** @domName Element.getAttribute */
  String operator [](String key) {
    return _element.getAttribute(key);
  }

  /** @domName Element.setAttribute */
  void operator []=(String key, String value) {
    _element.setAttribute(key, value);
  }

  String putIfAbsent(String key, String ifAbsent()) {
    if (!containsKey(key)) {
      this[key] = ifAbsent();
    }
  }

  /** @domName Element.removeAttribute */
  String remove(String key) {
    _element.removeAttribute(key);
  }

  void clear() {
    final attributes = _element.attributes;
    for (int i = attributes.length - 1; i >= 0; i--) {
      _element.removeAttribute(attributes.item(i).name);
    }
  }

  void forEach(void f(String key, String value)) {
    final attributes = _element.attributes;
    for (int i = 0, len = attributes.length; i < len; i++) {
      final item = attributes.item(i);
      f(item.name, item.value);
    }
  }

  Collection<String> getKeys() {
    // TODO(jacobr): generate a lazy collection instead.
    final attributes = _element.attributes;
    final keys = new List<String>(attributes.length);
    for (int i = 0, len = attributes.length; i < len; i++) {
      keys[i] = attributes.item(i).name;
    }
    return keys;
  }

  Collection<String> getValues() {
    // TODO(jacobr): generate a lazy collection instead.
    final attributes = _element.attributes;
    final values = new List<String>(attributes.length);
    for (int i = 0, len = attributes.length; i < len; i++) {
      values[i] = attributes.item(i).value;
    }
    return values;
  }

  /**
   * The number of {key, value} pairs in the map.
   */
  int get length() {
    return _element.attributes.length;
  }

  /**
   * Returns true if there is no {key, value} pair in the map.
   */
  bool isEmpty() {
    return !_element.hasAttributes();
  }
}

class ElementEventsImplementation extends EventsImplementation implements ElementEvents {
  ElementEventsImplementation._wrap(_ptr) : super._wrap(_ptr);

  EventListenerList get abort() => _get("abort");
  EventListenerList get beforeCopy() => _get("beforecopy");
  EventListenerList get beforeCut() => _get("beforecut");
  EventListenerList get beforePaste() => _get("beforepaste");
  EventListenerList get blur() => _get("blur");
  EventListenerList get change() => _get("change");
  EventListenerList get click() => _get("click");
  EventListenerList get contextMenu() => _get("contextmenu");
  EventListenerList get copy() => _get("copy");
  EventListenerList get cut() => _get("cut");
  EventListenerList get dblClick() => _get("dblclick");
  EventListenerList get drag() => _get("drag");
  EventListenerList get dragEnd() => _get("dragend");
  EventListenerList get dragEnter() => _get("dragenter");
  EventListenerList get dragLeave() => _get("dragleave");
  EventListenerList get dragOver() => _get("dragover");
  EventListenerList get dragStart() => _get("dragstart");
  EventListenerList get drop() => _get("drop");
  EventListenerList get error() => _get("error");
  EventListenerList get focus() => _get("focus");
  EventListenerList get input() => _get("input");
  EventListenerList get invalid() => _get("invalid");
  EventListenerList get keyDown() => _get("keydown");
  EventListenerList get keyPress() => _get("keypress");
  EventListenerList get keyUp() => _get("keyup");
  EventListenerList get load() => _get("load");
  EventListenerList get mouseDown() => _get("mousedown");
  EventListenerList get mouseMove() => _get("mousemove");
  EventListenerList get mouseOut() => _get("mouseout");
  EventListenerList get mouseOver() => _get("mouseover");
  EventListenerList get mouseUp() => _get("mouseup");
  EventListenerList get mouseWheel() => _get("mousewheel");
  EventListenerList get paste() => _get("paste");
  EventListenerList get reset() => _get("reset");
  EventListenerList get scroll() => _get("scroll");
  EventListenerList get search() => _get("search");
  EventListenerList get select() => _get("select");
  EventListenerList get selectStart() => _get("selectstart");
  EventListenerList get submit() => _get("submit");
  EventListenerList get touchCancel() => _get("touchcancel");
  EventListenerList get touchEnd() => _get("touchend");
  EventListenerList get touchLeave() => _get("touchleave");
  EventListenerList get touchMove() => _get("touchmove");
  EventListenerList get touchStart() => _get("touchstart");
  EventListenerList get transitionEnd() => _get("webkitTransitionEnd");
  EventListenerList get fullscreenChange() => _get("webkitfullscreenchange");
}

class SimpleClientRect implements ClientRect {
  final num left;
  final num top;
  final num width;
  final num height;
  num get right() => left + width;
  num get bottom() => top + height;

  const SimpleClientRect(this.left, this.top, this.width, this.height);

  bool operator ==(ClientRect other) {
    return other !== null && left == other.left && top == other.top
        && width == other.width && height == other.height;
  }

  String toString() => "($left, $top, $width, $height)";
}

// TODO(jacobr): we cannot currently be lazy about calculating the client
// rects as we must perform all measurement queries at a safe point to avoid
// triggering unneeded layouts.
/**
 * All your element measurement needs in one place
 * @domName none
 */
class ElementRectWrappingImplementation implements ElementRect {
  final ClientRect client;
  final ClientRect offset;
  final ClientRect scroll;

  // TODO(jacobr): should we move these outside of ElementRect to avoid the
  // overhead of computing them every time even though they are rarely used.
  // This should be type dom.ClientRect but that fails on dartium. b/5522629
  final _boundingClientRect; 
  // an exception due to a dartium bug.
  final _clientRects; // TODO(jacobr): should be dom.ClientRectList

  ElementRectWrappingImplementation(dom.HTMLElement element) :
    client = new SimpleClientRect(element.clientLeft,
                                  element.clientTop,
                                  element.clientWidth, 
                                  element.clientHeight), 
    offset = new SimpleClientRect(element.offsetLeft,
                                  element.offsetTop,
                                  element.offsetWidth,
                                  element.offsetHeight),
    scroll = new SimpleClientRect(element.scrollLeft,
                                  element.scrollTop,
                                  element.scrollWidth,
                                  element.scrollHeight),
    _boundingClientRect = element.getBoundingClientRect(),
    _clientRects = element.getClientRects();

  ClientRect get bounding() =>
      LevelDom.wrapClientRect(_boundingClientRect);

  List<ClientRect> get clientRects() {
    final out = new List(_clientRects.length);
    for (num i = 0; i < _clientRects.length; i++) {
      out[i] = LevelDom.wrapClientRect(_clientRects.item(i));
    }
    return out;
  }
}

class ElementWrappingImplementation extends NodeWrappingImplementation implements Element {
  
    static final _START_TAG_REGEXP = const RegExp('<(\\w+)');
    static final _CUSTOM_PARENT_TAG_MAP = const {
      'body' : 'html',
      'head' : 'html',
      'caption' : 'table',
      'td': 'tr',
      'tbody': 'table',
      'colgroup': 'table',
      'col' : 'colgroup',
      'tr' : 'tbody',
      'tbody' : 'table',
      'tfoot' : 'table',
      'thead' : 'table',
      'track' : 'audio',
    };

   factory ElementWrappingImplementation.html(String html) {
    // TODO(jacobr): this method can be made more robust and performant.
    // 1) Cache the dummy parent elements required to use innerHTML rather than
    //    creating them every call.
    // 2) Verify that the html does not contain leading or trailing text nodes.
    // 3) Verify that the html does not contain both <head> and <body> tags.
    // 4) Detatch the created element from its dummy parent.
    String parentTag = 'div';
    String tag;
    final match = _START_TAG_REGEXP.firstMatch(html);
    if (match !== null) {
      tag = match.group(1).toLowerCase();
      if (_CUSTOM_PARENT_TAG_MAP.containsKey(tag)) {
        parentTag = _CUSTOM_PARENT_TAG_MAP[tag];
      }
    }
    // TODO(jacobr): make type dom.HTMLElement when dartium allows it.
    var temp = dom.document.createElement(parentTag);
    temp.innerHTML = html;

    if (temp.childElementCount == 1) {
      return LevelDom.wrapElement(temp.firstElementChild);     
    } else if (parentTag == 'html' && temp.childElementCount == 2) {
      // Work around for edge case in WebKit and possibly other browsers where
      // both body and head elements are created even though the inner html
      // only contains a head or body element.
      return LevelDom.wrapElement(temp.children.item(tag == 'head' ? 0 : 1));
    } else {
      throw 'HTML had ${temp.childElementCount} top level elements but 1 expected';
    }
  }

  factory ElementWrappingImplementation.tag(String tag) {
    return LevelDom.wrapElement(dom.document.createElement(tag));
  }

  ElementWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  ElementAttributeMap _elementAttributeMap;
  ElementList _elements;
  _CssClassSet _cssClassSet;
  _DataAttributeMap _dataAttributes;

  Map<String, String> get attributes() {
    if (_elementAttributeMap === null) {
      _elementAttributeMap = new ElementAttributeMap._wrap(_ptr);
    }
    return _elementAttributeMap;
  }

  void set attributes(Map<String, String> value) {
    Map<String, String> attributes = this.attributes;
    attributes.clear();
    for (String key in value.getKeys()) {
      attributes[key] = value[key];
    }
  }

  void set elements(Collection<Element> value) {
    // Copy list first since we don't want liveness during iteration.
    List copy = new List.from(value);
    final elements = this.elements;
    elements.clear();
    elements.addAll(copy);
  }

  ElementList get elements() {
    if (_elements == null) {
      _elements = new _ChildrenElementList._wrap(_ptr);
    }
    return _elements;
  }

  Set<String> get classes() {
    if (_cssClassSet === null) {
      _cssClassSet = new _CssClassSet(_ptr);
    }
    return _cssClassSet;
  }

  void set classes(Collection<String> value) {
    _CssClassSet classSet = classes;
    classSet.clear();
    classSet.addAll(value);
  }

  Map<String, String> get dataAttributes() {
    if (_dataAttributes === null) {
      _dataAttributes = new _DataAttributeMap(attributes);
    }
    return _dataAttributes;
  }

  void set dataAttributes(Map<String, String> value) {
    Map<String, String> dataAttributes = this.dataAttributes;
    dataAttributes.clear();
    for (String key in value.getKeys()) {
      dataAttributes[key] = value[key];
    }
  }

  String get contentEditable() => _ptr.contentEditable;

  void set contentEditable(String value) { _ptr.contentEditable = value; }

  String get dir() => _ptr.dir;

  void set dir(String value) { _ptr.dir = value; }

  bool get draggable() => _ptr.draggable;

  void set draggable(bool value) { _ptr.draggable = value; }

  Element get firstElementChild() => LevelDom.wrapElement(_ptr.firstElementChild);

  bool get hidden() => _ptr.hidden;

  void set hidden(bool value) { _ptr.hidden = value; }

  String get id() => _ptr.id;

  void set id(String value) { _ptr.id = value; }

  String get innerHTML() => _ptr.innerHTML;

  void set innerHTML(String value) { _ptr.innerHTML = value; }

  bool get isContentEditable() => _ptr.isContentEditable;

  String get lang() => _ptr.lang;

  void set lang(String value) { _ptr.lang = value; }

  Element get lastElementChild() => LevelDom.wrapElement(_ptr.lastElementChild);

  Element get nextElementSibling() => LevelDom.wrapElement(_ptr.nextElementSibling);

  Element get offsetParent() => LevelDom.wrapElement(_ptr.offsetParent);

  String get outerHTML() => _ptr.outerHTML;

  Element get previousElementSibling() => LevelDom.wrapElement(_ptr.previousElementSibling);

  bool get spellcheck() => _ptr.spellcheck;

  void set spellcheck(bool value) { _ptr.spellcheck = value; }

  CSSStyleDeclaration get style() => LevelDom.wrapCSSStyleDeclaration(_ptr.style);

  int get tabIndex() => _ptr.tabIndex;

  void set tabIndex(int value) { _ptr.tabIndex = value; }

  String get tagName() => _ptr.tagName;

  String get title() => _ptr.title;

  void set title(String value) { _ptr.title = value; }

  String get webkitdropzone() => _ptr.webkitdropzone;

  void set webkitdropzone(String value) { _ptr.webkitdropzone = value; }

  void blur() {
    _ptr.blur();
  }

  bool contains(Node element) {
    return _ptr.contains(LevelDom.unwrap(element));
  }

  void focus() {
    _ptr.focus();
  }

  /** @domName HTMLElement.insertAdjacentElement */
  Element insertAdjacentElement([String where = null, Element element = null]) {
    return LevelDom.wrapElement(_ptr.insertAdjacentElement(where, LevelDom.unwrap(element)));
  }

  /** @domName HTMLElement.insertAdjacentHTML */
  void insertAdjacentHTML([String position_OR_where = null, String text = null]) {
    _ptr.insertAdjacentHTML(position_OR_where, text);
  }

  /** @domName HTMLElement.insertAdjacentText */
  void insertAdjacentText([String where = null, String text = null]) {
    _ptr.insertAdjacentText(where, text);
  }

  Element query(String selectors) {
    // TODO(jacobr): scope fix.
    return LevelDom.wrapElement(_ptr.querySelector(selectors));
  }

  ElementList queryAll(String selectors) {
    // TODO(jacobr): scope fix.
    return new FrozenElementList._wrap(_ptr.querySelectorAll(selectors));
  }

  void scrollByLines([int lines = null]) {
    _ptr.scrollByLines(lines);
  }

  void scrollByPages([int pages = null]) {
    _ptr.scrollByPages(pages);
  }

  void scrollIntoView([bool centerIfNeeded = null]) {
    _ptr.scrollIntoViewIfNeeded(centerIfNeeded);
  }

  bool matchesSelector([String selectors = null]) {
    return _ptr.webkitMatchesSelector(selectors);
  }

  void set scrollLeft(int value) { _ptr.scrollLeft = value; }
 
  void set scrollTop(int value) { _ptr.scrollTop = value; }

  /** @domName getClientRects */
  Future<ElementRect> get rect() {
    return _createMeasurementFuture(
        () => new ElementRectWrappingImplementation(_ptr),
        new Completer<ElementRect>());
  }

  Future<CSSStyleDeclaration> get computedStyle() {
     // TODO(jacobr): last param should be null, see b/5045788
     return getComputedStyle('');
  }

  /** @domName Window.getComputedStyle */
  Future<CSSStyleDeclaration> getComputedStyle(String pseudoElement) {
    return _createMeasurementFuture(() =>
        LevelDom.wrapCSSStyleDeclaration(
            dom.window.getComputedStyle(_ptr, pseudoElement)),
        new Completer<CSSStyleDeclaration>());
  }

  ElementEvents get on() {
    if (_on === null) {
      _on = new ElementEventsImplementation._wrap(_ptr);
    }
    return _on;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ErrorEventWrappingImplementation extends EventWrappingImplementation implements ErrorEvent {
  ErrorEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory ErrorEventWrappingImplementation(String type, String message,
      String filename, int lineNo, [bool canBubble = true,
      bool cancelable = true]) {
    final e = dom.document.createEvent("ErrorEvent");
    e.initErrorEvent(type, canBubble, cancelable, message, filename, lineNo);
    return LevelDom.wrapErrorEvent(e);
  }

  String get filename() => _ptr.filename;

  int get lineno() => _ptr.lineno;

  String get message() => _ptr.message;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class EventSourceEventsImplementation extends EventsImplementation implements EventSourceEvents {
  EventSourceEventsImplementation._wrap(_ptr) : super._wrap(_ptr);

  EventListenerList get error() => _get('error');
  EventListenerList get message() => _get('message');
  EventListenerList get open() => _get('open');
}

class EventSourceWrappingImplementation extends EventTargetWrappingImplementation implements EventSource {
  EventSourceWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  String get URL() => _ptr.URL;

  int get readyState() => _ptr.readyState;

  void close() {
    _ptr.close();
  }

  EventSourceEvents get on() {
    if (_on === null) {
      _on = new EventSourceEventsImplementation._wrap(_ptr);
    }
    return _on;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class EventsImplementation implements Events {
  /* Raw event target. */
  var _ptr;

  Map<String, EventListenerList> _listenerMap;

  EventsImplementation._wrap(this._ptr) {
    _listenerMap = <EventListenerList>{};
  }

  EventListenerList operator [](String type) {
    return _get(type.toLowerCase());
  }
  
  EventListenerList _get(String type) {
    return _listenerMap.putIfAbsent(type,
      () => new EventListenerListImplementation(_ptr, type));
  }
}

class _EventListenerWrapper {
  final EventListener raw;
  final Function wrapped;
  final bool useCapture;
  _EventListenerWrapper(this.raw, this.wrapped, this.useCapture);
}

class EventListenerListImplementation implements EventListenerList {
  final _ptr;
  final String _type;
  List<_EventListenerWrapper> _wrappers;

  EventListenerListImplementation(this._ptr, this._type) :
    // TODO(jacobr): switch to <_EventListenerWrapper>[] when the VM allow it.
    _wrappers = new List<_EventListenerWrapper>();

  EventListenerList add(EventListener listener, [bool useCapture = false]) {
    _add(listener, useCapture);
    return this;
  }

  EventListenerList remove(EventListener listener, [bool useCapture = false]) {
    _remove(listener, useCapture);
    return this;
  }

  bool dispatch(Event evt) {
    // TODO(jacobr): what is the correct behavior here. We could alternately
    // force the event to have the expected type.
    assert(evt.type == _type);
    return _ptr.dispatchEvent(LevelDom.unwrap(evt));
  }

  void _add(EventListener listener, bool useCapture) {
    _ptr.addEventListener(_type,
                          _findOrAddWrapper(listener, useCapture),
                          useCapture);
  }

  void _remove(EventListener listener, bool useCapture) {
    Function wrapper = _removeWrapper(listener, useCapture);
    if (wrapper !== null) {
      _ptr.removeEventListener(_type, wrapper, useCapture);
    }
  }

  Function _removeWrapper(EventListener listener, bool useCapture) {
    if (_wrappers === null) {
      return null;
    }
    for (int i = 0; i < _wrappers.length; i++) {
      _EventListenerWrapper wrapper = _wrappers[i];
      if (wrapper.raw === listener && wrapper.useCapture == useCapture) {
        // Order doesn't matter so we swap with the last element instead of
        // performing a more expensive remove from the middle of the list.
        if (i + 1 != _wrappers.length) {
          _wrappers[i] = _wrappers.removeLast();
        } else {
          _wrappers.removeLast();
        }
        return wrapper.wrapped;
      }
    }
    return null;
  }

  Function _findOrAddWrapper(EventListener listener, bool useCapture) {
    if (_wrappers === null) {
      _wrappers = <_EventListenerWrapper>[];
    } else {
      for (_EventListenerWrapper wrapper in _wrappers) {
        if (wrapper.raw === listener && wrapper.useCapture == useCapture) {
          return wrapper.wrapped;
        }
      }
    }
    final wrapped = (e) { listener(LevelDom.wrapEvent(e)); };
    _wrappers.add(new _EventListenerWrapper(listener, wrapped, useCapture));
    return wrapped;
  }
}

class EventTargetWrappingImplementation extends DOMWrapperBase implements EventTarget {
  Events _on;

  EventTargetWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  Events get on() {
    if (_on === null) {
      _on = new EventsImplementation._wrap(_ptr);
    }
    return _on;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class EventWrappingImplementation extends DOMWrapperBase implements Event {
  EventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory EventWrappingImplementation(String type, [bool canBubble = true,
      bool cancelable = true]) {
    final e = dom.document.createEvent("Event");
    e.initEvent(type, canBubble, cancelable);
    return LevelDom.wrapEvent(e);
  }

  bool get bubbles() => _ptr.bubbles;

  bool get cancelBubble() => _ptr.cancelBubble;

  void set cancelBubble(bool value) { _ptr.cancelBubble = value; }

  bool get cancelable() => _ptr.cancelable;

  EventTarget get currentTarget() => LevelDom.wrapEventTarget(_ptr.currentTarget);

  bool get defaultPrevented() => _ptr.defaultPrevented;

  int get eventPhase() => _ptr.eventPhase;

  bool get returnValue() => _ptr.returnValue;

  void set returnValue(bool value) { _ptr.returnValue = value; }

  EventTarget get srcElement() => LevelDom.wrapEventTarget(_ptr.srcElement);

  EventTarget get target() => LevelDom.wrapEventTarget(_ptr.target);

  int get timeStamp() => _ptr.timeStamp;

  String get type() => _ptr.type;

  void preventDefault() {
    _ptr.preventDefault();
    return;
  }

  void stopImmediatePropagation() {
    _ptr.stopImmediatePropagation();
    return;
  }

  void stopPropagation() {
    _ptr.stopPropagation();
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class HashChangeEventWrappingImplementation extends EventWrappingImplementation implements HashChangeEvent {
  HashChangeEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory HashChangeEventWrappingImplementation(String type, String oldURL,
      String newURL, [bool canBubble = true, bool cancelable = true]) {
    final e = dom.document.createEvent("HashChangeEvent");
    e.initHashChangeEvent(type, canBubble, cancelable, oldURL, newURL);
    return LevelDom.wrapHashChangeEvent(e);
  }

  String get newURL() => _ptr.newURL;

  String get oldURL() => _ptr.oldURL;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class KeyboardEventWrappingImplementation extends UIEventWrappingImplementation implements KeyboardEvent {
  KeyboardEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory KeyboardEventWrappingImplementation(String type, Window view,
      String keyIdentifier, int keyLocation, [bool canBubble = true,
      bool cancelable = true, bool ctrlKey = false, bool altKey = false,
      bool shiftKey = false, bool metaKey = false, bool altGraphKey = false]) {
    final e = dom.document.createEvent("KeyboardEvent");
    e.initKeyboardEvent(type, canBubble, cancelable, LevelDom.unwrap(view),
        keyIdentifier, keyLocation, ctrlKey, altKey, shiftKey, metaKey,
        altGraphKey);
    return LevelDom.wrapKeyboardEvent(e);
  }

  bool get altGraphKey() => _ptr.altGraphKey;

  bool get altKey() => _ptr.altKey;

  bool get ctrlKey() => _ptr.ctrlKey;

  String get keyIdentifier() => _ptr.keyIdentifier;

  int get keyLocation() => _ptr.keyLocation;

  bool get metaKey() => _ptr.metaKey;

  bool get shiftKey() => _ptr.shiftKey;

  bool getModifierState(String keyIdentifierArg) {
    return _ptr.getModifierState(keyIdentifierArg);
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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

final _MEASUREMENT_MESSAGE = "DART-MEASURE";
List<_MeasurementRequest> _pendingRequests;
List<TimeoutHandler> _pendingMeasurementFrameCallbacks;
bool _nextMeasurementFrameScheduled = false;
bool _firstMeasurementRequest = true;

void _maybeScheduleMeasurementFrame() {
  if (_nextMeasurementFrameScheduled) return;

  _nextMeasurementFrameScheduled = true;
  // postMessage gives us a way to receive a callback after the current
  // event listener has unwound but before the browser has repainted.
  if (_firstMeasurementRequest) {
    // Messages from other windows do not cause a security risk as
    // all we care about is that _onCompleteMeasurementRequests is called
    // after the current event loop is unwound and calling the function is
    // a noop when zero requests are pending.
    window.on.message.add((e) => _completeMeasurementFutures());
    _firstMeasurementRequest = false;
  }

  // TODO(jacobr): other mechanisms such as setImmediate and
  // requestAnimationFrame may work better of platforms that support them.
  // The key is we need a way to execute code immediately after the current
  // event listener queue unwinds.
  window.postMessage(_MEASUREMENT_MESSAGE, "*");
}

/**
 * Registers a [callback] which is called after the next batch of measurements
 * completes. Even if no measurements completed, the callback is triggered
 * when they would have completed to avoid confusing bugs if it happened that
 * no measurements were actually requested.
 */
void _addMeasurementFrameCallback(TimeoutHandler callback) {
  if (_pendingMeasurementFrameCallbacks === null) {
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
  if (_pendingRequests === null) {
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
  if (_nextMeasurementFrameScheduled == false) {
    // Ignore spurious call to this function.
    return;
  }

  _nextMeasurementFrameScheduled = false;
  // We must compute all new values before fulfilling the futures as
  // the onComplete callbacks for the futures could modify the DOM making
  // subsequent measurement calculations expensive to compute.
  if (_pendingRequests !== null) {
    for (_MeasurementRequest request in _pendingRequests) {
      try {
        request.value = request.computeValue();
      } catch(var e) {
        request.value = e;
        request.exception = true;
      }
    }
  }

  final completedRequests = _pendingRequests;
  final readyMeasurementFrameCallbacks = _pendingMeasurementFrameCallbacks;
  _pendingRequests = null;
  _pendingMeasurementFrameCallbacks = null;
  if (completedRequests !== null) {
    for (_MeasurementRequest request in completedRequests) {
      if (request.exception) {
        request.completer.completeException(request.value);
      } else {
        request.completer.complete(request.value);
      }
    }
  }

  if (readyMeasurementFrameCallbacks !== null) {
    for (TimeoutHandler handler in readyMeasurementFrameCallbacks) {
      // TODO(jacobr): wrap each call to a handler in a try-catch block.
      handler();
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class MessageEventWrappingImplementation extends EventWrappingImplementation implements MessageEvent {
  MessageEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory MessageEventWrappingImplementation(String type, String data,
      String origin, String lastEventId, Window source, MessagePort port,
      [bool canBubble = true, bool cancelable = true]) {
    final e = dom.document.createEvent("MessageEvent");
    e.initMessageEvent(type, canBubble, cancelable, data, origin, lastEventId,
        LevelDom.unwrap(source), LevelDom.unwrap(port));
    return LevelDom.wrapMessageEvent(e);
  }

  String get data() => _ptr.data;

  String get lastEventId() => _ptr.lastEventId;

  MessagePort get messagePort() => LevelDom.wrapMessagePort(_ptr.messagePort);

  String get origin() => _ptr.origin;

  Window get source() => LevelDom.wrapWindow(_ptr.source);

  void initMessageEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String dataArg, String originArg, String lastEventIdArg, Window sourceArg, MessagePort messagePort) {
    _ptr.initMessageEvent(typeArg, canBubbleArg, cancelableArg, dataArg, originArg, lastEventIdArg, LevelDom.unwrap(sourceArg), LevelDom.unwrap(messagePort));
    return;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class MessagePortWrappingImplementation extends EventTargetWrappingImplementation implements MessagePort {
  MessagePortWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class MouseEventWrappingImplementation extends UIEventWrappingImplementation implements MouseEvent {
  MouseEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory MouseEventWrappingImplementation(String type, Window view, int detail,
      int screenX, int screenY, int clientX, int clientY, int button,
      [bool canBubble = true, bool cancelable = true, bool ctrlKey = false,
      bool altKey = false, bool shiftKey = false, bool metaKey = false,
      EventTarget relatedTarget = null]) {
    final e = dom.document.createEvent("MouseEvent");
    e.initMouseEvent(type, canBubble, cancelable, LevelDom.unwrap(view), detail,
        screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey,
        button, LevelDom.unwrap(relatedTarget));
    return LevelDom.wrapMouseEvent(e);
  }

  bool get altKey() => _ptr.altKey;

  int get button() => _ptr.button;

  int get clientX() => _ptr.clientX;

  int get clientY() => _ptr.clientY;

  bool get ctrlKey() => _ptr.ctrlKey;

  Node get fromElement() => LevelDom.wrapNode(_ptr.fromElement);

  bool get metaKey() => _ptr.metaKey;

  int get offsetX() => _ptr.offsetX;

  int get offsetY() => _ptr.offsetY;

  EventTarget get relatedTarget() => LevelDom.wrapEventTarget(_ptr.relatedTarget);

  int get screenX() => _ptr.screenX;

  int get screenY() => _ptr.screenY;

  bool get shiftKey() => _ptr.shiftKey;

  Node get toElement() => LevelDom.wrapNode(_ptr.toElement);

  int get x() => _ptr.x;

  int get y() => _ptr.y;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class MutationEventWrappingImplementation extends EventWrappingImplementation implements MutationEvent {
  MutationEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory MutationEventWrappingImplementation(String type, Node relatedNode,
      String prevValue, String newValue, String attrName, int attrChange,
      [bool canBubble = true, bool cancelable = true]) {
    final e = dom.document.createEvent("MutationEvent");
    e.initMutationEvent(type, canBubble, cancelable,
        LevelDom.unwrap(relatedNode), prevValue, newValue, attrName,
        attrChange);
    return LevelDom.wrapMutationEvent(e);
  }

  int get attrChange() => _ptr.attrChange;

  String get attrName() => _ptr.attrName;

  String get newValue() => _ptr.newValue;

  String get prevValue() => _ptr.prevValue;

  Node get relatedNode() => LevelDom.wrapNode(_ptr.relatedNode);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _ChildrenNodeList implements NodeList {
  // Raw node.
  final _node;
  final _childNodes;

  _ChildrenNodeList._wrap(var node)
    : _childNodes = node.childNodes,
      _node = node;

  List<Node> _toList() {
    final output = new List(_childNodes.length);
    for (int i = 0, len = _childNodes.length; i < len; i++) {
      output[i] = LevelDom.wrapNode(_childNodes[i]);
    }
    return output;
  }

  Node get first() {
    return LevelDom.wrapNode(_node.firstChild);
  }

  void forEach(void f(Node element)) {
    for (var node in _childNodes) {
      f(LevelDom.wrapNode(node));
    }
  }

  Collection<Node> filter(bool f(Node element)) {
    List<Node> output = new List<Node>();
    forEach((Node element) {
      if (f(element)) {
        output.add(element);
      }
    });
    return output;
  }

  bool every(bool f(Node element)) {
    for(Node element in this) {
      if (!f(element)) {
        return false;
      }
    };
    return true;
  }

  bool some(bool f(Node element)) {
    for(Node element in this) {
      if (f(element)) {
        return true;
      }
    };
    return false;
  }

  /** @domName Node.hasChildNodes */
  bool isEmpty() {
    return !_node.hasChildNodes();
  }

  int get length() {
    return _childNodes.length;
  }

  Node operator [](int index) {
    return LevelDom.wrapNode(_childNodes[index]);
  }

  void operator []=(int index, Node value) {
    _childNodes[index] = LevelDom.unwrap(value);
  }

   void set length(int newLength) {
     throw new UnsupportedOperationException('');
   }

  /** @domName Node.appendChild */
  Node add(Node value) {
    _node.appendChild(LevelDom.unwrap(value));
    return value;
  }

  Node addLast(Node value) {
    _node.appendChild(LevelDom.unwrap(value));
    return value;
  }

  Iterator<Node> iterator() {
    return _toList().iterator();
  }

  void addAll(Collection<Node> collection) {
    for (Node node in collection) {
      _node.appendChild(LevelDom.unwrap(node));
    }
  }

  void sort(int compare(Node a, Node b)) {
    throw const UnsupportedOperationException('TODO(jacobr): should we impl?');
  }

  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) {
    throw 'Not impl yet. todo(jacobr)';
  }

  void setRange(int start, int length, List from, [int startFrom = 0]) {
    throw const NotImplementedException();
  }

  void removeRange(int start, int length) {
    throw const NotImplementedException();
  }

  void insertRange(int start, int length, [initialValue = null]) {
    throw const NotImplementedException();
  }

  List getRange(int start, int length) {
    throw const NotImplementedException();
  }

  int indexOf(Node element, [int start = 0]) {
    return _Lists.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(Node element, [int start = null]) {
    if (start === null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  void clear() {
    _node.textContent = '';
  }

  Node removeLast() {
    final last = this.last();
    if (last != null) {
      _node.removeChild(LevelDom.unwrap(last));
    }
    return last;
  }

  Node last() {
    return LevelDom.wrapNode(_node.lastChild);
  }
}

class NodeWrappingImplementation extends EventTargetWrappingImplementation implements Node {
  NodeList _nodes;

  NodeWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  void set nodes(Collection<Node> value) {
    // Copy list first since we don't want liveness during iteration.
    List copy = new List.from(value);
    nodes.clear();
    nodes.addAll(copy);
  }

  NodeList get nodes() {
    if (_nodes === null) {
      _nodes = new _ChildrenNodeList._wrap(_ptr);
    }
    return _nodes;
  }

  Node get nextNode() => LevelDom.wrapNode(_ptr.nextSibling);

  Document get document() => LevelDom.wrapDocument(_ptr.ownerDocument);

  Node get parent() => LevelDom.wrapNode(_ptr.parentNode);

  Node get previousNode() => LevelDom.wrapNode(_ptr.previousSibling);

  String get text() => _ptr.textContent;

  void set text(String value) { _ptr.textContent = value; }

  // New methods implemented.
  Node replaceWith(Node otherNode) {
    try {
      _ptr.parentNode.replaceChild(LevelDom.unwrap(otherNode), _ptr);
    } catch(var e) {
      // TODO(jacobr): what should we return on failure?
    }
    return this;
  }

  Node remove() {
    // TODO(jacobr): should we throw an exception if parent is already null?
    if (_ptr.parentNode !== null) {
      _ptr.parentNode.removeChild(_ptr);
    }
    return this;
  }

  /** @domName contains */
  bool contains(Node otherNode) {
    // TODO: Feature detect and use built in.
    while (otherNode != null && otherNode != this) {
      otherNode = otherNode.parent;
    }
    return otherNode == this;
  }

  // TODO(jacobr): remove when/if List supports a method similar to
  // insertBefore or we switch NodeList to implement LinkedList rather than
  // array.
  Node insertBefore(Node newChild, Node refChild) {
    return LevelDom.wrapNode(_ptr.insertBefore(
        LevelDom.unwrap(newChild), LevelDom.unwrap(refChild)));
  }

  Node clone(bool deep) {
    return LevelDom.wrapNode(_ptr.cloneNode(deep));
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jacobr) add custom Events class.
class NotificationWrappingImplementation extends EventTargetWrappingImplementation implements Notification {
  NotificationWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get dir() { return _ptr.dir; }

  void set dir(String value) { _ptr.dir = value; }

  EventListener get onclick() { return LevelDom.wrapEventListener(_ptr.onclick); }

  void set onclick(EventListener value) { _ptr.onclick = LevelDom.unwrap(value); }

  EventListener get onclose() { return LevelDom.wrapEventListener(_ptr.onclose); }

  void set onclose(EventListener value) { _ptr.onclose = LevelDom.unwrap(value); }

  EventListener get ondisplay() { return LevelDom.wrapEventListener(_ptr.ondisplay); }

  void set ondisplay(EventListener value) { _ptr.ondisplay = LevelDom.unwrap(value); }

  EventListener get onerror() { return LevelDom.wrapEventListener(_ptr.onerror); }

  void set onerror(EventListener value) { _ptr.onerror = LevelDom.unwrap(value); }

  String get replaceId() { return _ptr.replaceId; }

  void set replaceId(String value) { _ptr.replaceId = value; }

  void cancel() {
    _ptr.cancel();
    return;
  }

  void show() {
    _ptr.show();
    return;
  }

  String get typeName() { return "Notification"; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class OverflowEventWrappingImplementation extends EventWrappingImplementation implements OverflowEvent {
  OverflowEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  /** @domName OverflowEvent.initOverflowEvent */
  factory OverflowEventWrappingImplementation(int orient,
      bool horizontalOverflow, bool verticalOverflow) {
    final e = dom.document.createEvent("OverflowEvent");
    e.initOverflowEvent(orient, horizontalOverflow, verticalOverflow);
    return LevelDom.wrapOverflowEvent(e);
  }

  bool get horizontalOverflow() => _ptr.horizontalOverflow;

  int get orient() => _ptr.orient;

  bool get verticalOverflow() => _ptr.verticalOverflow;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class PageTransitionEventWrappingImplementation extends EventWrappingImplementation implements PageTransitionEvent {
  PageTransitionEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory PageTransitionEventWrappingImplementation(String type,
      [bool canBubble = true, bool cancelable = true,
      bool persisted = false]) {
    final e = dom.document.createEvent("PageTransitionEvent");
    e.initPageTransitionEvent(type, canBubble, cancelable, persisted);
    return LevelDom.wrapPageTransitionEvent(e);
  }

  bool get persisted() => _ptr.persisted;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class PopStateEventWrappingImplementation extends EventWrappingImplementation implements PopStateEvent {
  PopStateEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory PopStateEventWrappingImplementation(String type, Object state,
      [bool canBubble = true, bool cancelable = true]) {
    final e = dom.document.createEvent("PopStateEvent");
    e.initPopStateEvent(type, canBubble, cancelable, state);
    return LevelDom.wrapPopStateEvent(e);
  }

  String get state() => _ptr.state;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ProgressEventWrappingImplementation extends EventWrappingImplementation implements ProgressEvent {
  ProgressEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory ProgressEventWrappingImplementation(String type, int loaded,
      [bool canBubble = true, bool cancelable = true,
      bool lengthComputable = false, int total = 0]) {
    final e = dom.document.createEvent("ProgressEvent");
    e.initProgressEvent(type, canBubble, cancelable, lengthComputable, loaded,
        total);
    return LevelDom.wrapProgressEvent(e);
  }

  bool get lengthComputable() => _ptr.lengthComputable;

  int get loaded() => _ptr.loaded;

  int get total() => _ptr.total;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class SharedWorkerWrappingImplementation extends AbstractWorkerWrappingImplementation implements SharedWorker {
  SharedWorkerWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  MessagePort get port() { return LevelDom.wrapMessagePort(_ptr.port); }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class StorageEventWrappingImplementation extends EventWrappingImplementation implements StorageEvent {
  StorageEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory StorageEventWrappingImplementation(String type, String key,
      String url, Storage storageArea, [bool canBubble = true,
      bool cancelable = true, String oldValue = null,
      String newValue = null]) {
    final e = dom.document.createEvent("StorageEvent");
    e.initStorageEvent(type, canBubble, cancelable, key, oldValue, newValue,
        url, LevelDom.unwrap(storageArea));
    return LevelDom.wrapStorageEvent(e);
  }

  String get key() => _ptr.key;

  String get newValue() => _ptr.newValue;

  String get oldValue() => _ptr.oldValue;

  Storage get storageArea() => LevelDom.wrapStorage(_ptr.storageArea);

  String get url() => _ptr.url;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGDocumentWrappingImplementation extends DocumentWrappingImplementation implements SVGDocument {
  SVGDocumentWrappingImplementation._wrap(dom.SVGDocument ptr) : super._wrap(ptr, ptr.rootElement);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGElementInstanceWrappingImplementation extends EventTargetWrappingImplementation implements SVGElementInstance {
  SVGElementInstanceWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SVGElementInstanceList get childNodes() { return LevelDom.wrapSVGElementInstanceList(_ptr.childNodes); }

  SVGElement get correspondingElement() { return LevelDom.wrapSVGElement(_ptr.correspondingElement); }

  SVGUseElement get correspondingUseElement() { return LevelDom.wrapSVGUseElement(_ptr.correspondingUseElement); }

  SVGElementInstance get firstChild() { return LevelDom.wrapSVGElementInstance(_ptr.firstChild); }

  SVGElementInstance get lastChild() { return LevelDom.wrapSVGElementInstance(_ptr.lastChild); }

  SVGElementInstance get nextSibling() { return LevelDom.wrapSVGElementInstance(_ptr.nextSibling); }

  SVGElementInstance get parentNode() { return LevelDom.wrapSVGElementInstance(_ptr.parentNode); }

  SVGElementInstance get previousSibling() { return LevelDom.wrapSVGElementInstance(_ptr.previousSibling); }

}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class TextEventWrappingImplementation extends UIEventWrappingImplementation implements TextEvent {
  TextEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory TextEventWrappingImplementation(String type, Window view, String data,
      [bool canBubble = true, bool cancelable = true]) {
    final e = dom.document.createEvent("TextEvent");
    e.initTextEvent(type, canBubble, cancelable, LevelDom.unwrap(view), data);
    return LevelDom.wrapTextEvent(e);
  }

  String get data() => _ptr.data;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class TextWrappingImplementation extends CharacterDataWrappingImplementation implements Text {
  /** @domName Document.createTextNode */
  factory TextWrappingImplementation(String content) {
    return new TextWrappingImplementation._wrap(
        dom.document.createTextNode(content));
  }

  TextWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  String get wholeText() => _ptr.wholeText;

  Text replaceWholeText([String content = null]) {
    if (content === null) {
      return LevelDom.wrapText(_ptr.replaceWholeText());
    } else {
      return LevelDom.wrapText(_ptr.replaceWholeText(content));
    }
  }

  Text splitText([int offset = null]) {
    if (offset === null) {
      return LevelDom.wrapText(_ptr.splitText());
    } else {
      return LevelDom.wrapText(_ptr.splitText(offset));
    }
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class TouchEventWrappingImplementation extends UIEventWrappingImplementation implements TouchEvent {
  TouchEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory TouchEventWrappingImplementation(TouchList touches, TouchList targetTouches,
      TouchList changedTouches, String type, Window view, int screenX,
      int screenY, int clientX, int clientY, [bool ctrlKey = false,
      bool altKey = false, bool shiftKey = false, bool metaKey = false]) {
    final e = dom.document.createEvent("TouchEvent");
    e.initTouchEvent(LevelDom.unwrap(touches), LevelDom.unwrap(targetTouches),
        LevelDom.unwrap(changedTouches), type, LevelDom.unwrap(view), screenX,
        screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey);
    return LevelDom.wrapTouchEvent(e);
  }

  bool get altKey() => _ptr.altKey;

  TouchList get changedTouches() => LevelDom.wrapTouchList(_ptr.changedTouches);

  bool get ctrlKey() => _ptr.ctrlKey;

  bool get metaKey() => _ptr.metaKey;

  bool get shiftKey() => _ptr.shiftKey;

  TouchList get targetTouches() => LevelDom.wrapTouchList(_ptr.targetTouches);

  TouchList get touches() => LevelDom.wrapTouchList(_ptr.touches);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class TransitionEventWrappingImplementation extends EventWrappingImplementation implements TransitionEvent {
  static String _name;

  TransitionEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  static String get _eventName() {
    if (_name != null) return _name;

    try {
      dom.document.createEvent("WebKitTransitionEvent");
      _name = "WebKitTransitionEvent";
    } catch (var e) {
      _name = "TransitionEvent";
    }
    return _name;
  }

  factory TransitionEventWrappingImplementation(String type,
      String propertyName, double elapsedTime, [bool canBubble = true,
      bool cancelable = true]) {
    final e = dom.document.createEvent(_eventName);
    e.initWebKitTransitionEvent(type, canBubble, cancelable, propertyName,
        elapsedTime);
    return LevelDom.wrapTransitionEvent(e);
  }

  num get elapsedTime() => _ptr.elapsedTime;

  String get propertyName() => _ptr.propertyName;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class UIEventWrappingImplementation extends EventWrappingImplementation implements UIEvent {
  UIEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory UIEventWrappingImplementation(String type, Window view, int detail,
      [bool canBubble = true, bool cancelable = true]) {
    final e = dom.document.createEvent("UIEvent");
    e.initUIEvent(type, canBubble, cancelable, LevelDom.unwrap(view), detail);
    return LevelDom.wrapUIEvent(e);
  }

  int get charCode() => _ptr.charCode;

  int get detail() => _ptr.detail;

  int get keyCode() => _ptr.keyCode;

  int get layerX() => _ptr.layerX;

  int get layerY() => _ptr.layerY;

  int get pageX() => _ptr.pageX;

  int get pageY() => _ptr.pageY;

  Window get view() => LevelDom.wrapWindow(_ptr.view);

  int get which() => _ptr.which;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jacobr) add events.
class WebSocketWrappingImplementation extends EventTargetWrappingImplementation implements WebSocket {
  WebSocketWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get URL() { return _ptr.URL; }

  String get binaryType() { return _ptr.binaryType; }

  void set binaryType(String value) { _ptr.binaryType = value; }

  int get bufferedAmount() { return _ptr.bufferedAmount; }

  EventListener get onclose() { return LevelDom.wrapEventListener(_ptr.onclose); }

  void set onclose(EventListener value) { _ptr.onclose = LevelDom.unwrap(value); }

  EventListener get onerror() { return LevelDom.wrapEventListener(_ptr.onerror); }

  void set onerror(EventListener value) { _ptr.onerror = LevelDom.unwrap(value); }

  EventListener get onmessage() { return LevelDom.wrapEventListener(_ptr.onmessage); }

  void set onmessage(EventListener value) { _ptr.onmessage = LevelDom.unwrap(value); }

  EventListener get onopen() { return LevelDom.wrapEventListener(_ptr.onopen); }

  void set onopen(EventListener value) { _ptr.onopen = LevelDom.unwrap(value); }

  String get protocol() { return _ptr.protocol; }

  int get readyState() { return _ptr.readyState; }

  void close() {
    _ptr.close();
    return;
  }

  bool send(String data) {
    return _ptr.send(data);
  }

  String get typeName() { return "WebSocket"; }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class WheelEventWrappingImplementation extends UIEventWrappingImplementation implements WheelEvent {
  WheelEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory WheelEventWrappingImplementation(int deltaX, int deltaY, Window view,
      int screenX, int screenY, int clientX, int clientY, [bool ctrlKey = false,
      bool altKey = false, bool shiftKey = false, bool metaKey = false]) {
    final e = dom.document.createEvent("WheelEvent");
    e.initWebKitWheelEvent(deltaX, deltaY, LevelDom.unwrap(view), screenX, screenY,
        clientX, clientY, ctrlKey, altKey, shiftKey, metaKey);
    return LevelDom.wrapWheelEvent(e);
  }

  bool get altKey() => _ptr.altKey;

  int get clientX() => _ptr.clientX;

  int get clientY() => _ptr.clientY;

  bool get ctrlKey() => _ptr.ctrlKey;

  bool get metaKey() => _ptr.metaKey;

  int get offsetX() => _ptr.offsetX;

  int get offsetY() => _ptr.offsetY;

  int get screenX() => _ptr.screenX;

  int get screenY() => _ptr.screenY;

  bool get shiftKey() => _ptr.shiftKey;

  int get wheelDelta() => _ptr.wheelDelta;

  int get wheelDeltaX() => _ptr.wheelDeltaX;

  int get wheelDeltaY() => _ptr.wheelDeltaY;

  int get x() => _ptr.x;

  int get y() => _ptr.y;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jacobr): define a base class containing the overlap between
// this class and ElementEvents.
class WindowEventsImplementation extends EventsImplementation
      implements WindowEvents {
  WindowEventsImplementation._wrap(_ptr) : super._wrap(_ptr);

  EventListenerList get abort() => _get('abort');
  EventListenerList get beforeUnload() => _get('beforeunload');
  EventListenerList get blur() => _get('blur');
  EventListenerList get canPlay() => _get('canplay');
  EventListenerList get canPlayThrough() => _get('canplaythrough');
  EventListenerList get change() => _get('change');
  EventListenerList get click() => _get('click');
  EventListenerList get contextMenu() => _get('contextmenu');
  EventListenerList get dblClick() => _get('dblclick');
  EventListenerList get deviceMotion() => _get('devicemotion');
  EventListenerList get deviceOrientation() => _get('deviceorientation');
  EventListenerList get drag() => _get('drag');
  EventListenerList get dragEnd() => _get('dragend');
  EventListenerList get dragEnter() => _get('dragenter');
  EventListenerList get dragLeave() => _get('dragleave');
  EventListenerList get dragOver() => _get('dragover');
  EventListenerList get dragStart() => _get('dragstart');
  EventListenerList get drop() => _get('drop');
  EventListenerList get durationChange() => _get('durationchange');
  EventListenerList get emptied() => _get('emptied');
  EventListenerList get ended() => _get('ended');
  EventListenerList get error() => _get('error');
  EventListenerList get focus() => _get('focus');
  EventListenerList get hashChange() => _get('hashchange');
  EventListenerList get input() => _get('input');
  EventListenerList get invalid() => _get('invalid');
  EventListenerList get keyDown() => _get('keydown');
  EventListenerList get keyPress() => _get('keypress');
  EventListenerList get keyUp() => _get('keyup');
  EventListenerList get load() => _get('load');
  EventListenerList get loadedData() => _get('loadeddata');
  EventListenerList get loadedMetaData() => _get('loadedmetadata');
  EventListenerList get loadStart() => _get('loadstart');
  EventListenerList get message() => _get('message');
  EventListenerList get mouseDown() => _get('mousedown');
  EventListenerList get mouseMove() => _get('mousemove');
  EventListenerList get mouseOut() => _get('mouseout');
  EventListenerList get mouseOver() => _get('mouseover');
  EventListenerList get mouseUp() => _get('mouseup');
  EventListenerList get mouseWheel() => _get('mousewheel');
  EventListenerList get offline() => _get('offline');
  EventListenerList get online() => _get('online');
  EventListenerList get pageHide() => _get('pagehide');
  EventListenerList get pageShow() => _get('pageshow');
  EventListenerList get pause() => _get('pause');
  EventListenerList get play() => _get('play');
  EventListenerList get playing() => _get('playing');
  EventListenerList get popState() => _get('popstate');
  EventListenerList get progress() => _get('progress');
  EventListenerList get rateChange() => _get('ratechange');
  EventListenerList get reset() => _get('reset');
  EventListenerList get resize() => _get('resize');
  EventListenerList get scroll() => _get('scroll');
  EventListenerList get search() => _get('search');
  EventListenerList get seeked() => _get('seeked');
  EventListenerList get seeking() => _get('seeking');
  EventListenerList get select() => _get('select');
  EventListenerList get stalled() => _get('stalled');
  EventListenerList get storage() => _get('storage');
  EventListenerList get submit() => _get('submit');
  EventListenerList get suspend() => _get('suspend');
  EventListenerList get timeUpdate() => _get('timeupdate');
  EventListenerList get touchCancel() => _get('touchcancel');
  EventListenerList get touchEnd() => _get('touchend');
  EventListenerList get touchMove() => _get('touchmove');
  EventListenerList get touchStart() => _get('touchstart');
  EventListenerList get unLoad() => _get('unload');
  EventListenerList get volumeChange() => _get('volumechange');
  EventListenerList get waiting() => _get('waiting');
  EventListenerList get animationEnd() => _get('webkitAnimationEnd');
  EventListenerList get animationIteration() => _get('webkitAnimationIteration');
  EventListenerList get animationStart() => _get('webkitAnimationStart');
  EventListenerList get transitionEnd() => _get('webkitTransitionEnd');
  EventListenerList get contentLoaded() => _get('DOMContentLoaded');
}

/** @domName Window */
class WindowWrappingImplementation extends EventTargetWrappingImplementation implements Window {
  WindowWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  DOMApplicationCache get applicationCache() => LevelDom.wrapDOMApplicationCache(_ptr.applicationCache);

  Navigator get clientInformation() => LevelDom.wrapNavigator(_ptr.clientInformation);

  void set clientInformation(Navigator value) { _ptr.clientInformation = LevelDom.unwrap(value); }

  bool get closed() => _ptr.closed;

  Console get console() => LevelDom.wrapConsole(_ptr.console);

  void set console(Console value) { _ptr.console = LevelDom.unwrap(value); }

  Crypto get crypto() => LevelDom.wrapCrypto(_ptr.crypto);

  String get defaultStatus() => _ptr.defaultStatus;

  void set defaultStatus(String value) { _ptr.defaultStatus = value; }

  num get devicePixelRatio() => _ptr.devicePixelRatio;

  void set devicePixelRatio(num value) { _ptr.devicePixelRatio = value; }

  Document get document() => LevelDom.wrapDocument(_ptr.document);

  Event get event() => LevelDom.wrapEvent(_ptr.event);

  void set event(Event value) { _ptr.event = LevelDom.unwrap(value); }

  Element get frameElement() => LevelDom.wrapElement(_ptr.frameElement);

  Window get frames() => LevelDom.wrapWindow(_ptr.frames);

  void set frames(Window value) { _ptr.frames = LevelDom.unwrap(value); }

  History get history() => LevelDom.wrapHistory(_ptr.history);

  void set history(History value) { _ptr.history = LevelDom.unwrap(value); }

  int get innerHeight() => _ptr.innerHeight;

  void set innerHeight(int value) { _ptr.innerHeight = value; }

  int get innerWidth() => _ptr.innerWidth;

  void set innerWidth(int value) { _ptr.innerWidth = value; }

  int get length() => _ptr.length;

  void set length(int value) { _ptr.length = value; }

  Storage get localStorage() => LevelDom.wrapStorage(_ptr.localStorage);

  Location get location() => LevelDom.wrapLocation(_ptr.location);

  void set location(Location value) { _ptr.location = LevelDom.unwrap(value); }

  BarInfo get locationbar() => LevelDom.wrapBarInfo(_ptr.locationbar);

  void set locationbar(BarInfo value) { _ptr.locationbar = LevelDom.unwrap(value); }

  BarInfo get menubar() => LevelDom.wrapBarInfo(_ptr.menubar);

  void set menubar(BarInfo value) { _ptr.menubar = LevelDom.unwrap(value); }

  String get name() => _ptr.name;

  void set name(String value) { _ptr.name = value; }

  Navigator get navigator() => LevelDom.wrapNavigator(_ptr.navigator);

  void set navigator(Navigator value) { _ptr.navigator = LevelDom.unwrap(value); }

  bool get offscreenBuffering() => _ptr.offscreenBuffering;

  void set offscreenBuffering(bool value) { _ptr.offscreenBuffering = value; }

  EventListener get onabort() => LevelDom.wrapEventListener(_ptr.onabort);

  void set onabort(EventListener value) { _ptr.onabort = LevelDom.unwrap(value); }

  EventListener get onbeforeunload() => LevelDom.wrapEventListener(_ptr.onbeforeunload);

  void set onbeforeunload(EventListener value) { _ptr.onbeforeunload = LevelDom.unwrap(value); }

  EventListener get onblur() => LevelDom.wrapEventListener(_ptr.onblur);

  void set onblur(EventListener value) { _ptr.onblur = LevelDom.unwrap(value); }

  EventListener get oncanplay() => LevelDom.wrapEventListener(_ptr.oncanplay);

  void set oncanplay(EventListener value) { _ptr.oncanplay = LevelDom.unwrap(value); }

  EventListener get oncanplaythrough() => LevelDom.wrapEventListener(_ptr.oncanplaythrough);

  void set oncanplaythrough(EventListener value) { _ptr.oncanplaythrough = LevelDom.unwrap(value); }

  EventListener get onchange() => LevelDom.wrapEventListener(_ptr.onchange);

  void set onchange(EventListener value) { _ptr.onchange = LevelDom.unwrap(value); }

  EventListener get onclick() => LevelDom.wrapEventListener(_ptr.onclick);

  void set onclick(EventListener value) { _ptr.onclick = LevelDom.unwrap(value); }

  EventListener get oncontextmenu() => LevelDom.wrapEventListener(_ptr.oncontextmenu);

  void set oncontextmenu(EventListener value) { _ptr.oncontextmenu = LevelDom.unwrap(value); }

  EventListener get ondblclick() => LevelDom.wrapEventListener(_ptr.ondblclick);

  void set ondblclick(EventListener value) { _ptr.ondblclick = LevelDom.unwrap(value); }

  EventListener get ondevicemotion() => LevelDom.wrapEventListener(_ptr.ondevicemotion);

  void set ondevicemotion(EventListener value) { _ptr.ondevicemotion = LevelDom.unwrap(value); }

  EventListener get ondeviceorientation() => LevelDom.wrapEventListener(_ptr.ondeviceorientation);

  void set ondeviceorientation(EventListener value) { _ptr.ondeviceorientation = LevelDom.unwrap(value); }

  EventListener get ondrag() => LevelDom.wrapEventListener(_ptr.ondrag);

  void set ondrag(EventListener value) { _ptr.ondrag = LevelDom.unwrap(value); }

  EventListener get ondragend() => LevelDom.wrapEventListener(_ptr.ondragend);

  void set ondragend(EventListener value) { _ptr.ondragend = LevelDom.unwrap(value); }

  EventListener get ondragenter() => LevelDom.wrapEventListener(_ptr.ondragenter);

  void set ondragenter(EventListener value) { _ptr.ondragenter = LevelDom.unwrap(value); }

  EventListener get ondragleave() => LevelDom.wrapEventListener(_ptr.ondragleave);

  void set ondragleave(EventListener value) { _ptr.ondragleave = LevelDom.unwrap(value); }

  EventListener get ondragover() => LevelDom.wrapEventListener(_ptr.ondragover);

  void set ondragover(EventListener value) { _ptr.ondragover = LevelDom.unwrap(value); }

  EventListener get ondragstart() => LevelDom.wrapEventListener(_ptr.ondragstart);

  void set ondragstart(EventListener value) { _ptr.ondragstart = LevelDom.unwrap(value); }

  EventListener get ondrop() => LevelDom.wrapEventListener(_ptr.ondrop);

  void set ondrop(EventListener value) { _ptr.ondrop = LevelDom.unwrap(value); }

  EventListener get ondurationchange() => LevelDom.wrapEventListener(_ptr.ondurationchange);

  void set ondurationchange(EventListener value) { _ptr.ondurationchange = LevelDom.unwrap(value); }

  EventListener get onemptied() => LevelDom.wrapEventListener(_ptr.onemptied);

  void set onemptied(EventListener value) { _ptr.onemptied = LevelDom.unwrap(value); }

  EventListener get onended() => LevelDom.wrapEventListener(_ptr.onended);

  void set onended(EventListener value) { _ptr.onended = LevelDom.unwrap(value); }

  EventListener get onerror() => LevelDom.wrapEventListener(_ptr.onerror);

  void set onerror(EventListener value) { _ptr.onerror = LevelDom.unwrap(value); }

  EventListener get onfocus() => LevelDom.wrapEventListener(_ptr.onfocus);

  void set onfocus(EventListener value) { _ptr.onfocus = LevelDom.unwrap(value); }

  EventListener get onhashchange() => LevelDom.wrapEventListener(_ptr.onhashchange);

  void set onhashchange(EventListener value) { _ptr.onhashchange = LevelDom.unwrap(value); }

  EventListener get oninput() => LevelDom.wrapEventListener(_ptr.oninput);

  void set oninput(EventListener value) { _ptr.oninput = LevelDom.unwrap(value); }

  EventListener get oninvalid() => LevelDom.wrapEventListener(_ptr.oninvalid);

  void set oninvalid(EventListener value) { _ptr.oninvalid = LevelDom.unwrap(value); }

  EventListener get onkeydown() => LevelDom.wrapEventListener(_ptr.onkeydown);

  void set onkeydown(EventListener value) { _ptr.onkeydown = LevelDom.unwrap(value); }

  EventListener get onkeypress() => LevelDom.wrapEventListener(_ptr.onkeypress);

  void set onkeypress(EventListener value) { _ptr.onkeypress = LevelDom.unwrap(value); }

  EventListener get onkeyup() => LevelDom.wrapEventListener(_ptr.onkeyup);

  void set onkeyup(EventListener value) { _ptr.onkeyup = LevelDom.unwrap(value); }

  EventListener get onload() => LevelDom.wrapEventListener(_ptr.onload);

  void set onload(EventListener value) { _ptr.onload = LevelDom.unwrap(value); }

  EventListener get onloadeddata() => LevelDom.wrapEventListener(_ptr.onloadeddata);

  void set onloadeddata(EventListener value) { _ptr.onloadeddata = LevelDom.unwrap(value); }

  EventListener get onloadedmetadata() => LevelDom.wrapEventListener(_ptr.onloadedmetadata);

  void set onloadedmetadata(EventListener value) { _ptr.onloadedmetadata = LevelDom.unwrap(value); }

  EventListener get onloadstart() => LevelDom.wrapEventListener(_ptr.onloadstart);

  void set onloadstart(EventListener value) { _ptr.onloadstart = LevelDom.unwrap(value); }

  EventListener get onmessage() => LevelDom.wrapEventListener(_ptr.onmessage);

  void set onmessage(EventListener value) { _ptr.onmessage = LevelDom.unwrap(value); }

  EventListener get onmousedown() => LevelDom.wrapEventListener(_ptr.onmousedown);

  void set onmousedown(EventListener value) { _ptr.onmousedown = LevelDom.unwrap(value); }

  EventListener get onmousemove() => LevelDom.wrapEventListener(_ptr.onmousemove);

  void set onmousemove(EventListener value) { _ptr.onmousemove = LevelDom.unwrap(value); }

  EventListener get onmouseout() => LevelDom.wrapEventListener(_ptr.onmouseout);

  void set onmouseout(EventListener value) { _ptr.onmouseout = LevelDom.unwrap(value); }

  EventListener get onmouseover() => LevelDom.wrapEventListener(_ptr.onmouseover);

  void set onmouseover(EventListener value) { _ptr.onmouseover = LevelDom.unwrap(value); }

  EventListener get onmouseup() => LevelDom.wrapEventListener(_ptr.onmouseup);

  void set onmouseup(EventListener value) { _ptr.onmouseup = LevelDom.unwrap(value); }

  EventListener get onmousewheel() => LevelDom.wrapEventListener(_ptr.onmousewheel);

  void set onmousewheel(EventListener value) { _ptr.onmousewheel = LevelDom.unwrap(value); }

  EventListener get onoffline() => LevelDom.wrapEventListener(_ptr.onoffline);

  void set onoffline(EventListener value) { _ptr.onoffline = LevelDom.unwrap(value); }

  EventListener get ononline() => LevelDom.wrapEventListener(_ptr.ononline);

  void set ononline(EventListener value) { _ptr.ononline = LevelDom.unwrap(value); }

  EventListener get onpagehide() => LevelDom.wrapEventListener(_ptr.onpagehide);

  void set onpagehide(EventListener value) { _ptr.onpagehide = LevelDom.unwrap(value); }

  EventListener get onpageshow() => LevelDom.wrapEventListener(_ptr.onpageshow);

  void set onpageshow(EventListener value) { _ptr.onpageshow = LevelDom.unwrap(value); }

  EventListener get onpause() => LevelDom.wrapEventListener(_ptr.onpause);

  void set onpause(EventListener value) { _ptr.onpause = LevelDom.unwrap(value); }

  EventListener get onplay() => LevelDom.wrapEventListener(_ptr.onplay);

  void set onplay(EventListener value) { _ptr.onplay = LevelDom.unwrap(value); }

  EventListener get onplaying() => LevelDom.wrapEventListener(_ptr.onplaying);

  void set onplaying(EventListener value) { _ptr.onplaying = LevelDom.unwrap(value); }

  EventListener get onpopstate() => LevelDom.wrapEventListener(_ptr.onpopstate);

  void set onpopstate(EventListener value) { _ptr.onpopstate = LevelDom.unwrap(value); }

  EventListener get onprogress() => LevelDom.wrapEventListener(_ptr.onprogress);

  void set onprogress(EventListener value) { _ptr.onprogress = LevelDom.unwrap(value); }

  EventListener get onratechange() => LevelDom.wrapEventListener(_ptr.onratechange);

  void set onratechange(EventListener value) { _ptr.onratechange = LevelDom.unwrap(value); }

  EventListener get onreset() => LevelDom.wrapEventListener(_ptr.onreset);

  void set onreset(EventListener value) { _ptr.onreset = LevelDom.unwrap(value); }

  EventListener get onresize() => LevelDom.wrapEventListener(_ptr.onresize);

  void set onresize(EventListener value) { _ptr.onresize = LevelDom.unwrap(value); }

  EventListener get onscroll() => LevelDom.wrapEventListener(_ptr.onscroll);

  void set onscroll(EventListener value) { _ptr.onscroll = LevelDom.unwrap(value); }

  EventListener get onsearch() => LevelDom.wrapEventListener(_ptr.onsearch);

  void set onsearch(EventListener value) { _ptr.onsearch = LevelDom.unwrap(value); }

  EventListener get onseeked() => LevelDom.wrapEventListener(_ptr.onseeked);

  void set onseeked(EventListener value) { _ptr.onseeked = LevelDom.unwrap(value); }

  EventListener get onseeking() => LevelDom.wrapEventListener(_ptr.onseeking);

  void set onseeking(EventListener value) { _ptr.onseeking = LevelDom.unwrap(value); }

  EventListener get onselect() => LevelDom.wrapEventListener(_ptr.onselect);

  void set onselect(EventListener value) { _ptr.onselect = LevelDom.unwrap(value); }

  EventListener get onstalled() => LevelDom.wrapEventListener(_ptr.onstalled);

  void set onstalled(EventListener value) { _ptr.onstalled = LevelDom.unwrap(value); }

  EventListener get onstorage() => LevelDom.wrapEventListener(_ptr.onstorage);

  void set onstorage(EventListener value) { _ptr.onstorage = LevelDom.unwrap(value); }

  EventListener get onsubmit() => LevelDom.wrapEventListener(_ptr.onsubmit);

  void set onsubmit(EventListener value) { _ptr.onsubmit = LevelDom.unwrap(value); }

  EventListener get onsuspend() => LevelDom.wrapEventListener(_ptr.onsuspend);

  void set onsuspend(EventListener value) { _ptr.onsuspend = LevelDom.unwrap(value); }

  EventListener get ontimeupdate() => LevelDom.wrapEventListener(_ptr.ontimeupdate);

  void set ontimeupdate(EventListener value) { _ptr.ontimeupdate = LevelDom.unwrap(value); }

  EventListener get ontouchcancel() => LevelDom.wrapEventListener(_ptr.ontouchcancel);

  void set ontouchcancel(EventListener value) { _ptr.ontouchcancel = LevelDom.unwrap(value); }

  EventListener get ontouchend() => LevelDom.wrapEventListener(_ptr.ontouchend);

  void set ontouchend(EventListener value) { _ptr.ontouchend = LevelDom.unwrap(value); }

  EventListener get ontouchmove() => LevelDom.wrapEventListener(_ptr.ontouchmove);

  void set ontouchmove(EventListener value) { _ptr.ontouchmove = LevelDom.unwrap(value); }

  EventListener get ontouchstart() => LevelDom.wrapEventListener(_ptr.ontouchstart);

  void set ontouchstart(EventListener value) { _ptr.ontouchstart = LevelDom.unwrap(value); }

  EventListener get onunload() => LevelDom.wrapEventListener(_ptr.onunload);

  void set onunload(EventListener value) { _ptr.onunload = LevelDom.unwrap(value); }

  EventListener get onvolumechange() => LevelDom.wrapEventListener(_ptr.onvolumechange);

  void set onvolumechange(EventListener value) { _ptr.onvolumechange = LevelDom.unwrap(value); }

  EventListener get onwaiting() => LevelDom.wrapEventListener(_ptr.onwaiting);

  void set onwaiting(EventListener value) { _ptr.onwaiting = LevelDom.unwrap(value); }

  EventListener get onwebkitanimationend() => LevelDom.wrapEventListener(_ptr.onwebkitanimationend);

  void set onwebkitanimationend(EventListener value) { _ptr.onwebkitanimationend = LevelDom.unwrap(value); }

  EventListener get onwebkitanimationiteration() => LevelDom.wrapEventListener(_ptr.onwebkitanimationiteration);

  void set onwebkitanimationiteration(EventListener value) { _ptr.onwebkitanimationiteration = LevelDom.unwrap(value); }

  EventListener get onwebkitanimationstart() => LevelDom.wrapEventListener(_ptr.onwebkitanimationstart);

  void set onwebkitanimationstart(EventListener value) { _ptr.onwebkitanimationstart = LevelDom.unwrap(value); }

  EventListener get onwebkittransitionend() => LevelDom.wrapEventListener(_ptr.onwebkittransitionend);

  void set onwebkittransitionend(EventListener value) { _ptr.onwebkittransitionend = LevelDom.unwrap(value); }

  Window get opener() => LevelDom.wrapWindow(_ptr.opener);

  void set opener(Window value) { _ptr.opener = LevelDom.unwrap(value); }

  int get outerHeight() => _ptr.outerHeight;

  void set outerHeight(int value) { _ptr.outerHeight = value; }

  int get outerWidth() => _ptr.outerWidth;

  void set outerWidth(int value) { _ptr.outerWidth = value; }

  int get pageXOffset() => _ptr.pageXOffset;

  int get pageYOffset() => _ptr.pageYOffset;

  Window get parent() => LevelDom.wrapWindow(_ptr.parent);

  void set parent(Window value) { _ptr.parent = LevelDom.unwrap(value); }

  BarInfo get personalbar() => LevelDom.wrapBarInfo(_ptr.personalbar);

  void set personalbar(BarInfo value) { _ptr.personalbar = LevelDom.unwrap(value); }

  Screen get screen() => LevelDom.wrapScreen(_ptr.screen);

  void set screen(Screen value) { _ptr.screen = LevelDom.unwrap(value); }

  int get screenLeft() => _ptr.screenLeft;

  void set screenLeft(int value) { _ptr.screenLeft = value; }

  int get screenTop() => _ptr.screenTop;

  void set screenTop(int value) { _ptr.screenTop = value; }

  int get screenX() => _ptr.screenX;

  void set screenX(int value) { _ptr.screenX = value; }

  int get screenY() => _ptr.screenY;

  void set screenY(int value) { _ptr.screenY = value; }

  int get scrollX() => _ptr.scrollX;

  void set scrollX(int value) { _ptr.scrollX = value; }

  int get scrollY() => _ptr.scrollY;

  void set scrollY(int value) { _ptr.scrollY = value; }

  BarInfo get scrollbars() => LevelDom.wrapBarInfo(_ptr.scrollbars);

  void set scrollbars(BarInfo value) { _ptr.scrollbars = LevelDom.unwrap(value); }

  Window get self() => LevelDom.wrapWindow(_ptr.self);

  void set self(Window value) { _ptr.self = LevelDom.unwrap(value); }

  Storage get sessionStorage() => LevelDom.wrapStorage(_ptr.sessionStorage);

  String get status() => _ptr.status;

  void set status(String value) { _ptr.status = value; }

  BarInfo get statusbar() => LevelDom.wrapBarInfo(_ptr.statusbar);

  void set statusbar(BarInfo value) { _ptr.statusbar = LevelDom.unwrap(value); }

  StyleMedia get styleMedia() => LevelDom.wrapStyleMedia(_ptr.styleMedia);

  BarInfo get toolbar() => LevelDom.wrapBarInfo(_ptr.toolbar);

  void set toolbar(BarInfo value) { _ptr.toolbar = LevelDom.unwrap(value); }

  Window get top() => LevelDom.wrapWindow(_ptr.top);

  void set top(Window value) { _ptr.top = LevelDom.unwrap(value); }

  NotificationCenter get webkitNotifications() => LevelDom.wrapNotificationCenter(_ptr.webkitNotifications);

  void alert([String message = null]) {
    if (message === null) {
      _ptr.alert();
    } else {
      _ptr.alert(message);
    }
  }

  String atob([String string = null]) {
    if (string === null) {
      return _ptr.atob();
    } else {
      return _ptr.atob(string);
    }
  }

  void blur() {
    _ptr.blur();
  }

  String btoa([String string = null]) {
    if (string === null) {
      return _ptr.btoa();
    } else {
      return _ptr.btoa(string);
    }
  }

  void captureEvents() {
    _ptr.captureEvents();
  }

  void clearInterval([int handle = null]) {
    if (handle === null) {
      _ptr.clearInterval();
    } else {
      _ptr.clearInterval(handle);
    }
  }

  void clearTimeout([int handle = null]) {
    if (handle === null) {
      _ptr.clearTimeout();
    } else {
      _ptr.clearTimeout(handle);
    }
  }

  void close() {
    _ptr.close();
  }

  bool confirm([String message = null]) {
    if (message === null) {
      return _ptr.confirm();
    } else {
      return _ptr.confirm(message);
    }
  }

  FileReader createFileReader() =>
    LevelDom.wrapFileReader(_ptr.createFileReader());

  CSSMatrix createCSSMatrix([String cssValue = null]) {
    if (cssValue === null) {
      return LevelDom.wrapCSSMatrix(_ptr.createWebKitCSSMatrix());
    } else {
      return LevelDom.wrapCSSMatrix(_ptr.createWebKitCSSMatrix(cssValue));
    }
  }

  bool find([String string = null, bool caseSensitive = null, bool backwards = null, bool wrap = null, bool wholeWord = null, bool searchInFrames = null, bool showDialog = null]) {
    if (string === null) {
      if (caseSensitive === null) {
        if (backwards === null) {
          if (wrap === null) {
            if (wholeWord === null) {
              if (searchInFrames === null) {
                if (showDialog === null) {
                  return _ptr.find();
                }
              }
            }
          }
        }
      }
    } else {
      if (caseSensitive === null) {
        if (backwards === null) {
          if (wrap === null) {
            if (wholeWord === null) {
              if (searchInFrames === null) {
                if (showDialog === null) {
                  return _ptr.find(string);
                }
              }
            }
          }
        }
      } else {
        if (backwards === null) {
          if (wrap === null) {
            if (wholeWord === null) {
              if (searchInFrames === null) {
                if (showDialog === null) {
                  return _ptr.find(string, caseSensitive);
                }
              }
            }
          }
        } else {
          if (wrap === null) {
            if (wholeWord === null) {
              if (searchInFrames === null) {
                if (showDialog === null) {
                  return _ptr.find(string, caseSensitive, backwards);
                }
              }
            }
          } else {
            if (wholeWord === null) {
              if (searchInFrames === null) {
                if (showDialog === null) {
                  return _ptr.find(string, caseSensitive, backwards, wrap);
                }
              }
            } else {
              if (searchInFrames === null) {
                if (showDialog === null) {
                  return _ptr.find(string, caseSensitive, backwards, wrap, wholeWord);
                }
              } else {
                if (showDialog === null) {
                  return _ptr.find(string, caseSensitive, backwards, wrap, wholeWord, searchInFrames);
                } else {
                  return _ptr.find(string, caseSensitive, backwards, wrap, wholeWord, searchInFrames, showDialog);
                }
              }
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void focus() {
    _ptr.focus();
  }

  DOMSelection getSelection() =>
    LevelDom.wrapDOMSelection(_ptr.getSelection());

  MediaQueryList matchMedia(String query) {
    return LevelDom.wrapMediaQueryList(_ptr.matchMedia(query));
  }

  void moveBy(num x, num y) {
    _ptr.moveBy(x, y);
  }

  void moveTo(num x, num y) {
    _ptr.moveTo(x, y);
  }

  Window open(String url, String target, [String features = null]) {
    if (features === null) {
      return LevelDom.wrapWindow(_ptr.open(url, target));
    } else {
      return LevelDom.wrapWindow(_ptr.open(url, target, features));
    }
  }

  // TODO(jacobr): cleanup.
  void postMessage(String message, [var messagePort = null, var targetOrigin = null]) {
    if (targetOrigin === null) {
      if (messagePort === null) {
        _ptr.postMessage(message);
        return;
      } else {
        // messagePort is really the targetOrigin string.
        _ptr.postMessage(message, messagePort);
        return;
      }
    } else {
      _ptr.postMessage(message, LevelDom.unwrap(messagePort), targetOrigin);
      return;
    }
    throw "Incorrect number or type of arguments";
  }

  void print() {
    _ptr.print();
  }

  String prompt([String message = null, String defaultValue = null]) {
    if (message === null) {
      if (defaultValue === null) {
        return _ptr.prompt();
      }
    } else {
      if (defaultValue === null) {
        return _ptr.prompt(message);
      } else {
        return _ptr.prompt(message, defaultValue);
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void releaseEvents() {
    _ptr.releaseEvents();
  }

  void resizeBy(num x, num y) {
    _ptr.resizeBy(x, y);
  }

  void resizeTo(num width, num height) {
    _ptr.resizeTo(width, height);
  }

  void scroll(int x, int y) {
    _ptr.scroll(x, y);
  }

  void scrollBy(int x, int y) {
    _ptr.scrollBy(x, y);
  }

  void scrollTo(int x, int y) {
    _ptr.scrollTo(x, y);
  }

  int setInterval(TimeoutHandler handler, int timeout) =>
    _ptr.setInterval(handler, timeout);

  int setTimeout(TimeoutHandler handler, int timeout) =>
    _ptr.setTimeout(handler, timeout);

  Object showModalDialog(String url, [Object dialogArgs = null, String featureArgs = null]) {
    if (dialogArgs === null) {
      if (featureArgs === null) {
        return _ptr.showModalDialog(url);
      }
    } else {
      if (featureArgs === null) {
        return _ptr.showModalDialog(url, LevelDom.unwrap(dialogArgs));
      } else {
        return _ptr.showModalDialog(url, LevelDom.unwrap(dialogArgs),
                                    featureArgs);
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void stop() {
    _ptr.stop();
  }

  void webkitCancelRequestAnimationFrame(int id) {
    _ptr.webkitCancelRequestAnimationFrame(id);
  }

  Point webkitConvertPointFromNodeToPage([Node node = null, Point p = null]) {
    if (node === null) {
      if (p === null) {
        return LevelDom.wrapPoint(_ptr.webkitConvertPointFromNodeToPage());
      }
    } else {
      if (p === null) {
        return LevelDom.wrapPoint(_ptr.webkitConvertPointFromNodeToPage(LevelDom.unwrap(node)));
      } else {
        return LevelDom.wrapPoint(_ptr.webkitConvertPointFromNodeToPage(LevelDom.unwrap(node), LevelDom.unwrap(p)));
      }
    }
    throw "Incorrect number or type of arguments";
  }

  Point webkitConvertPointFromPageToNode([Node node = null, Point p = null]) {
    if (node === null) {
      if (p === null) {
        return LevelDom.wrapPoint(_ptr.webkitConvertPointFromPageToNode());
      }
    } else {
      if (p === null) {
        return LevelDom.wrapPoint(_ptr.webkitConvertPointFromPageToNode(LevelDom.unwrap(node)));
      } else {
        return LevelDom.wrapPoint(_ptr.webkitConvertPointFromPageToNode(LevelDom.unwrap(node), LevelDom.unwrap(p)));
      }
    }
    throw "Incorrect number or type of arguments";
  }

  int webkitRequestAnimationFrame(RequestAnimationFrameCallback callback, [Element element = null]) {
    return _ptr.webkitRequestAnimationFrame(callback, LevelDom.unwrap(element));
  }

  void requestLayoutFrame(TimeoutHandler callback) {
    _addMeasurementFrameCallback(callback);
  }

  WindowEvents get on() {
    if (_on === null) {
      _on = new WindowEventsImplementation._wrap(_ptr);
    }
    return _on;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class WorkerEventsImplementation extends AbstractWorkerEventsImplementation
    implements WorkerEvents {
  WorkerEventsImplementation._wrap(_ptr) : super._wrap(_ptr);

  EventListenerList get message() => _get('message');
}

class WorkerWrappingImplementation extends EventTargetWrappingImplementation implements Worker {
  WorkerWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void postMessage(String message, [MessagePort messagePort = null]) {
    if (messagePort === null) {
      _ptr.postMessage(message);
      return;
    } else {
      _ptr.postMessage(message, LevelDom.unwrap(messagePort));
      return;
    }
  }

  void terminate() {
    _ptr.terminate();
    return;
  }

  WorkerEvents get on() {
    if (_on === null) {
      _on = new WorkerEventsImplementation._wrap(_ptr);
    }
    return _on;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class XMLHttpRequestProgressEventWrappingImplementation extends ProgressEventWrappingImplementation implements XMLHttpRequestProgressEvent {
  XMLHttpRequestProgressEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory XMLHttpRequestProgressEventWrappingImplementation(String type,
      int loaded, [bool canBubble = true, bool cancelable = true,
      bool lengthComputable = false, int total = 0]) {
    final e = dom.document.createEvent("XMLHttpRequestProgressEvent");
    e.initProgressEvent(type, canBubble, cancelable, lengthComputable, loaded,
        total);
    return LevelDom.wrapProgressEvent(e);
  }

  int get position() => _ptr.position;

  int get totalSize() => _ptr.totalSize;
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class XMLHttpRequestUploadEventsImplementation extends EventsImplementation
    implements XMLHttpRequestUploadEvents {
  XMLHttpRequestUploadEventsImplementation._wrap(_ptr) : super._wrap(_ptr);

  EventListenerList get abort() => _get('abort');
  EventListenerList get error() => _get('error');
  EventListenerList get load() => _get('load');
  EventListenerList get loadStart() => _get('loadstart');
  EventListenerList get progress() => _get('progress');
}

class XMLHttpRequestUploadWrappingImplementation extends EventTargetWrappingImplementation implements XMLHttpRequestUpload {
  XMLHttpRequestUploadWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  XMLHttpRequestUploadEvents get on() {
    if (_on === null) {
      _on = new XMLHttpRequestUploadEventsImplementation._wrap(_ptr);
    }
    return _on;
  }
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class XMLHttpRequestEventsImplementation extends EventsImplementation
    implements XMLHttpRequestEvents {
  XMLHttpRequestEventsImplementation._wrap(_ptr) : super._wrap(_ptr);

  EventListenerList get abort() => _get('abort');
  EventListenerList get error() => _get('error');
  EventListenerList get load() => _get('load');
  EventListenerList get loadStart() => _get('loadstart');
  EventListenerList get progress() => _get('progress');
  EventListenerList get readyStateChange() => _get('readystatechange');
}

class XMLHttpRequestWrappingImplementation extends EventTargetWrappingImplementation implements XMLHttpRequest {
  XMLHttpRequestWrappingImplementation._wrap(
      dom.XMLHttpRequest ptr) : super._wrap(ptr);

  factory XMLHttpRequestWrappingImplementation() {
    return new XMLHttpRequestWrappingImplementation._wrap(
        new dom.XMLHttpRequest());
  }

  factory XMLHttpRequestWrappingImplementation.getTEMPNAME(String url,
      onSuccess(XMLHttpRequest request)) {
    final request = new XMLHttpRequest();
    request.open('GET', url, true);

    // TODO(terry): Validate after client login added if necessary to forward
    //              cookies to server.
    request.withCredentials = true;

    // Status 0 is for local XHR request.
    request.on.readyStateChange.add((e) {
      if (request.readyState == XMLHttpRequest.DONE &&
          (request.status == 200 || request.status == 0)) {
        onSuccess(request);
      }
    });

    request.send();

    return request;
  }

  int get readyState() => _ptr.readyState;

  String get responseText() => _ptr.responseText;

  String get responseType() => _ptr.responseType;

  void set responseType(String value) { _ptr.responseType = value; }

  Document get responseXML() => LevelDom.wrapDocument(_ptr.responseXML);

  int get status() => _ptr.status;

  String get statusText() => _ptr.statusText;

  XMLHttpRequestUpload get upload() => LevelDom.wrapXMLHttpRequestUpload(_ptr.upload);

  bool get withCredentials() => _ptr.withCredentials;

  void set withCredentials(bool value) { _ptr.withCredentials = value; }

  void abort() {
    _ptr.abort();
    return;
  }

  String getAllResponseHeaders() {
    return _ptr.getAllResponseHeaders();
  }

  String getResponseHeader(String header) {
    return _ptr.getResponseHeader(header);
  }

  void open(String method, String url, bool async, [String user = null, String password = null]) {
    if (user === null) {
      if (password === null) {
        _ptr.open(method, url, async);
        return;
      }
    } else {
      if (password === null) {
        _ptr.open(method, url, async, user);
        return;
      } else {
        _ptr.open(method, url, async, user, password);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void overrideMimeType(String mime) {
    _ptr.overrideMimeType(mime);
  }

  void send([var data = null]) {
    if (data === null) {
      _ptr.send();
      return;
    } else {
      if (data is Document) {
        _ptr.send(LevelDom.unwrapMaybePrimitive(data));
        return;
      } else {
        if (data is String) {
          _ptr.send(LevelDom.unwrapMaybePrimitive(data));
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void setRequestHeader(String header, String value) {
    _ptr.setRequestHeader(header, value);
  }

  XMLHttpRequestEvents get on() {
    if (_on === null) {
      _on = new XMLHttpRequestEventsImplementation._wrap(_ptr);
    }
    return _on;
  }
}
