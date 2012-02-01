
class XMLHttpRequestJs extends DOMTypeJs implements XMLHttpRequest native "*XMLHttpRequest" {
  XMLHttpRequest() native;


  static final int DONE = 4;

  static final int HEADERS_RECEIVED = 2;

  static final int LOADING = 3;

  static final int OPENED = 1;

  static final int UNSENT = 0;

  bool get asBlob() native "return this.asBlob;";

  void set asBlob(bool value) native "this.asBlob = value;";

  int get readyState() native "return this.readyState;";

  Object get response() native "return this.response;";

  BlobJs get responseBlob() native "return this.responseBlob;";

  String get responseText() native "return this.responseText;";

  String get responseType() native "return this.responseType;";

  void set responseType(String value) native "this.responseType = value;";

  DocumentJs get responseXML() native "return this.responseXML;";

  int get status() native "return this.status;";

  String get statusText() native "return this.statusText;";

  XMLHttpRequestUploadJs get upload() native "return this.upload;";

  bool get withCredentials() native "return this.withCredentials;";

  void set withCredentials(bool value) native "this.withCredentials = value;";

  void abort() native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(EventJs evt) native;

  String getAllResponseHeaders() native;

  String getResponseHeader(String header) native;

  void open(String method, String url, [bool async = null, String user = null, String password = null]) native;

  void overrideMimeType(String override) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void send([var data = null]) native;

  void setRequestHeader(String header, String value) native;
}
