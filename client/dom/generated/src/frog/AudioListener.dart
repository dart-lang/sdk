
class AudioListenerJs extends DOMTypeJs implements AudioListener native "*AudioListener" {

  num get dopplerFactor() native "return this.dopplerFactor;";

  void set dopplerFactor(num value) native "this.dopplerFactor = value;";

  num get speedOfSound() native "return this.speedOfSound;";

  void set speedOfSound(num value) native "this.speedOfSound = value;";

  void setOrientation(num x, num y, num z, num xUp, num yUp, num zUp) native;

  void setPosition(num x, num y, num z) native;

  void setVelocity(num x, num y, num z) native;
}
