// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * Error objects thrown in the case of a program failure.
 *
 * An `Error` object represents a program failure that the programmer
 * should have avoided.
 *
 * Examples include calling a function with invalid arguments,
 * or even with the wrong number of arguments,
 * or calling it at a time when it is not allowed.
 *
 * These are not errors that a caller should expect or catch -
 * if they occur, the program is erroneous,
 * and terminating the program may be the safest response.
 *
 * When deciding that a function throws an error,
 * the conditions where it happens should be clearly described,
 * and they should be detectable and predictable,
 * so the programmer using the function can avoid triggering the error.
 *
 * Such descriptions often uses words like
 * "must" or "must not" to describe the condition,
 * and if you see words like that in a function's documentation,
 * then not satisfying the requirement
 * is very likely to cause an error to be thrown.
 *
 * Example (from [String.contains]):
 *
 *        `startIndex` must not be negative or greater than `length`.
 *
 * In this case, an error will be thrown if `startIndex` is negative
 * or too large.
 *
 * If the conditions are not detectable before calling a function,
 * the called function should not throw an `Error`.
 * It may still throw a value,
 * but the caller will have to catch the thrown value,
 * effectively making it an alternative result rather than an error.
 * The thrown object can choose to implement [Exception]
 * to document that it represents an exceptional, but not erroneous, occurrence,
 * but it has no other effect than documentation.
 *
 * All non-`null` values can be thrown in Dart.
 * Objects extending `Error` are handled specially:
 * The first time they are thrown,
 * the stack trace at the throw point is recorded
 * and stored in the error object.
 * It can be retrieved using the [stackTrace] getter.
 * An error object that merely implements `Error`, and doesn't extend it,
 * will not store the stack trace automatically.
 *
 * Error objects are also used for system wide failures
 * like stack overflow or an out-of-memory situation.
 *
 * Since errors are not created to be caught,
 * there is no need for subclasses to distinguish the errors.
 * Instead subclasses have been created in order to make groups
 * of related errors easy to create with consistent error messages.
 * For example, the [String.contains] method will use a [RangeError]
 * if its `startIndex` isn't in the range `0..length`,
 * which is easily created by `new RangeError.range(startIndex, 0, length)`.
 */
class Error {
  Error();  // Prevent use as mixin.

  /**
   * Safely convert a value to a [String] description.
   *
   * The conversion is guaranteed to not throw, so it won't use the object's
   * toString method.
   */
  static String safeToString(Object object) {
    if (object is num || object is bool || null == object) {
      return object.toString();
    }
    if (object is String) {
      String string = object;
      StringBuffer buffer = new StringBuffer('"');
      const int TAB = 0x09;
      const int NEWLINE = 0x0a;
      const int CARRIGE_RETURN = 0x0d;
      const int BACKSLASH = 0x5c;
      const int DOUBLE_QUOTE = 0x22;
      const int DIGIT_ZERO = 0x30;
      const int LOWERCASE_A = 0x61;
      const int MAX_CONTROL = 0x1f;
      for (int i = 0; i < string.length; i++) {
        int codeUnit = string.codeUnitAt(i);
        if (codeUnit <= MAX_CONTROL) {
          if (codeUnit == NEWLINE) {
            buffer.write(r"\n");
          } else if (codeUnit == CARRIGE_RETURN) {
            buffer.write(r"\r");
          } else if (codeUnit == TAB) {
            buffer.write(r"\t");
          } else {
            buffer.write(r"\x");
            // Convert code in range 0x00 .. 0x1f to hex a two-digit hex string.
            if (codeUnit < 0x10) {
              buffer.write("0");
            } else {
              buffer.write("1");
              codeUnit -= 0x10;
            }
            // Single digit to hex.
            buffer.writeCharCode(codeUnit < 10 ? DIGIT_ZERO + codeUnit
                                               : LOWERCASE_A - 10 + codeUnit);
          }
        } else if (codeUnit == BACKSLASH) {
          buffer.write(r"\\");
        } else if (codeUnit == DOUBLE_QUOTE) {
          buffer.write(r'\"');
        } else {
          buffer.writeCharCode(codeUnit);
        }
      }
      buffer.write('"');
      return buffer.toString();
    }
    return _objectToString(object);
  }

  external static String _objectToString(Object object);

  external StackTrace get stackTrace;
}

