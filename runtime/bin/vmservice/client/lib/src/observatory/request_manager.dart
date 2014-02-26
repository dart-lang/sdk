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

  /// Decode [response] into a map.
  Map decodeResponse(String response) {
    var m;
    try {
      m = JSON.decode(response);
    } catch (e, st) {
      setResponseError('$e $st');
    };
    return m;
  }

  /// Parse
  void parseResponses(String responseString) {
    var r = decodeResponse(responseString);
    if (r == null) {
      return;
    }
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

  void setResponseRequestError(HttpRequest request) {
    String error = '${request.status} ${request.statusText}';
    if (request.status == 0) {
      error = 'No service found. Did you run with --enable-vm-service ?';
    }
    setResponses([{
      'type': 'Error',
      'errorType': 'RequestError',
      'text': error
    }]);
  }

  void setResponseError(String message) {
    setResponses([{
      'type': 'Error',
      'errorType': 'ResponseError',
      'text': message
    }]);
    Logger.root.severe(message);
  }

  static final RegExp _codeMatcher = new RegExp(r'/isolates/\d+/code/');
  static bool isCodeRequest(url) => _codeMatcher.hasMatch(url);
  static int codeAddressFromRequest(String url) {
    Match m = _codeMatcher.matchAsPrefix(url);
    if (m == null) {
      return 0;
    }
    try {
      var a = int.parse(m.input.substring(m.end), radix: 16);
      return a;
    } catch (e) {
      return 0;
    }
  }

  static final RegExp _isolateMatcher = new RegExp(r"/isolates/\d+");
  static String isolatePrefixFromRequest(String url) {
    Match m = _isolateMatcher.matchAsPrefix(url);
    if (m == null) {
      return null;
    }
    return m.input.substring(m.start, m.end);
  }

  static String isolateIdFromRequest(String url) {
    var prefix = isolatePrefixFromRequest(url);
    if (prefix == null) {
      return null;
    }
    // Chop off the '/'.
    return prefix.substring(1);
  }

  static final RegExp _scriptMatcher = new RegExp(r'/isolates/\d+/scripts/.+');
  static bool isScriptRequest(url) => _scriptMatcher.hasMatch(url);
  static final RegExp _scriptPrefixMatcher =
      new RegExp(r'/isolates/\d+/');
  static String scriptUrlFromRequest(String url) {
    var m = _scriptPrefixMatcher.matchAsPrefix(url);
    if (m == null) {
      return null;
    }
    return m.input.substring(m.end);
  }

  void _setModelResponse(String type, String modelName, dynamic model) {
    var response = {
      'type': type,
      modelName: model
    };
    setResponses([response]);
  }

  /// Handle 'Code' requests
  void _getCode(String requestString) {
    var isolateId = isolateIdFromRequest(requestString);
    if (isolateId == null) {
      setResponseError('$isolateId is not an isolate id.');
      return;
    }
    var isolate = _application.isolateManager.getIsolate(isolateId);
    if (isolate == null) {
      setResponseError('$isolateId could not be found.');
      return;
    }
    var address = codeAddressFromRequest(requestString);
    if (address == 0) {
      setResponseError('$requestString is not a valid code request.');
      return;
    }
    var code = isolate.findCodeByAddress(address);
    if (code != null) {
      Logger.root.info(
          'Found code with 0x${address.toRadixString(16)} in isolate.');
      _setModelResponse('Code', 'code', code);
      return;
    }
    request(requestString).then((responseString) {
      var map = decodeResponse(responseString);
      if (map == null) {
        return;
      }
      assert(map['type'] == 'Code');
      var code = new Code.fromMap(map);
      Logger.root.info(
          'Added code with 0x${address.toRadixString(16)} to isolate.');
      isolate.codes.add(code);
      _setModelResponse('Code', 'code', code);
    }).catchError(_requestCatchError);
  }

  void _getScript(String requestString) {
    var isolateId = isolateIdFromRequest(requestString);
    if (isolateId == null) {
      setResponseError('$isolateId is not an isolate id.');
      return;
    }
    var isolate = _application.isolateManager.getIsolate(isolateId);
    if (isolate == null) {
      setResponseError('$isolateId could not be found.');
      return;
    }
    var url = scriptUrlFromRequest(requestString);
    if (url == null) {
      setResponseError('$requestString is not a valid script request.');
      return;
    }
    var script = isolate.scripts[url];
    if ((script != null) && !script.needsSource) {
      Logger.root.info('Found script ${script.scriptRef['name']} in isolate');
      _setModelResponse('Script', 'script', script);
      return;
    }
    if (script != null) {
      // The isolate has the script but no script source code.
      requestMap(requestString).then((response) {
        assert(response['type'] == 'Script');
        script._processSource(response['source']);
        Logger.root.info(
            'Grabbed script ${script.scriptRef['name']} source.');
        _setModelResponse('Script', 'script', script);
      });
      return;
    }
    // New script.
    requestMap(requestString).then((response) {
      assert(response['type'] == 'Script');
      var script = new Script.fromMap(response);
      Logger.root.info(
          'Added script ${script.scriptRef['name']} to isolate.');
      _setModelResponse('Script', 'script', script);
      isolate.scripts[url] = script;
    });
  }

  void _requestCatchError(e, st) {
    if (e is ProgressEvent) {
      setResponseRequestError(e.target);
    } else {
      setResponseError('$e $st');
    }
  }

  /// Request [request] from the VM service. Updates [responses].
  /// Will trigger [interceptor] if one is set.
  void get(String requestString) {
    if (isCodeRequest(requestString)) {
      _getCode(requestString);
      return;
    }
    if (isScriptRequest(requestString)) {
      _getScript(requestString);
      return;
    }
    request(requestString).then((responseString) {
      parseResponses(responseString);
    }).catchError(_requestCatchError);
  }

  /// Abstract method. Given the [requestString], return a String in the
  /// future which contains the reply from the VM service.
  Future<String> request(String requestString);

  Future<Map> requestMap(String requestString) {
    if (requestString.startsWith('#')) {
      requestString = requestString.substring(1);
    }
    return request(requestString).then((response) {
      try {
        var m = JSON.decode(response);
        return m;
      } catch (e) { }
      return null;
    });
  }
}


class HttpRequestManager extends RequestManager {
  Future<String> request(String requestString) {
    Logger.root.info('Requesting $requestString');
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
