
class DatabaseCallback native "*DatabaseCallback" {

  bool handleEvent(var database) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
