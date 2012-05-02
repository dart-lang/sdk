// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class XMLHttpRequestEventsImplementation extends EventsImplementation
    implements XMLHttpRequestEvents {
  XMLHttpRequestEventsImplementation._wrap(_ptr) : super._wrap(_ptr);

  EventListenerList get abort() => _get('abort');
  EventListenerList get error() => _get('error');
  EventListenerList get load() => _get('load');
  EventListenerList get loadStart() => _get('loadstart');
  EventListenerList get progress() => _get('progress');
  EventListenerList get readyStateChange() => _get('readystatechange');
}

class XMLHttpRequestWrappingImplementation extends EventTargetWrappingImplementation implements XMLHttpRequest {
  XMLHttpRequestWrappingImplementation._wrap(
      dom.XMLHttpRequest ptr) : super._wrap(ptr);

  factory XMLHttpRequestWrappingImplementation() {
    return new XMLHttpRequestWrappingImplementation._wrap(
        new dom.XMLHttpRequest());
  }

  factory XMLHttpRequestWrappingImplementation.get(String url,
      onSuccess(XMLHttpRequest request)) {
    final request = new XMLHttpRequest();
    request.open('GET', url, true);

    // TODO(terry): Validate after client login added if necessary to forward
    //              cookies to server.
    request.withCredentials = true;

    // Status 0 is for local XHR request.
    request.on.readyStateChange.add((e) {
      if (request.readyState == XMLHttpRequest.DONE &&
          (request.status == 200 || request.status == 0)) {
        onSuccess(request);
      }
    });

    request.send();

    return request;
  }

  int get readyState() => _ptr.readyState;

  String get responseText() => _ptr.responseText;

  String get responseType() => _ptr.responseType;

  void set responseType(String value) { _ptr.responseType = value; }

  XMLDocument get responseXML() => LevelDom.wrapDocument(_ptr.responseXML);

  int get status() => _ptr.status;

  String get statusText() => _ptr.statusText;

  XMLHttpRequestUpload get upload() => LevelDom.wrapXMLHttpRequestUpload(_ptr.upload);

  bool get withCredentials() => _ptr.withCredentials;

  void set withCredentials(bool value) { _ptr.withCredentials = value; }

  void abort() {
    _ptr.abort();
    return;
  }

  String getAllResponseHeaders() {
    return _ptr.getAllResponseHeaders();
  }

  String getResponseHeader(String header) {
    return _ptr.getResponseHeader(header);
  }

  void open(String method, String url, bool async, [String user = null, String password = null]) {
    if (user === null) {
      if (password === null) {
        _ptr.open(method, url, async);
        return;
      }
    } else {
      if (password === null) {
        _ptr.open(method, url, async, user);
        return;
      } else {
        _ptr.open(method, url, async, user, password);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void overrideMimeType(String mime) {
    _ptr.overrideMimeType(mime);
  }

  void send([var data = null]) {
    if (data === null) {
      _ptr.send();
      return;
    } else {
      if (data is Document) {
        _ptr.send(LevelDom.unwrapMaybePrimitive(data));
        return;
      } else {
        if (data is String) {
          _ptr.send(LevelDom.unwrapMaybePrimitive(data));
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void setRequestHeader(String header, String value) {
    _ptr.setRequestHeader(header, value);
  }

  XMLHttpRequestEvents get on() {
    if (_on === null) {
      _on = new XMLHttpRequestEventsImplementation._wrap(_ptr);
    }
    return _on;
  }
}
