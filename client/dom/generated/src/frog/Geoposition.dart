
class GeopositionJs extends DOMTypeJs implements Geoposition native "*Geoposition" {

  CoordinatesJs get coords() native "return this.coords;";

  int get timestamp() native "return this.timestamp;";
}
