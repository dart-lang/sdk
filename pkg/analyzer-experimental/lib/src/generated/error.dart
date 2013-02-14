// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.error;

import 'java_core.dart';
import 'source.dart';

/**
 * Instances of the enumeration {@code ErrorType} represent the type of an {@link ErrorCode}.
 */
class ErrorType {
  /**
   * Compile-time errors are errors that preclude execution. A compile time error must be reported
   * by a Dart compiler before the erroneous code is executed.
   */
  static final ErrorType COMPILE_TIME_ERROR = new ErrorType('COMPILE_TIME_ERROR', 0, ErrorSeverity.ERROR);
  /**
   * Static warnings are those warnings reported by the static checker. They have no effect on
   * execution. Static warnings must be provided by Dart compilers used during development.
   */
  static final ErrorType STATIC_WARNING = new ErrorType('STATIC_WARNING', 1, ErrorSeverity.WARNING);
  /**
   * Many, but not all, static warnings relate to types, in which case they are known as static type
   * warnings.
   */
  static final ErrorType STATIC_TYPE_WARNING = new ErrorType('STATIC_TYPE_WARNING', 2, ErrorSeverity.WARNING);
  /**
   * Syntactic errors are errors produced as a result of input that does not conform to the grammar.
   */
  static final ErrorType SYNTACTIC_ERROR = new ErrorType('SYNTACTIC_ERROR', 3, ErrorSeverity.ERROR);
  static final List<ErrorType> values = [COMPILE_TIME_ERROR, STATIC_WARNING, STATIC_TYPE_WARNING, SYNTACTIC_ERROR];
  final String __name;
  final int __ordinal;
  /**
   * The severity of this type of error.
   */
  ErrorSeverity _severity;
  /**
   * Initialize a newly created error type to have the given severity.
   * @param severity the severity of this type of error
   */
  ErrorType(this.__name, this.__ordinal, ErrorSeverity severity) {
    this._severity = severity;
  }
  /**
   * Return the severity of this type of error.
   * @return the severity of this type of error
   */
  ErrorSeverity get severity => _severity;
  String toString() => __name;
}
/**
 * The interface {@code ErrorCode} defines the behavior common to objects representing error codes
 * associated with {@link AnalysisError analysis errors}.
 */
abstract class ErrorCode {
  /**
   * Return the severity of this error.
   * @return the severity of this error
   */
  ErrorSeverity get errorSeverity;
  /**
   * Return the message template used to create the message to be displayed for this error.
   * @return the message template used to create the message to be displayed for this error
   */
  String get message;
  /**
   * Return the type of the error.
   * @return the type of the error
   */
  ErrorType get type;
  /**
   * Return {@code true} if this error should cause recompilation of the source during the next
   * incremental compilation.
   * @return {@code true} if this error should cause recompilation of the source during the next
   * incremental compilation
   */
  bool needsRecompilation();
}
/**
 * Instances of the enumeration {@code ErrorSeverity} represent the severity of an {@link ErrorCode}.
 */
class ErrorSeverity {
  /**
   * The severity representing an error.
   */
  static final ErrorSeverity ERROR = new ErrorSeverity('ERROR', 0, "E");
  /**
   * The severity representing a warning. Warnings can become errors if the {@code -Werror} command
   * line flag is specified.
   */
  static final ErrorSeverity WARNING = new ErrorSeverity('WARNING', 1, "W");
  static final List<ErrorSeverity> values = [ERROR, WARNING];
  final String __name;
  final int __ordinal;
  String _name;
  ErrorSeverity(this.__name, this.__ordinal, String name) {
    this._name = name;
  }
  String get name => _name;
  String toString() => __name;
}
/**
 * The interface {@code AnalysisErrorListener} defines the behavior of objects that listen for{@link AnalysisError analysis errors} being produced by the analysis engine.
 */
abstract class AnalysisErrorListener {
  /**
   * This method is invoked when an error has been found by the analysis engine.
   * @param error the error that was just found (not {@code null})
   */
  void onError(AnalysisError error);
}
/**
 * Instances of the class {@code AnalysisError} represent an error discovered during the analysis of
 * some Dart code.
 * @see AnalysisErrorListener
 */
class AnalysisError {
  /**
   * An empty array of errors used when no errors are expected.
   */
  static List<AnalysisError> NO_ERRORS = new List<AnalysisError>.fixedLength(0);
  /**
   * The error code associated with the error.
   */
  ErrorCode _errorCode;
  /**
   * The localized error message.
   */
  String _message;
  /**
   * The source in which the error occurred, or {@code null} if unknown.
   */
  Source _source;
  /**
   * The character offset from the beginning of the source (zero based) where the error occurred.
   */
  int _offset = 0;
  /**
   * The number of characters from the offset to the end of the source which encompasses the
   * compilation error.
   */
  int _length = 0;
  /**
   * Initialize a newly created analysis error for the specified source. The error has no location
   * information.
   * @param source the source for which the exception occurred
   * @param errorCode the error code to be associated with this error
   * @param arguments the arguments used to build the error message
   */
  AnalysisError.con1(Source source2, ErrorCode errorCode2, List<Object> arguments) {
    _jtd_constructor_122_impl(source2, errorCode2, arguments);
  }
  _jtd_constructor_122_impl(Source source2, ErrorCode errorCode2, List<Object> arguments) {
    this._source = source2;
    this._errorCode = errorCode2;
    this._message = JavaString.format(errorCode2.message, arguments);
  }
  /**
   * Initialize a newly created analysis error for the specified source at the given location.
   * @param source the source for which the exception occurred
   * @param offset the offset of the location of the error
   * @param length the length of the location of the error
   * @param errorCode the error code to be associated with this error
   * @param arguments the arguments used to build the error message
   */
  AnalysisError.con2(Source source3, int offset2, int length11, ErrorCode errorCode3, List<Object> arguments) {
    _jtd_constructor_123_impl(source3, offset2, length11, errorCode3, arguments);
  }
  _jtd_constructor_123_impl(Source source3, int offset2, int length11, ErrorCode errorCode3, List<Object> arguments) {
    this._source = source3;
    this._offset = offset2;
    this._length = length11;
    this._errorCode = errorCode3;
    this._message = JavaString.format(errorCode3.message, arguments);
  }
  /**
   * Return the error code associated with the error.
   * @return the error code associated with the error
   */
  ErrorCode get errorCode => _errorCode;
  /**
   * Return the number of characters from the offset to the end of the source which encompasses the
   * compilation error.
   * @return the length of the error location
   */
  int get length => _length;
  /**
   * Return the localized error message.
   * @return the localized error message
   */
  String get message => _message;
  /**
   * Return the character offset from the beginning of the source (zero based) where the error
   * occurred.
   * @return the offset to the start of the error location
   */
  int get offset => _offset;
  /**
   * Return the source in which the error occurred, or {@code null} if unknown.
   * @return the source in which the error occurred
   */
  Source get source => _source;
  int get hashCode {
    int hashCode = _offset;
    hashCode ^= (_message != null) ? _message.hashCode : 0;
    hashCode ^= (_source != null) ? _source.hashCode : 0;
    return hashCode;
  }
  /**
   * Set the source in which the error occurred to the given source.
   * @param source the source in which the error occurred
   */
  void set source(Source source4) {
    this._source = source4;
  }
  String toString() {
    StringBuffer builder = new StringBuffer();
    builder.add((_source != null) ? _source.fullName : "<unknown source>");
    builder.add("(");
    builder.add(_offset);
    builder.add("..");
    builder.add(_offset + _length - 1);
    builder.add("): ");
    builder.add(_message);
    return builder.toString();
  }
}