
class _AudioContextImpl extends _DOMTypeBase implements AudioContext {
  _AudioContextImpl._wrap(ptr) : super._wrap(ptr);

  num get currentTime() => _wrap(_ptr.currentTime);

  AudioDestinationNode get destination() => _wrap(_ptr.destination);

  AudioListener get listener() => _wrap(_ptr.listener);

  EventListener get oncomplete() => _wrap(_ptr.oncomplete);

  void set oncomplete(EventListener value) { _ptr.oncomplete = _unwrap(value); }

  num get sampleRate() => _wrap(_ptr.sampleRate);

  RealtimeAnalyserNode createAnalyser() {
    return _wrap(_ptr.createAnalyser());
  }

  BiquadFilterNode createBiquadFilter() {
    return _wrap(_ptr.createBiquadFilter());
  }

  AudioBuffer createBuffer(var buffer_OR_numberOfChannels, var mixToMono_OR_numberOfFrames, [num sampleRate = null]) {
    if (buffer_OR_numberOfChannels is ArrayBuffer) {
      if (mixToMono_OR_numberOfFrames is bool) {
        if (sampleRate === null) {
          return _wrap(_ptr.createBuffer(_unwrap(buffer_OR_numberOfChannels), _unwrap(mixToMono_OR_numberOfFrames)));
        }
      }
    } else {
      if (buffer_OR_numberOfChannels is int) {
        if (mixToMono_OR_numberOfFrames is int) {
          return _wrap(_ptr.createBuffer(_unwrap(buffer_OR_numberOfChannels), _unwrap(mixToMono_OR_numberOfFrames), _unwrap(sampleRate)));
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  AudioBufferSourceNode createBufferSource() {
    return _wrap(_ptr.createBufferSource());
  }

  AudioChannelMerger createChannelMerger() {
    return _wrap(_ptr.createChannelMerger());
  }

  AudioChannelSplitter createChannelSplitter() {
    return _wrap(_ptr.createChannelSplitter());
  }

  ConvolverNode createConvolver() {
    return _wrap(_ptr.createConvolver());
  }

  DelayNode createDelayNode() {
    return _wrap(_ptr.createDelayNode());
  }

  DynamicsCompressorNode createDynamicsCompressor() {
    return _wrap(_ptr.createDynamicsCompressor());
  }

  AudioGainNode createGainNode() {
    return _wrap(_ptr.createGainNode());
  }

  HighPass2FilterNode createHighPass2Filter() {
    return _wrap(_ptr.createHighPass2Filter());
  }

  JavaScriptAudioNode createJavaScriptNode(int bufferSize) {
    return _wrap(_ptr.createJavaScriptNode(_unwrap(bufferSize)));
  }

  LowPass2FilterNode createLowPass2Filter() {
    return _wrap(_ptr.createLowPass2Filter());
  }

  MediaElementAudioSourceNode createMediaElementSource(MediaElement mediaElement) {
    return _wrap(_ptr.createMediaElementSource(_unwrap(mediaElement)));
  }

  AudioPannerNode createPanner() {
    return _wrap(_ptr.createPanner());
  }

  WaveShaperNode createWaveShaper() {
    return _wrap(_ptr.createWaveShaper());
  }

  void decodeAudioData(ArrayBuffer audioData, AudioBufferCallback successCallback, [AudioBufferCallback errorCallback = null]) {
    if (errorCallback === null) {
      _ptr.decodeAudioData(_unwrap(audioData), _unwrap(successCallback));
      return;
    } else {
      _ptr.decodeAudioData(_unwrap(audioData), _unwrap(successCallback), _unwrap(errorCallback));
      return;
    }
  }

  void startRendering() {
    _ptr.startRendering();
    return;
  }
}
