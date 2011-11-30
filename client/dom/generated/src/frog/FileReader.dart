
class FileReader native "*FileReader" {
  FileReader() native;


  static final int DONE = 2;

  static final int EMPTY = 0;

  static final int LOADING = 1;

  FileError error;

  int readyState;

  Object result;

  void abort() native;

  void readAsArrayBuffer(Blob blob) native;

  void readAsBinaryString(Blob blob) native;

  void readAsDataURL(Blob blob) native;

  void readAsText(Blob blob, [String encoding = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
