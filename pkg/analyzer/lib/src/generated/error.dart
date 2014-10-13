// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.error;

import 'dart:collection';
import 'java_core.dart';
import 'source.dart';
import 'scanner.dart' show Token;
import 'ast.dart' show AstNode;
import 'element.dart';

/**
 * Instances of the class `AnalysisError` represent an error discovered during the analysis of
 * some Dart code.
 *
 * @see AnalysisErrorListener
 */
class AnalysisError {
  /**
   * An empty array of errors used when no errors are expected.
   */
  static List<AnalysisError> NO_ERRORS = new List<AnalysisError>(0);

  /**
   * A [Comparator] that sorts by the name of the file that the [AnalysisError] was
   * found.
   */
  static Comparator<AnalysisError> FILE_COMPARATOR = (AnalysisError o1, AnalysisError o2) => o1.source.shortName.compareTo(o2.source.shortName);

  /**
   * A [Comparator] that sorts error codes first by their severity (errors first, warnings
   * second), and then by the the error code type.
   */
  static Comparator<AnalysisError> ERROR_CODE_COMPARATOR = (AnalysisError o1, AnalysisError o2) {
    ErrorCode errorCode1 = o1.errorCode;
    ErrorCode errorCode2 = o2.errorCode;
    ErrorSeverity errorSeverity1 = errorCode1.errorSeverity;
    ErrorSeverity errorSeverity2 = errorCode2.errorSeverity;
    ErrorType errorType1 = errorCode1.type;
    ErrorType errorType2 = errorCode2.type;
    if (errorSeverity1 == errorSeverity2) {
      return errorType1.compareTo(errorType2);
    } else {
      return errorSeverity2.compareTo(errorSeverity1);
    }
  };

  /**
   * The error code associated with the error.
   */
  final ErrorCode errorCode;

  /**
   * The localized error message.
   */
  String _message;

  /**
   * The correction to be displayed for this error, or `null` if there is no correction
   * information for this error.
   */
  String _correction;

  /**
   * The source in which the error occurred, or `null` if unknown.
   */
  Source source;

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
   * A flag indicating whether this error can be shown to be a non-issue because of the result of
   * type propagation.
   */
  bool isStaticOnly = false;

  /**
   * Initialize a newly created analysis error for the specified source. The error has no location
   * information.
   *
   * @param source the source for which the exception occurred
   * @param errorCode the error code to be associated with this error
   * @param arguments the arguments used to build the error message
   */
  AnalysisError.con1(this.source, this.errorCode, List<Object> arguments) {
    this._message = formatList(errorCode.message, arguments);
  }

  /**
   * Initialize a newly created analysis error for the specified source at the given location.
   *
   * @param source the source for which the exception occurred
   * @param offset the offset of the location of the error
   * @param length the length of the location of the error
   * @param errorCode the error code to be associated with this error
   * @param arguments the arguments used to build the error message
   */
  AnalysisError.con2(this.source, int offset, int length, this.errorCode, List<Object> arguments) {
    this._offset = offset;
    this._length = length;
    this._message = formatList(errorCode.message, arguments);
    String correctionTemplate = errorCode.correction;
    if (correctionTemplate != null) {
      this._correction = formatList(correctionTemplate, arguments);
    }
  }

  @override
  bool operator ==(Object obj) {
    if (identical(obj, this)) {
      return true;
    }
    // prepare other AnalysisError
    if (obj is! AnalysisError) {
      return false;
    }
    AnalysisError other = obj as AnalysisError;
    // Quick checks.
    if (!identical(errorCode, other.errorCode)) {
      return false;
    }
    if (_offset != other._offset || _length != other._length) {
      return false;
    }
    if (isStaticOnly != other.isStaticOnly) {
      return false;
    }
    // Deep checks.
    if (_message != other._message) {
      return false;
    }
    if (source != other.source) {
      return false;
    }
    // OK
    return true;
  }

  /**
   * Return the correction to be displayed for this error, or `null` if there is no correction
   * information for this error. The correction should indicate how the user can fix the error.
   *
   * @return the template used to create the correction to be displayed for this error
   */
  String get correction => _correction;

  /**
   * Return the number of characters from the offset to the end of the source which encompasses the
   * compilation error.
   *
   * @return the length of the error location
   */
  int get length => _length;

  /**
   * Return the message to be displayed for this error. The message should indicate what is wrong
   * and why it is wrong.
   *
   * @return the message to be displayed for this error
   */
  String get message => _message;

  /**
   * Return the character offset from the beginning of the source (zero based) where the error
   * occurred.
   *
   * @return the offset to the start of the error location
   */
  int get offset => _offset;

  /**
   * Return the value of the given property, or `null` if the given property is not defined
   * for this error.
   *
   * @param property the property whose value is to be returned
   * @return the value of the given property
   */
  Object getProperty(ErrorProperty property) => null;

  @override
  int get hashCode {
    int hashCode = _offset;
    hashCode ^= (_message != null) ? _message.hashCode : 0;
    hashCode ^= (source != null) ? source.hashCode : 0;
    return hashCode;
  }

  @override
  String toString() {
    JavaStringBuilder builder = new JavaStringBuilder();
    builder.append((source != null) ? source.fullName : "<unknown source>");
    builder.append("(");
    builder.append(_offset);
    builder.append("..");
    builder.append(_offset + _length - 1);
    builder.append("): ");
    //builder.append("(" + lineNumber + ":" + columnNumber + "): ");
    builder.append(_message);
    return builder.toString();
  }
}

/**
 * The interface `AnalysisErrorListener` defines the behavior of objects that listen for
 * [AnalysisError] being produced by the analysis engine.
 */
abstract class AnalysisErrorListener {
  /**
   * An error listener that ignores errors that are reported to it.
   */
  static final AnalysisErrorListener NULL_LISTENER = new AnalysisErrorListener_NULL_LISTENER();

  /**
   * This method is invoked when an error has been found by the analysis engine.
   *
   * @param error the error that was just found (not `null`)
   */
  void onError(AnalysisError error);
}

class AnalysisErrorListener_NULL_LISTENER implements AnalysisErrorListener {
  @override
  void onError(AnalysisError event) {
    // Ignore errors
  }
}

/**
 * Instances of the class `AnalysisErrorWithProperties`
 */
class AnalysisErrorWithProperties extends AnalysisError {
  /**
   * The properties associated with this error.
   */
  HashMap<ErrorProperty, Object> _propertyMap = new HashMap<ErrorProperty, Object>();

  /**
   * Initialize a newly created analysis error for the specified source. The error has no location
   * information.
   *
   * @param source the source for which the exception occurred
   * @param errorCode the error code to be associated with this error
   * @param arguments the arguments used to build the error message
   */
  AnalysisErrorWithProperties.con1(Source source, ErrorCode errorCode, List<Object> arguments) : super.con1(source, errorCode, arguments);

  /**
   * Initialize a newly created analysis error for the specified source at the given location.
   *
   * @param source the source for which the exception occurred
   * @param offset the offset of the location of the error
   * @param length the length of the location of the error
   * @param errorCode the error code to be associated with this error
   * @param arguments the arguments used to build the error message
   */
  AnalysisErrorWithProperties.con2(Source source, int offset, int length, ErrorCode errorCode, List<Object> arguments) : super.con2(source, offset, length, errorCode, arguments);

  @override
  Object getProperty(ErrorProperty property) => _propertyMap[property];

  /**
   * Set the value of the given property to the given value. Using a value of `null` will
   * effectively remove the property from this error.
   *
   * @param property the property whose value is to be returned
   * @param value the new value of the given property
   */
  void setProperty(ErrorProperty property, Object value) {
    _propertyMap[property] = value;
  }
}

/**
 * The enumeration `AngularCode` defines Angular specific problems.
 */
class AngularCode extends Enum<AngularCode> implements ErrorCode {
  static const AngularCode CANNOT_PARSE_SELECTOR = const AngularCode('CANNOT_PARSE_SELECTOR', 0, "The selector '{0}' cannot be parsed");

  static const AngularCode INVALID_FORMATTER_NAME = const AngularCode('INVALID_FORMATTER_NAME', 1, "Formatter name must be a simple identifier");

  static const AngularCode INVALID_PROPERTY_KIND = const AngularCode('INVALID_PROPERTY_KIND', 2, "Unknown property binding kind '{0}', use one of the '@', '=>', '=>!' or '<=>'");

  static const AngularCode INVALID_PROPERTY_FIELD = const AngularCode('INVALID_PROPERTY_FIELD', 3, "Unknown property field '{0}'");

  static const AngularCode INVALID_PROPERTY_MAP = const AngularCode('INVALID_PROPERTY_MAP', 4, "Argument 'map' must be a constant map literal");

  static const AngularCode INVALID_PROPERTY_NAME = const AngularCode('INVALID_PROPERTY_NAME', 5, "Property name must be a string literal");

  static const AngularCode INVALID_PROPERTY_SPEC = const AngularCode('INVALID_PROPERTY_SPEC', 6, "Property binding specification must be a string literal");

  static const AngularCode INVALID_REPEAT_SYNTAX = const AngularCode('INVALID_REPEAT_SYNTAX', 7, "Expected statement in form '_item_ in _collection_ [tracked by _id_]'");

  static const AngularCode INVALID_REPEAT_ITEM_SYNTAX = const AngularCode('INVALID_REPEAT_ITEM_SYNTAX', 8, "Item must by identifier or in '(_key_, _value_)' pair.");

  static const AngularCode INVALID_URI = const AngularCode('INVALID_URI', 9, "Invalid URI syntax: '{0}'");

  static const AngularCode MISSING_FORMATTER_COLON = const AngularCode('MISSING_FORMATTER_COLON', 10, "Missing ':' before formatter argument");

  static const AngularCode MISSING_NAME = const AngularCode('MISSING_NAME', 11, "Argument 'name' must be provided");

  static const AngularCode MISSING_PUBLISH_AS = const AngularCode('MISSING_PUBLISH_AS', 12, "Argument 'publishAs' must be provided");

  static const AngularCode MISSING_SELECTOR = const AngularCode('MISSING_SELECTOR', 13, "Argument 'selector' must be provided");

  static const AngularCode URI_DOES_NOT_EXIST = const AngularCode('URI_DOES_NOT_EXIST', 14, "Target of URI does not exist: '{0}'");

  static const List<AngularCode> values = const [
      CANNOT_PARSE_SELECTOR,
      INVALID_FORMATTER_NAME,
      INVALID_PROPERTY_KIND,
      INVALID_PROPERTY_FIELD,
      INVALID_PROPERTY_MAP,
      INVALID_PROPERTY_NAME,
      INVALID_PROPERTY_SPEC,
      INVALID_REPEAT_SYNTAX,
      INVALID_REPEAT_ITEM_SYNTAX,
      INVALID_URI,
      MISSING_FORMATTER_COLON,
      MISSING_NAME,
      MISSING_PUBLISH_AS,
      MISSING_SELECTOR,
      URI_DOES_NOT_EXIST];

  /**
   * The template used to create the message to be displayed for this error.
   */
  final String message;

  /**
   * Initialize a newly created error code to have the given message.
   *
   * @param message the message template used to create the message to be displayed for the error
   */
  const AngularCode(String name, int ordinal, this.message) : super(name, ordinal);

  @override
  String get correction => null;

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.INFO;

  @override
  ErrorType get type => ErrorType.ANGULAR;

  @override
  String get uniqueName => "${runtimeType.toString()}.${name}";
}

/**
 * Instances of the class `BooleanErrorListener` implement a listener that keeps track of
 * whether an error has been reported to it.
 */
class BooleanErrorListener implements AnalysisErrorListener {
  /**
   * A flag indicating whether an error has been reported to this listener.
   */
  bool _errorReported = false;

  /**
   * Return `true` if an error has been reported to this listener.
   *
   * @return `true` if an error has been reported to this listener
   */
  bool get errorReported => _errorReported;

  @override
  void onError(AnalysisError error) {
    _errorReported = true;
  }
}

/**
 * The enumeration `CompileTimeErrorCode` defines the error codes used for compile time errors
 * caused by constant evaluation that would throw an exception when run in checked mode. The client
 * of the analysis engine is responsible for determining how these errors should be presented to the
 * user (for example, a command-line compiler might elect to treat these errors differently
 * depending whether it is compiling it "checked" mode).
 */
class CheckedModeCompileTimeErrorCode extends Enum<CheckedModeCompileTimeErrorCode> implements ErrorCode {
  // TODO(paulberry): improve the text of these error messages so that it's
  // clear to the user that the error is coming from constant evaluation (and
  // hence the constant needs to be a subtype of the annotated type) as opposed
  // to static type analysis (which only requires that the two types be
  // assignable).  Also consider populating the "correction" field for these
  // errors.

  /**
   * 12.11.2 Const: It is a compile-time error if evaluation of a constant object results in an
   * uncaught exception being thrown.
   */
  static const CheckedModeCompileTimeErrorCode CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH =
      const CheckedModeCompileTimeErrorCode.con1(
          'CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH',
          0,
          "The object type '{0}' cannot be assigned to the field '{1}', which has type '{2}'");

  /**
   * 12.11.2 Const: It is a compile-time error if evaluation of a constant object results in an
   * uncaught exception being thrown.
   */
  static const CheckedModeCompileTimeErrorCode CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH =
      const CheckedModeCompileTimeErrorCode.con1(
          'CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH',
          1,
          "The object type '{0}' cannot be assigned to a parameter of type '{1}'");

  /**
   * 7.6.1 Generative Constructors: In checked mode, it is a dynamic type error if o is not
   * <b>null</b> and the interface of the class of <i>o</i> is not a subtype of the static type of
   * the field <i>v</i>.
   *
   * 12.11.2 Const: It is a compile-time error if evaluation of a constant object results in an
   * uncaught exception being thrown.
   *
   * @param initializerType the name of the type of the initializer expression
   * @param fieldType the name of the type of the field
   */
  static const CheckedModeCompileTimeErrorCode CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE = const CheckedModeCompileTimeErrorCode.con1('CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE', 2, "The initializer type '{0}' cannot be assigned to the field type '{1}'");

  /**
   * 12.6 Lists: A run-time list literal &lt;<i>E</i>&gt; [<i>e<sub>1</sub></i> ...
   * <i>e<sub>n</sub></i>] is evaluated as follows:
   * * The operator []= is invoked on <i>a</i> with first argument <i>i</i> and second argument
   * <i>o<sub>i+1</sub></i><i>, 1 &lt;= i &lt;= n</i>
   *
   * 12.14.2 Binding Actuals to Formals: Let <i>T<sub>i</sub></i> be the static type of
   * <i>a<sub>i</sub></i>, let <i>S<sub>i</sub></i> be the type of <i>p<sub>i</sub>, 1 &lt;= i &lt;=
   * n+k</i> and let <i>S<sub>q</sub></i> be the type of the named parameter <i>q</i> of <i>f</i>.
   * It is a static warning if <i>T<sub>j</sub></i> may not be assigned to <i>S<sub>j</sub>, 1 &lt;=
   * j &lt;= m</i>.
   */
  static const CheckedModeCompileTimeErrorCode LIST_ELEMENT_TYPE_NOT_ASSIGNABLE = const CheckedModeCompileTimeErrorCode.con1('LIST_ELEMENT_TYPE_NOT_ASSIGNABLE', 3, "The element type '{0}' cannot be assigned to the list type '{1}'");

  /**
   * 12.7 Map: A run-time map literal &lt;<i>K</i>, <i>V</i>&gt; [<i>k<sub>1</sub></i> :
   * <i>e<sub>1</sub></i> ... <i>k<sub>n</sub></i> : <i>e<sub>n</sub></i>] is evaluated as follows:
   * * The operator []= is invoked on <i>m</i> with first argument <i>k<sub>i</sub></i> and second
   * argument <i>e<sub>i</sub></i><i>, 1 &lt;= i &lt;= n</i>
   *
   * 12.14.2 Binding Actuals to Formals: Let <i>T<sub>i</sub></i> be the static type of
   * <i>a<sub>i</sub></i>, let <i>S<sub>i</sub></i> be the type of <i>p<sub>i</sub>, 1 &lt;= i &lt;=
   * n+k</i> and let <i>S<sub>q</sub></i> be the type of the named parameter <i>q</i> of <i>f</i>.
   * It is a static warning if <i>T<sub>j</sub></i> may not be assigned to <i>S<sub>j</sub>, 1 &lt;=
   * j &lt;= m</i>.
   */
  static const CheckedModeCompileTimeErrorCode MAP_KEY_TYPE_NOT_ASSIGNABLE = const CheckedModeCompileTimeErrorCode.con1('MAP_KEY_TYPE_NOT_ASSIGNABLE', 4, "The element type '{0}' cannot be assigned to the map key type '{1}'");

  /**
   * 12.7 Map: A run-time map literal &lt;<i>K</i>, <i>V</i>&gt; [<i>k<sub>1</sub></i> :
   * <i>e<sub>1</sub></i> ... <i>k<sub>n</sub></i> : <i>e<sub>n</sub></i>] is evaluated as follows:
   * * The operator []= is invoked on <i>m</i> with first argument <i>k<sub>i</sub></i> and second
   * argument <i>e<sub>i</sub></i><i>, 1 &lt;= i &lt;= n</i>
   *
   * 12.14.2 Binding Actuals to Formals: Let <i>T<sub>i</sub></i> be the static type of
   * <i>a<sub>i</sub></i>, let <i>S<sub>i</sub></i> be the type of <i>p<sub>i</sub>, 1 &lt;= i &lt;=
   * n+k</i> and let <i>S<sub>q</sub></i> be the type of the named parameter <i>q</i> of <i>f</i>.
   * It is a static warning if <i>T<sub>j</sub></i> may not be assigned to <i>S<sub>j</sub>, 1 &lt;=
   * j &lt;= m</i>.
   */
  static const CheckedModeCompileTimeErrorCode MAP_VALUE_TYPE_NOT_ASSIGNABLE = const CheckedModeCompileTimeErrorCode.con1('MAP_VALUE_TYPE_NOT_ASSIGNABLE', 5, "The element type '{0}' cannot be assigned to the map value type '{1}'");

  /**
   * 12.11.2 Const: It is a compile-time error if evaluation of a constant object results in an
   * uncaught exception being thrown.
   */
  static const CheckedModeCompileTimeErrorCode VARIABLE_TYPE_MISMATCH =
      const CheckedModeCompileTimeErrorCode.con1(
          'VARIABLE_TYPE_MISMATCH',
          6,
          "The object type '{0}' cannot be assigned to a variable of type '{1}'");

  static const List<CheckedModeCompileTimeErrorCode> values = const [
      CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH,
      CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
      CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE,
      LIST_ELEMENT_TYPE_NOT_ASSIGNABLE,
      MAP_KEY_TYPE_NOT_ASSIGNABLE,
      MAP_VALUE_TYPE_NOT_ASSIGNABLE,
      VARIABLE_TYPE_MISMATCH];

  /**
   * The template used to create the message to be displayed for this error.
   */
  final String message;

  /**
   * The template used to create the correction to be displayed for this error, or `null` if
   * there is no correction information for this error.
   */
  final String correction;

  /**
   * Initialize a newly created error code to have the given message.
   *
   * @param message the message template used to create the message to be displayed for the error
   */
  const CheckedModeCompileTimeErrorCode.con1(String name, int ordinal, String message) : this.con2(name, ordinal, message, null);

  /**
   * Initialize a newly created error code to have the given message and correction.
   *
   * @param message the template used to create the message to be displayed for the error
   * @param correction the template used to create the correction to be displayed for the error
   */
  const CheckedModeCompileTimeErrorCode.con2(String name, int ordinal, this.message, this.correction) : super(name, ordinal);

  @override
  ErrorSeverity get errorSeverity => ErrorType.CHECKED_MODE_COMPILE_TIME_ERROR.severity;

  @override
  ErrorType get type => ErrorType.CHECKED_MODE_COMPILE_TIME_ERROR;

  @override
  String get uniqueName => "${runtimeType.toString()}.${name}";
}

/**
 * The enumeration `CompileTimeErrorCode` defines the error codes used for compile time
 * errors. The convention for this class is for the name of the error code to indicate the problem
 * that caused the error to be generated and for the error message to explain what is wrong and,
 * when appropriate, how the problem can be corrected.
 */
class CompileTimeErrorCode extends Enum<CompileTimeErrorCode> implements ErrorCode {
  /**
   * Enum proposal: It is also a compile-time error to explicitly instantiate an enum via 'new' or
   * 'const' or to access its private fields.
   */
  static const CompileTimeErrorCode ACCESS_PRIVATE_ENUM_FIELD = const CompileTimeErrorCode.con1('ACCESS_PRIVATE_ENUM_FIELD', 0, "The private fields of an enum cannot be accessed, even within the same library");

  /**
   * 14.2 Exports: It is a compile-time error if a name <i>N</i> is re-exported by a library
   * <i>L</i> and <i>N</i> is introduced into the export namespace of <i>L</i> by more than one
   * export, unless each all exports refer to same declaration for the name N.
   *
   * @param ambiguousElementName the name of the ambiguous element
   * @param firstLibraryName the name of the first library that the type is found
   * @param secondLibraryName the name of the second library that the type is found
   */
  static const CompileTimeErrorCode AMBIGUOUS_EXPORT = const CompileTimeErrorCode.con1('AMBIGUOUS_EXPORT', 1, "The name '{0}' is defined in the libraries '{1}' and '{2}'");

  /**
   * 12.33 Argument Definition Test: It is a compile time error if <i>v</i> does not denote a formal
   * parameter.
   *
   * @param the name of the identifier in the argument definition test that is not a parameter
   */
  static const CompileTimeErrorCode ARGUMENT_DEFINITION_TEST_NON_PARAMETER = const CompileTimeErrorCode.con1('ARGUMENT_DEFINITION_TEST_NON_PARAMETER', 2, "'{0}' is not a parameter");

  /**
   * ?? Asynchronous For-in: It is a compile-time error if an asynchronous for-in statement appears
   * inside a synchronous function.
   */
  static const CompileTimeErrorCode ASYNC_FOR_IN_WRONG_CONTEXT = const CompileTimeErrorCode.con1('ASYNC_FOR_IN_WRONG_CONTEXT', 3, "The asynchronous for-in can only be used in a function marked with async or async*");

  /**
   * ??: It is a compile-time error if the function immediately enclosing a is not declared
   * asynchronous.
   */
  static const CompileTimeErrorCode AWAIT_IN_WRONG_CONTEXT = const CompileTimeErrorCode.con1('AWAIT_IN_WRONG_CONTEXT', 4, "The await expression can only be used in a function marked as async or async*");

  /**
   * 12.30 Identifier Reference: It is a compile-time error to use a built-in identifier other than
   * dynamic as a type annotation.
   */
  static const CompileTimeErrorCode BUILT_IN_IDENTIFIER_AS_TYPE = const CompileTimeErrorCode.con1('BUILT_IN_IDENTIFIER_AS_TYPE', 5, "The built-in identifier '{0}' cannot be as a type");

  /**
   * 12.30 Identifier Reference: It is a compile-time error if a built-in identifier is used as the
   * declared name of a class, type parameter or type alias.
   */
  static const CompileTimeErrorCode BUILT_IN_IDENTIFIER_AS_TYPE_NAME = const CompileTimeErrorCode.con1('BUILT_IN_IDENTIFIER_AS_TYPE_NAME', 6, "The built-in identifier '{0}' cannot be used as a type name");

  /**
   * 12.30 Identifier Reference: It is a compile-time error if a built-in identifier is used as the
   * declared name of a class, type parameter or type alias.
   */
  static const CompileTimeErrorCode BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME = const CompileTimeErrorCode.con1('BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME', 7, "The built-in identifier '{0}' cannot be used as a type alias name");

  /**
   * 12.30 Identifier Reference: It is a compile-time error if a built-in identifier is used as the
   * declared name of a class, type parameter or type alias.
   */
  static const CompileTimeErrorCode BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME = const CompileTimeErrorCode.con1('BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME', 8, "The built-in identifier '{0}' cannot be used as a type parameter name");

  /**
   * 13.9 Switch: It is a compile-time error if the class <i>C</i> implements the operator
   * <i>==</i>.
   */
  static const CompileTimeErrorCode CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS = const CompileTimeErrorCode.con1('CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS', 9, "The switch case expression type '{0}' cannot override the == operator");

  /**
   * 12.1 Constants: It is a compile-time error if evaluation of a compile-time constant would raise
   * an exception.
   */
  static const CompileTimeErrorCode COMPILE_TIME_CONSTANT_RAISES_EXCEPTION = const CompileTimeErrorCode.con1('COMPILE_TIME_CONSTANT_RAISES_EXCEPTION', 10, "");

  /**
   * 7.2 Getters: It is a compile-time error if a class has both a getter and a method with the same
   * name. This restriction holds regardless of whether the getter is defined explicitly or
   * implicitly, or whether the getter or the method are inherited or not.
   */
  static const CompileTimeErrorCode CONFLICTING_GETTER_AND_METHOD = const CompileTimeErrorCode.con1('CONFLICTING_GETTER_AND_METHOD', 11, "Class '{0}' cannot have both getter '{1}.{2}' and method with the same name");

  /**
   * 7.2 Getters: It is a compile-time error if a class has both a getter and a method with the same
   * name. This restriction holds regardless of whether the getter is defined explicitly or
   * implicitly, or whether the getter or the method are inherited or not.
   */
  static const CompileTimeErrorCode CONFLICTING_METHOD_AND_GETTER = const CompileTimeErrorCode.con1('CONFLICTING_METHOD_AND_GETTER', 12, "Class '{0}' cannot have both method '{1}.{2}' and getter with the same name");

  /**
   * 7.6 Constructors: A constructor name always begins with the name of its immediately enclosing
   * class, and may optionally be followed by a dot and an identifier <i>id</i>. It is a
   * compile-time error if <i>id</i> is the name of a member declared in the immediately enclosing
   * class.
   */
  static const CompileTimeErrorCode CONFLICTING_CONSTRUCTOR_NAME_AND_FIELD = const CompileTimeErrorCode.con1('CONFLICTING_CONSTRUCTOR_NAME_AND_FIELD', 13, "'{0}' cannot be used to name a constructor and a field in this class");

  /**
   * 7.6 Constructors: A constructor name always begins with the name of its immediately enclosing
   * class, and may optionally be followed by a dot and an identifier <i>id</i>. It is a
   * compile-time error if <i>id</i> is the name of a member declared in the immediately enclosing
   * class.
   */
  static const CompileTimeErrorCode CONFLICTING_CONSTRUCTOR_NAME_AND_METHOD = const CompileTimeErrorCode.con1('CONFLICTING_CONSTRUCTOR_NAME_AND_METHOD', 14, "'{0}' cannot be used to name a constructor and a method in this class");

  /**
   * 7. Classes: It is a compile time error if a generic class declares a type variable with the
   * same name as the class or any of its members or constructors.
   */
  static const CompileTimeErrorCode CONFLICTING_TYPE_VARIABLE_AND_CLASS = const CompileTimeErrorCode.con1('CONFLICTING_TYPE_VARIABLE_AND_CLASS', 15, "'{0}' cannot be used to name a type varaible in a class with the same name");

