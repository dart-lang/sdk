
class FileReader native "*FileReader" {
  FileReader() native;


  static final int DONE = 2;

  static final int EMPTY = 0;

  static final int LOADING = 1;

  FileError error;

  EventListener onabort;

  EventListener onerror;

  EventListener onload;

  EventListener onloadend;

  EventListener onloadstart;

  EventListener onprogress;

  int readyState;

  Object result;

  void abort() native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(Event evt) native;

  void readAsArrayBuffer(Blob blob) native;

  void readAsBinaryString(Blob blob) native;

  void readAsDataURL(Blob blob) native;

  void readAsText(Blob blob, [String encoding = null]) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
