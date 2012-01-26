
class RealtimeAnalyserNodeJs extends AudioNodeJs implements RealtimeAnalyserNode native "*RealtimeAnalyserNode" {

  int get fftSize() native "return this.fftSize;";

  void set fftSize(int value) native "this.fftSize = value;";

  int get frequencyBinCount() native "return this.frequencyBinCount;";

  num get maxDecibels() native "return this.maxDecibels;";

  void set maxDecibels(num value) native "this.maxDecibels = value;";

  num get minDecibels() native "return this.minDecibels;";

  void set minDecibels(num value) native "this.minDecibels = value;";

  num get smoothingTimeConstant() native "return this.smoothingTimeConstant;";

  void set smoothingTimeConstant(num value) native "this.smoothingTimeConstant = value;";

  void getByteFrequencyData(Uint8ArrayJs array) native;

  void getByteTimeDomainData(Uint8ArrayJs array) native;

  void getFloatFrequencyData(Float32ArrayJs array) native;
}
