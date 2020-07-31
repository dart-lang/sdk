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
  Error(); // Prevent use as mixin.

  /**
   * Safely convert a value to a [String] description.
   *
   * The conversion is guaranteed to not throw, so it won't use the object's
   * toString method.
   */
  static String safeToString(Object? object) {
    if (object is num || object is bool || null == object) {
      return object.toString();
    }
    if (object is String) {
      return _stringToSafeString(object);
    }
    return _objectToString(object);
  }

  /** Convert string to a valid string literal with no control characters. */
  external static String _stringToSafeString(String string);

  external static String _objectToString(Object object);

  external StackTrace? get stackTrace;
}

/**
 * Error thrown by the runtime system when an assert statement fails.
 */
class AssertionError extends Error {
  /** Message describing the assertion error. */
  final Object? message;

  AssertionError([this.message]);

  String toString() {
    if (message != null) {
      return "Assertion failed: ${Error.safeToString(message)}";
    }
    return "Assertion failed";
  }
}

/**
 * Error thrown by the runtime system when a dynamic type error happens.
 */
class TypeError extends Error {}

/**
 * Error thrown by the runtime system when a cast operation fails.
 */
@Deprecated("Use TypeError instead")
class CastError extends Error {}

/**
 * Error thrown when attempting to throw `null`.
 */
class NullThrownError extends Error {
  @pragma("vm:entry-point")
  NullThrownError();
  String toString() => "Throw of null.";
}

/**
 * Error thrown when a function is passed an unacceptable argument.
 */
class ArgumentError extends Error {
  /** Whether value was provided. */
  final bool _hasValue;
  /** The invalid value. */
  final dynamic invalidValue;
  /** Name of the invalid argument, if available. */
  final String? name;
  /** Message describing the problem. */
  final dynamic message;

  /**
   * The [message] describes the erroneous argument.
   *
   * Existing code may be using `message` to hold the invalid value.
   * If the `message` is not a [String], it is assumed to be a value instead
   * of a message.
   */
  @pragma("vm:entry-point")
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
  @pragma("vm:entry-point")
  ArgumentError.value(value, [this.name, this.message])
      : invalidValue = value,
        _hasValue = true;

  /**
   * Create an argument error for a `null` argument that must not be `null`.
   */
  ArgumentError.notNull([this.name])
      : _hasValue = false,
        message = "Must not be null",
        invalidValue = null;

  /**
   * Throws if [argument] is `null`.
   *
   * If [name] is supplied, it is used as the parameter name
   * in the error message.
   *
   * Returns the [argument] if it is not null.
   */
  @Since("2.1")
  static T checkNotNull<@Since("2.8") T>(T? argument, [String? name]) {
    if (argument == null) throw ArgumentError.notNull(name);
    return argument;
  }

  // Helper functions for toString overridden in subclasses.
  String get _errorName => "Invalid argument${!_hasValue ? "(s)" : ""}";
  String get _errorExplanation => "";

  String toString() {
    String? name = this.name;
    String nameString = (name == null) ? "" : " ($name)";
    Object? message = this.message;
    var messageString = (message == null) ? "" : ": ${message}";
    String prefix = "$_errorName$nameString$messageString";
    if (!_hasValue) return prefix;
    // If we know the invalid value, we can try to describe the problem.
    String explanation = _errorExplanation;
    String errorValue = Error.safeToString(invalidValue);
    return "$prefix$explanation: $errorValue";
  }
}

/**
 * Error thrown due to an index being outside a valid range.
 */
class RangeError extends ArgumentError {
  /** The minimum value that [value] is allowed to assume. */
  final num? start;
  /** The maximum value that [value] is allowed to assume. */
  final num? end;

  // TODO(lrn): This constructor should be called only with string values.
  // It currently isn't in all cases.
  /**
   * Create a new [RangeError] with the given [message].
   */
  @pragma("vm:entry-point")
  RangeError(var message)
      : start = null,
        end = null,
        super(message);

  /**
   * Create a new [RangeError] with a message for the given [value].
   *
   * An optional [name] can specify the argument name that has the
   * invalid value, and the [message] can override the default error
   * description.
   */
  RangeError.value(num value, [String? name, String? message])
      : start = null,
        end = null,
        super.value(value, name, message ?? "Value not in range");