/**
 * Error thrown by the runtime system when an assert statement fails.
 */
class AssertionError extends Error {
}

/**
 * Error thrown by the runtime system when a type assertion fails.
 */
class TypeError extends AssertionError {
}

/**
 * Error thrown by the runtime system when a cast operation fails.
 */
class CastError extends Error {
}

/**
 * Error thrown when attempting to throw [:null:].
 */
class NullThrownError extends Error {
  String toString() => "Throw of null.";
}

/**
 * Error thrown when a function is passed an unacceptable argument.
 */
class ArgumentError extends Error {
  /** Whether value was provided. */
  final bool _hasValue;
  /** The invalid value. */
  final invalidValue;
  /** Name of the invalid argument, if available. */
  final String name;
  /** Message describing the problem. */
  final message;

  /**
   * The [message] describes the erroneous argument.
   *
   * Existing code may be using `message` to hold the invalid value.
   * If the `message` is not a [String], it is assumed to be a value instead
   * of a message.
   */
  ArgumentError([this.message])
     : invalidValue = null,
       _hasValue = false,
       name = null;

  /**
   * Creates error containing the invalid [value].
   *
   * A message is built by suffixing the [message] argument with
   * the [name] argument (if provided) and the value. Example
   *
   *    "Invalid argument (foo): null"
   *
   * The `name` should match the argument name of the function, but if
   * the function is a method implementing an interface, and its argument
   * names differ from the interface, it might be more useful to use the
   * interface method's argument name (or just rename arguments to match).
   */
  ArgumentError.value(value,
                      [String this.name,
                       String this.message = "Invalid argument"])
      : invalidValue = value,
        _hasValue = true;

  /**
   * Create an argument error for a `null` argument that must not be `null`.
   *
   * Shorthand for calling [ArgumentError.value] with a `null` value and a
   * message of `"Must not be null"`.
   */
  ArgumentError.notNull([String name])
      : this.value(null, name, "Must not be null");

  String toString() {
    if (!_hasValue) {
      if (message != null) {
        return "Invalid argument(s): $message";
      }
      return "Invalid argument(s)";
    }
    String nameString = "";
    if (name != null) {
      nameString = " ($name)";
    }
    return "$message$nameString: ${Error.safeToString(invalidValue)}";
  }
}

/**
 * Error thrown due to an index being outside a valid range.
 */
class RangeError extends ArgumentError {
  /** The value that is outside its valid range. */
  final num invalidValue;
  /** The minimum value that [value] is allowed to assume. */
  final num start;
  /** The maximum value that [value] is allowed to assume. */
  final num end;

  // TODO(lrn): This constructor should be called only with string values.
  // It currently isn't in all cases.
  /**
   * Create a new [RangeError] with the given [message].
   */
  RangeError(var message)
      : invalidValue = null, start = null, end = null, super(message);

  /** Create a new [RangeError] with a message for the given [value]. */
  RangeError.value(num value, [String message = "Value not in range"])
      : invalidValue = value, start = null, end = null,
        super(message);

  /**
   * Create a new [RangeError] with for an invalid value being outside a range.
   *
   * The allowed range is from [start] to [end], inclusive.
   * If `start` or `end` are `null`, the range is infinite in that direction.
   *
   * For a range from 0 to the length of something, end exclusive, use
   * [RangeError.index].
   */
  RangeError.range(this.invalidValue, this.start, this.end,
                   [String message = "Invalid value"]) : super(message);

  /**
   * Creates a new [RangeError] stating that [index] is not a valid index
   * into [indexable].
   *
   * The [length] is the length of [indexable] at the time of the error.
   * If `length` is omitted, it defaults to `indexable.length`.
   *
   * The message is used as part of the string representation of the error.
   */
  factory RangeError.index(int index, indexable,
                           [String message,
                            int length]) = IndexError;

  String toString() {
    if (invalidValue == null) return "$message";
    String value = Error.safeToString(invalidValue);
    if (start == null) {
      if (end == null) {
        return "$message ($value)";
      }
      return "$message ($value): Value must be less than or equal to $end";
    }
    if (end == null) {
      return "$message ($value): Value must be greater than or equal to $start";
    }
    if (end > start) {
      return "$message ($value): Value must be in range $start..$end, "
             "inclusive.";
    }
    if (end < start) return "$message ($value): Valid range is empty";
    return "$message ($value): Only valid value is $start";
  }
}

