// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of vmservice;

class ServiceRequest {
  final List<String> pathSegments = new List<String>();
  final Map<String, String> parameters = new Map<String, String>();
  String _response;
  String get response => _response;

  ServiceRequest();

  bool parse(Uri uri) {
    var path = uri.path;
    var split = path.split('/');
    if (split.length == 0) {
      return false;
    }
    for (int i = 0; i < split.length; i++) {
      var pathSegment = split[i];
      if (pathSegment == '') {
        continue;
      }
      pathSegments.add(pathSegment);
    }
    uri.queryParameters.forEach((k, v) {
      parameters[k] = v;
    });
    return true;
  }

  String toServiceCallMessage() {
    return JSON.stringify({
      'p': pathSegments,
      'k': parameters.keys.toList(),
      'v': parameters.values.toList()
    });
  }

  void setErrorResponse(String error) {
    _response = JSON.stringify({
        'error': error,
        'pathSegments': pathSegments,
        'parameters': parameters
    });
  }

  void setResponse(String response) {
    _response = response;
  }

}