  /**
   * Create a new [RangeError] for a value being outside the valid range.
   *
   * The allowed range is from [minValue] to [maxValue], inclusive.
   * If `minValue` or `maxValue` are `null`, the range is infinite in
   * that direction.
   *
   * For a range from 0 to the length of something, end exclusive, use
   * [RangeError.index].
   *
   * An optional [name] can specify the argument name that has the
   * invalid value, and the [message] can override the default error
   * description.
   */
  @pragma("vm:entry-point")
  RangeError.range(num invalidValue, int? minValue, int? maxValue,
      [String? name, String? message])
      : start = minValue,
        end = maxValue,
        super.value(invalidValue, name, message ?? "Invalid value");

  /**
   * Creates a new [RangeError] stating that [index] is not a valid index
   * into [indexable].
   *
   * An optional [name] can specify the argument name that has the
   * invalid value, and the [message] can override the default error
   * description.
   *
   * The [length] is the length of [indexable] at the time of the error.
   * If `length` is omitted, it defaults to `indexable.length`.
   */
  factory RangeError.index(int index, dynamic indexable,
      [String? name, String? message, int? length]) = IndexError;

  /**
   * Check that an integer [value] lies in a specific interval.
   *
   * Throws if [value] is not in the interval.
   * The interval is from [minValue] to [maxValue], both inclusive.
   *
   * If [name] or [message] are provided, they are used as the parameter
   * name and message text of the thrown error.
   *
   * Returns [value] if it is in the interval.
   */
  static int checkValueInInterval(int value, int minValue, int maxValue,
      [String? name, String? message]) {
    if (value < minValue || value > maxValue) {
      throw RangeError.range(value, minValue, maxValue, name, message);
    }
    return value;
  }

  /**
   * Check that [index] is a valid index into an indexable object.
   *
   * Throws if [index] is not a valid index into [indexable].
   *
   * An indexable object is one that has a `length` and a and index-operator
   * `[]` that accepts an index if `0 <= index < length`.
   *
   * If [name] or [message] are provided, they are used as the parameter
   * name and message text of the thrown error. If [name] is omitted, it
   * defaults to `"index"`.
   *
   * If [length] is provided, it is used as the length of the indexable object,
   * otherwise the length is found as `indexable.length`.
   *
   * Returns [index] if it is a valid index.
   */
  static int checkValidIndex(int index, dynamic indexable,
      [String? name, int? length, String? message]) {
    length ??= (indexable.length as int);
    // Comparing with `0` as receiver produces better dart2js type inference.
    if (0 > index || index >= length) {
      name ??= "index";
      throw RangeError.index(index, indexable, name, message, length);
    }
    return index;
  }

  /**
   * Check that a range represents a slice of an indexable object.
   *
   * Throws if the range is not valid for an indexable object with
   * the given [length].
   * A range is valid for an indexable object with a given [length]
   *
   * if `0 <= [start] <= [end] <= [length]`.
   * An `end` of `null` is considered equivalent to `length`.
   *
   * The [startName] and [endName] defaults to `"start"` and `"end"`,
   * respectively.
   *
   * Returns the actual `end` value, which is `length` if `end` is `null`,
   * and `end` otherwise.
   */
  static int checkValidRange(int start, int? end, int length,
      [String? startName, String? endName, String? message]) {
    // Comparing with `0` as receiver produces better dart2js type inference.
    // Ditto `start > end` below.
    if (0 > start || start > length) {
      startName ??= "start";
      throw RangeError.range(start, 0, length, startName, message);
    }
    if (end != null) {
      if (start > end || end > length) {
        endName ??= "end";
        throw RangeError.range(end, start, length, endName, message);
      }
      return end;
    }
    return length;
  }

  /**
   * Check that an integer value is non-negative.
   *
   * Throws if the value is negative.
   *
   * If [name] or [message] are provided, they are used as the parameter
   * name and message text of the thrown error. If [name] is omitted, it
   * defaults to `index`.
   *
   * Returns [value] if it is not negative.
   */
  static int checkNotNegative(int value, [String? name, String? message]) {
    if (value < 0) throw RangeError.range(value, 0, null, name, message);
    return value;
  }