/**
 * A specialized [RangeError] used when an index is not in the range
 * `0..indexable.length-1`.
 *
 * Also contains the indexable object, its length at the time of the error,
 * and the invalid index itself.
 */
class IndexError extends ArgumentError implements RangeError {
  /** The indexable object that [index] was not a valid index into. */
  final indexable;
  /** The invalid index. */
  final int invalidValue;
  /** The length of [indexable] at the time of the error. */
  final int length;

  /**
   * Creates a new [IndexError] stating that [invalidValue] is not a valid index
   * into [indexable].
   *
   * The [length] is the length of [indexable] at the time of the error.
   * If `length` is omitted, it defaults to `indexable.length`.
   *
   * The message is used as part of the string representation of the error.
   */
  IndexError(this.invalidValue, indexable,
             [String message = "Index out of range", int length])
      : this.indexable = indexable,
        this.length = (length != null) ? length : indexable.length,
        super(message);

  // Getters inherited from RangeError.
  int get start => 0;
  int get end => length - 1;

  String toString() {
    String target = Error.safeToString(indexable);
    if (invalidValue < 0) {
      return "RangeError: $message ($target[$invalidValue]): "
             "index must not be negative.";
    }
    return "RangeError: $message: ($target[$invalidValue]): "
           "index should be less than $length.";
  }
}


/**
 * Error thrown when control reaches the end of a switch case.
 *
 * The Dart specification requires this error to be thrown when
 * control reaches the end of a switch case (except the last case
 * of a switch) without meeting a break or similar end of the control
 * flow.
 */
class FallThroughError extends Error {
  FallThroughError();
}

/**
 * Error thrown when trying to instantiate an abstract class.
 */
class AbstractClassInstantiationError extends Error {
  final String _className;
  AbstractClassInstantiationError(String this._className);
  String toString() => "Cannot instantiate abstract class: '$_className'";
}


/**
 * Error thrown by the default implementation of [:noSuchMethod:] on [Object].
 */
class NoSuchMethodError extends Error {
  final Object _receiver;
  final Symbol _memberName;
  final List _arguments;
  final Map<Symbol, dynamic> _namedArguments;
  final List _existingArgumentNames;

  /**
   * Create a [NoSuchMethodError] corresponding to a failed method call.
   *
   * The [receiver] is the receiver of the method call.
   * That is, the object on which the method was attempted called.
   * If the receiver is `null`, it is interpreted as a call to a top-level
   * function of a library.
   *
   * The [memberName] is a [Symbol] representing the name of the called method
   * or accessor. It should not be `null`.
   *
   * The [positionalArguments] is a list of the positional arguments that the
   * method was called with. If `null`, it is considered equivalent to the
   * empty list.
   *
   * The [namedArguments] is a map from [Symbol]s to the values of named
   * arguments that the method was called with.
   *
   * The optional [exisitingArgumentNames] is the expected parameters of a
   * method with the same name on the receiver, if available. This is
   * the signature of the method that would have been called if the parameters
   * had matched.
   */
  NoSuchMethodError(Object receiver,
                    Symbol memberName,
                    List positionalArguments,
                    Map<Symbol ,dynamic> namedArguments,
                    [List existingArgumentNames = null])
      : _receiver = receiver,
        _memberName = memberName,
        _arguments = positionalArguments,
        _namedArguments = namedArguments,
        _existingArgumentNames = existingArgumentNames;

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
class UnimplementedError extends Error implements UnsupportedError {
  final String message;
  UnimplementedError([String this.message]);
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
  String toString() => "Out of Memory";

  StackTrace get stackTrace => null;
}


class StackOverflowError implements Error {
  const StackOverflowError();
  String toString() => "Stack Overflow";

  StackTrace get stackTrace => null;
}

/**
 * Error thrown when a lazily initialized variable cannot be initialized.
 *
 * A static/library variable with an initializer expression is initialized
 * the first time it is read. If evaluating the initializer expression causes
 * another read of the variable, this error is thrown.
 */
class CyclicInitializationError extends Error {
  final String variableName;
  CyclicInitializationError([this.variableName]);
  String toString() => variableName == null
      ? "Reading static variable during its initialization"
      : "Reading static variable '$variableName' during its initialization";
}
