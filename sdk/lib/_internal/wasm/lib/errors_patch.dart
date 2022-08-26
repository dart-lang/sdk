// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

external Never _throwObjectWithStackTrace(Object error, StackTrace stacktrace);

@patch
class Error {
  @patch
  static String _objectToString(Object object) {
    return object.toString();
  }

  @patch
  static String _stringToSafeString(String string) {
    // TODO(joshualitt): JSON encode string.
    return string;
  }

  @patch
  StackTrace? get stackTrace => _stackTrace;

  StackTrace? _stackTrace;

  @patch
  static Never _throw(Object error, StackTrace stackTrace) {
    if (error is Error && error._stackTrace == null) {
      error._stackTrace = stackTrace;
    }
    return _throwObjectWithStackTrace(error, stackTrace);
  }
}

class _Error extends Error {
  final String _message;

  _Error(this._message);

  @override
  String toString() => _message;
}

class _TypeError extends _Error implements TypeError {
  _TypeError(String message) : super('TypeError: $message');

  factory _TypeError.fromMessageAndStackTrace(
      String message, StackTrace stackTrace) {
    final typeError = _TypeError(message);
    typeError._stackTrace = stackTrace;
    return typeError;
  }

  @pragma("wasm:entry-point")
  static Never _throwNullCheckError(StackTrace stackTrace) {
    final typeError = _TypeError.fromMessageAndStackTrace(
        "Null check operator used on a null value", stackTrace);
    return _throwObjectWithStackTrace(typeError, stackTrace);
  }

  @pragma("wasm:entry-point")
  static Never _throwAsCheckError(
      Object? operand, Type? type, StackTrace stackTrace) {
    final typeError = _TypeError.fromMessageAndStackTrace(
        "Type '${operand.runtimeType}' is not a subtype of type '$type' in type cast",
        stackTrace);
    return _throwObjectWithStackTrace(typeError, stackTrace);
  }

  @pragma("wasm:entry-point")
  static Never _throwWasmRefError(String expected, StackTrace stackTrace) {
    final typeError = _TypeError.fromMessageAndStackTrace(
        "The Wasm reference is not $expected", stackTrace);
    return _throwObjectWithStackTrace(typeError, stackTrace);
  }
}
