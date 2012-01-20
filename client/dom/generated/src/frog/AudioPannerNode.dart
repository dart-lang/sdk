
class AudioPannerNode extends AudioNode native "*AudioPannerNode" {

  static final int EQUALPOWER = 0;

  static final int HRTF = 1;

  static final int SOUNDFIELD = 2;

  AudioGain get coneGain() native "return this.coneGain;";

  num get coneInnerAngle() native "return this.coneInnerAngle;";

  void set coneInnerAngle(num value) native "this.coneInnerAngle = value;";

  num get coneOuterAngle() native "return this.coneOuterAngle;";

  void set coneOuterAngle(num value) native "this.coneOuterAngle = value;";

  num get coneOuterGain() native "return this.coneOuterGain;";

  void set coneOuterGain(num value) native "this.coneOuterGain = value;";

  AudioGain get distanceGain() native "return this.distanceGain;";

  int get distanceModel() native "return this.distanceModel;";

  void set distanceModel(int value) native "this.distanceModel = value;";

  num get maxDistance() native "return this.maxDistance;";

  void set maxDistance(num value) native "this.maxDistance = value;";

  int get panningModel() native "return this.panningModel;";

  void set panningModel(int value) native "this.panningModel = value;";

  num get refDistance() native "return this.refDistance;";

  void set refDistance(num value) native "this.refDistance = value;";

  num get rolloffFactor() native "return this.rolloffFactor;";

  void set rolloffFactor(num value) native "this.rolloffFactor = value;";

  void setOrientation(num x, num y, num z) native;

  void setPosition(num x, num y, num z) native;

  void setVelocity(num x, num y, num z) native;
}
