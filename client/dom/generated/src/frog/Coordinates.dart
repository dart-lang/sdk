
class CoordinatesJS implements Coordinates native "*Coordinates" {

  num get accuracy() native "return this.accuracy;";

  num get altitude() native "return this.altitude;";

  num get altitudeAccuracy() native "return this.altitudeAccuracy;";

  num get heading() native "return this.heading;";

  num get latitude() native "return this.latitude;";

  num get longitude() native "return this.longitude;";

  num get speed() native "return this.speed;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