  /**
   * 7. Classes: It is a compile time error if a generic class declares a type variable with the
   * same name as the class or any of its members or constructors.
   */
  static const CompileTimeErrorCode CONFLICTING_TYPE_VARIABLE_AND_MEMBER = const CompileTimeErrorCode.con1('CONFLICTING_TYPE_VARIABLE_AND_MEMBER', 16, "'{0}' cannot be used to name a type varaible and member in this class");

  /**
   * 12.11.2 Const: It is a compile-time error if evaluation of a constant object results in an
   * uncaught exception being thrown.
   */
  static const CompileTimeErrorCode CONST_CONSTRUCTOR_THROWS_EXCEPTION = const CompileTimeErrorCode.con1('CONST_CONSTRUCTOR_THROWS_EXCEPTION', 17, "'const' constructors cannot throw exceptions");

  /**
   * 10.6.3 Constant Constructors: It is a compile-time error if a constant constructor is declared
   * by a class C if any instance variable declared in C is initialized with an expression that is
   * not a constant expression.
   */
  static const CompileTimeErrorCode CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST = const CompileTimeErrorCode.con1('CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST', 18, "Can't define the 'const' constructor because the field '{0}' is initialized with a non-constant value");

  /**
   * 7.6.3 Constant Constructors: The superinitializer that appears, explicitly or implicitly, in
   * the initializer list of a constant constructor must specify a constant constructor of the
   * superclass of the immediately enclosing class or a compile-time error occurs.
   *
   * 9 Mixins: For each generative constructor named ... an implicitly declared constructor named
   * ... is declared.
   */
  static const CompileTimeErrorCode CONST_CONSTRUCTOR_WITH_MIXIN = const CompileTimeErrorCode.con1('CONST_CONSTRUCTOR_WITH_MIXIN', 19, "Constant constructor cannot be declared for a class with a mixin");

  /**
   * 7.6.3 Constant Constructors: The superinitializer that appears, explicitly or implicitly, in
   * the initializer list of a constant constructor must specify a constant constructor of the
   * superclass of the immediately enclosing class or a compile-time error occurs.
   */
  static const CompileTimeErrorCode CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER = const CompileTimeErrorCode.con1('CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER', 20, "Constant constructor cannot call non-constant super constructor of '{0}'");

  /**
   * 7.6.3 Constant Constructors: It is a compile-time error if a constant constructor is declared
   * by a class that has a non-final instance variable.
   *
   * The above refers to both locally declared and inherited instance variables.
   */
  static const CompileTimeErrorCode CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD = const CompileTimeErrorCode.con1('CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD', 21, "Cannot define the 'const' constructor for a class with non-final fields");

  /**
   * 12.12.2 Const: It is a compile-time error if <i>T</i> is a deferred type.
   */
  static const CompileTimeErrorCode CONST_DEFERRED_CLASS = const CompileTimeErrorCode.con1('CONST_DEFERRED_CLASS', 22, "Deferred classes cannot be created with 'const'");

  /**
   * 6.2 Formal Parameters: It is a compile-time error if a formal parameter is declared as a
   * constant variable.
   */
  static const CompileTimeErrorCode CONST_FORMAL_PARAMETER = const CompileTimeErrorCode.con1('CONST_FORMAL_PARAMETER', 23, "Parameters cannot be 'const'");

  /**
   * 5 Variables: A constant variable must be initialized to a compile-time constant or a
   * compile-time error occurs.
   */
  static const CompileTimeErrorCode CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE = const CompileTimeErrorCode.con1('CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE', 24, "'const' variables must be constant value");

  /**
   * 5 Variables: A constant variable must be initialized to a compile-time constant or a
   * compile-time error occurs.
   *
   * 12.1 Constants: A qualified reference to a static constant variable that is not qualified by a
   * deferred prefix.
   */
  static const CompileTimeErrorCode CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY = const CompileTimeErrorCode.con1('CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY', 25, "Constant values from a deferred library cannot be used to initialized a 'const' variable");

  /**
   * 7.5 Instance Variables: It is a compile-time error if an instance variable is declared to be
   * constant.
   */
  static const CompileTimeErrorCode CONST_INSTANCE_FIELD = const CompileTimeErrorCode.con1('CONST_INSTANCE_FIELD', 26, "Only static fields can be declared as 'const'");

  /**
   * 12.8 Maps: It is a compile-time error if the key of an entry in a constant map literal is an
   * instance of a class that implements the operator <i>==</i> unless the key is a string or
   * integer.
   */
  static const CompileTimeErrorCode CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS = const CompileTimeErrorCode.con1('CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS', 27, "The constant map entry key expression type '{0}' cannot override the == operator");

  /**
   * 5 Variables: A constant variable must be initialized to a compile-time constant (12.1) or a
   * compile-time error occurs.
   *
   * @param name the name of the uninitialized final variable
   */
  static const CompileTimeErrorCode CONST_NOT_INITIALIZED = const CompileTimeErrorCode.con1('CONST_NOT_INITIALIZED', 28, "The const variable '{0}' must be initialized");

  /**
   * 12.11.2 Const: An expression of one of the forms !e, e1 && e2 or e1 || e2, where e, e1 and e2
   * are constant expressions that evaluate to a boolean value.
   */
  static const CompileTimeErrorCode CONST_EVAL_TYPE_BOOL = const CompileTimeErrorCode.con1('CONST_EVAL_TYPE_BOOL', 29, "An expression of type 'bool' was expected");

  /**
   * 12.11.2 Const: An expression of one of the forms e1 == e2 or e1 != e2 where e1 and e2 are
   * constant expressions that evaluate to a numeric, string or boolean value or to null.
   */
  static const CompileTimeErrorCode CONST_EVAL_TYPE_BOOL_NUM_STRING = const CompileTimeErrorCode.con1('CONST_EVAL_TYPE_BOOL_NUM_STRING', 30, "An expression of type 'bool', 'num', 'String' or 'null' was expected");

  /**
   * 12.11.2 Const: An expression of one of the forms ~e, e1 ^ e2, e1 & e2, e1 | e2, e1 >> e2 or e1
   * << e2, where e, e1 and e2 are constant expressions that evaluate to an integer value or to
   * null.
   */
  static const CompileTimeErrorCode CONST_EVAL_TYPE_INT = const CompileTimeErrorCode.con1('CONST_EVAL_TYPE_INT', 31, "An expression of type 'int' was expected");

  /**
   * 12.11.2 Const: An expression of one of the forms e, e1 + e2, e1 - e2, e1 * e2, e1 / e2, e1 ~/
   * e2, e1 > e2, e1 < e2, e1 >= e2, e1 <= e2 or e1 % e2, where e, e1 and e2 are constant
   * expressions that evaluate to a numeric value or to null..
   */
  static const CompileTimeErrorCode CONST_EVAL_TYPE_NUM = const CompileTimeErrorCode.con1('CONST_EVAL_TYPE_NUM', 32, "An expression of type 'num' was expected");

  /**
   * 12.11.2 Const: It is a compile-time error if evaluation of a constant object results in an
   * uncaught exception being thrown.
   */
  static const CompileTimeErrorCode CONST_EVAL_THROWS_EXCEPTION = const CompileTimeErrorCode.con1('CONST_EVAL_THROWS_EXCEPTION', 33, "Evaluation of this constant expression causes exception");

  /**
   * 12.11.2 Const: It is a compile-time error if evaluation of a constant object results in an
   * uncaught exception being thrown.
   */
  static const CompileTimeErrorCode CONST_EVAL_THROWS_IDBZE = const CompileTimeErrorCode.con1('CONST_EVAL_THROWS_IDBZE', 34, "Evaluation of this constant expression throws IntegerDivisionByZeroException");

  /**
   * 12.11.2 Const: If <i>T</i> is a parameterized type <i>S&lt;U<sub>1</sub>, &hellip;,
   * U<sub>m</sub>&gt;</i>, let <i>R = S</i>; It is a compile time error if <i>S</i> is not a
   * generic type with <i>m</i> type parameters.
   *
   * @param typeName the name of the type being referenced (<i>S</i>)
   * @param parameterCount the number of type parameters that were declared
   * @param argumentCount the number of type arguments provided
   * @see CompileTimeErrorCode#NEW_WITH_INVALID_TYPE_PARAMETERS
   * @see StaticTypeWarningCode#WRONG_NUMBER_OF_TYPE_ARGUMENTS
   */
  static const CompileTimeErrorCode CONST_WITH_INVALID_TYPE_PARAMETERS = const CompileTimeErrorCode.con1('CONST_WITH_INVALID_TYPE_PARAMETERS', 35, "The type '{0}' is declared with {1} type parameters, but {2} type arguments were given");

  /**
   * 12.11.2 Const: If <i>e</i> is of the form <i>const T(a<sub>1</sub>, &hellip;, a<sub>n</sub>,
   * x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;, x<sub>n+k</sub>: a<sub>n+k</sub>)</i> it is a
   * compile-time error if the type <i>T</i> does not declare a constant constructor with the same
   * name as the declaration of <i>T</i>.
   */
  static const CompileTimeErrorCode CONST_WITH_NON_CONST = const CompileTimeErrorCode.con1('CONST_WITH_NON_CONST', 36, "The constructor being called is not a 'const' constructor");

  /**
   * 12.11.2 Const: In all of the above cases, it is a compile-time error if <i>a<sub>i</sub>, 1
   * &lt;= i &lt;= n + k</i>, is not a compile-time constant expression.
   */
  static const CompileTimeErrorCode CONST_WITH_NON_CONSTANT_ARGUMENT = const CompileTimeErrorCode.con1('CONST_WITH_NON_CONSTANT_ARGUMENT', 37, "Arguments of a constant creation must be constant expressions");

  /**
   * 12.11.2 Const: It is a compile-time error if <i>T</i> is not a class accessible in the current
   * scope, optionally followed by type arguments.
   *
   * 12.11.2 Const: If <i>e</i> is of the form <i>const T.id(a<sub>1</sub>, &hellip;, a<sub>n</sub>,
   * x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip; x<sub>n+k</sub>: a<sub>n+k</sub>)</i> it is a
   * compile-time error if <i>T</i> is not a class accessible in the current scope, optionally
   * followed by type arguments.
   *
   * @param name the name of the non-type element
   */
  static const CompileTimeErrorCode CONST_WITH_NON_TYPE = const CompileTimeErrorCode.con1('CONST_WITH_NON_TYPE', 38, "The name '{0}' is not a class");

  /**
   * 12.11.2 Const: It is a compile-time error if <i>T</i> includes any type parameters.
   */
  static const CompileTimeErrorCode CONST_WITH_TYPE_PARAMETERS = const CompileTimeErrorCode.con1('CONST_WITH_TYPE_PARAMETERS', 39, "The constant creation cannot use a type parameter");

  /**
   * 12.11.2 Const: It is a compile-time error if <i>T.id</i> is not the name of a constant
   * constructor declared by the type <i>T</i>.
   *
   * @param typeName the name of the type
   * @param constructorName the name of the requested constant constructor
   */
  static const CompileTimeErrorCode CONST_WITH_UNDEFINED_CONSTRUCTOR = const CompileTimeErrorCode.con1('CONST_WITH_UNDEFINED_CONSTRUCTOR', 40, "The class '{0}' does not have a constant constructor '{1}'");

  /**
   * 12.11.2 Const: It is a compile-time error if <i>T.id</i> is not the name of a constant
   * constructor declared by the type <i>T</i>.
   *
   * @param typeName the name of the type
   */
  static const CompileTimeErrorCode CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT = const CompileTimeErrorCode.con1('CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT', 41, "The class '{0}' does not have a default constant constructor");

  /**
   * 15.3.1 Typedef: It is a compile-time error if any default values are specified in the signature
   * of a function type alias.
   */
  static const CompileTimeErrorCode DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS = const CompileTimeErrorCode.con1('DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS', 42, "Default values aren't allowed in typedefs");

  /**
   * 6.2.1 Required Formals: By means of a function signature that names the parameter and describes
   * its type as a function type. It is a compile-time error if any default values are specified in
   * the signature of such a function type.
   */
  static const CompileTimeErrorCode DEFAULT_VALUE_IN_FUNCTION_TYPED_PARAMETER = const CompileTimeErrorCode.con1('DEFAULT_VALUE_IN_FUNCTION_TYPED_PARAMETER', 43, "Default values aren't allowed in function type parameters");

  /**
   * 7.6.2 Factories: It is a compile-time error if <i>k</i> explicitly specifies a default value
   * for an optional parameter.
   */
  static const CompileTimeErrorCode DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR = const CompileTimeErrorCode.con1('DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR', 44, "Default values aren't allowed in factory constructors that redirect to another constructor");

  /**
   * 3.1 Scoping: It is a compile-time error if there is more than one entity with the same name
   * declared in the same scope.
   */
  static const CompileTimeErrorCode DUPLICATE_CONSTRUCTOR_DEFAULT = const CompileTimeErrorCode.con1('DUPLICATE_CONSTRUCTOR_DEFAULT', 45, "The default constructor is already defined");

  /**
   * 3.1 Scoping: It is a compile-time error if there is more than one entity with the same name
   * declared in the same scope.
   *
   * @param duplicateName the name of the duplicate entity
   */
  static const CompileTimeErrorCode DUPLICATE_CONSTRUCTOR_NAME = const CompileTimeErrorCode.con1('DUPLICATE_CONSTRUCTOR_NAME', 46, "The constructor with name '{0}' is already defined");

  /**
   * 3.1 Scoping: It is a compile-time error if there is more than one entity with the same name
   * declared in the same scope.
   *
   * 7 Classes: It is a compile-time error if a class declares two members of the same name.
   *
   * 7 Classes: It is a compile-time error if a class has an instance member and a static member
   * with the same name.
   *
   * @param duplicateName the name of the duplicate entity
   */
  static const CompileTimeErrorCode DUPLICATE_DEFINITION = const CompileTimeErrorCode.con1('DUPLICATE_DEFINITION', 47, "The name '{0}' is already defined");

  /**
   * 7. Classes: It is a compile-time error if a class has an instance member and a static member
   * with the same name.
   *
   * This covers the additional duplicate definition cases where inheritance has to be considered.
   *
   * @param className the name of the class that has conflicting instance/static members
   * @param name the name of the conflicting members
   * @see #DUPLICATE_DEFINITION
   */
  static const CompileTimeErrorCode DUPLICATE_DEFINITION_INHERITANCE = const CompileTimeErrorCode.con1('DUPLICATE_DEFINITION_INHERITANCE', 48, "The name '{0}' is already defined in '{1}'");

  /**
   * 12.14.2 Binding Actuals to Formals: It is a compile-time error if <i>q<sub>i</sub> =
   * q<sub>j</sub></i> for any <i>i != j</i> [where <i>q<sub>i</sub></i> is the label for a named
   * argument].
   */
  static const CompileTimeErrorCode DUPLICATE_NAMED_ARGUMENT = const CompileTimeErrorCode.con1('DUPLICATE_NAMED_ARGUMENT', 49, "The argument for the named parameter '{0}' was already specified");

  /**
   * SDK implementation libraries can be exported only by other SDK libraries.
   *
   * @param uri the uri pointing to a library
   */
  static const CompileTimeErrorCode EXPORT_INTERNAL_LIBRARY = const CompileTimeErrorCode.con1('EXPORT_INTERNAL_LIBRARY', 50, "The library '{0}' is internal and cannot be exported");

  /**
   * 14.2 Exports: It is a compile-time error if the compilation unit found at the specified URI is
   * not a library declaration.
   *
   * @param uri the uri pointing to a non-library declaration
   */
  static const CompileTimeErrorCode EXPORT_OF_NON_LIBRARY = const CompileTimeErrorCode.con1('EXPORT_OF_NON_LIBRARY', 51, "The exported library '{0}' must not have a part-of directive");

  /**
   * Enum proposal: It is a compile-time error to subclass, mix-in or implement an enum.
   */
  static const CompileTimeErrorCode EXTENDS_ENUM = const CompileTimeErrorCode.con1('EXTENDS_ENUM', 52, "Classes cannot extend an enum");

  /**
   * 7.9 Superclasses: It is a compile-time error if the extends clause of a class <i>C</i> includes
   * a type expression that does not denote a class available in the lexical scope of <i>C</i>.
   *
   * @param typeName the name of the superclass that was not found
   */
  static const CompileTimeErrorCode EXTENDS_NON_CLASS = const CompileTimeErrorCode.con1('EXTENDS_NON_CLASS', 53, "Classes can only extend other classes");

  /**
   * 12.2 Null: It is a compile-time error for a class to attempt to extend or implement Null.
   *
   * 12.3 Numbers: It is a compile-time error for a class to attempt to extend or implement int.
   *
   * 12.3 Numbers: It is a compile-time error for a class to attempt to extend or implement double.
   *
   * 12.3 Numbers: It is a compile-time error for any type other than the types int and double to
   * attempt to extend or implement num.
   *
   * 12.4 Booleans: It is a compile-time error for a class to attempt to extend or implement bool.
   *
   * 12.5 Strings: It is a compile-time error for a class to attempt to extend or implement String.
   *
   * @param typeName the name of the type that cannot be extended
   * @see #IMPLEMENTS_DISALLOWED_CLASS
   */
  static const CompileTimeErrorCode EXTENDS_DISALLOWED_CLASS = const CompileTimeErrorCode.con1('EXTENDS_DISALLOWED_CLASS', 54, "Classes cannot extend '{0}'");

  /**
   * 7.9 Superclasses: It is a compile-time error if the extends clause of a class <i>C</i> includes
   * a deferred type expression.
   *
   * @param typeName the name of the type that cannot be extended
   * @see #IMPLEMENTS_DEFERRED_CLASS
   * @see #MIXIN_DEFERRED_CLASS
   */
  static const CompileTimeErrorCode EXTENDS_DEFERRED_CLASS = const CompileTimeErrorCode.con1('EXTENDS_DEFERRED_CLASS', 55, "This class cannot extend the deferred class '{0}'");

  /**
   * 12.14.2 Binding Actuals to Formals: It is a static warning if <i>m &lt; h</i> or if <i>m &gt;
   * n</i>.
   *
   * 12.11.2 Const: It is a compile-time error if evaluation of a constant object results in an
   * uncaught exception being thrown.
   *
   * @param requiredCount the maximum number of positional arguments
   * @param argumentCount the actual number of positional arguments given
   */
  static const CompileTimeErrorCode EXTRA_POSITIONAL_ARGUMENTS = const CompileTimeErrorCode.con1('EXTRA_POSITIONAL_ARGUMENTS', 56, "{0} positional arguments expected, but {1} found");

  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It is a compile time
   * error if more than one initializer corresponding to a given instance variable appears in
   * <i>k</i>'s list.
   */
  static const CompileTimeErrorCode FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS = const CompileTimeErrorCode.con1('FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS', 57, "The field '{0}' cannot be initialized twice in the same constructor");

  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It is a compile time
   * error if <i>k</i>'s initializer list contains an initializer for a variable that is initialized
   * by means of an initializing formal of <i>k</i>.
   */
  static const CompileTimeErrorCode FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER = const CompileTimeErrorCode.con1('FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER', 58, "Fields cannot be initialized in both the parameter list and the initializers");

  /**
   * 5 Variables: It is a compile-time error if a final instance variable that has is initialized by
   * means of an initializing formal of a constructor is also initialized elsewhere in the same
   * constructor.
   *
   * @param name the name of the field in question
   */
  static const CompileTimeErrorCode FINAL_INITIALIZED_MULTIPLE_TIMES = const CompileTimeErrorCode.con1('FINAL_INITIALIZED_MULTIPLE_TIMES', 59, "'{0}' is a final field and so can only be set once");

  /**
   * 7.6.1 Generative Constructors: It is a compile-time error if an initializing formal is used by
   * a function other than a non-redirecting generative constructor.
   */
  static const CompileTimeErrorCode FIELD_INITIALIZER_FACTORY_CONSTRUCTOR = const CompileTimeErrorCode.con1('FIELD_INITIALIZER_FACTORY_CONSTRUCTOR', 60, "Initializing formal fields cannot be used in factory constructors");

  /**
   * 7.6.1 Generative Constructors: It is a compile-time error if an initializing formal is used by
   * a function other than a non-redirecting generative constructor.
   */
  static const CompileTimeErrorCode FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR = const CompileTimeErrorCode.con1('FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR', 61, "Initializing formal fields can only be used in constructors");

  /**
   * 7.6.1 Generative Constructors: A generative constructor may be redirecting, in which case its
   * only action is to invoke another generative constructor.
   *
   * 7.6.1 Generative Constructors: It is a compile-time error if an initializing formal is used by
   * a function other than a non-redirecting generative constructor.
   */
  static const CompileTimeErrorCode FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR = const CompileTimeErrorCode.con1('FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR', 62, "The redirecting constructor cannot have a field initializer");

  /**
   * 7.2 Getters: It is a compile-time error if a class has both a getter and a method with the same
   * name.
   *
   * @param name the conflicting name of the getter and method
   */
  static const CompileTimeErrorCode GETTER_AND_METHOD_WITH_SAME_NAME = const CompileTimeErrorCode.con1('GETTER_AND_METHOD_WITH_SAME_NAME', 63, "'{0}' cannot be used to name a getter, there is already a method with the same name");

  /**
   * 7.10 Superinterfaces: It is a compile-time error if the implements clause of a class <i>C</i>
   * specifies a malformed type or deferred type as a superinterface.
   *
   * @param typeName the name of the type that cannot be extended
   * @see #EXTENDS_DEFERRED_CLASS
   * @see #MIXIN_DEFERRED_CLASS
   */
  static const CompileTimeErrorCode IMPLEMENTS_DEFERRED_CLASS = const CompileTimeErrorCode.con1('IMPLEMENTS_DEFERRED_CLASS', 64, "This class cannot implement the deferred class '{0}'");

  /**
   * 12.2 Null: It is a compile-time error for a class to attempt to extend or implement Null.
   *
   * 12.3 Numbers: It is a compile-time error for a class to attempt to extend or implement int.
   *
   * 12.3 Numbers: It is a compile-time error for a class to attempt to extend or implement double.
   *
   * 12.3 Numbers: It is a compile-time error for any type other than the types int and double to
   * attempt to extend or implement num.
   *
   * 12.4 Booleans: It is a compile-time error for a class to attempt to extend or implement bool.
   *
   * 12.5 Strings: It is a compile-time error for a class to attempt to extend or implement String.
   *
   * @param typeName the name of the type that cannot be implemented
   * @see #EXTENDS_DISALLOWED_CLASS
   */
  static const CompileTimeErrorCode IMPLEMENTS_DISALLOWED_CLASS = const CompileTimeErrorCode.con1('IMPLEMENTS_DISALLOWED_CLASS', 65, "Classes cannot implement '{0}'");

  /**
   * 7.10 Superinterfaces: It is a compile-time error if the implements clause of a class includes
   * type dynamic.
   */
  static const CompileTimeErrorCode IMPLEMENTS_DYNAMIC = const CompileTimeErrorCode.con1('IMPLEMENTS_DYNAMIC', 66, "Classes cannot implement 'dynamic'");

  /**
   * Enum proposal: It is a compile-time error to subclass, mix-in or implement an enum.
   */
  static const CompileTimeErrorCode IMPLEMENTS_ENUM = const CompileTimeErrorCode.con1('IMPLEMENTS_ENUM', 67, "Classes cannot implement an enum");

  /**
   * 7.10 Superinterfaces: It is a compile-time error if the implements clause of a class <i>C</i>
   * includes a type expression that does not denote a class available in the lexical scope of
   * <i>C</i>.
   *
   * @param typeName the name of the interface that was not found
   */
  static const CompileTimeErrorCode IMPLEMENTS_NON_CLASS = const CompileTimeErrorCode.con1('IMPLEMENTS_NON_CLASS', 68, "Classes can only implement other classes");

  /**
   * 7.10 Superinterfaces: It is a compile-time error if a type <i>T</i> appears more than once in
   * the implements clause of a class.
   *
   * @param className the name of the class that is implemented more than once
   */
  static const CompileTimeErrorCode IMPLEMENTS_REPEATED = const CompileTimeErrorCode.con1('IMPLEMENTS_REPEATED', 69, "'{0}' can only be implemented once");

  /**
   * 7.10 Superinterfaces: It is a compile-time error if the superclass of a class <i>C</i> appears
   * in the implements clause of <i>C</i>.
   *
   * @param className the name of the class that appears in both "extends" and "implements" clauses
   */
  static const CompileTimeErrorCode IMPLEMENTS_SUPER_CLASS = const CompileTimeErrorCode.con1('IMPLEMENTS_SUPER_CLASS', 70, "'{0}' cannot be used in both 'extends' and 'implements' clauses");

  /**
   * 7.6.1 Generative Constructors: Note that <b>this</b> is not in scope on the right hand side of
   * an initializer.
   *
   * 12.10 This: It is a compile-time error if this appears in a top-level function or variable
   * initializer, in a factory constructor, or in a static method or variable initializer, or in the
   * initializer of an instance variable.
   *
   * @param name the name of the type in question
   */
  static const CompileTimeErrorCode IMPLICIT_THIS_REFERENCE_IN_INITIALIZER = const CompileTimeErrorCode.con1('IMPLICIT_THIS_REFERENCE_IN_INITIALIZER', 71, "Only static members can be accessed in initializers");

  /**
   * SDK implementation libraries can be imported only by other SDK libraries.
   *
   * @param uri the uri pointing to a library
   */
  static const CompileTimeErrorCode IMPORT_INTERNAL_LIBRARY = const CompileTimeErrorCode.con1('IMPORT_INTERNAL_LIBRARY', 72, "The library '{0}' is internal and cannot be imported");

  /**
   * 14.1 Imports: It is a compile-time error if the specified URI of an immediate import does not
   * refer to a library declaration.
   *
   * @param uri the uri pointing to a non-library declaration
   * @see StaticWarningCode#IMPORT_OF_NON_LIBRARY
   */
  static const CompileTimeErrorCode IMPORT_OF_NON_LIBRARY = const CompileTimeErrorCode.con1('IMPORT_OF_NON_LIBRARY', 73, "The imported library '{0}' must not have a part-of directive");

  /**
   * 13.9 Switch: It is a compile-time error if values of the expressions <i>e<sub>k</sub></i> are
   * not instances of the same class <i>C</i>, for all <i>1 &lt;= k &lt;= n</i>.
   *
   * @param expressionSource the expression source code that is the unexpected type
   * @param expectedType the name of the expected type
   */
  static const CompileTimeErrorCode INCONSISTENT_CASE_EXPRESSION_TYPES = const CompileTimeErrorCode.con1('INCONSISTENT_CASE_EXPRESSION_TYPES', 74, "Case expressions must have the same types, '{0}' is not a '{1}'");

  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It is a compile-time
   * error if <i>k</i>'s initializer list contains an initializer for a variable that is not an
   * instance variable declared in the immediately surrounding class.
   *
   * @param id the name of the initializing formal that is not an instance variable in the
   *          immediately enclosing class
   * @see #INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD
   */
  static const CompileTimeErrorCode INITIALIZER_FOR_NON_EXISTENT_FIELD = const CompileTimeErrorCode.con1('INITIALIZER_FOR_NON_EXISTENT_FIELD', 75, "'{0}' is not a variable in the enclosing class");

  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It is a compile-time
   * error if <i>k</i>'s initializer list contains an initializer for a variable that is not an
   * instance variable declared in the immediately surrounding class.
   *
   * @param id the name of the initializing formal that is a static variable in the immediately
   *          enclosing class
   * @see #INITIALIZING_FORMAL_FOR_STATIC_FIELD
   */
  static const CompileTimeErrorCode INITIALIZER_FOR_STATIC_FIELD = const CompileTimeErrorCode.con1('INITIALIZER_FOR_STATIC_FIELD', 76, "'{0}' is a static variable in the enclosing class, variables initialized in a constructor cannot be static");

