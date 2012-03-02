
class _XMLHttpRequestImpl extends _EventTargetImpl implements XMLHttpRequest {
  _XMLHttpRequestImpl._wrap(ptr) : super._wrap(ptr);

  bool get asBlob() => _wrap(_ptr.asBlob);

  void set asBlob(bool value) { _ptr.asBlob = _unwrap(value); }

  int get readyState() => _wrap(_ptr.readyState);

  Object get response() => _wrap(_ptr.response);

  Blob get responseBlob() => _wrap(_ptr.responseBlob);

  String get responseText() => _wrap(_ptr.responseText);

  String get responseType() => _wrap(_ptr.responseType);

  void set responseType(String value) { _ptr.responseType = _unwrap(value); }

  Document get responseXML() => _FixHtmlDocumentReference(_wrap(_ptr.responseXML));

  int get status() => _wrap(_ptr.status);

  String get statusText() => _wrap(_ptr.statusText);

  XMLHttpRequestUpload get upload() => _wrap(_ptr.upload);

  bool get withCredentials() => _wrap(_ptr.withCredentials);

  void set withCredentials(bool value) { _ptr.withCredentials = _unwrap(value); }

  _XMLHttpRequestEventsImpl get on() {
    if (_on == null) _on = new _XMLHttpRequestEventsImpl(this);
    return _on;
  }

  void abort() {
    _ptr.abort();
    return;
  }

  void _addEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _ptr.addEventListener(_unwrap(type), _unwrap(listener));
      return;
    } else {
      _ptr.addEventListener(_unwrap(type), _unwrap(listener), _unwrap(useCapture));
      return;
    }
  }

  bool _dispatchEvent(Event evt) {
    return _wrap(_ptr.dispatchEvent(_unwrap(evt)));
  }

  String getAllResponseHeaders() {
    return _wrap(_ptr.getAllResponseHeaders());
  }

  String getResponseHeader(String header) {
    return _wrap(_ptr.getResponseHeader(_unwrap(header)));
  }

  void open(String method, String url, [bool async = null, String user = null, String password = null]) {
    if (async === null) {
      if (user === null) {
        if (password === null) {
          _ptr.open(_unwrap(method), _unwrap(url));
          return;
        }
      }
    } else {
      if (user === null) {
        if (password === null) {
          _ptr.open(_unwrap(method), _unwrap(url), _unwrap(async));
          return;
        }
      } else {
        if (password === null) {
          _ptr.open(_unwrap(method), _unwrap(url), _unwrap(async), _unwrap(user));
          return;
        } else {
          _ptr.open(_unwrap(method), _unwrap(url), _unwrap(async), _unwrap(user), _unwrap(password));
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void overrideMimeType(String override) {
    _ptr.overrideMimeType(_unwrap(override));
    return;
  }

  void _removeEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _ptr.removeEventListener(_unwrap(type), _unwrap(listener));
      return;
    } else {
      _ptr.removeEventListener(_unwrap(type), _unwrap(listener), _unwrap(useCapture));
      return;
    }
  }

  void send([var data = null]) {
    if (data === null) {
      _ptr.send();
      return;
    } else {
      if (data is ArrayBuffer) {
        _ptr.send(_unwrap(data));
        return;
      } else {
        if (data is Blob) {
          _ptr.send(_unwrap(data));
          return;
        } else {
          if (data is Document) {
            _ptr.send(_unwrap(data));
            return;
          } else {
            if (data is String) {
              _ptr.send(_unwrap(data));
              return;
            } else {
              if (data is DOMFormData) {
                _ptr.send(_unwrap(data));
                return;
              }
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void setRequestHeader(String header, String value) {
    _ptr.setRequestHeader(_unwrap(header), _unwrap(value));
    return;
  }
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
