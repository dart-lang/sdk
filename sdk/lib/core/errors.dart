// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

class Error {
  final StackTrace stackTrace;

  Error() : stackTrace = ((){ try { throw 0; } catch (e, s) { return s; } })();

  /**
   * Safely convert a value to a [String] description.
   *
   * The conversion is guaranteed to not throw, so it won't use the object's
   * toString method.
   */
  static String safeToString(Object object) {
    if (object is int || object is double || object is bool || null == object) {
      return object.toString();
    }
    if (object is String) {
      // TODO(ahe): Remove backslash when http://dartbug.com/4995 is fixed.
      String string = object;
      const backslash = '\\';
      String escaped = string
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

/**
 * Error thrown by the runtime system when an assert statement fails.
 */
class AssertionError implements Error {
  /** Assertion errors don't capture stack traces. */
  StackTrace get stackTrace => null;
}

/**
 * Error thrown by the runtime system when a type assertion fails.
 */
class TypeError implements AssertionError {
  /** Type errors don't capture stack traces. */
  StackTrace get stackTrace => null;
}

/**
 * Error thrown by the runtime system when a cast operation fails.
 */
class CastError implements Error {
  /** Cast errors don't capture stack traces. */
  StackTrace get stackTrace => null;
}

/**
 * Error thrown when attempting to throw [:null:].
 */
class NullThrownError implements Error {
  const NullThrownError();
  /** NullThrown errors don't capture stack traces. */
  StackTrace get stackTrace => null;
  String toString() => "Throw of null.";
}

/**
 * Error thrown when a function is passed an unacceptable argument.
 */
class ArgumentError extends Error {
  final message;

  /** The [message] describes the erroneous argument. */
  ArgumentError([this.message]);

  String toString() {
    if (message != null) {
      return "Illegal argument(s): $message";
    }
    return "Illegal argument(s)";
  }
}

/**
 * Error thrown because of an index outside of the valid range.
 *
 */
class RangeError extends ArgumentError {
  // TODO(lrn): This constructor should be called only with string values.
  // It currently isn't in all cases.
  /**
   * Create a new [RangeError] with the given [message].
   *
   * Temporarily made const for backwards compatibilty.
   */
  RangeError(var message) : super(message);

  /** Create a new [RangeError] with a message for the given [value]. */
  RangeError.value(num value) : super("value $value");

  /** Create a new [RangeError] with a message for a value and a range. */
  RangeError.range(num value, num start, num end)
      : super("value $value not in range $start..$end");

  String toString() => "RangeError: $message";
}


/**
 * Error thrown when control reaches the end of a switch case.
 *
 * The Dart specification requires this error to be thrown when
 * control reaches the end of a switch case (except the last case
 * of a switch) without meeting a break or similar end of the control
 * flow.
 */
class FallThroughError implements Error {
  const FallThroughError();
  StackTrace get stackTrace => null;
}

// TODO(lrn): Class description. Ensure that this is the class thrown by
// both implementations, or move it to the one that uses it.
class AbstractClassInstantiationError implements Error {
  final String _className;
  const AbstractClassInstantiationError(String this._className);
  StackTrace get stackTrace => null;
  String toString() => "Cannot instantiate abstract class: '$_className'";
}


/**
 * Error thrown by the default implementation of [:noSuchMethod:] on [Object].
 */
class NoSuchMethodError implements Error {
  final Object _receiver;
  final String _memberName;
  final List _arguments;
  final Map<String,dynamic> _namedArguments;
  final List _existingArgumentNames;

  /**
   * Create a [NoSuchMethodError] corresponding to a failed method call.
   *
   * The first parameter to this constructor is the receiver of the method call.
   * That is, the object on which the method was attempted called.
   * The second parameter is the name of the called method or accessor.
   * The third parameter is a list of the positional arguments that the method
   * was called with.
   * The fourth parameter is a map from [String] names to the values of named
   * arguments that the method was called with.
   * The optional [exisitingArgumentNames] is the expected parameters of a
   * method with the same name on the receiver, if available. This is
   * the method that would have been called if the parameters had matched.
   */
  NoSuchMethodError(Object this._receiver,
                          String this._memberName,
                          List this._arguments,
                          Map<String,dynamic> this._namedArguments,
                          [List existingArgumentNames = null])
      : this._existingArgumentNames = existingArgumentNames;

  StackTrace get stackTrace => null;

  external String toString();
}


/**
 * The operation was not allowed by the object.
 *
 * This [Error] is thrown when an instance cannot implement one of the methods
 * in its signature.
 */
class UnsupportedError extends Error {
  final String message;
  UnsupportedError(this.message);
  String toString() => "Unsupported operation: $message";
}


/**
 * Thrown by operations that have not been implemented yet.
 *
 * This [Error] is thrown by unfinished code that hasn't yet implemented
 * all the features it needs.
 *
 * If a class is not intending to implement the feature, it should throw
 * an [UnsupportedError] instead. This error is only intended for
 * use during development.
 */
class UnimplementedError extends UnsupportedError {
  UnimplementedError([String message]) : super(message);
  String toString() => (this.message != null
                        ? "UnimplementedError: $message"
                        : "UnimplementedError");
}


/**
 * The operation was not allowed by the current state of the object.
 *
 * This is a generic error used for a variety of different erroneous
 * actions. The message should be descriptive.
 */
class StateError extends Error {
  final String message;
  StateError(this.message);
  String toString() => "Bad state: $message";
}


/**
 * Error occurring when a collection is modified during iteration.
 *
 * Some modifications may be allowed for some collections, so each collection
 * ([Iterable] or similar collection of values) should declare which operations
 * are allowed during an iteration.
 */
class ConcurrentModificationError extends Error {
  /** The object that was modified in an incompatible way. */
  final Object modifiedObject;

  ConcurrentModificationError([this.modifiedObject]);

  String toString() {
    if (modifiedObject == null) {
      return "Concurrent modification during iteration.";
    }
    return "Concurrent modification during iteration: "
           "${Error.safeToString(modifiedObject)}.";
  }
}


class OutOfMemoryError implements Error {
  const OutOfMemoryError();
  StackTrace get stackTrace => null;
  String toString() => "Out of Memory";
}


class StackOverflowError implements Error {
  const StackOverflowError();
  StackTrace get stackTrace => null;
  String toString() => "Stack Overflow";
}

/**
 * Error thrown when a lazily initialized variable cannot be initialized.
 *
 * A static/library variable with an initializer expression is initialized
 * the first time it is read. If evaluating the initializer expression causes
 * another read of the variable, this error is thrown.
 */
class CyclicInitializationError implements Error {
  final String variableName;
  const CyclicInitializationError([this.variableName]);
  StackTrace get stackTrace => null;
  String toString() => variableName == null
      ? "Reading static variable during its initialization"
      : "Reading static variable '$variableName' during its initialization";
}