  /**
   * 7.6.1 Generative Constructors: An initializing formal has the form <i>this.id</i>. It is a
   * compile-time error if <i>id</i> is not the name of an instance variable of the immediately
   * enclosing class.
   *
   * @param id the name of the initializing formal that is not an instance variable in the
   *          immediately enclosing class
   * @see #INITIALIZING_FORMAL_FOR_STATIC_FIELD
   * @see #INITIALIZER_FOR_NON_EXISTENT_FIELD
   */
  static const CompileTimeErrorCode INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD = const CompileTimeErrorCode.con1('INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD', 77, "'{0}' is not a variable in the enclosing class");

  /**
   * 7.6.1 Generative Constructors: An initializing formal has the form <i>this.id</i>. It is a
   * compile-time error if <i>id</i> is not the name of an instance variable of the immediately
   * enclosing class.
   *
   * @param id the name of the initializing formal that is a static variable in the immediately
   *          enclosing class
   * @see #INITIALIZER_FOR_STATIC_FIELD
   */
  static const CompileTimeErrorCode INITIALIZING_FORMAL_FOR_STATIC_FIELD = const CompileTimeErrorCode.con1('INITIALIZING_FORMAL_FOR_STATIC_FIELD', 78, "'{0}' is a static field in the enclosing class, fields initialized in a constructor cannot be static");

  /**
   * 12.30 Identifier Reference: Otherwise, e is equivalent to the property extraction
   * <b>this</b>.<i>id</i>.
   */
  static const CompileTimeErrorCode INSTANCE_MEMBER_ACCESS_FROM_FACTORY = const CompileTimeErrorCode.con1('INSTANCE_MEMBER_ACCESS_FROM_FACTORY', 79, "Instance members cannot be accessed from a factory constructor");

  /**
   * 12.30 Identifier Reference: Otherwise, e is equivalent to the property extraction
   * <b>this</b>.<i>id</i>.
   */
  static const CompileTimeErrorCode INSTANCE_MEMBER_ACCESS_FROM_STATIC = const CompileTimeErrorCode.con1('INSTANCE_MEMBER_ACCESS_FROM_STATIC', 80, "Instance members cannot be accessed from a static method");

  /**
   * Enum proposal: It is also a compile-time error to explicitly instantiate an enum via 'new' or
   * 'const' or to access its private fields.
   */
  static const CompileTimeErrorCode INSTANTIATE_ENUM = const CompileTimeErrorCode.con1('INSTANTIATE_ENUM', 81, "Enums cannot be instantiated");

  /**
   * 11 Metadata: Metadata consists of a series of annotations, each of which begin with the
   * character @, followed by a constant expression that must be either a reference to a
   * compile-time constant variable, or a call to a constant constructor.
   */
  static const CompileTimeErrorCode INVALID_ANNOTATION = const CompileTimeErrorCode.con1('INVALID_ANNOTATION', 82, "Annotation can be only constant variable or constant constructor invocation");

  /**
   * 11 Metadata: Metadata consists of a series of annotations, each of which begin with the
   * character @, followed by a constant expression that must be either a reference to a
   * compile-time constant variable, or a call to a constant constructor.
   *
   * 12.1 Constants: A qualified reference to a static constant variable that is not qualified by a
   * deferred prefix.
   */
  static const CompileTimeErrorCode INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY = const CompileTimeErrorCode.con1('INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY', 83, "Constant values from a deferred library cannot be used as annotations");

  /**
   * 15.31 Identifier Reference: It is a compile-time error if any of the identifiers async, await
   * or yield is used as an identifier in a function body marked with either async, async* or sync*.
   */
  static const CompileTimeErrorCode INVALID_IDENTIFIER_IN_ASYNC = const CompileTimeErrorCode.con1('INVALID_IDENTIFIER_IN_ASYNC', 84, "The identifier '{0}' cannot be used in a function marked with async, async* or sync*");

  /**
   * 9. Functions: It is a compile-time error if an async, async* or sync* modifier is attached to
   * the body of a setter or constructor.
   */
  static const CompileTimeErrorCode INVALID_MODIFIER_ON_CONSTRUCTOR = const CompileTimeErrorCode.con1('INVALID_MODIFIER_ON_CONSTRUCTOR', 85, "The modifier '{0}' cannot be applied to the body of a constructor");

  /**
   * 9. Functions: It is a compile-time error if an async, async* or sync* modifier is attached to
   * the body of a setter or constructor.
   */
  static const CompileTimeErrorCode INVALID_MODIFIER_ON_SETTER = const CompileTimeErrorCode.con1('INVALID_MODIFIER_ON_SETTER', 86, "The modifier '{0}' cannot be applied to the body of a setter");

  /**
   * TODO(brianwilkerson) Remove this when we have decided on how to report errors in compile-time
   * constants. Until then, this acts as a placeholder for more informative errors.
   *
   * See TODOs in ConstantVisitor
   */
  static const CompileTimeErrorCode INVALID_CONSTANT = const CompileTimeErrorCode.con1('INVALID_CONSTANT', 87, "Invalid constant value");

  /**
   * 7.6 Constructors: It is a compile-time error if the name of a constructor is not a constructor
   * name.
   */
  static const CompileTimeErrorCode INVALID_CONSTRUCTOR_NAME = const CompileTimeErrorCode.con1('INVALID_CONSTRUCTOR_NAME', 88, "Invalid constructor name");

  /**
   * 7.6.2 Factories: It is a compile-time error if <i>M</i> is not the name of the immediately
   * enclosing class.
   */
  static const CompileTimeErrorCode INVALID_FACTORY_NAME_NOT_A_CLASS = const CompileTimeErrorCode.con1('INVALID_FACTORY_NAME_NOT_A_CLASS', 89, "The name of the immediately enclosing class expected");

  /**
   * 12.10 This: It is a compile-time error if this appears in a top-level function or variable
   * initializer, in a factory constructor, or in a static method or variable initializer, or in the
   * initializer of an instance variable.
   */
  static const CompileTimeErrorCode INVALID_REFERENCE_TO_THIS = const CompileTimeErrorCode.con1('INVALID_REFERENCE_TO_THIS', 90, "Invalid reference to 'this' expression");

  /**
   * 12.6 Lists: It is a compile time error if the type argument of a constant list literal includes
   * a type parameter.
   *
   * @name the name of the type parameter
   */
  static const CompileTimeErrorCode INVALID_TYPE_ARGUMENT_IN_CONST_LIST = const CompileTimeErrorCode.con1('INVALID_TYPE_ARGUMENT_IN_CONST_LIST', 91, "Constant list literals cannot include a type parameter as a type argument, such as '{0}'");

  /**
   * 12.7 Maps: It is a compile time error if the type arguments of a constant map literal include a
   * type parameter.
   *
   * @name the name of the type parameter
   */
  static const CompileTimeErrorCode INVALID_TYPE_ARGUMENT_IN_CONST_MAP = const CompileTimeErrorCode.con1('INVALID_TYPE_ARGUMENT_IN_CONST_MAP', 92, "Constant map literals cannot include a type parameter as a type argument, such as '{0}'");

  /**
   * 14.2 Exports: It is a compile-time error if the compilation unit found at the specified URI is
   * not a library declaration.
   *
   * 14.1 Imports: It is a compile-time error if the compilation unit found at the specified URI is
   * not a library declaration.
   *
   * 14.3 Parts: It is a compile time error if the contents of the URI are not a valid part
   * declaration.
   *
   * @param uri the URI that is invalid
   * @see #URI_DOES_NOT_EXIST
   */
  static const CompileTimeErrorCode INVALID_URI = const CompileTimeErrorCode.con1('INVALID_URI', 93, "Invalid URI syntax: '{0}'");

  /**
   * 13.13 Break: It is a compile-time error if no such statement <i>s<sub>E</sub></i> exists within
   * the innermost function in which <i>s<sub>b</sub></i> occurs.
   *
   * 13.14 Continue: It is a compile-time error if no such statement or case clause
   * <i>s<sub>E</sub></i> exists within the innermost function in which <i>s<sub>c</sub></i> occurs.
   *
   * @param labelName the name of the unresolvable label
   */
  static const CompileTimeErrorCode LABEL_IN_OUTER_SCOPE = const CompileTimeErrorCode.con1('LABEL_IN_OUTER_SCOPE', 94, "Cannot reference label '{0}' declared in an outer method");

  /**
   * 13.13 Break: It is a compile-time error if no such statement <i>s<sub>E</sub></i> exists within
   * the innermost function in which <i>s<sub>b</sub></i> occurs.
   *
   * 13.14 Continue: It is a compile-time error if no such statement or case clause
   * <i>s<sub>E</sub></i> exists within the innermost function in which <i>s<sub>c</sub></i> occurs.
   *
   * @param labelName the name of the unresolvable label
   */
  static const CompileTimeErrorCode LABEL_UNDEFINED = const CompileTimeErrorCode.con1('LABEL_UNDEFINED', 95, "Cannot reference undefined label '{0}'");

  /**
   * 7 Classes: It is a compile time error if a class <i>C</i> declares a member with the same name
   * as <i>C</i>.
   */
  static const CompileTimeErrorCode MEMBER_WITH_CLASS_NAME = const CompileTimeErrorCode.con1('MEMBER_WITH_CLASS_NAME', 96, "Class members cannot have the same name as the enclosing class");

  /**
   * 7.2 Getters: It is a compile-time error if a class has both a getter and a method with the same
   * name.
   *
   * @param name the conflicting name of the getter and method
   */
  static const CompileTimeErrorCode METHOD_AND_GETTER_WITH_SAME_NAME = const CompileTimeErrorCode.con1('METHOD_AND_GETTER_WITH_SAME_NAME', 97, "'{0}' cannot be used to name a method, there is already a getter with the same name");

  /**
   * 12.1 Constants: A constant expression is ... a constant list literal.
   */
  static const CompileTimeErrorCode MISSING_CONST_IN_LIST_LITERAL = const CompileTimeErrorCode.con1('MISSING_CONST_IN_LIST_LITERAL', 98, "List literals must be prefixed with 'const' when used as a constant expression");

  /**
   * 12.1 Constants: A constant expression is ... a constant map literal.
   */
  static const CompileTimeErrorCode MISSING_CONST_IN_MAP_LITERAL = const CompileTimeErrorCode.con1('MISSING_CONST_IN_MAP_LITERAL', 99, "Map literals must be prefixed with 'const' when used as a constant expression");

  /**
   * Enum proposal: It is a static warning if all of the following conditions hold:
   * * The switch statement does not have a 'default' clause.
   * * The static type of <i>e</i> is an enumerated typed with elements <i>id<sub>1</sub></i>,
   * &hellip;, <i>id<sub>n</sub></i>.
   * * The sets {<i>e<sub>1</sub></i>, &hellip;, <i>e<sub>k</sub></i>} and {<i>id<sub>1</sub></i>,
   * &hellip;, <i>id<sub>n</sub></i>} are not the same.
   *
   * @param constantName the name of the constant that is missing
   */
  static const CompileTimeErrorCode MISSING_ENUM_CONSTANT_IN_SWITCH = const CompileTimeErrorCode.con2('MISSING_ENUM_CONSTANT_IN_SWITCH', 100, "Missing case clause for '{0}'", "Add a case clause for the missing constant or add a default clause.");

  /**
   * 9 Mixins: It is a compile-time error if a declared or derived mixin explicitly declares a
   * constructor.
   *
   * @param typeName the name of the mixin that is invalid
   */
  static const CompileTimeErrorCode MIXIN_DECLARES_CONSTRUCTOR = const CompileTimeErrorCode.con1('MIXIN_DECLARES_CONSTRUCTOR', 101, "The class '{0}' cannot be used as a mixin because it declares a constructor");

  /**
   * 9.1 Mixin Application: It is a compile-time error if the with clause of a mixin application
   * <i>C</i> includes a deferred type expression.
   *
   * @param typeName the name of the type that cannot be extended
   * @see #EXTENDS_DEFERRED_CLASS
   * @see #IMPLEMENTS_DEFERRED_CLASS
   */
  static const CompileTimeErrorCode MIXIN_DEFERRED_CLASS = const CompileTimeErrorCode.con1('MIXIN_DEFERRED_CLASS', 102, "This class cannot mixin the deferred class '{0}'");

  /**
   * 9 Mixins: It is a compile-time error if a mixin is derived from a class whose superclass is not
   * Object.
   *
   * @param typeName the name of the mixin that is invalid
   */
  static const CompileTimeErrorCode MIXIN_INHERITS_FROM_NOT_OBJECT = const CompileTimeErrorCode.con1('MIXIN_INHERITS_FROM_NOT_OBJECT', 103, "The class '{0}' cannot be used as a mixin because it extends a class other than Object");

  /**
   * 12.2 Null: It is a compile-time error for a class to attempt to extend or implement Null.
   *
   * 12.3 Numbers: It is a compile-time error for a class to attempt to extend or implement int.
   *
   * 12.3 Numbers: It is a compile-time error for a class to attempt to extend or implement double.
   *
   * 12.3 Numbers: It is a compile-time error for any type other than the types int and double to
   * attempt to extend or implement num.
   *
   * 12.4 Booleans: It is a compile-time error for a class to attempt to extend or implement bool.
   *
   * 12.5 Strings: It is a compile-time error for a class to attempt to extend or implement String.
   *
   * @param typeName the name of the type that cannot be extended
   * @see #IMPLEMENTS_DISALLOWED_CLASS
   */
  static const CompileTimeErrorCode MIXIN_OF_DISALLOWED_CLASS = const CompileTimeErrorCode.con1('MIXIN_OF_DISALLOWED_CLASS', 104, "Classes cannot mixin '{0}'");

  /**
   * Enum proposal: It is a compile-time error to subclass, mix-in or implement an enum.
   */
  static const CompileTimeErrorCode MIXIN_OF_ENUM = const CompileTimeErrorCode.con1('MIXIN_OF_ENUM', 105, "Classes cannot mixin an enum");

  /**
   * 9.1 Mixin Application: It is a compile-time error if <i>M</i> does not denote a class or mixin
   * available in the immediately enclosing scope.
   */
  static const CompileTimeErrorCode MIXIN_OF_NON_CLASS = const CompileTimeErrorCode.con1('MIXIN_OF_NON_CLASS', 106, "Classes can only mixin other classes");

  /**
   * 9 Mixins: It is a compile-time error if a declared or derived mixin refers to super.
   */
  static const CompileTimeErrorCode MIXIN_REFERENCES_SUPER = const CompileTimeErrorCode.con1('MIXIN_REFERENCES_SUPER', 107, "The class '{0}' cannot be used as a mixin because it references 'super'");

  /**
   * 9.1 Mixin Application: It is a compile-time error if <i>S</i> does not denote a class available
   * in the immediately enclosing scope.
   */
  static const CompileTimeErrorCode MIXIN_WITH_NON_CLASS_SUPERCLASS = const CompileTimeErrorCode.con1('MIXIN_WITH_NON_CLASS_SUPERCLASS', 108, "Mixin can only be applied to class");

  /**
   * 7.6.1 Generative Constructors: A generative constructor may be redirecting, in which case its
   * only action is to invoke another generative constructor.
   */
  static const CompileTimeErrorCode MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS = const CompileTimeErrorCode.con1('MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS', 109, "Constructor may have at most one 'this' redirection");

  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. Then <i>k</i> may
   * include at most one superinitializer in its initializer list or a compile time error occurs.
   */
  static const CompileTimeErrorCode MULTIPLE_SUPER_INITIALIZERS = const CompileTimeErrorCode.con1('MULTIPLE_SUPER_INITIALIZERS', 110, "Constructor may have at most one 'super' initializer");

  /**
   * 11 Metadata: Metadata consists of a series of annotations, each of which begin with the
   * character @, followed by a constant expression that must be either a reference to a
   * compile-time constant variable, or a call to a constant constructor.
   */
  static const CompileTimeErrorCode NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS = const CompileTimeErrorCode.con1('NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS', 111, "Annotation creation must have arguments");

  /**
   * 7.6.1 Generative Constructors: If no superinitializer is provided, an implicit superinitializer
   * of the form <b>super</b>() is added at the end of <i>k</i>'s initializer list, unless the
   * enclosing class is class <i>Object</i>.
   *
   * 7.6.1 Generative constructors. It is a compile-time error if class <i>S</i> does not declare a
   * generative constructor named <i>S</i> (respectively <i>S.id</i>)
   */
  static const CompileTimeErrorCode NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT = const CompileTimeErrorCode.con1('NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT', 112, "The class '{0}' does not have a default constructor");

  /**
   * 7.6 Constructors: Iff no constructor is specified for a class <i>C</i>, it implicitly has a
   * default constructor C() : <b>super<b>() {}, unless <i>C</i> is class <i>Object</i>.
   *
   * 7.6.1 Generative constructors. It is a compile-time error if class <i>S</i> does not declare a
   * generative constructor named <i>S</i> (respectively <i>S.id</i>)
   */
  static const CompileTimeErrorCode NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT = const CompileTimeErrorCode.con1('NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT', 113, "The class '{0}' does not have a default constructor");

  /**
   * 13.2 Expression Statements: It is a compile-time error if a non-constant map literal that has
   * no explicit type arguments appears in a place where a statement is expected.
   */
  static const CompileTimeErrorCode NON_CONST_MAP_AS_EXPRESSION_STATEMENT = const CompileTimeErrorCode.con1('NON_CONST_MAP_AS_EXPRESSION_STATEMENT', 114, "A non-constant map literal without type arguments cannot be used as an expression statement");

  /**
   * 13.9 Switch: Given a switch statement of the form <i>switch (e) { label<sub>11</sub> &hellip;
   * label<sub>1j1</sub> case e<sub>1</sub>: s<sub>1</sub> &hellip; label<sub>n1</sub> &hellip;
   * label<sub>njn</sub> case e<sub>n</sub>: s<sub>n</sub> default: s<sub>n+1</sub>}</i> or the form
   * <i>switch (e) { label<sub>11</sub> &hellip; label<sub>1j1</sub> case e<sub>1</sub>:
   * s<sub>1</sub> &hellip; label<sub>n1</sub> &hellip; label<sub>njn</sub> case e<sub>n</sub>:
   * s<sub>n</sub>}</i>, it is a compile-time error if the expressions <i>e<sub>k</sub></i> are not
   * compile-time constants, for all <i>1 &lt;= k &lt;= n</i>.
   */
  static const CompileTimeErrorCode NON_CONSTANT_CASE_EXPRESSION = const CompileTimeErrorCode.con1('NON_CONSTANT_CASE_EXPRESSION', 115, "Case expressions must be constant");

  /**
   * 13.9 Switch: Given a switch statement of the form <i>switch (e) { label<sub>11</sub> &hellip;
   * label<sub>1j1</sub> case e<sub>1</sub>: s<sub>1</sub> &hellip; label<sub>n1</sub> &hellip;
   * label<sub>njn</sub> case e<sub>n</sub>: s<sub>n</sub> default: s<sub>n+1</sub>}</i> or the form
   * <i>switch (e) { label<sub>11</sub> &hellip; label<sub>1j1</sub> case e<sub>1</sub>:
   * s<sub>1</sub> &hellip; label<sub>n1</sub> &hellip; label<sub>njn</sub> case e<sub>n</sub>:
   * s<sub>n</sub>}</i>, it is a compile-time error if the expressions <i>e<sub>k</sub></i> are not
   * compile-time constants, for all <i>1 &lt;= k &lt;= n</i>.
   *
   * 12.1 Constants: A qualified reference to a static constant variable that is not qualified by a
   * deferred prefix.
   */
  static const CompileTimeErrorCode NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY = const CompileTimeErrorCode.con1('NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY', 116, "Constant values from a deferred library cannot be used as a case expression");

  /**
   * 6.2.2 Optional Formals: It is a compile-time error if the default value of an optional
   * parameter is not a compile-time constant.
   */
  static const CompileTimeErrorCode NON_CONSTANT_DEFAULT_VALUE = const CompileTimeErrorCode.con1('NON_CONSTANT_DEFAULT_VALUE', 117, "Default values of an optional parameter must be constant");

  /**
   * 6.2.2 Optional Formals: It is a compile-time error if the default value of an optional
   * parameter is not a compile-time constant.
   *
   * 12.1 Constants: A qualified reference to a static constant variable that is not qualified by a
   * deferred prefix.
   */
  static const CompileTimeErrorCode NON_CONSTANT_DEFAULT_VALUE_FROM_DEFERRED_LIBRARY = const CompileTimeErrorCode.con1('NON_CONSTANT_DEFAULT_VALUE_FROM_DEFERRED_LIBRARY', 118, "Constant values from a deferred library cannot be used as a default parameter value");

  /**
   * 12.6 Lists: It is a compile time error if an element of a constant list literal is not a
   * compile-time constant.
   */
  static const CompileTimeErrorCode NON_CONSTANT_LIST_ELEMENT = const CompileTimeErrorCode.con1('NON_CONSTANT_LIST_ELEMENT', 119, "'const' lists must have all constant values");

  /**
   * 12.6 Lists: It is a compile time error if an element of a constant list literal is not a
   * compile-time constant.
   *
   * 12.1 Constants: A qualified reference to a static constant variable that is not qualified by a
   * deferred prefix.
   */
  static const CompileTimeErrorCode NON_CONSTANT_LIST_ELEMENT_FROM_DEFERRED_LIBRARY = const CompileTimeErrorCode.con1('NON_CONSTANT_LIST_ELEMENT_FROM_DEFERRED_LIBRARY', 120, "Constant values from a deferred library cannot be used as values in a 'const' list");

  /**
   * 12.7 Maps: It is a compile time error if either a key or a value of an entry in a constant map
   * literal is not a compile-time constant.
   */
  static const CompileTimeErrorCode NON_CONSTANT_MAP_KEY = const CompileTimeErrorCode.con1('NON_CONSTANT_MAP_KEY', 121, "The keys in a map must be constant");

  /**
   * 12.7 Maps: It is a compile time error if either a key or a value of an entry in a constant map
   * literal is not a compile-time constant.
   *
   * 12.1 Constants: A qualified reference to a static constant variable that is not qualified by a
   * deferred prefix.
   */
  static const CompileTimeErrorCode NON_CONSTANT_MAP_KEY_FROM_DEFERRED_LIBRARY = const CompileTimeErrorCode.con1('NON_CONSTANT_MAP_KEY_FROM_DEFERRED_LIBRARY', 122, "Constant values from a deferred library cannot be used as keys in a map");

  /**
   * 12.7 Maps: It is a compile time error if either a key or a value of an entry in a constant map
   * literal is not a compile-time constant.
   */
  static const CompileTimeErrorCode NON_CONSTANT_MAP_VALUE = const CompileTimeErrorCode.con1('NON_CONSTANT_MAP_VALUE', 123, "The values in a 'const' map must be constant");

  /**
   * 12.7 Maps: It is a compile time error if either a key or a value of an entry in a constant map
   * literal is not a compile-time constant.
   *
   * 12.1 Constants: A qualified reference to a static constant variable that is not qualified by a
   * deferred prefix.
   */
  static const CompileTimeErrorCode NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY = const CompileTimeErrorCode.con1('NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY', 124, "Constant values from a deferred library cannot be used as values in a 'const' map");

  /**
   * 11 Metadata: Metadata consists of a series of annotations, each of which begin with the
   * character @, followed by a constant expression that must be either a reference to a
   * compile-time constant variable, or a call to a constant constructor.
   *
   * "From deferred library" case is covered by
   * [CompileTimeErrorCode#INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY].
   */
  static const CompileTimeErrorCode NON_CONSTANT_ANNOTATION_CONSTRUCTOR = const CompileTimeErrorCode.con1('NON_CONSTANT_ANNOTATION_CONSTRUCTOR', 125, "Annotation creation can use only 'const' constructor");

  /**
   * 7.6.3 Constant Constructors: Any expression that appears within the initializer list of a
   * constant constructor must be a potentially constant expression, or a compile-time error occurs.
   */
  static const CompileTimeErrorCode NON_CONSTANT_VALUE_IN_INITIALIZER = const CompileTimeErrorCode.con1('NON_CONSTANT_VALUE_IN_INITIALIZER', 126, "Initializer expressions in constant constructors must be constants");

  /**
   * 7.6.3 Constant Constructors: Any expression that appears within the initializer list of a
   * constant constructor must be a potentially constant expression, or a compile-time error occurs.
   *
   * 12.1 Constants: A qualified reference to a static constant variable that is not qualified by a
   * deferred prefix.
   */
  static const CompileTimeErrorCode NON_CONSTANT_VALUE_IN_INITIALIZER_FROM_DEFERRED_LIBRARY = const CompileTimeErrorCode.con1('NON_CONSTANT_VALUE_IN_INITIALIZER_FROM_DEFERRED_LIBRARY', 127, "Constant values from a deferred library cannot be used as constant initializers");

  /**
   * 12.14.2 Binding Actuals to Formals: It is a static warning if <i>m < h</i> or if <i>m > n</i>.
   *
   * 12.11.2 Const: It is a compile-time error if evaluation of a constant object results in an
   * uncaught exception being thrown.
   *
   * @param requiredCount the expected number of required arguments
   * @param argumentCount the actual number of positional arguments given
   */
  static const CompileTimeErrorCode NOT_ENOUGH_REQUIRED_ARGUMENTS = const CompileTimeErrorCode.con1('NOT_ENOUGH_REQUIRED_ARGUMENTS', 128, "{0} required argument(s) expected, but {1} found");

  /**
   * 7.6.1 Generative Constructors: Let <i>C</i> be the class in which the superinitializer appears
   * and let <i>S</i> be the superclass of <i>C</i>. Let <i>k</i> be a generative constructor. It is
   * a compile-time error if class <i>S</i> does not declare a generative constructor named <i>S</i>
   * (respectively <i>S.id</i>)
   */
  static const CompileTimeErrorCode NON_GENERATIVE_CONSTRUCTOR = const CompileTimeErrorCode.con1('NON_GENERATIVE_CONSTRUCTOR', 129, "The generative constructor '{0}' expected, but factory found");

  /**
   * 7.9 Superclasses: It is a compile-time error to specify an extends clause for class Object.
   */
  static const CompileTimeErrorCode OBJECT_CANNOT_EXTEND_ANOTHER_CLASS = const CompileTimeErrorCode.con1('OBJECT_CANNOT_EXTEND_ANOTHER_CLASS', 130, "");

  /**
   * 7.1.1 Operators: It is a compile-time error to declare an optional parameter in an operator.
   */
  static const CompileTimeErrorCode OPTIONAL_PARAMETER_IN_OPERATOR = const CompileTimeErrorCode.con1('OPTIONAL_PARAMETER_IN_OPERATOR', 131, "Optional parameters are not allowed when defining an operator");

