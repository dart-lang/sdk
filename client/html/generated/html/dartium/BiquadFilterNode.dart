
class _BiquadFilterNodeImpl extends _AudioNodeImpl implements BiquadFilterNode {
  _BiquadFilterNodeImpl._wrap(ptr) : super._wrap(ptr);

  AudioParam get Q() => _wrap(_ptr.Q);

  AudioParam get frequency() => _wrap(_ptr.frequency);

  AudioParam get gain() => _wrap(_ptr.gain);

  int get type() => _wrap(_ptr.type);

  void set type(int value) { _ptr.type = _unwrap(value); }

  void getFrequencyResponse(Float32Array frequencyHz, Float32Array magResponse, Float32Array phaseResponse) {
    _ptr.getFrequencyResponse(_unwrap(frequencyHz), _unwrap(magResponse), _unwrap(phaseResponse));
    return;
  }
}
