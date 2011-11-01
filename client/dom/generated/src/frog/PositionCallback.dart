
class PositionCallback native "PositionCallback" {

  bool handleEvent(Geoposition position) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