  /**
   * 14.3 Parts: It is a compile time error if the contents of the URI are not a valid part
   * declaration.
   *
   * @param uri the uri pointing to a non-library declaration
   */
  static const CompileTimeErrorCode PART_OF_NON_PART = const CompileTimeErrorCode.con1('PART_OF_NON_PART', 132, "The included part '{0}' must have a part-of directive");

  /**
   * 14.1 Imports: It is a compile-time error if the current library declares a top-level member
   * named <i>p</i>.
   */
  static const CompileTimeErrorCode PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER = const CompileTimeErrorCode.con1('PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER', 133, "The name '{0}' is already used as an import prefix and cannot be used to name a top-level element");

  /**
   * 6.2.2 Optional Formals: It is a compile-time error if the name of a named optional parameter
   * begins with an '_' character.
   */
  static const CompileTimeErrorCode PRIVATE_OPTIONAL_PARAMETER = const CompileTimeErrorCode.con1('PRIVATE_OPTIONAL_PARAMETER', 134, "Named optional parameters cannot start with an underscore");

  /**
   * 12.1 Constants: It is a compile-time error if the value of a compile-time constant expression
   * depends on itself.
   */
  static const CompileTimeErrorCode RECURSIVE_COMPILE_TIME_CONSTANT = const CompileTimeErrorCode.con1('RECURSIVE_COMPILE_TIME_CONSTANT', 135, "");

  /**
   * 7.6.1 Generative Constructors: A generative constructor may be redirecting, in which case its
   * only action is to invoke another generative constructor.
   *
   * TODO(scheglov) review this later, there are no explicit "it is a compile-time error" in
   * specification. But it was added to the co19 and there is same error for factories.
   *
   * https://code.google.com/p/dart/issues/detail?id=954
   */
  static const CompileTimeErrorCode RECURSIVE_CONSTRUCTOR_REDIRECT = const CompileTimeErrorCode.con1('RECURSIVE_CONSTRUCTOR_REDIRECT', 136, "Cycle in redirecting generative constructors");

  /**
   * 7.6.2 Factories: It is a compile-time error if a redirecting factory constructor redirects to
   * itself, either directly or indirectly via a sequence of redirections.
   */
  static const CompileTimeErrorCode RECURSIVE_FACTORY_REDIRECT = const CompileTimeErrorCode.con1('RECURSIVE_FACTORY_REDIRECT', 137, "Cycle in redirecting factory constructors");

  /**
   * 7.10 Superinterfaces: It is a compile-time error if the interface of a class <i>C</i> is a
   * superinterface of itself.
   *
   * 8.1 Superinterfaces: It is a compile-time error if an interface is a superinterface of itself.
   *
   * 7.9 Superclasses: It is a compile-time error if a class <i>C</i> is a superclass of itself.
   *
   * @param className the name of the class that implements itself recursively
   * @param strImplementsPath a string representation of the implements loop
   */
  static const CompileTimeErrorCode RECURSIVE_INTERFACE_INHERITANCE = const CompileTimeErrorCode.con1('RECURSIVE_INTERFACE_INHERITANCE', 138, "'{0}' cannot be a superinterface of itself: {1}");

  /**
   * 7.10 Superinterfaces: It is a compile-time error if the interface of a class <i>C</i> is a
   * superinterface of itself.
   *
   * 8.1 Superinterfaces: It is a compile-time error if an interface is a superinterface of itself.
   *
   * 7.9 Superclasses: It is a compile-time error if a class <i>C</i> is a superclass of itself.
   *
   * @param className the name of the class that implements itself recursively
   */
  static const CompileTimeErrorCode RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_EXTENDS = const CompileTimeErrorCode.con1('RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_EXTENDS', 139, "'{0}' cannot extend itself");

  /**
   * 7.10 Superinterfaces: It is a compile-time error if the interface of a class <i>C</i> is a
   * superinterface of itself.
   *
   * 8.1 Superinterfaces: It is a compile-time error if an interface is a superinterface of itself.
   *
   * 7.9 Superclasses: It is a compile-time error if a class <i>C</i> is a superclass of itself.
   *
   * @param className the name of the class that implements itself recursively
   */
  static const CompileTimeErrorCode RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS = const CompileTimeErrorCode.con1('RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS', 140, "'{0}' cannot implement itself");

  /**
   * 7.10 Superinterfaces: It is a compile-time error if the interface of a class <i>C</i> is a
   * superinterface of itself.
   *
   * 8.1 Superinterfaces: It is a compile-time error if an interface is a superinterface of itself.
   *
   * 7.9 Superclasses: It is a compile-time error if a class <i>C</i> is a superclass of itself.
   *
   * @param className the name of the class that implements itself recursively
   */
  static const CompileTimeErrorCode RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_WITH = const CompileTimeErrorCode.con1('RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_WITH', 141, "'{0}' cannot use itself as a mixin");

  /**
   * 7.6.2 Factories: It is a compile-time error if <i>k</i> is prefixed with the const modifier but
   * <i>k'</i> is not a constant constructor.
   */
  static const CompileTimeErrorCode REDIRECT_TO_MISSING_CONSTRUCTOR = const CompileTimeErrorCode.con1('REDIRECT_TO_MISSING_CONSTRUCTOR', 142, "The constructor '{0}' could not be found in '{1}'");

  /**
   * 7.6.2 Factories: It is a compile-time error if <i>k</i> is prefixed with the const modifier but
   * <i>k'</i> is not a constant constructor.
   */
  static const CompileTimeErrorCode REDIRECT_TO_NON_CLASS = const CompileTimeErrorCode.con1('REDIRECT_TO_NON_CLASS', 143, "The name '{0}' is not a type and cannot be used in a redirected constructor");

  /**
   * 7.6.2 Factories: It is a compile-time error if <i>k</i> is prefixed with the const modifier but
   * <i>k'</i> is not a constant constructor.
   */
  static const CompileTimeErrorCode REDIRECT_TO_NON_CONST_CONSTRUCTOR = const CompileTimeErrorCode.con1('REDIRECT_TO_NON_CONST_CONSTRUCTOR', 144, "Constant factory constructor cannot delegate to a non-constant constructor");

  /**
   * 7.6.1 Generative constructors: A generative constructor may be <i>redirecting</i>, in which
   * case its only action is to invoke another generative constructor.
   */
  static const CompileTimeErrorCode REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR = const CompileTimeErrorCode.con1('REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR', 145, "The constructor '{0}' could not be found in '{1}'");

  /**
   * 7.6.1 Generative constructors: A generative constructor may be <i>redirecting</i>, in which
   * case its only action is to invoke another generative constructor.
   */
  static const CompileTimeErrorCode REDIRECT_GENERATIVE_TO_NON_GENERATIVE_CONSTRUCTOR = const CompileTimeErrorCode.con1('REDIRECT_GENERATIVE_TO_NON_GENERATIVE_CONSTRUCTOR', 146, "Generative constructor cannot redirect to a factory constructor");

  /**
   * 5 Variables: A local variable may only be referenced at a source code location that is after
   * its initializer, if any, is complete, or a compile-time error occurs.
   */
  static const CompileTimeErrorCode REFERENCED_BEFORE_DECLARATION = const CompileTimeErrorCode.con1('REFERENCED_BEFORE_DECLARATION', 147, "Local variables cannot be referenced before they are declared");

  /**
   * 12.8.1 Rethrow: It is a compile-time error if an expression of the form <i>rethrow;</i> is not
   * enclosed within a on-catch clause.
   */
  static const CompileTimeErrorCode RETHROW_OUTSIDE_CATCH = const CompileTimeErrorCode.con1('RETHROW_OUTSIDE_CATCH', 148, "rethrow must be inside of a catch clause");

  /**
   * 13.12 Return: It is a compile-time error if a return statement of the form <i>return e;</i>
   * appears in a generative constructor.
   */
  static const CompileTimeErrorCode RETURN_IN_GENERATIVE_CONSTRUCTOR = const CompileTimeErrorCode.con1('RETURN_IN_GENERATIVE_CONSTRUCTOR', 149, "Constructors cannot return a value");

  /**
   * 13.12 Return: It is a compile-time error if a return statement of the form <i>return e;</i>
   * appears in a generator function.
   */
  static const CompileTimeErrorCode RETURN_IN_GENERATOR = const CompileTimeErrorCode.con1('RETURN_IN_GENERATOR', 150, "Cannot return a value from a generator function (one marked with either 'async*' or 'sync*')");

  /**
   * 14.1 Imports: It is a compile-time error if a prefix used in a deferred import is used in
   * another import clause.
   */
  static const CompileTimeErrorCode SHARED_DEFERRED_PREFIX = const CompileTimeErrorCode.con1('SHARED_DEFERRED_PREFIX', 151, "The prefix of a deferred import cannot be used in other import directives");

  /**
   * 12.15.4 Super Invocation: A super method invocation <i>i</i> has the form
   * <i>super.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;
   * x<sub>n+k</sub>: a<sub>n+k</sub>)</i>. It is a compile-time error if a super method invocation
   * occurs in a top-level function or variable initializer, in an instance variable initializer or
   * initializer list, in class Object, in a factory constructor, or in a static method or variable
   * initializer.
   */
  static const CompileTimeErrorCode SUPER_IN_INVALID_CONTEXT = const CompileTimeErrorCode.con1('SUPER_IN_INVALID_CONTEXT', 152, "Invalid context for 'super' invocation");

  /**
   * 7.6.1 Generative Constructors: A generative constructor may be redirecting, in which case its
   * only action is to invoke another generative constructor.
   */
  static const CompileTimeErrorCode SUPER_IN_REDIRECTING_CONSTRUCTOR = const CompileTimeErrorCode.con1('SUPER_IN_REDIRECTING_CONSTRUCTOR', 153, "The redirecting constructor cannot have a 'super' initializer");

  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It is a compile-time
   * error if a generative constructor of class Object includes a superinitializer.
   */
  static const CompileTimeErrorCode SUPER_INITIALIZER_IN_OBJECT = const CompileTimeErrorCode.con1('SUPER_INITIALIZER_IN_OBJECT', 154, "");

  /**
   * 12.11 Instance Creation: It is a static type warning if any of the type arguments to a
   * constructor of a generic type <i>G</i> invoked by a new expression or a constant object
   * expression are not subtypes of the bounds of the corresponding formal type parameters of
   * <i>G</i>.
   *
   * 12.11.1 New: If T is malformed a dynamic error occurs. In checked mode, if T is mal-bounded a
   * dynamic error occurs.
   *
   * 12.1 Constants: It is a compile-time error if evaluation of a compile-time constant would raise
   * an exception.
   *
   * @param boundedTypeName the name of the type used in the instance creation that should be
   *          limited by the bound as specified in the class declaration
   * @param boundingTypeName the name of the bounding type
   * @see StaticTypeWarningCode#TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
   */
  static const CompileTimeErrorCode TYPE_ARGUMENT_NOT_MATCHING_BOUNDS = const CompileTimeErrorCode.con1('TYPE_ARGUMENT_NOT_MATCHING_BOUNDS', 155, "'{0}' does not extend '{1}'");

  /**
   * 15.3.1 Typedef: Any self reference, either directly, or recursively via another typedef, is a
   * compile time error.
   */
  static const CompileTimeErrorCode TYPE_ALIAS_CANNOT_REFERENCE_ITSELF = const CompileTimeErrorCode.con1('TYPE_ALIAS_CANNOT_REFERENCE_ITSELF', 156, "Type alias cannot reference itself directly or recursively via another typedef");

  /**
   * 12.11.2 Const: It is a compile-time error if <i>T</i> is not a class accessible in the current
   * scope, optionally followed by type arguments.
   */
  static const CompileTimeErrorCode UNDEFINED_CLASS = const CompileTimeErrorCode.con1('UNDEFINED_CLASS', 157, "Undefined class '{0}'");

  /**
   * 7.6.1 Generative Constructors: Let <i>C</i> be the class in which the superinitializer appears
   * and let <i>S</i> be the superclass of <i>C</i>. Let <i>k</i> be a generative constructor. It is
   * a compile-time error if class <i>S</i> does not declare a generative constructor named <i>S</i>
   * (respectively <i>S.id</i>)
   */
  static const CompileTimeErrorCode UNDEFINED_CONSTRUCTOR_IN_INITIALIZER = const CompileTimeErrorCode.con1('UNDEFINED_CONSTRUCTOR_IN_INITIALIZER', 158, "The class '{0}' does not have a generative constructor '{1}'");

  /**
   * 7.6.1 Generative Constructors: Let <i>C</i> be the class in which the superinitializer appears
   * and let <i>S</i> be the superclass of <i>C</i>. Let <i>k</i> be a generative constructor. It is
   * a compile-time error if class <i>S</i> does not declare a generative constructor named <i>S</i>
   * (respectively <i>S.id</i>)
   */
  static const CompileTimeErrorCode UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT = const CompileTimeErrorCode.con1('UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT', 159, "The class '{0}' does not have a default generative constructor");

  /**
   * 12.14.2 Binding Actuals to Formals: Furthermore, each <i>q<sub>i</sub></i>, <i>1<=i<=l</i>,
   * must have a corresponding named parameter in the set {<i>p<sub>n+1</sub></i> ...
   * <i>p<sub>n+k</sub></i>} or a static warning occurs.
   *
   * 12.11.2 Const: It is a compile-time error if evaluation of a constant object results in an
   * uncaught exception being thrown.
   *
   * @param name the name of the requested named parameter
   */
  static const CompileTimeErrorCode UNDEFINED_NAMED_PARAMETER = const CompileTimeErrorCode.con1('UNDEFINED_NAMED_PARAMETER', 160, "The named parameter '{0}' is not defined");

  /**
   * 14.2 Exports: It is a compile-time error if the compilation unit found at the specified URI is
   * not a library declaration.
   *
   * 14.1 Imports: It is a compile-time error if the compilation unit found at the specified URI is
   * not a library declaration.
   *
   * 14.3 Parts: It is a compile time error if the contents of the URI are not a valid part
   * declaration.
   *
   * @param uri the URI pointing to a non-existent file
   * @see #INVALID_URI
   */
  static const CompileTimeErrorCode URI_DOES_NOT_EXIST = const CompileTimeErrorCode.con1('URI_DOES_NOT_EXIST', 161, "Target of URI does not exist: '{0}'");

  /**
   * 14.1 Imports: It is a compile-time error if <i>x</i> is not a compile-time constant, or if
   * <i>x</i> involves string interpolation.
   *
   * 14.3 Parts: It is a compile-time error if <i>s</i> is not a compile-time constant, or if
   * <i>s</i> involves string interpolation.
   *
   * 14.5 URIs: It is a compile-time error if the string literal <i>x</i> that describes a URI is
   * not a compile-time constant, or if <i>x</i> involves string interpolation.
   */
  static const CompileTimeErrorCode URI_WITH_INTERPOLATION = const CompileTimeErrorCode.con1('URI_WITH_INTERPOLATION', 162, "URIs cannot use string interpolation");

  /**
   * 7.1.1 Operators: It is a compile-time error if the arity of the user-declared operator []= is
   * not 2. It is a compile time error if the arity of a user-declared operator with one of the
   * names: &lt;, &gt;, &lt;=, &gt;=, ==, +, /, ~/, *, %, |, ^, &, &lt;&lt;, &gt;&gt;, [] is not 1.
   * It is a compile time error if the arity of the user-declared operator - is not 0 or 1. It is a
   * compile time error if the arity of the user-declared operator ~ is not 0.
   *
   * @param operatorName the name of the declared operator
   * @param expectedNumberOfParameters the number of parameters expected
   * @param actualNumberOfParameters the number of parameters found in the operator declaration
   */
  static const CompileTimeErrorCode WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR = const CompileTimeErrorCode.con1('WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR', 163, "Operator '{0}' should declare exactly {1} parameter(s), but {2} found");

  /**
   * 7.1.1 Operators: It is a compile time error if the arity of the user-declared operator - is not
   * 0 or 1.
   *
   * @param actualNumberOfParameters the number of parameters found in the operator declaration
   */
  static const CompileTimeErrorCode WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS = const CompileTimeErrorCode.con1('WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS', 164, "Operator '-' should declare 0 or 1 parameter, but {0} found");

  /**
   * 7.3 Setters: It is a compile-time error if a setter's formal parameter list does not include
   * exactly one required formal parameter <i>p</i>.
   */
  static const CompileTimeErrorCode WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER = const CompileTimeErrorCode.con1('WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER', 165, "Setters should declare exactly one required parameter");

  /**
   * ?? Yield: It is a compile-time error if a yield statement appears in a function that is not a
   * generator function.
   */
  static const CompileTimeErrorCode YIELD_EACH_IN_NON_GENERATOR = const CompileTimeErrorCode.con1('YIELD_EACH_IN_NON_GENERATOR', 166, "Yield-each statements must be in a generator function (one marked with either 'async*' or 'sync*')");

  /**
   * ?? Yield: It is a compile-time error if a yield statement appears in a function that is not a
   * generator function.
   */
  static const CompileTimeErrorCode YIELD_IN_NON_GENERATOR = const CompileTimeErrorCode.con1('YIELD_IN_NON_GENERATOR', 167, "Yield statements must be in a generator function (one marked with either 'async*' or 'sync*')");

  static const List<CompileTimeErrorCode> values = const [
      ACCESS_PRIVATE_ENUM_FIELD,
      AMBIGUOUS_EXPORT,
      ARGUMENT_DEFINITION_TEST_NON_PARAMETER,
      ASYNC_FOR_IN_WRONG_CONTEXT,
      AWAIT_IN_WRONG_CONTEXT,
      BUILT_IN_IDENTIFIER_AS_TYPE,
      BUILT_IN_IDENTIFIER_AS_TYPE_NAME,
      BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME,
      BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME,
      CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS,
      COMPILE_TIME_CONSTANT_RAISES_EXCEPTION,
      CONFLICTING_GETTER_AND_METHOD,
      CONFLICTING_METHOD_AND_GETTER,
      CONFLICTING_CONSTRUCTOR_NAME_AND_FIELD,
      CONFLICTING_CONSTRUCTOR_NAME_AND_METHOD,
      CONFLICTING_TYPE_VARIABLE_AND_CLASS,
      CONFLICTING_TYPE_VARIABLE_AND_MEMBER,
      CONST_CONSTRUCTOR_THROWS_EXCEPTION,
      CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST,
      CONST_CONSTRUCTOR_WITH_MIXIN,
      CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER,
      CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD,
      CONST_DEFERRED_CLASS,
      CONST_FORMAL_PARAMETER,
      CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE,
      CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY,
      CONST_INSTANCE_FIELD,
      CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS,
      CONST_NOT_INITIALIZED,
      CONST_EVAL_TYPE_BOOL,
      CONST_EVAL_TYPE_BOOL_NUM_STRING,
      CONST_EVAL_TYPE_INT,
      CONST_EVAL_TYPE_NUM,
      CONST_EVAL_THROWS_EXCEPTION,
      CONST_EVAL_THROWS_IDBZE,
      CONST_WITH_INVALID_TYPE_PARAMETERS,
      CONST_WITH_NON_CONST,
      CONST_WITH_NON_CONSTANT_ARGUMENT,
      CONST_WITH_NON_TYPE,
      CONST_WITH_TYPE_PARAMETERS,
      CONST_WITH_UNDEFINED_CONSTRUCTOR,
      CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT,
      DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS,
      DEFAULT_VALUE_IN_FUNCTION_TYPED_PARAMETER,
      DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR,
      DUPLICATE_CONSTRUCTOR_DEFAULT,
      DUPLICATE_CONSTRUCTOR_NAME,
      DUPLICATE_DEFINITION,
      DUPLICATE_DEFINITION_INHERITANCE,
      DUPLICATE_NAMED_ARGUMENT,
      EXPORT_INTERNAL_LIBRARY,
      EXPORT_OF_NON_LIBRARY,
      EXTENDS_ENUM,
      EXTENDS_NON_CLASS,
      EXTENDS_DISALLOWED_CLASS,
      EXTENDS_DEFERRED_CLASS,
      EXTRA_POSITIONAL_ARGUMENTS,
      FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS,
      FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER,
      FINAL_INITIALIZED_MULTIPLE_TIMES,
      FIELD_INITIALIZER_FACTORY_CONSTRUCTOR,
      FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR,
      FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR,
      GETTER_AND_METHOD_WITH_SAME_NAME,
      IMPLEMENTS_DEFERRED_CLASS,
      IMPLEMENTS_DISALLOWED_CLASS,
      IMPLEMENTS_DYNAMIC,
      IMPLEMENTS_ENUM,
      IMPLEMENTS_NON_CLASS,
      IMPLEMENTS_REPEATED,
      IMPLEMENTS_SUPER_CLASS,
      IMPLICIT_THIS_REFERENCE_IN_INITIALIZER,
      IMPORT_INTERNAL_LIBRARY,
      IMPORT_OF_NON_LIBRARY,
      INCONSISTENT_CASE_EXPRESSION_TYPES,
      INITIALIZER_FOR_NON_EXISTENT_FIELD,
      INITIALIZER_FOR_STATIC_FIELD,
      INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD,
      INITIALIZING_FORMAL_FOR_STATIC_FIELD,
      INSTANCE_MEMBER_ACCESS_FROM_FACTORY,
      INSTANCE_MEMBER_ACCESS_FROM_STATIC,
      INSTANTIATE_ENUM,
      INVALID_ANNOTATION,
      INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY,
      INVALID_IDENTIFIER_IN_ASYNC,
      INVALID_MODIFIER_ON_CONSTRUCTOR,
      INVALID_MODIFIER_ON_SETTER,
      INVALID_CONSTANT,
      INVALID_CONSTRUCTOR_NAME,
      INVALID_FACTORY_NAME_NOT_A_CLASS,
      INVALID_REFERENCE_TO_THIS,
      INVALID_TYPE_ARGUMENT_IN_CONST_LIST,
      INVALID_TYPE_ARGUMENT_IN_CONST_MAP,
      INVALID_URI,
      LABEL_IN_OUTER_SCOPE,
      LABEL_UNDEFINED,
      MEMBER_WITH_CLASS_NAME,
      METHOD_AND_GETTER_WITH_SAME_NAME,
      MISSING_CONST_IN_LIST_LITERAL,
      MISSING_CONST_IN_MAP_LITERAL,
      MISSING_ENUM_CONSTANT_IN_SWITCH,
      MIXIN_DECLARES_CONSTRUCTOR,
      MIXIN_DEFERRED_CLASS,
      MIXIN_INHERITS_FROM_NOT_OBJECT,
      MIXIN_OF_DISALLOWED_CLASS,
      MIXIN_OF_ENUM,
      MIXIN_OF_NON_CLASS,
      MIXIN_REFERENCES_SUPER,
      MIXIN_WITH_NON_CLASS_SUPERCLASS,
      MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS,
      MULTIPLE_SUPER_INITIALIZERS,
      NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS,
      NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT,
      NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT,
      NON_CONST_MAP_AS_EXPRESSION_STATEMENT,
      NON_CONSTANT_CASE_EXPRESSION,
      NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY,
      NON_CONSTANT_DEFAULT_VALUE,
      NON_CONSTANT_DEFAULT_VALUE_FROM_DEFERRED_LIBRARY,
      NON_CONSTANT_LIST_ELEMENT,
      NON_CONSTANT_LIST_ELEMENT_FROM_DEFERRED_LIBRARY,
      NON_CONSTANT_MAP_KEY,
      NON_CONSTANT_MAP_KEY_FROM_DEFERRED_LIBRARY,
      NON_CONSTANT_MAP_VALUE,
      NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY,
      NON_CONSTANT_ANNOTATION_CONSTRUCTOR,
      NON_CONSTANT_VALUE_IN_INITIALIZER,
      NON_CONSTANT_VALUE_IN_INITIALIZER_FROM_DEFERRED_LIBRARY,
      NOT_ENOUGH_REQUIRED_ARGUMENTS,
      NON_GENERATIVE_CONSTRUCTOR,
      OBJECT_CANNOT_EXTEND_ANOTHER_CLASS,
      OPTIONAL_PARAMETER_IN_OPERATOR,
      PART_OF_NON_PART,
      PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER,
      PRIVATE_OPTIONAL_PARAMETER,
      RECURSIVE_COMPILE_TIME_CONSTANT,
      RECURSIVE_CONSTRUCTOR_REDIRECT,
      RECURSIVE_FACTORY_REDIRECT,
      RECURSIVE_INTERFACE_INHERITANCE,
      RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_EXTENDS,
      RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS,
      RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_WITH,
      REDIRECT_TO_MISSING_CONSTRUCTOR,
      REDIRECT_TO_NON_CLASS,
      REDIRECT_TO_NON_CONST_CONSTRUCTOR,
      REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR,
      REDIRECT_GENERATIVE_TO_NON_GENERATIVE_CONSTRUCTOR,
      REFERENCED_BEFORE_DECLARATION,
      RETHROW_OUTSIDE_CATCH,
      RETURN_IN_GENERATIVE_CONSTRUCTOR,
      RETURN_IN_GENERATOR,
      SHARED_DEFERRED_PREFIX,
      SUPER_IN_INVALID_CONTEXT,
      SUPER_IN_REDIRECTING_CONSTRUCTOR,
      SUPER_INITIALIZER_IN_OBJECT,
      TYPE_ARGUMENT_NOT_MATCHING_BOUNDS,
      TYPE_ALIAS_CANNOT_REFERENCE_ITSELF,
      UNDEFINED_CLASS,
      UNDEFINED_CONSTRUCTOR_IN_INITIALIZER,
      UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT,
      UNDEFINED_NAMED_PARAMETER,
      URI_DOES_NOT_EXIST,
      URI_WITH_INTERPOLATION,
      WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR,
      WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS,
      WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER,
      YIELD_EACH_IN_NON_GENERATOR,
      YIELD_IN_NON_GENERATOR];

  /**
   * The template used to create the message to be displayed for this error.
   */
  final String message;

  /**
   * The template used to create the correction to be displayed for this error, or `null` if
   * there is no correction information for this error.
   */
  final String correction;

  /**
   * Initialize a newly created error code to have the given message.
   *
   * @param message the message template used to create the message to be displayed for the error
   */
  const CompileTimeErrorCode.con1(String name, int ordinal, String message) : this.con2(name, ordinal, message, null);

  /**
   * Initialize a newly created error code to have the given message and correction.
   *
   * @param message the template used to create the message to be displayed for the error
   * @param correction the template used to create the correction to be displayed for the error
   */
  const CompileTimeErrorCode.con2(String name, int ordinal, this.message, this.correction) : super(name, ordinal);

  @override
  ErrorSeverity get errorSeverity => ErrorType.COMPILE_TIME_ERROR.severity;

  @override
  ErrorType get type => ErrorType.COMPILE_TIME_ERROR;

  @override
  String get uniqueName => "${runtimeType.toString()}.${name}";
}

/**
 * The interface `ErrorCode` defines the behavior common to objects representing error codes
 * associated with [AnalysisError].
 *
 * Generally, we want to provide messages that consist of three sentences: 1. what is wrong, 2. why
 * is it wrong, and 3. how do I fix it. However, we combine the first two in the result of
 * [getMessage] and the last in the result of [getCorrection].
 */
