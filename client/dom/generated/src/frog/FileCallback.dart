
class FileCallback native "FileCallback" {

  bool handleEvent(File file) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
