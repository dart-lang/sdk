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
/// [method] - the method name of the service protocol request.
/// [parameters] - A map holding the parameters to the service protocol request.
///
/// *NOTE*: All parameter names and values are **encoded as strings**.
typedef Future<ServiceExtensionResponse>
    ServiceExtensionHandler(String method, Map<String, String> parameters);

/// Register a [ServiceExtensionHandler] that will be invoked in this isolate
/// for [method]. *NOTE*: Service protocol extensions must be registered
/// in each isolate and users of extensions must always specify a target
/// isolate.
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

/// Post an event of [eventKind] with payload of [eventData] to the `Extension`
/// event stream.
void postEvent(String eventKind, Map eventData) {
  if (eventKind is! String) {
    throw new ArgumentError.value(eventKind,
                                  'eventKind',
                                  'Must be a String');
  }
  if (eventData is! Map) {
    throw new ArgumentError.value(eventData,
                                  'eventData',
                                  'Must be a Map');
  }
  String eventDataAsString = JSON.encode(eventData);
  _postEvent(eventKind, eventDataAsString);
}

external _postEvent(String eventKind, String eventData);

// Both of these functions are written inside C++ to avoid updating the data
// structures in Dart, getting an OOB, and observing stale state. Do not move
// these into Dart code unless you can ensure that the operations will can be
// done atomically. Native code lives in vm/isolate.cc-
// LookupServiceExtensionHandler and RegisterServiceExtensionHandler.
external ServiceExtensionHandler _lookupExtension(String method);
external _registerExtension(String method, ServiceExtensionHandler handler);
