
class PositionErrorCallback native "*PositionErrorCallback" {

  bool handleEvent(PositionError error) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
