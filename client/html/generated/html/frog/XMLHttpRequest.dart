
class _XMLHttpRequestImpl extends _EventTargetImpl implements XMLHttpRequest native "*XMLHttpRequest" {

  _XMLHttpRequestEventsImpl get on() =>
    new _XMLHttpRequestEventsImpl(this);

  static final int DONE = 4;

  static final int HEADERS_RECEIVED = 2;

  static final int LOADING = 3;

  static final int OPENED = 1;

  static final int UNSENT = 0;

  bool asBlob;

  final int readyState;

  final Object response;

  final _BlobImpl responseBlob;

  final String responseText;

  String responseType;

  _DocumentImpl get responseXML() => _FixHtmlDocumentReference(_responseXML);

  _EventTargetImpl get _responseXML() native "return this.responseXML;";

  final int status;

  final String statusText;

  final _XMLHttpRequestUploadImpl upload;

  bool withCredentials;

  void abort() native;

  void _addEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.addEventListener(type, listener, useCapture);";

  bool _dispatchEvent(_EventImpl evt) native "return this.dispatchEvent(evt);";

  String getAllResponseHeaders() native;

  String getResponseHeader(String header) native;

  void open(String method, String url, [bool async = null, String user = null, String password = null]) native;

  void overrideMimeType(String override) native;

  void _removeEventListener(String type, EventListener listener, [bool useCapture = null]) native "this.removeEventListener(type, listener, useCapture);";

  void send([var data = null]) native;

  void setRequestHeader(String header, String value) native;
}

class _XMLHttpRequestEventsImpl extends _EventsImpl implements XMLHttpRequestEvents {
  _XMLHttpRequestEventsImpl(_ptr) : super(_ptr);

  EventListenerList get abort() => _get('abort');

  EventListenerList get error() => _get('error');

  EventListenerList get load() => _get('load');

  EventListenerList get loadEnd() => _get('loadend');

  EventListenerList get loadStart() => _get('loadstart');

  EventListenerList get progress() => _get('progress');

  EventListenerList get readyStateChange() => _get('readystatechange');
}
