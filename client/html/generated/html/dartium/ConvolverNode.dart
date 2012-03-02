
class _ConvolverNodeImpl extends _AudioNodeImpl implements ConvolverNode {
  _ConvolverNodeImpl._wrap(ptr) : super._wrap(ptr);

  AudioBuffer get buffer() => _wrap(_ptr.buffer);

  void set buffer(AudioBuffer value) { _ptr.buffer = _unwrap(value); }

  bool get normalize() => _wrap(_ptr.normalize);

  void set normalize(bool value) { _ptr.normalize = _unwrap(value); }
}
