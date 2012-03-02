
class _WaveShaperNodeImpl extends _AudioNodeImpl implements WaveShaperNode {
  _WaveShaperNodeImpl._wrap(ptr) : super._wrap(ptr);

  Float32Array get curve() => _wrap(_ptr.curve);

  void set curve(Float32Array value) { _ptr.curve = _unwrap(value); }
}
