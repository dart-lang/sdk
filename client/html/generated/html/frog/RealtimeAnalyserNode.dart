
class _RealtimeAnalyserNodeImpl extends _AudioNodeImpl implements RealtimeAnalyserNode native "*RealtimeAnalyserNode" {

  int fftSize;

  final int frequencyBinCount;

  num maxDecibels;

  num minDecibels;

  num smoothingTimeConstant;

  void getByteFrequencyData(_Uint8ArrayImpl array) native;

  void getByteTimeDomainData(_Uint8ArrayImpl array) native;

  void getFloatFrequencyData(_Float32ArrayImpl array) native;
}
