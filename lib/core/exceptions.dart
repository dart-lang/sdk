// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Exceptions are thrown either by the VM or from Dart code.

/**
 * Interface implemented by all core library exceptions.
 * Defaults to an implementation that only carries a simple message.
 */
interface Exception default _ExceptionImplementation {
  // TODO(lrn): This should be an abstract class, but we don't yet support
  // redirecting factory constructors.
  const Exception([var message]);
}


/** Default implementation of [Exception] which carries a message. */
class _ExceptionImplementation implements Exception {
  final message;
  const _ExceptionImplementation([this.message]);
  String toString() => (message == null) ? "Exception" : "Exception: $message";
}


/**
 * Exception thrown when a string or some other data does not have an expected
 * format and cannot be parsed or processed.
 */
class FormatException implements Exception {
  /**
   * A message describing the format error.
   */
  final String message;

  /**
   * Creates a new FormatException with an optional error [message].
   */
  const FormatException([this.message = ""]);

  String toString() => "FormatException: $message";
}


class NullPointerException implements Exception {
  const NullPointerException([this.functionName, this.arguments = const []]);
  String toString() {
    if (functionName == null) {
      return exceptionName;
    } else {
      return "$exceptionName : method: '$functionName'\n"
          "Receiver: null\n"
          "Arguments: $arguments";
    }
  }

  String get exceptionName => "NullPointerException";

  final String functionName;
  final List arguments;
}


class NotImplementedException implements Exception {
  const NotImplementedException([String message]) : this._message = message;
  String toString() => (this._message !== null
                        ? "NotImplementedException: $_message"
                        : "NotImplementedException");
  final String _message;
}


class IllegalJSRegExpException implements Exception {
  const IllegalJSRegExpException(String this._pattern, String this._errmsg);
  String toString() => "IllegalJSRegExpException: '$_pattern' '$_errmsg'";
  final String _pattern;
  final String _errmsg;
}


class IntegerDivisionByZeroException implements Exception {
  const IntegerDivisionByZeroException();
  String toString() => "IntegerDivisionByZeroException";
}

/**
 * Exception thrown when a runtime error occurs.
 */
class RuntimeError implements Exception {
  final message;
  RuntimeError(this.message);
  String toString() => "RuntimeError: $message";
}
