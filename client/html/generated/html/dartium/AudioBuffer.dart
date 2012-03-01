
class _AudioBufferImpl extends _DOMTypeBase implements AudioBuffer {
  _AudioBufferImpl._wrap(ptr) : super._wrap(ptr);

  num get duration() => _wrap(_ptr.duration);

  num get gain() => _wrap(_ptr.gain);

  void set gain(num value) { _ptr.gain = _unwrap(value); }

  int get length() => _wrap(_ptr.length);

  int get numberOfChannels() => _wrap(_ptr.numberOfChannels);

  num get sampleRate() => _wrap(_ptr.sampleRate);

  Float32Array getChannelData(int channelIndex) {
    return _wrap(_ptr.getChannelData(_unwrap(channelIndex)));
  }
}