abstract class ErrorCode {
  /**
   * Return the template used to create the correction to be displayed for this error, or
   * `null` if there is no correction information for this error. The correction should
   * indicate how the user can fix the error.
   *
   * @return the template used to create the correction to be displayed for this error
   */
  String get correction;

  /**
   * Return the severity of this error.
   *
   * @return the severity of this error
   */
  ErrorSeverity get errorSeverity;

  /**
   * Return the template used to create the message to be displayed for this error. The message
   * should indicate what is wrong and why it is wrong.
   *
   * @return the template used to create the message to be displayed for this error
   */
  String get message;

  /**
   * Return the type of the error.
   *
   * @return the type of the error
   */
  ErrorType get type;

  /**
   * Return a unique name for this error code.
   *
   * @return a unique name for this error code
   */
  String get uniqueName;
}

/**
 * The enumeration `ErrorProperty` defines the properties that can be associated with an
 * [AnalysisError].
 */
class ErrorProperty extends Enum<ErrorProperty> {
  /**
   * A property whose value is an array of [ExecutableElement] that should
   * be but are not implemented by a concrete class.
   */
  static const ErrorProperty UNIMPLEMENTED_METHODS = const ErrorProperty('UNIMPLEMENTED_METHODS', 0);

  static const List<ErrorProperty> values = const [UNIMPLEMENTED_METHODS];

  const ErrorProperty(String name, int ordinal) : super(name, ordinal);
}

/**
 * Instances of the class `ErrorReporter` wrap an error listener with utility methods used to
 * create the errors being reported.
 */
class ErrorReporter {
  /**
   * The error listener to which errors will be reported.
   */
  final AnalysisErrorListener _errorListener;

  /**
   * The default source to be used when reporting errors.
   */
  final Source _defaultSource;

  /**
   * The source to be used when reporting errors.
   */
  Source _source;

  /**
   * Initialize a newly created error reporter that will report errors to the given listener.
   *
   * @param errorListener the error listener to which errors will be reported
   * @param defaultSource the default source to be used when reporting errors
   */
  ErrorReporter(this._errorListener, this._defaultSource) {
    if (_errorListener == null) {
      throw new IllegalArgumentException("An error listener must be provided");
    } else if (_defaultSource == null) {
      throw new IllegalArgumentException("A default source must be provided");
    }
    this._source = _defaultSource;
  }

  Source get source => _source;

  /**
   * Creates an error with properties with the given error code and arguments.
   *
   * @param errorCode the error code of the error to be reported
   * @param node the node specifying the location of the error
   * @param arguments the arguments to the error, used to compose the error message
   */
  AnalysisErrorWithProperties newErrorWithProperties(ErrorCode errorCode, AstNode node, List<Object> arguments) => new AnalysisErrorWithProperties.con2(_source, node.offset, node.length, errorCode, arguments);

  /**
   * Report a passed error.
   *
   * @param error the error to report
   */
  void reportError(AnalysisError error) {
    _errorListener.onError(error);
  }

  /**
   * Report an error with the given error code and arguments.
   *
   * @param errorCode the error code of the error to be reported
   * @param element the element which name should be used as the location of the error
   * @param arguments the arguments to the error, used to compose the error message
   */
  void reportErrorForElement(ErrorCode errorCode, Element element, List<Object> arguments) {
    reportErrorForOffset(errorCode, element.nameOffset, element.displayName.length, arguments);
  }

  /**
   * Report an error with the given error code and arguments.
   *
   * If the arguments contain the names of two or more types, the method
   * [reportTypeErrorForNode] should be used and the types
   * themselves (rather than their names) should be passed as arguments.
   *
   * @param errorCode the error code of the error to be reported
   * @param node the node specifying the location of the error
   * @param arguments the arguments to the error, used to compose the error message
   */
  void reportErrorForNode(ErrorCode errorCode, AstNode node, List<Object> arguments) {
    reportErrorForOffset(errorCode, node.offset, node.length, arguments);
  }

  /**
   * Report an error with the given error code and arguments.
   *
   * @param errorCode the error code of the error to be reported
   * @param offset the offset of the location of the error
   * @param length the length of the location of the error
   * @param arguments the arguments to the error, used to compose the error message
   */
  void reportErrorForOffset(ErrorCode errorCode, int offset, int length, List<Object> arguments) {
    _errorListener.onError(new AnalysisError.con2(_source, offset, length, errorCode, arguments));
  }

  /**
   * Report an error with the given error code and arguments.
   *
   * @param errorCode the error code of the error to be reported
   * @param token the token specifying the location of the error
   * @param arguments the arguments to the error, used to compose the error message
   */
  void reportErrorForToken(ErrorCode errorCode, Token token, List<Object> arguments) {
    reportErrorForOffset(errorCode, token.offset, token.length, arguments);
  }

  /**
   * Report an error with the given error code and arguments. The arguments are expected to contain
   * two or more types. Convert the types into strings by using the display names of the types,
   * unless there are two or more types with the same names, in which case the extended display
   * names of the types will be used in order to clarify the message.
   *
   * If there are not two or more types in the argument list, the method
   * [reportErrorForNode] should be used instead.
   *
   * @param errorCode the error code of the error to be reported
   * @param node the node specifying the location of the error
   * @param arguments the arguments to the error, used to compose the error message
   */
  void reportTypeErrorForNode(ErrorCode errorCode, AstNode node, List<Object> arguments) {
    _convertTypeNames(arguments);
    reportErrorForOffset(errorCode, node.offset, node.length, arguments);
  }

  /**
   * Set the source to be used when reporting errors. Setting the source to `null` will cause
   * the default source to be used.
   *
   * @param source the source to be used when reporting errors
   */
  void set source(Source source) {
    this._source = source == null ? _defaultSource : source;
  }

  /**
   * Given an array of arguments that is expected to contain two or more types, convert the types
   * into strings by using the display names of the types, unless there are two or more types with
   * the same names, in which case the extended display names of the types will be used in order to
   * clarify the message.
   *
   * @param arguments the arguments that are to be converted
   */
  void _convertTypeNames(List<Object> arguments) {
    if (_hasEqualTypeNames(arguments)) {
      int count = arguments.length;
      for (int i = 0; i < count; i++) {
        Object argument = arguments[i];
        if (argument is DartType) {
          DartType type = argument;
          Element element = type.element;
          if (element == null) {
            arguments[i] = type.displayName;
          } else {
            arguments[i] = element.getExtendedDisplayName(type.displayName);
          }
        }
      }
    } else {
      int count = arguments.length;
      for (int i = 0; i < count; i++) {
        Object argument = arguments[i];
        if (argument is DartType) {
          arguments[i] = argument.displayName;
        }
      }
    }
  }

  /**
   * Return `true` if the given array of arguments contains two or more types with the same
   * display name.
   *
   * @param arguments the arguments being tested
   * @return `true` if the array of arguments contains two or more types with the same display
   *         name
   */
  bool _hasEqualTypeNames(List<Object> arguments) {
    int count = arguments.length;
    HashSet<String> typeNames = new HashSet<String>();
    for (int i = 0; i < count; i++) {
      if (arguments[i] is DartType && !typeNames.add((arguments[i] as DartType).displayName)) {
        return true;
      }
    }
    return false;
  }
}

/**
 * Instances of the enumeration `ErrorSeverity` represent the severity of an [ErrorCode]
 * .
 */
class ErrorSeverity extends Enum<ErrorSeverity> {
  /**
   * The severity representing a non-error. This is never used for any error code, but is useful for
   * clients.
   */
  static const ErrorSeverity NONE = const ErrorSeverity('NONE', 0, " ", "none");

  /**
   * The severity representing an informational level analysis issue.
   */
  static const ErrorSeverity INFO = const ErrorSeverity('INFO', 1, "I", "info");

  /**
   * The severity representing a warning. Warnings can become errors if the `-Werror` command
   * line flag is specified.
   */
  static const ErrorSeverity WARNING = const ErrorSeverity('WARNING', 2, "W", "warning");

  /**
   * The severity representing an error.
   */
  static const ErrorSeverity ERROR = const ErrorSeverity('ERROR', 3, "E", "error");

  static const List<ErrorSeverity> values = const [NONE, INFO, WARNING, ERROR];

  /**
   * The name of the severity used when producing machine output.
   */
  final String machineCode;

  /**
   * The name of the severity used when producing readable output.
   */
  final String displayName;

  /**
   * Initialize a newly created severity with the given names.
   *
   * @param machineCode the name of the severity used when producing machine output
   * @param displayName the name of the severity used when producing readable output
   */
  const ErrorSeverity(String name, int ordinal, this.machineCode, this.displayName) : super(name, ordinal);

  /**
   * Return the severity constant that represents the greatest severity.
   *
   * @param severity the severity being compared against
   * @return the most sever of this or the given severity
   */
  ErrorSeverity max(ErrorSeverity severity) => this.ordinal >= severity.ordinal ? this : severity;
}

/**
 * Instances of the enumeration `ErrorType` represent the type of an [ErrorCode].
 */
class ErrorType extends Enum<ErrorType> {
  /**
   * Task (todo) comments in user code.
   */
  static const ErrorType TODO = const ErrorType('TODO', 0, ErrorSeverity.INFO);

  /**
   * Extra analysis run over the code to follow best practices, which are not in the Dart Language
   * Specification.
   */
  static const ErrorType HINT = const ErrorType('HINT', 1, ErrorSeverity.INFO);

  /**
   * Compile-time errors are errors that preclude execution. A compile time error must be reported
   * by a Dart compiler before the erroneous code is executed.
   */
  static const ErrorType COMPILE_TIME_ERROR = const ErrorType('COMPILE_TIME_ERROR', 2, ErrorSeverity.ERROR);

  /**
   * Checked mode compile-time errors are errors that preclude execution in checked mode.
   */
  static const ErrorType CHECKED_MODE_COMPILE_TIME_ERROR = const ErrorType('CHECKED_MODE_COMPILE_TIME_ERROR', 3, ErrorSeverity.ERROR);

  /**
   * Static warnings are those warnings reported by the static checker. They have no effect on
   * execution. Static warnings must be provided by Dart compilers used during development.
   */
  static const ErrorType STATIC_WARNING = const ErrorType('STATIC_WARNING', 4, ErrorSeverity.WARNING);

  /**
   * Many, but not all, static warnings relate to types, in which case they are known as static type
   * warnings.
   */
  static const ErrorType STATIC_TYPE_WARNING = const ErrorType('STATIC_TYPE_WARNING', 5, ErrorSeverity.WARNING);

  /**
   * Syntactic errors are errors produced as a result of input that does not conform to the grammar.
   */
  static const ErrorType SYNTACTIC_ERROR = const ErrorType('SYNTACTIC_ERROR', 6, ErrorSeverity.ERROR);

  /**
   * Angular specific semantic problems.
   */
  static const ErrorType ANGULAR = const ErrorType('ANGULAR', 7, ErrorSeverity.INFO);

  /**
   * Polymer specific semantic problems.
   */
  static const ErrorType POLYMER = const ErrorType('POLYMER', 8, ErrorSeverity.INFO);

  static const List<ErrorType> values = const [
      TODO,
      HINT,
      COMPILE_TIME_ERROR,
      CHECKED_MODE_COMPILE_TIME_ERROR,
      STATIC_WARNING,
      STATIC_TYPE_WARNING,
      SYNTACTIC_ERROR,
      ANGULAR,
      POLYMER];

  /**
   * The severity of this type of error.
   */
  final ErrorSeverity severity;

  /**
   * Initialize a newly created error type to have the given severity.
   *
   * @param severity the severity of this type of error
   */
  const ErrorType(String name, int ordinal, this.severity) : super(name, ordinal);

  String get displayName => name.toLowerCase().replaceAll('_', ' ');
}

/**
 * The enumeration `HintCode` defines the hints and coding recommendations for best practices
 * which are not mentioned in the Dart Language Specification.
 */
class HintCode extends Enum<HintCode> implements ErrorCode {
  /**
   * This hint is generated anywhere where the
   * [StaticWarningCode#ARGUMENT_TYPE_NOT_ASSIGNABLE] would have been generated, if we used
   * propagated information for the warnings.
   *
   * @param actualType the name of the actual argument type
   * @param expectedType the name of the expected type
   * @see StaticWarningCode#ARGUMENT_TYPE_NOT_ASSIGNABLE
   */
  static const HintCode ARGUMENT_TYPE_NOT_ASSIGNABLE = const HintCode.con1('ARGUMENT_TYPE_NOT_ASSIGNABLE', 0, "The argument type '{0}' cannot be assigned to the parameter type '{1}'");

  /**
   * Dead code is code that is never reached, this can happen for instance if a statement follows a
   * return statement.
   */
  static const HintCode DEAD_CODE = const HintCode.con1('DEAD_CODE', 1, "Dead code");

  /**
   * Dead code is code that is never reached. This case covers cases where the user has catch
   * clauses after `catch (e)` or `on Object catch (e)`.
   */
  static const HintCode DEAD_CODE_CATCH_FOLLOWING_CATCH = const HintCode.con1('DEAD_CODE_CATCH_FOLLOWING_CATCH', 2, "Dead code, catch clauses after a 'catch (e)' or an 'on Object catch (e)' are never reached");

  /**
   * Dead code is code that is never reached. This case covers cases where the user has an on-catch
   * clause such as `on A catch (e)`, where a supertype of `A` was already caught.
   *
   * @param subtypeName name of the subtype
   * @param supertypeName name of the supertype
   */
  static const HintCode DEAD_CODE_ON_CATCH_SUBTYPE = const HintCode.con1('DEAD_CODE_ON_CATCH_SUBTYPE', 3, "Dead code, this on-catch block will never be executed since '{0}' is a subtype of '{1}'");

  /**
   * Deprecated members should not be invoked or used.
   *
   * @param memberName the name of the member
   */
  static const HintCode DEPRECATED_MEMBER_USE = const HintCode.con1('DEPRECATED_MEMBER_USE', 4, "'{0}' is deprecated");

  /**
   * Duplicate imports.
   */
  static const HintCode DUPLICATE_IMPORT = const HintCode.con1('DUPLICATE_IMPORT', 5, "Duplicate import");

  /**
   * Hint to use the ~/ operator.
   */
  static const HintCode DIVISION_OPTIMIZATION = const HintCode.con1('DIVISION_OPTIMIZATION', 6, "The operator x ~/ y is more efficient than (x / y).toInt()");

  /**
   * Hint for the `x is double` type checks.
   */
  static const HintCode IS_DOUBLE = const HintCode.con1('IS_DOUBLE', 7, "When compiled to JS, this test might return true when the left hand side is an int");

  /**
   * Hint for the `x is int` type checks.
   */
  static const HintCode IS_INT = const HintCode.con1('IS_INT', 8, "When compiled to JS, this test might return true when the left hand side is a double");

  /**
   * Hint for the `x is! double` type checks.
   */
  static const HintCode IS_NOT_DOUBLE = const HintCode.con1('IS_NOT_DOUBLE', 9, "When compiled to JS, this test might return false when the left hand side is an int");

  /**
   * Hint for the `x is! int` type checks.
   */
  static const HintCode IS_NOT_INT = const HintCode.con1('IS_NOT_INT', 10, "When compiled to JS, this test might return false when the left hand side is a double");

  /**
   * Deferred libraries shouldn't define a top level function 'loadLibrary'.
   */
  static const HintCode IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION = const HintCode.con1('IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION', 11, "The library '{0}' defines a top-level function named 'loadLibrary' which is hidden by deferring this library");

  /**
   * This hint is generated anywhere where the [StaticTypeWarningCode#INVALID_ASSIGNMENT]
   * would have been generated, if we used propagated information for the warnings.
   *
   * @param rhsTypeName the name of the right hand side type
   * @param lhsTypeName the name of the left hand side type
   * @see StaticTypeWarningCode#INVALID_ASSIGNMENT
   */
  static const HintCode INVALID_ASSIGNMENT = const HintCode.con1('INVALID_ASSIGNMENT', 12, "A value of type '{0}' cannot be assigned to a variable of type '{1}'");

  /**
   * Generate a hint for methods or functions that have a return type, but do not have a non-void
   * return statement on all branches. At the end of methods or functions with no return, Dart
   * implicitly returns `null`, avoiding these implicit returns is considered a best practice.
   *
   * @param returnType the name of the declared return type
   */
  static const HintCode MISSING_RETURN = const HintCode.con2('MISSING_RETURN', 13, "This function declares a return type of '{0}', but does not end with a return statement", "Either add a return statement or change the return type to 'void'");

  /**
   * A getter with the override annotation does not override an existing getter.
   */
  static const HintCode OVERRIDE_ON_NON_OVERRIDING_GETTER = const HintCode.con1('OVERRIDE_ON_NON_OVERRIDING_GETTER', 14, "Getter does not override an inherited getter");

  /**
   * A method with the override annotation does not override an existing method.
   */
  static const HintCode OVERRIDE_ON_NON_OVERRIDING_METHOD = const HintCode.con1('OVERRIDE_ON_NON_OVERRIDING_METHOD', 15, "Method does not override an inherited method");

  /**
   * A setter with the override annotation does not override an existing setter.
   */
  static const HintCode OVERRIDE_ON_NON_OVERRIDING_SETTER = const HintCode.con1('OVERRIDE_ON_NON_OVERRIDING_SETTER', 16, "Setter does not override an inherited setter");

  /**
   * Hint for classes that override equals, but not hashCode.
   *
   * @param className the name of the current class
   */
  static const HintCode OVERRIDE_EQUALS_BUT_NOT_HASH_CODE = const HintCode.con1('OVERRIDE_EQUALS_BUT_NOT_HASH_CODE', 17, "The class '{0}' overrides 'operator==', but not 'get hashCode'");

  /**
   * Type checks of the type `x is! Null` should be done with `x != null`.
   */
  static const HintCode TYPE_CHECK_IS_NOT_NULL = const HintCode.con1('TYPE_CHECK_IS_NOT_NULL', 18, "Tests for non-null should be done with '!= null'");

  /**
   * Type checks of the type `x is Null` should be done with `x == null`.
   */
  static const HintCode TYPE_CHECK_IS_NULL = const HintCode.con1('TYPE_CHECK_IS_NULL', 19, "Tests for null should be done with '== null'");

  /**
   * This hint is generated anywhere where the [StaticTypeWarningCode#UNDEFINED_GETTER] or
   * [StaticWarningCode#UNDEFINED_GETTER] would have been generated, if we used propagated
   * information for the warnings.
   *
   * @param getterName the name of the getter
   * @param enclosingType the name of the enclosing type where the getter is being looked for
   * @see StaticTypeWarningCode#UNDEFINED_GETTER
   * @see StaticWarningCode#UNDEFINED_GETTER
   */
  static const HintCode UNDEFINED_GETTER = const HintCode.con1('UNDEFINED_GETTER', 20, "There is no such getter '{0}' in '{1}'");

  /**
   * This hint is generated anywhere where the [StaticTypeWarningCode#UNDEFINED_METHOD] would
   * have been generated, if we used propagated information for the warnings.
   *
   * @param methodName the name of the method that is undefined
   * @param typeName the resolved type name that the method lookup is happening on
   * @see StaticTypeWarningCode#UNDEFINED_METHOD
   */
  static const HintCode UNDEFINED_METHOD = const HintCode.con1('UNDEFINED_METHOD', 21, "The method '{0}' is not defined for the class '{1}'");

  /**
   * This hint is generated anywhere where the [StaticTypeWarningCode#UNDEFINED_OPERATOR]
   * would have been generated, if we used propagated information for the warnings.
   *
   * @param operator the name of the operator
   * @param enclosingType the name of the enclosing type where the operator is being looked for
   * @see StaticTypeWarningCode#UNDEFINED_OPERATOR
   */
  static const HintCode UNDEFINED_OPERATOR = const HintCode.con1('UNDEFINED_OPERATOR', 22, "There is no such operator '{0}' in '{1}'");

  /**
   * This hint is generated anywhere where the [StaticTypeWarningCode#UNDEFINED_SETTER] or
   * [StaticWarningCode#UNDEFINED_SETTER] would have been generated, if we used propagated
   * information for the warnings.
   *
   * @param setterName the name of the setter
   * @param enclosingType the name of the enclosing type where the setter is being looked for
   * @see StaticTypeWarningCode#UNDEFINED_SETTER
   * @see StaticWarningCode#UNDEFINED_SETTER
   */
  static const HintCode UNDEFINED_SETTER = const HintCode.con1('UNDEFINED_SETTER', 23, "There is no such setter '{0}' in '{1}'");

  /**
   * Unnecessary cast.
   */
  static const HintCode UNNECESSARY_CAST = const HintCode.con1('UNNECESSARY_CAST', 24, "Unnecessary cast");

  /**
   * Unnecessary type checks, the result is always true.
   */
  static const HintCode UNNECESSARY_TYPE_CHECK_FALSE = const HintCode.con1('UNNECESSARY_TYPE_CHECK_FALSE', 25, "Unnecessary type check, the result is always false");

  /**
   * Unnecessary type checks, the result is always false.
   */
  static const HintCode UNNECESSARY_TYPE_CHECK_TRUE = const HintCode.con1('UNNECESSARY_TYPE_CHECK_TRUE', 26, "Unnecessary type check, the result is always true");

  /**
   * Unused imports are imports which are never not used.
   */
  static const HintCode UNUSED_IMPORT = const HintCode.con1('UNUSED_IMPORT', 27, "Unused import");

  /**
   * Hint for cases where the source expects a method or function to return a non-void result, but
   * the method or function signature returns void.
   *
   * @param name the name of the method or function that returns void
   */
  static const HintCode USE_OF_VOID_RESULT = const HintCode.con1('USE_OF_VOID_RESULT', 28, "The result of '{0}' is being used, even though it is declared to be 'void'");

  /**
   * It is a bad practice for a source file in a package "lib" directory hierarchy to traverse
   * outside that directory hierarchy. For example, a source file in the "lib" directory should not
   * contain a directive such as `import '../web/some.dart'` which references a file outside
   * the lib directory.
   */
  static const HintCode FILE_IMPORT_INSIDE_LIB_REFERENCES_FILE_OUTSIDE = const HintCode.con1('FILE_IMPORT_INSIDE_LIB_REFERENCES_FILE_OUTSIDE', 29, "A file in the 'lib' directory hierarchy should not reference a file outside that hierarchy");

  /**
   * It is a bad practice for a source file ouside a package "lib" directory hierarchy to traverse
   * into that directory hierarchy. For example, a source file in the "web" directory should not
   * contain a directive such as `import '../lib/some.dart'` which references a file inside
   * the lib directory.
   */
  static const HintCode FILE_IMPORT_OUTSIDE_LIB_REFERENCES_FILE_INSIDE = const HintCode.con1('FILE_IMPORT_OUTSIDE_LIB_REFERENCES_FILE_INSIDE', 30, "A file outside the 'lib' directory hierarchy should not reference a file inside that hierarchy. Use a package: reference instead.");

  /**
   * It is a bad practice for a package import to reference anything outside the given package, or
   * more generally, it is bad practice for a package import to contain a "..". For example, a
   * source file should not contain a directive such as `import 'package:foo/../some.dart'`.
   */
  static const HintCode PACKAGE_IMPORT_CONTAINS_DOT_DOT = const HintCode.con1('PACKAGE_IMPORT_CONTAINS_DOT_DOT', 31, "A package import should not contain '..'");

  static const List<HintCode> values = const [
      ARGUMENT_TYPE_NOT_ASSIGNABLE,
      DEAD_CODE,
      DEAD_CODE_CATCH_FOLLOWING_CATCH,
      DEAD_CODE_ON_CATCH_SUBTYPE,
      DEPRECATED_MEMBER_USE,
      DUPLICATE_IMPORT,
      DIVISION_OPTIMIZATION,
      IS_DOUBLE,
      IS_INT,
      IS_NOT_DOUBLE,
      IS_NOT_INT,
      IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION,
      INVALID_ASSIGNMENT,
      MISSING_RETURN,
      OVERRIDE_ON_NON_OVERRIDING_GETTER,
      OVERRIDE_ON_NON_OVERRIDING_METHOD,
      OVERRIDE_ON_NON_OVERRIDING_SETTER,
      OVERRIDE_EQUALS_BUT_NOT_HASH_CODE,
      TYPE_CHECK_IS_NOT_NULL,
      TYPE_CHECK_IS_NULL,
      UNDEFINED_GETTER,
      UNDEFINED_METHOD,
      UNDEFINED_OPERATOR,
      UNDEFINED_SETTER,
      UNNECESSARY_CAST,
      UNNECESSARY_TYPE_CHECK_FALSE,
      UNNECESSARY_TYPE_CHECK_TRUE,
      UNUSED_IMPORT,
      USE_OF_VOID_RESULT,
      FILE_IMPORT_INSIDE_LIB_REFERENCES_FILE_OUTSIDE,
      FILE_IMPORT_OUTSIDE_LIB_REFERENCES_FILE_INSIDE,
      PACKAGE_IMPORT_CONTAINS_DOT_DOT];

  /**
   * The template used to create the message to be displayed for this error.
   */
  final String message;

  /**
   * The template used to create the correction to be displayed for this error, or `null` if
   * there is no correction information for this error.
   */
  final String correction;

  /**
   * Initialize a newly created error code to have the given message.
   *
   * @param message the message template used to create the message to be displayed for the error
   */
  const HintCode.con1(String name, int ordinal, String message) : this.con2(name, ordinal, message, null);

  /**
   * Initialize a newly created error code to have the given message and correction.
   *
   * @param message the template used to create the message to be displayed for the error
   * @param correction the template used to create the correction to be displayed for the error
   */
  const HintCode.con2(String name, int ordinal, this.message, this.correction) : super(name, ordinal);

  @override
  ErrorSeverity get errorSeverity => ErrorType.HINT.severity;

  @override
  ErrorType get type => ErrorType.HINT;

  @override
  String get uniqueName => "${runtimeType.toString()}.${name}";
}

/**
 * The enumeration `HtmlWarningCode` defines the error codes used for warnings in HTML files.
 * The convention for this class is for the name of the error code to indicate the problem that
 * caused the error to be generated and for the error message to explain what is wrong and, when
 * appropriate, how the problem can be corrected.
 */
class HtmlWarningCode extends Enum<HtmlWarningCode> implements ErrorCode {
  /**
   * An error code indicating that the value of the 'src' attribute of a Dart script tag is not a
   * valid URI.
   *
   * @param uri the URI that is invalid
   */
  static const HtmlWarningCode INVALID_URI = const HtmlWarningCode.con1('INVALID_URI', 0, "Invalid URI syntax: '{0}'");

  /**
   * An error code indicating that the value of the 'src' attribute of a Dart script tag references
   * a file that does not exist.
   *
   * @param uri the URI pointing to a non-existent file
   */
  static const HtmlWarningCode URI_DOES_NOT_EXIST = const HtmlWarningCode.con1('URI_DOES_NOT_EXIST', 1, "Target of URI does not exist: '{0}'");

  static const List<HtmlWarningCode> values = const [INVALID_URI, URI_DOES_NOT_EXIST];

  /**
   * The template used to create the message to be displayed for this error.
   */
  final String message;

