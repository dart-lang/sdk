
class _FileReaderJs extends _DOMTypeJs implements FileReader native "*FileReader" {
  FileReader() native;


  static final int DONE = 2;

  static final int EMPTY = 0;

  static final int LOADING = 1;

  final _FileErrorJs error;

  EventListener onabort;

  EventListener onerror;

  EventListener onload;

  EventListener onloadend;

  EventListener onloadstart;

  EventListener onprogress;

  final int readyState;

  final Object result;

  void abort() native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventJs evt) native;

  void readAsArrayBuffer(_BlobJs blob) native;

  void readAsBinaryString(_BlobJs blob) native;

  void readAsDataURL(_BlobJs blob) native;

  void readAsText(_BlobJs blob, [String encoding = null]) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}
