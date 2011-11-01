
class FileException native "FileException" {

  int code;

  String message;

  String name;

  var dartObjectLocalStorage;

  String get typeName() native;
}
