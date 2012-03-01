
class _BiquadFilterNodeImpl extends _AudioNodeImpl implements BiquadFilterNode native "*BiquadFilterNode" {

  static final int ALLPASS = 7;

  static final int BANDPASS = 2;

  static final int HIGHPASS = 1;

  static final int HIGHSHELF = 4;

  static final int LOWPASS = 0;

  static final int LOWSHELF = 3;

  static final int NOTCH = 6;

  static final int PEAKING = 5;

  final _AudioParamImpl Q;

  final _AudioParamImpl frequency;

  final _AudioParamImpl gain;

  int type;

  void getFrequencyResponse(_Float32ArrayImpl frequencyHz, _Float32ArrayImpl magResponse, _Float32ArrayImpl phaseResponse) native;
}
