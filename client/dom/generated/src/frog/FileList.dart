
class FileList native "*FileList" {

  int get length() native "return this.length;";

  File item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
