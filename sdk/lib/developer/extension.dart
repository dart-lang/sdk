// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.developer;

/// A response to a service protocol extension RPC.
///
/// If the RPC was successful, use [ServiceExtensionResponse.result], otherwise
/// use [ServiceExtensionResponse.error].
class ServiceExtensionResponse {
  final String _result;
  final int _errorCode;
  final String _errorDetail;

  /// Creates a successful response to a service protocol extension RPC.
  ///
  /// Requires [result] to be a JSON object encoded as a string. When forming
  /// the JSON-RPC message [result] will be inlined directly.
  ServiceExtensionResponse.result(String result)
      : _result = result,
        _errorCode = null,
        _errorDetail = null {
    if (_result is! String) {
      throw new ArgumentError.value(_result, "result", "Must be a String");
    }
  }

  /// Creates an error response to a service protocol extension RPC.
  ///
  /// Requires [errorCode] to be [invalidParams] or between [extensionErrorMin]
  /// and [extensionErrorMax]. Requires [errorDetail] to be a JSON object
  /// encoded as a string. When forming the JSON-RPC message [errorDetail] will
  /// be inlined directly.
  ServiceExtensionResponse.error(int errorCode, String errorDetail)
      : _result = null,
        _errorCode = errorCode,
        _errorDetail = errorDetail {
    _validateErrorCode(_errorCode);
    if (_errorDetail is! String) {
      throw new ArgumentError.value(
          _errorDetail, "errorDetail", "Must be a String");
    }
  }

  /// Invalid method parameter(s) error code.
  @deprecated
  static const kInvalidParams = invalidParams;

  /// Generic extension error code.
  @deprecated
  static const kExtensionError = extensionError;

  /// Maximum extension provided error code.
  @deprecated
  static const kExtensionErrorMax = extensionErrorMax;

  /// Minimum extension provided error code.
  @deprecated
  static const kExtensionErrorMin = extensionErrorMin;

  /// Invalid method parameter(s) error code.
  static const invalidParams = -32602;

  /// Generic extension error code.
  static const extensionError = -32000;

  /// Maximum extension provided error code.
  static const extensionErrorMax = -32000;

  /// Minimum extension provided error code.
  static const extensionErrorMin = -32016;

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
    if (errorCode == invalidParams) {
      return;
    }
    if ((errorCode >= extensionErrorMin) && (errorCode <= extensionErrorMax)) {
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
      return json.encode({
        'code': _errorCode,
        'message': _errorCodeMessage(_errorCode),
        'data': {'details': _errorDetail}
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
typedef Future<ServiceExtensionResponse> ServiceExtensionHandler(
    String method, Map<String, String> parameters);

/// Register a [ServiceExtensionHandler] that will be invoked in this isolate
/// for [method]. *NOTE*: Service protocol extensions must be registered
/// in each isolate.
///
/// *NOTE*: [method] must begin with 'ext.' and you should use the following
/// structure to avoid conflicts with other packages: 'ext.package.command'.
/// That is, immediately following the 'ext.' prefix, should be the registering
/// package name followed by another period ('.') and then the command name.
/// For example: 'ext.dart.io.getOpenFiles'.
///
/// Because service extensions are isolate specific, clients using extensions
/// must always include an 'isolateId' parameter with each RPC.
void registerExtension(String method, ServiceExtensionHandler handler) {
  if (method is! String) {
    throw new ArgumentError.value(method, 'method', 'Must be a String');
  }
  if (!method.startsWith('ext.')) {
    throw new ArgumentError.value(method, 'method', 'Must begin with ext.');
  }
  if (_lookupExtension(method) != null) {
    throw new ArgumentError('Extension already registered: $method');
  }
  if (handler is! ServiceExtensionHandler) {
    throw new ArgumentError.value(
        handler, 'handler', 'Must be a ServiceExtensionHandler');
  }
  _registerExtension(method, handler);
}

/// Post an event of [eventKind] with payload of [eventData] to the `Extension`
/// event stream.
void postEvent(String eventKind, Map eventData) {
  if (eventKind is! String) {
    throw new ArgumentError.value(eventKind, 'eventKind', 'Must be a String');
  }
  if (eventData is! Map) {
    throw new ArgumentError.value(eventData, 'eventData', 'Must be a Map');
  }
  String eventDataAsString = json.encode(eventData);
  _postEvent(eventKind, eventDataAsString);
}

external void _postEvent(String eventKind, String eventData);

// Both of these functions are written inside C++ to avoid updating the data
// structures in Dart, getting an OOB, and observing stale state. Do not move
// these into Dart code unless you can ensure that the operations will can be
// done atomically. Native code lives in vm/isolate.cc-
// LookupServiceExtensionHandler and RegisterServiceExtensionHandler.
external ServiceExtensionHandler _lookupExtension(String method);
external _registerExtension(String method, ServiceExtensionHandler handler);
