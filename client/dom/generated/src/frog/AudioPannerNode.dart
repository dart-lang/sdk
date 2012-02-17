
class _AudioPannerNodeJs extends _AudioNodeJs implements AudioPannerNode native "*AudioPannerNode" {

  static final int EQUALPOWER = 0;

  static final int EXPONENTIAL_DISTANCE = 2;

  static final int HRTF = 1;

  static final int INVERSE_DISTANCE = 1;

  static final int LINEAR_DISTANCE = 0;

  static final int SOUNDFIELD = 2;

  final _AudioGainJs coneGain;

  num coneInnerAngle;

  num coneOuterAngle;

  num coneOuterGain;

  final _AudioGainJs distanceGain;

  int distanceModel;

  num maxDistance;

  int panningModel;

  num refDistance;

  num rolloffFactor;

  void setOrientation(num x, num y, num z) native;

  void setPosition(num x, num y, num z) native;

  void setVelocity(num x, num y, num z) native;
}
