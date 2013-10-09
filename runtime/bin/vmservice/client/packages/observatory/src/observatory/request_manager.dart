// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observatory;

/// A request response interceptor is called for each response.
typedef void RequestResponseInterceptor();

abstract class RequestManager extends Object with ChangeNotifierMixin {
  ObservatoryApplication _application;
  ObservatoryApplication get application => _application;
  RequestResponseInterceptor interceptor;

  /// The default request prefix is 127.0.0.1 on port 8181.
  @observable String get prefix => __$prefix; String __$prefix = 'http://127.0.0.1:8181'; set prefix(String value) { __$prefix = notifyPropertyChange(#prefix, __$prefix, value); }
  /// List of responses.
  @observable List<Map> get responses => __$responses; List<Map> __$responses = toObservable([]); set responses(List<Map> value) { __$responses = notifyPropertyChange(#responses, __$responses, value); }

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

  void setResponseError(String error) {
    setResponses([{
      'type': 'RequestError',
      'error': error
    }]);
  }

  /// Request [requestString] from the VM service. Updates [responses].
  /// Will trigger [interceptor] if one is set.
  Future<Map> get(String requestString) {
    request(requestString).then((responseString) {
      parseResponses(responseString);
    }).catchError((e) {
      setResponseError(e.toString());
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