  /**
   * The template used to create the correction to be displayed for this error, or `null` if
   * there is no correction information for this error.
   */
  final String correction;

  /**
   * Initialize a newly created error code to have the given message.
   *
   * @param message the message template used to create the message to be displayed for the error
   */
  const HtmlWarningCode.con1(String name, int ordinal, String message) : this.con2(name, ordinal, message, null);

  /**
   * Initialize a newly created error code to have the given message and correction.
   *
   * @param message the template used to create the message to be displayed for the error
   * @param correction the template used to create the correction to be displayed for the error
   */
  const HtmlWarningCode.con2(String name, int ordinal, this.message, this.correction) : super(name, ordinal);

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.WARNING;

  @override
  ErrorType get type => ErrorType.STATIC_WARNING;

  @override
  String get uniqueName => "${runtimeType.toString()}.${name}";
}

/**
 * The enumeration `PolymerCode` defines Polymer specific problems.
 */
class PolymerCode extends Enum<PolymerCode> implements ErrorCode {
  static const PolymerCode ATTRIBUTE_FIELD_NOT_PUBLISHED = const PolymerCode('ATTRIBUTE_FIELD_NOT_PUBLISHED', 0, "Field '{0}' in '{1}' must be @published");

  static const PolymerCode DUPLICATE_ATTRIBUTE_DEFINITION = const PolymerCode('DUPLICATE_ATTRIBUTE_DEFINITION', 1, "The attribute '{0}' is already defined");

  static const PolymerCode EMPTY_ATTRIBUTES = const PolymerCode('EMPTY_ATTRIBUTES', 2, "Empty 'attributes' attribute is useless");

  static const PolymerCode INVALID_ATTRIBUTE_NAME = const PolymerCode('INVALID_ATTRIBUTE_NAME', 3, "'{0}' is not a valid name for a custom element attribute");

  static const PolymerCode INVALID_TAG_NAME = const PolymerCode('INVALID_TAG_NAME', 4, "'{0}' is not a valid name for a custom element");

  static const PolymerCode MISSING_TAG_NAME = const PolymerCode('MISSING_TAG_NAME', 5, "Missing tag name of the custom element. Please include an attribute like name='your-tag-name'");

  static const PolymerCode UNDEFINED_ATTRIBUTE_FIELD = const PolymerCode('UNDEFINED_ATTRIBUTE_FIELD', 6, "There is no such field '{0}' in '{1}'");

  static const List<PolymerCode> values = const [
      ATTRIBUTE_FIELD_NOT_PUBLISHED,
      DUPLICATE_ATTRIBUTE_DEFINITION,
      EMPTY_ATTRIBUTES,
      INVALID_ATTRIBUTE_NAME,
      INVALID_TAG_NAME,
      MISSING_TAG_NAME,
      UNDEFINED_ATTRIBUTE_FIELD];

  /**
   * The template used to create the message to be displayed for this error.
   */
  final String message;

  /**
   * Initialize a newly created error code to have the given message.
   *
   * @param message the message template used to create the message to be displayed for the error
   */
  const PolymerCode(String name, int ordinal, this.message) : super(name, ordinal);

  @override
  String get correction => null;

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.INFO;

  @override
  ErrorType get type => ErrorType.POLYMER;

  @override
  String get uniqueName => "${runtimeType.toString()}.${name}";
}

/**
 * The enumeration `StaticTypeWarningCode` defines the error codes used for static type
 * warnings. The convention for this class is for the name of the error code to indicate the problem
 * that caused the error to be generated and for the error message to explain what is wrong and,
 * when appropriate, how the problem can be corrected.
 */
class StaticTypeWarningCode extends Enum<StaticTypeWarningCode> implements ErrorCode {
  /**
   * 12.7 Lists: A fresh instance (7.6.1) <i>a</i>, of size <i>n</i>, whose class implements the
   * built-in class <i>List&lt;E></i> is allocated.
   *
   * @param numTypeArgument the number of provided type arguments
   */
  static const StaticTypeWarningCode EXPECTED_ONE_LIST_TYPE_ARGUMENTS = const StaticTypeWarningCode.con1('EXPECTED_ONE_LIST_TYPE_ARGUMENTS', 0, "List literal requires exactly one type arguments or none, but {0} found");

  /**
   * 12.8 Maps: A fresh instance (7.6.1) <i>m</i>, of size <i>n</i>, whose class implements the
   * built-in class <i>Map&lt;K, V></i> is allocated.
   *
   * @param numTypeArgument the number of provided type arguments
   */
  static const StaticTypeWarningCode EXPECTED_TWO_MAP_TYPE_ARGUMENTS = const StaticTypeWarningCode.con1('EXPECTED_TWO_MAP_TYPE_ARGUMENTS', 1, "Map literal requires exactly two type arguments or none, but {0} found");

  /**
   * 12.18 Assignment: Let <i>T</i> be the static type of <i>e<sub>1</sub></i>. It is a static type
   * warning if <i>T</i> does not have an accessible instance setter named <i>v=</i>.
   *
   * @see #UNDEFINED_SETTER
   */
  static const StaticTypeWarningCode INACCESSIBLE_SETTER = const StaticTypeWarningCode.con1('INACCESSIBLE_SETTER', 2, "");

  /**
   * 8.1.1 Inheritance and Overriding: However, if the above rules would cause multiple members
   * <i>m<sub>1</sub>, &hellip;, m<sub>k</sub></i> with the same name <i>n</i> that would be
   * inherited (because identically named members existed in several superinterfaces) then at most
   * one member is inherited.
   *
   * If the static types <i>T<sub>1</sub>, &hellip;, T<sub>k</sub></i> of the members
   * <i>m<sub>1</sub>, &hellip;, m<sub>k</sub></i> are not identical, then there must be a member
   * <i>m<sub>x</sub></i> such that <i>T<sub>x</sub> &lt;: T<sub>i</sub>, 1 &lt;= x &lt;= k</i> for
   * all <i>i, 1 &lt;= i &lt;= k</i>, or a static type warning occurs. The member that is inherited
   * is <i>m<sub>x</sub></i>, if it exists; otherwise:
   * * Let <i>numberOfPositionals</i>(<i>f</i>) denote the number of positional parameters of a
   * function <i>f</i>, and let <i>numberOfRequiredParams</i>(<i>f</i>) denote the number of
   * required parameters of a function <i>f</i>. Furthermore, let <i>s</i> denote the set of all
   * named parameters of the <i>m<sub>1</sub>, &hellip;, m<sub>k</sub></i>. Then let
   * * <i>h = max(numberOfPositionals(m<sub>i</sub>)),</i>
   * * <i>r = min(numberOfRequiredParams(m<sub>i</sub>)), for all <i>i</i>, 1 <= i <= k.</i>
   * If <i>r <= h</i> then <i>I</i> has a method named <i>n</i>, with <i>r</i> required parameters
   * of type <b>dynamic</b>, <i>h</i> positional parameters of type <b>dynamic</b>, named parameters
   * <i>s</i> of type <b>dynamic</b> and return type <b>dynamic</b>.
   * * Otherwise none of the members <i>m<sub>1</sub>, &hellip;, m<sub>k</sub></i> is inherited.
   */
  static const StaticTypeWarningCode INCONSISTENT_METHOD_INHERITANCE = const StaticTypeWarningCode.con1('INCONSISTENT_METHOD_INHERITANCE', 3, "'{0}' is inherited by at least two interfaces inconsistently, from {1}");

  /**
   * 12.15.1 Ordinary Invocation: It is a static type warning if <i>T</i> does not have an
   * accessible (3.2) instance member named <i>m</i>.
   *
   * @param memberName the name of the static member
   * @see UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER
   */
  static const StaticTypeWarningCode INSTANCE_ACCESS_TO_STATIC_MEMBER = const StaticTypeWarningCode.con1('INSTANCE_ACCESS_TO_STATIC_MEMBER', 4, "Static member '{0}' cannot be accessed using instance access");

  /**
   * 12.18 Assignment: It is a static type warning if the static type of <i>e</i> may not be
   * assigned to the static type of <i>v</i>. The static type of the expression <i>v = e</i> is the
   * static type of <i>e</i>.
   *
   * 12.18 Assignment: It is a static type warning if the static type of <i>e</i> may not be
   * assigned to the static type of <i>C.v</i>. The static type of the expression <i>C.v = e</i> is
   * the static type of <i>e</i>.
   *
   * 12.18 Assignment: Let <i>T</i> be the static type of <i>e<sub>1</sub></i>. It is a static type
   * warning if the static type of <i>e<sub>2</sub></i> may not be assigned to <i>T</i>.
   *
   * @param rhsTypeName the name of the right hand side type
   * @param lhsTypeName the name of the left hand side type
   */
  static const StaticTypeWarningCode INVALID_ASSIGNMENT = const StaticTypeWarningCode.con1('INVALID_ASSIGNMENT', 5, "A value of type '{0}' cannot be assigned to a variable of type '{1}'");

  /**
   * 12.15.1 Ordinary Invocation: An ordinary method invocation <i>i</i> has the form
   * <i>o.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;
   * x<sub>n+k</sub>: a<sub>n+k</sub>)</i>.
   *
   * Let <i>T</i> be the static type of <i>o</i>. It is a static type warning if <i>T</i> does not
   * have an accessible instance member named <i>m</i>. If <i>T.m</i> exists, it is a static warning
   * if the type <i>F</i> of <i>T.m</i> may not be assigned to a function type. If <i>T.m</i> does
   * not exist, or if <i>F</i> is not a function type, the static type of <i>i</i> is dynamic.
   *
   * 12.15.3 Static Invocation: It is a static type warning if the type <i>F</i> of <i>C.m</i> may
   * not be assigned to a function type.
   *
   * 12.15.4 Super Invocation: A super method invocation <i>i</i> has the form
   * <i>super.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;
   * x<sub>n+k</sub>: a<sub>n+k</sub>)</i>. If <i>S.m</i> exists, it is a static warning if the type
   * <i>F</i> of <i>S.m</i> may not be assigned to a function type.
   *
   * @param nonFunctionIdentifier the name of the identifier that is not a function type
   */
  static const StaticTypeWarningCode INVOCATION_OF_NON_FUNCTION = const StaticTypeWarningCode.con1('INVOCATION_OF_NON_FUNCTION', 6, "'{0}' is not a method");

  /**
   * 12.14.4 Function Expression Invocation: A function expression invocation <i>i</i> has the form
   * <i>e<sub>f</sub>(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>,
   * &hellip;, x<sub>n+k</sub>: a<sub>n+k</sub>)</i>, where <i>e<sub>f</sub></i> is an expression.
   *
   * It is a static type warning if the static type <i>F</i> of <i>e<sub>f</sub></i> may not be
   * assigned to a function type.
   */
  static const StaticTypeWarningCode INVOCATION_OF_NON_FUNCTION_EXPRESSION = const StaticTypeWarningCode.con1('INVOCATION_OF_NON_FUNCTION_EXPRESSION', 7, "Cannot invoke a non-function");

  /**
   * 12.20 Conditional: It is a static type warning if the type of <i>e<sub>1</sub></i> may not be
   * assigned to bool.
   *
   * 13.5 If: It is a static type warning if the type of the expression <i>b</i> may not be assigned
   * to bool.
   *
   * 13.7 While: It is a static type warning if the type of <i>e</i> may not be assigned to bool.
   *
   * 13.8 Do: It is a static type warning if the type of <i>e</i> cannot be assigned to bool.
   */
  static const StaticTypeWarningCode NON_BOOL_CONDITION = const StaticTypeWarningCode.con1('NON_BOOL_CONDITION', 8, "Conditions must have a static type of 'bool'");

  /**
   * 13.15 Assert: It is a static type warning if the type of <i>e</i> may not be assigned to either
   * bool or () &rarr; bool
   */
  static const StaticTypeWarningCode NON_BOOL_EXPRESSION = const StaticTypeWarningCode.con1('NON_BOOL_EXPRESSION', 9, "Assertions must be on either a 'bool' or '() -> bool'");

  /**
   * 12.28 Unary Expressions: The expression !<i>e</i> is equivalent to the expression
   * <i>e</i>?<b>false<b> : <b>true</b>.
   *
   * 12.20 Conditional: It is a static type warning if the type of <i>e<sub>1</sub></i> may not be
   * assigned to bool.
   */
  static const StaticTypeWarningCode NON_BOOL_NEGATION_EXPRESSION = const StaticTypeWarningCode.con1('NON_BOOL_NEGATION_EXPRESSION', 10, "Negation argument must have a static type of 'bool'");

  /**
   * 12.21 Logical Boolean Expressions: It is a static type warning if the static types of both of
   * <i>e<sub>1</sub></i> and <i>e<sub>2</sub></i> may not be assigned to bool.
   *
   * @param operator the lexeme of the logical operator
   */
  static const StaticTypeWarningCode NON_BOOL_OPERAND = const StaticTypeWarningCode.con1('NON_BOOL_OPERAND', 11, "The operands of the '{0}' operator must be assignable to 'bool'");

  /**
   * 15.8 Parameterized Types: It is a static type warning if <i>A<sub>i</sub>, 1 &lt;= i &lt;=
   * n</i> does not denote a type in the enclosing lexical scope.
   */
  static const StaticTypeWarningCode NON_TYPE_AS_TYPE_ARGUMENT = const StaticTypeWarningCode.con1('NON_TYPE_AS_TYPE_ARGUMENT', 12, "The name '{0}' is not a type and cannot be used as a parameterized type");

  /**
   * 13.11 Return: It is a static type warning if the type of <i>e</i> may not be assigned to the
   * declared return type of the immediately enclosing function.
   *
   * @param actualReturnType the return type as declared in the return statement
   * @param expectedReturnType the expected return type as defined by the method
   * @param methodName the name of the method
   */
  static const StaticTypeWarningCode RETURN_OF_INVALID_TYPE = const StaticTypeWarningCode.con1('RETURN_OF_INVALID_TYPE', 13, "The return type '{0}' is not a '{1}', as defined by the method '{2}'");

  /**
   * 12.11 Instance Creation: It is a static type warning if any of the type arguments to a
   * constructor of a generic type <i>G</i> invoked by a new expression or a constant object
   * expression are not subtypes of the bounds of the corresponding formal type parameters of
   * <i>G</i>.
   *
   * 15.8 Parameterized Types: If <i>S</i> is the static type of a member <i>m</i> of <i>G</i>, then
   * the static type of the member <i>m</i> of <i>G&lt;A<sub>1</sub>, &hellip;,
   * A<sub>n</sub>&gt;</i> is <i>[A<sub>1</sub>, &hellip;, A<sub>n</sub>/T<sub>1</sub>, &hellip;,
   * T<sub>n</sub>]S</i> where <i>T<sub>1</sub>, &hellip;, T<sub>n</sub></i> are the formal type
   * parameters of <i>G</i>. Let <i>B<sub>i</sub></i> be the bounds of <i>T<sub>i</sub>, 1 &lt;= i
   * &lt;= n</i>. It is a static type warning if <i>A<sub>i</sub></i> is not a subtype of
   * <i>[A<sub>1</sub>, &hellip;, A<sub>n</sub>/T<sub>1</sub>, &hellip;,
   * T<sub>n</sub>]B<sub>i</sub>, 1 &lt;= i &lt;= n</i>.
   *
   * 7.6.2 Factories: It is a static type warning if any of the type arguments to <i>k'</i> are not
   * subtypes of the bounds of the corresponding formal type parameters of type.
   *
   * @param boundedTypeName the name of the type used in the instance creation that should be
   *          limited by the bound as specified in the class declaration
   * @param boundingTypeName the name of the bounding type
   * @see #TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND
   */
  static const StaticTypeWarningCode TYPE_ARGUMENT_NOT_MATCHING_BOUNDS = const StaticTypeWarningCode.con1('TYPE_ARGUMENT_NOT_MATCHING_BOUNDS', 14, "'{0}' does not extend '{1}'");

  /**
   * 10 Generics: It is a static type warning if a type parameter is a supertype of its upper bound.
   *
   * @param typeParameterName the name of the type parameter
   * @see #TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
   */
  static const StaticTypeWarningCode TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND = const StaticTypeWarningCode.con1('TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND', 15, "'{0}' cannot be a supertype of its upper bound");

  /**
   * 12.17 Getter Invocation: It is a static warning if there is no class <i>C</i> in the enclosing
   * lexical scope of <i>i</i>, or if <i>C</i> does not declare, implicitly or explicitly, a getter
   * named <i>m</i>.
   *
   * @param constantName the name of the enumeration constant that is not defined
   * @param enumName the name of the enumeration used to access the constant
   */
  static const StaticTypeWarningCode UNDEFINED_ENUM_CONSTANT = const StaticTypeWarningCode.con1('UNDEFINED_ENUM_CONSTANT', 16, "There is no constant named '{0}' in '{1}'");

  /**
   * 12.15.3 Unqualified Invocation: If there exists a lexically visible declaration named
   * <i>id</i>, let <i>f<sub>id</sub></i> be the innermost such declaration. Then: [skip].
   * Otherwise, <i>f<sub>id</sub></i> is considered equivalent to the ordinary method invocation
   * <b>this</b>.<i>id</i>(<i>a<sub>1</sub></i>, ..., <i>a<sub>n</sub></i>, <i>x<sub>n+1</sub></i> :
   * <i>a<sub>n+1</sub></i>, ..., <i>x<sub>n+k</sub></i> : <i>a<sub>n+k</sub></i>).
   *
   * @param methodName the name of the method that is undefined
   */
  static const StaticTypeWarningCode UNDEFINED_FUNCTION = const StaticTypeWarningCode.con1('UNDEFINED_FUNCTION', 17, "The function '{0}' is not defined");

  /**
   * 12.17 Getter Invocation: Let <i>T</i> be the static type of <i>e</i>. It is a static type
   * warning if <i>T</i> does not have a getter named <i>m</i>.
   *
   * @param getterName the name of the getter
   * @param enclosingType the name of the enclosing type where the getter is being looked for
   */
  static const StaticTypeWarningCode UNDEFINED_GETTER = const StaticTypeWarningCode.con1('UNDEFINED_GETTER', 18, "There is no such getter '{0}' in '{1}'");

  /**
   * 12.15.1 Ordinary Invocation: Let <i>T</i> be the static type of <i>o</i>. It is a static type
   * warning if <i>T</i> does not have an accessible instance member named <i>m</i>.
   *
   * @param methodName the name of the method that is undefined
   * @param typeName the resolved type name that the method lookup is happening on
   */
  static const StaticTypeWarningCode UNDEFINED_METHOD = const StaticTypeWarningCode.con1('UNDEFINED_METHOD', 19, "The method '{0}' is not defined for the class '{1}'");

  /**
   * 12.18 Assignment: Evaluation of an assignment of the form
   * <i>e<sub>1</sub></i>[<i>e<sub>2</sub></i>] = <i>e<sub>3</sub></i> is equivalent to the
   * evaluation of the expression (a, i, e){a.[]=(i, e); return e;} (<i>e<sub>1</sub></i>,
   * <i>e<sub>2</sub></i>, <i>e<sub>2</sub></i>).
   *
   * 12.29 Assignable Expressions: An assignable expression of the form
   * <i>e<sub>1</sub></i>[<i>e<sub>2</sub></i>] is evaluated as a method invocation of the operator
   * method [] on <i>e<sub>1</sub></i> with argument <i>e<sub>2</sub></i>.
   *
   * 12.15.1 Ordinary Invocation: Let <i>T</i> be the static type of <i>o</i>. It is a static type
   * warning if <i>T</i> does not have an accessible instance member named <i>m</i>.
   *
   * @param operator the name of the operator
   * @param enclosingType the name of the enclosing type where the operator is being looked for
   */
  static const StaticTypeWarningCode UNDEFINED_OPERATOR = const StaticTypeWarningCode.con1('UNDEFINED_OPERATOR', 20, "There is no such operator '{0}' in '{1}'");

  /**
   * 12.18 Assignment: Let <i>T</i> be the static type of <i>e<sub>1</sub></i>. It is a static type
   * warning if <i>T</i> does not have an accessible instance setter named <i>v=</i>.
   *
   * @param setterName the name of the setter
   * @param enclosingType the name of the enclosing type where the setter is being looked for
   * @see #INACCESSIBLE_SETTER
   */
  static const StaticTypeWarningCode UNDEFINED_SETTER = const StaticTypeWarningCode.con1('UNDEFINED_SETTER', 21, "There is no such setter '{0}' in '{1}'");

  /**
   * 12.15.4 Super Invocation: A super method invocation <i>i</i> has the form
   * <i>super.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;
   * x<sub>n+k</sub>: a<sub>n+k</sub>)</i>. It is a static type warning if <i>S</i> does not have an
   * accessible instance member named <i>m</i>.
   *
   * @param methodName the name of the method that is undefined
   * @param typeName the resolved type name that the method lookup is happening on
   */
  static const StaticTypeWarningCode UNDEFINED_SUPER_METHOD = const StaticTypeWarningCode.con1('UNDEFINED_SUPER_METHOD', 22, "There is no such method '{0}' in '{1}'");

  /**
   * 12.15.1 Ordinary Invocation: It is a static type warning if <i>T</i> does not have an
   * accessible (3.2) instance member named <i>m</i>.
   *
   * This is a specialization of [INSTANCE_ACCESS_TO_STATIC_MEMBER] that is used when we are
   * able to find the name defined in a supertype. It exists to provide a more informative error
   * message.
   */
  static const StaticTypeWarningCode UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER = const StaticTypeWarningCode.con1('UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER', 23, "Static members from supertypes must be qualified by the name of the defining type");

  /**
   * 15.8 Parameterized Types: It is a static type warning if <i>G</i> is not a generic type with
   * exactly <i>n</i> type parameters.
   *
   * @param typeName the name of the type being referenced (<i>G</i>)
   * @param parameterCount the number of type parameters that were declared
   * @param argumentCount the number of type arguments provided
   * @see CompileTimeErrorCode#CONST_WITH_INVALID_TYPE_PARAMETERS
   * @see CompileTimeErrorCode#NEW_WITH_INVALID_TYPE_PARAMETERS
   */
  static const StaticTypeWarningCode WRONG_NUMBER_OF_TYPE_ARGUMENTS = const StaticTypeWarningCode.con1('WRONG_NUMBER_OF_TYPE_ARGUMENTS', 24, "The type '{0}' is declared with {1} type parameters, but {2} type arguments were given");

  static const List<StaticTypeWarningCode> values = const [
      EXPECTED_ONE_LIST_TYPE_ARGUMENTS,
      EXPECTED_TWO_MAP_TYPE_ARGUMENTS,
      INACCESSIBLE_SETTER,
      INCONSISTENT_METHOD_INHERITANCE,
      INSTANCE_ACCESS_TO_STATIC_MEMBER,
      INVALID_ASSIGNMENT,
      INVOCATION_OF_NON_FUNCTION,
      INVOCATION_OF_NON_FUNCTION_EXPRESSION,
      NON_BOOL_CONDITION,
      NON_BOOL_EXPRESSION,
      NON_BOOL_NEGATION_EXPRESSION,
      NON_BOOL_OPERAND,
      NON_TYPE_AS_TYPE_ARGUMENT,
      RETURN_OF_INVALID_TYPE,
      TYPE_ARGUMENT_NOT_MATCHING_BOUNDS,
      TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND,
      UNDEFINED_ENUM_CONSTANT,
      UNDEFINED_FUNCTION,
      UNDEFINED_GETTER,
      UNDEFINED_METHOD,
      UNDEFINED_OPERATOR,
      UNDEFINED_SETTER,
      UNDEFINED_SUPER_METHOD,
      UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER,
      WRONG_NUMBER_OF_TYPE_ARGUMENTS];

  /**
   * The template used to create the message to be displayed for this error.
   */
  final String message;

  /**
   * The template used to create the correction to be displayed for this error, or `null` if
   * there is no correction information for this error.
   */
  final String correction;

  /**
   * Initialize a newly created error code to have the given message.
   *
   * @param message the message template used to create the message to be displayed for the error
   */
  const StaticTypeWarningCode.con1(String name, int ordinal, String message) : this.con2(name, ordinal, message, null);

  /**
   * Initialize a newly created error code to have the given message and correction.
   *
   * @param message the template used to create the message to be displayed for the error
   * @param correction the template used to create the correction to be displayed for the error
   */
  const StaticTypeWarningCode.con2(String name, int ordinal, this.message, this.correction) : super(name, ordinal);

  @override
  ErrorSeverity get errorSeverity => ErrorType.STATIC_TYPE_WARNING.severity;

  @override
  ErrorType get type => ErrorType.STATIC_TYPE_WARNING;

  @override
  String get uniqueName => "${runtimeType.toString()}.${name}";
}

/**
 * The enumeration `StaticWarningCode` defines the error codes used for static warnings. The
 * convention for this class is for the name of the error code to indicate the problem that caused
 * the error to be generated and for the error message to explain what is wrong and, when
 * appropriate, how the problem can be corrected.
 */
class StaticWarningCode extends Enum<StaticWarningCode> implements ErrorCode {
  /**
   * 14.1 Imports: If a name <i>N</i> is referenced by a library <i>L</i> and <i>N</i> is introduced
   * into the top level scope <i>L</i> by more than one import then:
   * <ol>
   * * A static warning occurs.
   * * If <i>N</i> is referenced as a function, getter or setter, a <i>NoSuchMethodError</i> is
   * raised.
   * * If <i>N</i> is referenced as a type, it is treated as a malformed type.
   * </ol>
   *
   * @param ambiguousTypeName the name of the ambiguous type
   * @param firstLibraryName the name of the first library that the type is found
   * @param secondLibraryName the name of the second library that the type is found
   */
  static const StaticWarningCode AMBIGUOUS_IMPORT = const StaticWarningCode.con1('AMBIGUOUS_IMPORT', 0, "The name '{0}' is defined in the libraries {1}");

  /**
   * 12.11.1 New: It is a static warning if the static type of <i>a<sub>i</sub>, 1 &lt;= i &lt;= n+
   * k</i> may not be assigned to the type of the corresponding formal parameter of the constructor
   * <i>T.id</i> (respectively <i>T</i>).
   *
   * 12.11.2 Const: It is a static warning if the static type of <i>a<sub>i</sub>, 1 &lt;= i &lt;=
   * n+ k</i> may not be assigned to the type of the corresponding formal parameter of the
   * constructor <i>T.id</i> (respectively <i>T</i>).
   *
   * 12.14.2 Binding Actuals to Formals: Let <i>T<sub>i</sub></i> be the static type of
   * <i>a<sub>i</sub></i>, let <i>S<sub>i</sub></i> be the type of <i>p<sub>i</sub>, 1 &lt;= i &lt;=
   * n+k</i> and let <i>S<sub>q</sub></i> be the type of the named parameter <i>q</i> of <i>f</i>.
   * It is a static warning if <i>T<sub>j</sub></i> may not be assigned to <i>S<sub>j</sub>, 1 &lt;=
   * j &lt;= m</i>.
   *
   * 12.14.2 Binding Actuals to Formals: Furthermore, each <i>q<sub>i</sub>, 1 &lt;= i &lt;= l</i>,
   * must have a corresponding named parameter in the set <i>{p<sub>n+1</sub>, &hellip;
   * p<sub>n+k</sub>}</i> or a static warning occurs. It is a static warning if
   * <i>T<sub>m+j</sub></i> may not be assigned to <i>S<sub>r</sub></i>, where <i>r = q<sub>j</sub>,
   * 1 &lt;= j &lt;= l</i>.
   *
   * @param actualType the name of the actual argument type
   * @param expectedType the name of the expected type
   */
  static const StaticWarningCode ARGUMENT_TYPE_NOT_ASSIGNABLE = const StaticWarningCode.con1('ARGUMENT_TYPE_NOT_ASSIGNABLE', 1, "The argument type '{0}' cannot be assigned to the parameter type '{1}'");

