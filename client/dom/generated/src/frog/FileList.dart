
class FileList native "FileList" {

  int length;

  File item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
