
class FileWriterCallback native "*FileWriterCallback" {

  bool handleEvent(FileWriter fileWriter) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
