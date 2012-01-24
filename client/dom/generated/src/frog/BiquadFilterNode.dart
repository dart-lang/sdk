
class BiquadFilterNodeJS extends AudioNodeJS implements BiquadFilterNode native "*BiquadFilterNode" {

  static final int ALLPASS = 7;

  static final int BANDPASS = 2;

  static final int HIGHPASS = 1;

  static final int HIGHSHELF = 4;

  static final int LOWPASS = 0;

  static final int LOWSHELF = 3;

  static final int NOTCH = 6;

  static final int PEAKING = 5;

  AudioParamJS get Q() native "return this.Q;";

  AudioParamJS get frequency() native "return this.frequency;";

  AudioParamJS get gain() native "return this.gain;";

  int get type() native "return this.type;";

  void set type(int value) native "this.type = value;";

  void getFrequencyResponse(Float32ArrayJS frequencyHz, Float32ArrayJS magResponse, Float32ArrayJS phaseResponse) native;
}
