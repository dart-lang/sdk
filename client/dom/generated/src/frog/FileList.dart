
class FileListJS implements FileList native "*FileList" {

  int get length() native "return this.length;";

  FileJS item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
