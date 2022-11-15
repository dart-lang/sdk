// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'core_patch.dart';

external Never _throwObjectWithStackTrace(Object error, StackTrace stacktrace);

@patch
class Error {
  @patch
  static String _objectToString(Object object) {
    return "Instance of '${object._runtimeType}'";
  }

  @patch
  static String _stringToSafeString(String string) {
    return jsonEncode(string);
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
  _TypeError(String message) : super(message);

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
  static Never _throwThrowNullError(StackTrace stackTrace) {
    final typeError =
        _TypeError.fromMessageAndStackTrace("Throw of null", stackTrace);
    return _throwObjectWithStackTrace(typeError, stackTrace);
  }

  @pragma("wasm:entry-point")
  static Never _throwAsCheckError(
      Object? operand, Type? type, StackTrace stackTrace) {
    final typeError = _TypeError.fromMessageAndStackTrace(
        "Type '${operand.runtimeType}' is not a subtype of type '$type'"
        " in type cast",
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

@patch
class NoSuchMethodError {
  final Object? _receiver;
  final Symbol _memberName;
  final List? _arguments;
  final Map<Symbol, dynamic>? _namedArguments;
  final List? _existingArgumentNames;

  @patch
  factory NoSuchMethodError.withInvocation(
          Object? receiver, Invocation invocation) =>
      NoSuchMethodError(receiver, invocation.memberName,
          invocation.positionalArguments, invocation.namedArguments);

  @patch
  NoSuchMethodError(Object? receiver, Symbol memberName,
      List? positionalArguments, Map<Symbol, dynamic>? namedArguments,
      [List? existingArgumentNames = null])
      : _receiver = receiver,
        _memberName = memberName,
        _arguments = positionalArguments,
        _namedArguments = namedArguments,
        _existingArgumentNames = existingArgumentNames;

  @pragma("wasm:entry-point")
  static Never _throwWithInvocation(Object? receiver, Invocation invocation) {
    throw NoSuchMethodError.withInvocation(receiver, invocation);
  }

  @patch
  String toString() {
    StringBuffer sb = StringBuffer('');
    String comma = '';
    List? arguments = _arguments;
    if (arguments != null) {
      for (var argument in arguments) {
        sb.write(comma);
        sb.write(Error.safeToString(argument));
        comma = ', ';
      }
    }
    Map<Symbol, dynamic>? namedArguments = _namedArguments;
    if (namedArguments != null) {
      namedArguments.forEach((Symbol key, var value) {
        sb.write(comma);
        sb.write(_symbolToString(key));
        sb.write(": ");
        sb.write(Error.safeToString(value));
        comma = ', ';
      });
    }
    String memberName = _symbolToString(_memberName);
    String receiverText = Error.safeToString(_receiver);
    String actualParameters = '$sb';
    List? existingArgumentNames = _existingArgumentNames;
    if (existingArgumentNames == null) {
      return "NoSuchMethodError: method not found: '$memberName'\n"
          "Receiver: ${receiverText}\n"
          "Arguments: [$actualParameters]";
    } else {
      String formalParameters = existingArgumentNames.join(', ');
      return "NoSuchMethodError: incorrect number of arguments passed to "
          "method named '$memberName'\n"
          "Receiver: ${receiverText}\n"
          "Tried calling: $memberName($actualParameters)\n"
          "Found: $memberName($formalParameters)";
    }
  }
}

/// Used by Fasta to report a runtime error when a final field with an
/// initializer is also initialized in a generative constructor.
///
/// Note: In strong mode, this is a compile-time error, but the CFE still needs
/// this class to exist in `dart:core`.
class _DuplicatedFieldInitializerError extends Error {
  final String _name;

  _DuplicatedFieldInitializerError(this._name);

  toString() => "Error: field '$_name' is already initialized.";
}

@patch
class StateError {
  static _throwNew(String msg) {
    throw new StateError(msg);
  }
}

// Implementations needed to implement the `_stackTrace` member added
// in the @patch class of [Error].

@patch
class OutOfMemoryError {
  StackTrace? get _stackTrace =>
      throw UnsupportedError('OutOfMemoryError._stackTrace');
  void set _stackTrace(StackTrace? _) {
    throw UnsupportedError('OutOfMemoryError._stackTrace');
  }
}

@patch
class StackOverflowError {
  StackTrace? get _stackTrace =>
      throw UnsupportedError('StackOverflowError._stackTrace');
  void set _stackTrace(StackTrace? _) {
    throw UnsupportedError('StackOverflowError._stackTrace');
  }
}

@patch
class IntegerDivisionByZeroException {
  StackTrace? get _stackTrace =>
      throw UnsupportedError('IntegerDivisionByZeroException._stackTrace');
  void set _stackTrace(StackTrace? _) {
    throw UnsupportedError('IntegerDivisionByZeroException._stackTrace');
  }
}
