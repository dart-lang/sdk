
class AudioPannerNode extends AudioNode native "*AudioPannerNode" {

  static final int EQUALPOWER = 0;

  static final int HRTF = 1;

  static final int SOUNDFIELD = 2;

  AudioGain coneGain;

  num coneInnerAngle;

  num coneOuterAngle;

  num coneOuterGain;

  AudioGain distanceGain;

  int distanceModel;

  num maxDistance;

  int panningModel;

  num refDistance;

  num rolloffFactor;

  void setOrientation(num x, num y, num z) native;

  void setPosition(num x, num y, num z) native;

  void setVelocity(num x, num y, num z) native;
}
