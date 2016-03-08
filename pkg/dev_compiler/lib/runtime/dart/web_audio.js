dart_library.library('dart/web_audio', null, /* Imports */[
  'dart/_runtime',
  'dart/core',
  'dart/html',
  'dart/_metadata',
  'dart/_js_helper',
  'dart/typed_data',
  'dart/_interceptors',
  'dart/async'
], /* Lazy imports */[
], function(exports, dart, core, html, _metadata, _js_helper, typed_data, _interceptors, async) {
  'use strict';
  let dartx = dart.dartx;
  const _connect = Symbol('_connect');
  dart.defineExtensionNames([
    'disconnect',
    'connectNode',
    'connectParam',
    'channelCount',
    'channelCountMode',
    'channelInterpretation',
    'context',
    'numberOfInputs',
    'numberOfOutputs'
  ]);
  class AudioNode extends html.EventTarget {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.channelCount]() {
      return this.channelCount;
    }
    set [dartx.channelCount](value) {
      this.channelCount = value;
    }
    get [dartx.channelCountMode]() {
      return this.channelCountMode;
    }
    set [dartx.channelCountMode](value) {
      this.channelCountMode = value;
    }
    get [dartx.channelInterpretation]() {
      return this.channelInterpretation;
    }
    set [dartx.channelInterpretation](value) {
      this.channelInterpretation = value;
    }
    get [dartx.context]() {
      return this.context;
    }
    get [dartx.numberOfInputs]() {
      return this.numberOfInputs;
    }
    get [dartx.numberOfOutputs]() {
      return this.numberOfOutputs;
    }
    [_connect](destination, output, input) {
      return this.connect(destination, output, input);
    }
    [dartx.disconnect](output) {
      return this.disconnect(output);
    }
    [dartx.connectNode](destination, output, input) {
      if (output === void 0) output = 0;
      if (input === void 0) input = 0;
      return this[_connect](destination, output, input);
    }
    [dartx.connectParam](destination, output) {
      if (output === void 0) output = 0;
      return this[_connect](destination, output);
    }
  }
  dart.setSignature(AudioNode, {
    constructors: () => ({_: [AudioNode, []]}),
    methods: () => ({
      [_connect]: [dart.void, [dart.dynamic, core.int], [core.int]],
      [dartx.disconnect]: [dart.void, [core.int]],
      [dartx.connectNode]: [dart.void, [AudioNode], [core.int, core.int]],
      [dartx.connectParam]: [dart.void, [AudioParam], [core.int]]
    })
  });
  AudioNode[dart.metadata] = () => [dart.const(new _metadata.DomName('AudioNode')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("AudioNode"))];
  dart.registerExtension(dart.global.AudioNode, AudioNode);
  dart.defineExtensionNames([
    'getByteFrequencyData',
    'getByteTimeDomainData',
    'getFloatFrequencyData',
    'getFloatTimeDomainData',
    'fftSize',
    'frequencyBinCount',
    'maxDecibels',
    'minDecibels',
    'smoothingTimeConstant'
  ]);
  class AnalyserNode extends AudioNode {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.fftSize]() {
      return this.fftSize;
    }
    set [dartx.fftSize](value) {
      this.fftSize = value;
    }
    get [dartx.frequencyBinCount]() {
      return this.frequencyBinCount;
    }
    get [dartx.maxDecibels]() {
      return this.maxDecibels;
    }
    set [dartx.maxDecibels](value) {
      this.maxDecibels = value;
    }
    get [dartx.minDecibels]() {
      return this.minDecibels;
    }
    set [dartx.minDecibels](value) {
      this.minDecibels = value;
    }
    get [dartx.smoothingTimeConstant]() {
      return this.smoothingTimeConstant;
    }
    set [dartx.smoothingTimeConstant](value) {
      this.smoothingTimeConstant = value;
    }
    [dartx.getByteFrequencyData](array) {
      return this.getByteFrequencyData(array);
    }
    [dartx.getByteTimeDomainData](array) {
      return this.getByteTimeDomainData(array);
    }
    [dartx.getFloatFrequencyData](array) {
      return this.getFloatFrequencyData(array);
    }
    [dartx.getFloatTimeDomainData](array) {
      return this.getFloatTimeDomainData(array);
    }
  }
  dart.setSignature(AnalyserNode, {
    constructors: () => ({_: [AnalyserNode, []]}),
    methods: () => ({
      [dartx.getByteFrequencyData]: [dart.void, [typed_data.Uint8List]],
      [dartx.getByteTimeDomainData]: [dart.void, [typed_data.Uint8List]],
      [dartx.getFloatFrequencyData]: [dart.void, [typed_data.Float32List]],
      [dartx.getFloatTimeDomainData]: [dart.void, [typed_data.Float32List]]
    })
  });
  AnalyserNode[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('AnalyserNode')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("AnalyserNode,RealtimeAnalyserNode"))];
  dart.registerExtension(dart.global.AnalyserNode, AnalyserNode);
  dart.defineExtensionNames([
    'getChannelData',
    'duration',
    'length',
    'numberOfChannels',
    'sampleRate'
  ]);
  class AudioBuffer extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.duration]() {
      return this.duration;
    }
    get [dartx.length]() {
      return this.length;
    }
    get [dartx.numberOfChannels]() {
      return this.numberOfChannels;
    }
    get [dartx.sampleRate]() {
      return this.sampleRate;
    }
    [dartx.getChannelData](channelIndex) {
      return this.getChannelData(channelIndex);
    }
  }
  dart.setSignature(AudioBuffer, {
    constructors: () => ({_: [AudioBuffer, []]}),
    methods: () => ({[dartx.getChannelData]: [typed_data.Float32List, [core.int]]})
  });
  AudioBuffer[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('AudioBuffer')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("AudioBuffer"))];
  dart.registerExtension(dart.global.AudioBuffer, AudioBuffer);
  const AudioBufferCallback = dart.typedef('AudioBufferCallback', () => dart.functionType(dart.void, [AudioBuffer]));
  class AudioSourceNode extends AudioNode {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
  }
  dart.setSignature(AudioSourceNode, {
    constructors: () => ({_: [AudioSourceNode, []]})
  });
  AudioSourceNode[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('AudioSourceNode')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("AudioSourceNode"))];
  dart.registerExtension(dart.global.AudioSourceNode, AudioSourceNode);
  dart.defineExtensionNames([
    'start',
    'stop',
    'onEnded',
    'buffer',
    'loop',
    'loopEnd',
    'loopStart',
    'playbackRate'
  ]);
  class AudioBufferSourceNode extends AudioSourceNode {
    [dartx.start](when, grainOffset, grainDuration) {
      if (grainOffset === void 0) grainOffset = null;
      if (grainDuration === void 0) grainDuration = null;
      if (!!this.start) {
        if (grainDuration != null) {
          this.start(when, grainOffset, grainDuration);
        } else if (grainOffset != null) {
          this.start(when, grainOffset);
        } else {
          this.start(when);
        }
      } else {
        if (grainDuration != null) {
          this.noteOn(when, grainOffset, grainDuration);
        } else if (grainOffset != null) {
          this.noteOn(when, grainOffset);
        } else {
          this.noteOn(when);
        }
      }
    }
    [dartx.stop](when) {
      if (!!this.stop) {
        this.stop(when);
      } else {
        this.noteOff(when);
      }
    }
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.buffer]() {
      return this.buffer;
    }
    set [dartx.buffer](value) {
      this.buffer = value;
    }
    get [dartx.loop]() {
      return this.loop;
    }
    set [dartx.loop](value) {
      this.loop = value;
    }
    get [dartx.loopEnd]() {
      return this.loopEnd;
    }
    set [dartx.loopEnd](value) {
      this.loopEnd = value;
    }
    get [dartx.loopStart]() {
      return this.loopStart;
    }
    set [dartx.loopStart](value) {
      this.loopStart = value;
    }
    get [dartx.playbackRate]() {
      return this.playbackRate;
    }
    get [dartx.onEnded]() {
      return AudioBufferSourceNode.endedEvent.forTarget(this);
    }
  }
  dart.setSignature(AudioBufferSourceNode, {
    constructors: () => ({_: [AudioBufferSourceNode, []]}),
    methods: () => ({
      [dartx.start]: [dart.void, [core.num], [core.num, core.num]],
      [dartx.stop]: [dart.void, [core.num]]
    })
  });
  AudioBufferSourceNode[dart.metadata] = () => [dart.const(new _metadata.DomName('AudioBufferSourceNode')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("AudioBufferSourceNode"))];
  AudioBufferSourceNode.endedEvent = dart.const(new (html.EventStreamProvider$(html.Event))('ended'));
  dart.registerExtension(dart.global.AudioBufferSourceNode, AudioBufferSourceNode);
  const _decodeAudioData = Symbol('_decodeAudioData');
  dart.defineExtensionNames([
    'createAnalyser',
    'createBiquadFilter',
    'createBuffer',
    'createBufferSource',
    'createChannelMerger',
    'createChannelSplitter',
    'createConvolver',
    'createDelay',
    'createDynamicsCompressor',
    'createMediaElementSource',
    'createMediaStreamDestination',
    'createMediaStreamSource',
    'createOscillator',
    'createPanner',
    'createPeriodicWave',
    'createWaveShaper',
    'startRendering',
    'onComplete',
    'createGain',
    'createScriptProcessor',
    'decodeAudioData',
    'currentTime',
    'destination',
    'listener',
    'sampleRate'
  ]);
  class AudioContext extends html.EventTarget {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static get supported() {
      return !!(window.AudioContext || window.webkitAudioContext);
    }
    get [dartx.currentTime]() {
      return this.currentTime;
    }
    get [dartx.destination]() {
      return this.destination;
    }
    get [dartx.listener]() {
      return this.listener;
    }
    get [dartx.sampleRate]() {
      return this.sampleRate;
    }
    [dartx.createAnalyser]() {
      return this.createAnalyser();
    }
    [dartx.createBiquadFilter]() {
      return this.createBiquadFilter();
    }
    [dartx.createBuffer](numberOfChannels, numberOfFrames, sampleRate) {
      return this.createBuffer(numberOfChannels, numberOfFrames, sampleRate);
    }
    [dartx.createBufferSource]() {
      return this.createBufferSource();
    }
    [dartx.createChannelMerger](numberOfInputs) {
      return this.createChannelMerger(numberOfInputs);
    }
    [dartx.createChannelSplitter](numberOfOutputs) {
      return this.createChannelSplitter(numberOfOutputs);
    }
    [dartx.createConvolver]() {
      return this.createConvolver();
    }
    [dartx.createDelay](maxDelayTime) {
      return this.createDelay(maxDelayTime);
    }
    [dartx.createDynamicsCompressor]() {
      return this.createDynamicsCompressor();
    }
    [dartx.createMediaElementSource](mediaElement) {
      return this.createMediaElementSource(mediaElement);
    }
    [dartx.createMediaStreamDestination]() {
      return this.createMediaStreamDestination();
    }
    [dartx.createMediaStreamSource](mediaStream) {
      return this.createMediaStreamSource(mediaStream);
    }
    [dartx.createOscillator]() {
      return this.createOscillator();
    }
    [dartx.createPanner]() {
      return this.createPanner();
    }
    [dartx.createPeriodicWave](real, imag) {
      return this.createPeriodicWave(real, imag);
    }
    [dartx.createWaveShaper]() {
      return this.createWaveShaper();
    }
    [_decodeAudioData](audioData, successCallback, errorCallback) {
      return this.decodeAudioData(audioData, successCallback, errorCallback);
    }
    [dartx.startRendering]() {
      return this.startRendering();
    }
    get [dartx.onComplete]() {
      return AudioContext.completeEvent.forTarget(this);
    }
    static new() {
      return dart.as(new (window.AudioContext || window.webkitAudioContext)(), AudioContext);
    }
    [dartx.createGain]() {
      if (this.createGain !== undefined) {
        return dart.as(this.createGain(), GainNode);
      } else {
        return dart.as(this.createGainNode(), GainNode);
      }
    }
    [dartx.createScriptProcessor](bufferSize, numberOfInputChannels, numberOfOutputChannels) {
      if (numberOfInputChannels === void 0) numberOfInputChannels = null;
      if (numberOfOutputChannels === void 0) numberOfOutputChannels = null;
      let func = this.createScriptProcessor || this.createJavaScriptNode;
      if (numberOfOutputChannels != null) {
        return dart.as(func.call(this, bufferSize, numberOfInputChannels, numberOfOutputChannels), ScriptProcessorNode);
      } else if (numberOfInputChannels != null) {
        return dart.as(func.call(this, bufferSize, numberOfInputChannels), ScriptProcessorNode);
      } else {
        return dart.as(func.call(this, bufferSize), ScriptProcessorNode);
      }
    }
    [dartx.decodeAudioData](audioData) {
      let completer = async.Completer$(AudioBuffer).new();
      this[_decodeAudioData](audioData, dart.fn(value => {
        completer.complete(value);
      }, dart.void, [AudioBuffer]), dart.fn(error => {
        if (error == null) {
          completer.completeError('');
        } else {
          completer.completeError(error);
        }
      }, dart.void, [AudioBuffer]));
      return completer.future;
    }
  }
  dart.setSignature(AudioContext, {
    constructors: () => ({
      _: [AudioContext, []],
      new: [AudioContext, []]
    }),
    methods: () => ({
      [dartx.createAnalyser]: [AnalyserNode, []],
      [dartx.createBiquadFilter]: [BiquadFilterNode, []],
      [dartx.createBuffer]: [AudioBuffer, [core.int, core.int, core.num]],
      [dartx.createBufferSource]: [AudioBufferSourceNode, []],
      [dartx.createChannelMerger]: [ChannelMergerNode, [], [core.int]],
      [dartx.createChannelSplitter]: [ChannelSplitterNode, [], [core.int]],
      [dartx.createConvolver]: [ConvolverNode, []],
      [dartx.createDelay]: [DelayNode, [], [core.num]],
      [dartx.createDynamicsCompressor]: [DynamicsCompressorNode, []],
      [dartx.createMediaElementSource]: [MediaElementAudioSourceNode, [html.MediaElement]],
      [dartx.createMediaStreamDestination]: [MediaStreamAudioDestinationNode, []],
      [dartx.createMediaStreamSource]: [MediaStreamAudioSourceNode, [html.MediaStream]],
      [dartx.createOscillator]: [OscillatorNode, []],
      [dartx.createPanner]: [PannerNode, []],
      [dartx.createPeriodicWave]: [PeriodicWave, [typed_data.Float32List, typed_data.Float32List]],
      [dartx.createWaveShaper]: [WaveShaperNode, []],
      [_decodeAudioData]: [dart.void, [typed_data.ByteBuffer, AudioBufferCallback], [AudioBufferCallback]],
      [dartx.startRendering]: [dart.void, []],
      [dartx.createGain]: [GainNode, []],
      [dartx.createScriptProcessor]: [ScriptProcessorNode, [core.int], [core.int, core.int]],
      [dartx.decodeAudioData]: [async.Future$(AudioBuffer), [typed_data.ByteBuffer]]
    })
  });
  AudioContext[dart.metadata] = () => [dart.const(new _metadata.DomName('AudioContext')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX)), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("AudioContext,webkitAudioContext"))];
  AudioContext.completeEvent = dart.const(new (html.EventStreamProvider$(html.Event))('complete'));
  dart.registerExtension(dart.global.AudioContext, AudioContext);
  dart.defineExtensionNames([
    'maxChannelCount'
  ]);
  class AudioDestinationNode extends AudioNode {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.maxChannelCount]() {
      return this.maxChannelCount;
    }
  }
  dart.setSignature(AudioDestinationNode, {
    constructors: () => ({_: [AudioDestinationNode, []]})
  });
  AudioDestinationNode[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('AudioDestinationNode')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("AudioDestinationNode"))];
  dart.registerExtension(dart.global.AudioDestinationNode, AudioDestinationNode);
  dart.defineExtensionNames([
    'setOrientation',
    'setPosition',
    'setVelocity',
    'dopplerFactor',
    'speedOfSound'
  ]);
  class AudioListener extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.dopplerFactor]() {
      return this.dopplerFactor;
    }
    set [dartx.dopplerFactor](value) {
      this.dopplerFactor = value;
    }
    get [dartx.speedOfSound]() {
      return this.speedOfSound;
    }
    set [dartx.speedOfSound](value) {
      this.speedOfSound = value;
    }
    [dartx.setOrientation](x, y, z, xUp, yUp, zUp) {
      return this.setOrientation(x, y, z, xUp, yUp, zUp);
    }
    [dartx.setPosition](x, y, z) {
      return this.setPosition(x, y, z);
    }
    [dartx.setVelocity](x, y, z) {
      return this.setVelocity(x, y, z);
    }
  }
  dart.setSignature(AudioListener, {
    constructors: () => ({_: [AudioListener, []]}),
    methods: () => ({
      [dartx.setOrientation]: [dart.void, [core.num, core.num, core.num, core.num, core.num, core.num]],
      [dartx.setPosition]: [dart.void, [core.num, core.num, core.num]],
      [dartx.setVelocity]: [dart.void, [core.num, core.num, core.num]]
    })
  });
  AudioListener[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('AudioListener')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("AudioListener"))];
  dart.registerExtension(dart.global.AudioListener, AudioListener);
  dart.defineExtensionNames([
    'cancelScheduledValues',
    'exponentialRampToValueAtTime',
    'linearRampToValueAtTime',
    'setTargetAtTime',
    'setValueAtTime',
    'setValueCurveAtTime',
    'defaultValue',
    'value'
  ]);
  class AudioParam extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.defaultValue]() {
      return this.defaultValue;
    }
    get [dartx.value]() {
      return this.value;
    }
    set [dartx.value](value) {
      this.value = value;
    }
    [dartx.cancelScheduledValues](startTime) {
      return this.cancelScheduledValues(startTime);
    }
    [dartx.exponentialRampToValueAtTime](value, time) {
      return this.exponentialRampToValueAtTime(value, time);
    }
    [dartx.linearRampToValueAtTime](value, time) {
      return this.linearRampToValueAtTime(value, time);
    }
    [dartx.setTargetAtTime](target, time, timeConstant) {
      return this.setTargetAtTime(target, time, timeConstant);
    }
    [dartx.setValueAtTime](value, time) {
      return this.setValueAtTime(value, time);
    }
    [dartx.setValueCurveAtTime](values, time, duration) {
      return this.setValueCurveAtTime(values, time, duration);
    }
  }
  dart.setSignature(AudioParam, {
    constructors: () => ({_: [AudioParam, []]}),
    methods: () => ({
      [dartx.cancelScheduledValues]: [dart.void, [core.num]],
      [dartx.exponentialRampToValueAtTime]: [dart.void, [core.num, core.num]],
      [dartx.linearRampToValueAtTime]: [dart.void, [core.num, core.num]],
      [dartx.setTargetAtTime]: [dart.void, [core.num, core.num, core.num]],
      [dartx.setValueAtTime]: [dart.void, [core.num, core.num]],
      [dartx.setValueCurveAtTime]: [dart.void, [typed_data.Float32List, core.num, core.num]]
    })
  });
  AudioParam[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('AudioParam')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("AudioParam"))];
  dart.registerExtension(dart.global.AudioParam, AudioParam);
  dart.defineExtensionNames([
    'inputBuffer',
    'outputBuffer',
    'playbackTime'
  ]);
  class AudioProcessingEvent extends html.Event {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.inputBuffer]() {
      return this.inputBuffer;
    }
    get [dartx.outputBuffer]() {
      return this.outputBuffer;
    }
    get [dartx.playbackTime]() {
      return this.playbackTime;
    }
  }
  dart.setSignature(AudioProcessingEvent, {
    constructors: () => ({_: [AudioProcessingEvent, []]})
  });
  AudioProcessingEvent[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('AudioProcessingEvent')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("AudioProcessingEvent"))];
  dart.registerExtension(dart.global.AudioProcessingEvent, AudioProcessingEvent);
  dart.defineExtensionNames([
    'getFrequencyResponse',
    'Q',
    'detune',
    'frequency',
    'gain',
    'type'
  ]);
  class BiquadFilterNode extends AudioNode {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.Q]() {
      return this.Q;
    }
    get [dartx.detune]() {
      return this.detune;
    }
    get [dartx.frequency]() {
      return this.frequency;
    }
    get [dartx.gain]() {
      return this.gain;
    }
    get [dartx.type]() {
      return this.type;
    }
    set [dartx.type](value) {
      this.type = value;
    }
    [dartx.getFrequencyResponse](frequencyHz, magResponse, phaseResponse) {
      return this.getFrequencyResponse(frequencyHz, magResponse, phaseResponse);
    }
  }
  dart.setSignature(BiquadFilterNode, {
    constructors: () => ({_: [BiquadFilterNode, []]}),
    methods: () => ({[dartx.getFrequencyResponse]: [dart.void, [typed_data.Float32List, typed_data.Float32List, typed_data.Float32List]]})
  });
  BiquadFilterNode[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('BiquadFilterNode')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("BiquadFilterNode"))];
  dart.registerExtension(dart.global.BiquadFilterNode, BiquadFilterNode);
  class ChannelMergerNode extends AudioNode {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
  }
  dart.setSignature(ChannelMergerNode, {
    constructors: () => ({_: [ChannelMergerNode, []]})
  });
  ChannelMergerNode[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('ChannelMergerNode')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("ChannelMergerNode,AudioChannelMerger"))];
  dart.registerExtension(dart.global.ChannelMergerNode, ChannelMergerNode);
  class ChannelSplitterNode extends AudioNode {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
  }
  dart.setSignature(ChannelSplitterNode, {
    constructors: () => ({_: [ChannelSplitterNode, []]})
  });
  ChannelSplitterNode[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('ChannelSplitterNode')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("ChannelSplitterNode,AudioChannelSplitter"))];
  dart.registerExtension(dart.global.ChannelSplitterNode, ChannelSplitterNode);
  dart.defineExtensionNames([
    'buffer',
    'normalize'
  ]);
  class ConvolverNode extends AudioNode {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.buffer]() {
      return this.buffer;
    }
    set [dartx.buffer](value) {
      this.buffer = value;
    }
    get [dartx.normalize]() {
      return this.normalize;
    }
    set [dartx.normalize](value) {
      this.normalize = value;
    }
  }
  dart.setSignature(ConvolverNode, {
    constructors: () => ({_: [ConvolverNode, []]})
  });
  ConvolverNode[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('ConvolverNode')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("ConvolverNode"))];
  dart.registerExtension(dart.global.ConvolverNode, ConvolverNode);
  dart.defineExtensionNames([
    'delayTime'
  ]);
  class DelayNode extends AudioNode {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.delayTime]() {
      return this.delayTime;
    }
  }
  dart.setSignature(DelayNode, {
    constructors: () => ({_: [DelayNode, []]})
  });
  DelayNode[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('DelayNode')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("DelayNode"))];
  dart.registerExtension(dart.global.DelayNode, DelayNode);
  dart.defineExtensionNames([
    'attack',
    'knee',
    'ratio',
    'reduction',
    'release',
    'threshold'
  ]);
  class DynamicsCompressorNode extends AudioNode {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.attack]() {
      return this.attack;
    }
    get [dartx.knee]() {
      return this.knee;
    }
    get [dartx.ratio]() {
      return this.ratio;
    }
    get [dartx.reduction]() {
      return this.reduction;
    }
    get [dartx.release]() {
      return this.release;
    }
    get [dartx.threshold]() {
      return this.threshold;
    }
  }
  dart.setSignature(DynamicsCompressorNode, {
    constructors: () => ({_: [DynamicsCompressorNode, []]})
  });
  DynamicsCompressorNode[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('DynamicsCompressorNode')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("DynamicsCompressorNode"))];
  dart.registerExtension(dart.global.DynamicsCompressorNode, DynamicsCompressorNode);
  dart.defineExtensionNames([
    'gain'
  ]);
  class GainNode extends AudioNode {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.gain]() {
      return this.gain;
    }
  }
  dart.setSignature(GainNode, {
    constructors: () => ({_: [GainNode, []]})
  });
  GainNode[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('GainNode')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("GainNode,AudioGainNode"))];
  dart.registerExtension(dart.global.GainNode, GainNode);
  dart.defineExtensionNames([
    'mediaElement'
  ]);
  class MediaElementAudioSourceNode extends AudioSourceNode {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.mediaElement]() {
      return this.mediaElement;
    }
  }
  dart.setSignature(MediaElementAudioSourceNode, {
    constructors: () => ({_: [MediaElementAudioSourceNode, []]})
  });
  MediaElementAudioSourceNode[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('MediaElementAudioSourceNode')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("MediaElementAudioSourceNode"))];
  dart.registerExtension(dart.global.MediaElementAudioSourceNode, MediaElementAudioSourceNode);
  dart.defineExtensionNames([
    'stream'
  ]);
  class MediaStreamAudioDestinationNode extends AudioNode {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.stream]() {
      return this.stream;
    }
  }
  dart.setSignature(MediaStreamAudioDestinationNode, {
    constructors: () => ({_: [MediaStreamAudioDestinationNode, []]})
  });
  MediaStreamAudioDestinationNode[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('MediaStreamAudioDestinationNode')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("MediaStreamAudioDestinationNode"))];
  dart.registerExtension(dart.global.MediaStreamAudioDestinationNode, MediaStreamAudioDestinationNode);
  dart.defineExtensionNames([
    'mediaStream'
  ]);
  class MediaStreamAudioSourceNode extends AudioSourceNode {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.mediaStream]() {
      return this.mediaStream;
    }
  }
  dart.setSignature(MediaStreamAudioSourceNode, {
    constructors: () => ({_: [MediaStreamAudioSourceNode, []]})
  });
  MediaStreamAudioSourceNode[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('MediaStreamAudioSourceNode')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("MediaStreamAudioSourceNode"))];
  dart.registerExtension(dart.global.MediaStreamAudioSourceNode, MediaStreamAudioSourceNode);
  dart.defineExtensionNames([
    'renderedBuffer'
  ]);
  class OfflineAudioCompletionEvent extends html.Event {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.renderedBuffer]() {
      return this.renderedBuffer;
    }
  }
  dart.setSignature(OfflineAudioCompletionEvent, {
    constructors: () => ({_: [OfflineAudioCompletionEvent, []]})
  });
  OfflineAudioCompletionEvent[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('OfflineAudioCompletionEvent')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("OfflineAudioCompletionEvent"))];
  dart.registerExtension(dart.global.OfflineAudioCompletionEvent, OfflineAudioCompletionEvent);
  class OfflineAudioContext extends AudioContext {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static new(numberOfChannels, numberOfFrames, sampleRate) {
      return OfflineAudioContext._create_1(numberOfChannels, numberOfFrames, sampleRate);
    }
    static _create_1(numberOfChannels, numberOfFrames, sampleRate) {
      return dart.as(new OfflineAudioContext(numberOfChannels, numberOfFrames, sampleRate), OfflineAudioContext);
    }
  }
  dart.setSignature(OfflineAudioContext, {
    constructors: () => ({
      _: [OfflineAudioContext, []],
      new: [OfflineAudioContext, [core.int, core.int, core.num]]
    }),
    statics: () => ({_create_1: [OfflineAudioContext, [dart.dynamic, dart.dynamic, dart.dynamic]]}),
    names: ['_create_1']
  });
  OfflineAudioContext[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('OfflineAudioContext')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("OfflineAudioContext"))];
  dart.registerExtension(dart.global.OfflineAudioContext, OfflineAudioContext);
  dart.defineExtensionNames([
    'noteOff',
    'noteOn',
    'setPeriodicWave',
    'start',
    'stop',
    'onEnded',
    'detune',
    'frequency',
    'type'
  ]);
  class OscillatorNode extends AudioSourceNode {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.detune]() {
      return this.detune;
    }
    get [dartx.frequency]() {
      return this.frequency;
    }
    get [dartx.type]() {
      return this.type;
    }
    set [dartx.type](value) {
      this.type = value;
    }
    [dartx.noteOff](when) {
      return this.noteOff(when);
    }
    [dartx.noteOn](when) {
      return this.noteOn(when);
    }
    [dartx.setPeriodicWave](periodicWave) {
      return this.setPeriodicWave(periodicWave);
    }
    [dartx.start](when) {
      return this.start(when);
    }
    [dartx.stop](when) {
      return this.stop(when);
    }
    get [dartx.onEnded]() {
      return OscillatorNode.endedEvent.forTarget(this);
    }
  }
  dart.setSignature(OscillatorNode, {
    constructors: () => ({_: [OscillatorNode, []]}),
    methods: () => ({
      [dartx.noteOff]: [dart.void, [core.num]],
      [dartx.noteOn]: [dart.void, [core.num]],
      [dartx.setPeriodicWave]: [dart.void, [PeriodicWave]],
      [dartx.start]: [dart.void, [], [core.num]],
      [dartx.stop]: [dart.void, [], [core.num]]
    })
  });
  OscillatorNode[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('OscillatorNode')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("OscillatorNode,Oscillator"))];
  OscillatorNode.endedEvent = dart.const(new (html.EventStreamProvider$(html.Event))('ended'));
  dart.registerExtension(dart.global.OscillatorNode, OscillatorNode);
  dart.defineExtensionNames([
    'setOrientation',
    'setPosition',
    'setVelocity',
    'coneInnerAngle',
    'coneOuterAngle',
    'coneOuterGain',
    'distanceModel',
    'maxDistance',
    'panningModel',
    'refDistance',
    'rolloffFactor'
  ]);
  class PannerNode extends AudioNode {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.coneInnerAngle]() {
      return this.coneInnerAngle;
    }
    set [dartx.coneInnerAngle](value) {
      this.coneInnerAngle = value;
    }
    get [dartx.coneOuterAngle]() {
      return this.coneOuterAngle;
    }
    set [dartx.coneOuterAngle](value) {
      this.coneOuterAngle = value;
    }
    get [dartx.coneOuterGain]() {
      return this.coneOuterGain;
    }
    set [dartx.coneOuterGain](value) {
      this.coneOuterGain = value;
    }
    get [dartx.distanceModel]() {
      return this.distanceModel;
    }
    set [dartx.distanceModel](value) {
      this.distanceModel = value;
    }
    get [dartx.maxDistance]() {
      return this.maxDistance;
    }
    set [dartx.maxDistance](value) {
      this.maxDistance = value;
    }
    get [dartx.panningModel]() {
      return this.panningModel;
    }
    set [dartx.panningModel](value) {
      this.panningModel = value;
    }
    get [dartx.refDistance]() {
      return this.refDistance;
    }
    set [dartx.refDistance](value) {
      this.refDistance = value;
    }
    get [dartx.rolloffFactor]() {
      return this.rolloffFactor;
    }
    set [dartx.rolloffFactor](value) {
      this.rolloffFactor = value;
    }
    [dartx.setOrientation](x, y, z) {
      return this.setOrientation(x, y, z);
    }
    [dartx.setPosition](x, y, z) {
      return this.setPosition(x, y, z);
    }
    [dartx.setVelocity](x, y, z) {
      return this.setVelocity(x, y, z);
    }
  }
  dart.setSignature(PannerNode, {
    constructors: () => ({_: [PannerNode, []]}),
    methods: () => ({
      [dartx.setOrientation]: [dart.void, [core.num, core.num, core.num]],
      [dartx.setPosition]: [dart.void, [core.num, core.num, core.num]],
      [dartx.setVelocity]: [dart.void, [core.num, core.num, core.num]]
    })
  });
  PannerNode[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('PannerNode')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("PannerNode,AudioPannerNode,webkitAudioPannerNode"))];
  dart.registerExtension(dart.global.PannerNode, PannerNode);
  class PeriodicWave extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
  }
  dart.setSignature(PeriodicWave, {
    constructors: () => ({_: [PeriodicWave, []]})
  });
  PeriodicWave[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('PeriodicWave')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("PeriodicWave"))];
  dart.registerExtension(dart.global.PeriodicWave, PeriodicWave);
  dart.defineExtensionNames([
    'setEventListener',
    'onAudioProcess',
    'bufferSize'
  ]);
  class ScriptProcessorNode extends AudioNode {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.bufferSize]() {
      return this.bufferSize;
    }
    [dartx.setEventListener](eventListener) {
      return this.setEventListener(eventListener);
    }
    get [dartx.onAudioProcess]() {
      return ScriptProcessorNode.audioProcessEvent.forTarget(this);
    }
  }
  dart.setSignature(ScriptProcessorNode, {
    constructors: () => ({_: [ScriptProcessorNode, []]}),
    methods: () => ({[dartx.setEventListener]: [dart.void, [html.EventListener]]})
  });
  ScriptProcessorNode[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('ScriptProcessorNode')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("ScriptProcessorNode,JavaScriptAudioNode"))];
  ScriptProcessorNode.audioProcessEvent = dart.const(new (html.EventStreamProvider$(AudioProcessingEvent))('audioprocess'));
  dart.registerExtension(dart.global.ScriptProcessorNode, ScriptProcessorNode);
  dart.defineExtensionNames([
    'curve',
    'oversample'
  ]);
  class WaveShaperNode extends AudioNode {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.curve]() {
      return this.curve;
    }
    set [dartx.curve](value) {
      this.curve = value;
    }
    get [dartx.oversample]() {
      return this.oversample;
    }
    set [dartx.oversample](value) {
      this.oversample = value;
    }
  }
  dart.setSignature(WaveShaperNode, {
    constructors: () => ({_: [WaveShaperNode, []]})
  });
  WaveShaperNode[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('WaveShaperNode')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("WaveShaperNode"))];
  dart.registerExtension(dart.global.WaveShaperNode, WaveShaperNode);
  // Exports:
  exports.AudioNode = AudioNode;
  exports.AnalyserNode = AnalyserNode;
  exports.AudioBuffer = AudioBuffer;
  exports.AudioBufferCallback = AudioBufferCallback;
  exports.AudioSourceNode = AudioSourceNode;
  exports.AudioBufferSourceNode = AudioBufferSourceNode;
  exports.AudioContext = AudioContext;
  exports.AudioDestinationNode = AudioDestinationNode;
  exports.AudioListener = AudioListener;
  exports.AudioParam = AudioParam;
  exports.AudioProcessingEvent = AudioProcessingEvent;
  exports.BiquadFilterNode = BiquadFilterNode;
  exports.ChannelMergerNode = ChannelMergerNode;
  exports.ChannelSplitterNode = ChannelSplitterNode;
  exports.ConvolverNode = ConvolverNode;
  exports.DelayNode = DelayNode;
  exports.DynamicsCompressorNode = DynamicsCompressorNode;
  exports.GainNode = GainNode;
  exports.MediaElementAudioSourceNode = MediaElementAudioSourceNode;
  exports.MediaStreamAudioDestinationNode = MediaStreamAudioDestinationNode;
  exports.MediaStreamAudioSourceNode = MediaStreamAudioSourceNode;
  exports.OfflineAudioCompletionEvent = OfflineAudioCompletionEvent;
  exports.OfflineAudioContext = OfflineAudioContext;
  exports.OscillatorNode = OscillatorNode;
  exports.PannerNode = PannerNode;
  exports.PeriodicWave = PeriodicWave;
  exports.ScriptProcessorNode = ScriptProcessorNode;
  exports.WaveShaperNode = WaveShaperNode;
});
