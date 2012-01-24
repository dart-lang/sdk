
class FileReaderJS implements FileReader native "*FileReader" {
  FileReader() native;


  static final int DONE = 2;

  static final int EMPTY = 0;

  static final int LOADING = 1;

  FileErrorJS get error() native "return this.error;";

  EventListener get onabort() native "return this.onabort;";

  void set onabort(EventListener value) native "this.onabort = value;";

  EventListener get onerror() native "return this.onerror;";

  void set onerror(EventListener value) native "this.onerror = value;";

  EventListener get onload() native "return this.onload;";

  void set onload(EventListener value) native "this.onload = value;";

  EventListener get onloadend() native "return this.onloadend;";

  void set onloadend(EventListener value) native "this.onloadend = value;";

  EventListener get onloadstart() native "return this.onloadstart;";

  void set onloadstart(EventListener value) native "this.onloadstart = value;";

  EventListener get onprogress() native "return this.onprogress;";

  void set onprogress(EventListener value) native "this.onprogress = value;";

  int get readyState() native "return this.readyState;";

  Object get result() native "return this.result;";

  void abort() native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(EventJS evt) native;

  void readAsArrayBuffer(BlobJS blob) native;

  void readAsBinaryString(BlobJS blob) native;

  void readAsDataURL(BlobJS blob) native;

  void readAsText(BlobJS blob, [String encoding = null]) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
