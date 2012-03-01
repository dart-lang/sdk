
class _FileReaderImpl implements FileReader native "*FileReader" {

  static final int DONE = 2;

  static final int EMPTY = 0;

  static final int LOADING = 1;

  final _FileErrorImpl error;

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

  bool dispatchEvent(_EventImpl evt) native;

  void readAsArrayBuffer(_BlobImpl blob) native;

  void readAsBinaryString(_BlobImpl blob) native;

  void readAsDataURL(_BlobImpl blob) native;

  void readAsText(_BlobImpl blob, [String encoding = null]) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}
