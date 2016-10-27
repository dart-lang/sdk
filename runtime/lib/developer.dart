// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';
import 'dart:_internal';

@patch bool debugger({bool when: true,
                     String message}) native "Developer_debugger";

@patch Object inspect(Object object) native "Developer_inspect";

@patch void log(String message,
                {DateTime time,
                 int sequenceNumber,
                 int level: 0,
                 String name: '',
                 Zone zone,
                 Object error,
                 StackTrace stackTrace}) {
  if (message is! String) {
    throw new ArgumentError(message, "message", "Must be a String");
  }
  if (time == null) {
    time = new DateTime.now();
  }
  if (time is! DateTime) {
    throw new ArgumentError(time, "time", "Must be a DateTime");
  }
  if (sequenceNumber == null) {
    sequenceNumber = _nextSequenceNumber++;
  } else {
    _nextSequenceNumber = sequenceNumber + 1;
  }
  _log(message,
       time.millisecondsSinceEpoch,
       sequenceNumber,
       level,
       name,
       zone,
       error,
       stackTrace);
}

int _nextSequenceNumber = 0;

_log(String message,
     int timestamp,
     int sequenceNumber,
     int level,
     String name,
     Zone zone,
     Object error,
     StackTrace stackTrace) native "Developer_log";

@patch void _postEvent(String eventKind, String eventData)
    native "Developer_postEvent";

@patch ServiceExtensionHandler _lookupExtension(String method)
    native "Developer_lookupExtension";

@patch _registerExtension(String method, ServiceExtensionHandler handler)
    native "Developer_registerExtension";

// This code is only invoked when there is no other Dart code on the stack.
_runExtension(ServiceExtensionHandler handler,
              String method,
              List<String> parameterKeys,
              List<String> parameterValues,
              SendPort replyPort,
              Object id,
              bool trace_service) {
  var parameters = {};
  for (var i = 0; i < parameterKeys.length; i++) {
    parameters[parameterKeys[i]] = parameterValues[i];
  }
  var response;
  try {
    response = handler(method, parameters);
  } catch (e, st) {
    var errorDetails = (st == null) ? '$e' : '$e\n$st';
    response = new ServiceExtensionResponse.error(
        ServiceExtensionResponse.kExtensionError,
        errorDetails);
    _postResponse(replyPort, id, response, trace_service);
    return;
  }
  if (response is! Future) {
    response = new ServiceExtensionResponse.error(
          ServiceExtensionResponse.kExtensionError,
          "Extension handler must return a Future");
    _postResponse(replyPort, id, response, trace_service);
    return;
  }
  response.catchError((e, st) {
    // Catch any errors eagerly and wrap them in a ServiceExtensionResponse.
    var errorDetails = (st == null) ? '$e' : '$e\n$st';
    return new ServiceExtensionResponse.error(
        ServiceExtensionResponse.kExtensionError,
        errorDetails);
  }).then((response) {
    // Post the valid response or the wrapped error after verifying that
    // the response is a ServiceExtensionResponse.
    if (response is! ServiceExtensionResponse) {
      response = new ServiceExtensionResponse.error(
          ServiceExtensionResponse.kExtensionError,
          "Extension handler must complete to a ServiceExtensionResponse");
    }
    _postResponse(replyPort, id, response, trace_service);
  }).catchError((e, st) {
    // We do not expect any errors to occur in the .then or .catchError blocks
    // but, suppress them just in case.
  });
}

// This code is only invoked by _runExtension.
_postResponse(SendPort replyPort,
              Object id,
              ServiceExtensionResponse response,
              bool trace_service) {
  assert(replyPort != null);
  if (id == null) {
    if (trace_service) {
      print("vm-service: posting no response for request");
    }
    // No id -> no response.
    replyPort.send(null);
    return;
  }
  assert(id != null);
  StringBuffer sb = new StringBuffer();
  sb.write('{"jsonrpc":"2.0",');
  if (response._isError()) {
    if (trace_service) {
      print("vm-service: posting error response for request $id");
    }
    sb.write('"error":');
  } else {
    if (trace_service) {
      print("vm-service: posting response for request $id");
    }
    sb.write('"result":');
  }
  sb.write('${response._toString()},');
  if (id is String) {
    sb.write('"id":"$id"}');
  } else {
    sb.write('"id":$id}');
  }
  replyPort.send(sb.toString());
}