  /**
   * 5 Variables: Attempting to assign to a final variable elsewhere will cause a NoSuchMethodError
   * to be thrown, because no setter is defined for it. The assignment will also give rise to a
   * static warning for the same reason.
   *
   * A constant variable is always implicitly final.
   */
  static const StaticWarningCode ASSIGNMENT_TO_CONST = const StaticWarningCode.con1('ASSIGNMENT_TO_CONST', 2, "Constant variables cannot be assigned a value");

  /**
   * 5 Variables: Attempting to assign to a final variable elsewhere will cause a NoSuchMethodError
   * to be thrown, because no setter is defined for it. The assignment will also give rise to a
   * static warning for the same reason.
   */
  static const StaticWarningCode ASSIGNMENT_TO_FINAL = const StaticWarningCode.con1('ASSIGNMENT_TO_FINAL', 3, "'{0}' cannot be used as a setter, it is final");

  /**
   * 5 Variables: Attempting to assign to a final variable elsewhere will cause a NoSuchMethodError
   * to be thrown, because no setter is defined for it. The assignment will also give rise to a
   * static warning for the same reason.
   */
  static const StaticWarningCode ASSIGNMENT_TO_FINAL_NO_SETTER = const StaticWarningCode.con1('ASSIGNMENT_TO_FINAL_NO_SETTER', 4, "No setter named '{0}' in class '{1}'");

  /**
   * 12.18 Assignment: It is as static warning if an assignment of the form <i>v = e</i> occurs
   * inside a top level or static function (be it function, method, getter, or setter) or variable
   * initializer and there is neither a local variable declaration with name <i>v</i> nor setter
   * declaration with name <i>v=</i> in the lexical scope enclosing the assignment.
   */
  static const StaticWarningCode ASSIGNMENT_TO_FUNCTION = const StaticWarningCode.con1('ASSIGNMENT_TO_FUNCTION', 5, "Functions cannot be assigned a value");

  /**
   * 12.18 Assignment: Let <i>T</i> be the static type of <i>e<sub>1</sub></i>. It is a static type
   * warning if <i>T</i> does not have an accessible instance setter named <i>v=</i>.
   */
  static const StaticWarningCode ASSIGNMENT_TO_METHOD = const StaticWarningCode.con1('ASSIGNMENT_TO_METHOD', 6, "Methods cannot be assigned a value");

  /**
   * 13.9 Switch: It is a static warning if the last statement of the statement sequence
   * <i>s<sub>k</sub></i> is not a break, continue, return or throw statement.
   */
  static const StaticWarningCode CASE_BLOCK_NOT_TERMINATED = const StaticWarningCode.con1('CASE_BLOCK_NOT_TERMINATED', 7, "The last statement of the 'case' should be 'break', 'continue', 'return' or 'throw'");

  /**
   * 12.32 Type Cast: It is a static warning if <i>T</i> does not denote a type available in the
   * current lexical scope.
   */
  static const StaticWarningCode CAST_TO_NON_TYPE = const StaticWarningCode.con1('CAST_TO_NON_TYPE', 8, "The name '{0}' is not a type and cannot be used in an 'as' expression");

  /**
   * 7.4 Abstract Instance Members: It is a static warning if an abstract member is declared or
   * inherited in a concrete class.
   */
  static const StaticWarningCode CONCRETE_CLASS_WITH_ABSTRACT_MEMBER = const StaticWarningCode.con1('CONCRETE_CLASS_WITH_ABSTRACT_MEMBER', 9, "'{0}' must have a method body because '{1}' is not abstract");

  /**
   * 14.1 Imports: If a name <i>N</i> is referenced by a library <i>L</i> and <i>N</i> would be
   * introduced into the top level scope of <i>L</i> by an import from a library whose URI begins
   * with <i>dart:</i> and an import from a library whose URI does not begin with <i>dart:</i>:
   * * The import from <i>dart:</i> is implicitly extended by a hide N clause.
   * * A static warning is issued.
   *
   * @param ambiguousName the ambiguous name
   * @param sdkLibraryName the name of the dart: library that the element is found
   * @param otherLibraryName the name of the non-dart: library that the element is found
   */
  static const StaticWarningCode CONFLICTING_DART_IMPORT = const StaticWarningCode.con1('CONFLICTING_DART_IMPORT', 10, "Element '{0}' from SDK library '{1}' is implicitly hidden by '{2}'");

  /**
   * 7.2 Getters: It is a static warning if a class <i>C</i> declares an instance getter named
   * <i>v</i> and an accessible static member named <i>v</i> or <i>v=</i> is declared in a
   * superclass of <i>C</i>.
   *
   * @param superName the name of the super class declaring a static member
   */
  static const StaticWarningCode CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER = const StaticWarningCode.con1('CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER', 11, "Superclass '{0}' declares static member with the same name");

  /**
   * 7.1 Instance Methods: It is a static warning if a class <i>C</i> declares an instance method
   * named <i>n</i> and has a setter named <i>n=</i>.
   */
  static const StaticWarningCode CONFLICTING_INSTANCE_METHOD_SETTER = const StaticWarningCode.con1('CONFLICTING_INSTANCE_METHOD_SETTER', 12, "Class '{0}' declares instance method '{1}', but also has a setter with the same name from '{2}'");

  /**
   * 7.1 Instance Methods: It is a static warning if a class <i>C</i> declares an instance method
   * named <i>n</i> and has a setter named <i>n=</i>.
   */
  static const StaticWarningCode CONFLICTING_INSTANCE_METHOD_SETTER2 = const StaticWarningCode.con1('CONFLICTING_INSTANCE_METHOD_SETTER2', 13, "Class '{0}' declares the setter '{1}', but also has an instance method in the same class");

  /**
   * 7.3 Setters: It is a static warning if a class <i>C</i> declares an instance setter named
   * <i>v=</i> and an accessible static member named <i>v=</i> or <i>v</i> is declared in a
   * superclass of <i>C</i>.
   *
   * @param superName the name of the super class declaring a static member
   */
  static const StaticWarningCode CONFLICTING_INSTANCE_SETTER_AND_SUPERCLASS_MEMBER = const StaticWarningCode.con1('CONFLICTING_INSTANCE_SETTER_AND_SUPERCLASS_MEMBER', 14, "Superclass '{0}' declares static member with the same name");

  /**
   * 7.2 Getters: It is a static warning if a class declares a static getter named <i>v</i> and also
   * has a non-static setter named <i>v=</i>.
   */
  static const StaticWarningCode CONFLICTING_STATIC_GETTER_AND_INSTANCE_SETTER = const StaticWarningCode.con1('CONFLICTING_STATIC_GETTER_AND_INSTANCE_SETTER', 15, "Class '{0}' declares non-static setter with the same name");

  /**
   * 7.3 Setters: It is a static warning if a class declares a static setter named <i>v=</i> and
   * also has a non-static member named <i>v</i>.
   */
  static const StaticWarningCode CONFLICTING_STATIC_SETTER_AND_INSTANCE_MEMBER = const StaticWarningCode.con1('CONFLICTING_STATIC_SETTER_AND_INSTANCE_MEMBER', 16, "Class '{0}' declares non-static member with the same name");

  /**
   * 12.11.2 Const: Given an instance creation expression of the form <i>const q(a<sub>1</sub>,
   * &hellip; a<sub>n</sub>)</i> it is a static warning if <i>q</i> is the constructor of an
   * abstract class but <i>q</i> is not a factory constructor.
   */
  static const StaticWarningCode CONST_WITH_ABSTRACT_CLASS = const StaticWarningCode.con1('CONST_WITH_ABSTRACT_CLASS', 17, "Abstract classes cannot be created with a 'const' expression");

  /**
   * 12.7 Maps: It is a static warning if the values of any two keys in a map literal are equal.
   */
  static const StaticWarningCode EQUAL_KEYS_IN_MAP = const StaticWarningCode.con1('EQUAL_KEYS_IN_MAP', 18, "Keys in a map cannot be equal");

  /**
   * 14.2 Exports: It is a static warning to export two different libraries with the same name.
   *
   * @param uri1 the uri pointing to a first library
   * @param uri2 the uri pointing to a second library
   * @param name the shared name of the exported libraries
   */
  static const StaticWarningCode EXPORT_DUPLICATED_LIBRARY_NAME = const StaticWarningCode.con1('EXPORT_DUPLICATED_LIBRARY_NAME', 19, "The exported libraries '{0}' and '{1}' should not have the same name '{2}'");

  /**
   * 12.14.2 Binding Actuals to Formals: It is a static warning if <i>m &lt; h</i> or if <i>m &gt;
   * n</i>.
   *
   * @param requiredCount the maximum number of positional arguments
   * @param argumentCount the actual number of positional arguments given
   * @see #NOT_ENOUGH_REQUIRED_ARGUMENTS
   */
  static const StaticWarningCode EXTRA_POSITIONAL_ARGUMENTS = const StaticWarningCode.con1('EXTRA_POSITIONAL_ARGUMENTS', 20, "{0} positional arguments expected, but {1} found");

  /**
   * 5. Variables: It is a static warning if a final instance variable that has been initialized at
   * its point of declaration is also initialized in a constructor.
   */
  static const StaticWarningCode FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION = const StaticWarningCode.con1('FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION', 21, "Values cannot be set in the constructor if they are final, and have already been set");

  /**
   * 5. Variables: It is a static warning if a final instance variable that has been initialized at
   * its point of declaration is also initialized in a constructor.
   *
   * @param name the name of the field in question
   */
  static const StaticWarningCode FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR = const StaticWarningCode.con1('FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR', 22, "'{0}' is final and was given a value when it was declared, so it cannot be set to a new value");

  /**
   * 7.6.1 Generative Constructors: Execution of an initializer of the form <b>this</b>.<i>v</i> =
   * <i>e</i> proceeds as follows: First, the expression <i>e</i> is evaluated to an object
   * <i>o</i>. Then, the instance variable <i>v</i> of the object denoted by this is bound to
   * <i>o</i>.
   *
   * 12.14.2 Binding Actuals to Formals: Let <i>T<sub>i</sub></i> be the static type of
   * <i>a<sub>i</sub></i>, let <i>S<sub>i</sub></i> be the type of <i>p<sub>i</sub>, 1 &lt;= i &lt;=
   * n+k</i> and let <i>S<sub>q</sub></i> be the type of the named parameter <i>q</i> of <i>f</i>.
   * It is a static warning if <i>T<sub>j</sub></i> may not be assigned to <i>S<sub>j</sub>, 1 &lt;=
   * j &lt;= m</i>.
   *
   * @param initializerType the name of the type of the initializer expression
   * @param fieldType the name of the type of the field
   */
  static const StaticWarningCode FIELD_INITIALIZER_NOT_ASSIGNABLE = const StaticWarningCode.con1('FIELD_INITIALIZER_NOT_ASSIGNABLE', 23, "The initializer type '{0}' cannot be assigned to the field type '{1}'");

  /**
   * 7.6.1 Generative Constructors: An initializing formal has the form <i>this.id</i>. It is a
   * static warning if the static type of <i>id</i> is not assignable to <i>T<sub>id</sub></i>.
   *
   * @param parameterType the name of the type of the field formal parameter
   * @param fieldType the name of the type of the field
   */
  static const StaticWarningCode FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE = const StaticWarningCode.con1('FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE', 24, "The parameter type '{0}' is incompatable with the field type '{1}'");

  /**
   * 5 Variables: It is a static warning if a library, static or local variable <i>v</i> is final
   * and <i>v</i> is not initialized at its point of declaration.
   *
   * 7.6.1 Generative Constructors: Each final instance variable <i>f</i> declared in the
   * immediately enclosing class must have an initializer in <i>k</i>'s initializer list unless it
   * has already been initialized by one of the following means:
   * * Initialization at the declaration of <i>f</i>.
   * * Initialization by means of an initializing formal of <i>k</i>.
   * or a static warning occurs.
   *
   * @param name the name of the uninitialized final variable
   */
  static const StaticWarningCode FINAL_NOT_INITIALIZED = const StaticWarningCode.con1('FINAL_NOT_INITIALIZED', 25, "The final variable '{0}' must be initialized");

  /**
   * 15.5 Function Types: It is a static warning if a concrete class implements Function and does
   * not have a concrete method named call().
   */
  static const StaticWarningCode FUNCTION_WITHOUT_CALL = const StaticWarningCode.con1('FUNCTION_WITHOUT_CALL', 26, "Concrete classes that implement Function must implement the method call()");

  /**
   * 14.1 Imports: It is a static warning to import two different libraries with the same name.
   *
   * @param uri1 the uri pointing to a first library
   * @param uri2 the uri pointing to a second library
   * @param name the shared name of the imported libraries
   */
  static const StaticWarningCode IMPORT_DUPLICATED_LIBRARY_NAME = const StaticWarningCode.con1('IMPORT_DUPLICATED_LIBRARY_NAME', 27, "The imported libraries '{0}' and '{1}' should not have the same name '{2}'");

  /**
   * 14.1 Imports: It is a static warning if the specified URI of a deferred import does not refer
   * to a library declaration.
   *
   * @param uri the uri pointing to a non-library declaration
   * @see CompileTimeErrorCode#IMPORT_OF_NON_LIBRARY
   */
  static const StaticWarningCode IMPORT_OF_NON_LIBRARY = const StaticWarningCode.con1('IMPORT_OF_NON_LIBRARY', 28, "The imported library '{0}' must not have a part-of directive");

  /**
   * 8.1.1 Inheritance and Overriding: However, if the above rules would cause multiple members
   * <i>m<sub>1</sub>, &hellip;, m<sub>k</sub></i> with the same name <i>n</i> that would be
   * inherited (because identically named members existed in several superinterfaces) then at most
   * one member is inherited.
   *
   * If some but not all of the <i>m<sub>i</sub>, 1 &lt;= i &lt;= k</i> are getters none of the
   * <i>m<sub>i</sub></i> are inherited, and a static warning is issued.
   */
  static const StaticWarningCode INCONSISTENT_METHOD_INHERITANCE_GETTER_AND_METHOD = const StaticWarningCode.con1('INCONSISTENT_METHOD_INHERITANCE_GETTER_AND_METHOD', 29, "'{0}' is inherited as a getter and also a method");

  /**
   * 7.1 Instance Methods: It is a static warning if a class <i>C</i> declares an instance method
   * named <i>n</i> and an accessible static member named <i>n</i> is declared in a superclass of
   * <i>C</i>.
   *
   * @param memberName the name of the member with the name conflict
   * @param superclassName the name of the enclosing class that has the static member
   */
  static const StaticWarningCode INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC = const StaticWarningCode.con1('INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC', 30, "'{0}' collides with a static member in the superclass '{1}'");

  /**
   * 7.2 Getters: It is a static warning if a getter <i>m1</i> overrides a getter <i>m2</i> and the
   * type of <i>m1</i> is not a subtype of the type of <i>m2</i>.
   *
   * @param actualReturnTypeName the name of the expected return type
   * @param expectedReturnType the name of the actual return type, not assignable to the
   *          actualReturnTypeName
   * @param className the name of the class where the overridden getter is declared
   * @see #INVALID_METHOD_OVERRIDE_RETURN_TYPE
   */
  static const StaticWarningCode INVALID_GETTER_OVERRIDE_RETURN_TYPE = const StaticWarningCode.con1('INVALID_GETTER_OVERRIDE_RETURN_TYPE', 31, "The return type '{0}' is not assignable to '{1}' as required by the getter it is overriding from '{2}'");

  /**
   * 7.1 Instance Methods: It is a static warning if an instance method <i>m1</i> overrides an
   * instance method <i>m2</i> and the type of <i>m1</i> is not a subtype of the type of <i>m2</i>.
   *
   * @param actualParamTypeName the name of the expected parameter type
   * @param expectedParamType the name of the actual parameter type, not assignable to the
   *          actualParamTypeName
   * @param className the name of the class where the overridden method is declared
   */
  static const StaticWarningCode INVALID_METHOD_OVERRIDE_NAMED_PARAM_TYPE = const StaticWarningCode.con1('INVALID_METHOD_OVERRIDE_NAMED_PARAM_TYPE', 32, "The parameter type '{0}' is not assignable to '{1}' as required by the method it is overriding from '{2}'");

  /**
   * 7.1 Instance Methods: It is a static warning if an instance method <i>m1</i> overrides an
   * instance method <i>m2</i> and the type of <i>m1</i> is not a subtype of the type of <i>m2</i>.
   *
   * @param actualParamTypeName the name of the expected parameter type
   * @param expectedParamType the name of the actual parameter type, not assignable to the
   *          actualParamTypeName
   * @param className the name of the class where the overridden method is declared
   * @see #INVALID_SETTER_OVERRIDE_NORMAL_PARAM_TYPE
   */
  static const StaticWarningCode INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE = const StaticWarningCode.con1('INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE', 33, "The parameter type '{0}' is not assignable to '{1}' as required by the method it is overriding from '{2}'");

  /**
   * 7.1 Instance Methods: It is a static warning if an instance method <i>m1</i> overrides an
   * instance method <i>m2</i> and the type of <i>m1</i> is not a subtype of the type of <i>m2</i>.
   *
   * @param actualParamTypeName the name of the expected parameter type
   * @param expectedParamType the name of the actual parameter type, not assignable to the
   *          actualParamTypeName
   * @param className the name of the class where the overridden method is declared
   */
  static const StaticWarningCode INVALID_METHOD_OVERRIDE_OPTIONAL_PARAM_TYPE = const StaticWarningCode.con1('INVALID_METHOD_OVERRIDE_OPTIONAL_PARAM_TYPE', 34, "The parameter type '{0}' is not assignable to '{1}' as required by the method it is overriding from '{2}'");

  /**
   * 7.1 Instance Methods: It is a static warning if an instance method <i>m1</i> overrides an
   * instance method <i>m2</i> and the type of <i>m1</i> is not a subtype of the type of <i>m2</i>.
   *
   * @param actualReturnTypeName the name of the expected return type
   * @param expectedReturnType the name of the actual return type, not assignable to the
   *          actualReturnTypeName
   * @param className the name of the class where the overridden method is declared
   * @see #INVALID_GETTER_OVERRIDE_RETURN_TYPE
   */
  static const StaticWarningCode INVALID_METHOD_OVERRIDE_RETURN_TYPE = const StaticWarningCode.con1('INVALID_METHOD_OVERRIDE_RETURN_TYPE', 35, "The return type '{0}' is not assignable to '{1}' as required by the method it is overriding from '{2}'");

  /**
   * 7.1 Instance Methods: It is a static warning if an instance method <i>m1</i> overrides an
   * instance member <i>m2</i>, the signature of <i>m2</i> explicitly specifies a default value for
   * a formal parameter <i>p</i> and the signature of <i>m1</i> specifies a different default value
   * for <i>p</i>.
   */
  static const StaticWarningCode INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_NAMED = const StaticWarningCode.con1('INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_NAMED', 36, "Parameters cannot override default values, this method overrides '{0}.{1}' where '{2}' has a different value");

  /**
   * 7.1 Instance Methods: It is a static warning if an instance method <i>m1</i> overrides an
   * instance member <i>m2</i>, the signature of <i>m2</i> explicitly specifies a default value for
   * a formal parameter <i>p</i> and the signature of <i>m1</i> specifies a different default value
   * for <i>p</i>.
   */
  static const StaticWarningCode INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL = const StaticWarningCode.con1('INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL', 37, "Parameters cannot override default values, this method overrides '{0}.{1}' where this positional parameter has a different value");

  /**
   * 7.1 Instance Methods: It is a static warning if an instance method <i>m1</i> overrides an
   * instance member <i>m2</i> and <i>m1</i> does not declare all the named parameters declared by
   * <i>m2</i>.
   *
   * @param paramCount the number of named parameters in the overridden member
   * @param className the name of the class from the overridden method
   */
  static const StaticWarningCode INVALID_OVERRIDE_NAMED = const StaticWarningCode.con1('INVALID_OVERRIDE_NAMED', 38, "Missing the named parameter '{0}' to match the overridden method from '{1}'");

  /**
   * 7.1 Instance Methods: It is a static warning if an instance method <i>m1</i> overrides an
   * instance member <i>m2</i> and <i>m1</i> has fewer positional parameters than <i>m2</i>.
   *
   * @param paramCount the number of positional parameters in the overridden member
   * @param className the name of the class from the overridden method
   */
  static const StaticWarningCode INVALID_OVERRIDE_POSITIONAL = const StaticWarningCode.con1('INVALID_OVERRIDE_POSITIONAL', 39, "Must have at least {0} parameters to match the overridden method from '{1}'");

  /**
   * 7.1 Instance Methods: It is a static warning if an instance method <i>m1</i> overrides an
   * instance member <i>m2</i> and <i>m1</i> has a greater number of required parameters than
   * <i>m2</i>.
   *
   * @param paramCount the number of required parameters in the overridden member
   * @param className the name of the class from the overridden method
   */
  static const StaticWarningCode INVALID_OVERRIDE_REQUIRED = const StaticWarningCode.con1('INVALID_OVERRIDE_REQUIRED', 40, "Must have {0} required parameters or less to match the overridden method from '{1}'");

  /**
   * 7.3 Setters: It is a static warning if a setter <i>m1</i> overrides a setter <i>m2</i> and the
   * type of <i>m1</i> is not a subtype of the type of <i>m2</i>.
   *
   * @param actualParamTypeName the name of the expected parameter type
   * @param expectedParamType the name of the actual parameter type, not assignable to the
   *          actualParamTypeName
   * @param className the name of the class where the overridden setter is declared
   * @see #INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE
   */
  static const StaticWarningCode INVALID_SETTER_OVERRIDE_NORMAL_PARAM_TYPE = const StaticWarningCode.con1('INVALID_SETTER_OVERRIDE_NORMAL_PARAM_TYPE', 41, "The parameter type '{0}' is not assignable to '{1}' as required by the setter it is overriding from '{2}'");

  /**
   * 12.6 Lists: A run-time list literal &lt;<i>E</i>&gt; [<i>e<sub>1</sub></i> &hellip;
   * <i>e<sub>n</sub></i>] is evaluated as follows:
   * * The operator []= is invoked on <i>a</i> with first argument <i>i</i> and second argument
   * <i>o<sub>i+1</sub></i><i>, 1 &lt;= i &lt;= n</i>
   *
   * 12.14.2 Binding Actuals to Formals: Let <i>T<sub>i</sub></i> be the static type of
   * <i>a<sub>i</sub></i>, let <i>S<sub>i</sub></i> be the type of <i>p<sub>i</sub>, 1 &lt;= i &lt;=
   * n+k</i> and let <i>S<sub>q</sub></i> be the type of the named parameter <i>q</i> of <i>f</i>.
   * It is a static warning if <i>T<sub>j</sub></i> may not be assigned to <i>S<sub>j</sub>, 1 &lt;=
   * j &lt;= m</i>.
   */
  static const StaticWarningCode LIST_ELEMENT_TYPE_NOT_ASSIGNABLE = const StaticWarningCode.con1('LIST_ELEMENT_TYPE_NOT_ASSIGNABLE', 42, "The element type '{0}' cannot be assigned to the list type '{1}'");

  /**
   * 12.7 Map: A run-time map literal &lt;<i>K</i>, <i>V</i>&gt; [<i>k<sub>1</sub></i> :
   * <i>e<sub>1</sub></i> &hellip; <i>k<sub>n</sub></i> : <i>e<sub>n</sub></i>] is evaluated as
   * follows:
   * * The operator []= is invoked on <i>m</i> with first argument <i>k<sub>i</sub></i> and second
   * argument <i>e<sub>i</sub></i><i>, 1 &lt;= i &lt;= n</i>
   *
   * 12.14.2 Binding Actuals to Formals: Let <i>T<sub>i</sub></i> be the static type of
   * <i>a<sub>i</sub></i>, let <i>S<sub>i</sub></i> be the type of <i>p<sub>i</sub>, 1 &lt;= i &lt;=
   * n+k</i> and let <i>S<sub>q</sub></i> be the type of the named parameter <i>q</i> of <i>f</i>.
   * It is a static warning if <i>T<sub>j</sub></i> may not be assigned to <i>S<sub>j</sub>, 1 &lt;=
   * j &lt;= m</i>.
   */
  static const StaticWarningCode MAP_KEY_TYPE_NOT_ASSIGNABLE = const StaticWarningCode.con1('MAP_KEY_TYPE_NOT_ASSIGNABLE', 43, "The element type '{0}' cannot be assigned to the map key type '{1}'");

  /**
   * 12.7 Map: A run-time map literal &lt;<i>K</i>, <i>V</i>&gt; [<i>k<sub>1</sub></i> :
   * <i>e<sub>1</sub></i> &hellip; <i>k<sub>n</sub></i> : <i>e<sub>n</sub></i>] is evaluated as
   * follows:
   * * The operator []= is invoked on <i>m</i> with first argument <i>k<sub>i</sub></i> and second
   * argument <i>e<sub>i</sub></i><i>, 1 &lt;= i &lt;= n</i>
   *
   * 12.14.2 Binding Actuals to Formals: Let <i>T<sub>i</sub></i> be the static type of
   * <i>a<sub>i</sub></i>, let <i>S<sub>i</sub></i> be the type of <i>p<sub>i</sub>, 1 &lt;= i &lt;=
   * n+k</i> and let <i>S<sub>q</sub></i> be the type of the named parameter <i>q</i> of <i>f</i>.
   * It is a static warning if <i>T<sub>j</sub></i> may not be assigned to <i>S<sub>j</sub>, 1 &lt;=
   * j &lt;= m</i>.
   */
  static const StaticWarningCode MAP_VALUE_TYPE_NOT_ASSIGNABLE = const StaticWarningCode.con1('MAP_VALUE_TYPE_NOT_ASSIGNABLE', 44, "The element type '{0}' cannot be assigned to the map value type '{1}'");

  /**
   * 7.3 Setters: It is a static warning if a class has a setter named <i>v=</i> with argument type
   * <i>T</i> and a getter named <i>v</i> with return type <i>S</i>, and <i>T</i> may not be
   * assigned to <i>S</i>.
   */
  static const StaticWarningCode MISMATCHED_GETTER_AND_SETTER_TYPES = const StaticWarningCode.con1('MISMATCHED_GETTER_AND_SETTER_TYPES', 45, "The parameter type for setter '{0}' is '{1}' which is not assignable to its getter (of type '{2}')");

