// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

// Exceptions are thrown either by the VM or from Dart code.

/**
 * A marker interface implemented by all core library exceptions.
 *
 * An [Exception] is intended to convey information to the user about a failure,
 * so that the error can be addressed programmatically. It is intended to be
 * caught, and it should contain useful data fields.
 *
 * Creating instances of [Exception] directly with [:new Exception("message"):]
 * is discouraged, and only included as a temporary measure during development,
 * until the actual exceptions used by a library are done.
 */
abstract class Exception {
  factory Exception([var message]) => new _ExceptionImplementation(message);
}


/** Default implementation of [Exception] which carries a message. */
class _ExceptionImplementation implements Exception {
  final message;

  _ExceptionImplementation([this.message]);

  String toString() {
    if (message == null) return "Exception";
    return "Exception: $message";
  }
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

class IntegerDivisionByZeroException implements Exception {
  const IntegerDivisionByZeroException();
  String toString() => "IntegerDivisionByZeroException";
}
