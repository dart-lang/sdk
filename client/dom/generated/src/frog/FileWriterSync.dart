
class FileWriterSync native "*FileWriterSync" {

  int length;

  int position;

  void seek(int position) native;

  void truncate(int size) native;

  void write(Blob data) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
