
class _BiquadFilterNodeJs extends _AudioNodeJs implements BiquadFilterNode native "*BiquadFilterNode" {

  static final int ALLPASS = 7;

  static final int BANDPASS = 2;

  static final int HIGHPASS = 1;

  static final int HIGHSHELF = 4;

  static final int LOWPASS = 0;

  static final int LOWSHELF = 3;

  static final int NOTCH = 6;

  static final int PEAKING = 5;

  final _AudioParamJs Q;

  final _AudioParamJs frequency;

  final _AudioParamJs gain;

  int type;

  void getFrequencyResponse(_Float32ArrayJs frequencyHz, _Float32ArrayJs magResponse, _Float32ArrayJs phaseResponse) native;
}
