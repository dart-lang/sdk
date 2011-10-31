
class FileSystemCallback native "FileSystemCallback" {

  bool handleEvent(DOMFileSystem fileSystem) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
