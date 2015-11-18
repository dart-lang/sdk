// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.developer;

class ServiceExtensionResponse {
  final String _result;
  final int _errorCode;
  final String _errorDetail;

  ServiceExtensionResponse.result(this._result)
      : _errorCode = null,
        _errorDetail = null {
    if (_result is! String) {
      throw new ArgumentError.value(_result, "result", "Must be a String");
    }
  }

  ServiceExtensionResponse.error(this._errorCode, this._errorDetail)
      : _result = null {
    _validateErrorCode(_errorCode);
    if (_errorDetail is! String) {
      throw new ArgumentError.value(_errorDetail,
                                    "errorDetail",
                                    "Must be a String");
    }
  }

  /// Invalid method parameter(s) error code.
  static const kInvalidParams = -32602;
  /// Generic extension error code.
  static const kExtensionError = -32000;
  /// Maximum extension provided error code.
  static const kExtensionErrorMax = -32000;
  /// Minimum extension provided error code.
  static const kExtensionErrorMin = -32016;

  static String _errorCodeMessage(int errorCode) {
    _validateErrorCode(errorCode);
    if (errorCode == kInvalidParams) {
      return "Invalid params";
    }
    return "Server error";
  }

  static _validateErrorCode(int errorCode) {
    if (errorCode is! int) {
      throw new ArgumentError.value(errorCode, "errorCode", "Must be an int");
    }
    if (errorCode == kInvalidParams) {
      return;
    }
    if ((errorCode >= kExtensionErrorMin) &&
        (errorCode <= kExtensionErrorMax)) {
      return;
    }
    throw new ArgumentError.value(errorCode, "errorCode", "Out of range");
  }

  bool _isError() => (_errorCode != null) && (_errorDetail != null);

  String _toString() {
    if (_result != null) {
      return _result;
    } else {
      assert(_errorCode != null);
      assert(_errorDetail != null);
      return JSON.encode({
        'code': _errorCode,
        'message': _errorCodeMessage(_errorCode),
        'data': {
          'details': _errorDetail
        }
      });
    }
  }
}

/// A service protocol extension handler. Registered with [registerExtension].
///
/// Must complete to a [ServiceExtensionResponse].
///
/// [method] - the method name.
/// [parameters] - the parameters.
typedef Future<ServiceExtensionResponse>
    ServiceExtensionHandler(String method, Map parameters);

/// Register a [ServiceExtensionHandler] that will be invoked in this isolate
/// for [method].
void registerExtension(String method, ServiceExtensionHandler handler) {
  if (method is! String) {
    throw new ArgumentError.value(method,
                                  'method',
                                  'Must be a String');
  }
  if (_lookupExtension(method) != null) {
    throw new ArgumentError('Extension already registered: $method');
  }
  if (handler is! ServiceExtensionHandler) {
    throw new ArgumentError.value(handler,
                                  'handler',
                                  'Must be a ServiceExtensionHandler');
  }
  _registerExtension(method, handler);
}

// Both of these functions are written inside C++ to avoid updating the data
// structures in Dart, getting an OOB, and observing stale state. Do not move
// these into Dart code unless you can ensure that the operations will can be
// done atomically. Native code lives in vm/isolate.cc-
// LookupServiceExtensionHandler and RegisterServiceExtensionHandler.
external ServiceExtensionHandler _lookupExtension(String method);
external _registerExtension(String method, ServiceExtensionHandler handler);

// This code is only invoked when there is no other Dart code on the stack.
_runExtension(ServiceExtensionHandler handler,
              String method,
              List<String> parameterKeys,
              List<String> parameterValues,
              SendPort replyPort,
              Object id) {
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
    _postResponse(replyPort, id, response);
    return;
  }
  if (response is! Future) {
    response = new ServiceExtensionResponse.error(
          ServiceExtensionResponse.kExtensionError,
          "Extension handler must return a Future");
    _postResponse(replyPort, id, response);
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
    _postResponse(replyPort, id, response);
  }).catchError((e, st) {
    // We do not expect any errors to occur in the .then or .catchError blocks
    // but, suppress them just in case.
  });
}

// This code is only invoked by _runExtension.
_postResponse(SendPort replyPort,
              Object id,
              ServiceExtensionResponse response) {
  assert(replyPort != null);
  if (id == null) {
    // No id -> no response.
    replyPort.send(null);
    return;
  }
  assert(id != null);
  StringBuffer sb = new StringBuffer();
  sb.write('{"jsonrpc":"2.0",');
  if (response._isError()) {
    sb.write('"error":');
  } else {
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
