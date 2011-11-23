
class FileWriter native "*FileWriter" {

  FileError error;

  int length;

  EventListener onabort;

  EventListener onerror;

  EventListener onprogress;

  EventListener onwrite;

  EventListener onwriteend;

  EventListener onwritestart;

  int position;

  int readyState;

  void abort() native;

  void seek(int position) native;

  void truncate(int size) native;

  void write(Blob data) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
