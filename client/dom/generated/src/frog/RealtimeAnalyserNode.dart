
class RealtimeAnalyserNode extends AudioNode native "*RealtimeAnalyserNode" {

  int fftSize;

  int frequencyBinCount;

  num maxDecibels;

  num minDecibels;

  num smoothingTimeConstant;

  void getByteFrequencyData(Uint8Array array) native;

  void getByteTimeDomainData(Uint8Array array) native;

  void getFloatFrequencyData(Float32Array array) native;
}