  /**
   * 7.3 Setters: It is a static warning if a class has a setter named <i>v=</i> with argument type
   * <i>T</i> and a getter named <i>v</i> with return type <i>S</i>, and <i>T</i> may not be
   * assigned to <i>S</i>.
   */
  static const StaticWarningCode MISMATCHED_GETTER_AND_SETTER_TYPES_FROM_SUPERTYPE = const StaticWarningCode.con1('MISMATCHED_GETTER_AND_SETTER_TYPES_FROM_SUPERTYPE', 46, "The parameter type for setter '{0}' is '{1}' which is not assignable to its getter (of type '{2}'), from superclass '{3}'");

  /**
   * 13.12 Return: It is a static warning if a function contains both one or more return statements
   * of the form <i>return;</i> and one or more return statements of the form <i>return e;</i>.
   */
  static const StaticWarningCode MIXED_RETURN_TYPES = const StaticWarningCode.con1('MIXED_RETURN_TYPES', 47, "Methods and functions cannot use return both with and without values");

  /**
   * 12.11.1 New: It is a static warning if <i>q</i> is a constructor of an abstract class and
   * <i>q</i> is not a factory constructor.
   */
  static const StaticWarningCode NEW_WITH_ABSTRACT_CLASS = const StaticWarningCode.con1('NEW_WITH_ABSTRACT_CLASS', 48, "Abstract classes cannot be created with a 'new' expression");

  /**
   * 15.8 Parameterized Types: Any use of a malbounded type gives rise to a static warning.
   *
   * @param typeName the name of the type being referenced (<i>S</i>)
   * @param parameterCount the number of type parameters that were declared
   * @param argumentCount the number of type arguments provided
   * @see CompileTimeErrorCode#CONST_WITH_INVALID_TYPE_PARAMETERS
   * @see StaticTypeWarningCode#WRONG_NUMBER_OF_TYPE_ARGUMENTS
   */
  static const StaticWarningCode NEW_WITH_INVALID_TYPE_PARAMETERS = const StaticWarningCode.con1('NEW_WITH_INVALID_TYPE_PARAMETERS', 49, "The type '{0}' is declared with {1} type parameters, but {2} type arguments were given");

  /**
   * 12.11.1 New: It is a static warning if <i>T</i> is not a class accessible in the current scope,
   * optionally followed by type arguments.
   *
   * @param name the name of the non-type element
   */
  static const StaticWarningCode NEW_WITH_NON_TYPE = const StaticWarningCode.con1('NEW_WITH_NON_TYPE', 50, "The name '{0}' is not a class");

  /**
   * 12.11.1 New: If <i>T</i> is a class or parameterized type accessible in the current scope then:
   * 1. If <i>e</i> is of the form <i>new T.id(a<sub>1</sub>, &hellip;, a<sub>n</sub>,
   * x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;, x<sub>n+k</sub>: a<sub>n+k</sub>)</i> it is a
   * static warning if <i>T.id</i> is not the name of a constructor declared by the type <i>T</i>.
   * If <i>e</i> of the form <i>new T(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>:
   * a<sub>n+1</sub>, &hellip;, x<sub>n+k</sub>: a<sub>n+kM/sub>)</i> it is a static warning if the
   * type <i>T</i> does not declare a constructor with the same name as the declaration of <i>T</i>.
   */
  static const StaticWarningCode NEW_WITH_UNDEFINED_CONSTRUCTOR = const StaticWarningCode.con1('NEW_WITH_UNDEFINED_CONSTRUCTOR', 51, "The class '{0}' does not have a constructor '{1}'");

  /**
   * 12.11.1 New: If <i>T</i> is a class or parameterized type accessible in the current scope then:
   * 1. If <i>e</i> is of the form <i>new T.id(a<sub>1</sub>, &hellip;, a<sub>n</sub>,
   * x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;, x<sub>n+k</sub>: a<sub>n+k</sub>)</i> it is a
   * static warning if <i>T.id</i> is not the name of a constructor declared by the type <i>T</i>.
   * If <i>e</i> of the form <i>new T(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>:
   * a<sub>n+1</sub>, &hellip;, x<sub>n+k</sub>: a<sub>n+kM/sub>)</i> it is a static warning if the
   * type <i>T</i> does not declare a constructor with the same name as the declaration of <i>T</i>.
   */
  static const StaticWarningCode NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT = const StaticWarningCode.con1('NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT', 52, "The class '{0}' does not have a default constructor");

  /**
   * 7.9.1 Inheritance and Overriding: It is a static warning if a non-abstract class inherits an
   * abstract method.
   *
   * 7.10 Superinterfaces: Let <i>C</i> be a concrete class that does not declare its own
   * <i>noSuchMethod()</i> method. It is a static warning if the implicit interface of <i>C</i>
   * includes an instance member <i>m</i> of type <i>F</i> and <i>C</i> does not declare or inherit
   * a corresponding instance member <i>m</i> of type <i>F'</i> such that <i>F' <: F</i>.
   *
   * 7.4 Abstract Instance Members: It is a static warning if an abstract member is declared or
   * inherited in a concrete class unless that member overrides a concrete one.
   *
   * @param memberName the name of the first member
   * @param memberName the name of the second member
   * @param memberName the name of the third member
   * @param memberName the name of the fourth member
   * @param additionalCount the number of additional missing members that aren't listed
   */
  static const StaticWarningCode NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS = const StaticWarningCode.con1('NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS', 53, "Missing concrete implementation of {0}, {1}, {2}, {3} and {4} more");

  /**
   * 7.9.1 Inheritance and Overriding: It is a static warning if a non-abstract class inherits an
   * abstract method.
   *
   * 7.10 Superinterfaces: Let <i>C</i> be a concrete class that does not declare its own
   * <i>noSuchMethod()</i> method. It is a static warning if the implicit interface of <i>C</i>
   * includes an instance member <i>m</i> of type <i>F</i> and <i>C</i> does not declare or inherit
   * a corresponding instance member <i>m</i> of type <i>F'</i> such that <i>F' <: F</i>.
   *
   * 7.4 Abstract Instance Members: It is a static warning if an abstract member is declared or
   * inherited in a concrete class unless that member overrides a concrete one.
   *
   * @param memberName the name of the first member
   * @param memberName the name of the second member
   * @param memberName the name of the third member
   * @param memberName the name of the fourth member
   */
  static const StaticWarningCode NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR = const StaticWarningCode.con1('NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR', 54, "Missing concrete implementation of {0}, {1}, {2} and {3}");

  /**
   * 7.9.1 Inheritance and Overriding: It is a static warning if a non-abstract class inherits an
   * abstract method.
   *
   * 7.10 Superinterfaces: Let <i>C</i> be a concrete class that does not declare its own
   * <i>noSuchMethod()</i> method. It is a static warning if the implicit interface of <i>C</i>
   * includes an instance member <i>m</i> of type <i>F</i> and <i>C</i> does not declare or inherit
   * a corresponding instance member <i>m</i> of type <i>F'</i> such that <i>F' <: F</i>.
   *
   * 7.4 Abstract Instance Members: It is a static warning if an abstract member is declared or
   * inherited in a concrete class unless that member overrides a concrete one.
   *
   * @param memberName the name of the member
   */
  static const StaticWarningCode NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE = const StaticWarningCode.con1('NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE', 55, "Missing concrete implementation of {0}");

  /**
   * 7.9.1 Inheritance and Overriding: It is a static warning if a non-abstract class inherits an
   * abstract method.
   *
   * 7.10 Superinterfaces: Let <i>C</i> be a concrete class that does not declare its own
   * <i>noSuchMethod()</i> method. It is a static warning if the implicit interface of <i>C</i>
   * includes an instance member <i>m</i> of type <i>F</i> and <i>C</i> does not declare or inherit
   * a corresponding instance member <i>m</i> of type <i>F'</i> such that <i>F' <: F</i>.
   *
   * 7.4 Abstract Instance Members: It is a static warning if an abstract member is declared or
   * inherited in a concrete class unless that member overrides a concrete one.
   *
   * @param memberName the name of the first member
   * @param memberName the name of the second member
   * @param memberName the name of the third member
   */
  static const StaticWarningCode NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE = const StaticWarningCode.con1('NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE', 56, "Missing concrete implementation of {0}, {1} and {2}");

  /**
   * 7.9.1 Inheritance and Overriding: It is a static warning if a non-abstract class inherits an
   * abstract method.
   *
   * 7.10 Superinterfaces: Let <i>C</i> be a concrete class that does not declare its own
   * <i>noSuchMethod()</i> method. It is a static warning if the implicit interface of <i>C</i>
   * includes an instance member <i>m</i> of type <i>F</i> and <i>C</i> does not declare or inherit
   * a corresponding instance member <i>m</i> of type <i>F'</i> such that <i>F' <: F</i>.
   *
   * 7.4 Abstract Instance Members: It is a static warning if an abstract member is declared or
   * inherited in a concrete class unless that member overrides a concrete one.
   *
   * @param memberName the name of the first member
   * @param memberName the name of the second member
   */
  static const StaticWarningCode NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO = const StaticWarningCode.con1('NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO', 57, "Missing concrete implementation of {0} and {1}");

  /**
   * 13.11 Try: An on-catch clause of the form <i>on T catch (p<sub>1</sub>, p<sub>2</sub>) s</i> or
   * <i>on T s</i> matches an object <i>o</i> if the type of <i>o</i> is a subtype of <i>T</i>. It
   * is a static warning if <i>T</i> does not denote a type available in the lexical scope of the
   * catch clause.
   *
   * @param name the name of the non-type element
   */
  static const StaticWarningCode NON_TYPE_IN_CATCH_CLAUSE = const StaticWarningCode.con1('NON_TYPE_IN_CATCH_CLAUSE', 58, "The name '{0}' is not a type and cannot be used in an on-catch clause");

  /**
   * 7.1.1 Operators: It is a static warning if the return type of the user-declared operator []= is
   * explicitly declared and not void.
   */
  static const StaticWarningCode NON_VOID_RETURN_FOR_OPERATOR = const StaticWarningCode.con1('NON_VOID_RETURN_FOR_OPERATOR', 59, "The return type of the operator []= must be 'void'");

  /**
   * 7.3 Setters: It is a static warning if a setter declares a return type other than void.
   */
  static const StaticWarningCode NON_VOID_RETURN_FOR_SETTER = const StaticWarningCode.con1('NON_VOID_RETURN_FOR_SETTER', 60, "The return type of the setter must be 'void'");

  /**
   * 15.1 Static Types: A type <i>T</i> is malformed iff: * <i>T</i> has the form <i>id</i> or the
   * form <i>prefix.id</i>, and in the enclosing lexical scope, the name <i>id</i> (respectively
   * <i>prefix.id</i>) does not denote a type. * <i>T</i> denotes a type parameter in the
   * enclosing lexical scope, but occurs in the signature or body of a static member. *
   * <i>T</i> is a parameterized type of the form <i>G&lt;S<sub>1</sub>, .., S<sub>n</sub>&gt;</i>,
   *
   * Any use of a malformed type gives rise to a static warning.
   *
   * @param nonTypeName the name that is not a type
   */
  static const StaticWarningCode NOT_A_TYPE = const StaticWarningCode.con1('NOT_A_TYPE', 61, "{0} is not a type");

  /**
   * 12.14.2 Binding Actuals to Formals: It is a static warning if <i>m &lt; h</i> or if <i>m &gt;
   * n</i>.
   *
   * @param requiredCount the expected number of required arguments
   * @param argumentCount the actual number of positional arguments given
   * @see #EXTRA_POSITIONAL_ARGUMENTS
   */
  static const StaticWarningCode NOT_ENOUGH_REQUIRED_ARGUMENTS = const StaticWarningCode.con1('NOT_ENOUGH_REQUIRED_ARGUMENTS', 62, "{0} required argument(s) expected, but {1} found");

  /**
   * 14.3 Parts: It is a static warning if the referenced part declaration <i>p</i> names a library
   * other than the current library as the library to which <i>p</i> belongs.
   *
   * @param expectedLibraryName the name of expected library name
   * @param actualLibraryName the non-matching actual library name from the "part of" declaration
   */
  static const StaticWarningCode PART_OF_DIFFERENT_LIBRARY = const StaticWarningCode.con1('PART_OF_DIFFERENT_LIBRARY', 63, "Expected this library to be part of '{0}', not '{1}'");

  /**
   * 7.6.2 Factories: It is a static warning if the function type of <i>k'</i> is not a subtype of
   * the type of <i>k</i>.
   *
   * @param redirectedName the name of the redirected constructor
   * @param redirectingName the name of the redirecting constructor
   */
  static const StaticWarningCode REDIRECT_TO_INVALID_FUNCTION_TYPE = const StaticWarningCode.con1('REDIRECT_TO_INVALID_FUNCTION_TYPE', 64, "The redirected constructor '{0}' has incompatible parameters with '{1}'");

  /**
   * 7.6.2 Factories: It is a static warning if the function type of <i>k'</i> is not a subtype of
   * the type of <i>k</i>.
   *
   * @param redirectedName the name of the redirected constructor return type
   * @param redirectingName the name of the redirecting constructor return type
   */
  static const StaticWarningCode REDIRECT_TO_INVALID_RETURN_TYPE = const StaticWarningCode.con1('REDIRECT_TO_INVALID_RETURN_TYPE', 65, "The return type '{0}' of the redirected constructor is not assignable to '{1}'");

  /**
   * 7.6.2 Factories: It is a static warning if type does not denote a class accessible in the
   * current scope; if type does denote such a class <i>C</i> it is a static warning if the
   * referenced constructor (be it <i>type</i> or <i>type.id</i>) is not a constructor of <i>C</i>.
   */
  static const StaticWarningCode REDIRECT_TO_MISSING_CONSTRUCTOR = const StaticWarningCode.con1('REDIRECT_TO_MISSING_CONSTRUCTOR', 66, "The constructor '{0}' could not be found in '{1}'");

  /**
   * 7.6.2 Factories: It is a static warning if type does not denote a class accessible in the
   * current scope; if type does denote such a class <i>C</i> it is a static warning if the
   * referenced constructor (be it <i>type</i> or <i>type.id</i>) is not a constructor of <i>C</i>.
   */
  static const StaticWarningCode REDIRECT_TO_NON_CLASS = const StaticWarningCode.con1('REDIRECT_TO_NON_CLASS', 67, "The name '{0}' is not a type and cannot be used in a redirected constructor");

  /**
   * 13.12 Return: Let <i>f</i> be the function immediately enclosing a return statement of the form
   * <i>return;</i> It is a static warning if both of the following conditions hold:
   * <ol>
   * * <i>f</i> is not a generative constructor.
   * * The return type of <i>f</i> may not be assigned to void.
   * </ol>
   */
  static const StaticWarningCode RETURN_WITHOUT_VALUE = const StaticWarningCode.con1('RETURN_WITHOUT_VALUE', 68, "Missing return value after 'return'");

  /**
   * 12.16.3 Static Invocation: It is a static warning if <i>C</i> does not declare a static method
   * or getter <i>m</i>.
   *
   * @param memberName the name of the instance member
   */
  static const StaticWarningCode STATIC_ACCESS_TO_INSTANCE_MEMBER = const StaticWarningCode.con1('STATIC_ACCESS_TO_INSTANCE_MEMBER', 69, "Instance member '{0}' cannot be accessed using static access");

  /**
   * 13.9 Switch: It is a static warning if the type of <i>e</i> may not be assigned to the type of
   * <i>e<sub>k</sub></i>.
   */
  static const StaticWarningCode SWITCH_EXPRESSION_NOT_ASSIGNABLE = const StaticWarningCode.con1('SWITCH_EXPRESSION_NOT_ASSIGNABLE', 70, "Type '{0}' of the switch expression is not assignable to the type '{1}' of case expressions");

  /**
   * 15.1 Static Types: It is a static warning to use a deferred type in a type annotation.
   *
   * @param name the name of the type that is deferred and being used in a type annotation
   */
  static const StaticWarningCode TYPE_ANNOTATION_DEFERRED_CLASS = const StaticWarningCode.con1('TYPE_ANNOTATION_DEFERRED_CLASS', 71, "The deferred type '{0}' cannot be used in a declaration, cast or type test");

  /**
   * 12.31 Type Test: It is a static warning if <i>T</i> does not denote a type available in the
   * current lexical scope.
   */
  static const StaticWarningCode TYPE_TEST_NON_TYPE = const StaticWarningCode.con1('TYPE_TEST_NON_TYPE', 72, "The name '{0}' is not a type and cannot be used in an 'is' expression");

  /**
   * 10 Generics: However, a type parameter is considered to be a malformed type when referenced by
   * a static member.
   *
   * 15.1 Static Types: Any use of a malformed type gives rise to a static warning. A malformed type
   * is then interpreted as dynamic by the static type checker and the runtime.
   */
  static const StaticWarningCode TYPE_PARAMETER_REFERENCED_BY_STATIC = const StaticWarningCode.con1('TYPE_PARAMETER_REFERENCED_BY_STATIC', 73, "Static members cannot reference type parameters");

  /**
   * 12.16.3 Static Invocation: A static method invocation <i>i</i> has the form
   * <i>C.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;
   * x<sub>n+k</sub>: a<sub>n+k</sub>)</i>. It is a static warning if <i>C</i> does not denote a
   * class in the current scope.
   *
   * @param undefinedClassName the name of the undefined class
   */
  static const StaticWarningCode UNDEFINED_CLASS = const StaticWarningCode.con1('UNDEFINED_CLASS', 74, "Undefined class '{0}'");

  /**
   * Same as [UNDEFINED_CLASS], but to catch using "boolean" instead of "bool".
   */
  static const StaticWarningCode UNDEFINED_CLASS_BOOLEAN = const StaticWarningCode.con1('UNDEFINED_CLASS_BOOLEAN', 75, "Undefined class 'boolean'; did you mean 'bool'?");

  /**
   * 12.17 Getter Invocation: It is a static warning if there is no class <i>C</i> in the enclosing
   * lexical scope of <i>i</i>, or if <i>C</i> does not declare, implicitly or explicitly, a getter
   * named <i>m</i>.
   *
   * @param getterName the name of the getter
   * @param enclosingType the name of the enclosing type where the getter is being looked for
   */
  static const StaticWarningCode UNDEFINED_GETTER = const StaticWarningCode.con1('UNDEFINED_GETTER', 76, "There is no such getter '{0}' in '{1}'");

  /**
   * 12.30 Identifier Reference: It is as static warning if an identifier expression of the form
   * <i>id</i> occurs inside a top level or static function (be it function, method, getter, or
   * setter) or variable initializer and there is no declaration <i>d</i> with name <i>id</i> in the
   * lexical scope enclosing the expression.
   *
   * @param name the name of the identifier
   */
  static const StaticWarningCode UNDEFINED_IDENTIFIER = const StaticWarningCode.con1('UNDEFINED_IDENTIFIER', 77, "Undefined name '{0}'");

  /**
   * 12.14.2 Binding Actuals to Formals: Furthermore, each <i>q<sub>i</sub></i>, <i>1<=i<=l</i>,
   * must have a corresponding named parameter in the set {<i>p<sub>n+1</sub></i> &hellip;
   * <i>p<sub>n+k</sub></i>} or a static warning occurs.
   *
   * @param name the name of the requested named parameter
   */
  static const StaticWarningCode UNDEFINED_NAMED_PARAMETER = const StaticWarningCode.con1('UNDEFINED_NAMED_PARAMETER', 78, "The named parameter '{0}' is not defined");

  /**
   * 12.18 Assignment: It is as static warning if an assignment of the form <i>v = e</i> occurs
   * inside a top level or static function (be it function, method, getter, or setter) or variable
   * initializer and there is no declaration <i>d</i> with name <i>v=</i> in the lexical scope
   * enclosing the assignment.
   *
   * 12.18 Assignment: It is a static warning if there is no class <i>C</i> in the enclosing lexical
   * scope of the assignment, or if <i>C</i> does not declare, implicitly or explicitly, a setter
   * <i>v=</i>.
   *
   * @param setterName the name of the getter
   * @param enclosingType the name of the enclosing type where the setter is being looked for
   */
  static const StaticWarningCode UNDEFINED_SETTER = const StaticWarningCode.con1('UNDEFINED_SETTER', 79, "There is no such setter '{0}' in '{1}'");

  /**
   * 12.16.3 Static Invocation: It is a static warning if <i>C</i> does not declare a static method
   * or getter <i>m</i>.
   *
   * @param methodName the name of the method
   * @param enclosingType the name of the enclosing type where the method is being looked for
   */
  static const StaticWarningCode UNDEFINED_STATIC_METHOD_OR_GETTER = const StaticWarningCode.con1('UNDEFINED_STATIC_METHOD_OR_GETTER', 80, "There is no such static method, getter or setter '{0}' in '{1}'");

  /**
   * 7.2 Getters: It is a static warning if the return type of a getter is void.
   */
  static const StaticWarningCode VOID_RETURN_FOR_GETTER = const StaticWarningCode.con1('VOID_RETURN_FOR_GETTER', 81, "The return type of the getter must not be 'void'");

  static const List<StaticWarningCode> values = const [
      AMBIGUOUS_IMPORT,
      ARGUMENT_TYPE_NOT_ASSIGNABLE,
      ASSIGNMENT_TO_CONST,
      ASSIGNMENT_TO_FINAL,
      ASSIGNMENT_TO_FINAL_NO_SETTER,
      ASSIGNMENT_TO_FUNCTION,
      ASSIGNMENT_TO_METHOD,
      CASE_BLOCK_NOT_TERMINATED,
      CAST_TO_NON_TYPE,
      CONCRETE_CLASS_WITH_ABSTRACT_MEMBER,
      CONFLICTING_DART_IMPORT,
      CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER,
      CONFLICTING_INSTANCE_METHOD_SETTER,
      CONFLICTING_INSTANCE_METHOD_SETTER2,
      CONFLICTING_INSTANCE_SETTER_AND_SUPERCLASS_MEMBER,
      CONFLICTING_STATIC_GETTER_AND_INSTANCE_SETTER,
      CONFLICTING_STATIC_SETTER_AND_INSTANCE_MEMBER,
      CONST_WITH_ABSTRACT_CLASS,
      EQUAL_KEYS_IN_MAP,
      EXPORT_DUPLICATED_LIBRARY_NAME,
      EXTRA_POSITIONAL_ARGUMENTS,
      FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION,
      FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR,
      FIELD_INITIALIZER_NOT_ASSIGNABLE,
      FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE,
      FINAL_NOT_INITIALIZED,
      FUNCTION_WITHOUT_CALL,
      IMPORT_DUPLICATED_LIBRARY_NAME,
      IMPORT_OF_NON_LIBRARY,
      INCONSISTENT_METHOD_INHERITANCE_GETTER_AND_METHOD,
      INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC,
      INVALID_GETTER_OVERRIDE_RETURN_TYPE,
      INVALID_METHOD_OVERRIDE_NAMED_PARAM_TYPE,
      INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE,
      INVALID_METHOD_OVERRIDE_OPTIONAL_PARAM_TYPE,
      INVALID_METHOD_OVERRIDE_RETURN_TYPE,
      INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_NAMED,
      INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL,
      INVALID_OVERRIDE_NAMED,
      INVALID_OVERRIDE_POSITIONAL,
      INVALID_OVERRIDE_REQUIRED,
      INVALID_SETTER_OVERRIDE_NORMAL_PARAM_TYPE,
      LIST_ELEMENT_TYPE_NOT_ASSIGNABLE,
      MAP_KEY_TYPE_NOT_ASSIGNABLE,
      MAP_VALUE_TYPE_NOT_ASSIGNABLE,
      MISMATCHED_GETTER_AND_SETTER_TYPES,
      MISMATCHED_GETTER_AND_SETTER_TYPES_FROM_SUPERTYPE,
      MIXED_RETURN_TYPES,
      NEW_WITH_ABSTRACT_CLASS,
      NEW_WITH_INVALID_TYPE_PARAMETERS,
      NEW_WITH_NON_TYPE,
      NEW_WITH_UNDEFINED_CONSTRUCTOR,
      NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT,
      NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS,
      NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR,
      NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
      NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE,
      NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO,
      NON_TYPE_IN_CATCH_CLAUSE,
      NON_VOID_RETURN_FOR_OPERATOR,
      NON_VOID_RETURN_FOR_SETTER,
      NOT_A_TYPE,
      NOT_ENOUGH_REQUIRED_ARGUMENTS,
      PART_OF_DIFFERENT_LIBRARY,
      REDIRECT_TO_INVALID_FUNCTION_TYPE,
      REDIRECT_TO_INVALID_RETURN_TYPE,
      REDIRECT_TO_MISSING_CONSTRUCTOR,
      REDIRECT_TO_NON_CLASS,
      RETURN_WITHOUT_VALUE,
      STATIC_ACCESS_TO_INSTANCE_MEMBER,
      SWITCH_EXPRESSION_NOT_ASSIGNABLE,
      TYPE_ANNOTATION_DEFERRED_CLASS,
      TYPE_TEST_NON_TYPE,
      TYPE_PARAMETER_REFERENCED_BY_STATIC,
      UNDEFINED_CLASS,
      UNDEFINED_CLASS_BOOLEAN,
      UNDEFINED_GETTER,
      UNDEFINED_IDENTIFIER,
      UNDEFINED_NAMED_PARAMETER,
      UNDEFINED_SETTER,
      UNDEFINED_STATIC_METHOD_OR_GETTER,
      VOID_RETURN_FOR_GETTER];

  /**
   * The template used to create the message to be displayed for this error.
   */
  final String message;

  /**
   * The template used to create the correction to be displayed for this error, or `null` if
   * there is no correction information for this error.
   */
  final String correction;

  /**
   * Initialize a newly created error code to have the given message.
   *
   * @param message the message template used to create the message to be displayed for the error
   */
  const StaticWarningCode.con1(String name, int ordinal, String message) : this.con2(name, ordinal, message, null);

  /**
   * Initialize a newly created error code to have the given message and correction.
   *
   * @param message the template used to create the message to be displayed for the error
   * @param correction the template used to create the correction to be displayed for the error
   */
  const StaticWarningCode.con2(String name, int ordinal, this.message, this.correction) : super(name, ordinal);

  @override
  ErrorSeverity get errorSeverity => ErrorType.STATIC_WARNING.severity;

  @override
  ErrorType get type => ErrorType.STATIC_WARNING;

  @override
  String get uniqueName => "${runtimeType.toString()}.${name}";
}

/**
 * The enumeration `TodoCode` defines the single TODO `ErrorCode`.
 */
class TodoCode extends Enum<TodoCode> implements ErrorCode {
  /**
   * The single enum of TodoCode.
   */
  static const TodoCode TODO = const TodoCode('TODO', 0);

  static const List<TodoCode> values = const [TODO];

  /**
   * This matches the two common Dart task styles
   *
   * * TODO:
   * * TODO(username):
   *
   * As well as
   * * TODO
   *
   * But not
   * * todo
   * * TODOS
   */
  static RegExp TODO_REGEX = new RegExp("([\\s/\\*])((TODO[^\\w\\d][^\\r\\n]*)|(TODO:?\$))");

  const TodoCode(String name, int ordinal) : super(name, ordinal);

  @override
  String get correction => null;

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.INFO;

  @override
  String get message => "{0}";

  @override
  ErrorType get type => ErrorType.TODO;

  @override
  String get uniqueName => "${runtimeType.toString()}.${name}";
}