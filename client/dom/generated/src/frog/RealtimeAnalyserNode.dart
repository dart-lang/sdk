
class _RealtimeAnalyserNodeJs extends _AudioNodeJs implements RealtimeAnalyserNode native "*RealtimeAnalyserNode" {

  int fftSize;

  final int frequencyBinCount;

  num maxDecibels;

  num minDecibels;

  num smoothingTimeConstant;

  void getByteFrequencyData(_Uint8ArrayJs array) native;

  void getByteTimeDomainData(_Uint8ArrayJs array) native;

  void getFloatFrequencyData(_Float32ArrayJs array) native;
}
