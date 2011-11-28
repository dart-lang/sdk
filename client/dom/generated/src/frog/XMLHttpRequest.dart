
class XMLHttpRequest native "*XMLHttpRequest" {
  XMLHttpRequest() native;


  static final int DONE = 4;

  static final int HEADERS_RECEIVED = 2;

  static final int LOADING = 3;

  static final int OPENED = 1;

  static final int UNSENT = 0;

  bool asBlob;

  int readyState;

  Blob responseBlob;

  String responseText;

  String responseType;

  Document responseXML;

  int status;

  String statusText;

  XMLHttpRequestUpload upload;

  bool withCredentials;

  void abort() native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(Event evt) native;

  String getAllResponseHeaders() native;

  String getResponseHeader(String header) native;

  void open(String method, String url, [bool async = null, String user = null, String password = null]) native;

  void overrideMimeType(String override) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void send([var data = null]) native;

  void setRequestHeader(String header, String value) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
