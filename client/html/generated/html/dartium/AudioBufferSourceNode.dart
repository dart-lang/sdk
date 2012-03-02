
class _AudioBufferSourceNodeImpl extends _AudioSourceNodeImpl implements AudioBufferSourceNode {
  _AudioBufferSourceNodeImpl._wrap(ptr) : super._wrap(ptr);

  AudioBuffer get buffer() => _wrap(_ptr.buffer);

  void set buffer(AudioBuffer value) { _ptr.buffer = _unwrap(value); }

  AudioGain get gain() => _wrap(_ptr.gain);

  bool get loop() => _wrap(_ptr.loop);

  void set loop(bool value) { _ptr.loop = _unwrap(value); }

  bool get looping() => _wrap(_ptr.looping);

  void set looping(bool value) { _ptr.looping = _unwrap(value); }

  AudioParam get playbackRate() => _wrap(_ptr.playbackRate);

  void noteGrainOn(num when, num grainOffset, num grainDuration) {
    _ptr.noteGrainOn(_unwrap(when), _unwrap(grainOffset), _unwrap(grainDuration));
    return;
  }

  void noteOff(num when) {
    _ptr.noteOff(_unwrap(when));
    return;
  }

  void noteOn(num when) {
    _ptr.noteOn(_unwrap(when));
    return;
  }
}