  String get _errorName => "RangeError";
  String get _errorExplanation {
    assert(_hasValue);
    String explanation = "";
    num? start = this.start;
    num? end = this.end;
    if (start == null) {
      if (end != null) {
        explanation = ": Not less than or equal to $end";
      }
      // If both are null, we don't add a description of the limits.
    } else if (end == null) {
      explanation = ": Not greater than or equal to $start";
    } else if (end > start) {
      explanation = ": Not in inclusive range $start..$end";
    } else if (end < start) {
      explanation = ": Valid value range is empty";
    } else {
      // end == start.
      explanation = ": Only valid value is $start";
    }
    return explanation;
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
  /** The indexable object that [invalidValue] was not a valid index into. */
  final indexable;
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
  IndexError(int invalidValue, dynamic indexable,
      [String? name, String? message, int? length])
      : this.indexable = indexable,
        this.length = length ?? indexable.length,
        super.value(invalidValue, name, message ?? "Index out of range");

  // Getters inherited from RangeError.
  int get start => 0;
  int get end => length - 1;

  String get _errorName => "RangeError";
  String get _errorExplanation {
    assert(_hasValue);
    int invalidValue = this.invalidValue;
    if (invalidValue < 0) {
      return ": index must not be negative";
    }
    if (length == 0) {
      return ": no indices are valid";
    }
    return ": index should be less than $length";
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
  @pragma("vm:entry-point")
  external FallThroughError._create(String url, int line);

  external String toString();
}

/**
 * Error thrown when trying to instantiate an abstract class.
 */
class AbstractClassInstantiationError extends Error {
  final String _className;
  AbstractClassInstantiationError(String className) : _className = className;

  external String toString();
}

/**
 * Error thrown by the default implementation of [:noSuchMethod:] on [Object].
 */
class NoSuchMethodError extends Error {
  /**
   * Create a [NoSuchMethodError] corresponding to a failed method call.
   *
   * The [receiver] is the receiver of the method call.
   * That is, the object on which the method was attempted called.
   *
   * The [invocation] represents the method call that failed. It
   * should not be `null`.
   */
  external NoSuchMethodError.withInvocation(
      Object? receiver, Invocation invocation);

  // Deprecated constructor to be removed after dart2js updates to the above.
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
   * arguments that the method was called with. If null, it is considered
   * equivalent to the empty map.
   *
   * This constructor does not handle type arguments.
   * To include type variables, create an [Invocation] and use
   * [NoSuchMethodError.withInvocation].
   */
  @Deprecated("Use NoSuchMethod.withInvocation instead")
  external NoSuchMethodError(Object? receiver, Symbol memberName,
      List? positionalArguments, Map<Symbol, dynamic>? namedArguments);

  external String toString();
}

/**
 * The operation was not allowed by the object.
 *
 * This [Error] is thrown when an instance cannot implement one of the methods
 * in its signature.
 */
@pragma("vm:entry-point")
class UnsupportedError extends Error {
  final String? message;
  @pragma("vm:entry-point")
  UnsupportedError(String this.message);
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
  final String? message;
  UnimplementedError([this.message]);
  String toString() {
    var message = this.message;
    return (message != null)
        ? "UnimplementedError: $message"
        : "UnimplementedError";
  }
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
  final Object? modifiedObject;

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
  @pragma("vm:entry-point")
  const OutOfMemoryError();
  String toString() => "Out of Memory";

  StackTrace? get stackTrace => null;
}

class StackOverflowError implements Error {
  @pragma("vm:entry-point")
  const StackOverflowError();
  String toString() => "Stack Overflow";

  StackTrace? get stackTrace => null;
}

/**
 * Error thrown when a lazily initialized variable cannot be initialized.
 *
 * A static/library variable with an initializer expression is initialized
 * the first time it is read. If evaluating the initializer expression causes
 * another read of the variable, this error is thrown.
 */
class CyclicInitializationError extends Error {
  final String? variableName;
  @pragma("vm:entry-point")
  CyclicInitializationError([this.variableName]);
  String toString() {
    var variableName = this.variableName;
    return variableName == null
        ? "Reading static variable during its initialization"
        : "Reading static variable '$variableName' during its initialization";
  }
}

/**
 * Error thrown when a late variable is accessed in an invalid manner.
 *
 * A late variable must be initialized before it's read.
 * If a late variable has no initializer expression and has not
 * been written to, then reading it will throw a
 * late initialization error.
 *
 * A late final variable with no initializer expression may only
 * be written to once.
 * If it is written to again, the writing will throw a
 * late initialization error.
 */
abstract class LateInitializationError extends Error {
  factory LateInitializationError._() => throw UnsupportedError("");
}
