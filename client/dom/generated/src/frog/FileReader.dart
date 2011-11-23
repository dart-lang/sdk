
class FileReader native "*FileReader" {
  FileReader() native;


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
