
class ErrorCallback native "ErrorCallback" {

  bool handleEvent(FileError error) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
