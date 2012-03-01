
class _RealtimeAnalyserNodeImpl extends _AudioNodeImpl implements RealtimeAnalyserNode {
  _RealtimeAnalyserNodeImpl._wrap(ptr) : super._wrap(ptr);

  int get fftSize() => _wrap(_ptr.fftSize);

  void set fftSize(int value) { _ptr.fftSize = _unwrap(value); }

  int get frequencyBinCount() => _wrap(_ptr.frequencyBinCount);

  num get maxDecibels() => _wrap(_ptr.maxDecibels);

  void set maxDecibels(num value) { _ptr.maxDecibels = _unwrap(value); }

  num get minDecibels() => _wrap(_ptr.minDecibels);

  void set minDecibels(num value) { _ptr.minDecibels = _unwrap(value); }

  num get smoothingTimeConstant() => _wrap(_ptr.smoothingTimeConstant);

  void set smoothingTimeConstant(num value) { _ptr.smoothingTimeConstant = _unwrap(value); }

  void getByteFrequencyData(Uint8Array array) {
    _ptr.getByteFrequencyData(_unwrap(array));
    return;
  }

  void getByteTimeDomainData(Uint8Array array) {
    _ptr.getByteTimeDomainData(_unwrap(array));
    return;
  }

  void getFloatFrequencyData(Float32Array array) {
    _ptr.getFloatFrequencyData(_unwrap(array));
    return;
  }
}
