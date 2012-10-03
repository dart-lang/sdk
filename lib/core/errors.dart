// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Error {
  const Error();
}

class AssertionError implements Error {
}

class TypeError implements AssertionError {
}

class CastError implements Error {
}

/**
 * Error thrown when a function is passed an unacceptable argument.
 */
class ArgumentError implements Error {
  final message;

  /** The [message] describes the erroneous argument. */
  const ArgumentError([this.message = ""]);

  String toString() {
    if (message != null) {
      return "Illegal argument(s): $message";
    }
    return "Illegal argument(s)";
  }
}

/**
 * Temporary backwards compatibility class.
 *
 * Removed when users have had time to change to using [ArgumentError].
 */
class IllegalArgumentException extends ArgumentError {
  const IllegalArgumentException([argument = ""]) : super(argument);
}


class FallThroughError implements Error {
  const FallThroughError();
}

class AbstractClassInstantiationError {
}

/**
 * Error thrown by the default implementation of [:noSuchMethod:] on [Object].
 */
class NoSuchMethodError implements Error {
  final Object _receiver;
  final String _functionName;
  final List _arguments;
  final List _existingArgumentNames;

  /**
   * Create a [NoSuchMethodError] corresponding to a failed method call.
   *
   * The first parameter is the receiver of the method call.
   * The second parameter is the name of the called method.
   * The third parameter is the positional arguments that the method was
   * called with.
   * The optional [exisitingArgumentNames] is the expected parameters of a
   * method with the same name on the receiver, if available. This is
   * the method that would have been called if the parameters had matched.
   *
   * TODO(lrn): This will be rewritten to use mirrors when they are available.
   */
  const NoSuchMethodError(Object this._receiver,
                          String this._functionName,
                          List this._arguments,
                          [List existingArgumentNames = null])
      : this._existingArgumentNames = existingArgumentNames;

  String toString() {
    StringBuffer sb = new StringBuffer();
    for (int i = 0; i < _arguments.length; i++) {
      if (i > 0) {
        sb.add(", ");
      }
      sb.add(safeToString(_arguments[i]));
    }
    if (_existingArgumentNames === null) {
      return "NoSuchMethodError : method not found: '$_functionName'\n"
          "Receiver: ${safeToString(_receiver)}\n"
          "Arguments: [$sb]";
    } else {
      String actualParameters = sb.toString();
      sb = new StringBuffer();
      for (int i = 0; i < _existingArgumentNames.length; i++) {
        if (i > 0) {
          sb.add(", ");
        }
        sb.add(_existingArgumentNames[i]);
      }
      String formalParameters = sb.toString();
      return "NoSuchMethodError: incorrect number of arguments passed to "
          "method named '$_functionName'\n"
          "Receiver: ${safeToString(_receiver)}\n"
          "Tried calling: $_functionName($actualParameters)\n"
          "Found: $_functionName($formalParameters)";
    }
  }

  static String safeToString(Object object) {
    if (object is int || object is double || object is bool || null == object) {
      return object.toString();
    }
    if (object is String) {
      // TODO(ahe): Remove backslash when http://dartbug.com/4995 is fixed.
      const backslash = '\\';
      String escaped = object
        .replaceAll('$backslash', '$backslash$backslash')
        .replaceAll('\n', '${backslash}n')
        .replaceAll('\r', '${backslash}r')
        .replaceAll('"',  '$backslash"');
      return '"$escaped"';
    }
    return _objectToString(object);
  }

  external static String _objectToString(Object object);
}
