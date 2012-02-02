
class _GeopositionJs extends _DOMTypeJs implements Geoposition native "*Geoposition" {

  _CoordinatesJs get coords() native "return this.coords;";

  int get timestamp() native "return this.timestamp;";
}
