// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observatory;

/// A request response interceptor is called for each response.
typedef void RequestResponseInterceptor();

abstract class RequestManager extends Observable {
  ObservatoryApplication _application;
  ObservatoryApplication get application => _application;
  RequestResponseInterceptor interceptor;

  /// The default request prefix is 127.0.0.1 on port 8181.
  @observable String prefix = 'http://127.0.0.1:8181';
  /// List of responses.
  @observable List<Map> responses = toObservable([]);

  /// Parse
  void parseResponses(String responseString) {
    var r = JSON.decode(responseString);
    if (r is Map) {
      setResponses([r]);
    } else {
      setResponses(r);
    }
  }

  void setResponses(List<Map> r) {
    responses = toObservable(r);
    if (interceptor != null) {
      interceptor();
    }
  }

  void setResponseError(HttpRequest request) {
    String error = '${request.status} ${request.statusText}';
    if (request.status == 0) {
      error = 'No service found. Did you run with --enable-vm-service ?';
    }
    setResponses([{
      'type': 'RequestError',
      'error': error
    }]);
  }

  /// Request [requestString] from the VM service. Updates [responses].
  /// Will trigger [interceptor] if one is set.
  void get(String requestString) {
    if (_application.locationManager.isScriptLink) {
      // We cache script sources.
      String scriptName = _application.locationManager.scriptName;
      getScriptSource(scriptName, requestString).then((source) {
        if (source != null) {
          setResponses([{
            'type': 'Script',
            'source': source
          }]);
        } else {
          setResponses([{
            'type': 'RequestError',
            'error': 'Source for $scriptName could not be loaded.'
          }]);
        }
      });
    } else {
      request(requestString).then((responseString) {
        parseResponses(responseString);
      }).catchError((e) {
        if (e is FormatException) {
          setResponseError(e.message);
        } else {
          setResponseError(e.target);
        }
      });
    }
  }

  Future<ScriptSource> getScriptSource(String name, String requestString) {
    int isolateId = _application.locationManager.currentIsolateId();
    Isolate isolate = _application.isolateManager.getIsolate(isolateId);
    ScriptSource source = isolate.scripts[name];
    if (source != null) {
      return new Future.value(source);
    }
    return request(requestString).then((responseString) {
      var r = JSON.decode(responseString);
      ScriptSource scriptSource = new ScriptSource(r);
      isolate.scripts[name] = scriptSource;
      return scriptSource;
    }).catchError((e) {
      setResponseError(e.target);
      return null;
    });
  }

  /// Abstract method. Given the [requestString], return a String in the
  /// future which contains the reply from the VM service.
  Future<String> request(String requestString);
}


class HttpRequestManager extends RequestManager {
  Future<String> request(String requestString) {
    return HttpRequest.getString(prefix + requestString);
  }
}

class PostMessageRequestManager extends RequestManager {
  final Map _outstandingRequests = new Map();
  int _requestSerial = 0;
  PostMessageRequestManager() {
    window.onMessage.listen(_messageHandler);
  }

  void _messageHandler(msg) {
    var id = msg.data['id'];
    var name = msg.data['name'];
    var data = msg.data['data'];
    if (name != 'observatoryData') {
      return;
    }
    print('Got reply $id $data');
    var completer = _outstandingRequests[id];
    if (completer != null) {
      _outstandingRequests.remove(id);
      print('Completing $id');
      completer.complete(data);
    } else {
      print('Could not find completer for $id');
    }
  }

  Future<String> request(String requestString) {
    var idString = '$_requestSerial';
    Map message = {};
    message['id'] = idString;
    message['method'] = 'observatoryQuery';
    message['query'] = requestString;
    _requestSerial++;

    var completer = new Completer();
    _outstandingRequests[idString] = completer;

    window.parent.postMessage(JSON.encode(message), '*');
    return completer.future;
  }
}
