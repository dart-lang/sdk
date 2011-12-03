
class AudioListener native "*AudioListener" {

  num dopplerFactor;

  num speedOfSound;

  void setOrientation(num x, num y, num z, num xUp, num yUp, num zUp) native;

  void setPosition(num x, num y, num z) native;

  void setVelocity(num x, num y, num z) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
