part of dart.core;
 class Error {Error();
 static String safeToString(Object object) {
  if (object is num || object is bool || null == object) {
    return object.toString();
    }
   if (object is String) {
    return _stringToSafeString(object);
    }
   return _objectToString(object);
  }
 external static String _stringToSafeString(String string);
 external static String _objectToString(Object object);
 external StackTrace get stackTrace;
}
 class AssertionError extends Error {}
 class TypeError extends AssertionError {}
 class CastError extends Error {}
 class NullThrownError extends Error {String toString() => "Throw of null.";
}
 class ArgumentError extends Error {final bool _hasValue;
 final invalidValue;
 final String name;
 final message;
 ArgumentError([this.message]) : invalidValue = null, _hasValue = false, name = null;
 ArgumentError.value(value, [String this.name, String this.message = "Invalid argument"]) : invalidValue = value, _hasValue = true;
 ArgumentError.notNull([String name]) : this.value(null, name, "Must not be null");
 String toString() {
if (!_hasValue) {
var result = "Invalid arguments(s)";
 if (message != null) {
result = "$result: $message";
}
 return result;
}
 String nameString = "";
 if (name != null) {
nameString = " ($name)";
}
 return "$message$nameString: ${Error.safeToString(invalidValue)}";
}
}
 class RangeError extends ArgumentError {final num start;
 final num end;
 RangeError(var message) : start = null, end = null, super(message);
 RangeError.value(num value, [String name, String message]) : start = null, end = null, super.value(value, name, (message != null) ? message : "Value not in range");
 RangeError.range(num invalidValue, int minValue, int maxValue, [String name, String message]) : start = minValue, end = maxValue, super.value(invalidValue, name, (message != null) ? message : "Invalid value");
 factory RangeError.index(int index, indexable, [String name, String message, int length]) = IndexError;
 static void checkValueInInterval(int value, int minValue, int maxValue, [String name, String message]) {
if (value < minValue || value > maxValue) {
throw new RangeError.range(value, minValue, maxValue, name, message);
}
}
 static void checkValidIndex(int index, var indexable, [String name, int length, String message]) {
if (length == null) length = DDC$RT.cast(indexable.length, dynamic, int, "CastGeneral", """line 281, column 34 of dart:core/errors.dart: """, indexable.length is int, true);
 if (index < 0 || index >= length) {
if (name == null) name = "index";
 throw new RangeError.index(index, indexable, name, message, length);
}
}
 static void checkValidRange(int start, int end, int length, [String startName, String endName, String message]) {
if (start < 0 || start > length) {
if (startName == null) startName = "start";
 throw new RangeError.range(start, 0, length, startName, message);
}
 if (end != null && (end < start || end > length)) {
if (endName == null) endName = "end";
 throw new RangeError.range(end, start, length, endName, message);
}
}
 static void checkNotNegative(int value, [String name, String message]) {
if (value < 0) throw new RangeError.range(value, 0, null, name, message);
}
 String toString() {
if (!_hasValue) return "RangeError: $message";
 String value = Error.safeToString(invalidValue);
 String explanation = "";
 if (start == null) {
if (end != null) {
explanation = ": Not less than or equal to $end";
}
}
 else if (end == null) {
explanation = ": Not greater than or equal to $start";
}
 else if (end > start) {
explanation = ": Not in range $start..$end, inclusive.";
}
 else if (end < start) {
explanation = ": Valid value range is empty";
}
 else {
explanation = ": Only valid value is $start";
}
 return "RangeError: $message ($value)$explanation";
}
}
 class IndexError extends ArgumentError implements RangeError {final indexable;
 final int length;
 IndexError(int invalidValue, indexable, [String name, String message, int length]) : this.indexable = indexable, this.length = ((__x3) => DDC$RT.cast(__x3, dynamic, int, "CastGeneral", """line 371, column 23 of dart:core/errors.dart: """, __x3 is int, true))((length != null) ? length : indexable.length), super.value(invalidValue, name, (message != null) ? message : "Index out of range");
 int get start => 0;
 int get end => length - 1;
 String toString() {
assert (_hasValue); String target = Error.safeToString(indexable);
 var explanation = "index should be less than $length";
 if (invalidValue < 0) {
explanation = "index must not be negative";
}
 return "RangeError: $message ($target[$invalidValue]): $explanation";
}
}
 class FallThroughError extends Error {FallThroughError();
}
 class AbstractClassInstantiationError extends Error {final String _className;
 AbstractClassInstantiationError(String this._className);
 String toString() => "Cannot instantiate abstract class: '$_className'";
}
 class NoSuchMethodError extends Error {final Object _receiver;
 final Symbol _memberName;
 final List _arguments;
 final Map<Symbol, dynamic> _namedArguments;
 final List _existingArgumentNames;
 NoSuchMethodError(Object receiver, Symbol memberName, List positionalArguments, Map<Symbol, dynamic> namedArguments, [List existingArgumentNames = null]) : _receiver = receiver, _memberName = memberName, _arguments = positionalArguments, _namedArguments = namedArguments, _existingArgumentNames = existingArgumentNames;
 external String toString();
}
 class UnsupportedError extends Error {final String message;
 UnsupportedError(this.message);
 String toString() => "Unsupported operation: $message";
}
 class UnimplementedError extends Error implements UnsupportedError {final String message;
 UnimplementedError([String this.message]);
 String toString() => (this.message != null ? "UnimplementedError: $message" : "UnimplementedError");
}
 class StateError extends Error {final String message;
 StateError(this.message);
 String toString() => "Bad state: $message";
}
 class ConcurrentModificationError extends Error {final Object modifiedObject;
 ConcurrentModificationError([this.modifiedObject]);
 String toString() {
if (modifiedObject == null) {
return "Concurrent modification during iteration.";
}
 return "Concurrent modification during iteration: " "${Error.safeToString(modifiedObject)}.";
}
}
 class OutOfMemoryError implements Error {const OutOfMemoryError();
 String toString() => "Out of Memory";
 StackTrace get stackTrace => null;
}
 class StackOverflowError implements Error {const StackOverflowError();
 String toString() => "Stack Overflow";
 StackTrace get stackTrace => null;
}
 class CyclicInitializationError extends Error {final String variableName;
 CyclicInitializationError([this.variableName]);
 String toString() => variableName == null ? "Reading static variable during its initialization" : "Reading static variable '$variableName' during its initialization";
}
